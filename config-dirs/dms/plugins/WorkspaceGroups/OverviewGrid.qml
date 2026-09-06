import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.Common
import qs.Widgets
import "WorkspaceGroupsDefaults.js" as Defaults

ColumnLayout {
    id: grid

    property var groups: []
    property int activeGroupIndex: 1
    property int selectedIndex: 0
    property var rowsByGroup: ({})
    property int totalItems: 0
    property bool contentVisible: false
    property int columns: 2
    property var controller: null
    property var dragContainer: null
    property bool hoverArmed: false
    property bool deletable: true
    signal switchRequested(int gid)
    signal editRequested(int gid)
    signal deleteRequested(int gid)
    signal createRequested
    signal reorderRequested(int from, int to)
    signal selectionRequested(int index)
    signal focusRequested(var row)
    function resetScroll() {
        overviewFlickable.contentY = 0;
    }


    readonly property real cardWidth: groupGrid.cardWidth
    readonly property real cardHeight: groupGrid.cardHeight

    function ensureVisible(idx) {
        overviewFlickable.ensureVisible(idx);
    }

    spacing: Theme.spacingM

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Theme.spacingXS

        RowLayout {
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
                onClicked: grid.createRequested()
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
            enabled: !overviewFlickable.moving && !overviewFlickable.flicking && grid.contentVisible
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
            if (height > 0 && contentHeight > 0 && grid.contentVisible) {
                ensureVisible(grid.selectedIndex);
            }
        }

        onContentHeightChanged: {
            const maxScroll = Math.max(0, contentHeight - height);
            if (contentY > maxScroll) {
                contentY = maxScroll;
            }
            if (height > 0 && contentHeight > 0 && grid.contentVisible) {
                ensureVisible(grid.selectedIndex);
            }
        }


        function ensureVisible(idx) {
            if (idx < 0 || idx >= grid.totalItems)
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

            const row = Math.floor(idx / grid.columns);
            const cardY = groupGrid.y + row * (grid.cardHeight + groupGrid.rowSpacing);
            const cardBottom = cardY + grid.cardHeight;
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
                if (event.angleDelta.y > 0) {
                    overviewFlickable.contentY = Math.max(0, overviewFlickable.contentY - Defaults.SCROLL_STEP_OVERVIEW);
                } else if (event.angleDelta.y < 0) {
                    overviewFlickable.contentY = Math.min(Math.max(0, overviewFlickable.contentHeight - overviewFlickable.height), overviewFlickable.contentY + Defaults.SCROLL_STEP_OVERVIEW);
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
            columns: grid.columns
            columnSpacing: Theme.spacingM
            rowSpacing: Theme.spacingM
            readonly property real cardWidth: Math.max(200, Math.floor((width - (columns - 1) * columnSpacing) / columns))
            readonly property real cardHeight: 240

            Repeater {
                model: grid.totalItems

                GroupCard {
                    width: grid.cardWidth
                    height: grid.cardHeight
                    cardIndex: index
                    group: index < grid.groups.length ? grid.groups[index] : null
                    isSelected: grid.selectedIndex === index
                    isActive: group !== null && grid.activeGroupIndex === group.id
                    windows: (group !== null && grid.rowsByGroup[group.id]) ? grid.rowsByGroup[group.id] : []
                    controller: grid.controller
                    dragContainer: grid.dragContainer
                    dragGrid: groupGrid
                    slotCount: grid.groups.length
                    hoverArmed: grid.hoverArmed
                    deletable: grid.deletable
                    onSwitchRequested: gid => grid.switchRequested(gid)
                    onEditRequested: gid => grid.editRequested(gid)
                    onDeleteRequested: gid => grid.deleteRequested(gid)
                    onCreateRequested: grid.createRequested()
                    onReorderRequested: (from, to) => grid.reorderRequested(from, to)
                    onSelectionRequested: idx => grid.selectionRequested(idx)
                    onFocusRequested: row => grid.focusRequested(row)
                }
            }
        }
    }
}
