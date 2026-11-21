# Tâche du matin : publier les devinettes de la nuit

Ce fichier est le mode d'emploi de la tâche programmée qui tourne chaque matin. Le site lit `data/days.json` puis `data/days/<date>.json`. Les scores sont dans Supabase et ne sont jamais touchés par cette tâche.

## 1. Récupérer la nuit
- Date du jour = date à Paris. Les matchs de la nuit sont ceux qui ont **commencé entre 08:00 la veille et 08:00 ce jour-là** (heure de Paris) : ça inclut les matchs du dimanche après-midi ou soir, joués en début de soirée en France.
- **Avant toute autre chose, vérifier que tous les matchs de la fenêtre sont terminés** (scores de la nuit : `fetch_sports_data` si disponible, sinon ESPN/NBA.com). Si un match est encore en cours :
  1. attendre 10 minutes (`sleep 600` dans le terminal), puis revérifier ;
  2. recommencer jusqu'à 4 fois au maximum (soit environ 40 minutes d'attente) ;
  3. une fois le match terminé, attendre encore 5 minutes (`sleep 300`) pour que son box score soit complet en ligne, puis continuer normalement ;
  4. si le match n'est toujours pas fini après les 4 attentes, publier sans lui : ne l'inclure ni dans les devinettes ni dans `matchups`, et le signaler dans le résumé.
- **Trois sources au même niveau : ESPN (www et miroirs), NBA.com et Basket USA.** Pour chaque match, prendre le premier box score lisible, marqué terminé et qui passe les contrôles (somme des points = score final, rebonds = off. + déf., totaux d'équipe), quelle que soit la source. Chercher les trois en parallèle dès le début plutôt que d'attendre qu'ESPN échoue. Les trois donnent les minutes jouées.
- **Recoupement :** pour les 5 joueurs choisis, vérifier la ligne dans une autre des trois sources (box score d'une autre source, ou journal de matchs ESPN du joueur `/nba/player/gamelog/_/id/...`, www ou miroir). En cas d'écart, garder la source qui colle aux totaux d'équipe, et le signaler dans le résumé.
- **Accès aux sites : seulement ESPN, NBA.com et Basket USA.** Ouvrir des pages (WebFetch) uniquement sur www.espn.com (et ses miroirs ci-dessous), www.nba.com et www.basketusa.com, jamais ailleurs : chaque nouveau site déclenche une demande d'autorisation et bloque la publication. WebSearch reste libre (pour trouver les liens, les moyennes, les fiches), mais sans ouvrir les pages d'autres sites. Les appels directs depuis le terminal (curl, Python) sont bloqués (erreur 403) : ne pas les tenter. Si une page www.espn.com refuse de s'ouvrir ou montre un match « en cours » / « avant-match » alors qu'il est fini (l'outil de lecture garde parfois une version figée en cache pendant des heures), prendre **le même chemin sur les miroirs ESPN**, dans cet ordre : www.espn.com.au, www.espn.ph, africa.espn.com (même identifiant de match, ex. `https://www.espn.com.au/nba/boxscore/_/gameId/401910022`). Ces miroirs sont autorisés au même titre que www.espn.com. **Ne jamais fabriquer l'adresse à la main** : une adresse qui n'est apparue dans aucun résultat de recherche déclenche une demande d'autorisation, et personne n'est là pour y répondre. Il faut d'abord la faire apparaître avec WebSearch (`allowed_domains` : espn.com.au, espn.ph, africa.espn.com ; requête avec les équipes, la date et l'identifiant du match), puis l'ouvrir. Les box scores NBA.com sont chargés en JavaScript et souvent illisibles : si la page ne montre que le menu, passer à une autre source. Les journaux de matchs (`/nba/player/gamelog/_/id/...`) des miroirs servent aussi pour les moyennes et les recoupements (attention : sur espn.com.au les dates sont décalées d'un jour). Si deux miroirs diffèrent, garder celui qui colle aux totaux d'équipe de la page du match. N'accepter un box score que si la somme des points des joueurs égale le score final de chaque équipe.
- **Basket USA (www.basketusa.com).** Le trouver par WebSearch (`allowed_domains` : basketusa.com ; requête avec les deux équipes, le score final et la date), puis l'ouvrir : l'article du match ou le « Stats & Highlights » de la nuit contient le box score complet, et la page de stats du match a la forme `https://www.basketusa.com/resultats/boxscore_<jjmmaa>_<eq1>-<eq2>` (ex. `boxscore_201126_uth-pho`). Cette adresse doit elle aussi apparaître dans une page ou un résultat de recherche avant d'être ouverte. Colonnes : Min, Tirs (FG), 3pts, LF, O (rebonds off.), D (déf.), T (total), Pd (passes), Fte (fautes), Int (interceptions), Bp (balles perdues), Ct (contres), +/-, Pts ; ignorer la colonne Eval. Exiger le tableau lu tel quel, pas un résumé, et les mêmes contrôles que pour les autres sources : somme des points = score final, rebonds = off. + déf., fautes et rebonds = totaux d'équipe. Noter dans `notes` la source de chaque match.
- L'outil `fetch_sports_data` (SportRadar), s'il est disponible, sert seulement de vérification : ses box scores oublient parfois des joueurs.
- S'il n'y a eu aucun match : ne rien publier, le dire dans le résumé.
- Enregistrer **toutes** les lignes joueurs dans `data/lines/<date>.json` : une liste de `{player, team, opp, home, result, score, pos, min, pts, fgm, fga, tpm, tpa, ftm, fta, oreb, dreb, reb, ast, stl, blk, tov, pf, pm, gmsc}`. Ces archives serviront à calculer nos propres moyennes.
- **Game score** (`gmsc`), à calculer pour chaque joueur :
  `PTS + 0,4×FGM − 0,7×FGA − 0,4×(FTA − FTM) + 0,7×OREB + 0,3×DREB + STL + 0,7×AST + 0,7×BLK − 0,4×PF − TOV`

## 2. Choisir les 5 devinettes (un joueur ne peut apparaître qu'une fois)
Ordre de sélection : MVP, Frenchie, Rookie, Looser, puis Révélation. Ordre d'affichage dans le fichier : MVP, Frenchie, Révélation, Rookie, Looser.
Égalité au game score (MVP, Frenchie, Rookie, perdant magnifique) : départager au meilleur +/-, puis au plus de points ; l'écrire dans `why` et dans `notes`.

1. **MVP de la nuit** : le plus haut game score parmi les joueurs des équipes gagnantes.
2. **Frenchie de la nuit** : le plus haut game score parmi les joueurs de `data/french.json`, hors MVP **et hors Victor Wembanyama**. Si aucun Français n'a joué, remplacer par **Défenseur de la nuit** (plus haut total interceptions + contres, départage au game score).
   - **Règle OVNI** : si Wembanyama a le plus haut game score des Français (et n'est pas déjà MVP), ajouter à la devinette du Frenchie un bloc `alien` avec sa ligne (format décrit dans `scripts/make_day.py`). Sur le site, sa ligne est à deviner d'abord, pour 0 point ; puis « OVNI détecté » s'affiche et le vrai Frenchie (le Français suivant) apparaît. Sinon, pas de bloc `alien`.
   - `desc` du Frenchie : « La meilleure ligne d'un joueur français (Wembanyama exclu : alien avant d'être français). »
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

- `winners` : le vainqueur de chaque match de `matchups`, `{"DET-WAS": "DET", ...}` (clé AWAY-HOME, abréviations à 3 lettres). Le script le cache dans `results` : le site n'affiche que les vainqueurs, jamais les scores.
- `tonight` (pronos) : les matchs de la nuit à venir, c'est-à-dire ceux qui commencent entre 08:00 aujourd'hui et 08:00 demain (heure de Paris), d'après le calendrier officiel NBA.com ou ESPN. Format `{"night": "<date de demain>", "lock": "<1er coup d'envoi en UTC ISO>", "games": [{"away": "MEM", "home": "WAS", "start": "2026-11-17T00:00:00Z"}, ...]}`. `lock` = l'heure de début la plus tôt. Pas de match ce soir : omettre `tonight`.

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
