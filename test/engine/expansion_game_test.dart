import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:skull_kings/engine/engine.dart';

const full = GameConfig(
  players: 5,
  seed: 0,
  kraken: true,
  whiteWhale: true,
  loot: true,
  piratePowers: true,
);

GameConfig withSeed(GameConfig config, int seed, {int? players}) => GameConfig(
  players: players ?? config.players,
  seed: seed,
  scoring: config.scoring,
  kraken: config.kraken,
  whiteWhale: config.whiteWhale,
  loot: config.loot,
  piratePowers: config.piratePowers,
);

/// Plays [game] to the end with random answers. [onQuestion] sees every
/// question before it is answered and may give the answer itself; [onEvent]
/// sees every event as it comes.
void play(
  Game game, {
  int botSeed = 1,
  Answer? Function(Question question)? onQuestion,
  void Function(Event event)? onEvent,
}) {
  final random = Random(botSeed);
  void drain() => game.takeEvents().forEach((event) => onEvent?.call(event));
  drain();
  var guard = 0;
  while (game.pending.isNotEmpty) {
    final questions = game.pending;
    final question = questions[random.nextInt(questions.length)];
    game.answer(onQuestion?.call(question) ?? randomAnswer(question, random));
    drain();
    expect(++guard, lessThan(100000));
  }
}

void main() {
  const seeds = 150;

  test('with every option on, games of every size end with one winner, '
      'and each round accounts for every trick', () {
    for (var players = 3; players <= 8; players++) {
      for (var seed = 0; seed < 60; seed++) {
        final game = Game(withSeed(full, seed, players: players));
        var destroyed = 0;
        var cards = 0;
        GameFinished? finished;
        play(
          game,
          botSeed: seed,
          onEvent: (event) {
            switch (event) {
              case RoundStarted():
                destroyed = 0;
                cards = event.cardsDealt;
              case TrickWon(destroyed: true):
                destroyed++;
              case RoundScored():
                final won = event.results.fold(0, (n, r) => n + r.tricksWon);
                expect(won + destroyed, cards, reason: 'seed $seed');
              case GameFinished():
                finished = event;
              default:
            }
          },
        );
        expect(game.isFinished, isTrue);
        final best = finished!.scores.reduce(max);
        expect(finished!.scores.where((s) => s == best), hasLength(1));
      }
    }
  });

  test('a destroyed trick is won by nobody, and its would-be winner leads '
      'the next one', () {
    var seen = 0;
    for (var seed = 0; seed < seeds; seed++) {
      final game = Game(withSeed(full, seed));
      int? expectedLeader;
      List<int> wonBefore = const [];
      play(
        game,
        botSeed: seed,
        onQuestion: (question) {
          if (question is PlayQuestion && expectedLeader != null) {
            expect(question.seat, expectedLeader);
            expect(game.viewFor(0).tricksWon, wonBefore);
            expectedLeader = null;
            seen++;
          }
          if (question is PlayQuestion && game.viewFor(0).trick.isEmpty) {
            wonBefore = game.viewFor(0).tricksWon;
          }
          return null;
        },
        onEvent: (event) {
          if (event is TrickWon && event.destroyed) {
            expect(event.bonuses, isEmpty);
            expectedLeader = event.winner;
          }
          if (event is RoundStarted) expectedLeader = null;
        },
      );
    }
    expect(seen, greaterThan(20));
  });

  test('a loot alliance pays 20 to both members only when both made '
      'their bid', () {
    var paid = 0;
    var unpaid = 0;
    for (var seed = 0; seed < seeds; seed++) {
      final game = Game(GameConfig(players: 4, seed: seed, loot: true));
      var alliances = <Alliance>[];
      play(
        game,
        botSeed: seed,
        onEvent: (event) {
          if (event is RoundStarted) alliances = [];
          if (event is TrickWon) alliances.addAll(event.alliances);
          if (event is RoundScored) {
            for (var seat = 0; seat < 4; seat++) {
              final made = alliances.where((alliance) {
                final mine =
                    alliance.lootSeat == seat || alliance.winnerSeat == seat;
                return mine &&
                    event.results[alliance.lootSeat].bidMade &&
                    event.results[alliance.winnerSeat].bidMade;
              }).length;
              expect(event.results[seat].score.alliancePoints, 20 * made);
              made > 0 ? paid++ : unpaid++;
            }
          }
        },
      );
    }
    expect(paid, greaterThan(0));
    expect(unpaid, greaterThan(0));
  });

  group('pirate powers', () {
    const powers = GameConfig(players: 4, seed: 0, piratePowers: true);

    /// The pirate that won the last trick, as a power question implies.
    Pirate? lastWinner(List<Event> events) {
      final trick = events.whereType<TrickWon>().last;
      final card = trick.plays.firstWhere((p) => p.seat == trick.winner).card;
      return Pirate.of(card);
    }

    test('without the option, no pirate ever asks for anything', () {
      for (var seed = 0; seed < 40; seed++) {
        play(
          Game(GameConfig(players: 4, seed: seed)),
          botSeed: seed,
          onQuestion: (question) {
            expect(question, anyOf(isA<BidQuestion>(), isA<PlayQuestion>()));
            return null;
          },
        );
      }
    });

    test('a power is asked of the seat that just won a trick with that '
        'pirate, never with the tigress', () {
      final asked = <Pirate, int>{};
      for (var seed = 0; seed < seeds; seed++) {
        final game = Game(withSeed(powers, seed));
        final events = <Event>[];
        play(
          game,
          botSeed: seed,
          onEvent: events.add,
          onQuestion: (question) {
            final pirate = switch (question) {
              ChooseLeaderQuestion() => Pirate.rosie,
              DiscardQuestion() => Pirate.will,
              WagerQuestion() => Pirate.rascal,
              // Harry waits for the end of the round: see his own test.
              _ => null,
            };
            if (pirate != null) {
              expect(lastWinner(events), pirate);
              expect(question.seat, events.whereType<TrickWon>().last.winner);
              asked[pirate] = (asked[pirate] ?? 0) + 1;
            }
            return null;
          },
        );
      }
      expect(
        asked.keys,
        containsAll([Pirate.rosie, Pirate.will, Pirate.rascal]),
      );
    });

    test('Harry: whoever won a trick with him is asked once the round is '
        'over, not when the trick is won', () {
      var asked = 0;
      var wonEarly = 0;
      for (var seed = 0; seed < seeds; seed++) {
        final game = Game(withSeed(powers, seed));
        int? harrySeat;
        play(
          game,
          botSeed: seed,
          onEvent: (event) {
            if (event is RoundStarted) harrySeat = null;
            if (event is TrickWon && !event.destroyed) {
              final card = event.plays
                  .firstWhere((play) => play.seat == event.winner)
                  .card;
              if (Pirate.of(card) == Pirate.harry) {
                harrySeat = event.winner;
                final handsLeft = game.viewFor(0).handSizes.first;
                if (handsLeft > 0) wonEarly++;
              }
            }
          },
          onQuestion: (question) {
            if (question is! AdjustBidQuestion) return null;
            final sizes = game.viewFor(0).handSizes;
            expect(sizes, everyElement(0), reason: 'the round is played out');
            expect(question.seat, harrySeat);
            asked++;
            return null;
          },
        );
      }
      expect(asked, greaterThan(5));
      expect(wonEarly, greaterThan(0), reason: 'he also wins before the end');
    });

    test('Rosie: the seat she names leads the next trick', () {
      var seen = 0;
      for (var seed = 0; seed < seeds; seed++) {
        final game = Game(withSeed(powers, seed));
        int? named;
        play(
          game,
          botSeed: seed,
          onQuestion: (question) {
            if (named != null) {
              expect(question, isA<PlayQuestion>());
              expect(question.seat, named);
              named = null;
              seen++;
            }
            if (question is ChooseLeaderQuestion) {
              expect(question.seats, [0, 1, 2, 3]);
              named = (question.seat + 2) % 4;
              return ChooseLeaderAnswer(seat: question.seat, leader: named!);
            }
            return null;
          },
        );
      }
      expect(seen, greaterThan(5));
    });

    test('Harry: the bid moves by one within what the round allows, and '
        'the round is scored on the new bid', () {
      var seen = 0;
      for (var seed = 0; seed < seeds; seed++) {
        final game = Game(withSeed(powers, seed));
        final expected = <int, int>{};
        var cards = 0;
        play(
          game,
          botSeed: seed,
          onEvent: (event) {
            if (event is RoundStarted) {
              expected.clear();
              cards = event.cardsDealt;
            }
            if (event is RoundScored) {
              expected.forEach((seat, bid) {
                expect(event.results[seat].bid, bid);
                seen++;
              });
            }
          },
          onQuestion: (question) {
            if (question is! AdjustBidQuestion) return null;
            final bid = game.viewFor(question.seat).bids[question.seat]!;
            expect(question.changes, contains(0));
            for (final change in question.changes) {
              expect(bid + change, inInclusiveRange(0, cards));
            }
            final change = question.changes.last;
            expected[question.seat] = bid + change;
            return AdjustBidAnswer(seat: question.seat, change: change);
          },
        );
      }
      expect(seen, greaterThan(5));
    });

    test('Rascal: the wager is won on a made bid and lost otherwise', () {
      var won = 0;
      var lost = 0;
      for (var seed = 0; seed < seeds; seed++) {
        final game = Game(withSeed(powers, seed));
        final staked = <int>{};
        play(
          game,
          botSeed: seed,
          onEvent: (event) {
            if (event is RoundStarted) staked.clear();
            if (event is RoundScored) {
              for (final (seat, result) in event.results.indexed) {
                final expected = !staked.contains(seat)
                    ? 0
                    : result.bidMade
                    ? 20
                    : -20;
                expect(result.score.wagerPoints, expected);
                if (expected > 0) won++;
                if (expected < 0) lost++;
              }
            }
          },
          onQuestion: (question) {
            if (question is! WagerQuestion) return null;
            expect(question.amounts, [0, 10, 20]);
            staked.add(question.seat);
            return WagerAnswer(seat: question.seat, amount: 20);
          },
        );
      }
      expect(won, greaterThan(0));
      expect(lost, greaterThan(0));
    });

    test('Will: two cards are drawn in private, then two are discarded, '
        'and the hand is back to its size', () {
      var seen = 0;
      for (var seed = 0; seed < seeds; seed++) {
        final game = Game(withSeed(powers, seed));
        CardsDrawn? drawn;
        play(
          game,
          botSeed: seed,
          onEvent: (event) {
            if (event is CardsDrawn) drawn = event;
          },
          onQuestion: (question) {
            if (question is! DiscardQuestion) return null;
            final view = game.viewFor(question.seat);
            final others = view.handSizes[(question.seat + 1) % 4];
            expect(drawn!.audience, question.seat);
            expect(question.count, drawn!.cards.length);
            expect(view.hand, containsAll(drawn!.cards));
            expect(view.hand.length, others + question.count);
            expect(
              () => game.answer(
                DiscardAnswer(seat: question.seat, cards: const []),
              ),
              throwsA(isA<IllegalAnswer>()),
            );
            final discarded = view.hand.take(question.count).toList();
            game.answer(DiscardAnswer(seat: question.seat, cards: discarded));
            final after = game.viewFor(question.seat);
            expect(after.hand.length, others);
            expect(after.hand, isNot(contains(discarded.first)));
            seen++;
            // Already answered: let the loop carry on with the next question.
            return game.pending.isEmpty
                ? null
                : randomAnswer(game.pending.first, Random(seed));
          },
        );
      }
      expect(seen, greaterThan(5));
    });

    test('Juanita: the cards left undealt are shown to her player alone', () {
      var seen = 0;
      for (var seed = 0; seed < seeds; seed++) {
        final game = Game(withSeed(powers, seed));
        var dealt = <Card>{};
        play(
          game,
          botSeed: seed,
          onEvent: (event) {
            if (event is RoundStarted) dealt = {};
            if (event is HandDealt) dealt.addAll(event.cards);
            if (event is StockRevealed) {
              expect(event.audience, event.seat);
              expect(event.cards.toSet().intersection(dealt), isEmpty);
              expect(event.cards, isNotEmpty);
              seen++;
            }
          },
        );
      }
      expect(seen, greaterThan(5));
    });

    test('after the last trick of a round only Harry is asked', () {
      var harryAtTheEnd = 0;
      for (var seed = 0; seed < seeds; seed++) {
        final game = Game(withSeed(powers, seed));
        play(
          game,
          botSeed: seed,
          onQuestion: (question) {
            final handsEmpty = game
                .viewFor(0)
                .handSizes
                .every((size) => size == 0);
            if (handsEmpty && game.viewFor(0).trick.isEmpty) {
              expect(question, isA<AdjustBidQuestion>());
              harryAtTheEnd++;
            }
            return null;
          },
        );
      }
      expect(harryAtTheEnd, greaterThan(0));
    });
  });

  test('a game with every option, saved as JSON half-way, resumes at the '
      'same point', () {
    for (var seed = 0; seed < 30; seed++) {
      final config = withSeed(full, seed);
      final original = Game(config);
      final random = Random(seed);
      for (var i = 0; i < 90 && original.pending.isNotEmpty; i++) {
        original.answer(randomAnswer(original.pending.first, random));
      }

      final json = jsonDecode(
        jsonEncode({
          'config': config.toJson(),
          'answers': original.answers.map(answerToJson).toList(),
        }),
      ) as Map<String, Object?>;
      final resumed = Game.replay(
        GameConfig.fromJson(json['config']! as Map<String, Object?>),
        (json['answers']! as List).map(
          (answer) => answerFromJson(answer as Map<String, Object?>),
        ),
      );

      for (var seat = 0; seat < config.players; seat++) {
        expect(resumed.viewFor(seat).hand, original.viewFor(seat).hand);
        expect(resumed.viewFor(seat).bids, original.viewFor(seat).bids);
        expect(resumed.viewFor(seat).scores, original.viewFor(seat).scores);
      }
      expect(
        resumed.pending.map((q) => (q.runtimeType, q.seat)),
        original.pending.map((q) => (q.runtimeType, q.seat)),
      );
    }
  });

  test('a config saved before the options existed reads as a base game', () {
    final config = GameConfig.fromJson({'players': 4, 'seed': 7});

    expect(config.scoring, Scoring.classic);
    expect(config.kraken || config.whiteWhale || config.loot, isFalse);
    expect(config.piratePowers, isFalse);
  });
}
