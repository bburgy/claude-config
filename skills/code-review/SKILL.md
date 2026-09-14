---
name: code-review
description: Review the changes with the grounded `review` agent — it reads the project's skills, CLAUDE.md and every docs/ folder before judging, then reports findings by severity. Optionally takes a target (PR number, branch, path) and an effort level.
argument-hint: "[target] [low|medium|high|max]"
context: fork
agent: review
---

Review the changes.

`$ARGUMENTS` — if this names a target (a PR number, a branch, a path), review that. If it names an effort level (`low`, `medium`, `high`, `max`), review at that depth. If it is empty, review the pending changes and establish the scope yourself.

Follow your own instructions in full: ground yourself in the project's skills, `CLAUDE.md`, `AGENTS.md` and every `docs/` folder that bears on the change before forming an opinion, delegate the lookups, the file fetches and any URL to `explore`, take open design questions to `plan`, and return your fixed report contract.
