-- The storage policies reference these buckets, but policies do not create
-- bucket rows. Keep both content buckets available in every environment.
insert into storage.buckets (id, name, public)
values
  ('honoo-images', 'honoo-images', true),
  ('hinoo', 'hinoo', true)
on conflict (id) do update
set
  name = excluded.name,
  public = excluded.public;
