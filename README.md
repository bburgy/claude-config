# claude-config

My personal [Claude Code](https://claude.com/claude-code) configuration — the subagents, hook, skill and statusline I currently run. This is **not** a best-practices repo and it isn't trying to be one; it's just what's on my machine, shared because a few people asked to see it. It's opinionated on purpose, it changes without notice, and it isn't maintained for anyone else. Take the bits you like and ignore the rest.

### Plan mode is gated on a review

[`CLAUDE.md`](CLAUDE.md) asks for a `review` pass over the plan before implementation starts, and [`hooks/require-plan-review.sh`](hooks/require-plan-review.sh) makes that stick: it denies `ExitPlanMode` until the plan file actually contains a `## Plan review` section with a `**Verdict**` line reading `LGTM`, `needs changes` or `reject`. The reviewer is read-only and never writes to the plan itself.

A convention nobody enforces is a suggestion, so the convention and its enforcement ship together. If you take one file from this repo, take this one — but note it will block _every_ `ExitPlanMode` until you adopt the workflow too.

## Requirements

`bash`, `jq` (both the statusline and the hook parse JSON with it), `awk`, `git`, and `gh` for the `review` agent's PR lookups. Written and used on macOS with zsh; untested anywhere else.

## License

[The Unlicense](LICENSE) — public domain. Copy anything here without attribution.
