import 'dart:async';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:skull_kings/bots/bot.dart';
import 'package:skull_kings/engine/engine.dart';
import 'package:skull_kings/game/seat_feed.dart';
import 'package:skull_kings/online/online_game.dart';
import 'package:skull_kings/online/room_transport.dart';

/// Lets queued messages and timers of [duration] go by.
Future<void> pause([Duration duration = Duration.zero]) =>
    Future<void>.delayed(duration);

/// Plays [feed] with random answers, keeping every event it receives.
class Player {
  Player(this.feed, int seed) : _random = Random(seed) {
    feed.onUpdate = _onUpdate;
  }

  final SeatFeed feed;
  final Random _random;
  final List<Event> events = [];

  /// When false, the player looks but does not answer.
  bool answers = true;

  GameFinished? get result => events.whereType<GameFinished>().firstOrNull;

  void _onUpdate() {
    events.addAll(feed.takeEvents());
    final question = feed.question;
    if (question != null && answers) {
      // Not from inside the feed's own callback.
      scheduleMicrotask(() {
        if (identical(feed.question, question)) {
          feed.answer(randomAnswer(question, _random));
        }
      });
    }
  }
}

void main() {
  late MemoryRoomHub hub;
  const config = GameConfig(players: 4, seed: 0);
  const fast = Duration(milliseconds: 5);

  OnlineHost host({GameConfig config = config, Duration grace = fast}) =>
      OnlineHost(
        transport: hub.transport('host'),
        self: const RoomPlayer(id: 'host', name: 'Anne', color: 0),
        config: config,
        bot: randomBot(Random(1)),
        grace: grace,
      );

  OnlineGuest guest(String id, {String? name}) => OnlineGuest(
    transport: hub.transport(id),
    self: RoomPlayer(id: id, name: name ?? id, color: 1),
    retry: fast,
  );

  setUp(() => hub = MemoryRoomHub());

  /// A started game: the host and [guests] guests, everyone playing at random.
  Future<(OnlineHost, List<OnlineGuest>, List<Player>)> startGame(
    int guests, {
    GameConfig config = config,
  }) async {
    final theHost = host(config: config);
    await theHost.open('ROOM');
    final theGuests = [for (var i = 1; i <= guests; i++) guest('g$i')];
    for (final guest in theGuests) {
      await guest.join('ROOM');
    }
    await pause(fast * 3);
    final hostFeed = theHost.start(Random(7));
    final players = [Player(hostFeed, 100)];
    for (final (index, guest) in theGuests.indexed) {
      final (_, feed) = await guest.started;
      players.add(Player(feed, 101 + index));
    }
    hostFeed.open();
    return (theHost, theGuests, players);
  }

  Future<void> untilOver(List<Player> players) async {
    for (var i = 0; i < 4000; i++) {
      if (players.every((player) => player.result != null)) return;
      await pause(const Duration(milliseconds: 1));
    }
    fail('the game never ended for everyone');
  }

  group('the room before the game', () {
    test('guests who join are listed after the host, for everyone', () async {
      final theHost = host();
      await theHost.open('ROOM');
      final first = guest('g1', name: 'Bob');
      final second = guest('g2', name: 'Chloé');
      Lobby? seenByFirst;
      first.lobby.listen((lobby) => seenByFirst = lobby);

      await first.join('ROOM');
      await second.join('ROOM');
      await pause(fast * 3);

      expect(theHost.currentLobby.players.map((p) => p.name), [
        'Anne',
        'Bob',
        'Chloé',
      ]);
      expect(seenByFirst!.players.map((p) => p.name), ['Anne', 'Bob', 'Chloé']);
      expect(seenByFirst!.hostId, 'host');
      expect(seenByFirst!.config.players, 4);
    });

    test(
      'a guest who leaves before the start gives their place back',
      () async {
        final theHost = host();
        await theHost.open('ROOM');
        final leaver = guest('g1');
        await leaver.join('ROOM');
        await pause(fast * 3);
        expect(theHost.currentLobby.players, hasLength(2));

        await leaver.leave();
        await pause(fast);

        expect(theHost.currentLobby.players.map((p) => p.id), ['host']);
      },
    );

    test('a full room turns the next guest away', () async {
      final theHost = host(config: const GameConfig(players: 2, seed: 0));
      await theHost.open('ROOM');
      await guest('g1').join('ROOM');
      await pause(fast * 3);
      final late = guest('g2');
      String? reason;
      late.refused.listen((r) => reason = r);

      await late.join('ROOM');
      await pause(fast * 3);

      expect(reason, 'full');
      expect(theHost.currentLobby.players, hasLength(2));
    });

    test('a guest cannot join a game that has started', () async {
      final (_, _, _) = await startGame(1);
      final late = guest('g9');
      String? reason;
      late.refused.listen((r) => reason = r);

      await late.join('ROOM');
      await pause(fast * 3);

      expect(reason, 'started');
    });
  });

  group('a game across phones', () {
    test('host and guests play the same game to the same result, bots '
        'filling the empty seats', () async {
      final (_, guests, players) = await startGame(2);

      await untilOver(players);

      final scores = players.first.result!.scores;
      expect(scores, hasLength(4));
      for (final player in players) {
        expect(player.result!.scores, scores);
        expect(player.result!.winner, players.first.result!.winner);
      }
      final (seating, _) = await guests.first.started;
      expect(seating.seat, 1);
      expect(seating.people.map((p) => p.id), ['host', 'g1', 'g2']);
    });

    test('each phone only ever receives its own cards', () async {
      final (_, _, players) = await startGame(2);
      await untilOver(players);

      for (final (seat, player) in players.indexed) {
        final hands = player.events.whereType<HandDealt>();
        expect(hands, isNotEmpty);
        expect(hands.map((hand) => hand.seat).toSet(), {seat});
        for (final event in player.events) {
          expect(event.audience, anyOf(isNull, seat));
        }
      }
    });

    test('every option of the game works across phones', () async {
      final (_, _, players) = await startGame(
        2,
        config: const GameConfig(
          players: 5,
          seed: 0,
          kraken: true,
          whiteWhale: true,
          loot: true,
          piratePowers: true,
          scoring: Scoring.rascal,
        ),
      );

      await untilOver(players);

      expect(players.first.result!.scores, hasLength(5));
    });

    test('two phones alone play with the ghost', () async {
      final (_, _, players) = await startGame(
        1,
        config: const GameConfig(players: 2, seed: 0),
      );

      await untilOver(players);

      expect(players.first.result!.scores, hasLength(2));
      expect(players.last.result!.scores, players.first.result!.scores);
    });
  });

  group('when the network misbehaves', () {
    test('a guest whose messages get lost for a while catches up', () async {
      final (_, guests, players) = await startGame(2);
      final shaky = guests.first.transport as MemoryRoomTransport;

      for (var i = 0; i < 6; i++) {
        shaky.dropOutgoing = true;
        await pause(fast * 4);
        shaky.dropOutgoing = false;
        await pause(fast * 4);
      }
      await untilOver(players);

      expect(players[1].result!.scores, players.first.result!.scores);
    });

    test('a guest who drops out is replaced by a bot after a while, and '
        'the others finish the game', () async {
      final (theHost, guests, players) = await startGame(2);
      await pause(fast * 2);

      players[1].answers = false;
      await guests.first.leave();
      await untilOver([players[0], players[2]]);

      expect(players[0].result!.scores, hasLength(4));
      expect(
        theHost.currentLobby.players.firstWhere((p) => p.id == 'g1').connected,
        isFalse,
      );
    });

    test('an answer sent for someone else\'s seat changes nothing', () async {
      final theHost = host();
      await theHost.open('ROOM');
      final honest = guest('g1');
      final cheat = hub.transport('g2');
      await honest.join('ROOM');
      await cheat.connect('ROOM');
      cheat.send({
        'type': 'hello',
        'protocol': onlineProtocol,
        'name': 'Cheat',
        'color': 0,
      });
      await pause(fast * 3);
      final hostFeed = theHost.start(Random(7))..open();
      await pause(fast);
      final before = hostFeed.question;

      // Seat 2 tries to bid for seat 0 and for seat 1.
      for (final seat in [0, 1]) {
        cheat.send({
          'type': 'answer',
          'answer': answerToJson(BidAnswer(seat: seat, bid: 0)),
        }, to: 'host');
      }
      await pause(fast * 2);

      expect(hostFeed.question, same(before));
      final (_, feed) = await honest.started;
      expect(feed.question, isA<BidQuestion>());
    });
  });

  test('when the host closes the room, the guests are told', () async {
    final (theHost, guests, _) = await startGame(1);
    var told = false;
    guests.single.closed.then((_) => told = true);

    await theHost.close();
    await pause(fast);

    expect(told, isTrue);
  });

  test('a room code is four letters that cannot be confused', () {
    final random = Random(3);
    for (var i = 0; i < 200; i++) {
      final code = newRoomCode(random);
      expect(code, matches(RegExp(r'^[A-HJKMNP-Z]{4}$')));
    }
  });
}
