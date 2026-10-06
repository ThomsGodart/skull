# Décisions de conception — `skull_kings`

**Statut : validé par Thomas le 2026-10-05.** Implémentation en cours, dans l'ordre de la section 10.

Tu m'as demandé de dérouler l'arbre de décisions et de trancher moi-même. Chaque décision ci-dessous a un identifiant (`P1`, `R4`…) pour que tu puisses répondre « OK sauf R7 et U3 ». Pour chacune : ce que j'ai retenu, pourquoi, et ce que j'ai écarté.

Sources : [`GAME_RULES.md`](../GAME_RULES.md), [`REFERENCE_REPOS.md`](REFERENCE_REPOS.md), [`REFERENCE_RTAROT.md`](REFERENCE_RTAROT.md), [`REFERENCE_CARD_GAMES.md`](REFERENCE_CARD_GAMES.md), et les conventions de ton projet `darts_points_counter` (drift, contrôleurs `ChangeNotifier`, code en anglais et interface en français, `CONTEXT.md` + `docs/adr/`).

## À relire en priorité

Ces dix décisions orientent tout le reste ou coûtent cher à changer plus tard.

| # | Décision | Pourquoi elle pèse |
|---|---|---|
| **P1** | Deux façons de jouer : seul contre des bots (hors ligne), et en ligne entre amis | Le solo est construit en premier, le jeu en ligne juste après |
| **O2** | En ligne, c'est le téléphone de l'hôte qui fait tourner la partie, via Supabase | Pas de serveur à écrire ni à héberger ; en échange, pas de protection contre la triche de l'hôte |
| **O3** | Parties privées par code de salon, sans matchmaking public | Définit tout le parcours en ligne |
| **P2** | Un mode compteur de points est inclus, après le jeu | Double usage de l'appli ; à retirer si tu ne veux que le jeu |
| **P4** | Combien de joueurs ? | 2 à 8 (1 humain + 1 à 7 bots). À 2, le fantôme de Barbe Grise joue un troisième paquet. La variante à 2 a été ajoutée en dernier, à l'étape 10. | Barbe Grise est un siège à part (pas de pari, pas de score, ne suit pas la couleur) : il a été ajouté une fois le socle stable. | — |
| **P6** | Projet personnel, pas de publication sur un store sous ce nom ni avec les visuels officiels | « Skull King » est une marque déposée |
| **R7** | Baleine blanche en cours de pli : on suit le livret français, pas la FAQ anglaise | Les deux sources officielles se contredisent |
| **A1** | Moteur en Dart pur, piloté par Questions / Réponses / Événements | Structure de toute l'application |
| **A7** | Une partie sauvegardée = graine + configuration + liste des réponses | Conditionne reprise, historique et rejeu |
| **U1** | Table en portrait, adversaires en vignettes en haut, pli en ligne au centre | Toute la mise en page de l'écran principal |

---

## 1. Produit et périmètre

| # | Question | Décision | Pourquoi | Écarté |
|---|---|---|---|---|
| **P1** | Qui joue ? | Deux modes : seul contre des bots, hors ligne et sans compte ; en ligne entre amis, chacun sur son téléphone, les sièges vides tenus par des bots. Le solo est construit d'abord. **Jeu en ligne demandé par Thomas le 2026-10-05.** | Le solo est nécessaire de toute façon (moteur, table, bots) et sert de socle au jeu en ligne. | Plusieurs humains sur un téléphone (abandonné, P3). |
| **P2** | Jeu seul, ou jeu et compteur ? | Les deux, dans la même appli. Le compteur (pour jouer avec le vrai paquet) arrive plus tard, une fois le jeu fait. **Confirmé par Thomas le 2026-10-05.** | Tu as dit « pas seulement un compteur ». Il réutilise le calcul des scores, la feuille de score, l'historique et les joueurs : coût faible. | Compteur seul ; jeu seul. |
| **P3** | Plusieurs humains sur un même téléphone ? | Non, abandonné. **Tranché par Thomas le 2026-10-05.** | Ce n'est pas l'usage visé. Pas d'écran de passage du téléphone à concevoir. | L'inclure en v1 ou plus tard. |
| **P4** | Combien de joueurs ? | 3 à 8 en v1 (1 humain + 2 à 7 bots). La variante à 2 avec Barbe Grise est ajoutée ensuite. | Barbe Grise est un siège à part (pas de pari, pas de score, ne suit pas la couleur) : un cas spécial à ne pas mêler au socle. | 2 à 8 dès la v1. |
| **P5** | En ligne ? | Oui, voir la section 6 « Jeu en ligne ». **Demandé par Thomas le 2026-10-05.** | — | — |
| **P6** | Nom, marque, visuels | Projet personnel. Nos propres visuels. Pas de publication sur un store sous le nom « Skull King » ni avec les illustrations officielles sans y réfléchir à nouveau. | Skull King® est une marque de Grandpa Beck's Games ; les illustrations sont protégées. | Reprendre les illustrations du livret. |
| **P7** | Plateforme cible | Android uniquement pour le moment. Les autres dossiers générés par Flutter restent en place, sans garantie. **Confirmé par Thomas le 2026-10-05.** | Tous les joueurs visés sont sur Android ; un fichier d'installation envoyé directement suffit. | iOS et web en v1. |
| **P8** | Langues | Interface en français uniquement. Textes regroupés dans `lib/ui/strings.dart` pour traduire plus tard ; seul le texte des règles, long, est à part dans `lib/ui/rules_content.dart`. Code, identifiants et tests en anglais. | Convention de ton autre projet ; le livret de référence est le français. | Internationalisation complète dès la v1. |
| **P9** | Longueur d'une partie | 10 manches, comme le livret. Pas de partie courte en v1. | Reste fidèle aux règles ; une partie courte est une option facile à ajouter. | Nombre de manches réglable. |

## 2. Règles : les points que le livret ne tranche pas

Numéros entre parenthèses = lignes de `GAME_RULES.md` §12. Une fois validées, je reporterai ces décisions dans `GAME_RULES.md` et retirerai les marques « interprétation ».

| # | Question | Décision | Pourquoi |
|---|---|---|---|
| **R1** | (1) Tigresse jouée comme pirate | C'est un pirate à part entière : +30 si le Skull King la capture, +20 par sirène qu'elle capture. Jouée comme fuite : aucun bonus. | Le livret la dit battue « comme pirate » ; la FAQ confirme le cas fuite. |
| **R2** | (2) Fuite en entame, puis un personnage, puis une carte Couleur | Pas de couleur à suivre pour ce pli. | Cohérent avec « personnage en entame = pas de couleur ». |
| **R3** | (3) Pari maximum | Le nombre de cartes distribuées. | On ne peut pas gagner plus de plis. |
| **R4** | (4) Premier donneur | Tiré au sort avec la graine de la partie. Dans le compteur : choisi à la création. | Reproductible ; dans le compteur c'est la table réelle qui décide. |
| **R5** | (5, 23) Égalité après la manche 10 | Manches supplémentaires au nombre de cartes de la manche 10, jouées par **tous**, tant qu'il y a égalité pour la **première place**. | Le livret dit « une nouvelle manche » ; c'est la lecture la plus simple, celle du dépôt de référence. Les autres égalités restent des ex æquo. |
| **R6** | (8) 8 joueurs avec l'extension | Plafond de 8 cartes maintenu aux manches 9 et 10. | Le livret ne lève la limite nulle part, et le pari à 0 se calcule dessus. |
| **R7** | (22) Baleine blanche jouée en cours de pli | Livret français : plus d'obligation de suivre à partir de cette carte. Idem pour le Kraken. | Deux sources officielles se contredisent ; l'édition de référence du projet est la française. Isolé dans une seule fonction pour pouvoir inverser. |
| **R8** | (9) Bonus d'un pli détruit par le Kraken | Perdus. | Personne ne remporte le pli. |
| **R9** | (10, 12) Qui « aurait dû gagner » un pli détruit | Le gagnant du pli résolu sans Kraken ni Baleine blanche. | Confirmé par la FAQ. |
| **R10** | (11) Baleine blanche et bonus | Les 14 du pli rapportent leur bonus au gagnant ; les bonus de personnages sont perdus. | Les cartes numérotées restent dans le pli, les spéciales sont détruites. |
| **R11** | (13) Kraken et Baleine blanche | Jouables à tout moment, comme toute carte spéciale. | Ce sont des cartes non numérotées. |
| **R12** | Kraken + Baleine blanche dans le même pli | Seul l'effet de la seconde s'applique, la première vaut une fuite. | FAQ officielle. |
| **R13** | (14, 15) Butin | Chaque butin crée sa propre alliance avec le gagnant du pli. Aucune alliance si le pli est détruit, sous une Baleine blanche (le butin est détruit avec les autres cartes spéciales), ou si c'est un butin qui remporte le pli : dans ce dernier cas personne n'est allié, pas même le joueur d'un second butin. Bonus soumis à un pari **exact** des deux, dans tous les modes de score. | Livret + FAQ. |
| **R14** | (16) Pouvoir de la Tigresse | Aucun. | Seuls les cinq pirates nommés en ont un. |
| **R15** | (17, 18) Will le Bandit et Juanita Jade sans pioche | Will pioche ce qui reste (0, 1 ou 2 cartes) et défausse autant ; Juanita voit ce qui reste. Défausse face cachée, hors jeu pour la manche. | La règle la moins surprenante. |
| **R16** | (19) Harry le Géant | Son pouvoir s'utilise **à la fin de la manche**, une fois tous les plis joués, et non au moment où le pli est gagné (demandé par Thomas le 2026-10-06). Pari modifié borné entre 0 et le nombre de cartes ; le score utilise le pari modifié. | C'est ainsi que le pouvoir a de l'intérêt : on sait combien de plis on a pris. Un pari hors bornes n'a pas de sens. |
| **R17** | (20) Rascal le Flambeur | Mise de 0, 10 ou 20 : gagnée si le pari est exact, **perdue** sinon, dans tous les modes de score. Si Harry le Géant a modifié le pari dans la même manche, c'est le pari modifié qui compte (lecture retenue à l'implémentation ; le livret dit « pari de début de manche », écrit sans envisager ce cas). | Livret + FAQ. |
| **R18** | (21) Pouvoir d'un pirate dont le pli est détruit | Pas de pouvoir. | Le pli n'est pas remporté. |
| **R19** | Pouvoirs facultatifs ? | Oui : Rosie peut se désigner elle-même, Rascal miser 0, Harry garder son pari. Seul Will pioche d'office ; son joueur peut défausser les cartes qu'il vient de piocher, ce qui revient au même pour sa main. | Le livret dit « vous pouvez » pour Harry ; je généralise pour ne jamais forcer un choix désavantageux. |
| **R20** | Variante « Cannonball » du score Rascal | Non incluse. | Aucune source officielle ne la décrit. |
| **R21** | Demi-points du score Rascal | Division par deux, sans arrondi à prévoir. | Le potentiel (10 × cartes) et tous les bonus sont des multiples de 10 : leur moitié est toujours un entier. |
| **R22** | (6, 7) Barbe Grise, à 2 joueurs | Ne parie pas, ne marque pas. Joue en deuxième ; s'il gagne un pli il entame le suivant, puis le joueur qui a entamé la manche, puis l'autre. Les bonus d'un pli qu'il remporte sont perdus, et un pirate avec lequel il gagne ne déclenche aucun pouvoir. | Lecture directe du livret ; les deux derniers points en découlent, puisqu'il ne marque pas et ne décide rien. |

## 3. Modes de jeu et configuration

| # | Question | Décision | Pourquoi |
|---|---|---|---|
| **M1** | Mode par défaut | Jeu de base (70 cartes), score classique, sans pouvoirs. | C'est la « partie classique » du livret. |
| **M2** | Extension | Trois interrupteurs indépendants : Kraken, Baleine blanche, Butin. Un quatrième pour les pouvoirs des pirates. | Le livret dit « une ou plusieurs, combinées selon vos envies ». |
| **M3** | Préréglages | « Classique », « Extension complète », « Personnalisé ». | Évite de régler quatre interrupteurs à chaque partie. |
| **M4** | Mode de score | Classique par défaut, Rascal en option, choisi par partie. | Les deux sont officiels. |
| **M5** | Configuration figée ? | Oui, une fois la partie lancée. Les préférences (vitesse, son…) restent modifiables. | Sinon l'historique et le rejeu deviennent incohérents. |
| **M6** | Mémoire | La dernière configuration est proposée par défaut. | Geste le plus fréquent : rejouer pareil. |

## 4. Architecture

| # | Question | Décision | Pourquoi | Écarté |
|---|---|---|---|---|
| **A1** | Où vivent les règles ? | Dans `lib/engine/`, en Dart pur. Un test échoue si un fichier de ce dossier importe Flutter. Le moteur se pilote par Questions / Réponses / Événements : il pose une question avec la liste des choix autorisés, reçoit une réponse, publie ce qui s'est passé. | Règles testables sans interface ; bots et humain passent par le même chemin ; l'interface n'a aucune règle à connaître. | Un paquet Dart séparé (plus lourd, sans gain à ce stade) ; règles dans les widgets. |
| **A2** | Résolution d'un pli | Une fonction pure appelée quand le pli est complet : elle rend le gagnant, les bonus et si le pli est détruit. La même fonction sert à afficher le gagnant provisoire. | La hiérarchie n'est pas un ordre (pirate > sirène > Skull King > pirate) et Kraken ou Baleine changent le résultat après coup. | Comparer chaque carte à la carte maîtresse au fil de l'eau. |
| **A3** | Aléatoire | Une graine par partie, fournie au moteur. Aucun appel à l'horloge ou au hasard système dans le moteur. Le générateur est écrit dans le moteur (`seeded_random.dart`), pas celui de Dart, dont la suite peut changer d'une version à l'autre ; un test fige les cartes distribuées pour une graine donnée. | Même graine et mêmes réponses = même partie : rejouer un bug, rejouer une partie. | — |
| **A4** | Paris simultanés | Le moteur garde les paris secrets et publie un seul événement de révélation quand tous ont répondu. Plusieurs questions peuvent être en attente en même temps. | Fidèle au livret ; les bots ne peuvent pas voir le pari de l'humain. | Paris à tour de rôle visibles. |
| **A5** | Information cachée | Le moteur fournit une vue par siège (ma main, ce qui est public, la composition du paquet). Les événements portent un destinataire : tous, ou un siège. Les bots ne reçoivent que leur vue, qui ne contient ni la graine ni les mains des autres. | Indispensable pour Juanita, Will et le jeu en ligne : chaque téléphone ne reçoit que la vue de son siège. Empêche un bot de tricher par construction. | Donner l'état complet à tout le monde. |
| **A6** | Erreurs | Une réponse illégale lève une exception typée ; le moteur reste dans son état précédent. | Idiome Dart ; ne doit jamais arriver puisque l'interface n'offre que les choix autorisés. | Type résultat à la Rust. |
| **A7** | Sauvegarde | Une partie = graine + configuration + liste ordonnée des réponses. On la reprend en rejouant les réponses. Écrite après chaque réponse. | Sauvegarde minuscule, reprise exacte, rejeu gratuit, aucun état dérivé à migrer. | Sérialiser tout l'état du moteur. |
| **A8** | Stockage | drift (SQLite), comme `darts_points_counter`. | Même outil que ton autre projet ; requêtes pour l'historique et les statistiques. | Fichiers JSON ; préférences seules. |
| **A9** | État de l'interface | Contrôleurs `ChangeNotifier`, sans bibliothèque de gestion d'état. Un contrôleur de partie fait le lien moteur ↔ écran et dépile les événements pour les animer. | Convention de ton autre projet ; suffisant pour une appli à un seul écran complexe. | Riverpod, Bloc. |
| **A10** | Navigation | `Navigator` seul, sans bibliothèque de routage. Les écrans sont poussés directement (la table reçoit son contrôleur en paramètre). | Une dizaine d'écrans, pas de liens profonds. | go_router. |
| **A11** | Modèles | Classes immuables et types scellés écrits à la main. Seule génération de code : drift. Exception assumée : la partie du compteur (`CounterGame`) est un objet qu'on modifie en place, manche après manche. | Peu de modèles ; pas de dépendance de plus. Pour le compteur, corriger une manche passée est l'opération centrale, et la recopie complète n'apportait rien. | freezed, json_serializable. |
| **A12** | Services externes | Supabase, uniquement pour le jeu en ligne (identité anonyme, salons, messages en temps réel), dans un **projet Supabase dédié, séparé de celui de `darts_points_counter`** (décidé par Thomas le 2026-10-05). Le solo, l'historique et les statistiques restent locaux et fonctionnent sans réseau. Pas de rapport de plantage en v1. | Déjà branché dans ton autre projet ; couvre les trois besoins sans serveur à nous. | Firebase ; un serveur Dart à héberger. |
| **A13** | Compteur et jeu | Le compteur enregistre des saisies (pari, plis, bonus par type) ; le jeu les déduit du moteur. Les deux alimentent le même calcul de score et la même feuille de score. | Un seul calcul des points, testé une fois. | Deux implémentations. |
| **A14** | Bonus | Liste d'événements typés, en deux familles : captures et 14 (proportionnels à la réussite du pari), Butin et mise de Rascal (pari exact exigé). | Voir `REFERENCE_REPOS.md` §3 : c'est ce que les compteurs existants ratent. | Un total brut. |

## 5. Bots

| # | Question | Décision | Pourquoi |
|---|---|---|---|
| **B1** | Niveaux | Trois niveaux, choisis à la création de la partie : Facile (se trompe un pari sur deux et une carte sur trois), Normal (le bot « raisonnable »), Difficile (parie en comptant le paquet à partir de 5 joueurs ; en dessous, il joue comme Normal, faute d'avoir trouvé mieux). | Mesuré sur des centaines de parties : le pari compté gagne nettement à 5 joueurs et plus, pas en dessous. |
| **B2** | Comment il parie | Estimation carte par carte de la chance de prendre un pli (personnages, atouts hauts, 14), arrondie. | Simple, lisible, ajustable. |
| **B3** | Comment il joue | S'il lui manque des plis : gagner au moindre coût. S'il a son compte : perdre, en gardant les fuites pour les plis dangereux. | Le cœur de la stratégie de Skull King. |
| **B4** | Ce qu'il voit | Uniquement la vue de son siège (A5). | Pas de triche. |
| **B5** | Identité | Noms de pirates inventés, une couleur et des initiales. Pas de personnalité ni de répliques en v1. | Suffit pour les distinguer. |
| **B6** | Rythme | Environ 0,7 s par coup de bot, réglable (normal, rapide, instantané). | Laisser le temps de lire le pli. |
| **B7** | Niveaux suivants | Plus tard : mémoire des cartes tombées, prise en compte des paris adverses. | Hors v1. |

## 6. Jeu en ligne

Ajouté le 2026-10-05 à ta demande. Supabase est déjà initialisé dans `darts_points_counter`, mais presque pas utilisé : rien n'est à reprendre tel quel.

| # | Question | Décision | Pourquoi | Écarté |
|---|---|---|---|---|
| **O1** | Quand ? | Après le solo jouable et sauvegardé, avant l'historique, l'extension et le compteur. | Le jeu en ligne réutilise le moteur, la table et les bots ; le construire avant qu'ils soient stables coûterait double. | En premier ; tout à la fin. |
| **O2** | Qui fait tourner la partie ? | Le téléphone de l'hôte (celui qui crée le salon). Il fait tourner le moteur, reçoit les réponses des autres et envoie à chacun la vue de son siège et les événements qui le concernent, par les canaux temps réel de Supabase. | Le moteur est en Dart : il tourne tel quel sur le téléphone de l'hôte. Aucun serveur à écrire, héberger ou payer. | Moteur côté serveur (il faudrait le réécrire en TypeScript ou héberger un serveur Dart). |
| **O2b** | Limite assumée | L'hôte pourrait techniquement voir toutes les mains en modifiant l'appli. Acceptable entre amis, pas pour du jeu public. | Si un jour il faut de l'anti-triche, le même moteur peut tourner sur un serveur Dart sans changer le reste. | — |
| **O3** | Avec qui ? | Parties privées entre amis : l'hôte crée un salon et partage un code court ou un lien. Pas de matchmaking public, pas de liste de salons. | C'est l'usage visé ; évite modération et triche. | Parties publiques. |
| **O4** | Comptes | Identité anonyme créée automatiquement, plus le pseudo et la couleur du profil local. Pas d'e-mail ni de mot de passe. | Rejoindre une partie doit prendre dix secondes. | Inscription obligatoire. |
| **O5** | Salon d'attente | Liste des joueurs présents, configuration de la partie choisie par l'hôte et visible de tous, bouton « Lancer » pour l'hôte. Les sièges vides peuvent être remplis par des bots. 2 à 8 joueurs au total (P4), dont au moins 2 humains. | Reprend l'écran de nouvelle partie. | — |
| **O6** | Paris | Chacun parie sur son téléphone ; révélation quand tous ont validé. | La règle du livret s'applique enfin naturellement. | — |
| **O7** | Joueur déconnecté | Son siège attend 30 secondes, puis un bot joue à sa place. Il reprend la main dès qu'il revient. | Une partie ne doit pas rester bloquée. | Annuler la partie. |
| **O8** | Hôte déconnecté | La partie est en pause pour tous jusqu'à son retour. La graine et les réponses sont enregistrées en ligne au fil de l'eau : l'hôte reprend exactement où il en était. | Conséquence de O2. Le transfert du rôle d'hôte à un autre joueur est possible plus tard grâce à cet enregistrement. | Transfert automatique d'hôte dès la v1. |
| **O9** | Temps de réflexion | Pas de chronomètre. | Entre amis ; à ajouter en option si besoin. | Minuteur par coup. |
| **O10** | Discussion | Aucune en v1. | Les amis se parlent déjà ailleurs ; évite toute modération. | Messagerie ; réactions prédéfinies (plus tard). |
| **O11** | Versions | Un salon porte la version des règles du moteur ; une appli d'une autre version ne peut pas le rejoindre et affiche « mets à jour l'appli ». | Deux moteurs différents donneraient deux parties différentes. | — |
| **O12** | Historique et statistiques | Une partie en ligne terminée s'enregistre dans l'historique local de chaque joueur, marquée « en ligne ». Statistiques séparées solo / en ligne. | Pas de profil en ligne à gérer. | Classement en ligne, ELO. |
| **O13** | Variante à 2 en ligne | Deux humains peuvent jouer seuls avec Barbe Grise, ou ajouter des bots. | La variante à 2 existe dans le moteur (P4). | — |
| **O14** | Sécurité des données | Chaque joueur ne peut lire que les messages de son siège et les messages publics du salon ; seul l'hôte écrit l'état de la partie. | Sinon n'importe qui lirait les mains des autres. | — |

Écrans ajoutés : sur l'accueil, « Jouer en ligne » → « Créer une partie » ou « Rejoindre avec un code » → salon d'attente → table. La table est la même qu'en solo, avec un indicateur de connexion par joueur.

## 7. Interface

| # | Question | Décision | Pourquoi | Écarté |
|---|---|---|---|---|
| **U1** | Orientation et disposition de la table | Portrait partout. Adversaires en vignettes sur une ou deux rangées en haut ; pli au centre, cartes posées en ligne dans l'ordre de jeu ; main en bas. | Jusqu'à 7 adversaires : une disposition « autour de la table » ne tient pas sur un téléphone. Le portrait se tient d'une main. | Paysage ; cartes en croix autour du centre. |
| **U2** | Vignette d'un adversaire | Initiales sur une couleur, nom, pari, plis pris, nombre de cartes en main. Anneau doré sur celui dont c'est le tour, marque pour le donneur. | Tout ce qu'il faut pour décider, sans afficher de dos de cartes. | Mains adverses dessinées. |
| **U3** | Jouer une carte | Un premier appui soulève la carte, un second la joue. Réglage pour jouer en un seul appui. | Une carte jouée par erreur ruine un pari. | Glisser-déposer ; un seul appui par défaut. |
| **U4** | Cartes injouables | Estompées et non cliquables ; une phrase d'état dit quoi faire (« À toi — fournis du vert »). | Les coups légaux doivent se voir, pas se deviner. | Les masquer. |
| **U5** | Tri de la main | Vert, jaune, violet, noir, par valeur croissante, puis les cartes spéciales. Fixe en v1. | Lisible ; l'atout juste avant les spéciales. | Tri réglable. |
| **U6** | Pari | Panneau sous la table : boutons de 0 à N, puis confirmation. Révélation simultanée animée. | Fidèle au « Yo-ho-ho ! ». | Curseur. |
| **U7** | Tigresse et pouvoirs | Fenêtre de choix à l'instant où la question se pose. Tigresse : pirate ou fuite. | Un choix ponctuel, une fenêtre. | — |
| **U8** | Fin de pli | Carte gagnante entourée, bonus affichés avec la mention « si pari réussi », pause d'environ 2,2 s (allongée à la demande de Thomas le 2026-10-06), puis suite automatique. Un appui passe. Pli détruit signalé explicitement. | Lisible sans ralentir. | Attendre un appui à chaque pli. |
| **U9** | Fin de manche | Panneau par-dessus la table : par joueur, pari, plis, points du pari, bonus détaillés, total de la manche, cumul. Bouton « manche suivante ». | Un écran séparé ralentit entre deux manches. | Écran plein. |
| **U10** | Toujours accessibles en jeu | Feuille de score complète, dernier pli, pause. | Vu dans toutes les bonnes références. | — |
| **U11** | Pause et sortie | Le retour système ouvre la pause : reprendre, réglages rapides, règles, quitter. La partie est déjà sauvegardée. | Quitter ne doit rien perdre. | Demande de confirmation destructive. |
| **U12** | Fin de partie | Gagnant en grand, classement final, puis « Rejouer à l'identique », « Accueil », « Feuille de score ». Animation sobre. | Modèle de hareeg-table. | Confettis. |
| **U13** | Identité visuelle | Fond bleu nuit, cartes couleur parchemin, accent or ; les quatre couleurs du jeu pour les cartes. Jetons de style centralisés (espacements, rayons, tailles tactiles de 44 px minimum). | Ambiance pirate sans surcharge ; lisible. | Tapis vert de casino. |
| **U14** | Dessin des cartes | Un seul widget carte, dont toute la géométrie dérive de la largeur. Numérotée : valeur dans deux coins, emblème au centre, bandeau « atout » pour le noir. Spéciale : grand emblème et nom. Thème décrit par des données. | Remplaçable sans toucher au reste. | Un widget par type de carte. |
| **U15** | Emblèmes | Pictogrammes monochromes tirés d'une police libre embarquée (Noto Emoji, licence SIL OFL), dessinés dans la couleur de la carte : identiques sur tous les téléphones. Ils ont remplacé les émojis provisoires du début. | Aucun travail graphique, rendu maîtrisé, licence compatible avec une diffusion. | Émojis du système (rendu variable) ; illustrations sur mesure. |
| **U16** | États d'une carte | Normale, sélectionnée, injouable, gagnante, face cachée. | Le minimum utile. | — |
| **U17** | Accessibilité | Jamais la couleur seule : chaque couleur a son emblème. Libellé lu par les lecteurs d'écran sur chaque carte. Respect du réglage système « réduire les animations ». | Peu coûteux si prévu dès le départ. | — |
| **U18** | Son et vibrations | Vibrations légères en v1 (carte jouée, pli gagné). Pas de son. | Le son demande des ressources libres de droits. | — |
| **U19** | Écran allumé | Maintenu allumé pendant une partie (`wakelock_plus`, comme ton autre projet). | — | — |

## 8. Écrans et contenu

| # | Écran | Contenu |
|---|---|---|
| **E1** | Accueil | « Continuer » (si une partie est en cours, avec manche et score), « Nouvelle partie », « Jouer en ligne », « Compteur de points », puis Historique, Statistiques, Règles, Réglages. |
| **E2** | Nouvelle partie | Nombre d'adversaires, préréglage (M3), mode de score, détail de l'extension. Résumé avant de lancer. |
| **E3** | Table | Voir §7. |
| **E4** | Fin de partie | Voir U12. |
| **E5** | Historique | Une ligne par partie terminée : date, mode, nombre de joueurs, mon classement, mon score, gagnant. Suppression par appui long, avec confirmation. |
| **E6** | Détail d'une partie | Feuille de score complète et configuration. Rejeu pli par pli : plus tard (les données sont déjà là grâce à A7). |
| **E7** | Statistiques | Parties jouées, victoires, taux de victoire, classement moyen, score moyen, meilleur score, taux de paris réussis, taux de réussite des paris à 0. Une valeur sans données s'affiche « — », jamais « 0 % ». |
| **E8** | Règles | Résumé rédigé par nous à partir de `GAME_RULES.md` : cartes, hiérarchie, score, extension. Pas de copie du livret. |
| **E9** | Réglages | Vitesse des bots, jouer en un appui, vibrations, animations réduites, nom et couleur du joueur, licences. |
| **E10** | Profil | Un seul profil local : un nom et une couleur, dans les réglages. Pas d'écran dédié, pas de compte. |
| **E11** | Compteur | Joueurs enregistrés réutilisables, ordre des sièges, premier joueur, mêmes options de règles. Par manche : paris, plis, bonus par type, récapitulatif. Correction d'une manche passée. |

Une seule partie de jeu en cours à la fois ; en lancer une nouvelle demande confirmation.

## 9. Qualité et organisation

| # | Question | Décision | Pourquoi |
|---|---|---|---|
| **Q1** | Tests du moteur | Écrits avant le code. Un test par règle de `GAME_RULES.md`, y compris chaque exemple du livret et de la FAQ. | Les règles sont le produit. |
| **Q2** | Tests par parties aléatoires | Des milliers de parties jouées par le bot aléatoire, dans toutes les configurations, en vérifiant : la partie se termine, aucune question sans choix, nombre de cartes constant, plis gagnés + plis détruits = cartes distribuées, même graine = même partie. | Débusque les cas limites que personne n'imagine. |
| **Q3** | Tests du score | Le tableau de `REFERENCE_REPOS.md` §1.2, plus 8 joueurs aux manches 9 et 10, et Butin et Rascal en score Rascal. | Cas déjà vérifiés ailleurs, plus ceux que les autres ratent. |
| **Q4** | Tests d'interface | Un test par écran qui vérifie qu'il s'affiche et qu'une partie complète se déroule jusqu'au bout avec des bots instantanés. | Filet minimal sans figer la mise en page. |
| **Q5** | Vocabulaire | Un `CONTEXT.md` à la racine fixe les termes : en code `Game`, `Round`, `Trick`, `Bid`, `Seat`, `Suit`, `Escape`, `Mermaid`, `Tigress`, `Loot` ; à l'écran partie, manche, pli, pari, joueur, couleur, fuite, sirène, Tigresse, butin. | Même pratique que ton autre projet ; évite « tour », « levée », « mise » employés au hasard. |
| **Q6** | Décisions d'architecture | Une fois ce document validé, A1, A2, A4, A5 et A7 deviennent des fiches dans `docs/adr/`. | Ce document reste la vue d'ensemble ; les fiches gardent le raisonnement. |
| **Q7** | Dépôt git | À initialiser, local, sans dépôt distant pour l'instant. Les documents de référence en premier commit. | Rien n'est versionné aujourd'hui. Je ne le fais pas sans ton accord. |
| **Q8** | Code des références | Rien copié depuis les dépôts sans licence ou sous AGPL. Repris avec attribution seulement depuis du MIT ou du CC0, si utile. | Voir `REFERENCE_CARD_GAMES.md`. |

## 10. Ordre de construction

Chaque étape se termine par quelque chose qu'on peut lancer ou vérifier.

| Étape | Contenu | Résultat |
|---|---|---|
| 1 | Cartes, paquet, distribution, coups légaux, résolution d'un pli, calcul du score (jeu de base, score classique) | Tests de règles au vert |
| 2 | Moteur complet d'une partie + bot aléatoire + tests par parties aléatoires | Des milliers de parties se déroulent sans erreur |
| 3 | Table jouable : main, pari, pli, fin de manche, feuille de score, fin de partie | Une partie complète contre des bots aléatoires |
| 4 | Bot raisonnable | Une partie qui a de l'intérêt |
| 5 | Sauvegarde et reprise, accueil, nouvelle partie, profil | On peut fermer l'appli et reprendre |
| 6 | **Jeu en ligne** : identité, salon par code, partie menée par l'hôte, déconnexions | Une partie entre amis, chacun sur son téléphone |
| 7 | Historique, statistiques, réglages, règles | Appli complète pour le jeu de base |
| 8 | Extension, pouvoirs des pirates, score Rascal | Tous les modes du livret, en solo et en ligne |
| 9 | Compteur de points | Second usage de l'appli |
| 10 | Variante à 2 joueurs, pictogrammes définitifs, niveaux de bots | Finitions |
| Plus tard | Rejeu pli par pli, son, transfert d'hôte, réactions | — |

## 11. Ce qui reste ouvert

Points que je ne peux pas trancher à ta place :

1. **Diffusion** (P6) : le jeu en ligne rend la question concrète, puisque tes amis devront installer l'appli. Entre amis, un fichier d'installation Android envoyé directement suffit. Pour un store, il faudra un autre nom et nos propres visuels avant.
4. ~~**iPhone**~~ : tranché le 2026-10-05 — Android uniquement pour le moment.
5. ~~**Compte Supabase**~~ : tranché le 2026-10-05 — un projet Supabase dédié à ce jeu, à créer avant l'étape 6.
2. ~~**Plusieurs humains sur un téléphone** (P3)~~ : tranché le 2026-10-05 — non, abandonné.
3. ~~**Compteur** (P2)~~ : tranché le 2026-10-05 — jeu et compteur dans la même appli, le compteur plus tard (étape 8).
