import 'package:flutter/material.dart';

import '../engine/engine.dart';
import '../game/score_views.dart';
import '../game/seat_identity.dart';
import 'counter_store.dart';
import '../theme/tokens.dart';
import '../ui/strings.dart';
import 'counter_game.dart';
import 'counter_round_screen.dart';

/// A counted game: its standings and score sheet, and the way to enter the
/// next round or correct a past one.
class CounterGameScreen extends StatefulWidget {
  const CounterGameScreen({
    super.key,
    required this.store,
    required this.saved,
  });

  final CounterStore store;
  final SavedCounterGame saved;

  @override
  State<CounterGameScreen> createState() => _CounterGameScreenState();
}

class _CounterGameScreenState extends State<CounterGameScreen> {
  CounterGame get _game => widget.saved.game;
  int get _id => widget.saved.id;
  bool get _finished => widget.saved.finishedAt != null;

  late final List<SeatIdentity> _seats = [
    for (final (player, name) in _game.players.indexed)
      SeatIdentity(name, Tokens.botColors[player % Tokens.botColors.length]),
  ];

  Future<void> _enter(int round) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => CounterRoundScreen(
          game: _game,
          round: round,
          onDraft: (bids, cards) {
            _game.draftBids = bids;
            _game.draftCards = cards;
            widget.store.save(_id, _game);
          },
          onSave: (entered) {
            _game.saveRound(round, entered);
            widget.store.save(_id, _game);
            Navigator.of(context).pop();
          },
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  bool _finishing = false;

  Future<void> _finish() async {
    if (_finishing) return;
    _finishing = true;
    final navigator = Navigator.of(context);
    await widget.store.finish(_id, _game);
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final game = _game;
    final round = game.nextRound;
    final rounds = game.scoredRounds;
    return Scaffold(
      appBar: AppBar(title: const Text(Strings.counter)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(Tokens.space4),
                children: [
                  if (game.winner case final winner?)
                    Padding(
                      padding: const EdgeInsets.only(bottom: Tokens.space3),
                      child: Text(
                        Strings.wins(game.players[winner]),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Tokens.text,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    )
                  else if (!_finished) ...[
                    Text(
                      Strings.counterRoundTitle(round, game.cardsIn(round)),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Tokens.text,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      Strings.counterLeads(game.players[game.leaderOf(round)]),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Tokens.mutedText),
                    ),
                    if (round > standardRounds)
                      const Padding(
                        padding: EdgeInsets.only(top: Tokens.space2),
                        child: Text(
                          Strings.counterTieBreak,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Tokens.gold),
                        ),
                      ),
                    const SizedBox(height: Tokens.space3),
                  ],
                  Standings(scores: game.totals, seats: _seats),
                  if (rounds.isNotEmpty) ...[
                    const SizedBox(height: Tokens.space4),
                    ScoreSheet(
                      rounds: rounds,
                      seats: _seats,
                      onRoundTap: _finished ? null : _enter,
                    ),
                    if (!_finished)
                      const Padding(
                        padding: EdgeInsets.only(top: Tokens.space2),
                        child: Text(
                          Strings.counterCorrectHint,
                          style: TextStyle(color: Tokens.mutedText),
                        ),
                      ),
                  ],
                ],
              ),
            ),
            if (!_finished)
              Padding(
                padding: const EdgeInsets.all(Tokens.space4),
                child: SizedBox(
                  width: double.infinity,
                  child: game.isOver
                      ? FilledButton(
                          key: const Key('counter-finish'),
                          onPressed: _finish,
                          child: const Text(Strings.counterFinish),
                        )
                      : FilledButton(
                          key: const Key('counter-enter'),
                          onPressed: () => _enter(round),
                          child: Text(
                            game.draftBids == null
                                ? Strings.counterEnterRound(round)
                                : Strings.counterEnterResults(round),
                          ),
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
