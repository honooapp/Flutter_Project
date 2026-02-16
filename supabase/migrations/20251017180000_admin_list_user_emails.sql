-- Admin-only email listing for autocomplete

drop function if exists public.admin_list_user_emails();

create function public.admin_list_user_emails()
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
  where au.email is not null
  order by au.email;
end;
$$;

revoke all on function public.admin_list_user_emails() from public;
grant execute on function public.admin_list_user_emails() to authenticated;
