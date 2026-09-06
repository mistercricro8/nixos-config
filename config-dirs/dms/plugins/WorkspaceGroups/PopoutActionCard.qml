import QtQuick
import qs.Common
import qs.Widgets

Rectangle {
    id: card

    property string iconName: ""
    property string glyph: ""
    property string label: ""
    signal activated

    width: parent.width
    height: 36
    radius: Theme.cornerRadiusSmall
    color: cardMouse.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainer

    MouseArea {
        id: cardMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: card.activated()
    }

    Row {
        anchors.centerIn: parent
        spacing: Theme.spacingS

        DankIcon {
            anchors.verticalCenter: parent.verticalCenter
            visible: card.iconName !== ""
            name: card.iconName
            size: 16
            color: Theme.primary
        }

        StyledText {
            visible: card.iconName === "" && card.glyph !== ""
            text: card.glyph
            font.pixelSize: Theme.fontSizeMedium
            color: Theme.primary
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: card.label
            font.pixelSize: Theme.fontSizeSmall
            font.weight: Font.Medium
            color: Theme.primary
        }
    }
}
