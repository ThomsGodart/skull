import '../engine/engine.dart';

/// What one seat receives from a game played somewhere — on this phone, or
/// on the host's — and how it answers.
///
/// A table shows a game from a feed alone, so it does not care where the
/// game runs.
abstract interface class SeatFeed {
  /// What the game is played with.
  GameConfig get config;

  /// The seat this feed is for.
  int get seat;

  /// Starts the game, or picks a resumed one up. Nothing comes before.
  void open();

  /// The events this seat may see that arrived since the last call, in order.
  List<Event> takeEvents();

  /// The question this seat must answer, if any. It only makes sense once
  /// every event has been taken and shown.
  Question? get question;

  /// Replies to [question]. Throws [IllegalAnswer] when it cannot be.
  void answer(Answer answer);

  /// Called whenever new events or a question are there to take.
  set onUpdate(void Function()? callback);

  /// Called when the game cannot go on.
  set onError(void Function(Object error)? callback);

  /// Tells the game that this seat has seen the final standings.
  void acknowledgeEnd(GameFinished result);

  void close();
}
