# Lane: Logic & Edge cases

**Your question:** for an honest user with valid-but-unusual input or state, does the code do what it promises — the right numbers, the right state, every time?

## Borders
- In: wrong results, wrong state transitions, crashes, data corruption, races between honest requests, broken contracts between layers (web ↔ API ↔ DB).
- Not yours → Security: anything that needs a malicious actor to trigger or profit.
- Not yours → UX/UI: the result is correct but presented confusingly. If the screen shows a **wrong value** (wrong total, stale status), that's yours.
- Not yours → Performance: correct but slow.
- Not yours → Data & Deploy: migrations, deploy order, old code against the new schema, config the deploy must set. When that lane is N/A for the scope, these are yours.

## How to hunt
1. Write the change's promise as invariants ("a slot is never booked twice", "paid = sum of approved payments", "status only moves forward").
2. For every branch in the diff, ask what input/state takes the other side of it, and whether that side is handled.
3. Trace each changed value to every reader: who else reads this column/field/prop and does the new meaning break them?

## Checklist
- **Boundaries**: 0, 1, max, empty list/string, null/undefined, missing optional field, exactly-at-limit vs one-over, negative.
- **Money and units**: integer minor units only, no float math; rounding direction; currency/unit mixing; totals that must match parts.
- **Time**: time zones (UTC vs local date), DST, midnight/day boundaries, end-exclusive ranges, "now" captured once vs repeatedly, expiry exactly at the instant.
- **State machines**: every status transition allowed/blocked as intended; terminal states stay terminal; an action on an already-cancelled/expired/paid record.
- **Concurrency**: two requests at once (double click, two tabs, webhook + cron), check-then-act without a lock or constraint, retries that are not idempotent, ordering of async effects, stale closures/state in React effects.
- **Error paths**: what happens after a partial failure (half the writes done), a thrown error inside a loop, a rejected promise not awaited, a network error the UI swallows.
- **Observability**: a failure on a changed path that is caught and dropped with no log, metric or error report; logging or error reporting the change removed from a failure path; a failure logged at a level that production filters out.
- **Contracts**: renamed/removed field still read elsewhere; changed function signature with old callers; DB function parameters vs the client's call; enum/status lists that must match in several places; for a library or public API, a breaking change shipped without the version bump or changelog entry its consumers rely on.
- **Docs that now lie**: a README, CLAUDE.md, API doc or code comment in the repo that states a command, option or behaviour this change altered.
- **Data shapes**: legacy rows (nulls, old formats) the new code assumes away; arrays assumed non-empty; ids assumed to exist.
- **Copy-paste and inversion**: wrong variable, inverted condition, `<` vs `<=`, `&&` vs `||`, a filter that should exclude a kind but doesn't.
- **Migrations and deploy order**: only when the Data & Deploy lane is N/A — then use its checklist (`data-deploy.md`).
- **Tests that can't fail**: a new test whose assertion matches the default state (passes before the code runs) — report as Low with the reason.

## Severity hints
Money or data wrong for real users = Critical/High. A core flow wrong on a realistic edge = High. Rare edge with a workaround = Medium/Low.
