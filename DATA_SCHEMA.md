# Data Schema (High-Level)

## Users
- id
- name
- email
- role_id
- status (active/inactive)
- created_at
- updated_at

## Roles
- id
- name (admin, core_team, rotating_member, read_only)
- permissions (list or JSON)
- created_at
- updated_at

## Assets
- id
- name
- description
- category_id
- tag_ids (list)
- location_id
- serial_number (optional)
- acquisition_date
- acquisition_source (donation/purchase/grant)
- valuation (optional)
- cultural_significance (optional)
- handling_notes (optional)
- photos (list of attachment ids)
- status (available/checked_out/retired)
- created_by
- created_at
- updated_at

## Categories
- id
- name
- description
- created_at
- updated_at

## Tags
- id
- name
- created_at
- updated_at

## Locations
- id
- name
- address (optional)
- notes (optional)
- created_at
- updated_at

## Events
- id
- name
- description (optional)
- start_date
- end_date
- location_id (optional)
- created_by
- created_at
- updated_at

## EventKits
- id
- event_id
- name
- notes (optional)
- created_at
- updated_at

## EventKitItems
- id
- event_kit_id
- asset_id
- quantity (default 1)
- notes (optional)
- created_at
- updated_at

## Checkouts
- id
- asset_id
- event_id (optional)
- checked_out_by (user id)
- assigned_to (user id, optional)
- checked_out_at
- due_back_at
- checked_in_at (optional)
- condition_out (optional)
- condition_in (optional)
- notes (optional)
- status (open/closed/overdue)
- created_at
- updated_at

## Attachments
- id
- asset_id (optional)
- maintenance_task_id (optional)
- condition_log_id (optional)
- checkout_id (optional)
- drive_file_id
- file_name
- file_type
- created_by
- created_at

## AuditLog
- id
- actor_id
- entity_type
- entity_id
- action
- before_state (optional JSON)
- after_state (optional JSON)
- created_at
