import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins
import "WorkspaceGroupsDefaults.js" as Defaults
import "WorkspaceGroupsMath.js" as WGMath

PluginComponent {
    id: root

    layerNamespacePlugin: "workspace-groups"
    property var popoutService: null
    WorkspaceGroupsIpc {
        id: wgIpc
    }

    property string activeGroupIcon: Defaults.FALLBACK_ICON
    property string activeGroupName: Defaults.DEFAULT_GROUP_NAME
    property string activeGroupColor: Defaults.FALLBACK_COLOR
    property int activeGroupIndex: 1
    property var groupsList: []
    property int workspacesPerMonitor: Defaults.WS_DEFAULT
    property int monitorCount: 1
    property bool hideEmptyWorkspaces: true
    property var sortedMonitorNames: []
    property var monitorPriority: Defaults.MONITOR_PRIORITY.slice()

    property int _toplevelsTrigger: 0

    readonly property string screenName: root.parentScreen?.name || ""

    popoutWidth: 320

    function updateFromGlobals() {
        if (!PluginService)
            return;
        activeGroupIndex = PluginService.getGlobalVar(Defaults.TARGET, Defaults.KEY_ACTIVE_INDEX, 1);
        groupsList = PluginService.getGlobalVar(Defaults.TARGET, Defaults.KEY_GROUPS, []);
        activeGroupName = PluginService.getGlobalVar(Defaults.TARGET, Defaults.KEY_ACTIVE_NAME, Defaults.DEFAULT_GROUP_NAME);
        activeGroupIcon = PluginService.getGlobalVar(Defaults.TARGET, Defaults.KEY_ACTIVE_ICON, Defaults.FALLBACK_ICON);
        activeGroupColor = PluginService.getGlobalVar(Defaults.TARGET, Defaults.KEY_ACTIVE_COLOR, Defaults.FALLBACK_COLOR);
        workspacesPerMonitor = PluginService.getGlobalVar(Defaults.TARGET, Defaults.KEY_WS_PER_MON, Defaults.WS_DEFAULT);
        monitorCount = PluginService.getGlobalVar(Defaults.TARGET, Defaults.KEY_MON_COUNT, 1);
        hideEmptyWorkspaces = PluginService.getGlobalVar(Defaults.TARGET, Defaults.KEY_HIDE_EMPTY, true);
        sortedMonitorNames = PluginService.getGlobalVar(Defaults.TARGET, Defaults.KEY_SORTED_MONS, []);
        monitorPriority = PluginService.getGlobalVar(Defaults.TARGET, Defaults.KEY_MON_PRIO, Defaults.MONITOR_PRIORITY.slice());
    }

    Component.onCompleted: {
        updateFromGlobals();
    }

    Connections {
        target: PluginService
        function onGlobalVarChanged(pluginId, varName) {
            if (pluginId === Defaults.TARGET) {
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
        function onRawEvent(event) {
            if (event.name === "workspace" || event.name === "focusedmon" || event.name === "moveworkspace") {
                root._toplevelsTrigger++;
            }
        }
    }

    Connections {
        target: Hyprland.monitors
        function onValuesChanged() {
            root._toplevelsTrigger++;
        }
    }
    function getMonitorIndex() {
        if (sortedMonitorNames && sortedMonitorNames.length > 0) {
            const sIdx = sortedMonitorNames.indexOf(root.screenName);
            if (sIdx >= 0)
                return sIdx;
        }
        const mons = Hyprland.monitors?.values || [];
        const prio = (monitorPriority && monitorPriority.length > 0) ? monitorPriority : ["HDMI-A-1", "DP-1"];
        const sorted = [];
        const seen = {};
        for (let i = 0; i < prio.length; i++) {
            const p = prio[i];
            const m = mons.find(x => x.name === p);
            if (m) {
                sorted.push(m);
                seen[m.name] = true;
            }
        }
        for (let i = 0; i < mons.length; i++) {
            const m = mons[i];
            if (!seen[m.name])
                sorted.push(m);
        }
        const idx = sorted.findIndex(m => m.name === root.screenName);
        return idx >= 0 ? idx : 0;
    }

    readonly property int activeWorkspaceIdOnThisMon: {
        root._toplevelsTrigger;
        const mon = (Hyprland.monitors?.values || []).find(m => m.name === root.screenName);
        const monWs = WGMath.resolveWorkspaceId(mon?.activeWorkspace);
        if (monWs > 0) return monWs;
        const focusedWs = WGMath.resolveWorkspaceId(Hyprland.focusedWorkspace);
        if (focusedWs > 0) return focusedWs;
        return 1;
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
            const wId = WGMath.resolveWorkspaceId(tl);
            if (wId === wsId)
                return true;
        }
        const workspaces = Hyprland.workspaces?.values || [];
        const foundWs = workspaces.find(w => WGMath.resolveWorkspaceId(w) === wsId);
        if (foundWs && (foundWs.windows > 0 || (foundWs.lastIpcObject && foundWs.lastIpcObject.windows > 0))) {
            return true;
        }
        return false;
    }

    function cycleGroupFromWheel(event) {
        if (event.angleDelta.y > 0) {
            wgIpc.call(wgIpc.prevGroup);
        } else if (event.angleDelta.y < 0) {
            wgIpc.call(wgIpc.nextGroup);
        }
    }
    pillClickAction: () => {
        wgIpc.call(wgIpc.toggleOverview);
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
                                wgIpc.call(wgIpc.toggleOverview);
                            }
                        }
                        onWheel: event => root.cycleGroupFromWheel(event)
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

                            WsPill {
                                id: wsPill
                                subNumber: modelData
                                targetWs: root.getTargetWorkspaceId(subNumber)
                                isActive: root.activeWorkspaceIdOnThisMon === targetWs
                                isOccupied: root.isWorkspaceOccupied(targetWs)
                                activeColor: root.activeGroupColor
                                orientation: "horizontal"
                                showDot: true
                                onClicked: mouse => {
                                    if (mouse.button === Qt.RightButton) {
                                        wgIpc.call(wgIpc.moveSubOnMon, subNumber.toString(), root.screenName);
                                    } else {
                                        wgIpc.call(wgIpc.switchSubOnMon, subNumber.toString(), root.screenName);
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
                                wgIpc.call(wgIpc.cycleSub, "prev");
                            } else if (event.angleDelta.y < 0) {
                                wgIpc.call(wgIpc.cycleSub, "next");
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
                                wgIpc.call(wgIpc.toggleOverview);
                            }
                        }
                        onWheel: event => root.cycleGroupFromWheel(event)
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

                    WsPill {
                        id: vertWsPill
                        Layout.alignment: Qt.AlignHCenter
                        subNumber: modelData
                        targetWs: root.getTargetWorkspaceId(subNumber)
                        isActive: root.activeWorkspaceIdOnThisMon === targetWs
                        isOccupied: root.isWorkspaceOccupied(targetWs)
                        activeColor: root.activeGroupColor
                        orientation: "vertical"
                        showDot: false
                        onClicked: mouse => {
                            if (mouse.button === Qt.RightButton) {
                                wgIpc.call(wgIpc.moveSubOnMon, subNumber.toString(), root.screenName);
                            } else {
                                wgIpc.call(wgIpc.switchSubOnMon, subNumber.toString(), root.screenName);
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
                                wgIpc.call(wgIpc.switchGroup, modelData.id.toString());
                                popoutComp.closePopout?.();
                            }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Theme.spacingM
                            anchors.rightMargin: Theme.spacingM
                            spacing: Theme.spacingS

                            StyledText {
                                text: modelData.icon || Defaults.FALLBACK_ICON
                                font.pixelSize: Theme.fontSizeMedium + 2
                                color: modelData.color || Defaults.FALLBACK_COLOR
                            }

                            StyledText {
                                text: modelData.name || (Defaults.NAME_PREFIX + modelData.id)
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

                            WGIconButton {
                                id: delPopBtn
                                visible: root.groupsList.length > 1
                                buttonSize: 24
                                baseColor: "transparent"
                                hoverColor: Theme.withAlpha(Theme.error, 0.2)
                                iconName: "delete"
                                iconSize: 14
                                iconColor: delPopBtn.containsMouse ? Theme.error : Theme.outlineMedium
                                onClicked: {
                                    wgIpc.call(wgIpc.remove, modelData.id.toString());
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

                PopoutActionCard {
                    iconName: "add"
                    label: "New Workspace Group (Super + Alt + Tab)"
                    onActivated: {
                        popoutComp.closePopout?.();
                        wgIpc.call(wgIpc.openCreate);
                    }
                }

                PopoutActionCard {
                    glyph: "󰍹"
                    label: "Open Group Overview (Super + Tab)"
                    onActivated: {
                        popoutComp.closePopout?.();
                        wgIpc.call(wgIpc.toggleOverview);
                    }
                }
            }
        }
    }
}
