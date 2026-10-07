import 'dart:async';
import 'dart:math';

import '../bots/bot.dart';
import '../engine/engine.dart';
import '../game/local_table.dart';
import '../game/seat_feed.dart';
import 'room_transport.dart';

/// Bumped whenever phones of different versions could no longer play the
/// same game together.
const onlineProtocol = 2;

/// How long an absent player is waited for before a bot plays in their place.
const absenceGrace = Duration(seconds: 30);

/// Someone in a room.
final class RoomPlayer {
  const RoomPlayer({
    required this.id,
    required this.name,
    required this.color,
    this.connected = true,
  });

  factory RoomPlayer.fromJson(Json json) => RoomPlayer(
    id: json['id']! as String,
    name: json['name']! as String,
    color: json['color']! as int,
    connected: json['connected'] as bool? ?? true,
  );

  final String id;
  final String name;

  /// An index into the colours a player may pick.
  final int color;
  final bool connected;

  Json toJson() => {
    'id': id,
    'name': name,
    'color': color,
    'connected': connected,
  };
}

/// What everyone in a room knows before the game starts.
final class Lobby {
  const Lobby({
    required this.hostId,
    required this.players,
    required this.config,
  });

  factory Lobby.fromJson(Json json) => Lobby(
    hostId: json['hostId']! as String,
    players: [
      for (final player in json['players']! as List)
        RoomPlayer.fromJson(player as Json),
    ],
    config: GameConfig.fromJson(json['config']! as Json),
  );

  final String hostId;

  /// The host first, then the guests in the order they came.
  final List<RoomPlayer> players;

  /// What will be played; its seed means nothing yet.
  final GameConfig config;

  Json toJson() => {
    'hostId': hostId,
    'players': [for (final player in players) player.toJson()],
    'config': config.toJson(),
  };
}

/// Who sits where, once the game has started: the people of the room on the
/// first seats, bots on the others.
final class Seating {
  const Seating({
    required this.config,
    required this.seat,
    required this.people,
  });

  factory Seating.fromJson(Json json) => Seating(
    config: GameConfig.fromJson(json['config']! as Json),
    seat: json['seat']! as int,
    people: [
      for (final player in json['people']! as List)
        RoomPlayer.fromJson(player as Json),
    ],
  );

  final GameConfig config;

  /// The seat of the phone this was sent to.
  final int seat;

  /// The person at each of the first seats, in seat order.
  final List<RoomPlayer> people;

  Json toJson() => {
    'config': config.toJson(),
    'seat': seat,
    'people': [for (final player in people) player.toJson()],
  };
}

/// A short code friends can read out to each other.
String newRoomCode(Random random) {
  // No letter that is mistaken for another when read aloud or typed.
  const letters = 'ABCDEFGHJKMNPQRSTUVWXYZ';
  return [for (var i = 0; i < 4; i++) letters[random.nextInt(letters.length)]]
      .join();
}

/// The phone that runs the game for a room: it holds the engine and the
/// bots, and sends each guest what their seat may see.
class OnlineHost {
  OnlineHost({
    required this.transport,
    required this.self,
    required this.config,
    required this.bot,
    this.grace = absenceGrace,
    this.capacity = maxPlayers,
  }) {
    _players.add(self);
  }

  final RoomTransport transport;
  final RoomPlayer self;
  final Bot bot;
  final Duration grace;

  /// How many people the room takes, the host included.
  final int capacity;

  /// What is played. Its seed is drawn when the game starts, and its number
  /// of players is then whoever is in the room, plus the bots asked for.
  GameConfig config;
  final List<RoomPlayer> _players = [];
  Set<String> _present = {};

  /// Everyone who was connected at some point: presence lags behind a
  /// guest's first message, and must not get them thrown out meanwhile.
  final Set<String> _everPresent = {};
  final _lobby = StreamController<Lobby>.broadcast();
  final List<StreamSubscription<Object?>> _subscriptions = [];

  LocalTable? _table;

  /// For each guest seat, every event sent to it so far, as JSON.
  final Map<int, List<Json>> _logs = {};
  final Map<String, Timer> _absences = {};

  /// The room as it stands, each time it changes.
  Stream<Lobby> get lobby => _lobby.stream;

  Lobby get currentLobby => Lobby(
    hostId: self.id,
    players: [
      for (final player in _players)
        RoomPlayer(
          id: player.id,
          name: player.name,
          color: player.color,
          // Not seen yet is not gone: presence comes a moment after hello.
          connected:
              player.id == self.id ||
              _present.contains(player.id) ||
              !_everPresent.contains(player.id),
        ),
    ],
    config: config,
  );

  bool get started => _table != null;

  Future<void> open(String room) async {
    _subscriptions
      ..add(transport.messages.listen(_onMessage))
      ..add(transport.presence.listen(_onPresence));
    await transport.connect(room);
    _announce();
  }

  void _announce() {
    final lobby = currentLobby;
    _lobby.add(lobby);
    transport.send({
      'type': 'lobby',
      'protocol': onlineProtocol,
      'started': started,
      ...lobby.toJson(),
    });
  }

  void _onPresence(Set<String> present) {
    _present = present;
    _everPresent.addAll(present);
    for (final (seat, player) in _players.indexed) {
      if (player.id == self.id) continue;
      if (present.contains(player.id)) {
        _absences.remove(player.id)?.cancel();
        _table?.setAutopilot(seat, on: false);
      } else if (started) {
        // A bot takes over if they are not back in time.
        _absences[player.id] ??= Timer(
          grace,
          () => _table?.setAutopilot(seat, on: true),
        );
      }
    }
    if (!started) {
      // Someone who left before the game started gives their place back.
      _players.removeWhere(
        (player) =>
            player.id != self.id &&
            _everPresent.contains(player.id) &&
            !present.contains(player.id),
      );
    }
    _announce();
  }

  void _onMessage(RoomMessage message) {
    final payload = message.payload;
    switch (payload['type']) {
      case 'hello':
        _onHello(message.from, payload);
      case 'sync':
        final seat = _seatOf(message.from);
        if (seat != null) _sendFeed(seat, from: payload['have'] as int? ?? 0);
      case 'answer':
        final seat = _seatOf(message.from);
        if (seat != null) _onAnswer(seat, payload);
    }
  }

  void _onHello(String id, Json payload) {
    if (payload['protocol'] != onlineProtocol) {
      transport.send({'type': 'refused', 'reason': 'version'}, to: id);
      return;
    }
    final known = _players.any((player) => player.id == id);
    if (!known) {
      if (started || _players.length >= capacity) {
        transport.send({
          'type': 'refused',
          'reason': started ? 'started' : 'full',
        }, to: id);
        return;
      }
      _players.add(
        RoomPlayer(
          id: id,
          name: payload['name'] as String? ?? '?',
          color: payload['color'] as int? ?? 0,
        ),
      );
    }
    _announce();
    // A guest who comes back mid-game gets everything again.
    final seat = _seatOf(id);
    if (seat != null && started) _sendFeed(seat, from: 0);
  }

  int? _seatOf(String id) {
    if (!started) return null;
    final seat = _players.indexWhere((player) => player.id == id);
    return seat > 0 ? seat : null;
  }

  /// How many bots may join the people of the room at most.
  int get botsRoom => maxPlayers - _players.length;

  /// Starts the game with whoever is in the room and [bots] bots more, and
  /// returns the host's own seat feed.
  SeatFeed start(Random random, {int bots = 0}) {
    final config = this.config = this.config.copyWith(
      seed: random.nextInt(1 << 32),
      players: (_players.length + bots).clamp(minPlayers, maxPlayers),
    );
    final table = _table = LocalTable(
      config: config,
      bot: bot,
      humanSeats: {for (var seat = 0; seat < _players.length; seat++) seat},
    );
    for (var seat = 1; seat < _players.length; seat++) {
      _logs[seat] = [];
      final feed = table.feedFor(seat);
      feed.onUpdate = () => _forward(seat, feed);
    }
    _announce();
    final own = table.feedFor(0);
    // The guests' feeds are opened with the host's: one game for everyone.
    for (var seat = 1; seat < _players.length; seat++) {
      _sendFeed(seat, from: 0);
    }
    return own;
  }

  /// Sends guest [seat] what its feed has in store.
  void _forward(int seat, SeatFeed feed) {
    final log = _logs[seat]!;
    final from = log.length;
    log.addAll(feed.takeEvents().map(eventToJson));
    _sendFeed(seat, from: from);
  }

  void _sendFeed(int seat, {required int from}) {
    final table = _table!;
    final log = _logs[seat]!;
    final start = from.clamp(0, log.length);
    final question = table.feedFor(seat).question;
    transport.send({
      'type': 'feed',
      'seating': Seating(
        config: table.config,
        seat: seat,
        people: _players,
      ).toJson(),
      'from': start,
      'events': log.sublist(start),
      'question': question == null ? null : questionToJson(question),
    }, to: _players[seat].id);
  }

  void _onAnswer(int seat, Json payload) {
    try {
      final answer = answerFromJson(payload['answer']! as Json);
      // Nobody answers for another seat.
      if (answer.seat != seat) return;
      _table!.feedFor(seat).answer(answer);
    } on Object {
      // Late, doubled or nonsense: the guest is told where things stand.
      _sendFeed(seat, from: _logs[seat]!.length);
    }
  }

  Future<void> close() async {
    for (final timer in _absences.values) {
      timer.cancel();
    }
    // First of all, and without waiting for anything: the guests must hear
    // of it even if the rest is cut short.
    transport.send({'type': 'closed'});
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    await transport.disconnect();
    await _lobby.close();
  }
}

/// A phone that joined a room: it shows what the host sends for its seat and
/// sends back its player's answers.
class OnlineGuest {
  OnlineGuest({
    required this.transport,
    required this.self,
    this.retry = const Duration(seconds: 2),
  });

  final RoomTransport transport;
  final RoomPlayer self;

  /// How long to wait for the host before asking again.
  final Duration retry;

  final _lobby = StreamController<Lobby>.broadcast();
  final _refused = StreamController<String>.broadcast();
  final _hostPresent = StreamController<bool>.broadcast();
  final _closed = Completer<void>();
  final List<StreamSubscription<Object?>> _subscriptions = [];
  final _started = Completer<(Seating, SeatFeed)>();
  Timer? _nudge;
  String? _hostId;
  Set<String>? _present;
  _RemoteFeed? _feed;

  /// Whether the host is connected, as far as this phone knows. True until
  /// it has been seen leaving.
  bool get hostIsPresent {
    final present = _present;
    final host = _hostId;
    return present == null || host == null || present.contains(host);
  }

  Stream<Lobby> get lobby => _lobby.stream;

  /// Why the host would not let this phone in: `full`, `started`, `version`.
  Stream<String> get refused => _refused.stream;

  /// Whether the host is connected: the game is paused while it is not.
  Stream<bool> get hostPresent => _hostPresent.stream;

  /// Completes when the host has ended the room.
  Future<void> get closed => _closed.future;

  /// Completes when the game starts, with who sits where and this seat's
  /// feed.
  Future<(Seating, SeatFeed)> get started => _started.future;

  Future<void> join(String room) async {
    _subscriptions
      ..add(transport.messages.listen(_onMessage))
      ..add(
        transport.presence.listen((present) {
          _present = present;
          _hostPresent.add(hostIsPresent);
        }),
      );
    await transport.connect(room);
    _hello();
    // Messages get lost: keep asking until the host has answered, and after
    // that whenever it has been silent for too long.
    _nudge = Timer.periodic(retry, (_) {
      final feed = _feed;
      if (feed == null) {
        _hello();
      } else if (feed.awaitingReply) {
        _sync();
      }
    });
  }

  void _hello() => transport.send({
    'type': 'hello',
    'protocol': onlineProtocol,
    'name': self.name,
    'color': self.color,
  });

  void _sync() => transport.send({
    'type': 'sync',
    'have': _feed?.received ?? 0,
  }, to: _hostId);

  void _onMessage(RoomMessage message) {
    final payload = message.payload;
    try {
      switch (payload['type']) {
        case 'lobby':
          if (payload['protocol'] != onlineProtocol) {
            _refused.add('version');
            return;
          }
          final lobby = Lobby.fromJson(payload);
          _hostId = lobby.hostId;
          _lobby.add(lobby);
        case 'refused':
          _refused.add(payload['reason'] as String? ?? 'full');
        case 'feed':
          _hostId ??= message.from;
          _onFeed(payload);
        case 'closed':
          if (!_closed.isCompleted) _closed.complete();
      }
    } on Object {
      // Nonsense from the network is no reason to stop.
    }
  }

  void _onFeed(Json payload) {
    final seating = Seating.fromJson(payload['seating']! as Json);
    final feed = _feed ??= _RemoteFeed(
      seating.config,
      seating.seat,
      (answer) => transport.send({
        'type': 'answer',
        'answer': answerToJson(answer),
      }, to: _hostId),
    );
    if (!_started.isCompleted) _started.complete((seating, feed));
    final from = payload['from']! as int;
    if (from > feed.received) {
      // Something was missed: ask for it again.
      _sync();
      return;
    }
    final events = (payload['events']! as List).cast<Json>();
    final question = payload['question'] as Json?;
    feed.receive([
      // What was already received is skipped.
      for (final event in events.skip(feed.received - from))
        eventFromJson(event),
    ], question == null ? null : questionFromJson(question));
  }

  Future<void> leave() async {
    _nudge?.cancel();
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    await transport.disconnect();
    await _lobby.close();
    await _refused.close();
    await _hostPresent.close();
  }
}

/// A seat's feed fed by the host over the network.
class _RemoteFeed implements SeatFeed {
  _RemoteFeed(this.config, this.seat, this._send);

  final void Function(Answer answer) _send;
  final List<Event> _events = [];
  void Function()? _onUpdate;
  Question? _question;

  /// How many events of the game this seat has received so far.
  int received = 0;

  /// True from an answer until the host is heard from again.
  bool awaitingReply = false;

  @override
  final GameConfig config;

  @override
  final int seat;

  void receive(List<Event> events, Question? question) {
    awaitingReply = false;
    received += events.length;
    _events.addAll(events);
    _question = question;
    _onUpdate?.call();
  }

  @override
  void open() {}

  @override
  List<Event> takeEvents() {
    final events = List.of(_events);
    _events.clear();
    return events;
  }

  @override
  Question? get question => _question;

  @override
  void answer(Answer answer) {
    // Until the host says otherwise, the question is taken as answered.
    _question = null;
    awaitingReply = true;
    _send(answer);
  }

  @override
  set onUpdate(void Function()? callback) => _onUpdate = callback;

  @override
  set onError(void Function(Object error)? callback) {}

  @override
  void acknowledgeEnd(GameFinished result) {}

  @override
  void close() => _onUpdate = null;
}
