# Tâche du matin : publier les devinettes de la nuit

Ce fichier est le mode d'emploi de la tâche programmée qui tourne chaque matin. Le site lit `data/days.json` puis `data/days/<date>.json`. Les scores sont dans Supabase et ne sont jamais touchés par cette tâche.

## 1. Récupérer la nuit
- Date du jour = date à Paris. Les matchs de la nuit sont ceux terminés (`closed`) dont l'heure de début, en heure de Paris, tombe entre 00:00 et 08:00 ce jour-là.
- Outil : `fetch_sports_data` (scores NBA), puis `game_stats` pour chaque match. Si l'outil n'est pas disponible, utiliser la recherche web (box scores ESPN, NBA.com, Basketball-Reference) et le signaler dans le résumé.
- S'il n'y a eu aucun match : ne rien publier, le dire dans le résumé.
- Enregistrer **toutes** les lignes joueurs dans `data/lines/<date>.json` : une liste de `{player, team, opp, home, result, score, pos, stats}`, `stats` étant l'objet renvoyé tel quel. Ces archives serviront à calculer les moyennes nous-mêmes.

## 2. Choisir les 3 devinettes (un joueur ne peut apparaître qu'une fois)
1. **MVP de la nuit** : le plus haut `efficiency_game_score` parmi les joueurs des équipes gagnantes.
2. **Frenchie de la nuit** : le plus haut `efficiency_game_score` parmi les joueurs de `data/french.json`, hors MVP. Si aucun Français n'a joué, remplacer par **Défenseur de la nuit** (plus haut total interceptions + contres, départage au game score).
3. **Révélation de la nuit** : parmi les 12 meilleurs game scores restants ayant marqué au moins 15 points, celui dont l'écart « points de la nuit − moyenne de points de la saison » est le plus grand.
   - Moyenne : chercher la moyenne de la saison en cours. Si moins de 5 matchs joués, ou si deux sources se contredisent de plus de 2 points, prendre la saison précédente et l'écrire dans `why` et dans `notes`.
   - Quand `data/lines/` contient au moins 15 jours, calculer la moyenne à partir des archives si le joueur y a au moins 8 matchs, et préférer ce chiffre.

## 3. Écrire la ligne et les indices
- `line` : PTS, TIR (`fgm/fga`), 3 PTS, LF, REB, PD, INT, CTR, BP, +/- (les zéros s'écrivent `0`, le signe moins est `−`). `result` : `Victoire` ou `Défaite`.
- Indice 1 : minutes jouées (`34 min`), trouvées par recherche web dans un box score de la nuit. Si introuvables : `Minutes indisponibles ce matin · Xe saison NBA`.
- Indice 2 : poste et conférence (`Pivot · Conférence Ouest`).
- Indice 3 : contexte du match (`Victoire 124-119 à l'extérieur, à Chicago`), plus un détail de carrière vérifié si utile (rang de draft).
- `why` : une ou deux phrases qui justifient le choix avec les chiffres (game score, écart à la moyenne et sa source).
- `accepts` : surnoms courants seulement ; le nom complet et le nom de famille sont ajoutés automatiquement.
- **Ne rien inventer** : toute info d'un indice ou de `why` doit venir des données ou d'une source trouvée. Dans le doute, l'enlever.

## 4. Publier
1. Écrire le fichier brut **hors du dépôt** (`/tmp/brut-<date>.json`, format décrit en tête de `scripts/make_day.py`). Il contient les réponses en clair : ne jamais le commiter.
2. `python3 scripts/make_day.py /tmp/brut-<date>.json`
3. Vérifier que `data/days/<date>.json` ne contient pas les noms des joueurs en clair (`grep`).
4. `git add data && git commit -m "Devinettes du <date>" && git push`.

## 5. Liste des Français (`data/french.json`)
- Une fois par semaine (le lundi), vérifier la liste par recherche web (effectifs NBA, liste des joueurs internationaux de NBA.com).
- Ne pas modifier la liste sans prévenir : signaler les ajouts/retraits proposés dans le résumé de la tâche, et ne les appliquer que s'ils sont confirmés par deux sources.

## 6. Résumé de fin de tâche
Trois lignes : date et nombre de matchs, les 3 catégories publiées (sans les noms des joueurs), et tout ce qui a manqué ou a été remplacé (minutes, moyenne, Frenchie, source des données).
