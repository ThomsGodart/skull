import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:skull_kings/bots/bot.dart';
import 'package:skull_kings/engine/engine.dart';
import 'package:skull_kings/game/game_controller.dart';

GameController controllerFor({int players = 4, int seed = 5}) => GameController(
  config: GameConfig(players: players, seed: seed),
  speed: TableSpeed.instant,
  bot: randomBot(Random(seed)),
);

/// Lets the controller run until it needs the human again.
Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  test('at the start the human holds a sorted hand and is asked to bid, '
      'while the bids of the bots stay hidden', () async {
    final controller = controllerFor()..start();
    await settle();

    expect(controller.round, 1);
    expect(controller.hand, hasLength(1));
    expect(controller.bidQuestion?.maxBid, 1);
    expect(controller.playQuestion, isNull);
    expect(controller.bids, [null, null, null, null]);
  });

  test('once the human bids, every bid is shown', () async {
    final controller = controllerFor()..start();
    await settle();

    controller.bid(1);
    await settle();

    expect(controller.bidQuestion, isNull);
    expect(controller.bids, everyElement(isNotNull));
    expect(controller.bids[0], 1);
  });

  test('the hand is sorted by suit then value, special cards last', () async {
    final controller = controllerFor(seed: 12)..start();
    // Play on until the human holds a larger hand.
    await playUntil(controller, () => controller.round == 6);

    final hand = controller.hand;
    int rank(Card card) => card.isNumber
        ? card.suit!.index * 100 + card.value!
        : 1000 + card.kind.index * 10 + card.copy;
    expect(hand.map(rank), [...hand.map(rank)]..sort());
    expect(hand, hasLength(6));
  });

  test('the bots play on their own until it is the human\'s turn', () async {
    final controller = controllerFor()..start();
    await settle();
    controller.bid(0);
    await settle();

    // Either the human is asked to play, or the round ended without needing
    // them again; in round one they always hold one card to play.
    final question = controller.playQuestion!;
    expect(question.seat, 0);
    expect(controller.currentSeat, 0);
    expect(controller.hand, containsAll(question.legalCards));
  });

  test(
    'a finished round waits for the human before the next one is dealt',
    () async {
      final controller = controllerFor()..start();
      await settle();
      controller.bid(0);
      await settle();
      controller.play(
        controller.playQuestion!.legalCards.first,
        tigressAs: tigressModeFor(controller.playQuestion!.legalCards.first),
      );
      await settle();

      expect(controller.roundSummary?.round, 1);
      expect(controller.round, 1, reason: 'round two is not shown yet');
      expect(controller.bidQuestion, isNull);

      controller.continueAfterRound();
      await settle();

      expect(controller.roundSummary, isNull);
      expect(controller.round, 2);
      expect(controller.hand, hasLength(2));
      expect(controller.scoredRounds, hasLength(1));
    },
  );

  test('the last trick stays available after the table is cleared', () async {
    final controller = controllerFor()..start();
    await playUntil(controller, () => controller.round == 2);

    expect(controller.trick, isEmpty);
    expect(controller.lastTrick, hasLength(4));
    expect(controller.lastTrickWinner, isNotNull);
  });

  test('a whole game can be played to the end', () async {
    final controller = controllerFor(players: 5, seed: 31)..start();

    await playUntil(controller, () => controller.result != null);

    final result = controller.result!;
    expect(controller.scores, result.scores);
    expect(controller.scoredRounds.length, greaterThanOrEqualTo(10));
    expect(controller.bidQuestion, isNull);
    expect(controller.playQuestion, isNull);
  });

  test('notifies its listeners as the table changes', () async {
    final controller = controllerFor();
    var notified = 0;
    controller.addListener(() => notified++);

    controller.start();
    await settle();

    expect(notified, greaterThan(0));
  });
}

TigressMode? tigressModeFor(Card card) =>
    card.kind == CardKind.tigress ? TigressMode.pirate : null;

/// Plays the human seat with the first legal choice until [done].
Future<void> playUntil(GameController controller, bool Function() done) async {
  for (var step = 0; step < 5000; step++) {
    await settle();
    if (done()) return;
    if (controller.roundSummary != null) {
      controller.continueAfterRound();
    } else if (controller.bidQuestion != null) {
      controller.bid(0);
    } else if (controller.playQuestion case final question?) {
      final card = question.legalCards.first;
      controller.play(card, tigressAs: tigressModeFor(card));
    }
  }
  fail('the condition was never reached');
}
