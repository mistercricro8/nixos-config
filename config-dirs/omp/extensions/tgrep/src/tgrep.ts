import * as path from "node:path";
import type { ExtensionAPI, ExtensionContext } from "@oh-my-pi/pi-coding-agent";

const TGREP_BIN = "tgrep";
const INSTALL_HINT =
  "tgrep binary not found on PATH. Install with: brew install tgrep (macOS/Linux) or cargo install --path tgrep-cli --locked (from a checkout). See https://github.com/microsoft/tgrep. Then re-run.";
const ESCAPED_PATH_MESSAGE_PREFIX =
  "tgrep path escapes session cwd; pass a path beneath ";
const CANCELLED_MESSAGE = "tgrep invocation was cancelled";
const SEARCHING_UPDATE_TEXT = "Searching with tgrep...";
const INDEXING_UPDATE_TEXT = "Building tgrep index...";
const STATUS_UPDATE_TEXT = "Checking tgrep status...";
const NO_MATCH_TEXT = "No matches found";
const STDERR_SUFFIX_LABEL = "\n\n[tgrep stderr] ";
const STALE_INDEX_PATTERN =
  /warning:\s*no index|server unreachable|falling back to local index/i;
const MAX_CONTEXT_LINES = 20;

const TGREP_SYSTEM_PROMPT = `tgrep (trigram-indexed grep) is available via the tgrep_search / tgrep_index / tgrep_status tools.
Prefer tgrep_search over unindexed grep on large trees; run tgrep_index once per checkout and again after large refactors or moves.
The index respects .gitignore even outside git checkouts; pass includeIgnored=true to index everything, or index an ignored directory directly as its own root (path=<dir>) and scope searches to it.
Indexed search does not see edits made after the last index build: re-run tgrep_index, or pass noIndex=true to scan the live tree.
Prefer literal=true for symbols/strings; scope with glob/fileType before maxCount. Exit 1 means no matches, not failure.`;

interface SearchParams {
  pattern: string;
  path?: string;
  literal?: boolean;
  wholeWord?: boolean;
  ignoreCase?: boolean;
  fileType?: string;
  glob?: string;
  filesWithMatches?: boolean;
  count?: boolean;
  contextLines?: number;
  maxCount?: number;
  quiet?: boolean;
  outputFormat?: "text" | "json" | "vimgrep";
  noIndex?: boolean;
  indexPath?: string;
  noRequireGit?: boolean;
}

interface IndexParams {
  path?: string;
  indexPath?: string;
  exclude?: string[];
  includeIgnored?: boolean;
}

interface StatusParams {
  path?: string;
  indexPath?: string;
}

async function ensureTgrep(
  pi: ExtensionAPI,
  ctx: ExtensionContext,
  signal: AbortSignal | undefined,
): Promise<void> {
  let code: number;
  try {
    const result = await pi.exec(TGREP_BIN, ["--version"], {
      cwd: ctx.cwd,
      signal,
    });
    if (result.killed) {
      throw new Error(CANCELLED_MESSAGE);
    }
    code = result.code;
  } catch (error) {
    if (error instanceof Error && error.message === CANCELLED_MESSAGE) {
      throw error;
    }
    throw new Error(INSTALL_HINT);
  }
  if (code !== 0) {
    throw new Error(INSTALL_HINT);
  }
}

function resolveSearchRoot(cwd: string, rawPath: string | undefined): string {
  const resolved = path.resolve(cwd, rawPath || ".");
  if (resolved !== cwd && !resolved.startsWith(cwd + path.sep)) {
    throw new Error(ESCAPED_PATH_MESSAGE_PREFIX + cwd);
  }
  return resolved;
}

function withStderrSuffix(text: string, stderr: string): string {
  if (!stderr) {
    return text;
  }
  if (STALE_INDEX_PATTERN.test(stderr)) {
    return text + STDERR_SUFFIX_LABEL + stderr.trim();
  }
  return text;
}

function buildSearchArgs(params: SearchParams, root: string): string[] {
  const args: string[] = [];
  if (params.literal ?? false) {
    args.push("-F");
  }
  if (params.wholeWord ?? false) {
    args.push("-w");
  }
  if (params.ignoreCase ?? false) {
    args.push("-i");
  }
  if (params.fileType !== undefined) {
    args.push("-t", params.fileType);
  }
  if (params.glob !== undefined) {
    args.push("-g", params.glob);
  }
  if (params.filesWithMatches ?? false) {
    args.push("-l");
  }
  if (params.count ?? false) {
    args.push("-c");
  }
  if (params.contextLines !== undefined) {
    args.push("-C", String(params.contextLines));
  }
  if (params.maxCount !== undefined) {
    args.push("-m", String(params.maxCount));
  }
  if (params.quiet ?? false) {
    args.push("-q");
  }
  if (params.outputFormat === "json") {
    args.push("--json");
  } else if (params.outputFormat === "vimgrep") {
    args.push("--vimgrep");
  }
  if (params.noIndex ?? false) {
    args.push("--no-index");
  }
  if (params.indexPath !== undefined) {
    args.push("--index-path", params.indexPath);
  }
  if (params.noRequireGit ?? false) {
    args.push("--no-require-git");
  }
  args.push("--", params.pattern, root);
  return args;
}

function buildIndexArgs(params: IndexParams, root: string): string[] {
  const args: string[] = ["index", root];
  if (params.indexPath !== undefined) {
    args.push("--index-path", params.indexPath);
  }
  for (const dir of params.exclude ?? []) {
    args.push("--exclude", dir);
  }
  if (params.includeIgnored ?? false) {
    args.push("--no-ignore");
  } else {
    args.push("--no-require-git");
  }
  return args;
}

export default function (pi: ExtensionAPI) {
  const z = pi.zod;

  pi.registerTool({
    name: "tgrep_search",
    label: "tgrep Search",
    description:
      "Fast trigram-indexed regex search (ripgrep-compatible subset). Needs a current index: run tgrep_index once per checkout and after large changes; misses edits made after indexing (then re-index or pass noIndex). Prefer literal=true for symbols/strings; scope with fileType/glob before maxCount. Exit 1 means no matches, not failure.",
    loadMode: "discoverable",
    approval: "read",
    parameters: z.object({
      pattern: z.string().min(1).describe("Regex, or literal string when literal=true"),
      path: z.string().default(".").describe("File or directory beneath session cwd; defaults to repo root"),
      literal: z.boolean().default(false).describe("Pass -F: fixed-string search"),
      wholeWord: z.boolean().default(false).describe("Pass -w"),
      ignoreCase: z.boolean().default(false).describe("Pass -i"),
      fileType: z.string().optional().describe("Pass -t <type>, e.g. rust"),
      glob: z.string().optional().describe("Pass -g <glob>, e.g. src/**"),
      filesWithMatches: z.boolean().default(false).describe("Pass -l: file names only"),
      count: z.boolean().default(false).describe("Pass -c: count per file"),
      contextLines: z
        .number()
        .int()
        .min(0)
        .max(MAX_CONTEXT_LINES)
        .optional()
        .describe("Pass -C <n>: lines of context"),
      maxCount: z.number().int().min(1).optional().describe("Pass -m <n>: trim output"),
      quiet: z.boolean().default(false).describe("Pass -q: exit code only"),
      outputFormat: z
        .enum(["text", "json", "vimgrep"])
        .default("text")
        .describe("text=default, json=--json ripgrep JSON lines, vimgrep=--vimgrep file:line:col:text"),
      noIndex: z
        .boolean()
        .default(false)
        .describe("Pass --no-index: full scan reflecting latest edits; slow on large trees"),
      indexPath: z
        .string()
        .optional()
        .describe("Pass --index-path <dir>; must match the value used for index"),
      noRequireGit: z.boolean().default(false).describe("Pass --no-require-git on search"),
    }),
    async execute(toolCallId, params, signal, onUpdate, ctx) {
      void toolCallId;
      const search = params as SearchParams;
      await ensureTgrep(pi, ctx, signal);
      const root = resolveSearchRoot(ctx.cwd, search.path);
      const args = buildSearchArgs(search, root);
      onUpdate?.({ content: [{ type: "text", text: SEARCHING_UPDATE_TEXT }] });
      const result = await pi.exec(TGREP_BIN, args, { cwd: ctx.cwd, signal });
      if (result.killed) {
        throw new Error(CANCELLED_MESSAGE);
      }
      if (result.code === 0) {
        return {
          content: [
            { type: "text", text: withStderrSuffix(result.stdout, result.stderr) },
          ],
          details: { exitCode: 0, root, stderr: result.stderr },
        };
      }
      if (result.code === 1) {
        return {
          content: [
            { type: "text", text: withStderrSuffix(NO_MATCH_TEXT, result.stderr) },
          ],
          details: { exitCode: 1, root, stderr: result.stderr },
        };
      }
      throw new Error(
        result.stderr.trim() || `tgrep search failed (exit ${result.code})`,
      );
    },
  });

  pi.registerTool({
    name: "tgrep_index",
    label: "tgrep Index",
    description:
      "Build/rebuild the .tgrep trigram index for a root. Respects .gitignore even outside git checkouts; pass includeIgnored to index everything, or index an ignored directory as its own root and scope searches to it.",
    loadMode: "discoverable",
    approval: "write",
    parameters: z.object({
      path: z.string().default(".").describe("Directory to index beneath session cwd"),
      indexPath: z.string().optional().describe("Pass --index-path <dir>"),
      exclude: z.array(z.string()).optional().describe("Repeat --exclude <DIR>"),
      includeIgnored: z.boolean().default(false).describe("Pass --no-ignore: index gitignored files too; combine with exclude to carve back out"),
    }),
    async execute(toolCallId, params, signal, onUpdate, ctx) {
      void toolCallId;
      const index = params as IndexParams;
      await ensureTgrep(pi, ctx, signal);
      const root = resolveSearchRoot(ctx.cwd, index.path);
      const args = buildIndexArgs(index, root);
      onUpdate?.({ content: [{ type: "text", text: INDEXING_UPDATE_TEXT }] });
      const result = await pi.exec(TGREP_BIN, args, { cwd: ctx.cwd, signal });
      if (result.killed) {
        throw new Error(CANCELLED_MESSAGE);
      }
      if (result.code !== 0) {
        throw new Error(
          result.stderr.trim() || `tgrep index failed (exit ${result.code})`,
        );
      }
      return {
        content: [{ type: "text", text: result.stdout }],
        details: { exitCode: 0, root },
      };
    },
  });

  pi.registerTool({
    name: "tgrep_status",
    label: "tgrep Status",
    description:
      "Show tgrep index/server state for a root (reports Indexing: complete once the initial build is done; not a freshness proof).",
    loadMode: "discoverable",
    approval: "read",
    parameters: z.object({
      path: z.string().default(".").describe("Root to inspect beneath session cwd"),
      indexPath: z.string().optional().describe("Pass --index-path <dir>"),
    }),
    async execute(toolCallId, params, signal, onUpdate, ctx) {
      void toolCallId;
      const status = params as StatusParams;
      await ensureTgrep(pi, ctx, signal);
      const root = resolveSearchRoot(ctx.cwd, status.path);
      const args: string[] = ["status", root];
      if (status.indexPath !== undefined) {
        args.push("--index-path", status.indexPath);
      }
      onUpdate?.({ content: [{ type: "text", text: STATUS_UPDATE_TEXT }] });
      const result = await pi.exec(TGREP_BIN, args, { cwd: ctx.cwd, signal });
      if (result.killed) {
        throw new Error(CANCELLED_MESSAGE);
      }
      if (result.code !== 0) {
        throw new Error(
          result.stderr.trim() || `tgrep status failed (exit ${result.code})`,
        );
      }
      return {
        content: [{ type: "text", text: result.stdout }],
        details: { exitCode: 0, root },
      };
    },
  });

  pi.on?.("before_agent_start", (event) => ({
    systemPrompt: [...(event.systemPrompt ?? []), TGREP_SYSTEM_PROMPT],
  }));
}
