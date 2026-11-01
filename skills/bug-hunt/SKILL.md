---
name: bug-hunt
description: Use when the user asks, in any language, to review code, audit, hunt for bugs, or check a change before deploy, merge or push — e.g. "review this branch", "review PR 42", "find bugs", "any bugs in this?", "is this safe to ship", "check before merge", "check before deploy", "bug hunt", "review โค้ด", "หาบัค", "เช็คก่อน deploy". Not for a dedicated security pen-test or full security audit (use security-audit), a quality-only cleanup with no bug hunting (use simplify), or fixing a known failing test (use systematic-debugging).
---

# bug-hunt

Goal: **a short, ranked list of bugs that are real**, each with where it is, how to trigger it and how to fix it, plus a plain statement of what was not checked. Five lanes hunt in parallel, each in its own category only; then the findings are merged, de-duplicated, independently re-checked and ranked.

## Facts, not assumptions
Never assume — find out. Every premise behind a finding, a severity or a "not a bug" verdict (what a function does, what a column holds, which statuses a row can reach, how a browser behaves, whether the local stack is up) is established by reading the code/SQL/docs, running a test, querying the local DB, or driving the local app. When something truly can't be established here (e.g. behaviour only on a real device or in production data), it is reported as **unverified**, with what was tried and what would settle it — never written as fact, and it keeps the finding below `CONFIRMED`. The main agent asks the user only for decisions that are theirs; facts are looked up.

## Workflow

`<scratchpad>` below means the session's scratchpad directory when the harness provides one, otherwise one new directory from `mktemp -d`, outside the repo, used for the whole hunt.

### 1. Resolve the scope (one file list for everyone)
- Given a branch, commit range or path: use exactly that.
- Given a PR number: review the PR's head, not whatever is checked out. Unless the checkout is already at `gh pr view <n> --json headRefOid`, run `git fetch origin <baseRefName> pull/<n>/head:bug-hunt/pr-<n>` and `git worktree add <scratchpad>/pr-<n> bug-hunt/pr-<n>`; that worktree is the `Repo:` for every lane and verifier, and the diff is `origin/<baseRefName>...bug-hunt/pr-<n>`. Remove the worktree and the branch at the end.
- Otherwise: the current branch vs its merge base with the repo's default branch, plus uncommitted changes. The default branch comes from `git symbolic-ref --short refs/remotes/origin/HEAD` (or `gh repo view --json defaultBranchRef -q .defaultBranchRef.name`), never an assumed `main`. The diff is `git diff $(git merge-base HEAD <it>)` (base vs working tree, so uncommitted tracked changes are in it; `<base>...HEAD` would drop them).
- Untracked files (`git ls-files --others --exclude-standard`) are part of "uncommitted changes" but `git diff` never shows them: add each to the file list and to the hunk list as `path:1-<wc -l>`. Also save `git status --porcelain` as the **before snapshot** for cleanup.
- "Whole project": only when asked. Narrow it to the riskiest areas (money, auth, data writes, public routes) and state that narrowing and the facts behind it (e.g. churn from `git log`, paths that move money) in the report.
- Write down: the diff command, the changed files, the **hunk list** (`git diff -U0 <range> | grep -E '^(\+\+\+|@@)'` → `path:start-end` per hunk), one sentence of **what the change promises**, and the **change description verbatim**: the PR body (`gh pr view <n> --json body -q .body`) and every commit message in the range (`git log --format='%h %B' <range>`). The author names exceptions there ("X is counted as Y", "left out on purpose"), and a lane that never sees them reports those as bugs (seen: a sport the PR body said was folded into another). Every lane gets this identical scope and description. Lanes may read any other file to understand the code, but report only bugs **in the scope or caused by it**; a bug they meet that was already there goes in with `Caused by this change: no`.

Resolve the scope from git itself (`git branch -a`, `gh pr view`, `git status`). If the facts still allow two different targets, ask the user (AskUserQuestion) rather than pick one.

### 2. Collect repo knowledge
- Read the repo's agent instructions (`CLAUDE.md`, `CLAUDE.local.md`, `AGENTS.md`, nested ones in the scope's directories: traps, rules, commands) and this project's auto-memory directory if the session has one (its path is in your context; don't construct it).
- Run `git log --oneline --grep='fix' -- <scope paths> | head -20` for past bugs in the same area.
- Collect the **decisions for this area**: the spec/design-doc links the repo's instructions or docs give for the features the diff touches, every recorded decision there about them (e.g. "(user decision YYYY-MM-DD)" lines, ADRs), the linked issue, and the memory files that record decisions for them. These say what the author meant; without them a lane judges intent from its own reading. Give the same list to every lane and every verifier.
- Split what you found by lane: e.g. authz/row-level policies/grants/secrets → Security; money units, status machines, constraints, time zones → Logic; design tokens, i18n, states → UX/UI; theme contrast, focus → Accessibility; query/bundle limits → Performance. Each lane gets only its own slice (keeps prompts short and lanes in lane).

Decide what lanes may run (step 4's "You may run") from facts, not guesses: check whether the local stack/app is actually up and who started it (`docker ps`, the repo's status and run commands). Running tests, querying the local DB read-only and driving the local app are expected wherever the repo supports them — that is how findings become `CONFIRMED`. Writes go only to throwaway data the lane creates itself. Never production or shared external accounts. If something needed is down, start it per the repo's instructions (and stop what you started afterwards).

**Parallel agents must not share a test harness.** E2E harnesses usually keep state in the checkout (server pid files, env files, `test-results/`) and their teardown kills "their" servers, so two agents running e2e in one checkout break each other's runs (seen: one run's teardown killed another's Vite). Any agent that may run e2e gets its own git worktree with its own ports. The main agent creates it (`git worktree add --detach <scratchpad>/wt-<agent> <the scope's head commit>`) and passes its path as `Repo:` — not the Agent tool's `isolation: "worktree"`, which is created at launch from the current checkout and can't be prepared first. A worktree starts from a commit, so when the scope includes uncommitted or untracked changes, carry them in (`git diff HEAD | git -C <wt> apply`, then copy the untracked files from step 1) and check `git -C <wt> status` shows the same changes. The prompt says how to finish preparing it (install deps, copy the gitignored env files, build steps) and the exact narrow command (e.g. Playwright needs `--project <name>` as well as `-g`, or project dependencies pull in the whole suite). Remove these worktrees at the end. Agents that only read code or query the DB can share the checkout.

**The shared local DB is the same kind of harness.** First find whose database is running (e.g. `docker ps` container names usually carry a project id or compose project name; compare with this checkout's config). Reset or migrate only a database this hunt started, or this checkout's own when no other session is using it; worktrees of one repo usually share the same project id, so when you can't tell whose it is, treat it as another session's. When the running database belongs to another checkout or session, start an isolated one for the hunt (the repo's instructions may say how; otherwise a copy of its DB config with a new project name and free ports — e.g. Supabase: copy `supabase/config.toml` with a new `project_id` and ports, symlink `migrations` and `seed.sql`, `SUPABASE_WORKDIR=<dir> supabase start`; Docker Compose: `docker compose -p <new name>` with remapped ports), point every lane at its DB URL, and stop it at the end. Tools that mount the checkout into Docker need it under a path the Docker VM can mount (often under `~`, not the system temp dir); otherwise run the test files through `docker exec`. Anything that resets, reseeds or migrates it (a DB reset, the full DB test suite, applying migrations) is run only by the main agent, one at a time: in step 2b, or after the lanes/verifiers of a step have all returned. Lanes and verifiers run only narrow tests that leave shared state as they found it (a DB test inside `begin; … rollback;`); a check that needs a reset goes in their report as the exact command to run, and the main agent runs it once the step's agents have returned.

After the hunt, copy every reproduction test a verifier named into `<scratchpad>/bug-hunt-repros/<repo-relative path>` and list those paths in the report — they are the failing tests for the fix step. Then remove what the agents left: untracked files in `git status --porcelain` now that weren't in step 1's before snapshot, and listening servers (`lsof -iTCP -sTCP:LISTEN`) that this hunt started: by the PID recorded at start, or a cwd under this hunt's worktrees/scratchpad. Never kill by command text or port range; other sessions run the same servers. Leave everything else alone.

### 2b. Run the automated checks first
Before any agent reads code, run what the repo already has (commands from its agent instructions / CI config): typecheck, lint, unit tests, DB tests and DB linters/advisors when SQL changed, and the e2e specs that touch the scope (grep the specs for the changed pages/endpoints). When the branch is behind its base and the scope changes migrations, run the DB checks a second time on the merged tree (`git merge-tree --write-tree origin/<base> <head>`, then `git archive <tree> <migrations dir>`), because production gets the merge, not the branch. Tell the lanes which migrations the DB they query has applied (branch head or merged). Record each command and its result. A failure inside the scope is a finding (already reproduced); a failure outside it is listed as pre-existing with its output, not hidden. Pass the results to every lane.

### 2c. Map the variants from the real schema
For each entity the scope touches, list every variant the changed code can meet — kinds, statuses, roles, plans, flags, branch modes — from the source of truth, not from memory: enum/check constraints and live function bodies in the local DB (Postgres: `pg_get_constraintdef`, `pg_proc.prosrc`), type unions/enums, status lists in the code. Also list what other code does to those rows (triggers, jobs, functions that update or **delete** them: `grep` the migrations and code, and query the live DB catalog). Skip this step when the scope touches no stored or enumerated state. Give the map to every lane; each changed branch must be judged against every variant it can receive.

### 3. Decide which lanes run
A lane runs when the scope contains anything it can judge. Mark a lane `N/A — <reason>` in the report instead of dispatching it when nothing applies (e.g. UX/UI and Accessibility on a SQL-only diff). Security and Logic run for any code change.

**Small diff** (≤ 3 files and ≤ 150 changed lines: `git diff --shortstat` plus the untracked files' lines): dispatch one agent instead of one per lane, with step 4's prompt where `<LANE>` lists the lanes that apply and `<lane-file>` lists their files. It returns one report per lane, in the report-format.md shape.

### 4. Dispatch the lanes — all in ONE message, in parallel
Use the Agent tool (not the Workflow tool unless the user asked for a workflow). Don't set `model`/`effort`. Each prompt is:

```
You are the <LANE> lane of a bug hunt. Report only — edit no tracked files. Don't ask questions and don't assume: find out by reading code, running tests, querying the local DB or driving the local app. What you truly cannot establish goes under "Unverified" with what you tried.
Read first: ${CLAUDE_SKILL_DIR}/references/<lane-file>.md and ${CLAUDE_SKILL_DIR}/references/report-format.md.
Repo: <absolute path>. Scope: <diff command>. Files: <list>.
The change promises: <one sentence>.
Change description (PR body and commit messages, verbatim): <text>.
Decisions for this area: <spec links / user decisions / memory notes from step 2, or "none found">.
Repo rules/traps for your lane: <bullets from step 2, or "none">.
Past fixes in this area: <shas + one line each, or "none">.
Automated check results: <commands + pass/fail, failures quoted>.
Variant map: <entity → kinds/statuses/roles…; who updates/deletes them>.
Hunks: <path:start-end list> — account for every one in your Hunk ledger.
You may run: <what step 2 found is available, e.g. "unit tests; local DB read-only via psql <url> (migrations applied: branch head | merged with base); local app at <url>">. Report the PID of any server you start.
Stay in your lane (the lane file says where the borders are). Cite only lines you actually read.
Return your report exactly in the report-format.md shape.
```

Lane files: `security.md`, `logic.md`, `ux-ui.md`, `accessibility.md`, `performance.md`.

### 5. Merge and de-duplicate
- Collect all findings. Two findings are the same when they share a root cause and their `file:line` ranges overlap or one causes the other: merge them, keep the higher severity, list both lanes.
- **Hunk coverage**: every hunk must be `checked` by at least one lane. A hunk no lane checked goes to the report's "not checked" section by name — or send one lane back to it.
- `Out of lane` notes: if another lane already reported or checked it (see their "checked and fine" lines), drop the note; if the note itself names no wrong outcome, drop it; otherwise turn it into a `suspect` finding of the right lane (it goes through verification like any other).
- A finding without `Intent check` or `Caused by this change` goes back to its lane for those two lines before it is verified; the merger never fills them in.
- Keep `Caused by this change: no` findings in a separate list ("found on the way"). They are verified like the rest but never count toward the deploy verdict.

### 6. Verify every finding independently
For each merged finding, dispatch a verifier (Agent tool, all in one message; put findings about the same function or effect in one verifier, so it can judge how their fixes interact). At most 6 verifiers per round (a re-verification round for brand-new bugs counts as its own round): group by file when there are more findings, and if groups still exceed 6, verify the highest-severity ones and list the rest as unverified in section 5. Give it **only** the finding block, the repo/scope and the one-line titles of the other findings — not the lane's reasoning:

```
Independently verify the reported bug(s) below. Report only; edit no tracked files (a new test file for the reproduction is fine; give its repo-relative path in your answer). You may run: <same rule as the lanes>.
Repo: <absolute path>. Change under review: <diff command>. The change promises: <one sentence>.
Change description (PR body and commit messages, verbatim): <text>.
Decisions for this area: <same list the lanes got, or "none found">.
Finding(s): <finding block(s) as the lane wrote them>
Other findings already reported (don't re-report these; say "duplicate of N" if you hit one): <titles>
Do steps 1-6 below. Answer per finding: CONFIRMED | PLAUSIBLE | INTENDED | REJECTED, reason, corrected severity, "caused by this change: yes/no" with the evidence, fix correction. Under 200 words per finding. Answer in English.
```

The verifier's steps:
1. Read the cited code and the code paths that reach it. Is the line real and does the claimed path exist?
2. Was the behaviour chosen? Read the intent sources in `report-format.md` in order (change description, decisions for the area, the same behaviour elsewhere in the product, a test asserting it, `git log -S` on the line) and name the one you stopped at. A source that chooses this behaviour ends the check: answer `INTENDED` with the source; do not go on to reproduce it.
3. Try to disprove it: a guard elsewhere, a constraint, RLS, a caller that never passes that input, a framework default.
4. Reproduce it: a failing test (unit, DB or e2e — whichever level the bug lives at), a query result on the local DB, or the local app showing the wrong state. Keep the test file and the exact command; that test becomes the regression test when the bug is fixed. Never touch production or shared external accounts.
5. Check the proposed fix too: does it fix the bug without breaking the change's promise or another finding's fix? And was the bug there before the change (`git blame`/`git log -S` on the line, or the file is outside the diff)? Answer "caused by this change: yes/no" with that evidence.
6. Answer `CONFIRMED` (**only** with a reproduction from step 4: name the test/command and the wrong output it showed), `PLAUSIBLE` (the path exists in code but could not be reproduced here: say what was tried and what would reproduce it), `INTENDED` (the behaviour happens, and the named source chose it; say what the source is, and whether the finding's "expected" disagrees with the product or only with the lane), or `REJECTED` (the claimed path or outcome does not exist, with the evidence), and correct the severity if it's wrong. A code trace alone, however complete, is `PLAUSIBLE`. "CONFIRMED but intended", "CONFIRMED, Info" and "real but by design" are not answers: that case is `INTENDED`.

Use the verifier's severity when it differs from the lane's, and show both in the report. Something the verifier rates below Low (no user-visible effect) goes to the dropped list. If the verifier rejects the proposed fix, report its corrected fix, never the original one. `INTENDED` findings go to the dropped list with their source; if the source is a convention the user may want to revisit (not a spec or a user decision), say so there in one line, as a question, not a finding.

A brand-new bug a verifier reports has not itself been verified: send it through this step again, or report it as `PLAUSIBLE`.

Drop `REJECTED` findings into the "Dropped after re-check" list with their one-line reason. Do not verify by re-reading the finder's argument yourself and agreeing with it.

### 7. Rank and report
Order: Critical → High → Medium → Low; within a tier `CONFIRMED` (reproduced) before `PLAUSIBLE`; then by blast radius (money/data/many users first).

Write the report in the user's language (section headings too), with code, paths, identifiers and commands left as they are. Where it goes: if the user's instructions name an output format, use it; otherwise, if an Artifact tool is available, publish it as an Artifact and share the link; otherwise write it to `<scratchpad>/bug-hunt-report-<short sha>.md` (never into the repo) and give the absolute path. Sections in this order:
1. **TL;DR** — one line verdict (e.g. "Ready to deploy" / "Don't deploy until 2 findings are fixed"), counts per severity. The verdict counts only findings caused by this change; the "found on the way" count is shown next to it, separately. `PLAUSIBLE` Critical/High findings count toward the verdict like `CONFIRMED` ones (not reproduced is not proven safe) and the verdict line says how many of them are not reproduced.
2. **Findings** — ranked, each with: severity, lanes, `file:line`, what goes wrong, the intent source checked, how to reproduce, fix, verification result with its evidence (test path + command, or query + output).
3. **Found on the way, not caused by this change** — verified findings with `Caused by this change: no`, ranked the same way, each saying where it already was. An empty section is written as "None".
4. **Dropped after re-check** — rejected findings, `INTENDED` ones with their source, and ones rated below Low, one line each with why (and the corrected fix if the verifier gave one).
5. **Unverified / not checked** — N/A lanes, each lane's "Not checked" and "Unverified" items with what was tried and what would settle each, the scope narrowing if any. No item here is phrased as fact.

In the terminal reply give only the link or path, the verdict line and the top items. Don't fix anything unless the user asks; when they do, fix from the top, one finding at a time, each with a failing test first where one can exist.

## Common mistakes
- Lanes reviewing different scopes → step 1's single file list is mandatory.
- Reporting style nits or "could be cleaner" as bugs → a finding needs a concrete wrong outcome for some input/state/user.
- `CONFIRMED` from reading code only → that's `PLAUSIBLE`. Confirmation means something ran and showed the bug.
- Judging a change only against the variants you remember → step 2c's map comes from the schema.
- Skipping step 2b because "the agents will find it" → a red test is the cheapest true finding there is.
- Words like "probably", "should", "likely", "I assume" in a finding, a severity reason or a rejection → a premise nobody checked. Check it, or move it to Unverified.
- Trusting lane output without step 6 → lanes over-report; verification is what makes the list worth reading.
- "Confirmed" read as "it's a bug" → confirmed only says it happens. Two chips sharing an icon was reproduced five times out of five and was a documented convention; the `Intent check` line, not the reproduction, decides whether it's a finding.
- Giving lanes one sentence of intent → they judge the rest from their own reading and report the author's stated exceptions as bugs. The PR body and commit messages go to every lane and verifier verbatim.
- Ranking a bug that was already on main with the change's own → the deploy verdict blames the change for it. `Caused by this change: no` keeps it visible in its own section.
- Publishing before verification finishes, or listing a finding twice because two lanes worded it differently.
