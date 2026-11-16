-- Pronos du soir : à coller une fois dans Supabase > SQL Editor > Run
create table if not exists picks (
  id bigint generated always as identity primary key,
  night date not null,
  player text not null references players(name),
  game text not null,
  pick text not null check (char_length(pick) between 2 and 4),
  created_at timestamptz not null default now()
);
alter table picks enable row level security;
create policy "lecture pronos" on picks for select to anon using (true);
create policy "ajout pronos" on picks for insert to anon with check (true);
