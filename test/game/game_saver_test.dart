import 'dart:math';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skull_kings/bots/bot.dart';
import 'package:skull_kings/engine/engine.dart';
import 'package:skull_kings/game/game_controller.dart';
import 'package:skull_kings/game/game_saver.dart';
import 'package:skull_kings/storage/app_database.dart';
import 'package:skull_kings/storage/drift_game_store.dart';
import 'package:skull_kings/storage/game_store.dart';

import 'game_controller_test.dart' show playUntil, settle;

void main() {
  const config = GameConfig(players: 4, seed: 13);
  late AppDatabase database;
  late DriftGameStore store;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    store = DriftGameStore(database);
  });
  tearDown(() => database.close());

  Future<(GameController, GameSaver)> newGame() async {
    final saver = GameSaver(
      store,
      await store.create(config),
      playerName: 'Anne',
    );
    final controller = GameController(
      config: config,
      bot: randomBot(Random(13)),
      speed: TableSpeed.instant,
      onProgress: saver.record,
    )..start();
    return (controller, saver);
  }

  test('a game played to the end is kept whole: its answers replay to a '
      'finished game with the same scores', () async {
    final (controller, saver) = await newGame();
    await playUntil(controller, () => controller.result != null);
    await saver.done;

    expect(await store.loadActive(), isNull);
    final stored = (await database.select(database.games).get()).single;
    expect(stored.finishedAt, isNotNull);
    expect(stored.winner, controller.result!.winner);
    expect(stored.playerName, 'Anne');
    expect(stored.roundsPlayed, controller.scoredRounds.length);
    expect(stored.humanScore, controller.result!.scores[0]);
    final replayed = Game.replay(config, decodeAnswers(stored.answers));
    expect(replayed.isFinished, isTrue);
    expect(replayed.viewFor(0).scores, controller.result!.scores);
  });

  test(
    'a game is only marked as over once its final standings are on '
    'screen: left before that, it can still be resumed to see them',
    () async {
      final (controller, saver) = await newGame();
      // Stop on the summary of the last round: every answer has been given.
      await playUntil(
        controller,
        () => controller.roundSummary != null && controller.round >= 10,
      );
      while (true) {
        await saver.done;
        final active = await store.loadActive();
        final finished = Game.replay(config, active!.answers).isFinished;
        if (finished) break;
        controller.continueAfterRound();
        await playUntil(controller, () => controller.roundSummary != null);
      }

      final active = (await store.loadActive())!;
      expect(controller.result, isNull, reason: 'standings not shown yet');
      final resumed = GameController(
        config: config,
        bot: randomBot(Random(13)),
        speed: TableSpeed.instant,
        savedAnswers: active.answers,
        onProgress: GameSaver(store, active.id, playerName: 'Anne').record,
      )..start();
      await settle();

      expect(resumed.result, isNotNull);
    },
  );

  test(
    'a write that fails is reported and does not stop the next ones',
    () async {
      final failing = _FailingOnce(store);
      final errors = <Object>[];
      final saver = GameSaver(
        failing,
        await store.create(config),
        playerName: 'Anne',
        onError: errors.add,
      );
      GameProgress progress(int round) =>
          GameProgress(answers: const [], round: round, humanScore: 0);

      saver.record(progress(2));
      saver.record(progress(3));
      await saver.done;

      expect(errors, hasLength(1));
      expect((await store.loadActive())!.round, 3);
    },
  );
}

class _FailingOnce implements GameStore {
  _FailingOnce(this._inner);

  final GameStore _inner;
  bool _failed = false;

  @override
  Future<void> saveProgress(
    int id, {
    required List<Answer> answers,
    required int round,
    required int humanScore,
  }) {
    if (!_failed) {
      _failed = true;
      throw StateError('disk full');
    }
    return _inner.saveProgress(
      id,
      answers: answers,
      round: round,
      humanScore: humanScore,
    );
  }

  @override
  Object? noSuchMethod(Invocation invocation) => throw UnimplementedError();

  @override
  Future<int> create(GameConfig config) => _inner.create(config);
  @override
  Future<SavedGame?> loadActive() => _inner.loadActive();
}
