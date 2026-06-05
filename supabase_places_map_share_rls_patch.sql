-- Fix quyen cho map dia diem rieng: sua/xoa/share.
-- Nghiep vu hien tai: share cho ban be la copy dia diem ngay, khong can nguoi nhan xac nhan.
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
  status text not null default 'accepted',
  created_at timestamptz not null default now(),
  accepted_at timestamptz,
  rejected_at timestamptz
);

alter table public.place_shares
  alter column status set default 'accepted';

create index if not exists idx_places_user_status
on public.places(user_id, status);

create table if not exists public.notifications (
  id bigserial primary key,
  profile_id uuid references public.profiles(id) on delete cascade,
  notification_type text,
  title text,
  content text,
  reference_id bigint,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

alter table public.notifications
  add column if not exists profile_id uuid references public.profiles(id) on delete cascade,
  add column if not exists notification_type text,
  add column if not exists title text,
  add column if not exists content text,
  add column if not exists reference_id bigint,
  add column if not exists is_read boolean not null default false,
  add column if not exists created_at timestamptz not null default now();

-- Chuyen cac loi moi pending cu sang nghiep vu moi: copy ngay vao map nguoi nhan.
insert into public.places (
  category_id,
  user_id,
  copied_from_place_id,
  name,
  province,
  district,
  address,
  latitude,
  longitude,
  opening_hours,
  price,
  avg_rating,
  total_reviews,
  total_saves,
  keywords,
  description,
  cover_image,
  status,
  updated_at
)
select
  p.category_id,
  ps.to_user_id,
  p.id,
  p.name,
  p.province,
  p.district,
  p.address,
  p.latitude,
  p.longitude,
  p.opening_hours,
  p.price,
  p.avg_rating,
  p.total_reviews,
  p.total_saves,
  p.keywords,
  p.description,
  p.cover_image,
  'active',
  now()
from public.place_shares ps
join public.places p
  on p.id = ps.place_id
where ps.status = 'pending'
  and p.status = 'active'
  and p.user_id = ps.from_user_id
  and not exists (
    select 1
    from public.places existing
    where existing.user_id = ps.to_user_id
      and existing.copied_from_place_id = p.id
      and existing.status = 'active'
  );

update public.place_shares
set
  status = 'accepted',
  accepted_at = coalesce(accepted_at, now()),
  rejected_at = null
where status = 'pending';

update public.notifications n
set reference_id = (
  select p.id
  from public.places p
  where p.user_id = n.profile_id
    and p.copied_from_place_id is not null
    and p.status = 'active'
    and (
      n.content is null
      or n.content ilike '%' || p.name || '%'
    )
  order by p.updated_at desc nulls last, p.id desc
  limit 1
)
where n.notification_type = 'place_share'
  and n.reference_id is null
  and exists (
    select 1
    from public.places p
    where p.user_id = n.profile_id
      and p.copied_from_place_id is not null
      and p.status = 'active'
      and (
        n.content is null
        or n.content ilike '%' || p.name || '%'
      )
  );

update public.notifications n
set reference_id = (
  select i.id
  from public.itineraries i
  where i.profile_id = n.profile_id
    and i.pinned = true
  order by i.updated_at desc nulls last, i.id desc
  limit 1
)
where n.notification_type = 'itinerary_reminder'
  and n.reference_id is null
  and exists (
    select 1
    from public.itineraries i
    where i.profile_id = n.profile_id
      and i.pinned = true
  );

create index if not exists idx_place_shares_to_status
on public.place_shares(to_user_id, status, created_at desc);

drop index if exists public.idx_place_shares_pending_unique;

delete from public.place_shares old_share
using public.place_shares keep_share
where old_share.status = 'accepted'
  and keep_share.status = 'accepted'
  and old_share.place_id = keep_share.place_id
  and old_share.from_user_id = keep_share.from_user_id
  and old_share.to_user_id = keep_share.to_user_id
  and old_share.id < keep_share.id;

create unique index if not exists idx_place_shares_accepted_unique
on public.place_shares(place_id, from_user_id, to_user_id)
where status = 'accepted';

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

drop trigger if exists place_shares_after_insert_notification on public.place_shares;
drop function if exists public.create_place_share_notification();

create or replace function public.share_place_direct(
  p_place_id bigint,
  p_to_user_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_from_user_id uuid := auth.uid();
  source_place public.places%rowtype;
  copied_place_id bigint;
  share_row_id bigint;
  sender_name text;
  shared_place_name text;
  already_exists boolean := false;
begin
  if v_from_user_id is null then
    raise exception 'Bạn cần đăng nhập để chia sẻ địa điểm';
  end if;

  if p_to_user_id is null or p_to_user_id = v_from_user_id then
    raise exception 'Người nhận chia sẻ không hợp lệ';
  end if;

  select *
  into source_place
  from public.places p
  where p.id = p_place_id
    and p.user_id = v_from_user_id
    and p.status = 'active';

  if not found then
    raise exception 'Chỉ được chia sẻ địa điểm riêng đang hoạt động của bạn';
  end if;

  if not exists (
    select 1
    from public.follows f1
    join public.follows f2
      on f2.follower_id = p_to_user_id
     and f2.following_id = v_from_user_id
     and f2.status = 'active'
    where f1.follower_id = v_from_user_id
      and f1.following_id = p_to_user_id
      and f1.status = 'active'
  ) then
    raise exception 'Chỉ có thể chia sẻ địa điểm cho bạn bè';
  end if;

  select p.id
  into copied_place_id
  from public.places p
  where p.user_id = p_to_user_id
    and p.copied_from_place_id = p_place_id
    and p.status = 'active'
  order by p.id desc
  limit 1;

  if copied_place_id is not null then
    already_exists := true;
  else
    insert into public.places (
      category_id,
      user_id,
      copied_from_place_id,
      name,
      province,
      district,
      address,
      latitude,
      longitude,
      opening_hours,
      price,
      avg_rating,
      total_reviews,
      total_saves,
      keywords,
      description,
      cover_image,
      status,
      updated_at
    )
    values (
      source_place.category_id,
      p_to_user_id,
      source_place.id,
      source_place.name,
      source_place.province,
      source_place.district,
      source_place.address,
      source_place.latitude,
      source_place.longitude,
      source_place.opening_hours,
      source_place.price,
      source_place.avg_rating,
      source_place.total_reviews,
      source_place.total_saves,
      source_place.keywords,
      source_place.description,
      source_place.cover_image,
      'active',
      now()
    )
    returning id into copied_place_id;
  end if;

  select ps.id
  into share_row_id
  from public.place_shares ps
  where ps.place_id = p_place_id
    and ps.from_user_id = v_from_user_id
    and ps.to_user_id = p_to_user_id
    and ps.status in ('pending', 'accepted')
  order by ps.created_at desc
  limit 1;

  if share_row_id is null then
    insert into public.place_shares (
      place_id,
      from_user_id,
      to_user_id,
      status,
      accepted_at
    )
    values (
      p_place_id,
      v_from_user_id,
      p_to_user_id,
      'accepted',
      now()
    )
    returning id into share_row_id;
  else
    update public.place_shares
    set
      status = 'accepted',
      accepted_at = coalesce(accepted_at, now()),
      rejected_at = null
    where id = share_row_id;
  end if;

  select coalesce(
    nullif(trim(p.nickname), ''),
    nullif(trim(p.full_name), ''),
    nullif(split_part(p.email, '@', 1), ''),
    'Người dùng'
  )
  into sender_name
  from public.profiles p
  where p.id = v_from_user_id;

  shared_place_name := coalesce(nullif(trim(source_place.name), ''), 'một địa điểm');

  if not already_exists
  and exists (
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
  )
  and exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'notifications'
      and column_name = 'reference_id'
  ) then
    insert into public.notifications (
      profile_id,
      notification_type,
      title,
      content,
      reference_id,
      is_read
    )
    values (
      p_to_user_id,
      'place_share',
      coalesce(sender_name, 'Người dùng'),
      'đã chia sẻ địa điểm "' || coalesce(shared_place_name, 'một địa điểm') || '" vào bản đồ của bạn',
      copied_place_id,
      false
    );
  end if;

  return jsonb_build_object(
    'copied_place_id', copied_place_id,
    'share_id', share_row_id,
    'already_exists', already_exists
  );
end;
$$;

revoke all on function public.share_place_direct(bigint, uuid) from public;
grant execute on function public.share_place_direct(bigint, uuid) to authenticated;

commit;
