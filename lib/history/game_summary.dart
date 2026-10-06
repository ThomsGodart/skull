import '../engine/engine.dart';

/// How the human bid over a whole game: what the statistics need, kept with
/// the game so that they never have to replay it.
final class GameSummary {
  const GameSummary({
    required this.rounds,
    required this.bidsMade,
    required this.zeroBids,
    required this.zeroBidsMade,
  });

  /// From the scored [rounds] of a game, for the seat of the human.
  factory GameSummary.of(List<RoundScored> rounds, {required int humanSeat}) {
    final mine = [for (final round in rounds) round.results[humanSeat]];
    bool made(SeatResult result) => result.bid == result.tricksWon;
    final zeros = mine.where((result) => result.bid == 0);
    return GameSummary(
      rounds: mine.length,
      bidsMade: mine.where(made).length,
      zeroBids: zeros.length,
      zeroBidsMade: zeros.where(made).length,
    );
  }

  /// Rounds played, tie-breaks included.
  final int rounds;

  /// Rounds where the bid was exact, zero bids included.
  final int bidsMade;
  final int zeroBids;
  final int zeroBidsMade;
}

/// A game that was played to the end.
final class FinishedGame {
  const FinishedGame({
    required this.id,
    required this.finishedAt,
    required this.scores,
    required this.winner,
    required this.playerName,
    this.summary,
    this.humanSeat = 0,
  });

  final int id;
  final DateTime finishedAt;

  /// Final score of each seat.
  final List<int> scores;
  final int winner;
  final int humanSeat;

  /// What the human was called when the game ended, if it was recorded.
  final String? playerName;

  /// Missing for a game kept before summaries were recorded.
  final GameSummary? summary;

  int get players => scores.length;
  int get humanScore => scores[humanSeat];
  bool get humanWon => winner == humanSeat;

  /// 1 for the best score. Equal scores share a rank.
  int get humanRank => 1 + scores.where((score) => score > humanScore).length;
}
