-- Add multi-share support to house_share_settings
-- - Adds text[] column share_modes to allow multiple selections
-- - Keeps legacy share_mode for backward compatibility

alter table if exists public.house_share_settings
  add column if not exists share_modes text[];

-- Optional backfill: if share_modes is null and share_mode present, seed array
update public.house_share_settings
  set share_modes = array[share_mode]::text[]
  where share_modes is null and share_mode is not null;

-- No changes to RLS policies are required; existing select/update policies still apply.

