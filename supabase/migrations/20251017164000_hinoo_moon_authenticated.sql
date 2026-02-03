-- Restrict moon visibility to authenticated users only

drop policy if exists "hinoo moon public" on public.hinoo;

create policy "hinoo moon authenticated"
  on public.hinoo
  for select
  to authenticated
  using (type = 'moon'::hinoo_type);
