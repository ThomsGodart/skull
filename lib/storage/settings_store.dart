/// Where the app's settings are kept, as plain text values under a key.
abstract interface class SettingsStore {
  Future<Map<String, String>> readAll();

  Future<void> write(String key, String value);
}
