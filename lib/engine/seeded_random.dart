/// A small pseudo-random generator whose sequence is fixed by this file.
///
/// A saved game is its seed and its answers, so the same seed must deal the
/// same cards forever. `dart:math`'s `Random` gives no such guarantee across
/// SDK releases; this one (mulberry32) does, as long as nobody edits it.
final class SeededRandom {
  SeededRandom(int seed) : _state = seed & _mask;

  static const _mask = 0xFFFFFFFF;

  int _state;

  int _next() {
    _state = (_state + 0x6D2B79F5) & _mask;
    var t = _state;
    t = ((t ^ (t >> 15)) * (t | 1)) & _mask;
    t ^= (t + (((t ^ (t >> 7)) * (t | 61)) & _mask)) & _mask;
    return (t ^ (t >> 14)) & _mask;
  }

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
