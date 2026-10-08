import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:skull_kings/ui/strings.dart';

void main() {
  test('the bot name pool has fifty distinct names', () {
    expect(Strings.botNames, hasLength(50));
    expect(Strings.botNames.toSet(), hasLength(50));
  });

  test('shuffledBotNames draws without repeating', () {
    final names = Strings.shuffledBotNames(7, Random(1));
    expect(names, hasLength(7));
    expect(names.toSet(), hasLength(7));
    expect(Strings.botNames.toSet().containsAll(names), isTrue);
  });
}
