import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:skull_kings/bots/bot.dart';
import 'package:skull_kings/bots/bot_level.dart';
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
          final bot = botFor(botLevel, Random(seed));
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

  test('at a crowded table, a hard bot wins clearly more often than a '
      'normal one would', () {
    final normal = level(BotLevel.normal);

    // Among six equal players, each wins about one game in six.
    expect(
      winRate(level(BotLevel.hard), normal, players: 6),
      greaterThan(0.26),
    );
    expect(
      winRate(level(BotLevel.hard), normal, players: 8),
      greaterThan(0.25),
    );
  });

  test('at a small table, a hard bot plays exactly like a normal one', () {
    final normal = level(BotLevel.normal);
    final hard = level(BotLevel.hard);
    for (var seed = 0; seed < 5; seed++) {
      final game = Game(GameConfig(players: 4, seed: seed));
      while (game.pending.isNotEmpty) {
        final question = game.pending.first;
        final view = game.viewFor(question.seat);
        final answer = hard(question, view);
        expect(answerToJson(answer), answerToJson(normal(question, view)));
        game.answer(answer);
      }
    }
  });
}
