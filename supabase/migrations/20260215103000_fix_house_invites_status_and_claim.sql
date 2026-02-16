alter table public.house_invites
  drop constraint if exists house_invites_status_check;

alter table public.house_invites
  add constraint house_invites_status_check
  check (status = any (array['pending'::text, 'accepted'::text, 'declined'::text]));

create or replace function public.claim_house_invite_by_email(p_email text)
returns int
language plpgsql
security definer
as $$
declare
  updated_count int;
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  if p_email is null or length(trim(p_email)) = 0 then
    return 0;
  end if;

  update public.house_invites
  set user_id = auth.uid()
  where user_id is null
    and lower(email) = lower(p_email)
    and status in ('pending', 'accepted', 'declined');

  get diagnostics updated_count = row_count;
  return updated_count;
end;
$$;

revoke all on function public.claim_house_invite_by_email(text) from public;
grant execute on function public.claim_house_invite_by_email(text) to authenticated;
