# Changelog

## 1.1.0

- Verifiers now read `references/verifier.md`, so they always get the six verification steps and a fixed answer shape.
- Pull requests from forks or from authors without write access are not installed, built or run until the user agrees; a read-only review is offered instead.
- The author's PR body and commit messages are passed to agents marked as data, not instructions.
- Cleanup removes only the worktrees, files, servers and databases the hunt's agents reported creating, and names any other new untracked file instead of deleting it. Cleanup is now its own final step.
- New conditional Data & Deploy lane for migrations, deploy order, env and deploy config; Logic keeps that checklist only when the lane is N/A.
- Security now checks added or upgraded dependencies, CI/CD permissions and personal data in logs. Logic now checks swallowed failures, public API breaking changes and docs the change made wrong.
- Worktree and shared-DB rules moved to `references/harness.md`, read only when an agent may run e2e tests or touch a local DB.
- Cost limits: at most two verification rounds; lockfiles, generated, vendored and snapshot files are left out of the hunk list; scopes over 60 files or 3,000 changed lines ask the user to narrow.
- The skill takes an argument (`argument-hint`), and the Security lane gets the installed security-audit skill's path when there is one.
- Small diffs still get one lane agent and the verifiers; the main agent no longer reviews inline. The first eval run caught it skipping both on a 37-line diff.
- Steps renumbered 1–10.
- Added an eval suite under `evals/`.

## 1.0.0

- First release.
