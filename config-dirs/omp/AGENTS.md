<!-- context7 -->
Use the `ctx7` CLI to fetch current documentation whenever the user asks about a library, framework, SDK, API, CLI tool, or cloud service — even well-known ones like React, Next.js, Prisma, Express, Tailwind, Django, or Spring Boot. This includes API syntax, configuration, version migration, library-specific debugging, setup instructions, and CLI tool usage. Use even when you think you know the answer — your training data may not reflect recent changes. Prefer this over web search for library docs.
Do not use for: refactoring, writing scripts from scratch, debugging business logic, code review, or general programming concepts.
Enable the find-docs skill for instructions on how to use `ctx7` to fetch documentation.

<!-- javascript tooling -->
NEVER use npm to install or run libraries, frameworks, SDKs, APIs, CLI tools, or cloud services. Whenever in a javascript context, test whether pnpm/bun/yarn are available and only use EITHER of those. If none are available, try using `nix run nixpkgs#package` (e.g. `nix run nixpkgs#pnpm` or `nix run nixpkgs#bun`) as an ad-hoc runner instead of aborting the task. Do not use npm for any reason.

<!-- python tooling -->
Standalone python, python3 or others will generally not be available. Explore whether uv is available and use it to run python scripts. If uv is not available, try using `nix run nixpkgs#package` (e.g. `nix run nixpkgs#uv`) as an ad-hoc runner instead of aborting the task.

<!-- quality -->
You must strictly adhere to the following architectural rules when generating or modifying code. Violating any of these principles is considered a fatal regression:

1. **Exhaustive Branching & Explicit State Handling**
   * Every branch in an `if/else` block, pattern match, or `switch` statement must explicitly manage application state or raise a dedicated error.
   * Never write silent `pass`/noop blocks, empty branches, or branches that merely log a warning without addressing control flow.

2. **Zero Fallbacks & Deterministic Control Flow**
   * Never implement fallback chains, speculative catch-alls, or silent defaults.
   * Every execution path must be explicit, deliberate, and predictable. If expected input or state is absent, fail fast and explicitly rather than defaulting to an assumed state.

3. **No Unrequested Legacy Support**
   * Implement only what is directly requested.
   * Do not introduce backwards-compatibility shims, polyfills, legacy wrappers, or deprecated API support unless explicitly instructed.

4. **Zero Magic Literals**
   * Never hardcode operational parameters, URLs, timeouts, retry counts, or domain-specific thresholds inline.
   * Extract all configuration-driven numbers and strings into centralized uppercase constants, config modules, or environment variables.

5. **Strict Path Discipline**
   * Never generate arbitrary, machine-dependent local paths (e.g., `~/`, `/home/user`, relative traversal outside the workspace).
   * All file operations must use paths that are strictly relative to the project root or strictly absolute system paths designed for containerized (Docker) environments.
