alter table public.assets
  drop column if exists status;

drop index if exists public.assets_status_idx;
