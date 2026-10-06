import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skull_kings/settings/app_settings.dart';
import 'package:skull_kings/storage/app_database.dart';
import 'package:skull_kings/storage/drift_settings_store.dart';

import '../support/memory_stores.dart';

void main() {
  test('a first launch starts with the defaults', () async {
    final settings = await AppSettings.load(MemorySettingsStore());

    expect(settings.playerName, AppSettings.defaultPlayerName);
    expect(settings.playerColor, 0);
    expect(settings.opponents, 3);
  });

  test('what the player chooses is still there at the next launch', () async {
    final store = MemorySettingsStore();
    final settings = await AppSettings.load(store);

    await settings.setPlayer(name: 'Anne', color: 2);
    await settings.setOpponents(6);

    final reloaded = await AppSettings.load(store);
    expect(reloaded.playerName, 'Anne');
    expect(reloaded.playerColor, 2);
    expect(reloaded.opponents, 6);
  });

  test('a blank name falls back to the default one', () async {
    final settings = await AppSettings.load(MemorySettingsStore());

    await settings.setPlayer(name: '   ', color: 0);

    expect(settings.playerName, AppSettings.defaultPlayerName);
  });

  test('a name is trimmed and kept short enough for the table', () async {
    final settings = await AppSettings.load(MemorySettingsStore());

    await settings.setPlayer(name: '  Barberousse le Terrible  ', color: 0);

    expect(settings.playerName, 'Barberousse ');
    expect(settings.playerName.length, AppSettings.maxNameLength);
  });

  test('the number of opponents stays between two and seven', () async {
    final settings = await AppSettings.load(MemorySettingsStore());

    await settings.setOpponents(12);
    expect(settings.opponents, 7);
    await settings.setOpponents(0);
    expect(settings.opponents, 2);
  });

  test('values that make no sense are ignored when loading', () async {
    final settings = await AppSettings.load(
      MemorySettingsStore({'opponents': 'many', 'playerColor': '99'}),
    );

    expect(settings.opponents, 3);
    expect(settings.playerColor, 0);
  });

  test('listeners are told when a setting changes', () async {
    final settings = await AppSettings.load(MemorySettingsStore());
    var notified = 0;
    settings.addListener(() => notified++);

    await settings.setOpponents(4);

    expect(notified, 1);
  });

  test('settings are kept in the database', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final store = DriftSettingsStore(database);

    await store.write('playerName', 'Anne');
    await store.write('playerName', 'Bob');

    expect(await store.readAll(), {'playerName': 'Bob'});
  });
}
