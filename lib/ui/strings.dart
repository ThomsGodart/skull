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
  static String setupSummary(int players) =>
      '$players joueurs · jeu de base · score classique · '
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
  static const baseGameClassic = 'Jeu de base · score classique';
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
  static String bonusesOf(String name, List<Bonus> bonuses) =>
      '$name : ${bonuses.map(bonusName).join(', ')}';

  static const gameOver = 'Partie terminée';
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

  static String cardName(Card card) => switch (card.kind) {
    CardKind.number => '${card.value} ${suitName(card.suit!)}',
    CardKind.escape => 'Fuite',
    CardKind.pirate => 'Pirate',
    CardKind.tigress => 'Tigresse',
    CardKind.skullKing => 'Skull King',
    CardKind.mermaid => 'Sirène',
  };

  static String bonusName(Bonus bonus) => switch (bonus) {
    Bonus.standardFourteen => '14',
    Bonus.blackFourteen => '14 noir',
    Bonus.mermaidCaptured => 'sirène capturée',
    Bonus.pirateCaptured => 'pirate capturé',
    Bonus.skullKingCaptured => 'Skull King capturé',
  };

  static String signed(int points) => points > 0 ? '+$points' : '$points';
}
