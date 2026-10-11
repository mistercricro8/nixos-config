.pragma library

var FALLBACK_PALETTE = ["#ff7eb6", "#7ee0ff", "#b9f27e", "#ffd166", "#c39bff", "#ff9f7e"];

function _xmur3(str) {
    var h = 1779033703 ^ str.length;
    for (var i = 0; i < str.length; i++) {
        h = Math.imul(h ^ str.charCodeAt(i), 3432918353);
        h = (h << 13) | (h >>> 19);
    }
    return function () {
        h = Math.imul(h ^ (h >>> 16), 2246822507);
        h = Math.imul(h ^ (h >>> 13), 3266489909);
        return (h ^= h >>> 16) >>> 0;
    };
}

function paletteFor(voice) {
    return FALLBACK_PALETTE[_xmur3(String(voice))() % FALLBACK_PALETTE.length];
}

function cleanStr(s) {
    return String(s || "").replace(/\[[^\]]*\]|\([^)]*\)|\{[^}]*\}/g, " ").split(/\s+/).join(" ").trim();
}


function stableKey(artist, title) {
    return cleanStr(artist).toLowerCase() + "\n" + cleanStr(title).toLowerCase();
}

function sanitizeStem(artist, title) {
    return String(artist + " - " + title).replace(/[^\w\-. ]+/gu, "_").trim().slice(0, 150);
}

function _stripQuotes(v) {
    var s = String(v).trim();
    if (s.length >= 2 && ((s[0] === '"' && s[s.length - 1] === '"') || (s[0] === "'" && s[s.length - 1] === "'")))
        return s.slice(1, -1);
    return s;
}

function _coerce(v) {
    var s = _stripQuotes(v);
    if (/^-?\d+(\.\d+)?$/.test(s))
        return parseFloat(s);
    return s;
}

function _parseFlow(inner) {
    var out = {};
    var re = /(\w+)\s*:\s*("[^"]*"|'[^']*'|[^,}]+)/g, m;
    while ((m = re.exec(inner)) !== null)
        out[m[1]] = _coerce(m[2]);
    return out;
}

function _parseBlock(fmLines, key) {
    var out = {};
    var keyIdx = -1, keyIndent = 0;
    for (var i = 0; i < fmLines.length; i++) {
        var lm = fmLines[i].match(/^(\s*)([^:\s][^:]*):\s*(.*)$/);
        if (!lm)
            continue;
        if (lm[2].trim() === key && keyIdx < 0) {
            keyIdx = i;
            keyIndent = lm[1].length;
            if (lm[3].trim().startsWith("{"))
                return _parseFlow(lm[3]);
            continue;
        }
        if (keyIdx >= 0 && fmLines[i].trim() !== "" && lm[1].length <= keyIndent)
            break;
        if (keyIdx >= 0) {
            var name = lm[2].trim(), rest = lm[3].trim();
            var indent = lm[1].length;
            if (rest.startsWith("{")) {
                out[name] = _parseFlow(rest);
            } else if (rest !== "") {
                out[name] = _coerce(rest);
            } else {
                var sub = {};
                var j = i + 1;
                for (; j < fmLines.length; j++) {
                    var sm = fmLines[j].match(/^(\s*)([^:\s][^:]*):\s*(.*)$/);
                    if (!sm || fmLines[j].trim() === "" || sm[1].length <= indent)
                        break;
                    sub[sm[2].trim()] = _coerce(sm[3]);
                }
                out[name] = sub;
            }
        }
    }
    return keyIdx < 0 ? null : out;
}

function _frontMatterLines(text) {
    var lines = String(text || "").split("\n");
    var s = 0;
    while (s < lines.length && lines[s].trim() === "")
        s++;
    if (s >= lines.length || lines[s].trim() !== "---")
        return null;
    var fm = [];
    for (var i = s + 1; i < lines.length; i++) {
        if (lines[i].trim() === "---")
            return fm;
        fm.push(lines[i]);
    }
    return fm;
}

function parseCharacters(text) {
    var fm = _frontMatterLines(text);
    if (!fm)
        return {};
    var chars = _parseBlock(fm, "characters");
    if (!chars)
        return {};
    var out = {};
    for (var name in chars) {
        var st = chars[name];
        if (st && typeof st === "object")
            out[name] = { font: st.font !== undefined ? st.font : null, size: st.size !== undefined ? st.size : null, color: st.color !== undefined ? st.color : null };
    }
    return out;
}

function parseSongMeta(text) {
    var fm = _frontMatterLines(text);
    if (!fm)
        return null;
    var sm = _parseBlock(fm, "song");
    if (!sm)
        return null;
    var tn = sm.trackName || sm.title || null;
    var an = sm.artistName || sm.artist || null;
    return (tn && an) ? { trackName: String(tn), artistName: String(an) } : null;
}
