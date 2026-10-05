import 'card.dart';
import 'deck.dart';
import 'protocol.dart';
import 'scoring.dart';
import 'seeded_random.dart';
import 'trick.dart';

/// What one seat is allowed to see of a game.
final class GameView {
  const GameView({
    required this.seat,
    required this.round,
    required this.cardsDealt,
    required this.dealer,
    required this.hand,
    required this.handSizes,
    required this.bids,
    required this.tricksWon,
    required this.trick,
    required this.scores,
  });

  final int seat;
  final int round;
  final int cardsDealt;
  final int dealer;

  /// The cards of [seat] only.
  final List<Card> hand;

  /// Cards left in each seat's hand.
  final List<int> handSizes;

  /// One entry per seat. Until bids are revealed, only the bid of [seat] is
  /// known; the others are null.
  final List<int?> bids;
  final List<int> tricksWon;

  /// The cards on the table, in play order.
  final List<Play> trick;

  /// Total score per seat, up to the last scored round.
  final List<int> scores;
}

/// A whole game of Skull King, with no user interface attached.
///
/// It never blocks: read [pending], reply with [answer], and render whatever
/// [takeEvents] returns. A bot and a human are driven the same way.
final class Game {
  Game(this.config) : _random = SeededRandom(config.seed) {
    if (config.players < 3 || config.players > 8) {
      throw ArgumentError.value(config.players, 'players', 'must be 3 to 8');
    }
    _dealer = _random.nextInt(config.players);
    _startRound();
  }

  /// Rebuilds a game from its [config] and the [answers] given so far.
  factory Game.replay(GameConfig config, Iterable<Answer> answers) {
    final game = Game(config);
    answers.forEach(game.answer);
    return game;
  }

  final GameConfig config;
  final SeededRandom _random;
  final List<Answer> _answers = [];
  final List<Event> _events = [];

  int _round = 0;
  int _cardsDealt = 0;
  int _dealer = 0;
  int _leader = 0;
  bool _bidsRevealed = false;
  bool _finished = false;
  late List<List<Card>> _hands;
  late List<int?> _bids;
  late List<int> _tricksWon;
  late List<List<Bonus>> _bonuses;
  List<Play> _trick = [];
  late final List<int> _scores = List.filled(config.players, 0);

  int get _players => config.players;

  bool get isFinished => _finished;

  /// Every answer accepted so far, in order. With [config], this is the game.
  List<Answer> get answers => List.unmodifiable(_answers);

  /// The questions the game is waiting on: one per seat still to bid, or the
  /// single seat whose turn it is to play. Empty once the game is over.
  List<Question> get pending {
    if (_finished) return const [];
    if (!_bidsRevealed) {
      return [
        for (var seat = 0; seat < _players; seat++)
          if (_bids[seat] == null) BidQuestion(seat: seat, maxBid: _cardsDealt),
      ];
    }
    final seat = (_leader + _trick.length) % _players;
    return [
      PlayQuestion(seat: seat, legalCards: legalCards(_hands[seat], _trick)),
    ];
  }

  /// Everything that happened since the last call, in order.
  List<Event> takeEvents() {
    final events = List.of(_events);
    _events.clear();
    return events;
  }

  GameView viewFor(int seat) => GameView(
    seat: seat,
    round: _round,
    cardsDealt: _cardsDealt,
    dealer: _dealer,
    hand: List.unmodifiable(_hands[seat]),
    handSizes: [for (final hand in _hands) hand.length],
    bids: [
      for (var other = 0; other < _players; other++)
        _bidsRevealed || other == seat ? _bids[other] : null,
    ],
    tricksWon: List.unmodifiable(_tricksWon),
    trick: List.unmodifiable(_trick),
    scores: List.unmodifiable(_scores),
  );

  /// Applies [answer] and runs the game on to its next question.
  ///
  /// Throws [IllegalAnswer], leaving the game untouched, when the answer does
  /// not match a pending question.
  void answer(Answer answer) {
    final question = pending.where((q) => q.seat == answer.seat).firstOrNull;
    switch ((question, answer)) {
      case (final BidQuestion question, final BidAnswer answer):
        _bid(question, answer);
      case (final PlayQuestion question, final PlayAnswer answer):
        _play(question, answer);
      default:
        throw IllegalAnswer('seat ${answer.seat} is not asked for this');
    }
    _answers.add(answer);
  }

  void _bid(BidQuestion question, BidAnswer answer) {
    if (answer.bid < 0 || answer.bid > question.maxBid) {
      throw IllegalAnswer('bid ${answer.bid} is not in 0..${question.maxBid}');
    }
    _bids[answer.seat] = answer.bid;
    if (_bids.contains(null)) return;
    _bidsRevealed = true;
    _events.add(BidsRevealed([for (final bid in _bids) bid!]));
  }

  void _play(PlayQuestion question, PlayAnswer answer) {
    final card = answer.card;
    if (!question.legalCards.contains(card)) {
      throw IllegalAnswer('$card may not be played now');
    }
    if ((card.kind == CardKind.tigress) != (answer.tigressAs != null)) {
      throw const IllegalAnswer('a tigress mode goes with the tigress only');
    }
    _hands[answer.seat].remove(card);
    final play = Play(
      seat: answer.seat,
      card: card,
      tigressAs: answer.tigressAs,
    );
    _trick.add(play);
    _events.add(CardPlayed(play));
    if (_trick.length == _players) _finishTrick();
  }

  void _finishTrick() {
    final result = resolveTrick(_trick);
    _tricksWon[result.winner]++;
    _bonuses[result.winner].addAll(result.bonuses);
    _events.add(
      TrickWon(winner: result.winner, plays: _trick, bonuses: result.bonuses),
    );
    _leader = result.winner;
    _trick = [];
    if (_hands.first.isEmpty) _finishRound();
  }

  void _finishRound() {
    final results = <SeatResult>[];
    for (var seat = 0; seat < _players; seat++) {
      final score = scoreRound(
        bid: _bids[seat]!,
        tricksWon: _tricksWon[seat],
        cardsDealt: _cardsDealt,
        bonuses: _bonuses[seat],
      );
      _scores[seat] += score.total;
      results.add(
        SeatResult(
          bid: _bids[seat]!,
          tricksWon: _tricksWon[seat],
          bonuses: List.unmodifiable(_bonuses[seat]),
          score: score,
          totalScore: _scores[seat],
        ),
      );
    }
    _events.add(RoundScored(round: _round, results: results));

    final best = _scores.reduce((a, b) => a > b ? a : b);
    final topSeats = [
      for (var seat = 0; seat < _players; seat++)
        if (_scores[seat] == best) seat,
    ];
    // A tie for first place after round ten is played off, one round at a time.
    if (_round >= standardRounds && topSeats.length == 1) {
      _finished = true;
      _events.add(
        GameFinished(winner: topSeats.single, scores: List.of(_scores)),
      );
      return;
    }
    // Whoever led this round deals the next one.
    _dealer = (_dealer + 1) % _players;
    _startRound();
  }

  void _startRound() {
    _round++;
    _cardsDealt = cardsDealt(round: _round, players: _players);
    _leader = (_dealer + 1) % _players;
    _bidsRevealed = false;
    _bids = List.filled(_players, null);
    _tricksWon = List.filled(_players, 0);
    _bonuses = List.generate(_players, (_) => []);
    _trick = [];
    final deck = baseDeck();
    _random.shuffle(deck);
    _hands = [
      for (var seat = 0; seat < _players; seat++)
        deck.sublist(seat * _cardsDealt, (seat + 1) * _cardsDealt),
    ];
    _events.add(
      RoundStarted(
        round: _round,
        cardsDealt: _cardsDealt,
        dealer: _dealer,
        leader: _leader,
      ),
    );
    for (var seat = 0; seat < _players; seat++) {
      _events.add(
        HandDealt(seat: seat, cards: List.unmodifiable(_hands[seat])),
      );
    }
  }
}
