import 'package:wakelock_plus/wakelock_plus.dart';

/// Keeps the screen from sleeping while a game is on the table.
abstract interface class ScreenAwake {
  Future<void> keepOn();
  Future<void> release();
}

class WakelockScreenAwake implements ScreenAwake {
  const WakelockScreenAwake();

  @override
  Future<void> keepOn() => _guard(WakelockPlus.enable);

  @override
  Future<void> release() => _guard(WakelockPlus.disable);

  /// A screen that sleeps is an annoyance, never a reason to crash.
  Future<void> _guard(Future<void> Function() call) async {
    try {
      await call();
    } on Object {
      // Not available on this device: the game goes on without it.
    }
  }
}
