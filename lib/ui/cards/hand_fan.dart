import 'package:flutter/material.dart' hide Card;

import '../../engine/engine.dart';
import 'card_view.dart';

/// The human's hand: overlapping cards that fit the available width.
///
/// When [legal] is given, the other cards are dimmed and cannot be tapped.
/// The [selected] card is lifted.
class HandFan extends StatelessWidget {
  const HandFan({
    super.key,
    required this.cards,
    this.legal,
    this.selected,
    this.onTap,
    this.cardWidth = 64,
    this.reduceMotion = false,
  });

  final List<Card> cards;
  final List<Card>? legal;
  final Card? selected;
  final ValueChanged<Card>? onTap;
  final double cardWidth;

  /// Cards jump to their place instead of sliding, as the system setting
  /// does when it asks for less motion.
  final bool reduceMotion;

  static const _lift = 18.0;

  @override
  Widget build(BuildContext context) {
    final height = cardWidth * CardView.aspect + _lift + 4;
    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final count = cards.length;
          if (count == 0) return const SizedBox.shrink();
          final step = count == 1
              ? 0.0
              : ((constraints.maxWidth - cardWidth - 8) / (count - 1)).clamp(
                  16.0,
                  cardWidth + 6,
                );
          final total = cardWidth + step * (count - 1);
          final left = (constraints.maxWidth - total) / 2;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              for (final (index, card) in cards.indexed)
                AnimatedPositioned(
                  key: ValueKey(card.id),
                  duration:
                      reduceMotion || MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 120),
                  left: left + index * step,
                  top: card == selected ? 0 : _lift,
                  child: _tappable(card),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _tappable(Card card) {
    final playable = legal?.contains(card) ?? false;
    return GestureDetector(
      key: Key('hand-${card.id}'),
      onTap: playable && onTap != null ? () => onTap!(card) : null,
      child: CardView(
        card,
        width: cardWidth,
        dimmed: legal != null && !playable,
        selected: card == selected,
      ),
    );
  }
}
