import QtQuick
import qs.Common
import qs.Widgets
import qs.DCommon.Widgets
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
        text: "Load a JSON file containing custom emoji/sticker entries. Supports fuzzy search (abbreviations, typos, word boundaries) and automatically recommends emojis based on usage frequency and recency."
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
        text: "Usage & Recommendations"
        font.pixelSize: Theme.fontSizeMedium
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    StyledText {
        width: parent.width
        text: "Usage counts and timestamps are tracked each time an emoji is copied or pasted. Top emojis appear first when opening the launcher with an empty query, and are boosted during search."
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }

    DButton {
        text: "Reset Usage Statistics"
        iconName: "delete_sweep"
        onClicked: {
            if (root.pluginService && typeof root.pluginService.clearPluginState === "function") {
                root.pluginService.clearPluginState(root.pluginId);
            }
        }
    }

    StyledText {
        width: parent.width
        text: "File format: a JSON array where each entry has \"name\" (search term) and \"url\" (local path or remote URL). Remote images are downloaded and cached on load. On select, the URL is copied to clipboard."
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }
}
