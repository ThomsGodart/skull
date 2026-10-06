import 'card.dart';
import 'scoring.dart';
import 'trick.dart';

/// Fewest and most seats a game can have.
const minPlayers = 3;
const maxPlayers = 8;

/// What defines a game before anything is answered.
final class GameConfig {
  const GameConfig({required this.players, required this.seed});

  /// Seats at the table, [minPlayers] to [maxPlayers].
  final int players;

  /// Seeds every shuffle and the choice of the first dealer: the same seed and
  /// the same answers always give the same game.
  final int seed;

  factory GameConfig.fromJson(Map<String, Object?> json) =>
      GameConfig(players: json['players']! as int, seed: json['seed']! as int);

  Map<String, Object?> toJson() => {'players': players, 'seed': seed};
}

/// [answer] as JSON. With its [GameConfig], the list of a game's answers is
/// all it takes to save it.
Map<String, Object?> answerToJson(Answer answer) => switch (answer) {
  BidAnswer() => {'seat': answer.seat, 'bid': answer.bid},
  PlayAnswer() => {
    'seat': answer.seat,
    'card': answer.card.id,
    if (answer.tigressAs case final mode?) 'tigressAs': mode.name,
  },
};

/// The reverse of [answerToJson]. Throws a [FormatException] on anything else.
Answer answerFromJson(Map<String, Object?> json) {
  try {
    final seat = json['seat']! as int;
    if (json['bid'] case final int bid) return BidAnswer(seat: seat, bid: bid);
    final mode = json['tigressAs'] as String?;
    return PlayAnswer(
      seat: seat,
      card: Card.fromId(json['card']! as String),
      tigressAs: mode == null ? null : TigressMode.values.byName(mode),
    );
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
  });

  final int winner;
  final List<Play> plays;
  final List<Bonus> bonuses;
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
