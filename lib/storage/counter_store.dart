import '../counter/counter_game.dart';

/// A counted game as it is kept.
final class SavedCounterGame {
  const SavedCounterGame({
    required this.id,
    required this.game,
    this.finishedAt,
  });

  final int id;
  final CounterGame game;

  /// Null while the game is still being counted.
  final DateTime? finishedAt;
}

/// Where counted games are kept. At most one is in progress at a time.
abstract interface class CounterStore {
  /// The game being counted, if there is one that can still be read.
  Future<SavedCounterGame?> loadActive();

  /// Starts keeping [game], dropping any other game in progress.
  Future<int> create(CounterGame game);

  /// Records where game [id] stands.
  Future<void> save(int id, CounterGame game);

  /// Marks game [id] as over.
  Future<void> finish(int id, CounterGame game);

  /// Every finished game, the latest first.
  Future<List<SavedCounterGame>> loadFinished();

  Future<void> delete(int id);
}
