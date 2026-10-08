import '../bots/bot.dart';
import '../engine/engine.dart';
import 'seat_feed.dart';

/// Where a game stands after an answer: what it takes to save it.
final class GameProgress {
  const GameProgress({
    required this.answers,
    required this.round,
    required this.humanScore,
    this.rounds = const [],
    this.result,
  });

  /// Every answer given since the start of the game.
  final List<Answer> answers;
  final int round;
  final int humanScore;

  /// Every round scored so far.
  final List<RoundScored> rounds;

  /// Set once, when the final standings were shown.
  final GameFinished? result;
}

/// A game running on this phone: the engine, the bots that play the seats
/// nobody holds, and a feed for each seat held by a person.
///
/// The engine and the bots run at once; whoever shows a feed paces it.
class LocalTable {
  LocalTable({
    required this.config,
    required this.bot,
    List<Answer> savedAnswers = const [],
    Set<int> humanSeats = const {0},
    this.primarySeat = 0,
    this.onProgress,
  }) : _game = Game.replay(config, savedAnswers) {
    for (final seat in humanSeats) {
      _feeds[seat] = _LocalFeed(this, seat);
    }
  }

  final GameConfig config;
  final Bot bot;

  /// The seat whose score [onProgress] reports: the one of this phone's owner.
  final int primarySeat;

  /// Called after every answer, the bots' included.
  final void Function(GameProgress progress)? onProgress;

  final Game _game;
  final Map<int, _LocalFeed> _feeds = {};

  /// Seats held by a person for whom a bot plays for now.
  final Set<int> _autopilot = {};
  final List<RoundScored> _rounds = [];
  bool _open = false;

  /// The feed of [seat], which must be one of the human seats.
  SeatFeed feedFor(int seat) => _feeds[seat]!;

  /// Lets a bot play for [seat] while its player is away, or hands it back.
  void setAutopilot(int seat, {required bool on}) {
    if (on ? !_autopilot.add(seat) : !_autopilot.remove(seat)) return;
    if (_open) _pump();
  }

  /// Ends the game now: the unfinished round is dropped.
  void finishEarly() {
    if (_game.isFinished) return;
    _game.finishEarly();
    _distribute();
    for (final feed in _feeds.values) {
      feed._question = null;
    }
    for (final feed in _feeds.values.toList()) {
      feed._onUpdate?.call();
    }
  }

  /// Every answer accepted so far, in order.
  List<Answer> get answers => _game.answers;

  bool _isBot(int seat) =>
      !_feeds.containsKey(seat) || _autopilot.contains(seat);

  void _openOnce() {
    if (_open) return;
    _open = true;
    _pump();
  }

  void _answer(Answer answer) {
    _game.answer(answer);
    _report(null);
    _pump();
  }

  /// Hands out what happened, lets the bots answer what they are asked, and
  /// leaves each person their question.
  void _pump() {
    try {
      while (true) {
        _distribute();
        final forBots = _game.pending.where((q) => _isBot(q.seat));
        if (forBots.isEmpty) break;
        final question = forBots.first;
        _game.answer(bot(question, _game.viewFor(question.seat)));
        _report(null);
      }
    } on Object catch (error) {
      // Left unreported, a failing bot would freeze the table for good.
      final feed = _feeds[primarySeat] ?? _feeds.values.first;
      final report = feed._onError;
      if (report == null) rethrow;
      report(error);
      return;
    }
    final pending = _game.pending;
    for (final feed in _feeds.values) {
      feed._question = pending
          .where((question) => question.seat == feed.seat)
          .firstOrNull;
    }
    for (final feed in _feeds.values.toList()) {
      feed._onUpdate?.call();
    }
  }

  void _distribute() {
    for (final event in _game.takeEvents()) {
      if (event is RoundScored) _rounds.add(event);
      for (final feed in _feeds.values) {
        if (event.audience == null || event.audience == feed.seat) {
          feed._events.add(event);
        }
      }
    }
  }

  void _report(GameFinished? result) {
    final report = onProgress;
    if (report == null) return;
    final view = _game.viewFor(primarySeat);
    report(
      GameProgress(
        answers: _game.answers,
        round: view.round,
        humanScore: view.scores[primarySeat],
        rounds: List.unmodifiable(
          // Rounds may still sit in the engine, not handed out yet.
          [..._rounds],
        ),
        result: result,
      ),
    );
  }
}

class _LocalFeed implements SeatFeed {
  _LocalFeed(this._table, this.seat);

  final LocalTable _table;
  final List<Event> _events = [];
  Question? _question;
  void Function()? _onUpdate;
  void Function(Object error)? _onError;

  @override
  final int seat;

  @override
  GameConfig get config => _table.config;

  @override
  void open() => _table._openOnce();

  @override
  List<Event> takeEvents() {
    final events = List.of(_events);
    _events.clear();
    return events;
  }

  @override
  Question? get question => _question;

  @override
  void answer(Answer answer) => _table._answer(answer);

  @override
  set onUpdate(void Function()? callback) => _onUpdate = callback;

  @override
  set onError(void Function(Object error)? callback) => _onError = callback;

  @override
  void acknowledgeEnd(GameFinished result) {
    if (seat == _table.primarySeat) _table._report(result);
  }

  @override
  void finishEarly() => _table.finishEarly();

  @override
  void close() {
    _onUpdate = null;
    _onError = null;
  }
}
