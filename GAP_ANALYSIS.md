# Gap Analysis (Product + Implementation Plans)

This document records gaps between current implementation and the stated plans in `PRODUCT_PLAN.md` and `IMPLEMENTATION_PLAN.md`.

## Product Plan Gaps

- Roles/permissions model (admin/core/rotating/read-only) not implemented; no role-based access control in UI or backend.
- Events, kits, and event-based checkout/check-in workflows are not implemented.
- Return checklist and condition tracking are not implemented.
- Audit log is not implemented; custody history is limited to asset loan and owner history.
- Google Workspace integrations are not implemented (Drive attachments, Calendar reminders).
- Tags, dedicated categories/locations entities, and richer asset attributes (provenance, handling rules, etc.) are not implemented.

## Implementation Plan Gaps

- Phase 2 auth UI only supports Google OAuth; email/password flows are not wired.
- Phase 3 data model is partial; missing categories/tags/locations/events tables; RLS is broad (authenticated-only).
- Phase 4 UX validation uses no Zod schemas; pagination not present.
- Phase 5 testing/QA coverage not present.
- Phase 6 deployment steps are not documented/verified (Vercel settings, env).
