import 'package:flutter/material.dart';

import '../settings/app_settings.dart';
import '../storage/counter_store.dart';
import '../theme/tokens.dart';
import '../ui/strings.dart';
import 'counter_game.dart';
import 'counter_game_screen.dart';
import 'counter_setup_screen.dart';

/// The counter: resume the game being counted, start one, or look back at
/// the finished ones.
class CounterHomeScreen extends StatefulWidget {
  const CounterHomeScreen({
    super.key,
    required this.store,
    required this.settings,
  });

  final CounterStore store;
  final AppSettings settings;

  @override
  State<CounterHomeScreen> createState() => _CounterHomeScreenState();
}

class _CounterHomeScreenState extends State<CounterHomeScreen> {
  SavedCounterGame? _active;
  List<SavedCounterGame> _finished = const [];
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final active = await widget.store.loadActive();
      final finished = await widget.store.loadFinished();
      if (!mounted) return;
      setState(() {
        _active = active;
        _finished = finished;
        _failed = false;
      });
    } on Object {
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _open(SavedCounterGame saved, {bool replace = false}) async {
    final route = MaterialPageRoute<void>(
      builder: (context) =>
          CounterGameScreen(store: widget.store, saved: saved),
    );
    final navigator = Navigator.of(context);
    if (replace) {
      await navigator.pushReplacement(route);
    } else {
      await navigator.push(route);
    }
    await _load();
  }

  Future<bool> _confirmReplace(BuildContext context) async {
    if (_active == null) return true;
    final replace = await showDialog<bool>(
      context: context,
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
    return replace ?? false;
  }

  void _setUp() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (setupContext) => CounterSetupScreen(
        settings: widget.settings,
        onStart: (game) => _start(setupContext, game),
      ),
    ),
  );

  bool _starting = false;

  Future<void> _start(BuildContext setupContext, CounterGame game) async {
    if (_starting) return;
    _starting = true;
    try {
      if (!await _confirmReplace(setupContext)) return;
      final id = await widget.store.create(game);
      await widget.settings.rememberPlayers(game.players);
      if (!mounted) return;
      // The game takes the place of the setup screen.
      await _open(SavedCounterGame(id: id, game: game), replace: true);
    } finally {
      _starting = false;
    }
  }

  Future<void> _confirmDelete(SavedCounterGame saved) async {
    final delete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(Strings.deleteGameTitle),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(Strings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(Strings.delete),
          ),
        ],
      ),
    );
    if (!(delete ?? false)) return;
    await widget.store.delete(saved.id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final active = _active;
    return Scaffold(
      appBar: AppBar(title: const Text(Strings.counter)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(Tokens.space4),
          children: [
            const Text(
              Strings.counterIntro,
              textAlign: TextAlign.center,
              style: TextStyle(color: Tokens.mutedText),
            ),
            const SizedBox(height: Tokens.space4),
            if (_failed)
              const Text(
                Strings.loadFailed,
                textAlign: TextAlign.center,
                style: TextStyle(color: Tokens.danger),
              ),
            if (active != null) ...[
              FilledButton(
                key: const Key('counter-resume'),
                onPressed: () => _open(active),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(Strings.counterResume),
                    Text(
                      Strings.counterResumeSummary(
                        active.game.nextRound,
                        active.game.players.length,
                      ),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Tokens.space3),
              OutlinedButton(
                key: const Key('counter-new'),
                onPressed: _setUp,
                child: const Text(Strings.counterNew),
              ),
            ] else
              FilledButton(
                key: const Key('counter-new'),
                onPressed: _setUp,
                child: const Text(Strings.counterNew),
              ),
            if (_finished.isNotEmpty) ...[
              const SizedBox(height: Tokens.space6),
              const Text(
                Strings.counterFinished,
                style: TextStyle(
                  color: Tokens.text,
                  fontWeight: FontWeight.w800,
                ),
              ),
              for (final saved in _finished)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  onTap: () => _open(saved),
                  onLongPress: () => _confirmDelete(saved),
                  title: Text(switch (saved.game.winner) {
                    final winner? => Strings.wonBy(saved.game.players[winner]),
                    null => Strings.playersCount(saved.game.players.length),
                  }),
                  subtitle: Text(
                    [
                      if (saved.finishedAt case final date?)
                        Strings.dateTime(date),
                      saved.game.players.join(', '),
                    ].join(' · '),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
