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
    this.wager,
    this.hasHarry = false,
    this.showTokens = false,
    this.scale = 1,
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

  /// What the seat staked with Rascal this round, once it did.
  final int? wager;

  /// The seat won a trick with Harry: it may move its bid at the end.
  final bool hasHarry;

  /// A token per trick bid, filled once taken: read at a glance.
  final bool showTokens;

  /// Everything in the chip is this many times its usual size.
  final double scale;

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
      padding: EdgeInsets.symmetric(
        horizontal: Tokens.space2 * scale,
        vertical: (Tokens.space1 + 2) * scale,
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
                  radius: 10 * scale,
                  backgroundColor: identity.color,
                  child: Text(
                    identity.initials,
                    style: TextStyle(
                      fontSize: 9 * scale,
                      fontWeight: FontWeight.w800,
                      color: Tokens.onAvatar,
                    ),
                  ),
                ),
                SizedBox(width: (Tokens.space1 + 2) * scale),
                Text(
                  identity.name,
                  style: TextStyle(
                    color: identity.color,
                    fontSize: 14 * scale,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (isDealer) _badge(Strings.dealerMark, Strings.dealer),
                if (leadsNext) _badge(Strings.leadMark, Strings.leadsNext),
              ],
            ),
          ),
          SizedBox(height: 2 * scale),
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
                  SizedBox(width: Tokens.space3 * scale),
                ],
                _stat(Strings.counterTricks, '$tricksWon', _tricksColor),
              ],
            ),
          ),
          if (showTokens && bid != null && !identity.isGhost) _tokens(bid!),
          if (wager != null || hasHarry)
            _fitted(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (wager case final amount?)
                    _badge(
                      Strings.wagerBadge(amount),
                      Strings.wagerBadgeHelp(amount),
                    ),
                  if (hasHarry)
                    _badge(Strings.harryBadge, Strings.harryBadgeHelp),
                ],
              ),
            ),
          _fitted(
            Text(
              [
                identity.isGhost ? Strings.ghostLabel : Strings.points(score),
                if (cardsLeft != null) Strings.cardsLeft(cardsLeft!),
              ].join(' · '),
              style: TextStyle(color: Tokens.mutedText, fontSize: 12 * scale),
            ),
          ),
        ],
      ),
    );
  }

  /// One token per trick bid: full when taken, hollow while still to take.
  /// Tricks beyond the bid are red.
  Widget _tokens(int bid) {
    final count = tricksWon > bid ? tricksWon : bid;
    if (count == 0) return const SizedBox.shrink();
    return Padding(
      key: const Key('trick-tokens'),
      padding: EdgeInsets.symmetric(vertical: 2 * scale),
      child: _fitted(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var index = 0; index < count; index++)
              Container(
                width: 14 * scale,
                height: 14 * scale,
                margin: EdgeInsets.symmetric(horizontal: 1.5 * scale),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index >= bid
                      ? Tokens.danger
                      : (index < tricksWon ? Tokens.gold : Colors.transparent),
                  border: Border.all(
                    color: index >= bid ? Tokens.danger : Tokens.gold,
                    width: 1.5 * scale,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static Widget _fitted(Widget child) =>
      FittedBox(fit: BoxFit.scaleDown, child: child);

  /// A label and the figure that goes with it, the figure large.
  Widget _stat(String label, String value, Color color, {bool boxed = false}) =>
      Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(color: Tokens.mutedText, fontSize: 13 * scale),
          ),
          SizedBox(width: Tokens.space1 * scale),
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: EdgeInsets.symmetric(horizontal: 6 * scale),
            decoration: BoxDecoration(
              color: boxed ? Tokens.gold : Colors.transparent,
              borderRadius: BorderRadius.circular(8 * scale),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: boxed ? Tokens.sea : color,
                fontSize: 24 * scale,
                fontWeight: FontWeight.w900,
                height: 1.15,
              ),
            ),
          ),
        ],
      );

  Widget _badge(String mark, String meaning) => Padding(
    padding: EdgeInsets.only(left: (Tokens.space1 + 2) * scale),
    child: Tooltip(
      message: meaning,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 5 * scale, vertical: scale),
        decoration: BoxDecoration(
          color: Tokens.gold,
          borderRadius: BorderRadius.circular(6 * scale),
        ),
        child: Text(
          mark,
          style: TextStyle(
            fontSize: 10 * scale,
            fontWeight: FontWeight.w900,
            color: Tokens.sea,
          ),
        ),
      ),
    ),
  );
}
