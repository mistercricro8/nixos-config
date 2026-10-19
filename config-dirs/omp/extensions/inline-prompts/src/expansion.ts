import * as path from "node:path";
import { ALT_CURSOR_PLACEHOLDER, CURSOR_PLACEHOLDER } from "./constants";
import type { InlinePrompt, InlinePromptRegistry, MatchedToken, ReplacementResult } from "./types";

export function expandVariables(template: string, cwd: string): string {
	const now = new Date();
	const dateStr = now.toISOString().slice(0, 10);
	const timeStr = now.toTimeString().slice(0, 8);
	const cwdBasename = path.basename(cwd);

	return template
		.replace(/\$DATE\b/g, dateStr)
		.replace(/\$TIME\b/g, timeStr)
		.replace(/\$CWD\b/g, cwdBasename)
		.replace(/\$FULL_CWD\b/g, cwd);
}

export function findAbbreviationToken(
	textBeforeCursor: string,
	registry: InlinePromptRegistry,
): MatchedToken | null {
	for (const prefix of registry.triggers) {
		const escapedPrefix = prefix.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
		const regex = new RegExp(`(?:^|[\\s([{>])(${escapedPrefix}([a-zA-Z0-9_+-]+))$`);
		const match = regex.exec(textBeforeCursor);

		if (match && match[1] && match[2]) {
			const rawToken = match[1];
			const keywordCandidate = match[2].toLowerCase();

			let prompt = registry.prompts.get(keywordCandidate);
			if (!prompt) {
				const canonical = registry.aliases.get(keywordCandidate);
				if (canonical) {
					prompt = registry.prompts.get(canonical);
				}
			}

			if (prompt) {
				const startIndex = textBeforeCursor.length - rawToken.length;
				return {
					rawToken,
					prefix,
					keyword: keywordCandidate,
					prompt,
					startIndex,
					endIndex: textBeforeCursor.length,
				};
			}
		}
	}

	const bareWordRegex = /(?:^|\s)([a-zA-Z0-9_+-]+)$/;
	const bareMatch = bareWordRegex.exec(textBeforeCursor);

	if (bareMatch && bareMatch[1]) {
		const rawToken = bareMatch[1];
		const keywordCandidate = rawToken.toLowerCase();

		let prompt = registry.prompts.get(keywordCandidate);
		if (!prompt) {
			const canonical = registry.aliases.get(keywordCandidate);
			if (canonical) {
				prompt = registry.prompts.get(canonical);
			}
		}

		if (prompt) {
			const startIndex = textBeforeCursor.length - rawToken.length;
			return {
				rawToken,
				prefix: "",
				keyword: keywordCandidate,
				prompt,
				startIndex,
				endIndex: textBeforeCursor.length,
			};
		}
	}

	return null;
}

export function calculateReplacementLines(
	lines: readonly string[],
	cursorLine: number,
	cursorCol: number,
	prefixLen: number,
	rawExpansion: string,
	cwd: string,
): ReplacementResult {
	const currentLine = lines[cursorLine] ?? "";
	const beforePrefix = currentLine.slice(0, Math.max(0, cursorCol - prefixLen));
	const afterCursor = currentLine.slice(cursorCol);

	const expanded = expandVariables(rawExpansion, cwd);

	let targetCursorLine = -1;
	let targetCursorCol = -1;

	let cleanExpansion = expanded;
	const placeholderIndex = expanded.indexOf(CURSOR_PLACEHOLDER);
	const altPlaceholderIndex = expanded.indexOf(ALT_CURSOR_PLACEHOLDER);

	let activePlaceholder = "";
	let activePlaceholderIndex = -1;

	if (placeholderIndex !== -1) {
		activePlaceholder = CURSOR_PLACEHOLDER;
		activePlaceholderIndex = placeholderIndex;
	} else if (altPlaceholderIndex !== -1) {
		activePlaceholder = ALT_CURSOR_PLACEHOLDER;
		activePlaceholderIndex = altPlaceholderIndex;
	}

	if (activePlaceholderIndex !== -1) {
		const textBeforePlaceholder = expanded.slice(0, activePlaceholderIndex);
		const linesBefore = textBeforePlaceholder.split("\n");

		if (linesBefore.length === 1) {
			targetCursorLine = cursorLine;
			targetCursorCol = beforePrefix.length + linesBefore[0].length;
		} else {
			targetCursorLine = cursorLine + linesBefore.length - 1;
			targetCursorCol = linesBefore[linesBefore.length - 1].length;
		}

		cleanExpansion =
			expanded.slice(0, activePlaceholderIndex) +
			expanded.slice(activePlaceholderIndex + activePlaceholder.length);
	}

	const expansionLines = cleanExpansion.split("\n");
	const newLines: string[] = [];

	if (expansionLines.length === 1) {
		const mergedLine = beforePrefix + expansionLines[0] + afterCursor;
		for (let i = 0; i < lines.length; i++) {
			if (i === cursorLine) {
				newLines.push(mergedLine);
			} else {
				newLines.push(lines[i] ?? "");
			}
		}

		if (targetCursorLine === -1) {
			targetCursorLine = cursorLine;
			targetCursorCol = beforePrefix.length + expansionLines[0].length;
		}
	} else {
		for (let i = 0; i < cursorLine; i++) {
			newLines.push(lines[i] ?? "");
		}

		const firstLine = beforePrefix + (expansionLines[0] ?? "");
		newLines.push(firstLine);

		for (let i = 1; i < expansionLines.length - 1; i++) {
			newLines.push(expansionLines[i] ?? "");
		}

		const lastLine = (expansionLines[expansionLines.length - 1] ?? "") + afterCursor;
		newLines.push(lastLine);

		for (let i = cursorLine + 1; i < lines.length; i++) {
			newLines.push(lines[i] ?? "");
		}

		if (targetCursorLine === -1) {
			targetCursorLine = cursorLine + expansionLines.length - 1;
			targetCursorCol = (expansionLines[expansionLines.length - 1] ?? "").length;
		}
	}

	return {
		lines: newLines,
		cursorLine: targetCursorLine,
		cursorCol: targetCursorCol,
	};
}

export function expandAllTokensInText(
	inputText: string,
	registry: InlinePromptRegistry,
	cwd: string,
): string {
	let output = inputText;

	for (const prefix of registry.triggers) {
		const escapedPrefix = prefix.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
		const regex = new RegExp(`(?:^|[\\s([{>])(${escapedPrefix}([a-zA-Z0-9_+-]+))(?=[\\s)\\]}>]|$)`, "g");

		output = output.replace(regex, (match, fullToken, keyword) => {
			const kw = (keyword as string).toLowerCase();
			let prompt: InlinePrompt | undefined = registry.prompts.get(kw);
			if (!prompt) {
				const canonical = registry.aliases.get(kw);
				if (canonical) {
					prompt = registry.prompts.get(canonical);
				}
			}

			if (prompt) {
				const expanded = expandVariables(prompt.content, cwd)
					.replace(/\$CURSOR/g, "")
					.replace(/\{\{cursor\}\}/g, "");
				return match.replace(fullToken as string, expanded);
			}

			return match;
		});
	}

	return output;
}
