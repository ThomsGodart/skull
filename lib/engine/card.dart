/// The four suits of number cards. Black is the trump suit.
enum Suit { green, yellow, purple, black }

enum CardKind { number, escape, pirate, tigress, skullKing, mermaid }

/// One physical card of the deck.
///
/// Cards are unique: the five pirates differ by [copy], so a card names itself
/// and two cards are equal only when they are the same physical card.
final class Card {
  const Card.number(Suit this.suit, int this.value)
    : kind = CardKind.number,
      copy = 1;

  const Card.special(this.kind, [this.copy = 1])
    : assert(kind != CardKind.number, 'use Card.number'),
      suit = null,
      value = null;

  /// The card named by [id], as written by [Card.id].
  ///
  /// Throws a [FormatException] when no card of the deck has that identifier.
  factory Card.fromId(String id) =>
      _byId[id] ?? (throw FormatException('unknown card', id));

  static final Map<String, Card> _byId = {
    for (final card in _everyCard()) card.id: card,
  };

  final CardKind kind;

  /// Null for a special card.
  final Suit? suit;

  /// 1 to 14, null for a special card.
  final int? value;

  /// Distinguishes the identical special cards of the deck, starting at 1.
  final int copy;

  bool get isNumber => kind == CardKind.number;

  /// Stable identifier, used for equality and for saving a game.
  String get id => switch (kind) {
    CardKind.number => '${suit!.name}-$value',
    _ => '${kind.name}-$copy',
  };

  @override
  bool operator ==(Object other) => other is Card && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => id;
}

/// How many copies of each special card exist, expansion cards included.
const specialCardCopies = {
  CardKind.escape: 5,
  CardKind.pirate: 5,
  CardKind.tigress: 1,
  CardKind.skullKing: 1,
  CardKind.mermaid: 2,
};

Iterable<Card> _everyCard() sync* {
  for (final suit in Suit.values) {
    for (var value = 1; value <= 14; value++) {
      yield Card.number(suit, value);
    }
  }
  for (final MapEntry(key: kind, value: copies) in specialCardCopies.entries) {
    for (var copy = 1; copy <= copies; copy++) {
      yield Card.special(kind, copy);
    }
  }
}
