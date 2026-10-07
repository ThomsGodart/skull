import 'package:flutter/material.dart';

import '../engine/engine.dart';
import '../theme/tokens.dart';
import '../ui/strings.dart';
import 'counter_game.dart';

/// Where a round of a counted game is entered: the bids first, then, once
/// the round is played, the tricks and bonuses.
class CounterRoundScreen extends StatefulWidget {
  const CounterRoundScreen({
    super.key,
    required this.game,
    required this.round,
    required this.onDraft,
    required this.onSave,
  });

  final CounterGame game;

  /// The round to enter, or a past one to correct.
  final int round;

  /// Called with the bids once they are all in.
  final ValueChanged<List<int>> onDraft;

  /// Called with the whole round once it is entered.
  final ValueChanged<CounterRound> onSave;

  @override
  State<CounterRoundScreen> createState() => _CounterRoundScreenState();
}

class _CounterRoundScreenState extends State<CounterRoundScreen> {
  late List<CounterEntry> _entries;
  late List<(int, int)> _alliances;

  /// True once the bids are in and the results are being entered.
  late bool _results;

  CounterGame get _game => widget.game;
  int get _cards => _game.cardsIn(widget.round);

  @override
  void initState() {
    super.initState();
    final past = _game.round(widget.round);
    final draft = _game.draftBids;
    _results = past != null || draft != null;
    _alliances = List.of(past?.alliances ?? const []);
    _entries =
        past?.entries.map(_withHarryInTheBid).toList() ??
        [
          for (var player = 0; player < _game.players.length; player++)
            CounterEntry(bid: draft?[player] ?? 0, tricksWon: 0),
        ];
  }

  /// Harry's change is entered by correcting the bid itself: one stored apart
  /// by an earlier version joins the bid, where it can be seen and edited.
  CounterEntry _withHarryInTheBid(CounterEntry entry) => entry.copyWith(
    bid: (entry.bid + entry.bidChange).clamp(0, _cards),
    bidChange: 0,
  );

  /// The most tricks [player] may still be given: the round has only so many.
  int _tricksLeftFor(int player) {
    final others = _round.tricksClaimed - _entries[player].tricksWon;
    return (_cards - others).clamp(_entries[player].tricksWon, _cards);
  }

  /// What is entered so far, as a round of its own: later edits on screen
  /// do not reach it.
  CounterRound get _round => CounterRound(
    entries: List.unmodifiable(_entries),
    alliances: List.unmodifiable(_alliances),
  );

  /// What [player] would score if the round were saved as it stands.
  int _preview(int player) {
    final copy = CounterGame.fromJson(_game.toJson());
    // A correction replaces the round; a new one comes after the others.
    copy.saveRound(widget.round, _round);
    return copy.scoredRounds[widget.round - 1].results[player].score.total;
  }

  void _edit(int player, CounterEntry entry) =>
      setState(() => _entries[player] = entry);

  Future<void> _editBonuses(int player) => showModalBottomSheet<void>(
    context: context,
    backgroundColor: Tokens.panel,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setSheetState) {
        final entry = _entries[player];
        void change(CounterEntry changed) {
          _edit(player, changed);
          setSheetState(() {});
        }

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              Tokens.space4,
              0,
              Tokens.space4,
              Tokens.space4,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Strings.counterBonusFor(_game.players[player]),
                  style: const TextStyle(
                    color: Tokens.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                for (final bonus in Bonus.values)
                  if (_game.secondExpansion || !bonus.isSecondExpansion)
                    _line(
                      Strings.bonusLabel(bonus),
                      _Stepper(
                        name: 'bonus-${bonus.name}',
                        value: entry.bonuses[bonus] ?? 0,
                        max: 5,
                        onChanged: (count) => change(
                          entry.copyWith(
                            bonuses: {...entry.bonuses, bonus: count}
                              ..removeWhere((_, count) => count == 0),
                          ),
                        ),
                      ),
                    ),
                if (_game.piratePowers) ...[
                  _line(
                    Strings.counterWager,
                    SegmentedButton<int>(
                      showSelectedIcon: false,
                      segments: [
                        for (final amount in wagerAmounts)
                          ButtonSegment(value: amount, label: Text('$amount')),
                      ],
                      selected: {entry.wager},
                      onSelectionChanged: (choice) =>
                          change(entry.copyWith(wager: choice.single)),
                    ),
                  ),
                ],
                const SizedBox(height: Tokens.space3),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    key: const Key('counter-bonus-close'),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(Strings.ok),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );

  Widget _line(String label, Widget control) => Padding(
    padding: const EdgeInsets.only(top: Tokens.space3),
    child: Row(
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(color: Tokens.text)),
        ),
        const SizedBox(width: Tokens.space2),
        control,
      ],
    ),
  );

  Future<void> _addAlliance() async {
    var first = 0;
    var second = 1;
    final pair = await showDialog<(int, int)>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          Widget picker(int value, ValueChanged<int> onChanged) =>
              DropdownButton<int>(
                value: value,
                isExpanded: true,
                items: [
                  for (final (player, name) in _game.players.indexed)
                    DropdownMenuItem(value: player, child: Text(name)),
                ],
                onChanged: (player) =>
                    setDialogState(() => onChanged(player ?? value)),
              );
          return AlertDialog(
            title: const Text(Strings.counterAllianceTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                picker(first, (player) => first = player),
                picker(second, (player) => second = player),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(Strings.cancel),
              ),
              FilledButton(
                key: const Key('counter-alliance-ok'),
                onPressed: first == second
                    ? null
                    : () => Navigator.pop(context, (first, second)),
                child: const Text(Strings.ok),
              ),
            ],
          );
        },
      ),
    );
    // The same two players allied twice is entered once.
    if (pair == null) return;
    final known = _alliances.any(
      (other) => {other.$1, other.$2}.containsAll([pair.$1, pair.$2]),
    );
    if (!known) setState(() => _alliances.add(pair));
  }

  @override
  Widget build(BuildContext context) {
    final claimed = _round.tricksClaimed;
    return Scaffold(
      appBar: AppBar(
        title: Text(Strings.counterRoundTitle(widget.round, _cards)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(Tokens.space3),
                children: [
                  Text(
                    _results
                        ? Strings.counterResultsPhase
                        : Strings.counterBidsPhase,
                    style: const TextStyle(
                      color: Tokens.gold,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (_byHand)
                    for (final (player, name) in _game.players.indexed)
                      _manualCard(player, name)
                  else ...[
                    _columnHeadings(),
                    for (final (player, name) in _game.players.indexed)
                      _playerCard(player, name),
                  ],
                  if (_results && _game.loot) _allianceEditor(),
                ],
              ),
            ),
            // Kept in view: it is the one thing to check before saving.
            if (_results && claimed != _cards)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Tokens.space4),
                child: Text(
                  Strings.counterTricksMismatch(claimed, _cards),
                  style: const TextStyle(color: Tokens.danger),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(Tokens.space4),
              child: SizedBox(
                width: double.infinity,
                child: _results
                    ? FilledButton(
                        key: const Key('counter-round-done'),
                        onPressed: () => widget.onSave(_round),
                        child: const Text(Strings.counterRoundDone),
                      )
                    : FilledButton(
                        key: const Key('counter-bids-done'),
                        onPressed: () {
                          widget.onDraft([
                            for (final entry in _entries) entry.bid,
                          ]);
                          setState(() => _results = true);
                        },
                        child: const Text(Strings.counterBidsDone),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The results are entered with a bonus total the players worked out.
  bool get _byHand => _results && _game.manualBonuses;

  /// What a hand-counted bonus moves by, and how far it may go either way.
  static const _bonusStep = 10;
  static const _bonusLimit = 500;

  static const _stepperWidth = 96.0;
  static const _bonusWidth = 40.0;
  static const _scoreWidth = 46.0;

  static const _heading = TextStyle(
    color: Tokens.mutedText,
    fontSize: 12,
    fontWeight: FontWeight.w700,
  );

  /// Names the columns of the player lines.
  Widget _columnHeadings() => Padding(
    padding: const EdgeInsets.fromLTRB(Tokens.space2, Tokens.space2, 0, 0),
    child: Row(
      children: [
        const Spacer(),
        const SizedBox(
          width: _stepperWidth,
          child: Text(
            Strings.counterBid,
            textAlign: TextAlign.center,
            style: _heading,
          ),
        ),
        if (_results) ...[
          const SizedBox(
            width: _stepperWidth,
            child: Text(
              Strings.counterTricks,
              textAlign: TextAlign.center,
              style: _heading,
            ),
          ),
          const SizedBox(width: _bonusWidth + _scoreWidth),
        ],
      ],
    ),
  );

  /// One line a player, so that the whole table is in view at once.
  Widget _playerCard(int player, String name) {
    final entry = _entries[player];
    final hasExtras =
        entry.bonuses.isNotEmpty || entry.wager != 0 || entry.bidChange != 0;
    return Container(
      margin: const EdgeInsets.only(top: Tokens.space1),
      padding: const EdgeInsets.only(left: Tokens.space2),
      decoration: BoxDecoration(
        color: Tokens.panel,
        borderRadius: BorderRadius.circular(Tokens.radiusButton),
        border: Border.all(color: Tokens.outline),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Tokens.text,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          SizedBox(
            width: _stepperWidth,
            child: _Stepper(
              name: 'bid-$player',
              value: entry.bid,
              max: _cards,
              onChanged: (bid) => _edit(player, entry.copyWith(bid: bid)),
            ),
          ),
          if (_results) ...[
            SizedBox(
              width: _stepperWidth,
              child: _Stepper(
                name: 'tricks-$player',
                value: entry.tricksWon,
                max: _tricksLeftFor(player),
                onChanged: (won) =>
                    _edit(player, entry.copyWith(tricksWon: won)),
              ),
            ),
            SizedBox(
              width: _bonusWidth,
              child: IconButton(
                key: Key('counter-bonus-$player'),
                tooltip: Strings.counterBonus,
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                onPressed: () => _editBonuses(player),
                icon: Icon(
                  hasExtras ? Icons.star : Icons.star_border,
                  color: Tokens.gold,
                ),
              ),
            ),
            SizedBox(
              width: _scoreWidth,
              child: Padding(
                padding: const EdgeInsets.only(right: Tokens.space2),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    Strings.signed(_preview(player)),
                    key: Key('counter-preview-$player'),
                    style: const TextStyle(
                      color: Tokens.gold,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// A player's results when the bonuses are counted by hand: the total they
  /// worked out sits beside the bid and the tricks, so it takes two lines.
  Widget _manualCard(int player, String name) {
    final entry = _entries[player];
    Widget labelled(String label, Widget stepper) => Column(
      children: [
        Text(label, style: _heading),
        stepper,
      ],
    );
    return Container(
      margin: const EdgeInsets.only(top: Tokens.space2),
      padding: const EdgeInsets.fromLTRB(
        Tokens.space2,
        Tokens.space2,
        Tokens.space2,
        0,
      ),
      decoration: BoxDecoration(
        color: Tokens.panel,
        borderRadius: BorderRadius.circular(Tokens.radiusButton),
        border: Border.all(color: Tokens.outline),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Tokens.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                Strings.signed(_preview(player)),
                key: Key('counter-preview-$player'),
                style: const TextStyle(
                  color: Tokens.gold,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: Tokens.space1),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              labelled(
                Strings.counterBid,
                _Stepper(
                  name: 'bid-$player',
                  value: entry.bid,
                  max: _cards,
                  onChanged: (bid) => _edit(player, entry.copyWith(bid: bid)),
                ),
              ),
              labelled(
                Strings.counterTricks,
                _Stepper(
                  name: 'tricks-$player',
                  value: entry.tricksWon,
                  max: _tricksLeftFor(player),
                  onChanged: (won) =>
                      _edit(player, entry.copyWith(tricksWon: won)),
                ),
              ),
              labelled(
                Strings.counterBonus,
                _Stepper(
                  name: 'manual-bonus-$player',
                  value: entry.manualBonus,
                  min: -_bonusLimit,
                  max: _bonusLimit,
                  step: _bonusStep,
                  valueWidth: 40,
                  onChanged: (points) =>
                      _edit(player, entry.copyWith(manualBonus: points)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _allianceEditor() => Padding(
    padding: const EdgeInsets.only(top: Tokens.space4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          Strings.counterAlliances,
          style: TextStyle(color: Tokens.text, fontWeight: FontWeight.w800),
        ),
        for (final (index, (first, second)) in _alliances.indexed)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              Strings.counterAlliance(
                _game.players[first],
                _game.players[second],
              ),
            ),
            trailing: IconButton(
              tooltip: Strings.delete,
              onPressed: () => setState(() => _alliances.removeAt(index)),
              icon: const Icon(Icons.close),
            ),
          ),
        TextButton.icon(
          key: const Key('counter-add-alliance'),
          onPressed: _addAlliance,
          icon: const Icon(Icons.add),
          label: const Text(Strings.counterAddAlliance),
        ),
      ],
    ),
  );
}

/// A number with a button on each side to lower or raise it.
class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.name,
    required this.value,
    required this.max,
    required this.onChanged,
    this.min = 0,
    this.step = 1,
    this.valueWidth = 26,
  });

  /// Names the two buttons for tests: `<name>-minus` and `<name>-plus`.
  final String name;
  final int value;
  final int max;
  final ValueChanged<int> onChanged;
  final int min;

  /// What one press adds or takes away.
  final int step;
  final double valueWidth;

  @override
  Widget build(BuildContext context) {
    Widget button(String side, IconData icon, int? next) => IconButton(
      key: Key('$name-$side'),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 34, minHeight: 40),
      style: IconButton.styleFrom(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: next == null ? null : () => onChanged(next),
      icon: Icon(icon),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        button(
          'minus',
          Icons.remove_circle_outline,
          value - step >= min ? value - step : null,
        ),
        SizedBox(
          width: valueWidth,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '$value',
              key: Key('$name-value'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Tokens.text,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        button(
          'plus',
          Icons.add_circle_outline,
          value + step <= max ? value + step : null,
        ),
      ],
    );
  }
}
