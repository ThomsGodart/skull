import 'package:flutter/material.dart' hide Card;

import '../../engine/engine.dart';

/// How a card is drawn: its colour and its emblem.
///
/// An emblem is one character of the bundled pictogram font (see
/// `Pictogram`), written here by its code point so that no system emoji
/// variant sneaks in.
final class CardLook {
  const CardLook(this.color, this.emblem);

  final Color color;
  final String emblem;

  static CardLook of(Card card) => switch (card.kind) {
    CardKind.number => switch (card.suit!) {
      Suit.green => const CardLook(Color(0xFF2E8B57), '\u{1F99C}'),
      Suit.yellow => const CardLook(Color(0xFFB98600), '\u{1F4B0}'),
      Suit.purple => const CardLook(Color(0xFF7B4BC2), '\u{1F5FA}'),
      Suit.black => const CardLook(Color(0xFF1C1B22), '\u{2620}'),
    },
    CardKind.escape => const CardLook(Color(0xFF6C7A89), '\u{1F3F3}'),
    CardKind.pirate => const CardLook(Color(0xFFC0392B), '\u{2694}'),
    CardKind.tigress => const CardLook(Color(0xFFD9822B), '\u{1F42F}'),
    CardKind.skullKing => const CardLook(Color(0xFF7A1420), '\u{1F451}'),
    CardKind.mermaid => const CardLook(Color(0xFF16897C), '\u{1F9DC}'),
    CardKind.loot => const CardLook(Color(0xFF9A7B1F), '\u{1F48E}'),
    CardKind.kraken => const CardLook(Color(0xFF8E2A4F), '\u{1F419}'),
    CardKind.whiteWhale => const CardLook(Color(0xFF3F7FB5), '\u{1F433}'),
  };
}
