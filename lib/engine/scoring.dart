import 'dart:math';

import 'trick.dart';

/// Rounds in a game before any tie-break.
const standardRounds = 10;

/// Size of the base deck, which bounds how many cards a round can deal.
const baseDeckSize = 70;

/// Cards each player receives in [round] (numbered from 1) with [players]
/// at the table. Tie-break rounds deal as many cards as round ten.
int cardsDealt({required int round, required int players}) =>
    min(min(round, standardRounds), baseDeckSize ~/ players);

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
