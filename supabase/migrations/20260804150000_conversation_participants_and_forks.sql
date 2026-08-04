-- Ogni partecipante può leggere l'intero filo, non soltanto le righe che
-- possiede o di cui è destinatario diretto.
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
          select u.address from public.users u where u.auth_id = auth.uid()
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
          select u.address from public.users u where u.auth_id = auth.uid()
        )
      )
  );
$$;

revoke all on function public.is_conversation_participant(text) from public;
grant execute on function public.is_conversation_participant(text)
  to authenticated;

create or replace function public.find_previous_unanswered_conversation(
  target_parent_id uuid
)
returns text
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  with direct_replies as (
    select h.conversation_id, h.created_at
    from public.honoo h
    where h.reply_to = target_parent_id
      and h.user_id = auth.uid()
    union all
    select x.conversation_id, x.created_at
    from public.hinoo x
    where x.reply_to = target_parent_id
      and x.user_id = auth.uid()
  ), unanswered as (
    select d.conversation_id, d.created_at
    from direct_replies d
    where d.conversation_id is not null
      and not exists (
        select 1
        from public.honoo h
        where h.conversation_id = d.conversation_id
          and h.user_id <> auth.uid()
          and h.created_at > d.created_at
        union all
        select 1
        from public.hinoo x
        where x.conversation_id = d.conversation_id
          and x.user_id <> auth.uid()
          and x.created_at > d.created_at
      )
  )
  select u.conversation_id
  from unanswered u
  order by u.created_at desc
  limit 1;
$$;

revoke all on function public.find_previous_unanswered_conversation(uuid)
  from public;
grant execute on function public.find_previous_unanswered_conversation(uuid)
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

-- Un reply può iniziare esplicitamente un nuovo filo sullo stesso contenuto.
-- Se conversation_id è omesso continua invece a ereditare il filo del padre.
create or replace function public.enforce_conversation_integrity()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_parent_cid text;
begin
  if new.reply_to is null then
    if new.conversation_id is null or btrim(new.conversation_id) = '' then
      new.conversation_id := new.id::text;
    end if;
    return new;
  end if;

  select coalesce(h.conversation_id, h.id::text)
    into v_parent_cid
  from public.honoo h
  where h.id = new.reply_to
  limit 1;

  if v_parent_cid is null then
    select coalesce(x.conversation_id, x.id::text)
      into v_parent_cid
    from public.hinoo x
    where x.id = new.reply_to
    limit 1;
  end if;

  if v_parent_cid is null then
    raise exception 'Invalid reply_to reference (%) for %',
      new.reply_to, tg_table_name;
  end if;

  if new.conversation_id is null or btrim(new.conversation_id) = '' then
    new.conversation_id := v_parent_cid;
  end if;

  return new;
end
$$;

revoke all on function public.enforce_conversation_integrity() from public;
