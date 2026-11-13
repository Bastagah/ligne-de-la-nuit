# Tâche du matin : publier les devinettes de la nuit

Ce fichier est le mode d'emploi de la tâche programmée qui tourne chaque matin. Le site lit `data/days.json` puis `data/days/<date>.json`. Les scores sont dans Supabase et ne sont jamais touchés par cette tâche.

## 1. Récupérer la nuit
- Date du jour = date à Paris. Les matchs de la nuit sont ceux terminés dont l'heure de début, en heure de Paris, tombe entre 00:00 et 08:00 ce jour-là.
- **Source principale : les box scores ESPN ou NBA.com** (recherche web puis lecture de la page). Ils sont complets et donnent les minutes jouées.
- **Recoupement :** pour les 5 joueurs choisis, vérifier la ligne dans une deuxième source (Covers, Basketball-Reference, CBS Sports). En cas d'écart, garder la source officielle (NBA.com) et le signaler dans le résumé.
- L'outil `fetch_sports_data` (SportRadar), s'il est disponible, sert seulement de vérification : ses box scores oublient parfois des joueurs.
- S'il n'y a eu aucun match : ne rien publier, le dire dans le résumé.
- Enregistrer **toutes** les lignes joueurs dans `data/lines/<date>.json` : une liste de `{player, team, opp, home, result, score, pos, min, pts, fgm, fga, tpm, tpa, ftm, fta, oreb, dreb, reb, ast, stl, blk, tov, pf, pm, gmsc}`. Ces archives serviront à calculer nos propres moyennes.
- **Game score** (`gmsc`), à calculer pour chaque joueur :
  `PTS + 0,4×FGM − 0,7×FGA − 0,4×(FTA − FTM) + 0,7×OREB + 0,3×DREB + STL + 0,7×AST + 0,7×BLK − 0,4×PF − TOV`

## 2. Choisir les 5 devinettes (un joueur ne peut apparaître qu'une fois)
Ordre de sélection : MVP, Frenchie, Rookie, Looser, puis Révélation. Ordre d'affichage dans le fichier : MVP, Frenchie, Révélation, Rookie, Looser.

1. **MVP de la nuit** : le plus haut game score parmi les joueurs des équipes gagnantes.
2. **Frenchie de la nuit** : le plus haut game score parmi les joueurs de `data/french.json`, hors MVP. Si aucun Français n'a joué, remplacer par **Défenseur de la nuit** (plus haut total interceptions + contres, départage au game score).
3. **Rookie de la nuit** : le plus haut game score parmi les joueurs de `data/rookies.json`, hors joueurs déjà choisis. Si aucun rookie n'a joué, remplacer par **Le perdant magnifique** : le meilleur game score parmi les joueurs des équipes perdantes, hors joueurs déjà choisis.
4. **Looser de la nuit** : parmi les joueurs ayant joué **au moins 20 minutes dans une défaite**, hors joueurs déjà choisis, le **plus bas game score**. Départage : le plus mauvais +/-.
5. **Révélation de la nuit** (hors joueurs déjà choisis) : parmi les 12 meilleurs game scores restants ayant marqué au moins 15 points, celui dont l'écart « points de la nuit − moyenne de points de la saison » est le plus grand.
   - Moyenne : chercher la moyenne de la saison en cours. Si moins de 5 matchs joués, ou si deux sources se contredisent de plus de 2 points, prendre la saison précédente et l'écrire dans `why` et dans `notes`.
   - Quand `data/lines/` contient au moins 15 jours, calculer la moyenne à partir des archives si le joueur y a au moins 8 matchs, et préférer ce chiffre.

## 3. Écrire la ligne et les indices
- `line`, dans cet ordre : MIN, PTS, TIR (`fgm/fga`), 3 PTS, LF, REB, PD, INT, CTR, BP, +/-. Les minutes s'écrivent en minutes entières (`34`). Les zéros s'écrivent `0`, le signe moins est `−`. Si les minutes sont introuvables, mettre `—` et le signaler.
- `result` : `Victoire` ou `Défaite`.
- Indice 1 : poste et conférence (`Pivot · Conférence Ouest`).
- Indice 2 : contexte du match (`Victoire 124-119 à l'extérieur, à Chicago`).
- Indice 3 : parcours, vérifié (`1er choix de la draft 2023`, université ou club d'avant la NBA, nombre de saisons NBA).
- `why` : une ou deux phrases qui justifient le choix avec les chiffres (game score, minutes, écart à la moyenne et sa source).
- `accepts` : surnoms courants seulement ; le nom complet et le nom de famille sont ajoutés automatiquement.
- `matchups` : la liste des matchs de la nuit **sans les scores**, en abréviations à 3 lettres, `[{"away": "DET", "home": "WAS"}, ...]`.
- **Ne rien inventer** : toute info d'un indice ou de `why` doit venir des données ou d'une source trouvée. Dans le doute, l'enlever.

## 4. Publier
1. Écrire le fichier brut **hors du dépôt** (`/tmp/brut-<date>.json`, format décrit en tête de `scripts/make_day.py`). Il contient les réponses en clair : ne jamais le commiter.
2. `python3 scripts/make_day.py /tmp/brut-<date>.json`
3. Vérifier que `data/days/<date>.json` ne contient pas les noms des joueurs en clair (`grep`).
4. `git add data && git commit -m "Devinettes du <date>" && git push`.

## 5. Listes des Français et des rookies (`data/french.json`, `data/rookies.json`)
- Une fois par semaine (le lundi), vérifier les deux listes par recherche web (effectifs NBA, joueurs internationaux de NBA.com, draft 2026 et rookies non draftés).
- Ne pas modifier une liste sans prévenir : signaler les ajouts/retraits proposés dans le résumé de la tâche, et ne les appliquer que s'ils sont confirmés par deux sources.

## 6. Résumé de fin de tâche
Trois lignes : date et nombre de matchs, les 5 catégories publiées (sans les noms des joueurs), et tout ce qui a manqué ou a été remplacé (minutes, moyenne, Frenchie, Rookie, sources utilisées).
