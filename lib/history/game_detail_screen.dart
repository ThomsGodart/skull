import 'package:flutter/material.dart';

import '../engine/engine.dart';
import '../game/score_views.dart';
import '../game/seat_identity.dart';
import '../storage/game_store.dart';
import '../theme/tokens.dart';
import '../ui/strings.dart';
import '../storage/finished_game.dart';

/// The standings and the full score sheet of a finished game.
class GameDetailScreen extends StatefulWidget {
  const GameDetailScreen({
    super.key,
    required this.games,
    required this.game,
    required this.seats,
  });

  final GameStore games;
  final FinishedGame game;
  final List<SeatIdentity> seats;

  @override
  State<GameDetailScreen> createState() => _GameDetailScreenState();
}

class _GameDetailScreenState extends State<GameDetailScreen> {
  /// The rounds of the game, replayed from what was kept. Empty when the
  /// game can no longer be replayed.
  late final Future<List<RoundScored>> _rounds = _replay();

  Future<List<RoundScored>> _replay() async {
    final kept = await widget.games.loadGame(widget.game.id);
    if (kept == null) return const [];
    try {
      final game = Game.replay(kept.config, kept.answers);
      return game.takeEvents().whereType<RoundScored>().toList();
    } on Object {
      return const [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    return Scaffold(
      appBar: AppBar(title: const Text(Strings.gameDetailTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(Tokens.space4),
          children: [
            Text(
              Strings.dateTime(game.finishedAt),
              style: const TextStyle(color: Tokens.mutedText),
            ),
            Text(
              Strings.gameSetup(game.players),
              style: const TextStyle(color: Tokens.mutedText),
            ),
            const SizedBox(height: Tokens.space4),
            Standings(scores: game.scores, seats: widget.seats),
            const SizedBox(height: Tokens.space6),
            FutureBuilder(
              future: _rounds,
              builder: (context, snapshot) {
                final rounds = snapshot.data;
                if (rounds == null) return const SizedBox.shrink();
                // A replay that does not match the stored result is no detail.
                final seats = rounds.firstOrNull?.results.length;
                if (seats != widget.seats.length) {
                  return const Text(
                    Strings.detailUnavailable,
                    style: TextStyle(color: Tokens.mutedText),
                  );
                }
                return ScoreSheet(rounds: rounds, seats: widget.seats);
              },
            ),
          ],
        ),
      ),
    );
  }
}
