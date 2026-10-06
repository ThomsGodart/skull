import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// Every game started on this device. The one with no [finishedAt] is the
/// game in progress.
@DataClassName('StoredGame')
class Games extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get startedAt => dateTime().withDefault(currentDateAndTime)();

  /// The game's `GameConfig`, as JSON.
  TextColumn get config => text()();

  /// Every answer given so far, in order, as a JSON list.
  TextColumn get answers => text().withDefault(const Constant('[]'))();

  /// Where the game stands, to describe it without replaying it.
  IntColumn get round => integer().withDefault(const Constant(1))();
  IntColumn get humanScore => integer().withDefault(const Constant(0))();

  DateTimeColumn get finishedAt => dateTime().nullable()();

  /// Final score of each seat, as a JSON list. Set when the game is over.
  TextColumn get finalScores => text().nullable()();
  IntColumn get winner => integer().nullable()();
}

/// The app's settings, one row per key.
@DataClassName('StoredSetting')
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

@DriftDatabase(tables: [Games, Settings])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// The app's database file on the device.
  factory AppDatabase.onDevice() =>
      AppDatabase(driftDatabase(name: 'skull_kings'));

  @override
  int get schemaVersion => 1;
}
