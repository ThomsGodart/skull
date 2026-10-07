import 'dart:math';

import '../engine/engine.dart';
import 'bot.dart';
import 'playout.dart';
import 'sensible_bot.dart';

/// How much the strongest bot may simulate before each decision, counted in
/// cards played in its imagined rounds. It keeps a phone's screen from
/// stalling when eight hands of ten cards are at stake.
const defaultEffort = 12000;

/// The fewest and the most deals it imagines, whatever the effort allows.
const defaultFewestSamples = 8;
const _mostSamples = 48;

/// How many deals fit in [effort] when [choices] are each tried on rounds
/// of [cards] cards still to play.
int _samplesFor(
  ({int effort, int fewest}) work, {
  required int choices,
  required int cards,
}) => (work.effort ~/ (choices * (cards < 1 ? 1 : cards))).clamp(
  work.fewest,
  _mostSamples,
);

/// The strongest bot. Before it bids or plays, it imagines the hidden cards
/// dealt in many ways, plays each of those rounds out to its end, and keeps
/// the bid or the card that scores best on average. It sees only its own
/// seat's view, and remembers what was played from the tricks of the round.
///
/// With two players, where the ghost plays by no rule, and for the powers
/// and the plank, it does as the sensible bot.
///
/// [effort] and [fewestSamples] bound the work of a decision; tests lower
/// them to go faster.
Bot sharpBot(
  Random random, {
  int effort = defaultEffort,
  int fewestSamples = defaultFewestSamples,
}) {
  final work = (effort: effort, fewest: fewestSamples);
  final sensible = sensibleBot();
  return (question, view) {
    final hasGhost = view.bids.length > view.scores.length;
    if (hasGhost) return sensible(question, view);
    return switch (question) {
      BidQuestion() => _bid(question, view, random, work),
      PlayQuestion() => _play(question, view, random, work),
      _ => sensible(question, view),
    };
  };
}

/// Tries the bid the plain rules give and its two neighbours, on the same
/// imagined deals, and keeps the one that scores best.
BidAnswer _bid(
  BidQuestion question,
  GameView view,
  Random random,
  ({int effort, int fewest}) work,
) {
  final players = view.handSizes.length;
  final guess = sensibleBid(
    view.hand,
    players: players,
  ).clamp(0, question.maxBid);
  final candidates = {
    for (final bid in [guess, guess - 1, guess + 1])
      if (bid >= 0 && bid <= question.maxBid) bid,
  }.toList();
  final totals = List.filled(candidates.length, 0);
  final leader = (view.dealer + 1) % players;
  final samples = _samplesFor(
    work,
    choices: candidates.length,
    cards: view.cardsDealt * players,
  );
  for (var sample = 0; sample < samples; sample++) {
    final hands = imagineHands(view, random);
    // The others bid what the plain rules make of the hand imagined for
    // them.
    final bids = [
      for (final hand in hands)
        sensibleBid(hand, players: players).clamp(0, question.maxBid),
    ];
    for (final (index, bid) in candidates.indexed) {
      bids[view.seat] = bid;
      totals[index] += Playout(
        me: view.seat,
        hands: hands,
        bids: bids,
        tricksWon: List.filled(players, 0),
        trick: const [],
        leader: leader,
        cardsDealt: view.cardsDealt,
        scoring: view.scoring,
      ).score();
    }
  }
  var best = 0;
  for (var index = 1; index < candidates.length; index++) {
    // The plain guess comes first: it wins the ties.
    if (totals[index] > totals[best]) best = index;
  }
  return BidAnswer(seat: question.seat, bid: candidates[best]);
}

/// Tries every card it may play, each on the same imagined deals, and keeps
/// the one after which the round scores best.
PlayAnswer _play(
  PlayQuestion question,
  GameView view,
  Random random,
  ({int effort, int fewest}) work,
) {
  final seat = question.seat;
  final plain = sensiblePlay(
    seat: seat,
    legalCards: question.legalCards,
    trick: view.trick,
    needsTricks: view.bids[seat]! > view.tricksWon[seat],
    seats: view.handSizes.length,
  );
  final options = [
    // The plain choice first: it wins the ties.
    plain,
    for (final card in question.legalCards)
      for (final way in waysToPlay(card, view.trick))
        if (way.card != plain.card ||
            way.tigressAs != plain.tigressAs ||
            way.declaredValue != plain.declaredValue ||
            way.jokerSuit != plain.jokerSuit)
          PlayAnswer(
            seat: seat,
            card: way.card,
            tigressAs: way.tigressAs,
            declaredValue: way.declaredValue,
            jokerSuit: way.jokerSuit,
          ),
  ];
  if (options.length == 1) return plain;
  final bids = [for (final bid in view.bids) bid ?? 0];
  final totals = List.filled(options.length, 0);
  final samples = _samplesFor(
    work,
    choices: options.length,
    cards: view.handSizes.fold(0, (sum, size) => sum + size),
  );
  for (var sample = 0; sample < samples; sample++) {
    final hands = imagineHands(view, random);
    for (final (index, option) in options.indexed) {
      totals[index] += Playout(
        me: seat,
        hands: hands,
        bids: bids,
        tricksWon: view.tricksWon,
        trick: view.trick,
        leader: seat,
        cardsDealt: view.cardsDealt,
        scoring: view.scoring,
      ).score(first: option);
    }
  }
  var best = 0;
  for (var index = 1; index < options.length; index++) {
    if (totals[index] > totals[best]) best = index;
  }
  return options[best];
}
