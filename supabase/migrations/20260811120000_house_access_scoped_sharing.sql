alter table public.house_access
  add column if not exists share_modes text[] not null default '{}';

alter table public.house_access
  drop constraint if exists house_access_share_modes_valid;

alter table public.house_access
  add constraint house_access_share_modes_valid check (
    share_modes <@ array['home', 'moon', 'all']::text[]
  );

create index if not exists house_access_visitor_granted_idx
  on public.house_access (visitor_id, granted_at)
  where granted_at is not null;

create or replace function public.approve_house_knock(
  p_knock_id bigint,
  p_share_modes text[]
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if auth.uid() is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  if p_share_modes is null
     or coalesce(array_length(p_share_modes, 1), 0) = 0
     or not (p_share_modes <@ array['home', 'moon', 'all']::text[]) then
    raise exception 'Invalid house share modes' using errcode = '22023';
  end if;

  update public.house_access ha
  set granted_at = now(),
      share_modes = array(select distinct unnest(p_share_modes))
  where ha.id = p_knock_id
    and ha.granted_at is null
    and exists (
      select 1
      from public."case" c
      where c.campanello_hinoo_id::text = ha.target_house_tag
        and c.owner_id = auth.uid()
    );

  if not found then
    raise exception 'Pending knock not found or not owned by user'
      using errcode = '42501';
  end if;
end;
$$;

revoke all on function public.approve_house_knock(bigint, text[]) from public;
grant execute on function public.approve_house_knock(bigint, text[])
  to authenticated;

create or replace function public.get_shared_house_chest(p_owner_id uuid)
returns table(kind text, data jsonb, created_at timestamptz)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  allowed_modes text[];
begin
  if auth.uid() is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  select coalesce(array_agg(distinct granted.mode), '{}'::text[])
  into allowed_modes
  from public.house_access ha
  join public."case" c
    on c.campanello_hinoo_id::text = ha.target_house_tag
  cross join lateral unnest(ha.share_modes) as granted(mode)
  where ha.visitor_id = auth.uid()
    and ha.granted_at is not null
    and c.owner_id = p_owner_id;

  if coalesce(array_length(allowed_modes, 1), 0) = 0 then
    raise exception 'House access not granted' using errcode = '42501';
  end if;

  return query
  select shared.kind, shared.data, shared.created_at
  from (
    select
      'honoo'::text as kind,
      jsonb_build_object(
        'id', h.id,
        'text', h.text,
        'image_url', h.image_url,
        'destination', h.destination,
        'created_at', h.created_at,
        'updated_at', h.updated_at,
        'user_id', h.user_id,
        'is_from_moon_saved', h.is_from_moon_saved
      ) as data,
      h.created_at
    from public.honoo h
    where h.user_id = p_owner_id
      and h.destination = 'chest'
      and (
        'all' = any(allowed_modes)
        or ('home' = any(allowed_modes) and not coalesce(h.is_from_moon_saved, false))
        or ('moon' = any(allowed_modes) and coalesce(h.is_from_moon_saved, false))
      )

    union all

    select
      'hinoo'::text as kind,
      jsonb_build_object(
        'id', h.id,
        'pages', h.pages,
        'type', h.type,
        'created_at', h.created_at,
        'user_id', h.user_id,
        'is_from_moon_saved', h.is_from_moon_saved
      ) as data,
      h.created_at
    from public.hinoo h
    where h.user_id = p_owner_id
      and h.type = 'personal'::public.hinoo_type
      and (
        'all' = any(allowed_modes)
        or ('home' = any(allowed_modes) and not coalesce(h.is_from_moon_saved, false))
        or ('moon' = any(allowed_modes) and coalesce(h.is_from_moon_saved, false))
      )
  ) shared
  order by shared.created_at desc;
end;
$$;

revoke all on function public.get_shared_house_chest(uuid) from public;
grant execute on function public.get_shared_house_chest(uuid)
  to authenticated;
