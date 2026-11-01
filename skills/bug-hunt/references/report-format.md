# Lane report format

Every lane returns exactly this shape. Write in English (the main agent translates for the user).

## Severity scale
- **Critical** — money lost or wrongly moved, data of one tenant/user exposed to another, auth bypass, data loss/corruption, or the main flow broken for everyone. Block the deploy.
- **High** — a core flow wrong or blocked for a realistic group of users/inputs, a security hole needing some precondition, a crash on a common path. Fix before deploy.
- **Medium** — wrong behaviour on an edge case, a degraded but workable flow, a noticeable slowdown, an accessibility barrier on a secondary screen. Fix soon.
- **Low** — minor and rare, cosmetic with a real (not stylistic) defect, a cheap hardening. Fix when nearby.

## Confidence
- **confirmed** — you reproduced it: a test that fails, a query result, or the local app showing the wrong state. Give the test path/command and what it showed. Reading code alone, however complete, is never `confirmed`.
- When the mechanism reproduces locally but its precondition exists only in production (which you may not query), it stays `suspect`: put the mechanism's reproduction (command + output) in the Confidence line, name the unverified precondition there, and list it under Unverified with what would settle it.
- **suspect** — the code path is wrong as far as you traced it, but it isn't reproduced yet, or a step couldn't be established here (say which, what you tried, and what would settle it). Not a shortcut for steps you could have checked.

Confidence says the behaviour **happens**. Whether it is **wrong** is a separate question, answered by the `Intent check` line: a behaviour chosen on purpose (spec, PR body, a user decision, a convention the rest of the product follows, a test that asserts it) is not a bug, however reproducible.

## Intent sources
Read, in this order, until one answers whether the behaviour was chosen:
1. The change description you were given (PR body, commit messages) — the author often names the exception.
2. The decisions you were given for this area (spec sections, user decisions in CLAUDE.md/memory).
3. The same behaviour elsewhere in the product (a sibling app, the same component in another place): `grep` for the pattern outside the diff.
4. An existing test that asserts the behaviour.
5. `git log -S'<the exact line>' -- <file>` and the commit message that introduced it.
Name the source you stopped at. "No source found that chooses this behaviour" is a valid answer only after 1–5 were tried.

## Finding block (one per finding)

```
### <N>. <one-line title>
- Severity: Critical | High | Medium | Low
- Confidence: confirmed | suspect — <evidence: test path + command + output, or what was traced and why it isn't reproduced>
- Location: <repo-relative path>:<line>[-<line>] (more lines if the bug spans files)
- What goes wrong: <input/state/user> → <wrong outcome> (expected: <correct outcome>)
- Intent check: <the intent source you stopped at: "PR body says …" / "spec §x says …" / "apps/web Icon.tsx does the same, comment at sports.ts:10" / "no source found after 1–5"> → <why the behaviour still contradicts it, or what it contradicts instead>
- Caused by this change: yes | no — <if no: where it already was, e.g. "same line on main since <sha>" or "<file> is not in the diff">. A clash with what landed on the base branch after the branch was cut counts as yes.
- Reproduce: <the failing test (path) and command, or a query/curl with its output; numbered steps only if neither is possible; local only>
- Fix: <the smallest change that removes the bug; name the function/line>
```

A finding block missing `Intent check` or `Caused by this change` is incomplete and the merger sends it back. When the intent source shows the behaviour was chosen, there is no finding: put it under "Checked and fine" with the source.

## Lane report

```
## Lane: <name>
Scope reviewed: <files actually read>

<finding blocks, most severe first; or "No findings.">

### Hunk ledger
- <path:start-end> — checked | N/A for this lane (<one-line reason>)   ← one line per hunk you were given, none skipped

### Checked and fine
- <one line per risky spot you examined and cleared, with why> (lets the merger drop other lanes' notes about it)

### Out of lane
- <one line per thing noticed that belongs to another lane: lane, file:line, what> (not investigated)

### Unverified
- <a premise you could not establish here: what you tried, what would settle it> (never a guess written as fact)

### Not checked
- <parts of the lane checklist you could not cover, and why>
```

Rules:
- Cite only lines you actually read in this repo; never guess a line number.
- Every premise (what code does, what data exists, how a platform behaves) comes from something you read or ran. If you didn't check it, it goes under Unverified, not into the finding or into "Checked and fine".
- One root cause = one finding, even if it shows in several places (list them all under Location).
- No style opinions, refactors or "consider…" items. If there's no wrong outcome, it isn't a finding.
- No finding without a Reproduce and a Fix. If you can't say how to trigger it, it's an Out of lane note or nothing.
- No finding without an Intent check naming its source. "Expected: …" is your reading of what the code should do; the Intent check is where you showed the author's reading agrees.
