import 'package:flutter/material.dart';

import '../game/seat_identity.dart';
import '../storage/game_store.dart';
import '../theme/tokens.dart';
import '../ui/strings.dart';
import 'game_detail_screen.dart';
import '../storage/finished_game.dart';

/// Every finished game, the latest first.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, required this.games, required this.human});

  final GameStore games;

  /// Who the human is today, for games kept without their name.
  final SeatIdentity human;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<FinishedGame>? _games;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final games = await widget.games.loadFinished();
      if (mounted) setState(() => _games = games);
    } on Object {
      if (mounted) setState(() => _failed = true);
    }
  }

  List<SeatIdentity> _seats(FinishedGame game) => SeatIdentity.table(
    game.players,
    human: SeatIdentity(
      game.playerName ?? widget.human.name,
      widget.human.color,
    ),
  );

  Future<void> _confirmDelete(FinishedGame game) async {
    final delete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(Strings.deleteGameTitle),
        content: const Text(Strings.deleteGameBody),
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
    try {
      await widget.games.deleteFinished(game.id);
    } on Object {
      if (mounted) setState(() => _failed = true);
      return;
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final games = _games;
    return Scaffold(
      appBar: AppBar(title: const Text(Strings.history)),
      body: SafeArea(
        child: _failed
            ? const _Notice(Strings.loadFailed)
            : games == null
            ? const SizedBox.shrink()
            : games.isEmpty
            ? const _Notice(Strings.historyEmpty)
            : ListView.separated(
                itemCount: games.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) => _line(games[index]),
              ),
      ),
    );
  }

  Widget _line(FinishedGame game) {
    final seats = _seats(game);
    return ListTile(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) =>
              GameDetailScreen(games: widget.games, game: game, seats: seats),
        ),
      ),
      onLongPress: () => _confirmDelete(game),
      title: Text(
        Strings.historyResult(game.humanRank, game.humanScore),
        style: TextStyle(
          color: game.humanWon ? Tokens.gold : Tokens.text,
          fontWeight: FontWeight.w800,
        ),
      ),
      subtitle: Text(
        [
          Strings.historyDetails(
            date: game.finishedAt,
            winner: game.humanWon ? null : seats[game.winner].name,
          ),
          if (game.config case final config?) Strings.modeName(config),
        ].join('\n'),
      ),
      isThreeLine: game.config != null,
      trailing: Text(
        Strings.playersCount(game.players),
        style: const TextStyle(color: Tokens.mutedText),
      ),
    );
  }
}

/// A message in the middle of an otherwise empty screen.
class _Notice extends StatelessWidget {
  const _Notice(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(Tokens.space6),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Tokens.mutedText),
      ),
    ),
  );
}
