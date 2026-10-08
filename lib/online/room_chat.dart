import 'dart:async';

import 'package:flutter/foundation.dart';

import 'room_transport.dart';

/// One line of the in-game chat.
final class ChatLine {
  const ChatLine({
    required this.fromId,
    required this.fromName,
    required this.text,
    required this.at,
  });

  final String fromId;
  final String fromName;
  final String text;
  final DateTime at;
}

/// A small chat shared by everyone in an online room.
class RoomChat extends ChangeNotifier {
  RoomChat({required this.transport, required this.selfId, this.selfName = ''}) {
    _subscription = transport.messages.listen(_onMessage);
  }

  final RoomTransport transport;
  final String selfId;
  String selfName;

  final List<ChatLine> _lines = [];
  int _unread = 0;
  bool _open = false;
  StreamSubscription<RoomMessage>? _subscription;

  List<ChatLine> get lines => List.unmodifiable(_lines);
  int get unread => _unread;

  void markOpen(bool open) {
    _open = open;
    if (open && _unread != 0) {
      _unread = 0;
      notifyListeners();
    }
  }

  void send(String text, {required String fromName}) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final line = ChatLine(
      fromId: selfId,
      fromName: fromName,
      text: trimmed,
      at: DateTime.now(),
    );
    _lines.add(line);
    transport.send({
      'type': 'chat',
      'name': fromName,
      'text': trimmed,
    });
    notifyListeners();
  }

  void _onMessage(RoomMessage message) {
    final payload = message.payload;
    if (payload['type'] != 'chat') return;
    final text = (payload['text'] as String?)?.trim() ?? '';
    if (text.isEmpty) return;
    _lines.add(
      ChatLine(
        fromId: message.from,
        fromName: payload['name'] as String? ?? '?',
        text: text,
        at: DateTime.now(),
      ),
    );
    if (!_open) _unread++;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
