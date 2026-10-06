import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import '../ui/strings.dart';
import 'seat_identity.dart';

/// A player at the table: who they are, what they bid, how they are doing.
class SeatChip extends StatelessWidget {
  const SeatChip({
    super.key,
    required this.identity,
    required this.bid,
    required this.tricksWon,
    required this.score,
    this.cardsLeft,
    this.isCurrent = false,
    this.isDealer = false,
    this.dense = false,
  });

  final SeatIdentity identity;

  /// Null while bids are hidden.
  final int? bid;
  final int tricksWon;
  final int score;

  /// Shown for opponents, whose hand is not on screen.
  final int? cardsLeft;
  final bool isCurrent;
  final bool isDealer;

  /// A narrow tile, so that up to seven opponents fit above the table.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    if (dense) return _dense();
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Tokens.space2,
        vertical: Tokens.space1,
      ),
      decoration: BoxDecoration(
        color: Tokens.panel,
        borderRadius: BorderRadius.circular(Tokens.radiusButton),
        border: Border.all(
          color: isCurrent ? Tokens.gold : Tokens.outline,
          width: isCurrent ? 2 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: identity.color,
            child: Text(
              identity.initials,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Tokens.onAvatar,
              ),
            ),
          ),
          const SizedBox(width: Tokens.space2),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    identity.name,
                    style: const TextStyle(
                      color: Tokens.text,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (isDealer) ...[
                    const SizedBox(width: Tokens.space1),
                    Tooltip(
                      message: Strings.dealer,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: Tokens.gold,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          Strings.dealerMark,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: Tokens.sea,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: Tokens.space2),
                  Text(
                    '$score',
                    style: const TextStyle(color: Tokens.gold, fontSize: 12),
                  ),
                ],
              ),
              Text(
                [
                  Strings.bidAndTricks(bid, tricksWon),
                  if (cardsLeft != null) '🂠 $cardsLeft',
                ].join(' · '),
                style: const TextStyle(color: Tokens.mutedText, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dense() {
    Widget line(
      String text, {
      Color color = Tokens.mutedText,
      bool bold = false,
    }) => FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        text,
        maxLines: 1,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
        ),
      ),
    );
    return Container(
      padding: const EdgeInsets.all(Tokens.space1),
      decoration: BoxDecoration(
        color: Tokens.panel,
        borderRadius: BorderRadius.circular(Tokens.radiusButton),
        border: Border.all(
          color: isCurrent ? Tokens.gold : Tokens.outline,
          width: isCurrent ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 8,
                  backgroundColor: identity.color,
                  child: Text(
                    identity.initials,
                    style: const TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      color: Tokens.onAvatar,
                    ),
                  ),
                ),
                const SizedBox(width: Tokens.space1),
                Text(
                  identity.name,
                  style: TextStyle(
                    color: identity.color,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (isDealer)
                  const Text(
                    ' · ${Strings.dealerMark}',
                    style: TextStyle(
                      color: Tokens.gold,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
              ],
            ),
          ),
          line(Strings.bidAndTricks(bid, tricksWon), color: Tokens.text),
          line(
            [
              Strings.points(score),
              if (cardsLeft != null) Strings.cardsLeft(cardsLeft!),
            ].join(' · '),
          ),
        ],
      ),
    );
  }
}
