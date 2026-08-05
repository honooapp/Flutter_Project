-- Reinstalla esplicitamente la visibilità dell'intero filo per entrambi i
-- partecipanti. Alcuni ambienti avevano avanzato il registro migrazioni senza
-- avere le policy introdotte in 20260804150000, lasciando il mittente capace di
-- leggere soltanto le proprie risposte.
create or replace function public.is_conversation_participant(
  target_conversation_id text
)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1
    from public.honoo h
    where h.conversation_id = target_conversation_id
      and (
        h.user_id = auth.uid()
        or h.recipient_tag = auth.uid()::text
        or h.recipient_tag in (
          select u.address
          from public.users u
          where u.auth_user_id = auth.uid()
        )
      )
    union all
    select 1
    from public.hinoo x
    where x.conversation_id = target_conversation_id
      and (
        x.user_id = auth.uid()
        or x.recipient_tag = auth.uid()::text
        or x.recipient_tag in (
          select u.address
          from public.users u
          where u.auth_user_id = auth.uid()
        )
      )
  );
$$;

revoke all on function public.is_conversation_participant(text) from public;
grant execute on function public.is_conversation_participant(text)
  to authenticated;

drop policy if exists "conversation participants read honoo"
  on public.honoo;
create policy "conversation participants read honoo"
  on public.honoo
  as permissive
  for select
  to authenticated
  using (public.is_conversation_participant(conversation_id));

drop policy if exists "conversation participants read hinoo"
  on public.hinoo;
create policy "conversation participants read hinoo"
  on public.hinoo
  as permissive
  for select
  to authenticated
  using (public.is_conversation_participant(conversation_id));
