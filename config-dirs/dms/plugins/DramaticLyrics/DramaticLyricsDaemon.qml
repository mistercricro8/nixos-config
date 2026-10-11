import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.Mpris
import QtCore
import qs.Common
import qs.Services
import qs.Modules.Plugins
import "DramaticLyricsMath.js" as DM
import "LyrStyle.js" as LS

PluginComponent {
    id: root

    readonly property var ctl: LyricsService.controller
    readonly property bool playing: LyricsService.activePlayer?.playbackState === MprisPlaybackState.Playing
    readonly property bool ready: ctl.state === "ready"
    readonly property bool showLyrics: (pluginData.enabled ?? true) && root.playing && root.ready

    LyricsSubscription {
        active: (pluginData.enabled ?? true) && LyricsService.controller.available
    }

    property var cfg: ({})
    function rebuildCfg() {
        var p = pluginData || {};
        cfg = {
            enabled: p.enabled ?? true,
            font: p.font ?? "Impact",
            fontSize: p.fontSize ?? "5%",
            revealSec: (p.revealMs ?? 250) / 1000.0,
            rotationDeg: p.rotationDeg ?? 15,
            letterRotationDeg: p.letterRotationDeg ?? 3,
            letterSpacing: p.letterSpacing ?? "0.2em",
            margin: p.margin ?? "4%",
            windSec: (p.windSecTimes10 ?? 12) / 10.0,
            windDriftX: p.windDriftX ?? "0.1em",
            windDriftY: p.windDriftY ?? "0.25em",
            windRotationDeg: p.windRotationDeg ?? 0,
            shimmerAmp: p.shimmerAmp ?? "0.02em",
            shimmerPeriodSec: (p.shimmerPeriodSecTimes10 ?? 30) / 10.0,
            bloomEnabled: p.bloomEnabled ?? true,
            bloomIntensity: (p.bloomIntensityTimes10 ?? 10) / 10.0,
            monitorMode: p.monitorMode ?? "single",
            monitorName: p.monitorName ?? "DP-1"
        };
        placedKey = "";
    }

    onPluginDataChanged: rebuildCfg()
    onShowLyricsChanged: {
        if (!showLyrics)
            clearSlots();
    }

    Component.onCompleted: {
        rebuildCfg();
        ensureSongsDir();
        if (root.ctl.state === "ready")
            refreshTrack();
    }

    property string songsDir: ""
    property var styleCache: ({})

    function _stateDir() {
        if (!pluginService || !pluginService.getPluginStatePath)
            return "";
        var f = String(pluginService.getPluginStatePath("dramaticLyrics") || "");
        if (!f)
            return "";
        var i = f.lastIndexOf("/");
        return i < 0 ? "" : f.slice(0, i);
    }

    function _readFileSync(absPath) {
        var escaped = absPath.replace(/\\/g, "\\\\").replace(/"/g, '\\"');
        var qml = 'import QtQuick; import Quickshell.Io; FileView { path: "' + escaped + '"; blockLoading: true; blockWrites: true }';
        var fv = null;
        try {
            fv = Qt.createQmlObject(qml, root, "lyr_reader");
            var raw = fv.text();
            fv.destroy();
            return raw || "";
        } catch (e) {
            if (fv)
                fv.destroy();
            return "";
        }
    }

    function ensureSongsDir() {
        var d = _stateDir();
        if (!d)
            return false;
        songsDir = d + "/dramaticLyrics_songs";
        return true;
    }

    function styleForTrack(artist, title) {
        var key = LS.stableKey(artist, title);
        if (styleCache[key] !== undefined)
            return styleCache[key];
        var chars = {};
        if (songsDir) {
            var idxRaw = _readFileSync(songsDir + "/index.json");
            var fname = "";
            if (idxRaw.trim()) {
                try {
                    var idx = JSON.parse(idxRaw) || {};
                    if (idx[key])
                        fname = idx[key];
                } catch (e) {}
            }
            if (fname) {
                var body = _readFileSync(songsDir + "/" + String(fname).replace(/\//g, "_"));
                if (body.trim())
                    chars = LS.parseCharacters(body);
            }
        }
        styleCache[key] = chars;
        return chars;
    }

    function styleForVoice(chars, voice) {
        if (voice && chars[voice])
            return chars[voice];
        if (chars["default"])
            return chars["default"];
        return { font: null, size: null, color: voice ? LS.paletteFor(voice) : "#FFFAF2" };
    }

    property var groups: []
    property string placedKey: ""
    property var placementsByScreen: ({})
    property string trackArtist: ""
    property string trackTitle: ""

    function trackMeta() {
        var p = LyricsService.presenter.current;
        if (p)
            return { title: p.title || "", artist: p.artist || "" };
        var mp = MprisController.activePlayer;
        if (mp)
            return { title: MprisController.stableTitle || "", artist: MprisController.stableArtist || "" };
        return { title: "", artist: "" };
    }

    function refreshTrack() {
        var meta = trackMeta();
        trackArtist = meta.artist;
        trackTitle = meta.title;
        styleForTrack(meta.artist, meta.title);
        var src = [];
        if (ctl.synced && ctl.lines && ctl.lines.length > 0) {
            for (var i = 0; i < ctl.lines.length; i++) {
                var g = ctl.lines[i];
                var parts = g.parts || [];
                var lines = [];
                for (var j = 0; j < parts.length; j++) {
                    lines.push({
                        text: parts[j].x || "",
                        start: parts[j].t,
                        dur: Math.max(0, (parts[j].e || parts[j].t) - parts[j].t),
                        voices: _voicesOf(parts[j]),
                        words: parts[j].w || []
                    });
                }
                if (lines.length > 0)
                    src.push({ t: g.t, e: g.e, lines: lines });
            }

            src.sort(function(a, b) {
                if (a.t !== b.t)
                    return a.t - b.t;
                return a.e - b.e;
            });

            for (var si = 0; si < src.length; si++) {
                var grp = src[si];
                if (!isFinite(grp.e) || grp.e <= grp.t) {
                    if (si + 1 < src.length && isFinite(src[si + 1].t) && src[si + 1].t > grp.t) {
                        grp.e = src[si + 1].t;
                    } else {
                        var maxLen = 0;
                        for (var li = 0; li < grp.lines.length; li++) {
                            maxLen = Math.max(maxLen, grp.lines[li].text.length);
                        }
                        grp.e = grp.t + Math.max(3.0, Math.min(8.0, maxLen * 0.15));
                    }
                }
                for (var lj = 0; lj < grp.lines.length; lj++) {
                    if (grp.lines[lj].dur <= 0 && grp.e > grp.lines[lj].start) {
                        grp.lines[lj].dur = grp.e - grp.lines[lj].start;
                    }
                }
            }
        } else if (ctl.plainLines && ctl.plainLines.length > 0) {
            var pls = [];
            for (var k = 0; k < ctl.plainLines.length; k++) {
                if (String(ctl.plainLines[k]).trim() !== "")
                    pls.push({ text: ctl.plainLines[k], start: -1, dur: 0, voices: [""], words: [] });
            }
            if (pls.length > 0)
                src.push({ t: -1, e: Infinity, lines: pls });
        }
        groups = src;
        placedKey = "";
        clearSlots();
    }

    function _voicesOf(part) {
        var v = [];
        var primary = part.voiceName || part.voice || "";
        if (primary)
            v.push(primary);
        return v.length > 0 ? v : [""];
    }

    function onTrackKeyChanged() {
        if (!ctl.trackKey)
            return;
        groups = [];
        placementsByScreen = {};
        placedKey = "";
        styleCache = {};
        clearSlots();
        refreshTrack();
    }

    Connections {
        target: LyricsService.controller
        function onTrackKeyChanged() { root.onTrackKeyChanged(); }
        function onStateChanged() { if (root.ctl.state === "ready") root.refreshTrack(); }
    }

    TextMetrics { id: measurer }
    property var charMeasureCache: ({})

    function measureChar(ch, fontFam, fontSize) {
        var mKey = fontFam + "|" + fontSize + "|" + ch;
        if (charMeasureCache[mKey] !== undefined)
            return charMeasureCache[mKey];
        measurer.font.family = fontFam;
        measurer.font.pixelSize = fontSize;
        measurer.text = ch;
        var w = measurer.advanceWidth;
        charMeasureCache[mKey] = w;
        return w;
    }

    function placeGroupsForScreen(scrWidth, scrHeight, scrName) {
        var key = (ctl.trackKey || "") + "|" + scrWidth + "x" + scrHeight + "|" + JSON.stringify(cfg);
        if (placementsByScreen[scrName] && placementsByScreen[scrName].key === key)
            return placementsByScreen[scrName].data;

        var rng = DM.seededRng((ctl.trackKey || "empty") + "-" + scrName);
        var chars = styleForTrack(trackArtist, trackTitle);
        var surf = [scrWidth, scrHeight];
        var basePx = DM.resolveDimension(cfg.fontSize, surf, "min", 64);
        var margin = DM.resolveDimension(cfg.margin, surf, "min", 43);
        var out = {};

        for (var gi = 0; gi < groups.length; gi++) {
            var gl = groups[gi].lines;
            var placed = [];
            for (var li = 0; li < gl.length; li++) {
                var ln = gl[li];
                var styles = [];
                var voices = (ln.voices && ln.voices.length > 0) ? ln.voices : [""];
                for (var vi = 0; vi < voices.length; vi++) {
                    var sv = styleForVoice(chars, voices[vi]);
                    var fam = sv.font || cfg.font;
                    var rawSize = (sv.size !== undefined && sv.size !== null) ? sv.size : cfg.fontSize;
                    var px = Math.max(1, Math.round(DM.resolveDimension(rawSize, surf, "min", basePx, basePx)));
                    styles.push({
                        font: fam,
                        size: px,
                        color: sv.color || (voices[vi] ? LS.paletteFor(voices[vi]) : "#FFFAF2"),
                        strokeColor: DM.darkenHex(sv.color || (voices[vi] ? LS.paletteFor(voices[vi]) : "#FFFAF2"), -0.30)
                    });
                }
                var refPx = styles.length > 0 ? styles[0].size : basePx;
                var ls = DM.resolveDimension(cfg.letterSpacing, surf, "x", 0, refPx);

                var charList = [];
                var totalW = 0;
                for (var ci = 0; ci < ln.text.length; ci++) {
                    var st = styles[ci % styles.length];
                    var cw = measureChar(ln.text[ci], st.font, st.size);
                    charList.push({
                        ch: ln.text[ci],
                        w: cw,
                        x: totalW,
                        font: st.font,
                        size: st.size,
                        color: st.color,
                        strokeColor: st.strokeColor,
                        phi: DM.randomAngle(rng, cfg.letterRotationDeg)
                    });
                    totalW += cw + ls;
                }
                if (ln.text.length > 0)
                    totalW -= ls;

                for (var k = 0; k < charList.length; k++) {
                    charList[k].x -= totalW / 2;
                }

                var lineH = styles.length > 0 ? styles[0].size * 1.2 : 24;
                var angle = DM.randomAngle(rng, cfg.rotationDeg);
                var bb = DM.rotatedBbox(totalW, lineH, angle);
                var ctr = DM.pickCenter(rng, bb[0], bb[1], scrWidth, scrHeight, margin);

                placed.push({
                    cx: ctr[0],
                    cy: ctr[1],
                    angle: angle,
                    width: totalW,
                    height: lineH,
                    chars: charList,
                    ln: ln
                });
            }
            out[gi] = placed;
        }

        var newCache = Object.assign({}, placementsByScreen);
        newCache[scrName] = { key: key, data: out };
        placementsByScreen = newCache;
        return out;
    }

    property var slotData: [
        { groupIdx: -1, exitT: -1.0 },
        { groupIdx: -1, exitT: -1.0 },
        { groupIdx: -1, exitT: -1.0 },
        { groupIdx: -1, exitT: -1.0 },
        { groupIdx: -1, exitT: -1.0 },
        { groupIdx: -1, exitT: -1.0 }
    ]

    property int slot0GroupIdx: -1
    property real slot0ExitT: -1.0
    property int slot1GroupIdx: -1
    property real slot1ExitT: -1.0
    property int slot2GroupIdx: -1
    property real slot2ExitT: -1.0
    property int slot3GroupIdx: -1
    property real slot3ExitT: -1.0
    property int slot4GroupIdx: -1
    property real slot4ExitT: -1.0
    property int slot5GroupIdx: -1
    property real slot5ExitT: -1.0

    function syncSlotProperties() {
        if (slot0GroupIdx !== slotData[0].groupIdx)
            slot0GroupIdx = slotData[0].groupIdx;
        if (slot0ExitT !== slotData[0].exitT)
            slot0ExitT = slotData[0].exitT;

        if (slot1GroupIdx !== slotData[1].groupIdx)
            slot1GroupIdx = slotData[1].groupIdx;
        if (slot1ExitT !== slotData[1].exitT)
            slot1ExitT = slotData[1].exitT;

        if (slot2GroupIdx !== slotData[2].groupIdx)
            slot2GroupIdx = slotData[2].groupIdx;
        if (slot2ExitT !== slotData[2].exitT)
            slot2ExitT = slotData[2].exitT;

        if (slot3GroupIdx !== slotData[3].groupIdx)
            slot3GroupIdx = slotData[3].groupIdx;
        if (slot3ExitT !== slotData[3].exitT)
            slot3ExitT = slotData[3].exitT;

        if (slot4GroupIdx !== slotData[4].groupIdx)
            slot4GroupIdx = slotData[4].groupIdx;
        if (slot4ExitT !== slotData[4].exitT)
            slot4ExitT = slotData[4].exitT;

        if (slot5GroupIdx !== slotData[5].groupIdx)
            slot5GroupIdx = slotData[5].groupIdx;
        if (slot5ExitT !== slotData[5].exitT)
            slot5ExitT = slotData[5].exitT;
    }

    function clearSlots() {
        for (var i = 0; i < slotData.length; i++) {
            slotData[i].groupIdx = -1;
            slotData[i].exitT = -1.0;
        }
        syncSlotProperties();
    }

    function updateActiveFrames(t) {
        if (!groups || groups.length === 0) {
            clearSlots();
            return;
        }

        if (groups[0].t < 0) {
            slotData[0].groupIdx = 0;
            slotData[0].exitT = -1.0;
            for (var k = 1; k < slotData.length; k++) {
                slotData[k].groupIdx = -1;
                slotData[k].exitT = -1.0;
            }
            syncSlotProperties();
            return;
        }

        var wind = Math.max(0.1, cfg.windSec);
        var activeList = [];

        for (var i = 0; i < groups.length; i++) {
            var g = groups[i];
            if (g.t > t)
                break;
            var start = g.t;
            var end = g.e;
            if (t >= start && t < end + wind) {
                var exitT = (t < end) ? -1.0 : Math.min(0.999, (t - end) / wind);
                activeList.push({ index: i, exitT: exitT });
            }
        }

        var assignedActive = {};
        for (var s = 0; s < slotData.length; s++) {
            var gIdx = slotData[s].groupIdx;
            if (gIdx >= 0) {
                var matched = false;
                for (var a = 0; a < activeList.length; a++) {
                    if (activeList[a].index === gIdx) {
                        slotData[s].exitT = activeList[a].exitT;
                        assignedActive[gIdx] = true;
                        matched = true;
                        break;
                    }
                }
                if (!matched) {
                    slotData[s].groupIdx = -1;
                    slotData[s].exitT = -1.0;
                }
            }
        }

        for (var b = 0; b < activeList.length; b++) {
            var item = activeList[b];
            if (!assignedActive[item.index]) {
                for (var f = 0; f < slotData.length; f++) {
                    if (slotData[f].groupIdx === -1) {
                        slotData[f].groupIdx = item.index;
                        slotData[f].exitT = item.exitT;
                        assignedActive[item.index] = true;
                        break;
                    }
                }
            }
        }

        syncSlotProperties();
    }

    property real currentTrackTime: 0.0
    property real monotonicSec: 0.0

    FrameAnimation {
        running: root.showLyrics
        onTriggered: {
            root.currentTrackTime = root.ctl.currentTime();
            root.monotonicSec = Date.now() / 1000.0;
            root.updateActiveFrames(root.currentTrackTime);
        }
    }

    readonly property var activeScreens: {
        var all = Quickshell.screens || [];
        if (cfg.monitorMode === "primary") {
            return all.length > 0 ? [all[0]] : [];
        } else if (cfg.monitorMode === "single" && cfg.monitorName) {
            var match = all.filter(s => (s.name === cfg.monitorName || s.model === cfg.monitorName));
            return match.length > 0 ? match : (all.length > 0 ? [all[0]] : []);
        }
        return all;
    }

    Variants {
        model: root.showLyrics ? root.activeScreens : []

        PanelWindow {
            id: overlayWindow
            required property var modelData

            screen: modelData
            visible: root.showLyrics
            color: "transparent"

            WlrLayershell.namespace: "dms:dramatic-lyrics"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.exclusiveZone: -1
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            Region { id: emptyRegion }
            mask: emptyRegion

            readonly property string scrName: modelData.name || modelData.model || "screen"
            readonly property int scrW: overlayWindow.width
            readonly property int scrH: overlayWindow.height

            readonly property var screenPlacements: root.placeGroupsForScreen(scrW, scrH, scrName)

            readonly property real driftX: DM.resolveDimension(root.cfg.windDriftX, [scrW, scrH], "x", 0, 64)
            readonly property real driftY: DM.resolveDimension(root.cfg.windDriftY, [scrW, scrH], "y", 0, 64)
            readonly property real shimAmp: DM.resolveDimension(root.cfg.shimmerAmp, [scrW, scrH], "min", 0, 64)
            readonly property real shimPeriod: Math.max(0.1, root.cfg.shimmerPeriodSec)

            component GroupSlot: Item {
                id: slotRoot
                anchors.fill: parent

                property int groupIdx: -1
                property real exitT: -1.0

                visible: groupIdx >= 0 && (exitT < 0.0 || exitT < 1.0)

                readonly property var placedLines: (groupIdx >= 0 && overlayWindow.screenPlacements && overlayWindow.screenPlacements[groupIdx]) ? overlayWindow.screenPlacements[groupIdx] : []

                Repeater {
                    model: slotRoot.placedLines

                    DramaticLine {
                        required property var modelData
                        placedLine: modelData
                        currentTrackTime: root.currentTrackTime
                        monotonicSec: root.monotonicSec
                        exitT: slotRoot.exitT
                        revealSec: root.cfg.revealSec
                        shimAmp: overlayWindow.shimAmp
                        shimPeriod: overlayWindow.shimPeriod
                        driftX: overlayWindow.driftX
                        driftY: overlayWindow.driftY
                        windRotationDeg: root.cfg.windRotationDeg
                        bloomEnabled: root.cfg.bloomEnabled
                        bloomIntensity: root.cfg.bloomIntensity
                    }
                }
            }

            GroupSlot { groupIdx: root.slot0GroupIdx; exitT: root.slot0ExitT }
            GroupSlot { groupIdx: root.slot1GroupIdx; exitT: root.slot1ExitT }
            GroupSlot { groupIdx: root.slot2GroupIdx; exitT: root.slot2ExitT }
            GroupSlot { groupIdx: root.slot3GroupIdx; exitT: root.slot3ExitT }
            GroupSlot { groupIdx: root.slot4GroupIdx; exitT: root.slot4ExitT }
            GroupSlot { groupIdx: root.slot5GroupIdx; exitT: root.slot5ExitT }

            Text {
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                anchors.margins: 16
                text: root.ctl.attributionText || root.ctl.attributionName || ""
                color: "#99ffffff"
                font.pixelSize: 12
                visible: text !== ""
            }
        }
    }

    IpcHandler {
        target: "dramatic-lyrics"

        function getLyrics(): string {
            if (!root.ctl)
                return "";
            var lines = root.ctl.lines || [];
            if (lines.length > 0) {
                var out = [];
                for (var i = 0; i < lines.length; i++) {
                    var g = lines[i];
                    var parts = g.parts || [];
                    for (var j = 0; j < parts.length; j++) {
                        var p = parts[j];
                        var start = Number(p.t || g.t || 0).toFixed(2);
                        var end = Number(p.e || g.e || 0).toFixed(2);
                        var vname = p.voiceName || p.voice || "";
                        var voice = vname ? "[" + vname + "] " : "";
                        out.push("[" + start + " -> " + end + "] " + voice + (p.x || ""));
                    }
                }
                return out.join("\n");
            }
            var plain = root.ctl.plainLines || [];
            if (plain.length > 0)
                return plain.join("\n");
            return "";
        }

        function printLyrics(): string {
            var lyr = getLyrics();
            if (lyr)
                return lyr;
            return "No lyrics currently loaded (state: " + (root.ctl ? root.ctl.state : "unavailable") + ")";
        }

        function debugStatus(): string {
            var meta = trackMeta();
            var key = LS.stableKey(meta.artist, meta.title);
            var chars = styleForTrack(meta.artist, meta.title);
            var firstLineVoice = (root.groups.length > 0 && root.groups[0].lines.length > 0) ? JSON.stringify(root.groups[0].lines[0].voices) : "none";
            var rawFirstLine = (root.ctl && root.ctl.lines && root.ctl.lines.length > 0) ? JSON.stringify(root.ctl.lines[0]) : "none";
            return JSON.stringify({
                artist: meta.artist,
                title: meta.title,
                key: key,
                songsDir: root.songsDir,
                parsedCharacters: chars,
                firstGroupFirstLineVoices: firstLineVoice,
                ctlFirstLine: rawFirstLine,
                slots: root.slotData
            }, null, 2);
        }
    }
}
