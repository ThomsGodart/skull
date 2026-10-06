import 'dart:math';

import 'package:flutter/material.dart';

import '../bots/sensible_bot.dart';
import '../engine/engine.dart';
import '../game/game_controller.dart';
import '../game/game_saver.dart';
import '../game/seat_identity.dart';
import '../game/table_screen.dart';
import '../settings/app_settings.dart';
import '../setup/setup_screen.dart';
import '../storage/game_store.dart';
import '../theme/tokens.dart';
import '../ui/strings.dart';
import 'profile_dialog.dart';

/// The first screen: continue the game in progress, or start a new one.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.games, required this.settings});

  final GameStore games;
  final AppSettings settings;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// The game in progress, once looked up.
  SavedGame? _saved;

  /// What is still being written about the game last played.
  Future<void> _saving = Future.value();

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
    final saver = GameSaver(_games, game.id);
    _saving = saver.done;
    final route = MaterialPageRoute<void>(
      builder: (context) => TableScreen(
        human: _human,
        controller: GameController(
          config: game.config,
          bot: sensibleBot(),
          savedAnswers: game.answers,
          onProgress: (progress) {
            saver.record(progress);
            _saving = saver.done;
          },
        ),
        onPlayAgain: () => _start(game.config.players, replace: true),
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

  /// Creates a game for [players] and opens the table on it.
  Future<void> _start(int players, {bool replace = false}) async {
    final config = GameConfig(
      players: players,
      seed: Random().nextInt(1 << 32),
    );
    final id = await _games.create(config);
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
        onLaunch: (players) => _launchFromSetup(context, players),
      ),
    ),
  );

  Future<void> _launchFromSetup(BuildContext setupContext, int players) async {
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
    await _settings.setOpponents(players - 1);
    // The table takes the place of the setup screen.
    await _start(players, replace: true);
  }

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
                    onPressed: () => _play(saved),
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
                const SizedBox(height: Tokens.space6),
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
