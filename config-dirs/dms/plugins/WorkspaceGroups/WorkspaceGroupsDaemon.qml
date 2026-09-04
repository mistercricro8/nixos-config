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
        { "id": 1, "name": "Code", "icon": "󰅩", "color": "#89b4fa" },
        { "id": 2, "name": "Browse", "icon": "󰈹", "color": "#f38ba8" },
        { "id": 3, "name": "Media", "icon": "󰋋", "color": "#a6e3a1" },
        { "id": 4, "name": "System", "icon": "󰇄", "color": "#fab387" }
    ]

    property var groups: {
        if (pluginData && pluginData.groups && Array.isArray(pluginData.groups) && pluginData.groups.length > 0)
            return pluginData.groups;
        return defaultGroups;
    }

    property int workspacesPerMonitor: (pluginData && pluginData.workspacesPerMonitor) ? pluginData.workspacesPerMonitor : 10
    property var monitorPriority: (pluginData && pluginData.monitorPriority) ? pluginData.monitorPriority : ["HDMI-A-1", "DP-1"]
    property bool hideEmptyWorkspaces: (pluginData && pluginData.hideEmptyWorkspaces !== undefined) ? pluginData.hideEmptyWorkspaces : true

    property int activeGroupIndex: 1
    property var lastActiveWorkspaces: ({})
    property bool overviewOpen: false
    property bool contentVisible: false
    property bool isClosing: false
    property int selectedOverviewIndex: 0

    Timer {
        id: overviewCloseTimer
        interval: Theme.modalAnimationDuration + 50
        repeat: false
        onTriggered: {
            root.isClosing = false;
            root.overviewOpen = false;
        }
    }

    readonly property bool isLua: CompositorService.isHyprland && (Hyprland.usingLua === true || HyprlandService.luaConfigActive)

    readonly property string configDir: Paths.strip(StandardPaths.writableLocation(StandardPaths.ConfigLocation))
    readonly property string hyprDmsDir: configDir + "/hypr/dms"
    readonly property string luaConfigPath: hyprDmsDir + "/workspace_groups.lua"

    Component.onCompleted: {
        syncFromCurrentWorkspace();
        notifyState();
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
    }

    function syncFromCurrentWorkspace() {
        const activeWs = Hyprland.focusedWorkspace?.id;
        if (!activeWs || activeWs < 1)
            return;

        const g = calcGroupFromWorkspace(activeWs);
        if (g !== root.activeGroupIndex) {
            root.activeGroupIndex = g;
            root.notifyState();
        }

        const activeMon = Hyprland.focusedMonitor?.name;
        if (activeMon) {
            if (!root.lastActiveWorkspaces[g])
                root.lastActiveWorkspaces[g] = {};
            root.lastActiveWorkspaces[g][activeMon] = activeWs;
        }
    }

    function getSortedMonitors() {
        const mons = Hyprland.monitors?.values || [];
        if (mons.length === 0)
            return [{ "name": "default", "id": 0 }];

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

    function calcWorkspace(groupId, monIdx, subWs) {
        const monCount = getMonitorCount();
        return (groupId - 1) * (workspacesPerMonitor * monCount) + (monIdx * workspacesPerMonitor) + subWs;
    }

    function calcGroupFromWorkspace(wsId) {
        const monCount = getMonitorCount();
        const totalPerGroup = workspacesPerMonitor * monCount;
        if (totalPerGroup <= 0)
            return 1;
        const g = Math.floor((wsId - 1) / totalPerGroup) + 1;
        return Math.max(1, Math.min(groups.length, g));
    }

    function calcSubWorkspaceFromWorkspace(wsId) {
        const monCount = getMonitorCount();
        const totalPerGroup = workspacesPerMonitor * monCount;
        if (totalPerGroup <= 0)
            return 1;
        const withinGroup = (wsId - 1) % totalPerGroup;
        return (withinGroup % workspacesPerMonitor) + 1;
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
    }

    function switchToGroup(groupId) {
        const g = parseInt(groupId);
        if (isNaN(g) || g < 1 || g > root.groups.length)
            return "INVALID_GROUP";
        if (g === root.activeGroupIndex)
            return "ALREADY_ACTIVE";

        const mons = getSortedMonitors();
        const focusedMonName = Hyprland.focusedMonitor?.name || (mons[0] ? mons[0].name : "");

        for (let i = 0; i < mons.length; i++) {
            const m = mons[i];
            const curWs = m.activeWorkspace ? m.activeWorkspace.id : null;
            if (curWs) {
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
            let targetWs = root.lastActiveWorkspaces[g][m.name];
            if (!targetWs) {
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

        const focusedMon = Hyprland.focusedMonitor;
        const monIdx = focusedMon ? getMonitorIndex(focusedMon.name) : 0;
        let targetWs = root.lastActiveWorkspaces[g]?.[focusedMon?.name];
        if (!targetWs) {
            targetWs = calcWorkspace(g, monIdx, 1);
        }
        if (root.isLua) {
            Quickshell.execDetached(["hyprctl", "dispatch", `hl.dsp.window.move({ workspace = '${targetWs}' })`]);
        } else {
            Quickshell.execDetached(["hyprctl", "dispatch", "movetoworkspace", targetWs.toString()]);
        }
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

        let monName = targetMonName;
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

    function moveWindowToSubWorkspace(subWsStr) {
        let sub = parseInt(subWsStr);
        if (isNaN(sub))
            return "INVALID_SUB_WORKSPACE";
        if (sub === 0)
            sub = 10;
        if (sub < 1 || sub > root.workspacesPerMonitor)
            return "OUT_OF_RANGE";

        const focusedMon = Hyprland.focusedMonitor;
        const monIdx = focusedMon ? getMonitorIndex(focusedMon.name) : 0;
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
        root.overviewOpen = true;
        root.selectedOverviewIndex = root.activeGroupIndex - 1;
        Qt.callLater(() => {
            root.contentVisible = true;
        });
        return "OVERVIEW_OPEN";
    }

    function closeOverview() {
        if (!root.overviewOpen && !root.contentVisible)
            return "OVERVIEW_CLOSED";
        root.contentVisible = false;
        root.isClosing = true;
        overviewCloseTimer.restart();
        return "OVERVIEW_CLOSED";
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

    function writeLuaConfig() {
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

  -- Group direct switch & move
  for _, g in ipairs(M.groups) do
    local n = tostring(g.id)
    hl.bind(mainMod .. " + ALT + " .. n, M.switch_group(g.id))
    hl.bind(mainMod .. " + ALT + SHIFT + " .. n, M.move_to_group(g.id))
  end

  -- Group cycling
  hl.bind(mainMod .. " + ALT + Right", M.cycle_groups("next"))
  hl.bind(mainMod .. " + ALT + Left", M.cycle_groups("prev"))

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

        Proc.runCommand("save-workspace-groups-lua", ["sh", "-c", `mkdir -p "${hyprDmsDir}" && cat << 'EOF' > "${luaConfigPath}"\n${luaContent}\nEOF\n`], (output, exitCode) => {
            if (exitCode !== 0) {
                console.warn("[WorkspaceGroups] Failed to write Lua config:", output);
            }
        });
    }

    IpcHandler {
        target: "workspaceGroups"

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

        function moveWindowToSubWorkspace(subWs: string): string {
            return root.moveWindowToSubWorkspace(subWs);
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
            active: root.overviewOpen || root.isClosing
            asynchronous: false

            sourceComponent: Variants {
                model: Quickshell.screens

                PanelWindow {
                    id: overviewWindow
                    required property var modelData

                    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(overviewWindow.screen)
                    property bool monitorIsFocused: (Hyprland.focusedMonitor?.id == monitor?.id)

                    screen: modelData
                    visible: root.overviewOpen || root.isClosing
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
                            if (hasBeenActivated && root.overviewOpen && !root.isClosing) {
                                root.closeOverview();
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
                                Qt.callLater(() => focusScope.forceActiveFocus());
                            } else {
                                delayedGrabTimer.stop();
                                grab.active = false;
                                grab.hasBeenActivated = false;
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
                                root.closeOverview();
                            }
                        }
                    }

                    Item {
                        id: modalCenter
                        anchors.centerIn: parent
                        width: Math.min(parent.width - 80, 1100)
                        height: 500
                        transformOrigin: Item.Center

                        opacity: root.contentVisible ? 1 : 0
                        scale: root.contentVisible ? 1.0 : 0.96

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
                                spacing: Theme.spacingL

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

                                    StyledText {
                                        text: "Press [1-4] or Click to switch • Esc to close"
                                        font.pixelSize: Theme.fontSizeSmall
                                        color: Theme.surfaceVariantText
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    spacing: Theme.spacingL

                                    Repeater {
                                        model: root.groups

                                        Rectangle {
                                            id: groupCard
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            radius: Theme.cornerRadius
                                            property bool isCurrentActive: root.activeGroupIndex === modelData.id
                                            property bool isSelected: root.selectedOverviewIndex === index
                                            readonly property var cardGroupData: modelData

                                            readonly property var groupWindows: {
                                                const allToplevels = Hyprland.toplevels?.values || [];
                                                const list = [];
                                                const monCount = root.getMonitorCount();
                                                const totalPerGroup = root.workspacesPerMonitor * monCount;
                                                const startWs = (groupCard.cardGroupData.id - 1) * totalPerGroup + 1;
                                                const endWs = groupCard.cardGroupData.id * totalPerGroup;

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
                                                        const address = top.address || ipcObj.address || "";
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

                                            color: isCurrentActive ? Theme.primaryContainer : (isSelected ? Theme.surfaceContainerHighest : Theme.surfaceContainerLow)
                                            border.color: isCurrentActive ? Theme.primary : (isSelected ? Theme.secondary : Theme.outlineVariant)
                                            border.width: (isCurrentActive || isSelected) ? 2 : 1

                                            scale: cardMouseArea.containsMouse ? 1.02 : 1.0
                                            Behavior on scale { NumberAnimation { duration: 120 } }
                                            Behavior on color { ColorAnimation { duration: 150 } }

                                            MouseArea {
                                                id: cardMouseArea
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    root.switchToGroup(modelData.id);
                                                    root.closeOverview();
                                                }
                                            }

                                            ColumnLayout {
                                                anchors.fill: parent
                                                anchors.margins: Theme.spacingM
                                                spacing: Theme.spacingS

                                                RowLayout {
                                                    Layout.fillWidth: true

                                                    Rectangle {
                                                        width: 24
                                                        height: 24
                                                        radius: 12
                                                        color: groupCard.isCurrentActive ? Theme.primary : Theme.surfaceContainerHighest

                                                        StyledText {
                                                            anchors.centerIn: parent
                                                            text: modelData.id.toString()
                                                            font.pixelSize: Theme.fontSizeSmall
                                                            font.weight: Font.Bold
                                                            color: groupCard.isCurrentActive ? Theme.onPrimary : Theme.surfaceText
                                                        }
                                                    }

                                                    Item { Layout.fillWidth: true }

                                                    Rectangle {
                                                        visible: groupCard.isCurrentActive
                                                        height: 20
                                                        width: 54
                                                        radius: 10
                                                        color: Theme.primary

                                                        StyledText {
                                                            anchors.centerIn: parent
                                                            text: "ACTIVE"
                                                            font.pixelSize: 10
                                                            font.weight: Font.Bold
                                                            color: Theme.onPrimary
                                                        }
                                                    }
                                                }

                                                Item { height: Theme.spacingS }

                                                StyledText {
                                                    Layout.alignment: Qt.AlignHCenter
                                                    text: modelData.icon || "󰅩"
                                                    font.pixelSize: 42
                                                    color: modelData.color || Theme.primary
                                                }

                                                StyledText {
                                                    Layout.alignment: Qt.AlignHCenter
                                                    text: modelData.name || ("Group " + modelData.id)
                                                    font.pixelSize: Theme.fontSizeLarge
                                                    font.weight: Font.Bold
                                                    color: Theme.surfaceText
                                                }

                                                Item { height: Theme.spacingS }

                                                Rectangle {
                                                    Layout.fillWidth: true
                                                    height: 1
                                                    color: Theme.outlineVariant
                                                }

                                                Item {
                                                    Layout.fillWidth: true
                                                    Layout.fillHeight: true
                                                    clip: true

                                                    ScrollView {
                                                        anchors.fill: parent
                                                        visible: groupCard.groupWindows.length > 0
                                                        clip: true

                                                        ColumnLayout {
                                                            width: parent.width
                                                            spacing: Theme.spacingXS

                                                            Repeater {
                                                                model: groupCard.groupWindows

                                                                Rectangle {
                                                                    Layout.fillWidth: true
                                                                    height: 38
                                                                    radius: Theme.cornerRadiusSmall
                                                                    clip: true
                                                                    color: winMouse.containsMouse ? Theme.surfaceContainerHighest : (modelData.isFocused ? Theme.withAlpha(Theme.primary, 0.15) : Theme.surfaceContainerLowest)
                                                                    border.color: modelData.isFocused ? Theme.primary : (winMouse.containsMouse ? Theme.outlineVariant : "transparent")
                                                                    border.width: 1

                                                                    Behavior on color { ColorAnimation { duration: 100 } }
                                                                    Behavior on border.color { ColorAnimation { duration: 100 } }

                                                                    MouseArea {
                                                                        id: winMouse
                                                                        anchors.fill: parent
                                                                        hoverEnabled: true
                                                                        cursorShape: Qt.PointingHandCursor
                                                                        onClicked: {
                                                                            if (modelData.address) {
                                                                                Quickshell.execDetached(["hyprctl", "dispatch", "focuswindow", "address:" + modelData.address]);
                                                                            } else {
                                                                                root.switchToSubWorkspace(modelData.subWs);
                                                                            }
                                                                            root.closeOverview();
                                                                        }
                                                                    }

                                                                    RowLayout {
                                                                        anchors.fill: parent
                                                                        anchors.leftMargin: Theme.spacingS
                                                                        anchors.rightMargin: Theme.spacingS
                                                                        spacing: Theme.spacingS

                                                                        Rectangle {
                                                                            width: 22
                                                                            height: 22
                                                                            radius: 4
                                                                            color: Theme.withAlpha(groupCard.cardGroupData.color || Theme.primary, 0.2)

                                                                            StyledText {
                                                                                anchors.centerIn: parent
                                                                                text: modelData.subWs.toString()
                                                                                font.pixelSize: 11
                                                                                font.weight: Font.Bold
                                                                                color: groupCard.cardGroupData.color || Theme.primary
                                                                            }
                                                                        }

                                                                        Item {
                                                                            width: 20
                                                                            height: 20
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
                                                                                size: 16
                                                                                color: Theme.surfaceVariantText
                                                                                visible: !modelData.icon || (modelData.icon !== "" && winIconImg.status !== Image.Ready)
                                                                            }
                                                                        }

                                                                        ColumnLayout {
                                                                            Layout.fillWidth: true
                                                                            spacing: 0
                                                                            clip: true

                                                                            StyledText {
                                                                                text: modelData.appName
                                                                                font.pixelSize: Theme.fontSizeSmall
                                                                                font.weight: Font.DemiBold
                                                                                color: Theme.surfaceText
                                                                                wrapMode: Text.NoWrap
                                                                                elide: Text.ElideRight
                                                                                maximumLineCount: 1
                                                                                Layout.fillWidth: true
                                                                            }

                                                                            StyledText {
                                                                                text: modelData.title
                                                                                font.pixelSize: Theme.fontSizeSmall - 2
                                                                                color: Theme.surfaceVariantText
                                                                                wrapMode: Text.NoWrap
                                                                                elide: Text.ElideRight
                                                                                maximumLineCount: 1
                                                                                Layout.fillWidth: true
                                                                                visible: modelData.title !== modelData.appName
                                                                            }
                                                                        }

                                                                        Rectangle {
                                                                            width: 6
                                                                            height: 6
                                                                            radius: 3
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
                                                        visible: groupCard.groupWindows.length === 0
                                                        spacing: Theme.spacingS

                                                        DankIcon {
                                                            Layout.alignment: Qt.AlignHCenter
                                                            name: "desktop_windows"
                                                            size: 36
                                                            color: Theme.outlineMedium
                                                        }

                                                        StyledText {
                                                            Layout.alignment: Qt.AlignHCenter
                                                            text: "No open windows"
                                                            font.pixelSize: Theme.fontSizeSmall
                                                            color: Theme.surfaceVariantText
                                                            wrapMode: Text.NoWrap
                                                        }
                                                    }
                                                }
                                            }
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
                            root.closeOverview();
                            event.accepted = true;
                        }

                        Keys.onPressed: event => {
                            if (event.key >= Qt.Key_1 && event.key <= Qt.Key_9) {
                                const targetId = event.key - Qt.Key_0;
                                if (targetId <= root.groups.length) {
                                    root.switchToGroup(targetId);
                                    root.closeOverview();
                                    event.accepted = true;
                                    return;
                                }
                            }

                            if (event.key === Qt.Key_Left || event.key === Qt.Key_Up) {
                                root.selectedOverviewIndex = Math.max(0, root.selectedOverviewIndex - 1);
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Right || event.key === Qt.Key_Down || event.key === Qt.Key_Tab) {
                                root.selectedOverviewIndex = (root.selectedOverviewIndex + 1) % root.groups.length;
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                                const chosen = root.groups[root.selectedOverviewIndex];
                                if (chosen) {
                                    root.switchToGroup(chosen.id);
                                    root.closeOverview();
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
