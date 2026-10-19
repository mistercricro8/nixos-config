import * as fs from "node:fs/promises";
import * as path from "node:path";
import {
	ABBREVIATIONS_FILENAME,
	DEFAULT_PREFIXES,
	FRONTMATTER_REGEX,
	MAX_DESCRIPTION_PREVIEW_LEN,
	PROMPTS_DIR_NAME,
} from "./constants";
import type { InlinePrompt, InlinePromptRegistry, PromptSourceType } from "./types";

interface ParsedFrontmatter {
	readonly description?: string;
	readonly keyword?: string;
	readonly aliases?: readonly string[];
	readonly triggers?: readonly string[];
}

function parseYamlFrontmatter(rawYaml: string): ParsedFrontmatter {
	const lines = rawYaml.split("\n");
	let description: string | undefined;
	let keyword: string | undefined;
	const aliases: string[] = [];
	const triggers: string[] = [];

	let currentArrayTarget: "aliases" | "triggers" | null = null;

	for (const line of lines) {
		const trimmed = line.trim();
		if (!trimmed || trimmed.startsWith("#")) {
			continue;
		}

		if (trimmed.startsWith("- ") && currentArrayTarget !== null) {
			const item = trimmed.slice(2).trim();
			if (item) {
				if (currentArrayTarget === "aliases") {
					aliases.push(item);
				} else if (currentArrayTarget === "triggers") {
					triggers.push(item);
				}
			}
			continue;
		}

		currentArrayTarget = null;

		const colonIndex = trimmed.indexOf(":");
		if (colonIndex === -1) {
			continue;
		}

		const key = trimmed.slice(0, colonIndex).trim().toLowerCase();
		const val = trimmed.slice(colonIndex + 1).trim();

		if (key === "description") {
			description = val.replace(/^["']|["']$/g, "");
		} else if (key === "keyword") {
			keyword = val.replace(/^["']|["']$/g, "").toLowerCase();
		} else if (key === "aliases") {
			if (val.startsWith("[") && val.endsWith("]")) {
				const items = val
					.slice(1, -1)
					.split(",")
					.map((item) => item.trim().replace(/^["']|["']$/g, ""))
					.filter(Boolean);
				aliases.push(...items);
			} else if (!val) {
				currentArrayTarget = "aliases";
			}
		} else if (key === "triggers") {
			if (val.startsWith("[") && val.endsWith("]")) {
				const items = val
					.slice(1, -1)
					.split(",")
					.map((item) => item.trim().replace(/^["']|["']$/g, ""))
					.filter(Boolean);
				triggers.push(...items);
			} else if (!val) {
				currentArrayTarget = "triggers";
			}
		}
	}

	return {
		description,
		keyword,
		aliases,
		triggers,
	};
}

function parsePromptMarkdown(
	rawContent: string,
	fallbackKeyword: string,
	source: PromptSourceType,
	filePath: string,
): InlinePrompt {
	const match = FRONTMATTER_REGEX.exec(rawContent);

	if (match) {
		const frontmatterRaw = match[1] ?? "";
		const body = (match[2] ?? "").trim();
		const frontmatter = parseYamlFrontmatter(frontmatterRaw);

		const keyword = frontmatter.keyword || fallbackKeyword;
		const description = frontmatter.description || body.slice(0, MAX_DESCRIPTION_PREVIEW_LEN).replace(/\n/g, " ");

		return {
			keyword,
			description,
			content: body,
			source,
			sourcePath: filePath,
			aliases: frontmatter.aliases ?? [],
			triggers: frontmatter.triggers ?? DEFAULT_PREFIXES,
		};
	}

	const trimmed = rawContent.trim();
	const firstLine = trimmed.split("\n")[0] ?? "";
	const description = firstLine.replace(/^#+\s*/, "").slice(0, MAX_DESCRIPTION_PREVIEW_LEN);

	return {
		keyword: fallbackKeyword,
		description: description || fallbackKeyword,
		content: trimmed,
		source,
		sourcePath: filePath,
		aliases: [],
		triggers: DEFAULT_PREFIXES,
	};
}

async function safeReadDir(dirPath: string): Promise<readonly string[]> {
	try {
		const entries = await fs.readdir(dirPath, { withFileTypes: true });
		return entries
			.filter((entry) => (entry.isFile() || entry.isSymbolicLink()) && entry.name.endsWith(".md"))
			.map((entry) => entry.name);
	} catch (error) {
		const err = error as NodeJS.ErrnoException;
		if (err.code === "ENOENT") {
			return [];
		}
		throw error;
	}
}

async function loadPromptsFromDir(
	dirPath: string,
	source: PromptSourceType,
): Promise<readonly InlinePrompt[]> {
	const filenames = await safeReadDir(dirPath);
	const prompts: InlinePrompt[] = [];

	for (const filename of filenames) {
		const filePath = path.join(dirPath, filename);
		const rawContent = await fs.readFile(filePath, "utf-8");
		const fallbackKeyword = path.basename(filename, ".md").toLowerCase();
		prompts.push(parsePromptMarkdown(rawContent, fallbackKeyword, source, filePath));
	}

	return prompts;
}

interface AbbreviationJsonEntry {
	readonly content: string;
	readonly description?: string;
	readonly aliases?: readonly string[];
	readonly triggers?: readonly string[];
}

type AbbreviationJsonFormat = Record<string, string | AbbreviationJsonEntry>;

async function loadAbbreviationsFromFile(
	filePath: string,
	source: PromptSourceType,
): Promise<readonly InlinePrompt[]> {
	try {
		const content = await fs.readFile(filePath, "utf-8");
		const data = JSON.parse(content) as AbbreviationJsonFormat;
		const prompts: InlinePrompt[] = [];

		for (const [key, val] of Object.entries(data)) {
			const keyword = key.toLowerCase();
			if (typeof val === "string") {
				prompts.push({
					keyword,
					description: val.slice(0, MAX_DESCRIPTION_PREVIEW_LEN).replace(/\n/g, " "),
					content: val,
					source,
					sourcePath: filePath,
					aliases: [],
					triggers: DEFAULT_PREFIXES,
				});
			} else if (val && typeof val === "object" && typeof val.content === "string") {
				prompts.push({
					keyword,
					description: val.description || val.content.slice(0, MAX_DESCRIPTION_PREVIEW_LEN).replace(/\n/g, " "),
					content: val.content,
					source,
					sourcePath: filePath,
					aliases: val.aliases ?? [],
					triggers: val.triggers ?? DEFAULT_PREFIXES,
				});
			}
		}

		return prompts;
	} catch (error) {
		const err = error as NodeJS.ErrnoException;
		if (err.code === "ENOENT") {
			return [];
		}
		throw error;
	}
}

export async function loadAllPrompts(
	globalAgentDir: string,
	projectCwd: string,
): Promise<InlinePromptRegistry> {
	const promptsMap = new Map<string, InlinePrompt>();
	const aliasesMap = new Map<string, string>();

	const globalPromptsDir = path.join(globalAgentDir, PROMPTS_DIR_NAME);
	const globalPrompts = await loadPromptsFromDir(globalPromptsDir, "global-prompt");
	for (const prompt of globalPrompts) {
		promptsMap.set(prompt.keyword, prompt);
	}

	const globalAbbrPath = path.join(globalAgentDir, ABBREVIATIONS_FILENAME);
	const globalAbbrs = await loadAbbreviationsFromFile(globalAbbrPath, "abbreviations-file");
	for (const prompt of globalAbbrs) {
		promptsMap.set(prompt.keyword, prompt);
	}

	const projectPromptsDir = path.join(projectCwd, ".omp", PROMPTS_DIR_NAME);
	const projectPrompts = await loadPromptsFromDir(projectPromptsDir, "project-prompt");
	for (const prompt of projectPrompts) {
		promptsMap.set(prompt.keyword, prompt);
	}

	const projectAbbrPath = path.join(projectCwd, ".omp", ABBREVIATIONS_FILENAME);
	const projectAbbrs = await loadAbbreviationsFromFile(projectAbbrPath, "abbreviations-file");
	for (const prompt of projectAbbrs) {
		promptsMap.set(prompt.keyword, prompt);
	}

	for (const [keyword, prompt] of promptsMap.entries()) {
		for (const alias of prompt.aliases) {
			aliasesMap.set(alias.toLowerCase(), keyword);
		}
	}

	return {
		prompts: promptsMap,
		aliases: aliasesMap,
		triggers: DEFAULT_PREFIXES,
	};
}

export async function saveAbbreviation(
	filePath: string,
	keyword: string,
	content: string,
	description?: string,
): Promise<void> {
	let existingData: AbbreviationJsonFormat = {};

	try {
		const raw = await fs.readFile(filePath, "utf-8");
		existingData = JSON.parse(raw) as AbbreviationJsonFormat;
	} catch (error) {
		const err = error as NodeJS.ErrnoException;
		if (err.code !== "ENOENT") {
			throw error;
		}
		await fs.mkdir(path.dirname(filePath), { recursive: true });
	}

	const normalizedKey = keyword.toLowerCase();
	if (description) {
		existingData[normalizedKey] = {
			content,
			description,
		};
	} else {
		existingData[normalizedKey] = content;
	}

	await fs.writeFile(filePath, JSON.stringify(existingData, null, 2), "utf-8");
}

export async function deleteAbbreviationFromFile(
	filePath: string,
	keyword: string,
): Promise<boolean> {
	try {
		const raw = await fs.readFile(filePath, "utf-8");
		const existingData = JSON.parse(raw) as AbbreviationJsonFormat;
		const normalizedKey = keyword.toLowerCase();

		if (Object.prototype.hasOwnProperty.call(existingData, normalizedKey)) {
			delete existingData[normalizedKey];
			await fs.writeFile(filePath, JSON.stringify(existingData, null, 2), "utf-8");
			return true;
		}

		return false;
	} catch (error) {
		const err = error as NodeJS.ErrnoException;
		if (err.code === "ENOENT") {
			return false;
		}
		throw error;
	}
}
