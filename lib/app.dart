import 'package:flutter/material.dart';

import 'home/home_screen.dart';
import 'settings/app_settings.dart';
import 'counter/counter_store.dart';
import 'storage/game_store.dart';
import 'theme/tokens.dart';
import 'ui/strings.dart';

class SkullKingsApp extends StatelessWidget {
  const SkullKingsApp({
    super.key,
    required this.games,
    required this.counters,
    required this.settings,
  });

  final GameStore games;
  final CounterStore counters;
  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: Strings.appTitle,
      debugShowCheckedModeBanner: false,
      theme: Tokens.theme(),
      // The in-app switch asks for the same as the system setting does, so
      // every screen treats the two alike.
      builder: (context, child) => ListenableBuilder(
        listenable: settings,
        builder: (context, _) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations:
                settings.reduceMotion ||
                MediaQuery.disableAnimationsOf(context),
          ),
          child: child!,
        ),
      ),
      home: HomeScreen(games: games, counters: counters, settings: settings),
    );
  }
}
