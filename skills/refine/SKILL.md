---
name: refine
description: "Refine a feature request from a product perspective before implementation. Scans the codebase for relevant context, identifies gaps, and produces a product requirement file. Use when: planning a new feature, clarifying requirements, writing a product spec. Triggers on: /refine."
---

# Feature Refinement

Turn a rough feature idea into a clear, unambiguous product requirement — before any code is written.

You are acting as a senior product manager. Your goal is to produce a clean product spec that any engineer or AI agent can use as input for `/plan`, without ambiguity about what to build, for whom, and why.

The skill has two modes:

- **Fresh mode** (default): write a new spec to `$PROJECT_DIR/.claude-refine/.draft-requirement.md`. A `Stop` hook then promotes it to a dated final file `.claude-refine/<YYYYMMDDHHMM>-<slug>.md`.
- **Retrofit mode** (when the user invokes `/refine @<slug> <new info>`): resolve the slug to an existing dated spec, run the same gap-analysis + Q&A against `[existing spec + new input]`, and append the result as a timestamped subsection under a `## Refinement Updates` heading in that file. Original sections are never modified.

You work in four phases:

0. **Mode detection** — decide between fresh and retrofit; resolve the target spec
1. **Codebase scan** — understand the existing project before asking questions
2. **Gap analysis** — identify what is unclear or missing
3. **Guided Q&A** — ask only the questions that matter, then write the output

---

## Phase 0: Mode Detection

Inspect the user's `/refine` argument.

**Does not reference an existing `.claude-refine/` file** → `mode = fresh`. Skip directly to Phase 1.

**Explicitly references an existing `.claude-refine/` file** → enter retrofit selection:

1. Strip the leading `@`. The remaining string is the requested slug (may be empty if the user typed just `@`).
2. List `$CLAUDE_PROJECT_DIR/.claude-refine/*.md`, excluding `.draft-requirement.md` and any dotfile. For each filename, derive the indexed slug:
   - If the filename matches `^(\d{12})-([a-z0-9-]+)\.md$`, the slug is the second capture group.
   - Otherwise (user-renamed or hand-created), the slug is the basename without `.md`.
3. **Exact match**: if exactly one indexed slug equals the requested slug → `target = <that path>`. Go to step 6.
4. **Unique-prefix match**: else if exactly one indexed slug starts with the requested slug (and the requested slug is non-empty) → `target = <that path>`. Go to step 6.
5. **Otherwise** (empty requested slug, no match, or multiple prefix matches): use `AskUserQuestion` with a single question (`header: "Which spec?"`), one option per existing indexed spec (label = slug, description = one-line excerpt from that spec's Problem Statement; cap at 3 options shown, sorted by most-recent timestamp), plus a final option labelled `Cancel — abort`. Do not add an explicit "Other" option — the tool adds it automatically.
   - If the user picks a spec → `target = <that path>`. Continue.
   - If the user picks `Cancel — abort` or supplies an unusable free-text answer → exit with a one-line message; make no file changes.
6. `mode = retrofit`. **Delete any stale `$PROJECT_DIR/.claude-refine/.draft-requirement.md` now** to mitigate Stop-hook false-trigger if a previous interrupted run left one behind.
7. The "new input" is everything after the `@<slug>` token in the original `/refine` argument. If that remainder is empty or whitespace-only, ask via `AskUserQuestion` with a single open-ended question (use one option `Cancel — abort` plus the tool's automatic "Other" for the free-text answer): `What would you like to add to <slug>?`. The user's free-text answer becomes the new input.
8. Read the `target` file and stash its content for use in Phases 1 and 2.

---

## Phase 1: Codebase Context Scan

Before asking any questions, scan the existing codebase to find what already relates to this feature. This makes your questions sharper and the output more grounded in project reality.

**How to scan:**

1. Extract 3-5 key concepts from the feature description (entities, actions, domain terms). In retrofit mode, draw concepts from both the existing spec's Problem Statement / Core Functionality **and** the new input.
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

**In retrofit mode**, read the existing spec's `## Codebase Context` section first. Carry forward only findings that are **not** already recorded there — these deltas are what may go into the new subsection. The original Codebase Context block is never modified.

**If there is no codebase, or no relevant code is found (or in retrofit, no new findings beyond the existing Codebase Context):** skip this phase silently and omit the Codebase Context section / "New codebase observations" group from the output.

Save findings internally — you will reference them in Phase 2 and include them in the output.

---

## Phase 2: Gap Analysis

Analyze the feature description against this product taxonomy. Score each category as **Clear**, **Partial**, or **Missing**:

| Category | What to check |
|----------|--------------|
| **Problem & Goal** | Is the problem being solved clearly stated? Is there a measurable goal? |
| **Target User** | Who specifically will use this? Is the user segment concrete? |
| **Core Functionality** | Are the 1-3 essential things this must do identified? |
| **Scope Boundaries** | Is there at least one explicit "this does NOT include..."? |
| **Success Criteria** | How will we know this feature succeeded? Is it measurable and technology-agnostic? |
| **Edge Cases & Constraints** | Are known failure scenarios or constraints mentioned? |

**Input to gap analysis:**

- **Fresh mode**: the user's `/refine` description, plus Phase 1 codebase findings.
- **Retrofit mode**: the existing spec's Problem Statement + Target User + Core Functionality **concatenated with** the new input. Markers must target gaps that the **new input** introduces or fails to resolve — not gaps already resolved in the original spec content.

For each **Partial** or **Missing** category that is decision-critical, mark it as `[NEEDS CLARIFICATION: specific question]`.

**Rules:**
- Maximum **8** clarification markers total — but only ask what genuinely needs an answer. A well-described feature may need 2-3 questions; a vague one may need 6-8. Do not pad to reach 8.
- Prioritize by impact: Scope > Target User > Success Criteria > Edge Cases
- For low-impact gaps: make an informed default assumption and document it in Assumptions instead of asking
- Use codebase scan findings to make questions specific. Instead of "which auth method?" ask "The project uses tenant-scoped JWT — should this feature require tenant authentication, or is it public?"

**No-op guard (retrofit only):** if gap analysis produces zero markers **and** the new input introduces no new functionality, scope, success criterion, or assumption, do not proceed to Phase 3. Tell the user in one sentence: `No new requirements detected; <slug>.md unchanged.` Exit without writing.

---

## Phase 3: Guided Q&A

Ask the clarification questions using the `AskUserQuestion` tool — never the manual "A / B / C / D" letter format in chat text.

**Batching rules:**

- `AskUserQuestion` accepts **1–4 questions per call**.
- If you have ≤4 markers: ask them all in **one round**.
- If you have 5–8 markers: split into **two rounds** of up to 4 questions each. Send the highest-priority batch first (Scope > Target User > Success Criteria > Edge Cases). Wait for answers, then send the second batch — informed by the first round's answers (drop or rewrite questions that became obsolete).
- Never exceed 2 rounds.

**Per-question requirements:**

- `header`: ≤12 chars, topic chip (e.g. "Auth", "Scope", "Trigger").
- `question`: one clear sentence ending with "?". Reference the relevant feature quote inline if it adds clarity.
- `options`: 2–4 mutually exclusive choices. Do **not** add an "Other" option — the tool adds it automatically. If you have a recommended option, list it first and append "(Recommended)" to the label.
- Each option needs a `description` explaining the implication of choosing it.
- Set `multiSelect: true` only when choices are genuinely non-exclusive (e.g. "which surfaces should this appear on?").

Once all answers are received across all rounds, incorporate them and proceed to Output.

---

## Output

Branch by mode.

### Fresh mode

**Step 1:** Check if `$PROJECT_DIR/.claude-refine/.draft-requirement.md` exists. If it does, delete it.

**Step 2:** Write `$PROJECT_DIR/.claude-refine/.draft-requirement.md` with this exact structure:

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

### Retrofit mode

Do **not** write `.draft-requirement.md`. Edit the `target` spec file in place.

**Step 1:** Read the `target` file. Note whether it already contains a `## Updates After Planning` section — that fact is needed for the re-plan reminder in the "After saving" step.

**Step 2:** Decide where to place the new subsection:

- If `## Refinement Updates` already exists in the file → append the new subsection at the end of that existing block (do not duplicate the heading).
- Else if `## Updates After Planning` exists → insert a new `## Refinement Updates` section **immediately before** it.
- Else → append a new `## Refinement Updates` section at the end of the file.

Refinement always precedes planning conceptually, so `## Refinement Updates` always appears before `## Updates After Planning` regardless of which was first created.

**Step 3:** The new subsection has this shape (omit any group whose list is empty):

```markdown
### YYYY-MM-DD HH:MM — from input: "<short paraphrase of the new input>"

**Extends Problem Statement:** …
**Extends Target User:** …
**Extends Core Functionality:** …
**Extends Out of Scope:** …
**Extends Success Criteria:** …
**New codebase observations:** …
**New assumptions:** …
**New open questions:** …
**Remaining clarifications:** …
```

The timestamp uses `date '+%Y-%m-%d %H:%M'`. The short paraphrase must not contain unescaped double-quotes. `**Remaining clarifications:**` holds any `[NEEDS CLARIFICATION]` markers that survived Phase 3 (typically none — Q&A normally resolves them).

**Step 4:** Use the `Edit` tool (not `Write`) to apply the insertion, so the rest of the file is preserved byte-for-byte. Pick an `old_string` that is unique in the file (e.g. the existing `## Updates After Planning` heading for insert-before, or the file's last non-empty line for append-at-EOF).

---

## Quality checklist (run before saving)

### Fresh mode

Verify every item before writing:

- [ ] Problem is stated as a problem, not as a solution ("users need X" not "build Y")
- [ ] Target user is specific — no "users", "everyone", or "the team"
- [ ] Core functionality has 1-3 items max — if more, combine or move to Out of Scope
- [ ] At least one Out of Scope item is explicitly named
- [ ] Success criteria are measurable and contain no implementation details
- [ ] Codebase Context section contains observations only — no "implement using X", no architecture decisions
- [ ] No technology choices or code references appear in Problem / Target User / Core Functionality / Out of Scope / Success Criteria sections

### Retrofit mode

(Original sections are frozen, so most fresh-mode rules do not apply. Reduced checklist:)

- [ ] Each `**Extends …:**` group contains no technology choices or implementation details
- [ ] `**New codebase observations:**` are observations, not prescriptions
- [ ] The subsection header paraphrase contains no unescaped double-quotes
- [ ] The subsection is not empty (no-op guard passed)

If any item fails, fix the output before saving.

---

## After saving

### Fresh mode

- Provide to the user three to ten sentences summarizing the refined feature

### Retrofit mode

- Provide to the user one to five sentences summarizing the new input that was captured
- **Re-plan reminder**: if the target file (as read in Step 1) already contained a `## Updates After Planning` section, add: "This spec was previously planned. Re-run `/plan` to incorporate the new additions and implement them." If `## Updates After Planning` is absent, suggest next step: "Run `/plan` (or another implementation tool) using `@.claude-refine/<final-filename>` as input."
