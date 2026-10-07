// Plays games between bots and measures how well they do.
//
//   dart run tool/bot_lab.dart stats [games] [players]
//       Every seat played by each level in turn: how well it bids.
//   dart run tool/bot_lab.dart duel [games] [players] [effort] [full]
//       The strongest bot on one seat against the sensible one on the
//       others: how often it wins, and what a decision costs in time.
import 'dart:io';
import 'dart:math';

import 'package:skull_kings/bots/bot.dart';
import 'package:skull_kings/bots/sensible_bot.dart';
import 'package:skull_kings/bots/sharp_bot.dart';
import 'package:skull_kings/engine/engine.dart';

/// What one seat did over the games played.
class Tally {
  int rounds = 0;
  int bidsMade = 0;
  int over = 0;
  int under = 0;
  int zeroBids = 0;
  int zeroBidsMade = 0;
  int points = 0;
  int wins = 0;
  int games = 0;

  void add(SeatResult result) {
    rounds++;
    points += result.score.total;
    if (result.bidMade) bidsMade++;
    if (result.tricksWon > result.bid) over++;
    if (result.tricksWon < result.bid) under++;
    if (result.bid == 0) {
      zeroBids++;
      if (result.bidMade) zeroBidsMade++;
    }
  }

  String pct(int part, int whole) =>
      whole == 0 ? '  n/a' : '${(100 * part / whole).toStringAsFixed(1)} %';

  String line(String name) =>
      '${name.padRight(10)} paris réussis ${pct(bidsMade, rounds)} · '
      'trop de plis ${pct(over, rounds)} · pas assez ${pct(under, rounds)} · '
      'zéros réussis ${pct(zeroBidsMade, zeroBids)} '
      '(${pct(zeroBids, rounds)} des paris) · '
      '${(points / rounds).toStringAsFixed(1)} pts/manche';
}

/// Plays one game; [botOf] gives the bot of each seat. Returns the winner.
int playGame(
  GameConfig config,
  Bot Function(int seat) botOf,
  void Function(int seat, SeatResult result) onResult,
) {
  final game = Game(config);
  var winner = -1;
  void drain() {
    for (final event in game.takeEvents()) {
      if (event is RoundScored) {
        for (final (seat, result) in event.results.indexed) {
          onResult(seat, result);
        }
      } else if (event is GameFinished) {
        winner = event.winner;
      }
    }
  }

  drain();
  while (game.pending.isNotEmpty) {
    final question = game.pending.first;
    game.answer(botOf(question.seat)(question, game.viewFor(question.seat)));
    drain();
  }
  return winner;
}

void main(List<String> args) {
  final mode = args.elementAtOrNull(0) ?? 'stats';
  final games = int.parse(args.elementAtOrNull(1) ?? '500');
  final players = int.parse(args.elementAtOrNull(2) ?? '4');
  final effort = int.tryParse(args.elementAtOrNull(3) ?? '') ?? defaultEffort;
  // "full" as a last word: every option of the game is on.
  final full = args.contains('full');
  GameConfig config(int seed) => GameConfig(
    players: players,
    seed: seed,
    kraken: full,
    whiteWhale: full,
    loot: full,
    piratePowers: full,
    secondExpansion: full,
  );
  final watch = Stopwatch()..start();

  if (mode == 'tune') {
    // For each table size, the correction of the plain bid under which the
    // sensible bots, all playing by it, score best.
    final bot = sensibleBot();
    for (var table = 2; table <= 8; table++) {
      // With two players the ghost's hand counts as a third.
      final hands = table == 2 ? 3 : table;
      var best = (scale: 1.0, points: double.negativeInfinity);
      final line = StringBuffer('$table joueurs :');
      for (var step = 5; step <= 18; step++) {
        final scale = step / 10;
        bidScales[hands] = scale;
        final tally = Tally();
        for (var seed = 0; seed < games; seed++) {
          playGame(
            GameConfig(players: table, seed: seed),
            (_) => bot,
            (_, result) => tally.add(result),
          );
        }
        final points = tally.points / tally.rounds;
        line.write(' $scale→${points.toStringAsFixed(1)}');
        if (points > best.points) best = (scale: scale, points: points);
      }
      stdout.writeln('$line  ⇒ ${best.scale}');
      if (table != 2) bidScales.remove(hands);
    }
  } else if (mode == 'stats') {
    final levels = <String, Bot>{
      'Normal': sensibleBot(),
      'Difficile': sharpBot(Random(1), effort: effort),
    };
    for (final MapEntry(key: name, value: bot) in levels.entries) {
      final tally = Tally();
      for (var seed = 0; seed < games; seed++) {
        playGame(config(seed), (_) => bot, (_, result) => tally.add(result));
      }
      stdout.writeln(tally.line(name));
    }
  } else {
    final sharp = sharpBot(Random(1), effort: effort);
    final sensible = sensibleBot();
    final mine = Tally();
    final theirs = Tally();
    var decisions = 0;
    var slowest = 0;
    final thinking = Stopwatch();
    Bot timed(Bot bot) => (question, view) {
      decisions++;
      final before = thinking.elapsedMicroseconds;
      thinking.start();
      final answer = bot(question, view);
      thinking.stop();
      final took = thinking.elapsedMicroseconds - before;
      if (took > slowest) slowest = took;
      return answer;
    };
    final timedSharp = timed(sharp);
    for (var seed = 0; seed < games; seed++) {
      // The seat changes from game to game: none is better than another.
      final seat = seed % players;
      final winner = playGame(
        config(seed),
        (other) => other == seat ? timedSharp : sensible,
        (other, result) => (other == seat ? mine : theirs).add(result),
      );
      mine.games++;
      if (winner == seat) mine.wins++;
    }
    stdout
      ..writeln(mine.line('Difficile'))
      ..writeln(theirs.line('Normal'))
      ..writeln(
        'Victoires du bot Difficile : ${mine.pct(mine.wins, mine.games)} '
        '(au hasard : ${(100 / players).toStringAsFixed(1)} %) sur '
        '$games parties à $players joueurs, effort $effort',
      )
      ..writeln(
        'Temps par décision : '
        '${(thinking.elapsedMicroseconds / decisions / 1000).toStringAsFixed(2)}'
        ' ms en moyenne, ${(slowest / 1000).toStringAsFixed(0)} ms au plus',
      );
  }
  stdout.writeln('(${watch.elapsed.inSeconds} s)');
}
