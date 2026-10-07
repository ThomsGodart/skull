import 'dart:math';

import '../engine/engine.dart';
import 'bot.dart';
import 'sensible_bot.dart';
import 'sharp_bot.dart';

/// True where numbers are JavaScript's: an int and a double are one there.
const _inBrowser = identical(0, 0.0);

/// How well the bots play.
enum BotLevel { easy, normal, hard }

/// A bot of [level]. [random] only serves the easy one, which blunders.
Bot botFor(BotLevel level, Random random) => switch (level) {
  BotLevel.easy => _easyBot(random),
  BotLevel.normal => sensibleBot(),
  BotLevel.hard => sharpBot(
    random,
    // In a browser the same work takes several times longer.
    effort: _inBrowser ? defaultEffort ~/ 3 : defaultEffort,
  ),
};

/// The sensible bot on a bad day: one bid in two is a trick off, and one
/// card in three is played without thinking.
Bot _easyBot(Random random) {
  final sensible = sensibleBot();
  return (question, view) {
    final answer = sensible(question, view);
    switch (question) {
      case BidQuestion(:final seat, :final maxBid):
        if (random.nextBool()) return answer;
        final off = (answer as BidAnswer).bid + (random.nextBool() ? 1 : -1);
        return BidAnswer(seat: seat, bid: off.clamp(0, maxBid));
      case PlayQuestion():
        return random.nextInt(3) == 0
            ? randomAnswer(question, random, trick: view.trick)
            : answer;
      case AfterTrickQuestion():
        return answer;
    }
  };
}
