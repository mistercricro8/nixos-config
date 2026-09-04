import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginSettings {
    id: root
    pluginId: "workspaceGroups"

    readonly property var defaultGroups: [
        { "id": 1, "name": "Code", "icon": "󰅩", "color": "#89b4fa" },
        { "id": 2, "name": "Browse", "icon": "󰈹", "color": "#f38ba8" },
        { "id": 3, "name": "Media", "icon": "󰋋", "color": "#a6e3a1" },
        { "id": 4, "name": "System", "icon": "󰇄", "color": "#fab387" }
    ]

    property int currentWsPerMonitor: 10
    property bool currentHideEmptyWorkspaces: true
    property string statusMessage: ""
    property bool isReady: false

    ListModel {
        id: groupsModel
    }

    function loadCurrentSettings() {
        if (!pluginService)
            return;
        const savedGroups = root.loadValue("groups", defaultGroups);
        let list = defaultGroups;
        if (savedGroups && Array.isArray(savedGroups) && savedGroups.length > 0) {
            list = savedGroups;
        }
        groupsModel.clear();
        for (let i = 0; i < list.length; i++) {
            const g = list[i];
            groupsModel.append({
                "id": g.id || (i + 1),
                "name": (g.name !== undefined && g.name !== null && g.name !== "") ? String(g.name) : ("Group " + (i + 1)),
                "icon": (g.icon !== undefined && g.icon !== null && g.icon !== "") ? String(g.icon) : "󰅩",
                "color": (g.color !== undefined && g.color !== null && g.color !== "") ? String(g.color) : "#89b4fa"
            });
        }
        currentWsPerMonitor = root.loadValue("workspacesPerMonitor", 10);
        currentHideEmptyWorkspaces = root.loadValue("hideEmptyWorkspaces", true);
        isReady = true;
    }

    Component.onCompleted: {
        Qt.callLater(loadCurrentSettings);
    }

    onPluginServiceChanged: {
        if (pluginService)
            Qt.callLater(loadCurrentSettings);
    }

    Timer {
        id: statusTimer
        interval: 4000
        repeat: false
        onTriggered: {
            root.statusMessage = "";
        }
    }

    function getGroupsArray() {
        const arr = [];
        for (let i = 0; i < groupsModel.count; i++) {
            const item = groupsModel.get(i);
            const rawName = item.name !== undefined && item.name !== null ? String(item.name).trim() : "";
            const rawIcon = item.icon !== undefined && item.icon !== null ? String(item.icon).trim() : "";
            const rawColor = item.color !== undefined && item.color !== null ? String(item.color).trim() : "";
            arr.push({
                "id": i + 1,
                "name": rawName.length > 0 ? rawName : ("Group " + (i + 1)),
                "icon": rawIcon.length > 0 ? rawIcon : "󰅩",
                "color": rawColor.length > 0 ? rawColor : "#89b4fa"
            });
        }
        return arr;
    }

    function saveAll() {
        if (!isReady)
            return;
        const normalized = getGroupsArray();
        root.saveValue("groups", normalized);
        root.saveValue("workspacesPerMonitor", currentWsPerMonitor);
        root.saveValue("hideEmptyWorkspaces", currentHideEmptyWorkspaces);
        statusMessage = "Settings saved & synced to Hyprland!";
        statusTimer.restart();
        Quickshell.execDetached(["dms", "ipc", "call", "workspaceGroups", "getGroups"]);
    }

    function addGroup() {
        const nextId = groupsModel.count + 1;
        const palette = ["#89b4fa", "#f38ba8", "#a6e3a1", "#fab387", "#cba6f7", "#f9e2af", "#94e2d5", "#74c7ec"];
        const icons = ["󰅩", "󰈹", "󰝚", "󰒓", "󰊴", "󰭹", "󰠮", "󰢹"];
        const color = palette[(nextId - 1) % palette.length];
        const icon = icons[(nextId - 1) % icons.length];
        groupsModel.append({
            "id": nextId,
            "name": "Group " + nextId,
            "icon": icon,
            "color": color
        });
        saveAll();
    }

    function removeGroup(index) {
        if (groupsModel.count <= 2)
            return;
        groupsModel.remove(index);
        for (let i = 0; i < groupsModel.count; i++) {
            groupsModel.setProperty(i, "id", i + 1);
        }
        saveAll();
    }

    function resetDefaults() {
        groupsModel.clear();
        for (let i = 0; i < defaultGroups.length; i++) {
            groupsModel.append(JSON.parse(JSON.stringify(defaultGroups[i])));
        }
        currentWsPerMonitor = 10;
        currentHideEmptyWorkspaces = true;
        saveAll();
    }

    ColumnLayout {
        width: parent.width
        spacing: Theme.spacingXS

        StyledText {
            text: "Workspace Groups Configuration"
            font.pixelSize: Theme.fontSizeLarge
            font.weight: Font.Bold
            color: Theme.surfaceText
        }

        StyledText {
            text: "Group Hyprland workspaces into top-level namespaces. Workspaces are automatically allocated across monitors and keybindings are synced to ~/.config/hypr/dms/workspace_groups.lua."
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.surfaceVariantText
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
    }

    Rectangle {
        width: parent.width
        implicitHeight: generalCol.implicitHeight + Theme.spacingM * 2
        radius: Theme.cornerRadius
        color: Theme.surfaceContainerLow
        border.color: Theme.outlineVariant
        border.width: 1

        ColumnLayout {
            id: generalCol
            anchors.fill: parent
            anchors.margins: Theme.spacingM
            spacing: Theme.spacingM

            StyledText {
                text: "General Settings"
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.Bold
                color: Theme.surfaceText
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.spacingM

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    StyledText {
                        text: "Workspaces per Monitor"
                        font.pixelSize: Theme.fontSizeMedium
                        font.weight: Font.Medium
                        color: Theme.surfaceText
                    }

                    StyledText {
                        text: "Number of workspaces per group allocated to each connected display (Default: 10)"
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceVariantText
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                }

                RowLayout {
                    spacing: Theme.spacingS

                    Rectangle {
                        width: 32
                        height: 32
                        radius: 16
                        color: minusMouse.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainer
                        border.color: Theme.outlineVariant
                        border.width: 1

                        StyledText {
                            anchors.centerIn: parent
                            text: "-"
                            font.pixelSize: 18
                            font.weight: Font.Bold
                            color: Theme.surfaceText
                        }

                        MouseArea {
                            id: minusMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.currentWsPerMonitor > 5) {
                                    root.currentWsPerMonitor--;
                                    root.saveAll();
                                }
                            }
                        }
                    }

                    Rectangle {
                        width: 50
                        height: 32
                        radius: Theme.cornerRadiusSmall
                        color: Theme.surfaceContainerHighest

                        StyledText {
                            anchors.centerIn: parent
                            text: root.currentWsPerMonitor.toString()
                            font.pixelSize: Theme.fontSizeMedium
                            font.weight: Font.Bold
                            color: Theme.primary
                        }
                    }

                    Rectangle {
                        width: 32
                        height: 32
                        radius: 16
                        color: plusMouse.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainer
                        border.color: Theme.outlineVariant
                        border.width: 1

                        StyledText {
                            anchors.centerIn: parent
                            text: "+"
                            font.pixelSize: 18
                            font.weight: Font.Bold
                            color: Theme.surfaceText
                        }

                        MouseArea {
                            id: plusMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.currentWsPerMonitor < 20) {
                                    root.currentWsPerMonitor++;
                                    root.saveAll();
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.outlineVariant
                opacity: 0.5
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.spacingM

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    StyledText {
                        text: "Hide Empty Workspaces"
                        font.pixelSize: Theme.fontSizeMedium
                        font.weight: Font.Medium
                        color: Theme.surfaceText
                    }

                    StyledText {
                        text: "Only display sub-workspaces that have open windows or are currently active on DankBar"
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceVariantText
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                }

                DankToggle {
                    checked: root.currentHideEmptyWorkspaces
                    onToggled: isChecked => {
                        root.currentHideEmptyWorkspaces = isChecked;
                        root.saveAll();
                    }
                }
            }
        }
    }

    RowLayout {
        width: parent.width

        StyledText {
            text: "Group Definitions (" + groupsModel.count + ")"
            font.pixelSize: Theme.fontSizeMedium
            font.weight: Font.Bold
            color: Theme.surfaceText
            Layout.fillWidth: true
        }

        DankButton {
            text: "Add Group"
            iconName: "add"
            onClicked: root.addGroup()
        }
    }

    ColumnLayout {
        width: parent.width
        spacing: Theme.spacingM

        Repeater {
            model: groupsModel

            Rectangle {
                id: groupCardItem
                readonly property int groupIdx: index
                readonly property string groupName: (model.name !== undefined && model.name !== null) ? model.name : ""
                readonly property string groupIcon: (model.icon !== undefined && model.icon !== null) ? model.icon : "󰅩"
                readonly property string groupColor: (model.color !== undefined && model.color !== null) ? model.color : "#89b4fa"

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
                            color: Theme.withAlpha(groupCardItem.groupColor || Theme.primary, 0.2)
                            border.color: groupCardItem.groupColor || Theme.primary
                            border.width: 1.5

                            StyledText {
                                anchors.centerIn: parent
                                text: (groupCardItem.groupIdx + 1).toString()
                                font.pixelSize: Theme.fontSizeMedium
                                font.weight: Font.Bold
                                color: groupCardItem.groupColor || Theme.primary
                            }
                        }

                        StyledText {
                            text: groupCardItem.groupIcon || "󰅩"
                            font.pixelSize: 26
                            color: groupCardItem.groupColor || Theme.primary
                        }

                        DankTextField {
                            id: nameField
                            Layout.fillWidth: true
                            text: groupCardItem.groupName
                            placeholderText: "Group Name (e.g. Code, Browse)"
                            onTextEdited: {
                                if (nameField.getActiveFocus()) {
                                    groupsModel.setProperty(groupCardItem.groupIdx, "name", nameField.text);
                                }
                            }
                            onEditingFinished: {
                                root.saveAll();
                            }
                        }

                        Rectangle {
                            visible: groupsModel.count > 2
                            width: 34
                            height: 34
                            radius: 17
                            color: delMouse.containsMouse ? Theme.withAlpha(Theme.error, 0.2) : Theme.surfaceContainer

                            DankIcon {
                                anchors.centerIn: parent
                                name: "delete"
                                size: 18
                                color: delMouse.containsMouse ? Theme.error : Theme.surfaceVariantText
                            }

                            MouseArea {
                                id: delMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.removeGroup(groupCardItem.groupIdx)
                            }
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
                            text: groupCardItem.groupIcon
                            placeholderText: "󰅩"
                            onTextEdited: {
                                if (iconField.getActiveFocus()) {
                                    groupsModel.setProperty(groupCardItem.groupIdx, "icon", iconField.text);
                                }
                            }
                            onEditingFinished: {
                                root.saveAll();
                            }
                        }

                        Row {
                            spacing: 4
                            Layout.fillWidth: true

                            Repeater {
                                model: [
                                    { "icon": "󰅩", "tip": "Code" },
                                    { "icon": "󰈹", "tip": "Web" },
                                    { "icon": "󰝚", "tip": "Media" },
                                    { "icon": "󰒓", "tip": "System" },
                                    { "icon": "󰊴", "tip": "Gaming" },
                                    { "icon": "󰭹", "tip": "Chat" },
                                    { "icon": "󰠮", "tip": "Notes" },
                                    { "icon": "󰢹", "tip": "Terminal" }
                                ]

                                Rectangle {
                                    width: 28
                                    height: 28
                                    radius: 14
                                    color: iconPresetMouse.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainer
                                    border.color: groupCardItem.groupIcon === modelData.icon ? Theme.primary : "transparent"
                                    border.width: 1.5

                                    StyledText {
                                        anchors.centerIn: parent
                                        text: modelData.icon
                                        font.pixelSize: 15
                                        color: Theme.surfaceText
                                    }

                                    MouseArea {
                                        id: iconPresetMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            groupsModel.setProperty(groupCardItem.groupIdx, "icon", modelData.icon);
                                            root.saveAll();
                                        }
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
                            color: groupCardItem.groupColor || Theme.primary
                            border.color: Theme.outlineVariant
                            border.width: 1
                        }

                        DankTextField {
                            id: colorField
                            implicitWidth: 100
                            text: groupCardItem.groupColor
                            placeholderText: "#89b4fa"
                            onTextEdited: {
                                if (colorField.getActiveFocus()) {
                                    groupsModel.setProperty(groupCardItem.groupIdx, "color", colorField.text);
                                }
                            }
                            onEditingFinished: {
                                root.saveAll();
                            }
                        }

                        Row {
                            spacing: 6
                            Layout.fillWidth: true

                            Repeater {
                                model: ["#89b4fa", "#f38ba8", "#a6e3a1", "#fab387", "#cba6f7", "#f9e2af", "#94e2d5", "#74c7ec"]

                                Rectangle {
                                    width: 24
                                    height: 24
                                    radius: 12
                                    color: modelData
                                    border.color: groupCardItem.groupColor === modelData ? Theme.surfaceText : Theme.withAlpha(Theme.outlineVariant, 0.5)
                                    border.width: groupCardItem.groupColor === modelData ? 2.5 : 1

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            groupsModel.setProperty(groupCardItem.groupIdx, "color", modelData);
                                            root.saveAll();
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    RowLayout {
        width: parent.width
        spacing: Theme.spacingM

        DankButton {
            text: "Save & Apply Changes"
            iconName: "save"
            backgroundColor: Theme.primary
            textColor: Theme.onPrimary
            onClicked: root.saveAll()
        }

        DankButton {
            text: "Reset to Defaults"
            iconName: "restore"
            onClicked: root.resetDefaults()
        }

        StyledText {
            text: root.statusMessage
            font.pixelSize: Theme.fontSizeSmall
            font.weight: Font.DemiBold
            color: Theme.primary
            visible: root.statusMessage !== ""
            Layout.fillWidth: true
        }
    }
}
