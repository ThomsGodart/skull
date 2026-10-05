# Jeux de cartes open source — écrans, contenu et interface

Recherche faite le 2026-10-05 à partir de https://github.com/topics/card-game (3 181 dépôts), complétée par des recherches ciblées : Flutter/Dart, « Skull King », jeux de plis, Wizard et Oh Hell (les deux jeux les plus proches de Skull King : on parie un nombre de plis).

Objectif : savoir ce que contient une application de jeu de cartes complète (nouvelle partie, table, score, historique, profil, réglages, rendu des cartes) pour construire l'enchaînement d'écrans de `skull_kings`.

Méthode : 17 dépôts clonés. Pour chacun j'ai lu le README, l'arborescence et les fichiers d'écrans, de modèles et de composants cartes. Je n'ai lancé aucune application : ce qui suit vient du code et de la documentation, plus deux captures d'écran fournies par les dépôts.

Les dépôts les plus étoilés du sujet (rlcard, frameworks Godot, PokerTH, outils Magic…) sont des bibliothèques d'IA, des moteurs d'autres technologies ou des gestionnaires de collection : rien d'utile pour nos écrans. Les bons candidats sont petits et récents.

Documents liés : règles dans [`GAME_RULES.md`](../GAME_RULES.md), compteurs de points dans [`REFERENCE_REPOS.md`](REFERENCE_REPOS.md), architecture du moteur dans [`REFERENCE_RTAROT.md`](REFERENCE_RTAROT.md).

---

## 1. Dépôts retenus

| Dépôt | Techno | Licence | Ce qu'il apporte |
|---|---|---|---|
| [Maiz27/hareeg-table](https://github.com/Maiz27/hareeg-table) | Flutter | MIT (code) | **Référence principale.** Jeu complet hors ligne, 1 humain contre 3 bots : accueil, configuration, table, pause, fin de partie, historique, statistiques, rejeu, tutoriel, réglages, thèmes de cartes. Documentation de conception détaillée. |
| [naltinbas/Bridge](https://github.com/naltinbas/Bridge) (`bridge-flutter`) | Flutter | aucune | Table de jeu de plis **minimale et complète** en ~1 000 lignes d'interface : carte, main en éventail, pli au centre, sièges. |
| [Sc02/WizardScore](https://github.com/Sc02/WizardScore) | Flutter + SQLite | CC0 | Compteur pour Wizard : joueurs réutilisables, classement, historique, schéma de base de données, retour en arrière. |
| [mytja/Tarok](https://github.com/mytja/Tarok) | Flutter + serveur Go | AGPL-3.0 | Jeu de tarot en ligne et hors ligne avec bots : salon, profil, amis, rejeux, journal de partie, guide, tournois, réglages très complets. |
| [vareversat/carg](https://github.com/vareversat/carg) | Flutter + Firebase | MIT | Compteur belote / coinche / tarot : comptes, joueurs, équipes, statistiques par joueur, liste des parties. |
| [WilburFort/spades](https://github.com/WilburFort/spades) | Web, un seul fichier | MIT | Table de jeu de plis très soignée : bots à personnalité, coach, accessibilité clavier. |
| [johnmorrisdotca/toranpu](https://github.com/johnmorrisdotca/toranpu) | TypeScript | MIT | Onze jeux (dont Oh Hell) sur une seule table : règles en fonctions pures, « une partie = sa graine + ses coups ». |
| [Shantanu467/skull-king](https://github.com/Shantanu467/skull-king) | Node + React | aucune | **Skull King jouable en ligne**, petit (2 700 lignes) : salon à code, paris, table, tableau des scores, métadonnées visuelles des cartes. |
| [AngelAmoSanchez/SkullKing-Card-Game](https://github.com/AngelAmoSanchez/SkullKing-Card-Game) | Spring + React | MIT | Skull King en ligne (projet universitaire) : 50 maquettes d'écrans, fenêtres de pari, choix Tigresse, gagnant du pli, gagnant de la partie. |
| [brunotot/skull-king](https://github.com/brunotot/skull-king) | Spring + React | aucune | Skull King en ligne : salons, phases, podium. |
| [Kibishi47/skull-king-companion](https://github.com/Kibishi47/skull-king-companion) | React (PWA) | aucune | Compteur Skull King **en français** : tiroir de bonus, récapitulatif de manche, podium, style parchemin. |
| [RomainMIRAS/SkullKingLeague](https://github.com/RomainMIRAS/SkullKingLeague) | PHP | aucune | Ligue Skull King : classement ELO, saisons, profils, historique. |
| [mayerwin/Escalier-Oh-Hell-Score-Keeper](https://github.com/mayerwin/Escalier-Oh-Hell-Score-Keeper) | Web (PWA) | non standard | Compteur Oh Hell : nombre de manches modifiable, joueur qui arrive ou part en cours, partage d'une partie par lien, graphique des scores. |

Écartés après lecture : `Lib1221/Crazy-Game` (surtout du chat Firebase), `yanexr/trump-cards` (jeu de bataille de fiches), `BuildmodeOne/wizard_points` (doublon moins complet de WizardScore), `Luke004/skull-king` (5 fichiers).

**Licences** : on ne copie du code que depuis les dépôts MIT ou CC0, avec attribution. Pour les autres (AGPL, sans licence), on ne reprend que les idées.

---

## 2. Les écrans qu'on retrouve partout

### 2.1 Accueil

hareeg-table : `Continuer` (seulement si une partie est sauvegardée, avec son résumé), `Nouvelle partie`, puis en secondaire `Entraînement`, `Historique`, `Statistiques`, `Règles`, `Réglages`.

- Une seule partie en cours à la fois, reprise en un geste. Si la sauvegarde est illisible, l'accueil le dit et propose de la supprimer plutôt que de planter.
- Tarok ajoute un salon (parties avec bots / avec des joueurs), les amis et les rejeux.
- Compteurs (WizardScore, carg) : barre d'onglets `Jouer / Joueurs / Historique / Classement`.

### 2.2 Nouvelle partie

| Réglage | Vu dans |
|---|---|
| Choix et ordre des joueurs, siège 1 = premier servi | WizardScore, carg, Escalier |
| Joueurs enregistrés réutilisables d'une partie à l'autre | WizardScore, carg, League |
| Bots : nombre, nom, niveau | Tarok (« ajouter un bot », « personnaliser les bots »), hareeg (4 niveaux), spades (personnages) |
| Qui commence : moi, au hasard | hareeg |
| Règles maison, avec résumé avant de lancer | hareeg, WizardScore, Tarok |
| Dernière configuration mémorisée | hareeg |

hareeg sépare bien la **configuration de la partie** (figée une fois lancée) des **préférences** (modifiables à tout moment). Certains réglages sont verrouillés pendant une partie, et l'écran le dit.

### 2.3 Paris

- Bridge Flutter : grille de boutons sous la table ; les annonces illégales sont grisées, jamais cachées.
- spades : les touches numériques parient, le coach peut suggérer un pari.
- Escalier : saisie rapide, annonce interdite barrée.
- AngelAmo : fenêtre modale de pari (`ApostarModal`), et une maquette « voir les paris pour faire sa stratégie ».

### 2.4 Table de jeu

Disposition commune à Bridge Flutter, spades et hareeg :

```
┌──────────────────────────────────────────────┐
│ barre d'état : manche, tour, scores, boutons │
│                 adversaire (dos de cartes)   │
│ adversaire        pli au centre    adversaire│
│                                              │
│      ma main en éventail, cartes injouables  │
│      grisées                                 │
└──────────────────────────────────────────────┘
```

Détails relevés :

- **Étiquette de siège** : nom, pari, plis pris sous forme de pastilles (spades : « Bid 3 · won 1 ■□□ »), anneau doré sur le joueur dont c'est le tour, pastille « D » pour le donneur.
- **Phrase d'état** en haut : « À toi — fournis du cœur ». spades explique aussi pourquoi une carte est injouable.
- **Carte gagnante du pli** entourée d'or ; le pli terminé reste affiché un instant, puis glisse vers le gagnant. Bridge Flutter fait une pause explicite après chaque pli « pour que la table reste lisible ».
- **Bouton « dernier pli »** pour revoir le pli précédent (spades).
- **Vitesse** : délai des bots, tours rapides, vitesse des animations, mouvement réduit (hareeg, Tarok).
- **Orientation** : hareeg joue la table en paysage et tout le reste en portrait. Bridge Flutter tient en portrait à 4 joueurs.
- hareeg : `game_table_screen.dart` fait 4 805 lignes malgré une vingtaine de fichiers « planner » extraits. À ne pas reproduire : découper la table en widgets dès le départ.

### 2.5 Pause

hareeg ouvre un panneau par-dessus la table : `Reprendre`, `Quitter la table`, et les réglages utiles en cours de partie (son, vibrations, vitesse, contraste des cartes, conseils), plus `Signaler un problème`. La partie est sauvegardée en continu : quitter ne perd rien.

### 2.6 Fin de manche et tableau des scores

- hareeg affiche la fin de manche **en surimpression sur la table**, sans changer d'écran. Une version plein écran a été essayée puis supprimée : trop lente entre deux manches.
- Panneau des scores accessible à tout moment : scores, qui a commencé, joueur courant.
- Kibishi : récapitulatif de manche + « tiroir de bonus » ; Escalier : graphique d'évolution des scores.
- AngelAmo : fenêtre « gagnant du pli » après chaque pli.

### 2.7 Fin de partie

Conception de hareeg (document `end-of-match-screen.md`) :

1. Titre « Partie terminée », puis le gagnant en très grand (« Tu gagnes » ou le nom du bot).
2. Classement final : rang, nom, score ; ligne du gagnant en or avec un trophée.
3. Une ligne de contexte : nombre de manches.
4. Actions : `Retour au menu` (principale), `Nouvelle partie, même configuration` (secondaire), `Exporter le compte rendu`.

Animation sobre et échelonnée (titre, gagnant, lignes du classement, boutons), un seul son, vibration seulement si l'humain gagne. Pas de confettis. Kibishi, brunotot et WizardScore font un podium.

### 2.8 Historique

- hareeg : une carte par partie (date, gagnant, classement de l'humain, scores par siège, configuration, « rejeu disponible ou non »), suppression avec confirmation, états vides et états d'erreur prévus.
- WizardScore : 50 dernières parties, détail = feuille de score complète.
- Tarok : liste des rejeux, journal de partie événement par événement, partage d'un rejeu par lien.

### 2.9 Statistiques et profil

| Donnée | Vu dans |
|---|---|
| Parties jouées, victoires, taux de victoire | hareeg, carg, WizardScore, Tarok, League |
| Classement moyen, marge moyenne | hareeg |
| Répartition par niveau de bot | hareeg |
| Classement entre joueurs | WizardScore, League, Crazy-Game |
| Classement ELO et saisons | League, Tarok |
| Avatar : couleur + initiales | WizardScore |
| Avatar : photo | carg, Tarok |
| Avatars générés et personnalité des bots | spades |

Deux règles de hareeg à reprendre telles quelles :

- **« Indisponible n'est pas zéro »** : une moyenne sans dénominateur s'affiche `—`, jamais `0 %`.
- Les statistiques se calculent à partir de **résumés de partie** légers, jamais en relisant les rejeux.

### 2.10 Règles, tutoriel, coach

- Règles consultables dans l'application : tous. WizardScore les met derrière une icône dans la barre de l'écran de jeu.
- hareeg : accueil guidé au premier lancement, liste de leçons d'entraînement avec progression, coach en jeu désactivable.
- spades : conseils courts aux moments clés, **chaque conseil disparaît après quelques apparitions**.
- Tarok : guide par thème (cartes, enchères, annonces).

### 2.11 Réglages

Regroupements de hareeg : **Apparence** (thème de cartes, tapis, contraste élevé), **Ressenti** (son, vibrations, vitesse, tours rapides des bots), **Tri de la main** (par couleur, par valeur, manuel), **Règles de table**, **Conseils**, **Langue**, **Licences**.

Tarok ajoute : confirmation automatique, enchaînement automatique de la manche suivante, coup préparé à l'avance, mise en évidence de la carte la plus forte, mode sombre, options développeur.

---

## 3. Rendu des cartes

### 3.1 Version minimale (Bridge Flutter)

Quatre widgets suffisent pour une table :

- `CardFace(card, width, dimmed)` : **toute la géométrie dérive de la largeur** (hauteur = 1,45 × largeur, rayon = 0,13 × largeur, tailles de police proportionnelles). Indice et symbole en haut à gauche, grand symbole en bas à droite.
- `CardBack(width)` : fond uni et liseré.
- `HandFan(cards, legal, onTap)` : cartes superposées dans une pile, pas calculé pour tenir dans la largeur disponible et borné ; les cartes hors de `legal` sont estompées et non cliquables.
- `HiddenHand(count, vertical)` : dos superposés, tournés d'un quart de tour pour les joueurs de côté.

Plus `TrickArea` (une carte par siège autour du centre, bordure dorée sur la gagnante) et `SeatTag` (nom et note, anneau doré si c'est son tour).

### 3.2 Version complète (hareeg-table, ADR 0002)

- **Le moteur ne sait rien du rendu.** Un seul widget carte, alimenté par un thème.
- **Thème = donnée**, pas une sous-classe : identifiant, libellé, palette, liste des illustrations, attribution de licence, indicateur « lisible en petit format ». Thèmes dessinés par code ou à partir d'images.
- **Variantes** de taille : `full`, `compact`, `picker`, `back`.
- **États visuels** appliqués par-dessus n'importe quel thème : `normal`, `selected`, `pending`, `invalid`, `disabled`, plus des surbrillances de cible et de coach.
- **Contraste élevé** : un second jeu de styles d'état, activable dans les réglages.
- **Test automatique** vérifiant que chaque carte a bien son illustration, ajouté après qu'un valet de carreau a affiché un valet de cœur.
- Étiquette d'accessibilité sur chaque carte.

### 3.3 Cartes Skull King (Shantanu467)

Une table de métadonnées par couleur et par carte spéciale : couleur, icône, libellé.

| Carte | Couleur | Icône |
|---|---|---|
| Vert / perroquet | `#2ecc71` | 🦜 |
| Jaune / coffre | `#f1c40f` | 💰 |
| Violet / carte au trésor | `#a55eea` | 🗺️ |
| Noir / drapeau pirate (atout) | `#cfd8e3` | ☠️ + badge « ATOUT » |
| Fuite | `#9aa6b2` | 🏳️ |
| Pirate | `#e67e22` | ⚔️ |
| Sirène | `#1abc9c` | 🧜‍♀️ |
| Skull King | `#e74c3c` | 👑 |
| Baleine blanche | `#74b9ff` | 🐳 |

Carte numérotée : valeur dans deux coins, icône au centre. Carte spéciale : grande icône et libellé. Bon point de départ sans aucune illustration ; attention, l'apparence des émojis change d'un appareil à l'autre.

### 3.4 Palettes de table relevées

| Dépôt | Tapis | Carte | Accent |
|---|---|---|---|
| hareeg-table | `#12382F` sur fond `#15110E` | ivoire `#F8F0DD` | or `#D69B35`, liseré sable `#D7BD83` |
| Bridge Flutter | `#1E5C3A` / `#17462C` | ivoire `#FDF9EE` | ambre |
| spades | vert en dégradé radial | blanc | or sur la carte gagnante |

hareeg centralise ses jetons de style : grille d'espacement de 4 px, rayons (carte 10, bouton 12, panneau 18), cibles tactiles (48 px, 44 px minimum pour une carte), styles de texte nommés.

---

## 4. Données et persistance

### 4.1 Schéma d'un jeu à paris (WizardScore, SQLite)

```
players        id, name, color_index, is_archived
games          id, started_at, ended_at, status, player_count, current_round, règle maison
game_players   game_id, player_id, seat, total_score, final_rank
rounds         id, game_id, round_number, cards_dealt, dealer_seat, status
round_entries  round_id, player_id, bid, bid_locked, tricks_won, points
game_winners   game_id, player_id
```

- Un joueur se **archive**, il ne se supprime pas : l'historique reste cohérent.
- Classement = victoires, puis taux de victoire.
- « Terminer sans enregistrer » : une partie abandonnée ne compte pour personne.

### 4.2 Sauvegarde, historique et rejeu (hareeg-table)

- **Partie en cours** : un seul point de reprise, écrit en continu.
- **Historique** : un index de **résumés** (identifiant, date de fin, configuration, scores finaux, gagnant, classement de l'humain, nombre de manches, rejouable ou non), lu à chaque affichage de la liste.
- **Rejeu** : un fichier par partie, chargé seulement à l'ouverture du rejeu.
- **Faits de fin de partie** écrits une seule fois au moment où la partie se termine (heure, gagnant, scores) et jamais recalculés, pour qu'un plantage pendant l'archivage ne produise pas un historique faux.
- Récupération au démarrage si l'archivage a été interrompu.
- toranpu résume l'idée du rejeu : **une partie, c'est sa graine et ses coups**. On la sauvegarde, la partage, la rejoue et la vérifie avec ça (cohérent avec `REFERENCE_RTAROT.md` §5).

### 4.3 Architecture en couches (hareeg-table, ADR 0001)

```
lib/domain   règles et modèles, Dart pur, sans Flutter
lib/cpu      bots : reçoivent l'état visible et les coups légaux, renvoient une intention
lib/data     dépôts et stockage
lib/ui       écrans, widgets, thèmes
lib/app      routes et assemblage
```

« Le niveau d'un bot ne peut pas contourner la légalité » : le moteur valide tout, y compris les coups des bots. Bridge Flutter fait pareil en petit : `engine/` en Dart pur, un seul contrôleur qui orchestre, `ui/`.

### 4.4 Bots

- Un bot ne voit que ce que son siège peut voir (hareeg, Bridge, toranpu, spades).
- Niveaux : hareeg en a quatre (débutant, occasionnel, confirmé, expert).
- spades donne aux bots un nom, un avatar, un niveau en étoiles et un style de jeu, avec de courtes répliques.
- Délai artificiel réglable pour que leurs coups soient lisibles.

---

## 5. Enchaînement d'écrans proposé pour `skull_kings`

Synthèse des dépôts ci-dessus appliquée aux règles. C'est une proposition à valider, pas une décision.

```
Démarrage
└─ Accueil
   ├─ Continuer              (si une partie est sauvegardée)
   ├─ Nouvelle partie ─────► Configuration ─► Table
   ├─ Historique ──────────► Détail d'une partie (feuille de score, rejeu)
   ├─ Statistiques / Profil
   ├─ Règles
   └─ Réglages
```

### 5.1 Configuration d'une partie

| Réglage | Valeurs | Règle |
|---|---|---|
| Joueurs | 2 à 8, humains ou bots, ordre des sièges | §4 |
| Niveau des bots | par bot | — |
| Premier joueur | choisi ou au hasard | §12 n° 4 |
| Mode de score | classique / Rascal | §8 |
| Cartes d'extension | Kraken, Baleine blanche, Butin (séparément) | §10 |
| Pouvoirs des pirates | oui / non | §10.5 |

Contraintes à refléter : à 2 joueurs, Barbe Grise est ajouté d'office et le Butin est indisponible ; à 8 joueurs, afficher que les manches 9 et 10 se jouent à 8 cartes.

### 5.2 Une manche

| Étape | Écran | Détail | Règle |
|---|---|---|---|
| Distribution | Table | Animation ; bandeau « Manche 3 · 3 cartes » | §4 |
| Paris | Table + panneau de pari | Boutons 0 à N. Paris cachés jusqu'à ce que tous aient choisi, puis révélés ensemble | §5.1 |
| Jeu | Table | Cartes injouables grisées, phrase d'état, pari et plis de chaque joueur visibles | §6 |
| Tigresse | Fenêtre | Pirate ou fuite | §7 |
| Pouvoir de pirate | Fenêtre | Rosie, Will, Rascal, Harry ; Juanita montre la pioche | §10.5 |
| Fin de pli | Table | Carte gagnante en surbrillance, bonus affichés, pli vers le gagnant. Pli détruit signalé | §7, §10 |
| Fin de manche | Surimpression sur la table | Par joueur : pari, plis, points du pari, bonus détaillés, total, cumul | §8 |
| Suite | — | Manche suivante, prolongation si égalité en tête, ou fin de partie | §5.4 |

Accessibles à tout moment depuis la table : **feuille de score** complète, **dernier pli**, **pause** (reprendre, réglages rapides, règles, quitter).

### 5.3 Fin de partie

Gagnant en grand, classement final avec scores, puis `Rejouer avec la même configuration`, `Retour à l'accueil`, `Voir la feuille de score`.

### 5.4 Points propres à Skull King, absents des dépôts étudiés

- **Plusieurs humains sur un même téléphone** : écran de passage (« Passe le téléphone à Léa ») avant d'afficher une main ou de demander un pari. Aucun des dépôts ne gère ce cas : ils sont soit « 1 humain contre des bots », soit en ligne.
- **Révélation simultanée des paris** : un moment à mettre en scène (le « Yo-ho-ho ! » du livret).
- **Bonus** : les afficher au moment où ils sont gagnés, en rappelant qu'ils ne comptent que si le pari est réussi.
- **Barbe Grise** à 2 joueurs : un siège qui retourne sa carte sans décider.

### 5.5 Ordre de construction suggéré

1. Table jouable à 1 humain contre des bots aléatoires (cartes minimales façon Bridge Flutter, métadonnées façon Shantanu467).
2. Fin de manche, feuille de score, fin de partie.
3. Accueil, configuration, reprise de partie.
4. Historique et statistiques.
5. Réglages, règles intégrées, thèmes de cartes.
6. Extension, pouvoirs des pirates, score Rascal.
7. Plusieurs humains sur un téléphone, tutoriel, meilleurs bots.
