-- Fix posts that were created with local time but stored as UTC.
-- Run once in Supabase SQL Editor if existing posts keep showing "Vừa xong".

begin;

update public.posts
set
  created_at = created_at - interval '7 hours',
  updated_at = case
    when updated_at is null then updated_at
    when updated_at > now() + interval '5 minutes' then updated_at - interval '7 hours'
    else updated_at
  end
where created_at > now() + interval '5 minutes';

commit;
