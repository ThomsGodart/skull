import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../bots/bot_level.dart';
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
  static const _onlineIdKey = 'onlineId';
  static const _knownPlayersKey = 'counterPlayers';
  static const _botSpeedKey = 'botSpeed';
  static const _botLevelKey = 'botLevel';
  static const _activeLevelKey = 'activeGameBotLevel';
  static const _singleTapKey = 'singleTapPlay';
  static const _hapticsKey = 'haptics';
  static const _reduceMotionKey = 'reduceMotion';
  static const _autoHarryKey = 'autoHarry';
  static const _trickTokensKey = 'trickTokens';
  static const _cardEffectsKey = 'cardEffects';

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
    settings._onlineId = values[_onlineIdKey];
    settings._botSpeed =
        BotSpeed.values.asNameMap()[values[_botSpeedKey]] ?? BotSpeed.normal;
    settings._botLevel =
        BotLevel.values.asNameMap()[values[_botLevelKey]] ?? BotLevel.normal;
    settings._activeGameBotLevel =
        BotLevel.values.asNameMap()[values[_activeLevelKey]] ??
        settings._botLevel;
    settings._singleTapPlay = values[_singleTapKey] == 'true';
    settings._haptics = values[_hapticsKey] != 'false';
    settings._reduceMotion = values[_reduceMotionKey] == 'true';
    settings._autoHarry = values[_autoHarryKey] == 'true';
    settings._trickTokens = values[_trickTokensKey] == 'true';
    settings._cardEffects = values[_cardEffectsKey] != 'false';
    return settings;
  }

  final SettingsStore _store;
  String _playerName = defaultPlayerName;
  int _playerColor = 0;
  int _opponents = 3;
  GameConfig _lastSetup = const GameConfig(players: 4, seed: 0);
  List<String> _knownPlayers = const [];
  String? _onlineId;
  BotSpeed _botSpeed = BotSpeed.normal;
  BotLevel _botLevel = BotLevel.normal;
  BotLevel _activeGameBotLevel = BotLevel.normal;
  bool _singleTapPlay = false;
  bool _haptics = true;
  bool _reduceMotion = false;
  bool _autoHarry = false;
  bool _trickTokens = false;
  bool _cardEffects = true;

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

  /// What this phone is known as in online rooms: drawn once, then kept, so
  /// that a player who reconnects is recognised.
  Future<String> onlineId(Random random) async {
    final known = _onlineId;
    if (known != null) return known;
    const alphabet = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final id = [
      for (var i = 0; i < 16; i++) alphabet[random.nextInt(alphabet.length)],
    ].join();
    _onlineId = id;
    await _changed(_onlineIdKey, id);
    return id;
  }

  BotSpeed get botSpeed => _botSpeed;

  /// The level offered for the next game: the one last launched.
  BotLevel get botLevel => _botLevel;

  /// The level of the bots in the game in progress. It is fixed when the
  /// game is launched, and stays whatever is chosen for a later one.
  BotLevel get activeGameBotLevel => _activeGameBotLevel;

  /// Records that a game was launched against bots of [level].
  Future<void> setLaunchedBotLevel(BotLevel level) async {
    _botLevel = level;
    _activeGameBotLevel = level;
    await _changed(_botLevelKey, level.name);
    await _store.write(_activeLevelKey, level.name);
  }

  /// A card is played by one tap instead of two.
  bool get singleTapPlay => _singleTapPlay;

  /// The phone vibrates lightly when a card is picked or played.
  bool get haptics => _haptics;

  /// Cards move without animation, whatever the system setting says.
  bool get reduceMotion => _reduceMotion;

  /// Harry's power is used without asking: the bid moves towards the tricks
  /// taken, as far as it may.
  bool get autoHarry => _autoHarry;

  /// Each seat shows a token per trick bid, filled once taken.
  bool get trickTokens => _trickTokens;

  /// A lifted card tells what it does. Without it, only the button that
  /// plays the card shows.
  bool get cardEffects => _cardEffects;

  Future<void> setCardEffects(bool value) {
    _cardEffects = value;
    return _changed(_cardEffectsKey, '$value');
  }

  Future<void> setAutoHarry(bool value) {
    _autoHarry = value;
    return _changed(_autoHarryKey, '$value');
  }

  Future<void> setTrickTokens(bool value) {
    _trickTokens = value;
    return _changed(_trickTokensKey, '$value');
  }

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
