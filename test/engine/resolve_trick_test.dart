import 'package:flutter_test/flutter_test.dart';
import 'package:skull_kings/engine/engine.dart';

import 'support.dart';

/// The seat that wins [cards], seat i having played `cards[i]`.
int winner(List<Card> cards, {TigressMode? tigressAs}) =>
    resolveTrick(trick(cards, tigressAs: tigressAs)).winner;

List<Bonus> bonuses(List<Card> cards, {TigressMode? tigressAs}) =>
    resolveTrick(trick(cards, tigressAs: tigressAs)).bonuses;

void main() {
  group('winner', () {
    test('the highest card of the lead suit wins', () {
      // Rulebook: 7 green, 12 green, 8 green.
      expect(winner([g(7), g(12), g(8)]), 1);
    });

    test('a card of another base suit never wins', () {
      // Rulebook: 12 yellow, 5 yellow, 14 purple.
      expect(winner([y(12), y(5), p(14)]), 0);
    });

    test('trump beats any base suit, whatever its value', () {
      // Rulebook: 12 yellow, 5 yellow, 2 black.
      expect(winner([y(12), y(5), b(2)]), 2);
    });

    test('the highest trump wins', () {
      expect(winner([y(12), b(2), b(9)]), 2);
    });

    test('an escape loses to any number card', () {
      expect(winner([esc(), g(1), esc(2)]), 1);
    });

    test('when everyone plays an escape, the first one wins', () {
      expect(
        winner([esc(), tigress, esc(2)], tigressAs: TigressMode.escape),
        0,
      );
    });

    test('a pirate beats every number card, trump included', () {
      expect(winner([b(14), pirate(), g(14)]), 1);
    });

    test('the first pirate played wins among pirates', () {
      expect(winner([g(3), pirate(2), pirate(1)]), 1);
    });

    test('a tigress played as a pirate is a pirate', () {
      expect(
        winner([b(14), tigress, pirate()], tigressAs: TigressMode.pirate),
        1,
      );
    });

    test('the skull king beats pirates and number cards', () {
      expect(winner([pirate(), b(14), skullKing]), 2);
    });

    test('a mermaid beats number cards', () {
      expect(winner([b(14), mermaid(), g(14)]), 1);
    });

    test('the first mermaid played wins among mermaids', () {
      expect(winner([mermaid(2), mermaid(1), g(14)]), 0);
    });

    test('a pirate beats a mermaid', () {
      expect(winner([mermaid(), pirate(), g(14)]), 1);
    });

    test('a mermaid beats the skull king', () {
      expect(winner([skullKing, mermaid(), g(14)]), 1);
    });

    test('mermaid, skull king and pirate together: the mermaid wins, '
        'whatever the order', () {
      expect(winner([pirate(), skullKing, mermaid()]), 2);
      expect(winner([mermaid(), pirate(), skullKing]), 0);
      expect(winner([skullKing, mermaid(), pirate()]), 1);
    });

    test('the winner is reported by seat, not by position in the trick', () {
      final plays = [
        Play(seat: 3, card: g(7)),
        Play(seat: 0, card: g(12)),
        Play(seat: 1, card: g(8)),
      ];

      expect(resolveTrick(plays).winner, 0);
    });
  });

  group('bonuses', () {
    test('a plain trick carries no bonus', () {
      expect(bonuses([g(7), g(12), g(8)]), isEmpty);
    });

    test('each base-suit 14 in the trick is worth 10 to the winner', () {
      expect(bonuses([g(14), y(14), b(2)]), [
        Bonus.standardFourteen,
        Bonus.standardFourteen,
      ]);
    });

    test('the black 14 is worth 20', () {
      expect(bonuses([b(14), g(3), g(4)]), [Bonus.blackFourteen]);
    });

    test('a pirate earns 20 for each mermaid it captures', () {
      expect(bonuses([mermaid(1), pirate(), mermaid(2)]), [
        Bonus.mermaidCaptured,
        Bonus.mermaidCaptured,
      ]);
    });

    test('the skull king earns 30 for each pirate it captures, '
        'a tigress played as a pirate included', () {
      expect(
        bonuses([pirate(), tigress, skullKing], tigressAs: TigressMode.pirate),
        [Bonus.pirateCaptured, Bonus.pirateCaptured],
      );
    });

    test('a tigress played as an escape is not a captured pirate', () {
      expect(
        bonuses([tigress, skullKing, g(3)], tigressAs: TigressMode.escape),
        isEmpty,
      );
    });

    test('a mermaid earns 40 for capturing the skull king', () {
      expect(bonuses([skullKing, mermaid(), g(3)]), [Bonus.skullKingCaptured]);
    });

    test('rulebook example: 14 yellow, pirate, skull king, mermaid '
        'gives the mermaid 10 + 40 and nothing else', () {
      final result = resolveTrick(trick([y(14), pirate(), skullKing, mermaid()]));

      expect(result.winner, 3);
      expect(result.bonuses, [Bonus.standardFourteen, Bonus.skullKingCaptured]);
    });

    test('a pirate that does not win captures nothing', () {
      // The skull king wins: the mermaid-free trick only pays for the pirate.
      expect(bonuses([pirate(), skullKing, g(3)]), [Bonus.pirateCaptured]);
    });
  });
}
