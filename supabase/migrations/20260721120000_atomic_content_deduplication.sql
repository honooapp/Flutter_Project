-- Atomic deduplication for copies saved to the Chest or published to the Moon.
alter table if exists public.honoo
  add column if not exists fingerprint text;

update public.honoo
set fingerprint = text || chr(31) || coalesce(image_url, '')
where fingerprint is null
  and destination in ('chest', 'moon');

-- Preserve historical rows while allowing one canonical fingerprint to guard
-- future inserts. No user content is deleted by this migration.
with ranked as (
  select id,
         row_number() over (
           partition by user_id, destination, md5(fingerprint)
           order by created_at, id
         ) as occurrence
  from public.honoo
  where fingerprint is not null
    and destination in ('chest', 'moon')
)
update public.honoo as item
set fingerprint = null
from ranked
where item.id = ranked.id
  and ranked.occurrence > 1;

create unique index if not exists honoo_user_destination_fingerprint_key
  on public.honoo (user_id, destination, md5(fingerprint))
  where fingerprint is not null
    and destination in ('chest', 'moon');

with ranked as (
  select id,
         row_number() over (
           partition by user_id, type, md5(fingerprint)
           order by created_at, id
         ) as occurrence
  from public.hinoo
  where fingerprint is not null
    and type in ('personal', 'moon')
)
update public.hinoo as item
set fingerprint = null
from ranked
where item.id = ranked.id
  and ranked.occurrence > 1;

create unique index if not exists hinoo_user_type_fingerprint_key
  on public.hinoo (user_id, type, md5(fingerprint))
  where fingerprint is not null
    and type in ('personal', 'moon');
