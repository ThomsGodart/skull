import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:skull_kings/engine/engine.dart';
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

  test('no bot is named after a card or a named pirate', () {
    final deck = deckFor(
      const GameConfig(
        players: 4,
        seed: 0,
        kraken: true,
        whiteWhale: true,
        loot: true,
        secondExpansion: true,
      ),
    );
    final labels = {
      for (final card in deck)
        if (!card.isNumber) ...[
          Strings.cardName(card),
          Strings.cardName(card, namedPirates: true),
        ],
      for (final pirate in Pirate.values) ...[
        Strings.pirateName(pirate),
        Strings.pirateShortName(pirate),
      ],
      Strings.ghostName,
    };
    final words = {
      for (final label in labels) ...label.toLowerCase().split(' '),
    };

    for (final name in Strings.botNames) {
      expect(words, isNot(contains(name.toLowerCase())), reason: name);
    }
  });
}
