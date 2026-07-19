-- Restore campanelli only on environments where the historical migration did
-- not create it. Existing installations (including production) are a strict
-- no-op: no data, grants, constraints, or policies are changed.
do $$
begin
  if to_regclass('public.campanelli') is not null then
    return;
  end if;

  create table public.campanelli (
    id uuid primary key default gen_random_uuid(),
    owner_id uuid not null references auth.users(id) on delete cascade,
    hinoo_id uuid references public.hinoo(id),
    house_id uuid references public."case"(id),
    created_at timestamptz not null default now()
  );

  create unique index campanelli_owner_id_key
    on public.campanelli (owner_id);

  alter table public.campanelli enable row level security;

  create policy "Campanelli insert own"
    on public.campanelli
    for insert
    with check (
      auth.uid() = owner_id
      and not exists (
        select 1
        from public.campanelli c
        where c.owner_id = auth.uid()
      )
    );

  create policy "Campanelli select own"
    on public.campanelli
    for select
    using (auth.uid() = owner_id);

  create policy "Campanelli update own"
    on public.campanelli
    for update
    using (auth.uid() = owner_id)
    with check (auth.uid() = owner_id);

  grant select, insert, update, delete, truncate, references, trigger
    on table public.campanelli
    to anon, authenticated, service_role;

  perform pg_notify('pgrst', 'reload schema');
end
$$;
