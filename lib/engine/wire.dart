import 'card.dart';
import 'protocol.dart';
import 'scoring.dart';
import 'trick.dart';

/// Events and questions as JSON, to send a seat what it may see of a game
/// that runs on another phone. Answers have their own, in `protocol.dart`.

List<String> _ids(List<Card> cards) => [for (final card in cards) card.id];

List<Card> _cards(Object? ids) => [
  for (final id in ids! as List) Card.fromId(id as String),
];

List<int> _ints(Object? values) => (values! as List).cast<int>();

Map<String, Object?> _playToJson(Play play) => {
  'seat': play.seat,
  'card': play.card.id,
  if (play.tigressAs case final mode?) 'tigressAs': mode.name,
};

Play _playFromJson(Object? json) {
  final map = json! as Map<String, Object?>;
  final mode = map['tigressAs'] as String?;
  return Play(
    seat: map['seat']! as int,
    card: Card.fromId(map['card']! as String),
    tigressAs: mode == null ? null : TigressMode.values.byName(mode),
  );
}

List<String> _bonusNames(List<Bonus> bonuses) => [
  for (final bonus in bonuses) bonus.name,
];

List<Bonus> _bonuses(Object? names) => [
  for (final name in names! as List) Bonus.values.byName(name as String),
];

Map<String, Object?> _resultToJson(SeatResult result) => {
  'bid': result.bid,
  'tricksWon': result.tricksWon,
  'bonuses': _bonusNames(result.bonuses),
  'bidPoints': result.score.bidPoints,
  'bonusPoints': result.score.bonusPoints,
  'alliancePoints': result.score.alliancePoints,
  'wagerPoints': result.score.wagerPoints,
  'totalScore': result.totalScore,
};

SeatResult _resultFromJson(Object? json) {
  final map = json! as Map<String, Object?>;
  return SeatResult(
    bid: map['bid']! as int,
    tricksWon: map['tricksWon']! as int,
    bonuses: _bonuses(map['bonuses']),
    score: RoundScore(
      bidPoints: map['bidPoints']! as int,
      bonusPoints: map['bonusPoints']! as int,
      alliancePoints: map['alliancePoints']! as int,
      wagerPoints: map['wagerPoints']! as int,
    ),
    totalScore: map['totalScore']! as int,
  );
}

/// [event] as JSON, tagged with its kind.
Map<String, Object?> eventToJson(Event event) => switch (event) {
  RoundStarted() => {
    'type': 'roundStarted',
    'round': event.round,
    'cardsDealt': event.cardsDealt,
    'dealer': event.dealer,
    'leader': event.leader,
  },
  HandDealt() => {
    'type': 'handDealt',
    'seat': event.seat,
    'cards': _ids(event.cards),
  },
  BidsRevealed() => {'type': 'bidsRevealed', 'bids': event.bids},
  CardPlayed() => {'type': 'cardPlayed', 'play': _playToJson(event.play)},
  TrickWon() => {
    'type': 'trickWon',
    'winner': event.winner,
    'plays': [for (final play in event.plays) _playToJson(play)],
    'bonuses': _bonusNames(event.bonuses),
    'alliances': [
      for (final alliance in event.alliances)
        [alliance.lootSeat, alliance.winnerSeat],
    ],
    'destroyed': event.destroyed,
  },
  PowerUsed() => {
    'type': 'powerUsed',
    'seat': event.seat,
    'pirate': event.pirate.name,
  },
  LeaderChosen() => {
    'type': 'leaderChosen',
    'seat': event.seat,
    'leader': event.leader,
  },
  CardsDrawn() => {
    'type': 'cardsDrawn',
    'seat': event.seat,
    'cards': _ids(event.cards),
  },
  CardsDiscarded() => {
    'type': 'cardsDiscarded',
    'seat': event.seat,
    'count': event.count,
  },
  OwnCardsDiscarded() => {
    'type': 'ownCardsDiscarded',
    'seat': event.seat,
    'cards': _ids(event.cards),
  },
  WagerPlaced() => {
    'type': 'wagerPlaced',
    'seat': event.seat,
    'amount': event.amount,
  },
  StockRevealed() => {
    'type': 'stockRevealed',
    'seat': event.seat,
    'cards': _ids(event.cards),
  },
  BidChanged() => {'type': 'bidChanged', 'seat': event.seat, 'bid': event.bid},
  RoundScored() => {
    'type': 'roundScored',
    'round': event.round,
    'results': [for (final result in event.results) _resultToJson(result)],
  },
  GameFinished() => {
    'type': 'gameFinished',
    'winner': event.winner,
    'scores': event.scores,
  },
};

/// The reverse of [eventToJson]. Throws a [FormatException] on anything else.
Event eventFromJson(Map<String, Object?> json) => _decode(json, 'event', () {
  int field(String name) => json[name]! as int;
  return switch (json['type']) {
    'roundStarted' => RoundStarted(
      round: field('round'),
      cardsDealt: field('cardsDealt'),
      dealer: field('dealer'),
      leader: field('leader'),
    ),
    'handDealt' => HandDealt(seat: field('seat'), cards: _cards(json['cards'])),
    'bidsRevealed' => BidsRevealed(_ints(json['bids'])),
    'cardPlayed' => CardPlayed(_playFromJson(json['play'])),
    'trickWon' => TrickWon(
      winner: field('winner'),
      plays: [for (final play in json['plays']! as List) _playFromJson(play)],
      bonuses: _bonuses(json['bonuses']),
      alliances: [
        for (final pair in json['alliances']! as List)
          Alliance(
            lootSeat: (pair as List)[0] as int,
            winnerSeat: pair[1] as int,
          ),
      ],
      destroyed: json['destroyed']! as bool,
    ),
    'powerUsed' => PowerUsed(
      seat: field('seat'),
      pirate: Pirate.values.byName(json['pirate']! as String),
    ),
    'leaderChosen' => LeaderChosen(
      seat: field('seat'),
      leader: field('leader'),
    ),
    'cardsDrawn' => CardsDrawn(
      seat: field('seat'),
      cards: _cards(json['cards']),
    ),
    'cardsDiscarded' => CardsDiscarded(
      seat: field('seat'),
      count: field('count'),
    ),
    'ownCardsDiscarded' => OwnCardsDiscarded(
      seat: field('seat'),
      cards: _cards(json['cards']),
    ),
    'wagerPlaced' => WagerPlaced(seat: field('seat'), amount: field('amount')),
    'stockRevealed' => StockRevealed(
      seat: field('seat'),
      cards: _cards(json['cards']),
    ),
    'bidChanged' => BidChanged(seat: field('seat'), bid: field('bid')),
    'roundScored' => RoundScored(
      round: field('round'),
      results: [
        for (final result in json['results']! as List) _resultFromJson(result),
      ],
    ),
    'gameFinished' => GameFinished(
      winner: field('winner'),
      scores: _ints(json['scores']),
    ),
    _ => throw const FormatException('unknown kind of event'),
  };
});

/// [question] as JSON, tagged with its kind.
Map<String, Object?> questionToJson(Question question) => {
  'seat': question.seat,
  ...switch (question) {
    BidQuestion() => {'type': 'bid', 'maxBid': question.maxBid},
    PlayQuestion() => {'type': 'play', 'legalCards': _ids(question.legalCards)},
    ChooseLeaderQuestion() => {'type': 'chooseLeader', 'seats': question.seats},
    DiscardQuestion() => {
      'type': 'discard',
      'hand': _ids(question.hand),
      'count': question.count,
    },
    WagerQuestion() => {'type': 'wager', 'amounts': question.amounts},
    AdjustBidQuestion() => {'type': 'adjustBid', 'changes': question.changes},
  },
};

/// The reverse of [questionToJson]. Throws a [FormatException] on anything
/// else.
Question questionFromJson(Map<String, Object?> json) =>
    _decode(json, 'question', () {
      final seat = json['seat']! as int;
      return switch (json['type']) {
        'bid' => BidQuestion(seat: seat, maxBid: json['maxBid']! as int),
        'play' => PlayQuestion(
          seat: seat,
          legalCards: _cards(json['legalCards']),
        ),
        'chooseLeader' => ChooseLeaderQuestion(
          seat: seat,
          seats: _ints(json['seats']),
        ),
        'discard' => DiscardQuestion(
          seat: seat,
          hand: _cards(json['hand']),
          count: json['count']! as int,
        ),
        'wager' => WagerQuestion(seat: seat, amounts: _ints(json['amounts'])),
        'adjustBid' => AdjustBidQuestion(
          seat: seat,
          changes: _ints(json['changes']),
        ),
        _ => throw const FormatException('unknown kind of question'),
      };
    });

/// Runs [read], turning whatever goes wrong into a [FormatException]: what
/// comes off a network is never to be trusted.
T _decode<T>(Map<String, Object?> json, String what, T Function() read) {
  try {
    return read();
  } on FormatException {
    rethrow;
  } on Object catch (error) {
    throw FormatException('not a valid $what: $error', json);
  }
}
