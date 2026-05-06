#!/bin/sh
# PostToolUse hook for ExitPlanMode.
# Fires only on successful plan approval. Detects whether the approved plan
# references a promoted .claude-refine/ spec and, if so, asks Claude to invoke
# the -internal-post-plan skill to capture plan-time mind-changes back into it.

plan_file=""
plan_mtime=0
for f in "$HOME/.claude/plans"/*.md; do
  [ -f "$f" ] || continue
  m=$(stat -f %m "$f" 2>/dev/null || stat -c %Y "$f" 2>/dev/null)
  [ -z "$m" ] && continue
  if [ "$m" -gt "$plan_mtime" ]; then
    plan_mtime=$m
    plan_file=$f
  fi
done
[ -z "$plan_file" ] && exit 0

refs=$(grep -oE '\.claude-refine/[A-Za-z0-9._-]+\.md' "$plan_file" 2>/dev/null | sort -u)

[ -z "$refs" ] && exit 0

case "$refs" in
  *"
"*)
    list=$(printf '%s' "$refs" | tr '\n' ' ')
    printf '{"decision":"block","reason":"Plan references multiple .claude-refine/ specs (%s). Post-plan capture skipped to avoid guessing the target. Tell the user in one sentence."}' "$list"
    exit 0
    ;;
esac

ref="$refs"
spec="$CLAUDE_PROJECT_DIR/$ref"
[ ! -f "$spec" ] && exit 0

printf '{"decision":"block","reason":"User approved the plan at %s, which references the refined spec %s. Invoke the claude-refine:-internal-post-plan skill now, passing PLAN_FILE=%s and SPEC_FILE=%s."}' "$plan_file" "$ref" "$plan_file" "$spec"
