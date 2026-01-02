# Agents Guide

## Project

mnts-asset-management is a web app for asset management. The stack is Vue 3 + TypeScript + Vite on the frontend, Tailwind CSS with shadcn-vue for UI, and Supabase (Postgres/Auth/Storage) for the backend. Deploy the frontend to Vercel.

## Expected Structure

- Frontend app lives in `apps/web/`.
- Shared UI components (if extracted) live in `packages/ui/`.
- Supabase schema, migrations, and seeds live in `supabase/`.

## Conventions

- Prefer Vue SFCs with `<script setup lang="ts">`.
- Keep UI components in `apps/web/src/components/` and page-level views in `apps/web/src/pages/`.
- Use Tailwind utility classes for layout and spacing; use shadcn-vue components when possible.
- Keep Supabase access through a single client module (for example `apps/web/src/lib/supabase.ts`).
- Do not commit secrets. Use `.env` locally and keep `.env.example` in repo.

## Current Implementation Notes

- Auth uses Supabase Google OAuth only; see `apps/web/src/pages/Auth.vue` and `apps/web/src/stores/session.ts`.
- Core asset flows live in `apps/web/src/pages/Assets.vue`, `apps/web/src/pages/AssetCreate.vue`, `apps/web/src/pages/AssetDetail.vue`, and `apps/web/src/pages/AssetPrint.vue` (including QR code generation and QR scan filtering).
- Supabase schema includes `assets`, `asset_loans`, `asset_owner_history`, and `profiles` plus the `asset-images` storage bucket with authenticated-only policies.
- RLS policies currently allow all authenticated users to read/write assets, loans, and owner history.

## Local Development (expected)

1) Install deps in `apps/web/`.
2) Run the dev server with `npm run dev` (or the repo's package manager).
3) Use Supabase project keys in `.env`:
   - `VITE_SUPABASE_URL`
   - `VITE_SUPABASE_ANON_KEY`

## Database Changes

- Add SQL migrations under `supabase/migrations/`.
- Keep Row Level Security (RLS) policies explicit and minimal.
- Seed data (if needed) goes in `supabase/seed/`.

## Deployment Notes

- Vercel build output should be `apps/web/dist`.
- Ensure Vercel env vars mirror the local `.env` keys.
