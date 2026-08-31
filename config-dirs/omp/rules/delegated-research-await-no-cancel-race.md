---
description: "Await delegated task subagents; do not race with manual reads or cancel early"
condition: 'hub\W*cancel'
scope:
  - 'tool:bash'
---

After delegating research via `task` async subagents, you MUST await their results via `hub wait`/`hub jobs` and merge them.

Do NOT start parallel manual `read`/`grep`/`glob` over the same scope to race them, and NEVER `hub cancel` just because you returned faster — that discards their work.

Let delegated agents deliver. Only cancel on true hang/timeout, explicit user request, or proven stale task.

If this cancellation is due to an explicit user request, proven hang/timeout, or stale task, proceed with `hub cancel` and state the justification.
