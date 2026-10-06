import '../engine/engine.dart';
import 'bot.dart';
import 'sensible_bot.dart';

/// Tables from this size up are where counting the deck pays off; below it,
/// the sensible bot's rule of thumb bids at least as well.
const _crowdedTable = 5;

/// The strongest bot: at a crowded table it bids from how likely each of its
/// cards is to be beaten by what the others may hold. Everything else it
/// does like the sensible bot.
Bot sharpBot() {
  final sensible = sensibleBot();
  return (question, view) =>
      question is BidQuestion && view.handSizes.length >= _crowdedTable
      ? BidAnswer(
          seat: question.seat,
          bid: _countedBid(view).clamp(0, question.maxBid),
        )
      : sensible(question, view);
}

/// Stands for "some opponent" when a trick is tried out.
const _someone = -1;

/// Every way [card] can be put down.
List<Play> _ways(Card card, int seat) => card.kind == CardKind.tigress
    ? [
        Play(seat: seat, card: card, tigressAs: TigressMode.pirate),
        Play(seat: seat, card: card, tigressAs: TigressMode.escape),
      ]
    : [Play(seat: seat, card: card)];

/// Whether [mine], led, still takes the trick once [other] follows it.
bool _survives(Play mine, Card other) => _ways(other, _someone).every((theirs) {
  final result = resolveTrick([mine, theirs]);
  return !result.destroyed && result.winner == mine.seat;
});

/// How many tricks the hand should take: for each card led, the chance that
/// no card able to beat it is both held by someone and played on it.
int _countedBid(GameView view) {
  final hand = view.hand.toSet();
  final unseen = [
    for (final card in deckFor(view.config!))
      if (!hand.contains(card)) card,
  ];
  final othersCards =
      view.handSizes.fold(0, (sum, size) => sum + size) - view.hand.length;
  // The share of the unseen cards that sit in the other hands.
  final held = (othersCards / unseen.length).clamp(0.0, 1.0);

  var expected = 0.0;
  for (final card in view.hand) {
    final mine = _ways(card, view.seat).first;
    if (!card.isNumber && !mine.isCharacter) continue;
    var wins = 1.0;
    for (final other in unseen) {
      // A card that beats it is in someone's hand, and is spent on this very
      // trick about one time in three.
      if (!_survives(mine, other)) wins *= 1 - held * 0.35;
    }
    // A base-suit card does not always get to be led.
    final leads = card.isNumber && card.suit != Suit.black ? 0.75 : 1.0;
    expected += wins * leads;
  }
  return expected.round();
}
