create or replace function public.admin_daily_content_counts()
returns table (
  chest_honoo integer,
  chest_hinoo integer,
  moon_honoo integer,
  moon_hinoo integer,
  reply_honoo integer,
  reply_hinoo integer
)
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_admin() then
    raise exception 'Not authorized';
  end if;

  return query
  select
    (select count(*)
     from public.honoo
     where destination = 'chest'
       and created_at::date = current_date) as chest_honoo,
    (select count(*)
     from public.hinoo
     where type = 'personal'
       and created_at::date = current_date) as chest_hinoo,
    (select count(*)
     from public.honoo
     where destination = 'moon'
       and created_at::date = current_date) as moon_honoo,
    (select count(*)
     from public.hinoo
     where type = 'moon'
       and created_at::date = current_date) as moon_hinoo,
    (select count(*)
     from public.honoo
     where destination = 'reply'
       and created_at::date = current_date) as reply_honoo,
    (select count(*)
     from public.hinoo
     where type = 'answer'
       and created_at::date = current_date) as reply_hinoo;
end;
$$;

revoke all on function public.admin_daily_content_counts() from public;
grant execute on function public.admin_daily_content_counts() to authenticated;
