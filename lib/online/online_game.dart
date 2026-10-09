import 'dart:async';
import 'dart:math';

import '../bots/bot.dart';
import '../engine/engine.dart';
import '../game/local_table.dart';
import '../game/seat_feed.dart';
import 'room_transport.dart';

/// Bumped whenever phones of different versions could no longer play the
/// same game together.
const onlineProtocol = 4;

/// How long an absent player is waited for before a bot plays in their place.
const absenceGrace = Duration(seconds: 30);

/// How long a guest may vanish from presence before the lobby drops them.
/// Presence flaps right after hello; without this the host loses the guest.
/// Longer than a guest's hello retry, so that a phone presence has lost but
/// which still talks is always heard in time.
const defaultLobbyGrace = Duration(seconds: 5);

/// Reads a wire integer that may arrive as [int] or [num] (JSON / JS).
int? onlineInt(Object? value) => switch (value) {
  final int n => n,
  final num n => n.toInt(),
  _ => null,
};

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
    color: onlineInt(json['color']) ?? 0,
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

/// Who sits where, once the game has started: each scoring seat holds a
/// person or a bot (`null`). Order is shuffled when the host starts.
final class Seating {
  const Seating({
    required this.config,
    required this.seat,
    required this.occupants,
  });

  factory Seating.fromJson(Json json) {
    final config = GameConfig.fromJson(json['config']! as Json);
    final raw =
        json['occupants'] as List? ?? json['people'] as List? ?? const [];
    // Older hosts sent people packed at the front; pad with bots.
    final packed = [
      for (final entry in raw)
        entry == null ? null : RoomPlayer.fromJson(entry as Json),
    ];
    return Seating(
      config: config,
      seat: onlineInt(json['seat'])!,
      occupants: [
        for (var seat = 0; seat < config.players; seat++)
          seat < packed.length ? packed[seat] : null,
      ],
    );
  }

  final GameConfig config;

  /// The seat of the phone this was sent to.
  final int seat;

  /// One entry per scoring seat: a person, or null for a bot.
  final List<RoomPlayer?> occupants;

  /// The person at [seat], if any.
  RoomPlayer? occupantAt(int seat) =>
      seat >= 0 && seat < occupants.length ? occupants[seat] : null;

  /// People only, in seat order — kept for callers that list humans.
  List<RoomPlayer> get people => [
    for (final occupant in occupants)
      if (occupant != null) occupant,
  ];

  Json toJson() => {
    'config': config.toJson(),
    'seat': seat,
    'occupants': [for (final occupant in occupants) occupant?.toJson()],
  };
}

/// What becomes of the seat of a player who dropped out of a started game.
enum AbsenceState {
  /// A bot takes the seat when [Absence.until] comes.
  counting,

  /// The host said to wait: nobody plays the seat until its player is back,
  /// or the host changes their mind.
  held,

  /// A bot plays the seat until its player is back.
  replaced,
}

/// A player of a started game who is not connected.
final class Absence {
  const Absence({
    required this.id,
    required this.name,
    required this.state,
    this.until,
  });

  final String id;
  final String name;
  final AbsenceState state;

  /// When a bot takes over, while [state] is [AbsenceState.counting].
  final DateTime? until;

  /// As sent to the guests: the time left rather than a moment, since two
  /// phones never quite agree on what time it is.
  Json toJson(DateTime now) => {
    'id': id,
    'name': name,
    'state': state.name,
    if (until case final until?) 'left': until.difference(now).inMilliseconds,
  };

  static Absence fromJson(Json json, DateTime now) => Absence(
    id: json['id']! as String,
    name: json['name']! as String,
    state: AbsenceState.values.byName(json['state']! as String),
    until: switch (json['left']) {
      final int left => now.add(Duration(milliseconds: left)),
      _ => null,
    },
  );
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
    this.lobbyGrace = defaultLobbyGrace,
    this.capacity = maxPlayers,
  }) {
    _players.add(self);
  }

  final RoomTransport transport;
  final RoomPlayer self;
  final Bot bot;
  final Duration grace;

  /// Delay before a presence gap drops a guest from the lobby.
  final Duration lobbyGrace;

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

  /// Who sits where once the game has started (bots as null).
  List<RoomPlayer?> _occupants = const [];

  /// For each human seat, every event sent to it so far, as JSON.
  final Map<int, List<Json>> _logs = {};

  /// The players of the started game who are away, and the timer that puts
  /// a bot on the seat of each one still counted down.
  final Map<String, Absence> _away = {};
  final Map<String, Timer> _absences = {};
  final Map<String, Timer> _lobbyLeaves = {};
  final _absent = StreamController<List<Absence>>.broadcast();

  void _cancelLobbyLeave(String id) {
    _lobbyLeaves.remove(id)?.cancel();
  }

  /// Who is away, each time that changes.
  Stream<List<Absence>> get absences => _absent.stream;

  List<Absence> get currentAbsences => List.unmodifiable(_away.values);

  void _setAbsence(RoomPlayer player, AbsenceState? state) {
    _absences.remove(player.id)?.cancel();
    final seat = _seatOf(player.id);
    if (seat == null) return;
    if (state == null) {
      _away.remove(player.id);
    } else {
      DateTime? until;
      if (state == AbsenceState.counting) {
        until = DateTime.now().add(grace);
        _absences[player.id] = Timer(
          grace,
          () => _setAbsence(player, AbsenceState.replaced),
        );
      }
      _away[player.id] = Absence(
        id: player.id,
        name: player.name,
        state: state,
        until: until,
      );
    }
    _table?.setAutopilot(seat, on: state == AbsenceState.replaced);
    final list = currentAbsences;
    if (!_absent.isClosed) _absent.add(list);
    final now = DateTime.now();
    transport.send({
      'type': 'absences',
      'list': [for (final absence in list) absence.toJson(now)],
    });
  }

  RoomPlayer? _guest(String id) =>
      _players.where((player) => player.id == id && id != self.id).firstOrNull;

  /// The host knows [id] is coming back: no bot takes the seat meanwhile.
  void keepWaiting(String id) {
    final player = _guest(id);
    if (player != null && _away.containsKey(id)) {
      _setAbsence(player, AbsenceState.held);
    }
  }

  /// A bot takes the seat of [id] now, until they are back.
  void replaceNow(String id) {
    final player = _guest(id);
    if (player != null && _away.containsKey(id)) {
      _setAbsence(player, AbsenceState.replaced);
    }
  }

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

  /// Who sits where after [start], bots as null.
  List<RoomPlayer?> get currentOccupants => List.unmodifiable(_occupants);

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
    if (started) {
      _checkAbsences();
    } else {
      // Presence often blanks a guest for a moment after hello: wait before
      // giving their place back, and cancel if they reappear or say hello.
      for (final player in List.of(_players)) {
        if (player.id == self.id) continue;
        if (present.contains(player.id)) {
          _cancelLobbyLeave(player.id);
        } else if (_everPresent.contains(player.id)) {
          _lobbyLeaves.putIfAbsent(
            player.id,
            // Still pending means neither seen again nor heard from.
            () => Timer(lobbyGrace, () {
              _lobbyLeaves.remove(player.id);
              _players.removeWhere((p) => p.id == player.id);
              _announce();
            }),
          );
        }
      }
    }
    _announce();
  }

  /// Starts or ends the absence of each player of the started game, from
  /// who is present.
  void _checkAbsences() {
    for (final player in _players) {
      if (player.id == self.id) continue;
      if (_present.contains(player.id)) {
        if (_away.containsKey(player.id)) _setAbsence(player, null);
      } else if (!_away.containsKey(player.id) &&
          _everPresent.contains(player.id)) {
        // A bot takes over if they are not back in time — unless the host
        // says otherwise.
        _setAbsence(player, AbsenceState.counting);
      }
    }
  }

  void _onMessage(RoomMessage message) {
    final payload = message.payload;
    try {
      switch (payload['type']) {
        case 'hello':
          _onHello(message.from, payload);
        case 'sync':
          final seat = _seatOf(message.from);
          if (seat != null) {
            _sendFeed(seat, from: onlineInt(payload['have']) ?? 0);
          }
        case 'answer':
          final seat = _seatOf(message.from);
          if (seat != null) _onAnswer(seat, payload);
      }
    } on Object {
      // A bad wire message must not stop the host hearing the next hello.
    }
  }

  void _onHello(String id, Json payload) {
    if (onlineInt(payload['protocol']) != onlineProtocol) {
      transport.send({'type': 'refused', 'reason': 'version'}, to: id);
      return;
    }
    _cancelLobbyLeave(id);
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
          color: onlineInt(payload['color']) ?? 0,
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
    final seat = _occupants.indexWhere((player) => player?.id == id);
    return seat >= 0 ? seat : null;
  }

  /// How many bots may join the people of the room at most.
  int get botsRoom => maxPlayers - _players.length;

  /// Starts the game with whoever is in the room and [bots] bots more, and
  /// returns the host's own seat feed. Seat order is shuffled so humans and
  /// bots are mixed and the host is not always first.
  SeatFeed start(Random random, {int bots = 0}) {
    final config = this.config = this.config.copyWith(
      seed: SeededRandom.newSeed(random),
      players: (_players.length + bots).clamp(minPlayers, maxPlayers),
    );
    final occupants = <RoomPlayer?>[
      ..._players,
      for (var i = 0; i < config.players - _players.length; i++) null,
    ]..shuffle(random);
    _occupants = occupants;
    final humanSeats = {
      for (final (seat, person) in occupants.indexed)
        if (person != null) seat,
    };
    final hostSeat = occupants.indexWhere((person) => person?.id == self.id);
    final table = _table = LocalTable(
      config: config,
      bot: bot,
      humanSeats: humanSeats,
      primarySeat: hostSeat,
    );
    for (final seat in humanSeats) {
      if (seat == hostSeat) continue;
      _logs[seat] = [];
      final feed = table.feedFor(seat);
      feed.onUpdate = () => _forward(seat, feed);
    }
    _announce();
    final own = table.feedFor(hostSeat);
    for (final seat in humanSeats) {
      if (seat == hostSeat) continue;
      _sendFeed(seat, from: 0);
    }
    // Someone who left a moment ago is still listed: from here on they are
    // waited for like anyone who drops out of the game.
    for (final timer in _lobbyLeaves.values) {
      timer.cancel();
    }
    _lobbyLeaves.clear();
    _checkAbsences();
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
    final person = _occupants[seat]!;
    transport.send({
      'type': 'feed',
      'seating': Seating(
        config: table.config,
        seat: seat,
        occupants: _occupants,
      ).toJson(),
      'from': start,
      'events': log.sublist(start),
      'question': question == null ? null : questionToJson(question),
    }, to: person.id);
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
    for (final timer in _lobbyLeaves.values) {
      timer.cancel();
    }
    _lobbyLeaves.clear();
    // First of all, and without waiting for anything: the guests must hear
    // of it even if the rest is cut short.
    transport.send({'type': 'closed'});
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    await transport.disconnect();
    await _lobby.close();
    await _absent.close();
  }
}

/// A phone that joined a room: it shows what the host sends for its seat and
/// sends back its player's answers.
class OnlineGuest {
  OnlineGuest({
    required this.transport,
    required this.self,
    this.retry = const Duration(seconds: 2),
    this.patience = const Duration(seconds: 6),
  });

  final RoomTransport transport;
  final RoomPlayer self;

  /// How long to wait for the host before asking again.
  final Duration retry;

  /// How long nobody may answer before the room is taken not to exist: any
  /// code opens a channel, so silence is the only sign of a wrong one.
  final Duration patience;

  final _lobby = StreamController<Lobby>.broadcast();
  final _refused = StreamController<String>.broadcast();
  final _hostPresent = StreamController<bool>.broadcast();
  final _absent = StreamController<List<Absence>>.broadcast();

  /// Who is away from the started game, as the host last said.
  Stream<List<Absence>> get absences => _absent.stream;
  final _closed = Completer<void>();
  final List<StreamSubscription<Object?>> _subscriptions = [];
  final _started = Completer<(Seating, SeatFeed)>();
  Timer? _nudge;
  Timer? _silence;
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

  /// Why this phone is not let in: `full`, `started` or `version` when the
  /// host said so, `unknown` when no host ever answered under this code.
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
    _silence = Timer(patience, () {
      if (!_refused.isClosed) _refused.add('unknown');
    });
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
        case 'lobby' || 'refused' || 'feed':
          // Someone holds this room.
          _silence?.cancel();
      }
      switch (payload['type']) {
        case 'lobby':
          if (onlineInt(payload['protocol']) != onlineProtocol) {
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
        case 'absences':
          final now = DateTime.now();
          _absent.add([
            for (final absence in payload['list']! as List)
              Absence.fromJson(absence as Json, now),
          ]);
        case 'closed':
          if (!_closed.isCompleted) _closed.complete();
      }
    } on Object {
      // Nonsense from the network is no reason to stop.
    }
  }

  void _onFeed(Json payload) {
    final seating = Seating.fromJson(payload['seating']! as Json);
    final from = onlineInt(payload['from'])!;
    final feed = _feed ??= _RemoteFeed(
      seating.config,
      seating.seat,
      (answer) => transport.send({
        'type': 'answer',
        'answer': answerToJson(answer),
      }, to: _hostId),
    );
    if (!_started.isCompleted) _started.complete((seating, feed));
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
    _silence?.cancel();
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    await transport.disconnect();
    await _lobby.close();
    await _refused.close();
    await _hostPresent.close();
    await _absent.close();
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
  void finishEarly() {
    // Only the host's local table may end the game early.
  }

  @override
  void close() => _onUpdate = null;
}
