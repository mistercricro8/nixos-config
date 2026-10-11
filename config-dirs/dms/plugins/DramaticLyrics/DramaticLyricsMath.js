.pragma library

function easeOut(t) {
    t = Math.min(Math.max(t, 0.0), 1.0);
    return 1.0 - Math.pow(1.0 - t, 3);
}

function charAppearanceTime(start, duration, charIndex, nChars) {
    if (nChars <= 1)
        return start;
    return start + duration * charIndex / Math.max(nChars, 1);
}

function charProgress(t, start, duration, charIndex, nChars, revealDuration) {
    if (duration <= 0 || nChars <= 0)
        return t >= start ? 1.0 : 0.0;
    var appear = charAppearanceTime(start, duration, charIndex, nChars);
    if (t < appear)
        return 0.0;
    if (revealDuration <= 0)
        return 1.0;
    return Math.min(1.0, (t - appear) / revealDuration);
}

function charExitProgress(exitT, charIndex, nChars, fadeWindow) {
    if (fadeWindow === undefined)
        fadeWindow = 0.4;
    if (exitT <= 0.0)
        return 0.0;
    if (exitT >= 1.0)
        return 1.0;
    if (nChars <= 1)
        return easeOut(exitT);
    var w = Math.min(Math.max(fadeWindow, 0.01), 1.0);
    var startI = (charIndex / (nChars - 1)) * (1.0 - w);
    var endI = startI + w;
    if (exitT <= startI)
        return 0.0;
    if (exitT >= endI)
        return 1.0;
    return easeOut((exitT - startI) / w);
}

function rotatedBbox(width, height, angleDeg) {
    var r = angleDeg * Math.PI / 180.0;
    var c = Math.abs(Math.cos(r)), s = Math.abs(Math.sin(r));
    return [width * c + height * s, width * s + height * c];
}

function randomAngle(rng, maxDeg) {
    return (rng() * 2 - 1) * maxDeg;
}

function windTransform(t, driftDx, driftDy, rotationDeg) {
    if (rotationDeg === undefined)
        rotationDeg = 0.0;
    var e = easeOut(t);
    return {
        alpha: 1.0 - e,
        scale: 1.0 - 0.08 * e,
        dx: -driftDx * e,
        dy: -driftDy * e,
        dangle: rotationDeg * e
    };
}

function pickCenter(rng, rw, rh, W, H, margin) {
    var minCx = margin + rw / 2, maxCx = W - margin - rw / 2;
    var minCy = margin + rh / 2, maxCy = H - margin - rh / 2;
    if (maxCx <= minCx || maxCy <= minCy)
        return [W / 2, H / 2];
    return [rng() * (maxCx - minCx) + minCx, rng() * (maxCy - minCy) + minCy];
}

function shimmerOffset(now, charIndex, amplitude, period) {
    var phase = charIndex * 1.7 + (now / period) * 2 * Math.PI;
    return [
        amplitude * Math.sin(phase),
        amplitude * Math.sin(phase * 1.31 + 1.0)
    ];
}

function resolveDimension(val, surfaceSize, axis, def, baseFontSize) {
    if (axis === undefined)
        axis = "min";
    if (def === undefined)
        def = 0.0;
    var w = surfaceSize[0], h = surfaceSize[1], ref = 1080.0;
    if (axis === "x" || axis === "width")
        ref = w;
    else if (axis === "y" || axis === "height")
        ref = h;
    else if (axis === "max")
        ref = Math.max(w, h);
    else
        ref = Math.min(w, h);
    if (val === undefined || val === null)
        return def;
    if (typeof val === "number") {
        if (val > 0.0 && val <= 1.0 && !Number.isInteger(val))
            return val * ref;
        return val;
    }
    if (typeof val === "string") {
        var s = val.trim();
        if (!s)
            return def;
        var low = s.toLowerCase();
        if (low.endsWith("em")) {
            var em = parseFloat(s.slice(0, -2));
            if (isNaN(em))
                return def;
            var fontPx = 64.0;
            if (typeof baseFontSize === "number")
                fontPx = baseFontSize;
            else if (typeof baseFontSize === "string")
                fontPx = resolveDimension(baseFontSize, surfaceSize, "min", 64.0);
            return em * fontPx;
        }
        if (s.endsWith("%")) {
            var pct = parseFloat(s.slice(0, -1));
            return isNaN(pct) ? def : (pct / 100.0) * ref;
        }
        if (low.endsWith("px")) {
            var px = parseFloat(s.slice(0, -2));
            return isNaN(px) ? def : px;
        }
        var p = parseFloat(s);
        if (isNaN(p))
            return def;
        if (p > 0.0 && p <= 1.0 && s.indexOf(".") !== -1)
            return p * ref;
        return p;
    }
    return def;
}

function xmur3(str) {
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

function mulberry32(seed) {
    var a = seed >>> 0;
    return function () {
        a |= 0;
        a = (a + 0x6D2B79F5) | 0;
        var t = Math.imul(a ^ (a >>> 15), 1 | a);
        t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
        return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
    };
}

function seededRng(str) {
    return mulberry32(xmur3(String(str))());
}

function hashString(str) {
    return xmur3(String(str))();
}

function darkenHex(hex, deltaL) {
    var c = String(hex).replace("#", "");
    if (c.length === 3)
        c = c[0] + c[0] + c[1] + c[1] + c[2] + c[2];
    var r = parseInt(c.slice(0, 2), 16) / 255;
    var g = parseInt(c.slice(2, 4), 16) / 255;
    var b = parseInt(c.slice(4, 6), 16) / 255;
    if (isNaN(r) || isNaN(g) || isNaN(b))
        return "#000000";
    var mx = Math.max(r, g, b), mn = Math.min(r, g, b);
    var h = 0, s = 0, l = (mx + mn) / 2;
    if (mx !== mn) {
        var d = mx - mn;
        s = l > 0.5 ? d / (2 - mx - mn) : d / (mx + mn);
        if (mx === r)
            h = (g - b) / d + (g < b ? 6 : 0);
        else if (mx === g)
            h = (b - r) / d + 2;
        else
            h = (r - g) / d + 4;
        h /= 6;
    }
    l = Math.min(Math.max(l + deltaL, 0), 1);
    var rr, gg, bb;
    if (s === 0) {
        rr = gg = bb = l;
    } else {
        var q = l < 0.5 ? l * (1 + s) : l + s - l * s;
        var p2 = 2 * l - q;
        var tc = [h + 1 / 3, h, h - 1 / 3].map(function (t) {
            if (t < 0)
                t += 1;
            if (t > 1)
                t -= 1;
            if (t < 1 / 6)
                return p2 + (q - p2) * 6 * t;
            if (t < 1 / 2)
                return q;
            if (t < 2 / 3)
                return p2 + (q - p2) * (2 / 3 - t) * 6;
            return p2;
        });
        rr = tc[0];
        gg = tc[1];
        bb = tc[2];
    }
    function to2(x) {
        var v = Math.round(Math.min(Math.max(x, 0), 1) * 255).toString(16);
        return v.length === 1 ? "0" + v : v;
    }
    return "#" + to2(rr) + to2(gg) + to2(bb);
}
