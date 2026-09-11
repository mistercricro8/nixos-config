.pragma library
.import WorkspaceGroupsDefaults.js as Defaults

function calcWorkspace(groupId, monIdx, subWs, wsPerMonitor, monCount) {
    var K = wsPerMonitor || Defaults.WS_DEFAULT;
    var M = Math.max(1, monCount || 1);
    return (groupId - 1) * (K * M) + (monIdx * K) + subWs;
}

function workspaceRangeForGroup(groupId, wsPerMonitor, monCount) {
    var K = wsPerMonitor || Defaults.WS_DEFAULT;
    var M = Math.max(1, monCount || 1);
    var totalPerGroup = K * M;
    var start = (groupId - 1) * totalPerGroup + 1;
    return { start: start, end: start + totalPerGroup - 1, totalPerGroup: totalPerGroup };
}

function isWorkspaceInRange(wsId, groupId, monIdx, wsPerMonitor, monCount) {
    if (!wsId || wsId < 1 || !groupId || groupId < 1 || monIdx === undefined || monIdx < 0)
        return false;
    var K = wsPerMonitor || Defaults.WS_DEFAULT;
    var M = Math.max(1, monCount || 1);
    var totalPerGroup = K * M;
    var startWs = (groupId - 1) * totalPerGroup + (monIdx * K) + 1;
    var endWs = startWs + K - 1;
    return wsId >= startWs && wsId <= endWs;
}

function groupFromWorkspace(wsId, wsPerMonitor, monCount) {
    if (!wsId || wsId < 1)
        return 1;
    var K = wsPerMonitor || Defaults.WS_DEFAULT;
    var M = Math.max(1, monCount || 1);
    var totalPerGroup = K * M;
    if (totalPerGroup <= 0)
        return 1;
    return Math.floor((wsId - 1) / totalPerGroup) + 1;
}

function subFromWorkspace(wsId, wsPerMonitor, monCount) {
    if (!wsId || wsId < 1)
        return 1;
    var K = wsPerMonitor || Defaults.WS_DEFAULT;
    var M = Math.max(1, monCount || 1);
    var totalPerGroup = K * M;
    if (totalPerGroup <= 0)
        return 1;
    var withinGroup = (wsId - 1) % totalPerGroup;
    return (withinGroup % K) + 1;
}

function sortMonitorNames(allNames, priority) {
    var prio = (priority && priority.length > 0) ? priority : Defaults.MONITOR_PRIORITY;
    var sorted = [];
    var seen = {};
    for (var i = 0; i < prio.length; i++) {
        if (seen[prio[i]])
            continue;
        if (allNames.indexOf(prio[i]) >= 0) {
            sorted.push(prio[i]);
            seen[prio[i]] = true;
        }
    }
    for (var j = 0; j < allNames.length; j++) {
        if (!seen[allNames[j]]) {
            sorted.push(allNames[j]);
            seen[allNames[j]] = true;
        }
    }
    return sorted;
}

function monitorIndexFromNames(allNames, priority, targetName) {
    var sorted = sortMonitorNames(allNames, priority);
    var idx = sorted.indexOf(targetName);
    return idx >= 0 ? idx : 0;
}

function clampWsPerMonitor(v) {
    var n = parseInt(v, 10);
    if (isNaN(n))
        return Defaults.WS_DEFAULT;
    return Math.max(Defaults.WS_MIN, Math.min(Defaults.WS_MAX, n));
}

function parseGroupId(s) {
    var n = parseInt(s, 10);
    if (isNaN(n) || n < 1)
        return -1;
    return n;
}

function parseIndex(s) {
    var n = parseInt(s, 10);
    if (isNaN(n) || n < 0)
        return -1;
    return n;
}

function resolveWorkspaceId(obj) {
    if (obj === null || obj === undefined) {
        return -1;
    }

    if (typeof obj === "number") {
        return (!isNaN(obj) && obj > 0) ? Math.floor(obj) : -1;
    }

    if (typeof obj === "string") {
        var parsedStr = parseInt(obj, 10);
        return (!isNaN(parsedStr) && parsedStr > 0) ? parsedStr : -1;
    }

    var wsTarget = null;
    if (obj.workspace) {
        wsTarget = obj.workspace;
    } else if (obj.lastIpcObject && obj.lastIpcObject.workspace) {
        wsTarget = obj.lastIpcObject.workspace;
    } else if (obj.activeWorkspace) {
        wsTarget = obj.activeWorkspace;
    } else {
        wsTarget = obj;
    }

    if (wsTarget.name !== undefined && wsTarget.name !== null && typeof wsTarget.name === "string") {
        var parsedName = parseInt(wsTarget.name, 10);
        if (!isNaN(parsedName) && parsedName > 0) {
            return parsedName;
        }
    }

    if (wsTarget.address !== undefined && wsTarget.address !== null) {
        var parsedAddr = parseInt(wsTarget.address, 10);
        if (!isNaN(parsedAddr) && parsedAddr > 0) {
            return parsedAddr;
        }
    }

    if (wsTarget.id !== undefined && wsTarget.id !== null && typeof wsTarget.id === "number" && wsTarget.id > 0) {
        return wsTarget.id;
    }

    if (wsTarget.lastIpcObject) {
        var ipc = wsTarget.lastIpcObject;
        if (ipc.name !== undefined && ipc.name !== null) {
            var parsedIpcName = parseInt(ipc.name, 10);
            if (!isNaN(parsedIpcName) && parsedIpcName > 0) {
                return parsedIpcName;
            }
        }
        if (ipc.address !== undefined && ipc.address !== null) {
            var parsedIpcAddr = parseInt(ipc.address, 10);
            if (!isNaN(parsedIpcAddr) && parsedIpcAddr > 0) {
                return parsedIpcAddr;
            }
        }
        if (ipc.id !== undefined && ipc.id !== null && typeof ipc.id === "number" && ipc.id > 0) {
            return ipc.id;
        }
    }

    if (typeof obj.id === "number" && obj.id > 0) {
        return obj.id;
    }

    return -1;
}
