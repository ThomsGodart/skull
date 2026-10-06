import 'protocol.dart';
import 'trick.dart';

/// What one player scores in one round.
final class RoundScore {
  const RoundScore({
    required this.bidPoints,
    required this.bonusPoints,
    this.alliancePoints = 0,
    this.wagerPoints = 0,
  });

  final int bidPoints;

  /// From the 14s and the captures. Zero when the bid was missed in classic
  /// scoring, scaled like the bid in rascal scoring.
  final int bonusPoints;

  /// From loot alliances whose two members made their bid.
  final int alliancePoints;

  /// What Rascal's wager brought: won on an exact bid, lost otherwise.
  final int wagerPoints;

  int get total => bidPoints + bonusPoints + alliancePoints + wagerPoints;
}

/// Scores a round for one player.
///
/// [alliancesMade] counts the loot alliances whose other member made their
/// bid; [wager] is what was staked with Rascal the gambler. Both need an exact
/// bid in every [scoring].
RoundScore scoreRound({
  required int bid,
  required int tricksWon,
  required int cardsDealt,
  List<Bonus> bonuses = const [],
  Scoring scoring = Scoring.classic,
  int alliancesMade = 0,
  int wager = 0,
}) {
  final miss = (bid - tricksWon).abs();
  final made = miss == 0;
  final captured = bonuses.fold(0, (sum, bonus) => sum + bonus.points);
  final int bidPoints;
  final int bonusPoints;
  switch (scoring) {
    case Scoring.classic:
      bidPoints = bid == 0
          ? (made ? 10 : -10) * cardsDealt
          : (made ? 20 * tricksWon : -10 * miss);
      bonusPoints = made ? captured : 0;
    case Scoring.rascal:
      // All, half or none of the same potential, for the bid and the bonuses.
      int share(int points) => switch (miss) {
        0 => points,
        1 => points ~/ 2,
        _ => 0,
      };
      bidPoints = share(10 * cardsDealt);
      bonusPoints = share(captured);
  }
  return RoundScore(
    bidPoints: bidPoints,
    bonusPoints: bonusPoints,
    alliancePoints: made ? allianceBonus * alliancesMade : 0,
    wagerPoints: made ? wager : -wager,
  );
}
