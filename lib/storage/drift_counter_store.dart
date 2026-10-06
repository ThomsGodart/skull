import 'dart:convert';

import 'package:drift/drift.dart';

import '../counter/counter_game.dart';
import 'app_database.dart';
import '../counter/counter_store.dart';

/// Counted games kept in the app's SQLite database.
final class DriftCounterStore implements CounterStore {
  DriftCounterStore(this._database);

  final AppDatabase _database;

  $CounterGamesTable get _games => _database.counterGames;

  static String _encode(CounterGame game) => jsonEncode(game.toJson());

  /// [row] as a counted game, or null when it cannot be read.
  static SavedCounterGame? _decode(StoredCounterGame row) {
    try {
      return SavedCounterGame(
        id: row.id,
        game: CounterGame.fromJson(
          jsonDecode(row.game) as Map<String, Object?>,
        ),
        finishedAt: row.finishedAt,
      );
    } on Object {
      // Unreadable, or describing a round that cannot be: either way it is
      // not a game to show.
      return null;
    }
  }

  @override
  Future<SavedCounterGame?> loadActive() async {
    final row =
        await (_database.select(_games)
              ..where((game) => game.finishedAt.isNull())
              ..orderBy([(game) => OrderingTerm.desc(game.id)])
              ..limit(1))
            .getSingleOrNull();
    if (row == null) return null;
    final saved = _decode(row);
    // A save nobody can read would otherwise come back at every launch.
    if (saved == null) await delete(row.id);
    return saved;
  }

  @override
  Future<int> create(CounterGame game) => _database.transaction(() async {
    await (_database.delete(
      _games,
    )..where((other) => other.finishedAt.isNull())).go();
    return _database
        .into(_games)
        .insert(CounterGamesCompanion.insert(game: _encode(game)));
  });

  @override
  Future<void> save(int id, CounterGame game) =>
      (_database.update(_games)..where((other) => other.id.equals(id))).write(
        CounterGamesCompanion(game: Value(_encode(game))),
      );

  @override
  Future<void> finish(int id, CounterGame game) =>
      (_database.update(_games)..where((other) => other.id.equals(id))).write(
        CounterGamesCompanion(
          game: Value(_encode(game)),
          finishedAt: Value(DateTime.now()),
        ),
      );

  @override
  Future<List<SavedCounterGame>> loadFinished() async {
    final rows =
        await (_database.select(_games)
              ..where((game) => game.finishedAt.isNotNull())
              ..orderBy([
                (game) => OrderingTerm.desc(game.finishedAt),
                (game) => OrderingTerm.desc(game.id),
              ]))
            .get();
    return [for (final row in rows) ?_decode(row)];
  }

  @override
  Future<void> delete(int id) =>
      (_database.delete(_games)..where((game) => game.id.equals(id))).go();
}
