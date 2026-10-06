import 'card.dart';

/// How a tigress is played. Chosen by its player when the card is put down.
enum TigressMode { pirate, escape }

/// A card put down in a trick by a seat.
final class Play {
  const Play({required this.seat, required this.card, this.tigressAs});

  final int seat;
  final Card card;

  /// Set if and only if [card] is the tigress.
  final TigressMode? tigressAs;

  /// Pirate, tigress played as a pirate, skull king or mermaid.
  bool get isCharacter => isPirate || isSkullKing || isMermaid;

  bool get isPirate =>
      card.kind == CardKind.pirate || tigressAs == TigressMode.pirate;
  bool get isSkullKing => card.kind == CardKind.skullKing;
  bool get isMermaid => card.kind == CardKind.mermaid;

  /// The kraken or the white whale.
  bool get isCreature =>
      card.kind == CardKind.kraken || card.kind == CardKind.whiteWhale;
  bool get isLoot => card.kind == CardKind.loot;
}

/// The seats in the order they play a trick led by [leader].
///
/// Clockwise from the leader — except with a [ghost], who always plays second;
/// when it leads itself, [roundStarter] (the player who led the round's first
/// trick) follows it.
List<int> playOrder({
  required int leader,
  required int seats,
  int? ghost,
  int roundStarter = 0,
}) {
  if (ghost == null) {
    return [for (var i = 0; i < seats; i++) (leader + i) % seats];
  }
  if (leader == ghost) return [ghost, roundStarter, 1 - roundStarter];
  return [leader, ghost, 1 - leader];
}

/// The suit that must be followed in [trick], if any.
///
/// The first number card sets it, unless a character was played before: then
/// nobody has to follow anything for the whole trick. A kraken or a white
/// whale lifts it for everyone who plays after.
Suit? leadSuit(List<Play> trick) {
  if (trick.any((play) => play.isCreature)) return null;
  for (final play in trick) {
    if (play.card.isNumber) return play.card.suit;
    if (play.isCharacter) return null;
  }
  return null;
}

/// The cards of [hand] that may be played next in [trick].
///
/// A special card is always legal. Number cards must follow the lead suit when
/// the hand holds it.
List<Card> legalCards(List<Card> hand, List<Play> trick) {
  final suit = leadSuit(trick);
  if (suit == null || !hand.any((card) => card.suit == suit)) {
    return List.of(hand);
  }
  return [
    for (final card in hand)
      if (!card.isNumber || card.suit == suit) card,
  ];
}

/// Points attached to a won trick. They only count when the bid is made.
enum Bonus {
  standardFourteen(10),
  blackFourteen(20),
  mermaidCaptured(20),
  pirateCaptured(30),
  skullKingCaptured(40);

  const Bonus(this.points);

  final int points;
}

/// The pact a loot card makes between its player and whoever wins the trick:
/// each earns a bonus if both make their bid.
final class Alliance {
  const Alliance({required this.lootSeat, required this.winnerSeat});

  final int lootSeat;
  final int winnerSeat;
}

/// Points each ally earns when both make their bid.
const allianceBonus = 20;

/// The outcome of a complete trick.
final class TrickResult {
  const TrickResult({
    required this.winner,
    this.bonuses = const [],
    this.alliances = const [],
    this.destroyed = false,
  });

  /// The seat that leads the next trick. It also wins this one, unless the
  /// trick is [destroyed].
  final int winner;

  /// One entry per bonus earned, so the same bonus may appear several times.
  final List<Bonus> bonuses;
  final List<Alliance> alliances;

  /// Nobody wins the trick: its cards and bonuses are lost.
  final bool destroyed;
}

/// Who wins [trick], and the bonuses it carries.
///
/// Meant for a complete trick; on a trick still being played it gives the seat
/// that is winning so far. [trick] must hold at least one card.
TrickResult resolveTrick(List<Play> trick) {
  if (trick.isEmpty) throw ArgumentError.value(trick, 'trick', 'is empty');
  // Of a kraken and a white whale, only the last one played takes effect.
  final creature = trick.where((play) => play.isCreature).lastOrNull;
  if (creature == null) return _resolvePlain(trick);

  final others = [
    for (final play in trick)
      if (!play.isCreature) play,
  ];
  // Whoever would have won had no creature been played.
  final wouldHaveWon = others.isEmpty
      ? trick.first.seat
      : _winningPlay(others).seat;
  if (creature.card.kind == CardKind.kraken) {
    return TrickResult(winner: wouldHaveWon, destroyed: true);
  }

  // White whale: special cards are destroyed, number cards lose their suit.
  final numbers = others.where((play) => play.card.isNumber).toList();
  if (numbers.isEmpty) {
    return TrickResult(winner: wouldHaveWon, destroyed: true);
  }
  final highest = numbers.reduce(
    // On equal values the earlier card stays ahead.
    (best, play) => play.card.value! > best.card.value! ? play : best,
  );
  return TrickResult(winner: highest.seat, bonuses: _fourteens(numbers));
}

List<Bonus> _fourteens(List<Play> plays) => [
  for (final play in plays)
    if (play.card.value == 14)
      play.card.suit == Suit.black
          ? Bonus.blackFourteen
          : Bonus.standardFourteen,
];

TrickResult _resolvePlain(List<Play> trick) {
  final winner = _winningPlay(trick);
  int count(bool Function(Play) test) => trick.where(test).length;

  final bonuses = [
    ..._fourteens(trick),
    // Only the winning character captures: a beaten one earns nothing.
    if (winner.isPirate)
      for (var i = 0; i < count((play) => play.isMermaid); i++)
        Bonus.mermaidCaptured,
    if (winner.isSkullKing)
      for (var i = 0; i < count((play) => play.isPirate); i++)
        Bonus.pirateCaptured,
    if (winner.isMermaid && trick.any((play) => play.isSkullKing))
      Bonus.skullKingCaptured,
  ];
  return TrickResult(
    winner: winner.seat,
    bonuses: bonuses,
    alliances: [
      // A loot that takes a trick of escapes allies nobody, as the rulebook
      // has it: "aucune alliance n'aura été formée".
      if (!winner.isLoot)
        for (final play in trick)
          if (play.isLoot)
            Alliance(lootSeat: play.seat, winnerSeat: winner.seat),
    ],
  );
}

Play _winningPlay(List<Play> trick) {
  Play? first(bool Function(Play) test) {
    for (final play in trick) {
      if (test(play)) return play;
    }
    return null;
  }

  final skullKing = first((play) => play.isSkullKing);
  final mermaid = first((play) => play.isMermaid);
  final pirate = first((play) => play.isPirate);

  // The three characters beat each other in a cycle; with all three in the
  // trick the mermaid wins, so she is checked first.
  if (mermaid != null && skullKing != null) return mermaid;
  if (skullKing != null) return skullKing;
  if (pirate != null) return pirate;
  if (mermaid != null) return mermaid;

  Play? highest(Suit? suit) {
    Play? best;
    for (final play in trick) {
      if (play.card.suit != suit || suit == null) continue;
      if (best == null || play.card.value! > best.card.value!) best = play;
    }
    return best;
  }

  return highest(Suit.black) ?? highest(leadSuit(trick)) ?? trick.first;
}
