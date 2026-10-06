import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:skull_kings/counter/counter_game.dart';
import 'package:skull_kings/engine/engine.dart';

CounterGame newGame({
  List<String> players = const ['Anne', 'Bob', 'Chloé'],
  Scoring scoring = Scoring.classic,
  int firstLeader = 0,
}) => CounterGame(players: players, firstLeader: firstLeader, scoring: scoring);

/// A round where each player bid and took what [lines] say: (bid, tricks).
CounterRound round(List<(int, int)> lines) => CounterRound(
  entries: [
    for (final (bid, won) in lines) CounterEntry(bid: bid, tricksWon: won),
  ],
);

void main() {
  test('round n is played with n cards, capped as at the table', () {
    final three = newGame();
    final eight = newGame(players: List.generate(8, (i) => 'P$i'));

    expect(three.cardsIn(1), 1);
    expect(three.cardsIn(10), 10);
    expect(eight.cardsIn(9), 8);
    expect(eight.cardsIn(10), 8);
  });

  test('the lead moves one player each round', () {
    final game = newGame(firstLeader: 1);

    expect([for (var r = 1; r <= 4; r++) game.leaderOf(r)], [1, 2, 0, 1]);
  });

  test('a round is scored as the rulebook says, with running totals', () {
    // The rulebook's score sheet: Suzie, Félix, Pauline over two rounds.
    final game = newGame(players: ['Suzie', 'Félix', 'Pauline'])
      ..saveRound(
        1,
        CounterRound(
          entries: [
            const CounterEntry(bid: 0, tricksWon: 0),
            const CounterEntry(bid: 0, tricksWon: 0),
            const CounterEntry(
              bid: 1,
              tricksWon: 1,
              bonuses: {Bonus.standardFourteen: 1},
            ),
          ],
        ),
      )
      ..saveRound(
        2,
        CounterRound(
          entries: [
            const CounterEntry(
              bid: 1,
              tricksWon: 1,
              bonuses: {Bonus.pirateCaptured: 1},
            ),
            const CounterEntry(bid: 2, tricksWon: 0),
            const CounterEntry(bid: 0, tricksWon: 1),
          ],
        ),
      );

    final scored = game.scoredRounds;

    expect(scored[0].results.map((r) => r.totalScore), [10, 10, 30]);
    expect(scored[1].results.map((r) => r.score.total), [50, -20, -20]);
    expect(scored[1].results.map((r) => r.totalScore), [60, -10, 10]);
    expect(game.totals, [60, -10, 10]);
  });

  test('bonuses are entered by kind and counted only on a made bid', () {
    final game = newGame()
      ..saveRound(
        1,
        CounterRound(
          entries: [
            const CounterEntry(
              bid: 1,
              tricksWon: 1,
              bonuses: {Bonus.mermaidCaptured: 2, Bonus.blackFourteen: 1},
            ),
            const CounterEntry(
              bid: 0,
              tricksWon: 0,
              bonuses: {Bonus.standardFourteen: 1},
            ),
            const CounterEntry(bid: 1, tricksWon: 0),
          ],
        ),
      );

    final results = game.scoredRounds.single.results;
    expect(results[0].score.bonusPoints, 60);
    expect(results[0].bonuses, hasLength(3));
    expect(results[1].score.bonusPoints, 10);
  });

  test('a loot alliance pays both members only when both made their bid', () {
    CounterGame withAlliance(int bobTricks) => newGame()
      ..saveRound(
        1,
        CounterRound(
          entries: [
            const CounterEntry(bid: 1, tricksWon: 1),
            CounterEntry(bid: 0, tricksWon: bobTricks),
            const CounterEntry(bid: 0, tricksWon: 0),
          ],
          alliances: const [(0, 1)],
        ),
      );

    final both = withAlliance(0).scoredRounds.single.results;
    expect(both[0].score.alliancePoints, 20);
    expect(both[1].score.alliancePoints, 20);
    expect(both[2].score.alliancePoints, 0);

    final one = withAlliance(1).scoredRounds.single.results;
    expect(one[0].score.alliancePoints, 0);
    expect(one[1].score.alliancePoints, 0);
  });

  test('Harry moves the bid that is scored, and Rascal\'s wager follows', () {
    final game = newGame()
      ..saveRound(1, round([(0, 0), (0, 0), (0, 0)]))
      ..saveRound(
        2,
        CounterRound(
          entries: [
            const CounterEntry(bid: 1, tricksWon: 2, bidChange: 1, wager: 20),
            const CounterEntry(bid: 1, tricksWon: 0, wager: 10),
            const CounterEntry(bid: 0, tricksWon: 0),
          ],
        ),
      );

    final results = game.scoredRounds.last.results;
    expect(results[0].bid, 2);
    expect(results[0].score.bidPoints, 40);
    expect(results[0].score.wagerPoints, 20);
    expect(results[1].score.wagerPoints, -10);
  });

  test('rascal scoring is used when the game says so', () {
    final game = newGame(scoring: Scoring.rascal);
    for (var r = 1; r <= 3; r++) {
      game.saveRound(r, round([(0, 0), (0, 0), (0, 0)]));
    }
    game.saveRound(4, round([(2, 2), (2, 3), (0, 4)]));

    expect(game.scoredRounds.last.results.map((r) => r.score.bidPoints), [
      40,
      20,
      0,
    ]);
  });

  test('correcting a past round changes every total after it', () {
    final game = newGame()
      ..saveRound(1, round([(1, 1), (0, 0), (0, 0)]))
      ..saveRound(2, round([(1, 1), (1, 1), (0, 0)]));
    expect(game.totals, [40, 30, 30]);

    game.saveRound(1, round([(1, 0), (0, 0), (0, 1)]));

    expect(game.totals, [10, 30, 10]);
    expect(game.scoredRounds, hasLength(2));
  });

  test('rounds are entered in order: the next one, or a correction', () {
    final game = newGame()..saveRound(1, round([(0, 0), (0, 0), (1, 1)]));

    expect(game.nextRound, 2);
    expect(
      () => game.saveRound(4, round([(0, 0), (0, 0), (0, 0)])),
      throwsArgumentError,
    );
    expect(
      () => game.saveRound(2, round([(0, 0), (0, 0)])),
      throwsArgumentError,
      reason: 'one entry per player',
    );
  });

  group('the end of the game', () {
    CounterGame after(int rounds, {required bool tie}) {
      final game = newGame();
      for (var r = 1; r <= rounds; r++) {
        // Anne and Bob both make a zero bid; Chloé too unless a tie is wanted
        // off, in which case she misses in round one.
        game.saveRound(
          r,
          round([(0, 0), (0, 0), tie || r > 1 ? (0, 0) : (0, 1)]),
        );
      }
      return game;
    }

    test('ten rounds with a single leader end the game', () {
      final game = newGame();
      for (var r = 1; r <= 10; r++) {
        game.saveRound(r, round([(0, 0), (0, r == 1 ? 1 : 0), (0, 1)]));
      }

      expect(game.isOver, isTrue);
      expect(game.winner, 0);
    });

    test('it is not over before round ten', () {
      expect(after(9, tie: false).isOver, isFalse);
    });

    test('a tie for first place after round ten calls for another round', () {
      final game = after(10, tie: true);

      expect(game.isOver, isFalse);
      expect(game.winner, isNull);
      expect(game.nextRound, 11);
      expect(game.cardsIn(11), 10);
    });
  });

  test('how many tricks were claimed in a round can be checked against '
      'the cards dealt', () {
    final entered = round([(1, 1), (0, 0), (1, 1)]);

    expect(entered.tricksClaimed, 2);
  });

  test('a game survives a trip through JSON, options and corrections '
      'included', () {
    final game =
        CounterGame(
          players: ['Anne', 'Bob'],
          firstLeader: 1,
          scoring: Scoring.rascal,
          loot: true,
          piratePowers: true,
        )..saveRound(
          1,
          CounterRound(
            entries: [
              const CounterEntry(
                bid: 1,
                tricksWon: 1,
                bonuses: {Bonus.skullKingCaptured: 1},
                wager: 10,
                bidChange: -1,
              ),
              const CounterEntry(bid: 0, tricksWon: 0),
            ],
            alliances: const [(0, 1)],
          ),
        );

    final copy = CounterGame.fromJson(
      jsonDecode(jsonEncode(game.toJson())) as Map<String, Object?>,
    );

    expect(copy.players, ['Anne', 'Bob']);
    expect(copy.firstLeader, 1);
    expect(copy.scoring, Scoring.rascal);
    expect(copy.loot, isTrue);
    expect(copy.piratePowers, isTrue);
    expect(copy.totals, game.totals);
    expect(copy.round(1)!.alliances, [(0, 1)]);
    expect(copy.round(1)!.entries.first.bonuses, {Bonus.skullKingCaptured: 1});
  });

  test('a game needs two to eight players with a name each', () {
    expect(() => newGame(players: ['Seul']), throwsArgumentError);
    expect(
      () => newGame(players: List.generate(9, (i) => 'P$i')),
      throwsArgumentError,
    );
  });

  group('what cannot be', () {
    test('an alliance of a player with themselves is refused', () {
      expect(
        () => newGame().saveRound(
          1,
          CounterRound(
            entries: round([(0, 0), (0, 0), (1, 1)]).entries,
            alliances: const [(1, 1)],
          ),
        ),
        throwsArgumentError,
      );
    });

    test('an alliance with a player who is not at the table is refused', () {
      expect(
        () => newGame().saveRound(
          1,
          CounterRound(
            entries: round([(0, 0), (0, 0), (1, 1)]).entries,
            alliances: const [(0, 7)],
          ),
        ),
        throwsArgumentError,
      );
    });

    test('stored data that describes such a round is not read as a game', () {
      final json = newGame().toJson()
        ..['rounds'] = [
          {
            'entries': [
              {'bid': 0, 'tricksWon': 0},
            ],
          },
        ];

      expect(() => CounterGame.fromJson(json), throwsA(anything));
    });

    test('Harry cannot push a bid below zero or above the cards dealt', () {
      final game = newGame()
        ..saveRound(
          1,
          CounterRound(
            entries: [
              const CounterEntry(bid: 0, tricksWon: 0, bidChange: -1),
              const CounterEntry(bid: 1, tricksWon: 1, bidChange: 1),
              const CounterEntry(bid: 0, tricksWon: 0),
            ],
          ),
        );

      final results = game.scoredRounds.single.results;
      expect(results[0].bid, 0);
      expect(results[0].score.bidPoints, 10);
      expect(results[1].bid, 1);
      expect(results[1].score.bidPoints, 20);
    });
  });

  test('once a correction ends the game, the bids of a round that will '
      'not be played are forgotten', () {
    final game = newGame();
    for (var r = 1; r <= 10; r++) {
      game.saveRound(r, round([(0, 0), (0, 0), (0, 0)]));
    }
    game.draftBids = [1, 2, 3];

    game.saveRound(10, round([(0, 0), (0, 1), (0, 1)]));

    expect(game.isOver, isTrue);
    expect(game.draftBids, isNull);
  });
}
