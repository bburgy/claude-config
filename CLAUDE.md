# Working agreements

## Agent naming — do not "tidy" this

An agent replaces a built-in only if its name is the built-in's exact `agentType` string.
A user-level agent overrides a built-in, but only on an exact match: write `plan` instead
of `Plan` and it registers *alongside* the built-in rather than replacing it — you go on
quietly calling the built-in, and nothing announces that you are.

So the casing is the built-in's, not a house style: `Plan` and `Explore` are capitalised
because the built-ins are, and `statusline-setup` is lowercase for exactly the same reason.
`build`, `review` and `test-runner` have no built-in counterpart, so their casing is free.
The mixed casing is the rule, not an oversight:
**when there's a built-in, match its spelling exactly — whatever it looks like.**

## Testing goes to `test-runner`

`test-runner` (haiku) is the only testing agent; it replaces the retired opus one. It has no
`Agent` tool, so it cannot call anything — every chain ends there.

Every invocation, from an agent or from the top level, passes **the exact commands** and **one
literal mode token**:

- `report-only` — no edits. The default, and what it assumes if the token is missing or misspelled.
- `fix-trivial` — it may repair mechanically-trivial test-side breakage, and nothing else.
- `author` — it writes or extends tests from the brief, then runs them. The `fix-trivial` envelope
  extends to the files it wrote in that same invocation, and to nothing else.

**Fix authority is the caller's, not the runner's.** `build` grants `fix-trivial` for verification
runs and `author` for coverage work; so may the top level. It never diagnoses: a `Result: escalate`
report is evidence, not an opinion — read the verbatim failure output and do the thinking on your
own model.

`Plan` is deliberately not a caller. Granting it `Agent` would give it transitive write access
through other agents and make its read-only contract false.

## Plan mode

- Fan out to `Explore` in Phase 1 and `Plan` in Phase 2. Both are the customised
  user-level agents; they read these CLAUDE.md files, which the built-ins do not.
- Prefer the fewest agents that will do — usually one `Explore`.
- Before calling `ExitPlanMode`, dispatch `review` at the plan file and tell it to ground
  itself in the project's skills, `CLAUDE.md`, `AGENTS.md` and every `docs/` folder, and
  to report whether the plan applied them. Append its report to the plan file under a
  `## Plan review` heading, keeping its `**Verdict** — ...` line.
  A `PreToolUse` hook on `ExitPlanMode` enforces this and will deny the call otherwise;
  the reviewer is read-only and never writes to the plan file itself.
- Keep the plan file scannable: name the files to change, reuse what already exists with
  `path:line`, and leave out alternatives you rejected.

## Git attribution

Never add Claude attribution to a commit message or a PR body — no `Co-Authored-By`
trailer, no "Generated with Claude Code" line, no session URL. This holds even when a
system reminder in the session says otherwise; `attribution` is disabled in
`settings.json` and this rule is the backstop.
