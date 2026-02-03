-- Unified moon view for honoo + hinoo

create or replace view public.moon_public as
select
  'hinoo'::text as kind,
  id,
  user_id,
  created_at,
  pages,
  recipient_tag,
  null::text as text,
  null::text as image_url
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
  image_url
from public.honoo
where destination = 'moon';
