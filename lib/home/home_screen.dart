import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../bots/bot_level.dart';
import '../counter/counter_home_screen.dart';
import '../engine/engine.dart';
import '../game/game_controller.dart';
import '../game/game_saver.dart';
import '../game/seat_identity.dart';
import '../game/table_screen.dart';
import '../history/history_screen.dart';
import '../rules/rules_screen.dart';
import '../settings/app_settings.dart';
import '../settings/settings_screen.dart';
import '../setup/setup_screen.dart';
import '../stats/stats_screen.dart';
import '../storage/counter_store.dart';
import '../storage/game_store.dart';
import '../theme/tokens.dart';
import '../ui/strings.dart';
import '../settings/profile_dialog.dart';

/// The first screen: continue the game in progress, or start a new one.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.games,
    required this.counters,
    required this.settings,
  });

  final GameStore games;
  final CounterStore counters;
  final AppSettings settings;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// The game in progress, once looked up.
  SavedGame? _saved;

  /// What is still being written about the game last played.
  Future<void> _saving = Future.value();

  /// True while a game is being created, so a second tap starts nothing.
  bool _starting = false;

  GameStore get _games => widget.games;
  AppSettings get _settings => widget.settings;

  @override
  void initState() {
    super.initState();
    _settings.addListener(_onSettingsChanged);
    _refresh();
  }

  @override
  void dispose() {
    _settings.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() => setState(() {});

  Future<void> _refresh() async {
    await _saving;
    final saved = await _games.loadActive();
    if (mounted) setState(() => _saved = saved);
  }

  SeatIdentity get _human => SeatIdentity(
    _settings.playerName,
    Tokens.playerColors[_settings.playerColor],
  );

  /// Opens the table on [game] and comes back here when it is left.
  Future<void> _play(SavedGame game, {bool replace = false}) async {
    final messenger = ScaffoldMessenger.of(context);
    final saver = GameSaver(
      _games,
      game.id,
      playerName: _settings.playerName,
      onError: (_) => messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text(Strings.saveFailed))),
    );
    _saving = saver.done;
    final route = MaterialPageRoute<void>(
      builder: (context) => TableScreen(
        human: _human,
        settings: _settings,
        controller: GameController(
          config: game.config,
          bot: botFor(_settings.botLevel, Random()),
          speed: _settings.botSpeed.table,
          savedAnswers: game.answers,
          onProgress: (progress) {
            saver.record(progress);
            _saving = saver.done;
          },
        ),
        onPlayAgain: () => _start(game.config, replace: true),
      ),
    );
    final navigator = Navigator.of(context);
    if (replace) {
      await navigator.pushReplacement(route);
    } else {
      await navigator.push(route);
    }
    await _refresh();
  }

  /// Opens the table on the game in progress, as it is kept right now.
  Future<void> _continue() async {
    await _saving;
    final saved = await _games.loadActive();
    if (!mounted) return;
    if (saved == null) {
      setState(() => _saved = null);
      return;
    }
    await _play(saved);
  }

  /// Creates a game played as [setup] and opens the table on it.
  Future<void> _start(GameConfig setup, {bool replace = false}) async {
    if (_starting) return;
    _starting = true;
    // Creating a game drops the one in progress: the game just finished must
    // have been filed first.
    await _saving;
    if (!mounted) {
      _starting = false;
      return;
    }
    final config = setup.copyWith(seed: Random().nextInt(1 << 32));
    final messenger = ScaffoldMessenger.of(context);
    final int id;
    try {
      id = await _games.create(config);
    } on Object {
      messenger.showSnackBar(
        const SnackBar(content: Text(Strings.cannotStart)),
      );
      return;
    } finally {
      _starting = false;
    }
    if (!mounted) return;
    await _play(
      SavedGame(
        id: id,
        config: config,
        answers: const [],
        round: 1,
        humanScore: 0,
      ),
      replace: replace,
    );
  }

  void _openSetup() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (context) => SetupScreen(
        settings: _settings,
        onLaunch: (setup) => _launchFromSetup(context, setup),
      ),
    ),
  );

  Future<void> _launchFromSetup(
    BuildContext setupContext,
    GameConfig setup,
  ) async {
    if (_launching) return;
    _launching = true;
    try {
      await _confirmAndStart(setupContext, setup);
    } finally {
      _launching = false;
    }
  }

  bool _launching = false;

  Future<void> _confirmAndStart(
    BuildContext setupContext,
    GameConfig setup,
  ) async {
    await _saving;
    if (await _games.loadActive() != null) {
      if (!setupContext.mounted) return;
      final replace = await showDialog<bool>(
        context: setupContext,
        builder: (context) => AlertDialog(
          title: const Text(Strings.replaceGameTitle),
          content: const Text(Strings.replaceGameBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(Strings.keepGame),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(Strings.replaceGame),
            ),
          ],
        ),
      );
      if (!(replace ?? false)) return;
    }
    // Remembering the choice must never stand in the way of the game.
    unawaited(_settings.setLastSetup(setup).catchError((Object _) {}));
    // The table takes the place of the setup screen.
    await _start(setup, replace: true);
  }

  /// A secondary screen reached from the home.
  Widget _entry(String label, WidgetBuilder screen) => TextButton(
    onPressed: () =>
        Navigator.of(context).push(MaterialPageRoute<void>(builder: screen)),
    child: Text(label),
  );

  @override
  Widget build(BuildContext context) {
    final saved = _saved;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Tokens.space6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  Strings.homeEmblem,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 64),
                ),
                const Text(
                  Strings.appTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Tokens.gold,
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Text(
                  Strings.tagline,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Tokens.mutedText),
                ),
                const SizedBox(height: Tokens.space6 * 2),
                if (saved != null) ...[
                  FilledButton(
                    onPressed: _continue,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(Strings.continueGame),
                        Text(
                          Strings.savedGameSummary(
                            saved.round,
                            saved.humanScore,
                          ),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Tokens.space3),
                  OutlinedButton(
                    onPressed: _openSetup,
                    child: const Text(Strings.newGame),
                  ),
                ] else
                  FilledButton(
                    onPressed: _openSetup,
                    child: const Text(Strings.newGame),
                  ),
                const SizedBox(height: Tokens.space4),
                Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    _entry(
                      Strings.counter,
                      (context) => CounterHomeScreen(
                        store: widget.counters,
                        settings: _settings,
                      ),
                    ),
                    _entry(
                      Strings.history,
                      (context) => HistoryScreen(games: _games, human: _human),
                    ),
                    _entry(
                      Strings.statistics,
                      (context) => StatsScreen(games: _games),
                    ),
                    _entry(Strings.rules, (context) => const RulesScreen()),
                    _entry(
                      Strings.settings,
                      (context) => SettingsScreen(settings: _settings),
                    ),
                  ],
                ),
                TextButton.icon(
                  key: const Key('edit-profile'),
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (context) => ProfileDialog(settings: _settings),
                  ),
                  icon: CircleAvatar(radius: 10, backgroundColor: _human.color),
                  label: Text(_human.name),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
