import QtQuick
import "WorkspaceGroupsDefaults.js" as Defaults

QtObject {
    id: ctrl

    property int dragFromIndex: -1
    property int dragTargetIndex: -1
    property bool isDragging: false
    property string ownerToken: ""
    property var host: null

    function trackGlobalMouse(item, x, y) {
        if (!host)
            return false;
        const globalPoint = item.mapToItem(null, x, y);
        if (!host.mouseMovedSinceOpen) {
            if (host.lastGlobalMouseX === -1) {
                host.lastGlobalMouseX = globalPoint.x;
                host.lastGlobalMouseY = globalPoint.y;
                return false;
            }
            const dx = Math.abs(globalPoint.x - host.lastGlobalMouseX);
            const dy = Math.abs(globalPoint.y - host.lastGlobalMouseY);
            if (dx < Defaults.HOVER_DEADZONE && dy < Defaults.HOVER_DEADZONE) {
                return false;
            }
            host.mouseMovedSinceOpen = true;
        }
        host.lastGlobalMouseX = globalPoint.x;
        host.lastGlobalMouseY = globalPoint.y;
        return true;
    }

    function isDraggingFor(token, fromIndex) {
        return isDragging && ownerToken === token && dragFromIndex === fromIndex;
    }

    function tryBegin(token, fromIndex, x, y, startX, startY) {
        if (isDragging)
            return isDraggingFor(token, fromIndex);
        const dist = Math.hypot(x - startX, y - startY);
        if (dist > Defaults.DRAG_THRESHOLD) {
            dragFromIndex = fromIndex;
            dragTargetIndex = fromIndex;
            isDragging = true;
            ownerToken = token;
            return true;
        }
        return false;
    }

    function move(token, fromIndex, mouseItem, x, y, container, grid, slotCount) {
        if (!isDraggingFor(token, fromIndex))
            return false;
        const modalPt = mouseItem.mapToItem(container, x, y);
        if (host) {
            host.dragMouseX = modalPt.x;
            host.dragMouseY = modalPt.y;
        }
        const gridPt = mouseItem.mapToItem(grid, x, y);
        const colW = grid.cardWidth + grid.columnSpacing;
        const rowH = grid.cardHeight + grid.rowSpacing;
        if (colW > 0 && rowH > 0) {
            const c = Math.max(0, Math.min(grid.columns - 1, Math.floor(Math.max(0, gridPt.x) / colW)));
            const r = Math.max(0, Math.floor(Math.max(0, gridPt.y) / rowH));
            const target = r * grid.columns + c;
            if (target >= 0 && target < slotCount) {
                dragTargetIndex = target;
            }
        }
        return true;
    }

    function finish(token, fromIndex, slotCount) {
        if (!isDraggingFor(token, fromIndex))
            return -1;
        const to = dragTargetIndex;
        cancel();
        if (to >= 0 && to !== fromIndex && to < slotCount)
            return to;
        return -1;
    }

    function cancel(token) {
        if (token === undefined || ownerToken === token || !isDragging) {
            isDragging = false;
            dragFromIndex = -1;
            dragTargetIndex = -1;
            ownerToken = "";
        }
    }
}
