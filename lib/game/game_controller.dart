import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../bots/bot.dart';
import '../engine/engine.dart';
import 'local_table.dart';
import 'seat_feed.dart';
import 'table_speed.dart';

export 'local_table.dart' show GameProgress;
export 'table_speed.dart';
import '../engine/engine.dart' as engine show leadSuit;

/// Holds what the table shows of a game, for the seat of one [SeatFeed].
///
/// The game resolves everything at once, wherever it runs; this replays its
/// events one at a time, so the screen shows each card, each trick and each
/// round in turn.
class GameController extends ChangeNotifier {
  /// A game on this phone: one human against bots.
  factory GameController({
    required GameConfig config,
    required Bot bot,
    TableSpeed speed = TableSpeed.normal,
    int humanSeat = 0,
    List<Answer> savedAnswers = const [],
    void Function(GameProgress progress)? onProgress,
  }) => GameController.onFeed(
    LocalTable(
      config: config,
      bot: bot,
      savedAnswers: savedAnswers,
      humanSeats: {humanSeat},
      primarySeat: humanSeat,
      onProgress: onProgress,
    ).feedFor(humanSeat),
    speed: speed,
  );

  /// The table of the seat [feed] is for, wherever the game runs.
  GameController.onFeed(this._feed, {this.speed = TableSpeed.normal});

  final SeatFeed _feed;

  /// What the game is played with.
  GameConfig get config => _feed.config;

  final TableSpeed speed;

  /// The seat this table is seen from.
  int get humanSeat => _feed.seat;

  /// Seats at the table, the ghost's included when two play.
  int get seats => tableHands(config.players);

  /// The seat of Greybeard's ghost in a two-player game.
  int? get ghostSeat => seats > config.players ? seats - 1 : null;

  /// The seats that bid and score: every one but the ghost's.
  int get scoringSeats => config.players;

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

  /// The seats in the order they play the trick on the table, as the game
  /// last said.
  List<int> _order = const [];

  /// The pirate the plank threw out of the trick held on the table.
  Card? trickOverboard;

  /// What the trick held on the table brings to seats that did not win it.
  List<(int seat, Bonus bonus)> trickSideBonuses = const [];

  /// The card Mary makes the human play at their next turn.
  Card? forcedCard;

  /// The human's cards, sorted for reading.
  List<Card> hand = const [];

  /// Cards left in each seat's hand.
  List<int> handSizes = const [];

  /// One per seat; all null until the bids are revealed.
  List<int?> bids = const [];
  List<int> tricksWon = const [];
  late List<int> scores = List.filled(seats, 0);

  /// The cards on the table, in play order.
  List<Play> trick = const [];

  /// Set while a finished trick is still on the table.
  int? trickWinner;
  List<Bonus> trickBonuses = const [];

  /// The previous trick, once cleared from the table.
  List<Play>? lastTrick;
  int? lastTrickWinner;
  Card? lastTrickOverboard;

  /// Set when the human must bid.
  BidQuestion? bidQuestion;

  /// The bid the human placed, while the others are still choosing theirs.
  int? placedBid;
  BidQuestion? _lastBidQuestion;

  /// Tricks nobody won this round: destroyed by a sea monster, or thrown
  /// away. They explain why the tricks taken fall short of the cards dealt.
  int destroyedTricks = 0;

  /// What each seat staked with Rascal this round.
  Map<int, int> wagers = const {};

  /// The seats that won a trick with Harry this round, and so may move their
  /// bid at the end of it.
  Set<int> harrySeats = const {};

  /// Set when the human must play a card.
  PlayQuestion? playQuestion;

  /// Set when the human must decide how to use a pirate's power.
  AfterTrickQuestion? afterTrickQuestion;

  /// What a pirate's power is doing right now, for the table to announce: one
  /// of [PowerUsed], [LeaderChosen], [CardsDiscarded], [WagerPlaced] and
  /// [BidChanged]. It only stays long enough to be read.
  Event? powerNotice;

  /// Juanita's power, used by the human: the cards nobody was dealt, shown
  /// until [dismissStock].
  List<Card>? revealedStock;

  /// True while the trick held on the table was destroyed.
  bool trickDestroyed = false;

  /// The alliances the trick held on the table made.
  List<Alliance> trickAlliances = const [];

  /// Set when a round has just been scored and awaits [continueAfterRound].
  RoundScored? roundSummary;

  /// Every round scored so far, for the score sheet.
  final List<RoundScored> scoredRounds = [];

  /// Set once the game is over.
  GameFinished? result;

  /// True while the bids, just turned over, are left on show.
  bool get revealingBids => _revealingBids;

  /// How many tricks the players announced in all, once the bids are known.
  int? get totalBids {
    final known = bids.take(scoringSeats);
    if (bids.isEmpty || known.any((bid) => bid == null)) return null;
    return known.fold<int>(0, (sum, bid) => sum + bid!);
  }

  /// The seat that leads the trick on the table, or the one about to be
  /// played.
  int get leader => _leader;

  /// Whose turn it is to play a card, when a trick is open.
  int? get currentSeat {
    // The ghost bids nothing: only the scoring seats' bids are awaited.
    final bidsAreIn = bids.take(scoringSeats).every((bid) => bid != null);
    if (bids.isEmpty || !bidsAreIn || trickWinner != null) return null;
    if (_revealingBids) return null;
    if (roundSummary != null || result != null) return null;
    return _order.elementAtOrNull(trick.length);
  }

  /// The suit to follow in the trick on the table, if any.
  Suit? get leadSuit => engine.leadSuit(trick);

  /// Starts the game, or picks a resumed one up where it was left.
  void start() {
    _catchingUp = true;
    _feed
      ..onUpdate = (() => unawaited(_run()))
      ..onError = _fail
      ..open();
    unawaited(_run());
  }

  void _fail(Object error) {
    final report = onError;
    if (report == null) throw error;
    report(error);
  }

  /// Ignored unless the human is being asked to bid.
  void bid(int bid) {
    final question = bidQuestion;
    if (question == null) return;
    _lastBidQuestion = question;
    // Before the answer goes: the bids may be turned over at once.
    placedBid = bid;
    _answer(BidAnswer(seat: humanSeat, bid: bid));
    _notify();
  }

  /// Lets the human choose another bid, while the bids are not turned over.
  void changeBid() {
    if (placedBid == null || bidQuestion != null) return;
    bidQuestion = _lastBidQuestion;
    _notify();
  }

  /// What Harry does to a bid of [bid] after [tricksWon] tricks when left to
  /// himself: he moves it towards the tricks taken, if [changes] allow.
  static int harryChange(int bid, int tricksWon, List<int> changes) {
    final wanted = (tricksWon - bid).clamp(-1, 1);
    return changes.contains(wanted) ? wanted : 0;
  }

  /// Ignored unless the human is being asked to play.
  void play(
    Card card, {
    TigressMode? tigressAs,
    int? declaredValue,
    Suit? jokerSuit,
  }) {
    if (playQuestion == null) return;
    _answer(
      PlayAnswer(
        seat: humanSeat,
        card: card,
        tigressAs: tigressAs,
        declaredValue: declaredValue,
        jokerSuit: jokerSuit,
      ),
    );
  }

  /// Answers the pirate power the human is asked about. Ignored when there
  /// is none.
  void answerAfterTrick(Answer answer) {
    if (afterTrickQuestion == null) return;
    _answer(answer);
  }

  /// Moves on from the round summary to the next deal.
  void continueAfterRound() => _releaseHold();

  /// Closes the cards Juanita showed.
  void dismissStock() => _releaseHold();

  /// Cuts short the pause on a finished trick.
  void skipHold() {
    if (roundSummary == null && revealedStock == null) _releaseHold();
  }

  @override
  void dispose() {
    _disposed = true;
    _feed.close();
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
      while (!_disposed) {
        _events.addAll(_feed.takeEvents());
        if (_events.isNotEmpty) {
          await _show(_events.removeFirst());
          continue;
        }
        // Whatever a resumed game had already been through is now on screen.
        _catchingUp = false;
        final question = _feed.question;
        if (question != null && !identical(question, _asked)) {
          _asked = question;
          _ask(question);
        }
        break;
      }
    } finally {
      _running = false;
    }
  }

  /// The question already put to the human, so it is not asked twice.
  Question? _asked;

  /// Sends the human's [answer]. The question is taken off the table first,
  /// since the game may come back with the next thing to show at once; it is
  /// put back if the answer is refused.
  void _answer(Answer answer) {
    final asked = (bidQuestion, playQuestion, afterTrickQuestion);
    bidQuestion = null;
    playQuestion = null;
    afterTrickQuestion = null;
    try {
      _feed.answer(answer);
    } on Object {
      bidQuestion = asked.$1;
      playQuestion = asked.$2;
      afterTrickQuestion = asked.$3;
      rethrow;
    }
    unawaited(_run());
  }

  void _ask(Question question) {
    switch (question) {
      case BidQuestion():
        bidQuestion = question;
      case PlayQuestion():
        playQuestion = question;
      case AfterTrickQuestion():
        afterTrickQuestion = question;
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
        handSizes = List.filled(seats, event.cardsDealt);
        bids = List.filled(seats, null);
        tricksWon = List.filled(seats, 0);
        trick = const [];
        powerNotice = null;
        lastTrick = null;
        lastTrickWinner = null;
        lastTrickOverboard = null;
        forcedCard = null;
        placedBid = null;
        destroyedTricks = 0;
        wagers = const {};
        harrySeats = const {};
        _order = const [];
      case TurnsSet():
        _order = event.order;
      case HandDealt():
        hand = sortedHand(event.cards);
      case BidsRevealed():
        // The ghost bids nothing.
        bids = List<int?>.of(event.bids)..length = seats;
        placedBid = null;
        // Too late to change one's mind.
        bidQuestion = null;
        _revealingBids = true;
        _notify();
        await _wait(speed.bidReveal);
        _revealingBids = false;
      case CardPlayed(:final play):
        // Someone else's card takes a moment to come: the game itself, bots
        // included, runs faster than anyone could follow.
        if (play.seat != humanSeat) await _wait(speed.botPlay);
        powerNotice = null;
        trick = [...trick, play];
        handSizes = [
          for (var seat = 0; seat < seats; seat++)
            handSizes[seat] - (seat == play.seat ? 1 : 0),
        ];
        if (play.seat == humanSeat) {
          if (play.card == forcedCard) forcedCard = null;
          hand = [
            for (final card in hand)
              if (card != play.card) card,
          ];
        }
      case TrickWon():
        trickWinner = event.winner;
        trickBonuses = event.bonuses;
        trickDestroyed = event.destroyed;
        trickAlliances = event.alliances;
        trickOverboard = event.overboard;
        trickSideBonuses = event.sideBonuses;
        if (event.destroyed) destroyedTricks++;
        if (!event.destroyed) {
          tricksWon = [
            for (var seat = 0; seat < seats; seat++)
              tricksWon[seat] + (seat == event.winner ? 1 : 0),
          ];
        }
        _notify();
        await _holdFor(speed.trickHold);
        lastTrick = event.plays;
        lastTrickWinner = event.winner;
        lastTrickOverboard = event.overboard;
        trickOverboard = null;
        trickSideBonuses = const [];
        trick = const [];
        trickWinner = null;
        trickBonuses = const [];
        trickDestroyed = false;
        trickAlliances = const [];
        _leader = event.winner;
      case PowerUsed():
        // The human's own power needs no announcement: its question, or its
        // result, follows at once. Harry's is the exception, since nothing
        // happens until the round is over.
        if (event.pirate == Pirate.harry) {
          harrySeats = {...harrySeats, event.seat};
        }
        if (event.seat != humanSeat || event.pirate == Pirate.harry) {
          await _announce(event);
        }
      case LeaderChosen():
        _leader = event.leader;
        await _announce(event);
      case VictimChosen():
        await _announce(event);
      case CardForced():
        forcedCard = event.card;
      case CardsDrawn():
        hand = sortedHand([...hand, ...event.cards]);
      case OwnCardsDiscarded():
        if (event.cards.contains(forcedCard)) forcedCard = null;
        hand = [
          for (final card in hand)
            if (!event.cards.contains(card)) card,
        ];
      case CardsDiscarded():
        await _announce(event);
      case WagerPlaced():
        wagers = {...wagers, event.seat: event.amount};
        await _announce(event);
      case BidChanged():
        bids = [
          for (var seat = 0; seat < seats; seat++)
            seat == event.seat ? event.bid : bids[seat],
        ];
        await _announce(event);
      case StockRevealed():
        // Only as it happens: a resumed game does not show old reveals again.
        if (!_catchingUp) {
          revealedStock = event.cards;
          _notify();
          await _holdFor(null);
          revealedStock = null;
        }
      case RoundScored():
        scoredRounds.add(event);
        scores = [
          for (final result in event.results) result.totalScore,
          if (ghostSeat != null) 0,
        ];
        roundSummary = event;
        _notify();
        await _holdFor(null);
        roundSummary = null;
      case GameFinished():
        result = event;
        // Only now: a game left before its standings were seen stays
        // resumable, and is reported as over when it is opened again.
        _feed.acknowledgeEnd(event);
    }
    _notify();
  }

  /// Shows what a power just did, long enough to be read, then takes the
  /// sentence away.
  Future<void> _announce(Event outcome) async {
    if (_catchingUp) return;
    powerNotice = outcome;
    _notify();
    await _wait(speed.bidReveal);
    powerNotice = null;
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
      // A 0/14 goes after the 14 of its suit, a second 7 or 8 after the first.
      ? card.suit!.index * 100 + (card.value ?? 15) * 2 + card.copy
      : 1000 + card.kind.index * 10 + card.copy;
  return List.of(cards)..sort((a, b) => rank(a).compareTo(rank(b)));
}
