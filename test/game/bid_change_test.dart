import 'package:flutter_test/flutter_test.dart';
import 'package:skull_kings/engine/engine.dart';
import 'package:skull_kings/game/game_controller.dart';
import 'package:skull_kings/game/seat_feed.dart';

/// A seat of a game played elsewhere, where the others take their time to
/// bid: it only records what it is answered.
class WaitingFeed implements SeatFeed {
  final List<Answer> answers = [];
  final List<Event> _events = [
    const RoundStarted(round: 1, cardsDealt: 1, dealer: 2, leader: 0),
    const HandDealt(seat: 0, cards: [Card.number(Suit.green, 3)]),
  ];
  void Function()? _onUpdate;

  @override
  Question? question = const BidQuestion(seat: 0, maxBid: 1);

  @override
  GameConfig get config => const GameConfig(players: 3, seed: 0);

  @override
  int get seat => 0;

  @override
  void open() {}

  @override
  List<Event> takeEvents() {
    final events = List.of(_events);
    _events.clear();
    return events;
  }

  @override
  void answer(Answer answer) {
    answers.add(answer);
    question = null;
  }

  /// The last of the others has bid.
  void reveal(List<int> bids) {
    _events.add(BidsRevealed(bids));
    _onUpdate?.call();
  }

  @override
  set onUpdate(void Function()? callback) => _onUpdate = callback;

  @override
  set onError(void Function(Object error)? callback) {}

  @override
  void acknowledgeEnd(GameFinished result) {}

  @override
  void close() {}
}

void main() {
  test('a placed bid shows as placed while the others choose, and can be '
      'changed until the bids are turned over', () async {
    final feed = WaitingFeed();
    final controller = GameController.onFeed(feed, speed: TableSpeed.instant)
      ..start();
    await Future<void>.delayed(Duration.zero);
    expect(controller.bidQuestion, isNotNull);

    controller.bid(1);
    expect(controller.placedBid, 1);
    expect(controller.bidQuestion, isNull);

    controller.changeBid();
    expect(controller.bidQuestion, isNotNull, reason: 'asked again');
    controller.bid(0);
    expect(feed.answers.map((answer) => (answer as BidAnswer).bid), [1, 0]);
    expect(controller.placedBid, 0);

    feed.reveal([0, 1, 0]);
    await Future<void>.delayed(Duration.zero);
    expect(controller.placedBid, isNull);
    controller.changeBid();
    expect(controller.bidQuestion, isNull, reason: 'too late');
    controller.dispose();
  });
}
