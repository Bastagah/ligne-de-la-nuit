-- La Ligne de la Nuit : création des tables
-- À coller une seule fois dans Supabase > SQL Editor, puis cliquer sur "Run".

-- 1. Les joueurs (Bastien, Alex, Guillaume) et leur code perso
create table if not exists players (
  name      text primary key,
  pin_hash  text not null            -- empreinte du code à 4 chiffres, pas le code lui-même
);

-- 2. Les réponses : une seule par joueur, par jour et par devinette
create table if not exists guesses (
  id          bigint generated always as identity primary key,
  day         date     not null,
  riddle      smallint not null check (riddle between 1 and 3),
  player      text     not null references players(name),
  hints_used  smallint not null check (hints_used between 0 and 3),
  guess       text     not null,
  correct     boolean  not null,
  points      smallint not null check (points between 0 and 4),
  created_at  timestamptz not null default now(),
  unique (day, riddle, player)       -- empêche une deuxième tentative
);

-- 3. Le classement, calculé automatiquement
create or replace view leaderboard as
  select p.name,
         coalesce(sum(g.points), 0)::int              as total,
         count(g.id) filter (where g.correct)::int    as trouvees,
         count(g.id)::int                             as jouees
  from players p left join guesses g on g.player = p.name
  group by p.name
  order by total desc;

-- 4. Droits d'accès pour le site (clé publique)
alter table players enable row level security;
alter table guesses enable row level security;

create policy "lecture joueurs"  on players for select to anon using (true);
create policy "lecture réponses" on guesses for select to anon using (true);
create policy "ajout réponse"    on guesses for insert to anon with check (true);
-- Aucune règle de modification ni de suppression : une réponse envoyée est définitive.

grant select on leaderboard to anon;
