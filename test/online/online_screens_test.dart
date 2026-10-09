import 'dart:math';

import 'package:flutter/material.dart' hide Card;
import 'package:flutter_test/flutter_test.dart';
import 'package:skull_kings/bots/bot.dart';
import 'package:skull_kings/engine/engine.dart';
import 'package:skull_kings/game/seat_feed.dart';
import 'package:skull_kings/game/seat_identity.dart';
import 'package:skull_kings/online/online_game.dart';
import 'package:skull_kings/online/online_screens.dart';
import 'package:skull_kings/online/room_transport.dart';
import 'package:skull_kings/settings/app_settings.dart';
import 'package:skull_kings/settings/profile_dialog.dart';
import 'package:skull_kings/theme/tokens.dart';
import 'package:skull_kings/ui/player_icons.dart';
import 'package:skull_kings/ui/rules_content.dart';
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

  testWidgets('when the host plays again, the guest is taken to the new '
      'game without leaving the room', (tester) async {
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
    final first = host.start(Random(2), bots: 1)..open();
    await settle(tester);
    expect(find.byKey(const Key('bid-0')), findsOneWidget);

    // The host ends the game: the guest sees the standings, and is told to
    // stay for the next one. Only the host can start it.
    first.finishEarly();
    await settle(tester);
    expect(find.text(Strings.gameOver), findsOneWidget);
    expect(find.byKey(const Key('game-over-note')), findsOneWidget);
    expect(find.byKey(const Key('play-again')), findsNothing);

    host.rematch(Random(5)).open();
    await settle(tester);

    expect(find.text(Strings.gameOver), findsNothing);
    expect(find.text(Strings.roundTitle(1, 1)), findsOneWidget);
    expect(find.byKey(const Key('bid-0')), findsOneWidget);
    expect(find.byKey(const Key('table-room-code')), findsOneWidget);
    expect(find.text('Zoé'), findsOneWidget);

    host.close();
    await tester.pumpWidget(const SizedBox());
    await settle(tester);
  });

  testWidgets('the host plays again from the final standings, in the same '
      'room', (tester) async {
    await openOnline(tester);
    await tester.tap(find.byKey(const Key('online-create')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('launch')));
    await settle(tester);
    final code = tester
        .widget<SelectableText>(find.byKey(const Key('online-room-code')))
        .data!;
    final guest = OnlineGuest(
      transport: hub.transport('guest'),
      self: const RoomPlayer(id: 'guest', name: 'Bob', color: 1),
      retry: const Duration(milliseconds: 10),
    );
    final games = <(Seating, SeatFeed)>[];
    guest.games.listen(games.add);
    guest.join(code);
    await settle(tester);
    await tester.tap(find.byKey(const Key('online-start')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('online-bots-confirm')));
    await settle(tester);
    expect(games, hasLength(1));

    // The host ends the game from the pause menu, then plays again.
    await tester.tap(find.byTooltip(Strings.pause));
    await settle(tester);
    await tester.tap(find.text(Strings.finishEarly));
    await settle(tester);
    expect(find.text(Strings.finishEarlyConfirm), findsOneWidget);
    await tester.tap(find.text(Strings.finishEarly).last);
    await settle(tester);
    expect(find.text(Strings.gameOver), findsOneWidget);
    await tester.tap(find.byKey(const Key('play-again')));
    await settle(tester);

    expect(find.text(Strings.gameOver), findsNothing);
    expect(find.byKey(const Key('bid-0')), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('table-room-code'))).data,
      contains(code),
    );
    expect(games, hasLength(2));
    expect(games.last.$1.seat, games.first.$1.seat);

    guest.leave();
    await tester.pumpWidget(const SizedBox());
    await settle(tester);
  });

  testWidgets('while it waits, a room shows a turning wheel, what it waits '
      'for in large gold letters, and the rules in brief', (tester) async {
    await openOnline(tester);
    await tester.tap(find.byKey(const Key('online-create')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('launch')));
    await settle(tester);

    expect(find.byKey(const Key('pirate-loader')), findsOneWidget);
    final waiting = tester.widget<Text>(find.text(Strings.onlineNeedGuest));
    expect(waiting.textAlign, TextAlign.center);
    expect(waiting.style!.color, Tokens.gold);
    expect(waiting.style!.fontSize, greaterThanOrEqualTo(20));
    expect(find.byKey(const Key('rules-reminder')), findsOneWidget);
    expect(find.text(RulesContent.reminder.first), findsOneWidget);
    expect(tester.takeException(), isNull);

    // The wheel turns.
    double angle() => tester
        .widget<RotationTransition>(
          find.descendant(
            of: find.byKey(const Key('pirate-loader')),
            matching: find.byType(RotationTransition),
          ),
        )
        .turns
        .value;
    final before = angle();
    await tester.pump(const Duration(milliseconds: 500));
    expect(angle(), isNot(before));

    // All the rules are one tap away, and the room is still there after.
    await tester.ensureVisible(find.text(Strings.rulesReminderMore));
    await tester.tap(find.text(Strings.rulesReminderMore));
    await settle(tester);
    expect(find.text(Strings.rulesTitle), findsOneWidget);
    await tester.pageBack();
    await settle(tester);
    expect(find.byKey(const Key('online-room-code')), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await settle(tester);
  });

  testWidgets('a guest waiting for the host sees the same', (tester) async {
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

    expect(find.byKey(const Key('pirate-loader')), findsOneWidget);
    expect(
      tester.widget<Text>(find.text(Strings.onlineWaitingHost)).style!.color,
      Tokens.gold,
    );
    expect(find.byKey(const Key('rules-reminder')), findsOneWidget);
    expect(tester.takeException(), isNull);

    host.close();
    await tester.pumpWidget(const SizedBox());
    await settle(tester);
  });

  test('there are ten emblems and a palette of colours to choose from', () {
    expect(PlayerIcons.glyphs, hasLength(10));
    expect(PlayerIcons.glyphs.toSet(), hasLength(10));
    expect(Tokens.playerColors.toSet().length, greaterThanOrEqualTo(8));
  });

  test('host and guest see every seat under the same name, colour and '
      'emblem', () async {
    final host = OnlineHost(
      transport: hub.transport('host'),
      self: const RoomPlayer(id: 'host', name: 'Zoé', color: 2, icon: 4),
      config: const GameConfig(players: 4, seed: 0),
      bot: randomBot(Random(1)),
    );
    await host.open('ROOM');
    final guest = OnlineGuest(
      transport: hub.transport('g'),
      self: const RoomPlayer(id: 'g', name: 'Bob', color: 6, icon: 8),
      retry: const Duration(milliseconds: 5),
    );
    await guest.join('ROOM');
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(host.currentLobby.players.last.icon, 8);

    final hostFeed = host.start(Random(3), bots: 2);
    final (guestSeating, _) = await guest.started;
    List<SeatIdentity> seats(Seating seating) =>
        onlineSeats(seating, random: Random(seating.config.seed));
    final atHost = seats(
      Seating(
        config: hostFeed.config,
        seat: hostFeed.seat,
        occupants: host.currentOccupants,
      ),
    );
    final atGuest = seats(guestSeating);

    String look(SeatIdentity seat) => '${seat.name} ${seat.color} ${seat.icon}';
    expect(atGuest.map(look), atHost.map(look));
    final bob = atHost.firstWhere((seat) => seat.name == 'Bob');
    expect(bob.icon, PlayerIcons.glyph(8));
    expect(bob.color, Tokens.playerColors[6]);
    expect(atHost.map((seat) => seat.icon), everyElement(isNotNull));
    expect(atHost.map((seat) => seat.icon).toSet(), hasLength(4));

    await guest.leave();
    await host.close();
  });

  testWidgets('the emblem picked in the profile is saved and shown', (
    tester,
  ) async {
    final store = MemorySettingsStore({'playerName': 'Anne'});
    final settings = await AppSettings.load(store);
    await tester.pumpWidget(
      MaterialApp(
        theme: Tokens.theme(),
        home: Scaffold(body: ProfileDialog(settings: settings)),
      ),
    );

    await tester.tap(find.byKey(const Key('profile-icon-3')));
    await tester.tap(find.byKey(const Key('profile-color-5')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('profile-save')));
    await tester.pump();

    expect(settings.playerIcon, 3);
    expect(settings.playerColor, 5);
    expect(store.values['playerIcon'], '3');
    expect(tester.takeException(), isNull);
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

  testWidgets('a code nobody holds is said to be unknown, not left on an '
      'empty page', (tester) async {
    await openOnline(tester, name: 'Bob');

    await tester.enterText(find.byKey(const Key('online-code')), 'NOPE');
    await tester.tap(find.byKey(const Key('online-join')));
    await settle(tester);
    expect(find.text(Strings.onlineConnecting), findsOneWidget);

    await tester.pump(const Duration(seconds: 7));
    expect(find.text(Strings.onlineRefused('unknown')), findsOneWidget);
    expect(
      Strings.onlineRefused('unknown'),
      isNot(
        anyOf([
          Strings.onlineRefused('full'),
          Strings.onlineRefused('started'),
          Strings.onlineRefused('version'),
        ]),
      ),
    );

    // Back to the way in: a code that led nowhere is not remembered.
    await tester.tap(find.text(Strings.close));
    await settle(tester);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('online-code')))
          .controller!
          .text,
      'NOPE',
      reason: 'still what was typed',
    );
    await tester.pumpWidget(const SizedBox());
    await settle(tester);
  });

  testWidgets('the code of a room joined is offered again after leaving it', (
    tester,
  ) async {
    final host = OnlineHost(
      transport: hub.transport('host'),
      self: const RoomPlayer(id: 'host', name: 'Zoé', color: 2),
      config: const GameConfig(players: 2, seed: 0),
      bot: randomBot(Random(1)),
    );
    host.open('ABCD');
    final store = MemorySettingsStore({'playerName': 'Bob'});
    Future<void> open() async {
      final settings = await AppSettings.load(store);
      await tester.pumpWidget(
        MaterialApp(
          key: UniqueKey(),
          theme: Tokens.theme(),
          home: OnlineHomeScreen(settings: settings, transports: hub.transport),
        ),
      );
      await tester.pumpAndSettle();
    }

    await open();
    await tester.enterText(find.byKey(const Key('online-code')), 'abcd');
    await tester.tap(find.byKey(const Key('online-join')));
    await settle(tester);
    expect(find.text('Zoé'), findsOneWidget);
    await tester.pump(const Duration(seconds: 7));
    expect(find.text(Strings.onlineRefused('unknown')), findsNothing);

    await tester.pageBack();
    await settle(tester);
    expect(store.values['lastRoomCode'], 'ABCD');

    // The app is opened again another day.
    await open();
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('online-code')))
          .controller!
          .text,
      'ABCD',
    );

    host.close();
    await tester.pumpWidget(const SizedBox());
    await settle(tester);
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
