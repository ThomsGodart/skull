import 'package:flutter_test/flutter_test.dart';
import 'package:skull_kings/engine/engine.dart';

import 'support.dart';

void main() {
  test(
    'holding the lead suit, a player may only play it or a special card',
    () {
      final hand = [g(3), g(9), y(5), b(2), pirate(), esc()];

      final legal = legalCards(hand, trick([g(7)]));

      expect(legal, [g(3), g(9), pirate(), esc()]);
    },
  );

  test('without the lead suit, any card may be played, trump included', () {
    final hand = [y(5), b(2), p(14), esc()];

    expect(legalCards(hand, trick([g(7)])), hand);
  });

  test('the player who leads may play any card', () {
    final hand = [g(3), y(5), pirate()];

    expect(legalCards(hand, const []), hand);
  });

  test('an escape that leads leaves the next number card to set the suit', () {
    final hand = [g(3), y(5), b(2)];

    expect(legalCards(hand, trick([esc(), y(9)])), [y(5)]);
  });

  test(
    'a tigress led as an escape leaves the next number card to set the suit',
    () {
      final hand = [g(3), y(5)];

      final legal = legalCards(
        hand,
        trick([tigress, y(9)], tigressAs: TigressMode.escape),
      );

      expect(legal, [y(5)]);
    },
  );

  test('when a character leads there is no suit to follow', () {
    final hand = [g(3), y(5), b(2)];

    for (final lead in [pirate(), mermaid(), skullKing]) {
      expect(legalCards(hand, trick([lead, y(9)])), hand, reason: '$lead');
    }
  });

  test('a tigress led as a pirate means there is no suit to follow', () {
    final hand = [g(3), y(5)];

    final legal = legalCards(
      hand,
      trick([tigress, y(9)], tigressAs: TigressMode.pirate),
    );

    expect(legal, hand);
  });

  test('a character played after an escape, before any number card, '
      'means there is no suit to follow', () {
    final hand = [g(3), y(5)];

    expect(legalCards(hand, trick([esc(), pirate(), y(9)])), hand);
  });

  test('a character played after the suit is set does not lift it', () {
    final hand = [g(3), y(5)];

    expect(legalCards(hand, trick([y(9), pirate()])), [y(5)]);
  });

  test('the lead suit of a trick is the suit players must follow, if any', () {
    expect(leadSuit(trick([esc(), y(9), g(3)])), Suit.yellow);
    expect(leadSuit(trick([pirate(), y(9)])), isNull);
    expect(leadSuit(const []), isNull);
  });
}
