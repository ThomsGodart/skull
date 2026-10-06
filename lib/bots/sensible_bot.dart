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
    for (final card in question.hand)
      (
        card: card,
        tigressAs: card.kind == CardKind.tigress ? TigressMode.pirate : null,
      ),
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
typedef _Option = ({Card card, TigressMode? tigressAs});

PlayAnswer _play(PlayQuestion question, GameView view) {
  final seat = question.seat;
  final options = <_Option>[
    for (final card in question.legalCards)
      if (card.kind == CardKind.tigress) ...[
        (card: card, tigressAs: TigressMode.pirate),
        (card: card, tigressAs: TigressMode.escape),
      ] else
        (card: card, tigressAs: null),
  ];
  Play played(_Option option) =>
      Play(seat: seat, card: option.card, tigressAs: option.tigressAs);
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
      final numbers = winning.where((o) => o.card.isNumber).toList();
      choice = numbers.isEmpty ? _weakest(winning) : _strongest(numbers);
    }
  } else if (losing.isNotEmpty) {
    // Duck, and use the chance to get rid of a card that could win later.
    choice = _strongest(_withoutGifts(losing, view.trick));
  } else {
    choice = _weakest(winning);
  }
  return PlayAnswer(seat: seat, card: choice.card, tigressAs: choice.tigressAs);
}

/// [losing] without the plays that hand a capture bonus to whoever wins the
/// trick, unless nothing else is left.
List<_Option> _withoutGifts(List<_Option> losing, List<Play> trick) {
  final skullKingPlayed = trick.any((play) => play.isSkullKing);
  final piratePlayed = trick.any((play) => play.isPirate);
  bool isGift(_Option option) => switch (option.card.kind) {
    CardKind.pirate => skullKingPlayed,
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
  CardKind.number =>
    option.card.value! + (option.card.suit == Suit.black ? 20 : 0),
  CardKind.mermaid => 40,
  CardKind.pirate => 50,
  CardKind.tigress => option.tigressAs == TigressMode.pirate ? 50 : 0,
  CardKind.skullKing => 60,
};
