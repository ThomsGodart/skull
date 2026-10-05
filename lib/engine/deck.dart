import 'card.dart';

/// The 70 cards of the base game, in a fixed order.
List<Card> baseDeck() => [
  for (final suit in Suit.values)
    for (var value = 1; value <= 14; value++) Card.number(suit, value),
  for (var copy = 1; copy <= 5; copy++) Card.special(CardKind.pirate, copy),
  const Card.special(CardKind.tigress),
  const Card.special(CardKind.skullKing),
  for (var copy = 1; copy <= 2; copy++) Card.special(CardKind.mermaid, copy),
  for (var copy = 1; copy <= 5; copy++) Card.special(CardKind.escape, copy),
];
