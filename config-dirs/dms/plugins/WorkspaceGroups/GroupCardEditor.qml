import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.Common
import qs.Widgets
import "WorkspaceGroupsDefaults.js" as Defaults

Rectangle {
    id: editor

    property int groupIdx: 0
    property string groupName: ""
    property string groupIcon: Defaults.FALLBACK_ICON
    property string groupColor: Defaults.FALLBACK_COLOR
    property bool removable: true
    signal nameEdited(int idx, string text)
    signal iconEdited(int idx, string text)
    signal colorEdited(int idx, string text)
    signal editingFinished
    signal iconPicked(int idx, string icon)
    signal colorPicked(int idx, string color)
    signal removed(int idx)

    function bindSave(field, idx, key) {
        if (field.getActiveFocus()) {
            if (key === "name") {
                editor.nameEdited(idx, field.text);
            } else if (key === "icon") {
                editor.iconEdited(idx, field.text);
            } else {
                editor.colorEdited(idx, field.text);
            }
        }
    }

    Layout.fillWidth: true
    implicitHeight: cardCol.implicitHeight + Theme.spacingM * 2
    radius: Theme.cornerRadius
    color: Theme.surfaceContainerLow
    border.color: Theme.outlineVariant
    border.width: 1

    ColumnLayout {
        id: cardCol
        anchors.fill: parent
        anchors.margins: Theme.spacingM
        spacing: Theme.spacingM

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingM

            Rectangle {
                width: 36
                height: 36
                radius: 18
                color: Theme.withAlpha(editor.groupColor || Theme.primary, 0.2)
                border.color: editor.groupColor || Theme.primary
                border.width: 1.5

                StyledText {
                    anchors.centerIn: parent
                    text: (editor.groupIdx + 1).toString()
                    font.pixelSize: Theme.fontSizeMedium
                    font.weight: Font.Bold
                    color: editor.groupColor || Theme.primary
                }
            }

            StyledText {
                text: editor.groupIcon || Defaults.FALLBACK_ICON
                font.pixelSize: 26
                color: editor.groupColor || Theme.primary
            }

            DankTextField {
                id: nameField
                Layout.fillWidth: true
                text: editor.groupName
                placeholderText: "Group Name (e.g. Code, Browse)"
                onTextEdited: {
                    editor.bindSave(nameField, editor.groupIdx, "name");
                }
                onEditingFinished: {
                    editor.editingFinished();
                }
            }

            WGIconButton {
                id: delBtn
                visible: editor.removable
                buttonSize: 34
                baseColor: Theme.surfaceContainer
                hoverColor: Theme.withAlpha(Theme.error, 0.2)
                iconName: "delete"
                iconSize: 18
                iconColor: delBtn.containsMouse ? Theme.error : Theme.surfaceVariantText
                onClicked: editor.removed(editor.groupIdx)
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingS

            StyledText {
                text: "Icon:"
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Medium
                color: Theme.surfaceVariantText
            }

            DankTextField {
                id: iconField
                implicitWidth: 70
                text: editor.groupIcon
                placeholderText: Defaults.FALLBACK_ICON
                onTextEdited: {
                    editor.bindSave(iconField, editor.groupIdx, "icon");
                }
                onEditingFinished: {
                    editor.editingFinished();
                }
            }

            Row {
                spacing: 4
                Layout.fillWidth: true

                Repeater {
                    model: Defaults.ICON_PRESETS

                    WGIconButton {
                        buttonSize: 28
                        baseColor: Theme.surfaceContainer
                        hoverColor: Theme.surfaceContainerHighest
                        borderColor: editor.groupIcon === modelData ? Theme.primary : "transparent"
                        borderWidth: 1.5
                        text: modelData
                        textSize: 15
                        textColor: Theme.surfaceText
                        onClicked: {
                            editor.iconPicked(editor.groupIdx, modelData);
                        }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingS

            StyledText {
                text: "Color:"
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Medium
                color: Theme.surfaceVariantText
            }

            Rectangle {
                width: 24
                height: 24
                radius: 12
                color: editor.groupColor || Theme.primary
                border.color: Theme.outlineVariant
                border.width: 1
            }

            DankTextField {
                id: colorField
                implicitWidth: 100
                text: editor.groupColor
                placeholderText: Defaults.FALLBACK_COLOR
                onTextEdited: {
                    editor.bindSave(colorField, editor.groupIdx, "color");
                }
                onEditingFinished: {
                    editor.editingFinished();
                }
            }

            Row {
                spacing: 6
                Layout.fillWidth: true

                Repeater {
                    model: Defaults.COLOR_PALETTE

                    WGIconButton {
                        buttonSize: 24
                        baseColor: modelData
                        hoverColor: modelData
                        borderColor: editor.groupColor === modelData ? Theme.surfaceText : Theme.withAlpha(Theme.outlineVariant, 0.5)
                        borderWidth: editor.groupColor === modelData ? 2.5 : 1
                        onClicked: {
                            editor.colorPicked(editor.groupIdx, modelData);
                        }
                    }
                }
            }
        }
    }
}
