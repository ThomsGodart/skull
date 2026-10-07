-- What each user's phone backs up: its settings, its games, its counted
-- games. One row per thing, as the app wrote it.
create table public.user_data (
  user_id uuid not null default auth.uid() references auth.users on delete cascade,
  kind text not null check (kind in ('setting', 'game', 'counter')),
  key text not null,
  value jsonb not null,
  updated_at timestamptz not null default now(),
  primary key (user_id, kind, key)
);

alter table public.user_data enable row level security;

-- Each user reads and writes their own rows, and nobody else's.
create policy "own rows" on public.user_data
  for all
  to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));
