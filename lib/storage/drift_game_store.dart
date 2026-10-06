import 'dart:convert';

import 'package:drift/drift.dart';

import '../engine/engine.dart';
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
  Future<void> finish(int id, GameFinished result) => _update(
    id,
    GamesCompanion(
      finishedAt: Value(DateTime.now()),
      finalScores: Value(jsonEncode(result.scores)),
      winner: Value(result.winner),
    ),
  );

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
