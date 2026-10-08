import 'package:flutter/services.dart';

/// Hides or restores the system bars (status / navigation).
Future<void> setAppFullscreen(bool enabled) async {
  await SystemChrome.setEnabledSystemUIMode(
    enabled ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
  );
}
