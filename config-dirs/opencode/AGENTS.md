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

4. **No Repeated Cross-File Literals**
  * Never hardcode the same operational parameter, URL, timeout, retry count, or domain-specific threshold across multiple distinct call sites or files.
  * If a literal value is shared by more than one component or module, extract it into a centralized configuration module, environment variable, or shared constant file.
  * Single-use literals that are tightly coupled to a single, isolated function or local scope may remain inline to avoid indirection bloat.

5. **Strict Path Discipline**
  * Never generate arbitrary, machine-dependent local paths (e.g., `~/`, `/home/user`, `file:///`, relative traversal outside the workspace).
  * All file operations must use paths that are strictly relative to the project root or strictly absolute system paths designed for containerized (Docker) environments.

6. **Prioritize Native & Ecosystem Solutions**
  * Before implementing custom utilities, boilerplate algorithms, or low-level logic, use `ctx7` or web search to verify whether the target framework or an established third-party library already provides a first-class solution.
  * **Framework built-ins take strict priority:** If the active framework provides an idiomatic, built-in solution for the task, you must use it over custom implementations.
  * **Library solutions must be recommended:** If an external library cleanly solves the task, explicitly recommend it and present it as the preferred path over rolling custom code, unless specifically instructed to avoid new dependencies.
