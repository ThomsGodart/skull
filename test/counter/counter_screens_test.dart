import 'package:flutter/material.dart' hide Card;
import 'package:flutter_test/flutter_test.dart';
import 'package:skull_kings/counter/counter_game.dart';
import 'package:skull_kings/counter/counter_home_screen.dart';
import 'package:skull_kings/engine/engine.dart';
import 'package:skull_kings/game/score_views.dart';
import 'package:skull_kings/settings/app_settings.dart';
import 'package:skull_kings/counter/counter_store.dart';
import 'package:skull_kings/theme/tokens.dart';
import 'package:skull_kings/ui/strings.dart';

import '../support/memory_stores.dart';

void main() {
  late MemoryCounterStore store;
  late MemorySettingsStore settingsStore;

  setUp(() {
    store = MemoryCounterStore();
    settingsStore = MemorySettingsStore();
  });

  Future<void> openCounter(WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final settings = await AppSettings.load(settingsStore);
    await tester.pumpWidget(
      MaterialApp(
        theme: Tokens.theme(),
        home: CounterHomeScreen(store: store, settings: settings),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, String key, {int times = 1}) async {
    final finder = find.byKey(Key(key));
    await tester.ensureVisible(finder);
    // The scroll only takes effect on the next frame.
    await tester.pumpAndSettle();
    for (var i = 0; i < times; i++) {
      await tester.tap(finder);
      await tester.pump();
    }
  }

  Future<void> startGame(WidgetTester tester, List<String> names) async {
    await tap(tester, 'counter-new');
    await tester.pumpAndSettle();
    for (final (index, name) in names.indexed) {
      await tester.enterText(find.byKey(Key('counter-name-$index')), name);
    }
    await tester.pump();
    await tap(tester, 'counter-start');
    await tester.pumpAndSettle();
  }

  testWidgets('a game is set up with its players, who are remembered', (
    tester,
  ) async {
    await openCounter(tester);

    await startGame(tester, ['Anne', 'Bob', 'Chloé']);

    expect(store.active!.game.players, ['Anne', 'Bob', 'Chloé']);
    expect(find.text(Strings.counterRoundTitle(1, 1)), findsOneWidget);
    expect(find.text(Strings.counterLeads('Anne')), findsOneWidget);
    final settings = await AppSettings.load(settingsStore);
    expect(settings.knownPlayers, ['Anne', 'Bob', 'Chloé']);
  });

  testWidgets('a player without a name stops the setup', (tester) async {
    await openCounter(tester);
    await tap(tester, 'counter-new');
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('counter-name-0')), 'Anne');

    await tap(tester, 'counter-start');
    await tester.pump();

    expect(find.text(Strings.counterNeedNames), findsOneWidget);
    expect(store.active, isNull);
  });

  testWidgets('a round is entered in two steps, bids then results, and '
      'scored as soon as it is saved', (tester) async {
    await openCounter(tester);
    await startGame(tester, ['Anne', 'Bob', 'Chloé']);

    await tap(tester, 'counter-enter');
    await tester.pumpAndSettle();
    expect(find.text(Strings.counterBidsPhase), findsOneWidget);
    await tap(tester, 'bid-2-plus');
    await tap(tester, 'counter-bids-done');
    await tester.pumpAndSettle();

    expect(store.active!.game.draftBids, [0, 0, 1]);
    expect(find.text(Strings.counterResultsPhase), findsOneWidget);
    // Nobody took the only trick yet: a warning says so.
    expect(find.text(Strings.counterTricksMismatch(0, 1)), findsOneWidget);

    await tap(tester, 'tricks-2-plus');
    expect(find.text(Strings.counterTricksMismatch(0, 1)), findsNothing);
    // The only trick is taken: nobody else can be given one.
    await tap(tester, 'tricks-0-plus');
    expect(find.text(Strings.counterTricksMismatch(2, 1)), findsNothing);
    await tap(tester, 'counter-bonus-2');
    await tester.pumpAndSettle();
    await tap(tester, 'bonus-standardFourteen-plus');
    await tap(tester, 'counter-bonus-close');
    await tester.pumpAndSettle();
    await tap(tester, 'counter-round-done');
    await tester.pumpAndSettle();

    final game = store.active!.game;
    expect(game.totals, [10, 10, 30]);
    expect(game.draftBids, isNull);
    expect(find.text(Strings.counterRoundTitle(2, 2)), findsOneWidget);
    expect(find.byType(ScoreSheet), findsOneWidget);
  });

  testWidgets('a past round can be corrected from the score sheet', (
    tester,
  ) async {
    final game = CounterGame(players: ['Anne', 'Bob'])
      ..saveRound(
        1,
        const CounterRound(
          entries: [
            CounterEntry(bid: 1, tricksWon: 1),
            CounterEntry(bid: 0, tricksWon: 0),
          ],
        ),
      );
    store.active = SavedCounterGame(id: 1, game: game);
    await openCounter(tester);
    await tap(tester, 'counter-resume');
    await tester.pumpAndSettle();
    expect(store.active!.game.totals, [20, 10]);

    await tap(tester, 'sheet-round-1');
    await tester.pumpAndSettle();
    // Anne took no trick after all.
    await tap(tester, 'tricks-0-minus');
    await tap(tester, 'counter-round-done');
    await tester.pumpAndSettle();

    expect(store.active!.game.totals, [-10, 10]);
    expect(store.active!.game.nextRound, 2);
  });

  testWidgets('with loot and pirate powers, alliances and wagers can be '
      'entered', (tester) async {
    final game = CounterGame(
      players: ['Anne', 'Bob', 'Chloé'],
      loot: true,
      piratePowers: true,
    );
    store.active = SavedCounterGame(id: 1, game: game);
    await openCounter(tester);
    await tap(tester, 'counter-resume');
    await tester.pumpAndSettle();
    await tap(tester, 'counter-enter');
    await tester.pumpAndSettle();
    await tap(tester, 'bid-0-plus');
    await tap(tester, 'counter-bids-done');
    await tester.pumpAndSettle();
    await tap(tester, 'tricks-0-plus');

    await tester.dragUntilVisible(
      find.byKey(const Key('counter-add-alliance')),
      find.byType(ListView),
      const Offset(0, -200),
    );
    await tap(tester, 'counter-add-alliance');
    await tester.pumpAndSettle();
    await tap(tester, 'counter-alliance-ok');
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(
      find.byKey(const Key('counter-bonus-0')),
      find.byType(ListView),
      const Offset(0, 200),
    );
    await tap(tester, 'counter-bonus-0');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('20'));
    await tester.tap(find.text('20'));
    await tester.pump();
    await tap(tester, 'counter-bonus-close');
    await tester.pumpAndSettle();
    await tap(tester, 'counter-round-done');
    await tester.pumpAndSettle();

    final entered = store.active!.game.round(1)!;
    expect(entered.alliances, [(0, 1)]);
    expect(entered.entries[0].wager, 20);
    // Harry's change is made on the bid itself.
    expect(find.text('Harry le Géant'), findsNothing);
    // Anne made her bid of one, Bob his zero: 20 + alliance 20 + wager 20.
    expect(store.active!.game.totals, [60, 30, 10]);
  });

  testWidgets('once ten rounds give a single leader, the game can be '
      'finished and joins the counted games', (tester) async {
    final game = CounterGame(players: ['Anne', 'Bob']);
    for (var round = 1; round <= 10; round++) {
      game.saveRound(
        round,
        CounterRound(
          entries: [
            const CounterEntry(bid: 0, tricksWon: 0),
            CounterEntry(bid: 0, tricksWon: round == 1 ? 1 : 0),
          ],
        ),
      );
    }
    store.active = SavedCounterGame(id: 1, game: game);
    await openCounter(tester);
    await tap(tester, 'counter-resume');
    await tester.pumpAndSettle();

    expect(find.text(Strings.wins('Anne')), findsOneWidget);
    await tap(tester, 'counter-finish');
    await tester.pumpAndSettle();

    expect(store.active, isNull);
    expect(store.finished.single.game.winner, 0);
    expect(find.text(Strings.wonBy('Anne')), findsOneWidget);
    expect(find.byKey(const Key('counter-resume')), findsNothing);
  });

  testWidgets('rascal scoring can be chosen for a counted game', (
    tester,
  ) async {
    await openCounter(tester);
    await tap(tester, 'counter-new');
    await tester.pumpAndSettle();
    for (final (index, name) in ['Anne', 'Bob', 'Chloé'].indexed) {
      await tester.enterText(find.byKey(Key('counter-name-$index')), name);
    }
    await tester.ensureVisible(find.text(Strings.scoringRascal));
    await tester.tap(find.text(Strings.scoringRascal));
    await tester.pump();
    await tap(tester, 'counter-start');
    await tester.pumpAndSettle();

    expect(store.active!.game.scoring, Scoring.rascal);
  });

  testWidgets('bonuses can be counted by hand: the total is entered beside '
      'the bid and the tricks', (tester) async {
    await openCounter(tester);
    await tap(tester, 'counter-new');
    await tester.pumpAndSettle();
    for (final (index, name) in ['Anne', 'Bob', 'Chloé'].indexed) {
      await tester.enterText(find.byKey(Key('counter-name-$index')), name);
    }
    await tester.dragUntilVisible(
      find.byKey(const Key('counter-manual-bonuses')),
      find.byType(ListView),
      const Offset(0, -200),
    );
    await tap(tester, 'counter-manual-bonuses');
    // Alliances and wagers are part of the total the players work out.
    expect(find.text(Strings.optionLoot), findsNothing);
    await tap(tester, 'counter-start');
    await tester.pumpAndSettle();
    expect(store.active!.game.manualBonuses, isTrue);

    await tap(tester, 'counter-enter');
    await tester.pumpAndSettle();
    await tap(tester, 'bid-0-plus');
    await tap(tester, 'counter-bids-done');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('counter-bonus-0')), findsNothing);

    await tap(tester, 'tricks-0-plus');
    await tap(tester, 'manual-bonus-0-plus', times: 3);
    // Bob took no trick: he has no bonus to enter.
    await tap(tester, 'manual-bonus-1-minus');
    await tap(tester, 'manual-bonus-1-plus');
    expect(
      tester.widget<Text>(find.byKey(const Key('counter-preview-0'))).data,
      '+50',
    );
    await tap(tester, 'counter-round-done');
    await tester.pumpAndSettle();

    expect(store.active!.game.totals, [50, 10, 10]);
  });

  testWidgets('a bonus counted by hand goes with a trick: taking the trick '
      'back takes it back, and it moves by five with the second expansion', (
    tester,
  ) async {
    store.active = SavedCounterGame(
      id: 1,
      game: CounterGame(
        players: ['Anne', 'Bob', 'Chloé'],
        manualBonuses: true,
        secondExpansion: true,
        draftBids: [1, 0, 0],
      ),
    );
    await openCounter(tester);
    await tap(tester, 'counter-resume');
    await tester.pumpAndSettle();
    await tap(tester, 'counter-enter');
    await tester.pumpAndSettle();

    await tap(tester, 'tricks-0-plus');
    await tap(tester, 'manual-bonus-0-plus');
    Text bonus() =>
        tester.widget<Text>(find.byKey(const Key('manual-bonus-0-value')));
    expect(bonus().data, '5');

    await tap(tester, 'tricks-0-minus');
    expect(bonus().data, '0');
  });

  testWidgets('the cards dealt in a round can be changed, and the round is '
      'scored on them', (tester) async {
    await openCounter(tester);
    await startGame(tester, ['Anne', 'Bob', 'Chloé']);
    await tap(tester, 'counter-enter');
    await tester.pumpAndSettle();
    expect(find.text(Strings.counterRoundTitle(1, 1)), findsOneWidget);

    await tap(tester, 'cards-plus', times: 2);
    expect(find.text(Strings.counterRoundTitle(1, 3)), findsOneWidget);
    await tap(tester, 'bid-0-plus', times: 3);
    await tap(tester, 'counter-bids-done');
    await tester.pumpAndSettle();
    expect(store.active!.game.draftCards, 3);

    await tap(tester, 'tricks-0-plus', times: 3);
    await tap(tester, 'counter-round-done');
    await tester.pumpAndSettle();

    final game = store.active!.game;
    expect(game.cardsIn(1), 3);
    // Three tricks bid and taken; a zero made with three cards is worth 30.
    expect(game.totals, [60, 30, 30]);
    expect(game.cardsIn(2), 2, reason: 'the next round is by the rules again');
  });

  testWidgets('the second expansion is an option, and brings its bonuses '
      'to the entry of a round', (tester) async {
    await openCounter(tester);
    await tap(tester, 'counter-new');
    await tester.pumpAndSettle();
    for (final (index, name) in ['Anne', 'Bob', 'Chloé'].indexed) {
      await tester.enterText(find.byKey(Key('counter-name-$index')), name);
    }
    await tap(tester, 'counter-second-expansion');
    await tap(tester, 'counter-start');
    await tester.pumpAndSettle();
    expect(store.active!.game.secondExpansion, isTrue);

    await tap(tester, 'counter-enter');
    await tester.pumpAndSettle();
    await tap(tester, 'counter-bids-done');
    await tester.pumpAndSettle();
    await tap(tester, 'counter-bonus-0');
    await tester.pumpAndSettle();
    await tap(tester, 'bonus-extraSeven-plus');
    await tap(tester, 'counter-bonus-close');
    await tester.pumpAndSettle();
    await tap(tester, 'counter-round-done');
    await tester.pumpAndSettle();

    expect(store.active!.game.totals, [5, 10, 10]);
  });

  testWidgets('without the second expansion, its bonuses are not offered', (
    tester,
  ) async {
    await openCounter(tester);
    await startGame(tester, ['Anne', 'Bob', 'Chloé']);
    await tap(tester, 'counter-enter');
    await tester.pumpAndSettle();
    await tap(tester, 'counter-bids-done');
    await tester.pumpAndSettle();
    await tap(tester, 'counter-bonus-0');
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('bonus-blackFourteen-plus')), findsOneWidget);
    expect(find.byKey(const Key('bonus-extraSeven-plus')), findsNothing);
  });

  testWidgets('two players cannot bear the same name', (tester) async {
    await openCounter(tester);
    await tap(tester, 'counter-new');
    await tester.pumpAndSettle();
    for (final (index, name) in ['Anne', 'Anne', 'Bob'].indexed) {
      await tester.enterText(find.byKey(Key('counter-name-$index')), name);
    }

    await tap(tester, 'counter-start');
    await tester.pump();

    expect(find.text(Strings.counterDistinctNames), findsOneWidget);
    expect(store.active, isNull);
  });

  testWidgets('removing a player does not hand the first lead to someone '
      'else', (tester) async {
    await openCounter(tester);
    await tap(tester, 'counter-new');
    await tester.pumpAndSettle();
    for (final (index, name) in ['Anne', 'Bob', 'Chloé'].indexed) {
      await tester.enterText(find.byKey(Key('counter-name-$index')), name);
    }
    await tester.pump();
    await tester.tap(find.byType(DropdownButton<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bob').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip(Strings.counterRemovePlayer).first);
    await tester.pumpAndSettle();
    await tap(tester, 'counter-start');
    await tester.pumpAndSettle();

    final game = store.active!.game;
    expect(game.players, ['Bob', 'Chloé']);
    expect(game.players[game.firstLeader], 'Bob');
  });

  testWidgets('players of earlier games are offered again', (tester) async {
    settingsStore.values['counterPlayers'] = '["Anne","Bob","Chloé","Dan"]';
    await openCounter(tester);
    await tap(tester, 'counter-new');
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ActionChip, 'Dan'), findsOneWidget);
    await tester.tap(find.widgetWithText(ActionChip, 'Dan'));
    await tester.pumpAndSettle();
    await tap(tester, 'counter-start');
    await tester.pumpAndSettle();

    expect(store.active!.game.players, ['Anne', 'Bob', 'Chloé', 'Dan']);
  });
}
