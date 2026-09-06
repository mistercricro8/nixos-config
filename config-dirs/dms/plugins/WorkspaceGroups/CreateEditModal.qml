import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.Common
import qs.Widgets
import "WorkspaceGroupsDefaults.js" as Defaults

WGModalCard {
    id: modal

    property int editingId: 0
    property string initialName: ""
    property string initialIcon: Defaults.FALLBACK_ICON
    property string initialColor: Defaults.FALLBACK_COLOR
    property bool initialSwitch: true
    property var colorList: Defaults.COLOR_PALETTE
    property var iconPool: []
    property var focusScopeItem: null
    signal submitted(int editingId, string name, string icon, string color, bool switchImmediate)
    signal closed

    property string formName: ""
    property string formIcon: Defaults.FALLBACK_ICON
    property string formColor: Defaults.FALLBACK_COLOR
    property bool formSwitch: true

    function focusNameInput() {
        createNameInput.forceActiveFocus();
    }

    function submitForm() {
        modal.submitted(modal.editingId, formName, formIcon, formColor, formSwitch);
    }

    onVisibleChanged: {
        if (visible) {
            formName = initialName;
            formIcon = initialIcon || Defaults.FALLBACK_ICON;
            formColor = initialColor || Defaults.FALLBACK_COLOR;
            formSwitch = initialSwitch;
        }
    }

    closedScale: 0.95
    useExpressiveCurves: false

    Keys.onEscapePressed: event => {
        modal.closed();
        event.accepted = true;
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacingXL
        spacing: Theme.spacingL

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingM

            StyledText {
                text: modal.editingId > 0 ? ("Edit Workspace Group " + modal.editingId) : "Create Workspace Group"
                font.pixelSize: Theme.fontSizeLarge + 2
                font.weight: Font.Bold
                color: Theme.surfaceText
            }

            Item { Layout.fillWidth: true }

            WGIconButton {
                buttonSize: 32
                baseColor: "transparent"
                hoverColor: Theme.surfaceContainerHighest
                iconName: "close"
                iconSize: 18
                iconColor: Theme.surfaceVariantText
                onClicked: modal.closed()
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingXS

            StyledText {
                text: "Group Name"
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Medium
                color: Theme.surfaceVariantText
            }

            DankTextField {
                id: createNameInput
                Layout.fillWidth: true
                text: modal.formName
                placeholderText: "e.g. Work, Gaming, Notes"
                focus: modal.visible
                keyForwardTargets: [modal, modal.focusScopeItem]
                Keys.onEscapePressed: event => {
                    modal.closed();
                    event.accepted = true;
                }
                onTextEdited: {
                    modal.formName = createNameInput.text;
                }
                onAccepted: {
                    modal.submitForm();
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingXS

            StyledText {
                text: "Icon (Nerd Font Glyph)"
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Medium
                color: Theme.surfaceVariantText
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.spacingM

                Rectangle {
                    width: 52
                    height: 52
                    radius: Theme.cornerRadiusSmall
                    color: Theme.withAlpha(modal.formColor, 0.15)
                    border.color: modal.formColor
                    border.width: 1.5

                    StyledText {
                        anchors.centerIn: parent
                        text: modal.formIcon || Defaults.FALLBACK_ICON
                        font.pixelSize: 30
                        color: modal.formColor
                    }
                }

                DankTextField {
                    id: createIconInput
                    implicitWidth: 80
                    text: modal.formIcon
                    placeholderText: Defaults.FALLBACK_ICON
                    keyForwardTargets: [modal, modal.focusScopeItem]
                    Keys.onEscapePressed: event => {
                        modal.closed();
                        event.accepted = true;
                    }
                    onTextEdited: {
                        modal.formIcon = createIconInput.text;
                    }
                    onAccepted: {
                        modal.submitForm();
                    }
                }

                DankButton {
                    text: "Randomize"
                    iconName: "casino"
                    onClicked: {
                        if (modal.iconPool.length > 0) {
                            modal.formIcon = modal.iconPool[Math.floor(Math.random() * modal.iconPool.length)];
                        }
                    }
                }

                Item { Layout.fillWidth: true }
            }

            Row {
                spacing: 6
                Layout.fillWidth: true

                Repeater {
                    model: Defaults.ICON_PRESETS

                    WGIconButton {
                        buttonSize: 32
                        baseColor: Theme.surfaceContainer
                        hoverColor: Theme.surfaceContainerHighest
                        borderColor: modal.formIcon === modelData ? modal.formColor : "transparent"
                        borderWidth: 1.5
                        text: modelData
                        textSize: 16
                        textColor: Theme.surfaceText
                        onClicked: {
                            modal.formIcon = modelData;
                        }
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingXS

            StyledText {
                text: "Color Accent"
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Medium
                color: Theme.surfaceVariantText
            }

            Row {
                spacing: 8
                Layout.fillWidth: true

                Repeater {
                    model: modal.colorList

                    WGIconButton {
                        buttonSize: 28
                        baseColor: modelData
                        hoverColor: modelData
                        borderColor: modal.formColor === modelData ? Theme.surfaceText : Theme.withAlpha(Theme.outlineVariant, 0.5)
                        borderWidth: modal.formColor === modelData ? 2.5 : 1
                        onClicked: {
                            modal.formColor = modelData;
                        }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingM
            visible: modal.editingId === 0

            StyledText {
                text: "Switch to group immediately"
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceText
                Layout.fillWidth: true
            }

            DankToggle {
                checked: modal.formSwitch
                onToggled: isChecked => {
                    modal.formSwitch = isChecked;
                }
            }
        }

        Item { height: Theme.spacingS }

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingM

            Item { Layout.fillWidth: true }

            DankButton {
                text: "Cancel"
                onClicked: modal.closed()
            }

            DankButton {
                text: modal.editingId > 0 ? "Save Changes" : "Create Group"
                iconName: modal.editingId > 0 ? "check" : "add"
                backgroundColor: modal.formColor || Theme.primary
                textColor: Theme.surfaceContainer
                onClicked: modal.submitForm()
            }
        }
    }
}
