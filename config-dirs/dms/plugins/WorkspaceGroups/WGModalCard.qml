import QtQuick
import Quickshell.Widgets
import qs.Common
import qs.Widgets

Item {
    id: card

    property bool shown: true
    property real closedScale: 0.96
    property bool useExpressiveCurves: true
    property int shadowLevel: Theme.elevationLevel3
    property real surfaceRadius: Theme.cornerRadius * 1.5
    readonly property alias surfaceImplicitHeight: surface.implicitHeight
    default property alias content: surface.data

    transformOrigin: Item.Center
    opacity: shown ? 1 : 0
    scale: shown ? 1.0 : closedScale

    Behavior on opacity {
        NumberAnimation {
            duration: Theme.modalAnimationDuration
            easing.type: card.useExpressiveCurves ? Easing.BezierSpline : Easing.Linear
            easing.bezierCurve: card.shown ? Theme.expressiveCurves.expressiveDefaultSpatial : Theme.expressiveCurves.emphasized
        }
    }

    Behavior on scale {
        NumberAnimation {
            duration: Theme.modalAnimationDuration
            easing.type: card.useExpressiveCurves ? Easing.BezierSpline : Easing.Linear
            easing.bezierCurve: card.shown ? Theme.expressiveCurves.expressiveDefaultSpatial : Theme.expressiveCurves.emphasized
        }
    }

    ElevationShadow {
        anchors.fill: parent
        level: card.shadowLevel
        targetRadius: card.surfaceRadius
        targetColor: Theme.surfaceContainer
        shadowEnabled: Theme.elevationEnabled && SettingsData.modalElevationEnabled
    }

    Rectangle {
        id: surface
        anchors.fill: parent
        color: Theme.surfaceContainer
        radius: card.surfaceRadius
        border.color: Theme.outlineVariant
        border.width: 1
        clip: true
    }
}
