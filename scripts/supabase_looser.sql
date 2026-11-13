-- La Ligne de la Nuit : autoriser une 5e devinette (Looser de la nuit)
alter table guesses drop constraint if exists guesses_riddle_check;
alter table guesses add constraint guesses_riddle_check check (riddle between 1 and 5);
