import 'package:flutter/material.dart' hide Card;

import '../../engine/engine.dart';

/// How a card is drawn: its colour and its emblem.
///
/// The emblems are emoji for now. They render differently from one phone to
/// the next; real pictograms replace them here without touching the rest.
final class CardLook {
  const CardLook(this.color, this.emblem);

  final Color color;
  final String emblem;

  static CardLook of(Card card) => switch (card.kind) {
    CardKind.number => switch (card.suit!) {
      Suit.green => const CardLook(Color(0xFF2E8B57), '🦜'),
      Suit.yellow => const CardLook(Color(0xFFB98600), '💰'),
      Suit.purple => const CardLook(Color(0xFF7B4BC2), '🗺️'),
      Suit.black => const CardLook(Color(0xFF1C1B22), '☠️'),
    },
    CardKind.escape => const CardLook(Color(0xFF6C7A89), '🏳️'),
    CardKind.pirate => const CardLook(Color(0xFFC0392B), '⚔️'),
    CardKind.tigress => const CardLook(Color(0xFFD9822B), '🐯'),
    CardKind.skullKing => const CardLook(Color(0xFF7A1420), '👑'),
    CardKind.mermaid => const CardLook(Color(0xFF16897C), '🧜‍♀️'),
  };
}
