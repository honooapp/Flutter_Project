-- Conversation integrity: backfill + trigger-based enforcement (idempotent, non-destructive)
--
-- Keep the column creation in the same migration that first consumes the
-- column. This matters on a clean local reset: the remote-schema snapshot
-- predates conversation_id, while the backfill below reads it immediately.
alter table if exists public.honoo
  add column if not exists conversation_id text;

alter table if exists public.hinoo
  add column if not exists conversation_id text;

-- ==========================
-- 1) Backfill existing data
-- ==========================

-- A) Roots (reply_to IS NULL and conversation_id IS NULL): seed conversation_id with own id
update public.honoo
set conversation_id = id::text
where conversation_id is null
  and reply_to is null;

update public.hinoo
set conversation_id = id::text
where conversation_id is null
  and reply_to is null;

-- B) Replies with missing conversation_id: inherit from parent (prefer parent's conversation_id, else parent id)
-- honoo rows whose parent is honoo
update public.honoo c
set conversation_id = coalesce(p.conversation_id, p.id::text)
from public.honoo p
where c.conversation_id is null
  and c.reply_to is not null
  and p.id = c.reply_to;

-- honoo rows whose parent is hinoo
update public.honoo c
set conversation_id = coalesce(p.conversation_id, p.id::text)
from public.hinoo p
where c.conversation_id is null
  and c.reply_to is not null
  and p.id = c.reply_to;

-- hinoo rows whose parent is honoo
update public.hinoo c
set conversation_id = coalesce(p.conversation_id, p.id::text)
from public.honoo p
where c.conversation_id is null
  and c.reply_to is not null
  and p.id = c.reply_to;

-- hinoo rows whose parent is hinoo
update public.hinoo c
set conversation_id = coalesce(p.conversation_id, p.id::text)
from public.hinoo p
where c.conversation_id is null
  and c.reply_to is not null
  and p.id = c.reply_to;


-- ==============================================
-- 2) Function: enforce_conversation_integrity()
-- ==============================================

create or replace function public.enforce_conversation_integrity()
returns trigger
language plpgsql
as $$
declare
  v_parent_cid text;
begin
  -- Case: root (no reply_to)
  if new.reply_to is null then
    if new.conversation_id is null then
      new.conversation_id := new.id::text;
    end if;
    return new;
  end if;

  -- Case: reply — lookup parent first in honoo, then in hinoo
  select coalesce(h.conversation_id, h.id::text) into v_parent_cid
  from public.honoo h
  where h.id = new.reply_to
  limit 1;

  if v_parent_cid is null then
    select coalesce(x.conversation_id, x.id::text) into v_parent_cid
    from public.hinoo x
    where x.id = new.reply_to
    limit 1;
  end if;

  if v_parent_cid is null then
    raise exception 'Invalid reply_to reference (%) for %', new.reply_to, tg_table_name;
  end if;

  if new.conversation_id is null then
    new.conversation_id := v_parent_cid;
  elsif new.conversation_id <> v_parent_cid then
    raise exception 'conversation_id mismatch with parent: expected %, got %', v_parent_cid, new.conversation_id;
  end if;

  return new;
end
$$;


-- =====================
-- 3) Attach the triggers
-- =====================

do $$
begin
  if not exists (
    select 1 from pg_trigger where tgname = 'trg_enforce_conv_integrity_honoo'
  ) then
    create trigger trg_enforce_conv_integrity_honoo
    before insert or update on public.honoo
    for each row execute function public.enforce_conversation_integrity();
  end if;
end $$;

do $$
begin
  if not exists (
    select 1 from pg_trigger where tgname = 'trg_enforce_conv_integrity_hinoo'
  ) then
    create trigger trg_enforce_conv_integrity_hinoo
    before insert or update on public.hinoo
    for each row execute function public.enforce_conversation_integrity();
  end if;
end $$;
