import 'package:flutter_test/flutter_test.dart';
import 'package:skull_kings/engine/engine.dart';

void main() {
  group('cards dealt', () {
    test('a round deals as many cards as its number', () {
      expect(cardsDealt(round: 1, players: 4), 1);
      expect(cardsDealt(round: 7, players: 4), 7);
      expect(cardsDealt(round: 10, players: 7), 10);
    });

    test('eight players never get more than eight cards', () {
      expect(cardsDealt(round: 8, players: 8), 8);
      expect(cardsDealt(round: 9, players: 8), 8);
      expect(cardsDealt(round: 10, players: 8), 8);
    });

    test('a tie-break round deals as many cards as round ten', () {
      expect(cardsDealt(round: 11, players: 4), 10);
      expect(cardsDealt(round: 13, players: 8), 8);
    });
  });

  group('bid points', () {
    int points(int bid, int won, int cards) =>
        scoreRound(bid: bid, tricksWon: won, cardsDealt: cards).bidPoints;

    test('an exact bid of one or more earns 20 per trick', () {
      expect(points(3, 3, 5), 60);
      expect(points(1, 1, 1), 20);
    });

    test('a missed bid of one or more loses 10 per trick of difference', () {
      expect(points(2, 4, 5), -20);
      expect(points(3, 1, 4), -20);
      expect(points(1, 0, 1), -10);
    });

    test('an exact bid of zero earns 10 per card dealt', () {
      expect(points(0, 0, 1), 10);
      expect(points(0, 0, 7), 70);
      expect(points(0, 0, 10), 100);
    });

    test(
      'with eight players, rounds nine and ten are worth 80 on a bid of zero',
      () {
        for (final round in [9, 10]) {
          final cards = cardsDealt(round: round, players: 8);

          expect(points(0, 0, cards), 80);
          expect(points(0, 3, cards), -80);
        }
      },
    );

    test('a missed bid of zero loses 10 per card dealt, '
        'however many tricks were taken', () {
      expect(points(0, 2, 9), -90);
      expect(points(0, 1, 9), -90);
      expect(points(0, 5, 4), -40);
    });
  });

  group('bonus points', () {
    const bonuses = [Bonus.standardFourteen, Bonus.skullKingCaptured];

    test('bonuses count when the bid is made', () {
      final score = scoreRound(
        bid: 1,
        tricksWon: 1,
        cardsDealt: 3,
        bonuses: bonuses,
      );

      expect(score.bonusPoints, 50);
      expect(score.total, 70);
    });

    test('bonuses are lost when the bid is missed', () {
      final score = scoreRound(
        bid: 1,
        tricksWon: 2,
        cardsDealt: 3,
        bonuses: bonuses,
      );

      expect(score.bonusPoints, 0);
      expect(score.total, -10);
    });

    test(
      'a 40-point capture counts on a made bid of one and not on a missed one',
      () {
        int bonus(int won) => scoreRound(
          bid: 1,
          tricksWon: won,
          cardsDealt: 3,
          bonuses: const [Bonus.skullKingCaptured],
        ).bonusPoints;

        expect(bonus(1), 40);
        expect(bonus(0), 0);
      },
    );

    test('bonuses are lost on a missed bid of zero', () {
      final score = scoreRound(
        bid: 0,
        tricksWon: 1,
        cardsDealt: 3,
        bonuses: bonuses,
      );

      expect(score.total, -30);
    });
  });
}
