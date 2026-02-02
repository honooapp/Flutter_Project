create or replace function public.admin_find_user_by_email(p_email text)
returns table (auth_user_id uuid, email text)
language plpgsql
security definer
set search_path = public, auth
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
  select au.id, au.email
  from auth.users au
  where lower(au.email) = lower(p_email)
  limit 1;
end;
$$;

revoke all on function public.admin_find_user_by_email(text) from public;
grant execute on function public.admin_find_user_by_email(text) to authenticated;
