import 'package:flutter/services.dart';

/// The system vibration: a long press on Android, the full vibrator on
/// iPhone, both well above the light taps of the rest of the table.
Future<void> turnBuzz() => HapticFeedback.vibrate();
