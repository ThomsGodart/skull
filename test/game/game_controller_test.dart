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

  test('the other seats are listed the way play goes round from the human, '
      'whichever seat the human holds', () {
    GameController at(int humanSeat, {int players = 5}) => GameController(
      config: GameConfig(players: players, seed: 1),
      bot: randomBot(Random(1)),
      humanSeat: humanSeat,
    );

    expect(at(0).opponents, [1, 2, 3, 4]);
    expect(at(2).opponents, [3, 4, 0, 1]);
    expect(at(4).opponents, [0, 1, 2, 3]);
    // With two players the ghost holds the third seat.
    expect(at(0, players: 2).opponents, [1, 2]);
    expect(at(1, players: 2).opponents, [2, 0]);
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
    bool oneTrickPlayedInRoundTwo() =>
        controller.round == 2 &&
        controller.trick.isEmpty &&
        controller.tricksWon.fold(0, (sum, won) => sum + won) == 1;

    await playUntil(controller, oneTrickPlayedInRoundTwo);

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

  test('the last trick is forgotten when a new round is dealt', () async {
    final controller = controllerFor()..start();

    await playUntil(controller, () => controller.round == 2);

    expect(controller.scoredRounds, hasLength(1), reason: 'a trick was played');
    expect(controller.lastTrick, isNull);
    expect(controller.lastTrickWinner, isNull);
  });

  test(
    'nobody is shown as playing while the bids are being revealed',
    () async {
      final controller = GameController(
        config: const GameConfig(players: 4, seed: 5),
        bot: randomBot(Random(5)),
        speed: const TableSpeed(
          botPlay: Duration.zero,
          trickHold: Duration.zero,
          bidReveal: Duration(milliseconds: 40),
        ),
      )..start();
      await settle();

      controller.bid(0);
      await settle();

      expect(controller.bids, everyElement(isNotNull));
      expect(controller.currentSeat, isNull);

      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(controller.currentSeat, isNotNull);
      controller.dispose();
    },
  );

  test('an answer nobody asked for is ignored', () async {
    final controller = controllerFor()..start();
    await settle();
    final card = controller.hand.single;

    controller.play(card);
    controller.bid(0);
    controller.bid(1);
    await settle();

    expect(controller.bids[0], 0, reason: 'the second bid changed nothing');
  });

  test('a bot that fails does not freeze the table silently', () async {
    final controller = GameController(
      config: const GameConfig(players: 4, seed: 5),
      bot: (question, view) => throw StateError('broken bot'),
      speed: TableSpeed.instant,
    );
    Object? error;
    controller.onError = (e) => error = e;

    controller.start();
    await settle();

    expect(error, isStateError);
  });

  group('saving and resuming', () {
    GameController resumable(
      List<GameProgress> log, {
      List<Answer> saved = const [],
    }) => GameController(
      config: const GameConfig(players: 4, seed: 5),
      bot: randomBot(Random(5)),
      speed: TableSpeed.instant,
      savedAnswers: saved,
      onProgress: log.add,
    );

    test('every answer is reported, bots included, with where the game '
        'stands', () async {
      final log = <GameProgress>[];
      final controller = resumable(log)..start();
      await playUntil(controller, () => controller.round == 3);

      expect(log.last.round, 3);
      expect(log.last.humanScore, controller.scores[0]);
      expect(log.last.result, isNull);
      final sizes = log.map((progress) => progress.answers.length).toList();
      expect(sizes, [...sizes]..sort(), reason: 'answers only ever grow');
      // Rounds one and two: 4 bids each, then 4 and 8 cards.
      expect(log.last.answers.length, greaterThanOrEqualTo(4 + 4 + 4 + 8));
    });

    test('a game resumed from its saved answers shows the table as it was, '
        'without replaying past rounds on screen', () async {
      final log = <GameProgress>[];
      final original = resumable(log)..start();
      await playUntil(
        original,
        () => original.round == 4 && original.playQuestion != null,
      );

      final resumed = resumable([], saved: log.last.answers)..start();
      await settle();

      expect(resumed.round, 4);
      expect(resumed.roundSummary, isNull);
      expect(resumed.hand, original.hand);
      expect(resumed.bids, original.bids);
      expect(resumed.tricksWon, original.tricksWon);
      expect(resumed.scores, original.scores);
      expect(
        resumed.trick.map((p) => p.card),
        original.trick.map((p) => p.card),
      );
      expect(resumed.scoredRounds, hasLength(3));
      expect(
        resumed.playQuestion!.legalCards,
        original.playQuestion!.legalCards,
      );
    });

    test('a resumed game plays on to the end', () async {
      final log = <GameProgress>[];
      final original = resumable(log)..start();
      await playUntil(original, () => original.round == 5);

      final resumed = resumable([], saved: log.last.answers)..start();
      await playUntil(resumed, () => resumed.result != null);

      expect(resumed.scoredRounds.length, greaterThanOrEqualTo(10));
    });

    test('a game saved after its last answer but never marked as over '
        'is reported as over when it is opened again', () async {
      final log = <GameProgress>[];
      final original = resumable(log)..start();
      await playUntil(original, () => original.result != null);

      final reopened = <GameProgress>[];
      final resumed = resumable(reopened, saved: log.last.answers)..start();
      await settle();

      expect(resumed.result, isNotNull);
      expect(reopened.single.result?.scores, original.result!.scores);
    });

    test('the end of the game is reported with its result', () async {
      final log = <GameProgress>[];
      final controller = resumable(log)..start();

      await playUntil(controller, () => controller.result != null);

      expect(log.last.result?.scores, controller.result!.scores);
      expect(log.where((progress) => progress.result != null), hasLength(1));
    });
  });

  group('with the expansion and the pirate powers', () {
    GameController full(int seed) => GameController(
      config: GameConfig(
        players: 4,
        seed: seed,
        kraken: true,
        whiteWhale: true,
        loot: true,
        piratePowers: true,
      ),
      bot: randomBot(Random(seed)),
      speed: TableSpeed.instant,
    );

    test(
      'a whole game can be played, the human answering every power',
      () async {
        final asked = <Type>{};
        var stocksShown = 0;
        for (var seed = 0; seed < 12; seed++) {
          final controller = full(seed)..start();
          await playUntil(
            controller,
            () => controller.result != null,
            onStep: () {
              if (controller.afterTrickQuestion case final question?) {
                asked.add(question.runtimeType);
              }
              if (controller.revealedStock != null) stocksShown++;
            },
          );
          controller.dispose();
        }
        expect(asked, hasLength(4), reason: 'every kind of power was asked');
        expect(stocksShown, greaterThan(0));
      },
    );

    test('a resumed game does not show again the cards Juanita revealed '
        'earlier', () async {
      for (var seed = 0; seed < 40; seed++) {
        GameProgress? last;
        final original = GameController(
          config: GameConfig(players: 4, seed: seed, piratePowers: true),
          bot: randomBot(Random(seed)),
          speed: TableSpeed.instant,
          onProgress: (progress) => last = progress,
        )..start();
        var revealed = false;
        await playUntil(
          original,
          // Stop at a bid some time after the stock was shown and closed.
          () =>
              original.result != null ||
              (revealed &&
                  original.revealedStock == null &&
                  original.bidQuestion != null),
          onStep: () => revealed |= original.revealedStock != null,
        );
        original.dispose();
        if (original.result != null) continue;

        final resumed = GameController(
          config: GameConfig(players: 4, seed: seed, piratePowers: true),
          bot: randomBot(Random(seed)),
          speed: TableSpeed.instant,
          savedAnswers: last!.answers,
        );
        var shownAgain = false;
        resumed.addListener(() => shownAgain |= resumed.revealedStock != null);
        resumed.start();
        await settle();

        expect(shownAgain, isFalse);
        expect(resumed.bidQuestion, isNotNull);
        resumed.dispose();
        return;
      }
      fail('Juanita never won the human a trick in forty games');
    });

    test('a destroyed trick is shown as such and counts for nobody', () async {
      for (var seed = 0; seed < 40; seed++) {
        final controller = GameController(
          config: GameConfig(players: 4, seed: seed, kraken: true),
          bot: randomBot(Random(seed)),
          speed: const TableSpeed(
            botPlay: Duration.zero,
            trickHold: Duration(days: 1),
            bidReveal: Duration.zero,
          ),
        )..start();
        var found = false;
        await playUntil(
          controller,
          () => found || controller.result != null,
          onStep: () {
            if (controller.trickDestroyed) {
              final cards = controller.cardsDealt;
              final left = controller.handSizes.first;
              final won = controller.tricksWon.fold(0, (a, b) => a + b);
              expect(won, lessThan(cards - left), reason: 'one trick is lost');
              found = true;
            }
          },
        );
        controller.dispose();
        if (found) return;
      }
      fail('no trick was destroyed in forty games');
    });
  });

  test('in a two-player game the table still shows whose turn it is', () async {
    final controller = GameController(
      config: const GameConfig(players: 2, seed: 3),
      bot: randomBot(Random(3)),
      speed: TableSpeed.instant,
    )..start();
    var shown = 0;
    await playUntil(
      controller,
      () => controller.round == 3,
      onStep: () {
        if (controller.playQuestion != null) {
          expect(controller.currentSeat, 0);
          shown++;
        }
      },
    );

    expect(shown, greaterThan(0));
    expect(controller.bids, hasLength(3));
    expect(controller.bids.last, isNull, reason: 'the ghost bids nothing');
    controller.dispose();
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
Future<void> playUntil(
  GameController controller,
  bool Function() done, {
  void Function()? onStep,
}) async {
  for (var step = 0; step < 8000; step++) {
    await settle();
    onStep?.call();
    if (done()) return;
    if (controller.roundSummary != null) {
      controller.continueAfterRound();
    } else if (controller.revealedStock != null) {
      controller.dismissStock();
    } else if (controller.afterTrickQuestion case final question?) {
      controller.answerAfterTrick(randomAnswer(question, Random(step)));
    } else if (controller.bidQuestion != null) {
      controller.bid(0);
    } else if (controller.playQuestion case final question?) {
      final card = question.legalCards.first;
      controller.play(card, tigressAs: tigressModeFor(card));
    } else if (controller.trickWinner != null) {
      controller.skipHold();
    }
  }
  fail('the condition was never reached');
}
