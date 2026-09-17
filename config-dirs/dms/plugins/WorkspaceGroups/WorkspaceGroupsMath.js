.pragma library

// TODO: .import felt like not working today, whenever it does just import from defaults
var WS_DEFAULT = 10;
var WS_MIN = 5;
var WS_MAX = 20;
var MAX_MONITOR_SLOTS = 4;
var INVALID_WORKSPACE_ID = -1;
var MONITOR_PRIORITY = ["HDMI-A-1", "DP-1"];

function totalPerGroupFixed(wsPerMonitor) {
    var K = wsPerMonitor || WS_DEFAULT;
    return K * MAX_MONITOR_SLOTS;
}

function clampSlot(slotIdx) {
    var n = parseInt(slotIdx, 10);
    if (isNaN(n))
        return 0;
    return Math.max(0, Math.min(MAX_MONITOR_SLOTS - 1, n));
}

function calcWorkspaceFixed(groupId, slotIdx, subWs, wsPerMonitor) {
    var K = wsPerMonitor || WS_DEFAULT;
    var S = MAX_MONITOR_SLOTS;
    return (groupId - 1) * (K * S) + (clampSlot(slotIdx) * K) + subWs;
}

function workspaceRangeForGroupFixed(groupId, wsPerMonitor) {
    var totalPerGroup = totalPerGroupFixed(wsPerMonitor);
    var start = (groupId - 1) * totalPerGroup + 1;
    return { start: start, end: start + totalPerGroup - 1, totalPerGroup: totalPerGroup };
}

function isWorkspaceInRangeFixed(wsId, groupId, slotIdx, wsPerMonitor) {
    if (!wsId || wsId < 1 || !groupId || groupId < 1 || slotIdx === undefined || slotIdx === null)
        return false;
    var K = wsPerMonitor || WS_DEFAULT;
    var slot = clampSlot(slotIdx);
    var totalPerGroup = totalPerGroupFixed(K);
    var startWs = (groupId - 1) * totalPerGroup + (slot * K) + 1;
    var endWs = startWs + K - 1;
    return wsId >= startWs && wsId <= endWs;
}

function groupFromWorkspaceFixed(wsId, wsPerMonitor) {
    if (!wsId || wsId < 1)
        return 1;
    var totalPerGroup = totalPerGroupFixed(wsPerMonitor);
    if (totalPerGroup <= 0)
        return 1;
    return Math.floor((wsId - 1) / totalPerGroup) + 1;
}

function subFromWorkspaceFixed(wsId, wsPerMonitor) {
    if (!wsId || wsId < 1)
        return 1;
    var K = wsPerMonitor || WS_DEFAULT;
    var totalPerGroup = totalPerGroupFixed(K);
    if (totalPerGroup <= 0)
        return 1;
    var withinGroup = (wsId - 1) % totalPerGroup;
    return (withinGroup % K) + 1;
}

function assignMonitorSlots(allNames, priority, existingSlots, maxSlots) {
    var max = maxSlots || MAX_MONITOR_SLOTS;
    if (max < 1)
        max = 1;
    var names = (allNames && allNames.slice) ? allNames.slice() : [];
    var prio = (priority && priority.length > 0) ? priority : MONITOR_PRIORITY;
    var prev = (existingSlots && typeof existingSlots === "object") ? existingSlots : {};
    var slots = {};
    var used = {};
    for (var i = 0; i < names.length; i++) {
        var keep = parseInt(prev[names[i]], 10);
        if (!isNaN(keep) && keep >= 0 && keep < max && !used[keep]) {
            slots[names[i]] = keep;
            used[keep] = true;
        }
    }
    var newcomers = [];
    for (var j = 0; j < names.length; j++) {
        if (slots[names[j]] === undefined)
            newcomers.push(names[j]);
    }
    newcomers.sort(function (a, b) {
        var pa = prio.indexOf(a);
        var pb = prio.indexOf(b);
        var ra = pa >= 0 ? pa : prio.length;
        var rb = pb >= 0 ? pb : prio.length;
        if (ra !== rb)
            return ra - rb;
        if (a < b)
            return -1;
        if (a > b)
            return 1;
        return 0;
    });
    for (var k = 0; k < newcomers.length; k++) {
        var free = -1;
        for (var s = 0; s < max; s++) {
            if (!used[s]) {
                free = s;
                break;
            }
        }
        if (free < 0)
            free = max - 1;
        slots[newcomers[k]] = free;
        used[free] = true;
    }
    var changed = false;
    var prevKeys = 0;
    for (var pk in prev) {
        if (names.indexOf(pk) >= 0)
            prevKeys++;
        else
            changed = true;
    }
    var nextKeys = 0;
    for (var nk in slots) {
        nextKeys++;
    }
    if (prevKeys !== nextKeys) {
        changed = true;
    } else {
        for (var ck in slots) {
            if (prev[ck] !== slots[ck]) {
                changed = true;
                break;
            }
        }
    }
    return { slots: slots, changed: changed };
}

function legacyGroupAndSub(wsId, wsPerMonitor, legacyMonCount) {
    if (wsId === null || wsId === undefined)
        return null;
    var id = (typeof wsId === "number") ? Math.floor(wsId) : parseInt(wsId, 10);
    if (isNaN(id) || id < 1)
        return null;
    var K = wsPerMonitor || WS_DEFAULT;
    var M = Math.max(1, parseInt(legacyMonCount, 10) || 1);
    var total = K * M;
    if (total <= 0)
        return null;
    var within = (id - 1) % total;
    return { group: Math.floor((id - 1) / total) + 1, sub: (within % K) + 1 };
}

function clampWsPerMonitor(v) {
    var n = parseInt(v, 10);
    if (isNaN(n))
        return WS_DEFAULT;
    return Math.max(WS_MIN, Math.min(WS_MAX, n));
}

function parseGroupId(s) {
    var n = parseInt(s, 10);
    if (isNaN(n) || n < 1)
        return INVALID_WORKSPACE_ID;
    return n;
}

function parseIndex(s) {
    var n = parseInt(s, 10);
    if (isNaN(n) || n < 0)
        return INVALID_WORKSPACE_ID;
    return n;
}

function resolveWorkspaceId(obj) {
    if (obj === null || obj === undefined) {
        return INVALID_WORKSPACE_ID;
    }

    if (typeof obj === "number") {
        return (!isNaN(obj) && obj > 0) ? Math.floor(obj) : INVALID_WORKSPACE_ID;
    }

    if (typeof obj === "string") {
        var parsedStr = parseInt(obj, 10);
        return (!isNaN(parsedStr) && parsedStr > 0) ? parsedStr : INVALID_WORKSPACE_ID;
    }

    if (obj.activeWorkspace !== undefined && obj.activeWorkspace !== null) {
        var resActive = resolveWorkspaceId(obj.activeWorkspace);
        if (resActive > 0) {
            return resActive;
        }
    }
    if (obj.lastIpcObject !== undefined && obj.lastIpcObject !== null &&
        obj.lastIpcObject.activeWorkspace !== undefined && obj.lastIpcObject.activeWorkspace !== null) {
        var resIpcActive = resolveWorkspaceId(obj.lastIpcObject.activeWorkspace);
        if (resIpcActive > 0) {
            return resIpcActive;
        }
    }

    var isMonitor = (obj.activeWorkspace !== undefined) ||
                    (obj.model !== undefined) ||
                    (obj.make !== undefined) ||
                    (obj.refreshRate !== undefined) ||
                    (obj.screen !== undefined) ||
                    (obj.screenName !== undefined) ||
                    (obj.availableGeometry !== undefined) ||
                    (obj.lastIpcObject !== undefined && obj.lastIpcObject !== null &&
                     (obj.lastIpcObject.activeWorkspace !== undefined || obj.lastIpcObject.model !== undefined));

    if (isMonitor) {
        return INVALID_WORKSPACE_ID;
    }

    if (obj.workspace !== undefined && obj.workspace !== null) {
        var resWs = resolveWorkspaceId(obj.workspace);
        if (resWs > 0) {
            return resWs;
        }
    }
    if (obj.lastIpcObject !== undefined && obj.lastIpcObject !== null &&
        obj.lastIpcObject.workspace !== undefined && obj.lastIpcObject.workspace !== null) {
        var resIpcWs = resolveWorkspaceId(obj.lastIpcObject.workspace);
        if (resIpcWs > 0) {
            return resIpcWs;
        }
    }

    if (obj.id !== undefined && obj.id !== null && typeof obj.id === "number" && obj.id > 0) {
        return Math.floor(obj.id);
    }

    if (obj.name !== undefined && obj.name !== null && typeof obj.name === "string") {
        var parsedName = parseInt(obj.name, 10);
        if (!isNaN(parsedName) && parsedName > 0) {
            return parsedName;
        }
    }

    if (obj.lastIpcObject !== undefined && obj.lastIpcObject !== null) {
        var ipc = obj.lastIpcObject;
        if (ipc.id !== undefined && ipc.id !== null && typeof ipc.id === "number" && ipc.id > 0) {
            return Math.floor(ipc.id);
        }
        if (ipc.name !== undefined && ipc.name !== null) {
            var parsedIpcName = parseInt(ipc.name, 10);
            if (!isNaN(parsedIpcName) && parsedIpcName > 0) {
                return parsedIpcName;
            }
        }
    }

    return INVALID_WORKSPACE_ID;
}
