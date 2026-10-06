import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skull_kings/counter/counter_game.dart';
import 'package:skull_kings/storage/app_database.dart';
import 'package:skull_kings/storage/drift_counter_store.dart';

void main() {
  late AppDatabase database;
  late DriftCounterStore store;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    store = DriftCounterStore(database);
  });
  tearDown(() => database.close());

  CounterGame game() => CounterGame(players: ['Anne', 'Bob', 'Chloé']);
  const zeros = CounterRound(
    entries: [
      CounterEntry(bid: 0, tricksWon: 0),
      CounterEntry(bid: 0, tricksWon: 0),
      CounterEntry(bid: 1, tricksWon: 1),
    ],
  );

  test('there is no counted game to begin with', () async {
    expect(await store.loadActive(), isNull);
    expect(await store.loadFinished(), isEmpty);
  });

  test('a game being counted is read back with what was entered', () async {
    final counted = game();
    final id = await store.create(counted);
    counted
      ..saveRound(1, zeros)
      ..draftBids = [1, 0, 2];

    await store.save(id, counted);

    final saved = (await store.loadActive())!;
    expect(saved.id, id);
    expect(saved.game.players, ['Anne', 'Bob', 'Chloé']);
    expect(saved.game.totals, [10, 10, 20]);
    expect(saved.game.draftBids, [1, 0, 2]);
  });

  test('starting a new game drops the one being counted', () async {
    await store.create(game());

    final second = await store.create(CounterGame(players: ['Dan', 'Eve']));

    expect((await store.loadActive())!.id, second);
    expect(await database.select(database.counterGames).get(), hasLength(1));
  });

  test('a finished game leaves the counter free and joins the list, '
      'latest first', () async {
    final first = await store.create(game());
    await store.finish(first, game()..saveRound(1, zeros));
    final second = await store.create(game());
    await store.finish(second, game());

    expect(await store.loadActive(), isNull);
    final finished = await store.loadFinished();
    expect(finished.map((saved) => saved.id), [second, first]);
    expect(finished.last.game.totals, [10, 10, 20]);
    expect(finished.first.finishedAt, isNotNull);
  });

  test('a finished game can be deleted', () async {
    final id = await store.create(game());
    await store.finish(id, game());

    await store.delete(id);

    expect(await store.loadFinished(), isEmpty);
  });

  test('a game that can no longer be read is dropped, or left out of '
      'the list', () async {
    final active = await store.create(game());
    await (database.update(database.counterGames)
          ..where((g) => g.id.equals(active)))
        .write(const CounterGamesCompanion(game: Value('not json')));

    expect(await store.loadActive(), isNull);
    expect(await database.select(database.counterGames).get(), isEmpty);
  });

  test('a database from version 2 gains the counter without losing '
      'its settings', () async {
    final old = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          raw.execute(
            'CREATE TABLE settings (key TEXT NOT NULL, value TEXT NOT NULL, '
            'PRIMARY KEY (key));',
          );
          raw.execute('''
            CREATE TABLE games (
              id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
              started_at INTEGER NOT NULL DEFAULT 0,
              config TEXT NOT NULL,
              answers TEXT NOT NULL DEFAULT '[]',
              round INTEGER NOT NULL DEFAULT 1,
              human_score INTEGER NOT NULL DEFAULT 0,
              finished_at INTEGER NULL,
              final_scores TEXT NULL,
              winner INTEGER NULL,
              player_name TEXT NULL,
              rounds_played INTEGER NULL,
              bids_made INTEGER NULL,
              zero_bids INTEGER NULL,
              zero_bids_made INTEGER NULL
            );
          ''');
          raw.execute("INSERT INTO settings VALUES ('playerName', 'Anne');");
          raw.execute('PRAGMA user_version = 2;');
        },
      ),
    );
    addTearDown(old.close);

    final id = await DriftCounterStore(old).create(game());

    expect(id, 1);
    expect((await old.select(old.settings).get()).single.value, 'Anne');
  });
}
