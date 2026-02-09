drop policy if exists "honoo delete admin moon" on public.honoo;
drop policy if exists "hinoo delete admin moon" on public.hinoo;

create policy "honoo delete admin moon"
  on public.honoo
  for delete
  using (public.is_admin() and destination = 'moon');

create policy "hinoo delete admin moon"
  on public.hinoo
  for delete
  using (public.is_admin() and type = 'moon');
