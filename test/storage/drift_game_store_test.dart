import 'dart:math';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skull_kings/engine/engine.dart';
import 'package:skull_kings/storage/app_database.dart';
import 'package:skull_kings/storage/drift_game_store.dart';

void main() {
  late AppDatabase database;
  late DriftGameStore store;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    store = DriftGameStore(database);
  });
  tearDown(() => database.close());

  const config = GameConfig(players: 4, seed: 9);

  /// The first answers of a real game, so that they are legal for [config].
  final answers = () {
    final game = Game(config);
    final random = Random(1);
    for (var i = 0; i < 9; i++) {
      game.answer(randomAnswer(game.pending.first, random));
    }
    return game.answers;
  }();

  test('there is no game in progress to begin with', () async {
    expect(await store.loadActive(), isNull);
  });

  test(
    'a game just created is the game in progress, with no answer yet',
    () async {
      final id = await store.create(config);

      final saved = (await store.loadActive())!;

      expect(saved.id, id);
      expect(saved.config.players, 4);
      expect(saved.config.seed, 9);
      expect(saved.answers, isEmpty);
      expect(saved.round, 1);
    },
  );

  test('saved progress is read back as it was', () async {
    final id = await store.create(config);

    await store.saveProgress(id, answers: answers, round: 3, humanScore: -20);

    final saved = (await store.loadActive())!;
    expect(saved.round, 3);
    expect(saved.humanScore, -20);
    expect(saved.answers.map(answerToJson), answers.map(answerToJson));
  });

  test('creating a game drops the one that was in progress', () async {
    final first = await store.create(config);
    await store.saveProgress(first, answers: answers, round: 2, humanScore: 0);

    final second = await store.create(const GameConfig(players: 6, seed: 1));

    final saved = (await store.loadActive())!;
    expect(saved.id, second);
    expect(saved.config.players, 6);
    expect(saved.answers, isEmpty);
  });

  test('a finished game is no longer in progress', () async {
    final id = await store.create(config);

    await store.finish(
      id,
      const GameFinished(winner: 2, scores: [10, 20, 90, -30]),
    );

    expect(await store.loadActive(), isNull);
  });

  test('a finished game is kept when a new one is created', () async {
    final first = await store.create(config);
    await store.finish(
      first,
      const GameFinished(winner: 0, scores: [50, 20, 10, 0]),
    );

    await store.create(config);

    final stored = await database.select(database.games).get();
    expect(stored.map((game) => game.finishedAt != null), [true, false]);
    expect(stored.first.winner, 0);
  });

  test('the game in progress can be discarded', () async {
    await store.create(config);

    await store.discardActive();

    expect(await store.loadActive(), isNull);
  });

  test('a save that can no longer be read is dropped rather than '
      'blocking the app', () async {
    final id = await store.create(config);
    await (database.update(
      database.games,
    )..where((g) => g.id.equals(id))).write(
      const GamesCompanion(answers: Value('[{"seat":0,"card":"dragon-1"}]')),
    );

    expect(await store.loadActive(), isNull);
    expect(await database.select(database.games).get(), isEmpty);
  });

  test(
    'a save whose answers are not legal for its game is dropped too',
    () async {
      final id = await store.create(config);
      await store.saveProgress(
        id,
        answers: const [BidAnswer(seat: 0, bid: 5)],
        round: 1,
        humanScore: 0,
      );

      expect(await store.loadActive(), isNull);
      expect(await database.select(database.games).get(), isEmpty);
    },
  );

  test('a save for an impossible number of players is dropped too', () async {
    await store.create(const GameConfig(players: 99, seed: 1));

    expect(await store.loadActive(), isNull);
  });

  test(
    'should two games ever be left in progress, the latest one wins',
    () async {
      await database
          .into(database.games)
          .insert(GamesCompanion.insert(config: '{"players":4,"seed":1}'));
      await database
          .into(database.games)
          .insert(GamesCompanion.insert(config: '{"players":6,"seed":2}'));

      expect((await store.loadActive())!.config.players, 6);
    },
  );
}
