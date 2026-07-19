-- Production-safe alignment: additive and idempotent only.
-- Intentionally contains no UPDATE/DELETE, policy changes, or changes to
-- existing Storage buckets. Existing production content is not touched.

alter table if exists public.house_share_settings
  add column if not exists share_modes text[];

-- Create only the buckets required by the current client when they are
-- missing. ON CONFLICT DO NOTHING preserves any existing bucket settings.
insert into storage.buckets (id, name, public)
values
  ('honoo-images', 'honoo-images', true),
  ('hinoo', 'hinoo', true)
on conflict (id) do nothing;
