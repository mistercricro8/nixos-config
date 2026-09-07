import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import QtCore
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins
import "WorkspaceGroupsDefaults.js" as Defaults
import "WorkspaceGroupsMath.js" as WGMath

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

    DragController {
        id: dragCtrl
        host: root
    }
    property alias dragFromIndex: dragCtrl.dragFromIndex
    property alias dragTargetIndex: dragCtrl.dragTargetIndex
    property alias isDraggingCard: dragCtrl.isDragging
    property real dragMouseX: 0
    property real dragMouseY: 0

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
        return WGMath.groupFromWorkspace(wsId, workspacesPerMonitor, getMonitorCount());
    }

    function calcWorkspace(groupId, monIdx, subWs) {
        return WGMath.calcWorkspace(groupId, monIdx, subWs, workspacesPerMonitor, getMonitorCount());
    }

    function isWorkspaceValidForGroupAndMonitor(wsId, groupId, monIdx) {
        return WGMath.isWorkspaceInRange(wsId, groupId, monIdx, workspacesPerMonitor, getMonitorCount());
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
        return WGMath.subFromWorkspace(wsId, workspacesPerMonitor, getMonitorCount());
    }

    function formatWindowAddress(rawAddrOrToplevel) {
        let rawAddr = rawAddrOrToplevel;
        if (rawAddrOrToplevel && typeof rawAddrOrToplevel === "object") {
            const top = rawAddrOrToplevel;
            rawAddr = top.lastIpcObject?.address || top.address;
        }
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

        root.commitState(true);
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
    function commitState(persistLua) {
        root.notifyState();
        if (persistLua === true) {
            root.writeLuaConfig();
        }
        root.saveStateFile();
    }

    function snapshotCurrent() {
        const mons = getSortedMonitors();
        for (let i = 0; i < mons.length; i++) {
            const m = mons[i];
            const curWs = m.activeWorkspace ? m.activeWorkspace.id : null;
            if (curWs && root.isWorkspaceValidForGroupAndMonitor(curWs, root.activeGroupIndex, i)) {
                if (!root.lastActiveWorkspaces[root.activeGroupIndex])
                    root.lastActiveWorkspaces[root.activeGroupIndex] = {};
                root.lastActiveWorkspaces[root.activeGroupIndex][m.name] = curWs;
            }
        }
        return mons;
    }

    function ensureTargetWorkspaces(g, mons) {
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
    }

    function buildFocusBatch(g, mons, focusedMonName) {
        root.ensureTargetWorkspaces(g, mons);
        const batchCommands = [];
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
        return batchCommands;
    }

    function moveWindowCommand(targetWs) {
        if (root.isLua) {
            return `dispatch hl.dsp.window.move({ workspace = '${targetWs}', silent = true })`;
        }
        return "dispatch movetoworkspacesilent " + targetWs;
    }

    function windowsInGroup(groupId) {
        const range = WGMath.workspaceRangeForGroup(groupId, workspacesPerMonitor, getMonitorCount());
        const allToplevels = Hyprland.toplevels?.values || [];
        const list = [];
        for (let i = 0; i < allToplevels.length; i++) {
            const top = allToplevels[i];
            if (!top) continue;
            const wsId = top.workspace?.id ?? top.lastIpcObject?.workspace?.id;
            if (wsId !== undefined && wsId >= range.start && wsId <= range.end) {
                list.push(top);
            }
        }
        return list;
    }
    function buildWindowRows(groupId) {
        const wins = root.windowsInGroup(groupId);
        const list = [];
        for (let i = 0; i < wins.length; i++) {
            const top = wins[i];
            if (!top) continue;
            const wsId = top.workspace?.id ?? top.lastIpcObject?.workspace?.id;
            if (wsId === undefined) continue;
            const subWs = calcSubWorkspaceFromWorkspace(wsId);
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
        list.sort((a, b) => a.subWs - b.subWs);
        return list;
    }

    readonly property var windowRowsByGroup: {
        const groups = root.groups || [];
        const tops = Hyprland.toplevels?.values || [];
        const map = {};
        for (let i = 0; i < groups.length; i++) {
            map[groups[i].id] = root.buildWindowRows(groups[i].id);
        }
        return map;
    }

    function luaEscape(s) {
        return String(s || "").replace(/\\/g, "\\\\").replace(/"/g, '\\"').replace(/\n/g, " ").replace(/\r/g, " ");
    }

    function switchToGroup(groupId) {
        const g = WGMath.parseGroupId(groupId);
        if (g === -1 || g > root.groups.length)
            return "INVALID_GROUP";
        if (g === root.activeGroupIndex)
            return "ALREADY_ACTIVE";

        if (root.overviewOpen || root.createModalOpen || root.contentVisible) {
            root.closeOverview();
        }

        const mons = root.snapshotCurrent();
        const focusedMonName = Hyprland.focusedMonitor?.name || (mons[0] ? mons[0].name : "");
        const batchCommands = root.buildFocusBatch(g, mons, focusedMonName);
        const fullBatch = batchCommands.join("; ");
        Quickshell.execDetached(["hyprctl", "--batch", fullBatch]);

        root.activeGroupIndex = g;
        root.commitState(false);
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
        const g = WGMath.parseGroupId(groupId);
        if (g === -1 || g > root.groups.length)
            return "INVALID_GROUP";
        if (g === root.activeGroupIndex)
            return "ALREADY_ACTIVE";

        if (root.overviewOpen || root.createModalOpen || root.contentVisible) {
            root.closeOverview();
        }

        const mons = root.snapshotCurrent();
        const focusedMon = Hyprland.focusedMonitor;
        const focusedMonName = focusedMon?.name || (mons[0] ? mons[0].name : "");
        const focusedMonIdx = focusedMon ? getMonitorIndex(focusedMon.name) : 0;
        root.ensureTargetWorkspaces(g, mons);
        const targetWsForFocusedMon = root.lastActiveWorkspaces[g]?.[focusedMonName] || calcWorkspace(g, focusedMonIdx, 1);
        const batchCommands = [root.moveWindowCommand(targetWsForFocusedMon)];
        for (const cmd of root.buildFocusBatch(g, mons, focusedMonName)) {
            batchCommands.push(cmd);
        }
        const fullBatch = batchCommands.join("; ");
        Quickshell.execDetached(["hyprctl", "--batch", fullBatch]);

        root.activeGroupIndex = g;
        root.commitState(false);
        return "SUCCESS";
    }

    function switchToSubWorkspace(subWsStr, targetMonName) {
        let sub = WGMath.parseIndex(subWsStr);
        if (sub === -1)
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
        let sub = WGMath.parseIndex(subWsStr);
        if (sub === -1)
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
        if (dir !== "next" && dir !== "prev")
            return "INVALID_DIRECTION";
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
        if (!root.overviewOpen && !root.createModalOpen && !root.deleteConfirmOpen && !root.contentVisible)
            return "OVERVIEW_CLOSED";
        if (root.isClosing)
            return "OVERVIEW_CLOSED";
        if (root.createModalOpen) {
            root.createModalOpen = false;
        }
        if (root.deleteConfirmOpen) {
            root.closeDeleteConfirm();
        }
        root.contentVisible = false;
        root.mouseMovedSinceOpen = false;
        root.lastGlobalMouseX = -1;
        root.lastGlobalMouseY = -1;
        root.isClosing = true;
        overviewCloseTimer.restart();
        return "OVERVIEW_CLOSED";
    }
    function closeDeleteConfirm() {
        root.deleteConfirmOpen = false;
        root.groupToDeleteId = 0;
        root.groupToDeleteName = "";
        root.groupToDeleteWindowCount = 0;
    }

    function closeTopmost() {
        if (root.deleteConfirmOpen) {
            root.closeDeleteConfirm();
            return "CONFIRM_CLOSED";
        }
        if (root.createModalOpen) {
            return root.closeCreateGroup();
        }
        return root.closeOverview();
    }

    function switchAndClose(gid) {
        root.closeOverview();
        Qt.callLater(() => {
            root.switchToGroup(gid);
        });
    }
    function focusWindowRow(row) {
        if (row.address) {
            if (root.isLua) {
                Quickshell.execDetached(["hyprctl", "dispatch", `hl.dsp.focus({ window = 'address:${row.address}' })`]);
            } else {
                Quickshell.execDetached(["hyprctl", "dispatch", "focuswindow", "address:" + row.address]);
            }
        } else {
            root.switchToSubWorkspace(row.subWs);
        }
        root.closeOverview();
    }

    function routeFocus() {
        Qt.callLater(() => {
            if (root.deleteConfirmOpen) {
                deleteConfirmContainer.forceActiveFocus();
            } else if (root.createModalOpen) {
                createModalContainer.focusNameInput();
            } else if (root.overviewOpen) {
                focusScope.forceActiveFocus();
                overviewGrid.ensureVisible(root.selectedOverviewIndex);
            }
        });
    }

    function clampSelection() {
        const count = root.groups ? root.groups.length : 0;
        if (root.selectedOverviewIndex >= count) {
            root.selectedOverviewIndex = Math.max(0, count - 1);
        }
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
        const g = WGMath.parseGroupId(groupId);
        if (g === -1 || g > root.groups.length)
            return "INVALID_GROUP";

        overviewCloseTimer.stop();
        root.isClosing = false;
        root.editingGroupId = g;
        const target = root.groups[g - 1];
        root.formGroupName = target?.name || ("Group " + g);
        root.formGroupIcon = target?.icon || "󰅩";
        root.formGroupColor = target?.color || "#89b4fa";
        root.formSwitchImmediate = false;
        root.overviewOpen = false;
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
        const g = WGMath.parseGroupId(groupId);
        if (g === -1 || g > root.groups.length)
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
        root.commitState(true);
        return "SUCCESS";
    }

    function buildReorderMoveBatchLua(mapping, totalPerGroup) {
        const batchCommands = [];
        const allToplevels = Hyprland.toplevels?.values || [];
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
        return batchCommands;
    }

    function buildReorderMoveBatchHypr(mapping, totalPerGroup) {
        const batchCommands = [];
        const allToplevels = Hyprland.toplevels?.values || [];
        for (let i = 0; i < allToplevels.length; i++) {
            const top = allToplevels[i];
            if (!top) continue;
            const wsId = top.workspace?.id ?? top.lastIpcObject?.workspace?.id;
            const addr = root.formatWindowAddress(top);
            if (!addr || wsId === undefined || wsId < 1) continue;
            const oldG = rawGroupFromWorkspace(wsId);
            const newG = mapping[oldG];
            if (newG !== undefined && newG !== oldG) {
                const offset = (wsId - 1) % totalPerGroup;
                const targetWs = (newG - 1) * totalPerGroup + 1 + offset;
                batchCommands.push(`dispatch movetoworkspacesilent ${targetWs},address:${addr}`);
            }
        }
        return batchCommands;
    }

    function reorderGroup(fromIdx, toIdx) {
        const from = WGMath.parseIndex(fromIdx);
        const to = WGMath.parseIndex(toIdx);
        if (from === -1 || to === -1 || from >= root.groups.length || to >= root.groups.length)
            return "INVALID_RANGE";
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

        const batchCommands = root.isLua ? root.buildReorderMoveBatchLua(mapping, totalPerGroup) : root.buildReorderMoveBatchHypr(mapping, totalPerGroup);

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
            for (const cmd of root.buildFocusBatch(newActive, mons, focusedMonName)) {
                batchCommands.push(cmd);
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
        root.clampSelection();
        root.commitState(true);
        return "OK";
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
        root.clampSelection();
        if (!root.lastActiveWorkspaces[newId])
            root.lastActiveWorkspaces[newId] = {};
        const sortedMons = getSortedMonitors();
        for (let i = 0; i < sortedMons.length; i++) {
            root.lastActiveWorkspaces[newId][sortedMons[i].name] = calcWorkspace(newId, i, 1);
        }
        root.commitState(true);

        if (shouldSwitch !== false) {
            root.switchAndClose(newId);
        } else {
            root.closeCreateGroup();
        }
        return "SUCCESS";
    }

    function getWindowsInGroup(groupId) {
        return root.windowsInGroup(groupId);
    }

    function evacuateGroupWindows(g, startWs, endWs, totalPerGroup, evacuateTargetGroup, activeWorkspacesSet, allToplevels) {
        const batchCommands = [];
        const renamed = {};
        if (root.isLua) {
            const groupGWsWithWindows = {};
            const groupWins = root.windowsInGroup(g);
            for (let i = 0; i < groupWins.length; i++) {
                const wid = groupWins[i].workspace?.id ?? groupWins[i].lastIpcObject?.workspace?.id;
                if (wid !== undefined && wid > 0) groupGWsWithWindows[wid] = true;
            }
            for (const wsIdStr in groupGWsWithWindows) {
                const wsId = parseInt(wsIdStr);
                const withinGroup = (wsId - 1) % totalPerGroup;
                const targetWs = (evacuateTargetGroup - 1) * totalPerGroup + 1 + withinGroup;
                if (g > 1 && !activeWorkspacesSet[targetWs]) {
                    batchCommands.push(`dispatch hl.dsp.workspace.change_id({ workspace = '${wsId}', id = ${targetWs} })`);
                    renamed[wsId] = true;
                    activeWorkspacesSet[targetWs] = true;
                }
            }
            for (let i = 0; i < allToplevels.length; i++) {
                const top = allToplevels[i];
                if (!top) continue;
                const wsId = top.workspace?.id ?? top.lastIpcObject?.workspace?.id;
                const addr = root.formatWindowAddress(top);
                if (!addr || wsId === undefined) continue;
                if (wsId >= startWs && wsId <= endWs) {
                    if (!renamed[wsId]) {
                        const withinGroup = (wsId - 1) % totalPerGroup;
                        const targetWs = (evacuateTargetGroup - 1) * totalPerGroup + 1 + withinGroup;
                        batchCommands.push(`dispatch hl.dsp.window.move({ workspace = '${targetWs}', silent = true, window = 'address:${addr}' })`);
                    }
                }
            }
        } else {
            for (let i = 0; i < allToplevels.length; i++) {
                const top = allToplevels[i];
                if (!top) continue;
                const wsId = top.workspace?.id ?? top.lastIpcObject?.workspace?.id;
                const addr = root.formatWindowAddress(top);
                if (!addr || wsId === undefined) continue;
                if (wsId >= startWs && wsId <= endWs) {
                    const withinGroup = (wsId - 1) % totalPerGroup;
                    const targetWs = (evacuateTargetGroup - 1) * totalPerGroup + 1 + withinGroup;
                    batchCommands.push(`dispatch movetoworkspacesilent ${targetWs},address:${addr}`);
                }
            }
        }
        return { commands: batchCommands, renamed: renamed };
    }

    function shiftHigherGroups(endWs, totalPerGroup, activeWorkspacesSet, allToplevels) {
        const batchCommands = [];
        if (root.isLua) {
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
                const addr = root.formatWindowAddress(top);
                if (!addr || wsId === undefined) continue;
                if (wsId > endWs) {
                    const shiftedWs = wsId - totalPerGroup;
                    batchCommands.push(`dispatch movetoworkspacesilent ${shiftedWs},address:${addr}`);
                }
            }
        }
        return batchCommands;
    }

    function refocusAfterDelete(newActive, newLastActive, sortedMons, focusedMonName) {
        const batchCommands = [];
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
        return batchCommands;
    }

    function deleteGroup(groupId) {
        const g = WGMath.parseGroupId(groupId);
        if (g === -1 || g > root.groups.length)
            return "INVALID_GROUP";
        if (root.groups.length <= 1)
            return "CANNOT_DELETE_LAST_GROUP";

        const monCount = root.getMonitorCount();
        const totalPerGroup = root.workspacesPerMonitor * monCount;
        const startWs = (g - 1) * totalPerGroup + 1;
        const endWs = g * totalPerGroup;

        const sortedMons = root.snapshotCurrent();
        const focusedMonName = Hyprland.focusedMonitor?.name || (sortedMons[0] ? sortedMons[0].name : "");
        const oldActive = root.activeGroupIndex;

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

        const evacuateTargetGroup = (g === 1) ? 2 : 1;
        const evac = root.evacuateGroupWindows(g, startWs, endWs, totalPerGroup, evacuateTargetGroup, activeWorkspacesSet, allToplevels);
        for (const cmd of evac.commands) {
            batchCommands.push(cmd);
        }
        for (const cmd of root.shiftHigherGroups(endWs, totalPerGroup, activeWorkspacesSet, allToplevels)) {
            batchCommands.push(cmd);
        }

        for (const cmd of root.refocusAfterDelete(newActive, newLastActive, sortedMons, focusedMonName)) {
            batchCommands.push(cmd);
        }

        if (batchCommands.length > 0) {
            Quickshell.execDetached(["hyprctl", "--batch", batchCommands.join("; ")]);
        }

        root.activeGroupIndex = newActive;
        root.groups = newGroups;
        root.lastActiveWorkspaces = newLastActive;
        root.sanitizeLastActiveWorkspaces();
        root.clampSelection();

        root.commitState(true);
        return "SUCCESS";
    }

    function deleteCurrentGroup() {
        return deleteGroup(root.activeGroupIndex);
    }

    function confirmDeleteGroup(groupId) {
        const g = WGMath.parseGroupId(groupId);
        if (g === -1 || g > root.groups.length || root.groups.length <= 1)
            return "INVALID_GROUP";
        const grp = root.groups[g - 1];
        const wins = getWindowsInGroup(g);
        if (wins.length === 0) {
            root.deleteGroup(g);
            return "OK";
        } else {
            root.groupToDeleteId = g;
            root.groupToDeleteName = grp?.name || ("Group " + g);
            root.groupToDeleteWindowCount = wins.length;
            root.deleteConfirmOpen = true;
            return "CONFIRM_OPEN";
        }
    }

    function resetToOnLaunchGroups() {
        root.groups = JSON.parse(JSON.stringify(root.onLaunchGroups));
        root.sanitizeLastActiveWorkspaces();
        root.ensureGroupsCoverAllWorkspaces();
        if (root.activeGroupIndex > root.groups.length) {
            root.switchToGroup(1);
        }
        root.commitState(true);
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
            const escapedName = root.luaEscape(g.name);
            const escapedIcon = root.luaEscape(g.icon);
            const color = root.luaEscape(g.color || Defaults.FALLBACK_COLOR);
            return `    { id = ${g.id}, name = "${escapedName}", icon = "${escapedIcon}", color = "${color}" },`;
        }).join("\n");

        const priorityLua = root.monitorPriority.map(p => `"${root.luaEscape(p)}"`).join(", ");
        const wsPerMonitorLua = Number.isInteger(root.workspacesPerMonitor) ? root.workspacesPerMonitor : Defaults.WS_DEFAULT;

        const luaContent = `-- Auto-generated by DMS Workspace Groups Plugin
-- DO NOT EDIT DIRECTLY: Changes will be overwritten when plugin settings change.

local M = {}

M.groups = {
${groupsLua}
}

M.workspaces_per_monitor = ${wsPerMonitorLua}
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
  hl.bind(mainMod .. " + CTRL + mouse_down", M.cycle_workspaces("next"))
  hl.bind(mainMod .. " + CTRL + mouse_up", M.cycle_workspaces("prev"))
end

return M
`;
        for (const line of luaContent.split("\n")) {
            if (line === "WG_GROUPS_EOF") {
                console.warn("[WorkspaceGroups] Refusing to write Lua config: content collides with heredoc delimiter");
                return;
            }
        }

        const tmpFile = luaConfigPath + ".tmp." + Date.now();
        Proc.runCommand("save-workspace-groups-lua", ["sh", "-c", `mkdir -p "${hyprDmsDir}" && cat << 'WG_GROUPS_EOF' > "${tmpFile}"\n${luaContent}\nWG_GROUPS_EOF\nmv -f "${tmpFile}" "${luaConfigPath}"\n`], (output, exitCode) => {
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
                                root.closeTopmost();
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
                                root.routeFocus();
                            } else {
                                delayedGrabTimer.stop();
                                grab.active = false;
                                grab.hasBeenActivated = false;
                                overviewGrid.resetScroll();
                            }
                        }
                        function onSelectedOverviewIndexChanged() {
                            if (root.contentVisible) {
                                overviewGrid.ensureVisible(root.selectedOverviewIndex);
                            }
                        }
                        function onCreateModalOpenChanged() {
                            if (root.contentVisible) {
                                if (root.createModalOpen) {
                                    root.routeFocus();
                                } else if (root.overviewOpen) {
                                    root.routeFocus();
                                }
                            }
                        }
                        function onDeleteConfirmOpenChanged() {
                            if (root.contentVisible) {
                                if (root.deleteConfirmOpen) {
                                    root.routeFocus();
                                } else if (root.overviewOpen) {
                                    root.routeFocus();
                                }
                            }
                        }
                    }

                    Connections {
                        target: overviewWindow
                        function onActiveFocusItemChanged() {
                            if (root.contentVisible && !overviewWindow.activeFocusItem) {
                                if (root.createModalOpen) {
                                    createModalContainer.focusNameInput();
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
                                root.closeTopmost();
                            }
                        }
                    }

                    WGModalCard {
                        id: overviewModalContainer
                        anchors.centerIn: parent
                        width: Math.min(parent.width - 60, Math.max(760, root.gridColumns * 360 + (root.gridColumns - 1) * Theme.spacingM + Theme.spacingXL * 2))
                        height: Math.min(parent.height - 60, root.gridRows <= 1 ? 400 : (root.gridRows === 2 ? 650 : Math.min(880, parent.height - 60)))
                        visible: root.overviewOpen && !root.createModalOpen && !root.deleteConfirmOpen
                        shown: root.contentVisible && visible

                            OverviewGrid {
                                id: overviewGrid
                                anchors.fill: parent
                                anchors.margins: Theme.spacingXL
                                groups: root.groups
                                activeGroupIndex: root.activeGroupIndex
                                selectedIndex: root.selectedOverviewIndex
                                rowsByGroup: root.windowRowsByGroup
                                totalItems: root.totalOverviewItems
                                columns: root.gridColumns
                                contentVisible: root.contentVisible
                                controller: dragCtrl
                                dragContainer: overviewModalContainer
                                hoverArmed: root.mouseMovedSinceOpen
                                deletable: root.groups.length > 1
                                onSwitchRequested: gid => root.switchAndClose(gid)
                                onEditRequested: gid => root.openEditGroup(gid)
                                onDeleteRequested: gid => root.confirmDeleteGroup(gid)
                                onCreateRequested: root.openCreateGroup()
                                onReorderRequested: (from, to) => {
                                    root.reorderGroup(from, to);
                                    root.selectedOverviewIndex = to;
                                }
                                onSelectionRequested: idx => {
                                    root.selectedOverviewIndex = idx;
                                }
                                onFocusRequested: row => root.focusWindowRow(row)
                            }
                    }

                    DragGhost {
                        id: dragProxy
                        visible: root.isDraggingCard && root.dragFromIndex >= 0 && root.dragFromIndex < root.groups.length
                        cardWidth: overviewGrid.cardWidth
                        cardHeight: overviewGrid.cardHeight
                        group: (root.dragFromIndex >= 0 && root.dragFromIndex < root.groups.length) ? root.groups[root.dragFromIndex] : null
                        targetSlot: root.dragTargetIndex
                        posX: overviewModalContainer.x + Math.max(0, Math.min(overviewModalContainer.width - cardWidth, root.dragMouseX - cardWidth / 2))
                        posY: overviewModalContainer.y + Math.max(0, Math.min(overviewModalContainer.height - cardHeight, root.dragMouseY - 30))
                    }

                    CreateEditModal {
                        id: createModalContainer
                        anchors.centerIn: parent
                        width: Math.min(parent.width - 40, 520)
                        visible: root.createModalOpen
                        shown: visible
                        editingId: root.editingGroupId
                        initialName: root.formGroupName
                        initialIcon: root.formGroupIcon
                        initialColor: root.formGroupColor
                        initialSwitch: root.formSwitchImmediate
                        colorList: root.colorPalette
                        iconPool: root.nerdfontPool
                        focusScopeItem: focusScope
                        onSubmitted: (editingId, name, icon, color, switchImmediate) => {
                            if (editingId > 0) {
                                root.updateGroup(editingId, name, icon, color);
                            } else {
                                root.createGroup(name, icon, color, switchImmediate);
                            }
                        }
                        onClosed: root.closeCreateGroup()
                    }

                    DeleteConfirmModal {
                        id: deleteConfirmContainer
                        anchors.centerIn: parent
                        width: Math.min(parent.width - 40, 460)
                        visible: root.deleteConfirmOpen
                        shown: visible
                        groupId: root.groupToDeleteId
                        groupName: root.groupToDeleteName
                        windowCount: root.groupToDeleteWindowCount
                        onConfirmed: {
                            const g = root.groupToDeleteId;
                            root.closeDeleteConfirm();
                            root.deleteGroup(g);
                        }
                        onClosed: root.closeDeleteConfirm()
                    }

                    FocusScope {
                        id: focusScope
                        anchors.fill: parent
                        focus: root.contentVisible && overviewWindow.monitorIsFocused

                        Keys.onEscapePressed: event => {
                            if (root.isDraggingCard) {
                                dragCtrl.cancel();
                            } else {
                                root.closeTopmost();
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
                                    root.switchAndClose(targetId);
                                    event.accepted = true;
                                    return;
                                }
                            } else if (event.key === Qt.Key_0) {
                                if (root.groups.length >= 10) {
                                    root.switchAndClose(10);
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
                                        root.switchAndClose(chosen.id);
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
