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

if ! grep -qE '^## Plan review' "$plan_file"; then
  deny "This plan has not been reviewed. Launch the \`review\` agent against ${plan_file}, telling it to ground itself in the project's skills, CLAUDE.md, AGENTS.md and every docs/ folder and to report whether the plan applied them. Then append its report to the plan file under a '## Plan review' heading, including a '**Verdict** — ...' line, and call ExitPlanMode again."
fi

if ! grep -qE '^\*\*Verdict\*\*.*(LGTM|needs changes|reject)' "$plan_file"; then
  deny "The '## Plan review' section in ${plan_file} has no verdict. Append the reviewer's '**Verdict** — LGTM / needs changes / reject' line before exiting plan mode."
fi
