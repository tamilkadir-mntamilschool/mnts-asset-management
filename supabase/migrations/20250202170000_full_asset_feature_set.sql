create sequence if not exists public.asset_code_seq;

create or replace function public.generate_asset_code()
returns text as $$
declare
  next_id bigint;
begin
  next_id := nextval('public.asset_code_seq');
  return 'MNTS-ASSET-' || lpad(next_id::text, 6, '0');
end;
$$ language plpgsql;

alter table public.assets
  add column if not exists asset_code text,
  add column if not exists permanent_owner_id uuid,
  add column if not exists image_paths text[];

update public.assets
set permanent_owner_id = user_id
where permanent_owner_id is null;

update public.assets
set asset_code = public.generate_asset_code()
where asset_code is null;

alter table public.assets
  alter column asset_code set default public.generate_asset_code(),
  alter column asset_code set not null,
  alter column permanent_owner_id set default auth.uid(),
  alter column permanent_owner_id set not null;

create unique index if not exists assets_asset_code_idx on public.assets (asset_code);
create index if not exists assets_permanent_owner_id_idx on public.assets (permanent_owner_id);

create table if not exists public.asset_loans (
  id uuid primary key default gen_random_uuid(),
  asset_id uuid not null references public.assets(id) on delete cascade,
  borrower_id uuid not null,
  checked_out_at timestamptz not null default now(),
  checked_in_at timestamptz,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists asset_loans_asset_id_idx on public.asset_loans (asset_id);
create index if not exists asset_loans_borrower_id_idx on public.asset_loans (borrower_id);
create unique index if not exists asset_loans_active_asset_idx on public.asset_loans (asset_id)
where checked_in_at is null;

drop trigger if exists set_asset_loans_updated_at on public.asset_loans;
create trigger set_asset_loans_updated_at
before update on public.asset_loans
for each row execute function public.set_updated_at();

create table if not exists public.asset_owner_history (
  id uuid primary key default gen_random_uuid(),
  asset_id uuid not null references public.assets(id) on delete cascade,
  owner_id uuid not null,
  changed_at timestamptz not null default now(),
  changed_by uuid
);

create index if not exists asset_owner_history_asset_id_idx on public.asset_owner_history (asset_id);

create or replace function public.log_asset_owner_change()
returns trigger as $$
begin
  if (tg_op = 'INSERT') then
    insert into public.asset_owner_history (asset_id, owner_id, changed_by)
    values (new.id, new.permanent_owner_id, auth.uid());
  elsif (tg_op = 'UPDATE' and new.permanent_owner_id is distinct from old.permanent_owner_id) then
    insert into public.asset_owner_history (asset_id, owner_id, changed_by)
    values (new.id, new.permanent_owner_id, auth.uid());
  end if;
  return new;
end;
$$ language plpgsql;

drop trigger if exists assets_owner_history on public.assets;
create trigger assets_owner_history
after insert or update of permanent_owner_id on public.assets
for each row execute function public.log_asset_owner_change();

insert into public.asset_owner_history (asset_id, owner_id, changed_at, changed_by)
select assets.id, assets.permanent_owner_id, now(), assets.user_id
from public.assets
where not exists (
  select 1 from public.asset_owner_history history where history.asset_id = assets.id
);

alter table public.assets enable row level security;
alter table public.asset_loans enable row level security;
alter table public.asset_owner_history enable row level security;

drop policy if exists "assets_select_own" on public.assets;
drop policy if exists "assets_insert_own" on public.assets;
drop policy if exists "assets_update_own" on public.assets;
drop policy if exists "assets_delete_own" on public.assets;

create policy "assets_select_all"
  on public.assets
  for select
  using (auth.role() = 'authenticated');

create policy "assets_insert_all"
  on public.assets
  for insert
  with check (auth.role() = 'authenticated');

create policy "assets_update_all"
  on public.assets
  for update
  using (auth.role() = 'authenticated')
  with check (auth.role() = 'authenticated');

create policy "assets_delete_all"
  on public.assets
  for delete
  using (auth.role() = 'authenticated');

drop policy if exists "asset_loans_select_all" on public.asset_loans;
drop policy if exists "asset_loans_insert_all" on public.asset_loans;
drop policy if exists "asset_loans_update_all" on public.asset_loans;
drop policy if exists "asset_loans_delete_all" on public.asset_loans;

create policy "asset_loans_select_all"
  on public.asset_loans
  for select
  using (auth.role() = 'authenticated');

create policy "asset_loans_insert_all"
  on public.asset_loans
  for insert
  with check (auth.role() = 'authenticated');

create policy "asset_loans_update_all"
  on public.asset_loans
  for update
  using (auth.role() = 'authenticated')
  with check (auth.role() = 'authenticated');

create policy "asset_loans_delete_all"
  on public.asset_loans
  for delete
  using (auth.role() = 'authenticated');

drop policy if exists "asset_owner_history_select_all" on public.asset_owner_history;
drop policy if exists "asset_owner_history_insert_all" on public.asset_owner_history;

create policy "asset_owner_history_select_all"
  on public.asset_owner_history
  for select
  using (auth.role() = 'authenticated');

create policy "asset_owner_history_insert_all"
  on public.asset_owner_history
  for insert
  with check (auth.role() = 'authenticated');

insert into storage.buckets (id, name, public)
values ('asset-images', 'asset-images', false)
on conflict (id) do nothing;

drop policy if exists "asset_images_read" on storage.objects;
drop policy if exists "asset_images_insert" on storage.objects;
drop policy if exists "asset_images_update" on storage.objects;
drop policy if exists "asset_images_delete" on storage.objects;

create policy "asset_images_read"
  on storage.objects
  for select
  using (bucket_id = 'asset-images' and auth.role() = 'authenticated');

create policy "asset_images_insert"
  on storage.objects
  for insert
  with check (bucket_id = 'asset-images' and auth.role() = 'authenticated');

create policy "asset_images_update"
  on storage.objects
  for update
  using (bucket_id = 'asset-images' and auth.role() = 'authenticated')
  with check (bucket_id = 'asset-images' and auth.role() = 'authenticated');

create policy "asset_images_delete"
  on storage.objects
  for delete
  using (bucket_id = 'asset-images' and auth.role() = 'authenticated');

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  email text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists set_profiles_updated_at on public.profiles;
create trigger set_profiles_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

alter table public.profiles enable row level security;

drop policy if exists "profiles_select_all" on public.profiles;
drop policy if exists "profiles_insert_self" on public.profiles;
drop policy if exists "profiles_update_self" on public.profiles;

create policy "profiles_select_all"
  on public.profiles
  for select
  using (auth.role() = 'authenticated');

create policy "profiles_insert_self"
  on public.profiles
  for insert
  with check (auth.uid() = id);

create policy "profiles_update_self"
  on public.profiles
  for update
  using (auth.uid() = id)
  with check (auth.uid() = id);

create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, full_name, email)
  values (new.id, new.raw_user_meta_data->>'full_name', new.email)
  on conflict (id) do update
    set full_name = excluded.full_name,
        email = excluded.email;
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

insert into public.profiles (id, full_name, email)
select id, raw_user_meta_data->>'full_name', email
from auth.users
on conflict (id) do update
  set full_name = excluded.full_name,
      email = excluded.email;
