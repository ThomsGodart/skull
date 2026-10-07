import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'app.dart';
import 'cloud/backed_up_stores.dart';
import 'cloud/cloud_backup.dart';
import 'cloud/supabase_cloud.dart';
import 'online/online_backend.dart';
import 'online/supabase_room_transport.dart';
import 'settings/app_settings.dart';
import 'storage/app_database.dart';
import 'storage/drift_counter_store.dart';
import 'storage/drift_game_store.dart';
import 'storage/drift_settings_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // The pictogram font is under the SIL Open Font License, which asks for
  // its text to travel with it: it joins the app's licences page.
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(const [
      'Noto Emoji',
    ], await rootBundle.loadString('assets/fonts/NotoEmoji-OFL.txt'));
  });
  final database = AppDatabase.onDevice();
  // The phone keeps everything; a copy follows in the cloud, under an
  // anonymous account, whenever the network allows.
  final local = DriftSettingsStore(database);
  final cloud = DebouncedCloudBackup(
    SupabaseCloudTable(onlineClient(), CloudAccount(onlineClient(), local)),
  );
  final settings = BackedUpSettingsStore(local, cloud);
  final games = BackedUpGameStore(DriftGameStore(database), cloud);
  final counters = BackedUpCounterStore(DriftCounterStore(database), cloud);
  runApp(
    SkullKingsApp(
      games: games,
      counters: counters,
      settings: await AppSettings.load(settings),
      // One connection for the app, opened the first time a room is joined.
      transports: (selfId) => SupabaseRoomTransport(onlineClient(), selfId),
    ),
  );
  // Whatever was changed while offline, or before backups existed.
  unawaited(
    Future.wait([settings.backUpAll(), games.backUpAll(), counters.backUpAll()])
        .catchError((Object _) => const <void>[]),
  );
}
