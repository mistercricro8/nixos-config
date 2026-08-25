import QtQuick
import Quickshell
import Quickshell.Io
import QtCore
import qs.Common
import qs.Services

QtObject {
    id: root

    property var pluginService: null
    property string pluginId: "customEmojiLauncher"
    property string trigger: "e:"

    signal itemsChanged

    property string emojiFilePath: ""
    property var entries: []
    property var localIconCache: ({})

    readonly property string cacheDir: {
        const p = String(StandardPaths.writableLocation(StandardPaths.GenericCacheLocation));
        return (p.startsWith("file://") ? p.substring(7) : p) + "/DankMaterialShell/customEmojiLauncher";
    }

    property int _downloadPending: 0

    property Connections serviceConn: Connections {
        target: pluginService
        enabled: pluginService !== null

        function onPluginDataChanged(changedPluginId) {
            if (changedPluginId !== pluginId)
                return;
            trigger = pluginService.loadPluginData(pluginId, "trigger", "e:");
            const newPath = pluginService.loadPluginData(pluginId, "emojiFilePath", "");
            if (newPath === emojiFilePath)
                return;
            emojiFilePath = newPath;
            loadEntriesFromFile(emojiFilePath);
        }
    }

    Component.onCompleted: {
        if (!pluginService)
            return;
        trigger = pluginService.loadPluginData(pluginId, "trigger", "e:");
        emojiFilePath = pluginService.loadPluginData(pluginId, "emojiFilePath", "");
        if (emojiFilePath)
            loadEntriesFromFile(emojiFilePath);
    }

    function loadEntriesFromFile(path) {
        if (!path || path.trim() === "") {
            entries = [];
            localIconCache = {};
            itemsChanged();
            return;
        }
        const escapedPath = path.replace(/\\/g, "\\\\").replace(/"/g, '\\"');
        try {
            const qml = 'import QtQuick; import Quickshell.Io; FileView { path: "' + escapedPath + '"; blockLoading: true; blockWrites: true }';
            const fv = Qt.createQmlObject(qml, root, "emoji_file_reader");
            const raw = fv.text();
            fv.destroy();
            if (raw && raw.trim()) {
                const parsed = JSON.parse(raw);
                entries = Array.isArray(parsed) ? parsed : [];
            } else {
                entries = [];
            }
        } catch (e) {
            console.warn("CustomEmojiLauncher: Failed to read file:", path, e.message);
            entries = [];
        }
        localIconCache = {};
        itemsChanged();
        downloadAllEntries();
    }

    function urlToFilename(url) {
        const hash = url.split("").reduce((h, c) => ((h << 5) + h + c.charCodeAt(0)) & 0x7FFFFFFF, 5381).toString(16).padStart(8, "0");
        const ext = url.split("?")[0].split(".").pop().toLowerCase();
        const safeExt = ["png", "jpg", "jpeg", "gif", "webp", "svg", "avif"].includes(ext) ? ext : "png";
        return hash + "." + safeExt;
    }

    function downloadAllEntries() {
        if (entries.length === 0)
            return;
        _downloadPending = entries.length;
        for (let i = 0; i < entries.length; i++) {
            downloadEntry(entries[i]);
        }
    }

    function downloadEntry(entry) {
        const url = entry.url || "";
        if (!url) {
            _onDownloadDone();
            return;
        }
        const filename = urlToFilename(url);
        const destPath = cacheDir + "/" + filename;

        const isRemote = url.startsWith("http://") || url.startsWith("https://");
        if (!isRemote) {
            const localPath = url.startsWith("file://") ? url.substring(7) : url;
            localIconCache[url] = localPath;
            localIconCache = Object.assign({}, localIconCache);
            _onDownloadDone();
            return;
        }

        const safeDir = cacheDir.replace(/'/g, "'\\''");
        const safeDest = destPath.replace(/'/g, "'\\''");
        const safeUrl = url.replace(/'/g, "'\\''");
        const shellCmd = "mkdir -p '" + safeDir + "' && curl -sSL -o '" + safeDest + "' '" + safeUrl + "'";
        const qml = 'import Quickshell.Io\nProcess {\n    signal downloadSucceeded()\n    signal downloadFailed()\n    command: ["sh", "-c", ' + JSON.stringify(shellCmd) + ']\n    running: true\n    onExited: exitCode => {\n        if (exitCode === 0) downloadSucceeded()\n        else downloadFailed()\n        destroy()\n    }\n}';
        try {
            const obj = Qt.createQmlObject(qml, root, "dl_" + filename);
            obj.downloadSucceeded.connect(() => {
                localIconCache[url] = destPath;
                localIconCache = Object.assign({}, localIconCache);
                _onDownloadDone();
            });
            obj.downloadFailed.connect(() => {
                console.warn("CustomEmojiLauncher: Failed to download", url);
                _onDownloadDone();
            });
        } catch (e) {
            console.warn("CustomEmojiLauncher: Qt.createQmlObject failed:", e.message);
            _onDownloadDone();
        }
    }

    function _onDownloadDone() {
        _downloadPending = Math.max(0, _downloadPending - 1);
        if (_downloadPending === 0)
            itemsChanged();
    }

    function getItems(query) {
        const lowerQuery = query ? query.toLowerCase().trim() : "";
        const filtered = lowerQuery.length === 0 ? entries : entries.filter(e => (e.name || "").toLowerCase().includes(lowerQuery));
        return filtered.map(e => {
            const url = e.url || "";
            const localPath = localIconCache[url] || "";
            return {
                name: e.name || "",
                icon: localPath ? "image:" + localPath : "material:mood",
                comment: url,
                action: "copy:" + url,
                categories: ["Custom Emoji"],
                imageUrl: url,
                animated: (url.endsWith(".gif") || url.endsWith(".webp"))
            };
        });
    }

    function executeItem(item) {
        const url = getPasteText(item);
        if (!url)
            return;
        Quickshell.execDetached(["dms", "cl", "copy", url]);
        ToastService.showInfo("Copied: " + (item.name || url), url);
    }

    function getPasteText(item) {
        if (!item?.action?.startsWith("copy:"))
            return null;
        return item.action.substring(5);
    }

    function getContextMenuActions(item) {
        if (!item)
            return [];
        return [
            {
                icon: "content_copy",
                text: "Copy URL",
                action: () => {
                    const url = item.imageUrl || "";
                    if (!url)
                        return;
                    Quickshell.execDetached(["dms", "cl", "copy", url]);
                    ToastService.showInfo("Copied", url);
                }
            }
        ];
    }
}
