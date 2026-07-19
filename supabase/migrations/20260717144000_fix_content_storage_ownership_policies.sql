drop policy if exists "Owners can delete their objects" on storage.objects;
create policy "Owners can delete their objects"
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'honoo-images'
  and split_part(name, '/', 1) = auth.uid()::text
);

drop policy if exists "Owners can update their objects" on storage.objects;
create policy "Owners can update their objects"
on storage.objects
for update
to authenticated
using (
  bucket_id = 'honoo-images'
  and split_part(name, '/', 1) = auth.uid()::text
)
with check (
  bucket_id = 'honoo-images'
  and split_part(name, '/', 1) = auth.uid()::text
);
