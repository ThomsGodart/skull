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
    this.deck = const [],
    this.roundTricks = const [],
    this.scoring = Scoring.classic,
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

  /// Every card the game is played with, in no telling order: everyone at
  /// the table knows what the deck holds.
  final List<Card> deck;

  /// The tricks already played this round, in order: everyone saw them.
  final List<List<Play>> roundTricks;

  /// How the round will be scored.
  final Scoring scoring;
}

/// A whole game of Skull King, with no user interface attached.
///
/// It never blocks: read [pending], reply with [answer], and render whatever
/// [takeEvents] returns. A bot and a human are driven the same way.
final class Game {
  Game(this.config) : _random = SeededRandom(config.seed) {
    if (config.players < minPlayers || config.players > maxPlayers) {
      throw ArgumentError.value(
        config.players,
        'players',
        'must be $minPlayers to $maxPlayers',
      );
    }
    if (config.startingRound < 1 || config.startingRound > standardRounds) {
      throw ArgumentError.value(
        config.startingRound,
        'startingRound',
        'must be 1 to $standardRounds',
      );
    }
    _dealer = _random.nextInt(config.players);
    // Skip early rounds without dealing them: the table asked to start later.
    _round = config.startingRound - 1;
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

  /// The tricks played so far this round.
  final List<List<Play>> _roundTricks = [];

  /// The cards nobody was dealt this round.
  List<Card> _stock = [];

  /// What each seat staked with Rascal this round.
  late List<int> _wagers;
  final List<Alliance> _alliances = [];

  /// The seat that won a trick with Harry this round, and so may change its
  /// bid once the round is played out.
  int? _harrySeat;

  /// A pirate power, or the plank, waiting for its player's decision.
  AfterTrickQuestion? _power;

  /// The powers still to be used for the trick just won: Mat hands his
  /// player those of every pirate he captured.
  final List<Pirate> _powersLeft = [];
  int _powerSeat = 0;

  /// The card each seat must play at its next turn, by Mary's doing.
  late List<Card?> _forced;

  /// The seat that fired the last salvo in the trick on the table.
  int? _salvoSeat;

  /// The seat that sits out the next trick it does not lead, having played
  /// two cards in an earlier one.
  int? _sitsOut;
  late final List<int> _scores = List.filled(config.players, 0);

  /// The players who bid and score.
  int get _players => config.players;

  /// Hands at the table: one per player, plus the ghost's when two play.
  int get seats => tableHands(config.players);

  /// The seat of Greybeard's ghost, who sits in when only two play: it bids
  /// nothing, scores nothing, and plays the top card of its packet.
  int? get ghostSeat => seats > _players ? seats - 1 : null;

  /// The seats in the order they play the trick on the table.
  List<int> _order = const [];

  /// The player who led the first trick of the round.
  int _roundStarter = 0;

  bool get isFinished => _finished;

  /// Every answer accepted so far, in order. With [config], this is the game.
  List<Answer> get answers => List.unmodifiable(_answers);

  /// The questions the game is waiting on: one per seat still to bid, or the
  /// single seat whose turn it is to play. Empty once the game is over.
  List<Question> get pending {
    if (_finished) return const [];
    if (_power case final power?) return [power];
    if (!_bidsRevealed) {
      return [
        for (var seat = 0; seat < _players; seat++)
          if (_bids[seat] == null) BidQuestion(seat: seat, maxBid: _cardsDealt),
      ];
    }
    final seat = _order[_trick.length];
    final forced = _forced[seat];
    return [
      PlayQuestion(
        seat: seat,
        // Mary's victim has no choice, whatever was led.
        legalCards: forced != null && _hands[seat].contains(forced)
            ? [forced]
            : legalCards(_hands[seat], _trick),
      ),
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
      for (var other = 0; other < seats; other++)
        _bidsRevealed || other == seat ? _bids[other] : null,
    ],
    tricksWon: List.unmodifiable(_tricksWon),
    trick: List.unmodifiable(_trick),
    scores: List.unmodifiable(_scores),
    deck: List.unmodifiable(deckFor(config)),
    roundTricks: List.unmodifiable(_roundTricks),
    scoring: config.scoring,
  );

  /// Applies [answer] and runs the game on to its next question.
  ///
  /// Throws [IllegalAnswer], leaving the game untouched, when the answer does
  /// not match a pending question.
  void answer(Answer answer) {
    var question = pending.where((q) => q.seat == answer.seat).firstOrNull;
    // A bid stays the player's own business until all are in: it may be
    // changed for as long as the bids are not turned over.
    if (question == null &&
        answer is BidAnswer &&
        !_finished &&
        !_bidsRevealed &&
        answer.seat >= 0 &&
        answer.seat < _players) {
      question = BidQuestion(seat: answer.seat, maxBid: _cardsDealt);
    }
    switch ((question, answer)) {
      case (null, WithdrawBidAnswer(:final seat))
          when !_finished &&
              !_bidsRevealed &&
              seat >= 0 &&
              seat < _players &&
              _bids[seat] != null:
        _bids[seat] = null;
        _events.add(BidWithdrawn(seat));
      case (final BidQuestion question, final BidAnswer answer):
        _bid(question, answer);
      case (final PlayQuestion question, final PlayAnswer answer):
        _play(question, answer);
      case (
        final ChooseLeaderQuestion question,
        final ChooseLeaderAnswer answer,
      ):
        if (!question.seats.contains(answer.leader)) {
          throw IllegalAnswer('seat ${answer.leader} cannot lead');
        }
        _leader = answer.leader;
        _startTrick();
        _events.add(LeaderChosen(seat: answer.seat, leader: answer.leader));
        _announceTurns();
        _powerDone();
      case (final WalkPlankQuestion question, final WalkPlankAnswer answer):
        if (!question.pirates.contains(answer.pirate)) {
          throw IllegalAnswer('${answer.pirate} cannot walk the plank');
        }
        _power = null;
        _settleTrick(overboard: answer.pirate);
      case (
        final ChooseVictimQuestion question,
        final ChooseVictimAnswer answer,
      ):
        if (!question.seats.contains(answer.victim)) {
          throw IllegalAnswer('seat ${answer.victim} holds no card');
        }
        final hand = _hands[answer.victim];
        final card = hand[_random.nextInt(hand.length)];
        _forced[answer.victim] = card;
        _events
          ..add(VictimChosen(seat: answer.seat, victim: answer.victim))
          ..add(CardForced(seat: answer.victim, card: card));
        _powerDone();
      case (final DiscardQuestion question, final DiscardAnswer answer):
        _discard(question, answer);
      case (final WagerQuestion question, final WagerAnswer answer):
        if (!question.amounts.contains(answer.amount)) {
          throw IllegalAnswer('${answer.amount} cannot be staked');
        }
        _wagers[answer.seat] = answer.amount;
        _events.add(WagerPlaced(seat: answer.seat, amount: answer.amount));
        _powerDone();
      case (final AdjustBidQuestion question, final AdjustBidAnswer answer):
        if (!question.changes.contains(answer.change)) {
          throw IllegalAnswer('the bid cannot move by ${answer.change}');
        }
        final bid = _bids[answer.seat]! + answer.change;
        _bids[answer.seat] = bid;
        if (answer.change != 0) {
          _events.add(BidChanged(seat: answer.seat, bid: bid));
        }
        _powerDone();
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
    _events.add(BidAccepted(answer.seat));
    final bids = _bids.take(_players);
    if (bids.contains(null)) return;
    _bidsRevealed = true;
    _events.add(BidsRevealed([for (final bid in bids) bid!]));
    _ghostPlays();
  }

  /// Ends the game with the scores as they stand. An unfinished round is
  /// abandoned (not scored). A tie for first names the lowest-numbered seat.
  void finishEarly() {
    if (_finished) return;
    _finished = true;
    _power = null;
    _powersLeft.clear();
    final best = _scores.isEmpty ? 0 : _scores.reduce((a, b) => a > b ? a : b);
    final winner =
        soleLeader(_scores) ??
        _scores.indexWhere((score) => score == best).clamp(0, _players - 1);
    _events.add(GameFinished(winner: winner, scores: List.of(_scores)));
  }

  void _play(PlayQuestion question, PlayAnswer answer) {
    final card = answer.card;
    if (!question.legalCards.contains(card)) {
      throw IllegalAnswer('$card may not be played now');
    }
    if ((card.kind == CardKind.tigress) != (answer.tigressAs != null)) {
      throw const IllegalAnswer('a tigress mode goes with the tigress only');
    }
    final declared = answer.declaredValue;
    if ((card.kind == CardKind.zeroFourteen) != (declared != null) ||
        (declared != null && declared != 0 && declared != 14)) {
      throw const IllegalAnswer('a 0/14, and only it, is played as 0 or 14');
    }
    // The joker names its suit only while the trick has none.
    final namesSuit = card.kind == CardKind.joker && suitIsOpen(_trick);
    final named = answer.jokerSuit;
    if (namesSuit != (named != null) ||
        (named != null && !jokerSuits.contains(named))) {
      throw const IllegalAnswer('the joker names a base suit when none is led');
    }
    _put(
      Play(
        seat: answer.seat,
        card: card,
        tigressAs: answer.tigressAs,
        declaredValue: declared,
        jokerSuit: card.kind == CardKind.joker
            ? named ?? inheritedJokerSuit(_trick)
            : null,
      ),
    );
    _ghostPlays();
  }

  void _put(Play play) {
    final hand = _hands[play.seat]..remove(play.card);
    if (_forced[play.seat] == play.card) _forced[play.seat] = null;
    _trick.add(play);
    _events.add(CardPlayed(play));
    // The last salvo: one more card from the same seat, once all have played
    // — unless it was that seat's last card.
    if (play.card.kind == CardKind.lastSalvo && hand.isNotEmpty) {
      _order = [..._order, play.seat];
      _salvoSeat = play.seat;
      _announceTurns();
    }
    if (_trick.length == _order.length) _finishTrick();
  }

  /// Plays for the ghost for as long as it is its turn: the top card of its
  /// packet, whatever was led, and its tigress as an escape.
  void _ghostPlays() {
    final ghost = ghostSeat;
    while (ghost != null &&
        !_finished &&
        _bidsRevealed &&
        _power == null &&
        !_roundOver &&
        _order[_trick.length] == ghost) {
      final card = _hands[ghost].first;
      _put(
        Play(
          seat: ghost,
          card: card,
          tigressAs: card.kind == CardKind.tigress ? TigressMode.escape : null,
        ),
      );
    }
  }

  /// Sets who plays in which order, now that [_leader] is known: everyone
  /// who still holds a card, but for the seat that sits this trick out. A
  /// seat that leads does not sit out: it will the trick after.
  void _startTrick() {
    final sitsOut = _sitsOut == _leader ? null : _sitsOut;
    _order = [
      for (final seat in playOrder(
        leader: _leader,
        seats: seats,
        ghost: ghostSeat,
        roundStarter: _roundStarter,
      ))
        if (_hands[seat].isNotEmpty && seat != sitsOut) seat,
    ];
  }

  /// Tells the table who plays the trick, once there is one to play.
  void _announceTurns() {
    if (_order.isNotEmpty) _events.add(TurnsSet(List.unmodifiable(_order)));
  }

  void _discard(DiscardQuestion question, DiscardAnswer answer) {
    final hand = _hands[answer.seat];
    final cards = answer.cards;
    if (cards.length != question.count ||
        cards.toSet().length != cards.length ||
        !cards.every(hand.contains)) {
      throw IllegalAnswer('${question.count} cards of the hand must go');
    }
    cards.forEach(hand.remove);
    if (cards.contains(_forced[answer.seat])) _forced[answer.seat] = null;
    _events
      ..add(CardsDiscarded(seat: answer.seat, count: cards.length))
      ..add(OwnCardsDiscarded(seat: answer.seat, cards: List.of(cards)));
    _powerDone();
  }

  /// The trick is played. The plank comes first: its player throws a named
  /// pirate out of it, and chooses which when there are several.
  void _finishTrick() {
    final plank = _trick
        .where((play) => play.card.kind == CardKind.plank)
        .firstOrNull;
    final pirates = [
      for (final play in _trick)
        if (play.isStandardPirate) play.card,
    ];
    if (plank == null || pirates.isEmpty) {
      _settleTrick();
    } else if (pirates.length == 1) {
      _settleTrick(overboard: pirates.single);
    } else {
      _power = WalkPlankQuestion(seat: plank.seat, pirates: pirates);
    }
  }

  void _settleTrick({Card? overboard}) {
    final plays = _trick;
    _roundTricks.add(List.unmodifiable(plays));
    final result = resolveTrick(plays, overboard: overboard);
    if (!result.destroyed) {
      _tricksWon[result.winner]++;
      _bonuses[result.winner].addAll(result.bonuses);
      _alliances.addAll(result.alliances);
    }
    for (final (seat, bonus) in result.sideBonuses) {
      _bonuses[seat].add(bonus);
    }
    // Whoever sat this trick out is back; whoever fired the salvo in it
    // sits out next.
    if (_sitsOut != null && !_order.contains(_sitsOut)) _sitsOut = null;
    if (_salvoSeat case final seat?) {
      _sitsOut = seat;
      _salvoSeat = null;
    }
    _leader = result.winner;
    _trick = [];
    _startTrick();
    _events.add(
      TrickWon(
        // Nobody won a destroyed trick: it only names who leads the next
        // one, and that is the seat after when the one meant has no card.
        winner: result.destroyed && _order.isNotEmpty
            ? _order.first
            : result.winner,
        plays: plays,
        bonuses: result.bonuses,
        alliances: result.alliances,
        destroyed: result.destroyed,
        overboard: overboard,
        sideBonuses: result.sideBonuses,
      ),
    );
    _announceTurns();
    // The ghost decides nothing: a pirate it wins with has no power.
    final winning = result.winningPlay;
    if (config.piratePowers && winning != null && result.winner != ghostSeat) {
      _powerSeat = result.winner;
      _powersLeft.addAll([
        ?Pirate.of(winning.card),
        // Mat uses the power of every pirate he captured.
        if (winning.isMat)
          for (final play in plays)
            if (play.card != overboard) ?Pirate.of(play.card),
      ]);
    }
    _nextPower();
  }

  /// Uses the powers the trick left to use, one at a time, then goes on.
  void _nextPower() {
    while (_power == null && _powersLeft.isNotEmpty) {
      _usePower(_powersLeft.removeAt(0), _powerSeat);
    }
    if (_power == null) _afterTrick();
  }

  bool get _roundOver => _hands.every((hand) => hand.isEmpty);

  /// Lets [seat] use the power of [pirate], which just won it a trick.
  ///
  /// After the last trick of a round only two still serve a purpose: Rascal,
  /// whose stake is on the bid, and Harry, whose question is in fact always
  /// asked then (see [_afterTrick]).
  void _usePower(Pirate pirate, int seat) {
    if (_roundOver && pirate != Pirate.harry && pirate != Pirate.rascal) {
      return;
    }
    switch (pirate) {
      case Pirate.rosie:
        _power = ChooseLeaderQuestion(
          seat: seat,
          // The ghost cannot be handed the lead.
          seats: [for (var other = 0; other < _players; other++) other],
        );
      case Pirate.will:
        // Whatever is left of the stock, two cards at most.
        final drawn = _stock.take(2).toList();
        if (drawn.isEmpty) return;
        _stock = _stock.sublist(drawn.length);
        _hands[seat].addAll(drawn);
        _events.add(PowerUsed(seat: seat, pirate: pirate));
        _events.add(CardsDrawn(seat: seat, cards: drawn));
        _power = DiscardQuestion(
          seat: seat,
          hand: List.unmodifiable(_hands[seat]),
          count: drawn.length,
        );
        return;
      case Pirate.rascal:
        _power = WagerQuestion(seat: seat, amounts: wagerAmounts);
      case Pirate.juanita:
        if (_stock.isEmpty) return;
        _events.add(PowerUsed(seat: seat, pirate: pirate));
        _events.add(
          StockRevealed(seat: seat, cards: List.unmodifiable(_stock)),
        );
        return;
      case Pirate.harry:
        // His power is kept for the end of the round, when its player knows
        // how many tricks they took.
        _harrySeat = seat;
      case Pirate.mary:
        // Only opponents: Mary never forces a card from her own hand.
        final victims = [
          for (var other = 0; other < _players; other++)
            if (other != seat && _hands[other].isNotEmpty) other,
        ];
        if (victims.isEmpty) return;
        _power = ChooseVictimQuestion(seat: seat, seats: victims);
    }
    _events.add(PowerUsed(seat: seat, pirate: pirate));
  }

  void _powerDone() {
    _power = null;
    _nextPower();
  }

  void _afterTrick() {
    if (!_roundOver) {
      _ghostPlays();
    } else if (_harrySeat case final seat?) {
      // The round is played out: whoever won a trick with Harry may now move
      // their bid, before it is scored.
      _harrySeat = null;
      _power = AdjustBidQuestion(
        seat: seat,
        changes: bidChangesFor(_bids[seat]!, _cardsDealt),
      );
    } else {
      _finishRound();
    }
  }

  void _finishRound() {
    final results = <SeatResult>[];
    bool made(int seat) => _bids[seat] == _tricksWon[seat];
    for (var seat = 0; seat < _players; seat++) {
      final score = scoreRound(
        bid: _bids[seat]!,
        tricksWon: _tricksWon[seat],
        cardsDealt: _cardsDealt,
        bonuses: _bonuses[seat],
        scoring: config.scoring,
        // An alliance counts once its other member made their bid too.
        alliancesMade: alliancesMadeBy(seat, _alliances, made),
        wager: _wagers[seat],
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

    final winner = soleLeader(_scores);
    // A tie for first place after round ten is played off, one round at a time.
    if (_round >= standardRounds && winner != null) {
      _finished = true;
      _events.add(GameFinished(winner: winner, scores: List.of(_scores)));
      return;
    }
    // Whoever led this round deals the next one.
    _dealer = (_dealer + 1) % _players;
    _startRound();
  }

  void _startRound() {
    _round++;
    _cardsDealt = cardsDealt(
      round: _round,
      players: _players,
      secondExpansion: config.playsSecondExpansion,
    );
    _leader = (_dealer + 1) % _players;
    _roundStarter = _leader;
    _bidsRevealed = false;
    _bids = List.filled(seats, null);
    _tricksWon = List.filled(seats, 0);
    _bonuses = List.generate(seats, (_) => []);
    _wagers = List.filled(seats, 0);
    _alliances.clear();
    _harrySeat = null;
    _roundTricks.clear();
    _forced = List.filled(seats, null);
    _salvoSeat = null;
    _sitsOut = null;
    _trick = [];
    final deck = deckFor(config);
    _random.shuffle(deck);
    _hands = [
      for (var seat = 0; seat < seats; seat++)
        deck.sublist(seat * _cardsDealt, (seat + 1) * _cardsDealt),
    ];
    _stock = deck.sublist(seats * _cardsDealt);
    _startTrick();
    _events.add(
      RoundStarted(
        round: _round,
        cardsDealt: _cardsDealt,
        dealer: _dealer,
        leader: _leader,
      ),
    );
    _announceTurns();
    for (var seat = 0; seat < _players; seat++) {
      _events.add(
        HandDealt(seat: seat, cards: List.unmodifiable(_hands[seat])),
      );
    }
  }
}
