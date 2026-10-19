export type PromptSourceType = "global-prompt" | "project-prompt" | "abbreviations-file" | "runtime-command";

export interface InlinePrompt {
	readonly keyword: string;
	readonly description: string;
	readonly content: string;
	readonly source: PromptSourceType;
	readonly sourcePath?: string;
	readonly aliases: readonly string[];
	readonly triggers: readonly string[];
}

export interface ReplacementResult {
	readonly lines: string[];
	readonly cursorLine: number;
	readonly cursorCol: number;
}

export interface MatchedToken {
	readonly rawToken: string;
	readonly prefix: string;
	readonly keyword: string;
	readonly prompt: InlinePrompt;
	readonly startIndex: number;
	readonly endIndex: number;
}

export interface InlinePromptRegistry {
	readonly prompts: Map<string, InlinePrompt>;
	readonly aliases: Map<string, string>;
	readonly triggers: readonly string[];
}
