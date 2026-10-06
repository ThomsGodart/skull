import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import '../ui/strings.dart';
import 'seat_identity.dart';

/// A player at the table: who they are, what they bid, how many tricks they
/// took, and whether they deal or lead.
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
    this.leadsNext = false,
    this.emphasizeBid = false,
  });

  final SeatIdentity identity;

  /// Null while bids are hidden.
  final int? bid;
  final int tricksWon;
  final int score;

  /// Shown for opponents, whose hand is not on screen.
  final int? cardsLeft;

  /// It is this seat's turn to play.
  final bool isCurrent;
  final bool isDealer;

  /// This seat leads the trick about to be played.
  final bool leadsNext;

  /// The bids were just turned over: this one is shown off.
  final bool emphasizeBid;

  /// Gold on target, red once over the bid: a glance tells how a seat stands.
  Color get _tricksColor {
    final bid = this.bid;
    if (bid == null || identity.isGhost) return Tokens.text;
    if (tricksWon > bid) return Tokens.danger;
    return tricksWon == bid ? Tokens.gold : Tokens.text;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Tokens.space2,
        vertical: Tokens.space1 + 2,
      ),
      decoration: BoxDecoration(
        color: isCurrent ? Tokens.panelRaised : Tokens.panel,
        borderRadius: BorderRadius.circular(Tokens.radiusButton),
        border: Border.all(
          color: isCurrent ? Tokens.gold : Tokens.outline,
          width: isCurrent ? 2.5 : 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _fitted(
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 10,
                  backgroundColor: identity.color,
                  child: Text(
                    identity.initials,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Tokens.onAvatar,
                    ),
                  ),
                ),
                const SizedBox(width: Tokens.space1 + 2),
                Text(
                  identity.name,
                  style: TextStyle(
                    color: identity.color,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (isDealer) _badge(Strings.dealerMark, Strings.dealer),
                if (leadsNext) _badge(Strings.leadMark, Strings.leadsNext),
              ],
            ),
          ),
          const SizedBox(height: 2),
          _fitted(
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!identity.isGhost) ...[
                  _stat(
                    Strings.counterBid,
                    bid?.toString() ?? '?',
                    Tokens.text,
                    boxed: emphasizeBid,
                  ),
                  const SizedBox(width: Tokens.space3),
                ],
                _stat(Strings.counterTricks, '$tricksWon', _tricksColor),
              ],
            ),
          ),
          _fitted(
            Text(
              [
                identity.isGhost ? Strings.ghostLabel : Strings.points(score),
                if (cardsLeft != null) Strings.cardsLeft(cardsLeft!),
              ].join(' · '),
              style: const TextStyle(color: Tokens.mutedText, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _fitted(Widget child) =>
      FittedBox(fit: BoxFit.scaleDown, child: child);

  /// A label and the figure that goes with it, the figure large.
  static Widget _stat(
    String label,
    String value,
    Color color, {
    bool boxed = false,
  }) => Row(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Text(
        label,
        style: const TextStyle(color: Tokens.mutedText, fontSize: 13),
      ),
      const SizedBox(width: Tokens.space1),
      AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: boxed ? Tokens.gold : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          value,
          style: TextStyle(
            color: boxed ? Tokens.sea : color,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            height: 1.15,
          ),
        ),
      ),
    ],
  );

  static Widget _badge(String mark, String meaning) => Padding(
    padding: const EdgeInsets.only(left: Tokens.space1 + 2),
    child: Tooltip(
      message: meaning,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        decoration: BoxDecoration(
          color: Tokens.gold,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          mark,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: Tokens.sea,
          ),
        ),
      ),
    ),
  );
}
