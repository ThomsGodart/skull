import 'package:flutter/material.dart' hide Card;
import 'package:flutter_test/flutter_test.dart';
import 'package:skull_kings/engine/engine.dart';
import 'package:skull_kings/online/room_chat.dart';
import 'package:skull_kings/ui/cards/card_look.dart';
import 'package:skull_kings/ui/cards/card_view.dart';

void main() {
  Future<void> show(WidgetTester tester, Card card) => tester.pumpWidget(
    MaterialApp(home: Center(child: CardView(card, width: 80))),
  );

  final deck = deckFor(
    const GameConfig(players: 4, seed: 0, secondExpansion: true),
  );

  testWidgets('a 14 shows what it is worth to whoever takes it: +10, and '
      '+20 for the black one', (tester) async {
    await show(tester, const Card.number(Suit.yellow, 14));
    expect(find.text('+10'), findsNWidgets(2));

    await show(tester, const Card.number(Suit.black, 14));
    expect(find.text('+20'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('the extra 7 and 8 still show theirs, and a card worth '
      'nothing shows none', (tester) async {
    final extraEight = deck.firstWhere((c) => c.isExtraNumber && c.value == 8);
    final extraSeven = deck.firstWhere((c) => c.isExtraNumber && c.value == 7);
    await show(tester, extraEight);
    expect(find.text('+5'), findsNWidgets(2));
    await show(tester, extraSeven);
    expect(find.text('-5'), findsNWidgets(2));

    // A plain 13, and a 0/14, which earns nothing even played as a 14.
    final worthless = [
      const Card.number(Suit.green, 13),
      deck.firstWhere((card) => card.kind == CardKind.zeroFourteen),
    ];
    for (final card in worthless) {
      await show(tester, card);
      expect(find.textContaining('+'), findsNothing, reason: '$card');
    }
  });

  test('the tigress is red enough not to be taken for a yellow card, and '
      'is not the pirates\' red either', () {
    final tigress = deck.firstWhere((card) => card.kind == CardKind.tigress);
    final pirate = deck.firstWhere((card) => card.kind == CardKind.pirate);
    double hue(Card card) => HSLColor.fromColor(CardLook.of(card).color).hue;

    final yellow = hue(const Card.number(Suit.yellow, 1));
    expect((hue(tigress) - yellow).abs(), greaterThan(25));
    expect(hue(tigress), lessThan(20), reason: 'towards red');
    expect(CardLook.of(tigress).color, isNot(CardLook.of(pirate).color));
  });

  test('the emojis on offer are all different, and say more than faces', () {
    expect(RoomChat.emojis.toSet(), hasLength(RoomChat.emojis.length));
    expect(RoomChat.emojis, containsAll(['👍', '👎', '👋', '🙏', '😇']));
    expect(RoomChat.emojis.length, greaterThanOrEqualTo(16));
  });
}
