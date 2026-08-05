-- A house is listed for every authenticated island visitor. Its associated
-- personal hinoo is the public-facing campanello and must be readable with it.
-- Other personal hinoo remain private.

drop policy if exists "hinoo read house campanelli" on public.hinoo;
create policy "hinoo read house campanelli"
  on public.hinoo
  for select
  to authenticated
  using (
    exists (
      select 1
      from public."case" houses
      where houses.campanello_hinoo_id = hinoo.id
    )
  );
