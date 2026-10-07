import '../counter/counter_game.dart';
import '../counter/counter_store.dart';
import '../engine/engine.dart';
import '../storage/finished_game.dart';
import '../storage/game_store.dart';
import '../storage/settings_store.dart';
import 'cloud_backup.dart';
import 'supabase_cloud.dart';

/// Settings that are also copied to the cloud, one by one as they change.
final class BackedUpSettingsStore implements SettingsStore {
  BackedUpSettingsStore(this._inner, this._cloud);

  final SettingsStore _inner;
  final CloudBackup _cloud;

  /// What stays on the phone: the key to the account itself.
  static bool _isPrivate(String key) => key == CloudAccount.sessionKey;

  @override
  Future<Map<String, String>> readAll() => _inner.readAll();

  @override
  Future<void> write(String key, String value) async {
    await _inner.write(key, value);
    if (!_isPrivate(key)) _backUp(key, value);
  }

  void _backUp(String key, String value) =>
      _cloud.put(CloudKind.setting, key, () async => {'value': value});

  /// Copies every setting as it stands.
  Future<void> backUpAll() async {
    for (final MapEntry(:key, :value) in (await _inner.readAll()).entries) {
      if (!_isPrivate(key)) _backUp(key, value);
    }
  }
}

/// Games that are also copied to the cloud: the one in progress as it goes,
/// the finished ones with their result.
final class BackedUpGameStore implements GameStore {
  BackedUpGameStore(this._inner, this._cloud);

  final GameStore _inner;
  final CloudBackup _cloud;

  void _backUp(int id) => _cloud.put(CloudKind.game, '$id', () async {
    final game = await _inner.loadGame(id);
    if (game == null) return null;
    final finished = (await _inner.loadFinished())
        .where((finished) => finished.id == id)
        .firstOrNull;
    return {
      'config': game.config.toJson(),
      'answers': [for (final answer in game.answers) answerToJson(answer)],
      'round': game.round,
      'humanScore': game.humanScore,
      if (finished != null)
        'finished': {
          'at': finished.finishedAt.toUtc().toIso8601String(),
          'scores': finished.scores,
          'winner': finished.winner,
          'humanSeat': finished.humanSeat,
          'playerName': finished.playerName,
          if (finished.summary case final summary?)
            'summary': {
              'rounds': summary.rounds,
              'bidsMade': summary.bidsMade,
              'zeroBids': summary.zeroBids,
              'zeroBidsMade': summary.zeroBidsMade,
            },
        },
    };
  });

  @override
  Future<SavedGame?> loadActive() => _inner.loadActive();

  @override
  Future<int> create(GameConfig config) async {
    // The game it replaces, if any, is dropped: so is its copy.
    final replaced = await _inner.loadActive();
    final id = await _inner.create(config);
    if (replaced != null) _cloud.remove(CloudKind.game, '${replaced.id}');
    _backUp(id);
    return id;
  }

  @override
  Future<void> saveProgress(
    int id, {
    required List<Answer> answers,
    required int round,
    required int humanScore,
  }) async {
    await _inner.saveProgress(
      id,
      answers: answers,
      round: round,
      humanScore: humanScore,
    );
    _backUp(id);
  }

  @override
  Future<void> finish(
    int id,
    GameFinished result, {
    required GameSummary summary,
    required String playerName,
  }) async {
    await _inner.finish(id, result, summary: summary, playerName: playerName);
    _backUp(id);
  }

  @override
  Future<List<FinishedGame>> loadFinished() => _inner.loadFinished();

  @override
  Future<SavedGame?> loadGame(int id) => _inner.loadGame(id);

  @override
  Future<void> deleteFinished(int id) async {
    await _inner.deleteFinished(id);
    _cloud.remove(CloudKind.game, '$id');
  }

  @override
  Future<void> discardActive() async {
    final active = await _inner.loadActive();
    await _inner.discardActive();
    if (active != null) _cloud.remove(CloudKind.game, '${active.id}');
  }

  /// Copies the game in progress and every finished one.
  Future<void> backUpAll() async {
    if (await _inner.loadActive() case final active?) _backUp(active.id);
    for (final game in await _inner.loadFinished()) {
      _backUp(game.id);
    }
  }
}

/// Counted games that are also copied to the cloud.
final class BackedUpCounterStore implements CounterStore {
  BackedUpCounterStore(this._inner, this._cloud);

  final CounterStore _inner;
  final CloudBackup _cloud;

  void _backUp(int id, CounterGame game, {DateTime? finishedAt}) {
    // Taken now: the game is changed in place as it is counted.
    final value = {
      'game': game.toJson(),
      'finishedAt': finishedAt?.toUtc().toIso8601String(),
    };
    _cloud.put(CloudKind.counter, '$id', () async => value);
  }

  @override
  Future<SavedCounterGame?> loadActive() => _inner.loadActive();

  @override
  Future<int> create(CounterGame game) async {
    final replaced = await _inner.loadActive();
    final id = await _inner.create(game);
    if (replaced != null) _cloud.remove(CloudKind.counter, '${replaced.id}');
    _backUp(id, game);
    return id;
  }

  @override
  Future<void> save(int id, CounterGame game) async {
    await _inner.save(id, game);
    _backUp(id, game);
  }

  @override
  Future<void> finish(int id, CounterGame game) async {
    await _inner.finish(id, game);
    _backUp(id, game, finishedAt: DateTime.now());
  }

  @override
  Future<List<SavedCounterGame>> loadFinished() => _inner.loadFinished();

  @override
  Future<void> delete(int id) async {
    await _inner.delete(id);
    _cloud.remove(CloudKind.counter, '$id');
  }

  /// Copies the game being counted and every finished one.
  Future<void> backUpAll() async {
    if (await _inner.loadActive() case final active?) {
      _backUp(active.id, active.game);
    }
    for (final saved in await _inner.loadFinished()) {
      _backUp(saved.id, saved.game, finishedAt: saved.finishedAt);
    }
  }
}
