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

/// The 19 cards of the second expansion, in a fixed order.
const maryCard = Card.special(CardKind.pirate, 6);
const jokerCard = Card.special(CardKind.joker);
const matCard = Card.special(CardKind.mat);
const plankCard = Card.special(CardKind.plank);
const stingrayCard = Card.special(CardKind.stingray);
const lastSalvoCard = Card.special(CardKind.lastSalvo);
const davyJonesCard = Card.special(CardKind.davyJones);
List<Card> secondExpansionCards() => [
  for (final suit in Suit.values) ...[
    Card.extraNumber(suit, 7),
    Card.extraNumber(suit, 8),
    Card.zeroFourteen(suit),
  ],
  jokerCard,
  maryCard,
  matCard,
  plankCard,
  stingrayCard,
  lastSalvoCard,
  davyJonesCard,
];

/// Every card that exists, expansions included.
List<Card> allCards() => [
  ...baseDeck(),
  ...lootCards,
  krakenCard,
  whiteWhaleCard,
  ...secondExpansionCards(),
];

/// The deck a game with [config] is played with, in a fixed order: the base
/// deck first, so that a base game deals the same whatever is added later.
List<Card> deckFor(GameConfig config) => [
  ...baseDeck(),
  // Loot needs two players to ally: it is left out of a two-player game.
  if (config.loot && config.players > 2) ...lootCards,
  if (config.kraken) krakenCard,
  if (config.whiteWhale) whiteWhaleCard,
  if (config.playsSecondExpansion) ...secondExpansionCards(),
];

/// Cards each player receives in [round] (numbered from 1) with [players]
/// at the table. Tie-break rounds deal as many cards as round ten.
///
/// The base deck bounds it, whatever the first expansion adds: eight players
/// never get more than eight cards. The [secondExpansion] makes the deck
/// large enough for ten cards each at any table.
int cardsDealt({
  required int round,
  required int players,
  bool secondExpansion = false,
}) => min(
  min(round, standardRounds),
  (baseDeck().length + (secondExpansion ? secondExpansionCards().length : 0)) ~/
      tableHands(players),
);

/// Hands dealt for [players]: one each, plus the ghost's packet when only
/// two play.
int tableHands(int players) => players == 2 ? 3 : players;
