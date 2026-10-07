import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skull_kings/cloud/backed_up_stores.dart';
import 'package:skull_kings/cloud/cloud_backup.dart';
import 'package:skull_kings/cloud/supabase_cloud.dart';
import 'package:skull_kings/counter/counter_game.dart';
import 'package:skull_kings/engine/engine.dart';
import 'package:skull_kings/storage/finished_game.dart';

import '../support/memory_stores.dart';

/// A cloud table kept in memory, which can be made to fail.
class MemoryCloudTable implements CloudTable {
  final Map<(String, String), CloudValue> rows = {};
  int writes = 0;
  bool down = false;

  @override
  Future<void> upsert(String kind, String key, CloudValue value) async {
    if (down) throw StateError('offline');
    writes++;
    rows[(kind, key)] = value;
  }

  @override
  Future<void> delete(String kind, String key) async {
    if (down) throw StateError('offline');
    rows.remove((kind, key));
  }
}

void main() {
  late MemoryCloudTable table;
  late DebouncedCloudBackup cloud;
  const delay = Duration(seconds: 3);

  setUp(() {
    table = MemoryCloudTable();
    cloud = DebouncedCloudBackup(table, delay: delay);
  });

  /// Runs [body], then lets the copies it asked for be made.
  void backedUp(Future<void> Function() body) => fakeAsync((async) {
    body();
    async.flushMicrotasks();
    async.elapse(delay * 2);
  });

  test('several changes in a row make one copy, of the last state', () {
    fakeAsync((async) {
      var value = 0;
      for (var i = 0; i < 5; i++) {
        value = i;
        cloud.put(CloudKind.game, '1', () async => {'n': value});
        async.elapse(const Duration(seconds: 1));
      }
      expect(table.writes, 0);

      async.elapse(delay);
      expect(table.writes, 1);
      expect(table.rows[(CloudKind.game, '1')], {'n': 4});
    });
  });

  test('a cloud that cannot be reached never breaks anything', () {
    table.down = true;
    fakeAsync((async) {
      cloud.put(CloudKind.setting, 'name', () async => {'value': 'Anne'});
      cloud.remove(CloudKind.setting, 'gone');
      async.elapse(delay * 2);
    });
    expect(table.rows, isEmpty);
  });

  test('settings are copied as they change, but for the account\'s own '
      'session', () {
    final store = BackedUpSettingsStore(MemorySettingsStore(), cloud);
    backedUp(() async {
      await store.write('playerName', 'Anne');
      await store.write(CloudAccount.sessionKey, '{"secret": true}');
    });

    expect(table.rows, {
      (CloudKind.setting, 'playerName'): {'value': 'Anne'},
    });
  });

  test('a game is copied as it is played, with its result once over, and '
      'its copy goes when it is deleted', () {
    final inner = MemoryGameStore();
    final store = BackedUpGameStore(inner, cloud);
    const config = GameConfig(players: 3, seed: 5);
    late int id;
    backedUp(() async {
      id = await store.create(config);
      await store.saveProgress(
        id,
        answers: const [BidAnswer(seat: 0, bid: 1)],
        round: 2,
        humanScore: 20,
      );
    });
    final playing = table.rows[(CloudKind.game, '$id')]!;
    expect(playing['round'], 2);
    expect(playing['answers'], hasLength(1));
    expect(playing.containsKey('finished'), isFalse);

    backedUp(
      () => store.finish(
        id,
        const GameFinished(winner: 0, scores: [50, 10, 0]),
        summary: const GameSummary(
          rounds: 10,
          bidsMade: 6,
          zeroBids: 2,
          zeroBidsMade: 1,
        ),
        playerName: 'Anne',
      ),
    );
    final finished =
        table.rows[(CloudKind.game, '$id')]!['finished']! as CloudValue;
    expect(finished['scores'], [50, 10, 0]);
    expect(finished['playerName'], 'Anne');

    backedUp(() => store.deleteFinished(id));
    expect(table.rows, isEmpty);
  });

  test('a new game takes the place of the one in progress, in the cloud '
      'too', () {
    final store = BackedUpGameStore(MemoryGameStore(), cloud);
    const config = GameConfig(players: 3, seed: 5);
    backedUp(() async {
      await store.create(config);
    });
    backedUp(() async {
      await store.create(config);
    });

    expect(table.rows.keys, [(CloudKind.game, '2')]);
  });

  test('counted games are copied, and everything kept before backups '
      'existed is copied at launch', () {
    final inner = MemoryCounterStore();
    final store = BackedUpCounterStore(inner, cloud);
    final game = CounterGame(players: const ['Anne', 'Bob']);
    backedUp(() async {
      final id = await inner.create(game);
      await inner.finish(id, game);
      await inner.create(CounterGame(players: const ['Chloé', 'Dan']));
    });
    expect(table.rows, isEmpty);

    backedUp(store.backUpAll);

    expect(table.rows.keys, {
      (CloudKind.counter, '1'),
      (CloudKind.counter, '2'),
    });
    expect(table.rows[(CloudKind.counter, '1')]!['finishedAt'], isNotNull);
  });
}
