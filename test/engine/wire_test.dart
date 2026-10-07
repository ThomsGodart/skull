import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:skull_kings/engine/engine.dart';

/// [json] after a trip through text, as it would cross a network.
Map<String, Object?> wired(Map<String, Object?> json) =>
    jsonDecode(jsonEncode(json)) as Map<String, Object?>;

void main() {
  const config = GameConfig(
    players: 5,
    seed: 3,
    kraken: true,
    whiteWhale: true,
    loot: true,
    piratePowers: true,
    scoring: Scoring.rascal,
  );

  test('every event of whole games, with every option, comes back the same '
      'from JSON', () {
    final kinds = <Type>{};
    for (var seed = 0; seed < 25; seed++) {
      final game = Game(config.copyWith(seed: seed));
      final random = Random(seed);
      void check() {
        for (final event in game.takeEvents()) {
          final json = eventToJson(event);
          final back = eventFromJson(wired(json));
          expect(back.runtimeType, event.runtimeType);
          expect(back.audience, event.audience);
          expect(eventToJson(back), json);
          kinds.add(event.runtimeType);
        }
      }

      check();
      while (game.pending.isNotEmpty) {
        game.answer(randomAnswer(game.pending.first, random));
        check();
      }
    }
    expect(kinds, hasLength(16), reason: 'every kind of event was seen');
  });

  test('every question comes back the same from JSON', () {
    final kinds = <Type>{};
    for (var seed = 0; seed < 25; seed++) {
      final game = Game(config.copyWith(seed: seed));
      final random = Random(seed);
      while (game.pending.isNotEmpty) {
        for (final question in game.pending) {
          final json = questionToJson(question);
          final back = questionFromJson(wired(json));
          expect(back.runtimeType, question.runtimeType);
          expect(back.seat, question.seat);
          expect(questionToJson(back), json);
          kinds.add(question.runtimeType);
        }
        game.answer(randomAnswer(game.pending.first, random));
      }
    }
    expect(kinds, hasLength(6));
  });

  test('what does not describe an event or a question is refused', () {
    expect(() => eventFromJson({'type': 'earthquake'}), throwsFormatException);
    expect(() => eventFromJson({'type': 'cardPlayed'}), throwsFormatException);
    expect(() => questionFromJson({'type': 'riddle'}), throwsFormatException);
  });
}
