import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Common
import qs.Widgets
import qs.DCommon.Widgets
import qs.Modules.Plugins
import "./QuickLinksConstants.js" as Constants
import "./QuickLinksSearch.js" as Search

PluginSettings {
    id: root
    pluginId: "quickLinks"

    property var linkList: []

    function refreshLinkList() {
        var stored = root.loadState(Constants.STATE_KEY_LINKS, null);
        if (stored && Array.isArray(stored)) {
            linkList = stored;
        } else {
            linkList = Constants.STARTER_LINKS.slice();
        }
    }

    Component.onCompleted: {
        Qt.callLater(refreshLinkList);
    }

    onPluginServiceChanged: {
        if (pluginService) {
            Qt.callLater(refreshLinkList);
        }
    }

    Connections {
        target: root.pluginService
        enabled: root.pluginService !== null

        function onPluginStateChanged(changedPluginId) {
            if (changedPluginId === root.pluginId) {
                root.refreshLinkList();
            }
        }
    }

    StyledText {
        width: parent.width
        text: "Quick Links Configuration"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    StyledText {
        width: parent.width
        text: "Store, fuzzy search, and quick-open URLs using tags and historic recommendations."
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }

    StringSetting {
        settingKey: Constants.SETTING_KEY_TRIGGER
        label: "Launcher Trigger"
        description: "Prefix entered in DMS launcher to activate Quick Links (e.g. l: or link:)"
        placeholder: Constants.DEFAULT_TRIGGER
        defaultValue: Constants.DEFAULT_TRIGGER
    }

    SliderSetting {
        settingKey: Constants.SETTING_KEY_MAX_RECOMMENDATIONS
        label: "Maximum Recommendations / Results"
        description: "Number of top results or historic recommendations shown in the launcher"
        minimum: 3
        maximum: 25
        defaultValue: Constants.DEFAULT_MAX_RECOMMENDATIONS
    }

    Rectangle {
        width: parent.width
        height: 1
        color: Theme.outline
        opacity: 0.25
    }

    Column {
        width: parent.width
        spacing: Theme.spacingS

        StyledText {
            text: "Add New Link"
            font.pixelSize: Theme.fontSizeMedium
            font.weight: Font.Bold
            color: Theme.surfaceText
        }

        DTextField {
            id: newUrlField
            width: parent.width
            placeholderText: "URL (e.g. https://github.com or nixos.org)"
        }

        DTextField {
            id: newTitleField
            width: parent.width
            placeholderText: "Title (e.g. GitHub Repository)"
        }

        DTextField {
            id: newTagsField
            width: parent.width
            placeholderText: "Tags, comma or space separated (e.g. git, code, work)"
        }

        DTextField {
            id: newKeywordsField
            width: parent.width
            placeholderText: "Additional search keywords (e.g. gh, pr, repo)"
        }

        Row {
            spacing: Theme.spacingM

            Rectangle {
                id: addBtnRect
                width: 120
                height: 38
                radius: 8
                color: addMouseArea.containsMouse ? Theme.primaryContainer : Theme.primary

                StyledText {
                    anchors.centerIn: parent
                    text: "Add Link"
                    font.weight: Font.DemiBold
                    color: Theme.onPrimary
                }

                MouseArea {
                    id: addMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        var rawUrl = newUrlField.text.trim();
                        if (rawUrl.length === 0) {
                            return;
                        }
                        var url = Search.normalizeUrl(rawUrl);
                        var title = newTitleField.text.trim();
                        if (title.length === 0) {
                            var withoutProto = url.replace(/^(https?:\/\/)/, "");
                            title = withoutProto.split("/")[0] || url;
                        }

                        var tags = newTagsField.text.split(/[, ]+/).map(function(t) {
                            return t.trim().toLowerCase().replace(/^#/, "");
                        }).filter(function(t) {
                            return t.length > 0;
                        });

                        var keywords = newKeywordsField.text.split(/[, ]+/).map(function(k) {
                            return k.trim().toLowerCase().replace(/^@/, "");
                        }).filter(function(k) {
                            return k.length > 0;
                        });

                        var newEntry = {
                            id: "link_" + Date.now() + "_" + Math.floor(Math.random() * 1000),
                            title: title,
                            url: url,
                            tags: tags,
                            keywords: keywords,
                            usageCount: 0,
                            lastUsed: 0
                        };

                        var updatedList = root.linkList.slice();
                        updatedList.unshift(newEntry);
                        root.saveState(Constants.STATE_KEY_LINKS, updatedList);
                        root.linkList = updatedList;

                        newUrlField.text = "";
                        newTitleField.text = "";
                        newTagsField.text = "";
                        newKeywordsField.text = "";
                    }
                }
            }
        }
    }

    Rectangle {
        width: parent.width
        height: 1
        color: Theme.outline
        opacity: 0.25
    }

    RowLayout {
        width: parent.width
        spacing: Theme.spacingM

        StyledText {
            text: "Stored Links (" + root.linkList.length + ")"
            font.pixelSize: Theme.fontSizeMedium
            font.weight: Font.Bold
            color: Theme.surfaceText
            Layout.fillWidth: true
        }

        Rectangle {
            width: 90
            height: 32
            radius: 6
            color: clearMouse.containsMouse ? "#40FF5252" : "#20FF5252"

            StyledText {
                anchors.centerIn: parent
                text: "Clear All"
                font.pixelSize: Theme.fontSizeSmall
                color: "#FF5252"
            }

            MouseArea {
                id: clearMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.saveState(Constants.STATE_KEY_LINKS, []);
                    root.linkList = [];
                }
            }
        }
    }

    Column {
        width: parent.width
        spacing: Theme.spacingS

        Repeater {
            model: root.linkList

            Rectangle {
                id: linkCard
                width: parent.width
                height: cardCol.implicitHeight + 16
                radius: 8
                color: Theme.surfaceContainerHigh || "#22272e"
                border.color: Theme.outline
                border.width: 1

                required property var modelData
                required property int index

                Column {
                    id: cardCol
                    anchors.left: parent.left
                    anchors.right: actionRow.left
                    anchors.top: parent.top
                    anchors.margins: 8
                    spacing: 4

                    StyledText {
                        width: parent.width
                        text: linkCard.modelData.title || linkCard.modelData.url
                        font.pixelSize: Theme.fontSizeMedium
                        font.weight: Font.DemiBold
                        color: Theme.surfaceText
                        elide: Text.ElideRight
                    }

                    StyledText {
                        width: parent.width
                        text: linkCard.modelData.url
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.primary
                        elide: Text.ElideRight
                    }

                    Row {
                        spacing: 8
                        visible: (linkCard.modelData.tags && linkCard.modelData.tags.length > 0) || (linkCard.modelData.usageCount > 0)

                        StyledText {
                            text: (linkCard.modelData.tags && linkCard.modelData.tags.length > 0) ? ("#" + linkCard.modelData.tags.join(" #")) : ""
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceVariantText
                        }

                        StyledText {
                            text: "• " + (linkCard.modelData.usageCount || 0) + " opens (" + Search.formatRelativeTime(linkCard.modelData.lastUsed, Date.now()) + ")"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceVariantText
                        }
                    }
                }

                Row {
                    id: actionRow
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.rightMargin: 8
                    spacing: 8

                    DActionButton {
                        iconName: "open_in_browser"
                        tooltipText: "Open in Browser"
                        onClicked: {
                            Quickshell.execDetached(["xdg-open", linkCard.modelData.url]);
                        }
                    }

                    DActionButton {
                        iconName: "refresh"
                        tooltipText: "Reset Stats"
                        onClicked: {
                            var currentList = root.linkList.slice();
                            for (var k = 0; k < currentList.length; k++) {
                                if (currentList[k].id === linkCard.modelData.id) {
                                    var updated = Object.assign({}, currentList[k]);
                                    updated.usageCount = 0;
                                    updated.lastUsed = 0;
                                    currentList[k] = updated;
                                    break;
                                }
                            }
                            root.saveState(Constants.STATE_KEY_LINKS, currentList);
                            root.linkList = currentList;
                        }
                    }

                    DActionButton {
                        iconName: "delete"
                        tooltipText: "Delete Link"
                        iconColor: "#FF5252"
                        onClicked: {
                            var filtered = root.linkList.filter(function(item) {
                                return item.id !== linkCard.modelData.id;
                            });
                            root.saveState(Constants.STATE_KEY_LINKS, filtered);
                            root.linkList = filtered;
                        }
                    }
                }
            }
        }
    }
}
