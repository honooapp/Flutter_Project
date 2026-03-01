-- Campanelli ↔ Case schema + RLS (Supabase)

create table if not exists public.campanelli (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  hinoo_id uuid,
  house_id uuid references public."case"(id),
  created_at timestamptz not null default now()
);

create unique index if not exists campanelli_owner_id_key
  on public.campanelli (owner_id);

create table if not exists public."case" (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  campanello_id uuid not null references public.campanelli(id),
  created_at timestamptz not null default now()
);

create unique index if not exists case_owner_id_key
  on public."case" (owner_id);

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'campanelli_house_id_fkey'
      and conrelid = 'public.campanelli'::regclass
  ) then
    alter table public.campanelli
      add constraint campanelli_house_id_fkey
      foreign key (house_id) references public."case"(id);
  end if;
end
$$;

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

alter table public.campanelli enable row level security;
alter table public."case" enable row level security;
alter table public.house_invites enable row level security;

create or replace function public.is_admin()
returns boolean
language sql
stable
as $$
  select exists (
    select 1
    from public.users
    where auth_user_id = auth.uid()
      and is_admin = true
  );
$$;

-- Campanelli policies
drop policy if exists "Campanelli insert own" on public.campanelli;
create policy "Campanelli insert own"
  on public.campanelli
  for insert
  with check (
    auth.uid() = owner_id
    and not exists (
      select 1 from public.campanelli c
      where c.owner_id = auth.uid()
    )
  );

drop policy if exists "Campanelli select own" on public.campanelli;
create policy "Campanelli select own"
  on public.campanelli
  for select
  using (auth.uid() = owner_id);

drop policy if exists "Campanelli update own" on public.campanelli;
create policy "Campanelli update own"
  on public.campanelli
  for update
  using (auth.uid() = owner_id)
  with check (auth.uid() = owner_id);

-- Case policies
drop policy if exists "Case insert own" on public."case";
create policy "Case insert own"
  on public."case"
  for insert
  with check (
    auth.uid() = owner_id
    and exists (
      select 1 from public.house_invites i
      where i.user_id = auth.uid()
        and i.status = 'accepted'
    )
    and not exists (
      select 1 from public."case" c
      where c.owner_id = auth.uid()
    )
  );

drop policy if exists "Case select own" on public."case";
create policy "Case select own"
  on public."case"
  for select
  using (auth.uid() = owner_id);

drop policy if exists "Case update own" on public."case";
create policy "Case update own"
  on public."case"
  for update
  using (auth.uid() = owner_id)
  with check (auth.uid() = owner_id);

-- House invites policies
drop policy if exists "Invites insert admin" on public.house_invites;
create policy "Invites insert admin"
  on public.house_invites
  for insert
  with check (public.is_admin());

drop policy if exists "Invites select admin or owner" on public.house_invites;
create policy "Invites select admin or owner"
  on public.house_invites
  for select
  using (
    public.is_admin()
    or auth.uid() = user_id
  );

drop policy if exists "Invites update owner status" on public.house_invites;
create policy "Invites update owner status"
  on public.house_invites
  for update
  using (auth.uid() = user_id)
  with check (
    auth.uid() = user_id
    and status in ('pending', 'accepted', 'declined')
  );

drop policy if exists "Invites delete admin" on public.house_invites;
create policy "Invites delete admin"
  on public.house_invites
  for delete
  using (public.is_admin());

-- Column-level protection: only status can be updated by authenticated users.
revoke update on public.house_invites from authenticated;
grant update (status) on public.house_invites to authenticated;
