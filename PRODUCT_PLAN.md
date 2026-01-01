# Asset Management Web App Product Plan

## Overview
Build a web-based asset management system for a nonprofit promoting Tamil culture in Minnesota. The system will track event equipment, cultural artifacts, musical instruments, and decor. It will support a core team of ~30 and rotating members (~200), with strong accountability, conservation tracking, and Google Workspace integration.

## Goals
- Protect and preserve culturally significant assets.
- Simplify event preparation and returns.
- Improve accountability with clear custody history.
- Integrate with existing Google Workspace workflows.
- Use AI-assisted development to accelerate delivery and improve UX.
- Provide audit-ready custody history for donors and boards.

## Non-Goals (for MVP)
- Full accounting and depreciation schedules.
- Multi-organization tenancy.
- IoT sensor integrations.

## Users and Roles
- Admin: full access, manage roles, settings, and approvals.
- Core Team: create events, manage inventory, approve checkouts.
- Rotating Members: request/checkout assets, view assigned items.
- Auditors/Board: read-only access.

## Key Asset Types and Attributes
- General Equipment: serial number, warranty details.
- Artifacts: provenance, cultural significance, handling rules.
- Instruments: storage conditions and handling notes.
- Decor: condition notes, set usage, photos.

## MVP Scope (Phase 1)
### Inventory and Catalog
- Create/edit assets with photos and metadata.
- Categories and tags for asset types.
- Storage location tracking.

### Event-Based Checkout
- Create events and kits (asset bundles).
- Check-out/check-in with time bounds.
- Return checklist and condition notes.

### Custody and Audit
- Assignment history (who/when/where).
- Immutable activity log.

### Google Workspace Integration
- Google SSO for authentication.
- Attach Drive files (photos, receipts, appraisals).
- Calendar reminders for returns.


## Phase 2 Enhancements
- Donor and grant tracking (restrictions, acknowledgements).
- Asset valuation and appraisal history.
- QR/barcode scanning via mobile camera.
- Offline mode for event check-ins.
- Multi-language labels (Tamil/English).

## Data Model (High-Level)
- Users, Roles, Permissions
- Assets, Categories, Tags
- Locations
- Events
- Checkouts (assignments)
- Attachments (Drive links)
- AuditLog

## Key Workflows
1. Admin sets up categories, locations, roles.
2. Core team adds assets and photos.
3. Event created with kit list.
4. Members request checkout; core team approves.
5. Check-in after event with condition updates.
6. Returns verified and logged.

## UX Principles
- Mobile-first for event use.
- Minimal steps for checkout/check-in.
- Clear status indicators (location, custodian, condition).

## Success Metrics
- >90% assets have complete metadata and photos.
- <5% overdue returns after 30 days.
- Reduced time to prepare event kits by 50%.

## Risks and Mitigations
- Rotating members forget returns: automated reminders and approvals.
- Artifact damage: enforce condition check-in and handling notes.
- Adoption gaps: simple UI and short onboarding guide.

## AI-Assisted Delivery Plan (Target MVP ~4 Weeks)
### Week 1: Discovery and Design
- Finalize MVP scope and user roles.
- Define data model and key workflows.
- Produce wireframes and UX flows.
- Set up repository, CI, and baseline architecture.

### Week 2: Core Build
- Implement inventory, locations, and asset catalog.
- Build event creation and kit management.
- Add check-in/out with basic audit logs.

### Week 3: Quality and Integration
- Implement Google SSO and Drive attachments.

### Week 4: Hardening and Pilot
- Add reminders and notifications.
- Improve admin tools.
- Run pilot event, capture feedback, fix issues.

## AI Usage Approach
- Product discovery: generate user stories, edge cases, and workflow maps.
- Design: create wireframes and UX copy, iterate quickly with feedback.
- Engineering: scaffold services, data models, and CRUD flows.
- QA: draft test cases and automated checks for key workflows.
- Docs: produce onboarding guides and admin runbooks.

## MVP Requirements Checklist
- Authentication with Google SSO.
- User roles: admin, core team, rotating members, read-only.
- Asset catalog: create/edit, photos, categories, tags, locations.
- Event management: create events, add kits, assign assets.
- Check-out/check-in with timestamps and condition notes.
- Custody history and immutable audit log.
- Drive attachments for receipts, photos, appraisals.
