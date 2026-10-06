import 'package:flutter/material.dart';

import '../engine/engine.dart';
import '../theme/tokens.dart';
import '../ui/strings.dart';
import 'seat_identity.dart';

const _cell = TextStyle(color: Tokens.text, fontSize: 13);
const _head = TextStyle(
  color: Tokens.mutedText,
  fontSize: 11,
  fontWeight: FontWeight.w700,
);

/// What every seat scored in one round, and why.
class RoundSummaryTable extends StatelessWidget {
  const RoundSummaryTable({
    super.key,
    required this.round,
    required this.seats,
  });

  final RoundScored round;
  final List<SeatIdentity> seats;

  @override
  Widget build(BuildContext context) {
    TableRow row(List<Widget> cells) => TableRow(
      children: [
        for (final cell in cells)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 3),
            child: cell,
          ),
      ],
    );
    Widget number(String text, {Color? color, bool bold = false}) => Text(
      text,
      textAlign: TextAlign.right,
      style: _cell.copyWith(
        color: color,
        fontWeight: bold ? FontWeight.w800 : null,
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Table(
          columnWidths: const {0: FlexColumnWidth(2.2)},
          defaultColumnWidth: const FlexColumnWidth(),
          children: [
            row([
              const Text(Strings.colPlayer, style: _head),
              for (final title in [
                Strings.colBidTricks,
                Strings.colBidPoints,
                Strings.colBonus,
                Strings.colRound,
                Strings.colTotal,
              ])
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(title, style: _head),
                ),
            ]),
            for (final (seat, result) in round.results.indexed)
              row([
                Text(
                  seats[seat].name,
                  overflow: TextOverflow.ellipsis,
                  style: _cell.copyWith(fontWeight: FontWeight.w700),
                ),
                number('${result.bid}/${result.tricksWon}'),
                number(Strings.signed(result.score.bidPoints)),
                number(
                  result.bonuses.isEmpty
                      ? Strings.noBonus
                      : result.score.bonusPoints > 0
                      ? Strings.signed(result.score.bonusPoints)
                      : Strings.bonusLost,
                  color: result.bonuses.isEmpty ? Tokens.mutedText : null,
                ),
                number(
                  Strings.signed(result.score.total),
                  color: result.score.total < 0 ? Tokens.danger : Tokens.gold,
                  bold: true,
                ),
                number('${result.totalScore}', bold: true),
              ]),
          ],
        ),
        for (final (seat, result) in round.results.indexed)
          if (result.bonuses.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: Tokens.space1),
              child: Text(
                Strings.bonusesOf(seats[seat].name, result.bonuses),
                style: const TextStyle(color: Tokens.mutedText, fontSize: 11),
              ),
            ),
      ],
    );
  }
}

/// Every round of the game so far: bid, tricks and running total per seat.
class ScoreSheet extends StatelessWidget {
  const ScoreSheet({super.key, required this.rounds, required this.seats});

  final List<RoundScored> rounds;
  final List<SeatIdentity> seats;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: Tokens.space4,
        headingRowHeight: 36,
        dataRowMinHeight: 40,
        dataRowMaxHeight: 44,
        columns: [
          const DataColumn(label: Text(Strings.colRound, style: _head)),
          for (final seat in seats)
            DataColumn(label: Text(seat.name, style: _head)),
        ],
        rows: [
          for (final round in rounds)
            DataRow(
              cells: [
                DataCell(Text('${round.round}', style: _cell)),
                for (final result in round.results)
                  DataCell(
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${result.totalScore}',
                          style: _cell.copyWith(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          '${result.bid}/${result.tricksWon} · '
                          '${Strings.signed(result.score.total)}',
                          style: const TextStyle(
                            color: Tokens.mutedText,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

/// The final ranking, best score first.
class Standings extends StatelessWidget {
  const Standings({super.key, required this.scores, required this.seats});

  final List<int> scores;
  final List<SeatIdentity> seats;

  /// 1 for the best score. Equal scores share a place.
  int _rank(int seat) =>
      1 + scores.where((score) => score > scores[seat]).length;

  @override
  Widget build(BuildContext context) {
    final order = [for (var seat = 0; seat < scores.length; seat++) seat]
      ..sort((a, b) => scores[b].compareTo(scores[a]));
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final seat in order)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Text(
                    _rank(seat) == 1 ? Strings.winnerMark : '${_rank(seat)}.',
                    style: _cell.copyWith(color: Tokens.mutedText),
                  ),
                ),
                Expanded(
                  child: Text(
                    seats[seat].name,
                    style: _cell.copyWith(
                      color: _rank(seat) == 1 ? Tokens.gold : Tokens.text,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
                Text(
                  '${scores[seat]}',
                  style: _cell.copyWith(
                    color: _rank(seat) == 1 ? Tokens.gold : Tokens.text,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
