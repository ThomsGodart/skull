import 'dart:math';

import 'package:flutter/material.dart' hide Card;
import 'package:flutter_test/flutter_test.dart';
import 'package:skull_kings/bots/bot.dart';
import 'package:skull_kings/engine/engine.dart';
import 'package:skull_kings/game/game_controller.dart';
import 'package:skull_kings/game/score_views.dart';
import 'package:skull_kings/game/screen_awake.dart';
import 'package:skull_kings/game/seat_identity.dart';
import 'package:skull_kings/game/table_screen.dart';
import 'package:skull_kings/theme/tokens.dart';
import 'package:skull_kings/ui/strings.dart';

void main() {
  Future<GameController> openTable(
    WidgetTester tester, {
    int players = 4,
    int seed = 3,
  }) async {
    // A small phone, portrait.
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller = GameController(
      config: GameConfig(players: players, seed: seed),
      bot: randomBot(Random(seed)),
      speed: TableSpeed.instant,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: Tokens.theme(),
        home: TableScreen(controller: controller, onPlayAgain: () {}),
      ),
    );
    await tester.pump();
    return controller;
  }

  /// Taps the visible left edge of a card of the hand, which stays reachable
  /// even when the next card overlaps it.
  Future<void> tapCard(WidgetTester tester, Card card) async {
    final corner = tester.getTopLeft(find.byKey(Key('hand-${card.id}')));
    await tester.tapAt(corner + const Offset(6, 30));
    await tester.pump(const Duration(milliseconds: 200));
  }

  testWidgets('the table opens on round one and asks for a bid', (
    tester,
  ) async {
    await openTable(tester);

    expect(find.text(Strings.roundTitle(1, 1)), findsOneWidget);
    expect(find.text(Strings.chooseBid), findsOneWidget);
    expect(find.byKey(const Key('bid-0')), findsOneWidget);
    expect(find.byKey(const Key('bid-1')), findsOneWidget);
    expect(find.byKey(const Key('bid-2')), findsNothing);
  });

  testWidgets('a card is played with two taps: one lifts it, one plays it', (
    tester,
  ) async {
    final controller = await openTable(tester);
    await tester.tap(find.byKey(const Key('bid-0')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('place-bid')));
    await tester.pump();
    final card = controller.playQuestion!.legalCards.first;

    await tapCard(tester, card);

    expect(controller.playQuestion, isNotNull, reason: 'only lifted so far');
    expect(find.text(Strings.tapAgain), findsOneWidget);
  });

  testWidgets('the score sheet stays within reach while a round summary '
      'is shown', (tester) async {
    final controller = await openTable(tester);
    await tester.tap(find.byKey(const Key('bid-0')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('place-bid')));
    await tester.pump();
    final card = controller.playQuestion!.legalCards.first;
    await tapCard(tester, card);
    await tapCard(tester, card);
    if (card.kind == CardKind.tigress) {
      await tester.tap(find.byKey(const Key('tigress-escape')));
    }
    await tester.pump();
    expect(find.text(Strings.roundOver(1)), findsOneWidget);

    await tester.tap(find.byTooltip(Strings.scoreSheet));
    await tester.pumpAndSettle();

    expect(find.byType(ScoreSheet), findsOneWidget);
  });

  testWidgets('the screen stays on when a new table replaces the old one', (
    tester,
  ) async {
    final awake = _RecordingScreenAwake();
    GameController controller() => GameController(
      config: const GameConfig(players: 4, seed: 3),
      bot: randomBot(Random(3)),
      speed: TableSpeed.instant,
    );
    final navigator = GlobalKey<NavigatorState>();
    Widget table() => TableScreen(
      controller: controller(),
      onPlayAgain: () {},
      screenAwake: awake,
    );
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        theme: Tokens.theme(),
        home: table(),
      ),
    );
    await tester.pump();

    navigator.currentState!.pushReplacement(
      MaterialPageRoute<void>(builder: (_) => table()),
    );
    await tester.pumpAndSettle();

    expect(awake.on, isTrue, reason: 'calls were ${awake.calls}');

    await tester.pumpWidget(const SizedBox());
    expect(awake.on, isFalse);
  });

  testWidgets('players level on points share a place in the standings', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Standings(
            scores: const [40, 90, 40, 10],
            seats: SeatIdentity.table(
              4,
              human: const SeatIdentity('Anne', Tokens.gold),
            ),
          ),
        ),
      ),
    );

    expect(find.text('2.'), findsNWidgets(2));
    expect(find.text('3.'), findsNothing);
    expect(find.text('4.'), findsOneWidget);
  });

  testWidgets('a whole game with the expansion and the pirate powers runs '
      'to the end, every power answered in its dialog', (tester) async {
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final dialogs = <String>{};
    for (var seed = 0; seed < 6; seed++) {
      final controller = GameController(
        config: GameConfig(
          players: 5,
          seed: seed,
          kraken: true,
          whiteWhale: true,
          loot: true,
          piratePowers: true,
          scoring: Scoring.rascal,
        ),
        bot: randomBot(Random(seed)),
        speed: TableSpeed.instant,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: Tokens.theme(),
          home: TableScreen(
            key: ValueKey(seed),
            controller: controller,
            onPlayAgain: () {},
          ),
        ),
      );
      Future<bool> tapIfShown(String key) async {
        final finder = find.byKey(Key(key));
        if (finder.evaluate().isEmpty) return false;
        await tester.tap(finder);
        await tester.pumpAndSettle();
        dialogs.add(key.split('-').take(2).join('-'));
        return true;
      }

      for (var step = 0; step < 3000; step++) {
        await tester.pumpAndSettle();
        if (controller.result != null && controller.roundSummary == null) break;
        if (await tapIfShown('stock-close')) continue;
        if (await tapIfShown('power-leader-0')) continue;
        if (await tapIfShown('power-wager-10')) continue;
        if (await tapIfShown('power-change-0')) continue;
        if (controller.powerQuestion case DiscardQuestion(
          :final hand,
          :final count,
        )) {
          for (final card in hand.take(count)) {
            await tester.tap(find.byKey(Key('power-discard-${card.id}')));
            await tester.pump();
          }
          await tapIfShown('power-confirm');
          continue;
        }
        if (controller.roundSummary != null) {
          await tester.tap(find.byKey(const Key('continue')));
        } else if (controller.bidQuestion != null) {
          await tester.tap(find.byKey(const Key('bid-0')));
          await tester.pump();
          await tester.tap(find.byKey(const Key('place-bid')));
        } else if (controller.playQuestion case final question?) {
          final card = question.legalCards.first;
          await tapCard(tester, card);
          await tapCard(tester, card);
          if (card.kind == CardKind.tigress) {
            await tester.tap(find.byKey(const Key('tigress-escape')));
          }
        }
      }
      expect(controller.result, isNotNull, reason: 'seed $seed');
    }
    expect(
      dialogs,
      containsAll([
        'power-leader',
        'power-wager',
        'power-change',
        'power-confirm',
      ]),
    );
  });

  testWidgets('with two players the ghost sits at the table, and only the '
      'two players are on the score sheet', (tester) async {
    final controller = await openTable(tester, players: 2, seed: 4);

    expect(find.text(Strings.ghostName), findsOneWidget);
    expect(find.textContaining(Strings.ghostLabel), findsOneWidget);

    for (var step = 0; step < 4000; step++) {
      await tester.pump();
      if (controller.result != null && controller.roundSummary == null) break;
      if (controller.roundSummary != null) {
        expect(controller.roundSummary!.results, hasLength(2));
        await tester.tap(find.byKey(const Key('continue')));
      } else if (controller.bidQuestion != null) {
        await tester.tap(find.byKey(const Key('bid-0')));
        await tester.pump();
        await tester.tap(find.byKey(const Key('place-bid')));
      } else if (controller.playQuestion case final question?) {
        final card = question.legalCards.first;
        await tapCard(tester, card);
        await tapCard(tester, card);
        if (card.kind == CardKind.tigress) {
          await tester.tap(find.byKey(const Key('tigress-escape')));
        }
      }
    }
    await tester.pump();

    expect(controller.result!.scores, hasLength(2));
    expect(find.text(Strings.gameOver), findsOneWidget);
    // The ghost is not in the final standings.
    expect(
      find.descendant(
        of: find.byType(Standings),
        matching: find.text(Strings.ghostName),
      ),
      findsNothing,
    );
  });

  testWidgets('before the first trick, the seat that will lead is marked, '
      'and the table says who it is', (tester) async {
    final controller = await openTable(tester);

    expect(find.text(Strings.leadMark), findsOneWidget);
    final leader = controller.leader;
    final expected = leader == 0
        ? Strings.youLeadRound
        : Strings.leadsRound(Strings.botNames[leader - 1]);
    expect(find.textContaining(expected), findsOneWidget);
  });

  testWidgets('the round summary gives tricks before bid, under a Bonus '
      'heading when there is one', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: Tokens.theme(),
        home: Scaffold(
          body: RoundSummaryTable(
            round: RoundScored(
              round: 3,
              results: [
                SeatResult(
                  bid: 2,
                  tricksWon: 1,
                  bonuses: const [Bonus.standardFourteen],
                  score: scoreRound(bid: 2, tricksWon: 1, cardsDealt: 3),
                  totalScore: -10,
                ),
                SeatResult(
                  bid: 0,
                  tricksWon: 0,
                  bonuses: const [],
                  score: scoreRound(bid: 0, tricksWon: 0, cardsDealt: 3),
                  totalScore: 30,
                ),
              ],
            ),
            seats: SeatIdentity.table(
              2,
              human: const SeatIdentity('Anne', Tokens.gold),
            ),
          ),
        ),
      ),
    );

    expect(find.text(Strings.colTricksBid), findsOneWidget);
    expect(find.text('1/2'), findsOneWidget);
    expect(find.text('0/0'), findsOneWidget);
    // The column of the table, and the heading above the details.
    expect(find.text(Strings.bonusHeading), findsNWidgets(2));
  });

  for (final players in [3, 8]) {
    testWidgets('a whole game with $players players runs to the final '
        'standings without a layout error', (tester) async {
      final controller = await openTable(tester, players: players, seed: 11);

      for (var step = 0; step < 4000; step++) {
        await tester.pump();
        if (controller.result != null && controller.roundSummary == null) break;
        if (controller.roundSummary != null) {
          await tester.tap(find.byKey(const Key('continue')));
        } else if (controller.bidQuestion != null) {
          await tester.tap(find.byKey(const Key('bid-0')));
          await tester.pump();
          await tester.tap(find.byKey(const Key('place-bid')));
        } else if (controller.playQuestion case final question?) {
          final card = question.legalCards.first;
          await tapCard(tester, card);
          await tapCard(tester, card);
          if (card.kind == CardKind.tigress) {
            await tester.tap(find.byKey(const Key('tigress-escape')));
          }
        }
      }
      await tester.pump();

      expect(controller.result, isNotNull);
      expect(find.text(Strings.gameOver), findsOneWidget);
      expect(find.text(Strings.playAgain), findsOneWidget);
    });
  }
}

class _RecordingScreenAwake implements ScreenAwake {
  final List<String> calls = [];
  bool on = false;

  @override
  Future<void> keepOn() async {
    calls.add('on');
    on = true;
  }

  @override
  Future<void> release() async {
    calls.add('off');
    on = false;
  }
}
