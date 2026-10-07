import 'dart:math';

import 'card.dart';
import 'protocol.dart';
import 'trick.dart';

/// A legal answer to [question] picked at random: the weakest possible bot,
/// and what the engine's own tests are played with.
///
/// [trick] is what lies on the table: the joker needs it to know whether it
/// has a suit to name.
Answer randomAnswer(
  Question question,
  Random random, {
  List<Play> trick = const [],
}) => switch (question) {
  BidQuestion(:final seat, :final maxBid) => BidAnswer(
    seat: seat,
    bid: random.nextInt(maxBid + 1),
  ),
  PlayQuestion(:final seat, :final legalCards) => _randomPlay(
    seat,
    legalCards[random.nextInt(legalCards.length)],
    random,
    trick,
  ),
  ChooseLeaderQuestion(:final seat, :final seats) => ChooseLeaderAnswer(
    seat: seat,
    leader: seats[random.nextInt(seats.length)],
  ),
  WalkPlankQuestion(:final seat, :final pirates) => WalkPlankAnswer(
    seat: seat,
    pirate: pirates[random.nextInt(pirates.length)],
  ),
  ChooseVictimQuestion(:final seat, :final seats) => ChooseVictimAnswer(
    seat: seat,
    victim: seats[random.nextInt(seats.length)],
  ),
  DiscardQuestion(:final seat, :final hand, :final count) => DiscardAnswer(
    seat: seat,
    cards: (List.of(hand)..shuffle(random)).take(count).toList(),
  ),
  WagerQuestion(:final seat, :final amounts) => WagerAnswer(
    seat: seat,
    amount: amounts[random.nextInt(amounts.length)],
  ),
  AdjustBidQuestion(:final seat, :final changes) => AdjustBidAnswer(
    seat: seat,
    change: changes[random.nextInt(changes.length)],
  ),
};

PlayAnswer _randomPlay(int seat, Card card, Random random, List<Play> trick) =>
    PlayAnswer(
      seat: seat,
      card: card,
      tigressAs: card.kind == CardKind.tigress
          ? TigressMode.values[random.nextInt(TigressMode.values.length)]
          : null,
      declaredValue: card.kind == CardKind.zeroFourteen
          ? (random.nextBool() ? 0 : 14)
          : null,
      jokerSuit: card.kind == CardKind.joker && suitIsOpen(trick)
          ? jokerSuits[random.nextInt(jokerSuits.length)]
          : null,
    );

/// The cards on the table after [events]: what a seat that only receives
/// events needs to know to play a joker.
List<Play> trickAfter(Iterable<Event> events) {
  var trick = <Play>[];
  for (final event in events) {
    switch (event) {
      case CardPlayed(:final play):
        trick.add(play);
      case TrickWon() || RoundStarted():
        trick = [];
      default:
    }
  }
  return trick;
}
