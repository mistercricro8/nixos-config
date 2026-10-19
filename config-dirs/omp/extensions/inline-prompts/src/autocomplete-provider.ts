import type { AutocompleteItem, AutocompleteProvider } from "@oh-my-pi/pi-tui";
import { PROMPT_ICON } from "./constants";
import { calculateReplacementLines, expandVariables } from "./expansion";
import type { InlinePrompt, InlinePromptRegistry } from "./types";

export interface ProviderContext {
	getRegistry(): InlinePromptRegistry;
	getCwd(): string;
	setEditorText?(text: string): void;
	getEditorText?(): string;
}

export function createInlinePromptAutocompleteProvider(
	baseProvider: AutocompleteProvider,
	ctx: ProviderContext,
): AutocompleteProvider {
	function getMatchingPrompts(
		query: string,
		registry: InlinePromptRegistry,
	): readonly InlinePrompt[] {
		const lowerQuery = query.toLowerCase();
		const results: { prompt: InlinePrompt; score: number }[] = [];

		for (const prompt of registry.prompts.values()) {
			const kw = prompt.keyword.toLowerCase();
			if (kw === lowerQuery) {
				results.push({ prompt, score: 100 });
				continue;
			}
			if (prompt.aliases.some((a) => a.toLowerCase() === lowerQuery)) {
				results.push({ prompt, score: 95 });
				continue;
			}
			if (kw.startsWith(lowerQuery)) {
				results.push({ prompt, score: 80 - (kw.length - lowerQuery.length) });
				continue;
			}
			if (prompt.aliases.some((a) => a.toLowerCase().startsWith(lowerQuery))) {
				results.push({ prompt, score: 70 });
				continue;
			}
			if (kw.includes(lowerQuery)) {
				results.push({ prompt, score: 50 });
				continue;
			}
			if (prompt.description.toLowerCase().includes(lowerQuery)) {
				results.push({ prompt, score: 30 });
				continue;
			}
		}

		results.sort((a, b) => b.score - a.score);
		return results.map((r) => r.prompt);
	}

	function detectPromptTrigger(
		textBeforeCursor: string,
		registry: InlinePromptRegistry,
	): { prefix: string; query: string; fullPrefix: string } | null {
		for (const trigger of registry.triggers) {
			const escaped = trigger.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
			const regex = new RegExp(`(?:^|[\\s([{>])(${escaped}([a-zA-Z0-9_+-]*))$`);
			const match = regex.exec(textBeforeCursor);

			if (match && match[1]) {
				const fullPrefix = match[1];
				const query = match[2] ?? "";
				return { prefix: trigger, query, fullPrefix };
			}
		}

		return null;
	}

	return {
		async getSuggestions(lines, cursorLine, cursorCol, signal) {
			if (signal?.aborted) {
				return null;
			}

			const registry = ctx.getRegistry();
			const currentLine = lines[cursorLine] ?? "";
			const textBeforeCursor = currentLine.slice(0, cursorCol);

			const triggerInfo = detectPromptTrigger(textBeforeCursor, registry);
			if (triggerInfo) {
				const { prefix, query, fullPrefix } = triggerInfo;
				const matchedPrompts = getMatchingPrompts(query, registry);

				if (matchedPrompts.length > 0) {
					const items: AutocompleteItem[] = matchedPrompts.map((p) => {
						const hintText = p.content.slice(0, 40).replace(/\n/g, " ");
						return {
							value: p.keyword,
							label: `${prefix}${p.keyword}`,
							description: p.description,
							icon: PROMPT_ICON,
							hint: hintText.length > 0 ? `  ${hintText}` : undefined,
						};
					});

					return {
						items,
						prefix: fullPrefix,
					};
				}
			}

			return baseProvider.getSuggestions(lines, cursorLine, cursorCol, signal);
		},

		applyCompletion(lines, cursorLine, cursorCol, item, prefix) {
			const registry = ctx.getRegistry();
			const prompt =
				registry.prompts.get(item.value.toLowerCase()) ||
				registry.prompts.get(registry.aliases.get(item.value.toLowerCase()) || "");

			if (prompt) {
				const replacement = calculateReplacementLines(
					lines,
					cursorLine,
					cursorCol,
					prefix.length,
					prompt.content,
					ctx.getCwd(),
				);

				return {
					lines: replacement.lines,
					cursorLine: replacement.cursorLine,
					cursorCol: replacement.cursorCol,
				};
			}

			return baseProvider.applyCompletion(lines, cursorLine, cursorCol, item, prefix);
		},

		getInlineHint(lines, cursorLine, cursorCol) {
			const registry = ctx.getRegistry();
			const currentLine = lines[cursorLine] ?? "";
			const textBeforeCursor = currentLine.slice(0, cursorCol);

			const triggerInfo = detectPromptTrigger(textBeforeCursor, registry);
			if (triggerInfo && triggerInfo.query.length > 0) {
				const { query } = triggerInfo;
				const matched = getMatchingPrompts(query, registry);
				if (matched.length > 0 && matched[0]) {
					const kw = matched[0].keyword;
					if (kw.toLowerCase().startsWith(query.toLowerCase())) {
						return kw.slice(query.length);
					}
				}
			}

			if (typeof baseProvider.getInlineHint === "function") {
				return baseProvider.getInlineHint(lines, cursorLine, cursorCol);
			}

			return null;
		},

		trySyncInlineReplace(textBeforeCursor) {
			const registry = ctx.getRegistry();

			for (const prefix of registry.triggers) {
				const escaped = prefix.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
				const regex = new RegExp(`(?:^|[\\s([{>])(${escaped}([a-zA-Z0-9_+-]+)) $`);
				const match = regex.exec(textBeforeCursor);

				if (match && match[1] && match[2]) {
					const fullTokenWithSpace = `${match[1]} `;
					const kw = match[2].toLowerCase();
					let prompt = registry.prompts.get(kw);
					if (!prompt) {
						const canonical = registry.aliases.get(kw);
						if (canonical) {
							prompt = registry.prompts.get(canonical);
						}
					}

					if (prompt) {
						const expanded = expandVariables(prompt.content, ctx.getCwd())
							.replace(/\$CURSOR/g, "")
							.replace(/\{\{cursor\}\}/g, "");

						if (!expanded.includes("\n")) {
							return {
								replaceLen: fullTokenWithSpace.length,
								insert: `${expanded} `,
							};
						}

						if (typeof ctx.setEditorText === "function" && typeof ctx.getEditorText === "function") {
							const currentText = ctx.getEditorText();
							const tokenIndex = currentText.lastIndexOf(fullTokenWithSpace);
							if (tokenIndex !== -1) {
								const newText =
									currentText.slice(0, tokenIndex) +
									expanded +
									" " +
									currentText.slice(tokenIndex + fullTokenWithSpace.length);
								queueMicrotask(() => {
									ctx.setEditorText?.(newText);
								});
							}
						}
					}
				}
			}

			if (typeof baseProvider.trySyncInlineReplace === "function") {
				return baseProvider.trySyncInlineReplace(textBeforeCursor);
			}

			return null;
		},

		trySyncSlashCompletion(textBeforeCursor) {
			if (typeof baseProvider.trySyncSlashCompletion === "function") {
				return baseProvider.trySyncSlashCompletion(textBeforeCursor);
			}
			return null;
		},

		getForceFileSuggestions(lines, cursorLine, cursorCol, signal) {
			if (typeof baseProvider.getForceFileSuggestions === "function") {
				return baseProvider.getForceFileSuggestions(lines, cursorLine, cursorCol, signal);
			}
			return Promise.resolve(null);
		},

		shouldTriggerFileCompletion(lines, cursorLine, cursorCol) {
			if (typeof baseProvider.shouldTriggerFileCompletion === "function") {
				return baseProvider.shouldTriggerFileCompletion(lines, cursorLine, cursorCol);
			}
			return false;
		},
	};
}
