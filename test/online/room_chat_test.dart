import 'package:flutter_test/flutter_test.dart';
import 'package:skull_kings/online/room_chat.dart';
import 'package:skull_kings/online/room_transport.dart';

Future<void> pause() => Future<void>.delayed(Duration.zero);

void main() {
  late MemoryRoomHub hub;
  late RoomChat anne;
  late RoomChat bob;

  setUp(() async {
    hub = MemoryRoomHub();
    final a = hub.transport('a');
    final b = hub.transport('b');
    await a.connect('ROOM');
    await b.connect('ROOM');
    anne = RoomChat(transport: a, selfId: 'a');
    bob = RoomChat(transport: b, selfId: 'b');
  });

  tearDown(() {
    anne.dispose();
    bob.dispose();
  });

  test('a line written by one is read by the other, and counted unread '
      'until the chat is opened', () async {
    anne.send('  Yo-ho-ho !  ', fromName: 'Anne');
    await pause();

    expect(anne.lines.single.text, 'Yo-ho-ho !');
    expect(bob.lines.single.fromName, 'Anne');
    expect(bob.unread, 1);
    expect(anne.unread, 0);

    bob.markOpen(true);
    expect(bob.unread, 0);
  });

  test('a reaction is seen by everyone at the table, whoever pulled it '
      'included, and is no line of the chat', () async {
    final seenByAnne = <Reaction>[];
    final seenByBob = <Reaction>[];
    anne.reactions.listen(seenByAnne.add);
    bob.reactions.listen(seenByBob.add);

    anne.react('👍', fromName: 'Anne');
    await pause();

    expect(seenByAnne.single.emoji, '👍');
    expect(seenByBob.single.emoji, '👍');
    expect(seenByBob.single.fromName, 'Anne');
    expect(seenByBob.single.fromId, 'a');
    expect(bob.lines, isEmpty);
    expect(bob.unread, 0);
  });

  test('only the faces of the menu go round: anything else is dropped, '
      'sent or received', () async {
    final seen = <Reaction>[];
    bob.reactions.listen(seen.add);
    anne.reactions.listen(seen.add);

    anne.react('not an emoji', fromName: 'Anne');
    hub.transport('c')
      ..connect('ROOM')
      ..send({'type': 'reaction', 'name': 'Eve', 'emoji': '<b>boo</b>'})
      ..send({'type': 'reaction', 'name': 'Eve', 'emoji': 3});
    await pause();

    expect(seen, isEmpty);
  });
}
