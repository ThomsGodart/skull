import 'dart:math';

import 'package:flutter/material.dart' hide Card;
import 'package:flutter_test/flutter_test.dart';
import 'package:skull_kings/engine/engine.dart';
import 'package:skull_kings/game/game_controller.dart';
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
