-- Abilita gli eventi Postgres Changes usati dai thread e dallo Scrigno.

do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'honoo'
  ) then
    alter publication supabase_realtime add table public.honoo;
  end if;

  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'hinoo'
  ) then
    alter publication supabase_realtime add table public.hinoo;
  end if;
end
$$;
