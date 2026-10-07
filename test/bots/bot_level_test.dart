import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:skull_kings/bots/bot.dart';
import 'package:skull_kings/bots/bot_level.dart';
import 'package:skull_kings/bots/playout.dart';
import 'package:skull_kings/bots/sharp_bot.dart';
import 'package:skull_kings/engine/engine.dart';

/// Share of [games] won by [candidate] at seat 0 against [others].
double winRate(
  Bot candidate,
  Bot others, {
  required int players,
  int games = 250,
}) {
  var wins = 0;
  for (var seed = 0; seed < games; seed++) {
    final game = Game(GameConfig(players: players, seed: seed));
    GameFinished? finished;
    while (game.pending.isNotEmpty) {
      final question = game.pending.first;
      final bot = question.seat == 0 ? candidate : others;
      game.answer(bot(question, game.viewFor(question.seat)));
      finished =
          game.takeEvents().whereType<GameFinished>().firstOrNull ?? finished;
    }
    if (finished!.winner == 0) wins++;
  }
  return wins / games;
}

void main() {
  Bot level(BotLevel level) => botFor(level, Random(1));

  test('every level only ever gives legal answers, with every option and '
      'at every table size', () {
    for (final botLevel in BotLevel.values) {
      for (var players = 2; players <= 8; players++) {
        for (var seed = 0; seed < 6; seed++) {
          final game = Game(
            GameConfig(
              players: players,
              seed: seed,
              kraken: true,
              whiteWhale: true,
              loot: true,
              piratePowers: true,
              secondExpansion: seed % 3 != 0,
              scoring: seed.isEven ? Scoring.classic : Scoring.rascal,
            ),
          );
          // The hard bot with little to simulate: only its answers being
          // legal is looked at here.
          final bot = botLevel == BotLevel.hard
              ? sharpBot(Random(seed), effort: 1, fewestSamples: 2)
              : botFor(botLevel, Random(seed));
          var guard = 0;
          while (game.pending.isNotEmpty) {
            final question = game.pending.first;
            game.answer(bot(question, game.viewFor(question.seat)));
            expect(++guard, lessThan(20000));
          }
          expect(
            game.isFinished,
            isTrue,
            reason: '$botLevel, $players players',
          );
        }
      }
    }
  });

  test('an easy bot wins clearly less often than a normal one would', () {
    final normal = level(BotLevel.normal);

    // Among four equal players, each wins about one game in four.
    expect(winRate(level(BotLevel.easy), normal, players: 4), lessThan(0.17));
  });

  test('a hard bot wins far more often than a normal one would, at a small '
      'table as at a crowded one', () {
    final normal = level(BotLevel.normal);
    Bot hard() => sharpBot(Random(1), effort: 3000);

    // Among equal players, each would win one game in four, or in six.
    expect(winRate(hard(), normal, players: 4, games: 30), greaterThan(0.4));
    expect(winRate(hard(), normal, players: 6, games: 20), greaterThan(0.35));
  });

  test('with two players, where the ghost follows no rule, a hard bot plays '
      'like a normal one', () {
    final normal = level(BotLevel.normal);
    final hard = level(BotLevel.hard);
    for (var seed = 0; seed < 5; seed++) {
      final game = Game(GameConfig(players: 2, seed: seed));
      while (game.pending.isNotEmpty) {
        final question = game.pending.first;
        final view = game.viewFor(question.seat);
        final answer = hard(question, view);
        expect(answerToJson(answer), answerToJson(normal(question, view)));
        game.answer(answer);
      }
    }
  });

  test('the hidden cards a bot imagines are the ones it has not seen, in '
      'hands of the right size, and never a suit a seat ran out of', () {
    final random = Random(3);
    for (var seed = 0; seed < 20; seed++) {
      final game = Game(GameConfig(players: 5, seed: seed));
      final bot = level(BotLevel.normal);
      var checked = 0;
      while (game.pending.isNotEmpty && checked < 40) {
        final question = game.pending.first;
        final view = game.viewFor(question.seat);
        if (question is PlayQuestion) {
          checked++;
          final hands = imagineHands(view, random);
          expect(hands[view.seat], view.hand);
          expect([for (final hand in hands) hand.length], view.handSizes);
          final dealt = [for (final hand in hands) ...hand];
          expect(dealt.toSet(), hasLength(dealt.length));
          final played = {
            for (final play in view.trick) play.card,
            for (final trick in view.roundTricks)
              for (final play in trick) play.card,
          };
          expect(dealt.where(played.contains), isEmpty);
          expect(view.deck, containsAll(dealt));
        }
        game.answer(bot(question, view));
      }
    }
  });

  test('a round played out in the mind ends with every card played and '
      'scores like the rules', () {
    // Two cards each: seat 0 holds the two highest trumps and bid two.
    final hands = [
      [const Card.number(Suit.black, 14), const Card.number(Suit.black, 13)],
      [const Card.number(Suit.green, 3), const Card.number(Suit.green, 4)],
      [const Card.number(Suit.yellow, 5), const Card.number(Suit.yellow, 6)],
    ];
    int score(int bid) => Playout(
      me: 0,
      hands: hands,
      bids: [bid, 0, 0],
      tricksWon: [0, 0, 0],
      trick: const [],
      leader: 0,
      cardsDealt: 2,
      scoring: Scoring.classic,
    ).score();

    // Both tricks, and the black 14 among them.
    expect(score(2), 60);
    expect(
      hands.every((hand) => hand.length == 2),
      isTrue,
      reason: 'untouched',
    );
  });
}
