-- ====================================================================
-- Arabic Couples Game (من أنا؟ • لعبة الأزواج)
-- Complete Supabase Database Schema with Row Level Security (RLS) & Realtime
-- Production Optimized for Low-Latency & High Security
-- ====================================================================

-- 1. Enable pgcrypto for UUID generation
create extension if not exists pgcrypto;

-- 2. Profiles Table
create table if not exists public.profiles (
  id uuid references auth.users on delete cascade primary key,
  display_name text,
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

drop policy if exists "Users can read their own profile" on public.profiles;
create policy "Users can read their own profile"
  on public.profiles for select
  to authenticated
  using ((select auth.uid()) = id);

drop policy if exists "Users can update their own profile" on public.profiles;
create policy "Users can update their own profile"
  on public.profiles for update
  to authenticated
  using ((select auth.uid()) = id)
  with check ((select auth.uid()) = id);

drop policy if exists "Users can insert their own profile" on public.profiles;
create policy "Users can insert their own profile"
  on public.profiles for insert
  to authenticated
  with check ((select auth.uid()) = id);

-- 3. Game Rooms Table
create table if not exists public.game_rooms (
  id uuid primary key default gen_random_uuid(),
  room_code text unique not null,
  status text not null default 'waiting'
    check (status in ('waiting', 'playing', 'finished', 'closed')),
  host_id uuid references auth.users(id) on delete set null,
  guest_id uuid references auth.users(id) on delete set null,
  current_card_index int not null default 0,
  selected_categories text[] not null default '{}',
  round_size int not null default 10,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  expires_at timestamptz not null default (now() + interval '24 hours')
);

-- Fast lookup indexes
create index if not exists game_rooms_code_idx on public.game_rooms(room_code);
create index if not exists game_rooms_status_idx on public.game_rooms(status);
create index if not exists game_rooms_host_id_idx on public.game_rooms(host_id);
create index if not exists game_rooms_guest_id_idx on public.game_rooms(guest_id);
create index if not exists game_rooms_expires_idx on public.game_rooms(expires_at);

alter table public.game_rooms enable row level security;

drop policy if exists "Anyone authenticated can view waiting or participating rooms" on public.game_rooms;
create policy "Anyone authenticated can view waiting or participating rooms"
  on public.game_rooms for select
  to authenticated
  using (
    status = 'waiting' or
    host_id = (select auth.uid()) or
    guest_id = (select auth.uid())
  );

drop policy if exists "Authenticated users can create rooms" on public.game_rooms;
create policy "Authenticated users can create rooms"
  on public.game_rooms for insert
  to authenticated
  with check (host_id = (select auth.uid()));

drop policy if exists "Participants can update room status" on public.game_rooms;
create policy "Participants can update room status"
  on public.game_rooms for update
  to authenticated
  using (
    host_id = (select auth.uid()) or
    guest_id = (select auth.uid()) or
    (status = 'waiting' and guest_id is null)
  )
  with check (
    host_id = (select auth.uid()) or
    guest_id = (select auth.uid()) or
    (status = 'waiting' and guest_id is null)
  );

-- 4. Room Events Table (Realtime multiplayer communication)
create table if not exists public.room_events (
  id bigint generated always as identity primary key,
  room_id uuid not null references public.game_rooms(id) on delete cascade,
  event_type text not null check (event_type in ('joined', 'card_revealed', 'card_skipped', 'card_completed', 'round_finished', 'game_mode_change', 'know_me_action', 'guess_who_action', 'jackaroo_action')),
  card_id text,
  actor_role text not null check (actor_role in ('host', 'guest', 'system')),
  event_data jsonb,
  created_at timestamptz not null default now()
);

create index if not exists room_events_room_id_idx on public.room_events(room_id, created_at desc);

alter table public.room_events enable row level security;

drop policy if exists "Participants can view room events" on public.room_events;
create policy "Participants can view room events"
  on public.room_events for select
  to authenticated
  using (
    exists (
      select 1 from public.game_rooms
      where game_rooms.id = room_events.room_id
      and (game_rooms.host_id = (select auth.uid()) or game_rooms.guest_id = (select auth.uid()) or game_rooms.status = 'waiting')
    )
  );

drop policy if exists "Participants can insert room events" on public.room_events;
create policy "Participants can insert room events"
  on public.room_events for insert
  to authenticated
  with check (
    exists (
      select 1 from public.game_rooms
      where game_rooms.id = room_events.room_id
      and (game_rooms.host_id = (select auth.uid()) or game_rooms.guest_id = (select auth.uid()) or game_rooms.status = 'waiting')
    )
  );

-- 5. User Favorites Sync Table
create table if not exists public.user_favorites (
  user_id uuid primary key references auth.users(id) on delete cascade,
  card_ids text[] not null default '{}',
  updated_at timestamptz not null default now()
);

alter table public.user_favorites enable row level security;

drop policy if exists "Users can manage their own favorites" on public.user_favorites;
create policy "Users can manage their own favorites"
  on public.user_favorites for all
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

-- 6. Enable Realtime Replication Full Identity
alter table public.game_rooms replica identity full;
alter table public.room_events replica identity full;

-- 7. Enable Realtime Publications (Safe & Idempotent for Supabase)
do $$
begin
  if not exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    create publication supabase_realtime;
  end if;

  if not exists (
    select 1 from pg_publication_tables 
    where pubname = 'supabase_realtime' 
      and schemaname = 'public' 
      and tablename = 'game_rooms'
  ) then
    alter publication supabase_realtime add table public.game_rooms;
  end if;

  if not exists (
    select 1 from pg_publication_tables 
    where pubname = 'supabase_realtime' 
      and schemaname = 'public' 
      and tablename = 'room_events'
  ) then
    alter publication supabase_realtime add table public.room_events;
  end if;
end $$;

-- 8. Routine Housekeeping: Expired Game Rooms Cleanup
create or replace function public.cleanup_expired_game_rooms()
returns void
language sql
security definer
set search_path = public
as $$
  delete from public.game_rooms
  where expires_at < now() or status = 'closed';
$$;
