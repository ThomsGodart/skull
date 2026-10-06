import 'package:flutter/material.dart' hide Card;

import '../../engine/engine.dart';
import '../../theme/tokens.dart';
import '../pictogram.dart';
import '../strings.dart';
import 'card_look.dart';

/// One face-up card. [width] drives the whole geometry.
class CardView extends StatelessWidget {
  const CardView(
    this.card, {
    super.key,
    this.width = 56,
    this.dimmed = false,
    this.selected = false,
    this.winning = false,
    this.namedPirates = false,
  });

  static const aspect = 1.45;

  final Card card;
  final double width;

  /// The card may not be played now.
  final bool dimmed;

  /// The card is lifted, one tap away from being played.
  final bool selected;

  /// The card takes the trick.
  final bool winning;

  /// Pirates go by their own name, as they do when their powers are in play.
  final bool namedPirates;

  @override
  Widget build(BuildContext context) {
    final look = CardLook.of(card);
    final highlighted = selected || winning;
    return Semantics(
      label: Strings.cardName(card, namedPirates: namedPirates),
      child: Opacity(
        opacity: dimmed ? 0.4 : 1,
        child: Container(
          width: width,
          height: width * aspect,
          decoration: BoxDecoration(
            color: Tokens.parchment,
            borderRadius: BorderRadius.circular(width * 0.13),
            border: Border.all(
              color: highlighted ? Tokens.gold : look.color,
              width: highlighted ? width * 0.07 : width * 0.04,
            ),
            boxShadow: [
              BoxShadow(
                color: highlighted
                    ? Tokens.gold.withValues(alpha: 0.6)
                    : Tokens.cardShadow,
                blurRadius: highlighted ? 10 : 3,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ExcludeSemantics(
            child: card.isNumber ? _number(look) : _special(look),
          ),
        ),
      ),
    );
  }

  Widget _number(CardLook look) {
    final value = Text(
      '${card.value}',
      style: TextStyle(
        color: look.color,
        fontSize: width * 0.32,
        fontWeight: FontWeight.w800,
        height: 1,
      ),
    );
    return Padding(
      padding: EdgeInsets.all(width * 0.07),
      child: Stack(
        children: [
          Align(alignment: Alignment.topLeft, child: value),
          Align(alignment: Alignment.bottomRight, child: value),
          Center(
            child: Pictogram(
              look.emblem,
              size: width * 0.42,
              color: look.color,
            ),
          ),
          if (card.suit == Suit.black)
            Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                Strings.trump,
                style: TextStyle(
                  color: look.color,
                  fontSize: width * 0.13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _special(CardLook look) => Padding(
    padding: EdgeInsets.all(width * 0.06),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Each part shrinks on its own: a long name must not shrink the
        // emblem, and nothing may overflow whatever the font.
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Pictogram(
              look.emblem,
              size: width * 0.46,
              color: look.color,
            ),
          ),
        ),
        SizedBox(height: width * 0.04),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            Strings.cardName(card, namedPirates: namedPirates),
            style: TextStyle(
              color: look.color,
              fontSize: width * 0.2,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );
}
