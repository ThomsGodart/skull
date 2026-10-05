import 'trick.dart';

/// What one player scores in one round.
final class RoundScore {
  const RoundScore({required this.bidPoints, required this.bonusPoints});

  final int bidPoints;

  /// Zero when the bid was missed, whatever was captured.
  final int bonusPoints;

  int get total => bidPoints + bonusPoints;
}

/// Classic scoring of a round for one player.
RoundScore scoreRound({
  required int bid,
  required int tricksWon,
  required int cardsDealt,
  List<Bonus> bonuses = const [],
}) {
  final made = bid == tricksWon;
  final int bidPoints;
  if (bid == 0) {
    bidPoints = (made ? 10 : -10) * cardsDealt;
  } else {
    bidPoints = made ? 20 * tricksWon : -10 * (bid - tricksWon).abs();
  }
  final bonusPoints = made
      ? bonuses.fold(0, (sum, bonus) => sum + bonus.points)
      : 0;
  return RoundScore(bidPoints: bidPoints, bonusPoints: bonusPoints);
}
