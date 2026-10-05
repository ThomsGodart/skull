# rtarot — ce qu'on en retient pour le jeu complet

Analyse de [AdrienPensart/rtarot](https://github.com/AdrienPensart/rtarot), lu intégralement le 2026-10-05 (commit `0dffe2b`, 2026-09-07). C'est un jeu de tarot français complet (3, 4 ou 5 joueurs) écrit en Rust.

`skull_kings` ne sera pas qu'un compteur : on veut le jeu complet (distribution, mains, plis, résolution). Ce document sert de base d'architecture pour le moteur de jeu.

## Ce que le dépôt contient réellement

| Attendu | Réalité |
|---|---|
| Enchaînement d'écrans | **Aucun écran.** L'interface est un terminal : des `println!` et une saisie d'index au clavier. |
| Style des cartes | **Aucun visuel.** Une couleur de terminal par enseigne, un symbole Unicode (♥ ♠ ♦ ♣), et un dessin ASCII par carte. |
| Moteur de jeu | **Oui, et c'est la partie précieuse** : un moteur de règles complet, sans aucune dépendance à l'interface, testé, déterministe. |

Le dépôt n'a pas de fichier de licence : on reprend l'architecture et les idées, pas le code.

Structure : un espace de travail à deux paquets.

| Paquet | Rôle | Taille |
|---|---|---|
| `core` | Moteur de règles, « free of any user interface » | ~3 900 lignes, dont `engine.rs` 1 600 (700 de tests) |
| `cli` | Interface terminal : poser les questions à l'humain, afficher les événements | ~450 lignes |

---

## 1. L'idée centrale : Question / Réponse / Événement

Le moteur **ne lit rien, n'affiche rien, ne bloque jamais**. Il se pilote avec deux appels :

```
moteur.pending()         → la Question en attente (ou rien si la partie est finie)
moteur.answer(réponse)   → applique la réponse, puis avance jusqu'à la prochaine question
moteur.take_events()     → tout ce qui s'est passé depuis le dernier appel
```

Boucle complète du pilote (c'est toute la fonction `play` du terminal) :

```
tant que vrai :
    pour chaque événement de moteur.take_events() : l'afficher
    question = moteur.pending()  ; si aucune → fin
    réponse  = demander à l'humain, ou à un bot
    moteur.answer(réponse)
```

Trois types font tout le contrat entre le moteur et l'interface :

- **Question** : ce que le moteur a besoin de savoir. Elle porte **le joueur concerné** et **la liste des choix autorisés**. L'interface n'a jamais à connaître les règles : elle affiche `allowed` et renvoie un élément de cette liste.
- **Réponse** : le choix. Le moteur revérifie qu'il est dans la liste (`InvalidCard`, `MismatchedAnswer`, `UnexpectedAnswer` sinon).
- **Événement** : ce qui vient de se passer, sous forme de données (`CardPlayed { player, card }`, `TurnWon { player, cards }`…). L'interface en fait ce qu'elle veut : texte, animation, son.

Conséquences directes, toutes utiles pour nous :

1. **Le même moteur sert à l'humain, aux bots et aux tests.** Un bot est juste une autre façon de produire une réponse. `random_answer(question)` tire un choix légal au hasard : c'est déjà un bot minimal.
2. **Les animations se calent sur les événements**, pas sur l'état : l'interface dépile la liste et joue une animation par événement, dans l'ordre.
3. **Aucune règle dans l'interface** : griser les cartes injouables = afficher `question.allowed`.
4. **Passage en ligne possible plus tard** sans toucher au moteur : questions et événements sont des données sérialisables.

## 2. Machine à états interne

Le moteur garde une `Phase` et une fonction `advance()` qui boucle tant qu'aucune question n'est en attente : chaque phase soit pose une question, soit fait avancer l'état et passe à la suivante.

Phases du tarot : `Dealing → Bidding → Calling → AnnouncingSlam → Discarding → Handle → TrimHandle → Playing → Counting → (Dealing…) → Finished`.

Points de conception à reprendre :

- Un constructeur qui appelle `advance()` : un moteur tout neuf est **déjà en attente de sa première question**.
- Une phase peut ne rien demander (ex. « personne n'a de poignée à annoncer ») et enchaîner directement.
- Les effets automatiques (distribution, attribution du pli, calcul des points) sont des étapes de `advance()` qui n'émettent que des événements.

## 3. Modèle de données

Séparation nette entre ce qui dure toute la partie et ce qui ne vit qu'une donne :

```
Engine (toute la partie)
  mode                 nombre de joueurs et tout ce qui en dépend
  rng                  générateur aléatoire à graine
  deals_left, dealer
  players: Player[]    nom + score cumulé
  deal: Deal?          la donne en cours
  phase, pending (Question?), events (Event[])

Deal (une donne)
  players: PlayerInGame[]   main, cartes gagnées, rôle, équipe, annonces
  leader                    qui entame le pli en cours
  master                    qui est en train de gagner le pli
  turn: Turn                les cartes posées + index de la carte maîtresse
  …état propre au tarot (chien, contrat, preneur)

Turn (un pli)
  cards                cartes dans l'ordre de jeu
  master_index         index de la carte qui gagne pour l'instant
  called()             première carte qui fixe la couleur (ignore l'Excuse)
```

Détails à reprendre :

- **`Mode` centralise tout ce qui dépend du nombre de joueurs** (cartes par joueur, taille du chien, seuils). Chez nous : cartes par manche, plafond à 8 joueurs, variante à 2 avec Barbe Grise.
- **Joueur courant calculé, pas stocké** : `(leader + nombre de cartes posées) mod nbJoueurs`.
- **Carte = type somme** (`Atout | Normale`), copiable et comparable ; les cartes étant uniques, une réponse désigne une carte par sa valeur, pas par un index.
- **`Deck` = liste de cartes** avec les opérations de base : paquet complet dans un ordre fixe, mélange avec le générateur fourni, `give(n)` pour distribuer, tri.
- **Carte maîtresse suivie au fil de l'eau** : à chaque carte posée, on la compare à la carte maîtresse courante (`master.master(card)`) et on émet `MasterChanged`. Simple pour le tarot ; **insuffisant pour Skull King** (voir §6).
- **`called()` saute l'Excuse** pour trouver la couleur demandée : exactement notre règle « une fuite en entame ne fixe pas la couleur ».

## 4. Coups légaux

`PlayerInGame::playable(turn)` renvoie la liste des cartes jouables. Commentaire du code : ce type « only ever *computes* what is legal, it never chooses ». La logique trie la main en catégories (même couleur, atouts plus forts, atouts plus faibles, autres couleurs, Excuse) puis applique « fournir, sinon couper, sinon n'importe quoi ».

Pour Skull King la règle est plus simple (pas d'obligation de couper ni de monter) : voir `GAME_RULES.md` §6.

## 5. Aléatoire, robustesse, tests

- **Graine fournie par l'appelant** (`Engine::new(mode, deals, seed)`). Le moteur n'utilise jamais l'horloge ni l'aléatoire système : même graine + mêmes réponses = même partie. Indispensable pour rejouer un bug, et pour le jeu en ligne.
- **Erreurs typées**, jamais de plantage : tout renvoie un résultat (`InvalidCard`, `MismatchedAnswer`, `NoDeal`…).
- **Contrôles d'intégrité internes** à chaque donne : toutes les cartes sont encore quelque part (78), le total des points est constant (91), la somme des scores vaut zéro.
- **Tests par parties aléatoires complètes** (`autoplay`) : on joue des centaines de parties avec `random_answer` et on vérifie des propriétés, plutôt que des scénarios écrits à la main. Propriétés vérifiées :
  - toute partie se termine, dans tous les modes ;
  - une question n'offre jamais une liste de choix vide ;
  - une carte illégale ou une réponse du mauvais type est refusée ;
  - même graine → mêmes événements ; graines différentes → parties différentes ;
  - chaque pli contient une carte par joueur ; toutes les cartes sont jouées ;
  - le gagnant d'un pli entame le suivant ;
  - les cartes et les points sont conservés.
- **Mode test en continu** dans le terminal (`--test`) : des parties aléatoires en boucle sur tous les cœurs, pour débusquer les cas limites.
- Options de confort : `--auto` (joue seul quand une seule carte est légale), `--random` (aucun humain), `--quiet`.

## 6. Transposition à Skull King

### Questions

| Question | Quand | Choix autorisés |
|---|---|---|
| `Parier` | Début de manche, pour chaque joueur | 0 à cartes distribuées |
| `JouerCarte` | À son tour dans un pli | Cartes légales de la main (`GAME_RULES.md` §6) |
| `ChoisirTigresse` | Juste après avoir posé la Tigresse (ou intégré à `JouerCarte`) | pirate / fuite |
| `ChoisirPremierJoueur` | Pli gagné avec Rosie la Douce | Tous les joueurs |
| `DefausserDeuxCartes` | Pli gagné avec Will le Bandit, après pioche de 2 | Cartes de la main |
| `MiserRascal` | Pli gagné avec Rascal le Flambeur | 0 / 10 / 20 |
| `ModifierPari` | Pli gagné avec Harry le Géant | −1 / 0 / +1 |

Juanita Jade ne demande rien : elle produit un événement **privé** (les cartes non distribuées), visible du seul joueur concerné.

### Événements

`MancheCommencee`, `CartesDistribuees`, `ParisReveles`, `CarteJouee`, `PliRemporte`, `PliDetruit` (Kraken, Baleine blanche sans carte numérotée), `BonusObtenu`, `PouvoirDeclenche`, `AllianceFormee` (Butin), `PariModifie`, `MancheScoree` (détail par joueur : points du pari, bonus, cumul), `ProlongationCommencee`, `PartieTerminee`.

### Phases

`Distribution → Paris → Jeu (→ Pouvoir de pirate) → Décompte → Distribution… → Terminée`.

### Différences avec le tarot à traiter

1. **Paris simultanés et secrets.** rtarot n'a qu'une question en attente à la fois, et chaque enchère est publiée aussitôt. Chez nous : poser `Parier` à chaque joueur, **ne rien publier** tant que tous n'ont pas répondu, puis émettre un seul événement `ParisReveles`. Sur un seul téléphone qu'on se passe, cela impose un écran de passage entre deux joueurs.
2. **Information cachée.** Les événements de rtarot sont tous publics. Il nous faut une notion de destinataire (public, ou réservé à un joueur) pour la main reçue, Juanita Jade et la pioche de Will le Bandit.
3. **Résolution du pli en fin de pli, pas au fil de l'eau.** La comparaison « carte contre carte maîtresse » ne marche pas : pirate > sirène > Skull King > pirate n'est pas un ordre, et sirène + Skull King + pirate donne la sirène quel que soit l'ordre. Le Kraken et la Baleine blanche changent aussi le résultat après coup. Il faut une fonction pure `résoudre(pli) → gagnant, bonus, pli détruit ou non` appelée quand le pli est complet (algorithme en `GAME_RULES.md` §7.3). On peut tout de même afficher un « gagnant provisoire » en appelant cette fonction sur le pli partiel.
4. **Couleur demandée** : première carte numérotée, sauf si un personnage a été joué avant elle (alors pas de couleur à suivre).
5. **Pas de preneur ni d'équipes** : chacun pour soi, le score dépend du pari de chacun.
6. **Contrôles d'intégrité adaptés** : nombre de cartes constant sur la manche (70 ou 74 moins la pioche) ; somme des plis remportés + plis détruits = cartes distribuées.
7. **Joueur spécial Barbe Grise** à 2 joueurs : un siège sans décision (carte du dessus de son paquet), pas tenu de suivre.

### Enchaînement d'écrans

rtarot n'en propose aucun. Proposition déduite des phases du moteur, à valider :

```
Accueil
  ├─ Nouvelle partie → Configuration (joueurs, humains ou bots, mode de score, extension, pouvoirs)
  ├─ Reprendre une partie
  └─ Règles / Réglages

Partie, pour chaque manche :
  Distribution (animation)
  → Paris            (un écran par joueur humain, puis révélation simultanée)
  → Table de jeu     (main en bas, pli au centre, adversaires autour avec pari et plis pris)
       ↳ fenêtres ponctuelles : choix Tigresse, pouvoirs de pirate
  → Fin de manche    (détail des points et bonus par joueur)
  → Feuille de score (accessible à tout moment)
→ Classement final (ou prolongation en cas d'égalité)
```

Chaque écran correspond à une question en attente ou à un groupe d'événements : l'interface n'a pas d'autre logique de navigation que « quelle question est en attente ? ».

### Style des cartes

rtarot ne fournit que le principe, mais il est bon : le moteur expose pour chaque carte une **représentation sémantique** (une couleur nommée, un symbole court, un dessin) et ne connaît ni terminal ni pixels ; l'interface traduit. Son commentaire : remplacer le module de rendu suffit à changer de support.

À appliquer chez nous : le moteur expose `couleur` (vert, violet, jaune, noir, ou spéciale), `valeur`, `type` ; un seul composant Flutter « carte » décide de l'apparence.

Éléments visuels fixés par les règles (`GAME_RULES.md` §3) :

| Carte | Couleur | Emblème |
|---|---|---|
| Vert 1–14 | vert | perroquet |
| Violet 1–14 | violet | carte au trésor |
| Jaune 1–14 | jaune | coffre |
| Noir 1–14 (atout) | noir | drapeau pirate |
| Spéciales | propre à chaque carte | personnage ou créature |

Deux idées de présentation de rtarot à garder : **trier la main** (atouts d'abord, puis une couleur par ligne) et **nommer les sièges** par défaut (Est, Nord, Sud, Ouest), l'humain étant au Sud, en bas de l'écran.

Les illustrations officielles sont protégées (Grandpa Beck's Games) : il faudra nos propres visuels.

## 7. Ce qu'on retient, en bref

1. Un paquet Dart pur pour le moteur (sans import Flutter), l'application Flutter par-dessus.
2. Contrat Question / Réponse / Événement, avec la liste des choix autorisés dans chaque question.
3. Machine à états avec `advance()` qui tourne jusqu'à la prochaine question.
4. Aléatoire à graine injectée ; erreurs typées ; contrôles d'intégrité.
5. Tests par parties aléatoires complètes avec propriétés, en plus des tests de règles ciblés.
6. Bots = une autre source de réponses, à commencer par un bot aléatoire.
7. Adaptations propres à Skull King : paris simultanés, information cachée, résolution du pli en fin de pli.
