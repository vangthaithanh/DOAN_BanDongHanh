-- Fix quyen cho map dia diem rieng: sua/xoa/share.
-- Chay trong Supabase SQL Editor.

begin;

alter table public.places
  add column if not exists user_id uuid references public.profiles(id) on delete cascade,
  add column if not exists copied_from_place_id bigint references public.places(id) on delete set null,
  add column if not exists cover_image text,
  add column if not exists updated_at timestamptz default now();

create table if not exists public.place_shares (
  id bigserial primary key,
  place_id bigint not null references public.places(id) on delete cascade,
  from_user_id uuid not null references public.profiles(id) on delete cascade,
  to_user_id uuid not null references public.profiles(id) on delete cascade,
  status text not null default 'pending',
  created_at timestamptz not null default now(),
  accepted_at timestamptz,
  rejected_at timestamptz
);

create index if not exists idx_places_user_status
on public.places(user_id, status);

create index if not exists idx_place_shares_to_status
on public.place_shares(to_user_id, status, created_at desc);

delete from public.place_shares old_share
using public.place_shares keep_share
where old_share.status = 'pending'
  and keep_share.status = 'pending'
  and old_share.place_id = keep_share.place_id
  and old_share.from_user_id = keep_share.from_user_id
  and old_share.to_user_id = keep_share.to_user_id
  and old_share.id < keep_share.id;

create unique index if not exists idx_place_shares_pending_unique
on public.place_shares(place_id, from_user_id, to_user_id)
where status = 'pending';

create table if not exists public.notifications (
  id bigserial primary key,
  profile_id uuid references public.profiles(id) on delete cascade,
  notification_type text,
  title text,
  content text,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

alter table public.notifications
  add column if not exists profile_id uuid references public.profiles(id) on delete cascade,
  add column if not exists notification_type text,
  add column if not exists title text,
  add column if not exists content text,
  add column if not exists is_read boolean not null default false,
  add column if not exists created_at timestamptz not null default now();

alter table public.places enable row level security;
alter table public.place_shares enable row level security;

drop policy if exists "places_select_public_or_own" on public.places;
create policy "places_select_public_or_own"
on public.places
for select
to authenticated
using (
  status = 'active'
  and (
    user_id is null
    or user_id = (select auth.uid())
  )
);

drop policy if exists "places_select_public_anon" on public.places;
create policy "places_select_public_anon"
on public.places
for select
to anon
using (
  status = 'active'
  and user_id is null
);

drop policy if exists "places_insert_own" on public.places;
create policy "places_insert_own"
on public.places
for insert
to authenticated
with check (
  user_id = (select auth.uid())
  and status in ('active', 'draft')
);

drop policy if exists "places_update_own" on public.places;
create policy "places_update_own"
on public.places
for update
to authenticated
using (user_id = (select auth.uid()))
with check (user_id = (select auth.uid()));

drop policy if exists "places_delete_own" on public.places;
create policy "places_delete_own"
on public.places
for delete
to authenticated
using (user_id = (select auth.uid()));

drop policy if exists "place_shares_select_related" on public.place_shares;
create policy "place_shares_select_related"
on public.place_shares
for select
to authenticated
using (
  from_user_id = (select auth.uid())
  or to_user_id = (select auth.uid())
);

drop policy if exists "place_shares_insert_own_place" on public.place_shares;
create policy "place_shares_insert_own_place"
on public.place_shares
for insert
to authenticated
with check (
  from_user_id = (select auth.uid())
  and to_user_id <> (select auth.uid())
  and status = 'pending'
  and exists (
    select 1
    from public.places p
    where p.id = place_id
      and p.user_id = (select auth.uid())
      and p.status = 'active'
  )
);

drop policy if exists "place_shares_update_related" on public.place_shares;
create policy "place_shares_update_related"
on public.place_shares
for update
to authenticated
using (
  from_user_id = (select auth.uid())
  or to_user_id = (select auth.uid())
)
with check (
  from_user_id = (select auth.uid())
  or to_user_id = (select auth.uid())
);

create or replace function public.create_place_share_notification()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  sender_name text;
  shared_place_name text;
begin
  if new.status <> 'pending' then
    return new;
  end if;

  select coalesce(
    nullif(trim(p.nickname), ''),
    nullif(trim(p.full_name), ''),
    nullif(split_part(p.email, '@', 1), ''),
    'Người dùng'
  )
  into sender_name
  from public.profiles p
  where p.id = new.from_user_id;

  select coalesce(nullif(trim(pl.name), ''), 'một địa điểm')
  into shared_place_name
  from public.places pl
  where pl.id = new.place_id;

  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'notifications'
      and column_name = 'profile_id'
  )
  and exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'notifications'
      and column_name = 'notification_type'
  )
  and exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'notifications'
      and column_name = 'title'
  )
  and exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'notifications'
      and column_name = 'content'
  ) then
    insert into public.notifications (
      profile_id,
      notification_type,
      title,
      content,
      is_read
    )
    values (
      new.to_user_id,
      'place_share',
      coalesce(sender_name, 'Người dùng'),
      'đã chia sẻ địa điểm "' || coalesce(shared_place_name, 'một địa điểm') || '" cho bạn',
      false
    );
  end if;

  return new;
end;
$$;

drop trigger if exists place_shares_after_insert_notification on public.place_shares;
create trigger place_shares_after_insert_notification
after insert on public.place_shares
for each row
execute function public.create_place_share_notification();

commit;
