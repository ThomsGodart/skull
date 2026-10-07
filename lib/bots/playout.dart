import 'dart:math';

import '../engine/engine.dart';
import 'sensible_bot.dart';

/// A round with every hand known, as a bot imagines it: the hidden cards
/// dealt at random among the others. It is played out to its end by the
/// plain rules, to see what a choice is worth.
///
/// It is a rough model of the game, not the game: the pirates' powers, the
/// plank and the last salvo are left out. They weigh little on what a card
/// is worth, and the real game applies them all the same.
final class Playout {
  Playout({
    required this.me,
    required List<List<Card>> hands,
    required this.bids,
    required List<int> tricksWon,
    required List<Play> trick,
    required int leader,
    required this.cardsDealt,
    required this.scoring,
  }) : _hands = [for (final hand in hands) List.of(hand)],
       _won = List.of(tricksWon),
       _trick = List.of(trick),
       // Whoever led the trick on the table, or leads the next one.
       _leader = trick.isEmpty ? leader : trick.first.seat;

  /// The seat the round is scored for.
  final int me;
  final int cardsDealt;
  final Scoring scoring;

  final List<List<Card>> _hands;

  /// The bid of each seat.
  final List<int> bids;
  final List<int> _won;
  final List<Play> _trick;
  final List<Bonus> _bonuses = [];
  int _leader;

  int get _seats => _hands.length;

  /// Plays the round out and gives what [me] scores in it. [first], when
  /// given, is what [me] plays at its first turn; everything else follows
  /// the plain rules.
  int score({PlayAnswer? first}) {
    var mine = first;
    while (true) {
      // Who still has to play this trick: clockwise from its leader,
      // whoever holds a card and has not played yet.
      final played = {for (final play in _trick) play.seat};
      final toPlay = [
        for (var i = 0; i < _seats; i++)
          if (_hands[(_leader + i) % _seats].isNotEmpty &&
              !played.contains((_leader + i) % _seats))
            (_leader + i) % _seats,
      ];
      if (toPlay.isEmpty && _trick.isEmpty) break;
      final seats = played.length + toPlay.length;
      for (final seat in toPlay) {
        final PlayAnswer answer;
        if (seat == me && mine != null) {
          answer = mine;
          mine = null;
        } else {
          answer = sensiblePlay(
            seat: seat,
            legalCards: legalCards(_hands[seat], _trick),
            trick: _trick,
            needsTricks: bids[seat] > _won[seat],
            seats: seats,
          );
        }
        _hands[seat].remove(answer.card);
        _trick.add(
          Play(
            seat: seat,
            card: answer.card,
            tigressAs: answer.tigressAs,
            declaredValue: answer.declaredValue,
            jokerSuit: answer.card.kind == CardKind.joker
                ? answer.jokerSuit ?? inheritedJokerSuit(_trick)
                : null,
          ),
        );
      }
      final result = resolveTrick(_trick);
      if (!result.destroyed) {
        _won[result.winner]++;
        if (result.winner == me) _bonuses.addAll(result.bonuses);
      }
      for (final (seat, bonus) in result.sideBonuses) {
        if (seat == me) _bonuses.add(bonus);
      }
      _leader = result.winner;
      _trick.clear();
    }
    return scoreRound(
      bid: bids[me],
      tricksWon: _won[me],
      cardsDealt: cardsDealt,
      bonuses: _bonuses,
      scoring: scoring,
    ).total;
  }
}

/// What [view] does not show, dealt at random: a hand for every other seat,
/// of the size it holds, from the cards that were neither seen nor played.
/// A seat that could not follow a suit earlier in the round gets none of it,
/// as far as the cards left allow.
List<List<Card>> imagineHands(GameView view, Random random) {
  final seen = <Card>{
    ...view.hand,
    for (final play in view.trick) play.card,
    for (final trick in view.roundTricks)
      for (final play in trick) play.card,
  };
  final pool = [
    for (final card in view.deck)
      if (!seen.contains(card)) card,
  ]..shuffle(random);
  final voids = _voids(view);
  final seats = view.handSizes.length;
  final hands = List.generate(seats, (_) => <Card>[]);
  hands[view.seat] = List.of(view.hand);
  // The seats with the most suits ruled out choose first.
  final others = [
    for (var seat = 0; seat < seats; seat++)
      if (seat != view.seat) seat,
  ]..sort((a, b) => voids[b].length.compareTo(voids[a].length));
  for (final seat in others) {
    final size = view.handSizes[seat];
    final hand = hands[seat];
    for (var i = 0; i < pool.length && hand.length < size;) {
      final card = pool[i];
      if (card.isNumber && voids[seat].contains(card.suit)) {
        i++;
      } else {
        hand.add(pool.removeAt(i));
      }
    }
    // Not enough cards it may hold: what is known gives way.
    while (hand.length < size && pool.isNotEmpty) {
      hand.add(pool.removeLast());
    }
  }
  return hands;
}

/// The suits each seat showed it no longer holds, by not following them.
List<Set<Suit>> _voids(GameView view) {
  final voids = List.generate(view.handSizes.length, (_) => <Suit>{});
  for (final trick in [...view.roundTricks, view.trick]) {
    for (var index = 1; index < trick.length; index++) {
      final play = trick[index];
      final suit = leadSuit(trick.sublist(0, index));
      if (suit != null && play.card.isNumber && play.card.suit != suit) {
        voids[play.seat].add(suit);
      }
    }
  }
  return voids;
}
