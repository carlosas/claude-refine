---
name: -internal-post-plan
description: "Runs automatically after a plan is approved that references a .claude-refine/ promoted spec. Triggered by the claude-refine plugin's PostToolUse hook on ExitPlanMode. Captures plan-time mind-changes back into the spec under 'Updates After Planning'."
---

# Post-Plan: Capture Plan-Time Spec Drift

This skill runs after the user approves a plan (via `ExitPlanMode`) that references a promoted `.claude-refine/<file>.md` spec. It captures product-level mind-changes the user made during planning back into that spec.

The hook injects two paths into the invocation reason: `PLAN_FILE` (the approved plan in `~/.claude/plans/`) and `SPEC_FILE` (the referenced promoted markdown). Use those exact paths.

## Steps

1. **Read inputs.** Read `PLAN_FILE` and `SPEC_FILE`. If either is missing or unreadable, stop and tell the user — do not invent content.

2. **Parse the spec's fixed sections.** The spec follows a fixed structure: Problem Statement, Target User, Core Functionality, Out of Scope, Success Criteria, Codebase Context (optional), Assumptions, Open Questions. Section order and headings are stable; rely on `## ` markers.

3. **Detect deltas.** Compare the plan against the spec and produce two lists:

   - **Contradictions to refined content** — items where the plan diverges from the spec's Problem Statement, Target User, Core Functionality, Out of Scope, or Success Criteria. Examples: spec says "Out of Scope: bulk export" but the plan implements bulk export; spec says target user is "anonymous visitors" but the plan assumes authenticated tenants.
   - **New decisions made during planning** — product-level decisions introduced during plan Q&A that were not in the spec. Examples: a new scope addition agreed during planning, a target-user shift, a new success criterion.

   Strict exclusions (these are NOT deltas):
   - Pure implementation choices: file paths, function names, libraries, internal data structures.
   - Resolutions to entries in the spec's Open Questions section.
   - Wording or phrasing differences that do not change product meaning.

4. **No-op case.** If both lists are empty, do **not** modify the spec. Tell the user in one sentence: ``Plan was consistent with `<SPEC_FILE>` — no updates.`` Then stop.

5. **Get the timestamp.** Run `date '+%Y-%m-%d %H:%M'` via the `Bash` tool. Use the exact stdout — do not reformat from memory.

6. **Append the section.** In `SPEC_FILE`:

   - If `## Updates After Planning` does not exist, append it at the end of the file, preceded by a blank line.
   - Under that heading, append a new subsection (do **not** modify or replace earlier subsections):

     ```markdown
     ### <YYYY-MM-DD HH:MM> — from plan <basename of PLAN_FILE>

     **Contradictions to refined content:**

     - **[Spec section]:** Originally [what the spec said]. Plan diverges to [what the plan does]. Reason: [if discernible from plan, else omit "Reason"].

     **New decisions made during planning:**

     - **[Topic]:** [Decision]. Reason: [rationale from plan, else omit "Reason"].
     ```

     Omit either bullet group entirely if its list is empty. Use exactly one blank line between the subsection heading, the bold group labels, the bullet lists, and any following subsections.

7. **Confirm to the user.** One to three sentences:
   - The spec path that was updated.
   - How many contradictions and new decisions were captured.
   - No suggested next step (the user is about to execute the plan).
