

create table if not exists public."case" (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  campanello_hinoo_id uuid not null,
  created_at timestamptz not null default now()
);

alter table if exists public."case"
  drop column if exists campanello_id,
  add column if not exists campanello_hinoo_id uuid;

alter table if exists public."case"
  alter column campanello_hinoo_id set not null;

create unique index if not exists case_owner_id_key
  on public."case" (owner_id);

create unique index if not exists case_campanello_hinoo_id_key
  on public."case" (campanello_hinoo_id);

create table if not exists public.house_invites (
  id uuid primary key default gen_random_uuid(),
  email text,
  user_id uuid references auth.users(id),
  invited_by uuid not null references auth.users(id),
  status text not null check (status in ('pending', 'accepted')),
  created_at timestamptz not null default now()
);

create index if not exists house_invites_user_id_idx
  on public.house_invites (user_id);

create index if not exists house_invites_email_idx
  on public.house_invites (email);

alter table public."case" enable row level security;
alter table public.house_invites enable row level security;

alter table if exists public.users
  add column if not exists auth_user_id uuid,
  add column if not exists is_admin boolean not null default false;

do $$
begin
  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'users'
      and column_name = 'auth_id'
  ) then
    execute 'update public.users set auth_user_id = auth_id where auth_user_id is null and auth_id is not null';
  end if;
end
$$;

create unique index if not exists users_auth_user_id_key
  on public.users (auth_user_id);

create or replace function public.is_admin()
returns boolean
language sql
stable
as $$
  select exists (
    select 1
    from public.users
    where users.auth_user_id = auth.uid()
      and users.is_admin = true
  );
$$;

drop policy if exists "Case insert own" on public."case";
drop policy if exists "Case select own" on public."case";
drop policy if exists "Case update own" on public."case";
drop policy if exists "Case delete deny" on public."case";

create policy "Case insert own"
  on public."case"
  for insert
  with check (
    auth.uid() = owner_id
    and exists (
      select 1
      from public.house_invites invites
      where invites.user_id = auth.uid()
        and invites.status = 'accepted'
    )
    and not exists (
      select 1
      from public."case" existing
      where existing.owner_id = auth.uid()
    )
  );

create policy "Case select own"
  on public."case"
  for select
  using (auth.uid() = owner_id);

create policy "Case update own"
  on public."case"
  for update
  using (auth.uid() = owner_id)
  with check (auth.uid() = owner_id);

create policy "Case delete deny"
  on public."case"
  for delete
  using (false);

drop policy if exists "Invites insert admin" on public.house_invites;
drop policy if exists "Invites select admin or owner" on public.house_invites;
drop policy if exists "Invites update owner status" on public.house_invites;
drop policy if exists "Invites delete admin" on public.house_invites;

create policy "Invites insert admin"
  on public.house_invites
  for insert
  with check (public.is_admin());

create policy "Invites select admin or owner"
  on public.house_invites
  for select
  using (
    public.is_admin()
    or auth.uid() = user_id
  );

create policy "Invites update owner status"
  on public.house_invites
  for update
  using (auth.uid() = user_id)
  with check (
    auth.uid() = user_id
    and status in ('pending', 'accepted', 'declined')
  );

create policy "Invites delete admin"
  on public.house_invites
  for delete
  using (public.is_admin());

revoke update on public.house_invites from authenticated;
grant update (status) on public.house_invites to authenticated;
