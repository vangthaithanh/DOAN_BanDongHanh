begin;

create table if not exists public.trip_groups (
  id bigserial primary key,
  owner_id uuid references public.profiles(id) on delete cascade,
  title text not null,
  description text,
  start_date date,
  end_date date,
  status text default 'active',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists public.trip_members (
  id bigserial primary key,
  trip_id bigint references public.trip_groups(id) on delete cascade,
  user_id uuid references public.profiles(id) on delete cascade,
  role text default 'member',
  status text default 'active',
  created_at timestamptz default now()
);

create table if not exists public.trip_stops (
  id bigserial primary key,
  trip_id bigint references public.trip_groups(id) on delete cascade,
  place_id bigint references public.places(id) on delete set null,
  title text,
  note text,
  latitude double precision not null,
  longitude double precision not null,
  address text,
  arrive_at timestamptz not null,
  check_radius_m integer default 300,
  sort_order integer default 0,
  status text default 'active',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists public.user_location_snapshots (
  id bigserial primary key,
  user_id uuid references public.profiles(id) on delete cascade,
  latitude double precision not null,
  longitude double precision not null,
  accuracy_m double precision,
  source text default 'gps',
  updated_at timestamptz default now()
);

create table if not exists public.trip_stop_checkins (
  id bigserial primary key,
  trip_stop_id bigint references public.trip_stops(id) on delete cascade,
  trip_id bigint references public.trip_groups(id) on delete cascade,
  user_id uuid references public.profiles(id) on delete cascade,
  distance_m double precision,
  is_arrived boolean default false,
  location_latitude double precision,
  location_longitude double precision,
  checked_at timestamptz default now(),
  status text default 'checked'
);

create index if not exists trip_groups_owner_status_idx
  on public.trip_groups(owner_id, status);

create index if not exists trip_members_user_status_idx
  on public.trip_members(user_id, status);

create index if not exists trip_members_trip_status_idx
  on public.trip_members(trip_id, status);

create unique index if not exists trip_members_trip_user_idx
  on public.trip_members(trip_id, user_id);

create index if not exists trip_stops_trip_status_idx
  on public.trip_stops(trip_id, status);

create unique index if not exists user_location_snapshots_user_id_key
  on public.user_location_snapshots(user_id);

create index if not exists trip_stop_checkins_trip_idx
  on public.trip_stop_checkins(trip_id);

create unique index if not exists trip_stop_checkins_stop_user_idx
  on public.trip_stop_checkins(trip_stop_id, user_id);

create or replace function public.gomate_set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trip_groups_set_updated_at on public.trip_groups;
create trigger trip_groups_set_updated_at
before update on public.trip_groups
for each row execute function public.gomate_set_updated_at();

drop trigger if exists trip_stops_set_updated_at on public.trip_stops;
create trigger trip_stops_set_updated_at
before update on public.trip_stops
for each row execute function public.gomate_set_updated_at();

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

create or replace function public.can_view_trip_user_location(
  p_target_user_id uuid,
  p_current_user_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.trip_members mine
    join public.trip_members target
      on target.trip_id = mine.trip_id
    join public.trip_groups tg
      on tg.id = mine.trip_id
    where mine.user_id = p_current_user_id
      and target.user_id = p_target_user_id
      and mine.status = 'active'
      and target.status = 'active'
      and coalesce(tg.status, 'active') <> 'deleted'
  );
$$;

alter table public.trip_groups enable row level security;
alter table public.trip_members enable row level security;
alter table public.trip_stops enable row level security;
alter table public.user_location_snapshots enable row level security;
alter table public.trip_stop_checkins enable row level security;

drop policy if exists trip_groups_select_members on public.trip_groups;
create policy trip_groups_select_members
on public.trip_groups
for select
using (
  owner_id = auth.uid()
  or public.is_trip_member(id, auth.uid())
);

drop policy if exists trip_groups_insert_owner on public.trip_groups;
create policy trip_groups_insert_owner
on public.trip_groups
for insert
with check (owner_id = auth.uid());

drop policy if exists trip_groups_update_owner on public.trip_groups;
create policy trip_groups_update_owner
on public.trip_groups
for update
using (owner_id = auth.uid())
with check (owner_id = auth.uid());

drop policy if exists trip_groups_delete_owner on public.trip_groups;
create policy trip_groups_delete_owner
on public.trip_groups
for delete
using (owner_id = auth.uid());

drop policy if exists trip_members_select_same_group on public.trip_members;
create policy trip_members_select_same_group
on public.trip_members
for select
using (
  public.is_trip_member(trip_id, auth.uid())
  or public.is_trip_owner(trip_id, auth.uid())
);

drop policy if exists trip_members_insert_owner on public.trip_members;
create policy trip_members_insert_owner
on public.trip_members
for insert
with check (public.is_trip_owner(trip_id, auth.uid()));

drop policy if exists trip_members_update_owner on public.trip_members;
create policy trip_members_update_owner
on public.trip_members
for update
using (public.is_trip_owner(trip_id, auth.uid()))
with check (public.is_trip_owner(trip_id, auth.uid()));

drop policy if exists trip_members_delete_owner on public.trip_members;
create policy trip_members_delete_owner
on public.trip_members
for delete
using (public.is_trip_owner(trip_id, auth.uid()));

drop policy if exists trip_stops_select_members on public.trip_stops;
create policy trip_stops_select_members
on public.trip_stops
for select
using (
  public.is_trip_member(trip_id, auth.uid())
  or public.is_trip_owner(trip_id, auth.uid())
);

drop policy if exists trip_stops_insert_owner on public.trip_stops;
create policy trip_stops_insert_owner
on public.trip_stops
for insert
with check (public.is_trip_owner(trip_id, auth.uid()));

drop policy if exists trip_stops_update_owner on public.trip_stops;
create policy trip_stops_update_owner
on public.trip_stops
for update
using (public.is_trip_owner(trip_id, auth.uid()))
with check (public.is_trip_owner(trip_id, auth.uid()));

drop policy if exists trip_stops_delete_owner on public.trip_stops;
create policy trip_stops_delete_owner
on public.trip_stops
for delete
using (public.is_trip_owner(trip_id, auth.uid()));

drop policy if exists user_location_snapshots_select_group_members on public.user_location_snapshots;
create policy user_location_snapshots_select_group_members
on public.user_location_snapshots
for select
using (
  user_id = auth.uid()
  or public.can_view_trip_user_location(user_id, auth.uid())
);

drop policy if exists user_location_snapshots_insert_own on public.user_location_snapshots;
create policy user_location_snapshots_insert_own
on public.user_location_snapshots
for insert
with check (user_id = auth.uid());

drop policy if exists user_location_snapshots_update_own on public.user_location_snapshots;
create policy user_location_snapshots_update_own
on public.user_location_snapshots
for update
using (user_id = auth.uid())
with check (user_id = auth.uid());

drop policy if exists user_location_snapshots_delete_own on public.user_location_snapshots;
create policy user_location_snapshots_delete_own
on public.user_location_snapshots
for delete
using (user_id = auth.uid());

drop policy if exists trip_stop_checkins_select_members on public.trip_stop_checkins;
create policy trip_stop_checkins_select_members
on public.trip_stop_checkins
for select
using (
  public.is_trip_member(trip_id, auth.uid())
  or public.is_trip_owner(trip_id, auth.uid())
);

drop policy if exists trip_stop_checkins_insert_members on public.trip_stop_checkins;
create policy trip_stop_checkins_insert_members
on public.trip_stop_checkins
for insert
with check (
  (
    public.is_trip_member(trip_id, auth.uid())
    or public.is_trip_owner(trip_id, auth.uid())
  )
  and public.is_trip_member(trip_id, user_id)
);

drop policy if exists trip_stop_checkins_update_members on public.trip_stop_checkins;
create policy trip_stop_checkins_update_members
on public.trip_stop_checkins
for update
using (
  public.is_trip_member(trip_id, auth.uid())
  or public.is_trip_owner(trip_id, auth.uid())
)
with check (
  (
    public.is_trip_member(trip_id, auth.uid())
    or public.is_trip_owner(trip_id, auth.uid())
  )
  and public.is_trip_member(trip_id, user_id)
);

drop policy if exists trip_stop_checkins_delete_owner on public.trip_stop_checkins;
create policy trip_stop_checkins_delete_owner
on public.trip_stop_checkins
for delete
using (public.is_trip_owner(trip_id, auth.uid()));

commit;
