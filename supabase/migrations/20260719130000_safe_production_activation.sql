-- Safe production activation for the conversation release.
--
-- This rollup is intentionally limited to schema/runtime additions. It does
-- not update or delete existing rows, replace RLS/Storage policies, or change
-- existing bucket settings.

alter table if exists public.house_share_settings
  add column if not exists share_modes text[];

insert into storage.buckets (id, name, public)
values
  ('honoo-images', 'honoo-images', true),
  ('hinoo', 'hinoo', true)
on conflict (id) do nothing;

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
  elsif new.conversation_id <> v_parent_cid then
    raise exception 'conversation_id mismatch with parent: expected %, got %',
      v_parent_cid, new.conversation_id;
  end if;

  return new;
end
$$;

revoke all on function public.enforce_conversation_integrity() from public;

do $$
begin
  if not exists (
    select 1
    from pg_trigger
    where tgrelid = 'public.honoo'::regclass
      and tgname = 'trg_enforce_conv_integrity_honoo'
      and not tgisinternal
  ) then
    create trigger trg_enforce_conv_integrity_honoo
    before insert or update of reply_to, conversation_id on public.honoo
    for each row execute function public.enforce_conversation_integrity();
  end if;

  if not exists (
    select 1
    from pg_trigger
    where tgrelid = 'public.hinoo'::regclass
      and tgname = 'trg_enforce_conv_integrity_hinoo'
      and not tgisinternal
  ) then
    create trigger trg_enforce_conv_integrity_hinoo
    before insert or update of reply_to, conversation_id on public.hinoo
    for each row execute function public.enforce_conversation_integrity();
  end if;
end
$$;

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

create or replace view public.moon_public as
select
  'hinoo'::text as kind,
  id,
  user_id,
  created_at,
  pages,
  recipient_tag,
  null::text as text,
  null::text as image_url,
  conversation_id
from public.hinoo
where type = 'moon'
union all
select
  'honoo'::text as kind,
  id,
  user_id,
  created_at,
  null::jsonb as pages,
  recipient_tag,
  text,
  image_url,
  conversation_id
from public.honoo
where destination = 'moon';
