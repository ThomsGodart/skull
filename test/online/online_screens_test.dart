import 'dart:math';

import 'package:flutter/material.dart' hide Card;
import 'package:flutter_test/flutter_test.dart';
import 'package:skull_kings/bots/bot.dart';
import 'package:skull_kings/engine/engine.dart';
import 'package:skull_kings/online/online_game.dart';
import 'package:skull_kings/online/online_screens.dart';
import 'package:skull_kings/online/room_transport.dart';
import 'package:skull_kings/settings/app_settings.dart';
import 'package:skull_kings/theme/tokens.dart';
import 'package:skull_kings/ui/strings.dart';

import '../support/memory_stores.dart';

void main() {
  late MemoryRoomHub hub;

  setUp(() => hub = MemoryRoomHub());

  Future<void> openOnline(WidgetTester tester, {String name = 'Anne'}) async {
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final settings = await AppSettings.load(
      MemorySettingsStore({'playerName': name, 'botSpeed': 'instant'}),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: Tokens.theme(),
        home: OnlineHomeScreen(
          settings: settings,
          transports: hub.transport,
          random: Random(4),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Lets messages travel and screens settle.
  Future<void> settle(WidgetTester tester) async {
    // Long enough for a screen transition to finish.
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  testWidgets('creating a game shows its code and waits for a guest before '
      'it can start', (tester) async {
    await openOnline(tester);
    await tester.tap(find.byKey(const Key('online-create')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('launch')));
    await settle(tester);

    final code = tester
        .widget<SelectableText>(find.byKey(const Key('online-room-code')))
        .data!;
    expect(code, matches(RegExp(r'^[A-Z]{4}$')));
    expect(find.text('Anne'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('online-start')))
          .onPressed,
      isNull,
    );

    final guest = OnlineGuest(
      transport: hub.transport('guest'),
      self: const RoomPlayer(id: 'guest', name: 'Bob', color: 1),
      retry: const Duration(milliseconds: 10),
    );
    Seating? seating;
    guest.started.then((start) => seating = start.$1);
    guest.join(code);
    await settle(tester);

    expect(find.text('Bob'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('online-start')))
          .onPressed,
      isNotNull,
    );

    // Two people: the host is asked whether bots should join them.
    await tester.tap(find.byKey(const Key('online-start')));
    await settle(tester);
    expect(find.text(Strings.onlineBotsTitle), findsOneWidget);
    await tester.tap(find.byKey(const Key('online-bots-plus')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('online-bots-confirm')));
    await settle(tester);

    // The host is at the table, facing Bob (seats are shuffled).
    expect(find.text(Strings.roundTitle(1, 1)), findsOneWidget);
    expect(find.text('Bob'), findsOneWidget);
    expect(seating?.people.map((p) => p.name).toSet(), {'Anne', 'Bob'});
    expect(find.text(Strings.you), findsNothing);

    guest.leave();
    await tester.pumpWidget(const SizedBox());
    await settle(tester);
  });

  testWidgets('joining with a code shows the room, then the table once the '
      'host starts', (tester) async {
    final host = OnlineHost(
      transport: hub.transport('host'),
      self: const RoomPlayer(id: 'host', name: 'Zoé', color: 2),
      config: const GameConfig(players: 3, seed: 0),
      bot: randomBot(Random(1)),
    );
    host.open('WXYZ');
    await openOnline(tester, name: 'Bob');

    await tester.enterText(find.byKey(const Key('online-code')), 'wxyz');
    await tester.tap(find.byKey(const Key('online-join')));
    await settle(tester);

    expect(find.text(Strings.onlineCode('WXYZ')), findsOneWidget);
    expect(find.text('Zoé'), findsOneWidget);
    expect(find.text(Strings.onlineWaitingHost), findsOneWidget);
    expect(host.currentLobby.players.map((p) => p.name), ['Zoé', 'Bob']);

    host.start(Random(2), bots: 1).open();
    await settle(tester);

    expect(find.text(Strings.roundTitle(1, 1)), findsOneWidget);
    // Own seat shows the real name, never « Toi ».
    expect(find.text('Zoé'), findsOneWidget);
    expect(find.text('Bob'), findsOneWidget);
    expect(find.text(Strings.you), findsNothing);
    expect(find.byKey(const Key('bid-0')), findsOneWidget);
    expect(find.byKey(const Key('table-room-code')), findsOneWidget);

    host.close();
    await settle(tester);
    expect(find.text(Strings.onlineClosed), findsWidgets);

    await tester.pumpWidget(const SizedBox());
    await settle(tester);
  });

  testWidgets('an empty name is replaced before online play, so setup opens '
      'without a rename prompt', (tester) async {
    await openOnline(tester, name: '');

    await tester.tap(find.byKey(const Key('online-create')));
    await tester.pumpAndSettle();
    expect(find.text(Strings.onlineNamePrompt), findsNothing);
    expect(find.byKey(const Key('launch')), findsOneWidget);

    await tester.tap(find.byKey(const Key('launch')));
    await settle(tester);
    expect(find.byKey(const Key('online-room-code')), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await settle(tester);
  });

  testWidgets('a player with a name of their own is not asked again', (
    tester,
  ) async {
    await openOnline(tester, name: 'Bob');

    await tester.tap(find.byKey(const Key('online-create')));
    await tester.pumpAndSettle();

    expect(find.text(Strings.onlineNamePrompt), findsNothing);
    expect(find.byKey(const Key('launch')), findsOneWidget);
  });

  testWidgets('a full game is refused with a message', (tester) async {
    final host = OnlineHost(
      transport: hub.transport('host'),
      self: const RoomPlayer(id: 'host', name: 'Zoé', color: 2),
      config: const GameConfig(players: 2, seed: 0),
      bot: randomBot(Random(1)),
      capacity: 2,
    );
    host.open('FULL');
    final first = OnlineGuest(
      transport: hub.transport('first'),
      self: const RoomPlayer(id: 'first', name: 'Chloé', color: 1),
    );
    first.join('FULL');
    await openOnline(tester, name: 'Bob');
    await settle(tester);

    await tester.enterText(find.byKey(const Key('online-code')), 'FULL');
    await tester.tap(find.byKey(const Key('online-join')));
    await settle(tester);

    expect(find.text(Strings.onlineRefused('full')), findsOneWidget);

    first.leave();
    host.close();
    await tester.pumpWidget(const SizedBox());
    await settle(tester);
  });
}
