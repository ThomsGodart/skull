import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:skull_kings/bots/bot.dart';
import 'package:skull_kings/bots/sensible_bot.dart';
import 'package:skull_kings/engine/engine.dart';

import '../engine/support.dart';

/// What seat 0 sees, holding [hand], in a four-player round.
GameView view({
  required List<Card> hand,
  List<Play> trick = const [],
  int bid = 0,
  int tricksWon = 0,
}) => GameView(
  seat: 0,
  round: hand.length,
  cardsDealt: hand.length,
  dealer: 3,
  hand: hand,
  handSizes: List.filled(4, hand.length),
  bids: [bid, 1, 1, 1],
  tricksWon: [tricksWon, 0, 0, 0],
  trick: trick,
  scores: List.filled(4, 0),
);

/// Cards played before seat 0 by seats 1, 2, …
List<Play> played(List<Card> cards) => [
  for (final (index, card) in cards.indexed) Play(seat: index + 1, card: card),
];

void main() {
  final bot = sensibleBot();

  int bidFor(List<Card> hand) {
    final answer = bot(
      BidQuestion(seat: 0, maxBid: hand.length),
      view(hand: hand),
    );
    return (answer as BidAnswer).bid;
  }

  PlayAnswer playFor(GameView view) {
    final question = PlayQuestion(
      seat: 0,
      legalCards: legalCards(view.hand, view.trick),
    );
    return bot(question, view) as PlayAnswer;
  }

  group('bidding', () {
    test('a hand of low cards and escapes bids zero', () {
      expect(bidFor([g(2), y(3), p(4), esc(), esc(2)]), 0);
    });

    test(
      'the skull king, a pirate and the black 14 are worth three tricks',
      () {
        expect(bidFor([skullKing, pirate(), b(14), g(2), y(3)]), 3);
      },
    );

    test('a stronger hand never bids less', () {
      final weak = bidFor([g(2), y(3), p(4), g(5), y(6)]);
      final strong = bidFor([pirate(), y(3), p(4), g(5), y(6)]);

      expect(strong, greaterThan(weak));
    });
  });

  group('playing', () {
    test('needing a trick and playing last, it wins as cheaply as it can', () {
      final answer = playFor(
        view(
          hand: [g(9), g(13), pirate()],
          trick: played([g(7), g(8), g(3)]),
          bid: 1,
        ),
      );

      expect(answer.card, g(9));
    });

    test('with its bid already made, it loses the trick '
        'and sheds its most dangerous losing card', () {
      final answer = playFor(
        view(
          hand: [g(6), g(13), g(2)],
          trick: played([g(7), g(14), g(3)]),
          bid: 0,
        ),
      );

      expect(answer.card, g(13));
    });

    test(
      'with its bid already made, it plays an escape rather than a pirate',
      () {
        final answer = playFor(
          view(
            hand: [pirate(), esc()],
            trick: played([g(7), g(8), g(3)]),
            bid: 0,
          ),
        );

        expect(answer.card, esc());
      },
    );

    test('wanting no trick, it plays the tigress as an escape', () {
      final answer = playFor(
        view(hand: [tigress], trick: played([g(7), g(8), g(3)]), bid: 0),
      );

      expect(answer.tigressAs, TigressMode.escape);
    });

    test('needing a trick, it plays the tigress as a pirate', () {
      final answer = playFor(
        view(hand: [tigress], trick: played([g(7), g(8), g(3)]), bid: 1),
      );

      expect(answer.tigressAs, TigressMode.pirate);
    });

    test('needing tricks, it does not throw a pirate under the skull king', () {
      final answer = playFor(
        view(
          hand: [pirate(), g(2)],
          trick: played([skullKing, g(8), g(3)]),
          bid: 1,
        ),
      );

      expect(answer.card, g(2));
    });
  });

  group('keeping its best cards', () {
    test('needing tricks and leading, it does not open with the skull king '
        'when a high number card can do the job', () {
      final answer = playFor(view(hand: [skullKing, b(13), g(2)], bid: 2));

      expect(answer.card, b(13));
    });

    test('ducking under a skull king, it does not hand over a pirate', () {
      final answer = playFor(
        view(
          hand: [pirate(), g(4)],
          trick: played([skullKing, g(8), g(3)]),
          bid: 0,
        ),
      );

      expect(answer.card, g(4));
    });

    test('ducking with only the tigress, it plays her as an escape '
        'even under a skull king', () {
      final answer = playFor(
        view(hand: [tigress], trick: played([skullKing, g(8), g(3)]), bid: 0),
      );

      expect(answer.tigressAs, TigressMode.escape);
    });
  });

  test(
    'it only ever gives legal answers: whole games of sensible bots end',
    () {
      for (var seed = 0; seed < 60; seed++) {
        final game = Game(GameConfig(players: 3 + seed % 6, seed: seed));
        var guard = 0;
        while (game.pending.isNotEmpty) {
          final question = game.pending.first;
          game.answer(bot(question, game.viewFor(question.seat)));
          expect(++guard, lessThan(10000));
        }
        expect(game.isFinished, isTrue);
      }
    },
  );

  test('against three random players it wins most games', () {
    const games = 300;
    var wins = 0;
    for (var seed = 0; seed < games; seed++) {
      final game = Game(GameConfig(players: 4, seed: seed));
      final random = randomBot(Random(seed));
      GameFinished? finished;
      while (game.pending.isNotEmpty) {
        final question = game.pending.first;
        final player = question.seat == 0 ? bot : random;
        game.answer(player(question, game.viewFor(question.seat)));
        finished =
            game.takeEvents().whereType<GameFinished>().firstOrNull ?? finished;
      }
      if (finished!.winner == 0) wins++;
    }

    // A random player would win one game in four.
    expect(wins / games, greaterThan(0.6));
  });
}
