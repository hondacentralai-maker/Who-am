-- ====================================================================
-- Arabic Couples Game (من أنا؟ • لعبة الأزواج)
-- Complete Supabase Database Schema with Row Level Security (RLS) & Realtime
-- ====================================================================

-- 1. Enable pgcrypto for UUIDs
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

create policy "Users can read their own profile"
  on public.profiles for select
  using (auth.uid() = id);

create policy "Users can update their own profile"
  on public.profiles for update
  using (auth.uid() = id);

create policy "Users can insert their own profile"
  on public.profiles for insert
  with check (auth.uid() = id);

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

create index if not exists game_rooms_code_idx on public.game_rooms(room_code);
create index if not exists game_rooms_status_idx on public.game_rooms(status);

alter table public.game_rooms enable row level security;

create policy "Anyone authenticated can view waiting or participating rooms"
  on public.game_rooms for select
  using (
    auth.role() = 'authenticated' and (
      status = 'waiting' or
      host_id = auth.uid() or
      guest_id = auth.uid()
    )
  );

create policy "Authenticated users can create rooms"
  on public.game_rooms for insert
  with check (auth.role() = 'authenticated');

create policy "Participants can update room status"
  on public.game_rooms for update
  using (
    auth.role() = 'authenticated' and (
      host_id = auth.uid() or
      guest_id = auth.uid() or
      (status = 'waiting' and guest_id is null)
    )
  );

-- 4. Room Events Table (Realtime communication)
create table if not exists public.room_events (
  id bigint generated always as identity primary key,
  room_id uuid not null references public.game_rooms(id) on delete cascade,
  event_type text not null check (event_type in ('joined', 'card_revealed', 'card_skipped', 'card_completed', 'round_finished')),
  card_id text,
  actor_role text not null check (actor_role in ('host', 'guest', 'system')),
  event_data jsonb,
  created_at timestamptz not null default now()
);

create index if not exists room_events_room_id_idx on public.room_events(room_id, created_at);

alter table public.room_events enable row level security;

create policy "Participants can view room events"
  on public.room_events for select
  using (
    exists (
      select 1 from public.game_rooms
      where game_rooms.id = room_events.room_id
      and (game_rooms.host_id = auth.uid() or game_rooms.guest_id = auth.uid() or game_rooms.status = 'waiting')
    )
  );

create policy "Participants can insert room events"
  on public.room_events for insert
  with check (
    auth.role() = 'authenticated' and
    exists (
      select 1 from public.game_rooms
      where game_rooms.id = room_events.room_id
      and (game_rooms.host_id = auth.uid() or game_rooms.guest_id = auth.uid() or game_rooms.status = 'waiting')
    )
  );

-- 5. User Favorites Sync Table
create table if not exists public.user_favorites (
  user_id uuid primary key references auth.users(id) on delete cascade,
  card_ids text[] not null default '{}',
  updated_at timestamptz not null default now()
);

alter table public.user_favorites enable row level security;

create policy "Users can manage their own favorites"
  on public.user_favorites for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- 6. Enable Realtime Publications (Safe & Idempotent for Supabase)
do $$
begin
  -- Ensure publication exists or use existing Supabase system publication
  if not exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    create publication supabase_realtime;
  end if;

  -- Add game_rooms if not already in publication
  if not exists (
    select 1 from pg_publication_tables 
    where pubname = 'supabase_realtime' 
      and schemaname = 'public' 
      and tablename = 'game_rooms'
  ) then
    alter publication supabase_realtime add table public.game_rooms;
  end if;

  -- Add room_events if not already in publication
  if not exists (
    select 1 from pg_publication_tables 
    where pubname = 'supabase_realtime' 
      and schemaname = 'public' 
      and tablename = 'room_events'
  ) then
    alter publication supabase_realtime add table public.room_events;
  end if;
end $$;
