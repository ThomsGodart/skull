import 'deck.dart';

/// The four suits of number cards. Black is the trump suit.
enum Suit { green, yellow, purple, black }

enum CardKind {
  number,
  escape,
  pirate,
  tigress,
  skullKing,
  mermaid,

  // Expansion cards.
  loot,
  kraken,
  whiteWhale,

  // Second expansion.
  /// A number card of a suit whose value, 0 or 14, is said when it is played.
  zeroFourteen,

  /// The monkey: a 15 of whichever base suit serves, never of the trump suit.
  joker,

  /// Mat the rogue, who beats every pirate.
  mat,
  plank,
  stingray,
  lastSalvo,
  davyJones,
}

/// The pirates of the deck, each with a power of its own when the advanced
/// pirate powers are in play. A pirate card's [Card.copy] names it. The first
/// five are in the base deck; Mary comes with the second expansion.
enum Pirate {
  rosie,
  will,
  rascal,
  juanita,
  harry,
  mary;

  /// The pirate drawn on [card], or null when it is not a pirate card.
  static Pirate? of(Card card) =>
      card.kind == CardKind.pirate ? values[card.copy - 1] : null;
}

/// One physical card of the deck.
///
/// Cards are unique: the five pirates differ by [copy], so a card names itself
/// and two cards are equal only when they are the same physical card.
final class Card {
  const Card.number(Suit this.suit, int this.value)
    : kind = CardKind.number,
      copy = 1;

  /// The second 7 or 8 of [suit], which the second expansion adds: taking it
  /// in a trick is worth a few points, or costs some.
  const Card.extraNumber(Suit this.suit, int this.value)
    : assert(value == 7 || value == 8, 'only 7 and 8 come twice'),
      kind = CardKind.number,
      copy = 2;

  const Card.zeroFourteen(Suit this.suit)
    : kind = CardKind.zeroFourteen,
      value = null,
      copy = 1;

  const Card.special(this.kind, [this.copy = 1])
    : assert(kind != CardKind.number, 'use Card.number'),
      assert(kind != CardKind.zeroFourteen, 'use Card.zeroFourteen'),
      suit = null,
      value = null;

  /// The card named by [id], as written by [Card.id].
  ///
  /// Throws a [FormatException] when no card of the deck has that identifier.
  factory Card.fromId(String id) =>
      _byId[id] ?? (throw FormatException('unknown card', id));

  static final Map<String, Card> _byId = {
    for (final card in allCards()) card.id: card,
  };

  final CardKind kind;

  /// Null for a special card.
  final Suit? suit;

  /// 1 to 14. Null for a special card, and for a 0/14: its value is only
  /// known once it is played.
  final int? value;

  /// Distinguishes the identical cards of the deck, starting at 1.
  final int copy;

  /// A card of a suit, which has to follow the suit led: a plain number card
  /// or a 0/14. The joker is not one: it may always be played.
  bool get isNumber => suit != null;

  /// The 7 or 8 the second expansion adds to a suit.
  bool get isExtraNumber => kind == CardKind.number && copy == 2;

  /// Stable identifier, used for equality and for saving a game.
  String get id => switch (kind) {
    CardKind.number when copy == 1 => '${suit!.name}-$value',
    CardKind.number => '${suit!.name}-$value-extra',
    CardKind.zeroFourteen => '${suit!.name}-0or14',
    _ => '${kind.name}-$copy',
  };

  @override
  bool operator ==(Object other) => other is Card && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => id;
}
