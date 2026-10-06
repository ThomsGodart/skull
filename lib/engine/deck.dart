import 'dart:math';

import 'card.dart';
import 'protocol.dart';

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

/// The cards the expansion adds to the base deck.
const krakenCard = Card.special(CardKind.kraken);
const whiteWhaleCard = Card.special(CardKind.whiteWhale);
const lootCards = [Card.special(CardKind.loot), Card.special(CardKind.loot, 2)];

/// Every card that exists, expansion included.
List<Card> allCards() => [
  ...baseDeck(),
  ...lootCards,
  krakenCard,
  whiteWhaleCard,
];

/// The deck a game with [config] is played with, in a fixed order: the base
/// deck first, so that a base game deals the same whatever is added later.
List<Card> deckFor(GameConfig config) => [
  ...baseDeck(),
  if (config.loot) ...lootCards,
  if (config.kraken) krakenCard,
  if (config.whiteWhale) whiteWhaleCard,
];

/// Cards each player receives in [round] (numbered from 1) with [players]
/// at the table. Tie-break rounds deal as many cards as round ten.
///
/// The base deck bounds it, expansion or not: eight players never get more
/// than eight cards.
int cardsDealt({required int round, required int players}) =>
    min(min(round, standardRounds), baseDeck().length ~/ players);
