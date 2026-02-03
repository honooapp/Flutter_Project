-- House access knock tracking (admin-free, owner-readable)

alter table public.house_access enable row level security;

drop policy if exists "House access insert" on public.house_access;
drop policy if exists "House access select owner" on public.house_access;
drop policy if exists "House access update owner" on public.house_access;

create policy "House access insert"
  on public.house_access
  for insert
  with check (
    visitor_id = auth.uid()
    and exists (
      select 1
      from public."case" c
      where c.campanello_hinoo_id::text = target_house_tag
    )
  );

create policy "House access select owner"
  on public.house_access
  for select
  using (
    exists (
      select 1
      from public."case" c
      where c.campanello_hinoo_id::text = target_house_tag
        and c.owner_id = auth.uid()
    )
  );

create policy "House access update owner"
  on public.house_access
  for update
  using (
    exists (
      select 1
      from public."case" c
      where c.campanello_hinoo_id::text = target_house_tag
        and c.owner_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1
      from public."case" c
      where c.campanello_hinoo_id::text = target_house_tag
        and c.owner_id = auth.uid()
    )
  );
