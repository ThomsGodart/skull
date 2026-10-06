import 'dart:math';

import 'card.dart';
import 'protocol.dart';
import 'trick.dart';

/// A legal answer to [question] picked at random: the weakest possible bot,
/// and what the engine's own tests are played with.
Answer randomAnswer(Question question, Random random) => switch (question) {
  BidQuestion(:final seat, :final maxBid) => BidAnswer(
    seat: seat,
    bid: random.nextInt(maxBid + 1),
  ),
  PlayQuestion(:final seat, :final legalCards) => _randomPlay(
    seat,
    legalCards[random.nextInt(legalCards.length)],
    random,
  ),
  ChooseLeaderQuestion(:final seat, :final seats) => ChooseLeaderAnswer(
    seat: seat,
    leader: seats[random.nextInt(seats.length)],
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

PlayAnswer _randomPlay(int seat, Card card, Random random) => PlayAnswer(
  seat: seat,
  card: card,
  tigressAs: card.kind == CardKind.tigress
      ? TigressMode.values[random.nextInt(TigressMode.values.length)]
      : null,
);
