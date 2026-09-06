import QtQuick
import qs.Common
import qs.Widgets

Rectangle {
    id: pill

    property int subNumber: 0
    property int targetWs: 0
    property bool isActive: false
    property bool isOccupied: false
    property color activeColor: Theme.primary
    property string orientation: "horizontal"
    property bool showDot: true
    signal clicked(var mouse)

    readonly property bool isVertical: orientation === "vertical"
    width: isVertical ? 24 : (isActive ? 28 : 24)
    height: isVertical ? (isActive ? 28 : 24) : 26
    radius: Theme.cornerRadiusSmall

    color: {
        if (isActive)
            return activeColor;
        if (pillMouse.containsMouse)
            return Theme.surfaceContainerHighest;
        if (isOccupied)
            return Theme.withAlpha(Theme.surfaceContainerHigh, 0.7);
        return "transparent";
    }

    border.color: {
        if (isActive)
            return activeColor;
        if (isOccupied)
            return Theme.withAlpha(activeColor, 0.4);
        if (pillMouse.containsMouse)
            return Theme.outlineVariant;
        return "transparent";
    }
    border.width: 1

    Behavior on width { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
    Behavior on color { ColorAnimation { duration: 100 } }
    Behavior on border.color { ColorAnimation { duration: 100 } }

    StyledText {
        anchors.centerIn: parent
        text: pill.subNumber.toString()
        font.pixelSize: Theme.fontSizeSmall
        font.weight: pill.isActive ? Font.Bold : (pill.isOccupied ? Font.DemiBold : Font.Normal)
        color: {
            if (pill.isActive)
                return Theme.surfaceContainer;
            if (pill.isOccupied)
                return Theme.surfaceText;
            return Theme.surfaceVariantText;
        }
        opacity: pill.isVertical ? 1.0 : (pill.isActive ? 1.0 : (pill.isOccupied ? 0.95 : 0.65))
    }

    Rectangle {
        visible: pill.showDot && pill.isOccupied && !pill.isActive
        width: 4
        height: 4
        radius: 2
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 2
        anchors.horizontalCenter: parent.horizontalCenter
        color: pill.activeColor
    }

    MouseArea {
        id: pillMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => pill.clicked(mouse)
    }
}
