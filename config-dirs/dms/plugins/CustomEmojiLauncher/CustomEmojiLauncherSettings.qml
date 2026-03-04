import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginSettings {
    id: root
    pluginId: "customEmojiLauncher"

    StyledText {
        width: parent.width
        text: "Custom Emoji Launcher"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    StyledText {
        width: parent.width
        text: "Load a JSON file containing custom emoji/sticker entries. Each entry needs a name and a URL pointing to an image file."
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }

    StringSetting {
        settingKey: "emojiFilePath"
        label: "Emoji File Path"
        description: "Absolute path to a JSON file with entries: [{\"name\": \"smile\", \"url\": \"/path/to/smile.png\"}, ...]"
        placeholder: "/home/user/emojis.json"
        defaultValue: ""
    }

    StringSetting {
        settingKey: "trigger"
        label: "Trigger"
        description: "Prefix to activate this plugin in the launcher (e.g. e:)"
        placeholder: "e:"
        defaultValue: "e:"
    }

    StyledText {
        width: parent.width
        text: "File format: a JSON array where each entry has \"name\" (search term) and \"url\" (local path or remote URL). Remote images are downloaded and cached on load. On select, the URL is copied to clipboard."
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }
}
