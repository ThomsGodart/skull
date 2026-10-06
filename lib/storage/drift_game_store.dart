import 'dart:convert';

import 'package:drift/drift.dart';

import '../engine/engine.dart';
import 'finished_game.dart';
import 'app_database.dart';
import 'game_store.dart';

/// Games kept in the app's SQLite database.
final class DriftGameStore implements GameStore {
  DriftGameStore(this._database);

  final AppDatabase _database;

  $GamesTable get _games => _database.games;

  @override
  Future<SavedGame?> loadActive() async {
    final row =
        await (_database.select(_games)
              ..where((game) => game.finishedAt.isNull())
              ..orderBy([(game) => OrderingTerm.desc(game.id)])
              ..limit(1))
            .getSingleOrNull();
    if (row == null) return null;
    try {
      final config = GameConfig.fromJson(
        jsonDecode(row.config) as Map<String, Object?>,
      );
      final answers = decodeAnswers(row.answers);
      // Replaying is the only real proof that the save can be resumed.
      Game.replay(config, answers);
      return SavedGame(
        id: row.id,
        config: config,
        answers: answers,
        round: row.round,
        humanScore: row.humanScore,
      );
    } on Object {
      // A save nobody can resume would otherwise come back at every launch.
      await discardActive();
      return null;
    }
  }

  @override
  Future<int> create(GameConfig config) => _database.transaction(() async {
    await discardActive();
    return _database
        .into(_games)
        .insert(GamesCompanion.insert(config: jsonEncode(config.toJson())));
  });

  @override
  Future<void> saveProgress(
    int id, {
    required List<Answer> answers,
    required int round,
    required int humanScore,
  }) => _update(
    id,
    GamesCompanion(
      answers: Value(jsonEncode(answers.map(answerToJson).toList())),
      round: Value(round),
      humanScore: Value(humanScore),
    ),
  );

  @override
  Future<void> finish(
    int id,
    GameFinished result, {
    required GameSummary summary,
    required String playerName,
  }) =>
      // Only a game still in progress: finishing twice must not re-date it.
      (_database.update(
        _games,
      )..where((game) => game.id.equals(id) & game.finishedAt.isNull())).write(
        GamesCompanion(
          finishedAt: Value(DateTime.now()),
          finalScores: Value(jsonEncode(result.scores)),
          winner: Value(result.winner),
          playerName: Value(playerName),
          roundsPlayed: Value(summary.rounds),
          bidsMade: Value(summary.bidsMade),
          zeroBids: Value(summary.zeroBids),
          zeroBidsMade: Value(summary.zeroBidsMade),
        ),
      );

  @override
  Future<List<FinishedGame>> loadFinished() async {
    final rows =
        await (_database.select(_games)
              ..where((game) => game.finishedAt.isNotNull())
              ..orderBy([
                (game) => OrderingTerm.desc(game.finishedAt),
                (game) => OrderingTerm.desc(game.id),
              ]))
            .get();
    return [for (final row in rows) ?_finished(row)];
  }

  /// [row] as a finished game, or null when it cannot be read.
  FinishedGame? _finished(StoredGame row) {
    try {
      final scores = (jsonDecode(row.finalScores!) as List).cast<int>();
      final winner = row.winner!;
      if (winner < 0 || winner >= scores.length) return null;
      // The four bid counters are written together: all of them, or no summary.
      final summary = switch ((
        row.roundsPlayed,
        row.bidsMade,
        row.zeroBids,
        row.zeroBidsMade,
      )) {
        (
          final rounds?,
          final bidsMade?,
          final zeroBids?,
          final zeroBidsMade?,
        ) =>
          GameSummary(
            rounds: rounds,
            bidsMade: bidsMade,
            zeroBids: zeroBids,
            zeroBidsMade: zeroBidsMade,
          ),
        _ => null,
      };
      return FinishedGame(
        id: row.id,
        finishedAt: row.finishedAt!,
        scores: List.unmodifiable(scores),
        winner: winner,
        playerName: row.playerName,
        config: _config(row),
        summary: summary,
      );
    } on Object {
      return null;
    }
  }

  static GameConfig? _config(StoredGame row) {
    try {
      return GameConfig.fromJson(
        jsonDecode(row.config) as Map<String, Object?>,
      );
    } on Object {
      return null;
    }
  }

  @override
  Future<SavedGame?> loadGame(int id) async {
    final row = await (_database.select(
      _games,
    )..where((game) => game.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    try {
      return SavedGame(
        id: row.id,
        config: GameConfig.fromJson(
          jsonDecode(row.config) as Map<String, Object?>,
        ),
        answers: decodeAnswers(row.answers),
        round: row.round,
        humanScore: row.humanScore,
      );
    } on Object {
      return null;
    }
  }

  @override
  Future<void> deleteFinished(int id) => (_database.delete(
    _games,
  )..where((game) => game.id.equals(id) & game.finishedAt.isNotNull())).go();

  @override
  Future<void> discardActive() => (_database.delete(
    _games,
  )..where((game) => game.finishedAt.isNull())).go();

  Future<void> _update(int id, GamesCompanion changes) => (_database.update(
    _games,
  )..where((game) => game.id.equals(id))).write(changes);
}

/// The answers of a game as stored in [Games.answers].
List<Answer> decodeAnswers(String json) => [
  for (final answer in jsonDecode(json) as List)
    answerFromJson(answer as Map<String, Object?>),
];
