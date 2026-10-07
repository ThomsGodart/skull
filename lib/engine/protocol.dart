import 'card.dart';
import 'scoring.dart';
import 'trick.dart';

/// Fewest and most seats a game can have.
const minPlayers = 2;
const maxPlayers = 8;

/// How a round is scored.
enum Scoring {
  /// The rulebook's scoring: 20 per trick for a made bid, losses otherwise.
  classic,

  /// "The Rascal's Scoring": the same potential for everyone, earned in full
  /// on an exact bid, by half when one trick off, not at all beyond.
  rascal,
}

/// What defines a game before anything is answered.
final class GameConfig {
  const GameConfig({
    required this.players,
    required this.seed,
    this.scoring = Scoring.classic,
    this.kraken = false,
    this.whiteWhale = false,
    this.loot = false,
    this.piratePowers = false,
    this.secondExpansion = false,
    this.leftOut = const {},
  });

  factory GameConfig.fromJson(Map<String, Object?> json) => GameConfig(
    players: json['players']! as int,
    seed: json['seed']! as int,
    // Absent from games saved before these options existed.
    scoring: Scoring.values.byName(
      json['scoring'] as String? ?? Scoring.classic.name,
    ),
    kraken: json['kraken'] as bool? ?? false,
    whiteWhale: json['whiteWhale'] as bool? ?? false,
    loot: json['loot'] as bool? ?? false,
    piratePowers: json['piratePowers'] as bool? ?? false,
    secondExpansion: json['secondExpansion'] as bool? ?? false,
    leftOut: {
      for (final kind in json['leftOut'] as List? ?? const [])
        CardKind.values.byName(kind as String),
    },
  );

  /// Seats at the table, [minPlayers] to [maxPlayers].
  final int players;

  /// Seeds every shuffle and the choice of the first dealer: the same seed and
  /// the same answers always give the same game.
  final int seed;

  final Scoring scoring;

  /// Expansion cards shuffled into the deck, each on its own.
  final bool kraken;
  final bool whiteWhale;
  final bool loot;

  /// A pirate that wins a trick lets its player use that pirate's power.
  final bool piratePowers;

  /// The 19 cards of the second expansion are shuffled into the deck.
  final bool secondExpansion;

  /// The cards of the second expansion the table chose to do without, among
  /// [optionalKinds].
  final Set<CardKind> leftOut;

  /// The cards of the second expansion that may be left out; the others
  /// always come with it.
  static const optionalKinds = [
    CardKind.mat,
    CardKind.plank,
    CardKind.stingray,
    CardKind.lastSalvo,
    CardKind.davyJones,
  ];

  /// The second expansion is asked for and can be played: its cards call for
  /// choices the ghost of a two-player game cannot make.
  bool get playsSecondExpansion => secondExpansion && players > 2;

  GameConfig copyWith({
    int? players,
    int? seed,
    Scoring? scoring,
    bool? kraken,
    bool? whiteWhale,
    bool? loot,
    bool? piratePowers,
    bool? secondExpansion,
    Set<CardKind>? leftOut,
  }) => GameConfig(
    players: players ?? this.players,
    seed: seed ?? this.seed,
    scoring: scoring ?? this.scoring,
    kraken: kraken ?? this.kraken,
    whiteWhale: whiteWhale ?? this.whiteWhale,
    loot: loot ?? this.loot,
    piratePowers: piratePowers ?? this.piratePowers,
    secondExpansion: secondExpansion ?? this.secondExpansion,
    leftOut: leftOut ?? this.leftOut,
  );

  /// Any expansion card or the pirate powers are in play.
  bool get usesExpansion => kraken || whiteWhale || loot || piratePowers;

  /// Every expansion card and the pirate powers are in play.
  bool get usesFullExpansion => kraken && whiteWhale && loot && piratePowers;

  Map<String, Object?> toJson() => {
    'players': players,
    'seed': seed,
    'scoring': scoring.name,
    'kraken': kraken,
    'whiteWhale': whiteWhale,
    'loot': loot,
    'piratePowers': piratePowers,
    if (secondExpansion) 'secondExpansion': true,
    if (leftOut.isNotEmpty) 'leftOut': [for (final kind in leftOut) kind.name],
  };
}

/// [answer] as JSON. With its [GameConfig], the list of a game's answers is
/// all it takes to save it.
Map<String, Object?> answerToJson(Answer answer) => {
  'seat': answer.seat,
  ...switch (answer) {
    BidAnswer() => {'bid': answer.bid},
    PlayAnswer() => {
      'card': answer.card.id,
      if (answer.tigressAs case final mode?) 'tigressAs': mode.name,
      'declaredValue': ?answer.declaredValue,
      if (answer.jokerSuit case final suit?) 'jokerSuit': suit.name,
    },
    WalkPlankAnswer() => {'overboard': answer.pirate.id},
    ChooseVictimAnswer() => {'victim': answer.victim},
    ChooseLeaderAnswer() => {'leader': answer.leader},
    DiscardAnswer() => {
      'discard': [for (final card in answer.cards) card.id],
    },
    WagerAnswer() => {'wager': answer.amount},
    AdjustBidAnswer() => {'change': answer.change},
  },
};

/// The reverse of [answerToJson]. Throws a [FormatException] on anything else.
Answer answerFromJson(Map<String, Object?> json) {
  try {
    final seat = json['seat']! as int;
    return switch (json) {
      {'bid': final int bid} => BidAnswer(seat: seat, bid: bid),
      {'leader': final int leader} => ChooseLeaderAnswer(
        seat: seat,
        leader: leader,
      ),
      {'discard': final List<Object?> ids} => DiscardAnswer(
        seat: seat,
        cards: [for (final id in ids) Card.fromId(id! as String)],
      ),
      {'wager': final int amount} => WagerAnswer(seat: seat, amount: amount),
      {'change': final int change} => AdjustBidAnswer(
        seat: seat,
        change: change,
      ),
      {'overboard': final String id} => WalkPlankAnswer(
        seat: seat,
        pirate: Card.fromId(id),
      ),
      {'victim': final int victim} => ChooseVictimAnswer(
        seat: seat,
        victim: victim,
      ),
      {'card': final String id} => PlayAnswer(
        seat: seat,
        card: Card.fromId(id),
        declaredValue: json['declaredValue'] as int?,
        jokerSuit: switch (json['jokerSuit']) {
          null => null,
          final String suit => Suit.values.byName(suit),
          _ => throw const FormatException('bad joker suit'),
        },
        tigressAs: switch (json['tigressAs']) {
          null => null,
          final String mode => TigressMode.values.byName(mode),
          _ => throw const FormatException('bad tigress mode'),
        },
      ),
      _ => throw const FormatException('unknown kind of answer'),
    };
  } on FormatException {
    rethrow;
  } catch (error) {
    throw FormatException('not a saved answer: $error', json);
  }
}

/// Something the game needs from a seat before it can go on.
sealed class Question {
  const Question(this.seat);

  final int seat;
}

final class BidQuestion extends Question {
  const BidQuestion({required int seat, required this.maxBid}) : super(seat);

  /// Bids from 0 to [maxBid] are allowed.
  final int maxBid;
}

final class PlayQuestion extends Question {
  const PlayQuestion({required int seat, required this.legalCards})
    : super(seat);

  /// Never empty. Playing the tigress also requires a [TigressMode], a 0/14
  /// its value, and the joker a suit while the trick has none
  /// ([suitIsOpen]).
  final List<Card> legalCards;
}

/// A decision a card calls for once the trick is played: how to use the
/// power of the pirate that just won it, or whom the plank throws overboard.
sealed class AfterTrickQuestion extends Question {
  const AfterTrickQuestion(super.seat);
}

/// The plank: with several named pirates in the trick, say which one of
/// [pirates] leaves it before it is settled.
final class WalkPlankQuestion extends AfterTrickQuestion {
  const WalkPlankQuestion({required int seat, required this.pirates})
    : super(seat);

  final List<Card> pirates;
}

/// Mary's power: name the seat that will have to play, in the next trick, a
/// card drawn at random from its hand.
final class ChooseVictimQuestion extends AfterTrickQuestion {
  const ChooseVictimQuestion({required int seat, required this.seats})
    : super(seat);

  /// Every seat that still holds a card, the asking one included.
  final List<int> seats;
}

/// Rosie's power: name the seat that leads the next trick.
final class ChooseLeaderQuestion extends AfterTrickQuestion {
  const ChooseLeaderQuestion({required int seat, required this.seats})
    : super(seat);

  /// Every seat may be named, the asking one included.
  final List<int> seats;
}

/// Will's power: after drawing, put [count] cards of the hand out of play.
final class DiscardQuestion extends AfterTrickQuestion {
  const DiscardQuestion({
    required int seat,
    required this.hand,
    required this.count,
  }) : super(seat);

  /// The cards to choose from: the hand, drawn cards included.
  final List<Card> hand;
  final int count;
}

/// Rascal's power: stake one of [amounts] on making the bid.
final class WagerQuestion extends AfterTrickQuestion {
  const WagerQuestion({required int seat, required this.amounts}) : super(seat);

  final List<int> amounts;
}

/// Harry's power: move the bid by one of [changes], which always holds 0.
final class AdjustBidQuestion extends AfterTrickQuestion {
  const AdjustBidQuestion({required int seat, required this.changes})
    : super(seat);

  final List<int> changes;
}

/// The reply of a seat to its pending [Question].
sealed class Answer {
  const Answer(this.seat);

  final int seat;
}

final class BidAnswer extends Answer {
  const BidAnswer({required int seat, required this.bid}) : super(seat);

  final int bid;
}

final class PlayAnswer extends Answer {
  const PlayAnswer({
    required int seat,
    required this.card,
    this.tigressAs,
    this.declaredValue,
    this.jokerSuit,
  }) : super(seat);

  final Card card;

  /// Required for the tigress, forbidden for any other card.
  final TigressMode? tigressAs;

  /// 0 or 14: required for a 0/14, forbidden for any other card.
  final int? declaredValue;

  /// One of [jokerSuits]: required for the joker while the trick has no suit
  /// yet, forbidden otherwise.
  final Suit? jokerSuit;
}

final class WalkPlankAnswer extends Answer {
  const WalkPlankAnswer({required int seat, required this.pirate})
    : super(seat);

  final Card pirate;
}

final class ChooseVictimAnswer extends Answer {
  const ChooseVictimAnswer({required int seat, required this.victim})
    : super(seat);

  final int victim;
}

final class ChooseLeaderAnswer extends Answer {
  const ChooseLeaderAnswer({required int seat, required this.leader})
    : super(seat);

  final int leader;
}

final class DiscardAnswer extends Answer {
  const DiscardAnswer({required int seat, required this.cards}) : super(seat);

  final List<Card> cards;
}

final class WagerAnswer extends Answer {
  const WagerAnswer({required int seat, required this.amount}) : super(seat);

  final int amount;
}

final class AdjustBidAnswer extends Answer {
  const AdjustBidAnswer({required int seat, required this.change})
    : super(seat);

  final int change;
}

/// Thrown when an [Answer] does not match a pending question or breaks a
/// rule. The game is left exactly as it was.
final class IllegalAnswer implements Exception {
  const IllegalAnswer(this.message);

  final String message;

  @override
  String toString() => 'IllegalAnswer: $message';
}

/// Something that just happened.
sealed class Event {
  const Event();

  /// The only seat allowed to see this event, or null when it is public.
  int? get audience => null;
}

final class RoundStarted extends Event {
  const RoundStarted({
    required this.round,
    required this.cardsDealt,
    required this.dealer,
    required this.leader,
  });

  /// Numbered from 1; above ten for a tie-break round.
  final int round;
  final int cardsDealt;
  final int dealer;

  /// The seat that leads the first trick.
  final int leader;
}

/// Who plays the trick about to be played, or being played, and in which
/// order. Sent again when it changes: Rosie names another leader, or the last
/// salvo gives its player a second turn.
final class TurnsSet extends Event {
  const TurnsSet(this.order);

  /// A seat that plays twice is in it twice.
  final List<int> order;
}

final class HandDealt extends Event {
  const HandDealt({required this.seat, required this.cards});

  final int seat;
  final List<Card> cards;

  @override
  int get audience => seat;
}

final class BidsRevealed extends Event {
  const BidsRevealed(this.bids);

  /// One bid per seat.
  final List<int> bids;
}

final class CardPlayed extends Event {
  const CardPlayed(this.play);

  final Play play;
}

final class TrickWon extends Event {
  const TrickWon({
    required this.winner,
    required this.plays,
    required this.bonuses,
    this.alliances = const [],
    this.destroyed = false,
    this.overboard,
    this.sideBonuses = const [],
  });

  /// The seat that leads the next trick; it won this one unless [destroyed].
  final int winner;
  final List<Play> plays;
  final List<Bonus> bonuses;

  /// Bonuses the trick brings to a seat whether or not it won it: those of
  /// Davy Jones' chest.
  final List<(int seat, Bonus bonus)> sideBonuses;
  final List<Alliance> alliances;

  /// A kraken, a whale or a stingray over special cards only, or nothing but
  /// cards that take no trick: nobody wins.
  final bool destroyed;

  /// The pirate the plank threw out of the trick before it was settled.
  final Card? overboard;
}

/// Mary: [victim] will have to play a card drawn from its hand.
final class VictimChosen extends Event {
  const VictimChosen({required this.seat, required this.victim});

  final int seat;
  final int victim;
}

/// Mary: the card [seat] has to play at its next turn. Only that seat sees
/// which.
final class CardForced extends Event {
  const CardForced({required this.seat, required this.card});

  final int seat;
  final Card card;

  @override
  int get audience => seat;
}

/// A seat won a trick with [pirate] and gets to use its power.
final class PowerUsed extends Event {
  const PowerUsed({required this.seat, required this.pirate});

  final int seat;
  final Pirate pirate;
}

/// Rosie: [leader] leads the next trick.
final class LeaderChosen extends Event {
  const LeaderChosen({required this.seat, required this.leader});

  final int seat;
  final int leader;
}

/// Will: [seat] drew [cards]. Only that seat sees which.
final class CardsDrawn extends Event {
  const CardsDrawn({required this.seat, required this.cards});

  final int seat;
  final List<Card> cards;

  @override
  int get audience => seat;
}

/// Will: [seat] put [count] cards out of play, face down.
final class CardsDiscarded extends Event {
  const CardsDiscarded({required this.seat, required this.count});

  final int seat;
  final int count;
}

/// Will: the cards [seat] itself put out of play.
final class OwnCardsDiscarded extends Event {
  const OwnCardsDiscarded({required this.seat, required this.cards});

  final int seat;
  final List<Card> cards;

  @override
  int get audience => seat;
}

/// Rascal: [seat] staked [amount] on making its bid.
final class WagerPlaced extends Event {
  const WagerPlaced({required this.seat, required this.amount});

  final int seat;
  final int amount;
}

/// Juanita: the cards nobody was dealt. Only [seat] sees them.
final class StockRevealed extends Event {
  const StockRevealed({required this.seat, required this.cards});

  final int seat;
  final List<Card> cards;

  @override
  int get audience => seat;
}

/// Harry: the bid of [seat] is now [bid].
final class BidChanged extends Event {
  const BidChanged({required this.seat, required this.bid});

  final int seat;
  final int bid;
}

/// How one seat did in a round.
final class SeatResult {
  const SeatResult({
    required this.bid,
    required this.tricksWon,
    required this.bonuses,
    required this.score,
    required this.totalScore,
  });

  final int bid;
  final int tricksWon;

  /// Every bonus in the tricks this seat won, counted or not.
  final List<Bonus> bonuses;
  final RoundScore score;

  /// Running total after this round.
  final int totalScore;

  /// The seat took exactly the tricks it bid.
  bool get bidMade => bid == tricksWon;
}

final class RoundScored extends Event {
  const RoundScored({required this.round, required this.results});

  final int round;

  /// One result per seat.
  final List<SeatResult> results;
}

final class GameFinished extends Event {
  const GameFinished({required this.winner, required this.scores});

  final int winner;

  /// Final score per seat.
  final List<int> scores;
}
