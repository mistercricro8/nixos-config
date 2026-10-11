import QtQuick
import qs.Common
import qs.Modules.Plugins
import qs.Widgets

PluginSettings {
    id: root
    pluginId: "dramaticLyrics"

    StyledText {
        width: parent.width
        text: "Dramatic Lyrics"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    StyledText {
        width: parent.width
        text: "GPU-accelerated fullscreen dramatic lyrics overlay. Automatically follows your active media player across all monitors or chosen displays, with character-level reveal, shimmer, and wind-drift effects."
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }

    ToggleSetting {
        settingKey: "enabled"
        label: "Enabled"
        description: "Show lyrics while music plays."
        defaultValue: true
    }

    SelectionSetting {
        settingKey: "monitorMode"
        label: "Monitor Mode"
        description: "Choose which monitors display the lyrics overlay."
        options: [
            { label: "Specific Monitor", value: "single" },
            { label: "All Monitors", value: "all" },
            { label: "Primary Monitor Only", value: "primary" }
        ]
        defaultValue: "single"
    }

    StringSetting {
        settingKey: "monitorName"
        label: "Target Monitor Name"
        description: "Output name (e.g. HDMI-A-1 or DP-1) when using Specific Monitor."
        placeholder: "DP-1"
        defaultValue: "DP-1"
    }

    StringSetting {
        settingKey: "font"
        label: "Default Font"
        description: "Fontconfig family used when a singer declares none."
        placeholder: "Impact"
        defaultValue: "Impact"
    }

    StringSetting {
        settingKey: "fontSize"
        label: "Font Size"
        description: "Base size: percent of screen (e.g. 5%), pixels (64px), or em."
        placeholder: "5%"
        defaultValue: "5%"
    }

    SliderSetting {
        settingKey: "revealMs"
        label: "Reveal Duration"
        description: "How long each character takes to fade in."
        minimum: 0
        maximum: 1000
        unit: "ms"
        defaultValue: 250
    }

    SliderSetting {
        settingKey: "rotationDeg"
        label: "Line Rotation"
        description: "Maximum random rotation per line, ±degrees."
        minimum: 0
        maximum: 45
        unit: "°"
        defaultValue: 15
    }

    SliderSetting {
        settingKey: "letterRotationDeg"
        label: "Letter Rotation"
        description: "Maximum random rotation per character, ±degrees."
        minimum: 0
        maximum: 15
        unit: "°"
        defaultValue: 3
    }

    StringSetting {
        settingKey: "letterSpacing"
        label: "Letter Spacing"
        description: "Extra space between letters (px, % of width, or em)."
        placeholder: "0.2em"
        defaultValue: "0.2em"
    }

    StringSetting {
        settingKey: "margin"
        label: "Screen Margin"
        description: "Empty border kept around screen edges."
        placeholder: "4%"
        defaultValue: "4%"
    }

    SliderSetting {
        settingKey: "windSecTimes10"
        label: "Wind Exit Duration"
        description: "How long finished verses take to blow away (tenths of a second)."
        minimum: 0
        maximum: 30
        defaultValue: 12
    }

    StringSetting {
        settingKey: "windDriftX"
        label: "Wind Drift X"
        description: "How far exiting lines drift left (px, %, or em)."
        placeholder: "0.1em"
        defaultValue: "0.1em"
    }

    StringSetting {
        settingKey: "windDriftY"
        label: "Wind Drift Y"
        description: "How far exiting lines drift up (px, %, or em)."
        placeholder: "0.25em"
        defaultValue: "0.25em"
    }

    SliderSetting {
        settingKey: "windRotationDeg"
        label: "Wind Rotation"
        description: "Exit rotation angle in degrees."
        minimum: 0
        maximum: 45
        unit: "°"
        defaultValue: 0
    }

    StringSetting {
        settingKey: "shimmerAmp"
        label: "Shimmer Amplitude"
        description: "Idle character wobble (px, % of screen, or em)."
        placeholder: "0.02em"
        defaultValue: "0.02em"
    }

    SliderSetting {
        settingKey: "shimmerPeriodSecTimes10"
        label: "Shimmer Period"
        description: "Seconds per shimmer cycle (tenths)."
        minimum: 5
        maximum: 80
        defaultValue: 30
    }

    ToggleSetting {
        settingKey: "bloomEnabled"
        label: "GPU Bloom Glow"
        description: "GPU-accelerated glow in each character's own color."
        defaultValue: true
    }

    SliderSetting {
        settingKey: "bloomIntensityTimes10"
        label: "Bloom Intensity"
        description: "Scales glow radius and brightness (tenths)."
        minimum: 0
        maximum: 20
        defaultValue: 10
    }
}
