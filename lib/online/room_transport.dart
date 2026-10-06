import 'dart:async';

typedef Json = Map<String, Object?>;

/// A message received in a room, and who sent it.
final class RoomMessage {
  const RoomMessage(this.from, this.payload);

  final String from;
  final Json payload;
}

/// How the phones of a room talk to each other. Delivery is not guaranteed:
/// whoever uses it must cope with a message that never arrives.
abstract interface class RoomTransport {
  /// What this phone is known as in a room.
  String get selfId;

  /// Messages sent to everyone, or to this phone alone.
  Stream<RoomMessage> get messages;

  /// Who is connected to the room right now, this phone included.
  Stream<Set<String>> get presence;

  Future<void> connect(String room);

  /// Sends [payload] to [to], or to everyone else in the room.
  void send(Json payload, {String? to});

  Future<void> disconnect();
}

/// Rooms that live in memory, for tests: every transport made by the same
/// hub can reach the others.
class MemoryRoomHub {
  final Map<String, Map<String, MemoryRoomTransport>> _rooms = {};

  MemoryRoomTransport transport(String id) => MemoryRoomTransport._(this, id);

  void _presenceChanged(String room) {
    final members = _rooms[room] ?? const {};
    final ids = members.keys.toSet();
    for (final member in members.values.toList()) {
      member._presence.add(ids);
    }
  }
}

class MemoryRoomTransport implements RoomTransport {
  MemoryRoomTransport._(this._hub, this.selfId);

  final MemoryRoomHub _hub;
  final _messages = StreamController<RoomMessage>.broadcast();
  final _presence = StreamController<Set<String>>.broadcast();
  String? _room;

  /// When true, what this phone sends is lost, as on a bad connection.
  bool dropOutgoing = false;

  @override
  final String selfId;

  @override
  Stream<RoomMessage> get messages => _messages.stream;

  @override
  Stream<Set<String>> get presence => _presence.stream;

  @override
  Future<void> connect(String room) async {
    _room = room;
    (_hub._rooms[room] ??= {})[selfId] = this;
    _hub._presenceChanged(room);
  }

  @override
  void send(Json payload, {String? to}) {
    final room = _room;
    if (room == null || dropOutgoing) return;
    final members = _hub._rooms[room] ?? const {};
    for (final member in members.values.toList()) {
      if (member.selfId == selfId) continue;
      if (to != null && member.selfId != to) continue;
      // As a network would: later, and as a copy.
      scheduleMicrotask(() {
        if (member._room == room && !member._messages.isClosed) {
          member._messages.add(RoomMessage(selfId, Map.of(payload)));
        }
      });
    }
  }

  @override
  Future<void> disconnect() async {
    final room = _room;
    if (room == null) return;
    _room = null;
    _hub._rooms[room]?.remove(selfId);
    _hub._presenceChanged(room);
  }
}
