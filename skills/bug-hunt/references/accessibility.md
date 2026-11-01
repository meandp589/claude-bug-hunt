# Lane: Accessibility

**Your question:** can someone using only a keyboard, a screen reader, zoom, or with low vision or motor limits use the changed screens?

## Borders
- In: keyboard operability, focus order and visibility, focus management in dialogs/sheets, semantic elements and names, ARIA correctness, live announcements, contrast, text resize/zoom, touch target size, reduced motion, form labels and error association, language attributes.
- Not yours → UX/UI: missing states, copy, layout for sighted mouse users, general consistency.
- Not yours → Logic, Security, Performance.

## How to hunt
1. List interactive elements the scope adds or changes (buttons, links, inputs, custom controls, dialogs, toasts, tabs, menus).
2. For each, check in code: element type, accessible name, keyboard path, focus behaviour, state exposure.
3. If the app runs locally, an accessibility snapshot (e.g. Playwright `browser_snapshot`) or tabbing through is the evidence for `confirmed`; get it whenever the repo can run the app. Screen-reader behaviour you couldn't observe goes under Unverified.

## Checklist (WCAG 2.2 AA as the bar)
- **Semantics**: clickable `div`/`span` instead of `button`/`a`; links used as buttons or vice versa; headings in order; lists as lists; tables with headers.
- **Names**: icon-only buttons have `aria-label`; inputs have a `<label>` (placeholder is not a label); images have meaningful `alt` or `alt=""` if decorative.
- **Keyboard**: everything reachable and operable with Tab/Enter/Space/Esc/arrows as the pattern expects; no keyboard trap; custom controls handle keys; `tabIndex` > 0 not used.
- **Focus**: visible focus ring (not removed by `outline: none` without a replacement); dialogs move focus in, trap it, return it on close; focus not lost after an item is removed or a route changes.
- **Dynamic content**: toasts/status changes/validation errors announced (`aria-live`, `role=status/alert`); loading state exposed (`aria-busy` or text); polling updates don't steal focus.
- **Forms**: errors tied to fields (`aria-describedby`, `aria-invalid`); required fields marked beyond colour.
- **Contrast**: text ≥ 4.5:1 (≥ 3:1 large), UI component borders/icons ≥ 3:1, in every theme the app ships; information never by colour alone.
- **Size and zoom**: touch targets ≥ 24×24 CSS px (44 preferred on mobile); layout survives 200% zoom/text resize without loss; no fixed heights clipping text.
- **Motion**: animations respect `prefers-reduced-motion`; nothing flashes.
- **Language**: `lang` set correctly, especially when the page switches languages.

## Severity hints
A core flow impossible by keyboard or screen reader = High. A barrier on a secondary screen or missing announcement = Medium. Minor naming/contrast slip on decorative text = Low.
