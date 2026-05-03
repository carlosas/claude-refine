---
name: refine
description: "Refine a feature request from a product perspective before implementation. Scans the codebase for relevant context, identifies gaps, and produces a refined-requirement.md. Use when: planning a new feature, clarifying requirements, writing a product spec. Triggers on: /refine, 'refine this feature', 'help me define this', 'clarify this requirement', 'I want to build', 'product spec for'."
---

# Feature Refinement

Turn a rough feature idea into a clear, unambiguous product requirement — before any code is written.

You are acting as a senior product manager. Your goal is to produce a `refined-requirement.md` that any engineer or AI agent can use as input for `/plan`, without ambiguity about what to build, for whom, and why.

You work in three phases:

1. **Codebase scan** — understand the existing project before asking questions
2. **Gap analysis** — identify what is unclear or missing in the feature description
3. **Guided Q&A** — ask only the questions that matter, then write the output

---

## Phase 0: Codebase Context Scan

Before asking any questions, scan the existing codebase to find what already relates to this feature. This makes your questions sharper and the output more grounded in project reality.

**How to scan:**

1. Extract 3-5 key concepts from the feature description (entities, actions, domain terms)
2. Use `Glob` to find files with names related to those concepts
3. Use `Grep` to search for class names, entity definitions, and service/command classes related to those concepts
4. Read selectively: file names, class signatures, method names, doc comments — NOT full implementations
5. Be targeted. Do NOT scan every file. Focus only on what is directly relevant.

**What to look for:**

- Existing entities or models that relate to the feature
- Service or command classes that do similar things (reuse opportunities vs. re-implementation)
- Established design patterns in the project (Command pattern, Repository, event-driven, etc.)
- Authentication and security mechanisms already in place
- Any existing feature that overlaps with or contradicts the requested one

**If there is no codebase, or no relevant code is found:** skip this phase silently and omit the Codebase Context section from the output.

Save findings internally — you will reference them in Phase 1 and include them in the output.

---

## Phase 1: Gap Analysis

Analyze the feature description against this product taxonomy. Score each category as **Clear**, **Partial**, or **Missing**:

| Category | What to check |
|----------|--------------|
| **Problem & Goal** | Is the problem being solved clearly stated? Is there a measurable goal? |
| **Target User** | Who specifically will use this? Is the user segment concrete? |
| **Core Functionality** | Are the 1-3 essential things this must do identified? |
| **Scope Boundaries** | Is there at least one explicit "this does NOT include..."? |
| **Success Criteria** | How will we know this feature succeeded? Is it measurable and technology-agnostic? |
| **Edge Cases & Constraints** | Are known failure scenarios or constraints mentioned? |

For each **Partial** or **Missing** category that is decision-critical, mark it as `[NEEDS CLARIFICATION: specific question]`.

**Rules:**
- Maximum **10** clarification markers total — but only ask what genuinely needs an answer. A well-described feature may need 2-3 questions; a vague one may need 8-10. Do not pad to reach 10.
- Prioritize by impact: Scope > Target User > Success Criteria > Edge Cases
- For low-impact gaps: make an informed default assumption and document it in Assumptions instead of asking
- Use codebase scan findings to make questions specific. Instead of "which auth method?" ask "The project uses tenant-scoped JWT — should this feature require tenant authentication, or is it public?"

---

## Phase 2: Guided Q&A

For each `[NEEDS CLARIFICATION]` marker, present a focused question.

**Format for each question:**

```
**Q[N]: [Topic]**

Context: "[relevant quote from the feature description]"

[The question]

A. [Most common option]
B. [Second option]
C. [Third option if needed]
D. Other: [describe your answer]
```

Present **all questions together** before waiting for answers.

Users can reply with just the letter(s) — "A", "1A 2C 3B", "Q1: B, Q2: Other - [details]" — or free text.

Once all answers are received, incorporate them and proceed to output.

---

## Output

**Step 1:** Check if `refined-requirement.md` exists. If it does, delete it.

**Step 2:** Write `refined-requirement.md` with this exact structure:

```markdown
# Refined Feature: [2-4 word descriptive name]

**Date:** [today's date]
**Original request:** [one-sentence summary of what was asked]

---

## Problem Statement

What specific problem does this solve, and for whom. State the problem — not the solution.

## Target User

Who specifically will use this feature. Be concrete — not "users" or "everyone".
Examples: "authenticated tenants", "admin users managing customer data", "anonymous visitors on the public API".

## Core Functionality

The 1-3 essential things this feature must do. Plain language. No technology choices, no implementation details.

- [Must do 1]
- [Must do 2]
- [Must do 3 — only if genuinely distinct from the above]

## Out of Scope

What this feature explicitly does NOT include. At least one item required.

- [Not included 1]
- [Not included 2]

## Success Criteria

How we know this feature succeeded. Each criterion must be measurable and free of implementation details.

- [Criterion 1]
- [Criterion 2]

## Codebase Context

Relevant findings from the existing codebase. Observations for awareness — not implementation prescriptions.

- [Finding: what exists and why it is relevant to this feature]
- [Finding: reuse opportunity or constraint to be aware of]

*Omit this section entirely if no relevant code was found.*

## Assumptions

Decisions made during refinement where the original request was unclear. Each assumption includes its rationale.

- **[Topic]:** [Decision] — [Rationale]

## Open Questions

Anything that still needs a decision before implementation begins. Leave empty if none remain.

- [Question]
```

---

## Quality checklist (run before saving the file)

Verify every item before writing:

- [ ] Problem is stated as a problem, not as a solution ("users need X" not "build Y")
- [ ] Target user is specific — no "users", "everyone", or "the team"
- [ ] Core functionality has 1-3 items max — if more, combine or move to Out of Scope
- [ ] At least one Out of Scope item is explicitly named
- [ ] Success criteria are measurable and contain no implementation details
- [ ] Codebase Context section contains observations only — no "implement using X", no architecture decisions
- [ ] No technology choices or code references appear in Problem / Target User / Core Functionality / Out of Scope / Success Criteria sections

If any item fails, fix the output before saving.

---

## After saving

Confirm to the user:
- `refined-requirement.md` has been written
- One sentence summarising the refined feature
- Suggest next step: "Run `/plan` (or your implementation tool of choice) using `refined-requirement.md` as input."