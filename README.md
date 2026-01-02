# MNTS Asset Management

Web app for tracking MNTS assets, ownership, and loans. Built with Vue 3 + TypeScript + Vite, Tailwind, shadcn-vue, and Supabase.

## Project Structure

- `apps/web/`: frontend app
- `supabase/`: schema, migrations, and seed data
- `scripts/`: helper scripts

## Prerequisites

- Node.js 18+ (or the repo default)
- Supabase project (URL + anon key)

## Setup

```sh
cd apps/web
npm install
```

Create `.env` in `apps/web/`:

```env
VITE_SUPABASE_URL=your-supabase-url
VITE_SUPABASE_ANON_KEY=your-supabase-anon-key
```

Run the dev server:

```sh
npm run dev
```

## Scripts

From `apps/web/`:

- `npm run dev`
- `npm run build`
- `npm run lint`
- `npm run preview`

## Supabase

- Migrations live in `supabase/migrations/`
- Seed data is in `supabase/seed/`
- Storage bucket: `asset-images`

## Deployment (Vercel)

- Build output: `apps/web/dist`
- Env vars: `VITE_SUPABASE_URL`, `VITE_SUPABASE_ANON_KEY`

## Notes

- See `PRODUCT_PLAN.md` and `IMPLEMENTATION_PLAN.md` for roadmap details.
- Current gaps are tracked in `GAP_ANALYSIS.md`.
