import '../engine/engine.dart';

/// Every text the player reads. Kept in one place so it can be translated.
abstract final class Strings {
  static const appTitle = 'Skull Kings';
  static const homeEmblem = '☠️';
  static const tagline = 'Parie tes plis, tiens ta parole.';
  static const newGame = 'Nouvelle partie';
  static const opponents = 'Adversaires';
  static const you = 'Toi';

  /// Names of the bots, in seat order.
  static const botNames = [
    'Mako',
    'Corail',
    'Bosco',
    'Sloop',
    'Récif',
    'Ancre',
    'Rafale',
  ];

  static String roundTitle(int round, int cards) =>
      'Manche $round · $cards carte${cards > 1 ? 's' : ''}';
  static String tieBreakTitle(int cards) =>
      'Départage · $cards carte${cards > 1 ? 's' : ''}';

  static const chooseBid = 'Combien de plis vas-tu prendre ?';
  static String placeBid(int bid) => 'Parier $bid';
  static const pickBidFirst = 'Choisis un nombre';
  static const bidsHidden = 'Les autres ont déjà parié en secret.';
  static const yourLead = 'À toi — joue la carte de ton choix';
  static const playAnything =
      'À toi — pas de couleur à suivre : joue ce que tu veux';
  static String followSuit(Suit suit) => 'À toi — fournis du ${suitName(suit)}';
  static String noSuitHeld(Suit suit) =>
      'À toi — pas de ${suitName(suit)} : joue ce que tu veux';
  static const tapAgain = 'Touche encore la carte pour la jouer';
  static String thinking(String name) => '$name réfléchit…';
  static String trickFor(String name) => 'Pli pour $name';
  static const trickForYou = 'Pli pour toi';
  static String trickBonus(List<Bonus> bonuses) {
    final points = bonuses.fold(0, (sum, bonus) => sum + bonus.points);
    return '+$points (${bonuses.map(bonusName).join(', ')}) '
        'si le pari est réussi';
  }

  static const tigressTitle = 'Jouer la Tigresse comme…';
  static const asPirate = 'Pirate';
  static const asEscape = 'Fuite';
  static String playedAs(TigressMode mode) => switch (mode) {
    TigressMode.pirate => 'pirate',
    TigressMode.escape => 'fuite',
  };

  static String bidAndTricks(int? bid, int tricks) =>
      'pari ${bid ?? '?'} · plis $tricks';
  static const dealer = 'Donneur';
  static const dealerMark = 'D';
  static String points(int score) => '$score pts';
  static String cardsLeft(int cards) => '$cards c.';

  static const lastTrick = 'Dernier pli';
  static const noLastTrick = 'Aucun pli joué dans cette manche.';
  static const scoreSheet = 'Feuille de score';
  static const close = 'Fermer';
  static const quit = 'Quitter';
  static const pause = 'Pause';
  static const gameIsSaved =
      'La partie est sauvegardée. Tu pourras la reprendre depuis l\'accueil.';
  static const resume = 'Reprendre';

  static String savedGameSummary(int round, int score) =>
      'Manche $round · ${points(score)}';
  static const replaceGameTitle = 'Remplacer la partie en cours ?';
  static const replaceGameBody =
      'Une partie est déjà commencée. En lancer une nouvelle l\'efface.';
  static const replaceGame = 'Remplacer';
  static const keepGame = 'Garder';

  static const setupTitle = 'Nouvelle partie';
  static const launch = 'Lancer la partie';
  static String setupSummary(GameConfig config) =>
      '${config.players} joueurs · ${modeName(config)} · '
      '$standardRounds manches';
  static String fewerCardsNote(int players, int cards) =>
      'À $players joueurs, les dernières manches se jouent avec $cards cartes.';
  static const saveFailed = 'La sauvegarde a échoué.';
  static const cannotStart = 'Impossible de lancer la partie.';

  static const history = 'Historique';
  static const historyEmpty = 'Aucune partie terminée pour l\'instant.';
  static String historyResult(int rank, int score) =>
      '${ordinal(rank)} · ${points(score)}';
  static String playersCount(int players) => '$players joueurs';
  static String wonBy(String name) => 'Gagnée par $name';
  static const wonByYou = 'Gagnée par toi';

  /// The first line under a game in the history. A null [winner] is the human.
  static String historyDetails({required DateTime date, String? winner}) =>
      '${dateTime(date)} · ${winner == null ? wonByYou : wonBy(winner)}';
  static String gameSetup(int players, GameConfig? config) =>
      [playersCount(players), if (config != null) modeName(config)].join(' · ');
  static const delete = 'Supprimer';
  static const deleteGameTitle = 'Supprimer cette partie ?';
  static const deleteGameBody =
      'Elle disparaîtra de l\'historique et des statistiques.';
  static const gameDetailTitle = 'Détail de la partie';
  static const detailUnavailable =
      'Le détail de cette partie n\'est plus disponible.';

  static String ordinal(int rank) => rank == 1 ? '1er' : '${rank}e';

  /// A day and a time, as in « 06/10/2026 à 21:30 ».
  static String dateTime(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year} '
        'à ${two(date.hour)}:${two(date.minute)}';
  }

  static const loadFailed = 'Impossible de lire les parties enregistrées.';

  static const statistics = 'Statistiques';
  static const statGamesPlayed = 'Parties jouées';
  static const statWins = 'Victoires';
  static const statWinRate = 'Taux de victoire';
  static const statAverageRank = 'Classement moyen';
  static const statAverageScore = 'Score moyen';
  static const statBestScore = 'Meilleur score';
  static const statBidSuccess = 'Paris réussis';
  static const statZeroBidSuccess = 'Paris à 0 réussis';
  static String statMeasuredOn(int games) =>
      'Paris mesurés sur $games partie${games > 1 ? 's' : ''}.';

  /// Shown instead of a figure that has nothing to measure.
  static const unavailable = '—';
  static String percent(double ratio) => '${(ratio * 100).round()} %';
  static String decimal(double value) =>
      value.toStringAsFixed(1).replaceFirst('.', ',');

  static const settings = 'Réglages';
  static const botSpeedLabel = 'Vitesse des adversaires';
  static const speedNormal = 'Normale';
  static const speedFast = 'Rapide';
  static const speedInstant = 'Instantanée';
  static const singleTapPlay = 'Jouer en un seul appui';
  static const singleTapPlayHelp =
      'Sinon, un premier appui soulève la carte et un second la joue.';
  static const hapticsLabel = 'Vibrations';
  static const reduceMotionLabel = 'Réduire les animations';
  static const licenses = 'Licences';

  static const rules = 'Règles';
  static const rulesTitle = 'Règles du jeu';

  static const presetLabel = 'Mode de jeu';
  static const presetClassic = 'Classique';
  static const presetFull = 'Extension';
  static const presetCustom = 'Personnalisé';
  static const scoringLabel = 'Calcul des points';
  static const scoringClassic = 'Classique';
  static const scoringRascal = 'Rascal';
  static const scoringRascalHelp =
      'Même potentiel pour tous : tout si le pari est exact, la moitié à un '
      'pli près, rien au-delà. Pas de points négatifs, sauf une mise de '
      'Rascal le Flambeur perdue.';
  static const optionKraken = 'Kraken';
  static const optionKrakenHelp = 'Détruit le pli : personne ne le remporte.';
  static const optionWhale = 'Baleine blanche';
  static const optionWhaleHelp =
      'Détruit les cartes spéciales : la plus haute valeur gagne.';
  static const optionLoot = 'Butin (2 cartes)';
  static const optionLootHelp =
      'Alliance avec le gagnant du pli : +$allianceBonus chacun si les deux '
      'paris sont réussis.';
  static const optionPowers = 'Pouvoirs des pirates';
  static const optionPowersHelp =
      'Gagner un pli avec un pirate déclenche son pouvoir.';

  /// What a game is played with, as one line.
  static String modeName(GameConfig config) => [
    config.usesFullExpansion
        ? 'Extension complète'
        : config.usesExpansion
        ? 'Extension partielle'
        : 'Jeu de base',
    config.scoring == Scoring.rascal ? 'score Rascal' : 'score classique',
  ].join(' · ');

  static String pirateName(Pirate pirate) => switch (pirate) {
    Pirate.rosie => 'Rosie la Douce',
    Pirate.will => 'Will le Bandit',
    Pirate.rascal => 'Rascal le Flambeur',
    Pirate.juanita => 'Juanita Jade',
    Pirate.harry => 'Harry le Géant',
  };

  /// The short name written on a pirate card.
  static String pirateShortName(Pirate pirate) => switch (pirate) {
    Pirate.rosie => 'Rosie',
    Pirate.will => 'Will',
    Pirate.rascal => 'Rascal',
    Pirate.juanita => 'Juanita',
    Pirate.harry => 'Harry',
  };

  static String usesPower(String name, Pirate pirate) =>
      '$name utilise ${pirateName(pirate)}';
  static String leaderChosen(String leader) =>
      '${pirateName(Pirate.rosie)} : $leader entame le prochain pli';
  static String cardsDiscarded(String name, int count) =>
      '${pirateName(Pirate.will)} : $name pioche et défausse '
      '$count carte${count > 1 ? 's' : ''}';
  static String wagerPlaced(String name, int amount) =>
      '${pirateName(Pirate.rascal)} : $name mise $amount';
  static String bidChanged(String name, int bid) =>
      '${pirateName(Pirate.harry)} : $name parie maintenant $bid';

  static const chooseLeaderBody = 'Qui entame le prochain pli ?';
  static String discardBody(int count) =>
      'Tu as pioché. Choisis $count carte${count > 1 ? 's' : ''} à défausser.';
  static const discardConfirm = 'Défausser';
  static const wagerBody =
      'Mise sur ton pari : gagnée s\'il est réussi, perdue sinon.';
  static String wagerOption(int amount) =>
      amount == 0 ? 'Ne rien miser' : 'Miser $amount';
  static const adjustBidBody = 'Tu peux modifier ton pari d\'un pli.';
  static String adjustBidOption(int change, int bid) => switch (change) {
    0 => 'Garder $bid',
    > 0 => 'Monter à $bid',
    _ => 'Descendre à $bid',
  };
  static const stockBody = 'Ces cartes ne sont pas en jeu dans cette manche.';

  static String trickDestroyed(String leader) => 'Pli détruit — $leader entame';
  static const trickDestroyedYouLead = 'Pli détruit — tu entames';
  static String alliance(String first, String second) =>
      'Alliance : $first et $second, +$allianceBonus chacun si les deux '
      'paris sont réussis';
  static String allianceLine(int points) => 'alliance ${signed(points)}';
  static String wagerLine(int points) => 'mise ${signed(points)}';

  static const counter = 'Compteur de points';
  static const counterIntro =
      'Vous jouez avec le vrai paquet : l\'appli tient la feuille de score.';
  static const counterNew = 'Nouvelle partie à compter';
  static const counterResume = 'Reprendre';
  static String counterResumeSummary(int round, int players) =>
      'Manche $round · ${playersCount(players)}';
  static const counterFinished = 'Parties comptées';
  static const counterPlayers = 'Joueurs';
  static String counterPlayerHint(int number) => 'Joueur $number';
  static const counterAddPlayer = 'Ajouter un joueur';
  static const counterRemovePlayer = 'Retirer';
  static const counterFirstLeader = 'Premier à entamer';
  static const counterStart = 'Commencer';
  static const counterNeedNames = 'Donne un nom à chaque joueur.';
  static String counterRoundTitle(int round, int cards) =>
      roundTitle(round, cards);
  static String counterLeads(String name) => '$name entame';
  static String counterEnterRound(int round) => 'Saisir la manche $round';
  static String counterEnterResults(int round) =>
      'Saisir les résultats de la manche $round';
  static const counterBidsPhase = 'Les paris';
  static const counterResultsPhase = 'Les résultats';
  static const counterBidsDone = 'Valider les paris';
  static const counterRoundDone = 'Valider la manche';
  static const counterBid = 'Pari';
  static const counterTricks = 'Plis';
  static const counterBonus = 'Bonus';
  static String counterBonusFor(String name) => 'Bonus de $name';
  static String counterTricksMismatch(int claimed, int cards) =>
      '$claimed pli${claimed > 1 ? 's' : ''} saisi${claimed > 1 ? 's' : ''} '
      'pour $cards carte${cards > 1 ? 's' : ''} : vérifie, sauf si un pli a '
      'été détruit.';
  static const counterAlliances = 'Alliances (Butin)';
  static const counterAddAlliance = 'Ajouter une alliance';
  static String counterAlliance(String first, String second) =>
      '$first et $second';
  static const counterAllianceTitle = 'Qui s\'allie ?';
  static const counterWager = 'Mise de Rascal';
  static const counterBidChange = 'Harry le Géant';
  static const counterCorrectHint =
      'Touche le numéro d\'une manche pour la corriger.';
  static const counterFinish = 'Terminer la partie';
  static const counterTieBreak =
      'Égalité en tête : jouez une manche de départage.';
  static const ok = 'OK';

  static String bonusLabel(Bonus bonus) => switch (bonus) {
    Bonus.standardFourteen => '14 vert, jaune ou violet (+10)',
    Bonus.blackFourteen => '14 noir (+20)',
    Bonus.mermaidCaptured => 'Sirène capturée par un pirate (+20)',
    Bonus.pirateCaptured => 'Pirate capturé par le Skull King (+30)',
    Bonus.skullKingCaptured => 'Skull King capturé par une sirène (+40)',
  };

  static const profileTitle = 'Ton profil';
  static const playerNameLabel = 'Nom';
  static const playerColorLabel = 'Couleur';
  static const save = 'Enregistrer';
  static const cancel = 'Annuler';

  static String roundOver(int round) => 'Fin de la manche $round';
  static const continueGame = 'Continuer';
  static const colPlayer = 'Joueur';
  static const colBid = 'Pari';
  static const colTricks = 'Plis';
  static const colBidTricks = 'Pari/Plis';
  static const colBidPoints = 'Points';
  static const colBonus = 'Bonus';
  static const colRound = 'Manche';
  static const colTotal = 'Total';
  static const bonusLost = 'perdu';
  static const noBonus = '—';
  static String detailsOf(String name, List<String> details) =>
      '$name : ${details.join(', ')}';

  static const gameOver = 'Partie terminée';
  static const winnerMark = '🏆';
  static const youWin = 'Tu gagnes !';
  static String wins(String name) => '$name gagne';
  static const playAgain = 'Rejouer';
  static const home = 'Accueil';

  static String suitName(Suit suit) => switch (suit) {
    Suit.green => 'vert',
    Suit.yellow => 'jaune',
    Suit.purple => 'violet',
    Suit.black => 'noir',
  };

  static const trump = 'ATOUT';

  /// The name of [card]. With [namedPirates], a pirate goes by its own name.
  static String cardName(Card card, {bool namedPirates = false}) =>
      switch (Pirate.of(card)) {
        final pirate? when namedPirates => pirateShortName(pirate),
        _ => _kindName(card),
      };

  static String _kindName(Card card) => switch (card.kind) {
    CardKind.number => '${card.value} ${suitName(card.suit!)}',
    CardKind.escape => 'Fuite',
    CardKind.pirate => 'Pirate',
    CardKind.tigress => 'Tigresse',
    CardKind.skullKing => 'Skull King',
    CardKind.mermaid => 'Sirène',
    CardKind.loot => 'Butin',
    CardKind.kraken => 'Kraken',
    CardKind.whiteWhale => 'Baleine blanche',
  };

  static String bonusName(Bonus bonus) => switch (bonus) {
    Bonus.standardFourteen => '14',
    Bonus.blackFourteen => '14 noir',
    Bonus.mermaidCaptured => 'sirène capturée',
    Bonus.pirateCaptured => 'pirate capturé',
    Bonus.skullKingCaptured => 'Skull King capturé',
  };

  static String signed(int points) => points > 0 ? '+$points' : '$points';

  /// Like [signed], for a figure that may well be zero.
  static String signedOrZero(int points) => points == 0 ? '0' : signed(points);
}
