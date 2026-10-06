import 'game_summary.dart';

/// How the human has done over every finished game.
///
/// A figure with nothing to measure is null, never zero: "no zero bid ever
/// attempted" and "none of them made" are different things to tell a player.
final class GameStatistics {
  const GameStatistics._({
    required this.gamesPlayed,
    required this.wins,
    required this.averageRank,
    required this.averageScore,
    required this.bestScore,
    required this.gamesWithBidDetails,
    required this.bidSuccessRate,
    required this.zeroBidSuccessRate,
  });

  factory GameStatistics.of(List<FinishedGame> games) {
    int sum(Iterable<int> values) => values.fold(0, (total, v) => total + v);
    double? ratio(int part, int whole) => whole == 0 ? null : part / whole;

    final summaries = [for (final game in games) ?game.summary];
    return GameStatistics._(
      gamesPlayed: games.length,
      wins: games.where((game) => game.humanWon).length,
      averageRank: ratio(sum(games.map((g) => g.humanRank)), games.length),
      averageScore: ratio(sum(games.map((g) => g.humanScore)), games.length),
      bestScore: games.isEmpty
          ? null
          : games.map((g) => g.humanScore).reduce((a, b) => a > b ? a : b),
      gamesWithBidDetails: summaries.length,
      bidSuccessRate: ratio(
        sum(summaries.map((s) => s.bidsMade)),
        sum(summaries.map((s) => s.rounds)),
      ),
      zeroBidSuccessRate: ratio(
        sum(summaries.map((s) => s.zeroBidsMade)),
        sum(summaries.map((s) => s.zeroBids)),
      ),
    );
  }

  final int gamesPlayed;
  final int wins;
  final double? averageRank;
  final double? averageScore;
  final int? bestScore;

  /// How many games the bid rates are measured on.
  final int gamesWithBidDetails;

  /// Share of rounds where the bid was exact.
  final double? bidSuccessRate;

  /// Share of zero bids that were made.
  final double? zeroBidSuccessRate;

  double? get winRate => gamesPlayed == 0 ? null : wins / gamesPlayed;
}
