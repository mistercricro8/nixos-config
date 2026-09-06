import QtQuick
import Quickshell
import QtQuick.Layouts
import Quickshell.Widgets
import qs.Common
import qs.Widgets
import "WorkspaceGroupsDefaults.js" as Defaults

Rectangle {
    id: row

    property var rowData: ({})
    property color accent: Theme.primary
    property bool hoverArmed: false
    property var controller: null
    property string dragToken: "row"
    property int dragIndex: -1
    property var dragContainer: null
    property var dragGrid: null
    property int slotCount: 0
    signal selectRequested
    signal focusRequested(var row)
    signal reorderRequested(int from, int to)

    width: parent ? parent.width : 0
    height: 30
    radius: Theme.cornerRadiusSmall
    clip: true
    color: (winMouse.containsMouse && hoverArmed) ? Theme.surfaceContainerHighest : ((rowData.isFocused) ? Theme.withAlpha(Theme.primary, 0.15) : Theme.surfaceContainerLowest)
    border.color: rowData.isFocused ? Theme.primary : ((winMouse.containsMouse && hoverArmed) ? Theme.outlineVariant : "transparent")
    border.width: 1

    MouseArea {
        id: winMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: (row.controller && row.controller.isDragging) ? Qt.ClosedHandCursor : Qt.PointingHandCursor

        property real startWinX: 0
        property real startWinY: 0
        property bool dragActive: false

        onPressed: mouse => {
            startWinX = mouse.x;
            startWinY = mouse.y;
            dragActive = false;
        }

        onPositionChanged: mouse => {
            if (!row.controller) {
                return;
            }
            if (!row.controller.trackGlobalMouse(winMouse, mouse.x, mouse.y)) {
                return;
            }
            if (pressed) {
                if (row.controller.tryBegin(row.dragToken, row.dragIndex, mouse.x, mouse.y, startWinX, startWinY)) {
                    dragActive = true;
                }
            }
            if (row.controller.move(row.dragToken, row.dragIndex, winMouse, mouse.x, mouse.y, row.dragContainer, row.dragGrid, row.slotCount)) {
            } else if (!row.controller.isDragging) {
                row.selectRequested();
            }
        }

        onReleased: mouse => {
            if (row.controller && row.controller.isDraggingFor(row.dragToken, row.dragIndex)) {
                const to = row.controller.finish(row.dragToken, row.dragIndex, row.slotCount);
                dragActive = false;
                if (to >= 0) {
                    row.reorderRequested(row.dragIndex, to);
                }
                return;
            }
            if (dragActive) {
                dragActive = false;
                return;
            }
        }

        onCanceled: {
            if (row.controller) {
                row.controller.cancel(row.dragToken);
            }
            dragActive = false;
        }

        onClicked: {
            if (dragActive || (row.controller && row.controller.isDragging)) {
                return;
            }
            row.focusRequested(row.rowData);
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
            color: Theme.withAlpha(row.accent, 0.2)

            StyledText {
                anchors.centerIn: parent
                text: row.rowData.subWs !== undefined ? row.rowData.subWs.toString() : ""
                font.pixelSize: 10
                font.weight: Font.Bold
                color: row.accent
            }
        }

        Item {
            width: 16
            height: 16
            Layout.alignment: Qt.AlignVCenter

            IconImage {
                id: winIconImg
                anchors.fill: parent
                source: row.rowData.icon || ""
                visible: row.rowData.icon !== "" && status === Image.Ready
            }

            DankIcon {
                anchors.centerIn: parent
                name: "desktop_windows"
                size: 14
                color: Theme.surfaceVariantText
                visible: !row.rowData.icon || (row.rowData.icon !== "" && winIconImg.status !== Image.Ready)
            }
        }

        StyledText {
            text: row.rowData.appName || row.rowData.title
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
            visible: row.rowData.isFocused
        }
    }
}
