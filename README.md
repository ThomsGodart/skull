# Skull Kings

Une application Flutter pour jouer à **Skull King**, le jeu de plis à paris : contre des bots, entre amis en ligne, ou avec le vrai paquet en laissant l'appli compter les points.

**Version web : https://thomsgodart.github.io/skull/**

> Projet personnel, non officiel. Skull King est un jeu de Grandpa Beck's Games, édité en français par Blackrock Games ; ce projet n'est affilié ni à l'un ni à l'autre. Il ne contient aucune illustration du jeu : les cartes sont dessinées avec des pictogrammes libres.

## Sommaire

- [Ce que fait l'appli](#ce-que-fait-lappli)
- [Démarrer](#démarrer)
- [Commandes utiles](#commandes-utiles)
- [Organisation du code](#organisation-du-code)
- [Comment ça marche](#comment-ça-marche)
- [Jeu en ligne et sauvegarde](#jeu-en-ligne-et-sauvegarde)
- [Version web](#version-web)
- [Tests](#tests)
- [Documentation du projet](#documentation-du-projet)
- [Limites connues](#limites-connues)
- [Licence](#licence)

## Ce que fait l'appli

### Jouer

- **Le jeu complet** : distribution, paris simultanés, plis, résolution, scores, manches de départage en cas d'égalité.
- **2 à 8 joueurs.** À deux, le fantôme de Barbe Grise joue le troisième paquet.
- **Bots à trois niveaux** : Facile, Normal, Difficile. Ils ne voient que leur propre main. Le niveau Difficile simule la manche avant chaque décision.
- **Deux façons de compter** : le score classique du livret et le score Rascal.
- **Modes avancés, au choix** : Kraken, Baleine blanche, Butin, pouvoirs des pirates.
- **Deuxième extension, au choix** (à partir de 3 joueurs) : 7, 8 et 0/14 en double, Joker 15, Mary Thorne, Mat le Forban, Marcher sur la planche, Raie Tachetée, Dernière Salve, Coffre de Davy Jones. Les cinq dernières se retirent une à une.
- **Partie sauvegardée en continu** : on la reprend depuis l'accueil.

### Jouer en ligne

- Parties privées entre amis : l'hôte crée un salon et donne un code de quatre lettres.
- Tous ceux qui rejoignent jouent, jusqu'à 8. Au lancement, l'hôte choisit combien de bots ajouter.
- Si un joueur se déconnecte, tout le monde le voit, avec le décompte avant qu'un bot prenne sa place. L'hôte peut choisir de l'attendre, ou de mettre le bot tout de suite.

### Compter les points

Pour jouer avec le vrai paquet : on saisit les paris, puis les plis et les bonus, et l'appli tient la feuille de score.

- Bonus détaillés carte par carte, ou total saisi à la main.
- Butin, mise de Rascal le Flambeur, deuxième extension.
- Nombre de cartes modifiable pour une manche, correction d'une manche passée.

### Autour du jeu

- Historique des parties, avec le détail de chacune, et statistiques.
- Règles consultables dans l'appli, avec les cartes dessinées à côté du texte.
- Réglages : vitesse des bots, jouer en un appui, vibrations, animations réduites, jetons de plis, Harry le Géant automatique, profil (nom et couleur).

## Démarrer

Il faut [Flutter](https://docs.flutter.dev/get-started/install) (canal stable, version 3.47 ou plus récente ; Dart 3.13).

```sh
git clone https://github.com/ThomsGodart/skull.git
cd skull
flutter pub get
flutter run
```

`flutter run` propose les appareils disponibles : téléphone Android branché, bureau Linux, Chrome.

L'appli fonctionne sans réseau pour le jeu en solo, le compteur, l'historique et les statistiques. Seuls le jeu en ligne et la sauvegarde en ligne ont besoin d'Internet.

## Commandes utiles

| Pour | Commande |
|---|---|
| Lancer les tests | `flutter test` |
| Vérifier le code | `flutter analyze` |
| Mettre en forme | `dart format lib test tool` |
| APK Android | `flutter build apk --release` |
| Site web | `flutter build web --release` |
| Régénérer le code de la base après un changement de schéma | `dart run build_runner build` |
| Redessiner l'icône sur toutes les plateformes | `python3 tool/app_icon.py` (demande Pillow) |
| Jouer une vraie partie à travers Supabase | `dart run tool/online_smoke.dart` |
| Mesurer les bots sur des centaines de parties | `dart run tool/bot_lab.dart duel 400 4` (voir l'en-tête du fichier) |

L'APK est écrit dans `build/app/outputs/flutter-apk/app-release.apk`.

## Organisation du code

```
lib/
  engine/     Les règles, en Dart pur : cartes, paquet, plis, scores, partie
  bots/       Les trois niveaux de bots
  game/       La table : contrôleur, écran, sièges, pli, dialogues
  setup/      Création d'une partie
  online/     Salons, hôte, invités, transport Supabase Realtime
  counter/    Le compteur de points
  history/    Historique et détail d'une partie
  stats/      Statistiques
  rules/      L'écran des règles
  settings/   Réglages et profil
  storage/    Base locale (drift / SQLite)
  cloud/      Copie des données dans Supabase
  home/       Accueil
  theme/      Couleurs, espacements, thème
  ui/         Textes de l'interface, rendu des cartes, pictogrammes
test/         Les tests, rangés comme lib/
tool/         Scripts : icône, essai du jeu en ligne
supabase/     Schéma de la base distante
web/          Page d'accueil du site et fichiers SQLite pour le navigateur
docs/         Décisions de conception et analyses de référence
```

Le code est en anglais, l'interface en français. Tous les textes affichés sont dans `lib/ui/strings.dart` et `lib/ui/rules_content.dart`.

## Comment ça marche

### Le moteur

`lib/engine/` ne dépend pas de Flutter (un test le vérifie). Une partie est un objet `Game` qui ne bloque jamais :

1. il expose les **questions** en attente (`pending`) : parier, jouer une carte, utiliser un pouvoir ;
2. on lui donne une **réponse** (`answer`) ;
3. il produit des **événements** (`takeEvents`) : carte jouée, pli remporté, manche comptée…

Un bot et un humain sont pilotés de la même façon. Tout l'aléatoire vient d'une graine : la même graine et les mêmes réponses redonnent exactement la même partie. Sauvegarder une partie, c'est donc garder sa configuration et la liste de ses réponses.

### La table

`GameController` rejoue les événements un par un, au rythme choisi, pour que l'écran montre chaque carte et chaque pli. Il lit un `SeatFeed` : le flux d'un siège, que la partie tourne sur ce téléphone ou sur celui de l'hôte. La table ne fait pas la différence.

### Le stockage

Les parties, les parties comptées et les réglages sont dans une base SQLite locale, par [drift](https://drift.simonbinder.eu/). Le schéma est dans `lib/storage/app_database.dart` ; après l'avoir modifié, il faut régénérer le code et ajouter une migration avec un nouveau `schemaVersion`.

## Jeu en ligne et sauvegarde

Les deux passent par un projet [Supabase](https://supabase.com/), dont l'adresse et la clé publique sont dans `lib/online/online_backend.dart`. Cette clé est faite pour être distribuée avec l'appli.

### Jeu en ligne

Il n'y a pas de serveur de jeu. Le téléphone de l'hôte fait tourner le moteur et envoie à chaque invité, par les canaux temps réel de Supabase, ce que son siège a le droit de voir. Les invités renvoient leurs réponses.

Conséquence assumée : l'hôte pourrait voir toutes les mains en modifiant l'appli. C'est acceptable entre amis, pas pour du jeu public.

Les téléphones d'une même partie doivent avoir la même version du protocole (`onlineProtocol` dans `lib/online/online_game.dart`) ; sinon l'entrée dans le salon est refusée.

### Sauvegarde en ligne

Chaque changement de réglage, de partie ou de partie comptée est recopié dans une table `user_data`, sous un compte anonyme créé tout seul. Chaque compte ne voit que ses propres lignes.

C'est une copie, pas une synchronisation : l'appli ne lit que la base du téléphone, et une erreur réseau est ignorée. Le compte anonyme n'est rattaché à rien, donc la copie ne se retrouve pas sur un autre téléphone ni après une réinstallation.

### Utiliser son propre projet Supabase

1. Créer un projet, puis remplacer l'adresse et la clé dans `lib/online/online_backend.dart`.
2. Appliquer le schéma : `supabase link --project-ref <ref>` puis `supabase db push` (le SQL est dans `supabase/migrations/`).
3. Dans le tableau de bord, activer la connexion anonyme (Authentication → Sign In / Providers).

Le jeu en ligne n'a besoin d'aucune table ; les étapes 2 et 3 ne servent qu'à la sauvegarde.

## Version web

Le site est publié sur GitHub Pages par `.github/workflows/pages.yml` : à chaque poussée sur `main`, le workflow lance les tests, compile le site et le déploie.

Dans un navigateur, SQLite tourne en WebAssembly. Deux fichiers de `web/` en dépendent :

| Fichier | Vient de | Version à suivre |
|---|---|---|
| `sqlite3.wasm` | publications GitHub de `simolus3/sqlite3.dart`, étiquette `sqlite3-<version>` | celle de `sqlite3` dans `pubspec.lock` |
| `drift_worker.js` | publications GitHub de `simolus3/drift`, étiquette `drift-<version>` | celle de `drift` dans `pubspec.lock` |

Après une montée de version de l'un de ces paquets, il faut retélécharger le fichier correspondant.

Les données du site sont gardées par le navigateur, séparément de celles de l'appli Android.

## Tests

`flutter test` lance toute la suite. Elle couvre :

- **les règles** : chaque cas de résolution d'un pli, les scores, et des centaines de parties entières jouées au hasard, à toutes les tailles de table et avec toutes les options ;
- **la reprise** : une partie sauvegardée à mi-chemin reprend au même point ;
- **les bots** : chaque niveau ne donne que des réponses légales, et le niveau Difficile gagne plus souvent ;
- **le jeu en ligne** : hôte et invités sur un réseau simulé, avec messages perdus, départs et retours ;
- **les écrans** : parties entières jouées à travers l'interface, en portrait et en paysage, sans erreur de mise en page ;
- **le stockage** : la base locale et la copie en ligne, sur une table simulée.

## Documentation du projet

| Fichier | Contenu |
|---|---|
| `GAME_RULES.md` | Les règles complètes, et la décision retenue pour chaque point que les livrets ne tranchent pas. C'est la référence pour toute logique de jeu. |
| `docs/DECISIONS.md` | Toutes les décisions de conception, numérotées, avec leur raison. |
| `CONTEXT.md` | Le vocabulaire du domaine : termes du code et de l'interface. |
| `CLAUDE.md` | Les consignes données à l'assistant de code qui travaille sur le projet. |
| `docs/REFERENCE_*.md` | Analyses d'autres projets (compteurs de points, moteur de tarot, jeux de cartes) qui ont servi de base de réflexion. |

## Limites connues

- **Vérifications sur appareil** : les fonctions récentes (deuxième extension, compteur manuel, salon ouvert, version web) sont couvertes par les tests automatiques, mais peu éprouvées en conditions réelles.
- **Sauvegarde en ligne** : sans moyen de connexion rattaché au compte, la copie ne peut pas être restaurée ailleurs.
- **Bots** : le niveau Difficile ne tient pas compte, dans ses simulations, des pouvoirs des pirates, de la Planche ni de la Dernière Salve. Il reste nettement plus fort que le niveau Normal avec ces options, mais ne les exploite pas.
- **9 joueurs** : le livret de la deuxième extension le permet ; l'appli s'arrête à 8.
- **iOS, macOS, Windows** : les projets existent, mais rien n'y a été compilé ni testé.

## Licence

Aucune licence n'est attachée à ce dépôt pour l'instant : le code est consultable, mais sa réutilisation n'est pas autorisée par défaut.

La police Noto Emoji, utilisée pour les pictogrammes, est sous licence SIL Open Font License ; son texte est dans `assets/fonts/NotoEmoji-OFL.txt`.
