# Dépôts de référence — ce qu'on en retient

Analyse de deux compteurs de points Skull King open source, lus intégralement le 2026-10-05. Objectif : récupérer ce qui est utile pour `skull_kings` (calcul des points, modèles de données, déroulé, modes de jeu) et noter les erreurs à ne pas reproduire.

Les règles elles-mêmes sont dans [`GAME_RULES.md`](../GAME_RULES.md), qui reste la référence. En cas de désaccord entre un dépôt et ce fichier, c'est `GAME_RULES.md` qui a raison.

| Dépôt | Commit lu | Verdict |
|---|---|---|
| [SiloCityLabs/skull-king](https://github.com/SiloCityLabs/skull-king) | `86a406a` (2026-08-24) | Référence sérieuse : logique de score pure et testée, modèle de partie complet, déroulé par phases. Licence **CC BY-SA 4.0**. |
| [websitedsigns/skull-kings-scorer](https://github.com/websitedsigns/skull-kings-scorer) | `dbc4c7f` (2025-01-04) | Prototype React incomplet, avec des erreurs de score. Utile surtout comme liste de pièges. Pas de licence. |

Les deux sont des **compteurs de points** (on saisit paris, plis et bonus à la main). Aucun n'implémente le moteur de jeu : pas de cartes, pas de résolution de pli, pas de vérification de l'obligation de suivre.

**Licence** : CC BY-SA 4.0 impose attribution et partage à l'identique pour toute reprise de code. On s'inspire de la structure et des règles, on ne copie pas le code.

---

## 1. SiloCityLabs/skull-king

PWA statique sans framework (HTML/CSS/JS en modules ES), hors ligne, hébergée sur Cloudflare Pages.

| Fichier | Rôle |
|---|---|
| `score.js` | Fonctions pures : score, modèle de partie, ordre des tours, classement, départage |
| `db.js` | Persistance IndexedDB (une table `games`) |
| `app.js` | Interface + machine à états des phases + réglages |
| `tests/score.test.js` | Tests Vitest de `score.js` |
| `index.html` | Vues (accueil, création, jeu, réglages) et aide-mémoire du score |

### 1.1 Modèle de données

Tout est stocké dans un seul objet `Game`, sérialisé tel quel. **Seules les saisies sont stockées** ; les points sont toujours recalculés.

```
Game
  id                   string   (UUID)
  title                string   (par défaut : date et heure de création)
  createdAt            int      (ms epoch)
  updatedAt            int      (ms epoch, mis à jour à chaque sauvegarde)
  scoringMode          "classic" | "rascal"
  currentRound         int      (1-based ; > 10 = prolongation)
  phase                "bidding" | "tricks" | "bonuses" | "review" | "finished"
  turnIndex            int      (index du joueur en train de saisir)
  startingPlayerIndex  int      (index du joueur qui entame la manche 1)
  players              Player[]

Player
  id       string
  name     string  (20 caractères max à la saisie)
  ghost    bool    (true = Barbe Grise : ni pari, ni score)
  rounds   Round[] (10 cases créées d'avance, étendues en prolongation)

Round  (une case par joueur et par manche)
  bid          int | null    pari annoncé
  won          int | null    plis remportés
  bonus        int | null    bonus brut saisi (avant application de la règle « pari réussi »)
  bidType      "grapeshot" | "cannonball"   (utilisé seulement en score Rascal)
  harryAdjust  -1 | 0 | +1   modification du pari par Harry le Géant
  completed    bool
```

Valeurs **dérivées**, jamais stockées (`recomputePlayerTotals`) : `cardsDealt`, `bidPoints`, `bonusPoints`, `roundPoints`, `runningTotal`. Elles valent `null` tant que la manche n'est pas terminée.

Persistance (`db.js`) : base `skull-king.db.v1`, table `games` avec clé `id` et index sur `updatedAt`. API : `list()` (triée par `updatedAt` décroissant), `get(id)`, `put(game)`, `remove(id)`.

Réglages (stockés à part, clé `skull-king.settings.v1`) : mode de score par défaut, alerte d'incohérence des plis, écran toujours allumé, retour haptique.

Une fonction `normalizeGame` complète les anciennes sauvegardes avec les champs ajoutés depuis (`ghost`, `harryAdjust`, `startingPlayerIndex`) : à prévoir chez nous dès qu'on fait évoluer le modèle.

### 1.2 Calcul des points

Conforme à `GAME_RULES.md` §8.

```
classique(pari, plis, cartes) :
  pari == plis  et pari == 0  → +10 × cartes
  pari == plis  et pari  > 0  → +20 × plis
  pari != plis  et pari == 0  → −10 × cartes     (PAS −10 × plis pris)
  pari != plis  et pari  > 0  → −10 × |pari − plis|

rascal « grapeshot »(pari, plis, cartes) :
  potentiel = 10 × cartes
  écart 0 → potentiel ; écart 1 → potentiel / 2 ; sinon 0

rascal « cannonball »(pari, plis, cartes) :
  écart 0 → 15 × cartes ; sinon 0

bonus appliqué = arrondi(bonus brut × multiplicateur)
  classique  : 1 si pari exact, sinon 0
  grapeshot  : 1 / 0,5 / 0
  cannonball : 1 si pari exact, sinon 0

score de la manche = points du pari + bonus appliqué
pari effectif      = borne(pari + harryAdjust, 0, cartes)   ← utilisé pour tout le calcul
```

Le mode « cannonball » n'apparaît pas dans la fiche officielle du score Rascal : voir `GAME_RULES.md` §8.5.

Cas de test à reprendre tels quels pour nos tests unitaires :

| Pari | Plis | Cartes | Mode | Attendu |
|---|---|---|---|---|
| 3 | 3 | 5 | classique | +60 |
| 1 | 1 | 1 | classique | +20 |
| 0 | 0 | 1 / 7 / 10 | classique | +10 / +70 / +100 |
| 0 | 2 | 9 | classique | −90 |
| 0 | 1 | 9 | classique | −90 |
| 0 | 5 | 4 | classique | −40 |
| 2 | 4 | 5 | classique | −20 |
| 3 | 1 | 4 | classique | −20 |
| 1 | 0 | 1 | classique | −10 |
| 2 | 2 / 1 / 0 | 4 | rascal grapeshot | 40 / 20 / 0 |
| 3 | 3 / 2 | 6 | rascal cannonball | 90 / 0 |
| bonus 40, pari 1 | 1 / 0 | — | classique | 40 / 0 |
| bonus 20, pari 1 | 1 / 0 / 3 | — | rascal grapeshot | 20 / 10 / 0 |
| 4 (+1 Harry) | 5 | 5 | classique | +100 |
| 5 (+1 Harry) | — | 5 | — | pari effectif borné à 5 |
| 0 (−1 Harry) | — | 3 | — | pari effectif borné à 0 |

Scénario de la feuille de score du livret (3 joueurs, 2 manches) : cumuls 10 → 60, 10 → −10, 30 → 10.

### 1.3 Déroulé d'une manche

Machine à états : `bidding → tricks → bonuses → review → manche suivante`, puis `finished`.

| Phase | Saisie | Bornes | Passage à la suite |
|---|---|---|---|
| `bidding` | Pari de chaque joueur, un par un | 0 à cartes distribuées | quand tous les non-fantômes ont parié |
| `tricks` | Plis remportés par chaque joueur, **fantôme compris** ; boutons Harry +1 / −1 / effacer | 0 à cartes distribuées | quand tous ont saisi |
| `bonuses` | Bonus brut par joueur (pas de 10, raccourcis 0 à 50) | 0 à 200 | quand tous les non-fantômes ont saisi |
| `review` | Récapitulatif de la manche, bouton « modifier » | — | manche suivante ou fin |

Détails utiles :

- **Ordre de saisie** : on commence par le joueur qui entame la manche, puis sens horaire. Le premier joueur de la manche `n` est `(startingPlayerIndex + n − 1) mod nbJoueurs` (choisi à la création pour la manche 1).
- **Contrôle de cohérence** : si la somme des plis saisis ≠ cartes distribuées, simple avertissement non bloquant (désactivable). Attention : avec le Kraken, un pli détruit n'est gagné par personne, donc la somme peut légitimement être inférieure.
- **Correction d'une manche passée** : on remet la manche en phase `bidding`, on mémorise la position courante (`resumeAfterEdit`) et on y revient après correction. Comme les points sont recalculés depuis les saisies, tous les cumuls suivants se mettent à jour seuls.
- **Historique** : balayage gauche/droite ou points de progression pour parcourir les manches terminées.
- **Trois vues pendant la partie** : tour en cours, feuille de score complète (pari/plis, points du pari, bonus, points de manche, cumul), classement.

### 1.4 Départage et fin de partie

- Après la manche 10, s'il y a égalité **pour la première place**, on enchaîne des manches de prolongation (11, 12, …) à **10 cartes**, jusqu'à avoir un seul premier. Les égalités aux autres places ne déclenchent rien.
- Le classement exclut le fantôme.

### 1.5 Partie à 2 joueurs

À la création d'une partie à 2, l'app propose d'ajouter « Greybeard's Ghost » (Barbe Grise). Il est inséré **entre les deux joueurs** (index 1), ne parie pas, ne marque pas, mais on saisit ses plis pour que le total des plis reste cohérent.

### 1.6 Extension et modes avancés : ce qui est couvert

| Élément | Prise en charge |
|---|---|
| Score Rascal (grapeshot / cannonball) | Oui, choix par partie ; type de pari choisi par joueur et par manche |
| Harry le Géant | Oui, champ `harryAdjust` |
| Butin (+20 d'alliance) | Non modélisé : à ajouter à la main dans le bonus brut |
| Rascal le Flambeur (mise 0/10/20) | **Non** : impossible à saisir, le bonus ne peut pas être négatif |
| Kraken, Baleine blanche, Rosie, Will, Juanita | Sans objet pour un compteur (aucun effet direct sur le score) |

### 1.7 Écarts et limites constatés

- **8 joueurs** : `cardsInRound` renvoie le numéro de manche plafonné à 10, sans tenir compte du nombre de joueurs. Aux manches 9 et 10 à 8 joueurs, il compte 9 et 10 cartes au lieu de 8 → paris à 0 et score Rascal faux.
- **Bonus saisi comme un total brut** : pas de détail par type, donc pas de vérification possible ni de statistiques.
- **Butin et Rascal le Flambeur en score Rascal** : la FAQ officielle exige un pari exact, alors que le code appliquerait 50 % à un butin saisi dans le bonus brut avec un écart de 1.
- **Départage à 10 cartes** : choix du dépôt, le livret ne précise pas.

---

## 2. websitedsigns/skull-kings-scorer

Application Create React App à deux écrans. Le README annonce un backend Flask avec SQLite/PostgreSQL : **`backend/app.py` et `requirements.txt` sont vides** (0 octet). Il n'y a donc aucun modèle côté serveur à récupérer.

### 2.1 Modèle de données

État React en mémoire uniquement, perdu au rechargement :

```
players        [{ name, score }]     score = cumul uniquement, pas d'historique par manche
currentRound   int (1 à 10)
bids           int[]                 par joueur, manche en cours
tricksWon      int[]                 par joueur, manche en cours
specialBonuses int[][]               par joueur, liste de valeurs de bonus sélectionnées
scoringPhase   bool                  false = saisie des paris, true = saisie des plis et bonus
```

Déroulé : saisie des paris (0 à numéro de manche) → saisie des plis et des bonus → cumul → manche suivante, jusqu'à 10.

### 2.2 Idée à retenir

Les bonus sont choisis dans une **liste d'événements nommés** plutôt que saisis comme un nombre : 14 standard (+10), 14 noir (+20), sirène capturée (+20), pirate capturé par le Skull King (+30), Skull King capturé par une sirène (+40). C'est plus lisible et moins sujet aux erreurs de calcul mental que le total brut de SiloCityLabs.

### 2.3 Erreurs à ne pas reproduire

| Problème | Détail |
|---|---|
| Pari 0 raté | Compte **−10 fixe** au lieu de −10 × cartes distribuées. |
| Bonus toujours comptés | Ajoutés même si le pari est raté, contrairement à la règle. |
| Libellé inversé | « Mermaid captures Pirate (+20) » : c'est le pirate qui capture la sirène. |
| Bonus de même valeur confondus | Les options sont identifiées par leur valeur ; deux options valent 20, donc l'affichage et les clés se mélangent. Un bonus doit être identifié par son **type**, pas par ses points. |
| Bonus impossibles à retirer | On ne peut qu'en ajouter. |
| Noms des joueurs ignorés | Les champs de saisie ne sont reliés à rien : les joueurs restent « Player 1 », « Player 2 »… |
| Plis non bornés | Aucun maximum, aucune vérification de la somme des plis. |
| 8 joueurs | Pas de plafond à 8 cartes aux manches 9 et 10. |
| Pas d'historique, pas de sauvegarde, pas de correction | Une erreur de saisie est définitive. |
| Égalité, 2 joueurs, modes avancés | Rien. |
| Incohérence | Le README annonce 2 à 6 joueurs, l'interface en propose 2 à 8. |

---

## 3. Ce qu'on retient pour `skull_kings`

**Modèle**

1. Ne stocker que les saisies ; recalculer tous les points et cumuls par une fonction pure. La correction d'une manche passée devient gratuite.
2. Une case par joueur et par manche : pari, plis, bonus, modification Harry, terminé ou non.
3. Stocker les bonus comme une **liste d'événements typés** (type + quantité), pas un total. Types du jeu de base : `quatorzeCouleur`, `quatorzeNoir`, `sireneCaptureeParPirate`, `pirateCaptureParSkullKing`, `skullKingCaptureParSirene`. Types de l'extension : `allianceButin`, `miseRascal` (signée : +/−0, 10 ou 20).
4. Distinguer deux familles de bonus, car elles n'obéissent pas à la même règle :
   - bonus « de capture » (14 et personnages) : multipliés par le taux de réussite du pari (0 / 1 en classique ; 0 / 0,5 / 1 en Rascal) ;
   - bonus « tout ou rien » (Butin, mise de Rascal le Flambeur) : pari **exact** requis dans tous les modes ; la mise de Rascal devient négative si le pari est raté.
5. Calculer les cartes distribuées avec le nombre de joueurs : `min(manche, 10)`, plafonné à 8 à 8 joueurs.
6. Drapeau « fantôme » sur un joueur pour Barbe Grise, exclu des paris, des scores et du classement.
7. Prévoir dès le départ une migration des sauvegardes (version de schéma).

**Configuration d'une partie** (pour le futur mode de jeu « extension »)

```
mode de score        classique | rascal (+ option cannonball, non officielle)
cartes d'extension   kraken, baleine blanche, butin      (activables séparément)
pouvoirs des pirates activés ou non
premier joueur       index du joueur qui entame la manche 1
```

La configuration conditionne ce que l'interface propose : bonus Butin seulement si le butin est activé et à plus de 2 joueurs ; Harry et mise de Rascal seulement si les pouvoirs sont activés ; alerte « somme des plis » assouplie si le Kraken ou la Baleine blanche sont en jeu.

**Déroulé**

- Phases : paris → plis → bonus → récapitulatif, saisie dans l'ordre du tour à partir du joueur qui entame.
- Alerte non bloquante si la somme des plis ne correspond pas.
- Correction d'une manche passée avec retour à la position courante.
- Prolongation en cas d'égalité pour la première place.
- Trois vues : tour en cours, feuille de score, classement.

**Tests**

Reprendre le tableau du §1.2 comme base de tests unitaires du calcul des points, et y ajouter les cas que les deux dépôts ratent : 8 joueurs aux manches 9 et 10, Butin et mise de Rascal en score Rascal avec un écart de 1.
