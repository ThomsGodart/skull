import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:skull_kings/engine/engine.dart';

/// Plays [game] to the end with random legal answers and returns every event.
///
/// Open bids are answered in a random seat order, as they would be at a table.
List<Event> autoplay(Game game, {int botSeed = 1}) {
  final random = Random(botSeed);
  final events = <Event>[];
  var guard = 0;
  while (true) {
    events.addAll(game.takeEvents());
    final questions = game.pending;
    if (questions.isEmpty) {
      expect(game.isFinished, isTrue, reason: 'nothing asked, yet not over');
      break;
    }
    final question = questions[random.nextInt(questions.length)];
    if (question is PlayQuestion) {
      expect(
        question.legalCards,
        isNotEmpty,
        reason: 'a question with no choice',
      );
    }
    game.answer(randomAnswer(question, random));
    expect(++guard, lessThan(100000), reason: 'the game never ended');
  }
  return events;
}

/// A comparable trace of [events].
List<String> trace(List<Event> events) => [
  for (final event in events)
    switch (event) {
      RoundStarted e => 'round ${e.round} dealer ${e.dealer}',
      HandDealt e => 'hand ${e.seat} ${e.cards}',
      BidsRevealed e => 'bids ${e.bids}',
      CardPlayed e => 'play ${e.play.seat} ${e.play.card} ${e.play.tigressAs}',
      TrickWon e => 'trick ${e.winner} ${e.bonuses}',
      RoundScored e => 'scored ${e.results.map((r) => r.totalScore)}',
      GameFinished e => 'finished ${e.winner} ${e.scores}',
      _ => '$event',
    },
];

void main() {
  test('the winner of a trick leads the next one', () {
    final game = Game(const GameConfig(players: 4, seed: 3));
    final random = Random(5);
    int? lastWinner;
    var checked = 0;
    while (game.pending.isNotEmpty && checked < 20) {
      final question = game.pending.first;
      if (lastWinner != null && question is PlayQuestion) {
        expect(question.seat, lastWinner);
        checked++;
        lastWinner = null;
      }
      game.answer(randomAnswer(question, random));
      for (final event in game.takeEvents()) {
        // The last trick of a round is followed by a new deal, not a lead.
        if (event is TrickWon) lastWinner = event.winner;
        if (event is RoundStarted) lastWinner = null;
      }
    }
    expect(checked, 20);
  });

  test('round n deals n cards and the lead moves one seat each round', () {
    final events = autoplay(Game(const GameConfig(players: 5, seed: 11)));

    final rounds = events.whereType<RoundStarted>().take(10).toList();

    expect(rounds.map((r) => r.cardsDealt), [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
    for (var i = 1; i < rounds.length; i++) {
      expect(rounds[i].leader, (rounds[i - 1].leader + 1) % 5);
      expect(rounds[i].dealer, rounds[i - 1].leader);
    }
  });

  test('a round is scored from bids, tricks won and bonuses', () {
    final events = autoplay(Game(const GameConfig(players: 4, seed: 21)));

    final bids = events.whereType<BidsRevealed>().first.bids;
    final scored = events.whereType<RoundScored>().first;
    final winner = events.whereType<TrickWon>().first.winner;

    for (var seat = 0; seat < 4; seat++) {
      final result = scored.results[seat];
      expect(result.bid, bids[seat]);
      expect(result.tricksWon, seat == winner ? 1 : 0);
      // Round one, one card: +20 for a made bid of one, +10 for a made zero,
      // -10 for any miss, before bonuses.
      final expected = result.bid == result.tricksWon
          ? (result.bid == 1 ? 20 : 10)
          : -10;
      expect(result.score.bidPoints, expected);
      expect(result.totalScore, result.score.total);
    }
  });

  test('a round result lists the bonuses a seat collected in its tricks', () {
    for (var seed = 0; seed < 200; seed++) {
      final events = autoplay(Game(GameConfig(players: 6, seed: seed)));
      final rounds = events.whereType<RoundScored>().toList();
      var cursor = 0;
      for (final round in rounds) {
        // The tricks of this round: as many as it scored.
        final tricksInRound = round.results.fold(0, (n, r) => n + r.tricksWon);
        final tricks = events
            .whereType<TrickWon>()
            .skip(cursor)
            .take(tricksInRound)
            .toList();
        cursor += tricksInRound;
        for (var seat = 0; seat < 6; seat++) {
          final collected = [
            for (final trick in tricks)
              if (trick.winner == seat) ...trick.bonuses,
          ];
          expect(round.results[seat].bonuses, collected);
        }
      }
    }
  });

  group('whatever the seed and the number of players', () {
    // 2,100 whole games, each played once and checked by every test below.
    final games = [
      for (var players = 3; players <= 8; players++)
        for (var seed = 0; seed < 350; seed++)
          GameConfig(players: players, seed: seed),
    ];
    final played = <GameConfig, List<Event>>{};
    setUpAll(() {
      for (final config in games) {
        played[config] = autoplay(Game(config), botSeed: config.seed);
      }
    });

    test('the game ends with a single winner holding the best score', () {
      for (final config in games) {
        final events = played[config]!;
        final finished = events.whereType<GameFinished>().single;

        expect(events.last, same(finished));
        final best = finished.scores.reduce(max);
        expect(finished.scores[finished.winner], best);
        expect(finished.scores.where((s) => s == best), hasLength(1));
        expect(
          finished.scores,
          events.whereType<RoundScored>().last.results.map((r) => r.totalScore),
        );
      }
    });

    test('ten rounds are played, plus one per tie for first place', () {
      for (final config in games) {
        final events = played[config]!;
        final scored = events.whereType<RoundScored>().toList();

        expect(scored.length, greaterThanOrEqualTo(10));
        for (final round in scored) {
          final totals = round.results.map((r) => r.totalScore).toList();
          final tied = totals.where((s) => s == totals.reduce(max)).length > 1;
          final isLast = identical(round, scored.last);
          if (round.round >= 10) expect(tied, !isLast, reason: '$config');
        }
      }
    });

    test('every card is dealt once and every trick has one card per seat', () {
      for (final config in games) {
        final events = played[config]!;
        final dealt = <int, List<Card>>{};
        var round = 0;
        for (final event in events) {
          if (event is RoundStarted) round = event.round;
          if (event is HandDealt) (dealt[round] ??= []).addAll(event.cards);
          if (event is TrickWon) {
            expect(
              event.plays.map((p) => p.seat).toSet(),
              hasLength(config.players),
            );
          }
        }
        for (final cards in dealt.values) {
          expect(
            cards.toSet(),
            hasLength(cards.length),
            reason: 'no duplicate',
          );
        }
        expect(
          dealt[9],
          hasLength(config.players * (config.players == 8 ? 8 : 9)),
        );
      }
    });

    test('tricks won in a round add up to the cards dealt', () {
      for (final config in games) {
        final events = played[config]!;
        final started = events.whereType<RoundStarted>().toList();
        final scored = events.whereType<RoundScored>().toList();

        for (var i = 0; i < scored.length; i++) {
          final won = scored[i].results.fold(0, (sum, r) => sum + r.tricksWon);
          expect(won, started[i].cardsDealt);
        }
      }
    });
  });

  test('a tie for first place after round ten is played off, '
      'with as many cards as round ten and every seat playing', () {
    for (var seed = 0; seed < 500; seed++) {
      const players = 4;
      final events = autoplay(Game(GameConfig(players: players, seed: seed)));
      final scored = events.whereType<RoundScored>().toList();
      if (scored.length == 10) continue;

      final afterTen = scored[9].results.map((r) => r.totalScore).toList();
      final best = afterTen.reduce(max);
      expect(afterTen.where((s) => s == best).length, greaterThan(1));
      final tieBreak = events.whereType<RoundStarted>().elementAt(10);
      expect(tieBreak.round, 11);
      expect(tieBreak.cardsDealt, 10);
      expect(scored[10].results, hasLength(players));
      expect(events.whereType<GameFinished>(), hasLength(1));
      return;
    }
    fail('no seed produced a tie after round ten');
  });

  group('determinism', () {
    const config = GameConfig(players: 6, seed: 99);

    test('the same seed and the same answers give the same game', () {
      expect(trace(autoplay(Game(config))), trace(autoplay(Game(config))));
    });

    test('another seed gives another game', () {
      final other = autoplay(Game(const GameConfig(players: 6, seed: 100)));

      expect(trace(autoplay(Game(config))), isNot(trace(other)));
    });

    test('a seed deals the same cards forever', () {
      // Pinned on purpose: saved games depend on it. If this fails, the
      // generator or the deck order changed and old saves no longer replay.
      final game = Game(const GameConfig(players: 4, seed: 2026));
      final events = game.takeEvents();

      expect(events.whereType<RoundStarted>().single.dealer, 3);
      expect(events.whereType<HandDealt>().map((e) => e.cards.single.id), [
        'escape-2',
        'skullKing-1',
        'purple-10',
        'black-14',
      ]);
    });

    test('a game is rebuilt from its config and its answers', () {
      final original = Game(config);
      final events = autoplay(original);

      final rebuilt = Game.replay(config, original.answers);

      expect(trace(rebuilt.takeEvents()), trace(events));
      expect(rebuilt.isFinished, isTrue);
    });

    test('a game in progress is rebuilt at the same point', () {
      final original = Game(config);
      final random = Random(4);
      for (var i = 0; i < 37; i++) {
        original.answer(randomAnswer(original.pending.first, random));
      }

      final rebuilt = Game.replay(config, original.answers);

      expect(
        rebuilt.pending.map((q) => q.seat),
        original.pending.map((q) => q.seat),
      );
      expect(rebuilt.viewFor(2).hand, original.viewFor(2).hand);
      expect(rebuilt.viewFor(2).scores, original.viewFor(2).scores);
    });
  });

  group('playing', () {
    PlayQuestion playQuestion(Game game) {
      final random = Random(2);
      while (game.pending.first is! PlayQuestion) {
        game.answer(randomAnswer(game.pending.first, random));
      }
      return game.pending.single as PlayQuestion;
    }

    test('a card that is not in the legal list is refused', () {
      final game = Game(const GameConfig(players: 4, seed: 1));
      final question = playQuestion(game);
      final foreign = baseDeck().firstWhere(
        (card) => !question.legalCards.contains(card),
      );

      expect(
        () => game.answer(PlayAnswer(seat: question.seat, card: foreign)),
        throwsA(isA<IllegalAnswer>()),
      );
    });

    test('only the seat whose turn it is may play', () {
      final game = Game(const GameConfig(players: 4, seed: 1));
      final question = playQuestion(game);
      final other = (question.seat + 1) % 4;
      final card = game.viewFor(other).hand.first;

      expect(
        () => game.answer(PlayAnswer(seat: other, card: card)),
        throwsA(isA<IllegalAnswer>()),
      );
    });

    test('the tigress must be played as a pirate or as an escape, '
        'and no other card may be', () {
      const tigress = Card.special(CardKind.tigress);
      // Find a game where the tigress is in the first hand to play.
      for (var seed = 0; seed < 500; seed++) {
        final game = Game(GameConfig(players: 8, seed: seed));
        final question = playQuestion(game);
        if (!question.legalCards.contains(tigress)) continue;

        expect(
          () => game.answer(PlayAnswer(seat: question.seat, card: tigress)),
          throwsA(isA<IllegalAnswer>()),
        );
        game.answer(
          PlayAnswer(
            seat: question.seat,
            card: tigress,
            tigressAs: TigressMode.escape,
          ),
        );
        final played = game.takeEvents().whereType<CardPlayed>().single;
        expect(played.play.tigressAs, TigressMode.escape);
        return;
      }
      fail('no seed dealt the tigress to the leader');
    });

    test('a tigress mode on another card is refused', () {
      final game = Game(const GameConfig(players: 4, seed: 1));
      final question = playQuestion(game);
      final card = question.legalCards.firstWhere(
        (card) => card.kind != CardKind.tigress,
      );

      expect(
        () => game.answer(
          PlayAnswer(
            seat: question.seat,
            card: card,
            tigressAs: TigressMode.pirate,
          ),
        ),
        throwsA(isA<IllegalAnswer>()),
      );
    });
  });

  group('what a seat sees', () {
    test(
      'its own hand and bid, but not the bids of others before the reveal',
      () {
        final game = Game(const GameConfig(players: 4, seed: 8));
        final dealt = game.takeEvents().whereType<HandDealt>().toList();
        game.answer(const BidAnswer(seat: 0, bid: 1));
        game.answer(const BidAnswer(seat: 1, bid: 0));

        final view = game.viewFor(1);

        expect(view.hand, dealt[1].cards);
        expect(view.handSizes, [1, 1, 1, 1]);
        expect(view.bids, [null, 0, null, null]);
      },
    );

    test('every bid once they are revealed', () {
      final game = Game(const GameConfig(players: 4, seed: 8));
      for (var seat = 0; seat < 4; seat++) {
        game.answer(BidAnswer(seat: seat, bid: seat.isEven ? 1 : 0));
      }

      expect(game.viewFor(3).bids, [1, 0, 1, 0]);
    });
  });

  test('a game needs three to eight players', () {
    expect(
      () => Game(const GameConfig(players: 2, seed: 1)),
      throwsArgumentError,
    );
    expect(
      () => Game(const GameConfig(players: 9, seed: 1)),
      throwsArgumentError,
    );
  });
}
