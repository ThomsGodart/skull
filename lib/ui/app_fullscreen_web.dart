import 'package:web/web.dart';

/// Enters or leaves the page fullscreen from an in-app control (not the
/// browser chrome).
Future<void> setAppFullscreen(bool enabled) async {
  final doc = document;
  if (enabled) {
    if (doc.fullscreenElement == null) {
      doc.documentElement?.requestFullscreen();
    }
  } else if (doc.fullscreenElement != null) {
    doc.exitFullscreen();
  }
}
