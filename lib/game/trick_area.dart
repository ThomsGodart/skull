import 'package:flutter/material.dart' hide Card;

import '../engine/engine.dart';
import '../theme/tokens.dart';
import '../ui/cards/card_view.dart';
import '../ui/strings.dart';
import 'seat_identity.dart';

/// The cards on the table, in play order, each under its player's name.
class TrickArea extends StatelessWidget {
  const TrickArea({
    super.key,
    required this.plays,
    required this.seats,
    this.winner,
    this.cardWidth = 54,
    this.namedPirates = false,
    this.overboard,
  });

  final List<Play> plays;
  final List<SeatIdentity> seats;

  /// The seat that takes the trick, once it is complete.
  final int? winner;
  final double cardWidth;
  final bool namedPirates;

  /// The pirate the plank threw out of the trick.
  final Card? overboard;

  /// The card that takes the trick: the winner may have played two, after
  /// a last salvo.
  Play? get _winning {
    if (winner == null) return null;
    final taking = resolveTrick(plays, overboard: overboard).winningPlay;
    return taking ?? plays.where((play) => play.seat == winner).firstOrNull;
  }

  @override
  Widget build(BuildContext context) {
    final winning = _winning;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: Tokens.space2,
      runSpacing: Tokens.space2,
      children: [
        for (final play in plays)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CardView(
                play.card,
                width: cardWidth,
                winning: play == winning,
                dimmed: play.card == overboard,
                namedPirates: namedPirates,
              ),
              const SizedBox(height: 2),
              Text(
                [
                  seats[play.seat].name,
                  if (play.tigressAs case final mode?) Strings.playedAs(mode),
                  if (play.declaredValue case final value?) '$value',
                  if (play.jokerSuit case final suit?) Strings.suitName(suit),
                  if (play.card == overboard) Strings.overboard,
                ].join(' · '),
                style: TextStyle(
                  color: play == winning ? Tokens.gold : Tokens.mutedText,
                  fontSize: 13,
                  fontWeight: play == winning
                      ? FontWeight.w800
                      : FontWeight.w500,
                ),
              ),
            ],
          ),
      ],
    );
  }
}
