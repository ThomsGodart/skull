import 'dart:js_interop';

import 'package:web/web.dart';

/// Two pulses, where the browser can vibrate (not Safari on iPhone).
Future<void> turnBuzz() async {
  try {
    window.navigator.vibrate(<JSNumber>[180.toJS, 90.toJS, 180.toJS].toJS);
  } on Object {
    // No vibrator, or the page may not use it: nothing to say.
  }
}
