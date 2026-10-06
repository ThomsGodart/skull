import 'package:flutter/material.dart' hide Card;

import '../engine/engine.dart';
import '../theme/tokens.dart';
import '../ui/cards/card_view.dart';
import '../ui/strings.dart';
import 'game_controller.dart';
import 'seat_identity.dart';

/// Asks the human how to use the power of the pirate that just won them a
/// trick, and pops with their [Answer].
class PowerDialog extends StatefulWidget {
  const PowerDialog({
    super.key,
    required this.question,
    required this.seats,
    required this.bid,
    this.tricksWon = 0,
    this.namedPirates = true,
  });

  final PowerQuestion question;
  final List<SeatIdentity> seats;

  /// The human's current bid, to show what Harry would make of it.
  final int bid;

  /// The tricks the human took this round, shown with Harry's question.
  final int tricksWon;
  final bool namedPirates;

  @override
  State<PowerDialog> createState() => _PowerDialogState();
}

class _PowerDialogState extends State<PowerDialog> {
  /// The cards picked for Will's discard.
  final Set<Card> _discards = {};

  int get _seat => widget.question.seat;

  void _answer(Answer answer) => Navigator.pop(context, answer);

  Widget _choice(Key key, String label, Answer answer) => Padding(
    padding: const EdgeInsets.only(top: Tokens.space2),
    child: SizedBox(
      width: double.infinity,
      child: FilledButton.tonal(
        key: key,
        onPressed: () => _answer(answer),
        child: Text(label),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final (pirate, body, choices, actions) = switch (widget.question) {
      ChooseLeaderQuestion(:final seats) => (
        Pirate.rosie,
        Strings.chooseLeaderBody,
        [
          for (final seat in seats)
            _choice(
              Key('power-leader-$seat'),
              widget.seats[seat].name,
              ChooseLeaderAnswer(seat: _seat, leader: seat),
            ),
        ],
        const <Widget>[],
      ),
      WagerQuestion(:final amounts) => (
        Pirate.rascal,
        Strings.wagerBody,
        [
          for (final amount in amounts)
            _choice(
              Key('power-wager-$amount'),
              Strings.wagerOption(amount),
              WagerAnswer(seat: _seat, amount: amount),
            ),
        ],
        const <Widget>[],
      ),
      AdjustBidQuestion(:final changes) => (
        Pirate.harry,
        Strings.adjustBidBody(widget.tricksWon),
        [
          for (final change in changes)
            _choice(
              Key('power-change-$change'),
              Strings.adjustBidOption(change, widget.bid + change),
              AdjustBidAnswer(seat: _seat, change: change),
            ),
        ],
        const <Widget>[],
      ),
      DiscardQuestion(:final hand, :final count) => (
        Pirate.will,
        Strings.discardBody(count),
        [
          Wrap(
            spacing: Tokens.space1,
            runSpacing: Tokens.space1,
            children: [
              for (final card in sortedHand(hand))
                GestureDetector(
                  key: Key('power-discard-${card.id}'),
                  onTap: () => setState(() {
                    if (!_discards.remove(card) && _discards.length < count) {
                      _discards.add(card);
                    }
                  }),
                  child: CardView(
                    card,
                    width: 64,
                    selected: _discards.contains(card),
                    namedPirates: widget.namedPirates,
                  ),
                ),
            ],
          ),
        ],
        [
          FilledButton(
            key: const Key('power-confirm'),
            onPressed: _discards.length == count
                ? () => _answer(
                    DiscardAnswer(seat: _seat, cards: _discards.toList()),
                  )
                : null,
            child: const Text(Strings.discardConfirm),
          ),
        ],
      ),
    };
    return AlertDialog(
      backgroundColor: Tokens.panel,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: Tokens.space3,
        vertical: Tokens.space6,
      ),
      title: Text(Strings.pirateName(pirate)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(body),
            const SizedBox(height: Tokens.space2),
            ...choices,
          ],
        ),
      ),
      actions: actions,
    );
  }
}
