create table if not exists public.site_visits (
  visit_date date primary key,
  count integer not null default 0,
  updated_at timestamptz not null default now()
);

alter table public.site_visits enable row level security;

drop policy if exists "Site visits select admin" on public.site_visits;

create policy "Site visits select admin"
  on public.site_visits
  for select
  using (public.is_admin());

create or replace function public.increment_site_visit()
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  new_count integer;
begin
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

create or replace function public.admin_list_site_visits(p_days int default 3)
returns table (visit_date date, count integer)
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_admin() then
    raise exception 'Not authorized';
  end if;

  return query
  select v.visit_date, v.count
  from public.site_visits v
  where v.visit_date >= current_date - (p_days - 1)
  order by v.visit_date desc;
end;
$$;

revoke all on function public.increment_site_visit() from public;
grant execute on function public.increment_site_visit() to anon, authenticated;

revoke all on function public.admin_list_site_visits(int) from public;
grant execute on function public.admin_list_site_visits(int) to authenticated;
