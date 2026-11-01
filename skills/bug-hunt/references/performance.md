# Lane: Performance

**Your question:** does this change make something measurably slower, heavier or more expensive for real data sizes and real devices — or will it, as data grows?

## Borders
- In: query cost (N+1, missing index, full scans, unbounded result sets), wasteful network calls (duplicate fetches, polling too often, no cleanup), React re-render storms, heavy work on the main thread, bundle size and lazy loading, memory leaks (listeners/intervals not cleared), serverless/edge CPU, memory and subrequest limits, cron batches that grow without bound.
- Not yours → Security: a cheap request an attacker can abuse to exhaust the server (DoS) — note it under Out of lane.
- Not yours → Logic: a leak or race that produces wrong results; the timer that fires on an unmounted component and sets wrong state is Logic, the timer that keeps polling forever is yours.
- Not yours → UX/UI (missing loading state), Accessibility.

## How to hunt
1. For each changed data access, find rows touched at realistic scale (count them in the local DB / seed, and say what production size you used and where that number comes from, e.g. a busy tenant after a year) and how often it runs (per request, per render, per minute).
2. For each changed effect/timer/listener/subscription, find its cleanup and its trigger frequency.
3. Measure: `EXPLAIN (ANALYZE)` on the local DB, a bundle size check, counting requests in the network panel or a test. A number you couldn't measure goes under Unverified with how to measure it, never as fact.

## Checklist
- **DB**: query inside a loop (N+1); filters/joins/order-by on unindexed columns of big tables; `select *` of wide rows; missing `limit`/pagination; per-row function calls in policies or views that scan; locks held across slow work; triggers that fan out.
- **Network**: same data fetched by several components; refetch on every render/focus; polling interval too short or never stopped (hidden tab, unmounted, finished state); no request de-dup/abort on fast navigation; large payloads where a count would do.
- **React/web**: effects with missing/unstable deps causing loops; new objects/functions in props defeating memo on large lists; long lists without virtualisation; heavy computation in render; images without size/lazy loading; new large dependency or a static import that should be lazy.
- **Memory/cleanup**: `setInterval`/`setTimeout`/listeners/subscriptions without cleanup; caches without bounds.
- **Server/Worker**: CPU-heavy work per request; sequential awaits that could be parallel; unbounded batch sizes in cron; outbound calls without timeouts.

## Severity hints
A core page or endpoint that will time out or cost real money at expected scale = High. Noticeable slowdown or wasted calls on a common path = Medium. Micro-optimisation with no user-visible effect is not a finding.
