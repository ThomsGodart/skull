import '../engine/engine.dart';

/// Every text the player reads. Kept in one place so it can be translated.
abstract final class Strings {
  static const appTitle = 'Skull Kings';
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
  static const quitTitle = 'Quitter la partie ?';
  static const quitBody = 'La partie en cours sera perdue.';
  static const stay = 'Rester';

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
