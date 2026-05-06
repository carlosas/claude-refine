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

```
/refine Add a customer search endpoint to the API
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
- The output file is `.claude-refine/.draft-requirement.md`, fully overwritten each run (no merge, no history). The Stop hook keys off this exact path; renaming it requires updating `hooks/hooks.json` in lockstep.
- Section order and headings are fixed (Problem Statement → Target User → Core Functionality → Out of Scope → Success Criteria → Codebase Context → Assumptions → Open Questions). Downstream tools like `/plan` consume this structure.
- Problem/Target User/Core Functionality/Out of Scope/Success Criteria sections must contain **no technology choices or implementation details**. Codebase Context is observations only, never prescriptions. The skill enforces this via a quality checklist that runs before save.
- Hook commands in `hooks/hooks.json` must stay POSIX-portable (macOS + Linux). The mtime read uses `stat -f %m` with a `stat -c %Y` fallback for exactly this reason.
- Questions are asked via the native `AskUserQuestion` tool. ≤4 markers → one round; 5–8 markers → two rounds (max). Never the manual lettered-option chat format.
- Once `/refine` finishes and `.claude-refine/.draft-requirement.md` is written (mtime within 60 seconds), a `Stop` hook injects a follow-up instruction that invokes the `claude-refine:-internal-post-draft` skill. No sentinel files, no stale-flag risk if the user interrupts mid-refinement.

Workflow:

- **Phase 0 — Codebase scan**: targeted `Glob`/`Grep` based on 3-5 extracted concepts; reads signatures only, never full implementations. Silently skipped (and the output section omitted) if no relevant code exists.
- **Phase 1 — Gap analysis**: scores 6 fixed taxonomy categories (Problem & Goal, Target User, Core Functionality, Scope Boundaries, Success Criteria, Edge Cases & Constraints) as Clear/Partial/Missing, then emits up to **8** `[NEEDS CLARIFICATION]` markers prioritized Scope > Target User > Success Criteria > Edge Cases. Low-impact gaps must become Assumptions, not questions.
- **Phase 2 — Guided Q&A**: questions are asked to the user. One or two rounds, highest-priority batch first.
- **Phase 3 — Spec file production**: a clean, unambiguous product spec ready to hand to `/plan` or any other implementation tool
