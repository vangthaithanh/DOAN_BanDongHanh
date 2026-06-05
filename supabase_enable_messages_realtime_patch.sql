-- Enable Supabase Realtime events for message inserts/updates.
-- Run once in Supabase SQL Editor if message list/chat does not auto-update.

begin;

do $$
begin
  alter publication supabase_realtime add table public.messages;
exception
  when duplicate_object then null;
  when undefined_object then null;
end $$;

commit;
