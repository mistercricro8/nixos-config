import * as path from "node:path";
import type { ExtensionCommandContext } from "@oh-my-pi/pi-coding-agent";
import type { AutocompleteItem } from "@oh-my-pi/pi-tui";
import { ABBREVIATIONS_FILENAME, COMMAND_NAME } from "./constants";
import { deleteAbbreviationFromFile, saveAbbreviation } from "./prompts-loader";
import type { InlinePromptRegistry } from "./types";

export interface CommandsContext {
	getRegistry(): InlinePromptRegistry;
	reloadPrompts(): Promise<void>;
	getGlobalDir(): string;
	getCwd(): string;
}

export function registerAbbrCommand(
	registerCommand: (
		name: string,
		options: {
			description?: string;
			getArgumentCompletions?: (argPrefix: string) => AutocompleteItem[] | null;
			handler: (args: string, ctx: ExtensionCommandContext) => Promise<void>;
		},
	) => void,
	ctx: CommandsContext,
): void {
	registerCommand(COMMAND_NAME, {
		description: "Manage inline prompt abbreviations (/abbr list, /abbr add, /abbr delete, /abbr reload)",
		getArgumentCompletions(argPrefix: string) {
			const subcommands = ["list", "add", "delete", "reload"];
			const trimmed = argPrefix.trim();
			const matches = subcommands
				.filter((cmd) => cmd.startsWith(trimmed))
				.map((cmd) => ({
					value: cmd,
					label: cmd,
					description: `Subcommand: ${cmd}`,
				}));
			return matches;
		},
		async handler(args: string, cmdCtx: ExtensionCommandContext) {
			const parts = args.trim().split(/\s+/);
			const subcommand = parts[0]?.toLowerCase() || "list";

			if (subcommand === "list") {
				const registry = ctx.getRegistry();
				const promptsList = Array.from(registry.prompts.values());

				if (promptsList.length === 0) {
					cmdCtx.ui.notify("No inline prompt abbreviations registered.", "info");
					return;
				}

				const formattedLines: string[] = [
					`Registered Prompt Abbreviations (${promptsList.length}):`,
					"",
				];

				for (const p of promptsList) {
					const triggers = p.triggers.map((t) => `${t}${p.keyword}`).join(", ");
					formattedLines.push(`• ${triggers} — ${p.description}`);
					if (p.aliases.length > 0) {
						formattedLines.push(`  Aliases: ${p.aliases.join(", ")}`);
					}
					formattedLines.push(`  Source: ${p.source}`);
				}

				cmdCtx.ui.notify(formattedLines.join("\n"), "info");
				return;
			}

			if (subcommand === "reload") {
				await ctx.reloadPrompts();
				const count = ctx.getRegistry().prompts.size;
				cmdCtx.ui.notify(`Reloaded prompt templates. Total abbreviations: ${count}`, "info");
				return;
			}

			if (subcommand === "add") {
				const kw = parts[1]?.toLowerCase();
				const promptContent = parts.slice(2).join(" ");

				if (!kw || !promptContent) {
					cmdCtx.ui.notify("Usage: /abbr add <keyword> <prompt text>", "error");
					return;
				}

				const targetFile = path.join(ctx.getGlobalDir(), ABBREVIATIONS_FILENAME);
				await saveAbbreviation(targetFile, kw, promptContent);
				await ctx.reloadPrompts();

				cmdCtx.ui.notify(`Added abbreviation :${kw} successfully!`, "info");
				return;
			}

			if (subcommand === "delete" || subcommand === "del" || subcommand === "remove") {
				const kw = parts[1]?.toLowerCase();
				if (!kw) {
					cmdCtx.ui.notify("Usage: /abbr delete <keyword>", "error");
					return;
				}

				const targetFile = path.join(ctx.getGlobalDir(), ABBREVIATIONS_FILENAME);
				const deleted = await deleteAbbreviationFromFile(targetFile, kw);
				if (deleted) {
					await ctx.reloadPrompts();
					cmdCtx.ui.notify(`Removed abbreviation :${kw}`, "info");
				} else {
					cmdCtx.ui.notify(`Abbreviation "${kw}" not found in ${ABBREVIATIONS_FILENAME}`, "warning");
				}
				return;
			}

			cmdCtx.ui.notify(`Unknown subcommand: ${subcommand}. Use /abbr list, add, delete, or reload.`, "error");
		},
	});
}
