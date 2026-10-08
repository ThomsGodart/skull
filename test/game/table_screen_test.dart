import 'dart:math';

import 'package:flutter/material.dart' hide Card;
import 'package:flutter_test/flutter_test.dart';
import 'package:skull_kings/bots/bot.dart';
import 'package:skull_kings/engine/engine.dart';
import 'package:skull_kings/game/game_controller.dart';
import 'package:skull_kings/game/score_views.dart';
import 'package:skull_kings/game/screen_awake.dart';
import 'package:skull_kings/game/seat_chip.dart';
import 'package:skull_kings/game/seat_identity.dart';
import 'package:skull_kings/game/power_dialog.dart';
import 'package:skull_kings/game/table_screen.dart';
import 'package:skull_kings/game/trick_area.dart';
import 'package:skull_kings/settings/app_settings.dart';
import 'package:skull_kings/theme/tokens.dart';
import 'package:skull_kings/ui/strings.dart';

import '../support/memory_stores.dart';

void main() {
  Future<GameController> openTable(
    WidgetTester tester, {
    int players = 4,
    int seed = 3,
    // A small phone, portrait.
    Size size = const Size(360, 720),
    AppSettings? settings,
    TableSpeed speed = TableSpeed.instant,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller = GameController(
      config: GameConfig(players: players, seed: seed),
      bot: randomBot(Random(seed)),
      speed: speed,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: Tokens.theme(),
        home: TableScreen(
          controller: controller,
          settings: settings,
          onPlayAgain: () {},
        ),
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

  /// Lifts [card], then plays it with the button.
  Future<void> playCard(WidgetTester tester, Card card) async {
    await tapCard(tester, card);
    await tester.tap(find.byKey(const Key('play-card')));
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

  testWidgets('a tap lifts a card and says what it does; a second tap puts '
      'it back, and only the button plays it', (tester) async {
    final controller = await openTable(tester);
    await tester.tap(find.byKey(const Key('bid-0')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('place-bid')));
    await tester.pump();
    final card = controller.playQuestion!.legalCards.first;

    await tapCard(tester, card);
    expect(find.byKey(const Key('card-hint')), findsOneWidget);
    expect(find.byKey(const Key('play-card')), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byKey(const Key('play-card'))).onPressed,
      isNotNull,
    );

    await tapCard(tester, card);
    expect(controller.playQuestion, isNotNull, reason: 'put back, not played');
    // « Jouer » stays on screen, disabled until a card is selected again.
    expect(
      tester.widget<FilledButton>(find.byKey(const Key('play-card'))).onPressed,
      isNull,
    );

    await tapCard(tester, card);
    await tester.tap(find.byKey(const Key('play-card')));
    await tester.pump();
    if (card.kind == CardKind.tigress) {
      await tester.tap(find.byKey(const Key('tigress-escape')));
      await tester.pump();
    }
    expect(controller.hand, isNot(contains(card)));
  });

  testWidgets('the score sheet stays within reach while a round summary '
      'is shown', (tester) async {
    final controller = await openTable(tester);
    await tester.tap(find.byKey(const Key('bid-0')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('place-bid')));
    await tester.pump();
    final card = controller.playQuestion!.legalCards.first;
    await playCard(tester, card);
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
        if (controller.afterTrickQuestion case DiscardQuestion(
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
          await playCard(tester, card);
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

  testWidgets('a whole game with the second expansion runs to the end, each '
      'of its cards played through its own dialog', (tester) async {
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final dialogs = <String>{};
    for (var seed = 0; seed < 8; seed++) {
      final controller = GameController(
        config: GameConfig(
          players: 4,
          seed: seed,
          kraken: true,
          whiteWhale: true,
          piratePowers: true,
          secondExpansion: true,
        ),
        bot: randomBot(Random(seed)),
        speed: TableSpeed.instant,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: Tokens.theme(),
          home: TableScreen(
            key: ValueKey('second-$seed'),
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
        if (await tapIfShown('declare-14')) continue;
        if (await tapIfShown('joker-green')) continue;
        switch (controller.afterTrickQuestion) {
          case DiscardQuestion(:final hand, :final count):
            for (final card in hand.take(count)) {
              await tester.tap(find.byKey(Key('power-discard-${card.id}')));
              await tester.pump();
            }
            await tapIfShown('power-confirm');
            continue;
          case WalkPlankQuestion(:final pirates):
            await tapIfShown('power-overboard-${pirates.first.id}');
            continue;
          case ChooseVictimQuestion(:final seats):
            await tapIfShown('power-victim-${seats.last}');
            continue;
          default:
        }
        if (controller.roundSummary != null) {
          await tester.tap(find.byKey(const Key('continue')));
        } else if (controller.bidQuestion != null) {
          await tester.tap(find.byKey(const Key('bid-0')));
          await tester.pump();
          await tester.tap(find.byKey(const Key('place-bid')));
        } else if (controller.playQuestion case final question?) {
          // The joker as soon as it may name its suit.
          final card = question.legalCards.firstWhere(
            (card) =>
                card.kind == CardKind.joker && suitIsOpen(controller.trick),
            orElse: () => question.legalCards.first,
          );
          await playCard(tester, card);
          if (card.kind == CardKind.tigress) {
            await tester.tap(find.byKey(const Key('tigress-escape')));
          }
        }
      }
      expect(controller.result, isNotNull, reason: 'seed $seed');
    }
    expect(dialogs, containsAll(['declare-14', 'joker-green', 'power-victim']));
  });

  testWidgets('a card slides into place when it is put down, unless the '
      'trick is only looked back at', (tester) async {
    Widget area(List<Play> plays, {bool animate = true}) => MaterialApp(
      theme: Tokens.theme(),
      home: TrickArea(
        plays: plays,
        seats: const [
          SeatIdentity('Anne', Tokens.gold),
          SeatIdentity('Bob', Tokens.gold),
        ],
        slideFromBelow: 0,
        animate: animate,
      ),
    );
    const first = Play(seat: 1, card: Card.number(Suit.green, 3));
    const second = Play(seat: 0, card: Card.number(Suit.green, 9));
    double top(Play play) => tester
        .getTopLeft(find.bySemanticsLabel(Strings.cardName(play.card)))
        .dy;
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(area([first]));
    await tester.pumpAndSettle();
    final rest = top(first);

    await tester.pumpWidget(area([first, second]));
    await tester.pump(const Duration(milliseconds: 40));
    expect(top(first), rest, reason: 'the card already down stays put');
    expect(top(second), greaterThan(rest), reason: 'it comes from below');
    await tester.pumpAndSettle();
    expect(top(second), rest);

    await tester.pumpWidget(area(const [], animate: false));
    await tester.pumpWidget(area([first], animate: false));
    expect(top(first), rest);
    handle.dispose();
  });

  testWidgets('the plank asks which pirate leaves the trick', (tester) async {
    Answer? answer;
    const rosie = Card.special(CardKind.pirate);
    await tester.pumpWidget(
      MaterialApp(
        theme: Tokens.theme(),
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => answer = await showDialog<Answer>(
              context: context,
              builder: (context) => const PowerDialog(
                question: WalkPlankQuestion(
                  seat: 0,
                  pirates: [rosie, maryCard],
                ),
                seats: [],
                bid: 0,
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text(Strings.plankTitle), findsOneWidget);
    await tester.tap(find.byKey(Key('power-overboard-${maryCard.id}')));
    await tester.pumpAndSettle();

    expect((answer! as WalkPlankAnswer).pirate, maryCard);
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
        await playCard(tester, card);
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
    final seats = SeatIdentity.table(
      4,
      human: const SeatIdentity(Strings.you, Tokens.gold),
      random: Random(3),
    );
    final expected = leader == 0
        ? Strings.youLeadRound
        : Strings.leadsRound(seats[leader].name);
    expect(find.textContaining(expected), findsOneWidget);
  });

  testWidgets('a card selected before our turn keeps Jouer ready when the '
      'turn arrives', (tester) async {
    // Linger after bids so a card can be lifted before PlayQuestion lands.
    const slowReveal = TableSpeed(
      botPlay: Duration.zero,
      trickHold: Duration.zero,
      bidReveal: Duration(milliseconds: 400),
    );
    final controller = await openTable(tester, speed: slowReveal);
    await tester.tap(find.byKey(const Key('bid-0')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('place-bid')));
    await tester.pump();

    expect(controller.playQuestion, isNull, reason: 'still revealing bids');
    final card = controller.hand.first;
    await tapCard(tester, card);
    expect(
      tester.widget<FilledButton>(find.byKey(const Key('play-card'))).onPressed,
      isNull,
    );

    await tester.pump(const Duration(milliseconds: 450));
    expect(controller.playQuestion, isNotNull);
    expect(
      tester.widget<FilledButton>(find.byKey(const Key('play-card'))).onPressed,
      isNotNull,
      reason: 'pre-selected card makes Jouer clickable on our turn',
    );
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

  testWidgets('a card tapped while bidding tells what it does without '
      'hiding the table, and a second tap puts it away', (tester) async {
    final controller = await openTable(tester);
    final card = controller.hand.single;

    await tapCard(tester, card);

    expect(find.byKey(const Key('card-hint')), findsOneWidget);
    expect(find.byKey(const Key('play-card')), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byKey(const Key('play-card'))).onPressed,
      isNull,
      reason: 'not our turn to play while bidding',
    );
    expect(find.byKey(const Key('place-bid')), findsOneWidget);
    expect(controller.bidQuestion, isNotNull, reason: 'still bidding');
    final hint = Strings.cardHint(card, powers: false);
    if (hint != null) expect(find.textContaining(hint), findsOneWidget);

    await tapCard(tester, card);

    expect(find.byKey(const Key('card-hint')), findsNothing);
  });

  testWidgets('with the cards\' effects turned off, a lifted card only brings '
      'the button that plays it', (tester) async {
    final settings = await AppSettings.load(
      MemorySettingsStore({'cardEffects': 'false'}),
    );
    final controller = await openTable(tester, settings: settings);
    final card = controller.hand.single;

    // While bidding the card cannot be played: the button stays disabled.
    await tapCard(tester, card);
    expect(find.byKey(const Key('card-hint')), findsNothing);
    expect(
      tester.widget<FilledButton>(find.byKey(const Key('play-card'))).onPressed,
      isNull,
    );
    await tapCard(tester, card);

    await tester.tap(find.byKey(const Key('bid-0')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('place-bid')));
    await tester.pump();
    await tapCard(tester, controller.playQuestion!.legalCards.first);

    expect(find.byKey(const Key('card-hint')), findsNothing);
    expect(
      tester.widget<FilledButton>(find.byKey(const Key('play-card'))).onPressed,
      isNotNull,
    );
  });

  testWidgets('on its side, the phone shows every seat, and larger than '
      'upright', (tester) async {
    double nameSize() =>
        tester.widget<Text>(find.text(Strings.you)).style!.fontSize!;
    await openTable(tester);
    final upright = nameSize();

    await openTable(tester, size: const Size(800, 360));
    await tester.pump();

    expect(nameSize(), greaterThan(upright * 1.3));
    // All four of them, none scrolled out of sight.
    final screen = tester.getRect(find.byType(TableScreen));
    for (final chip in tester.widgetList(find.byType(SeatChip))) {
      expect(
        screen.contains(tester.getRect(find.byWidget(chip)).center),
        isTrue,
      );
    }
    expect(find.byType(SeatChip), findsNWidgets(4));
  });

  testWidgets('a seat shows what it staked with Rascal, that it holds '
      'Harry, and a token per trick bid when asked to', (tester) async {
    Widget chip({bool tokens = true}) => MaterialApp(
      theme: Tokens.theme(),
      home: Center(
        child: SizedBox(
          width: 160,
          child: SeatChip(
            identity: const SeatIdentity('Bob', Tokens.gold),
            bid: 3,
            tricksWon: 1,
            score: 40,
            wager: 20,
            hasHarry: true,
            showTokens: tokens,
          ),
        ),
      ),
    );
    await tester.pumpWidget(chip());

    expect(find.text(Strings.wagerBadge(20)), findsOneWidget);
    expect(find.text(Strings.harryBadge), findsOneWidget);
    final tokens = find.descendant(
      of: find.byKey(const Key('trick-tokens')),
      matching: find.byType(Container),
    );
    expect(tokens, findsNWidgets(3));

    await tester.pumpWidget(chip(tokens: false));
    expect(find.byKey(const Key('trick-tokens')), findsNothing);
  });

  test('left to himself, Harry moves the bid towards the tricks taken', () {
    expect(GameController.harryChange(2, 3, const [-1, 0, 1]), 1);
    expect(GameController.harryChange(2, 0, const [-1, 0, 1]), -1);
    expect(GameController.harryChange(2, 2, const [-1, 0, 1]), 0);
    expect(GameController.harryChange(0, 0, const [0, 1]), 0);
    // A bid of zero cannot go lower.
    expect(GameController.harryChange(4, 2, const [0]), 0);
  });

  test('a pirate with its power on tells that power, a plain one how it '
      'ranks', () {
    final harry = baseDeck().firstWhere(
      (card) => Pirate.of(card) == Pirate.harry,
    );

    expect(
      Strings.cardHint(harry, powers: true),
      contains('à la fin de la manche'),
    );
    expect(
      Strings.cardHint(harry, powers: false),
      contains('Perd contre le Skull King'),
    );
  });

  testWidgets('once the bids are turned over, the header gives their total '
      'against the tricks to take', (tester) async {
    final controller = await openTable(tester);
    expect(find.byKey(const Key('bids-total')), findsNothing);

    await tester.tap(find.byKey(const Key('bid-1')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('place-bid')));
    await tester.pump();

    final total = controller.bids.fold<int>(0, (sum, bid) => sum + bid!);
    expect(find.text(Strings.bidsTotal(total, 1)), findsOneWidget);
  });

  for (final (players, size) in [
    (3, const Size(360, 720)),
    (8, const Size(360, 720)),
    // The phone on its side.
    (3, const Size(720, 360)),
    (8, const Size(720, 360)),
  ]) {
    testWidgets('a whole game with $players players on a ${size.width.round()}'
        'x${size.height.round()} screen runs to the final standings without '
        'a layout error', (tester) async {
      final controller = await openTable(
        tester,
        players: players,
        seed: 11,
        size: size,
      );

      for (var step = 0; step < 4000; step++) {
        await tester.pump();
        if (controller.result != null && controller.roundSummary == null) break;
        if (controller.roundSummary != null) {
          await tester.tap(find.byKey(const Key('continue')));
        } else if (controller.bidQuestion != null) {
          await tester.ensureVisible(find.byKey(const Key('bid-0')));
          await tester.tap(find.byKey(const Key('bid-0')));
          await tester.pump();
          await tester.ensureVisible(find.byKey(const Key('place-bid')));
          await tester.tap(find.byKey(const Key('place-bid')));
        } else if (controller.playQuestion case final question?) {
          final card = question.legalCards.first;
          await playCard(tester, card);
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
