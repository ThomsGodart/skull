import 'dart:math';

import 'package:flutter/material.dart' hide Card;
import 'package:flutter_test/flutter_test.dart';
import 'package:skull_kings/app.dart';
import 'package:skull_kings/bots/bot.dart';
import 'package:skull_kings/engine/engine.dart';
import 'package:skull_kings/game/game_controller.dart';
import 'package:skull_kings/settings/app_settings.dart';
import 'package:skull_kings/storage/game_store.dart';
import 'package:skull_kings/ui/strings.dart';

import 'support/memory_stores.dart';

/// A four-player game left during round [round], as it would be saved.
Future<SavedGame> gameLeftInRound(int round) async {
  const config = GameConfig(players: 4, seed: 21);
  GameProgress? last;
  final controller = GameController(
    config: config,
    bot: randomBot(Random(1)),
    speed: TableSpeed.instant,
    onProgress: (progress) => last = progress,
  )..start();
  for (var step = 0; step < 2000; step++) {
    await Future<void>.delayed(Duration.zero);
    if (controller.round == round && controller.playQuestion != null) break;
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
  controller.dispose();
  return SavedGame(
    id: 1,
    config: config,
    answers: last!.answers,
    round: last!.round,
    humanScore: last!.humanScore,
  );
}

void main() {
  late MemoryGameStore games;
  late MemorySettingsStore settingsStore;

  setUp(() {
    games = MemoryGameStore();
    settingsStore = MemorySettingsStore();
  });

  Future<void> openApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final settings = await AppSettings.load(settingsStore);
    await tester.pumpWidget(SkullKingsApp(games: games, settings: settings));
    await tester.pumpAndSettle();
  }

  testWidgets('with no game in progress, the home only offers a new game', (
    tester,
  ) async {
    await openApp(tester);

    expect(find.text(Strings.newGame), findsOneWidget);
    expect(find.text(Strings.continueGame), findsNothing);
  });

  testWidgets('a new game is set up with the chosen number of opponents, '
      'kept, and remembered for next time', (tester) async {
    await openApp(tester);
    await tester.tap(find.text(Strings.newGame));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add_circle_outline));
    await tester.pump();
    await tester.tap(find.byKey(const Key('launch')));
    await tester.pumpAndSettle();

    expect(find.text(Strings.roundTitle(1, 1)), findsOneWidget);
    expect(games.active!.config.players, 5);
    expect(settingsStore.values['opponents'], '4');
  });

  testWidgets('a game in progress is offered on the home, with where it '
      'stands, and resumes at the same round', (tester) async {
    final saved = await tester.runAsync(() => gameLeftInRound(4));
    games.active = saved;
    await openApp(tester);

    expect(find.text(Strings.continueGame), findsOneWidget);
    expect(
      find.text(Strings.savedGameSummary(4, saved!.humanScore)),
      findsOneWidget,
    );

    await tester.tap(find.text(Strings.continueGame));
    await tester.pumpAndSettle();

    expect(find.text(Strings.roundTitle(4, 4)), findsOneWidget);
  });

  testWidgets('starting a new game over one in progress asks first, '
      'and keeping the old one is possible', (tester) async {
    games.active = await tester.runAsync(() => gameLeftInRound(3));
    await openApp(tester);
    await tester.tap(find.text(Strings.newGame));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('launch')));
    await tester.pumpAndSettle();

    expect(find.text(Strings.replaceGameTitle), findsOneWidget);
    await tester.tap(find.text(Strings.keepGame));
    await tester.pumpAndSettle();

    expect(games.active!.round, 3);
    expect(find.byKey(const Key('launch')), findsOneWidget);

    await tester.tap(find.byKey(const Key('launch')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(Strings.replaceGame));
    await tester.pumpAndSettle();

    expect(games.active!.round, 1);
    expect(find.text(Strings.roundTitle(1, 1)), findsOneWidget);
  });

  testWidgets('leaving the table keeps the game: the home offers to '
      'continue it', (tester) async {
    await openApp(tester);
    await tester.tap(find.text(Strings.newGame));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('launch')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('bid-1')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('place-bid')));
    await tester.pump();

    await tester.tap(find.byTooltip(Strings.pause));
    await tester.pumpAndSettle();
    expect(find.text(Strings.gameIsSaved), findsOneWidget);
    await tester.tap(find.text(Strings.quit));
    await tester.pumpAndSettle();

    expect(find.text(Strings.continueGame), findsOneWidget);
    expect(games.active!.answers, isNotEmpty);
  });

  testWidgets('the player can choose their name, which is shown at their '
      'seat and kept', (tester) async {
    await openApp(tester);

    await tester.tap(find.byKey(const Key('edit-profile')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Anne');
    await tester.tap(find.text(Strings.save));
    await tester.pumpAndSettle();

    expect(settingsStore.values['playerName'], 'Anne');
    await tester.tap(find.text(Strings.newGame));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('launch')));
    await tester.pumpAndSettle();
    expect(find.text('Anne'), findsOneWidget);
  });
}
