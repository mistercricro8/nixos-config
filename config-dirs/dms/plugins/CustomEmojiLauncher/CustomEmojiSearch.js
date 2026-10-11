.pragma library

const EXACT_MATCH = 10000;
const PREFIX_MATCH = 8000;
const WORD_PREFIX_MATCH = 6000;
const ACRONYM_MATCH = 5000;
const SUBSTRING_MATCH = 4000;
const SUBSEQUENCE_MATCH = 2500;
const TYPO_MATCH = 1000;
const EMPTY_QUERY_SCORE = 1000;
const HALF_LIFE_DAYS = 14;
const MS_PER_DAY = 86400000;

function tokenize(text) {
    if (!text) {
        return [];
    }
    return text.toLowerCase().trim().split(/[_\s\-]+/).filter(function (w) {
        return w.length > 0;
    });
}

function levenshteinDistance(s1, s2) {
    const len1 = s1.length;
    const len2 = s2.length;
    let prev = new Array(len2 + 1);
    let curr = new Array(len2 + 1);

    for (let j = 0; j <= len2; j++) {
        prev[j] = j;
    }

    for (let i = 1; i <= len1; i++) {
        curr[0] = i;
        for (let j = 1; j <= len2; j++) {
            const cost = s1[i - 1] === s2[j - 1] ? 0 : 1;
            curr[j] = Math.min(prev[j] + 1, curr[j - 1] + 1, prev[j - 1] + cost);
        }
        for (let j = 0; j <= len2; j++) {
            prev[j] = curr[j];
        }
    }
    return prev[len2];
}

function calculateMatchScore(name, query) {
    if (!query || query.trim().length === 0) {
        return EMPTY_QUERY_SCORE;
    }

    const nameLower = (name || "").toLowerCase().trim();
    const qLower = query.toLowerCase().trim();

    if (nameLower.length === 0 || qLower.length === 0) {
        return 0;
    }

    if (nameLower === qLower) {
        return EXACT_MATCH;
    }

    if (nameLower.startsWith(qLower)) {
        return PREFIX_MATCH + Math.round((qLower.length / nameLower.length) * 1000);
    }

    const tokens = tokenize(nameLower);
    for (let i = 0; i < tokens.length; i++) {
        if (tokens[i].startsWith(qLower)) {
            return WORD_PREFIX_MATCH + Math.round((qLower.length / tokens[i].length) * 500);
        }
    }

    if (tokens.length >= qLower.length && qLower.length > 1) {
        let acronym = "";
        for (let i = 0; i < tokens.length; i++) {
            acronym += tokens[i][0];
        }
        if (acronym.startsWith(qLower)) {
            return ACRONYM_MATCH;
        }
    }

    const subIdx = nameLower.indexOf(qLower);
    if (subIdx !== -1) {
        return SUBSTRING_MATCH - Math.min(1000, subIdx * 50) + Math.round((qLower.length / nameLower.length) * 500);
    }

    let qIdx = 0;
    let consecutive = 0;
    let boundaryBonus = 0;
    let firstMatchIdx = -1;
    let lastMatchIdx = -1;

    for (let i = 0; i < nameLower.length && qIdx < qLower.length; i++) {
        if (nameLower[i] === qLower[qIdx]) {
            if (firstMatchIdx === -1) {
                firstMatchIdx = i;
            }
            lastMatchIdx = i;
            if (i > 0 && nameLower[i - 1] === qLower[qIdx - 1]) {
                consecutive++;
            }
            if (i === 0 || nameLower[i - 1] === "_" || nameLower[i - 1] === "-" || nameLower[i - 1] === " ") {
                boundaryBonus += 200;
            }
            qIdx++;
        }
    }

    if (qIdx === qLower.length) {
        const span = lastMatchIdx - firstMatchIdx + 1;
        const compactness = Math.max(0, 500 - (span - qLower.length) * 50);
        return SUBSEQUENCE_MATCH + (consecutive * 150) + boundaryBonus + compactness;
    }

    if (qLower.length >= 3) {
        const maxDist = qLower.length <= 4 ? 1 : 2;
        const wholeDist = levenshteinDistance(nameLower, qLower);
        if (wholeDist <= maxDist) {
            return TYPO_MATCH - (wholeDist * 300);
        }

        for (let i = 0; i < tokens.length; i++) {
            const tokenDist = levenshteinDistance(tokens[i], qLower);
            if (tokenDist <= maxDist) {
                return TYPO_MATCH - (tokenDist * 300);
            }
        }
    }

    return 0;
}

function calculateUsageRate(usageEntry, nowTimestamp) {
    if (!usageEntry || typeof usageEntry.count !== "number" || usageEntry.count <= 0) {
        return 0;
    }

    const lastUsed = typeof usageEntry.lastUsed === "number" ? usageEntry.lastUsed : nowTimestamp;
    const ageMs = Math.max(0, nowTimestamp - lastUsed);
    const decay = Math.pow(0.5, ageMs / (HALF_LIFE_DAYS * MS_PER_DAY));
    return usageEntry.count * decay;
}

function scoreAndFilter(entries, query, usageData, nowTimestamp) {
    const isQueryEmpty = !query || query.trim().length === 0;
    const scored = [];

    for (let i = 0; i < entries.length; i++) {
        const entry = entries[i];
        const matchScore = calculateMatchScore(entry.name, query);

        if (matchScore === 0 && !isQueryEmpty) {
            continue;
        }

        const key = entry.id || entry.name || entry.url || "";
        const usageEntry = (usageData && key && usageData[key]) ? usageData[key] : null;
        const usageRate = calculateUsageRate(usageEntry, nowTimestamp);

        let finalScore = 0;
        if (isQueryEmpty) {
            finalScore = EMPTY_QUERY_SCORE + Math.min(2000, Math.round(usageRate * 50));
        } else {
            const usageBonus = Math.min(1500, Math.round(usageRate * 30));
            finalScore = matchScore + usageBonus;
        }

        scored.push({
            entry: entry,
            score: finalScore,
            usageRate: usageRate,
            usageCount: usageEntry ? (usageEntry.count || 0) : 0,
            originalIndex: i
        });
    }

    scored.sort(function (a, b) {
        if (a.score !== b.score) {
            return b.score - a.score;
        }
        return a.originalIndex - b.originalIndex;
    });

    return scored;
}
