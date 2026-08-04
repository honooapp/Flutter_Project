-- Keep house requests separate from invitations authorized by an admin and
-- create the campanello + house in one transaction.

alter table public.house_invites
  alter column invited_by drop not null;

alter table public.house_invites
  drop constraint if exists house_invites_status_check;

alter table public.house_invites
  add constraint house_invites_status_check
  check (status in ('requested', 'pending', 'accepted', 'declined'));

drop policy if exists "Invites select admin or owner" on public.house_invites;
create policy "Invites select admin owner or email"
  on public.house_invites
  for select
  to authenticated
  using (
    public.is_admin()
    or auth.uid() = user_id
    or (
      user_id is null
      and email is not null
      and lower(email) = lower(coalesce(auth.jwt() ->> 'email', ''))
    )
  );

drop policy if exists "Invites update owner status" on public.house_invites;
create policy "Invites update owner authorized status"
  on public.house_invites
  for update
  to authenticated
  using (
    auth.uid() = user_id
    and status in ('pending', 'accepted')
  )
  with check (
    auth.uid() = user_id
    and status in ('accepted', 'declined')
  );

drop policy if exists "Invites update admin" on public.house_invites;
create policy "Invites update admin"
  on public.house_invites
  for update
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

create or replace function public.request_house_invite(p_email text default null)
returns boolean
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  requester_id uuid := auth.uid();
begin
  if requester_id is null then
    raise exception 'Not authenticated';
  end if;

  perform pg_advisory_xact_lock(hashtextextended(requester_id::text, 0));

  if public.is_admin() then
    raise exception 'Administrators cannot request a house invitation';
  end if;

  if exists (
    select 1 from public."case" where owner_id = requester_id
  ) or exists (
    select 1
    from public.house_invites
    where user_id = requester_id
      and status in ('requested', 'pending', 'accepted')
  ) then
    return false;
  end if;

  insert into public.house_invites (user_id, email, invited_by, status)
  values (
    requester_id,
    nullif(btrim(coalesce(p_email, '')), ''),
    null,
    'requested'
  );

  return true;
end;
$$;

revoke all on function public.request_house_invite(text) from public;
grant execute on function public.request_house_invite(text) to authenticated;

create or replace function public.admin_review_house_request(
  p_invite_id uuid,
  p_approved boolean
)
returns boolean
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if not public.is_admin() then
    raise exception 'Admin access required';
  end if;

  update public.house_invites
  set status = case when p_approved then 'pending' else 'declined' end,
      invited_by = auth.uid()
  where id = p_invite_id
    and status = 'requested';

  return found;
end;
$$;

revoke all on function public.admin_review_house_request(uuid, boolean) from public;
grant execute on function public.admin_review_house_request(uuid, boolean)
  to authenticated;

create or replace function public.create_house_with_campanello(
  p_pages jsonb,
  p_house_image_url text,
  p_bg_transform jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  owner_uid uuid := auth.uid();
  campanello_id uuid;
begin
  if owner_uid is null then
    raise exception 'Not authenticated';
  end if;

  if jsonb_typeof(p_pages) <> 'array'
     or jsonb_array_length(p_pages) < 1
     or jsonb_array_length(p_pages) > 9 then
    raise exception 'Invalid campanello pages';
  end if;

  if nullif(btrim(coalesce(p_house_image_url, '')), '') is null then
    raise exception 'House image is required';
  end if;

  perform pg_advisory_xact_lock(hashtextextended(owner_uid::text, 1));

  if exists (select 1 from public."case" where owner_id = owner_uid) then
    raise exception 'House already exists';
  end if;

  if not exists (
    select 1
    from public.house_invites
    where user_id = owner_uid
      and status = 'accepted'
  ) then
    raise exception 'An accepted house invitation is required';
  end if;

  insert into public.hinoo (user_id, pages, type)
  values (owner_uid, p_pages, 'personal'::public.hinoo_type)
  returning id into campanello_id;

  insert into public."case" (
    owner_id,
    campanello_hinoo_id,
    house_image_url,
    bg_transform
  ) values (
    owner_uid,
    campanello_id,
    p_house_image_url,
    p_bg_transform
  );

  return campanello_id;
end;
$$;

revoke all on function public.create_house_with_campanello(jsonb, text, jsonb)
  from public;
grant execute on function public.create_house_with_campanello(jsonb, text, jsonb)
  to authenticated;

drop policy if exists "House access select visitor" on public.house_access;
create policy "House access select visitor"
  on public.house_access
  for select
  to authenticated
  using (visitor_id = auth.uid());

alter table public.house_invites replica identity full;
alter table public.house_access replica identity full;

do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'house_invites'
  ) then
    alter publication supabase_realtime add table public.house_invites;
  end if;

  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'house_access'
  ) then
    alter publication supabase_realtime add table public.house_access;
  end if;
end
$$;
