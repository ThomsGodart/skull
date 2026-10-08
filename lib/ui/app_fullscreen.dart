import 'app_fullscreen_stub.dart'
    if (dart.library.html) 'app_fullscreen_web.dart'
    if (dart.library.io) 'app_fullscreen_io.dart'
    as impl;

/// Puts the app in fullscreen (immersive system UI on phones, page fullscreen
/// on the web) or leaves it. Triggered from in-app controls only.
Future<void> setAppFullscreen(bool enabled) => impl.setAppFullscreen(enabled);
