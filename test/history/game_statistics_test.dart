import 'package:flutter_test/flutter_test.dart';
import 'package:skull_kings/engine/engine.dart';
import 'package:skull_kings/history/game_statistics.dart';
import 'package:skull_kings/history/game_summary.dart';

SeatResult seat(int bid, int won, {int total = 0}) => SeatResult(
  bid: bid,
  tricksWon: won,
  bonuses: const [],
  score: scoreRound(bid: bid, tricksWon: won, cardsDealt: 3),
  totalScore: total,
);

RoundScored round(int number, List<SeatResult> results) =>
    RoundScored(round: number, results: results);

FinishedGame game({
  required List<int> scores,
  GameSummary? summary,
  int id = 1,
}) => FinishedGame(
  id: id,
  finishedAt: DateTime(2026, 10, 6),
  scores: scores,
  winner: scores.indexOf(scores.reduce((a, b) => a > b ? a : b)),
  playerName: 'Anne',
  summary: summary,
);

void main() {
  group('summary of a game, for the human at seat 0', () {
    final rounds = [
      round(1, [seat(0, 0), seat(1, 1)]), // zero bid made
      round(2, [seat(0, 1), seat(2, 1)]), // zero bid missed
      round(3, [seat(2, 2), seat(1, 1)]), // bid made
      round(4, [seat(3, 1), seat(1, 3)]), // bid missed
    ];

    test('counts the rounds played and the bids made', () {
      final summary = GameSummary.of(rounds, humanSeat: 0);

      expect(summary.rounds, 4);
      expect(summary.bidsMade, 2);
    });

    test('counts zero bids apart, attempted and made', () {
      final summary = GameSummary.of(rounds, humanSeat: 0);

      expect(summary.zeroBids, 2);
      expect(summary.zeroBidsMade, 1);
    });

    test('looks at the right seat', () {
      final summary = GameSummary.of(rounds, humanSeat: 1);

      expect(summary.bidsMade, 2);
      expect(summary.zeroBids, 0);
    });
  });

  group('rank of the human in a finished game', () {
    test('is one for the best score', () {
      expect(game(scores: [90, 40, 10]).humanRank, 1);
    });

    test('counts the players ahead', () {
      expect(game(scores: [10, 40, 90, -20]).humanRank, 3);
    });

    test('is shared when scores are equal', () {
      expect(game(scores: [40, 90, 40, 10]).humanRank, 2);
    });
  });

  group('statistics', () {
    test('with no game, every figure is unavailable rather than zero', () {
      final stats = GameStatistics.of(const []);

      expect(stats.gamesPlayed, 0);
      expect(stats.wins, 0);
      expect(stats.winRate, isNull);
      expect(stats.averageRank, isNull);
      expect(stats.averageScore, isNull);
      expect(stats.bestScore, isNull);
      expect(stats.bidSuccessRate, isNull);
      expect(stats.zeroBidSuccessRate, isNull);
    });

    test('counts games, wins, ranks and scores of the human', () {
      final stats = GameStatistics.of([
        game(scores: [100, 40, 10]),
        game(scores: [20, 40, 10]),
        game(scores: [-60, 40, 10]),
        game(scores: [80, 40, 10]),
      ]);

      expect(stats.gamesPlayed, 4);
      expect(stats.wins, 2);
      expect(stats.winRate, 0.5);
      expect(stats.averageRank, (1 + 2 + 3 + 1) / 4);
      expect(stats.averageScore, (100 + 20 - 60 + 80) / 4);
      expect(stats.bestScore, 100);
    });

    test('a best score can be negative', () {
      expect(
        GameStatistics.of([
          game(scores: [-30, -80]),
        ]).bestScore,
        -30,
      );
    });

    test('bid success is measured over every round of every game', () {
      final stats = GameStatistics.of([
        game(
          scores: [10, 0],
          summary: const GameSummary(
            rounds: 10,
            bidsMade: 4,
            zeroBids: 3,
            zeroBidsMade: 3,
          ),
        ),
        game(
          scores: [10, 0],
          summary: const GameSummary(
            rounds: 10,
            bidsMade: 8,
            zeroBids: 1,
            zeroBidsMade: 0,
          ),
        ),
      ]);

      expect(stats.bidSuccessRate, 12 / 20);
      expect(stats.zeroBidSuccessRate, 3 / 4);
    });

    test('a player who never bid zero has no zero-bid rate, not a rate '
        'of zero', () {
      final stats = GameStatistics.of([
        game(
          scores: [10, 0],
          summary: const GameSummary(
            rounds: 10,
            bidsMade: 5,
            zeroBids: 0,
            zeroBidsMade: 0,
          ),
        ),
      ]);

      expect(stats.bidSuccessRate, 0.5);
      expect(stats.zeroBidSuccessRate, isNull);
    });

    test('games kept without a summary count for wins and scores, '
        'but are left out of the bid rates', () {
      final stats = GameStatistics.of([
        game(scores: [50, 0]),
        game(
          scores: [10, 20],
          summary: const GameSummary(
            rounds: 10,
            bidsMade: 10,
            zeroBids: 2,
            zeroBidsMade: 2,
          ),
        ),
      ]);

      expect(stats.gamesPlayed, 2);
      expect(stats.wins, 1);
      expect(stats.bidSuccessRate, 1.0);
      expect(stats.gamesWithBidDetails, 1);
    });
  });
}
