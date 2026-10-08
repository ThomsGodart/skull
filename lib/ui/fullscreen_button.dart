import 'package:flutter/material.dart';

import '../settings/app_settings.dart';
import 'strings.dart';

/// Toggles the in-app fullscreen mode kept in [settings].
class FullscreenButton extends StatelessWidget {
  const FullscreenButton({super.key, required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        final on = settings.fullscreen;
        return IconButton(
          key: const Key('fullscreen-toggle'),
          tooltip: on ? Strings.fullscreenExit : Strings.fullscreenEnter,
          onPressed: () => settings.setFullscreen(!on),
          icon: Icon(on ? Icons.fullscreen_exit : Icons.fullscreen),
        );
      },
    );
  }
}
