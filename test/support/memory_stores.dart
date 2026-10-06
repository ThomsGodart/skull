import 'package:skull_kings/engine/engine.dart';
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
  final List<GameFinished> finished = [];
  int _nextId = 1;

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
  Future<void> finish(int id, GameFinished result) async {
    if (active?.id == id) active = null;
    finished.add(result);
  }

  @override
  Future<void> discardActive() async => active = null;
}
