import 'dart:math';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skull_kings/engine/engine.dart';
import 'package:skull_kings/history/game_summary.dart';
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

  const summary = GameSummary(
    rounds: 10,
    bidsMade: 6,
    zeroBids: 3,
    zeroBidsMade: 2,
  );

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
      summary: summary,
      playerName: 'Anne',
    );

    expect(await store.loadActive(), isNull);
  });

  test('a finished game is kept when a new one is created', () async {
    final first = await store.create(config);
    await store.finish(
      first,
      const GameFinished(winner: 0, scores: [50, 20, 10, 0]),
      summary: summary,
      playerName: 'Anne',
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

  group('finished games', () {
    Future<int> finishGame(List<int> scores, {String name = 'Anne'}) async {
      final id = await store.create(config);
      await store.saveProgress(id, answers: answers, round: 10, humanScore: 0);
      final best = scores.reduce((a, b) => a > b ? a : b);
      await store.finish(
        id,
        GameFinished(winner: scores.indexOf(best), scores: scores),
        summary: summary,
        playerName: name,
      );
      return id;
    }

    test('are listed with their result, the name the human bore and how '
        'they bid', () async {
      final id = await finishGame([10, 20, 90, -30]);

      final game = (await store.loadFinished()).single;

      expect(game.id, id);
      expect(game.scores, [10, 20, 90, -30]);
      expect(game.winner, 2);
      expect(game.playerName, 'Anne');
      expect(game.humanRank, 3);
      expect(game.summary!.rounds, 10);
      expect(game.summary!.bidsMade, 6);
      expect(game.summary!.zeroBids, 3);
      expect(game.summary!.zeroBidsMade, 2);
      expect(game.finishedAt.difference(DateTime.now()).inMinutes.abs(), 0);
    });

    test(
      'come latest first, and the game in progress is not among them',
      () async {
        final first = await finishGame([10, 20, 30, 40]);
        final second = await finishGame([40, 30, 20, 10]);
        await store.create(config);

        final games = await store.loadFinished();

        expect(games.map((game) => game.id), [second, first]);
      },
    );

    test('can be replayed from what was kept', () async {
      final id = await finishGame([10, 20, 30, 40]);

      final kept = (await store.loadGame(id))!;

      expect(kept.config.seed, config.seed);
      expect(kept.answers.map(answerToJson), answers.map(answerToJson));
    });

    test('one can be forgotten without touching the others', () async {
      final first = await finishGame([10, 20, 30, 40]);
      final second = await finishGame([40, 30, 20, 10]);

      await store.deleteFinished(first);

      expect((await store.loadFinished()).map((game) => game.id), [second]);
      expect(await store.loadGame(first), isNull);
    });

    test(
      'forgetting a finished game never drops the one in progress',
      () async {
        final active = await store.create(config);

        await store.deleteFinished(active);

        expect((await store.loadActive())!.id, active);
      },
    );

    test('a finished game whose scores cannot be read is left out of the '
        'list instead of breaking it', () async {
      final broken = await finishGame([10, 20, 30, 40]);
      final sound = await finishGame([40, 30, 20, 10]);
      await (database.update(database.games)..where((g) => g.id.equals(broken)))
          .write(const GamesCompanion(finalScores: Value('not json')));

      expect((await store.loadFinished()).map((game) => game.id), [sound]);
    });
  });

  test('a database from the first version is upgraded and its games kept, '
      'without the bid details it never had', () async {
    final old = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          raw.execute('''
            CREATE TABLE games (
              id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
              started_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)),
              config TEXT NOT NULL,
              answers TEXT NOT NULL DEFAULT '[]',
              round INTEGER NOT NULL DEFAULT 1,
              human_score INTEGER NOT NULL DEFAULT 0,
              finished_at INTEGER NULL,
              final_scores TEXT NULL,
              winner INTEGER NULL
            );
          ''');
          raw.execute(
            'CREATE TABLE settings (key TEXT NOT NULL, value TEXT NOT NULL, '
            'PRIMARY KEY (key));',
          );
          raw.execute(
            "INSERT INTO games (config, finished_at, final_scores, winner) "
            "VALUES ('{\"players\":3,\"seed\":1}', 1790000000, '[30,10,20]', 0);",
          );
          raw.execute('PRAGMA user_version = 1;');
        },
      ),
    );
    addTearDown(old.close);

    final game = (await DriftGameStore(old).loadFinished()).single;

    expect(game.scores, [30, 10, 20]);
    expect(game.humanRank, 1);
    expect(game.summary, isNull);
    expect(game.playerName, isNull);
  });
}
