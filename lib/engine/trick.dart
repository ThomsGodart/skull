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
}

/// The suit that must be followed in [trick], if any.
///
/// The first number card sets it, unless a character was played before: then
/// nobody has to follow anything for the whole trick.
Suit? _leadSuit(List<Play> trick) {
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
  final lead = _leadSuit(trick);
  if (lead == null || !hand.any((card) => card.suit == lead)) {
    return List.of(hand);
  }
  return [
    for (final card in hand)
      if (!card.isNumber || card.suit == lead) card,
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

/// The outcome of a complete trick.
final class TrickResult {
  const TrickResult({required this.winner, required this.bonuses});

  /// The seat that wins the trick and leads the next one.
  final int winner;

  /// One entry per bonus earned, so the same bonus may appear several times.
  final List<Bonus> bonuses;
}

/// Who wins a complete [trick], and the bonuses the trick carries.
TrickResult resolveTrick(List<Play> trick) {
  final winner = _winningPlay(trick);
  int count(bool Function(Play) test) => trick.where(test).length;

  final bonuses = [
    for (final play in trick)
      if (play.card.value == 14)
        play.card.suit == Suit.black
            ? Bonus.blackFourteen
            : Bonus.standardFourteen,
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
  return TrickResult(winner: winner.seat, bonuses: bonuses);
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

  return highest(Suit.black) ?? highest(_leadSuit(trick)) ?? trick.first;
}
