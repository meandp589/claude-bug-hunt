# Shared harnesses: worktrees and the local DB

Read this when any lane or verifier may run e2e tests or touch a local database. Agents that only read code or run self-contained unit tests can share the checkout and skip it.

## Parallel agents must not share an e2e harness
E2E harnesses usually keep state in the checkout (server pid files, env files, `test-results/`) and their teardown kills "their" servers, so two agents running e2e in one checkout break each other's runs (seen: one run's teardown killed another's Vite). Any agent that may run e2e gets its own git worktree with its own ports.

- The main agent creates it (`git worktree add --detach <scratchpad>/wt-<agent> <the scope's head commit>`) and passes its path as `Repo:` — not the Agent tool's `isolation: "worktree"`, which is created at launch from the current checkout and can't be prepared first.
- A worktree starts from a commit, so when the scope includes uncommitted or untracked changes, carry them in (`git diff HEAD | git -C <wt> apply`, then copy the untracked files from step 1) and check `git -C <wt> status` shows the same changes.
- The prompt says how to finish preparing it (install deps, copy the gitignored env files, build steps) and the exact narrow command (e.g. Playwright needs `--project <name>` as well as `-g`, or project dependencies pull in the whole suite).
- Installing dependencies in every worktree is slow; give a worktree only to the agents that will run e2e, and let the rest share the checkout.
- Record each worktree path; step 10 removes them.

## The shared local DB is the same kind of harness
- First find whose database is running (e.g. `docker ps` container names usually carry a project id or compose project name; compare with this checkout's config). Reset or migrate only a database this hunt started, or this checkout's own when no other session is using it; worktrees of one repo usually share the same project id, so when you can't tell whose it is, treat it as another session's.
- When the running database belongs to another checkout or session, start an isolated one for the hunt (the repo's instructions may say how; otherwise a copy of its DB config with a new project name and free ports — e.g. Supabase: copy `supabase/config.toml` with a new `project_id` and ports, symlink `migrations` and `seed.sql`, `SUPABASE_WORKDIR=<dir> supabase start`; Docker Compose: `docker compose -p <new name>` with remapped ports), point every lane at its DB URL, and stop it at the end.
- Tools that mount the checkout into Docker need it under a path the Docker VM can mount (often under `~`, not the system temp dir); otherwise run the test files through `docker exec`.
- Anything that resets, reseeds or migrates it (a DB reset, the full DB test suite, applying migrations) is run only by the main agent, one at a time: in step 3, or after the lanes/verifiers of a step have all returned.
- Lanes and verifiers run only narrow tests that leave shared state as they found it (a DB test inside `begin; … rollback;`); a check that needs a reset goes in their report as the exact command to run, and the main agent runs it once the step's agents have returned.
