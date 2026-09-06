import QtQuick
import Quickshell
import "WorkspaceGroupsDefaults.js" as Defaults

QtObject {
    readonly property string target: Defaults.TARGET

    readonly property string switchGroup: Defaults.VERB_SWITCH_GROUP
    readonly property string moveToGroup: Defaults.VERB_MOVE_TO_GROUP
    readonly property string nextGroup: Defaults.VERB_NEXT_GROUP
    readonly property string prevGroup: Defaults.VERB_PREV_GROUP
    readonly property string switchSub: Defaults.VERB_SWITCH_SUB
    readonly property string switchSubOnMon: Defaults.VERB_SWITCH_SUB_ON_MON
    readonly property string moveSub: Defaults.VERB_MOVE_SUB
    readonly property string moveSubOnMon: Defaults.VERB_MOVE_SUB_ON_MON
    readonly property string cycleSub: Defaults.VERB_CYCLE_SUB
    readonly property string toggleOverview: Defaults.VERB_TOGGLE_OVERVIEW
    readonly property string openOverview: Defaults.VERB_OPEN_OVERVIEW
    readonly property string closeOverview: Defaults.VERB_CLOSE_OVERVIEW
    readonly property string openCreate: Defaults.VERB_OPEN_CREATE
    readonly property string closeCreate: Defaults.VERB_CLOSE_CREATE
    readonly property string toggleCreate: Defaults.VERB_TOGGLE_CREATE
    readonly property string create: Defaults.VERB_CREATE
    readonly property string remove: Defaults.VERB_DELETE
    readonly property string removeCurrent: Defaults.VERB_DELETE_CURRENT
    readonly property string resetToLaunch: Defaults.VERB_RESET_TO_LAUNCH
    readonly property string openEdit: Defaults.VERB_OPEN_EDIT
    readonly property string openEditCurrent: Defaults.VERB_OPEN_EDIT_CURRENT
    readonly property string update: Defaults.VERB_UPDATE
    readonly property string reorder: Defaults.VERB_REORDER
    readonly property string getActive: Defaults.VERB_GET_ACTIVE
    readonly property string getGroups: Defaults.VERB_GET_GROUPS

    function call(verb) {
        var args = Array.prototype.slice.call(arguments, 1);
        Quickshell.execDetached(["dms", "ipc", "call", target, verb].concat(args));
    }
}
