-- Support real message unread counts and message notifications.
-- Run in Supabase SQL Editor.

begin;

alter table public.conversation_members
  add column if not exists last_read_at timestamptz;

create index if not exists idx_messages_conversation_sent_at
on public.messages(conversation_id, sent_at desc);

create index if not exists idx_conversation_members_profile
on public.conversation_members(profile_id, conversation_id);

create index if not exists idx_follows_pair_status
on public.follows(follower_id, following_id, status);

create or replace function public.create_message_notification()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  sender_name text;
begin
  select coalesce(
    nullif(trim(p.nickname), ''),
    nullif(trim(p.full_name), ''),
    nullif(split_part(p.email, '@', 1), ''),
    'Người dùng'
  )
  into sender_name
  from public.profiles p
  where p.id = new.sender_profile_id;

  insert into public.notifications(
    profile_id,
    notification_type,
    title,
    content,
    is_read
  )
  select
    cm.profile_id,
    'message',
    coalesce(sender_name, 'Người dùng'),
    'đã gửi tin nhắn cho bạn',
    false
  from public.conversation_members cm
  where cm.conversation_id = new.conversation_id
    and cm.profile_id <> new.sender_profile_id
    and cm.status = 'active';

  return new;
end;
$$;

drop trigger if exists messages_after_insert_notification on public.messages;
create trigger messages_after_insert_notification
after insert on public.messages
for each row
execute function public.create_message_notification();

commit;
