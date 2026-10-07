import 'dart:math';

/// A small pseudo-random generator whose sequence is fixed by this file.
///
/// A saved game is its seed and its answers, so the same seed must deal the
/// same cards forever. `dart:math`'s `Random` gives no such guarantee across
/// SDK releases; this one (mulberry32) does, as long as nobody edits it.
///
/// It also gives the same sequence on every platform. In a browser an `int`
/// is a double, exact up to 2^53 only, so two 32-bit numbers are never
/// multiplied directly: see [_multiply].
final class SeededRandom {
  SeededRandom(int seed) : _state = seed & _mask;

  static const _mask = 0xFFFFFFFF;

  int _state;

  int _next() {
    _state = (_state + 0x6D2B79F5) & _mask;
    var t = _state;
    t = _multiply(t ^ (t >> 15), t | 1);
    t ^= (t + _multiply(t ^ (t >> 7), t | 61)) & _mask;
    return (t ^ (t >> 14)) & _mask;
  }

  /// The low 32 bits of [a] × [b], both 32-bit numbers, computed in two
  /// halves so that nothing ever exceeds 2^53.
  static int _multiply(int a, int b) {
    final low = (a & 0xFFFF) * b;
    final high = ((a >> 16) * b) & 0xFFFF;
    return (low + high * 0x10000) & _mask;
  }

  /// A seed drawn from [random]: any 32-bit number.
  static int newSeed(Random random) => random.nextInt(_seeds);

  // Written out: `1 << 32` is 0 in a browser.
  static const _seeds = 0x100000000;

  /// A value from 0 inclusive to [max] exclusive.
  int nextInt(int max) => _next() % max;

  /// Shuffles [items] in place.
  void shuffle<T>(List<T> items) {
    for (var i = items.length - 1; i > 0; i--) {
      final j = nextInt(i + 1);
      final swapped = items[i];
      items[i] = items[j];
      items[j] = swapped;
    }
  }
}
