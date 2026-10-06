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

  /// What the human was called when the game ended.
  TextColumn get playerName => text().nullable()();

  /// How the human bid over the game, for the statistics. All four are set
  /// together when the game ends; null for a game kept before version 2.
  IntColumn get roundsPlayed => integer().nullable()();
  IntColumn get bidsMade => integer().nullable()();
  IntColumn get zeroBids => integer().nullable()();
  IntColumn get zeroBidsMade => integer().nullable()();
}

/// Games played with the real cards, of which only the score is kept. The
/// one with no [finishedAt] is the one being counted.
@DataClassName('StoredCounterGame')
class CounterGames extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get startedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get finishedAt => dateTime().nullable()();

  /// The whole `CounterGame`, as JSON.
  TextColumn get game => text()();
}

/// The app's settings, one row per key.
@DataClassName('StoredSetting')
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

@DriftDatabase(tables: [Games, CounterGames, Settings])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// The app's database file on the device.
  factory AppDatabase.onDevice() =>
      AppDatabase(driftDatabase(name: 'skull_kings'));

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.addColumn(games, games.playerName);
        await migrator.addColumn(games, games.roundsPlayed);
        await migrator.addColumn(games, games.bidsMade);
        await migrator.addColumn(games, games.zeroBids);
        await migrator.addColumn(games, games.zeroBidsMade);
      }
      if (from < 3) await migrator.createTable(counterGames);
    },
  );
}
