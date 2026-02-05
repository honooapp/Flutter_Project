alter table public.house_invites
drop column if exists share_mode;

alter table public.house_invites
drop constraint if exists house_invites_share_mode_check;
