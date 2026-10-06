import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import '../ui/strings.dart';

/// Who sits at a seat, as far as the screen is concerned.
final class SeatIdentity {
  const SeatIdentity(this.name, this.color);

  final String name;
  final Color color;

  String get initials => name.substring(0, name.length < 2 ? 1 : 2);

  /// [human] at seat 0, bots at the others.
  static List<SeatIdentity> table(int players, {required SeatIdentity human}) =>
      [
        human,
        for (var bot = 0; bot < players - 1; bot++)
          SeatIdentity(Strings.botNames[bot], Tokens.botColors[bot]),
      ];
}
