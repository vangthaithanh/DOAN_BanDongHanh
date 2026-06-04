-- GoMate: RLS + trigger patch cho tim và bình luận bài viết.
-- Chạy trong Supabase Dashboard > SQL Editor.
-- Patch này không xóa dữ liệu, có thể chạy lại nhiều lần.

begin;

alter table public.post_likes enable row level security;
alter table public.comments enable row level security;

grant select, insert, delete on public.post_likes to authenticated;
grant select, insert on public.comments to authenticated;
grant usage, select on all sequences in schema public to authenticated;

drop policy if exists post_likes_select_visible_post on public.post_likes;
create policy post_likes_select_visible_post
on public.post_likes
for select
to authenticated
using (public.can_view_post(post_id));

drop policy if exists post_likes_insert_own_visible_post on public.post_likes;
create policy post_likes_insert_own_visible_post
on public.post_likes
for insert
to authenticated
with check (
  profile_id = (select auth.uid())
  and public.can_view_post(post_id)
);

drop policy if exists post_likes_delete_own on public.post_likes;
create policy post_likes_delete_own
on public.post_likes
for delete
to authenticated
using (profile_id = (select auth.uid()));

drop policy if exists comments_select_visible_post on public.comments;
create policy comments_select_visible_post
on public.comments
for select
to authenticated
using (status = 'active' and public.can_view_post(post_id));

drop policy if exists comments_insert_own_visible_post on public.comments;
create policy comments_insert_own_visible_post
on public.comments
for insert
to authenticated
with check (
  profile_id = (select auth.uid())
  and status = 'active'
  and public.can_view_post(post_id)
);

create or replace function public.recount_post_like_count(p_post_id bigint)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.posts p
  set
    like_count = (
      select count(*)::int
      from public.post_likes l
      where l.post_id = p_post_id
    ),
    updated_at = coalesce(p.updated_at, now())
  where p.id = p_post_id;
end;
$$;

create or replace function public.recount_post_comment_count(p_post_id bigint)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.posts p
  set
    comment_count = (
      select count(*)::int
      from public.comments c
      where c.post_id = p_post_id
        and c.status = 'active'
    ),
    updated_at = coalesce(p.updated_at, now())
  where p.id = p_post_id;
end;
$$;

create or replace function public.handle_post_likes_recount()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'DELETE' then
    perform public.recount_post_like_count(old.post_id);
    return old;
  end if;

  perform public.recount_post_like_count(new.post_id);
  return new;
end;
$$;

create or replace function public.handle_comments_recount()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'DELETE' then
    perform public.recount_post_comment_count(old.post_id);
    return old;
  end if;

  perform public.recount_post_comment_count(new.post_id);

  if tg_op = 'UPDATE' and old.post_id <> new.post_id then
    perform public.recount_post_comment_count(old.post_id);
  end if;

  return new;
end;
$$;

drop trigger if exists trg_post_likes_recount on public.post_likes;
create trigger trg_post_likes_recount
after insert or delete on public.post_likes
for each row
execute function public.handle_post_likes_recount();

drop trigger if exists trg_comments_recount on public.comments;
create trigger trg_comments_recount
after insert or update or delete on public.comments
for each row
execute function public.handle_comments_recount();

update public.posts p
set like_count = (
  select count(*)::int
  from public.post_likes l
  where l.post_id = p.id
);

update public.posts p
set comment_count = (
  select count(*)::int
  from public.comments c
  where c.post_id = p.id
    and c.status = 'active'
);

commit;
