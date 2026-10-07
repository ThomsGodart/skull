import 'package:flutter/material.dart' hide Card;

import '../engine/engine.dart';
import '../theme/tokens.dart';
import '../ui/cards/card_view.dart';
import '../ui/rules_content.dart';
import '../ui/strings.dart';

/// The rules of the game, to read at any time, with the cards they speak of
/// drawn as they are on the table.
class RulesScreen extends StatelessWidget {
  const RulesScreen({super.key});

  static const _cardWidth = 44.0;
  static const _text = TextStyle(color: Tokens.text, height: 1.4);

  /// The lines of [body], each with the cards announced on the line before.
  static List<Widget> _lines(String body) {
    final widgets = <Widget>[];
    var cards = const <Card>[];
    for (final line in body.split('\n')) {
      if (line.startsWith(RulesContent.cardsMark)) {
        cards = [
          for (final id
              in line.substring(RulesContent.cardsMark.length).split(' '))
            Card.fromId(id),
        ];
      } else if (line.isEmpty) {
        widgets.add(const SizedBox(height: Tokens.space3));
      } else {
        widgets.add(_line(line, cards));
        cards = const [];
      }
    }
    return widgets;
  }

  static Widget _line(String text, List<Card> cards) {
    if (cards.isEmpty) return Text(text, style: _text);
    final drawn = Wrap(
      spacing: Tokens.space1,
      children: [
        for (final card in cards)
          CardView(card, width: _cardWidth, namedPirates: true),
      ],
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Tokens.space1),
      // One or two cards sit beside the sentence; more go above it.
      child: cards.length > 2
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                drawn,
                const SizedBox(height: Tokens.space2),
                Text(text, style: _text),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                drawn,
                const SizedBox(width: Tokens.space3),
                Expanded(child: Text(text, style: _text)),
              ],
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(Strings.rulesTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(Tokens.space4),
          children: [
            for (final section in RulesContent.sections) ...[
              Text(
                section.title,
                style: const TextStyle(
                  color: Tokens.gold,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: Tokens.space2),
              ..._lines(section.body),
              const SizedBox(height: Tokens.space6),
            ],
          ],
        ),
      ),
    );
  }
}
