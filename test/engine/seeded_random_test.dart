import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:skull_kings/engine/engine.dart';

void main() {
  // Saved games are replayed from their seed: these numbers must never
  // change, on a phone or in a browser (`flutter test --platform chrome`).
  test('a seed gives the same sequence forever, on every platform', () {
    List<int> first(int seed) {
      final random = SeededRandom(seed);
      return [for (var i = 0; i < 6; i++) random.nextInt(1000000007)];
    }

    expect(first(0), [
      144304731,
      1416247,
      958946056,
      627933444,
      7157702,
      340967971,
    ]);
    expect(first(123456789), [
      107202807,
      169434443,
      372958117,
      885470128,
      301683838,
      208624219,
    ]);
    expect(first(4294967295), [
      850105790,
      813802916,
      73704827,
      54706408,
      630262810,
      315588649,
    ]);
  });

  test('a new seed is any 32-bit number, and never fails to be drawn', () {
    final random = Random(1);
    for (var i = 0; i < 1000; i++) {
      final seed = SeededRandom.newSeed(random);
      expect(seed, inInclusiveRange(0, 0xFFFFFFFF));
    }
  });

  test('a game deals the same hands from the same seed', () {
    final hand = Game(const GameConfig(players: 4, seed: 42)).viewFor(0).hand;
    final again = Game(const GameConfig(players: 4, seed: 42)).viewFor(0).hand;
    expect(hand, again);
  });
}
