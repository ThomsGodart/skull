import 'package:flutter/foundation.dart';

import '../storage/settings_store.dart';
import '../theme/tokens.dart';
import '../ui/strings.dart';

/// What the player has chosen, kept from one launch to the next.
class AppSettings extends ChangeNotifier {
  AppSettings._(this._store);

  static const defaultPlayerName = Strings.you;
  static const maxNameLength = 12;
  static const minOpponents = 2;
  static const maxOpponents = 7;

  static Future<AppSettings> load(SettingsStore store) async {
    final values = await store.readAll();
    final settings = AppSettings._(store);
    settings._playerName = _cleanName(values['playerName'] ?? '');
    final color = int.tryParse(values['playerColor'] ?? '');
    if (color != null && color >= 0 && color < Tokens.playerColors.length) {
      settings._playerColor = color;
    }
    final opponents = int.tryParse(values['opponents'] ?? '');
    if (opponents != null) settings._opponents = _clampOpponents(opponents);
    return settings;
  }

  final SettingsStore _store;
  String _playerName = defaultPlayerName;
  int _playerColor = 0;
  int _opponents = 3;

  /// The name shown at the human's seat.
  String get playerName => _playerName;

  /// An index into [Tokens.playerColors].
  int get playerColor => _playerColor;

  /// How many bots the last game was set up with.
  int get opponents => _opponents;

  Future<void> setPlayer({required String name, required int color}) async {
    _playerName = _cleanName(name);
    _playerColor = color;
    notifyListeners();
    await _store.write('playerName', _playerName);
    await _store.write('playerColor', '$color');
  }

  Future<void> setOpponents(int opponents) async {
    _opponents = _clampOpponents(opponents);
    notifyListeners();
    await _store.write('opponents', '$_opponents');
  }

  static int _clampOpponents(int opponents) =>
      opponents.clamp(minOpponents, maxOpponents);

  static String _cleanName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return defaultPlayerName;
    return trimmed.length <= maxNameLength
        ? trimmed
        : trimmed.substring(0, maxNameLength);
  }
}
