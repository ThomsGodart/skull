// Plays a whole game between a host and two guests over the real Supabase
// project, each with its own connection, and checks they agree on the result.
//
//   dart run tool/online_smoke.dart
import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:skull_kings/bots/bot.dart';
import 'package:skull_kings/engine/engine.dart';
import 'package:skull_kings/game/seat_feed.dart';
import 'package:skull_kings/online/online_backend.dart';
import 'package:skull_kings/online/online_game.dart';
import 'package:skull_kings/online/supabase_room_transport.dart';
import 'package:supabase/supabase.dart';

SupabaseClient client() =>
    SupabaseClient(OnlineBackend.url, OnlineBackend.publishableKey);

GameFinished? drive(SeatFeed feed, int seed, void Function(GameFinished) done) {
  final random = Random(seed);
  feed.onUpdate = () {
    for (final event in feed.takeEvents()) {
      if (event is GameFinished) done(event);
    }
    final question = feed.question;
    if (question != null) {
      scheduleMicrotask(() {
        if (identical(feed.question, question)) {
          feed.answer(randomAnswer(question, random));
        }
      });
    }
  };
  return null;
}

Future<void> main() async {
  final room = 'SMOKE${Random().nextInt(1 << 20)}';
  final clients = [client(), client(), client()];
  final watch = Stopwatch()..start();

  final host = OnlineHost(
    transport: SupabaseRoomTransport(clients[0], 'host'),
    self: const RoomPlayer(id: 'host', name: 'Host', color: 0),
    config: const GameConfig(players: 4, seed: 0, piratePowers: true),
    bot: randomBot(Random(1)),
  );
  await host.open(room);
  stdout.writeln('host connected after ${watch.elapsedMilliseconds} ms');

  final guests = [
    for (final (index, id) in ['g1', 'g2'].indexed)
      OnlineGuest(
        transport: SupabaseRoomTransport(clients[index + 1], id),
        self: RoomPlayer(id: id, name: id, color: 1),
      ),
  ];
  for (final guest in guests) {
    await guest.join(room);
  }
  for (var i = 0; i < 100 && host.currentLobby.players.length < 3; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  final lobby = host.currentLobby;
  stdout.writeln(
    'lobby after ${watch.elapsedMilliseconds} ms: '
    '${lobby.players.map((p) => '${p.name}${p.connected ? '' : ' (away)'}')}',
  );
  if (lobby.players.length != 3) {
    stdout.writeln('FAILED: the guests never reached the host');
    exit(1);
  }

  for (var i = 0; i < 50; i++) {
    if (host.currentLobby.players.every((p) => p.connected)) break;
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  stdout.writeln(
    'presence after ${watch.elapsedMilliseconds} ms: '
    '${host.currentLobby.players.map((p) => '${p.name}:${p.connected}')}',
  );
  var hostSeen = false;
  guests.first.hostPresent.listen((present) => hostSeen = present);

  final results = <String, GameFinished>{};
  final hostFeed = host.start(Random());
  drive(hostFeed, 10, (result) => results['host'] = result);
  for (final (index, guest) in guests.indexed) {
    final (seating, feed) = await guest.started.timeout(
      const Duration(seconds: 15),
    );
    stdout.writeln('guest ${index + 1} sits at seat ${seating.seat}');
    drive(feed, 11 + index, (result) => results['g${index + 1}'] = result);
  }
  hostFeed.open();

  for (var i = 0; i < 1800 && results.length < 3; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  stdout.writeln(
    'finished for ${results.keys.toList()} '
    'after ${watch.elapsedMilliseconds} ms',
  );
  final scores = {for (final result in results.values) '${result.scores}'};
  final ok = results.length == 3 && scores.length == 1;
  stdout.writeln('guest sees the host as present: $hostSeen');
  stdout.writeln(ok ? 'OK: everyone agrees on $scores' : 'FAILED: $scores');

  await host.close();
  for (final guest in guests) {
    await guest.leave();
  }
  for (final c in clients) {
    await c.dispose();
  }
  exit(ok ? 0 : 1);
}
