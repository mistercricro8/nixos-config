import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.Common
import qs.Widgets
import qs.DCommon.Widgets

WGModalCard {
    id: modal

    property int groupId: 0
    property string groupName: ""
    property int windowCount: 0
    signal confirmed
    signal closed

    implicitHeight: deleteCol.implicitHeight + Theme.spacingXL * 2

    closedScale: 0.95
    useExpressiveCurves: false

    Keys.onEscapePressed: event => {
        modal.closed();
        event.accepted = true;
    }

    Keys.onReturnPressed: event => {
        modal.confirmed();
        event.accepted = true;
    }

    Keys.onEnterPressed: event => {
        modal.confirmed();
        event.accepted = true;
    }

    ColumnLayout {
        id: deleteCol
        anchors.fill: parent
        anchors.margins: Theme.spacingXL
        spacing: Theme.spacingM

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingS

            DIcon {
                name: "warning"
                size: 24
                color: Theme.error
            }

            StyledText {
                text: "Delete Group " + modal.groupName + "?"
                font.pixelSize: Theme.fontSizeLarge
                font.weight: Font.Bold
                color: Theme.surfaceText
            }
        }

        StyledText {
            text: "This group has " + modal.windowCount + " open window(s). Deleting it will safely move all its windows to Group 1."
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.surfaceVariantText
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        Item { height: Theme.spacingXS }

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingM

            Item { Layout.fillWidth: true }

            DButton {
                id: cancelBtn
                text: "Cancel"
                onClicked: modal.closed()
            }

            DButton {
                text: "Delete & Move Windows"
                iconName: "delete"
                backgroundColor: Theme.error
                textColor: Theme.surfaceContainer
                onClicked: modal.confirmed()
            }
        }
    }
}
