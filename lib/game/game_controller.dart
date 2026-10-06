import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../bots/bot.dart';
import '../engine/engine.dart';
import '../engine/engine.dart' as engine show leadSuit;

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

/// Where a game stands after an answer: what it takes to save it.
final class GameProgress {
  const GameProgress({
    required this.answers,
    required this.round,
    required this.humanScore,
    this.result,
  });

  /// Every answer given since the start of the game.
  final List<Answer> answers;
  final int round;
  final int humanScore;

  /// Set once, when the final standings are shown.
  final GameFinished? result;
}

/// Runs a game for one human against bots, and holds what the table shows.
///
/// The engine resolves everything at once; this replays its events one at a
/// time, so the screen shows each card, each trick and each round in turn.
class GameController extends ChangeNotifier {
  GameController({
    required GameConfig config,
    required this.bot,
    this.speed = TableSpeed.normal,
    this.humanSeat = 0,
    List<Answer> savedAnswers = const [],
    this.onProgress,
  }) : _game = Game.replay(config, savedAnswers),
       players = config.players;

  /// Called after every answer, the bots' included.
  final void Function(GameProgress progress)? onProgress;

  final Bot bot;
  final TableSpeed speed;
  final int humanSeat;
  final int players;

  final Game _game;
  final Queue<Event> _events = Queue();
  bool _running = false;

  /// True while the events of a resumed game are applied in one go.
  bool _catchingUp = false;

  /// True while the revealed bids are left on show, before anyone plays.
  bool _revealingBids = false;

  /// Called when the game cannot go on, for instance because a bot failed.
  void Function(Object error)? onError;
  bool _disposed = false;
  Completer<void>? _hold;
  Timer? _waitTimer;
  Completer<void>? _waitDone;

  int round = 0;
  int cardsDealt = 0;
  int dealer = 0;
  int _leader = 0;

  /// The human's cards, sorted for reading.
  List<Card> hand = const [];

  /// Cards left in each seat's hand.
  List<int> handSizes = const [];

  /// One per seat; all null until the bids are revealed.
  List<int?> bids = const [];
  List<int> tricksWon = const [];
  late List<int> scores = List.filled(players, 0);

  /// The cards on the table, in play order.
  List<Play> trick = const [];

  /// Set while a finished trick is still on the table.
  int? trickWinner;
  List<Bonus> trickBonuses = const [];

  /// The previous trick, once cleared from the table.
  List<Play>? lastTrick;
  int? lastTrickWinner;

  /// Set when the human must bid.
  BidQuestion? bidQuestion;

  /// Set when the human must play a card.
  PlayQuestion? playQuestion;

  /// Set when a round has just been scored and awaits [continueAfterRound].
  RoundScored? roundSummary;

  /// Every round scored so far, for the score sheet.
  final List<RoundScored> scoredRounds = [];

  /// Set once the game is over.
  GameFinished? result;

  /// Whose turn it is to play a card, when a trick is open.
  int? get currentSeat {
    if (!bids.every((bid) => bid != null) || trickWinner != null) return null;
    if (_revealingBids) return null;
    if (roundSummary != null || result != null) return null;
    return (_leader + trick.length) % players;
  }

  /// The suit to follow in the trick on the table, if any.
  Suit? get leadSuit => engine.leadSuit(trick);

  /// Starts the game, or picks a resumed one up where it was left.
  void start() {
    _catchingUp = true;
    unawaited(_run());
  }

  /// Ignored unless the human is being asked to bid.
  void bid(int bid) {
    if (bidQuestion == null) return;
    _answer(BidAnswer(seat: humanSeat, bid: bid));
    bidQuestion = null;
    unawaited(_run());
  }

  /// Ignored unless the human is being asked to play.
  void play(Card card, {TigressMode? tigressAs}) {
    if (playQuestion == null) return;
    _answer(PlayAnswer(seat: humanSeat, card: card, tigressAs: tigressAs));
    playQuestion = null;
    unawaited(_run());
  }

  /// Moves on from the round summary to the next deal.
  void continueAfterRound() => _releaseHold();

  /// Cuts short the pause on a finished trick.
  void skipHold() {
    if (roundSummary == null) _releaseHold();
  }

  @override
  void dispose() {
    _disposed = true;
    _releaseHold();
    _waitTimer?.cancel();
    if (_waitDone case final done? when !done.isCompleted) done.complete();
    super.dispose();
  }

  void _releaseHold() {
    final hold = _hold;
    _hold = null;
    if (hold != null && !hold.isCompleted) hold.complete();
  }

  Future<void> _run() async {
    if (_running) return;
    _running = true;
    try {
      await _advance();
    } catch (error) {
      // Left unreported, a failing bot would freeze the table for good.
      final report = onError;
      if (report == null) rethrow;
      report(error);
    } finally {
      _running = false;
    }
  }

  Future<void> _advance() async {
    while (!_disposed) {
      _collectEvents();
      if (_events.isNotEmpty) {
        await _show(_events.removeFirst());
        continue;
      }
      // Whatever a resumed game had already been through is now on screen.
      _catchingUp = false;
      final questions = _game.pending;
      if (questions.isEmpty) break;
      final forBots = questions.where((q) => q.seat != humanSeat);
      if (forBots.isEmpty) {
        _ask(questions.single);
        break;
      }
      final question = forBots.first;
      if (question is PlayQuestion) await _wait(speed.botPlay);
      if (_disposed) break;
      _answer(bot(question, _game.viewFor(question.seat)));
    }
  }

  void _collectEvents() => _events.addAll(
    _game.takeEvents().where(
      (event) => event.audience == null || event.audience == humanSeat,
    ),
  );

  void _answer(Answer answer) {
    _game.answer(answer);
    _collectEvents();
    _report(null);
  }

  void _report(GameFinished? result) {
    final view = _game.viewFor(humanSeat);
    onProgress?.call(
      GameProgress(
        answers: _game.answers,
        round: view.round,
        humanScore: view.scores[humanSeat],
        result: result,
      ),
    );
  }

  void _ask(Question question) {
    switch (question) {
      case BidQuestion():
        bidQuestion = question;
      case PlayQuestion():
        playQuestion = question;
    }
    _notify();
  }

  Future<void> _show(Event event) async {
    switch (event) {
      case RoundStarted():
        round = event.round;
        cardsDealt = event.cardsDealt;
        dealer = event.dealer;
        _leader = event.leader;
        handSizes = List.filled(players, event.cardsDealt);
        bids = List.filled(players, null);
        tricksWon = List.filled(players, 0);
        trick = const [];
        lastTrick = null;
        lastTrickWinner = null;
      case HandDealt():
        hand = sortedHand(event.cards);
      case BidsRevealed():
        bids = List.of(event.bids);
        _revealingBids = true;
        _notify();
        await _wait(speed.bidReveal);
        _revealingBids = false;
      case CardPlayed(:final play):
        trick = [...trick, play];
        handSizes = [
          for (var seat = 0; seat < players; seat++)
            handSizes[seat] - (seat == play.seat ? 1 : 0),
        ];
        if (play.seat == humanSeat) {
          hand = [
            for (final card in hand)
              if (card != play.card) card,
          ];
        }
      case TrickWon():
        trickWinner = event.winner;
        trickBonuses = event.bonuses;
        tricksWon = [
          for (var seat = 0; seat < players; seat++)
            tricksWon[seat] + (seat == event.winner ? 1 : 0),
        ];
        _notify();
        await _holdFor(speed.trickHold);
        lastTrick = event.plays;
        lastTrickWinner = event.winner;
        trick = const [];
        trickWinner = null;
        trickBonuses = const [];
        _leader = event.winner;
      case RoundScored():
        scoredRounds.add(event);
        scores = [for (final result in event.results) result.totalScore];
        roundSummary = event;
        _notify();
        await _holdFor(null);
        roundSummary = null;
      case GameFinished():
        result = event;
        // Only now: a game left before its standings were seen stays
        // resumable, and is reported as over when it is opened again.
        _report(event);
    }
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  /// Waits for [duration]. Cut short when the controller is disposed, so no
  /// timer outlives the table.
  Future<void> _wait(Duration duration) {
    if (duration == Duration.zero || _catchingUp || _disposed) {
      return Future.value();
    }
    final done = Completer<void>();
    _waitTimer = Timer(duration, done.complete);
    _waitDone = done;
    return done.future;
  }

  /// Waits until released, or for [duration] at most when one is given.
  Future<void> _holdFor(Duration? duration) async {
    if (duration == Duration.zero || _disposed || _catchingUp) return;
    final hold = _hold = Completer<void>();
    final timer = duration == null ? null : Timer(duration, _releaseHold);
    await hold.future;
    timer?.cancel();
  }
}

/// [cards] in reading order: green, yellow, purple, black by rising value,
/// then the special cards.
List<Card> sortedHand(List<Card> cards) {
  int rank(Card card) => card.isNumber
      ? card.suit!.index * 100 + card.value!
      : 1000 + card.kind.index * 10 + card.copy;
  return List.of(cards)..sort((a, b) => rank(a).compareTo(rank(b)));
}
