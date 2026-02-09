create or replace function public.increment_site_visit()
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  new_count integer;
begin
  if auth.uid() is not null and public.is_admin() then
    return 0;
  end if;

  insert into public.site_visits (visit_date, count, updated_at)
  values (current_date, 1, now())
  on conflict (visit_date)
  do update
    set count = public.site_visits.count + 1,
        updated_at = now()
  returning count into new_count;

  return new_count;
end;
$$;

revoke all on function public.increment_site_visit() from public;
grant execute on function public.increment_site_visit() to anon, authenticated;
