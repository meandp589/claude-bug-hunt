# Lane: Security

**Your question:** can someone who shouldn't — an anonymous visitor, another tenant, another customer, a lower role, a forged webhook — read, change, spend or break something because of this code?

## Borders
- In: anything an **untrusted actor can exploit on purpose**.
- Not yours → Logic: wrong results for legitimate users with honest input (a rounding bug, a race between two honest requests) unless an attacker can steer it for gain — then it's yours.
- Not yours → Performance: slowness in general. A cheap request that makes the server do unbounded work (DoS) is yours.
- Not yours → UX/UI, Accessibility.
- Deep audits: if your prompt gives the path of an installed security-audit skill, its reference files cover specific classes in depth; read only the one you need.

## How to hunt
1. List every **entry point** the scope touches: HTTP routes, RPC/DB functions callable by clients, webhooks, cron, file uploads, URL params, postMessage/localStorage reads.
2. For each, write who can call it and what it trusts from the caller. Then follow each caller-controlled value to where it is used.
3. Ask at each use: who checked this, against what, on the server?

## Checklist
- **AuthN/AuthZ**: every write/read checks the caller on the server; role and tenant come from the session, never from a parameter; no "client hides the button" as the only guard.
- **Tenant/row isolation**: row-level policies present and correct for new tables/columns; functions that bypass them (e.g. Postgres `security definer`, a service-role/admin key) re-check the caller; no id taken from the client to pick whose data (IDOR).
- **Grants**: new tables/functions/columns not granted wider than needed (anon vs authenticated vs service role); revoked functions not re-granted by a recreate.
- **Injection**: SQL built from strings, dynamic identifiers, `eval`/`Function`, shell commands, HTML built from user text (`dangerouslySetInnerHTML`, email/chat message templates), header/redirect values.
- **Open redirect / SSRF**: redirect targets and fetched URLs from user input must be allow-listed by origin.
- **Webhooks and signatures**: signature checked on the raw body before parsing; replay/idempotency; account/tenant taken from the signed event, not metadata.
- **Secrets and personal data**: no keys in client bundles, logs, error reports, URLs, or tables readable by anon; no personal data (emails, phone numbers, tokens, payment details) newly written to logs, analytics or error reports; tokens compared in constant time where it matters.
- **Uploads**: type/size checked before reading the body; decoded sizes bounded; stored under server-chosen keys; served with safe content type.
- **Money/quotas abuse**: can a user repeat, replay or race a request to get something twice (double refund, double credit, coupon reuse)? Rate limits on OTP, login, email sending.
- **Sessions**: sign-out/password change actually revokes; tokens bound to the right audience; no session fixation from URL params.
- **Dependencies**: each package the change adds or upgrades (diff the manifests and lockfiles): is it the intended package (typosquats), does it run install scripts, does the repo's audit tool (`npm audit`, `pnpm audit`, `pip-audit`, `osv-scanner`) report a known vulnerability in the new versions, did the lockfile change in ways the manifest change doesn't explain?
- **CI/CD**: workflow permissions widened, secrets exposed to pull requests from forks (`pull_request_target` with a checkout of the PR head), unpinned third-party actions, untrusted input (PR titles, branch names) interpolated into shell steps.
- **Client-side**: XSS sinks, `target=_blank` without `rel`, framing, sensitive data in localStorage, postMessage without origin check.

## Severity hints
Cross-tenant read/write or auth bypass = Critical. Needs a stolen token or an insider role = High. Info leak of non-sensitive metadata = Medium/Low.
