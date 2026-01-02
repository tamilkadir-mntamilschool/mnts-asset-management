# UI Actions (Agent-Friendly)

## Scope
- Mobile-first app experience.
- Auth-first entry: landing page becomes sign-in; signed-in users land on app.
- Improve color scheme for modern, readable, appealing UI.

## Navigation + Layout
- Replace the current landing page with a mobile-optimized sign-in screen.
- Route `/` to the auth page; on successful sign-in, redirect to `/assets`.
- Add a persistent mobile navigation pattern so primary screens are reachable on small screens.
- Rework the assets list into mobile cards with label/value pairs; avoid multi-column tables on mobile.
- Make primary actions sticky on mobile (e.g., “New Asset”, search/filter controls).

## Forms + Accessibility
- Add explicit labels for auth inputs and core form fields (avoid placeholder-only inputs).
- Improve empty states with a clear CTA to create the first asset.
- Add visible filter chips or summaries near results with a quick “clear all” action.

## Visual + Color System
- Lighten the dark base background to avoid crushed contrast; use a softer near-black base.
- Increase contrast for secondary text; ensure body copy is comfortably readable on mobile.
- Introduce a single accent hue for primary actions (modern, neutral, no purple bias).
- Strengthen status colors for Operational / Needs Service / Offline with distinct, readable hues.
- Add subtle depth via a low-contrast gradient or noise texture for the background.
- Enhance focus/hover states for touch use (clearer outlines or background tints).

