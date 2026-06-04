-- GoMate: RLS patch cho luồng tạo bài viết thật từ Flutter.
-- Chạy trong Supabase Dashboard > SQL Editor.
-- Patch này không xóa dữ liệu và chỉ mở quyền theo owner auth.uid().

begin;

alter table public.posts enable row level security;
alter table public.post_media enable row level security;
alter table public.hashtags enable row level security;
alter table public.post_hashtags enable row level security;
alter table public.post_place_tags enable row level security;

grant select, insert on public.posts to authenticated;
grant select, insert on public.post_media to authenticated;
grant select, insert on public.hashtags to authenticated;
grant select, insert on public.post_hashtags to authenticated;
grant select, insert on public.post_place_tags to authenticated;
grant usage, select on all sequences in schema public to authenticated;

drop policy if exists posts_insert_own_active on public.posts;
create policy posts_insert_own_active
on public.posts
for insert
to authenticated
with check (
  profile_id = (select auth.uid())
  and status = 'active'
  and visibility in ('public', 'follower', 'private')
);

drop policy if exists post_media_select_visible_post on public.post_media;
create policy post_media_select_visible_post
on public.post_media
for select
to authenticated
using (public.can_view_post(post_id));

drop policy if exists post_media_insert_own_post on public.post_media;
create policy post_media_insert_own_post
on public.post_media
for insert
to authenticated
with check (
  exists (
    select 1
    from public.posts p
    where p.id = post_media.post_id
      and p.profile_id = (select auth.uid())
  )
);

drop policy if exists hashtags_select_active on public.hashtags;
create policy hashtags_select_active
on public.hashtags
for select
to authenticated
using (status = 'active');

drop policy if exists hashtags_insert_active on public.hashtags;
create policy hashtags_insert_active
on public.hashtags
for insert
to authenticated
with check (status = 'active');

drop policy if exists post_hashtags_select_visible_post on public.post_hashtags;
create policy post_hashtags_select_visible_post
on public.post_hashtags
for select
to authenticated
using (public.can_view_post(post_id));

drop policy if exists post_hashtags_insert_own_post on public.post_hashtags;
create policy post_hashtags_insert_own_post
on public.post_hashtags
for insert
to authenticated
with check (
  exists (
    select 1
    from public.posts p
    where p.id = post_hashtags.post_id
      and p.profile_id = (select auth.uid())
  )
);

drop policy if exists post_place_tags_select_visible_post on public.post_place_tags;
create policy post_place_tags_select_visible_post
on public.post_place_tags
for select
to authenticated
using (public.can_view_post(post_id));

drop policy if exists post_place_tags_insert_own_post on public.post_place_tags;
create policy post_place_tags_insert_own_post
on public.post_place_tags
for insert
to authenticated
with check (
  exists (
    select 1
    from public.posts p
    where p.id = post_place_tags.post_id
      and p.profile_id = (select auth.uid())
  )
);

drop policy if exists "post_media_public_read" on storage.objects;
create policy "post_media_public_read"
on storage.objects
for select
to public
using (bucket_id = 'post-media');

drop policy if exists "post_media_upload_own_folder" on storage.objects;
create policy "post_media_upload_own_folder"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'post-media'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);

drop policy if exists "post_media_update_own_folder" on storage.objects;
create policy "post_media_update_own_folder"
on storage.objects
for update
to authenticated
using (
  bucket_id = 'post-media'
  and (storage.foldername(name))[1] = (select auth.uid())::text
)
with check (
  bucket_id = 'post-media'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);

commit;
