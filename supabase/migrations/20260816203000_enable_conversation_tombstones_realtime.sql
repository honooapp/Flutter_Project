-- Keep deleted-content placeholders in sync without waiting for client polling.
do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'conversation_tombstones'
  ) then
    alter publication supabase_realtime
      add table public.conversation_tombstones;
  end if;
end
$$;
