import 'package:flutter_test/flutter_test.dart';
import 'package:skull_kings/online/supabase_room_transport.dart';

void main() {
  const envelope = {
    'from': 'host',
    'to': 'g1',
    'body': {'type': 'hello', 'protocol': 3},
  };

  test('a broadcast as it was sent is read', () {
    final message = roomMessageFrom({
      ...envelope,
      'type': 'broadcast',
      'event': 'message',
    }, selfId: 'g1')!;

    expect(message.from, 'host');
    expect(message.payload, {'type': 'hello', 'protocol': 3});
  });

  test('a broadcast wrapped under payload is read the same', () {
    final message = roomMessageFrom({
      'type': 'broadcast',
      'event': 'message',
      'payload': envelope,
    }, selfId: 'g1')!;

    expect(message.from, 'host');
    expect(message.payload, {'type': 'hello', 'protocol': 3});
  });

  test('a broadcast for another phone is dropped, wrapped or not', () {
    expect(roomMessageFrom(envelope, selfId: 'g2'), isNull);
    expect(roomMessageFrom({'payload': envelope}, selfId: 'g2'), isNull);
  });

  test('a broadcast to everyone is read by anyone', () {
    final toAll = {...envelope}..remove('to');
    expect(roomMessageFrom(toAll, selfId: 'g2'), isNotNull);
  });

  test('anything else is dropped', () {
    expect(roomMessageFrom({'event': 'message'}, selfId: 'g1'), isNull);
    expect(
      roomMessageFrom({'from': 'host', 'body': 'text'}, selfId: 'g1'),
      isNull,
    );
  });
}
