-- La Ligne de la Nuit : passage aux essais multiples
-- À coller une seule fois dans Supabase > SQL Editor, puis cliquer sur "Run".

-- 1. Autoriser plusieurs essais par joueur et par devinette
alter table guesses drop constraint if exists guesses_day_riddle_player_key;

-- 2. Mais une seule bonne réponse comptée, et un seul abandon
create unique index if not exists une_victoire_par_devinette
  on guesses (day, riddle, player) where correct;
create unique index if not exists un_abandon_par_devinette
  on guesses (day, riddle, player) where guess = '(abandon)';

-- 3. Classement : "jouees" compte les devinettes tentées, pas le nombre d'essais
create or replace view leaderboard as
  select p.name,
         coalesce(sum(g.points), 0)::int                                as total,
         count(g.id) filter (where g.correct)::int                      as trouvees,
         count(distinct (g.day, g.riddle)) filter (where g.id is not null)::int as jouees
  from players p left join guesses g on g.player = p.name
  group by p.name
  order by total desc;

grant select on leaderboard to anon;
