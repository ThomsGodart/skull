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
