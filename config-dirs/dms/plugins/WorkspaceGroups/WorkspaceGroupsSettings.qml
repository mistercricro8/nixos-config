import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.Common
import qs.Widgets
import qs.Modules.Plugins
import "WorkspaceGroupsDefaults.js" as Defaults

PluginSettings {
    id: root
    pluginId: "workspaceGroups"
    WorkspaceGroupsIpc {
        id: wgIpc
    }

    readonly property var defaultGroups: [
        { "id": 1, "name": Defaults.DEFAULT_GROUP_NAME, "icon": Defaults.FALLBACK_ICON, "color": Defaults.FALLBACK_COLOR }
    ]

    property int currentWsPerMonitor: Defaults.WS_DEFAULT
    property bool currentHideEmptyWorkspaces: true
    property string statusMessage: ""
    property bool isReady: false

    ListModel {
        id: groupsModel
    }

    function loadCurrentSettings() {
        if (!pluginService)
            return;
        const savedOnLaunch = root.loadValue("onLaunchGroups", null);
        const savedGroups = root.loadValue("groups", null);
        let list = defaultGroups;
        if (savedOnLaunch && Array.isArray(savedOnLaunch) && savedOnLaunch.length > 0) {
            list = savedOnLaunch;
        } else if (savedGroups && Array.isArray(savedGroups) && savedGroups.length > 0) {
            list = savedGroups;
        }
        groupsModel.clear();
        for (let i = 0; i < list.length; i++) {
            const g = list[i];
            groupsModel.append({
                "id": g.id || (i + 1),
                "name": (g.name !== undefined && g.name !== null && g.name !== "") ? String(g.name) : (Defaults.NAME_PREFIX + (i + 1)),
                "icon": (g.icon !== undefined && g.icon !== null && g.icon !== "") ? String(g.icon) : Defaults.FALLBACK_ICON,
                "color": (g.color !== undefined && g.color !== null && g.color !== "") ? String(g.color) : Defaults.FALLBACK_COLOR
            });
        }
        const loadedWsPerMon = parseInt(root.loadValue("workspacesPerMonitor", Defaults.WS_DEFAULT), 10);
        currentWsPerMonitor = isNaN(loadedWsPerMon) ? Defaults.WS_DEFAULT : Math.max(Defaults.WS_MIN, Math.min(Defaults.WS_MAX, loadedWsPerMon));
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
        interval: Defaults.STATUS_TIMEOUT
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
                "name": rawName.length > 0 ? rawName : (Defaults.NAME_PREFIX + (i + 1)),
                "icon": rawIcon.length > 0 ? rawIcon : Defaults.FALLBACK_ICON,
                "color": rawColor.length > 0 ? rawColor : Defaults.FALLBACK_COLOR
            });
        }
        return arr;
    }

    function saveAll() {
        if (!isReady)
            return;
        const normalized = getGroupsArray();
        root.saveValue("onLaunchGroups", normalized);
        root.saveValue("groups", normalized);
        root.saveValue("workspacesPerMonitor", currentWsPerMonitor);
        root.saveValue("hideEmptyWorkspaces", currentHideEmptyWorkspaces);
        statusMessage = "On-launch configuration saved!";
        statusTimer.restart();
    }

    function applyToCurrentSession() {
        saveAll();
        wgIpc.call(wgIpc.resetToLaunch);
        statusMessage = "Applied to current session!";
        statusTimer.restart();
    }

    function addGroup() {
        const nextId = groupsModel.count + 1;
        const color = Defaults.COLOR_PALETTE[(nextId - 1) % Defaults.COLOR_PALETTE.length];
        const icon = Defaults.ICON_PRESETS[(nextId - 1) % Defaults.ICON_PRESETS.length];
        groupsModel.append({
            "id": nextId,
            "name": Defaults.NAME_PREFIX + nextId,
            "icon": icon,
            "color": color
        });
        saveAll();
    }

    function removeGroup(index) {
        if (groupsModel.count <= 1)
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
        currentWsPerMonitor = Defaults.WS_DEFAULT;
        currentHideEmptyWorkspaces = true;
        saveAll();
    }

    ColumnLayout {
        width: parent.width
        spacing: Theme.spacingXS

        StyledText {
            text: "Workspace Groups (On-Launch Configuration)"
            font.pixelSize: Theme.fontSizeLarge
            font.weight: Font.Bold
            color: Theme.surfaceText
        }

        StyledText {
            text: "Configure the default workspace groups initialized when DMS starts. Groups dynamically created or deleted during your session will not overwrite this on-launch configuration."
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

                    WGIconButton {
                        buttonSize: 32
                        baseColor: Theme.surfaceContainer
                        hoverColor: Theme.surfaceContainerHighest
                        borderColor: Theme.outlineVariant
                        borderWidth: 1
                        text: "-"
                        textSize: 18
                        textWeight: Font.Bold
                        textColor: Theme.surfaceText
                        onClicked: {
                            if (root.currentWsPerMonitor > Defaults.WS_MIN) {
                                root.currentWsPerMonitor--;
                                root.saveAll();
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

                    WGIconButton {
                        buttonSize: 32
                        baseColor: Theme.surfaceContainer
                        hoverColor: Theme.surfaceContainerHighest
                        borderColor: Theme.outlineVariant
                        borderWidth: 1
                        text: "+"
                        textSize: 18
                        textWeight: Font.Bold
                        textColor: Theme.surfaceText
                        onClicked: {
                            if (root.currentWsPerMonitor < Defaults.WS_MAX) {
                                root.currentWsPerMonitor++;
                                root.saveAll();
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

            GroupCardEditor {
                groupIdx: index
                groupName: (model.name !== undefined && model.name !== null) ? model.name : ""
                groupIcon: (model.icon !== undefined && model.icon !== null) ? model.icon : Defaults.FALLBACK_ICON
                groupColor: (model.color !== undefined && model.color !== null) ? model.color : Defaults.FALLBACK_COLOR
                removable: groupsModel.count > 1
                onNameEdited: (idx, text) => {
                    groupsModel.setProperty(idx, "name", text);
                }
                onIconEdited: (idx, text) => {
                    groupsModel.setProperty(idx, "icon", text);
                }
                onColorEdited: (idx, text) => {
                    groupsModel.setProperty(idx, "color", text);
                }
                onEditingFinished: root.saveAll()
                onIconPicked: (idx, icon) => {
                    groupsModel.setProperty(idx, "icon", icon);
                    root.saveAll();
                }
                onColorPicked: (idx, color) => {
                    groupsModel.setProperty(idx, "color", color);
                    root.saveAll();
                }
                onRemoved: idx => root.removeGroup(idx)
            }
        }
    }

    RowLayout {
        width: parent.width
        spacing: Theme.spacingM

        DankButton {
            text: "Save On-Launch Config"
            iconName: "save"
            backgroundColor: Theme.primary
            textColor: Theme.onPrimary
            onClicked: root.saveAll()
        }

        DankButton {
            text: "Apply to Current Session"
            iconName: "sync"
            onClicked: root.applyToCurrentSession()
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
