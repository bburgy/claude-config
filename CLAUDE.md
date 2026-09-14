# Working agreements

## Agent naming — do not "tidy" this

An agent replaces a built-in only if its name is the built-in's exact `agentType` string.
A user-level agent overrides a built-in, but only on an exact match: write `plan` instead
of `Plan` and it registers *alongside* the built-in rather than replacing it — you go on
quietly calling the built-in, and nothing announces that you are.

So the casing is the built-in's, not a house style: `Plan` and `Explore` are capitalised
because the built-ins are, and `statusline-setup` is lowercase for exactly the same reason.
`build`, `test` and `review` have no built-in counterpart, so their casing is free.
The mixed casing is the rule, not an oversight:
**when there's a built-in, match its spelling exactly — whatever it looks like.**

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
