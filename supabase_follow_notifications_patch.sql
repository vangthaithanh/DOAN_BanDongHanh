-- Create real notifications when one profile follows another profile.
-- Run in Supabase SQL Editor.

begin;

create table if not exists public.notifications (
  id bigserial primary key,
  profile_id uuid not null references public.profiles(id) on delete cascade,
  notification_type text not null,
  title text not null,
  content text not null,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

alter table public.notifications enable row level security;

drop policy if exists "notifications_select_own" on public.notifications;
create policy "notifications_select_own"
on public.notifications
for select
to authenticated
using (profile_id = (select auth.uid()));

drop policy if exists "notifications_update_own" on public.notifications;
create policy "notifications_update_own"
on public.notifications
for update
to authenticated
using (profile_id = (select auth.uid()))
with check (profile_id = (select auth.uid()));

create or replace function public.create_follow_notification()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  follower_name text;
begin
  if new.status <> 'active' or new.follower_id = new.following_id then
    return new;
  end if;

  select coalesce(
    nullif(trim(p.nickname), ''),
    nullif(trim(p.full_name), ''),
    nullif(split_part(p.email, '@', 1), ''),
    'Người dùng'
  )
  into follower_name
  from public.profiles p
  where p.id = new.follower_id;

  insert into public.notifications(
    profile_id,
    notification_type,
    title,
    content,
    is_read
  )
  values (
    new.following_id,
    'follow',
    coalesce(follower_name, 'Người dùng'),
    'đã theo dõi bạn',
    false
  );

  return new;
end;
$$;

drop trigger if exists follows_after_insert_notification on public.follows;
create trigger follows_after_insert_notification
after insert on public.follows
for each row
execute function public.create_follow_notification();

drop trigger if exists follows_after_update_notification on public.follows;
create trigger follows_after_update_notification
after update of status on public.follows
for each row
when (old.status is distinct from new.status)
execute function public.create_follow_notification();

insert into public.notifications(
  profile_id,
  notification_type,
  title,
  content,
  is_read
)
select
  f.following_id,
  'follow',
  coalesce(
    nullif(trim(p.nickname), ''),
    nullif(trim(p.full_name), ''),
    nullif(split_part(p.email, '@', 1), ''),
    'Người dùng'
  ),
  'đã theo dõi bạn',
  false
from public.follows f
join public.profiles p on p.id = f.follower_id
where f.status = 'active'
  and f.follower_id <> f.following_id
  and not exists (
    select 1
    from public.notifications n
    where n.profile_id = f.following_id
      and n.notification_type = 'follow'
      and n.title = coalesce(
        nullif(trim(p.nickname), ''),
        nullif(trim(p.full_name), ''),
        nullif(split_part(p.email, '@', 1), ''),
        'Người dùng'
      )
      and n.content = 'đã theo dõi bạn'
  );

commit;
