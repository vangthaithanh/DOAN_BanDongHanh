-- Them reference_id de notification co the link toi dung man hinh.
-- place_share.reference_id = id dia diem copy cua nguoi nhan.
-- itinerary_reminder.reference_id = id lich trinh.

begin;

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
  add column if not exists reference_id bigint;

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
  order by p.id desc
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
  order by i.id desc
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

commit;
