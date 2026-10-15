.pragma library

function normalizeUrl(rawUrl) {
    if (!rawUrl || typeof rawUrl !== "string") {
        return "";
    }
    var trimmed = rawUrl.trim();
    if (trimmed.length === 0) {
        return "";
    }
    if (trimmed.startsWith("http://") || trimmed.startsWith("https://") || trimmed.startsWith("file://")) {
        return trimmed;
    }
    return "https://" + trimmed;
}

function computeUsageScore(link, nowEpochMs) {
    if (!link) {
        return 0;
    }
    var count = typeof link.usageCount === "number" ? link.usageCount : 0;
    var freqScore = Math.log2(1 + count) * 8;

    var recencyScore = 0;
    var lastUsed = typeof link.lastUsed === "number" ? link.lastUsed : 0;
    if (lastUsed > 0 && nowEpochMs > lastUsed) {
        var diffHours = (nowEpochMs - lastUsed) / (1000 * 60 * 60);
        if (diffHours < 24) {
            recencyScore = 15;
        } else if (diffHours < 72) {
            recencyScore = 10;
        } else if (diffHours < 168) {
            recencyScore = 6;
        } else if (diffHours < 720) {
            recencyScore = 2;
        } else {
            recencyScore = 0;
        }
    } else {
        recencyScore = 0;
    }

    return freqScore + recencyScore;
}

function scoreFuzzy(pattern, text) {
    if (!pattern || !text || typeof pattern !== "string" || typeof text !== "string") {
        return 0;
    }
    var p = pattern.toLowerCase();
    var t = text.toLowerCase();

    if (t === p) {
        return 100;
    }
    if (t.startsWith(p)) {
        return 80 + Math.min(10, Math.floor((p.length / t.length) * 10));
    }

    var wordIndex = t.indexOf(" " + p);
    if (wordIndex === -1) {
        wordIndex = t.indexOf("-" + p);
    }
    if (wordIndex === -1) {
        wordIndex = t.indexOf("_" + p);
    }
    if (wordIndex === -1) {
        wordIndex = t.indexOf("/" + p);
    }
    if (wordIndex !== -1) {
        return 70;
    }

    var subIdx = t.indexOf(p);
    if (subIdx !== -1) {
        return 50 + Math.max(0, 15 - subIdx);
    }

    var pLen = p.length;
    var tLen = t.length;
    var pIdx = 0;
    var tIdx = 0;
    var score = 0;
    var consecutive = 0;
    var prevMatchedIdx = -1;

    while (pIdx < pLen && tIdx < tLen) {
        var pChar = p.charAt(pIdx);
        var tChar = t.charAt(tIdx);

        if (pChar === tChar) {
            score += 5;
            if (prevMatchedIdx !== -1 && tIdx === prevMatchedIdx + 1) {
                consecutive++;
                score += consecutive * 4;
            } else {
                consecutive = 0;
            }

            if (tIdx === 0 || " -_./:#".indexOf(t.charAt(tIdx - 1)) !== -1) {
                score += 8;
            }

            prevMatchedIdx = tIdx;
            pIdx++;
        }
        tIdx++;
    }

    if (pIdx === pLen) {
        return Math.min(65, 20 + score);
    } else {
        return 0;
    }
}

function scoreLink(link, query, nowEpochMs) {
    if (!link || !query || typeof query !== "string") {
        return 0;
    }
    var cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.length === 0) {
        return 0;
    }

    var isTagFilter = cleanQuery.startsWith("#");
    var tagSearchTerm = isTagFilter ? cleanQuery.substring(1) : cleanQuery;

    var bestTagScore = 0;
    if (Array.isArray(link.tags)) {
        for (var i = 0; i < link.tags.length; i++) {
            var tagVal = String(link.tags[i]);
            var tagScore = scoreFuzzy(tagSearchTerm, tagVal);
            if (tagScore > bestTagScore) {
                bestTagScore = tagScore;
            }
        }
    }

    if (isTagFilter) {
        if (bestTagScore <= 0) {
            return 0;
        }
        return (bestTagScore * 10) + computeUsageScore(link, nowEpochMs);
    }

    var bestKeywordScore = 0;
    if (Array.isArray(link.keywords)) {
        for (var j = 0; j < link.keywords.length; j++) {
            var kwVal = String(link.keywords[j]);
            var kwScore = scoreFuzzy(cleanQuery, kwVal);
            if (kwScore > bestKeywordScore) {
                bestKeywordScore = kwScore;
            }
        }
    }

    var titleScore = scoreFuzzy(cleanQuery, link.title || "");
    var urlScore = scoreFuzzy(cleanQuery, link.url || "");

    var primaryMatchScore = Math.max(
        bestTagScore * 1.25,
        bestKeywordScore * 1.15,
        titleScore,
        urlScore * 0.75
    );

    if (primaryMatchScore <= 0) {
        return 0;
    }

    var usageBonus = computeUsageScore(link, nowEpochMs);
    return (primaryMatchScore * 10) + usageBonus;
}

function searchLinks(links, query, maxResults) {
    if (!Array.isArray(links)) {
        return [];
    }
    var limit = typeof maxResults === "number" && maxResults > 0 ? maxResults : 10;
    var now = Date.now();
    var cleanQuery = (query || "").trim();

    if (cleanQuery.length === 0) {
        var sortedRecommendations = links.slice().sort(function(a, b) {
            var scoreA = computeUsageScore(a, now);
            var scoreB = computeUsageScore(b, now);
            if (scoreB !== scoreA) {
                return scoreB - scoreA;
            }
            var countA = typeof a.usageCount === "number" ? a.usageCount : 0;
            var countB = typeof b.usageCount === "number" ? b.usageCount : 0;
            if (countB !== countA) {
                return countB - countA;
            }
            return (a.title || "").localeCompare(b.title || "");
        });
        return sortedRecommendations.slice(0, limit);
    }

    var scored = [];
    for (var i = 0; i < links.length; i++) {
        var link = links[i];
        var s = scoreLink(link, cleanQuery, now);
        if (s > 0) {
            scored.push({ link: link, score: s });
        }
    }

    scored.sort(function(a, b) {
        if (b.score !== a.score) {
            return b.score - a.score;
        }
        var countA = typeof a.link.usageCount === "number" ? a.link.usageCount : 0;
        var countB = typeof b.link.usageCount === "number" ? b.link.usageCount : 0;
        if (countB !== countA) {
            return countB - countA;
        }
        return (a.link.title || "").localeCompare(b.link.title || "");
    });

    var results = [];
    for (var j = 0; j < Math.min(scored.length, limit); j++) {
        results.push(scored[j].link);
    }
    return results;
}

function parseQuickAdd(query) {
    if (!query || typeof query !== "string") {
        return null;
    }
    var raw = query.trim();
    if (raw.length === 0) {
        return null;
    }

    var isAddCommand = false;
    var payload = "";

    if (raw.startsWith("add ") || raw.startsWith("add\t")) {
        isAddCommand = true;
        payload = raw.substring(4).trim();
    } else if (raw.startsWith("+ ") || raw.startsWith("+\t")) {
        isAddCommand = true;
        payload = raw.substring(2).trim();
    } else if (raw.startsWith("http://") || raw.startsWith("https://")) {
        isAddCommand = true;
        payload = raw;
    } else {
        return null;
    }

    if (payload.length === 0) {
        return null;
    }

    var tokens = payload.split(/\s+/);
    if (tokens.length === 0) {
        return null;
    }

    var url = normalizeUrl(tokens[0]);
    if (!url || url === "https://") {
        return null;
    }

    var tags = [];
    var titleParts = [];
    var keywords = [];

    for (var i = 1; i < tokens.length; i++) {
        var tok = tokens[i];
        if (tok.startsWith("#") && tok.length > 1) {
            tags.push(tok.substring(1).toLowerCase());
        } else if (tok.startsWith("@") && tok.length > 1) {
            keywords.push(tok.substring(1).toLowerCase());
        } else {
            titleParts.push(tok);
        }
    }

    var title = titleParts.join(" ").trim();
    if (title.length === 0) {
        try {
            var withoutProto = url.replace(/^(https?:\/\/)/, "");
            title = withoutProto.split("/")[0] || url;
        } catch (e) {
            title = url;
        }
    }

    return {
        url: url,
        title: title,
        tags: tags,
        keywords: keywords
    };
}

function formatRelativeTime(epochMs, nowEpochMs) {
    if (!epochMs || typeof epochMs !== "number" || epochMs <= 0) {
        return "Never opened";
    }
    var now = typeof nowEpochMs === "number" ? nowEpochMs : Date.now();
    var diffMs = now - epochMs;
    if (diffMs < 0) {
        return "Just now";
    }
    var diffSeconds = Math.floor(diffMs / 1000);
    if (diffSeconds < 60) {
        return "Just now";
    }
    var diffMinutes = Math.floor(diffSeconds / 60);
    if (diffMinutes < 60) {
        return diffMinutes + "m ago";
    }
    var diffHours = Math.floor(diffMinutes / 60);
    if (diffHours < 24) {
        return diffHours + "h ago";
    }
    var diffDays = Math.floor(diffHours / 24);
    if (diffDays < 30) {
        return diffDays + "d ago";
    }
    var diffMonths = Math.floor(diffDays / 30);
    if (diffMonths < 12) {
        return diffMonths + "mo ago";
    }
    var diffYears = Math.floor(diffDays / 365);
    return diffYears + "y ago";
}
