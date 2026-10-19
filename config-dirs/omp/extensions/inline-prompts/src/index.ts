import * as os from "node:os";
import * as path from "node:path";
import type { ExtensionAPI, ExtensionContext } from "@oh-my-pi/pi-coding-agent";
import { createInlinePromptAutocompleteProvider } from "./autocomplete-provider";
import { registerAbbrCommand } from "./commands";
import { EXTENSION_NAME } from "./constants";
import { expandAllTokensInText } from "./expansion";
import { loadAllPrompts } from "./prompts-loader";
import type { InlinePromptRegistry } from "./types";

export default function (pi: ExtensionAPI): void {
	const globalAgentDir =
		process.env.PI_CODING_AGENT_DIR || path.join(os.homedir(), ".omp", "agent");

	let currentCwd = process.cwd();
	let registry: InlinePromptRegistry = {
		prompts: new Map(),
		aliases: new Map(),
		triggers: [":", "#"],
	};

	async function refreshPrompts(): Promise<void> {
		try {
			registry = await loadAllPrompts(globalAgentDir, currentCwd);
			pi.logger.debug("Inline prompts loaded", {
				count: registry.prompts.size,
				extension: EXTENSION_NAME,
			});
		} catch (error) {
			pi.logger.error("Failed to load inline prompts", {
				error: String(error),
				extension: EXTENSION_NAME,
			});
		}
	}

	void refreshPrompts();

	registerAbbrCommand(pi.registerCommand.bind(pi), {
		getRegistry: () => registry,
		reloadPrompts: refreshPrompts,
		getGlobalDir: () => globalAgentDir,
		getCwd: () => currentCwd,
	});

	function installAutocomplete(ctx: ExtensionContext): void {
		if (!ctx.hasUI) {
			return;
		}

		currentCwd = ctx.cwd;

		ctx.ui.addAutocompleteProvider((baseProvider) => {
			return createInlinePromptAutocompleteProvider(baseProvider, {
				getRegistry: () => registry,
				getCwd: () => currentCwd,
				setEditorText: (text: string) => {
					ctx.ui.setEditorText(text);
				},
				getEditorText: () => {
					return ctx.ui.getEditorText();
				},
			});
		});
	}

	pi.on("session_start", async (_event, ctx) => {
		currentCwd = ctx.cwd;
		await refreshPrompts();
		installAutocomplete(ctx);
	});

	pi.on("session_switch", async (_event, ctx) => {
		currentCwd = ctx.cwd;
		await refreshPrompts();
		installAutocomplete(ctx);
	});

	pi.on("input", async (event, ctx) => {
		if (event.source !== "interactive") {
			return;
		}

		const expandedText = expandAllTokensInText(event.text, registry, ctx.cwd);
		if (expandedText !== event.text) {
			return {
				text: expandedText,
			};
		}

		return undefined;
	});
}
