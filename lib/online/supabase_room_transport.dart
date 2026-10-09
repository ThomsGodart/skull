import 'dart:async';

import 'package:supabase/supabase.dart';

import 'room_transport.dart';

/// Rooms carried by Supabase Realtime: one channel per room, on which every
/// phone broadcasts and announces its presence.
///
/// Every message of a room travels on the same channel, with the phone it is
/// meant for written on it; the others drop it unread. Someone who rewrote
/// the app could read them: this is for games among friends.
class SupabaseRoomTransport implements RoomTransport {
  SupabaseRoomTransport(this._client, this.selfId);

  final SupabaseClient _client;
  final _messages = StreamController<RoomMessage>.broadcast();
  final _presence = StreamController<Set<String>>.broadcast();
  RealtimeChannel? _channel;

  static const _event = 'message';

  @override
  final String selfId;

  @override
  Stream<RoomMessage> get messages => _messages.stream;

  @override
  Stream<Set<String>> get presence => _presence.stream;

  @override
  Future<void> connect(String room) {
    final joined = Completer<void>();
    final channel = _channel = _client.channel(
      'skull-kings:$room',
      opts: RealtimeChannelConfig(key: selfId),
    );
    channel
        .onBroadcast(event: _event, callback: _onBroadcast)
        .onPresenceSync((_) => _presence.add(_present(channel)))
        .subscribe((status, error) async {
          switch (status) {
            case RealtimeSubscribeStatus.subscribed:
              // Also after a reconnection: say again that this phone is here.
              await channel.track({'id': selfId});
              if (!joined.isCompleted) joined.complete();
            case RealtimeSubscribeStatus.channelError ||
                RealtimeSubscribeStatus.timedOut:
              if (!joined.isCompleted) {
                joined.completeError(
                  StateError('could not join the room: ${error ?? status}'),
                );
              }
            case RealtimeSubscribeStatus.closed:
          }
        });
    return joined.future;
  }

  static Set<String> _present(RealtimeChannel channel) => {
    for (final state in channel.presenceState()) state.key,
  };

  void _onBroadcast(Map<String, dynamic> message) {
    final received = roomMessageFrom(message, selfId: selfId);
    if (received != null) _messages.add(received);
  }

  @override
  void send(Json payload, {String? to}) {
    // Lost messages are expected and made up for by whoever sends them.
    unawaited(
      _channel
          ?.sendBroadcastMessage(
            event: _event,
            payload: {'from': selfId, 'to': to, 'body': payload},
          )
          .catchError((Object _) => ChannelResponse.error),
    );
  }

  @override
  Future<void> disconnect() async {
    final channel = _channel;
    _channel = null;
    if (channel != null) await _client.removeChannel(channel);
  }
}

/// The room message a broadcast carries for [selfId], or null when it is
/// meant for another phone or is not one of ours.
///
/// A broadcast sent over the socket arrives as it was sent. The client
/// falls back to REST while its channel is rejoining, and such a broadcast
/// may arrive wrapped under `payload`: both are read.
RoomMessage? roomMessageFrom(
  Map<String, dynamic> broadcast, {
  required String selfId,
}) {
  final Map<Object?, Object?> envelope = switch (broadcast['payload']) {
    final Map<Object?, Object?> inner when broadcast['from'] == null => inner,
    _ => broadcast,
  };
  final from = envelope['from'];
  final to = envelope['to'];
  final body = envelope['body'];
  if (from is! String || body is! Map) return null;
  if (to != null && to != selfId) return null;
  return RoomMessage(from, {
    for (final entry in body.entries)
      if (entry.key is String) entry.key as String: entry.value,
  });
}
