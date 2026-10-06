import 'dart:math';

import 'package:flutter/material.dart';

import '../engine/engine.dart';
import '../game/game_controller.dart';
import '../game/table_screen.dart';
import '../theme/tokens.dart';
import '../ui/strings.dart';

/// Where a game is set up and started.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _minOpponents = 2;
  static const _maxOpponents = 7;

  int _opponents = 3;

  void _startGame({bool replace = false}) {
    final random = Random();
    final route = MaterialPageRoute<void>(
      builder: (context) => TableScreen(
        controller: GameController(
          config: GameConfig(
            players: _opponents + 1,
            seed: random.nextInt(1 << 32),
          ),
          bot: randomBot(random),
        ),
        onPlayAgain: () => _startGame(replace: true),
      ),
    );
    final navigator = Navigator.of(context);
    replace ? navigator.pushReplacement(route) : navigator.push(route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(Tokens.space6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('☠️', style: TextStyle(fontSize: 64)),
                const Text(
                  Strings.appTitle,
                  style: TextStyle(
                    color: Tokens.gold,
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Text(
                  Strings.tagline,
                  style: TextStyle(color: Tokens.mutedText),
                ),
                const SizedBox(height: Tokens.space6 * 2),
                const Text(
                  Strings.opponents,
                  style: TextStyle(color: Tokens.text),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: _opponents > _minOpponents
                          ? () => setState(() => _opponents--)
                          : null,
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    SizedBox(
                      width: 48,
                      child: Text(
                        '$_opponents',
                        key: const Key('opponents'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Tokens.text,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _opponents < _maxOpponents
                          ? () => setState(() => _opponents++)
                          : null,
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
                const SizedBox(height: Tokens.space6),
                FilledButton(
                  onPressed: _startGame,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: Tokens.space6),
                    child: Text(Strings.newGame),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
