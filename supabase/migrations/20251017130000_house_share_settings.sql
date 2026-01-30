-- House share settings for Casa scrigno

create table if not exists public.house_share_settings (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  campanello_hinoo_id uuid not null,
  share_mode text not null check (share_mode in ('honoo', 'hinoo', 'conversations')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists house_share_settings_owner_id_key
  on public.house_share_settings (owner_id);

create unique index if not exists house_share_settings_campanello_hinoo_id_key
  on public.house_share_settings (campanello_hinoo_id);

alter table public.house_share_settings enable row level security;

drop policy if exists "House share select own" on public.house_share_settings;
drop policy if exists "House share insert own" on public.house_share_settings;
drop policy if exists "House share update own" on public.house_share_settings;
drop policy if exists "House share delete deny" on public.house_share_settings;

create policy "House share select own"
  on public.house_share_settings
  for select
  using (auth.uid() = owner_id);

create policy "House share insert own"
  on public.house_share_settings
  for insert
  with check (auth.uid() = owner_id);

create policy "House share update own"
  on public.house_share_settings
  for update
  using (auth.uid() = owner_id)
  with check (auth.uid() = owner_id);

create policy "House share delete deny"
  on public.house_share_settings
  for delete
  using (false);

drop trigger if exists set_house_share_settings_updated_at
  on public.house_share_settings;

create trigger set_house_share_settings_updated_at
  before update on public.house_share_settings
  for each row execute function public.set_updated_at();
