---
name: -internal-post-draft
description: "Runs automatically after /refine completes. Triggered by the claude-refine plugin's Stop hook once .claude-refine/.draft-requirement.md has been produced. Promotes the draft into a dated final spec file."
---

# Post-Draft: Promote Draft to Final

This skill runs after `/refine` completes. It promotes the ephemeral draft into a permanent, dated spec file.

## Steps

1. **Read the draft.** Read `$CLAUDE_PROJECT_DIR/.claude-refine/.draft-requirement.md`. If the file does not exist, stop and tell the user the draft is missing — do not invent content.

2. **Extract the feature slug.** From the draft's `# Refined Feature: <name>` heading, take the name and convert it to a 2-4 word kebab-case slug:
   - lowercase
   - spaces → `-`
   - strip any character that is not `a-z`, `0-9`, or `-`
   - collapse repeated `-`
   - if the heading yields more than 4 words, keep the first 4 most meaningful (drop articles like "the", "a", "an")
   - if it yields fewer than 2 words, pad from Core Functionality keywords until you have at least 2

3. **Get the timestamp.** Run `date '+%Y%m%d%H%M'` via the `Bash` tool. Use the exact stdout — never retype or reformat from memory.

4. **Compose the final filename.** `<timestamp>-<feature-slug>.md` — e.g. `202611061430-customer-search-endpoint.md`.

5. **Write the final file.** Write the draft's full content verbatim to `$PROJECT_DIR/.claude-refine/<final-filename>`. No edits, no reformatting, no added sections.

6. **Leave the draft in place.** Do not delete `.draft-requirement.md` — the next `/refine` run overwrites it.

## Confirm to the user

- One to five sentences summarizing the refined feature.
- The path of the final file written.
- Suggest next step: "Run `/plan` (or another implementation tool) using `.claude-refine/<final-filename>` as input."
