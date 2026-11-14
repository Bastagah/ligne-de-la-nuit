# Tâche du matin : publier les devinettes de la nuit

Ce fichier est le mode d'emploi de la tâche programmée qui tourne chaque matin. Le site lit `data/days.json` puis `data/days/<date>.json`. Les scores sont dans Supabase et ne sont jamais touchés par cette tâche.

## 1. Récupérer la nuit
- Date du jour = date à Paris. Les matchs de la nuit sont ceux qui ont **commencé entre 08:00 la veille et 08:00 ce jour-là** (heure de Paris) : ça inclut les matchs du dimanche après-midi ou soir, joués en début de soirée en France.
- **Avant toute autre chose, vérifier que tous les matchs de la fenêtre sont terminés** (scores de la nuit : `fetch_sports_data` si disponible, sinon ESPN/NBA.com). Si un match est encore en cours :
  1. attendre 10 minutes (`sleep 600` dans le terminal), puis revérifier ;
  2. recommencer jusqu'à 4 fois au maximum (soit environ 40 minutes d'attente) ;
  3. une fois le match terminé, attendre encore 5 minutes (`sleep 300`) pour que son box score soit complet en ligne, puis continuer normalement ;
  4. si le match n'est toujours pas fini après les 4 attentes, publier sans lui : ne l'inclure ni dans les devinettes ni dans `matchups`, et le signaler dans le résumé.
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
2. **Frenchie de la nuit** : le plus haut game score parmi les joueurs de `data/french.json`, hors MVP et **toujours hors Victor Wembanyama** (règle du jeu : c'est un alien avant d'être français). `desc` : « La meilleure ligne d'un joueur français. Wembanyama exclu : alien avant d'être français. » Si aucun Français n'a joué, remplacer par **Défenseur de la nuit** (plus haut total interceptions + contres, départage au game score).
3. **Rookie de la nuit** : le plus haut game score parmi les joueurs de `data/rookies.json`, hors joueurs déjà choisis. Si aucun rookie n'a joué, remplacer par **Le perdant magnifique** : le meilleur game score parmi les joueurs des équipes perdantes, hors joueurs déjà choisis.
4. **Looser de la nuit** : parmi les joueurs ayant joué **au moins 20 minutes dans une défaite**, hors joueurs déjà choisis, le **plus bas game score**. Départage : le plus mauvais +/-.
5. **Révélation de la nuit** (hors joueurs déjà choisis) : le joueur qui a le plus marqué **par rapport à sa moyenne**.
   - Candidats : les **25 meilleurs game scores** de la nuit, parmi tous les joueurs (vainqueurs et perdants), hors joueurs déjà choisis.
   - On classe par le **rapport points de la nuit ÷ moyenne de points**. Pour éviter les divisions absurdes, une moyenne inférieure à 3 points compte pour 3. Départage : le plus gros écart « points − moyenne ».
   - Moyenne : chercher la moyenne de la saison en cours. Si moins de 5 matchs joués, ou si deux sources se contredisent de plus de 2 points, prendre la saison précédente ; un rookie sans 5 matchs compte pour 3 points. Écrire la moyenne utilisée et sa source dans `why` et dans `notes`.
   - Quand `data/lines/` contient au moins 15 jours, calculer la moyenne à partir des archives si le joueur y a au moins 8 matchs, et préférer ce chiffre.

## 3. Écrire la ligne et les indices
- `line`, dans cet ordre : MIN, PTS, TIR (`fgm/fga`), 3 PTS, LF, REB, PD, INT, CTR, BP, +/-. Les minutes s'écrivent en minutes entières (`34`). Les zéros s'écrivent `0`, le signe moins est `−`. Si les minutes sont introuvables, mettre `—` et le signaler.
- `result` : `Victoire` ou `Défaite`.
- Indice 1 : poste et conférence (`Pivot · Conférence Ouest`).
- Indice 2 : parcours, vérifié (`1er choix de la draft 2023`, université ou club d'avant la NBA, nombre de saisons NBA).
- Indice 3 : **moyenne de points de la saison en cours, avant ce match** (`Moyenne cette saison : 6,8 pts en 11 matchs`), avec la même source que pour la Révélation. Pour un rookie à moins de 5 matchs, donner quand même sa moyenne réelle et le nombre de matchs. Ne pas donner l'adversaire ni le score (les matchs sont déjà affichés sur le site).
- `why` : une ou deux phrases qui justifient le choix avec les chiffres (game score, minutes, écart à la moyenne et sa source).
- `profile` : l'adresse de la fiche officielle du joueur sur NBA.com, au format `https://www.nba.com/player/<id>/<nom>`, trouvée par une recherche web limitée à nba.com (l'identifiant doit apparaître dans un résultat, ne jamais le deviner). Si introuvable, laisser vide : le site proposera alors un lien de recherche.
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
