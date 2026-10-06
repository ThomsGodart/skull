import 'package:flutter/material.dart';

import 'home/home_screen.dart';
import 'settings/app_settings.dart';
import 'storage/game_store.dart';
import 'theme/tokens.dart';
import 'ui/strings.dart';

class SkullKingsApp extends StatelessWidget {
  const SkullKingsApp({super.key, required this.games, required this.settings});

  final GameStore games;
  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: Strings.appTitle,
      debugShowCheckedModeBanner: false,
      theme: Tokens.theme(),
      home: HomeScreen(games: games, settings: settings),
    );
  }
}
