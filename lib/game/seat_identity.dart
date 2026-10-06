import 'package:flutter/material.dart';

import '../ui/strings.dart';

/// Who sits at a seat, as far as the screen is concerned.
final class SeatIdentity {
  const SeatIdentity(this.name, this.color);

  final String name;
  final Color color;

  String get initials => name.substring(0, name.length < 2 ? 1 : 2);

  static const _bots = [
    SeatIdentity('Mako', Color(0xFF3F8EC4)),
    SeatIdentity('Corail', Color(0xFFD9667B)),
    SeatIdentity('Bosco', Color(0xFF5FA36A)),
    SeatIdentity('Sloop', Color(0xFFC98A3A)),
    SeatIdentity('Récif', Color(0xFF8A6FCB)),
    SeatIdentity('Ancre', Color(0xFF4FA7A0)),
    SeatIdentity('Rafale', Color(0xFFB7694A)),
  ];

  /// The human at seat 0, bots at the others.
  static List<SeatIdentity> table(int players) => [
    const SeatIdentity(Strings.you, Color(0xFFE0A93B)),
    ..._bots.take(players - 1),
  ];
}
