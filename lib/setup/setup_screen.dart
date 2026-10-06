import 'package:flutter/material.dart';

import '../engine/engine.dart';
import '../settings/app_settings.dart';
import '../theme/tokens.dart';
import '../ui/strings.dart';

/// Where a new game is set up. Calls [onLaunch] with the number of players.
class SetupScreen extends StatefulWidget {
  const SetupScreen({
    super.key,
    required this.settings,
    required this.onLaunch,
  });

  final AppSettings settings;
  final ValueChanged<int> onLaunch;

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  late int _opponents = widget.settings.opponents;

  static int _lastRoundCards(int players) =>
      cardsDealt(round: standardRounds, players: players);

  @override
  Widget build(BuildContext context) {
    final players = _opponents + 1;
    return Scaffold(
      appBar: AppBar(title: const Text(Strings.setupTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Tokens.space6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                Strings.opponents,
                textAlign: TextAlign.center,
                style: TextStyle(color: Tokens.text),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _opponents > AppSettings.minOpponents
                        ? () => setState(() => _opponents--)
                        : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  SizedBox(
                    width: Tokens.tapTarget,
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
                    onPressed: _opponents < AppSettings.maxOpponents
                        ? () => setState(() => _opponents++)
                        : null,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
              const SizedBox(height: Tokens.space4),
              Text(
                Strings.setupSummary(players),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Tokens.mutedText),
              ),
              if (_lastRoundCards(players) < standardRounds) ...[
                const SizedBox(height: Tokens.space2),
                Text(
                  Strings.fewerCardsNote(players, _lastRoundCards(players)),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Tokens.mutedText),
                ),
              ],
              const Spacer(),
              FilledButton(
                key: const Key('launch'),
                onPressed: () => widget.onLaunch(players),
                child: const Text(Strings.launch),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
