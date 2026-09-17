#!/usr/bin/env bash
# PreToolUse:ExitPlanMode — deny until the plan file carries a review verdict.
set -uo pipefail

input=$(cat)

deny() {
  jq -n --arg r "$1" '{hookSpecificOutput:{hookEventName:"PreToolUse",
    permissionDecision:"deny", permissionDecisionReason:$r}}'
  exit 0
}

transcript=$(printf '%s' "$input" | jq -r '.transcript_path // empty')
plan_file=""
if [[ -n "$transcript" && -f "$transcript" ]]; then
  plan_file=$(grep -oE '/[^"[:space:]]+/plans/[^"[:space:]]+\.md' "$transcript" | tail -1)
fi
if [[ ! -f "$plan_file" ]]; then
  plan_file=$(ls -t "$HOME"/.claude/plans/*.md 2>/dev/null | head -1)
fi

[[ -f "$plan_file" ]] || deny "Could not locate the plan file to verify it was reviewed."

# Match only outside fenced blocks: a heading or verdict quoted inside the reviewer's
# report — or inside any example — is that text, not this plan's own claim to have
# been reviewed.
plain=$(awk '/^[[:space:]]*```/ { fenced = !fenced; next } !fenced' "$plan_file")

if ! grep -qE '^## Plan review' <<<"$plain"; then
  deny "This plan has not been reviewed. Launch the \`copilot-review\` agent against ${plan_file}; it runs the plan past GitHub Copilot on a non-Claude model, grounded in the project's skills, CLAUDE.md, AGENTS.md and every docs/ folder. Append its report to the plan file under a '## Plan review' heading, left as the blockquote the script emits, then restate its verdict as an unquoted '**Verdict** — LGTM / needs changes / reject' line. If Copilot is unavailable, fall back to the \`review\` agent and say in that section which reviewer ran."
fi

if ! grep -qE '^\*\*Verdict\*\*.*(LGTM|needs changes|reject)' <<<"$plain"; then
  deny "The '## Plan review' section in ${plan_file} has no verdict outside a code fence. Append the reviewer's '**Verdict** — LGTM / needs changes / reject' line at top level — a verdict inside the quoted report does not count — before exiting plan mode."
fi
