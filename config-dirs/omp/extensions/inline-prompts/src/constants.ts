export const EXTENSION_NAME = "omp-inline-prompts";
export const EXTENSION_VERSION = "0.1.0";

export const DEFAULT_PREFIXES: readonly string[] = [":", "#"] as const;

export const CURSOR_PLACEHOLDER = "$CURSOR";
export const ALT_CURSOR_PLACEHOLDER = "{{cursor}}";

export const ABBREVIATIONS_FILENAME = "abbreviations.json";
export const PROMPTS_DIR_NAME = "prompts";

export const COMMAND_NAME = "abbr";

export const PROMPT_ICON = "󰪣";
export const ABBR_ICON = "󱄽";

export const FRONTMATTER_REGEX = /^---\r?\n([\s\S]*?)\r?\n---\r?\n([\s\S]*)$/;

export const MAX_AUTOCOMPLETE_VISIBLE = 10;
export const MAX_DESCRIPTION_PREVIEW_LEN = 80;
