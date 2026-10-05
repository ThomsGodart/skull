import 'dart:math';

import 'card.dart';

/// Rounds in a game before any tie-break.
const standardRounds = 10;

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

/// Cards each player receives in [round] (numbered from 1) with [players]
/// at the table. Tie-break rounds deal as many cards as round ten.
///
/// The base deck bounds it: eight players never get more than eight cards.
int cardsDealt({required int round, required int players}) =>
    min(min(round, standardRounds), baseDeck().length ~/ players);
