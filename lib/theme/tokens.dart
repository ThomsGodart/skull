import 'package:flutter/material.dart';

/// Colours, spacing and sizes shared by every screen.
abstract final class Tokens {
  static const sea = Color(0xFF0E1B2B);
  static const panel = Color(0xFF16283D);
  static const panelRaised = Color(0xFF1E3550);
  static const parchment = Color(0xFFF3E7CC);
  static const gold = Color(0xFFE0A93B);
  static const text = Color(0xFFF5EFE3);
  static const mutedText = Color(0xFF9FB0C3);
  static const danger = Color(0xFFE07466);
  static const scrim = Color(0xD90A1420);
  static const outline = Colors.white12;
  static const onAvatar = Colors.white;
  static const cardShadow = Colors.black45;

  /// The colours the player may pick for their own seat.
  static const playerColors = [
    gold,
    Color(0xFFE0605A),
    Color(0xFF3FB3A8),
    Color(0xFF9B7BE0),
    Color(0xFF6FBF5A),
  ];

  /// One colour per bot seat, in seat order.
  static const botColors = [
    Color(0xFF3F8EC4),
    Color(0xFFD9667B),
    Color(0xFF5FA36A),
    Color(0xFFC98A3A),
    Color(0xFF8A6FCB),
    Color(0xFF4FA7A0),
    Color(0xFFB7694A),
  ];

  static const space1 = 4.0;
  static const space2 = 8.0;
  static const space3 = 12.0;
  static const space4 = 16.0;
  static const space6 = 24.0;

  static const radiusButton = 12.0;
  static const radiusPanel = 18.0;

  /// Smallest comfortable touch target.
  static const tapTarget = 44.0;

  static ThemeData theme() {
    final scheme = ColorScheme.fromSeed(
      seedColor: gold,
      brightness: Brightness.dark,
      surface: sea,
      primary: gold,
    );
    return ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: sea,
      useMaterial3: true,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(tapTarget, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusButton),
          ),
        ),
      ),
    );
  }
}
