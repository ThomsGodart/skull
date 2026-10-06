import 'package:flutter/material.dart';

import 'home/home_screen.dart';
import 'theme/tokens.dart';
import 'ui/strings.dart';

class SkullKingsApp extends StatelessWidget {
  const SkullKingsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: Strings.appTitle,
      debugShowCheckedModeBanner: false,
      theme: Tokens.theme(),
      home: const HomeScreen(),
    );
  }
}
