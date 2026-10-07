import '../engine/engine.dart';
import 'bot.dart';

/// A bot that plays by a few plain rules: it bids what its hand looks worth,
/// then takes tricks while it still needs some and ducks them once it has
/// enough. It sees only its own seat's view.
Bot sensibleBot() =>
    (question, view) => switch (question) {
      BidQuestion() => BidAnswer(
        seat: question.seat,
        bid: _bid(view).clamp(0, question.maxBid),
      ),
      PlayQuestion() => _play(question, view),
      ChooseLeaderQuestion() => ChooseLeaderAnswer(
        seat: question.seat,
        // Leading suits a hand that still wants tricks; otherwise pass it on.
        leader: _needsTricks(view)
            ? question.seat
            : question.seats[(question.seats.indexOf(question.seat) + 1) %
                  question.seats.length],
      ),
      WalkPlankQuestion() => WalkPlankAnswer(
        seat: question.seat,
        // Someone else's pirate, when there is one.
        pirate: view.trick
            .where(
              (play) =>
                  play.seat != question.seat &&
                  question.pirates.contains(play.card),
            )
            .map((play) => play.card)
            .firstWhere((_) => true, orElse: () => question.pirates.first),
      ),
      ChooseVictimQuestion() => ChooseVictimAnswer(
        seat: question.seat,
        // Anyone but itself, when someone else still holds a card.
        victim: question.seats.firstWhere(
          (seat) => seat != question.seat,
          orElse: () => question.seat,
        ),
      ),
      DiscardQuestion() => DiscardAnswer(
        seat: question.seat,
        cards: _discards(question, view),
      ),
      WagerQuestion() => WagerAnswer(
        seat: question.seat,
        amount: _wager(question, view),
      ),
      AdjustBidQuestion() => AdjustBidAnswer(
        seat: question.seat,
        change: _bidChange(question, view),
      ),
    };

bool _needsTricks(GameView view) =>
    view.bids[view.seat]! > view.tricksWon[view.seat];

/// Keeps what serves the bid: strong cards while tricks are missing, weak
/// ones once there are enough.
List<Card> _discards(DiscardQuestion question, GameView view) {
  final options = [
    // Each card for the most it can be worth.
    for (final card in question.hand) _strongest(_ways(card, const [])),
  ]..sort((a, b) => _strength(a).compareTo(_strength(b)));
  final ordered = _needsTricks(view) ? options : options.reversed.toList();
  return [for (final option in ordered.take(question.count)) option.card];
}

/// Stakes only on a bid that is already exactly made, and more when few
/// cards are left to spoil it.
int _wager(WagerQuestion question, GameView view) {
  final seat = view.seat;
  if (view.bids[seat] != view.tricksWon[seat]) return 0;
  final wanted = view.hand.length <= 2 ? 20 : 10;
  return question.amounts.contains(wanted) ? wanted : 0;
}

/// Raises a bid that was just overshot; lowers one that can no longer be
/// reached because the round is over.
int _bidChange(AdjustBidQuestion question, GameView view) {
  final seat = view.seat;
  final missing = view.bids[seat]! - view.tricksWon[seat];
  final wanted = missing < 0 ? 1 : (missing > 0 && view.hand.isEmpty ? -1 : 0);
  return question.changes.contains(wanted) ? wanted : 0;
}

/// How many tricks the hand should take: the sum of each card's chance.
int _bid(GameView view) {
  final players = view.handSizes.length;
  // With more players, more cards can beat a good number card.
  final crowd = (4 / players).clamp(0.5, 1.2);
  var expected = 0.0;
  for (final card in view.hand) {
    expected += switch (card.kind) {
      CardKind.skullKing => 0.95,
      CardKind.pirate => 0.75,
      CardKind.tigress => 0.7,
      CardKind.mermaid => 0.45,
      CardKind.escape || CardKind.loot => 0.0,
      // Whatever they do to a trick, they never take one.
      CardKind.kraken || CardKind.whiteWhale => 0.0,
      CardKind.plank ||
      CardKind.stingray ||
      CardKind.lastSalvo ||
      CardKind.davyJones => 0.0,
      CardKind.mat => 0.85,
      CardKind.joker => crowd * 0.6,
      // A 14 when it serves, a 0 when it does not.
      CardKind.zeroFourteen => card.suit == Suit.black ? 0.6 : crowd * 0.4,
      CardKind.number when card.suit == Suit.black => switch (card.value!) {
        >= 10 => 0.5 + (card.value! - 10) * 0.1,
        >= 6 => 0.3,
        _ => 0.15,
      },
      CardKind.number =>
        crowd *
            switch (card.value!) {
              14 => 0.55,
              13 => 0.4,
              12 => 0.3,
              11 => 0.2,
              _ => 0.03,
            },
    };
  }
  return expected.round();
}

/// One way of putting a card down.
typedef _Option = ({
  Card card,
  TigressMode? tigressAs,
  int? declaredValue,
  Suit? jokerSuit,
});

/// Every way [card] can be put down on [trick].
List<_Option> _ways(Card card, List<Play> trick) {
  _Option way({TigressMode? tigressAs, int? declaredValue, Suit? jokerSuit}) =>
      (
        card: card,
        tigressAs: tigressAs,
        declaredValue: declaredValue,
        jokerSuit: jokerSuit,
      );
  return switch (card.kind) {
    CardKind.tigress => [
      way(tigressAs: TigressMode.pirate),
      way(tigressAs: TigressMode.escape),
    ],
    CardKind.zeroFourteen => [way(declaredValue: 14), way(declaredValue: 0)],
    CardKind.joker when suitIsOpen(trick) => [
      for (final suit in jokerSuits) way(jokerSuit: suit),
    ],
    _ => [way()],
  };
}

PlayAnswer _play(PlayQuestion question, GameView view) {
  final seat = question.seat;
  final options = <_Option>[
    for (final card in question.legalCards) ..._ways(card, view.trick),
  ];
  Play played(_Option option) => Play(
    seat: seat,
    card: option.card,
    tigressAs: option.tigressAs,
    declaredValue: option.declaredValue,
    jokerSuit: option.card.kind == CardKind.joker
        ? option.jokerSuit ?? inheritedJokerSuit(view.trick)
        : null,
  );
  bool winsSoFar(_Option option) {
    final result = resolveTrick([...view.trick, played(option)]);
    // A destroyed trick is taken by nobody.
    return !result.destroyed && result.winner == seat;
  }

  final winning = options.where(winsSoFar).toList();
  final losing = options.where((option) => !winsSoFar(option)).toList();
  final needsTricks = _needsTricks(view);
  final isLast = view.trick.length == view.handSizes.length - 1;

  final _Option choice;
  if (needsTricks) {
    if (winning.isEmpty) {
      // The trick is lost: give away the least useful card.
      choice = _weakest(_withoutGifts(losing, view.trick));
    } else if (isLast) {
      choice = _weakest(winning);
    } else {
      // Others still play: a high number card is tried first, the characters
      // are kept for a trick they are sure to take.
      final numbers = winning.where((o) => played(o).isNumber).toList();
      choice = numbers.isEmpty ? _weakest(winning) : _strongest(numbers);
    }
  } else if (losing.isNotEmpty) {
    // Duck, and use the chance to get rid of a card that could win later.
    choice = _strongest(_withoutGifts(losing, view.trick));
  } else {
    choice = _weakest(winning);
  }
  return PlayAnswer(
    seat: seat,
    card: choice.card,
    tigressAs: choice.tigressAs,
    declaredValue: choice.declaredValue,
    jokerSuit: choice.jokerSuit,
  );
}

/// [losing] without the plays that hand a capture bonus to whoever wins the
/// trick, unless nothing else is left.
List<_Option> _withoutGifts(List<_Option> losing, List<Play> trick) {
  final skullKingPlayed = trick.any((play) => play.isSkullKing);
  final piratePlayed = trick.any((play) => play.isPirate);
  final mermaidPlayed = trick.any((play) => play.isMermaid);
  bool isGift(_Option option) => switch (option.card.kind) {
    CardKind.pirate => skullKingPlayed,
    CardKind.mat => skullKingPlayed || mermaidPlayed,
    // As an escape she loses just as surely, and gives nothing away.
    CardKind.tigress => option.tigressAs == TigressMode.pirate,
    CardKind.mermaid => piratePlayed && !skullKingPlayed,
    _ => false,
  };
  final safe = losing.where((option) => !isGift(option)).toList();
  return safe.isEmpty ? losing : safe;
}

_Option _weakest(List<_Option> options) =>
    options.reduce((a, b) => _strength(b) < _strength(a) ? b : a);

_Option _strongest(List<_Option> options) =>
    options.reduce((a, b) => _strength(b) > _strength(a) ? b : a);

/// A rough ranking of how likely a card is to take a trick.
int _strength(_Option option) => switch (option.card.kind) {
  CardKind.escape || CardKind.loot => 0,
  CardKind.kraken || CardKind.whiteWhale => 1,
  CardKind.plank ||
  CardKind.stingray ||
  CardKind.lastSalvo ||
  CardKind.davyJones => 1,
  CardKind.number =>
    option.card.value! + (option.card.suit == Suit.black ? 20 : 0),
  CardKind.zeroFourteen =>
    option.declaredValue! + (option.card.suit == Suit.black ? 20 : 0),
  CardKind.joker => jokerValue,
  CardKind.mermaid => 40,
  CardKind.pirate => 50,
  CardKind.tigress => option.tigressAs == TigressMode.pirate ? 50 : 0,
  CardKind.mat => 55,
  CardKind.skullKing => 60,
};
