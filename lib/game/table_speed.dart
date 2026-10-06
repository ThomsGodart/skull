import '../settings/app_settings.dart';

/// How long the table lingers so a human can follow it.
final class TableSpeed {
  const TableSpeed({
    required this.botPlay,
    required this.trickHold,
    required this.bidReveal,
  });

  static const normal = TableSpeed(
    botPlay: Duration(milliseconds: 700),
    trickHold: Duration(milliseconds: 1200),
    bidReveal: Duration(milliseconds: 900),
  );

  /// No waiting at all: for tests, not for play.
  static const instant = TableSpeed(
    botPlay: Duration.zero,
    trickHold: Duration.zero,
    bidReveal: Duration.zero,
  );

  /// Before a bot puts its card down.
  final Duration botPlay;

  /// A finished trick stays on the table this long, unless skipped.
  final Duration trickHold;

  /// After the bids are turned over.
  final Duration bidReveal;
}

/// The pace of the table for each bot speed the player can choose.
extension BotSpeedPace on BotSpeed {
  TableSpeed get table => switch (this) {
    BotSpeed.normal => TableSpeed.normal,
    BotSpeed.fast => const TableSpeed(
      botPlay: Duration(milliseconds: 250),
      trickHold: Duration(milliseconds: 800),
      bidReveal: Duration(milliseconds: 500),
    ),
    // The bots answer at once, yet a finished trick still stays a moment:
    // unlike [TableSpeed.instant], this one is meant for a human.
    BotSpeed.instant => const TableSpeed(
      botPlay: Duration.zero,
      trickHold: Duration(milliseconds: 600),
      bidReveal: Duration(milliseconds: 300),
    ),
  };
}
