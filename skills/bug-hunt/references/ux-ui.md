# Lane: UX/UI

**Your question:** when a real person uses the changed screens, does what they see and can do match what the feature promises, in every state — not just the happy path?

## Borders
- In: missing/wrong states (loading, empty, error, success), confusing or wrong copy, layout breaks, actions with no feedback, flows that dead-end, inconsistent behaviour with the rest of the app, design-token/theme violations, i18n gaps.
- Not yours → Accessibility: keyboard, screen readers, focus management, contrast ratios, ARIA, touch target size.
- Not yours → Logic: the data shown is computed wrong (wrong total) — note it under Out of lane.
- Not yours → Performance: slow rendering/loading as such. A missing loading indicator is yours.
- Not yours → Security.

## How to hunt
1. List the screens/components the scope changes and the states each can be in.
2. Read the component and walk each state: initial load, loading, empty, error, success, very long text, many items, narrow phone width, dark/light theme, signed-out, wrong role.
3. Drive the local app when the repo can run it (screenshot only states that look wrong); read the CSS that actually applies rather than guessing layout. What you couldn't see goes under Unverified with how to see it.
4. Compare against the project's reference (approved mockups, design tokens, existing similar screens) when the repo links them.

## Checklist
- **States**: every async load has loading + error UI; empty lists say so; errors tell the user what to do; success is acknowledged.
- **Feedback**: buttons disable/spin while working; double submit prevented in the UI; optimistic updates roll back on failure; polling/refresh doesn't flicker or reset user input.
- **Copy**: matches the product language rules (e.g. translation function used, no hard-coded strings where the app translates); no developer error codes shown raw; numbers/dates/currency formatted the app's way.
- **Layout**: long names/amounts wrap or truncate; nothing overflows at 320–375 px; fixed bars don't cover content (bottom padding); spacing consistent with siblings.
- **Theme/tokens**: colours come from tokens, not literals, where the project requires it; dark themes don't produce invisible text.
- **Navigation**: back button and deep links land in a sensible state; query params preserved where expected; no dead ends after an error.
- **Destructive actions**: confirmed, clearly worded, reversible where promised.
- **Consistency**: the same action looks and behaves like elsewhere in the app.

## Severity hints
User can't complete a core flow or is told something false = High. Confusing but completable = Medium. Cosmetic defect visible to users = Low. Pure taste is not a finding.
