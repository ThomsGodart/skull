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
    this.slideFromBelow,
    this.animate = false,
    this.onCardTap,
  });

  final List<Play> plays;
  final List<SeatIdentity> seats;

  /// The seat that takes the trick, once it is complete.
  final int? winner;
  final double cardWidth;
  final bool namedPirates;

  /// The pirate the plank threw out of the trick.
  final Card? overboard;

  /// The seat whose cards come up from the bottom of the screen, where its
  /// hand is; the others' come down from the top.
  final int? slideFromBelow;

  /// A card slides into place when it is put down.
  final bool animate;

  /// Called when a card in the trick is tapped, to show what it does.
  final ValueChanged<Play>? onCardTap;

  static const _slide = Duration(milliseconds: 260);

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
          _slideIn(
            play,
            GestureDetector(
              key: Key('trick-card-${play.card.id}'),
              onTap: onCardTap == null ? null : () => onCardTap!(play),
              child: Column(
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
                      if (play.tigressAs case final mode?)
                        Strings.playedAs(mode),
                      if (play.declaredValue case final value?) '$value',
                      if (play.jokerSuit case final suit?)
                        Strings.suitName(suit),
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
            ),
          ),
      ],
    );
  }

  /// [child], gliding in from where its player sits the first time it shows.
  /// Keyed by its card, so the cards already down stay put.
  Widget _slideIn(Play play, Widget child) {
    if (!animate) return child;
    final from = play.seat == slideFromBelow ? 1.0 : -1.0;
    return TweenAnimationBuilder<double>(
      key: ValueKey('slide-${play.card.id}'),
      tween: Tween(begin: 0, end: 1),
      duration: _slide,
      curve: Curves.easeOutCubic,
      builder: (context, progress, child) => Opacity(
        opacity: progress.clamp(0, 1),
        child: Transform.translate(
          offset: Offset(0, from * cardWidth * 1.2 * (1 - progress)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
