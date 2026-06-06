begin;

create or replace function public.is_trip_member(
  p_trip_id bigint,
  p_user_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.trip_members tm
    join public.trip_groups tg on tg.id = tm.trip_id
    where tm.trip_id = p_trip_id
      and tm.user_id = p_user_id
      and tm.status = 'active'
      and coalesce(tg.status, 'active') <> 'deleted'
  );
$$;

create or replace function public.is_trip_owner(
  p_trip_id bigint,
  p_user_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.trip_groups tg
    where tg.id = p_trip_id
      and tg.owner_id = p_user_id
      and coalesce(tg.status, 'active') <> 'deleted'
  );
$$;

drop policy if exists trip_groups_select_members on public.trip_groups;
create policy trip_groups_select_members
on public.trip_groups
for select
using (
  owner_id = auth.uid()
  or public.is_trip_member(id, auth.uid())
);

drop policy if exists trip_members_select_same_group on public.trip_members;
create policy trip_members_select_same_group
on public.trip_members
for select
using (
  public.is_trip_member(trip_id, auth.uid())
  or public.is_trip_owner(trip_id, auth.uid())
);

drop policy if exists trip_stops_select_members on public.trip_stops;
create policy trip_stops_select_members
on public.trip_stops
for select
using (
  public.is_trip_member(trip_id, auth.uid())
  or public.is_trip_owner(trip_id, auth.uid())
);

drop policy if exists trip_stop_checkins_select_members on public.trip_stop_checkins;
create policy trip_stop_checkins_select_members
on public.trip_stop_checkins
for select
using (
  public.is_trip_member(trip_id, auth.uid())
  or public.is_trip_owner(trip_id, auth.uid())
);

commit;
