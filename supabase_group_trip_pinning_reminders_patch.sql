begin;

alter table public.trip_members
  add column if not exists pinned boolean default false,
  add column if not exists actual_start_time timestamptz;

create table if not exists public.trip_stop_reminders (
  id bigserial primary key,
  trip_stop_id bigint references public.trip_stops(id) on delete cascade,
  trip_id bigint references public.trip_groups(id) on delete cascade,
  user_id uuid references public.profiles(id) on delete cascade,
  remind_time timestamptz not null default now(),
  status text default 'sent',
  sent_at timestamptz default now(),
  created_at timestamptz default now()
);

create index if not exists trip_members_user_pinned_idx
  on public.trip_members(user_id, pinned)
  where status = 'active';

create unique index if not exists trip_stop_reminders_stop_user_idx
  on public.trip_stop_reminders(trip_stop_id, user_id);

create index if not exists trip_stop_reminders_user_trip_idx
  on public.trip_stop_reminders(user_id, trip_id);

alter table public.trip_stop_reminders enable row level security;

drop policy if exists trip_members_update_self_pin on public.trip_members;

create or replace function public.clear_my_group_trip_pins()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.trip_members
  set pinned = false,
      actual_start_time = null
  where user_id = auth.uid()
    and status = 'active'
    and pinned = true;
end;
$$;

create or replace function public.set_my_group_trip_pin(
  p_trip_id bigint,
  p_pinned boolean
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_pinned then
    update public.itineraries
    set pinned = false,
        status = 'draft',
        updated_at = now()
    where profile_id = auth.uid()
      and pinned = true;

    update public.trip_members
    set pinned = false,
        actual_start_time = null
    where user_id = auth.uid()
      and status = 'active'
      and pinned = true;
  end if;

  update public.trip_members
  set pinned = p_pinned,
      actual_start_time = case when p_pinned then now() else null end
  where trip_id = p_trip_id
    and user_id = auth.uid()
    and status = 'active';
end;
$$;

drop policy if exists trip_stop_reminders_select_own on public.trip_stop_reminders;
create policy trip_stop_reminders_select_own
on public.trip_stop_reminders
for select
using (user_id = auth.uid());

drop policy if exists trip_stop_reminders_insert_own_member on public.trip_stop_reminders;
create policy trip_stop_reminders_insert_own_member
on public.trip_stop_reminders
for insert
with check (
  user_id = auth.uid()
  and public.is_trip_member(trip_id, auth.uid())
);

drop policy if exists trip_stop_reminders_update_own on public.trip_stop_reminders;
create policy trip_stop_reminders_update_own
on public.trip_stop_reminders
for update
using (user_id = auth.uid())
with check (user_id = auth.uid());

commit;
