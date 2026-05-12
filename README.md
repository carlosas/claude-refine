# Claude-Refine

A Claude Code plugin that converts a rough feature idea into a refined product spec. Distribution via the Claude Code plugin marketplace.

## Installation

```bash
/plugin marketplace add carlosas/claude-refine
```
```bash
/plugin install claude-refine@claude-refine
```

## Usage

Fresh refinement:

```
/refine Add a customer search endpoint to the API
```

Update an existing spec with additional requirements (`@<slug>` resolves against `.claude-refine/<YYYYMMDDHHMM>-<slug>.md`; unique-prefix match works too):

```
/refine @customer-search also allow filtering by tier
```

## Output

`/refine` writes a refined feature specification inside a `.claude-refine/` folder in your project.

**Structure:**
- **Problem Statement**: the problem, not the solution
- **Target User**: concrete, not "users"
- **Core Functionality**: 1-3 essential things, plain language
- **Out of Scope**: explicit boundaries
- **Success Criteria**: measurable, technology-agnostic
- **Codebase Context**: relevant existing code found during scan (observations, not prescriptions)
- **Assumptions**: decisions made with rationale
- **Open Questions**: anything still unresolved

## What it does

`/refine` acts as a senior PM reviewing your feature request:

1. **Scans your codebase** for relevant existing code (entities, services, patterns, auth mechanisms) to ground the refinement in project reality
2. **Identifies gaps** in your feature description using a product taxonomy (problem, target user, scope, success criteria, edge cases)
3. **Asks targeted questions** to the user, only the ones that actually matter
4. **Writes a spec markdown file**, a clean, unambiguous product spec ready to hand to `/plan` or any other implementation tool

## Inspiration

- [Structured-Prompt-Driven Development (SPDD)](https://martinfowler.com/articles/structured-prompt-driven/)
- [github/spec-kit](https://github.com/github/spec-kit)
- [Fission-AI/OpenSpec](https://github.com/Fission-AI/OpenSpec/)

---

# Editing guidance

Constraints:

- Most changes are prompt-engineering on `skills/refine/SKILL.md`. Treat the description, phase rules, output template, and quality checklist as the four load-bearing parts — do not loosen the constraints (e.g., the 8-question cap, the `AskUserQuestion`-only Q&A rule, the "observations not prescriptions" rule for Codebase Context) without explicit reason.
- Keep the marketplace name and the plugin name (both `claude-refine` in `marketplace.json`) stable — renaming either breaks every existing user's `/plugin install claude-refine@claude-refine` and forces them to re-add the marketplace.
- In **fresh** mode the output file is `.claude-refine/.draft-requirement.md`, fully overwritten each run (no merge, no history). The Stop hook keys off this exact path; renaming it requires updating `hooks/hooks.json` in lockstep. In **retrofit** mode (`/refine @<slug> …`) the skill does **not** write `.draft-requirement.md` at all — it edits the matched dated spec in place by appending to a `## Refinement Updates` section, so the Stop hook silently does not fire. Phase 0 of the skill also deletes any stale `.draft-requirement.md` at retrofit entry to mitigate Stop-hook false-trigger from a previously interrupted run.
- Section order and headings of the base spec are fixed (Problem Statement → Target User → Core Functionality → Out of Scope → Success Criteria → Codebase Context → Assumptions → Open Questions). Downstream tools like `/plan` consume this structure. Retrofit and post-plan never mutate these base sections — they append `## Refinement Updates` and `## Updates After Planning` blocks below them. When both appended sections exist, `## Refinement Updates` always appears before `## Updates After Planning` (refinement is conceptually pre-plan).
- Problem/Target User/Core Functionality/Out of Scope/Success Criteria sections must contain **no technology choices or implementation details**. Codebase Context is observations only, never prescriptions. The skill enforces this via a quality checklist that runs before save.
- Hook commands in `hooks/hooks.json` must stay POSIX-portable (macOS + Linux). The mtime read uses `stat -f %m` with a `stat -c %Y` fallback for exactly this reason.
- Questions are asked via the native `AskUserQuestion` tool. ≤4 markers → one round; 5–8 markers → two rounds (max). Never the manual lettered-option chat format.
- Once `/refine` finishes and `.claude-refine/.draft-requirement.md` is written (mtime within 60 seconds), a `Stop` hook injects a follow-up instruction that invokes the `claude-refine:-internal-post-draft` skill. No sentinel files, no stale-flag risk if the user interrupts mid-refinement.
- After the user approves a plan (`ExitPlanMode`), a `PostToolUse` hook (`hooks/post-plan.sh`) checks the most-recently-modified `~/.claude/plans/*.md` for references to a `.claude-refine/<file>.md` spec. References to `.draft-requirement.md` are filtered out (transient artifact, never a valid target), and any reference whose file does not exist on disk in `$CLAUDE_PROJECT_DIR` is also dropped (example filenames inside the plan body, not real targets). With exactly one reference remaining after filtering, it injects an instruction that invokes the `claude-refine:-internal-post-plan` skill, which appends a dated subsection under `## Updates After Planning` in the spec — capturing contradictions to refined content and new product-level decisions made during planning. With zero remaining references the hook is silent; with multiple it asks Claude to surface a one-line note and skips, to avoid guessing the target spec.

Workflow:

- **Phase 0 — Mode detection**: if the first token of the `/refine` argument starts with `@`, enter retrofit mode. Slug after the `@` is resolved against `.claude-refine/<YYYYMMDDHHMM>-<slug>.md` (with basename fallback for renamed / hand-created files): exact match wins; else unique-prefix match. If unresolvable (empty slug, no match, or ambiguous prefix), `AskUserQuestion` lists existing specs sorted by most-recent timestamp plus a `Cancel — abort` option. Empty new-input after the slug triggers a follow-up `AskUserQuestion` for the addition. Without a leading `@` the skill is fresh mode and behaves as it always has — backwards-compatible.
- **Phase 1 — Codebase scan**: targeted `Glob`/`Grep` based on 3-5 extracted concepts; reads signatures only, never full implementations. Silently skipped (and the output section omitted) if no relevant code exists. In retrofit mode, only findings not already present in the existing `## Codebase Context` are carried forward.
- **Phase 2 — Gap analysis**: scores 6 fixed taxonomy categories (Problem & Goal, Target User, Core Functionality, Scope Boundaries, Success Criteria, Edge Cases & Constraints) as Clear/Partial/Missing, then emits up to **8** `[NEEDS CLARIFICATION]` markers prioritized Scope > Target User > Success Criteria > Edge Cases. Low-impact gaps must become Assumptions, not questions. In retrofit mode the input is `[existing Problem Statement + Target User + Core Functionality] + new input`, and a no-op guard exits silently with no file change when neither markers nor new content are produced.
- **Phase 3 — Guided Q&A**: questions are asked to the user. One or two rounds, highest-priority batch first.
- **Output — Spec file production**:
  - *Fresh*: clean, unambiguous product spec written to `.draft-requirement.md` and promoted by the Stop hook to a dated final file.
  - *Retrofit*: appends a timestamped subsection (`### YYYY-MM-DD HH:MM — from input: "<paraphrase>"`) to a `## Refinement Updates` section in the target dated spec, with `**Extends <Section>:**` / `**New codebase observations:**` / `**New assumptions:**` / `**New open questions:**` / `**Remaining clarifications:**` groups (empty groups omitted). If `## Updates After Planning` is already present on the target, a one-line reminder asks the user to re-run `/plan` and implement the new additions.
