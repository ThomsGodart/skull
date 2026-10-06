import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:skull_kings/engine/engine.dart';

/// Plays a two-player game to the end with random answers.
List<Event> playTwo(GameConfig config, {int botSeed = 1}) {
  final game = Game(config);
  final random = Random(botSeed);
  final events = <Event>[];
  var guard = 0;
  while (true) {
    events.addAll(game.takeEvents());
    final questions = game.pending;
    if (questions.isEmpty) break;
    for (final question in questions) {
      expect(question.seat, lessThan(2), reason: 'the ghost is never asked');
    }
    game.answer(
      randomAnswer(questions[random.nextInt(questions.length)], random),
    );
    expect(++guard, lessThan(100000));
  }
  expect(game.isFinished, isTrue);
  return events;
}

void main() {
  const two = GameConfig(players: 2, seed: 0);
  const seeds = 80;

  test('two players sit with a ghost: three hands are dealt, two bids '
      'are asked', () {
    final game = Game(two);
    final events = game.takeEvents();

    expect(game.seats, 3);
    expect(game.ghostSeat, 2);
    expect(events.whereType<HandDealt>().map((e) => e.seat), [0, 1]);
    expect(game.viewFor(0).handSizes, [1, 1, 1]);
    expect(game.pending.map((q) => q.seat), unorderedEquals([0, 1]));
  });

  test('with three players or more there is no ghost', () {
    final game = Game(const GameConfig(players: 3, seed: 0));

    expect(game.seats, 3);
    expect(game.ghostSeat, isNull);
  });

  test('the two players take turns to lead the rounds', () {
    for (var seed = 0; seed < 10; seed++) {
      final leaders = playTwo(two.copyWith(seed: seed))
          .whereType<RoundStarted>()
          .take(10)
          .map((round) => round.leader)
          .toList();

      expect(leaders.toSet(), {0, 1});
      for (var i = 1; i < leaders.length; i++) {
        expect(leaders[i], 1 - leaders[i - 1]);
      }
    }
  });

  test('the ghost always plays second when a player leads; when the ghost '
      'leads, the player who started the round plays second', () {
    var ghostLed = 0;
    for (var seed = 0; seed < seeds; seed++) {
      var starter = 0;
      for (final event in playTwo(two.copyWith(seed: seed), botSeed: seed)) {
        if (event is RoundStarted) starter = event.leader;
        if (event is! TrickWon) continue;
        final order = event.plays.map((play) => play.seat).toList();
        expect(order.toSet(), {0, 1, 2}, reason: 'one card per seat');
        if (order.first == 2) {
          expect(order[1], starter);
          ghostLed++;
        } else {
          expect(order[1], 2);
        }
      }
    }
    expect(ghostLed, greaterThan(0));
  });

  test('whoever wins a trick leads the next one, the ghost included', () {
    for (var seed = 0; seed < 20; seed++) {
      int? winner;
      for (final event in playTwo(two.copyWith(seed: seed))) {
        if (event is RoundStarted) winner = null;
        if (event is! TrickWon) continue;
        if (winner != null) expect(event.plays.first.seat, winner);
        winner = event.winner;
      }
    }
  });

  test('the ghost plays the cards of its packet in order, without having '
      'to follow suit, and its tigress is an escape', () {
    var tigress = 0;
    var revoked = 0;
    for (var seed = 0; seed < seeds; seed++) {
      for (final event in playTwo(two.copyWith(seed: seed), botSeed: seed)) {
        if (event is! TrickWon) continue;
        final ghost = event.plays.firstWhere((play) => play.seat == 2);
        if (ghost.card.kind == CardKind.tigress) {
          expect(ghost.tigressAs, TigressMode.escape);
          tigress++;
        }
        final before = event.plays.takeWhile((play) => play.seat != 2).toList();
        final suit = leadSuit(before);
        if (suit != null && ghost.card.isNumber && ghost.card.suit != suit) {
          revoked++;
        }
      }
    }
    expect(tigress, greaterThan(0));
    expect(revoked, greaterThan(0), reason: 'it plays off suit at times');
  });

  test('only the two players bid and score; the ghost just takes tricks', () {
    var ghostTricks = 0;
    for (var seed = 0; seed < seeds; seed++) {
      final events = playTwo(two.copyWith(seed: seed), botSeed: seed);
      var cards = 0;
      var tricks = <TrickWon>[];
      for (final event in events) {
        switch (event) {
          case RoundStarted():
            cards = event.cardsDealt;
            tricks = [];
          case BidsRevealed():
            expect(event.bids, hasLength(2));
          case TrickWon():
            tricks.add(event);
          case RoundScored():
            expect(event.results, hasLength(2));
            final byPlayers = event.results.fold(0, (n, r) => n + r.tricksWon);
            final byGhost = tricks.where((t) => t.winner == 2).length;
            expect(byPlayers + byGhost, cards);
            ghostTricks += byGhost;
          case GameFinished():
            expect(event.scores, hasLength(2));
            expect(event.winner, lessThan(2));
          default:
        }
      }
    }
    expect(ghostTricks, greaterThan(0));
  });

  test('loot is left out of a two-player game, whatever was asked', () {
    final config = two.copyWith(loot: true, kraken: true, piratePowers: true);

    expect(
      deckFor(config).where((card) => card.kind == CardKind.loot),
      isEmpty,
    );
    expect(
      deckFor(config).where((card) => card.kind == CardKind.kraken),
      hasLength(1),
    );
    for (var seed = 0; seed < 30; seed++) {
      playTwo(config.copyWith(seed: seed), botSeed: seed);
    }
  });

  test('the ghost never uses a pirate power, and Rosie may only name a '
      'player', () {
    final config = two.copyWith(piratePowers: true);
    var named = 0;
    for (var seed = 0; seed < seeds; seed++) {
      final game = Game(config.copyWith(seed: seed));
      final random = Random(seed);
      while (game.pending.isNotEmpty) {
        final question = game.pending[random.nextInt(game.pending.length)];
        expect(question.seat, lessThan(2));
        if (question is ChooseLeaderQuestion) {
          expect(question.seats, [0, 1]);
          named++;
        }
        game.answer(randomAnswer(question, random));
      }
    }
    expect(named, greaterThan(0));
  });

  test('each round deals as many cards as a three-handed one', () {
    expect(cardsDealt(round: 10, players: 2), 10);
    expect(cardsDealt(round: 4, players: 2), 4);
  });

  test('a two-player game resumes from its answers', () {
    final original = Game(two.copyWith(seed: 5));
    final random = Random(5);
    for (var i = 0; i < 40; i++) {
      original.answer(randomAnswer(original.pending.first, random));
    }

    final resumed = Game.replay(two.copyWith(seed: 5), original.answers);

    expect(resumed.viewFor(0).hand, original.viewFor(0).hand);
    expect(resumed.viewFor(0).trick.length, original.viewFor(0).trick.length);
    expect(
      resumed.pending.map((q) => q.seat),
      original.pending.map((q) => q.seat),
    );
  });
}
