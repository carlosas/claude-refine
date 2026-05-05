# claude-refine

A Claude Code plugin (`claude-refine`) that ships a single skill (`refine`) which converts a rough feature idea into a `refined-requirement.md` product spec. Distribution via the Claude Code plugin marketplace.

## Installation

```bash
/plugin marketplace add carlosas/claude-refine
/plugin install refine@claude-refine
```

## Usage

```
/refine Add a customer search endpoint to the agent API
```

Or just describe what you want to build and the skill will trigger automatically:

```
I want to add notifications when a customer is authenticated
```

## Output

`/refine` produces `refined-requirement.md` in your current directory. The file is rewritten on every run - no stale state from previous features.

**Structure:**
- **Problem Statement**: the problem, not the solution
- **Target User**: concrete, not "users"
- **Core Functionality**: 1-3 essential things, plain language
- **Out of Scope**: explicit boundaries
- **Success Criteria**: measurable, technology-agnostic
- **Codebase Context**: relevant existing code found during scan (observations, not prescriptions)
- **Assumptions**: decisions made with rationale
- **Open Questions**: anything still unresolved

## Workflow

The skill defines a strict three-phase workflow:

1. **Phase 0 — Codebase scan**: targeted `Glob`/`Grep` based on 3-5 extracted concepts; reads signatures only, never full implementations. Silently skipped (and the output section omitted) if no relevant code exists.
2. **Phase 1 — Gap analysis**: scores 6 fixed taxonomy categories (Problem & Goal, Target User, Core Functionality, Scope Boundaries, Success Criteria, Edge Cases & Constraints) as Clear/Partial/Missing, then emits up to 10 `[NEEDS CLARIFICATION]` markers prioritized Scope > Target User > Success Criteria > Edge Cases. Low-impact gaps must become Assumptions, not questions.
3. **Phase 2 — Guided Q&A**: lettered-option questions presented **all at once**, accepting compact replies like `1A 2C 3B`.

## What it does

`/refine` acts as a senior PM reviewing your feature request:

1. **Scans your codebase** for relevant existing code (entities, services, patterns, auth mechanisms) to ground the refinement in project reality
2. **Identifies gaps** in your feature description using a product taxonomy (problem, target user, scope, success criteria, edge cases)
3. **Asks targeted questions**, only the ones that actually matter with lettered options for fast answers
4. **Writes `refined-requirement.md`**, a clean, unambiguous product spec ready to hand to `/plan` or any implementation tool

## Plugin structure

```
claude-refine/
├── .claude-plugin/
│   ├── plugin.json
│   └── marketplace.json
├── skills/
│   └── refine/
│       └── SKILL.md
└── README.md
```

## Inspiration

- [Structured-Prompt-Driven Development (SPDD)](https://martinfowler.com/articles/structured-prompt-driven/)
- [github/spec-kit](https://github.com/github/spec-kit)
- [Fission-AI/OpenSpec](https://github.com/Fission-AI/OpenSpec/)

## Editing guidance

- Most changes are prompt-engineering on `SKILL.md`. Treat the description, phase rules, output template, and quality checklist as the four load-bearing parts — do not loosen the constraints (e.g., the 10-question cap, the "observations not prescriptions" rule for Codebase Context) without explicit reason.
- Keep the marketplace name (`claude-refine` in `marketplace.json`) and plugin name (`refine` in the marketplace's `plugins[]` entry) stable — renaming either breaks every existing user's `/plugin install refine@claude-refine` and forces them to re-add the marketplace.
- The output file is always `refined-requirement.md` in the cwd, fully overwritten each run (no merge, no history).
- Section order and headings are fixed (Problem Statement → Target User → Core Functionality → Out of Scope → Success Criteria → Codebase Context → Assumptions → Open Questions). Downstream tools like `/plan` consume this structure.
- Problem/Target User/Core Functionality/Out of Scope/Success Criteria sections must contain **no technology choices or implementation details**. Codebase Context is observations only, never prescriptions. The skill enforces this via a quality checklist that runs before save.
