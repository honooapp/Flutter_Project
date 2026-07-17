-- Reinstalla in modo deterministico i trigger di integrità conversazioni.
-- Corregge ambienti in cui la migrazione storica risulta applicata ma i
-- trigger non sono presenti/attivi sulle tabelle correnti.

create or replace function public.enforce_conversation_integrity()
returns trigger
language plpgsql
set search_path = public
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
  elsif new.conversation_id <> v_parent_cid then
    raise exception 'conversation_id mismatch with parent: expected %, got %',
      v_parent_cid, new.conversation_id;
  end if;

  return new;
end
$$;

drop trigger if exists trg_enforce_conv_integrity_honoo on public.honoo;
create trigger trg_enforce_conv_integrity_honoo
before insert or update of reply_to, conversation_id on public.honoo
for each row execute function public.enforce_conversation_integrity();

drop trigger if exists trg_enforce_conv_integrity_hinoo on public.hinoo;
create trigger trg_enforce_conv_integrity_hinoo
before insert or update of reply_to, conversation_id on public.hinoo
for each row execute function public.enforce_conversation_integrity();

update public.honoo
set conversation_id = id::text
where conversation_id is null
  and reply_to is null;

update public.hinoo
set conversation_id = id::text
where conversation_id is null
  and reply_to is null;
