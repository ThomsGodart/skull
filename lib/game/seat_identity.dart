import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import '../ui/player_icons.dart';
import '../ui/strings.dart';

/// Who sits at a seat, as far as the screen is concerned.
final class SeatIdentity {
  const SeatIdentity(this.name, this.color, {this.icon, this.isGhost = false});

  final String name;
  final Color color;

  /// The emblem shown beside the name, a glyph of the bundled font. Without
  /// one, the first letters of the name stand in.
  final String? icon;

  /// Greybeard's ghost: it neither bids nor scores.
  final bool isGhost;

  String get initials => name.substring(0, name.length < 2 ? 1 : 2);

  /// [human] at [humanSeat] and bots at the others, for a table of [seats].
  /// With a [ghostSeat], that seat is the ghost's. Bot names are drawn at
  /// random from the pool so the same few names do not always appear.
  static List<SeatIdentity> table(
    int seats, {
    required SeatIdentity human,
    int humanSeat = 0,
    int? ghostSeat,
    Random? random,
  }) {
    final botCount = seats - 1 - (ghostSeat != null ? 1 : 0);
    final names = Strings.shuffledBotNames(botCount, random);
    final icons = botIcons(botCount, random);
    var bots = 0;
    return [
      for (var seat = 0; seat < seats; seat++)
        if (seat == ghostSeat)
          ghost
        else if (seat == humanSeat)
          human
        else
          SeatIdentity(
            names[bots],
            Tokens.botColors[bots % Tokens.botColors.length],
            icon: icons[bots++],
          ),
    ];
  }

  /// Greybeard's ghost, as it sits at any table of two.
  static const ghost = SeatIdentity(
    Strings.ghostName,
    Tokens.ghost,
    icon: PlayerIcons.ghost,
    isGhost: true,
  );

  /// An emblem for each of [count] bots, no two alike while there are
  /// enough to go round.
  static List<String> botIcons(int count, [Random? random]) {
    final glyphs = List<String>.of(PlayerIcons.glyphs)
      ..shuffle(random ?? Random());
    return [for (var bot = 0; bot < count; bot++) glyphs[bot % glyphs.length]];
  }
}
