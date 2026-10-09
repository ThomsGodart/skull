import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:skull_kings/bots/bot.dart';
import 'package:skull_kings/engine/engine.dart';
import 'package:skull_kings/game/game_controller.dart';
import 'package:skull_kings/game/local_table.dart';
import 'package:skull_kings/game/table_interaction.dart';

import 'game_controller_test.dart' show playUntil, settle, tigressModeFor;

/// A game that can be made to say it changed when nothing did, as a real
/// one does while a hold or a notice comes and goes.
class Restless extends GameController {
  Restless(GameConfig config, int seed)
    : super.onFeed(
        LocalTable(config: config, bot: randomBot(Random(seed))).feedFor(0),
        speed: TableSpeed.instant,
      );

  void stir() => notifyListeners();
}

Restless controllerFor({int seed = 5, bool piratePowers = false}) => Restless(
  GameConfig(players: 4, seed: seed, piratePowers: piratePowers),
  seed,
);

void main() {
  /// A table at the human's first turn to play, in round one.
  Future<(GameController, TableInteraction)> atFirstTurn() async {
    final game = controllerFor();
    final table = TableInteraction(game);
    game.start();
    await settle();
    game.bid(0);
    await settle();
    expect(game.playQuestion, isNotNull);
    return (game, table);
  }

  test(
    'a tap lifts a card that may be played, a second puts it back',
    () async {
      final (game, table) = await atFirstTurn();
      final card = game.playQuestion!.legalCards.first;
      var notified = 0;
      table.addListener(() => notified++);

      table.tap(card);
      expect(table.selected, card);
      expect(table.shown, card);
      expect(table.canPlay, isTrue);
      expect(notified, 1);

      table.tap(card);
      expect(table.selected, isNull);
      expect(table.canPlay, isFalse);
    },
  );

  test('nothing can be played before a card is chosen', () async {
    final (_, table) = await atFirstTurn();

    expect(table.shown, isNull);
    expect(table.canPlay, isFalse);
  });

  test('a card looked at while waiting cannot be played, and becomes the '
      'selection once it may be', () async {
    final game = controllerFor();
    final table = TableInteraction(game);
    game.start();
    await settle();
    final card = game.hand.single;

    table.inspect(card);
    expect(table.inspected, card);
    expect(table.shown, card);
    expect(table.canPlay, isFalse);

    // The game moves on, but it is not yet their turn.
    game.stir();
    expect(table.inspected, card);
    expect(table.selected, isNull);

    game.bid(0);
    await settle();

    expect(table.selected, card);
    expect(table.inspected, isNull);
    expect(table.canPlay, isTrue);
  });

  test('looking at a card again puts it back, and a tap on the table puts '
      'everything back', () async {
    final game = controllerFor();
    final table = TableInteraction(game);
    game.start();
    await settle();
    final card = game.hand.single;

    table.inspect(card);
    table.inspect(card);
    expect(table.shown, isNull);

    table.inspect(card);
    table.clear();
    expect(table.shown, isNull);
  });

  test('the selection goes once its card has left the hand', () async {
    final (game, table) = await atFirstTurn();
    final card = game.playQuestion!.legalCards.first;
    table.tap(card);

    game.play(card, tigressAs: tigressModeFor(card));
    await settle();

    expect(game.hand, isNot(contains(card)));
    expect(table.selected, isNull);
  });

  test('a turn to play is signalled once, however often the game changes, '
      'and again at the next turn', () async {
    final game = controllerFor(seed: 12);
    final table = TableInteraction(game);
    var turns = 0;
    var questions = 0;
    PlayQuestion? last;
    table.onTurn = () => turns++;
    game.start();

    await playUntil(
      game,
      () => game.round == 4,
      onStep: () {
        game.stir();
        final question = game.playQuestion;
        if (question != null && !identical(question, last)) questions++;
        last = question;
      },
    );

    expect(questions, greaterThan(3));
    expect(turns, questions);
  });

  test('the table hears of everything the game does', () async {
    final game = controllerFor();
    final table = TableInteraction(game);
    var notified = 0;
    table.addListener(() => notified++);

    game.start();
    await settle();

    expect(notified, greaterThan(0));
  });

  group('a pirate power', () {
    /// Plays games with powers and returns the power questions handed to
    /// the table to ask.
    Future<List<AfterTrickQuestion>> asked({required bool autoHarry}) async {
      final questions = <AfterTrickQuestion>[];
      for (var seed = 0; seed < 12; seed++) {
        final game = controllerFor(seed: seed, piratePowers: true);
        final table = TableInteraction(game, autoHarry: () => autoHarry);
        table.onPower = questions.add;
        game.start();
        await playUntil(game, () => game.result != null, onStep: game.stir);
        table.dispose();
        game.dispose();
      }
      return questions;
    }

    test('is handed to the table to ask, once each', () async {
      final questions = await asked(autoHarry: false);

      expect(questions.whereType<AdjustBidQuestion>(), isNotEmpty);
      expect(questions.toSet(), hasLength(questions.length));
    });

    test('is answered without asking when it is Harry left to himself, and '
        'the table does not freeze', () async {
      final questions = await asked(autoHarry: true);

      expect(questions, isNotEmpty);
      expect(questions.whereType<AdjustBidQuestion>(), isEmpty);
    });

    test('left to himself, Harry moves the bid towards the tricks taken', () {
      expect(TableInteraction.harryChange(2, 3, [-1, 0, 1]), 1);
      expect(TableInteraction.harryChange(2, 0, [-1, 0, 1]), -1);
      expect(TableInteraction.harryChange(2, 2, [-1, 0, 1]), 0);
      expect(TableInteraction.harryChange(0, 3, [0, 1]), 1);
      expect(TableInteraction.harryChange(0, 0, [0, 1]), 0);
      expect(TableInteraction.harryChange(3, 0, [0, 1]), 0);
      // A bid of zero cannot go lower.
      expect(TableInteraction.harryChange(4, 2, [0]), 0);
    });
  });

  test('Juanita\'s stock is handed to the table to show, once', () async {
    final shown = <List<Card>>[];
    for (var seed = 0; seed < 12; seed++) {
      final game = controllerFor(seed: seed, piratePowers: true);
      final table = TableInteraction(game)..onStock = shown.add;
      game.start();
      await playUntil(game, () => game.result != null, onStep: game.stir);
      table.dispose();
      game.dispose();
    }

    expect(shown, isNotEmpty);
    expect(shown.toSet(), hasLength(shown.length));
  });
}
