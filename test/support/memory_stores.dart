import 'package:skull_kings/counter/counter_game.dart';
import 'package:skull_kings/engine/engine.dart';
import 'package:skull_kings/counter/counter_store.dart';
import 'package:skull_kings/storage/finished_game.dart';
import 'package:skull_kings/storage/game_store.dart';
import 'package:skull_kings/storage/settings_store.dart';

/// Settings kept in memory, shared by every instance built on [values].
class MemorySettingsStore implements SettingsStore {
  MemorySettingsStore([Map<String, String>? values]) : values = values ?? {};

  final Map<String, String> values;

  @override
  Future<Map<String, String>> readAll() async => Map.of(values);

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

/// Games kept in memory.
class MemoryGameStore implements GameStore {
  SavedGame? active;

  /// Finished games, the latest first.
  final List<FinishedGame> finished = [];

  /// What was kept of each finished game, to replay it.
  final Map<int, SavedGame> kept = {};
  int _nextId = 1;

  /// How many games were created.
  int get created => _nextId - 1;

  @override
  Future<SavedGame?> loadActive() async => active;

  @override
  Future<int> create(GameConfig config) async {
    active = SavedGame(
      id: _nextId++,
      config: config,
      answers: const [],
      round: 1,
      humanScore: 0,
    );
    return active!.id;
  }

  @override
  Future<void> saveProgress(
    int id, {
    required List<Answer> answers,
    required int round,
    required int humanScore,
  }) async {
    if (active?.id != id) return;
    active = SavedGame(
      id: id,
      config: active!.config,
      answers: List.of(answers),
      round: round,
      humanScore: humanScore,
    );
  }

  @override
  Future<void> finish(
    int id,
    GameFinished result, {
    required GameSummary summary,
    required String playerName,
  }) async {
    final game = active?.id == id ? active : null;
    if (game != null) {
      kept[id] = game;
      active = null;
    }
    finished.insert(
      0,
      FinishedGame(
        id: id,
        finishedAt: DateTime(2026, 10, 6, 21, 30),
        scores: result.scores,
        winner: result.winner,
        playerName: playerName,
        config: game?.config,
        summary: summary,
      ),
    );
  }

  /// Makes [loadFinished] fail, as a broken database would.
  bool failLoading = false;

  @override
  Future<List<FinishedGame>> loadFinished() async {
    if (failLoading) throw StateError('unreadable');
    return List.of(finished);
  }

  @override
  Future<SavedGame?> loadGame(int id) async => kept[id];

  @override
  Future<void> deleteFinished(int id) async {
    finished.removeWhere((game) => game.id == id);
    kept.remove(id);
  }

  @override
  Future<void> discardActive() async => active = null;
}

/// Counted games kept in memory.
class MemoryCounterStore implements CounterStore {
  SavedCounterGame? active;
  final List<SavedCounterGame> finished = [];
  int _nextId = 1;

  @override
  Future<SavedCounterGame?> loadActive() async => active;

  @override
  Future<int> create(CounterGame game) async {
    active = SavedCounterGame(id: _nextId++, game: game);
    return active!.id;
  }

  @override
  Future<void> save(int id, CounterGame game) async {
    if (active?.id == id) active = SavedCounterGame(id: id, game: game);
  }

  @override
  Future<void> finish(int id, CounterGame game) async {
    if (active?.id == id) active = null;
    finished.insert(
      0,
      SavedCounterGame(
        id: id,
        game: game,
        finishedAt: DateTime(2026, 10, 6, 22),
      ),
    );
  }

  @override
  Future<List<SavedCounterGame>> loadFinished() async => List.of(finished);

  @override
  Future<void> delete(int id) async =>
      finished.removeWhere((saved) => saved.id == id);
}
