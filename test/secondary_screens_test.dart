import 'dart:math';

import 'package:flutter/material.dart' hide Card;
import 'package:flutter_test/flutter_test.dart';
import 'package:skull_kings/app.dart';
import 'package:skull_kings/bots/bot.dart';
import 'package:skull_kings/engine/engine.dart';
import 'package:skull_kings/game/game_controller.dart';
import 'package:skull_kings/game/game_saver.dart';
import 'package:skull_kings/game/score_views.dart';
import 'package:skull_kings/settings/app_settings.dart';
import 'package:skull_kings/ui/strings.dart';

import 'support/memory_stores.dart';

/// Plays a whole four-player game into [games], as the app would keep it.
Future<void> playWholeGame(MemoryGameStore games, {int seed = 4}) async {
  final config = GameConfig(players: 4, seed: seed);
  final saver = GameSaver(
    games,
    await games.create(config),
    playerName: 'Anne',
  );
  final controller = GameController(
    config: config,
    bot: randomBot(Random(seed)),
    speed: TableSpeed.instant,
    onProgress: saver.record,
  )..start();
  while (controller.result == null) {
    await Future<void>.delayed(Duration.zero);
    if (controller.roundSummary != null) {
      controller.continueAfterRound();
    } else if (controller.bidQuestion != null) {
      controller.bid(0);
    } else if (controller.playQuestion case final question?) {
      final card = question.legalCards.first;
      controller.play(
        card,
        tigressAs: card.kind == CardKind.tigress ? TigressMode.escape : null,
      );
    }
  }
  await saver.done;
  controller.dispose();
}

void main() {
  late MemoryGameStore games;
  late MemorySettingsStore settingsStore;
  late AppSettings settings;

  setUp(() {
    games = MemoryGameStore();
    settingsStore = MemorySettingsStore();
  });

  Future<void> openApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    settings = await AppSettings.load(settingsStore);
    await tester.pumpWidget(
      SkullKingsApp(
        games: games,
        counters: MemoryCounterStore(),
        settings: settings,
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> open(WidgetTester tester, String entry) async {
    await tester.ensureVisible(find.text(entry));
    await tester.tap(find.text(entry));
    await tester.pumpAndSettle();
  }

  group('history', () {
    testWidgets('says so when no game has been finished yet', (tester) async {
      await openApp(tester);
      await open(tester, Strings.history);

      expect(find.text(Strings.historyEmpty), findsOneWidget);
    });

    testWidgets('lists a finished game with the human\'s rank and score, '
        'and opens its score sheet', (tester) async {
      await tester.runAsync(() => playWholeGame(games));
      final game = games.finished.single;
      await openApp(tester);
      await open(tester, Strings.history);

      expect(
        find.text(Strings.historyResult(game.humanRank, game.humanScore)),
        findsOneWidget,
      );
      expect(find.text(Strings.playersCount(4)), findsOneWidget);

      await tester.tap(
        find.text(Strings.historyResult(game.humanRank, game.humanScore)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ScoreSheet), findsOneWidget);
      expect(find.byType(Standings), findsOneWidget);
      expect(find.text('Anne'), findsWidgets);
    });

    testWidgets('a long press forgets a game, after confirmation', (
      tester,
    ) async {
      await tester.runAsync(() => playWholeGame(games));
      final game = games.finished.single;
      await openApp(tester);
      await open(tester, Strings.history);
      final line = find.text(
        Strings.historyResult(game.humanRank, game.humanScore),
      );

      await tester.longPress(line);
      await tester.pumpAndSettle();
      await tester.tap(find.text(Strings.cancel));
      await tester.pumpAndSettle();
      expect(games.finished, hasLength(1));

      await tester.longPress(line);
      await tester.pumpAndSettle();
      await tester.tap(find.text(Strings.delete));
      await tester.pumpAndSettle();

      expect(games.finished, isEmpty);
      expect(find.text(Strings.historyEmpty), findsOneWidget);
    });
  });

  testWidgets('when the games cannot be loaded, history and statistics '
      'say so instead of staying blank', (tester) async {
    games.failLoading = true;
    await openApp(tester);

    await open(tester, Strings.history);
    expect(find.text(Strings.loadFailed), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await open(tester, Strings.statistics);
    expect(find.text(Strings.loadFailed), findsOneWidget);
  });

  group('statistics', () {
    testWidgets('show a dash, not a zero, when nothing has been played', (
      tester,
    ) async {
      await openApp(tester);
      await open(tester, Strings.statistics);

      expect(find.text(Strings.statGamesPlayed), findsOneWidget);
      // No game played, none won.
      expect(find.text('0'), findsNWidgets(2));
      expect(find.text(Strings.unavailable), findsNWidgets(6));
      expect(find.textContaining('%'), findsNothing);
    });

    testWidgets('show the figures of the games played', (tester) async {
      await tester.runAsync(() async {
        await playWholeGame(games, seed: 4);
        await playWholeGame(games, seed: 9);
      });
      await openApp(tester);
      await open(tester, Strings.statistics);

      expect(find.text('2'), findsWidgets);
      final best = games.finished
          .map((game) => game.humanScore)
          .reduce((a, b) => a > b ? a : b);
      expect(find.text('$best'), findsWidgets);
      expect(find.textContaining('%'), findsWidgets);
    });
  });

  group('settings', () {
    testWidgets('changing an option keeps it', (tester) async {
      await openApp(tester);
      await open(tester, Strings.settings);

      await tester.tap(find.text(Strings.speedFast));
      await tester.pumpAndSettle();
      await tester.tap(find.text(Strings.singleTapPlay));
      await tester.pumpAndSettle();

      expect(settingsStore.values['botSpeed'], 'fast');
      expect(settingsStore.values['singleTapPlay'], 'true');
    });

    testWidgets('with single-tap play on, one tap plays a card', (
      tester,
    ) async {
      settingsStore.values['singleTapPlay'] = 'true';
      settingsStore.values['botSpeed'] = 'instant';
      await openApp(tester);
      await tester.tap(find.text(Strings.newGame));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('launch')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('bid-0')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('place-bid')));
      // Let the bids be revealed and the bots before the human play.
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();

      final hand = find.byWidgetPredicate(
        (widget) => widget.key.toString().contains('hand-'),
      );
      expect(hand, findsOneWidget);
      await tester.tap(hand);
      await tester.pump(const Duration(milliseconds: 50));
      if (find.byKey(const Key('tigress-escape')).evaluate().isNotEmpty) {
        await tester.tap(find.byKey(const Key('tigress-escape')));
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(hand, findsNothing, reason: 'the card left the hand');
      await tester.pumpAndSettle(const Duration(seconds: 3));
    });
  });

  testWidgets('the rules can be read from the home', (tester) async {
    await openApp(tester);
    await open(tester, Strings.rules);

    expect(find.text(Strings.rulesTitle), findsOneWidget);
    expect(find.textContaining('parie le nombre exact'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Les bonus'), 300);

    expect(find.textContaining('Skull King capturé'), findsOneWidget);
  });
}
