import 'package:flutter/material.dart';

import '../engine/engine.dart';
import '../theme/tokens.dart';
import '../ui/pictogram.dart';
import '../ui/strings.dart';
import 'seat_identity.dart';

const _cell = TextStyle(color: Tokens.text, fontSize: 17);
const _head = TextStyle(
  color: Tokens.mutedText,
  fontSize: 13,
  fontWeight: FontWeight.w700,
);

/// Everything a seat scored on top of its bid.
int _extras(SeatResult result) => result.score.total - result.score.bidPoints;

/// What the bonus column says for [result]: nothing to count, bonuses that
/// were lost with the bid, or what the extras add up to (even zero, when a
/// lost wager cancels a bonus).
String _extrasLabel(SeatResult result) {
  final score = result.score;
  final nothingCounted =
      score.bonusPoints == 0 &&
      score.alliancePoints == 0 &&
      score.wagerPoints == 0;
  if (!nothingCounted) return Strings.signedOrZero(_extras(result));
  return result.bonuses.isEmpty ? Strings.noBonus : Strings.bonusLost;
}

/// What made up the extras of [result], in words.
List<String> _details(SeatResult result) => [
  ...result.bonuses.map(Strings.bonusName),
  if (result.score.alliancePoints != 0)
    Strings.allianceLine(result.score.alliancePoints),
  if (result.score.wagerPoints != 0)
    Strings.wagerLine(result.score.wagerPoints),
];

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
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 3),
            child: cell,
          ),
      ],
    );
    // A figure never wraps: it shrinks to its column instead.
    Widget number(String text, {Color? color, bool bold = false}) => FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerRight,
      child: Text(
        text,
        maxLines: 1,
        style: _cell.copyWith(
          color: color,
          fontWeight: bold ? FontWeight.w800 : null,
        ),
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
                Strings.colTricksBid,
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
                number(Strings.tricksOverBid(result.tricksWon, result.bid)),
                number(Strings.signed(result.score.bidPoints)),
                number(
                  _extrasLabel(result),
                  color: _extrasLabel(result) == Strings.noBonus
                      ? Tokens.mutedText
                      : null,
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
        if (round.results.any((result) => _details(result).isNotEmpty))
          const Padding(
            padding: EdgeInsets.only(top: Tokens.space3),
            child: Text(
              Strings.bonusHeading,
              style: TextStyle(
                color: Tokens.gold,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        for (final (seat, result) in round.results.indexed)
          if (_details(result).isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: Tokens.space1),
              child: Text(
                Strings.detailsOf(seats[seat].name, _details(result)),
                style: const TextStyle(color: Tokens.mutedText, fontSize: 14),
              ),
            ),
      ],
    );
  }
}

/// Every round of the game so far: bid, tricks and running total per seat.
class ScoreSheet extends StatelessWidget {
  const ScoreSheet({
    super.key,
    required this.rounds,
    required this.seats,
    this.onRoundTap,
  });

  final List<RoundScored> rounds;
  final List<SeatIdentity> seats;

  /// Called with a round's number when it is tapped, to correct it.
  final ValueChanged<int>? onRoundTap;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: Tokens.space6,
        headingRowHeight: 48,
        dataRowMinHeight: 60,
        dataRowMaxHeight: 66,
        columns: [
          const DataColumn(label: Text(Strings.colRound, style: _head)),
          for (final seat in seats)
            DataColumn(
              label: Text(seat.name, style: _head.copyWith(fontSize: 15)),
            ),
        ],
        rows: [
          for (final round in rounds)
            DataRow(
              cells: [
                DataCell(
                  Text(
                    '${round.round}',
                    key: Key('sheet-round-${round.round}'),
                    style: _cell.copyWith(
                      fontSize: 18,
                      color: onRoundTap == null ? null : Tokens.gold,
                      fontWeight: onRoundTap == null ? null : FontWeight.w800,
                    ),
                  ),
                  onTap: onRoundTap == null
                      ? null
                      : () => onRoundTap!(round.round),
                ),
                for (final result in round.results)
                  DataCell(
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${result.totalScore}',
                          style: _cell.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                          ),
                        ),
                        Text(
                          '${Strings.tricksOverBid(result.tricksWon, result.bid)} · '
                          '${Strings.signed(result.score.total)}',
                          style: TextStyle(
                            color: Tokens.mutedText,
                            fontSize: 14,
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
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 36,
                  child: _rank(seat) == 1
                      ? const Align(
                          alignment: Alignment.centerLeft,
                          child: Pictogram(
                            Strings.winnerMark,
                            size: 24,
                            color: Tokens.gold,
                          ),
                        )
                      : Text(
                          '${_rank(seat)}.',
                          style: _cell.copyWith(color: Tokens.mutedText),
                        ),
                ),
                Expanded(
                  child: Text(
                    seats[seat].name,
                    style: _cell.copyWith(
                      color: _rank(seat) == 1 ? Tokens.gold : Tokens.text,
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                    ),
                  ),
                ),
                Text(
                  '${scores[seat]}',
                  style: _cell.copyWith(
                    color: _rank(seat) == 1 ? Tokens.gold : Tokens.text,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
