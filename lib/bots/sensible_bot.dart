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
    };

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
      CardKind.escape => 0.0,
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
  bool winsSoFar(_Option option) =>
      resolveTrick([...view.trick, played(option)]).winner == seat;

  final winning = options.where(winsSoFar).toList();
  final losing = options.where((option) => !winsSoFar(option)).toList();
  final needsTricks = view.bids[seat]! > view.tricksWon[seat];
  final isLast = view.trick.length == view.handSizes.length - 1;

  final _Option choice;
  if (needsTricks) {
    if (winning.isEmpty) {
      // The trick is lost: give away the least useful card.
      choice = _weakest(losing);
    } else {
      // Last to play, the cheapest winner is enough; earlier, play strong so
      // the cards still to come are less likely to take it back.
      choice = isLast ? _weakest(winning) : _strongest(winning);
    }
  } else if (losing.isNotEmpty) {
    // Duck, and use the chance to get rid of a card that could win later.
    choice = _strongest(losing);
  } else {
    choice = _weakest(winning);
  }
  return PlayAnswer(seat: seat, card: choice.card, tigressAs: choice.tigressAs);
}

_Option _weakest(List<_Option> options) =>
    options.reduce((a, b) => _strength(b) < _strength(a) ? b : a);

_Option _strongest(List<_Option> options) =>
    options.reduce((a, b) => _strength(b) > _strength(a) ? b : a);

/// A rough ranking of how likely a card is to take a trick.
int _strength(_Option option) => switch (option.card.kind) {
  CardKind.escape => 0,
  CardKind.number =>
    option.card.value! + (option.card.suit == Suit.black ? 20 : 0),
  CardKind.mermaid => 40,
  CardKind.pirate => 50,
  CardKind.tigress => option.tigressAs == TigressMode.pirate ? 50 : 0,
  CardKind.skullKing => 60,
};
