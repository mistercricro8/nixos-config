import QtQuick
import QtQuick.Effects
import "DramaticLyricsMath.js" as DM

Item {
    id: root

    property var placedLine: null
    property real currentTrackTime: 0.0
    property real monotonicSec: 0.0
    property real exitT: -1.0
    property real revealSec: 0.25
    property real shimAmp: 0.0
    property real shimPeriod: 3.0
    property real driftX: 0.0
    property real driftY: 0.0
    property real windRotationDeg: 0.0
    property bool bloomEnabled: true
    property real bloomIntensity: 1.0

    anchors.fill: parent
    visible: placedLine !== null && (exitT < 0.0 || exitT < 1.0) && opacity > 0.005

    readonly property var wind: exitT >= 0.0 ? DM.windTransform(Math.min(exitT, 1.0), driftX, driftY, windRotationDeg) : null
    readonly property real lineAngle: placedLine ? (placedLine.angle + (wind ? wind.dangle : 0)) : 0
    readonly property real lineScale: wind ? wind.scale : 1.0
    readonly property real radLine: lineAngle * Math.PI / 180.0
    readonly property real cosLine: Math.cos(radLine)
    readonly property real sinLine: Math.sin(radLine)

    readonly property real centerX: placedLine ? placedLine.cx : 0
    readonly property real centerY: placedLine ? placedLine.cy : 0
    readonly property real windDx: wind ? wind.dx : 0
    readonly property real windDy: wind ? wind.dy : 0

    MultiEffect {
        anchors.fill: charsLayer
        source: charsLayer
        visible: root.bloomEnabled && root.bloomIntensity > 0.0 && root.visible
        blurEnabled: true
        blur: Math.min(1.0, 0.8 * root.bloomIntensity)
        blurMax: Math.round(32 * (placedLine ? (placedLine.height / 64.0) : 1.0))
        opacity: Math.min(1.0, 0.9 * root.bloomIntensity)
    }

    Item {
        id: charsLayer
        anchors.fill: parent

        Repeater {
            model: root.placedLine ? root.placedLine.chars.length : 0

            DramaticChar {
                required property int index

                readonly property var chData: root.placedLine.chars[index]
                readonly property int totalChars: root.placedLine.chars.length
                readonly property var ln: root.placedLine.ln

                readonly property real baseAlpha: {
                    if (!ln || ln.start < 0)
                        return 1.0;
                    var dur = ln.dur || 0.0;
                    var app = ln.start + (totalChars > 1 ? (dur * index / totalChars) : 0);
                    if (root.currentTrackTime < app)
                        return 0.0;
                    if (root.revealSec <= 0)
                        return 1.0;
                    return Math.min(1.0, (root.currentTrackTime - app) / root.revealSec);
                }

                readonly property real exitK: (root.exitT >= 0.0) ? DM.charExitProgress(root.exitT, index, totalChars) : 0.0
                readonly property real exitAlpha: 1.0 - exitK

                charAlpha: baseAlpha * exitAlpha

                readonly property var shim: {
                    if (root.shimAmp > 0 && charAlpha > 0.005) {
                        return DM.shimmerOffset(root.monotonicSec, index, root.shimAmp, root.shimPeriod);
                    }
                    return [0, 0];
                }

                readonly property real u: chData.x + (chData.w / 2.0) + shim[0] - root.driftX * exitK
                readonly property real v: shim[1] - root.driftY * exitK

                localX: root.centerX + root.lineScale * (u * root.cosLine - v * root.sinLine)
                localY: root.centerY + root.lineScale * (u * root.sinLine + v * root.cosLine)

                charRotation: chData.phi

                character: chData.ch
                fontFamily: chData.font
                fontSize: chData.size
                charColor: chData.color
                strokeColor: chData.strokeColor
            }
        }
    }
}
