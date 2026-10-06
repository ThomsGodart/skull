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

  group('rascal scoring', () {
    RoundScore rascal(
      int bid,
      int won,
      int cards, {
      List<Bonus> bonuses = const [],
    }) => scoreRound(
      bid: bid,
      tricksWon: won,
      cardsDealt: cards,
      bonuses: bonuses,
      scoring: Scoring.rascal,
    );

    test('an exact bid earns 10 per card dealt, whatever the bid', () {
      // Official sheet, example A: three cards, bids 0, 1 and 2 all made.
      expect(rascal(0, 0, 3).bidPoints, 30);
      expect(rascal(1, 1, 3).bidPoints, 30);
      expect(rascal(2, 2, 3).bidPoints, 30);
    });

    test('one trick off earns half, two or more nothing', () {
      // Official sheet, example B: four cards.
      expect(rascal(1, 1, 4).bidPoints, 40);
      expect(rascal(0, 1, 4).bidPoints, 20);
      expect(rascal(4, 2, 4).bidPoints, 0);
    });

    test('a score is never negative', () {
      expect(rascal(0, 5, 5).total, 0);
    });

    test('capture bonuses follow the same rule: all, half or none', () {
      const bonuses = [Bonus.skullKingCaptured, Bonus.standardFourteen];

      expect(rascal(2, 2, 5, bonuses: bonuses).bonusPoints, 50);
      expect(rascal(2, 3, 5, bonuses: bonuses).bonusPoints, 25);
      expect(rascal(2, 4, 5, bonuses: bonuses).bonusPoints, 0);
    });
  });

  group('loot alliances', () {
    RoundScore score(int won, {Scoring scoring = Scoring.classic}) =>
        scoreRound(
          bid: 2,
          tricksWon: won,
          cardsDealt: 5,
          alliancesMade: 2,
          scoring: scoring,
        );

    test('each alliance whose two members made their bid is worth 20', () {
      expect(score(2).alliancePoints, 40);
      expect(score(2).total, 40 + 40);
    });

    test('a missed bid earns nothing from an alliance', () {
      expect(score(3).alliancePoints, 0);
    });

    test('in rascal scoring too the bid must be exact: one off earns '
        'nothing from an alliance', () {
      expect(score(2, scoring: Scoring.rascal).alliancePoints, 40);
      expect(score(3, scoring: Scoring.rascal).alliancePoints, 0);
    });
  });

  group('the wager of Rascal the gambler', () {
    RoundScore score(int won, int wager, {Scoring scoring = Scoring.classic}) =>
        scoreRound(
          bid: 1,
          tricksWon: won,
          cardsDealt: 4,
          wager: wager,
          scoring: scoring,
        );

    test('is won on a made bid', () {
      expect(score(1, 20).wagerPoints, 20);
      expect(score(1, 20).total, 20 + 20);
    });

    test('is lost on a missed bid', () {
      expect(score(2, 10).wagerPoints, -10);
      expect(score(2, 10).total, -10 - 10);
    });

    test('a wager of zero changes nothing', () {
      expect(score(2, 0).wagerPoints, 0);
    });

    test('in rascal scoring it is lost when one trick off', () {
      expect(score(2, 20, scoring: Scoring.rascal).wagerPoints, -20);
      expect(score(2, 20, scoring: Scoring.rascal).total, 20 - 20);
    });
  });
}
