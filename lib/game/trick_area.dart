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
  });

  final List<Play> plays;
  final List<SeatIdentity> seats;

  /// The seat that takes the trick, once it is complete.
  final int? winner;
  final double cardWidth;

  @override
  Widget build(BuildContext context) {
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
                winning: play.seat == winner,
              ),
              const SizedBox(height: 2),
              Text(
                [
                  seats[play.seat].name,
                  if (play.tigressAs case final mode?) Strings.playedAs(mode),
                ].join(' · '),
                style: TextStyle(
                  color: play.seat == winner ? Tokens.gold : Tokens.mutedText,
                  fontSize: 11,
                  fontWeight: play.seat == winner
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
