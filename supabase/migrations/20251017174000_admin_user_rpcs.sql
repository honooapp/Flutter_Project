-- Admin RPCs to avoid direct users table selects

create or replace function public.admin_is_admin()
returns boolean
language plpgsql
security definer
set search_path = public
as $$
begin
  return exists (
    select 1
    from public.users
    where auth_user_id = auth.uid()
      and is_admin = true
  );
end;
$$;

create or replace function public.admin_list_users()
returns table (auth_user_id uuid)
language plpgsql
security definer
set search_path = public
as $$
begin
  if not exists (
    select 1
    from public.users
    where auth_user_id = auth.uid()
      and is_admin = true
  ) then
    raise exception 'Not authorized';
  end if;

  return query
  select auth_user_id
  from public.users
  where auth_user_id is not null;
end;
$$;

revoke all on function public.admin_is_admin() from public;
grant execute on function public.admin_is_admin() to authenticated;

revoke all on function public.admin_list_users() from public;
grant execute on function public.admin_list_users() to authenticated;
