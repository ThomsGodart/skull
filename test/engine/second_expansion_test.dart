import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:skull_kings/engine/engine.dart';

import 'support.dart';

Card g7x = const Card.extraNumber(Suit.green, 7);
Card y8x = const Card.extraNumber(Suit.yellow, 8);
Card zero14(Suit suit) => Card.zeroFourteen(suit);

/// A play of [card] by [seat], with whatever its card needs said.
Play pl(int seat, Card card, {int? as, Suit? suit, TigressMode? tigressAs}) =>
    Play(
      seat: seat,
      card: card,
      declaredValue: as,
      jokerSuit: suit,
      tigressAs: tigressAs,
    );

const everything = GameConfig(
  players: 5,
  seed: 0,
  kraken: true,
  whiteWhale: true,
  loot: true,
  piratePowers: true,
  secondExpansion: true,
);

void main() {
  group('the deck', () {
    test('the second expansion adds its 19 cards, each found again from its '
        'identifier', () {
      final base = deckFor(const GameConfig(players: 4, seed: 1));
      final deck = deckFor(
        const GameConfig(players: 4, seed: 1, secondExpansion: true),
      );

      expect(deck, hasLength(89));
      expect(deck.take(70), base, reason: 'the base deck comes first');
      expect(deck.toSet(), hasLength(89));
      for (final card in secondExpansionCards()) {
        expect(Card.fromId(card.id), card);
      }
      expect(deckFor(everything), hasLength(93));
    });

    test('with it, eight players get ten cards in the last rounds', () {
      expect(cardsDealt(round: 10, players: 8, secondExpansion: true), 10);
      expect(cardsDealt(round: 10, players: 8), 8);
    });

    test('its five additional cards may each be left out; the others always '
        'come with it', () {
      const config = GameConfig(
        players: 4,
        seed: 1,
        secondExpansion: true,
        leftOut: {CardKind.mat, CardKind.lastSalvo},
      );
      final deck = deckFor(config);

      expect(deck, hasLength(87));
      expect(deck, isNot(contains(matCard)));
      expect(deck, isNot(contains(lastSalvoCard)));
      expect(deck, containsAll([jokerCard, maryCard, plankCard]));
      final back = GameConfig.fromJson(
        jsonDecode(jsonEncode(config.toJson())) as Map<String, Object?>,
      );
      expect(back.leftOut, config.leftOut);
    });

    test('it is left out of a two-player game, which the ghost could not '
        'play', () {
      const config = GameConfig(players: 2, seed: 1, secondExpansion: true);

      expect(config.playsSecondExpansion, isFalse);
      expect(deckFor(config), hasLength(70));
    });
  });

  group('the extra number cards', () {
    test('of two equal 8s, the first played wins; taking the extra 8 is '
        'worth 5 and the extra 7 costs 5', () {
      final result = resolveTrick([
        pl(0, y(8)),
        pl(1, p(12)),
        pl(2, y8x),
        pl(3, esc()),
      ]);
      expect(result.winner, 0);
      expect(result.bonuses, [Bonus.extraEight]);

      expect(resolveTrick([pl(0, g7x), pl(1, g(7))]).winner, 0);
      expect(resolveTrick([pl(0, g(9)), pl(1, g7x)]).bonuses, [
        Bonus.extraSeven,
      ]);
    });

    test('an extra card follows its suit like any other', () {
      expect(legalCards([g7x, y(3)], [pl(0, g(2))]), [g7x]);
    });

    test('a 0/14 follows its suit, wins as a 14 and loses as a 0, and '
        'carries no bonus', () {
      final card = zero14(Suit.green);
      expect(legalCards([card, y(3)], [pl(0, g(2))]), [card]);

      final high = resolveTrick([pl(0, g(13)), pl(1, card, as: 14)]);
      expect(high.winner, 1);
      expect(high.bonuses, isEmpty);
      expect(resolveTrick([pl(0, g(1)), pl(1, card, as: 0)]).winner, 0);
      // Of two 14s, the first played.
      expect(resolveTrick([pl(0, g(14)), pl(1, card, as: 14)]).winner, 0);
    });
  });

  group('the joker', () {
    test('is always legal and never forces a suit', () {
      expect(legalCards([jokerCard, g(3)], [pl(0, g(2))]), [jokerCard, g(3)]);
      expect(legalCards([jokerCard, g(3)], [pl(0, y(2))]), [jokerCard, g(3)]);
    });

    test('is a 15 of the base suit led, and loses to any trump', () {
      final led = [pl(0, y(14))];
      expect(inheritedJokerSuit(led), Suit.yellow);
      expect(
        resolveTrick([...led, pl(1, jokerCard, suit: Suit.yellow)]).winner,
        1,
      );
      expect(
        resolveTrick([...led, pl(1, jokerCard, suit: Suit.yellow), pl(2, b(1))])
            .winner,
        2,
      );
    });

    test('stands for no suit when trump is led, and loses', () {
      expect(inheritedJokerSuit([pl(0, b(2))]), isNull);
      expect(resolveTrick([pl(0, b(2)), pl(1, jokerCard)]).winner, 0);
    });

    test('names the suit when it sets it, and the others follow', () {
      expect(suitIsOpen([pl(0, esc())]), isTrue);
      expect(suitIsOpen([pl(0, g(2))]), isFalse);
      expect(suitIsOpen([pl(0, pirate())]), isFalse);
      final trick = [pl(0, jokerCard, suit: Suit.purple)];
      expect(leadSuit(trick), Suit.purple);
      expect(legalCards([p(2), g(9)], trick), [p(2)]);
    });

    test('is the highest card under the white whale', () {
      final result = resolveTrick([
        pl(0, b(14)),
        pl(1, jokerCard),
        pl(2, whale),
      ]);
      expect(result.winner, 1);
    });
  });

  group('Mat', () {
    test('beats pirates and numbers, earns nothing for the pirates', () {
      final result = resolveTrick([
        pl(0, pirate()),
        pl(1, matCard),
        pl(2, b(14)),
      ]);
      expect(result.winner, 1);
      expect(result.bonuses, [Bonus.blackFourteen]);
    });

    test('is taken by the Skull King and by a mermaid, even with a pirate '
        'around, for 30 points', () {
      final king = resolveTrick([pl(0, matCard), pl(1, skullKing)]);
      expect(king.winner, 1);
      expect(king.bonuses, [Bonus.matCaptured]);

      final siren = resolveTrick([
        pl(0, pirate()),
        pl(1, matCard),
        pl(2, mermaid()),
      ]);
      expect(siren.winner, 2);
      expect(siren.bonuses, [Bonus.matCaptured]);
    });

    test('led, sets no suit to follow', () {
      expect(leadSuit([pl(0, matCard), pl(1, g(4))]), isNull);
    });
  });

  group('the stingray', () {
    test('gives the trick to the lowest number, the first of equals', () {
      final result = resolveTrick([
        pl(0, b(9)),
        pl(1, g(3)),
        pl(2, skullKing),
        pl(3, y(3)),
        pl(4, stingrayCard),
      ]);
      expect(result.winner, 1);
    });

    test('a 0 is the lowest of all', () {
      final result = resolveTrick([
        pl(0, g(1)),
        pl(1, zero14(Suit.black), as: 0),
        pl(2, stingrayCard),
      ]);
      expect(result.winner, 1);
    });

    test('of several sea monsters, the last played decides', () {
      final plays = [pl(0, g(2)), pl(1, g(9))];
      expect(
        resolveTrick([...plays, pl(2, stingrayCard), pl(3, whale)]).winner,
        1,
      );
      expect(
        resolveTrick([...plays, pl(2, whale), pl(3, stingrayCard)]).winner,
        0,
      );
      expect(
        resolveTrick([...plays, pl(2, stingrayCard), pl(3, kraken)]).destroyed,
        isTrue,
      );
    });

    test('led, leaves the next player to set the suit; played later, lifts '
        'it', () {
      final hand = [g(3), y(5)];
      expect(legalCards(hand, [pl(0, stingrayCard), pl(1, y(9))]), [y(5)]);
      expect(legalCards(hand, [pl(0, y(9)), pl(1, stingrayCard)]), hand);
    });
  });

  group('Davy Jones\' chest', () {
    test('destroys the sea monsters: the trick is settled without them, and '
        'its player earns 20 for each', () {
      final result = resolveTrick([
        pl(0, g(5)),
        pl(1, kraken),
        pl(2, davyJonesCard),
        pl(3, g(11)),
        pl(4, whale),
      ]);
      expect(result.destroyed, isFalse);
      expect(result.winner, 3);
      expect(result.sideBonuses, [
        (2, Bonus.seaMonsterCaptured),
        (2, Bonus.seaMonsterCaptured),
      ]);
    });

    test('without a sea monster, it simply loses', () {
      final result = resolveTrick([pl(0, davyJonesCard), pl(1, g(2))]);
      expect(result.winner, 1);
      expect(result.sideBonuses, isEmpty);
    });
  });

  group('the cards that take no trick', () {
    test('are no escapes: the first escape takes a trick of them', () {
      final result = resolveTrick([
        pl(0, plankCard),
        pl(1, lastSalvoCard),
        pl(2, esc()),
        pl(3, esc(2)),
      ]);
      expect(result.destroyed, isFalse);
      expect(result.winner, 2);
    });

    test('alone, they make a trick that is thrown away: its leader leads '
        'again', () {
      final result = resolveTrick([
        pl(1, davyJonesCard),
        pl(2, stingrayCard),
        pl(0, plankCard),
      ]);
      expect(result.destroyed, isTrue);
      expect(result.winner, 1);
    });

    test('led, they leave the next player to set the suit', () {
      final hand = [g(3), y(5)];
      for (final card in [plankCard, lastSalvoCard, davyJonesCard]) {
        expect(legalCards(hand, [pl(0, card), pl(1, y(9))]), [y(5)]);
      }
    });
  });

  group('the plank', () {
    test('a pirate thrown overboard no longer counts: neither to win, nor '
        'for the Skull King\'s bonus', () {
      final plays = [pl(0, pirate()), pl(1, plankCard), pl(2, g(4))];
      expect(resolveTrick(plays, overboard: pirate()).winner, 2);

      final king = [pl(0, pirate()), pl(1, skullKing), pl(2, plankCard)];
      expect(resolveTrick(king, overboard: pirate()).bonuses, isEmpty);
    });

    test('with several pirates its player says which one goes, which may '
        'change the winner', () {
      final game = _gameWhere(
        (game) => game.pending.first is WalkPlankQuestion,
        const GameConfig(players: 4, seed: 0, secondExpansion: true),
      );
      final question = game.pending.single as WalkPlankQuestion;
      expect(question.pirates.length, greaterThan(1));
      expect(
        () => game.answer(
          WalkPlankAnswer(seat: question.seat, pirate: skullKing),
        ),
        throwsA(isA<IllegalAnswer>()),
      );

      game.takeEvents();
      final thrown = question.pirates.first;
      game.answer(WalkPlankAnswer(seat: question.seat, pirate: thrown));
      final won = game.takeEvents().whereType<TrickWon>().single;
      expect(won.overboard, thrown);
      expect(won.winner, resolveTrick(won.plays, overboard: thrown).winner);
    });
  });

  group('in a whole game', () {
    test('with everything on, games of every size end with one winner and '
        'every card is played', () {
      final seen = <Type>{};
      for (var players = 3; players <= 8; players++) {
        for (var seed = 0; seed < 40; seed++) {
          final game = Game(everything.copyWith(players: players, seed: seed));
          final random = Random(seed);
          var plays = 0;
          var cards = 0;
          GameFinished? finished;
          void drain() {
            for (final event in game.takeEvents()) {
              seen.add(event.runtimeType);
              switch (event) {
                case RoundStarted():
                  plays = 0;
                  cards = event.cardsDealt;
                case CardPlayed():
                  plays++;
                case RoundScored():
                  // Will draws and discards as many: every hand is played.
                  expect(plays, cards * players, reason: '$players/$seed');
                  final won = event.results.fold(0, (n, r) => n + r.tricksWon);
                  expect(won, lessThanOrEqualTo(cards));
                case GameFinished():
                  finished = event;
                default:
              }
            }
          }

          drain();
          var guard = 0;
          while (game.pending.isNotEmpty) {
            final question = game.pending.first;
            seen.add(question.runtimeType);
            game.answer(
              randomAnswer(
                question,
                random,
                trick: game.viewFor(question.seat).trick,
              ),
            );
            drain();
            expect(++guard, lessThan(100000));
          }
          expect(finished, isNotNull, reason: '$players/$seed');
        }
      }
      expect(
        seen,
        containsAll([
          WalkPlankQuestion,
          ChooseVictimQuestion,
          VictimChosen,
          CardForced,
        ]),
      );
    });

    test('the last salvo makes its player play twice in the trick, then sit '
        'out a later one', () {
      var checked = 0;
      for (var seed = 0; seed < 40 && checked < 5; seed++) {
        final game = Game(
          GameConfig(players: 4, seed: seed, secondExpansion: true),
        );
        final random = Random(seed);
        int? salvoSeat;
        var sitsOut = false;
        var roundCards = 0;
        while (game.pending.isNotEmpty) {
          final question = game.pending.first;
          game.answer(
            randomAnswer(
              question,
              random,
              trick: game.viewFor(question.seat).trick,
            ),
          );
          for (final event in game.takeEvents()) {
            switch (event) {
              case RoundStarted():
                expect(salvoSeat == null || sitsOut || roundCards == 0, isTrue);
                salvoSeat = null;
                sitsOut = false;
                roundCards = event.cardsDealt;
              case TrickWon(:final plays):
                final seats = [for (final play in plays) play.seat];
                final salvo = plays
                    .where((p) => p.card.kind == CardKind.lastSalvo)
                    .firstOrNull;
                if (salvo != null && seats.length == 5) {
                  expect(seats.where((s) => s == salvo.seat), hasLength(2));
                  expect(seats.last, salvo.seat);
                  salvoSeat = salvo.seat;
                  checked++;
                } else if (salvoSeat != null && seats.length == 3) {
                  expect(seats, isNot(contains(salvoSeat)));
                  sitsOut = true;
                }
              default:
            }
          }
        }
      }
      expect(checked, greaterThanOrEqualTo(5));
    });

    test('the game says who plays each trick, and that is who is asked', () {
      for (var seed = 0; seed < 25; seed++) {
        final game = Game(everything.copyWith(players: 4, seed: seed));
        final random = Random(seed);
        var order = const <int>[];
        var played = 0;
        void drain() {
          for (final event in game.takeEvents()) {
            switch (event) {
              case TurnsSet():
                order = event.order;
              case CardPlayed():
                played++;
              case TrickWon():
                expect(played, order.length, reason: 'seed $seed');
                played = 0;
              default:
            }
          }
        }

        drain();
        while (game.pending.isNotEmpty) {
          final question = game.pending.first;
          if (question is PlayQuestion) {
            expect(question.seat, order[played], reason: 'seed $seed');
          }
          game.answer(
            randomAnswer(
              question,
              random,
              trick: game.viewFor(question.seat).trick,
            ),
          );
          drain();
        }
      }
    });

    test('Mary cannot pick herself: only opponents with cards left', () {
      final game = _gameWhere(
        (game) => game.pending.first is ChooseVictimQuestion,
        everything.copyWith(players: 4),
      );
      final question = game.pending.single as ChooseVictimQuestion;
      expect(question.seats, isNot(contains(question.seat)));
      expect(question.seats, isNotEmpty);
      for (final victim in question.seats) {
        expect(game.viewFor(victim).hand, isNotEmpty);
      }
    });

    test('Mary\'s victim can only play the card drawn from its hand', () {
      final game = _gameWhere(
        (game) => game.pending.first is ChooseVictimQuestion,
        everything.copyWith(players: 4),
      );
      final question = game.pending.single as ChooseVictimQuestion;
      final victim = question.seats.first;
      game.takeEvents();
      game.answer(ChooseVictimAnswer(seat: question.seat, victim: victim));
      final forced = game.takeEvents().whereType<CardForced>().single;
      expect(forced.audience, victim);
      expect(game.viewFor(victim).hand, contains(forced.card));

      final random = Random(1);
      while (game.pending.isNotEmpty) {
        final next = game.pending.first;
        if (next case PlayQuestion(:final seat, :final legalCards)
            when seat == victim) {
          expect(legalCards, [forced.card]);
          return;
        }
        game.answer(
          randomAnswer(next, random, trick: game.viewFor(next.seat).trick),
        );
      }
      fail('the victim never played');
    });

    test('a 0/14 needs its value and the joker its suit, and nothing else '
        'takes them', () {
      final game = _gameWhere((game) {
        final question = game.pending.first;
        return question is PlayQuestion &&
            question.legalCards.contains(jokerCard) &&
            suitIsOpen(game.viewFor(question.seat).trick) &&
            question.legalCards.any((c) => c.kind == CardKind.zeroFourteen);
      }, const GameConfig(players: 3, seed: 0, secondExpansion: true));
      final question = game.pending.first as PlayQuestion;
      final seat = question.seat;
      final card = question.legalCards.firstWhere(
        (c) => c.kind == CardKind.zeroFourteen,
      );
      void refused(PlayAnswer answer) =>
          expect(() => game.answer(answer), throwsA(isA<IllegalAnswer>()));

      refused(PlayAnswer(seat: seat, card: jokerCard));
      refused(PlayAnswer(seat: seat, card: jokerCard, jokerSuit: Suit.black));
      refused(PlayAnswer(seat: seat, card: card));
      refused(PlayAnswer(seat: seat, card: card, declaredValue: 7));
      refused(
        PlayAnswer(
          seat: seat,
          card: card,
          declaredValue: 0,
          jokerSuit: Suit.green,
        ),
      );
      game.answer(
        PlayAnswer(seat: seat, card: jokerCard, jokerSuit: Suit.green),
      );
      expect(game.viewFor(seat).trick.last.suit, Suit.green);
    });

    test('a game saved as JSON half-way resumes at the same point, and its '
        'events and questions come back the same from JSON', () {
      for (var seed = 0; seed < 20; seed++) {
        final config = everything.copyWith(seed: seed);
        final original = Game(config);
        final random = Random(seed);
        for (var i = 0; i < 120 && original.pending.isNotEmpty; i++) {
          for (final question in original.pending) {
            final json = questionToJson(question);
            final back = questionFromJson(
              jsonDecode(jsonEncode(json)) as Map<String, Object?>,
            );
            expect(questionToJson(back), json);
          }
          final question = original.pending.first;
          original.answer(
            randomAnswer(
              question,
              random,
              trick: original.viewFor(question.seat).trick,
            ),
          );
          for (final event in original.takeEvents()) {
            final json = eventToJson(event);
            final back = eventFromJson(
              jsonDecode(jsonEncode(json)) as Map<String, Object?>,
            );
            expect(eventToJson(back), json);
          }
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
          expect(
            resumed.viewFor(seat).trick.length,
            original.viewFor(seat).trick.length,
          );
        }
        expect(
          resumed.pending.map(questionToJson).toList(),
          original.pending.map(questionToJson).toList(),
        );
      }
    });
  });
}

/// Plays random games of [config], seed after seed, up to the first moment
/// [reached] holds, and returns that game.
Game _gameWhere(bool Function(Game game) reached, GameConfig config) {
  for (var seed = 0; seed < 400; seed++) {
    final game = Game(config.copyWith(seed: seed));
    final random = Random(seed);
    while (game.pending.isNotEmpty) {
      if (reached(game)) return game;
      final question = game.pending.first;
      game.answer(
        randomAnswer(
          question,
          random,
          trick: game.viewFor(question.seat).trick,
        ),
      );
    }
  }
  fail('no game reached that point');
}
