import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'pictogram.dart';

/// The pirate emblems a player may sit under, drawn from the bundled font.
abstract final class PlayerIcons {
  /// Skull, anchor, parrot, dagger, treasure, compass, octopus, shark,
  /// ship and bomb. A player's choice is an index into this list.
  static const glyphs = [
    '☠',
    '⚓',
    '\u{1F99C}',
    '\u{1F5E1}',
    '\u{1F4B0}',
    '\u{1F9ED}',
    '\u{1F419}',
    '\u{1F988}',
    '⛵',
    '\u{1F4A3}',
  ];

  /// The emblem of Greybeard's ghost.
  static const ghost = '\u{1F47B}';

  /// The emblem at [index], whatever a phone of another version sent.
  static String glyph(int index) => glyphs[index % glyphs.length];
}

/// A player's emblem on a disc of their colour.
class PlayerAvatar extends StatelessWidget {
  const PlayerAvatar({
    super.key,
    required this.color,
    required this.glyph,
    this.radius = 14,
  });

  final Color color;
  final String glyph;
  final double radius;

  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: radius,
    backgroundColor: color,
    child: Pictogram(glyph, size: radius * 1.25, color: Tokens.sea),
  );
}
