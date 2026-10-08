import 'package:flutter_test/flutter_test.dart';
import 'package:skull_kings/engine/engine.dart';

/// Answers every pending bid with [bid].
void bidAll(Game game, int bid) {
  for (final question in game.pending.cast<BidQuestion>().toList()) {
    game.answer(BidAnswer(seat: question.seat, bid: bid));
  }
}

void main() {
  const config = GameConfig(players: 4, seed: 7);

  group('a new game', () {
    test('starts round one and deals one card to each seat, privately', () {
      final game = Game(config);

      final events = game.takeEvents();

      final started = events.whereType<RoundStarted>().single;
      expect(started.round, 1);
      expect(started.cardsDealt, 1);
      final hands = events.whereType<HandDealt>().toList();
      expect(hands.map((e) => e.seat), [0, 1, 2, 3]);
      for (final hand in hands) {
        expect(hand.cards, hasLength(1));
        expect(hand.audience, hand.seat, reason: 'a hand is private');
      }
      expect(hands.expand((e) => e.cards).toSet(), hasLength(4));
    });

    test('asks every seat for a bid at once', () {
      final game = Game(config);

      final questions = game.pending;

      expect(questions, everyElement(isA<BidQuestion>()));
      expect(questions.map((q) => q.seat), unorderedEquals([0, 1, 2, 3]));
      expect(
        questions.cast<BidQuestion>().map((q) => q.maxBid),
        everyElement(1),
      );
    });

    test('the seat left of the dealer leads the first trick', () {
      final game = Game(config);
      final started = game.takeEvents().whereType<RoundStarted>().single;

      bidAll(game, 0);

      expect(started.leader, (started.dealer + 1) % 4);
      expect(game.pending.single.seat, started.leader);
    });
  });

  group('bidding', () {
    test('bids stay secret until every seat has bid, '
        'then are revealed together', () {
      final game = Game(config)..takeEvents();

      game.answer(const BidAnswer(seat: 0, bid: 1));
      game.answer(const BidAnswer(seat: 1, bid: 0));
      game.answer(const BidAnswer(seat: 2, bid: 1));

      expect(
        game.takeEvents().whereType<BidAccepted>().map((e) => e.seat),
        [0, 1, 2],
      );
      expect(game.pending.single.seat, 3);

      game.answer(const BidAnswer(seat: 3, bid: 0));

      final events = game.takeEvents();
      expect(events.whereType<BidAccepted>().single.seat, 3);
      final revealed = events.whereType<BidsRevealed>().single;
      expect(revealed.bids, [1, 0, 1, 0]);
      expect(revealed.audience, isNull);
    });

    test('a short game may start at a later round', () {
      final game = Game(
        const GameConfig(players: 4, seed: 7, startingRound: 5),
      );

      expect(game.takeEvents().whereType<RoundStarted>().single.round, 5);
      expect(game.viewFor(0).cardsDealt, 5);
    });

    test('finishEarly ends with the scores as they stand', () {
      final game = Game(config)..takeEvents();
      bidAll(game, 0);
      game.takeEvents();
      game.finishEarly();

      final finished = game.takeEvents().whereType<GameFinished>().single;
      expect(finished.scores, everyElement(0));
      expect(game.pending, isEmpty);
    });

    test('a bid above the number of cards dealt is refused', () {
      final game = Game(config);

      expect(
        () => game.answer(const BidAnswer(seat: 0, bid: 2)),
        throwsA(isA<IllegalAnswer>()),
      );
      expect(game.pending, hasLength(4), reason: 'nothing changed');
    });

    test('a seat that bids again changes its bid, within the same limits', () {
      final game = Game(config);
      game.answer(const BidAnswer(seat: 0, bid: 1));
      game.answer(const BidAnswer(seat: 0, bid: 0));

      expect(game.viewFor(0).bids[0], 0);
      expect(
        () => game.answer(const BidAnswer(seat: 0, bid: 2)),
        throwsA(isA<IllegalAnswer>()),
      );
    });

    test('a card cannot be played while bids are open', () {
      final game = Game(config);
      final card = game.takeEvents().whereType<HandDealt>().first.cards.single;

      expect(
        () => game.answer(PlayAnswer(seat: 0, card: card)),
        throwsA(isA<IllegalAnswer>()),
      );
    });
  });
}
