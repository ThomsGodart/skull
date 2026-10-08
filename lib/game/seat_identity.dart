import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import '../ui/strings.dart';

/// Who sits at a seat, as far as the screen is concerned.
final class SeatIdentity {
  const SeatIdentity(this.name, this.color, {this.isGhost = false});

  final String name;
  final Color color;

  /// Greybeard's ghost: it neither bids nor scores.
  final bool isGhost;

  String get initials => name.substring(0, name.length < 2 ? 1 : 2);

  /// [human] at [humanSeat] and bots at the others, for a table of [seats].
  /// With a [ghostSeat], that seat is the ghost's.
  static List<SeatIdentity> table(
    int seats, {
    required SeatIdentity human,
    int humanSeat = 0,
    int? ghostSeat,
  }) {
    var bots = 0;
    return [
      for (var seat = 0; seat < seats; seat++)
        if (seat == ghostSeat)
          const SeatIdentity(Strings.ghostName, Tokens.ghost, isGhost: true)
        else if (seat == humanSeat)
          human
        else
          SeatIdentity(
            Strings.botNames[bots % Strings.botNames.length],
            Tokens.botColors[bots++ % Tokens.botColors.length],
          ),
    ];
  }
}
