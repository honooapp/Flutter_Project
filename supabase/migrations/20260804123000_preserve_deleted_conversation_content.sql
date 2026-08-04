-- Preserve the position of Moon content removed by an admin and repair
-- conversations whose parent content was already hard-deleted.

alter table public.honoo
  add column if not exists admin_deleted_at timestamptz;

alter table public.hinoo
  add column if not exists admin_deleted_at timestamptz;

create table if not exists public.conversation_tombstones (
  content_id uuid primary key,
  conversation_id text not null,
  source_kind text not null
    check (source_kind in ('honoo', 'hinoo', 'unknown')),
  original_created_at timestamptz not null,
  deleted_at timestamptz not null default now()
);

alter table public.conversation_tombstones enable row level security;

drop policy if exists "authenticated read conversation tombstones"
  on public.conversation_tombstones;
create policy "authenticated read conversation tombstones"
  on public.conversation_tombstones
  for select
  to authenticated
  using (true);

-- Existing orphan replies cannot recover the deleted payload, but their
-- reply_to id and conversation id are sufficient to restore its placeholder.
with orphan_replies as (
  select
    reply_to as content_id,
    coalesce(nullif(conversation_id, ''), reply_to::text) as conversation_id,
    created_at
  from public.honoo reply
  where reply_to is not null
    and not exists (select 1 from public.honoo h where h.id = reply.reply_to)
    and not exists (select 1 from public.hinoo h where h.id = reply.reply_to)
  union all
  select
    reply_to as content_id,
    coalesce(nullif(conversation_id, ''), reply_to::text) as conversation_id,
    created_at
  from public.hinoo reply
  where reply_to is not null
    and not exists (select 1 from public.honoo h where h.id = reply.reply_to)
    and not exists (select 1 from public.hinoo h where h.id = reply.reply_to)
), repaired as (
  select
    content_id,
    min(conversation_id) as conversation_id,
    min(created_at) - interval '1 microsecond' as original_created_at
  from orphan_replies
  group by content_id
)
insert into public.conversation_tombstones (
  content_id,
  conversation_id,
  source_kind,
  original_created_at
)
select content_id, conversation_id, 'unknown', original_created_at
from repaired
on conflict (content_id) do nothing;

create or replace function public.admin_moon_content_has_replies(
  p_kind text,
  p_id uuid
)
returns boolean
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if not public.is_admin() then
    raise exception 'Admin privileges required';
  end if;

  if p_kind not in ('honoo', 'hinoo') then
    raise exception 'Unsupported content kind: %', p_kind;
  end if;

  return exists(select 1 from public.honoo where reply_to = p_id)
    or exists(select 1 from public.hinoo where reply_to = p_id);
end
$$;

create or replace function public.admin_soft_delete_moon_content(
  p_kind text,
  p_id uuid
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_conversation_id text;
  v_created_at timestamptz;
begin
  if not public.is_admin() then
    raise exception 'Admin privileges required';
  end if;

  if p_kind = 'honoo' then
    select coalesce(nullif(conversation_id, ''), id::text), created_at
      into v_conversation_id, v_created_at
    from public.honoo
    where id = p_id
      and destination = 'moon'
      and admin_deleted_at is null;

    if not found then
      raise exception 'Moon content not found';
    end if;

    insert into public.conversation_tombstones (
      content_id,
      conversation_id,
      source_kind,
      original_created_at
    ) values (p_id, v_conversation_id, 'honoo', v_created_at)
    on conflict (content_id) do update
      set conversation_id = excluded.conversation_id,
          source_kind = excluded.source_kind,
          original_created_at = excluded.original_created_at,
          deleted_at = now();

    update public.honoo
    set admin_deleted_at = now(),
        text = 'contenuto eliminato',
        image_url = '',
        updated_at = now()
    where id = p_id;
  elsif p_kind = 'hinoo' then
    select coalesce(nullif(conversation_id, ''), id::text), created_at
      into v_conversation_id, v_created_at
    from public.hinoo
    where id = p_id
      and type::text = 'moon'
      and admin_deleted_at is null;

    if not found then
      raise exception 'Moon content not found';
    end if;

    insert into public.conversation_tombstones (
      content_id,
      conversation_id,
      source_kind,
      original_created_at
    ) values (p_id, v_conversation_id, 'hinoo', v_created_at)
    on conflict (content_id) do update
      set conversation_id = excluded.conversation_id,
          source_kind = excluded.source_kind,
          original_created_at = excluded.original_created_at,
          deleted_at = now();

    update public.hinoo
    set admin_deleted_at = now(),
        pages = jsonb_build_array(
          jsonb_build_object(
            'backgroundImage', null,
            'text', 'contenuto eliminato',
            'isTextWhite', true,
            'bgScale', 1.0,
            'bgOffsetX', 0.0,
            'bgOffsetY', 0.0
          )
        ),
        updated_at = now()
    where id = p_id;
  else
    raise exception 'Unsupported content kind: %', p_kind;
  end if;
end
$$;

revoke all on function public.admin_moon_content_has_replies(text, uuid)
  from public;
revoke all on function public.admin_soft_delete_moon_content(text, uuid)
  from public;
grant execute on function public.admin_moon_content_has_replies(text, uuid)
  to authenticated;
grant execute on function public.admin_soft_delete_moon_content(text, uuid)
  to authenticated;

-- Admin deletion must pass through the preserving RPC above.
drop policy if exists "honoo delete admin moon" on public.honoo;
drop policy if exists "hinoo delete admin moon" on public.hinoo;

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
where type::text = 'moon'
  and admin_deleted_at is null
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
where destination = 'moon'
  and admin_deleted_at is null;
