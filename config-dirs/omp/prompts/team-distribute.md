---
description: Distribute tasks between team members for small assignments.
keyword: team-distribute
aliases: [distribute, team]
triggers: [":"]
---

Check the project at XXXXXX and distribute its tasks among the team members (check previous assignments for the member list).

Shuffle the members randomly before assigning (use code with today's date as seed), so roles don't always fall on the same people.

Keep the following guidelines in mind:
- Self-contained "one-and-done" work: split the project into monolithic pieces (e.g., full report, entire slides, standalone tool/script) so each person can finish their part alone, without going back and forth or waiting on reviews. Avoid having multiple people edit the same file.
- The Descriptions to be given should be for an AI agent who will do the work, don't give exact step-by-step instructions, but rather a clear understanding of what to produce and how to use the inputs.
- Make sure to always include this constraint: Missing input, tool, data source, evidence, decision, etc. is missing? ALWAYS stop and ask for clarification before proceeding.

You may create any integration files, perform any initialization tasks, or set up any necessary scaffolding for the project, but avoid doing any of the actual work for the team members.

For each member, provide:
- Member Name
- Scope: Precise mapping to the guide or intermediate deliverables for other members to use as input.
- Inputs: Some existing relative paths to read first (code, screenshots, prior report). No guessing.
- Output: Files to produce, with relative paths and file types. If multiple files, use a numbered list.
- Description: Paragraph in plain language, what to produce reusing evidence from Inputs.
- Deadline: XXXXX (Deadline for the project is XXXXXX)
- Dependencies: Only teammate outputs needed first, or "Can start immediately".
