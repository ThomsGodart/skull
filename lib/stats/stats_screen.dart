import 'package:flutter/material.dart';

import '../history/game_statistics.dart';
import '../storage/game_store.dart';
import '../theme/tokens.dart';
import '../ui/strings.dart';

/// How the player has done over every finished game.
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key, required this.games});

  final GameStore games;

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  late final Future<GameStatistics> _stats = widget.games.loadFinished().then(
    GameStatistics.of,
  );

  /// A figure, or a dash when there is nothing to measure.
  static String _show<T>(T? value, String Function(T) format) =>
      value == null ? Strings.unavailable : format(value);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(Strings.statistics)),
      body: SafeArea(
        child: FutureBuilder(
          future: _stats,
          builder: (context, snapshot) {
            final stats = snapshot.data;
            if (stats == null) return const SizedBox.shrink();
            final lines = [
              (Strings.statGamesPlayed, '${stats.gamesPlayed}'),
              (Strings.statWins, '${stats.wins}'),
              (Strings.statWinRate, _show(stats.winRate, Strings.percent)),
              (
                Strings.statAverageRank,
                _show(stats.averageRank, Strings.decimal),
              ),
              (
                Strings.statAverageScore,
                _show(stats.averageScore, Strings.decimal),
              ),
              (Strings.statBestScore, _show(stats.bestScore, (v) => '$v')),
              (
                Strings.statBidSuccess,
                _show(stats.bidSuccessRate, Strings.percent),
              ),
              (
                Strings.statZeroBidSuccess,
                _show(stats.zeroBidSuccessRate, Strings.percent),
              ),
            ];
            return ListView(
              padding: const EdgeInsets.all(Tokens.space4),
              children: [
                for (final (label, value) in lines)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: Tokens.space2,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            label,
                            style: const TextStyle(color: Tokens.text),
                          ),
                        ),
                        Text(
                          value,
                          style: TextStyle(
                            color: value == Strings.unavailable
                                ? Tokens.mutedText
                                : Tokens.gold,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                // The bid rates may rest on fewer games than the rest.
                if (stats.gamesWithBidDetails != stats.gamesPlayed &&
                    stats.gamesWithBidDetails > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: Tokens.space3),
                    child: Text(
                      Strings.statMeasuredOn(stats.gamesWithBidDetails),
                      style: const TextStyle(color: Tokens.mutedText),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
