.pragma library

var TARGET = "workspaceGroups";

var FALLBACK_ICON = "󰅩";
var FALLBACK_COLOR = "#89b4fa";
var DEFAULT_GROUP_NAME = "default";
var NAME_PREFIX = "Group ";

var COLOR_PALETTE = [
    "#89b4fa", "#f38ba8", "#a6e3a1", "#fab387", "#cba6f7",
    "#f9e2af", "#94e2d5", "#74c7ec", "#b4befe", "#eba0ac"
];

var ICON_PRESETS = ["󰅩", "󰈹", "󰝚", "󰒓", "󰊴", "󰭹", "󰠮", "󰀝", "󱄅", "󰣇"];

var WS_DEFAULT = 10;
var WS_MIN = 5;
var WS_MAX = 20;

var MONITOR_PRIORITY = ["HDMI-A-1", "DP-1"];

var STATUS_TIMEOUT = 4000;
var DRAG_THRESHOLD = 8;
var HOVER_DEADZONE = 4;
var SCROLL_STEP_OVERVIEW = 80;
var SCROLL_STEP_CARD = 33;

var KEY_ACTIVE_INDEX = "activeGroupIndex";
var KEY_GROUPS = "groups";
var KEY_ACTIVE_NAME = "activeGroupName";
var KEY_ACTIVE_ICON = "activeGroupIcon";
var KEY_ACTIVE_COLOR = "activeGroupColor";
var KEY_WS_PER_MON = "workspacesPerMonitor";
var KEY_MON_COUNT = "monitorCount";
var KEY_HIDE_EMPTY = "hideEmptyWorkspaces";
var KEY_SORTED_MONS = "sortedMonitorNames";
var KEY_MON_PRIO = "monitorPriority";

var VERB_SWITCH_GROUP = "switchToGroup";
var VERB_MOVE_TO_GROUP = "moveWindowToGroup";
var VERB_NEXT_GROUP = "nextGroup";
var VERB_PREV_GROUP = "prevGroup";
var VERB_SWITCH_SUB = "switchToSubWorkspace";
var VERB_SWITCH_SUB_ON_MON = "switchToSubWorkspaceOnMonitor";
var VERB_MOVE_SUB = "moveWindowToSubWorkspace";
var VERB_MOVE_SUB_ON_MON = "moveWindowToSubWorkspaceOnMonitor";
var VERB_CYCLE_SUB = "cycleSubWorkspaces";
var VERB_TOGGLE_OVERVIEW = "toggleOverview";
var VERB_OPEN_OVERVIEW = "openOverview";
var VERB_CLOSE_OVERVIEW = "closeOverview";
var VERB_OPEN_CREATE = "openCreateGroup";
var VERB_CLOSE_CREATE = "closeCreateGroup";
var VERB_TOGGLE_CREATE = "toggleCreateGroup";
var VERB_CREATE = "createGroup";
var VERB_DELETE = "deleteGroup";
var VERB_DELETE_CURRENT = "deleteCurrentGroup";
var VERB_RESET_TO_LAUNCH = "resetToOnLaunchGroups";
var VERB_OPEN_EDIT = "openEditGroup";
var VERB_OPEN_EDIT_CURRENT = "openEditCurrentGroup";
var VERB_UPDATE = "updateGroup";
var VERB_REORDER = "reorderGroup";
var VERB_GET_ACTIVE = "getActiveGroup";
var VERB_GET_GROUPS = "getGroups";
var VERB_SAVE_STATE = "saveState";
var VERB_RECOVER_ORPHANS = "recoverOrphanGroups";
var VERB_WRITE_LUA = "writeLuaConfig";

var INVALID_WORKSPACE_ID = -1;
var DEFAULT_SUB_WORKSPACE_INDEX = 1;

var EVENT_WORKSPACE = "workspace";
var EVENT_WORKSPACE_V2 = "workspacev2";
var EVENT_FOCUSED_MON = "focusedmon";
var EVENT_FOCUSED_MON_V2 = "focusedmonv2";
var EVENT_MOVE_WORKSPACE = "moveworkspace";
