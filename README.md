# bug-hunt — evidence-first code review for Claude Code

`bug-hunt` reviews a branch, a pull request or your uncommitted changes and returns **a short, ranked list of bugs that are real**: each with where it is, how to trigger it, how to fix it, and a plain list of what was not checked.

How it works:

1. **One scope for everyone**: the exact diff, every hunk, the PR body and commit messages verbatim.
2. **Automated checks first**: the repo's own typecheck, lint, unit, DB and e2e tests that touch the scope.
3. **Lanes in parallel**: Security, Logic & edge cases, UX/UI, Accessibility, Performance, plus Data & Deploy when the change touches migrations, env or deploy config. Each stays in its own category and accounts for every hunk.
4. **Independent verification**: every finding goes to a fresh verifier that tries to disprove it, checks whether the behaviour was chosen on purpose, and reproduces it with a failing test, query or app run. `CONFIRMED` means something ran and showed the bug; a code trace alone is only `PLAUSIBLE`.
5. **Ranked report**: Critical → Low, findings caused by this change kept apart from older bugs found on the way, and a section for everything unverified.

## Install

In Claude Code:

```
/plugin marketplace add meandp589/claude-bug-hunt
/plugin install bug-hunt@claude-bug-hunt
```

Or from a shell:

```bash
claude plugin marketplace add meandp589/claude-bug-hunt
claude plugin install bug-hunt@claude-bug-hunt                  # for you
claude plugin install bug-hunt@claude-bug-hunt --scope project  # for everyone on this repo
```

Update later with `claude plugin update bug-hunt@claude-bug-hunt`.

## Use

Ask in plain words ("review this branch", "review PR 42", "any bugs before I merge?", "is this safe to ship?") or call it directly: `/bug-hunt:bug-hunt [PR number | branch | path]`.

It works best when the repo can run its tests locally and has a `CLAUDE.md` (or `AGENTS.md`) listing its commands, rules and traps; the lanes use those to reproduce findings. It never touches production or shared external accounts and edits no tracked files. At the end it removes only what it created: the worktrees, files and servers its agents reported. For a pull request from a fork or from an author without write access, it asks before installing, building or running any of that code, and offers a read-only review instead.

The lane checklists are stack-neutral, but their worked examples come from web apps on Postgres/Supabase, React and Playwright, which is where the skill has been used most.

Requirements: Claude Code with the Agent tool, `git` 2.38+, a POSIX shell (macOS, Linux or WSL); `gh` for GitHub PR numbers. The report is written as a Markdown file outside the repo; it is published elsewhere (e.g. as a claude.ai Artifact) only when your instructions say so, because it quotes your code.

Cost: a full hunt starts up to six lane agents plus up to six verifiers per round, for at most two verification rounds. Small diffs (≤ 3 files, ≤ 150 lines) use one lane agent. Scopes over 60 files or 3,000 changed lines ask you to narrow first; lockfiles, generated and vendored files are not read line by line.

## Evals

`evals/` holds cases with a planted-bug fixture repo. Run them from the repo root:

```bash
claude plugin eval . --scaffold --allow-tools Bash Write Edit --runs 1 --ablation none --no-publish
```

Each case runs a full hunt, so it costs about as much as one real review.

## License

MIT
