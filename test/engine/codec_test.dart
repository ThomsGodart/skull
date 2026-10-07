import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:skull_kings/engine/engine.dart';

void main() {
  test('every card of the deck is found again from its identifier', () {
    for (final card in baseDeck()) {
      expect(Card.fromId(card.id), card);
    }
  });

  test('an unknown card identifier is refused', () {
    expect(() => Card.fromId('green-15'), throwsFormatException);
    expect(() => Card.fromId('dragon-1'), throwsFormatException);
    expect(() => Card.fromId('pirate-7'), throwsFormatException);
  });

  test('a bid and a played card survive a trip through JSON', () {
    final answers = <Answer>[
      const BidAnswer(seat: 2, bid: 3),
      const PlayAnswer(seat: 1, card: Card.number(Suit.black, 14)),
      const PlayAnswer(
        seat: 0,
        card: Card.special(CardKind.tigress),
        tigressAs: TigressMode.escape,
      ),
    ];

    final decoded = [
      for (final answer in answers)
        answerFromJson(
          jsonDecode(jsonEncode(answerToJson(answer))) as Map<String, Object?>,
        ),
    ];

    expect(decoded[0], isA<BidAnswer>());
    expect((decoded[0] as BidAnswer).seat, 2);
    expect((decoded[0] as BidAnswer).bid, 3);
    expect((decoded[1] as PlayAnswer).card, const Card.number(Suit.black, 14));
    expect((decoded[1] as PlayAnswer).tigressAs, isNull);
    expect((decoded[2] as PlayAnswer).tigressAs, TigressMode.escape);
  });

  test('a game saved as JSON half-way resumes at the very same point', () {
    const config = GameConfig(players: 5, seed: 77);
    final original = Game(config);
    final random = Random(3);
    for (var i = 0; i < 61; i++) {
      original.answer(randomAnswer(original.pending.first, random));
    }

    final saved = jsonEncode({
      'config': config.toJson(),
      'answers': original.answers.map(answerToJson).toList(),
    });
    final json = jsonDecode(saved) as Map<String, Object?>;
    final resumed = Game.replay(
      GameConfig.fromJson(json['config']! as Map<String, Object?>),
      (json['answers']! as List).map(
        (answer) => answerFromJson(answer as Map<String, Object?>),
      ),
    );

    for (var seat = 0; seat < 5; seat++) {
      final before = original.viewFor(seat);
      final after = resumed.viewFor(seat);
      expect(after.hand, before.hand);
      expect(after.bids, before.bids);
      expect(after.tricksWon, before.tricksWon);
      expect(after.scores, before.scores);
      expect(after.trick.map((p) => p.card), before.trick.map((p) => p.card));
    }
    expect(
      resumed.pending.map((q) => q.seat),
      original.pending.map((q) => q.seat),
    );
  });
}
