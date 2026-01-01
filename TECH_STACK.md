# Tech Stack

## Overview

- Frontend: Vue 3 + TypeScript + Vite
- UI: shadcn-vue + Tailwind CSS
- State: Pinia
- Routing: Vue Router
- Forms/Validation: Vee-Validate + Zod
- Backend: Supabase (Postgres + Auth + Storage)
- Hosting: Vercel (Vite build output)
- Auth: Supabase Auth
- Data access: Supabase JS client

## Repo Structure

```
repo/
  apps/
    web/
      src/
        assets/
        components/
        composables/
        layouts/
        pages/
        router/
        stores/
        styles/
        types/
        utils/
      public/
      .env.example
      index.html
      package.json
      tailwind.config.ts
      tsconfig.json
      vite.config.ts
  packages/
    ui/
      src/
        components/
        styles/
      package.json
      tailwind.config.ts
      tsconfig.json
  supabase/
    migrations/
    seed/
    config.toml
  scripts/
  .gitignore
  README.md
```

## Setup Checklist

1) Frontend
- Create Vite + Vue + TS app.
- Install Tailwind CSS and configure `tailwind.config.ts`.
- Install shadcn-vue and generate components into `apps/web/src/components`.
- Add Pinia and Vue Router.
- Add Vee-Validate and Zod.

2) Supabase
- Create a Supabase project (free tier).
- Capture `SUPABASE_URL` and `SUPABASE_ANON_KEY`.
- Set up tables and RLS policies.
- Add auth providers (email/password and any OAuth).

3) Environment
- Add `.env.example` and `.env` in `apps/web/` with Supabase keys.
- Use `import.meta.env` in the frontend.

4) Vercel
- Connect repo to Vercel.
- Set build command: `pnpm --filter web build` or `npm run build`.
- Set output directory: `apps/web/dist`.
- Add `SUPABASE_URL` and `SUPABASE_ANON_KEY` as Vercel env vars.

5) Local validation
- Run `pnpm --filter web dev` (or `npm run dev`).
- Verify auth, CRUD, and RLS.
