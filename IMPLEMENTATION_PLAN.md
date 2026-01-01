# Implementation Blueprint

This plan is a step-by-step blueprint for agents to implement the app with Vue 3 + TS, shadcn-vue + Tailwind, Supabase, and Vercel.

## Assumptions

- Frontend in `apps/web/`.
- Supabase project exists (free tier).
- Use Vite + Vue 3 + TS.

## Roles (suggested)

- Frontend agent: UI, routing, state, forms, and Supabase client integration.
- Backend agent: Supabase schema, RLS, auth providers, and seed data.
- QA agent: tests, validation, and deployment checks.

## Phase 0: Project Initialization

Deliverables
- Vite app scaffolded in `apps/web/`.
- Tailwind configured and verified.
- shadcn-vue installed and first component generated.

Tasks
- Create app scaffold and add dependencies.
- Set up Tailwind config and base styles.
- Add shadcn-vue and generate a button/input component.

Exit criteria
- `npm run dev` works.
- Tailwind utilities render in a test page.

## Phase 1: App Foundation

Deliverables
- App shell with layout, navigation, and router.
- Base design tokens (Tailwind config and CSS variables).

Tasks
- Add Vue Router and Pinia.
- Create main layout and navigation shell.
- Establish `src/styles/` and theme variables.

Exit criteria
- Routes render correctly and shared layout loads.

## Phase 2: Authentication + Supabase Client

Deliverables
- Supabase client module and env config.
- Auth flow (sign in, sign up, sign out).

Tasks
- Add `.env.example` and load `VITE_SUPABASE_URL` + `VITE_SUPABASE_ANON_KEY`.
- Create `src/lib/supabase.ts` client.
- Build auth views and session store.

Exit criteria
- User can sign up, sign in, sign out.

## Phase 3: Data Model and RLS

Deliverables
- Initial schema and RLS policies.
- CRUD for core asset records.

Tasks
- Create tables (assets, categories, locations, etc).
- Add RLS policies for per-user access.
- Create CRUD screens and forms.

Exit criteria
- Authenticated users can read/write their data only.

## Phase 4: UX and Workflow

Deliverables
- Core asset workflows implemented.
- Validation, loading states, and empty states.

Tasks
- Build list/detail/create/edit flows.
- Add filters, search, and pagination.
- Add Zod schemas for form validation.

Exit criteria
- Common workflows are complete and stable.

## Phase 5: Testing and QA

Deliverables
- Basic test coverage and manual QA checklist.

Tasks
- Add unit tests for stores and utilities.
- Add smoke tests for auth and CRUD.
- Run manual QA on main flows.

Exit criteria
- All tests pass; no critical bugs in core flows.

## Phase 6: Deployment

Deliverables
- Vercel deployment with env vars configured.

Tasks
- Configure Vercel build settings.
- Add env vars in Vercel dashboard.
- Verify production build and auth.

Exit criteria
- Production site loads; auth and CRUD work.

## Milestones

- M1: Frontend scaffold + Tailwind + shadcn-vue.
- M2: App shell + routing + state.
- M3: Auth working end-to-end.
- M4: CRUD + RLS complete.
- M5: UX polish and testing.
- M6: Deployed on Vercel.

## Definition of Done

- Core asset flows complete.
- RLS policies in place.
- Vercel deployment live.
- Docs updated in `TECH_STACK.md` and `AGENTS.md`.
