import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import qs.Common
import qs.Widgets
import "WorkspaceGroupsDefaults.js" as Defaults

Rectangle {
    id: card

    property int cardIndex: -1
    property var group: null
    property bool isSelected: false
    property bool isActive: false
    property var windows: []
    property var controller: null
    property var dragContainer: null
    property var dragGrid: null
    property int slotCount: 0
    property bool hoverArmed: false
    property bool deletable: true
    signal switchRequested(int gid)
    signal editRequested(int gid)
    signal deleteRequested(int gid)
    signal createRequested
    signal reorderRequested(int from, int to)
    signal selectionRequested(int index)
    signal focusRequested(var row)

    readonly property bool isAddCard: group === null
    readonly property bool isDraggedSource: controller ? (controller.isDragging && controller.dragFromIndex === cardIndex) : false
    readonly property bool isDropTarget: controller ? (controller.isDragging && controller.dragTargetIndex === cardIndex && controller.dragTargetIndex !== controller.dragFromIndex) : false

    radius: Theme.cornerRadius
    clip: true
    z: (isActive || isSelected || isDropTarget) ? 3 : 1
    opacity: isDraggedSource ? 0.35 : 1.0
    scale: isDropTarget ? 1.02 : 1.0
    color: isAddCard
        ? (isSelected ? Theme.surfaceContainerHighest : Theme.surfaceContainerLow)
        : (isSelected ? (isActive ? Theme.primaryContainer : Theme.surfaceContainerHighest) : (isActive ? Theme.withAlpha(Theme.primaryContainer, 0.45) : Theme.surfaceContainerLow))
    border.color: isDropTarget
        ? Theme.primary
        : (isAddCard
            ? (isSelected ? Theme.primary : Theme.outlineVariant)
            : (isSelected ? (isActive ? Theme.primary : Theme.secondary) : (isActive ? Theme.withAlpha(Theme.primary, 0.4) : Theme.outlineVariant)))
    border.width: isDropTarget ? 3 : (isSelected ? 2 : 1)

    Behavior on color { ColorAnimation { duration: 150 } }
    Behavior on border.color { ColorAnimation { duration: 150 } }
    Behavior on opacity { NumberAnimation { duration: 150 } }
    Behavior on scale { NumberAnimation { duration: 150 } }

    MouseArea {
        id: cardMouseArea
        anchors.fill: parent
        enabled: !card.isAddCard
        hoverEnabled: true
        cursorShape: (card.controller && card.controller.isDragging) ? Qt.ClosedHandCursor : Qt.PointingHandCursor

        property real startMouseX: 0
        property real startMouseY: 0
        property bool dragActive: false

        onPressed: mouse => {
            startMouseX = mouse.x;
            startMouseY = mouse.y;
            dragActive = false;
        }

        onPositionChanged: mouse => {
            if (!card.controller) {
                return;
            }
            if (!card.controller.trackGlobalMouse(cardMouseArea, mouse.x, mouse.y)) {
                return;
            }
            if (pressed && !card.isAddCard) {
                if (card.controller.tryBegin("card", card.cardIndex, mouse.x, mouse.y, startMouseX, startMouseY)) {
                    dragActive = true;
                }
            }
            if (card.controller.move("card", card.cardIndex, cardMouseArea, mouse.x, mouse.y, card.dragContainer, card.dragGrid, card.slotCount)) {
            } else if (!card.controller.isDragging) {
                card.selectionRequested(card.cardIndex);
            }
        }

        onReleased: mouse => {
            if (card.controller && card.controller.isDraggingFor("card", card.cardIndex)) {
                const to = card.controller.finish("card", card.cardIndex, card.slotCount);
                dragActive = false;
                if (to >= 0) {
                    card.reorderRequested(card.cardIndex, to);
                }
                return;
            }
            if (dragActive) {
                dragActive = false;
                return;
            }
            if (card.group) {
                card.switchRequested(card.group.id);
            }
        }

        onCanceled: {
            if (card.controller) {
                card.controller.cancel("card");
            }
            dragActive = false;
        }
    }

    MouseArea {
        id: addCardMouse
        anchors.fill: parent
        enabled: card.isAddCard
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onPositionChanged: mouse => {
            if (!card.controller) {
                return;
            }
            if (!card.controller.trackGlobalMouse(addCardMouse, mouse.x, mouse.y)) {
                return;
            }
            card.selectionRequested(card.cardIndex);
        }
        onClicked: {
            card.createRequested();
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacingM
        spacing: Theme.spacingXS
        visible: !card.isAddCard

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingS

            Rectangle {
                width: (card.group && card.group.id >= 10) ? 28 : 24
                height: 24
                radius: 12
                color: card.isActive ? Theme.primary : Theme.surfaceContainerHighest

                StyledText {
                    anchors.centerIn: parent
                    text: card.group ? card.group.id.toString() : ""
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: Font.Bold
                    color: card.isActive ? Theme.onPrimary : Theme.surfaceText
                }
            }

            StyledText {
                text: (card.group && card.group.icon) ? card.group.icon : Defaults.FALLBACK_ICON
                font.pixelSize: 20
                color: (card.group && card.group.color) ? card.group.color : Theme.primary
            }

            StyledText {
                text: card.group ? (card.group.name || (Defaults.NAME_PREFIX + card.group.id)) : ""
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.Bold
                color: Theme.surfaceText
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            WGIconButton {
                id: editBtn
                buttonSize: 28
                baseColor: Theme.withAlpha(Theme.surfaceContainerHighest, 0.7)
                hoverColor: Theme.withAlpha(Theme.primary, 0.2)
                iconName: "edit"
                iconSize: 15
                iconColor: editBtn.containsMouse ? Theme.primary : Theme.surfaceText
                onClicked: {
                    if (card.group) {
                        card.editRequested(card.group.id);
                    }
                }
            }

            WGIconButton {
                id: delBtn
                visible: card.deletable
                buttonSize: 28
                baseColor: Theme.withAlpha(Theme.surfaceContainerHighest, 0.7)
                hoverColor: Theme.withAlpha(Theme.error, 0.2)
                iconName: "delete"
                iconSize: 15
                iconColor: delBtn.containsMouse ? Theme.error : Theme.surfaceText
                onClicked: {
                    if (card.group) {
                        card.deleteRequested(card.group.id);
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
                visible: card.windows.length > 0
                clip: true
                contentWidth: width
                contentHeight: winCol.height
                boundsBehavior: Flickable.StopAtBounds
                interactive: false

                ScrollBar.vertical: DankScrollbar {
                    id: winScrollBar
                }

                WheelHandler {
                    target: winFlickable
                    enabled: winFlickable.contentHeight > winFlickable.height
                    onWheel: event => {
                        if (event.angleDelta.y > 0) {
                            winFlickable.contentY = Math.max(0, winFlickable.contentY - Defaults.SCROLL_STEP_CARD);
                        } else if (event.angleDelta.y < 0) {
                            winFlickable.contentY = Math.min(Math.max(0, winFlickable.contentHeight - winFlickable.height), winFlickable.contentY + Defaults.SCROLL_STEP_CARD);
                        }
                        winScrollBar._scrollBarActive = true;
                        winScrollBar.hideTimer.restart();
                    }
                }

                Column {
                    id: winCol
                    width: card.windows.length > 5 ? (winFlickable.width - 8) : winFlickable.width
                    spacing: 3

                    Repeater {
                        model: card.windows

                        WindowRow {
                            width: winCol.width
                            rowData: modelData
                            accent: (card.group && card.group.color) || Theme.primary
                            hoverArmed: card.hoverArmed
                            controller: card.controller
                            dragToken: "row"
                            dragIndex: card.cardIndex
                            dragContainer: card.dragContainer
                            dragGrid: card.dragGrid
                            slotCount: card.slotCount
                            onSelectRequested: card.selectionRequested(card.cardIndex)
                            onFocusRequested: row => card.focusRequested(row)
                            onReorderRequested: (from, to) => card.reorderRequested(from, to)
                        }
                    }
                }
            }

            ColumnLayout {
                anchors.centerIn: parent
                visible: card.windows.length === 0
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
        visible: card.isAddCard
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
