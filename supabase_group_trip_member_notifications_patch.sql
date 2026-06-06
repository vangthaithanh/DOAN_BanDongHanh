-- Create notifications when a user is added to a group itinerary.
-- Run in Supabase SQL Editor.

begin;

alter table public.notifications
  add column if not exists reference_id bigint;

create or replace function public.create_group_trip_member_notification()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  trip_title text;
  trip_owner_id uuid;
  owner_name text;
begin
  if coalesce(new.status, 'active') <> 'active'
     or coalesce(new.role, 'member') = 'owner' then
    return new;
  end if;

  select
    tg.title,
    tg.owner_id
  into
    trip_title,
    trip_owner_id
  from public.trip_groups tg
  where tg.id = new.trip_id;

  if trip_owner_id is null or new.user_id = trip_owner_id then
    return new;
  end if;

  select coalesce(
    nullif(trim(p.nickname), ''),
    nullif(trim(p.full_name), ''),
    nullif(split_part(p.email, '@', 1), ''),
    'Người dùng'
  )
  into owner_name
  from public.profiles p
  where p.id = trip_owner_id;

  insert into public.notifications(
    profile_id,
    notification_type,
    title,
    content,
    reference_id,
    is_read
  )
  values (
    new.user_id,
    'group_trip_member_added',
    coalesce(owner_name, 'Người dùng'),
    'đã thêm bạn vào lịch trình nhóm "' ||
      coalesce(nullif(trim(trip_title), ''), 'Lịch trình nhóm') || '"',
    new.trip_id,
    false
  );

  return new;
end;
$$;

drop trigger if exists trip_members_after_insert_notification on public.trip_members;
create trigger trip_members_after_insert_notification
after insert on public.trip_members
for each row
execute function public.create_group_trip_member_notification();

drop trigger if exists trip_members_after_update_notification on public.trip_members;
create trigger trip_members_after_update_notification
after update of status, role on public.trip_members
for each row
when (
  old.status is distinct from new.status
  or old.role is distinct from new.role
)
execute function public.create_group_trip_member_notification();

commit;
