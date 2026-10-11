import QtQuick

Item {
    id: root

    property string character: ""
    property string fontFamily: "Impact"
    property real fontSize: 64
    property color charColor: "#FFFAF2"
    property color strokeColor: "#000000"
    property real charAlpha: 1.0
    property real localX: 0
    property real localY: 0
    property real charRotation: 0

    visible: charAlpha > 0.005 && character !== ""

    x: Math.round(localX - width / 2)
    y: Math.round(localY - height / 2)
    width: glyphText.contentWidth + 8
    height: glyphText.contentHeight + 8
    opacity: Math.min(Math.max(charAlpha, 0.0), 1.0)
    rotation: charRotation

    Text {
        id: glyphText
        anchors.centerIn: parent
        text: root.character
        font.family: root.fontFamily
        font.pixelSize: Math.round(root.fontSize)
        color: root.charColor
        style: Text.Outline
        styleColor: root.strokeColor
        renderType: Text.NativeRendering
    }
}
