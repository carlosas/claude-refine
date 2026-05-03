# claude-refine

A Claude Code plugin that turns rough feature ideas into clear, implementation-ready product requirements before any code is written.

## What it does

`/refine` acts as a senior PM reviewing your feature request. Its skill:

1. **Scans your codebase** for relevant existing code (entities, services, patterns, auth mechanisms) to ground the refinement in project reality
2. **Identifies gaps** in your feature description using a product taxonomy (problem, target user, scope, success criteria, edge cases)
3. **Asks targeted questions**, only the ones that actually matter with lettered options for fast answers
4. **Writes `refined-requirement.md`**, a clean, unambiguous product spec ready to hand to `/plan` or any implementation tool

## Installation

```bash
/plugin install github:carlosas/claude-refine
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

```
/refine  →  refined-requirement.md
/plan    →  reads refined-requirement.md as input spec
```

## Plugin structure

```
refine-feature-plugin/
├── .claude-plugin/
│   └── plugin.json
├── skills/
│   └── refine/
│       └── SKILL.md
└── README.md
```
