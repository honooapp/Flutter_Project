alter table public.house_invites
add column if not exists share_mode text not null default 'honoo';

alter table public.house_invites
drop constraint if exists house_invites_status_check;

alter table public.house_invites
add constraint house_invites_status_check
check (status in ('pending', 'accepted', 'declined'));

alter table public.house_invites
drop constraint if exists house_invites_share_mode_check;

alter table public.house_invites
add constraint house_invites_share_mode_check
check (share_mode in ('honoo', 'hinoo', 'conversations'));

drop policy if exists "Invites update owner status" on public.house_invites;

create policy "Invites update owner status"
  on public.house_invites
  for update
  using (auth.uid() = user_id)
  with check (
    auth.uid() = user_id
    and status in ('pending', 'accepted', 'declined')
  );

drop policy if exists "Case select own" on public."case";

create policy "Case select authenticated"
  on public."case"
  for select
  to authenticated
  using (true);

drop policy if exists "House share select own" on public.house_share_settings;

create policy "House share select authenticated"
  on public.house_share_settings
  for select
  to authenticated
  using (true);
