create or replace function public.admin_moon_counts_today()
returns table (honoo_count integer, hinoo_count integer)
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_admin() then
    raise exception 'Not authorized';
  end if;

  return query
  select
    (select count(*)
     from public.honoo
     where destination = 'moon'
       and created_at::date = current_date) as honoo_count,
    (select count(*)
     from public.hinoo
     where type = 'moon'
       and created_at::date = current_date) as hinoo_count;
end;
$$;

revoke all on function public.admin_moon_counts_today() from public;
grant execute on function public.admin_moon_counts_today() to authenticated;
