import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../engine/engine.dart';
import '../storage/settings_store.dart';
import '../theme/tokens.dart';
import '../ui/strings.dart';

/// How fast the bots play.
enum BotSpeed { normal, fast, instant }

/// What the player has chosen, kept from one launch to the next.
class AppSettings extends ChangeNotifier {
  AppSettings._(this._store);

  static const defaultPlayerName = Strings.you;
  static const maxNameLength = 12;
  static const minOpponents = minPlayers - 1;
  static const maxOpponents = maxPlayers - 1;

  static const _nameKey = 'playerName';
  static const _colorKey = 'playerColor';
  static const _opponentsKey = 'opponents';
  static const _setupKey = 'lastSetup';
  static const _knownPlayersKey = 'counterPlayers';
  static const _botSpeedKey = 'botSpeed';
  static const _singleTapKey = 'singleTapPlay';
  static const _hapticsKey = 'haptics';
  static const _reduceMotionKey = 'reduceMotion';

  static Future<AppSettings> load(SettingsStore store) async {
    final values = await store.readAll();
    final settings = AppSettings._(store);
    settings._playerName = _cleanName(values[_nameKey] ?? '');
    final color = int.tryParse(values[_colorKey] ?? '');
    if (color != null && _isColor(color)) settings._playerColor = color;
    final opponents = int.tryParse(values[_opponentsKey] ?? '');
    if (opponents != null) settings._opponents = _clampOpponents(opponents);
    try {
      final setup = GameConfig.fromJson(
        jsonDecode(values[_setupKey] ?? '') as Map<String, Object?>,
      );
      settings._lastSetup = setup.copyWith(
        players: _clampOpponents(setup.players - 1) + 1,
      );
    } on Object {
      // Never set, or no longer readable: the opponents alone are kept.
      settings._lastSetup = GameConfig(
        players: settings._opponents + 1,
        seed: 0,
      );
    }
    try {
      settings._knownPlayers =
          (jsonDecode(values[_knownPlayersKey] ?? '[]') as List).cast<String>();
    } on Object {
      settings._knownPlayers = const [];
    }
    settings._botSpeed =
        BotSpeed.values.asNameMap()[values[_botSpeedKey]] ?? BotSpeed.normal;
    settings._singleTapPlay = values[_singleTapKey] == 'true';
    settings._haptics = values[_hapticsKey] != 'false';
    settings._reduceMotion = values[_reduceMotionKey] == 'true';
    return settings;
  }

  final SettingsStore _store;
  String _playerName = defaultPlayerName;
  int _playerColor = 0;
  int _opponents = 3;
  GameConfig _lastSetup = const GameConfig(players: 4, seed: 0);
  List<String> _knownPlayers = const [];
  BotSpeed _botSpeed = BotSpeed.normal;
  bool _singleTapPlay = false;
  bool _haptics = true;
  bool _reduceMotion = false;

  /// The name shown at the human's seat.
  String get playerName => _playerName;

  /// An index into [Tokens.playerColors].
  int get playerColor => _playerColor;

  /// How many bots the last game was set up with.
  int get opponents => _lastSetup.players - 1;

  /// What the last game was set up with, offered again for the next one.
  /// Its seed means nothing.
  GameConfig get lastSetup => _lastSetup;

  Future<void> setLastSetup(GameConfig setup) async {
    _lastSetup = setup.copyWith(
      players: _clampOpponents(setup.players - 1) + 1,
      seed: 0,
    );
    _opponents = _lastSetup.players - 1;
    await _changed(_setupKey, jsonEncode(_lastSetup.toJson()));
    await _store.write(_opponentsKey, '$_opponents');
  }

  /// Names already used in counted games, the latest first, offered again.
  List<String> get knownPlayers => _knownPlayers;

  /// Puts [names] at the front of [knownPlayers].
  Future<void> rememberPlayers(List<String> names) {
    _knownPlayers = {...names, ..._knownPlayers}.take(20).toList();
    return _changed(_knownPlayersKey, jsonEncode(_knownPlayers));
  }

  BotSpeed get botSpeed => _botSpeed;

  /// A card is played by one tap instead of two.
  bool get singleTapPlay => _singleTapPlay;

  /// The phone vibrates lightly when a card is picked or played.
  bool get haptics => _haptics;

  /// Cards move without animation, whatever the system setting says.
  bool get reduceMotion => _reduceMotion;

  Future<void> setBotSpeed(BotSpeed speed) {
    _botSpeed = speed;
    return _changed(_botSpeedKey, speed.name);
  }

  Future<void> setSingleTapPlay(bool value) {
    _singleTapPlay = value;
    return _changed(_singleTapKey, '$value');
  }

  Future<void> setHaptics(bool value) {
    _haptics = value;
    return _changed(_hapticsKey, '$value');
  }

  Future<void> setReduceMotion(bool value) {
    _reduceMotion = value;
    return _changed(_reduceMotionKey, '$value');
  }

  Future<void> _changed(String key, String value) async {
    notifyListeners();
    try {
      await _store.write(key, value);
    } on Object {
      // The choice still applies until the app is closed.
    }
  }

  Future<void> setPlayer({required String name, required int color}) async {
    _playerName = _cleanName(name);
    if (_isColor(color)) _playerColor = color;
    notifyListeners();
    await _store.write(_nameKey, _playerName);
    await _store.write(_colorKey, '$_playerColor');
  }

  Future<void> setOpponents(int opponents) =>
      setLastSetup(_lastSetup.copyWith(players: opponents + 1));

  static bool _isColor(int color) =>
      color >= 0 && color < Tokens.playerColors.length;

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
