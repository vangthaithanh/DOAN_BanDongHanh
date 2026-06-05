-- Tao bucket anh cho dia diem rieng tren map.
-- Chay trong Supabase SQL Editor neu app bao "Bucket not found" voi place-images.

insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values (
  'place-images',
  'place-images',
  true,
  10485760,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update
set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "place images public read" on storage.objects;
drop policy if exists "place images authenticated upload own folder" on storage.objects;
drop policy if exists "place images authenticated update own folder" on storage.objects;
drop policy if exists "place images authenticated delete own folder" on storage.objects;

create policy "place images public read"
on storage.objects
for select
using (bucket_id = 'place-images');

create policy "place images authenticated upload own folder"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'place-images'
  and (storage.foldername(name))[1] = auth.uid()::text
);

create policy "place images authenticated update own folder"
on storage.objects
for update
to authenticated
using (
  bucket_id = 'place-images'
  and (storage.foldername(name))[1] = auth.uid()::text
)
with check (
  bucket_id = 'place-images'
  and (storage.foldername(name))[1] = auth.uid()::text
);

create policy "place images authenticated delete own folder"
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'place-images'
  and (storage.foldername(name))[1] = auth.uid()::text
);
