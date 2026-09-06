import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.Common
import qs.Widgets
import "WorkspaceGroupsDefaults.js" as Defaults

Item {
    id: ghost

    property var group: null
    property int targetSlot: -1
    property real cardWidth: 200
    property real cardHeight: 240
    property real posX: 0
    property real posY: 0

    enabled: false
    width: cardWidth
    height: cardHeight
    x: posX
    y: posY
    z: 9999
    opacity: 0.95
    scale: 1.04

    ElevationShadow {
        anchors.fill: parent
        level: Theme.elevationLevel4
        targetRadius: Theme.cornerRadius
        targetColor: Theme.surfaceContainerHighest
        shadowEnabled: Theme.elevationEnabled
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.cornerRadius
        color: Theme.surfaceContainerHighest
        border.color: (ghost.group && ghost.group.color) || Theme.primary
        border.width: 2.5

        ColumnLayout {
            anchors.centerIn: parent
            spacing: Theme.spacingM

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 46
                height: 46
                radius: 23
                color: Theme.withAlpha((ghost.group && ghost.group.color) || Theme.primary, 0.2)
                border.color: (ghost.group && ghost.group.color) || Theme.primary
                border.width: 1.5

                StyledText {
                    anchors.centerIn: parent
                    text: (ghost.group && ghost.group.icon) || Defaults.FALLBACK_ICON
                    font.pixelSize: 24
                    color: (ghost.group && ghost.group.color) || Theme.primary
                }
            }

            ColumnLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 3

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: (ghost.group && ghost.group.name) || "Group"
                    font.pixelSize: Theme.fontSizeMedium
                    font.weight: Font.Bold
                    color: Theme.surfaceText
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Slot " + (ghost.targetSlot + 1)
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: Font.Medium
                    color: (ghost.group && ghost.group.color) || Theme.primary
                }
            }
        }
    }
}
