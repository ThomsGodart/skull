import 'package:flutter_test/flutter_test.dart';
import 'package:skull_kings/engine/engine.dart';

import 'support.dart';

TrickResult resolve(List<Card> cards, {TigressMode? tigressAs}) =>
    resolveTrick(trick(cards, tigressAs: tigressAs));

void main() {
  group('the deck', () {
    test('the base game has 70 cards and no expansion card', () {
      final deck = deckFor(const GameConfig(players: 4, seed: 1));

      expect(deck, hasLength(70));
      expect(deck.where((card) => card.kind == CardKind.kraken), isEmpty);
    });

    test('each expansion card is added on its own', () {
      List<Card> deck({bool k = false, bool w = false, bool l = false}) =>
          deckFor(
            GameConfig(players: 4, seed: 1, kraken: k, whiteWhale: w, loot: l),
          );

      expect(deck(k: true), hasLength(71));
      expect(deck(w: true), hasLength(71));
      expect(deck(l: true), hasLength(72));
      expect(deck(k: true, w: true, l: true), hasLength(74));
    });

    test('every expansion card is found again from its identifier', () {
      for (final card in [kraken, whale, loot(1), loot(2)]) {
        expect(Card.fromId(card.id), card);
      }
    });

    test('eight players still never get more than eight cards with the '
        'full expansion', () {
      expect(cardsDealt(round: 10, players: 8), 8);
    });
  });

  group('following suit with expansion cards', () {
    final hand = [g(3), y(5), b(2)];

    test('a kraken or a white whale that leads sets no suit', () {
      expect(legalCards(hand, trick([kraken, y(9)])), hand);
      expect(legalCards(hand, trick([whale, y(9)])), hand);
    });

    test('once a kraken or a white whale is played, nobody has to follow '
        'the suit any more', () {
      expect(legalCards(hand, trick([y(9), kraken])), hand);
      expect(legalCards(hand, trick([y(9), g(4), whale])), hand);
    });

    test('a loot that leads leaves the next number card to set the suit', () {
      expect(legalCards(hand, trick([loot(), y(9)])), [y(5)]);
    });
  });

  group('the kraken', () {
    test('destroys the trick: nobody wins it, and its bonuses are lost', () {
      final result = resolve([y(14), kraken, pirate(), skullKing]);

      expect(result.destroyed, isTrue);
      expect(result.bonuses, isEmpty);
    });

    test('whoever would have won without it leads the next trick', () {
      expect(resolve([y(12), kraken, y(5), b(2)]).winner, 3);
      expect(resolve([kraken, g(7), g(12), g(8)]).winner, 2);
    });
  });

  group('the white whale', () {
    test('rulebook example: 2 black, pirate, 14 yellow, skull king, whale: '
        'the 14 yellow wins', () {
      final result = resolve([b(2), pirate(), y(14), skullKing, whale]);

      expect(result.destroyed, isFalse);
      expect(result.winner, 2);
    });

    test('the highest number wins whatever its suit, trump included', () {
      expect(resolve([b(3), whale, g(9), y(8)]).winner, 2);
    });

    test('between equal values the first one played wins', () {
      expect(resolve([whale, g(9), y(9), p(4)]).winner, 1);
    });

    test('the 14s still pay their bonus, the characters pay none', () {
      final result = resolve([mermaid(), pirate(), y(14), whale]);

      expect(result.bonuses, [Bonus.standardFourteen]);
    });

    test('with nothing but special cards, the trick is destroyed and '
        'whoever would have won leads', () {
      final result = resolve([pirate(), whale, skullKing, esc()]);

      expect(result.destroyed, isTrue);
      expect(result.winner, 2);
      expect(result.bonuses, isEmpty);
    });
  });

  group('kraken and white whale in the same trick', () {
    test('only the second one played takes effect', () {
      // Official FAQ: 12 yellow, 3 black, white whale, kraken.
      final krakenLast = resolve([y(12), b(3), whale, kraken]);
      expect(krakenLast.destroyed, isTrue);
      expect(krakenLast.winner, 1, reason: 'the 3 black would have won');

      final whaleLast = resolve([y(12), b(3), kraken, whale]);
      expect(whaleLast.destroyed, isFalse);
      expect(whaleLast.winner, 0, reason: 'highest number, suits ignored');
    });
  });

  group('loot', () {
    test('loses like an escape', () {
      expect(resolve([loot(), g(1), g(2)]).winner, 2);
    });

    test('allies its player with the winner of the trick', () {
      final result = resolve([g(7), loot(), g(12)]);

      expect(result.alliances, hasLength(1));
      expect(result.alliances.single.lootSeat, 1);
      expect(result.alliances.single.winnerSeat, 2);
    });

    test('two loots make two alliances with the same winner', () {
      final result = resolve([loot(1), pirate(), loot(2)]);

      expect(result.alliances.map((a) => (a.lootSeat, a.winnerSeat)), [
        (0, 1),
        (2, 1),
      ]);
    });

    test('a loot that wins the trick itself makes no alliance', () {
      final result = resolve([loot(), esc(), esc(2)]);

      expect(result.winner, 0);
      expect(result.alliances, isEmpty);
    });

    test('a destroyed trick makes no alliance', () {
      expect(resolve([loot(), kraken, g(3)]).alliances, isEmpty);
    });

    test('under a white whale the loot is destroyed with the other '
        'special cards', () {
      expect(resolve([loot(), whale, g(3)]).alliances, isEmpty);
    });
  });
}
