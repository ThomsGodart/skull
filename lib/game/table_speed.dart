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

  /// No waiting at all, for tests.
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
