import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import QtCore
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    layerNamespacePlugin: "workspace-groups"

    readonly property var defaultGroups: [
        { "id": 1, "name": "default", "icon": "󰅩", "color": "#89b4fa" }
    ]

    readonly property var onLaunchGroups: {
        if (pluginData && pluginData.onLaunchGroups && Array.isArray(pluginData.onLaunchGroups) && pluginData.onLaunchGroups.length > 0)
            return pluginData.onLaunchGroups;
        if (pluginData && pluginData.groups && Array.isArray(pluginData.groups) && pluginData.groups.length > 0)
            return pluginData.groups;
        return defaultGroups;
    }

    property var groups: []

    readonly property var nerdfontPool: [
        "󰅩", "󰅨", "󰘐", "󰨞", "󰆍", "󰢹", "󱆃", "", "󰘚", "󰆼", "󰒓", "󰇄",
        "󰈹", "󰖟", "󰇧", "󰈮", "󰊯", "󰒋",
        "󰋋", "󰝚", "󰎈", "󰕼", "󰗃", "󰓇", "󰐌", "󰏘", "󰥔",
        "󰭹", "󰍡", "󰇮", "󰻞", "󰒱", "󰭻",
        "󰊴", "󰊲", "󰊳", "󰊵", "󰯀",
        "󰠮", "󰏫", "󰈙", "󰃭", "󰄬", "󱉸",
        "󰀝", "󰄛", "󱄄", "󰡩", "󰀪", "󰣇", "󱄅", "󰘧"
    ]

    readonly property var colorPalette: [
        "#89b4fa", "#f38ba8", "#a6e3a1", "#fab387", "#cba6f7",
        "#f9e2af", "#94e2d5", "#74c7ec", "#b4befe", "#eba0ac"
    ]

    function getRandomNerdfontIcon() {
        return nerdfontPool[Math.floor(Math.random() * nerdfontPool.length)];
    }

    function getNextGroupColor() {
        return colorPalette[(root.groups.length) % colorPalette.length];
    }

    property int workspacesPerMonitor: (pluginData && pluginData.workspacesPerMonitor) ? pluginData.workspacesPerMonitor : 10
    property var monitorPriority: (pluginData && pluginData.monitorPriority) ? pluginData.monitorPriority : ["HDMI-A-1", "DP-1"]
    property bool hideEmptyWorkspaces: (pluginData && pluginData.hideEmptyWorkspaces !== undefined) ? pluginData.hideEmptyWorkspaces : true

    property int activeGroupIndex: 1
    property var lastActiveWorkspaces: ({})
    property bool overviewOpen: false
    property bool createModalOpen: false
    property bool deleteConfirmOpen: false
    property bool contentVisible: false
    property bool isClosing: false
    property int selectedOverviewIndex: 0

    property string formGroupName: ""
    property string formGroupIcon: "󰅩"
    property string formGroupColor: "#89b4fa"
    property bool formSwitchImmediate: true
    property int editingGroupId: 0

    property int dragFromIndex: -1
    property int dragTargetIndex: -1
    property real dragMouseX: 0
    property real dragMouseY: 0
    property bool isDraggingCard: false

    property int groupToDeleteId: 0
    property string groupToDeleteName: ""
    property int groupToDeleteWindowCount: 0

    readonly property int totalOverviewItems: (root.groups ? root.groups.length : 0) + 1
    readonly property int gridColumns: totalOverviewItems <= 4 ? 2 : (totalOverviewItems <= 9 ? 3 : 4)
    readonly property int gridRows: Math.max(1, Math.ceil(totalOverviewItems / gridColumns))

    property bool mouseMovedSinceOpen: false
    property real lastGlobalMouseX: -1
    property real lastGlobalMouseY: -1

    Timer {
        id: overviewCloseTimer
        interval: Theme.modalAnimationDuration + 50
        repeat: false
        onTriggered: {
            root.isClosing = false;
            root.overviewOpen = false;
            root.createModalOpen = false;
            root.deleteConfirmOpen = false;
        }
    }

    readonly property bool isLua: CompositorService.isHyprland && (Hyprland.usingLua === true || HyprlandService.luaConfigActive)

    readonly property string configDir: Paths.strip(StandardPaths.writableLocation(StandardPaths.ConfigLocation))
    readonly property string hyprDmsDir: configDir + "/hypr/dms"
    readonly property string luaConfigPath: hyprDmsDir + "/workspace_groups.lua"

    readonly property string stateDir: {
        const loc = StandardPaths.writableLocation(StandardPaths.GenericStateLocation);
        const p = loc ? Paths.strip(loc) : "";
        if (p && p.length > 0)
            return p + "/DankMaterialShell";
        return (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/DankMaterialShell";
    }
    readonly property string stateFilePath: stateDir + "/workspace_groups.json"

    Timer {
        id: saveStateDebounceTimer
        interval: 1000
        repeat: false
        onTriggered: root.saveStateFile()
    }

    function loadStateFile() {
        try {
            const escapedPath = root.stateFilePath.replace(/\\/g, "\\\\").replace(/"/g, '\\"');
            const qml = 'import QtQuick; import Quickshell.Io; FileView { path: "' + escapedPath + '"; blockLoading: true; blockWrites: true }';
            const fv = Qt.createQmlObject(qml, root, "workspace_groups_reader");
            const raw = fv.text();
            fv.destroy();
            if (raw && raw.trim()) {
                const parsed = JSON.parse(raw);
                if (parsed && typeof parsed === "object") {
                    return parsed;
                }
            }
        } catch (e) {
            console.log("[WorkspaceGroups] No existing state file or failed to read:", e.message);
        }
        return null;
    }

    function saveStateFile(callback) {
        saveStateDebounceTimer.stop();
        const data = {
            "groups": root.groups,
            "activeGroupIndex": root.activeGroupIndex,
            "lastActiveWorkspaces": root.lastActiveWorkspaces,
            "timestamp": new Date().toISOString()
        };
        const jsonString = JSON.stringify(data, null, 2);
        const tmpFile = root.stateFilePath + ".tmp." + Date.now();

        Proc.runCommand(
            "save-workspace-groups-state",
            [
                "sh", "-c",
                'mkdir -p "$1" && printf "%s\\n" "$2" > "$3" && mv -f "$3" "$4"',
                "_",
                root.stateDir,
                jsonString,
                tmpFile,
                root.stateFilePath
            ],
            (output, exitCode) => {
                if (exitCode !== 0) {
                    console.warn("[WorkspaceGroups] Failed to save state file:", output);
                } else if (typeof callback === "function") {
                    callback();
                }
            }
        );
    }

    Component.onCompleted: {
        const savedState = loadStateFile();
        if (savedState && Array.isArray(savedState.groups) && savedState.groups.length > 0) {
            root.groups = savedState.groups.map((g, idx) => ({
                id: idx + 1,
                name: g.name || ("Group " + (idx + 1)),
                icon: g.icon || getRandomNerdfontIcon(),
                color: g.color || colorPalette[idx % colorPalette.length]
            }));
            if (savedState.lastActiveWorkspaces && typeof savedState.lastActiveWorkspaces === "object") {
                root.lastActiveWorkspaces = savedState.lastActiveWorkspaces;
            }
            if (typeof savedState.activeGroupIndex === "number" && savedState.activeGroupIndex >= 1 && savedState.activeGroupIndex <= root.groups.length) {
                root.activeGroupIndex = savedState.activeGroupIndex;
            }
        } else {
            root.groups = JSON.parse(JSON.stringify(root.onLaunchGroups));
        }

        sanitizeLastActiveWorkspaces();
        ensureGroupsCoverAllWorkspaces();
        syncFromCurrentWorkspace();
        notifyState();
        saveStateFile();
        Qt.callLater(writeLuaConfig);
    }

    onPluginDataChanged: {
        notifyState();
        Qt.callLater(writeLuaConfig);
    }

    Connections {
        target: Hyprland
        function onFocusedWorkspaceChanged() {
            root.syncFromCurrentWorkspace();
        }
        function onWorkspacesChanged() {
            root.notifyState();
        }
    }

    Connections {
        target: Hyprland.monitors
        function onValuesChanged() {
            root.notifyState();
        }
    }

    function syncFromCurrentWorkspace() {
        const activeWs = Hyprland.focusedWorkspace?.id;
        if (!activeWs || activeWs < 1)
            return;

        const g = calcGroupFromWorkspace(activeWs);
        if (g !== root.activeGroupIndex) {
            root.activeGroupIndex = g;
            root.notifyState();
            saveStateDebounceTimer.restart();
        }

        const activeMon = Hyprland.focusedMonitor?.name;
        if (activeMon) {
            const monIdx = getMonitorIndex(activeMon);
            if (root.isWorkspaceValidForGroupAndMonitor(activeWs, g, monIdx)) {
                if (!root.lastActiveWorkspaces[g])
                    root.lastActiveWorkspaces[g] = {};
                if (root.lastActiveWorkspaces[g][activeMon] !== activeWs) {
                    root.lastActiveWorkspaces[g][activeMon] = activeWs;
                    saveStateDebounceTimer.restart();
                }
            }
        }
    }

    function getSortedMonitors() {
        const mons = Hyprland.monitors?.values || [];
        if (mons.length === 0) {
            if (root.monitorPriority && root.monitorPriority.length > 0) {
                return root.monitorPriority.map((p, idx) => ({ "name": p, "id": idx }));
            }
            return [{ "name": "default", "id": 0 }];
        }

        const sorted = [];
        const seen = {};
        for (let i = 0; i < monitorPriority.length; i++) {
            const prio = monitorPriority[i];
            const m = mons.find(x => x.name === prio);
            if (m) {
                sorted.push(m);
                seen[m.name] = true;
            }
        }
        for (let i = 0; i < mons.length; i++) {
            const m = mons[i];
            if (!seen[m.name])
                sorted.push(m);
        }
        return sorted;
    }

    function getMonitorIndex(monitorName) {
        const list = getSortedMonitors();
        const idx = list.findIndex(m => m.name === monitorName);
        return idx >= 0 ? idx : 0;
    }

    function getMonitorCount() {
        return Math.max(1, getSortedMonitors().length);
    }

    function rawGroupFromWorkspace(wsId) {
        if (!wsId || wsId < 1)
            return 1;
        const monCount = getMonitorCount();
        const totalPerGroup = workspacesPerMonitor * monCount;
        if (totalPerGroup <= 0)
            return 1;
        return Math.floor((wsId - 1) / totalPerGroup) + 1;
    }

    function calcWorkspace(groupId, monIdx, subWs) {
        const monCount = getMonitorCount();
        return (groupId - 1) * (workspacesPerMonitor * monCount) + (monIdx * workspacesPerMonitor) + subWs;
    }

    function isWorkspaceValidForGroupAndMonitor(wsId, groupId, monIdx) {
        if (!wsId || wsId < 1 || !groupId || groupId < 1 || monIdx === undefined || monIdx < 0)
            return false;
        const monCount = getMonitorCount();
        const totalPerGroup = workspacesPerMonitor * monCount;
        const startWs = (groupId - 1) * totalPerGroup + (monIdx * workspacesPerMonitor) + 1;
        const endWs = startWs + workspacesPerMonitor - 1;
        return wsId >= startWs && wsId <= endWs;
    }

    function getValidWorkspaceForMonitor(groupId, monIdx, preferredWs) {
        if (isWorkspaceValidForGroupAndMonitor(preferredWs, groupId, monIdx)) {
            return preferredWs;
        }
        return calcWorkspace(groupId, monIdx, 1);
    }

    function sanitizeLastActiveWorkspaces() {
        const sanitized = {};
        const sortedMons = getSortedMonitors();
        const numGroups = (root.groups && root.groups.length > 0) ? root.groups.length : 1;
        for (let gNum = 1; gNum <= numGroups; gNum++) {
            sanitized[gNum] = {};
            const gMap = (root.lastActiveWorkspaces && root.lastActiveWorkspaces[gNum]) ? root.lastActiveWorkspaces[gNum] : {};
            for (let mIdx = 0; mIdx < sortedMons.length; mIdx++) {
                const mName = sortedMons[mIdx].name;
                sanitized[gNum][mName] = getValidWorkspaceForMonitor(gNum, mIdx, gMap[mName]);
            }
        }
        root.lastActiveWorkspaces = sanitized;
    }

    function calcGroupFromWorkspace(wsId) {
        const raw = rawGroupFromWorkspace(wsId);
        return Math.max(1, Math.min(root.groups ? root.groups.length : 1, raw));
    }

    function calcSubWorkspaceFromWorkspace(wsId) {
        if (!wsId || wsId < 1)
            return 1;
        const monCount = getMonitorCount();
        const totalPerGroup = workspacesPerMonitor * monCount;
        if (totalPerGroup <= 0)
            return 1;
        const withinGroup = (wsId - 1) % totalPerGroup;
        return (withinGroup % workspacesPerMonitor) + 1;
    }

    function formatWindowAddress(rawAddr) {
        if (!rawAddr)
            return "";
        const s = String(rawAddr).trim();
        if (!s)
            return "";
        return s.startsWith("0x") ? s : ("0x" + s);
    }

    function ensureGroupsCoverAllWorkspaces() {
        let maxG = root.groups ? root.groups.length : 0;

        const wses = Hyprland.workspaces?.values || [];
        for (let i = 0; i < wses.length; i++) {
            const ws = wses[i];
            if (!ws) continue;
            const wid = ws.id;
            if (wid && wid > 0) {
                const winCount = (ws.windows !== undefined) ? ws.windows : (ws.lastIpcObject?.windows || 0);
                const isPersistent = (ws.ispersistent === true) || (ws.lastIpcObject?.ispersistent === true);

                if (winCount > 0 || isPersistent) {
                    const g = rawGroupFromWorkspace(wid);
                    if (g > maxG)
                        maxG = g;

                    const monName = ws.monitor?.name || ws.monitor || ws.lastIpcObject?.monitor;
                    if (monName) {
                        const mIdx = getMonitorIndex(monName);
                        if (isWorkspaceValidForGroupAndMonitor(wid, g, mIdx)) {
                            if (!root.lastActiveWorkspaces[g])
                                root.lastActiveWorkspaces[g] = {};
                            if (!root.lastActiveWorkspaces[g][monName])
                                root.lastActiveWorkspaces[g][monName] = wid;
                        }
                    }
                }
            }
        }

        const tops = Hyprland.toplevels?.values || [];
        for (let i = 0; i < tops.length; i++) {
            const top = tops[i];
            if (!top) continue;
            const wid = top.workspace?.id ?? top.lastIpcObject?.workspace?.id;
            if (wid !== undefined && wid > 0) {
                const g = rawGroupFromWorkspace(wid);
                if (g > maxG)
                    maxG = g;
            }
        }

        const maxAllowed = 20;
        const targetMax = Math.min(maxG, maxAllowed);
        if (targetMax <= (root.groups ? root.groups.length : 0)) {
            return false;
        }

        const updatedGroups = [...root.groups];
        for (let k = updatedGroups.length + 1; k <= targetMax; k++) {
            updatedGroups.push({
                "id": k,
                "name": "Group " + k,
                "icon": getRandomNerdfontIcon(),
                "color": colorPalette[(k - 1) % colorPalette.length]
            });
        }
        root.groups = updatedGroups;
        root.sanitizeLastActiveWorkspaces();

        root.notifyState();
        root.writeLuaConfig();
        root.saveStateFile();
        return true;
    }

    function notifyState() {
        if (!PluginService)
            return;
        PluginService.setGlobalVar("workspaceGroups", "activeGroupIndex", root.activeGroupIndex);
        PluginService.setGlobalVar("workspaceGroups", "groups", root.groups);
        const activeGroup = root.groups[root.activeGroupIndex - 1] || root.defaultGroups[0];
        PluginService.setGlobalVar("workspaceGroups", "activeGroupName", activeGroup.name || "");
        PluginService.setGlobalVar("workspaceGroups", "activeGroupIcon", activeGroup.icon || "󰅩");
        PluginService.setGlobalVar("workspaceGroups", "activeGroupColor", activeGroup.color || "#89b4fa");
        PluginService.setGlobalVar("workspaceGroups", "workspacesPerMonitor", root.workspacesPerMonitor);
        PluginService.setGlobalVar("workspaceGroups", "monitorCount", root.getMonitorCount());
        PluginService.setGlobalVar("workspaceGroups", "hideEmptyWorkspaces", root.hideEmptyWorkspaces);
        PluginService.setGlobalVar("workspaceGroups", "sortedMonitorNames", root.getSortedMonitors().map(m => m.name));
        PluginService.setGlobalVar("workspaceGroups", "monitorPriority", root.monitorPriority);
    }

    function switchToGroup(groupId) {
        const g = parseInt(groupId);
        if (isNaN(g) || g < 1 || g > root.groups.length)
            return "INVALID_GROUP";
        if (g === root.activeGroupIndex)
            return "ALREADY_ACTIVE";

        if (root.overviewOpen || root.createModalOpen || root.contentVisible) {
            root.closeOverview();
        }

        const mons = getSortedMonitors();
        const focusedMonName = Hyprland.focusedMonitor?.name || (mons[0] ? mons[0].name : "");

        for (let i = 0; i < mons.length; i++) {
            const m = mons[i];
            const curWs = m.activeWorkspace ? m.activeWorkspace.id : null;
            if (curWs && root.isWorkspaceValidForGroupAndMonitor(curWs, root.activeGroupIndex, i)) {
                if (!root.lastActiveWorkspaces[root.activeGroupIndex])
                    root.lastActiveWorkspaces[root.activeGroupIndex] = {};
                root.lastActiveWorkspaces[root.activeGroupIndex][m.name] = curWs;
            }
        }

        if (!root.lastActiveWorkspaces[g])
            root.lastActiveWorkspaces[g] = {};

        const batchCommands = [];
        for (let i = 0; i < mons.length; i++) {
            const m = mons[i];
            let targetWs = root.lastActiveWorkspaces[g]?.[m.name];
            if (!root.isWorkspaceValidForGroupAndMonitor(targetWs, g, i)) {
                targetWs = calcWorkspace(g, i, 1);
                root.lastActiveWorkspaces[g][m.name] = targetWs;
            }
            if (root.isLua) {
                batchCommands.push(`dispatch hl.dsp.focus({ monitor = '${m.name}' })`);
                batchCommands.push(`dispatch hl.dsp.focus({ workspace = '${targetWs}' })`);
            } else {
                batchCommands.push("dispatch focusmonitor " + m.name);
                batchCommands.push("dispatch workspace " + targetWs);
            }
        }
        if (focusedMonName) {
            if (root.isLua) {
                batchCommands.push(`dispatch hl.dsp.focus({ monitor = '${focusedMonName}' })`);
            } else {
                batchCommands.push("dispatch focusmonitor " + focusedMonName);
            }
        }

        const fullBatch = batchCommands.join("; ");
        Quickshell.execDetached(["hyprctl", "--batch", fullBatch]);

        root.activeGroupIndex = g;
        root.notifyState();
        root.saveStateFile();
        return "SUCCESS";
    }

    function nextGroup() {
        let next = root.activeGroupIndex + 1;
        if (next > root.groups.length)
            next = 1;
        return switchToGroup(next);
    }

    function prevGroup() {
        let prev = root.activeGroupIndex - 1;
        if (prev < 1)
            prev = root.groups.length;
        return switchToGroup(prev);
    }

    function moveWindowToGroup(groupId) {
        const g = parseInt(groupId);
        if (isNaN(g) || g < 1 || g > root.groups.length)
            return "INVALID_GROUP";
        if (g === root.activeGroupIndex)
            return "ALREADY_ACTIVE";

        if (root.overviewOpen || root.createModalOpen || root.contentVisible) {
            root.closeOverview();
        }

        const mons = getSortedMonitors();
        const focusedMon = Hyprland.focusedMonitor;
        const focusedMonName = focusedMon?.name || (mons[0] ? mons[0].name : "");
        const focusedMonIdx = focusedMon ? getMonitorIndex(focusedMon.name) : 0;

        for (let i = 0; i < mons.length; i++) {
            const m = mons[i];
            const curWs = m.activeWorkspace ? m.activeWorkspace.id : null;
            if (curWs && root.isWorkspaceValidForGroupAndMonitor(curWs, root.activeGroupIndex, i)) {
                if (!root.lastActiveWorkspaces[root.activeGroupIndex])
                    root.lastActiveWorkspaces[root.activeGroupIndex] = {};
                root.lastActiveWorkspaces[root.activeGroupIndex][m.name] = curWs;
            }
        }

        if (!root.lastActiveWorkspaces[g])
            root.lastActiveWorkspaces[g] = {};

        for (let i = 0; i < mons.length; i++) {
            const m = mons[i];
            let targetWs = root.lastActiveWorkspaces[g]?.[m.name];
            if (!root.isWorkspaceValidForGroupAndMonitor(targetWs, g, i)) {
                targetWs = calcWorkspace(g, i, 1);
                root.lastActiveWorkspaces[g][m.name] = targetWs;
            }
        }

        const targetWsForFocusedMon = root.lastActiveWorkspaces[g]?.[focusedMonName] || calcWorkspace(g, focusedMonIdx, 1);

        const batchCommands = [];
        if (root.isLua) {
            batchCommands.push(`dispatch hl.dsp.window.move({ workspace = '${targetWsForFocusedMon}', silent = true })`);
        } else {
            batchCommands.push("dispatch movetoworkspacesilent " + targetWsForFocusedMon);
        }

        for (let i = 0; i < mons.length; i++) {
            const m = mons[i];
            const targetWs = root.lastActiveWorkspaces[g][m.name];
            if (root.isLua) {
                batchCommands.push(`dispatch hl.dsp.focus({ monitor = '${m.name}' })`);
                batchCommands.push(`dispatch hl.dsp.focus({ workspace = '${targetWs}' })`);
            } else {
                batchCommands.push("dispatch focusmonitor " + m.name);
                batchCommands.push("dispatch workspace " + targetWs);
            }
        }
        if (focusedMonName) {
            if (root.isLua) {
                batchCommands.push(`dispatch hl.dsp.focus({ monitor = '${focusedMonName}' })`);
            } else {
                batchCommands.push("dispatch focusmonitor " + focusedMonName);
            }
        }

        const fullBatch = batchCommands.join("; ");
        Quickshell.execDetached(["hyprctl", "--batch", fullBatch]);

        root.activeGroupIndex = g;
        root.notifyState();
        root.saveStateFile();
        return "SUCCESS";
    }

    function switchToSubWorkspace(subWsStr, targetMonName) {
        let sub = parseInt(subWsStr);
        if (isNaN(sub))
            return "INVALID_SUB_WORKSPACE";
        if (sub === 0)
            sub = 10;
        if (sub < 1 || sub > root.workspacesPerMonitor)
            return "OUT_OF_RANGE";

        let monName = (targetMonName && targetMonName !== "undefined" && targetMonName !== "null") ? targetMonName : "";
        if (!monName) {
            const focusedMon = Hyprland.focusedMonitor;
            monName = focusedMon ? focusedMon.name : "";
        }
        const monIdx = monName ? getMonitorIndex(monName) : 0;
        const targetWs = calcWorkspace(root.activeGroupIndex, monIdx, sub);
        if (root.isLua) {
            if (monName && monName !== Hyprland.focusedMonitor?.name) {
                Quickshell.execDetached(["hyprctl", "--batch", `dispatch hl.dsp.focus({ monitor = '${monName}' }); dispatch hl.dsp.focus({ workspace = '${targetWs}' })`]);
            } else {
                Quickshell.execDetached(["hyprctl", "dispatch", `hl.dsp.focus({ workspace = '${targetWs}' })`]);
            }
        } else {
            if (monName && monName !== Hyprland.focusedMonitor?.name) {
                Quickshell.execDetached(["hyprctl", "--batch", `dispatch focusmonitor ${monName}; dispatch workspace ${targetWs}`]);
            } else {
                Quickshell.execDetached(["hyprctl", "dispatch", "workspace", targetWs.toString()]);
            }
        }
        return "SUCCESS";
    }

    function moveWindowToSubWorkspace(subWsStr, targetMonName) {
        let sub = parseInt(subWsStr);
        if (isNaN(sub))
            return "INVALID_SUB_WORKSPACE";
        if (sub === 0)
            sub = 10;
        if (sub < 1 || sub > root.workspacesPerMonitor)
            return "OUT_OF_RANGE";

        let monName = (targetMonName && targetMonName !== "undefined" && targetMonName !== "null") ? targetMonName : "";
        if (!monName) {
            const focusedMon = Hyprland.focusedMonitor;
            monName = focusedMon ? focusedMon.name : "";
        }
        const monIdx = monName ? getMonitorIndex(monName) : 0;
        const targetWs = calcWorkspace(root.activeGroupIndex, monIdx, sub);
        if (root.isLua) {
            Quickshell.execDetached(["hyprctl", "dispatch", `hl.dsp.window.move({ workspace = '${targetWs}' })`]);
        } else {
            Quickshell.execDetached(["hyprctl", "dispatch", "movetoworkspace", targetWs.toString()]);
        }
        return "SUCCESS";
    }

    function cycleSubWorkspaces(dir) {
        const focusedWs = Hyprland.focusedWorkspace?.id || 1;
        const curSub = calcSubWorkspaceFromWorkspace(focusedWs);
        let nextSub = curSub + (dir === "next" ? 1 : -1);
        if (nextSub > root.workspacesPerMonitor)
            nextSub = 1;
        if (nextSub < 1)
            nextSub = root.workspacesPerMonitor;
        return switchToSubWorkspace(nextSub);
    }

    function toggleOverview() {
        if (root.overviewOpen && !root.isClosing) {
            return closeOverview();
        } else {
            return openOverview();
        }
    }

    function openOverview() {
        overviewCloseTimer.stop();
        root.isClosing = false;
        root.mouseMovedSinceOpen = false;
        root.lastGlobalMouseX = -1;
        root.lastGlobalMouseY = -1;
        root.overviewOpen = true;
        root.selectedOverviewIndex = Math.max(0, Math.min(root.groups.length - 1, root.activeGroupIndex - 1));
        Qt.callLater(() => {
            root.contentVisible = true;
        });
        return "OVERVIEW_OPEN";
    }

    function closeOverview() {
        if (!root.overviewOpen && !root.createModalOpen && !root.contentVisible)
            return "OVERVIEW_CLOSED";
        if (root.createModalOpen) {
            root.createModalOpen = false;
        }
        if (root.deleteConfirmOpen) {
            root.deleteConfirmOpen = false;
        }
        root.contentVisible = false;
        root.isClosing = true;
        overviewCloseTimer.restart();
        return "OVERVIEW_CLOSED";
    }

    function openCreateGroup() {
        overviewCloseTimer.stop();
        root.isClosing = false;
        root.editingGroupId = 0;
        root.formGroupName = "";
        root.formGroupIcon = getRandomNerdfontIcon();
        root.formGroupColor = getNextGroupColor();
        root.formSwitchImmediate = true;
        root.createModalOpen = true;
        Qt.callLater(() => {
            root.contentVisible = true;
        });
        return "CREATE_MODAL_OPEN";
    }

    function openEditGroup(groupId) {
        const g = parseInt(groupId);
        if (isNaN(g) || g < 1 || g > root.groups.length)
            return "INVALID_GROUP";

        overviewCloseTimer.stop();
        root.isClosing = false;
        root.editingGroupId = g;
        const target = root.groups[g - 1];
        root.formGroupName = target?.name || ("Group " + g);
        root.formGroupIcon = target?.icon || "󰅩";
        root.formGroupColor = target?.color || "#89b4fa";
        root.formSwitchImmediate = false;
        root.createModalOpen = true;
        Qt.callLater(() => {
            root.contentVisible = true;
        });
        return "EDIT_MODAL_OPEN";
    }

    function openEditCurrentGroup() {
        return openEditGroup(root.activeGroupIndex);
    }

    function closeCreateGroup() {
        if (!root.createModalOpen)
            return "MODAL_CLOSED";
        root.createModalOpen = false;
        root.editingGroupId = 0;
        if (!root.overviewOpen) {
            root.contentVisible = false;
            root.isClosing = true;
            overviewCloseTimer.restart();
        }
        return "MODAL_CLOSED";
    }

    function toggleCreateGroup() {
        if (root.createModalOpen)
            return closeCreateGroup();
        return openCreateGroup();
    }

    function updateGroup(groupId, name, icon, color) {
        const g = parseInt(groupId);
        if (isNaN(g) || g < 1 || g > root.groups.length)
            return "INVALID_GROUP";

        const finalName = (name && name.trim()) ? name.trim() : ("Group " + g);
        const finalIcon = (icon && icon.trim()) ? icon.trim() : (root.groups[g - 1].icon || getRandomNerdfontIcon());
        const finalColor = (color && color.trim()) ? color.trim() : (root.groups[g - 1].color || getNextGroupColor());

        const newGroups = [...root.groups];
        newGroups[g - 1] = {
            "id": g,
            "name": finalName,
            "icon": finalIcon,
            "color": finalColor
        };
        root.groups = newGroups;

        root.closeCreateGroup();
        root.notifyState();
        root.writeLuaConfig();
        root.saveStateFile();
        return "SUCCESS";
    }

    function reorderGroup(fromIdx, toIdx) {
        const from = parseInt(fromIdx);
        const to = parseInt(toIdx);
        if (isNaN(from) || isNaN(to) || from < 0 || to < 0 || from >= root.groups.length || to >= root.groups.length)
            return "INVALID_INDICES";
        if (from === to)
            return "NO_OP";

        const monCount = root.getMonitorCount();
        const totalPerGroup = root.workspacesPerMonitor * monCount;

        const newGroups = [...root.groups];
        const [movedGroup] = newGroups.splice(from, 1);
        newGroups.splice(to, 0, movedGroup);

        const mapping = {};
        for (let k = 0; k < newGroups.length; k++) {
            const grp = newGroups[k];
            const oldId = grp.id;
            const newId = k + 1;
            mapping[oldId] = newId;
        }

        const batchCommands = [];
        const allToplevels = Hyprland.toplevels?.values || [];

        if (root.isLua) {
            const activeWorkspacesSet = {};
            const hyprWses = Hyprland.workspaces?.values || [];
            for (let i = 0; i < hyprWses.length; i++) {
                const wid = hyprWses[i]?.id;
                if (wid && wid > 0) activeWorkspacesSet[wid] = true;
            }
            for (let i = 0; i < allToplevels.length; i++) {
                const wid = allToplevels[i]?.workspace?.id ?? allToplevels[i]?.lastIpcObject?.workspace?.id;
                if (wid && wid > 0) activeWorkspacesSet[wid] = true;
            }
            const hyprMons = Hyprland.monitors?.values || [];
            for (let i = 0; i < hyprMons.length; i++) {
                const wid = hyprMons[i]?.activeWorkspace?.id;
                if (wid && wid > 0) activeWorkspacesSet[wid] = true;
            }

            const workspacesToMigrate = [];
            for (const wsIdStr in activeWorkspacesSet) {
                const wsId = parseInt(wsIdStr);
                const oldG = rawGroupFromWorkspace(wsId);
                const newG = mapping[oldG];
                if (newG !== undefined && newG !== oldG) {
                    const offset = (wsId - 1) % totalPerGroup;
                    const targetWs = (newG - 1) * totalPerGroup + 1 + offset;
                    workspacesToMigrate.push({ oldWs: wsId, targetWs: targetWs });
                }
            }

            for (let i = 0; i < workspacesToMigrate.length; i++) {
                const item = workspacesToMigrate[i];
                const tempId = item.oldWs + 100000;
                batchCommands.push(`dispatch hl.dsp.workspace.change_id({ workspace = '${item.oldWs}', id = ${tempId} })`);
            }
            for (let i = 0; i < workspacesToMigrate.length; i++) {
                const item = workspacesToMigrate[i];
                const tempId = item.oldWs + 100000;
                batchCommands.push(`dispatch hl.dsp.workspace.change_id({ workspace = '${tempId}', id = ${item.targetWs} })`);
            }
        } else {
            for (let i = 0; i < allToplevels.length; i++) {
                const top = allToplevels[i];
                if (!top) continue;
                const wsId = top.workspace?.id ?? top.lastIpcObject?.workspace?.id;
                const rawAddr = top.lastIpcObject?.address || top.address;
                const addr = root.formatWindowAddress(rawAddr);
                if (!addr || wsId === undefined || wsId < 1) continue;

                const oldG = rawGroupFromWorkspace(wsId);
                const newG = mapping[oldG];
                if (newG !== undefined && newG !== oldG) {
                    const offset = (wsId - 1) % totalPerGroup;
                    const targetWs = (newG - 1) * totalPerGroup + 1 + offset;
                    batchCommands.push(`dispatch movetoworkspacesilent ${targetWs},address:${addr}`);
                }
            }
        }

        const oldLastActive = root.lastActiveWorkspaces || {};
        const newLastActive = {};
        const sortedMons = getSortedMonitors();
        for (let newG = 1; newG <= root.groups.length; newG++) {
            newLastActive[newG] = {};
        }
        for (const oldGStr in oldLastActive) {
            const oldG = parseInt(oldGStr);
            const newG = mapping[oldG] || oldG;
            if (!newLastActive[newG]) newLastActive[newG] = {};
            const monMap = oldLastActive[oldGStr];
            if (monMap && typeof monMap === "object") {
                for (let i = 0; i < sortedMons.length; i++) {
                    const monName = sortedMons[i].name;
                    const oldWs = monMap[monName];
                    if (oldWs && root.isWorkspaceValidForGroupAndMonitor(oldWs, oldG, i)) {
                        const offset = (oldWs - 1) % totalPerGroup;
                        newLastActive[newG][monName] = (newG - 1) * totalPerGroup + 1 + offset;
                    } else {
                        newLastActive[newG][monName] = calcWorkspace(newG, i, 1);
                    }
                }
            }
        }
        for (let gNum = 1; gNum <= root.groups.length; gNum++) {
            if (!newLastActive[gNum]) newLastActive[gNum] = {};
            for (let i = 0; i < sortedMons.length; i++) {
                const monName = sortedMons[i].name;
                if (!root.isWorkspaceValidForGroupAndMonitor(newLastActive[gNum][monName], gNum, i)) {
                    newLastActive[gNum][monName] = calcWorkspace(gNum, i, 1);
                }
            }
        }
        root.lastActiveWorkspaces = newLastActive;

        const oldActive = root.activeGroupIndex;
        const newActive = mapping[oldActive] || oldActive;
        root.activeGroupIndex = newActive;

        if (newActive !== oldActive) {
            const mons = getSortedMonitors();
            const focusedMonName = Hyprland.focusedMonitor?.name || (mons[0] ? mons[0].name : "");
            for (let i = 0; i < mons.length; i++) {
                const m = mons[i];
                let targetWs = root.lastActiveWorkspaces[newActive]?.[m.name];
                if (!root.isWorkspaceValidForGroupAndMonitor(targetWs, newActive, i)) {
                    targetWs = calcWorkspace(newActive, i, 1);
                }
                if (root.isLua) {
                    batchCommands.push(`dispatch hl.dsp.focus({ monitor = '${m.name}' })`);
                    batchCommands.push(`dispatch hl.dsp.focus({ workspace = '${targetWs}' })`);
                } else {
                    batchCommands.push("dispatch focusmonitor " + m.name);
                    batchCommands.push("dispatch workspace " + targetWs);
                }
            }
            if (focusedMonName) {
                if (root.isLua) {
                    batchCommands.push(`dispatch hl.dsp.focus({ monitor = '${focusedMonName}' })`);
                } else {
                    batchCommands.push("dispatch focusmonitor " + focusedMonName);
                }
            }
        }

        if (batchCommands.length > 0) {
            Quickshell.execDetached(["hyprctl", "--batch", batchCommands.join("; ")]);
        }

        root.groups = newGroups.map((g, idx) => ({
            "id": idx + 1,
            "name": g.name,
            "icon": g.icon,
            "color": g.color
        }));

        root.notifyState();
        root.writeLuaConfig();
        root.saveStateFile();
        return "SUCCESS";
    }

    function createGroup(name, icon, color, shouldSwitch) {
        const newId = root.groups.length + 1;
        const finalName = (name && name.trim()) ? name.trim() : ("Group " + newId);
        const finalIcon = (icon && icon.trim()) ? icon.trim() : getRandomNerdfontIcon();
        const finalColor = (color && color.trim()) ? color.trim() : getNextGroupColor();

        const newGroup = {
            "id": newId,
            "name": finalName,
            "icon": finalIcon,
            "color": finalColor
        };

        root.groups = [...root.groups, newGroup];
        if (!root.lastActiveWorkspaces[newId])
            root.lastActiveWorkspaces[newId] = {};
        const sortedMons = getSortedMonitors();
        for (let i = 0; i < sortedMons.length; i++) {
            root.lastActiveWorkspaces[newId][sortedMons[i].name] = calcWorkspace(newId, i, 1);
        }
        root.notifyState();
        root.writeLuaConfig();
        root.saveStateFile();

        if (shouldSwitch !== false) {
            root.closeOverview();
            Qt.callLater(() => {
                root.switchToGroup(newId);
            });
        } else {
            root.closeCreateGroup();
        }
        return "SUCCESS";
    }

    function getWindowsInGroup(groupId) {
        const allToplevels = Hyprland.toplevels?.values || [];
        const list = [];
        const monCount = root.getMonitorCount();
        const totalPerGroup = root.workspacesPerMonitor * monCount;
        const startWs = (groupId - 1) * totalPerGroup + 1;
        const endWs = groupId * totalPerGroup;

        for (let i = 0; i < allToplevels.length; i++) {
            const top = allToplevels[i];
            if (!top) continue;
            const wsId = top.workspace?.id ?? top.lastIpcObject?.workspace?.id;
            if (wsId !== undefined && wsId >= startWs && wsId <= endWs) {
                list.push(top);
            }
        }
        return list;
    }

    function deleteGroup(groupId) {
        const g = parseInt(groupId);
        if (isNaN(g) || g < 1 || g > root.groups.length)
            return "INVALID_GROUP";
        if (root.groups.length <= 1)
            return "CANNOT_DELETE_LAST_GROUP";

        const monCount = root.getMonitorCount();
        const totalPerGroup = root.workspacesPerMonitor * monCount;
        const startWs = (g - 1) * totalPerGroup + 1;
        const endWs = g * totalPerGroup;

        const sortedMons = getSortedMonitors();
        const focusedMon = Hyprland.focusedMonitor;
        const focusedMonName = focusedMon?.name || (sortedMons[0] ? sortedMons[0].name : "");
        const oldActive = root.activeGroupIndex;

        for (let i = 0; i < sortedMons.length; i++) {
            const m = sortedMons[i];
            const curWs = m.activeWorkspace ? m.activeWorkspace.id : null;
            if (curWs && root.isWorkspaceValidForGroupAndMonitor(curWs, oldActive, i)) {
                if (!root.lastActiveWorkspaces[oldActive])
                    root.lastActiveWorkspaces[oldActive] = {};
                root.lastActiveWorkspaces[oldActive][m.name] = curWs;
            }
        }

        const newGroups = [];
        for (let i = 0; i < root.groups.length; i++) {
            const grp = root.groups[i];
            if (grp.id === g) continue;
            const newId = newGroups.length + 1;
            newGroups.push({
                "id": newId,
                "name": grp.name,
                "icon": grp.icon,
                "color": grp.color
            });
        }

        let newActive = oldActive;
        if (oldActive === g) {
            newActive = Math.max(1, Math.min(g, newGroups.length));
        } else if (oldActive > g) {
            newActive = oldActive - 1;
        }

        delete root.lastActiveWorkspaces[g];
        const newLastActive = {};
        for (const k in root.lastActiveWorkspaces) {
            const numK = parseInt(k);
            if (numK < g) {
                newLastActive[numK] = root.lastActiveWorkspaces[k];
            } else if (numK > g) {
                const shiftedG = numK - 1;
                newLastActive[shiftedG] = {};
                const monMap = root.lastActiveWorkspaces[k];
                if (monMap && typeof monMap === "object") {
                    for (let i = 0; i < sortedMons.length; i++) {
                        const mName = sortedMons[i].name;
                        const oldWs = monMap[mName];
                        if (oldWs && root.isWorkspaceValidForGroupAndMonitor(oldWs, numK, i)) {
                            newLastActive[shiftedG][mName] = oldWs - totalPerGroup;
                        } else {
                            newLastActive[shiftedG][mName] = calcWorkspace(shiftedG, i, 1);
                        }
                    }
                }
            }
        }

        const allToplevels = Hyprland.toplevels?.values || [];
        const batchCommands = [];

        const activeWorkspacesSet = {};
        const hyprWses = Hyprland.workspaces?.values || [];
        for (let i = 0; i < hyprWses.length; i++) {
            const wid = hyprWses[i]?.id;
            if (wid && wid > 0) activeWorkspacesSet[wid] = true;
        }
        for (let i = 0; i < allToplevels.length; i++) {
            const wid = allToplevels[i]?.workspace?.id ?? allToplevels[i]?.lastIpcObject?.workspace?.id;
            if (wid && wid > 0) activeWorkspacesSet[wid] = true;
        }

        const groupGWsWithWindows = {};
        for (let i = 0; i < allToplevels.length; i++) {
            const top = allToplevels[i];
            if (!top) continue;
            const wid = top.workspace?.id ?? top.lastIpcObject?.workspace?.id;
            if (wid !== undefined && wid >= startWs && wid <= endWs) {
                groupGWsWithWindows[wid] = true;
            }
        }

        const evacuateTargetGroup = (g === 1) ? 2 : 1;

        if (root.isLua) {
            const evacuatedWorkspacesRenamed = {};
            for (const wsIdStr in groupGWsWithWindows) {
                const wsId = parseInt(wsIdStr);
                const withinGroup = (wsId - 1) % totalPerGroup;
                const targetWs = (evacuateTargetGroup - 1) * totalPerGroup + 1 + withinGroup;
                if (g > 1 && !activeWorkspacesSet[targetWs]) {
                    batchCommands.push(`dispatch hl.dsp.workspace.change_id({ workspace = '${wsId}', id = ${targetWs} })`);
                    evacuatedWorkspacesRenamed[wsId] = true;
                    activeWorkspacesSet[targetWs] = true;
                }
            }

            for (let i = 0; i < allToplevels.length; i++) {
                const top = allToplevels[i];
                if (!top) continue;
                const wsId = top.workspace?.id ?? top.lastIpcObject?.workspace?.id;
                const rawAddr = top.lastIpcObject?.address || top.address;
                const addr = root.formatWindowAddress(rawAddr);
                if (!addr || wsId === undefined) continue;

                if (wsId >= startWs && wsId <= endWs) {
                    if (!evacuatedWorkspacesRenamed[wsId]) {
                        const withinGroup = (wsId - 1) % totalPerGroup;
                        const targetWs = (evacuateTargetGroup - 1) * totalPerGroup + 1 + withinGroup;
                        batchCommands.push(`dispatch hl.dsp.window.move({ workspace = '${targetWs}', silent = true, window = 'address:${addr}' })`);
                    }
                }
            }

            const higherWsList = [];
            for (const wsIdStr in activeWorkspacesSet) {
                const wsId = parseInt(wsIdStr);
                if (wsId > endWs) {
                    higherWsList.push(wsId);
                }
            }
            higherWsList.sort((a, b) => a - b);
            for (let i = 0; i < higherWsList.length; i++) {
                const wsId = higherWsList[i];
                const shiftedWs = wsId - totalPerGroup;
                batchCommands.push(`dispatch hl.dsp.workspace.change_id({ workspace = '${wsId}', id = ${shiftedWs} })`);
            }
        } else {
            for (let i = 0; i < allToplevels.length; i++) {
                const top = allToplevels[i];
                if (!top) continue;
                const wsId = top.workspace?.id ?? top.lastIpcObject?.workspace?.id;
                const rawAddr = top.lastIpcObject?.address || top.address;
                const addr = root.formatWindowAddress(rawAddr);
                if (!addr || wsId === undefined) continue;

                if (wsId >= startWs && wsId <= endWs) {
                    const withinGroup = (wsId - 1) % totalPerGroup;
                    const targetWs = (evacuateTargetGroup - 1) * totalPerGroup + 1 + withinGroup;
                    batchCommands.push(`dispatch movetoworkspacesilent ${targetWs},address:${addr}`);
                } else if (wsId > endWs) {
                    const shiftedWs = wsId - totalPerGroup;
                    batchCommands.push(`dispatch movetoworkspacesilent ${shiftedWs},address:${addr}`);
                }
            }
        }

        for (let i = 0; i < sortedMons.length; i++) {
            const m = sortedMons[i];
            let targetWs = newLastActive[newActive]?.[m.name];
            if (!root.isWorkspaceValidForGroupAndMonitor(targetWs, newActive, i)) {
                targetWs = calcWorkspace(newActive, i, 1);
                if (!newLastActive[newActive]) newLastActive[newActive] = {};
                newLastActive[newActive][m.name] = targetWs;
            }
            if (root.isLua) {
                batchCommands.push(`dispatch hl.dsp.focus({ monitor = '${m.name}' })`);
                batchCommands.push(`dispatch hl.dsp.focus({ workspace = '${targetWs}' })`);
            } else {
                batchCommands.push("dispatch focusmonitor " + m.name);
                batchCommands.push("dispatch workspace " + targetWs);
            }
        }
        if (focusedMonName) {
            if (root.isLua) {
                batchCommands.push(`dispatch hl.dsp.focus({ monitor = '${focusedMonName}' })`);
            } else {
                batchCommands.push("dispatch focusmonitor " + focusedMonName);
            }
        }

        if (batchCommands.length > 0) {
            Quickshell.execDetached(["hyprctl", "--batch", batchCommands.join("; ")]);
        }

        root.activeGroupIndex = newActive;
        root.groups = newGroups;
        root.lastActiveWorkspaces = newLastActive;
        root.sanitizeLastActiveWorkspaces();
        if (root.selectedOverviewIndex >= newGroups.length) {
            root.selectedOverviewIndex = Math.max(0, newGroups.length - 1);
        }

        root.notifyState();
        root.writeLuaConfig();
        root.saveStateFile();
        return "SUCCESS";
    }

    function deleteCurrentGroup() {
        return deleteGroup(root.activeGroupIndex);
    }

    function confirmDeleteGroup(groupId) {
        const g = parseInt(groupId);
        if (isNaN(g) || g < 1 || g > root.groups.length || root.groups.length <= 1)
            return;
        const grp = root.groups[g - 1];
        const wins = getWindowsInGroup(g);
        if (wins.length === 0) {
            deleteGroup(g);
        } else {
            root.groupToDeleteId = g;
            root.groupToDeleteName = grp?.name || ("Group " + g);
            root.groupToDeleteWindowCount = wins.length;
            root.deleteConfirmOpen = true;
        }
    }

    function resetToOnLaunchGroups() {
        root.groups = JSON.parse(JSON.stringify(root.onLaunchGroups));
        root.sanitizeLastActiveWorkspaces();
        root.ensureGroupsCoverAllWorkspaces();
        if (root.activeGroupIndex > root.groups.length) {
            root.switchToGroup(1);
        }
        root.notifyState();
        root.writeLuaConfig();
        root.saveStateFile();
        return "SUCCESS";
    }

    function getActiveGroup() {
        return JSON.stringify({
            "index": root.activeGroupIndex,
            "group": root.groups[root.activeGroupIndex - 1] || null
        });
    }

    function getGroups() {
        return JSON.stringify(root.groups);
    }

    function writeLuaConfig(callback) {
        const groupsLua = root.groups.map(g => {
            const escapedName = (g.name || "").replace(/"/g, '\\"');
            const escapedIcon = (g.icon || "").replace(/"/g, '\\"');
            const color = g.color || "#89b4fa";
            return `    { id = ${g.id}, name = "${escapedName}", icon = "${escapedIcon}", color = "${color}" },`;
        }).join("\n");

        const priorityLua = root.monitorPriority.map(p => `"${p}"`).join(", ");

        const luaContent = `-- Auto-generated by DMS Workspace Groups Plugin
-- DO NOT EDIT DIRECTLY: Changes will be overwritten when plugin settings change.

local M = {}

M.groups = {
${groupsLua}
}

M.workspaces_per_monitor = ${root.workspacesPerMonitor}
M.monitor_priority = { ${priorityLua} }

local function dms_ipc(target, func, ...)
  local args = { ... }
  local cmd = "dms ipc call " .. target .. " " .. func
  for _, a in ipairs(args) do
    cmd = cmd .. " " .. tostring(a)
  end
  hl.exec_cmd(cmd)
end

function M.switch_group(group_id)
  return function()
    dms_ipc("workspaceGroups", "switchToGroup", group_id)
  end
end

function M.move_to_group(group_id)
  return function()
    dms_ipc("workspaceGroups", "moveWindowToGroup", group_id)
  end
end

function M.cycle_groups(direction)
  return function()
    if direction == "next" then
      dms_ipc("workspaceGroups", "nextGroup")
    else
      dms_ipc("workspaceGroups", "prevGroup")
    end
  end
end

function M.toggle_overview()
  return function()
    dms_ipc("workspaceGroups", "toggleOverview")
  end
end

function M.open_create_group()
  return function()
    dms_ipc("workspaceGroups", "openCreateGroup")
  end
end

function M.open_edit_current_group()
  return function()
    dms_ipc("workspaceGroups", "openEditCurrentGroup")
  end
end

function M.delete_current_group()
  return function()
    dms_ipc("workspaceGroups", "deleteCurrentGroup")
  end
end

function M.workspace(sub_ws_str)
  return function()
    dms_ipc("workspaceGroups", "switchToSubWorkspace", sub_ws_str)
  end
end

function M.move_to_workspace(sub_ws_str)
  return function()
    dms_ipc("workspaceGroups", "moveWindowToSubWorkspace", sub_ws_str)
  end
end

function M.cycle_workspaces(direction)
  return function()
    dms_ipc("workspaceGroups", "cycleSubWorkspaces", direction)
  end
end

function M.setup(opts)
  opts = opts or {}
  local mainMod = opts.mainMod or "SUPER"

  -- Toggle Overview
  hl.bind(mainMod .. " + Tab", M.toggle_overview())

  -- Create / Manage Groups Modal
  hl.bind(mainMod .. " + ALT + Tab", M.open_create_group())
  hl.bind(mainMod .. " + ALT + N", M.open_create_group())

  -- Edit Current Group Modal
  hl.bind(mainMod .. " + ALT + E", M.open_edit_current_group())

  -- Group direct switch & move (1..9, and 0 for group 10)
  for _, g in ipairs(M.groups) do
    if g.id <= 10 then
      local n = (g.id == 10) and "0" or tostring(g.id)
      hl.bind(mainMod .. " + ALT + " .. n, M.switch_group(g.id))
      hl.bind(mainMod .. " + ALT + SHIFT + " .. n, M.move_to_group(g.id))
    end
  end

  -- Group cycling
  hl.bind(mainMod .. " + ALT + Right", M.cycle_groups("next"))
  hl.bind(mainMod .. " + ALT + Left", M.cycle_groups("prev"))
  hl.bind(mainMod .. " + ALT + L", M.cycle_groups("next"))
  hl.bind(mainMod .. " + ALT + H", M.cycle_groups("prev"))

  -- Sub-workspaces 1..10 within active group
  for i = 1, 10 do
    local n = (i == 10) and "0" or tostring(i)
    hl.bind(mainMod .. " + " .. n, M.workspace(tostring(i)))
    hl.bind(mainMod .. " + SHIFT + " .. n, M.move_to_workspace(tostring(i)))
  end

  -- Cycle sub-workspaces
  hl.bind(mainMod .. " + mouse_down", M.cycle_workspaces("next"))
  hl.bind(mainMod .. " + mouse_up", M.cycle_workspaces("prev"))
  hl.bind(mainMod .. " + CTRL + mouse_down", M.move_to_workspace("+1"))
  hl.bind(mainMod .. " + CTRL + mouse_up", M.move_to_workspace("-1"))
end

return M
`;

        const tmpFile = luaConfigPath + ".tmp." + Date.now();
        Proc.runCommand("save-workspace-groups-lua", ["sh", "-c", `mkdir -p "${hyprDmsDir}" && cat << 'EOF' > "${tmpFile}"\n${luaContent}\nEOF\nmv -f "${tmpFile}" "${luaConfigPath}"\n`], (output, exitCode) => {
            if (exitCode !== 0) {
                console.warn("[WorkspaceGroups] Failed to write Lua config:", output);
            } else {
                Quickshell.execDetached(["hyprctl", "reload"]);
                if (typeof callback === "function") {
                    callback();
                }
            }
        });
    }

    IpcHandler {
        target: "workspaceGroups"

        function saveState(): string {
            root.saveStateFile();
            return "OK";
        }

        function recoverOrphanGroups(): string {
            const added = root.ensureGroupsCoverAllWorkspaces();
            return added ? "RECOVERED" : "NO_ORPHANS";
        }

        function writeLuaConfig(): string {
            root.writeLuaConfig();
            return "OK";
        }

        function switchToGroup(groupId: string): string {
            return root.switchToGroup(groupId);
        }

        function nextGroup(): string {
            return root.nextGroup();
        }

        function prevGroup(): string {
            return root.prevGroup();
        }

        function moveWindowToGroup(groupId: string): string {
            return root.moveWindowToGroup(groupId);
        }

        function switchToSubWorkspace(subWs: string): string {
            return root.switchToSubWorkspace(subWs);
        }

        function switchToSubWorkspaceOnMonitor(subWs: string, targetMon: string): string {
            return root.switchToSubWorkspace(subWs, targetMon);
        }

        function moveWindowToSubWorkspace(subWs: string): string {
            return root.moveWindowToSubWorkspace(subWs);
        }

        function moveWindowToSubWorkspaceOnMonitor(subWs: string, targetMon: string): string {
            return root.moveWindowToSubWorkspace(subWs, targetMon);
        }

        function cycleSubWorkspaces(dir: string): string {
            return root.cycleSubWorkspaces(dir);
        }

        function toggleOverview(): string {
            return root.toggleOverview();
        }

        function openOverview(): string {
            return root.openOverview();
        }

        function closeOverview(): string {
            return root.closeOverview();
        }

        function openCreateGroup(): string {
            return root.openCreateGroup();
        }

        function closeCreateGroup(): string {
            return root.closeCreateGroup();
        }

        function toggleCreateGroup(): string {
            return root.toggleCreateGroup();
        }

        function createGroup(name: string, icon: string, color: string): string {
            return root.createGroup(name, icon, color, true);
        }

        function deleteGroup(groupId: string): string {
            return root.deleteGroup(groupId);
        }

        function deleteCurrentGroup(): string {
            return root.deleteCurrentGroup();
        }

        function resetToOnLaunchGroups(): string {
            return root.resetToOnLaunchGroups();
        }

        function openEditGroup(groupId: string): string {
            return root.openEditGroup(groupId);
        }

        function openEditCurrentGroup(): string {
            return root.openEditCurrentGroup();
        }

        function updateGroup(groupId: string, name: string, icon: string, color: string): string {
            return root.updateGroup(groupId, name, icon, color);
        }

        function reorderGroup(fromIdx: string, toIdx: string): string {
            return root.reorderGroup(fromIdx, toIdx);
        }

        function getActiveGroup(): string {
            return root.getActiveGroup();
        }

        function getGroups(): string {
            return root.getGroups();
        }
    }

    Scope {
        id: overviewScope

        Loader {
            id: overviewLoader
            active: root.overviewOpen || root.createModalOpen || root.isClosing
            asynchronous: false

            sourceComponent: Variants {
                model: Quickshell.screens

                PanelWindow {
                    id: overviewWindow
                    required property var modelData

                    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(overviewWindow.screen)
                    property bool monitorIsFocused: (Hyprland.focusedMonitor?.id == monitor?.id)

                    screen: modelData
                    visible: root.overviewOpen || root.createModalOpen || root.isClosing
                    color: "transparent"

                    WlrLayershell.namespace: "dms:workspace-groups-overview"
                    WlrLayershell.layer: WlrLayer.Overlay
                    WlrLayershell.exclusiveZone: -1
                    WlrLayershell.keyboardFocus: CompositorService.useHyprlandFocusGrab ? WlrKeyboardFocus.OnDemand : (root.contentVisible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None)

                    anchors {
                        top: true
                        left: true
                        right: true
                        bottom: true
                    }

                    HyprlandFocusGrab {
                        id: grab
                        windows: [overviewWindow]
                        active: false
                        property bool hasBeenActivated: false

                        onActiveChanged: {
                            if (active) hasBeenActivated = true;
                        }
                        onCleared: () => {
                            if (hasBeenActivated && !root.isClosing) {
                                if (root.overviewOpen) {
                                    root.closeOverview();
                                } else if (root.createModalOpen) {
                                    root.closeCreateGroup();
                                }
                            }
                        }
                    }

                    Connections {
                        target: root
                        function onContentVisibleChanged() {
                            if (root.contentVisible) {
                                grab.hasBeenActivated = false;
                                if (CompositorService.useHyprlandFocusGrab) {
                                    delayedGrabTimer.start();
                                }
                                Qt.callLater(() => {
                                    if (root.createModalOpen) {
                                        createNameInput.forceActiveFocus();
                                    } else {
                                        focusScope.forceActiveFocus();
                                        if (overviewFlickable && overviewFlickable.height > 0) {
                                            overviewFlickable.ensureVisible(root.selectedOverviewIndex);
                                        }
                                    }
                                });
                            } else {
                                delayedGrabTimer.stop();
                                grab.active = false;
                                grab.hasBeenActivated = false;
                                if (overviewFlickable) {
                                    overviewFlickable.contentY = 0;
                                }
                            }
                        }
                        function onSelectedOverviewIndexChanged() {
                            if (root.contentVisible && overviewFlickable) {
                                overviewFlickable.ensureVisible(root.selectedOverviewIndex);
                            }
                        }
                        function onCreateModalOpenChanged() {
                            if (root.contentVisible) {
                                if (root.createModalOpen) {
                                    Qt.callLater(() => createNameInput.forceActiveFocus());
                                } else if (root.overviewOpen) {
                                    Qt.callLater(() => focusScope.forceActiveFocus());
                                }
                            }
                        }
                        function onDeleteConfirmOpenChanged() {
                            if (root.contentVisible) {
                                if (root.deleteConfirmOpen) {
                                    Qt.callLater(() => deleteConfirmContainer.forceActiveFocus());
                                } else if (root.overviewOpen) {
                                    Qt.callLater(() => focusScope.forceActiveFocus());
                                }
                            }
                        }
                    }

                    Connections {
                        target: overviewWindow
                        function onActiveFocusItemChanged() {
                            if (root.contentVisible && !overviewWindow.activeFocusItem) {
                                if (root.createModalOpen) {
                                    createNameInput.forceActiveFocus();
                                } else if (root.deleteConfirmOpen) {
                                    deleteConfirmContainer.forceActiveFocus();
                                } else {
                                    focusScope.forceActiveFocus();
                                }
                            }
                        }
                        function onMonitorIsFocusedChanged() {
                            if (!CompositorService.useHyprlandFocusGrab)
                                return;
                            if (root.contentVisible && overviewWindow.monitorIsFocused && !grab.active) {
                                grab.hasBeenActivated = false;
                                grab.active = true;
                            } else if (root.contentVisible && !overviewWindow.monitorIsFocused && grab.active) {
                                grab.active = false;
                            }
                        }
                    }

                    Timer {
                        id: delayedGrabTimer
                        interval: 120
                        repeat: false
                        onTriggered: {
                            if (CompositorService.useHyprlandFocusGrab && root.contentVisible && overviewWindow.monitorIsFocused) {
                                grab.active = true;
                            }
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: "black"
                        opacity: root.contentVisible ? (SettingsData.modalDarkenBackground ? 0.5 : 0.35) : 0
                        visible: opacity > 0 || root.contentVisible

                        Behavior on opacity {
                            NumberAnimation {
                                duration: Theme.modalAnimationDuration
                                easing.type: Easing.BezierSpline
                                easing.bezierCurve: root.contentVisible ? Theme.expressiveCurves.expressiveDefaultSpatial : Theme.expressiveCurves.emphasized
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: root.contentVisible
                            onClicked: {
                                if (root.createModalOpen) {
                                    root.closeCreateGroup();
                                } else if (root.deleteConfirmOpen) {
                                    root.deleteConfirmOpen = false;
                                } else {
                                    root.closeOverview();
                                }
                            }
                        }
                    }

                    Item {
                        id: overviewModalContainer
                        anchors.centerIn: parent
                        width: Math.min(parent.width - 60, Math.max(760, root.gridColumns * 360 + (root.gridColumns - 1) * Theme.spacingM + Theme.spacingXL * 2))
                        height: Math.min(parent.height - 60, root.gridRows <= 1 ? 400 : (root.gridRows === 2 ? 650 : Math.min(880, parent.height - 60)))
                        transformOrigin: Item.Center
                        visible: root.overviewOpen && !root.createModalOpen && !root.deleteConfirmOpen

                        opacity: root.contentVisible && visible ? 1 : 0
                        scale: root.contentVisible && visible ? 1.0 : 0.96

                        Behavior on opacity {
                            NumberAnimation {
                                duration: Theme.modalAnimationDuration
                                easing.type: Easing.BezierSpline
                                easing.bezierCurve: root.contentVisible ? Theme.expressiveCurves.expressiveDefaultSpatial : Theme.expressiveCurves.emphasized
                            }
                        }

                        Behavior on scale {
                            NumberAnimation {
                                duration: Theme.modalAnimationDuration
                                easing.type: Easing.BezierSpline
                                easing.bezierCurve: root.contentVisible ? Theme.expressiveCurves.expressiveDefaultSpatial : Theme.expressiveCurves.emphasized
                            }
                        }

                        ElevationShadow {
                            anchors.fill: parent
                            level: Theme.elevationLevel3
                            targetRadius: Theme.cornerRadius * 1.5
                            targetColor: Theme.surfaceContainer
                            shadowEnabled: Theme.elevationEnabled && SettingsData.modalElevationEnabled
                        }

                        Rectangle {
                            anchors.fill: parent
                            color: Theme.surfaceContainer
                            radius: Theme.cornerRadius * 1.5
                            border.color: Theme.outlineVariant
                            border.width: 1
                            clip: true

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: Theme.spacingXL
                                spacing: Theme.spacingM

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: Theme.spacingXS

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: Theme.spacingM

                                        StyledText {
                                            text: "Workspace Groups"
                                            font.pixelSize: Theme.fontSizeLarge + 4
                                            font.weight: Font.Bold
                                            color: Theme.surfaceText
                                        }

                                        Item { Layout.fillWidth: true }

                                        DankButton {
                                            text: "New Group"
                                            iconName: "add"
                                            buttonHeight: 32
                                            horizontalPadding: Theme.spacingM
                                            iconSize: 15
                                            onClicked: root.openCreateGroup()
                                        }
                                    }

                                    StyledText {
                                        Layout.fillWidth: true
                                        text: "Press [1-9, 0] to switch • [H/J/K/L] / Arrows to move • [E] Edit"
                                        font.pixelSize: Theme.fontSizeSmall
                                        color: Theme.surfaceVariantText
                                        elide: Text.ElideRight
                                    }

                                    StyledText {
                                        Layout.fillWidth: true
                                        text: "[Shift+H/L] Reorder (or Drag & Drop) • [N] Add • [Del] Delete • Esc to close"
                                        font.pixelSize: Theme.fontSizeSmall
                                        color: Theme.surfaceVariantText
                                        elide: Text.ElideRight
                                    }
                                }

                                Flickable {
                                    id: overviewFlickable
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    clip: true
                                    contentWidth: width
                                    contentHeight: groupGrid.height + 16
                                    boundsBehavior: Flickable.StopAtBounds

                                    Behavior on contentY {
                                        enabled: !overviewFlickable.moving && !overviewFlickable.flicking && root.contentVisible
                                        NumberAnimation {
                                            duration: 180
                                            easing.type: Easing.OutCubic
                                        }
                                    }

                                    onHeightChanged: {
                                        const maxScroll = Math.max(0, contentHeight - height);
                                        if (contentY > maxScroll) {
                                            contentY = maxScroll;
                                        }
                                        if (height > 0 && contentHeight > 0 && root.contentVisible) {
                                            ensureVisible(root.selectedOverviewIndex);
                                        }
                                    }

                                    onContentHeightChanged: {
                                        const maxScroll = Math.max(0, contentHeight - height);
                                        if (contentY > maxScroll) {
                                            contentY = maxScroll;
                                        }
                                        if (height > 0 && contentHeight > 0 && root.contentVisible) {
                                            ensureVisible(root.selectedOverviewIndex);
                                        }
                                    }

                                    function ensureVisible(idx) {
                                        if (idx < 0 || idx >= root.totalOverviewItems)
                                            return;
                                        if (overviewFlickable.height <= 0 || overviewFlickable.contentHeight <= 0)
                                            return;

                                        const maxScroll = Math.max(0, overviewFlickable.contentHeight - overviewFlickable.height);
                                        if (maxScroll === 0) {
                                            if (overviewFlickable.contentY !== 0) {
                                                overviewFlickable.contentY = 0;
                                            }
                                            return;
                                        }

                                        const cols = root.gridColumns;
                                        const row = Math.floor(idx / cols);
                                        const cardY = groupGrid.y + row * (groupGrid.cardHeight + groupGrid.rowSpacing);
                                        const cardBottom = cardY + groupGrid.cardHeight;
                                        const pad = 10;

                                        const targetTop = Math.max(0, cardY - pad);
                                        const targetBottom = cardBottom + pad;

                                        if (cardY - pad < overviewFlickable.contentY) {
                                            overviewFlickable.contentY = Math.max(0, Math.min(maxScroll, targetTop));
                                            overviewScrollBar._scrollBarActive = true;
                                            overviewScrollBar.hideTimer.restart();
                                        } else if (cardBottom + pad > overviewFlickable.contentY + overviewFlickable.height) {
                                            overviewFlickable.contentY = Math.max(0, Math.min(maxScroll, targetBottom - overviewFlickable.height));
                                            overviewScrollBar._scrollBarActive = true;
                                            overviewScrollBar.hideTimer.restart();
                                        }
                                    }

                                    ScrollBar.vertical: DankScrollbar {
                                        id: overviewScrollBar
                                    }

                                    WheelHandler {
                                        target: overviewFlickable
                                        onWheel: event => {
                                            const step = 80;
                                            if (event.angleDelta.y > 0) {
                                                overviewFlickable.contentY = Math.max(0, overviewFlickable.contentY - step);
                                            } else if (event.angleDelta.y < 0) {
                                                overviewFlickable.contentY = Math.min(Math.max(0, overviewFlickable.contentHeight - overviewFlickable.height), overviewFlickable.contentY + step);
                                            }
                                            overviewScrollBar._scrollBarActive = true;
                                            overviewScrollBar.hideTimer.restart();
                                        }
                                    }

                                    Grid {
                                        id: groupGrid
                                        x: 4
                                        y: 4
                                        width: overviewFlickable.width - 18
                                        columns: root.gridColumns
                                        columnSpacing: Theme.spacingM
                                        rowSpacing: Theme.spacingM

                                        readonly property real cardWidth: Math.max(200, Math.floor((width - (columns - 1) * columnSpacing) / columns))
                                        readonly property real cardHeight: 240

                                        Repeater {
                                            model: root.totalOverviewItems

                                            Rectangle {
                                                id: overviewCard
                                                width: groupGrid.cardWidth
                                                height: groupGrid.cardHeight
                                                radius: Theme.cornerRadius
                                                clip: true
                                                z: (isCurrentActive || isSelected || isDropTarget) ? 3 : 1

                                                readonly property int cardIndex: index
                                                readonly property bool isAddCard: index === (root.groups ? root.groups.length : 0)
                                                readonly property var cardGroupData: isAddCard ? null : root.groups[index]
                                                readonly property bool isCurrentActive: !isAddCard && cardGroupData && root.activeGroupIndex === cardGroupData.id
                                                readonly property bool isSelected: root.selectedOverviewIndex === index
                                                readonly property bool isDraggedSource: root.isDraggingCard && root.dragFromIndex === index
                                                readonly property bool isDropTarget: root.isDraggingCard && root.dragTargetIndex === index && root.dragTargetIndex !== root.dragFromIndex

                                                opacity: isDraggedSource ? 0.35 : 1.0
                                                scale: isDropTarget ? 1.02 : 1.0

                                                function handleCardDragPosition(fromIndex, mouseItem, mouseX, mouseY) {
                                                    const modalPt = mouseItem.mapToItem(overviewModalContainer, mouseX, mouseY);
                                                    root.dragMouseX = modalPt.x;
                                                    root.dragMouseY = modalPt.y;

                                                    const gridPt = mouseItem.mapToItem(groupGrid, mouseX, mouseY);
                                                    const colW = groupGrid.cardWidth + groupGrid.columnSpacing;
                                                    const rowH = groupGrid.cardHeight + groupGrid.rowSpacing;
                                                    if (colW > 0 && rowH > 0) {
                                                        const c = Math.max(0, Math.min(groupGrid.columns - 1, Math.floor(Math.max(0, gridPt.x) / colW)));
                                                        const r = Math.max(0, Math.floor(Math.max(0, gridPt.y) / rowH));
                                                        const target = r * groupGrid.columns + c;
                                                        if (target >= 0 && target < root.groups.length) {
                                                            root.dragTargetIndex = target;
                                                        }
                                                    }
                                                }

                                                function handleCardDragRelease(fromIndex) {
                                                    if (root.isDraggingCard && root.dragFromIndex === fromIndex) {
                                                        const from = root.dragFromIndex;
                                                        const to = root.dragTargetIndex;
                                                        root.isDraggingCard = false;
                                                        root.dragFromIndex = -1;
                                                        root.dragTargetIndex = -1;
                                                        if (to >= 0 && to !== from && to < root.groups.length) {
                                                            root.reorderGroup(from, to);
                                                            root.selectedOverviewIndex = to;
                                                        }
                                                    }
                                                }

                                                readonly property var groupWindows: {
                                                    if (overviewCard.isAddCard || !overviewCard.cardGroupData)
                                                        return [];
                                                    const allToplevels = Hyprland.toplevels?.values || [];
                                                    const list = [];
                                                    const monCount = root.getMonitorCount();
                                                    const totalPerGroup = root.workspacesPerMonitor * monCount;
                                                    const startWs = (overviewCard.cardGroupData.id - 1) * totalPerGroup + 1;
                                                    const endWs = overviewCard.cardGroupData.id * totalPerGroup;

                                                    for (let i = 0; i < allToplevels.length; i++) {
                                                        const top = allToplevels[i];
                                                        if (!top) continue;

                                                        const wsId = top.workspace?.id ?? top.lastIpcObject?.workspace?.id;
                                                        if (wsId !== undefined && wsId >= startWs && wsId <= endWs) {
                                                            const withinGroup = (wsId - 1) % totalPerGroup;
                                                            const subWs = (withinGroup % root.workspacesPerMonitor) + 1;

                                                            const ipcObj = top.lastIpcObject || {};
                                                            const keyBase = ipcObj.class || ipcObj.initialClass || top.wayland?.appId || top.appId || "unknown";
                                                            const moddedId = Paths.moddedAppId(keyBase);
                                                            const desktopEntry = DesktopEntries.heuristicLookup(moddedId);
                                                            const icon = Paths.getAppIcon(moddedId, desktopEntry);
                                                            const appName = Paths.getAppName(moddedId, desktopEntry) || keyBase;
                                                            const title = top.title || ipcObj.title || appName;
                                                            const address = root.formatWindowAddress(ipcObj.address || top.address);
                                                            const isFocused = top.activated || (top.wayland && top.wayland.activated) || false;

                                                            list.push({
                                                                "subWs": subWs,
                                                                "wsId": wsId,
                                                                "appName": appName,
                                                                "title": title,
                                                                "icon": icon,
                                                                "address": address,
                                                                "isFocused": isFocused
                                                            });
                                                        }
                                                    }
                                                    list.sort((a, b) => a.subWs - b.subWs);
                                                    return list;
                                                }

                                                color: isAddCard
                                                    ? (isSelected ? Theme.surfaceContainerHighest : Theme.surfaceContainerLow)
                                                    : (isSelected ? (isCurrentActive ? Theme.primaryContainer : Theme.surfaceContainerHighest) : (isCurrentActive ? Theme.withAlpha(Theme.primaryContainer, 0.45) : Theme.surfaceContainerLow))

                                                border.color: isDropTarget
                                                    ? Theme.primary
                                                    : (isAddCard
                                                        ? (isSelected ? Theme.primary : Theme.outlineVariant)
                                                        : (isSelected ? (isCurrentActive ? Theme.primary : Theme.secondary) : (isCurrentActive ? Theme.withAlpha(Theme.primary, 0.4) : Theme.outlineVariant)))
                                                border.width: isDropTarget ? 3 : (isSelected ? 2 : 1)

                                                Behavior on color { ColorAnimation { duration: 150 } }
                                                Behavior on border.color { ColorAnimation { duration: 150 } }
                                                Behavior on opacity { NumberAnimation { duration: 150 } }
                                                Behavior on scale { NumberAnimation { duration: 150 } }

                                                MouseArea {
                                                    id: cardMouseArea
                                                    anchors.fill: parent
                                                    enabled: !overviewCard.isAddCard
                                                    hoverEnabled: true
                                                    cursorShape: root.isDraggingCard ? Qt.ClosedHandCursor : Qt.PointingHandCursor

                                                    property real startMouseX: 0
                                                    property real startMouseY: 0
                                                    property bool dragActive: false

                                                    onPressed: mouse => {
                                                        startMouseX = mouse.x;
                                                        startMouseY = mouse.y;
                                                        dragActive = false;
                                                    }

                                                    onPositionChanged: mouse => {
                                                        const globalPoint = mapToItem(null, mouse.x, mouse.y);
                                                        if (!root.mouseMovedSinceOpen) {
                                                            if (root.lastGlobalMouseX === -1) {
                                                                root.lastGlobalMouseX = globalPoint.x;
                                                                root.lastGlobalMouseY = globalPoint.y;
                                                                return;
                                                            }
                                                            const dx = Math.abs(globalPoint.x - root.lastGlobalMouseX);
                                                            const dy = Math.abs(globalPoint.y - root.lastGlobalMouseY);
                                                            if (dx < 4 && dy < 4) {
                                                                return;
                                                            }
                                                            root.mouseMovedSinceOpen = true;
                                                        }
                                                        root.lastGlobalMouseX = globalPoint.x;
                                                        root.lastGlobalMouseY = globalPoint.y;

                                                        if (pressed && !overviewCard.isAddCard) {
                                                            const dist = Math.hypot(mouse.x - startMouseX, mouse.y - startMouseY);
                                                            if (dist > 8 && !root.isDraggingCard) {
                                                                root.dragFromIndex = index;
                                                                root.dragTargetIndex = index;
                                                                root.isDraggingCard = true;
                                                                dragActive = true;
                                                            }
                                                        }

                                                        if (root.isDraggingCard && root.dragFromIndex === index) {
                                                            overviewCard.handleCardDragPosition(index, cardMouseArea, mouse.x, mouse.y);
                                                        } else if (!root.isDraggingCard) {
                                                            if (root.selectedOverviewIndex !== index) {
                                                                root.selectedOverviewIndex = index;
                                                            }
                                                        }
                                                    }

                                                    onReleased: mouse => {
                                                        if (root.isDraggingCard && root.dragFromIndex === index) {
                                                            overviewCard.handleCardDragRelease(index);
                                                            dragActive = false;
                                                            return;
                                                        }

                                                        if (dragActive) {
                                                            dragActive = false;
                                                            return;
                                                        }

                                                        if (overviewCard.cardGroupData) {
                                                            const gid = overviewCard.cardGroupData.id;
                                                            root.closeOverview();
                                                            Qt.callLater(() => {
                                                                root.switchToGroup(gid);
                                                            });
                                                        }
                                                    }

                                                    onCanceled: {
                                                        if (root.isDraggingCard && root.dragFromIndex === index) {
                                                            root.isDraggingCard = false;
                                                            root.dragFromIndex = -1;
                                                            root.dragTargetIndex = -1;
                                                        }
                                                        dragActive = false;
                                                    }
                                                }

                                                MouseArea {
                                                    id: addCardMouse
                                                    anchors.fill: parent
                                                    enabled: overviewCard.isAddCard
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onPositionChanged: mouse => {
                                                        const globalPoint = mapToItem(null, mouse.x, mouse.y);
                                                        if (!root.mouseMovedSinceOpen) {
                                                            if (root.lastGlobalMouseX === -1) {
                                                                root.lastGlobalMouseX = globalPoint.x;
                                                                root.lastGlobalMouseY = globalPoint.y;
                                                                return;
                                                            }
                                                            const dx = Math.abs(globalPoint.x - root.lastGlobalMouseX);
                                                            const dy = Math.abs(globalPoint.y - root.lastGlobalMouseY);
                                                            if (dx < 4 && dy < 4) {
                                                                return;
                                                            }
                                                            root.mouseMovedSinceOpen = true;
                                                        }
                                                        root.lastGlobalMouseX = globalPoint.x;
                                                        root.lastGlobalMouseY = globalPoint.y;
                                                        if (root.selectedOverviewIndex !== index) {
                                                            root.selectedOverviewIndex = index;
                                                        }
                                                    }
                                                    onClicked: {
                                                        root.openCreateGroup();
                                                    }
                                                }

                                                ColumnLayout {
                                                    anchors.fill: parent
                                                    anchors.margins: Theme.spacingM
                                                    spacing: Theme.spacingXS
                                                    visible: !overviewCard.isAddCard

                                                    RowLayout {
                                                        Layout.fillWidth: true
                                                        spacing: Theme.spacingS

                                                        Rectangle {
                                                            width: (overviewCard.cardGroupData && overviewCard.cardGroupData.id >= 10) ? 28 : 24
                                                            height: 24
                                                            radius: 12
                                                            color: overviewCard.isCurrentActive ? Theme.primary : Theme.surfaceContainerHighest

                                                            StyledText {
                                                                anchors.centerIn: parent
                                                                text: overviewCard.cardGroupData ? overviewCard.cardGroupData.id.toString() : ""
                                                                font.pixelSize: Theme.fontSizeSmall
                                                                font.weight: Font.Bold
                                                                color: overviewCard.isCurrentActive ? Theme.onPrimary : Theme.surfaceText
                                                            }
                                                        }

                                                        StyledText {
                                                            text: (overviewCard.cardGroupData && overviewCard.cardGroupData.icon) ? overviewCard.cardGroupData.icon : "󰅩"
                                                            font.pixelSize: 20
                                                            color: (overviewCard.cardGroupData && overviewCard.cardGroupData.color) ? overviewCard.cardGroupData.color : Theme.primary
                                                        }

                                                        StyledText {
                                                            text: overviewCard.cardGroupData ? (overviewCard.cardGroupData.name || ("Group " + overviewCard.cardGroupData.id)) : ""
                                                            font.pixelSize: Theme.fontSizeMedium
                                                            font.weight: Font.Bold
                                                            color: Theme.surfaceText
                                                            elide: Text.ElideRight
                                                            Layout.fillWidth: true
                                                        }

                                                        Rectangle {
                                                            width: 28
                                                            height: 28
                                                            radius: 14
                                                            color: editBtnMouse.containsMouse ? Theme.withAlpha(Theme.primary, 0.2) : Theme.withAlpha(Theme.surfaceContainerHighest, 0.7)

                                                            DankIcon {
                                                                anchors.centerIn: parent
                                                                name: "edit"
                                                                size: 15
                                                                color: editBtnMouse.containsMouse ? Theme.primary : Theme.surfaceText
                                                            }

                                                            MouseArea {
                                                                id: editBtnMouse
                                                                anchors.fill: parent
                                                                hoverEnabled: true
                                                                cursorShape: Qt.PointingHandCursor
                                                                onClicked: {
                                                                    if (overviewCard.cardGroupData) {
                                                                        root.openEditGroup(overviewCard.cardGroupData.id);
                                                                    }
                                                                }
                                                            }
                                                        }

                                                        Rectangle {
                                                            visible: root.groups.length > 1
                                                            width: 28
                                                            height: 28
                                                            radius: 14
                                                            color: delBtnMouse.containsMouse ? Theme.withAlpha(Theme.error, 0.2) : Theme.withAlpha(Theme.surfaceContainerHighest, 0.7)

                                                            DankIcon {
                                                                anchors.centerIn: parent
                                                                name: "delete"
                                                                size: 15
                                                                color: delBtnMouse.containsMouse ? Theme.error : Theme.surfaceText
                                                            }

                                                            MouseArea {
                                                                id: delBtnMouse
                                                                anchors.fill: parent
                                                                hoverEnabled: true
                                                                cursorShape: Qt.PointingHandCursor
                                                                onClicked: {
                                                                    if (overviewCard.cardGroupData) {
                                                                        root.confirmDeleteGroup(overviewCard.cardGroupData.id);
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }

                                                    Rectangle {
                                                        Layout.fillWidth: true
                                                        height: 1
                                                        color: Theme.outlineVariant
                                                    }

                                                    Item {
                                                        Layout.fillWidth: true
                                                        Layout.fillHeight: true
                                                        implicitHeight: 0
                                                        clip: true

                                                        Flickable {
                                                            id: winFlickable
                                                            anchors.fill: parent
                                                            visible: overviewCard.groupWindows.length > 0
                                                            clip: true
                                                            contentWidth: width
                                                            contentHeight: winCol.height
                                                            boundsBehavior: Flickable.StopAtBounds

                                                            ScrollBar.vertical: DankScrollbar {
                                                                id: winScrollBar
                                                            }

                                                            WheelHandler {
                                                                target: winFlickable
                                                                enabled: winFlickable.contentHeight > winFlickable.height
                                                                onWheel: event => {
                                                                    const step = 33;
                                                                    if (event.angleDelta.y > 0) {
                                                                        winFlickable.contentY = Math.max(0, winFlickable.contentY - step);
                                                                    } else if (event.angleDelta.y < 0) {
                                                                        winFlickable.contentY = Math.min(Math.max(0, winFlickable.contentHeight - winFlickable.height), winFlickable.contentY + step);
                                                                    }
                                                                    winScrollBar._scrollBarActive = true;
                                                                    winScrollBar.hideTimer.restart();
                                                                }
                                                            }

                                                            Column {
                                                                id: winCol
                                                                width: overviewCard.groupWindows.length > 5 ? (winFlickable.width - 8) : winFlickable.width
                                                                spacing: 3

                                                                Repeater {
                                                                    model: overviewCard.groupWindows

                                                                    Rectangle {
                                                                        width: winCol.width
                                                                        height: 30
                                                                        radius: Theme.cornerRadiusSmall
                                                                        clip: true
                                                                        color: (winMouse.containsMouse && root.mouseMovedSinceOpen) ? Theme.surfaceContainerHighest : (modelData.isFocused ? Theme.withAlpha(Theme.primary, 0.15) : Theme.surfaceContainerLowest)
                                                                        border.color: modelData.isFocused ? Theme.primary : ((winMouse.containsMouse && root.mouseMovedSinceOpen) ? Theme.outlineVariant : "transparent")
                                                                        border.width: 1

                                                                        MouseArea {
                                                                            id: winMouse
                                                                            anchors.fill: parent
                                                                            hoverEnabled: true
                                                                            cursorShape: root.isDraggingCard ? Qt.ClosedHandCursor : Qt.PointingHandCursor

                                                                            property real startWinX: 0
                                                                            property real startWinY: 0
                                                                            property bool dragActive: false

                                                                            onPressed: mouse => {
                                                                                startWinX = mouse.x;
                                                                                startWinY = mouse.y;
                                                                                dragActive = false;
                                                                            }

                                                                            onPositionChanged: mouse => {
                                                                                const globalPoint = mapToItem(null, mouse.x, mouse.y);
                                                                                if (!root.mouseMovedSinceOpen) {
                                                                                    if (root.lastGlobalMouseX === -1) {
                                                                                        root.lastGlobalMouseX = globalPoint.x;
                                                                                        root.lastGlobalMouseY = globalPoint.y;
                                                                                        return;
                                                                                    }
                                                                                    const dx = Math.abs(globalPoint.x - root.lastGlobalMouseX);
                                                                                    const dy = Math.abs(globalPoint.y - root.lastGlobalMouseY);
                                                                                    if (dx < 4 && dy < 4) {
                                                                                        return;
                                                                                    }
                                                                                    root.mouseMovedSinceOpen = true;
                                                                                }
                                                                                root.lastGlobalMouseX = globalPoint.x;
                                                                                root.lastGlobalMouseY = globalPoint.y;

                                                                                if (pressed && !overviewCard.isAddCard) {
                                                                                    const dist = Math.hypot(mouse.x - startWinX, mouse.y - startWinY);
                                                                                    if (dist > 8 && !root.isDraggingCard) {
                                                                                        root.dragFromIndex = overviewCard.cardIndex;
                                                                                        root.dragTargetIndex = overviewCard.cardIndex;
                                                                                        root.isDraggingCard = true;
                                                                                        dragActive = true;
                                                                                    }
                                                                                }

                                                                                if (root.isDraggingCard && root.dragFromIndex === overviewCard.cardIndex) {
                                                                                    overviewCard.handleCardDragPosition(overviewCard.cardIndex, winMouse, mouse.x, mouse.y);
                                                                                } else if (!root.isDraggingCard) {
                                                                                    if (root.selectedOverviewIndex !== overviewCard.cardIndex) {
                                                                                        root.selectedOverviewIndex = overviewCard.cardIndex;
                                                                                    }
                                                                                }
                                                                            }

                                                                            onReleased: mouse => {
                                                                                if (root.isDraggingCard && root.dragFromIndex === overviewCard.cardIndex) {
                                                                                    overviewCard.handleCardDragRelease(overviewCard.cardIndex);
                                                                                    dragActive = false;
                                                                                    return;
                                                                                }
                                                                                if (dragActive) {
                                                                                    dragActive = false;
                                                                                    return;
                                                                                }
                                                                            }

                                                                            onCanceled: {
                                                                                if (root.isDraggingCard && root.dragFromIndex === overviewCard.cardIndex) {
                                                                                    root.isDraggingCard = false;
                                                                                    root.dragFromIndex = -1;
                                                                                    root.dragTargetIndex = -1;
                                                                                }
                                                                                dragActive = false;
                                                                            }

                                                                            onClicked: {
                                                                                if (dragActive || root.isDraggingCard) {
                                                                                    return;
                                                                                }
                                                                                if (modelData.address) {
                                                                                    if (root.isLua) {
                                                                                        Quickshell.execDetached(["hyprctl", "dispatch", `hl.dsp.focus({ window = 'address:${modelData.address}' })`]);
                                                                                    } else {
                                                                                        Quickshell.execDetached(["hyprctl", "dispatch", "focuswindow", "address:" + modelData.address]);
                                                                                    }
                                                                                } else {
                                                                                    root.switchToSubWorkspace(modelData.subWs);
                                                                                }
                                                                                root.closeOverview();
                                                                            }
                                                                            onWheel: event => {
                                                                                if (winFlickable.contentHeight <= winFlickable.height) {
                                                                                    event.accepted = false;
                                                                                    return;
                                                                                }
                                                                                const step = 33;
                                                                                if (event.angleDelta.y > 0) {
                                                                                    winFlickable.contentY = Math.max(0, winFlickable.contentY - step);
                                                                                } else if (event.angleDelta.y < 0) {
                                                                                    winFlickable.contentY = Math.min(Math.max(0, winFlickable.contentHeight - winFlickable.height), winFlickable.contentY + step);
                                                                                }
                                                                                winScrollBar._scrollBarActive = true;
                                                                                winScrollBar.hideTimer.restart();
                                                                            }
                                                                        }

                                                                        RowLayout {
                                                                            anchors.fill: parent
                                                                            anchors.leftMargin: Theme.spacingXS
                                                                            anchors.rightMargin: Theme.spacingXS
                                                                            spacing: Theme.spacingXS

                                                                            Rectangle {
                                                                                width: 18
                                                                                height: 18
                                                                                radius: 3
                                                                                color: Theme.withAlpha((overviewCard.cardGroupData && overviewCard.cardGroupData.color) || Theme.primary, 0.2)

                                                                                StyledText {
                                                                                    anchors.centerIn: parent
                                                                                    text: modelData.subWs.toString()
                                                                                    font.pixelSize: 10
                                                                                    font.weight: Font.Bold
                                                                                    color: (overviewCard.cardGroupData && overviewCard.cardGroupData.color) || Theme.primary
                                                                                }
                                                                            }

                                                                            Item {
                                                                                width: 16
                                                                                height: 16
                                                                                Layout.alignment: Qt.AlignVCenter

                                                                                IconImage {
                                                                                    id: winIconImg
                                                                                    anchors.fill: parent
                                                                                    source: modelData.icon || ""
                                                                                    visible: modelData.icon !== "" && status === Image.Ready
                                                                                }

                                                                                DankIcon {
                                                                                    anchors.centerIn: parent
                                                                                    name: "desktop_windows"
                                                                                    size: 14
                                                                                    color: Theme.surfaceVariantText
                                                                                    visible: !modelData.icon || (modelData.icon !== "" && winIconImg.status !== Image.Ready)
                                                                                }
                                                                            }

                                                                            StyledText {
                                                                                text: modelData.appName || modelData.title
                                                                                font.pixelSize: Theme.fontSizeSmall - 1
                                                                                color: Theme.surfaceText
                                                                                wrapMode: Text.NoWrap
                                                                                elide: Text.ElideRight
                                                                                maximumLineCount: 1
                                                                                Layout.fillWidth: true
                                                                            }

                                                                            Rectangle {
                                                                                width: 5
                                                                                height: 5
                                                                                radius: 2.5
                                                                                color: Theme.primary
                                                                                visible: modelData.isFocused
                                                                            }
                                                                        }
                                                                    }
                                                                }
                                                            }
                                                        }

                                                        ColumnLayout {
                                                            anchors.centerIn: parent
                                                            visible: overviewCard.groupWindows.length === 0
                                                            spacing: Theme.spacingXS

                                                            DankIcon {
                                                                Layout.alignment: Qt.AlignHCenter
                                                                name: "desktop_windows"
                                                                size: 26
                                                                color: Theme.outlineMedium
                                                            }

                                                            StyledText {
                                                                Layout.alignment: Qt.AlignHCenter
                                                                text: "No open windows"
                                                                font.pixelSize: Theme.fontSizeSmall - 1
                                                                color: Theme.surfaceVariantText
                                                            }
                                                        }
                                                    }
                                                }

                                                ColumnLayout {
                                                    anchors.centerIn: parent
                                                    visible: overviewCard.isAddCard
                                                    spacing: Theme.spacingS

                                                    Rectangle {
                                                        Layout.alignment: Qt.AlignHCenter
                                                        width: 48
                                                        height: 48
                                                        radius: 24
                                                        color: Theme.withAlpha(Theme.primary, 0.15)
                                                        border.color: Theme.withAlpha(Theme.primary, 0.4)
                                                        border.width: 1

                                                        DankIcon {
                                                            anchors.centerIn: parent
                                                            name: "add"
                                                            size: 24
                                                            color: Theme.primary
                                                        }
                                                    }

                                                    StyledText {
                                                        Layout.alignment: Qt.AlignHCenter
                                                        text: "Add Group"
                                                        font.pixelSize: Theme.fontSizeMedium
                                                        font.weight: Font.Bold
                                                        color: Theme.surfaceText
                                                    }

                                                    StyledText {
                                                        Layout.alignment: Qt.AlignHCenter
                                                        text: "Press N or Click"
                                                        font.pixelSize: Theme.fontSizeSmall
                                                        color: Theme.surfaceVariantText
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Item {
                        id: dragProxy
                        enabled: false
                        visible: root.isDraggingCard && root.dragFromIndex >= 0 && root.dragFromIndex < root.groups.length
                        width: groupGrid.cardWidth
                        height: groupGrid.cardHeight
                        x: Math.max(0, Math.min(overviewModalContainer.width - width, root.dragMouseX - width / 2))
                        y: Math.max(0, Math.min(overviewModalContainer.height - height, root.dragMouseY - 30))
                        z: 9999
                        opacity: 0.95
                        scale: 1.04

                        readonly property var draggedGroup: (root.dragFromIndex >= 0 && root.dragFromIndex < root.groups.length) ? root.groups[root.dragFromIndex] : null

                        ElevationShadow {
                            anchors.fill: parent
                            level: Theme.elevationLevel4
                            targetRadius: Theme.cornerRadius
                            targetColor: Theme.surfaceContainerHighest
                            shadowEnabled: Theme.elevationEnabled
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: Theme.cornerRadius
                            color: Theme.surfaceContainerHighest
                            border.color: (dragProxy.draggedGroup && dragProxy.draggedGroup.color) || Theme.primary
                            border.width: 2.5

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: Theme.spacingM

                                Rectangle {
                                    Layout.alignment: Qt.AlignHCenter
                                    width: 46
                                    height: 46
                                    radius: 23
                                    color: Theme.withAlpha((dragProxy.draggedGroup && dragProxy.draggedGroup.color) || Theme.primary, 0.2)
                                    border.color: (dragProxy.draggedGroup && dragProxy.draggedGroup.color) || Theme.primary
                                    border.width: 1.5

                                    StyledText {
                                        anchors.centerIn: parent
                                        text: (dragProxy.draggedGroup && dragProxy.draggedGroup.icon) || "󰅩"
                                        font.pixelSize: 24
                                        color: (dragProxy.draggedGroup && dragProxy.draggedGroup.color) || Theme.primary
                                    }
                                }

                                ColumnLayout {
                                    Layout.alignment: Qt.AlignHCenter
                                    spacing: 3

                                    StyledText {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: (dragProxy.draggedGroup && dragProxy.draggedGroup.name) || "Group"
                                        font.pixelSize: Theme.fontSizeMedium
                                        font.weight: Font.Bold
                                        color: Theme.surfaceText
                                    }

                                    StyledText {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: "Slot " + (root.dragTargetIndex + 1)
                                        font.pixelSize: Theme.fontSizeSmall
                                        font.weight: Font.Medium
                                        color: (dragProxy.draggedGroup && dragProxy.draggedGroup.color) || Theme.primary
                                    }
                                }
                            }
                        }
                    }

                    Item {
                        id: createModalContainer
                        anchors.centerIn: parent
                        width: Math.min(parent.width - 40, 520)
                        implicitHeight: createCard.implicitHeight
                        visible: root.createModalOpen
                        scale: visible ? 1.0 : 0.95
                        opacity: visible ? 1.0 : 0.0

                        Keys.onEscapePressed: event => {
                            root.closeCreateGroup();
                            event.accepted = true;
                        }

                        Behavior on scale { NumberAnimation { duration: Theme.modalAnimationDuration } }
                        Behavior on opacity { NumberAnimation { duration: Theme.modalAnimationDuration } }

                        Connections {
                            target: root
                            function onCreateModalOpenChanged() {
                                if (root.createModalOpen) {
                                    Qt.callLater(() => {
                                        createNameInput.forceActiveFocus();
                                    });
                                }
                            }
                        }

                        ElevationShadow {
                            anchors.fill: parent
                            level: Theme.elevationLevel3
                            targetRadius: Theme.cornerRadius * 1.5
                            targetColor: Theme.surfaceContainer
                            shadowEnabled: Theme.elevationEnabled && SettingsData.modalElevationEnabled
                        }

                        Rectangle {
                            id: createCard
                            width: parent.width
                            implicitHeight: createCol.implicitHeight + Theme.spacingXL * 2
                            color: Theme.surfaceContainer
                            radius: Theme.cornerRadius * 1.5
                            border.color: Theme.outlineVariant
                            border.width: 1
                            clip: true

                            ColumnLayout {
                                id: createCol
                                anchors.fill: parent
                                anchors.margins: Theme.spacingXL
                                spacing: Theme.spacingL

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: Theme.spacingM

                                    StyledText {
                                        text: root.editingGroupId > 0 ? ("Edit Workspace Group " + root.editingGroupId) : "Create Workspace Group"
                                        font.pixelSize: Theme.fontSizeLarge + 2
                                        font.weight: Font.Bold
                                        color: Theme.surfaceText
                                    }

                                    Item { Layout.fillWidth: true }

                                    Rectangle {
                                        width: 32
                                        height: 32
                                        radius: 16
                                        color: closeCreateMouse.containsMouse ? Theme.surfaceContainerHighest : "transparent"

                                        DankIcon {
                                            anchors.centerIn: parent
                                            name: "close"
                                            size: 18
                                            color: Theme.surfaceVariantText
                                        }

                                        MouseArea {
                                            id: closeCreateMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.closeCreateGroup()
                                        }
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: Theme.spacingXS

                                    StyledText {
                                        text: "Group Name"
                                        font.pixelSize: Theme.fontSizeSmall
                                        font.weight: Font.Medium
                                        color: Theme.surfaceVariantText
                                    }

                                    DankTextField {
                                        id: createNameInput
                                        Layout.fillWidth: true
                                        text: root.formGroupName
                                        placeholderText: "e.g. Work, Gaming, Notes"
                                        focus: root.createModalOpen
                                        keyForwardTargets: [createModalContainer, focusScope]
                                        Keys.onEscapePressed: event => {
                                            root.closeCreateGroup();
                                            event.accepted = true;
                                        }
                                        onTextEdited: {
                                            root.formGroupName = createNameInput.text;
                                        }
                                        onAccepted: {
                                            createModalContainer.submitForm();
                                        }
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: Theme.spacingXS

                                    StyledText {
                                        text: "Icon (Nerd Font Glyph)"
                                        font.pixelSize: Theme.fontSizeSmall
                                        font.weight: Font.Medium
                                        color: Theme.surfaceVariantText
                                    }

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: Theme.spacingM

                                        Rectangle {
                                            width: 52
                                            height: 52
                                            radius: Theme.cornerRadiusSmall
                                            color: Theme.withAlpha(root.formGroupColor, 0.15)
                                            border.color: root.formGroupColor
                                            border.width: 1.5

                                            StyledText {
                                                anchors.centerIn: parent
                                                text: root.formGroupIcon || "󰅩"
                                                font.pixelSize: 30
                                                color: root.formGroupColor
                                            }
                                        }

                                        DankTextField {
                                            id: createIconInput
                                            implicitWidth: 80
                                            text: root.formGroupIcon
                                            placeholderText: "󰅩"
                                            keyForwardTargets: [createModalContainer, focusScope]
                                            Keys.onEscapePressed: event => {
                                                root.closeCreateGroup();
                                                event.accepted = true;
                                            }
                                            onTextEdited: {
                                                root.formGroupIcon = createIconInput.text;
                                            }
                                            onAccepted: {
                                                createModalContainer.submitForm();
                                            }
                                        }

                                        DankButton {
                                            text: "Randomize"
                                            iconName: "casino"
                                            onClicked: {
                                                root.formGroupIcon = root.getRandomNerdfontIcon();
                                                createIconInput.text = root.formGroupIcon;
                                            }
                                        }

                                        Item { Layout.fillWidth: true }
                                    }

                                    Row {
                                        spacing: 6
                                        Layout.fillWidth: true

                                        Repeater {
                                            model: ["󰅩", "󰈹", "󰝚", "󰒓", "󰊴", "󰭹", "󰠮", "󰀝", "󱄅", "󰣇"]

                                            Rectangle {
                                                width: 32
                                                height: 32
                                                radius: 16
                                                color: iconPsetMouse.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainer
                                                border.color: root.formGroupIcon === modelData ? root.formGroupColor : "transparent"
                                                border.width: 1.5

                                                StyledText {
                                                    anchors.centerIn: parent
                                                    text: modelData
                                                    font.pixelSize: 16
                                                    color: Theme.surfaceText
                                                }

                                                MouseArea {
                                                    id: iconPsetMouse
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        root.formGroupIcon = modelData;
                                                        createIconInput.text = modelData;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: Theme.spacingXS

                                    StyledText {
                                        text: "Color Accent"
                                        font.pixelSize: Theme.fontSizeSmall
                                        font.weight: Font.Medium
                                        color: Theme.surfaceVariantText
                                    }

                                    Row {
                                        spacing: 8
                                        Layout.fillWidth: true

                                        Repeater {
                                            model: root.colorPalette

                                            Rectangle {
                                                width: 28
                                                height: 28
                                                radius: 14
                                                color: modelData
                                                border.color: root.formGroupColor === modelData ? Theme.surfaceText : Theme.withAlpha(Theme.outlineVariant, 0.5)
                                                border.width: root.formGroupColor === modelData ? 2.5 : 1

                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        root.formGroupColor = modelData;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: Theme.spacingM
                                    visible: root.editingGroupId === 0

                                    StyledText {
                                        text: "Switch to group immediately"
                                        font.pixelSize: Theme.fontSizeSmall
                                        color: Theme.surfaceText
                                        Layout.fillWidth: true
                                    }

                                    DankToggle {
                                        checked: root.formSwitchImmediate
                                        onToggled: isChecked => {
                                            root.formSwitchImmediate = isChecked;
                                        }
                                    }
                                }

                                Item { height: Theme.spacingS }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: Theme.spacingM

                                    Item { Layout.fillWidth: true }

                                    DankButton {
                                        text: "Cancel"
                                        onClicked: root.closeCreateGroup()
                                    }

                                    DankButton {
                                        text: root.editingGroupId > 0 ? "Save Changes" : "Create Group"
                                        iconName: root.editingGroupId > 0 ? "check" : "add"
                                        backgroundColor: root.formGroupColor || Theme.primary
                                        textColor: Theme.surfaceContainer
                                        onClicked: createModalContainer.submitForm()
                                    }
                                }
                            }
                        }

                        function submitForm() {
                            if (root.editingGroupId > 0) {
                                root.updateGroup(root.editingGroupId, root.formGroupName, root.formGroupIcon, root.formGroupColor);
                            } else {
                                root.createGroup(root.formGroupName, root.formGroupIcon, root.formGroupColor, root.formSwitchImmediate);
                            }
                        }

                        function submitCreateGroup() {
                            submitForm();
                        }
                    }

                    Item {
                        id: deleteConfirmContainer
                        anchors.centerIn: parent
                        width: Math.min(parent.width - 40, 460)
                        implicitHeight: deleteCard.implicitHeight
                        visible: root.deleteConfirmOpen
                        scale: visible ? 1.0 : 0.95
                        opacity: visible ? 1.0 : 0.0

                        Keys.onEscapePressed: event => {
                            root.deleteConfirmOpen = false;
                            event.accepted = true;
                        }

                        Behavior on scale { NumberAnimation { duration: Theme.modalAnimationDuration } }
                        Behavior on opacity { NumberAnimation { duration: Theme.modalAnimationDuration } }

                        ElevationShadow {
                            anchors.fill: parent
                            level: Theme.elevationLevel3
                            targetRadius: Theme.cornerRadius * 1.5
                            targetColor: Theme.surfaceContainer
                            shadowEnabled: Theme.elevationEnabled && SettingsData.modalElevationEnabled
                        }

                        Rectangle {
                            id: deleteCard
                            width: parent.width
                            implicitHeight: deleteCol.implicitHeight + Theme.spacingXL * 2
                            color: Theme.surfaceContainer
                            radius: Theme.cornerRadius * 1.5
                            border.color: Theme.outlineVariant
                            border.width: 1
                            clip: true

                            ColumnLayout {
                                id: deleteCol
                                anchors.fill: parent
                                anchors.margins: Theme.spacingXL
                                spacing: Theme.spacingM

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: Theme.spacingS

                                    DankIcon {
                                        name: "warning"
                                        size: 24
                                        color: Theme.error
                                    }

                                    StyledText {
                                        text: "Delete Group " + root.groupToDeleteName + "?"
                                        font.pixelSize: Theme.fontSizeLarge
                                        font.weight: Font.Bold
                                        color: Theme.surfaceText
                                    }
                                }

                                StyledText {
                                    text: "This group has " + root.groupToDeleteWindowCount + " open window(s). Deleting it will safely move all its windows to Group 1."
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: Theme.surfaceVariantText
                                    wrapMode: Text.WordWrap
                                    Layout.fillWidth: true
                                }

                                Item { height: Theme.spacingXS }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: Theme.spacingM

                                    Item { Layout.fillWidth: true }

                                    DankButton {
                                        text: "Cancel"
                                        onClicked: {
                                            root.deleteConfirmOpen = false;
                                        }
                                    }

                                    DankButton {
                                        text: "Delete & Move Windows"
                                        iconName: "delete"
                                        backgroundColor: Theme.error
                                        textColor: Theme.surfaceContainer
                                        onClicked: {
                                            const g = root.groupToDeleteId;
                                            root.deleteConfirmOpen = false;
                                            root.deleteGroup(g);
                                        }
                                    }
                                }
                            }
                        }
                    }

                    FocusScope {
                        id: focusScope
                        anchors.fill: parent
                        focus: root.contentVisible && overviewWindow.monitorIsFocused

                        Keys.onEscapePressed: event => {
                            if (root.isDraggingCard) {
                                root.isDraggingCard = false;
                                root.dragFromIndex = -1;
                                root.dragTargetIndex = -1;
                            } else if (root.deleteConfirmOpen) {
                                root.deleteConfirmOpen = false;
                            } else if (root.createModalOpen) {
                                root.closeCreateGroup();
                            } else {
                                root.closeOverview();
                            }
                            event.accepted = true;
                        }

                        Keys.onPressed: event => {
                            if (root.createModalOpen || root.deleteConfirmOpen) {
                                return;
                            }

                            root.mouseMovedSinceOpen = false;
                            root.lastGlobalMouseX = -1;
                            root.lastGlobalMouseY = -1;

                            if (event.key >= Qt.Key_1 && event.key <= Qt.Key_9) {
                                const targetId = event.key - Qt.Key_0;
                                if (targetId <= root.groups.length) {
                                    root.closeOverview();
                                    Qt.callLater(() => {
                                        root.switchToGroup(targetId);
                                    });
                                    event.accepted = true;
                                    return;
                                }
                            } else if (event.key === Qt.Key_0) {
                                if (root.groups.length >= 10) {
                                    root.closeOverview();
                                    Qt.callLater(() => {
                                        root.switchToGroup(10);
                                    });
                                    event.accepted = true;
                                    return;
                                }
                            }

                            if (event.key === Qt.Key_E) {
                                if (root.selectedOverviewIndex >= 0 && root.selectedOverviewIndex < root.groups.length) {
                                    const chosen = root.groups[root.selectedOverviewIndex];
                                    if (chosen) {
                                        root.openEditGroup(chosen.id);
                                        event.accepted = true;
                                        return;
                                    }
                                }
                            }

                            if (event.key === Qt.Key_N || event.key === Qt.Key_Plus) {
                                root.openCreateGroup();
                                event.accepted = true;
                                return;
                            }

                            if (event.key === Qt.Key_Delete || event.key === Qt.Key_D) {
                                const chosen = root.groups[root.selectedOverviewIndex];
                                if (chosen && root.groups.length > 1) {
                                    root.confirmDeleteGroup(chosen.id);
                                    event.accepted = true;
                                    return;
                                }
                            }

                            if (event.modifiers & Qt.ShiftModifier) {
                                if (event.key === Qt.Key_Left || event.key === Qt.Key_H) {
                                    if (root.selectedOverviewIndex > 0 && root.selectedOverviewIndex < root.groups.length) {
                                        const from = root.selectedOverviewIndex;
                                        const to = root.selectedOverviewIndex - 1;
                                        root.reorderGroup(from, to);
                                        root.selectedOverviewIndex = to;
                                    }
                                    event.accepted = true;
                                    return;
                                } else if (event.key === Qt.Key_Right || event.key === Qt.Key_L) {
                                    if (root.selectedOverviewIndex >= 0 && root.selectedOverviewIndex < root.groups.length - 1) {
                                        const from = root.selectedOverviewIndex;
                                        const to = root.selectedOverviewIndex + 1;
                                        root.reorderGroup(from, to);
                                        root.selectedOverviewIndex = to;
                                    }
                                    event.accepted = true;
                                    return;
                                }
                            }

                            const totalItems = root.groups.length + 1;
                            const cols = root.gridColumns;

                            if (event.key === Qt.Key_Left || event.key === Qt.Key_Backtab || event.key === Qt.Key_H) {
                                root.selectedOverviewIndex = (root.selectedOverviewIndex - 1 + totalItems) % totalItems;
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Right || event.key === Qt.Key_Tab || event.key === Qt.Key_L) {
                                root.selectedOverviewIndex = (root.selectedOverviewIndex + 1) % totalItems;
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Up || event.key === Qt.Key_K) {
                                root.selectedOverviewIndex = Math.max(0, root.selectedOverviewIndex - cols);
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Down || event.key === Qt.Key_J) {
                                root.selectedOverviewIndex = Math.min(totalItems - 1, root.selectedOverviewIndex + cols);
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                                if (root.selectedOverviewIndex === root.groups.length) {
                                    root.openCreateGroup();
                                } else {
                                    const chosen = root.groups[root.selectedOverviewIndex];
                                    if (chosen) {
                                        root.closeOverview();
                                        Qt.callLater(() => {
                                            root.switchToGroup(chosen.id);
                                        });
                                    }
                                }
                                event.accepted = true;
                            }
                        }
                    }
                }
            }
        }
    }
}
