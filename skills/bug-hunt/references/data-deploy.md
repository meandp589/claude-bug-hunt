# Lane: Data & Deploy

**Your question:** when this change ships to production — with real existing data, the old code still running for a while, and the deploy config as it is — does it apply cleanly and keep working, and is there a way back?

## Borders
- In: migrations and schema changes, backfills, deploy order between code and schema, compatibility with the version still running during the rollout, env vars/secrets/cron/queues the code needs, CI/CD and deploy config (pipelines, Dockerfiles, IaC, platform config such as `wrangler.toml` or `vercel.json`), rollback.
- Not yours → Logic: the new code computes the wrong result once deployed.
- Not yours → Security: grants, row-level policies, secrets exposed, CI permissions an attacker can use — note them under Out of lane.
- Not yours → Performance: a slow query as such. A backfill or index build that locks a big table during deploy is yours.

## How to hunt
1. List what production has now (the base branch's migrations, config and the code that's live) and what this change adds or alters.
2. Walk the deploy in order: migration applied with old code still running, then new code with the migrated DB; then a rollback of the code with the migration kept.
3. Judge against the local DB you were given ("You may run" says which migrations it has applied, and your Automated check results include the merged-tree run when the branch is behind its base). Test old rows inside a rolled-back transaction. Don't apply migrations or reset the DB yourself: put the exact command you need in your report, and the main agent runs it.

## Checklist
- **Migration order**: a migration version older than one already on the base branch (or applied in production) — many tools refuse it on deploy (e.g. `supabase db push` fails with `DbPushMissingRemoteError`) and a fresh reset runs it in a different order than production did.
- **Old code, new schema (and the reverse)**: old code or cached clients still reading a dropped/renamed column, or calling an old function/endpoint signature; new code reading a column the migration hasn't created yet when code ships first.
- **Destructive steps**: drop column/table, narrowing a type, a backfill that overwrites — is the data needed anywhere, is there a way back?
- **Existing data**: a constraint or `not null` added over rows that violate it; a default that is wrong for old rows; an enum value removed while rows still hold it.
- **Locks and duration**: a backfill, index build or table rewrite that locks a big table during the deploy.
- **Config the code needs**: env vars, secrets, cron schedules, queues or bindings the new code reads that the deploy config (or each environment's) doesn't set; a renamed variable still set under its old name.
- **CI/CD and infra**: pipeline steps that no longer run the checks they did, a build that now ships different files, a Dockerfile or platform config change that alters the runtime (version, entry point, region, memory/CPU limits).
- **Rollback**: can the previous release run against the migrated DB? If not, say what would have to happen to roll back.

## Severity hints
A deploy that fails, or data lost or corrupted on deploy = Critical. Production broken during the rollout window, or no way back from a destructive step = High. A config gap with a visible error and an easy fix = Medium. A missing rollback note for a reversible change = Low.
