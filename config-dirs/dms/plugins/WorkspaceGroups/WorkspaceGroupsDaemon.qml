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

    property int groupToDeleteId: 0
    property string groupToDeleteName: ""
    property int groupToDeleteWindowCount: 0

    readonly property int totalOverviewItems: (root.groups ? root.groups.length : 0) + 1
    readonly property int gridColumns: totalOverviewItems <= 4 ? 2 : (totalOverviewItems <= 9 ? 3 : 4)
    readonly property int gridRows: Math.max(1, Math.ceil(totalOverviewItems / gridColumns))

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

    Component.onCompleted: {
        root.groups = JSON.parse(JSON.stringify(root.onLaunchGroups));
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
        root.selectedOverviewIndex = Math.max(0, Math.min(root.groups.length - 1, root.activeGroupIndex - 1));
        Qt.callLater(() => {
            root.contentVisible = true;
        });
        return "OVERVIEW_OPEN";
    }

    function closeOverview() {
        if (!root.overviewOpen && !root.contentVisible)
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

    function closeCreateGroup() {
        if (!root.createModalOpen)
            return "MODAL_CLOSED";
        root.createModalOpen = false;
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
        root.notifyState();
        root.writeLuaConfig();
        Quickshell.execDetached(["hyprctl", "reload"]);

        if (shouldSwitch !== false) {
            root.switchToGroup(newId);
        }
        closeCreateGroup();
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

        const allToplevels = Hyprland.toplevels?.values || [];
        const batchCommands = [];

        for (let i = 0; i < allToplevels.length; i++) {
            const top = allToplevels[i];
            if (!top) continue;
            const wsId = top.workspace?.id ?? top.lastIpcObject?.workspace?.id;
            const addr = top.address || top.lastIpcObject?.address;
            if (!addr || wsId === undefined) continue;

            if (wsId >= startWs && wsId <= endWs) {
                const withinGroup = (wsId - 1) % totalPerGroup;
                const targetWs = 1 + withinGroup;
                batchCommands.push(`dispatch movetoworkspacesilent ${targetWs},address:${addr}`);
            } else if (wsId > endWs) {
                const shiftedWs = wsId - totalPerGroup;
                batchCommands.push(`dispatch movetoworkspacesilent ${shiftedWs},address:${addr}`);
            }
        }

        if (batchCommands.length > 0) {
            Quickshell.execDetached(["hyprctl", "--batch", batchCommands.join("; ")]);
        }

        delete root.lastActiveWorkspaces[g];
        const newLastActive = {};
        for (const k in root.lastActiveWorkspaces) {
            const numK = parseInt(k);
            if (numK < g) {
                newLastActive[numK] = root.lastActiveWorkspaces[k];
            } else if (numK > g) {
                newLastActive[numK - 1] = root.lastActiveWorkspaces[k];
            }
        }
        root.lastActiveWorkspaces = newLastActive;

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
        root.groups = newGroups;

        if (root.activeGroupIndex === g) {
            root.activeGroupIndex = Math.max(1, Math.min(g, root.groups.length));
            root.switchToGroup(root.activeGroupIndex);
        } else if (root.activeGroupIndex > g) {
            root.activeGroupIndex = root.activeGroupIndex - 1;
        }

        root.notifyState();
        root.writeLuaConfig();
        Quickshell.execDetached(["hyprctl", "reload"]);
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
        if (root.activeGroupIndex > root.groups.length) {
            root.switchToGroup(1);
        }
        root.notifyState();
        root.writeLuaConfig();
        Quickshell.execDetached(["hyprctl", "reload"]);
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

function M.open_create_group()
  return function()
    dms_ipc("workspaceGroups", "openCreateGroup")
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
                        width: Math.min(parent.width - 60, root.gridColumns === 2 ? 820 : (root.gridColumns === 3 ? 1160 : 1380))
                        height: Math.min(parent.height - 60, root.gridRows <= 1 ? 380 : (root.gridRows === 2 ? 620 : 760))
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
                                        text: "Press [1-9] to switch • [N] Add Group • [Del] Delete • Esc to close"
                                        font.pixelSize: Theme.fontSizeSmall
                                        color: Theme.surfaceVariantText
                                    }

                                    DankButton {
                                        text: "New Group"
                                        iconName: "add"
                                        onClicked: root.openCreateGroup()
                                    }
                                }

                                Flickable {
                                    id: overviewFlickable
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    clip: true
                                    contentWidth: width
                                    contentHeight: groupGrid.height
                                    boundsBehavior: Flickable.StopAtBounds

                                    Grid {
                                        id: groupGrid
                                        width: overviewFlickable.width
                                        columns: root.gridColumns
                                        columnSpacing: Theme.spacingM
                                        rowSpacing: Theme.spacingM

                                        readonly property real cardWidth: Math.max(200, Math.floor((width - (columns - 1) * columnSpacing) / columns))
                                        readonly property real cardHeight: 230

                                        Repeater {
                                            model: root.totalOverviewItems

                                            Rectangle {
                                                id: overviewCard
                                                width: groupGrid.cardWidth
                                                height: groupGrid.cardHeight
                                                radius: Theme.cornerRadius

                                                readonly property bool isAddCard: index === (root.groups ? root.groups.length : 0)
                                                readonly property var cardGroupData: isAddCard ? null : root.groups[index]
                                                readonly property bool isCurrentActive: !isAddCard && cardGroupData && root.activeGroupIndex === cardGroupData.id
                                                readonly property bool isSelected: root.selectedOverviewIndex === index

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

                                                color: isAddCard
                                                    ? (addCardMouse.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerLow)
                                                    : (isCurrentActive ? Theme.primaryContainer : (isSelected ? Theme.surfaceContainerHighest : Theme.surfaceContainerLow))

                                                border.color: isAddCard
                                                    ? (isSelected ? Theme.primary : Theme.outlineVariant)
                                                    : (isCurrentActive ? Theme.primary : (isSelected ? Theme.secondary : Theme.outlineVariant))
                                                border.width: (isCurrentActive || isSelected) ? 2 : 1

                                                scale: (isAddCard ? addCardMouse.containsMouse : cardMouseArea.containsMouse) ? 1.01 : 1.0
                                                Behavior on scale { NumberAnimation { duration: 120 } }
                                                Behavior on color { ColorAnimation { duration: 150 } }

                                                MouseArea {
                                                    id: cardMouseArea
                                                    anchors.fill: parent
                                                    enabled: !overviewCard.isAddCard
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        if (overviewCard.cardGroupData) {
                                                            root.switchToGroup(overviewCard.cardGroupData.id);
                                                            root.closeOverview();
                                                        }
                                                    }
                                                }

                                                MouseArea {
                                                    id: addCardMouse
                                                    anchors.fill: parent
                                                    enabled: overviewCard.isAddCard
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
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
                                                            width: 24
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
                                                            visible: overviewCard.isCurrentActive
                                                            height: 18
                                                            width: 48
                                                            radius: 9
                                                            color: Theme.primary

                                                            StyledText {
                                                                anchors.centerIn: parent
                                                                text: "ACTIVE"
                                                                font.pixelSize: 9
                                                                font.weight: Font.Bold
                                                                color: Theme.onPrimary
                                                            }
                                                        }

                                                        Rectangle {
                                                            visible: root.groups.length > 1
                                                            width: 26
                                                            height: 26
                                                            radius: 13
                                                            color: delBtnMouse.containsMouse ? Theme.withAlpha(Theme.error, 0.2) : "transparent"

                                                            DankIcon {
                                                                anchors.centerIn: parent
                                                                name: "delete"
                                                                size: 15
                                                                color: delBtnMouse.containsMouse ? Theme.error : Theme.outlineMedium
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
                                                        clip: true

                                                        Flickable {
                                                            id: winFlickable
                                                            anchors.fill: parent
                                                            visible: overviewCard.groupWindows.length > 0
                                                            clip: true
                                                            contentWidth: width
                                                            contentHeight: winCol.height
                                                            boundsBehavior: Flickable.StopAtBounds

                                                            Column {
                                                                id: winCol
                                                                width: winFlickable.width
                                                                spacing: 3

                                                                Repeater {
                                                                    model: overviewCard.groupWindows

                                                                    Rectangle {
                                                                        width: winCol.width
                                                                        height: 30
                                                                        radius: Theme.cornerRadiusSmall
                                                                        clip: true
                                                                        color: winMouse.containsMouse ? Theme.surfaceContainerHighest : (modelData.isFocused ? Theme.withAlpha(Theme.primary, 0.15) : Theme.surfaceContainerLowest)
                                                                        border.color: modelData.isFocused ? Theme.primary : (winMouse.containsMouse ? Theme.outlineVariant : "transparent")
                                                                        border.width: 1

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
                        id: createModalContainer
                        anchors.centerIn: parent
                        width: Math.min(parent.width - 40, 520)
                        implicitHeight: createCard.implicitHeight
                        visible: root.createModalOpen
                        scale: visible ? 1.0 : 0.95
                        opacity: visible ? 1.0 : 0.0

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
                                        text: "Create Workspace Group"
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
                                        onTextEdited: {
                                            root.formGroupName = createNameInput.text;
                                        }
                                        onAccepted: {
                                            createModalContainer.submitCreateGroup();
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
                                            onTextEdited: {
                                                root.formGroupIcon = createIconInput.text;
                                            }
                                            onAccepted: {
                                                createModalContainer.submitCreateGroup();
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
                                        text: "Create Group"
                                        iconName: "add"
                                        backgroundColor: root.formGroupColor || Theme.primary
                                        textColor: Theme.surfaceContainer
                                        onClicked: createModalContainer.submitCreateGroup()
                                    }
                                }
                            }
                        }

                        function submitCreateGroup() {
                            root.createGroup(root.formGroupName, root.formGroupIcon, root.formGroupColor, root.formSwitchImmediate);
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
                            if (root.deleteConfirmOpen) {
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

                            if (event.key >= Qt.Key_1 && event.key <= Qt.Key_9) {
                                const targetId = event.key - Qt.Key_0;
                                if (targetId <= root.groups.length) {
                                    root.switchToGroup(targetId);
                                    root.closeOverview();
                                    event.accepted = true;
                                    return;
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

                            const totalItems = root.groups.length + 1;
                            const cols = root.gridColumns;

                            if (event.key === Qt.Key_Left || event.key === Qt.Key_Backtab) {
                                root.selectedOverviewIndex = (root.selectedOverviewIndex - 1 + totalItems) % totalItems;
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Right || event.key === Qt.Key_Tab) {
                                root.selectedOverviewIndex = (root.selectedOverviewIndex + 1) % totalItems;
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Up) {
                                root.selectedOverviewIndex = Math.max(0, root.selectedOverviewIndex - cols);
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Down) {
                                root.selectedOverviewIndex = Math.min(totalItems - 1, root.selectedOverviewIndex + cols);
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                                if (root.selectedOverviewIndex === root.groups.length) {
                                    root.openCreateGroup();
                                } else {
                                    const chosen = root.groups[root.selectedOverviewIndex];
                                    if (chosen) {
                                        root.switchToGroup(chosen.id);
                                        root.closeOverview();
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
