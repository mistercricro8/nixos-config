import QtQuick
import Quickshell
import qs.Common
import qs.Services
import "./QuickLinksConstants.js" as Constants
import "./QuickLinksSearch.js" as Search

Item {
    id: root

    property var pluginService: null
    property string pluginId: Constants.PLUGIN_ID
    property string trigger: Constants.DEFAULT_TRIGGER
    property var links: []
    property int maxRecommendations: Constants.DEFAULT_MAX_RECOMMENDATIONS

    signal itemsChanged()

    Connections {
        target: pluginService
        enabled: pluginService !== null

        function onPluginDataChanged(changedPluginId) {
            if (changedPluginId !== pluginId) {
                return;
            }
            trigger = pluginService.loadPluginData(pluginId, Constants.SETTING_KEY_TRIGGER, Constants.DEFAULT_TRIGGER);
            maxRecommendations = pluginService.loadPluginData(pluginId, Constants.SETTING_KEY_MAX_RECOMMENDATIONS, Constants.DEFAULT_MAX_RECOMMENDATIONS);
            itemsChanged();
        }

        function onPluginStateChanged(changedPluginId) {
            if (changedPluginId !== pluginId) {
                return;
            }
            loadStoredLinks();
        }
    }

    Component.onCompleted: {
        if (!pluginService) {
            links = Constants.STARTER_LINKS.slice();
            return;
        }

        trigger = pluginService.loadPluginData(pluginId, Constants.SETTING_KEY_TRIGGER, Constants.DEFAULT_TRIGGER);
        maxRecommendations = pluginService.loadPluginData(pluginId, Constants.SETTING_KEY_MAX_RECOMMENDATIONS, Constants.DEFAULT_MAX_RECOMMENDATIONS);
        loadStoredLinks();
    }

    onTriggerChanged: {
        if (pluginService) {
            pluginService.savePluginData(pluginId, Constants.SETTING_KEY_TRIGGER, trigger);
        }
    }

    function loadStoredLinks() {
        if (!pluginService) {
            return;
        }
        var rawLinks = pluginService.loadPluginState(pluginId, Constants.STATE_KEY_LINKS, null);
        if (!rawLinks || !Array.isArray(rawLinks)) {
            links = Constants.STARTER_LINKS.slice();
            pluginService.savePluginState(pluginId, Constants.STATE_KEY_LINKS, links);
        } else {
            links = rawLinks;
        }
        itemsChanged();
    }

    function saveStoredLinks() {
        if (!pluginService) {
            return;
        }
        pluginService.savePluginState(pluginId, Constants.STATE_KEY_LINKS, links);
        itemsChanged();
    }

    function getItems(query) {
        var items = [];
        var cleanQuery = (query || "").trim();

        var addCandidate = Search.parseQuickAdd(cleanQuery);
        if (addCandidate !== null) {
            items.push({
                name: "Add Link: " + addCandidate.title,
                icon: Constants.ADD_ICON,
                comment: addCandidate.url + (addCandidate.tags.length > 0 ? " [#" + addCandidate.tags.join(" #") + "]" : ""),
                action: Constants.ACTION_ADD_PREFIX + JSON.stringify(addCandidate),
                categories: [Constants.CATEGORY_NAME],
                isAddAction: true
            });
        }

        var matchedLinks = Search.searchLinks(links, cleanQuery, maxRecommendations);
        var now = Date.now();

        for (var i = 0; i < matchedLinks.length; i++) {
            var l = matchedLinks[i];
            var tagStr = (Array.isArray(l.tags) && l.tags.length > 0) ? ("[" + l.tags.join(", ") + "] • ") : "";
            var usageStr = (typeof l.usageCount === "number" && l.usageCount > 0)
                ? (" • " + l.usageCount + "x, " + Search.formatRelativeTime(l.lastUsed, now))
                : "";

            var itemIcon = Constants.DEFAULT_ICON;
            if (cleanQuery.length === 0 && l.usageCount > 0) {
                itemIcon = Constants.RECOMMENDATION_ICON;
            }

            items.push({
                name: l.title || l.url,
                icon: itemIcon,
                comment: tagStr + l.url + usageStr,
                action: Constants.ACTION_OPEN_PREFIX + l.url,
                categories: [Constants.CATEGORY_NAME],
                linkId: l.id,
                url: l.url,
                linkTitle: l.title || l.url,
                isAddAction: false
            });
        }

        return items;
    }

    function executeItem(item) {
        if (!item || !item.action || typeof item.action !== "string") {
            return;
        }

        if (item.action.startsWith(Constants.ACTION_OPEN_PREFIX)) {
            var targetUrl = item.action.substring(Constants.ACTION_OPEN_PREFIX.length);
            _recordLinkUsage(item.linkId, targetUrl);
            Quickshell.execDetached(["xdg-open", targetUrl]);
            if (typeof ToastService !== "undefined") {
                ToastService.showInfo("Opening Link", targetUrl);
            }
        } else if (item.action.startsWith(Constants.ACTION_ADD_PREFIX)) {
            var rawData = item.action.substring(Constants.ACTION_ADD_PREFIX.length);
            try {
                var newLinkData = JSON.parse(rawData);
                _addNewLink(newLinkData);
            } catch (e) {
                if (typeof ToastService !== "undefined") {
                    ToastService.showWarning("Failed to add link", e.message);
                }
            }
        } else if (item.action.startsWith(Constants.ACTION_COPY_PREFIX)) {
            var textToCopy = item.action.substring(Constants.ACTION_COPY_PREFIX.length);
            Quickshell.execDetached(["dms", "cl", "copy", textToCopy]);
            if (typeof ToastService !== "undefined") {
                ToastService.showInfo("Copied to clipboard", textToCopy);
            }
        } else if (item.action.startsWith(Constants.ACTION_DELETE_PREFIX)) {
            var deleteId = item.action.substring(Constants.ACTION_DELETE_PREFIX.length);
            _deleteLink(deleteId);
        } else {
            console.warn("QuickLinks: Unrecognized action prefix in", item.action);
        }
    }

    function _recordLinkUsage(linkId, url) {
        var foundIndex = -1;
        for (var i = 0; i < links.length; i++) {
            if ((linkId && links[i].id === linkId) || links[i].url === url) {
                foundIndex = i;
                break;
            }
        }

        if (foundIndex !== -1) {
            var updated = Object.assign({}, links[foundIndex]);
            updated.usageCount = (typeof updated.usageCount === "number" ? updated.usageCount : 0) + 1;
            updated.lastUsed = Date.now();
            links[foundIndex] = updated;
            saveStoredLinks();
        }
    }

    function _addNewLink(data) {
        var existingIdx = -1;
        for (var i = 0; i < links.length; i++) {
            if (links[i].url === data.url) {
                existingIdx = i;
                break;
            }
        }

        var entry = {
            id: "link_" + Date.now() + "_" + Math.floor(Math.random() * 1000),
            title: data.title || data.url,
            url: data.url,
            tags: Array.isArray(data.tags) ? data.tags : [],
            keywords: Array.isArray(data.keywords) ? data.keywords : [],
            usageCount: 0,
            lastUsed: 0
        };

        if (existingIdx !== -1) {
            links[existingIdx] = entry;
        } else {
            links.unshift(entry);
        }

        saveStoredLinks();
        if (typeof ToastService !== "undefined") {
            ToastService.showInfo("Link Saved", entry.title);
        }
    }

    function _deleteLink(linkId) {
        links = links.filter(function(l) {
            return l.id !== linkId;
        });
        saveStoredLinks();
        if (typeof ToastService !== "undefined") {
            ToastService.showInfo("Link Removed", "");
        }
    }

    function getPasteText(item) {
        if (!item) {
            return null;
        }
        if (item.action && item.action.startsWith(Constants.ACTION_OPEN_PREFIX)) {
            return item.action.substring(Constants.ACTION_OPEN_PREFIX.length);
        }
        return null;
    }

    function getContextMenuActions(item) {
        if (!item || item.isAddAction || !item.url) {
            return [];
        }

        var linkUrl = item.url;
        var linkTitle = item.linkTitle || item.name || linkUrl;
        var linkId = item.linkId;

        return [
            {
                icon: "open_in_browser",
                text: "Open in Browser",
                action: function() {
                    Quickshell.execDetached(["xdg-open", linkUrl]);
                    _recordLinkUsage(linkId, linkUrl);
                }
            },
            {
                icon: "content_copy",
                text: "Copy URL",
                action: function() {
                    Quickshell.execDetached(["dms", "cl", "copy", linkUrl]);
                    if (typeof ToastService !== "undefined") {
                        ToastService.showInfo("Copied URL", linkUrl);
                    }
                }
            },
            {
                icon: "data_object",
                text: "Copy as Markdown",
                action: function() {
                    var md = "[" + linkTitle + "](" + linkUrl + ")";
                    Quickshell.execDetached(["dms", "cl", "copy", md]);
                    if (typeof ToastService !== "undefined") {
                        ToastService.showInfo("Copied Markdown", md);
                    }
                }
            },
            {
                icon: "refresh",
                text: "Reset Stats",
                action: function() {
                    for (var i = 0; i < links.length; i++) {
                        if (links[i].id === linkId) {
                            var updated = Object.assign({}, links[i]);
                            updated.usageCount = 0;
                            updated.lastUsed = 0;
                            links[i] = updated;
                            break;
                        }
                    }
                    saveStoredLinks();
                    if (typeof ToastService !== "undefined") {
                        ToastService.showInfo("Stats Reset", linkTitle);
                    }
                }
            },
            {
                icon: "delete",
                text: "Delete Link",
                action: function() {
                    _deleteLink(linkId);
                }
            }
        ];
    }
}
