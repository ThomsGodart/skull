import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'app.dart';
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
  runApp(
    SkullKingsApp(
      games: DriftGameStore(database),
      counters: DriftCounterStore(database),
      settings: await AppSettings.load(DriftSettingsStore(database)),
      // One connection for the app, opened the first time a room is joined.
      transports: (selfId) => SupabaseRoomTransport(onlineClient(), selfId),
    ),
  );
}
