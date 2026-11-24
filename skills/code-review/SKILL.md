---
name: code-review
description: Review the changes with the grounded `review` agent — it reads the project's skills, CLAUDE.md and every docs/ folder before judging, then reports findings by severity. Needs an existing PR. Optionally takes a target (PR number or branch), an effort level and `full`. When the target is a GitHub PR, it also posts the review to the PR, with inline comments on the changed lines.
argument-hint: "[target] [low|medium|high|max] [full]"
context: fork
agent: review
---

Review the changes.

**Prerequisite: a PR must exist.** Before anything else, find the PR to review:

- If `$ARGUMENTS` names a PR number or URL, check it with `gh pr view <number> --json number,state`.
- Otherwise use the PR for the named branch, or for the current branch: `gh pr view [<branch>] --json number,state`.

If there is no PR, or `gh` fails, stop. Do not start the review. Reply with one line: "No PR found for `<branch>`. Create the PR first, then run `/code-review` again." Include the verbatim `gh` error if there was one. If a PR is found, that PR is the target.

`$ARGUMENTS` — if this names a target (a PR number or URL, or a branch), review its PR. If it names an effort level (`low`, `medium`, `high`, `max`), review at that depth. If it contains `full`, review the whole PR rather than only the changes since your last review. If it is empty, review the PR of the current branch.

If the target is a GitHub PR, post the finished review to it as described under **Posting to a GitHub PR** in your instructions.

Follow your own instructions in full: ground yourself in the project's skills, `CLAUDE.md`, `AGENTS.md` and every `docs/` folder that bears on the change before forming an opinion, delegate the lookups, the file fetches and any URL to `Explore`, take open design questions to `Plan`, and return your fixed report contract.
