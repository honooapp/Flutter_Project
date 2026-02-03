-- Allow authenticated users to read moon honoo

drop policy if exists "honoo moon authenticated" on public.honoo;

drop policy if exists "honoo moon public" on public.honoo;

drop policy if exists "Public moon honoo" on public.honoo;

drop policy if exists "select moon honoo" on public.honoo;

create policy "honoo moon authenticated"
  on public.honoo
  for select
  to authenticated
  using (destination = 'moon');
