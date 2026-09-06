import QtQuick
import qs.Common
import qs.Widgets

Rectangle {
    id: btn

    property int buttonSize: 28
    property real cornerRadius: buttonSize / 2
    property color baseColor: Theme.surfaceContainer
    property color hoverColor: Theme.surfaceContainerHighest
    property alias borderColor: btn.border.color
    property alias borderWidth: btn.border.width
    property string iconName: ""
    property int iconSize: 15
    property color iconColor: Theme.surfaceText
    property string text: ""
    property int textSize: 15
    property color textColor: Theme.surfaceText
    property int textWeight: Font.Normal
    readonly property alias containsMouse: btnMouse.containsMouse
    signal clicked

    width: buttonSize
    height: buttonSize
    radius: cornerRadius
    color: btnMouse.containsMouse ? hoverColor : baseColor

    DankIcon {
        anchors.centerIn: parent
        visible: btn.iconName !== ""
        name: btn.iconName
        size: btn.iconSize
        color: btn.iconColor
    }

    StyledText {
        anchors.centerIn: parent
        visible: btn.iconName === "" && btn.text !== ""
        text: btn.text
        font.pixelSize: btn.textSize
        font.weight: btn.textWeight
        color: btn.textColor
    }

    MouseArea {
        id: btnMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: btn.clicked()
    }
}
