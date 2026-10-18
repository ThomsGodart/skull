import 'turn_buzz_stub.dart'
    if (dart.library.html) 'turn_buzz_web.dart'
    if (dart.library.io) 'turn_buzz_io.dart'
    as impl;

/// A firm buzz that says the turn has come: stronger than a key tap, felt
/// with the phone in a pocket or on the table.
Future<void> turnBuzz() => impl.turnBuzz();
