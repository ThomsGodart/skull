import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'settings/app_settings.dart';
import 'storage/app_database.dart';
import 'storage/drift_game_store.dart';
import 'storage/drift_settings_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final database = AppDatabase.onDevice();
  runApp(
    SkullKingsApp(
      games: DriftGameStore(database),
      settings: await AppSettings.load(DriftSettingsStore(database)),
    ),
  );
}
