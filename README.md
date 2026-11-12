# La Ligne de la Nuit

Devinettes NBA quotidiennes entre Bastien, Alex et Guillaume : une ligne de stats brute, un joueur à trouver.

- Site statique (GitHub Pages) : `index.html`
- Devinettes : `data/days/*.json`, publiées chaque matin par une tâche automatique (voir `TASK.md`)
- Réponses et classement : Supabase (tables `players`, `guesses`, vue `leaderboard`)
- Les réponses sont stockées sous forme d'empreintes (SHA-256) : elles ne sont pas lisibles dans les fichiers.
