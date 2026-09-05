import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    layerNamespacePlugin: "workspace-groups"
    property var popoutService: null

    property string activeGroupIcon: "󰅩"
    property string activeGroupName: "Code"
    property string activeGroupColor: "#89b4fa"
    property int activeGroupIndex: 1
    property var groupsList: []
    property int workspacesPerMonitor: 10
    property int monitorCount: 1
    property bool hideEmptyWorkspaces: true

    property int _toplevelsTrigger: 0

    readonly property string screenName: root.parentScreen?.name || ""

    popoutWidth: 320

    function updateFromGlobals() {
        if (!PluginService)
            return;
        activeGroupIndex = PluginService.getGlobalVar("workspaceGroups", "activeGroupIndex", 1);
        groupsList = PluginService.getGlobalVar("workspaceGroups", "groups", []);
        activeGroupName = PluginService.getGlobalVar("workspaceGroups", "activeGroupName", "Code");
        activeGroupIcon = PluginService.getGlobalVar("workspaceGroups", "activeGroupIcon", "󰅩");
        activeGroupColor = PluginService.getGlobalVar("workspaceGroups", "activeGroupColor", "#89b4fa");
        workspacesPerMonitor = PluginService.getGlobalVar("workspaceGroups", "workspacesPerMonitor", 10);
        monitorCount = PluginService.getGlobalVar("workspaceGroups", "monitorCount", 1);
        hideEmptyWorkspaces = PluginService.getGlobalVar("workspaceGroups", "hideEmptyWorkspaces", true);
    }

    Component.onCompleted: {
        updateFromGlobals();
    }

    Connections {
        target: PluginService
        function onGlobalVarChanged(pluginId, varName) {
            if (pluginId === "workspaceGroups") {
                root.updateFromGlobals();
            }
        }
    }

    Connections {
        target: Hyprland
        function onToplevelsChanged() {
            root._toplevelsTrigger++;
        }
        function onFocusedWorkspaceChanged() {
            root._toplevelsTrigger++;
        }
        function onWorkspacesChanged() {
            root._toplevelsTrigger++;
        }
    }

    function getMonitorIndex() {
        const mons = Hyprland.monitors?.values || [];
        const idx = mons.findIndex(m => m.name === root.screenName);
        return idx >= 0 ? idx : 0;
    }

    readonly property int activeWorkspaceIdOnThisMon: {
        root._toplevelsTrigger;
        const mon = (Hyprland.monitors?.values || []).find(m => m.name === root.screenName);
        return mon?.activeWorkspace?.id || Hyprland.focusedWorkspace?.id || 1;
    }

    readonly property var subWorkspacesList: {
        root._toplevelsTrigger;
        root.hideEmptyWorkspaces;
        const count = Math.max(1, Math.min(20, root.workspacesPerMonitor || 10));
        const arr = [];
        for (let i = 1; i <= count; i++) {
            const targetWs = root.getTargetWorkspaceId(i);
            const isActive = root.activeWorkspaceIdOnThisMon === targetWs;
            const isOccupied = root.isWorkspaceOccupied(targetWs);
            if (!root.hideEmptyWorkspaces || isActive || isOccupied) {
                arr.push(i);
            }
        }
        return arr;
    }

    function getTargetWorkspaceId(subWs) {
        const K = root.workspacesPerMonitor || 10;
        const M = Math.max(1, root.monitorCount);
        const G = root.activeGroupIndex;
        const m = root.getMonitorIndex();
        return (G - 1) * (K * M) + (m * K) + subWs;
    }

    function isWorkspaceOccupied(wsId) {
        root._toplevelsTrigger;
        const toplevels = Hyprland.toplevels?.values || [];
        for (let i = 0; i < toplevels.length; i++) {
            const tl = toplevels[i];
            const wId = tl.workspace?.id ?? tl.lastIpcObject?.workspace?.id;
            if (wId === wsId)
                return true;
        }
        const workspaces = Hyprland.workspaces?.values || [];
        const foundWs = workspaces.find(w => w.id === wsId);
        if (foundWs && (foundWs.windows > 0 || (foundWs.lastIpcObject && foundWs.lastIpcObject.windows > 0))) {
            return true;
        }
        return false;
    }

    pillClickAction: () => {
        Quickshell.execDetached(["dms", "ipc", "call", "workspaceGroups", "toggleOverview"]);
    }

    pillRightClickAction: () => {
        if (root.hasPopout) {
            pluginPopout.toggle();
        }
    }

    horizontalBarPill: Component {
        Item {
            id: horizItem
            implicitWidth: barRow.implicitWidth
            implicitHeight: barRow.implicitHeight

            RowLayout {
                id: barRow
                anchors.centerIn: parent
                spacing: Theme.spacingS

                Rectangle {
                    id: groupPill
                    implicitWidth: groupRow.implicitWidth + Theme.spacingM
                    implicitHeight: 28
                    radius: Theme.cornerRadiusSmall
                    color: groupMouse.containsMouse ? Theme.withAlpha(root.activeGroupColor, 0.25) : Theme.withAlpha(root.activeGroupColor, 0.15)
                    border.color: Theme.withAlpha(root.activeGroupColor, 0.4)
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: 100 } }

                    RowLayout {
                        id: groupRow
                        anchors.centerIn: parent
                        spacing: Theme.spacingXS

                        StyledText {
                            text: root.activeGroupIcon
                            font.pixelSize: Theme.fontSizeMedium + 2
                            color: root.activeGroupColor
                        }

                        StyledText {
                            text: root.activeGroupName
                            font.pixelSize: Theme.fontSizeMedium
                            font.weight: Font.DemiBold
                            color: Theme.surfaceText
                            elide: Text.ElideRight
                        }
                    }

                    MouseArea {
                        id: groupMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: mouse => {
                            if (mouse.button === Qt.RightButton) {
                                if (root.hasPopout) {
                                    pluginPopout.toggle();
                                }
                            } else {
                                Quickshell.execDetached(["dms", "ipc", "call", "workspaceGroups", "toggleOverview"]);
                            }
                        }
                        onWheel: event => {
                            if (event.angleDelta.y > 0) {
                                Quickshell.execDetached(["dms", "ipc", "call", "workspaceGroups", "prevGroup"]);
                            } else if (event.angleDelta.y < 0) {
                                Quickshell.execDetached(["dms", "ipc", "call", "workspaceGroups", "nextGroup"]);
                            }
                        }
                    }
                }

                Rectangle {
                    visible: root.subWorkspacesList.length > 0
                    implicitWidth: 1
                    implicitHeight: 16
                    color: Theme.outlineVariant
                    opacity: 0.5
                }

                Item {
                    visible: root.subWorkspacesList.length > 0
                    implicitWidth: wsRow.implicitWidth
                    implicitHeight: wsRow.implicitHeight

                    Row {
                        id: wsRow
                        spacing: 4

                        Repeater {
                            model: root.subWorkspacesList

                            Rectangle {
                                id: wsPill
                                readonly property int subNumber: modelData
                                readonly property int targetWs: root.getTargetWorkspaceId(subNumber)
                                readonly property bool isActive: root.activeWorkspaceIdOnThisMon === targetWs
                                readonly property bool isOccupied: root.isWorkspaceOccupied(targetWs)

                                width: isActive ? 28 : 24
                                height: 26
                                radius: Theme.cornerRadiusSmall

                                color: {
                                    if (isActive)
                                        return root.activeGroupColor;
                                    if (wsMouse.containsMouse)
                                        return Theme.surfaceContainerHighest;
                                    if (isOccupied)
                                        return Theme.withAlpha(Theme.surfaceContainerHigh, 0.7);
                                    return "transparent";
                                }

                                border.color: {
                                    if (isActive)
                                        return root.activeGroupColor;
                                    if (isOccupied)
                                        return Theme.withAlpha(root.activeGroupColor, 0.4);
                                    if (wsMouse.containsMouse)
                                        return Theme.outlineVariant;
                                    return "transparent";
                                }
                                border.width: 1

                                Behavior on width { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                                Behavior on color { ColorAnimation { duration: 100 } }
                                Behavior on border.color { ColorAnimation { duration: 100 } }

                                StyledText {
                                    anchors.centerIn: parent
                                    text: wsPill.subNumber.toString()
                                    font.pixelSize: Theme.fontSizeSmall
                                    font.weight: wsPill.isActive ? Font.Bold : (wsPill.isOccupied ? Font.DemiBold : Font.Normal)
                                    color: {
                                        if (wsPill.isActive)
                                            return Theme.surfaceContainer;
                                        if (wsPill.isOccupied)
                                            return Theme.surfaceText;
                                        return Theme.surfaceVariantText;
                                    }
                                    opacity: wsPill.isActive ? 1.0 : (wsPill.isOccupied ? 0.95 : 0.65)
                                }

                                Rectangle {
                                    visible: wsPill.isOccupied && !wsPill.isActive
                                    width: 4
                                    height: 4
                                    radius: 2
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: 2
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    color: root.activeGroupColor
                                }

                                MouseArea {
                                    id: wsMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                                    onClicked: mouse => {
                                        if (mouse.button === Qt.RightButton) {
                                            Quickshell.execDetached(["dms", "ipc", "call", "workspaceGroups", "moveWindowToSubWorkspace", wsPill.subNumber.toString()]);
                                        } else {
                                            Quickshell.execDetached(["dms", "ipc", "call", "workspaceGroups", "switchToSubWorkspace", wsPill.subNumber.toString(), root.screenName]);
                                        }
                                    }
                                }
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.NoButton
                        onWheel: event => {
                            if (event.angleDelta.y > 0) {
                                Quickshell.execDetached(["dms", "ipc", "call", "workspaceGroups", "cycleSubWorkspaces", "prev"]);
                            } else if (event.angleDelta.y < 0) {
                                Quickshell.execDetached(["dms", "ipc", "call", "workspaceGroups", "cycleSubWorkspaces", "next"]);
                            }
                        }
                    }
                }
            }
        }
    }

    verticalBarPill: Component {
        Item {
            id: vertItem
            implicitWidth: verticalContent.implicitWidth
            implicitHeight: verticalContent.implicitHeight

            ColumnLayout {
                id: verticalContent
                anchors.centerIn: parent
                spacing: 4

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: 32
                    implicitHeight: 32
                    radius: Theme.cornerRadiusSmall
                    color: vertGroupMouse.containsMouse ? Theme.withAlpha(root.activeGroupColor, 0.25) : Theme.withAlpha(root.activeGroupColor, 0.15)
                    border.color: Theme.withAlpha(root.activeGroupColor, 0.4)
                    border.width: 1

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 1

                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: root.activeGroupIcon
                            font.pixelSize: Theme.fontSizeSmall + 2
                            color: root.activeGroupColor
                        }

                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: root.activeGroupIndex.toString()
                            font.pixelSize: 9
                            font.weight: Font.Bold
                            color: Theme.surfaceText
                        }
                    }

                    MouseArea {
                        id: vertGroupMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: mouse => {
                            if (mouse.button === Qt.RightButton) {
                                if (root.hasPopout)
                                    pluginPopout.toggle();
                            } else {
                                Quickshell.execDetached(["dms", "ipc", "call", "workspaceGroups", "toggleOverview"]);
                            }
                        }
                        onWheel: event => {
                            if (event.angleDelta.y > 0) {
                                Quickshell.execDetached(["dms", "ipc", "call", "workspaceGroups", "prevGroup"]);
                            } else if (event.angleDelta.y < 0) {
                                Quickshell.execDetached(["dms", "ipc", "call", "workspaceGroups", "nextGroup"]);
                            }
                        }
                    }
                }

                Rectangle {
                    visible: root.subWorkspacesList.length > 0
                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: 16
                    implicitHeight: 1
                    color: Theme.outlineVariant
                    opacity: 0.5
                }

                Repeater {
                    model: root.subWorkspacesList

                    Rectangle {
                        id: vertWsPill
                        Layout.alignment: Qt.AlignHCenter
                        readonly property int subNumber: modelData
                        readonly property int targetWs: root.getTargetWorkspaceId(subNumber)
                        readonly property bool isActive: root.activeWorkspaceIdOnThisMon === targetWs
                        readonly property bool isOccupied: root.isWorkspaceOccupied(targetWs)

                        width: 24
                        height: isActive ? 28 : 24
                        radius: Theme.cornerRadiusSmall

                        color: {
                            if (isActive)
                                return root.activeGroupColor;
                            if (vertWsMouse.containsMouse)
                                return Theme.surfaceContainerHighest;
                            if (isOccupied)
                                return Theme.withAlpha(Theme.surfaceContainerHigh, 0.7);
                            return "transparent";
                        }

                        border.color: {
                            if (isActive)
                                return root.activeGroupColor;
                            if (isOccupied)
                                return Theme.withAlpha(root.activeGroupColor, 0.4);
                            return "transparent";
                        }
                        border.width: 1

                        StyledText {
                            anchors.centerIn: parent
                            text: vertWsPill.subNumber.toString()
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: vertWsPill.isActive ? Font.Bold : (vertWsPill.isOccupied ? Font.DemiBold : Font.Normal)
                            color: {
                                if (vertWsPill.isActive)
                                    return Theme.surfaceContainer;
                                if (vertWsPill.isOccupied)
                                    return Theme.surfaceText;
                                return Theme.surfaceVariantText;
                            }
                        }

                        MouseArea {
                            id: vertWsMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Quickshell.execDetached(["dms", "ipc", "call", "workspaceGroups", "switchToSubWorkspace", vertWsPill.subNumber.toString(), root.screenName]);
                            }
                        }
                    }
                }
            }
        }
    }

    popoutContent: Component {
        PopoutComponent {
            id: popoutComp
            headerText: "Workspace Groups"
            detailsText: "Active: " + root.activeGroupIndex + ": " + root.activeGroupName
            showCloseButton: true

            Column {
                width: parent.width
                spacing: Theme.spacingS

                Repeater {
                    model: root.groupsList

                    Rectangle {
                        width: parent.width
                        height: 38
                        radius: Theme.cornerRadiusSmall
                        property bool isCurrent: root.activeGroupIndex === modelData.id
                        color: isCurrent ? Theme.primaryContainer : (itemMouseArea.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerLow)
                        border.color: isCurrent ? Theme.primary : Theme.outlineVariant
                        border.width: isCurrent ? 2 : 1

                        MouseArea {
                            id: itemMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Quickshell.execDetached(["dms", "ipc", "call", "workspaceGroups", "switchToGroup", modelData.id.toString()]);
                                popoutComp.closePopout?.();
                            }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Theme.spacingM
                            anchors.rightMargin: Theme.spacingM
                            spacing: Theme.spacingS

                            StyledText {
                                text: modelData.icon || "󰅩"
                                font.pixelSize: Theme.fontSizeMedium + 2
                                color: modelData.color || Theme.primary
                            }

                            StyledText {
                                text: modelData.name || ("Group " + modelData.id)
                                font.pixelSize: Theme.fontSizeMedium
                                font.weight: Font.DemiBold
                                color: Theme.surfaceText
                                Layout.fillWidth: true
                            }

                            StyledText {
                                visible: isCurrent
                                text: "ACTIVE"
                                font.pixelSize: 10
                                font.weight: Font.Bold
                                color: Theme.primary
                            }

                            Rectangle {
                                visible: root.groupsList.length > 1
                                width: 24
                                height: 24
                                radius: 12
                                color: delPopMouse.containsMouse ? Theme.withAlpha(Theme.error, 0.2) : "transparent"

                                DankIcon {
                                    anchors.centerIn: parent
                                    name: "delete"
                                    size: 14
                                    color: delPopMouse.containsMouse ? Theme.error : Theme.outlineMedium
                                }

                                MouseArea {
                                    id: delPopMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        Quickshell.execDetached(["dms", "ipc", "call", "workspaceGroups", "deleteGroup", modelData.id.toString()]);
                                    }
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Theme.outlineVariant
                }

                Rectangle {
                    width: parent.width
                    height: 36
                    radius: Theme.cornerRadiusSmall
                    color: addBtnMouse.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainer

                    MouseArea {
                        id: addBtnMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            popoutComp.closePopout?.();
                            Quickshell.execDetached(["dms", "ipc", "call", "workspaceGroups", "openCreateGroup"]);
                        }
                    }

                    Row {
                        anchors.centerIn: parent
                        spacing: Theme.spacingS

                        DankIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            name: "add"
                            size: 16
                            color: Theme.primary
                        }

                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "New Workspace Group (Super + Alt + Tab)"
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Font.Medium
                            color: Theme.primary
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 36
                    radius: Theme.cornerRadiusSmall
                    color: overviewBtnMouse.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainer

                    MouseArea {
                        id: overviewBtnMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            popoutComp.closePopout?.();
                            Quickshell.execDetached(["dms", "ipc", "call", "workspaceGroups", "toggleOverview"]);
                        }
                    }

                    Row {
                        anchors.centerIn: parent
                        spacing: Theme.spacingS

                        StyledText {
                            text: "󰍹"
                            font.pixelSize: Theme.fontSizeMedium
                            color: Theme.primary
                        }

                        StyledText {
                            text: "Open Group Overview (Super + Tab)"
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Font.Medium
                            color: Theme.primary
                        }
                    }
                }
            }
        }
    }
}
