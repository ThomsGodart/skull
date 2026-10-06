import 'app_database.dart';
import 'settings_store.dart';

/// Settings kept in the app's SQLite database.
final class DriftSettingsStore implements SettingsStore {
  DriftSettingsStore(this._database);

  final AppDatabase _database;

  @override
  Future<Map<String, String>> readAll() async => {
    for (final row in await _database.select(_database.settings).get())
      row.key: row.value,
  };

  @override
  Future<void> write(String key, String value) => _database
      .into(_database.settings)
      .insertOnConflictUpdate(StoredSetting(key: key, value: value));
}
