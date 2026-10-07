# skull_kings

Application Flutter pour le jeu de cartes Skull King : le **jeu complet** (distribution, mains, plis, résolution, bots à trois niveaux, extension, variante à 2 joueurs) en solo, plus un compteur de points pour jouer avec le vrai paquet. Le jeu en ligne entre amis passe par Supabase Realtime (`lib/online/`) : le téléphone de l'hôte fait tourner la partie et envoie à chaque invité le flux de son siège. `dart run tool/online_smoke.dart` joue une vraie partie à travers le projet Supabase pour le vérifier.

Les règles complètes du jeu (cartes, hiérarchie, scores, restrictions, modes avancés, score Rascal, FAQ officielle) sont dans `GAME_RULES.md`. C'est la référence pour toute logique de jeu : la lire avant d'implémenter ou de modifier une règle, et ne pas inventer de règle absente de ce fichier. Les points que le livret ne tranche pas (section 12) ont reçu une décision validée : l'appliquer telle quelle. La deuxième extension (section 14, option `secondExpansion`) a ses propres points tranchés en section 14.7, validés le 2026-10-07.

`docs/REFERENCE_REPOS.md` analyse deux compteurs de points open source (modèle de données, calcul des points, déroulé, cas de test, erreurs à éviter). À lire avant de concevoir les modèles, le calcul des scores ou le mode extension. Ne pas copier leur code (licence CC BY-SA 4.0 pour l'un, aucune licence pour l'autre).

`docs/REFERENCE_RTAROT.md` analyse un moteur de tarot en Rust et sert de base d'architecture pour le moteur de jeu : contrat Question / Réponse / Événement, machine à états, aléatoire à graine, tests par parties aléatoires, et les adaptations propres à Skull King. À lire avant de concevoir le moteur ou l'enchaînement des écrans. Pas de licence : ne pas copier le code.

`docs/REFERENCE_CARD_GAMES.md` recense 13 jeux de cartes open source (dont un jeu Flutter complet hors ligne et plusieurs Skull King en ligne) et ce qu'ils contiennent : accueil, configuration, table, pause, fin de manche et de partie, historique, statistiques, profil, réglages, rendu des cartes, persistance. Sa section 5 propose l'enchaînement d'écrans de `skull_kings`, relié aux règles ; c'est une proposition à valider. À lire avant de concevoir un écran ou le composant carte.

`docs/DECISIONS.md` liste toutes les décisions de conception (périmètre, règles tranchées, architecture, jeu en ligne, bots, interface, écrans, tests, ordre de construction), chacune avec un identifiant. Statut : **validées par l'utilisateur le 2026-10-05**. Sa section 10 donne l'ordre de construction.

Vocabulaire du domaine (termes du code en anglais, de l'interface en français) : `CONTEXT.md`. Le moteur de règles est dans `lib/engine/`, en Dart pur : aucun import Flutter n'y est permis (un test le vérifie).

Stockage : drift (SQLite), schéma dans `lib/storage/app_database.dart`. Après toute modification du schéma, régénérer avec `dart run build_runner build` et incrémenter `schemaVersion` avec une migration.

@GAME_RULES.md
