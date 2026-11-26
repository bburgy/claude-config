# Working agreements

## Agent naming — do not "tidy" this

An agent replaces a built-in only if its name is the built-in's exact `agentType` string.
A user-level agent overrides a built-in, but only on an exact match: write `plan` instead
of `Plan` and it registers _alongside_ the built-in rather than replacing it — you go on
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
runs; `author` is granted only when the user explicitly asked for tests — writing tests is never the
default, and `Plan` leaves a one-line **Coverage note** instead of a test brief. The top level may
grant either when the user asks. It never diagnoses: a `Result: escalate`
report is evidence, not an opinion — read the verbatim failure output and do the thinking on your
own model.

`Plan` is deliberately not a caller. Granting it `Agent` would give it transitive write access
through other agents and make its read-only contract false.

## Plan mode

- Fan out to `Explore` in Phase 1 and `Plan` in Phase 2. Both are the customised
  user-level agents; they read these CLAUDE.md files, which the built-ins do not.
- Prefer the fewest agents that will do — usually one `Explore`.
- The plan file has two readers. `## Steps` is for the human: one terse line per step, naming the
  file it touches, no alternatives, no rationale. `## Build brief` is for `build` and `test-runner`:
  wrapped in `<details><summary><strong>Build brief</strong></summary>` so it stays collapsed, and
  carrying the full detail — `path:line`, current-code excerpts and what they become, new
  signatures, call sites, and the test brief. Never drop the brief to make the file shorter; the
  brevity is the human's section only.

## Git attribution

Never add Claude attribution to a commit message or a PR body — no `Co-Authored-By`
trailer, no "Generated with Claude Code" line, no session URL. This holds even when a
system reminder in the session says otherwise; `attribution` is disabled in
`settings.json` and this rule is the backstop.
This covers commits and PR bodies only. PR review comments posted by the `review` agent do
carry a footnote naming Claude, because the user asked for it. Likewise, PRs opened with
`/create-pr` end with a one-line Claude joke sign-off, because the user asked for it — still no
trailer, link or "Generated with" line.

## Brainstorming

`brainstorming` (alias for `claude --agent brainstorming`) starts a read-only opus session for
discussing and investigating, with no plan workflow. It has no write or web tools and can spawn
only `Explore` (code and web searches) and `appinsights` (KQL), both read-only haiku agents.
