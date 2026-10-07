import 'card.dart';

/// How a tigress is played. Chosen by its player when the card is put down.
enum TigressMode { pirate, escape }

/// A card put down in a trick by a seat.
final class Play {
  const Play({
    required this.seat,
    required this.card,
    this.tigressAs,
    this.declaredValue,
    this.jokerSuit,
  });

  final int seat;
  final Card card;

  /// Set if and only if [card] is the tigress.
  final TigressMode? tigressAs;

  /// 0 or 14: set if and only if [card] is a 0/14.
  final int? declaredValue;

  /// The base suit the joker stands for: the one already led, or the one its
  /// player named when none was. Null when it stands for none — after a trump
  /// lead or a character — and for any other card.
  final Suit? jokerSuit;

  /// What the card counts for among number cards; null for a special card.
  int? get value => switch (card.kind) {
    CardKind.joker => jokerValue,
    CardKind.zeroFourteen => declaredValue,
    _ => card.value,
  };

  /// The suit the card counts for in this trick.
  Suit? get suit => card.kind == CardKind.joker ? jokerSuit : card.suit;

  /// Ranks by its value: a number card, a 0/14 or the joker.
  bool get isNumber => value != null;

  /// Pirate, tigress played as a pirate, Mat, skull king or mermaid.
  bool get isCharacter => isPirate || isMat || isSkullKing || isMermaid;

  bool get isPirate =>
      card.kind == CardKind.pirate || tigressAs == TigressMode.pirate;

  /// One of the named pirates, which the plank can throw overboard.
  bool get isStandardPirate => card.kind == CardKind.pirate;
  bool get isMat => card.kind == CardKind.mat;
  bool get isSkullKing => card.kind == CardKind.skullKing;
  bool get isMermaid => card.kind == CardKind.mermaid;

  /// A sea monster: the kraken, the white whale or the stingray.
  bool get isCreature =>
      card.kind == CardKind.kraken ||
      card.kind == CardKind.whiteWhale ||
      card.kind == CardKind.stingray;
  bool get isLoot => card.kind == CardKind.loot;

  /// Loses like an escape, and takes a trick made of such cards only.
  bool get isEscapeLike =>
      card.kind == CardKind.escape || tigressAs == TigressMode.escape || isLoot;
}

/// What the joker is worth among the cards of its suit.
const jokerValue = 15;

/// The suits the joker may stand for: any but the trump suit.
const jokerSuits = [Suit.green, Suit.yellow, Suit.purple];

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

/// The suit [trick] is played in: that of its first number card, unless a
/// character came before. Sea monsters change nothing to it.
Suit? _suitOf(List<Play> trick) {
  for (final play in trick) {
    if (play.isNumber) return play.suit;
    if (play.isCharacter) return null;
  }
  return null;
}

/// Whether the next card of [trick] may still set its suit: no number card
/// and no character was played yet. A joker played now names its suit.
bool suitIsOpen(List<Play> trick) =>
    trick.every((play) => !play.isNumber && !play.isCharacter);

/// The suit that must be followed in [trick], if any.
///
/// The first number card sets it, unless a character was played before: then
/// nobody has to follow anything for the whole trick. A sea monster lifts it
/// for everyone who plays after — except a stingray that leads, after which
/// the next player sets the suit.
Suit? leadSuit(List<Play> trick) {
  for (final (index, play) in trick.indexed) {
    final leadingStingray = index == 0 && play.card.kind == CardKind.stingray;
    if (play.isCreature && !leadingStingray) return null;
  }
  return _suitOf(trick);
}

/// The suit a joker played next in [trick] stands for when it has none to
/// name: the base suit the trick is played in, if any.
Suit? inheritedJokerSuit(List<Play> trick) {
  final suit = _suitOf(trick);
  return suit == Suit.black ? null : suit;
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
  skullKingCaptured(40),

  // Second expansion.
  extraEight(5),
  extraSeven(-5),
  matCaptured(30),
  seaMonsterCaptured(20);

  const Bonus(this.points);

  final int points;

  /// Comes with the cards of the second expansion.
  bool get isSecondExpansion => index >= extraEight.index;
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

/// How many of [alliances] count for [seat]: those it belongs to and whose
/// other member made their bid. Its own bid is checked when scoring.
int alliancesMadeBy(
  int seat,
  Iterable<Alliance> alliances,
  bool Function(int seat) bidMade,
) => alliances
    .where(
      (alliance) =>
          (alliance.lootSeat == seat && bidMade(alliance.winnerSeat)) ||
          (alliance.winnerSeat == seat && bidMade(alliance.lootSeat)),
    )
    .length;

/// The outcome of a complete trick.
final class TrickResult {
  const TrickResult({
    required this.winner,
    this.winningPlay,
    this.bonuses = const [],
    this.sideBonuses = const [],
    this.alliances = const [],
    this.destroyed = false,
  });

  /// The seat that leads the next trick. It also wins this one, unless the
  /// trick is [destroyed].
  final int winner;

  /// The card that took the trick; null when it is [destroyed].
  final Play? winningPlay;

  /// One entry per bonus earned, so the same bonus may appear several times.
  final List<Bonus> bonuses;

  /// Bonuses that go to a seat whether or not it wins the trick: those of
  /// Davy Jones' chest, per sea monster it destroyed.
  final List<(int seat, Bonus bonus)> sideBonuses;
  final List<Alliance> alliances;

  /// Nobody wins the trick: its cards and bonuses are lost.
  final bool destroyed;
}

/// Who wins [trick], and the bonuses it carries.
///
/// Meant for a complete trick; on a trick still being played it gives the seat
/// that is winning so far. [trick] must hold at least one card. [overboard]
/// is the pirate the plank threw out: it is no longer part of the trick.
TrickResult resolveTrick(List<Play> trick, {Card? overboard}) {
  if (trick.isEmpty) throw ArgumentError.value(trick, 'trick', 'is empty');
  final leader = trick.first.seat;
  final plays = [
    for (final play in trick)
      if (play.card != overboard) play,
  ];
  final creatures = plays.where((play) => play.isCreature).toList();
  final others = [
    for (final play in plays)
      if (!play.isCreature) play,
  ];
  // Davy Jones' chest destroys every sea monster: the trick is then played
  // out as if none had been there.
  final chest = plays
      .where((play) => play.card.kind == CardKind.davyJones)
      .firstOrNull;
  if (chest != null || creatures.isEmpty) {
    return _resolvePlain(
      others,
      leader: leader,
      sideBonuses: [
        if (chest != null)
          for (var i = 0; i < creatures.length; i++)
            (chest.seat, Bonus.seaMonsterCaptured),
      ],
    );
  }

  // Of several sea monsters, only the last one played takes effect.
  final creature = creatures.last.card.kind;
  // Whoever would have won had no sea monster been played.
  final wouldHaveWon = _winningPlay(others)?.seat ?? leader;
  if (creature == CardKind.kraken) {
    return TrickResult(winner: wouldHaveWon, destroyed: true);
  }

  // White whale or stingray: special cards are destroyed, number cards lose
  // their suit. The whale gives the trick to the highest, the stingray to
  // the lowest.
  final numbers = others.where((play) => play.isNumber).toList();
  if (numbers.isEmpty) {
    return TrickResult(winner: wouldHaveWon, destroyed: true);
  }
  final lowestWins = creature == CardKind.stingray;
  final best = numbers.reduce(
    // On equal values the earlier card stays ahead.
    (best, play) =>
        (lowestWins ? play.value! < best.value! : play.value! > best.value!)
        ? play
        : best,
  );
  return TrickResult(
    winner: best.seat,
    winningPlay: best,
    bonuses: _cardBonuses(numbers),
  );
}

/// The bonuses and penalties the number cards of [plays] carry by themselves.
List<Bonus> _cardBonuses(List<Play> plays) => [
  for (final play in plays)
    // A 0/14 played as a 14 is worth nothing.
    if (play.card.kind == CardKind.number)
      if (play.card.value == 14)
        play.card.suit == Suit.black
            ? Bonus.blackFourteen
            : Bonus.standardFourteen
      else if (play.card.isExtraNumber)
        play.card.value == 8 ? Bonus.extraEight : Bonus.extraSeven,
];

TrickResult _resolvePlain(
  List<Play> trick, {
  required int leader,
  List<(int, Bonus)> sideBonuses = const [],
}) {
  final winner = _winningPlay(trick);
  // Nothing but special cards that take no trick: it is thrown away, and
  // whoever led it leads again.
  if (winner == null) {
    return TrickResult(
      winner: leader,
      sideBonuses: sideBonuses,
      destroyed: true,
    );
  }
  int count(bool Function(Play) test) => trick.where(test).length;
  final matTaken = trick.any((play) => play.isMat) && !winner.isMat;

  final bonuses = [
    ..._cardBonuses(trick),
    // Only the winning character captures: a beaten one earns nothing.
    if (winner.isPirate)
      for (var i = 0; i < count((play) => play.isMermaid); i++)
        Bonus.mermaidCaptured,
    if (winner.isSkullKing)
      for (var i = 0; i < count((play) => play.isPirate); i++)
        Bonus.pirateCaptured,
    if (winner.isMermaid && trick.any((play) => play.isSkullKing))
      Bonus.skullKingCaptured,
    if (matTaken && (winner.isSkullKing || winner.isMermaid)) Bonus.matCaptured,
  ];
  return TrickResult(
    winner: winner.seat,
    winningPlay: winner,
    bonuses: bonuses,
    sideBonuses: sideBonuses,
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

/// The card that takes [trick], or null when it holds nothing that can.
Play? _winningPlay(List<Play> trick) {
  Play? first(bool Function(Play) test) {
    for (final play in trick) {
      if (test(play)) return play;
    }
    return null;
  }

  final skullKing = first((play) => play.isSkullKing);
  final mermaid = first((play) => play.isMermaid);
  final mat = first((play) => play.isMat);
  final pirate = first((play) => play.isPirate);

  // The three characters beat each other in a cycle; with all three in the
  // trick the mermaid wins, so she is checked first.
  if (mermaid != null && skullKing != null) return mermaid;
  if (skullKing != null) return skullKing;
  // Mat beats every pirate, but a mermaid takes him even with pirates around.
  if (mat != null) return mermaid ?? mat;
  if (pirate != null) return pirate;
  if (mermaid != null) return mermaid;

  Play? highest(Suit? suit) {
    Play? best;
    for (final play in trick) {
      if (!play.isNumber || play.suit != suit || suit == null) continue;
      if (best == null || play.value! > best.value!) best = play;
    }
    return best;
  }

  return highest(Suit.black) ??
      highest(_suitOf(trick)) ??
      first((play) => play.isEscapeLike);
}
