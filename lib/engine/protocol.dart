import 'card.dart';
import 'scoring.dart';
import 'trick.dart';

/// Fewest and most seats a game can have.
const minPlayers = 3;
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

  Map<String, Object?> toJson() => {
    'players': players,
    'seed': seed,
    'scoring': scoring.name,
    'kraken': kraken,
    'whiteWhale': whiteWhale,
    'loot': loot,
    'piratePowers': piratePowers,
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
    },
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
      {'card': final String id} => PlayAnswer(
        seat: seat,
        card: Card.fromId(id),
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

  /// Never empty. Playing the tigress also requires a [TigressMode].
  final List<Card> legalCards;
}

/// Rosie's power: name the seat that leads the next trick.
final class ChooseLeaderQuestion extends Question {
  const ChooseLeaderQuestion({required int seat, required this.seats})
    : super(seat);

  /// Every seat may be named, the asking one included.
  final List<int> seats;
}

/// Will's power: after drawing, put [count] cards of the hand out of play.
final class DiscardQuestion extends Question {
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
final class WagerQuestion extends Question {
  const WagerQuestion({required int seat, required this.amounts}) : super(seat);

  final List<int> amounts;
}

/// Harry's power: move the bid by one of [changes], which always holds 0.
final class AdjustBidQuestion extends Question {
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
  const PlayAnswer({required int seat, required this.card, this.tigressAs})
    : super(seat);

  final Card card;

  /// Required for the tigress, forbidden for any other card.
  final TigressMode? tigressAs;
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
  });

  /// The seat that leads the next trick; it won this one unless [destroyed].
  final int winner;
  final List<Play> plays;
  final List<Bonus> bonuses;
  final List<Alliance> alliances;

  /// A kraken, or a white whale over special cards only: nobody wins.
  final bool destroyed;
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
