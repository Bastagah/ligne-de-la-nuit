-- 1. Remise à zéro : efface toutes les réponses enregistrées jusqu'ici
delete from guesses;

-- 2. Bonus premier essai : une devinette peut désormais rapporter jusqu'à 5 points
alter table guesses drop constraint if exists guesses_points_check;
alter table guesses add constraint guesses_points_check check (points between 0 and 5);

-- 3. Le classement ne compte qu'à partir du 13 novembre 2026 (les devinettes du 12 restent jouables pour s'entraîner)
create or replace view leaderboard as
  select p.name,
         coalesce(sum(g.points), 0)::int                                as total,
         count(g.id) filter (where g.correct)::int                      as trouvees,
         count(distinct (g.day, g.riddle)) filter (where g.id is not null)::int as jouees
  from players p left join guesses g on g.player = p.name and g.day >= '2026-11-13'
  group by p.name
  order by total desc;

grant select on leaderboard to anon;
