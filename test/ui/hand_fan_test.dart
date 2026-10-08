import 'package:flutter/material.dart' hide Card;
import 'package:flutter_test/flutter_test.dart';
import 'package:skull_kings/engine/engine.dart';
import 'package:skull_kings/ui/cards/hand_fan.dart';

void main() {
  testWidgets('with no legal list, a tap selects via onTap (pre-turn)', (
    tester,
  ) async {
    final card = const Card.number(Suit.green, 3);
    Card? tapped;
    Card? inspected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HandFan(
            cards: [card],
            onTap: (c) => tapped = c,
            onInspect: (c) => inspected = c,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(Key('hand-${card.id}')));
    await tester.pump();

    expect(tapped, card);
    expect(inspected, isNull);
  });

  testWidgets('with a legal list, an illegal card uses onInspect', (
    tester,
  ) async {
    final legal = const Card.number(Suit.green, 3);
    final other = const Card.number(Suit.yellow, 2);
    Card? tapped;
    Card? inspected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HandFan(
            cards: [legal, other],
            legal: [legal],
            onTap: (c) => tapped = c,
            onInspect: (c) => inspected = c,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(Key('hand-${other.id}')));
    await tester.pump();

    expect(inspected, other);
    expect(tapped, isNull);
  });
}
