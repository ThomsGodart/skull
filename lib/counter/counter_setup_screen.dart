import 'package:flutter/material.dart';

import '../engine/engine.dart';
import '../settings/app_settings.dart';
import '../theme/tokens.dart';
import '../ui/strings.dart';
import 'counter_game.dart';

/// Where a game to count is set up: who plays, who leads, which rules.
class CounterSetupScreen extends StatefulWidget {
  const CounterSetupScreen({
    super.key,
    required this.settings,
    required this.onStart,
  });

  final AppSettings settings;
  final ValueChanged<CounterGame> onStart;

  @override
  State<CounterSetupScreen> createState() => _CounterSetupScreenState();
}

class _CounterSetupScreenState extends State<CounterSetupScreen> {
  late final List<TextEditingController> _names = [
    for (var i = 0; i < 3; i++)
      TextEditingController(
        text: widget.settings.knownPlayers.elementAtOrNull(i) ?? '',
      ),
  ];
  int _firstLeader = 0;
  Scoring _scoring = Scoring.classic;
  bool _loot = false;
  bool _powers = false;

  @override
  void dispose() {
    for (final name in _names) {
      name.dispose();
    }
    super.dispose();
  }

  List<String> get _entered => [for (final name in _names) name.text.trim()];

  /// Names used in earlier games and not yet at this table.
  List<String> get _suggestions => [
    for (final name in widget.settings.knownPlayers)
      if (!_entered.contains(name)) name,
  ];

  /// Seats a known player: in the first empty field, or in a new one.
  void _suggest(String name) => setState(() {
    final empty = _names.where((field) => field.text.trim().isEmpty);
    if (empty.isNotEmpty) {
      empty.first.text = name;
    } else if (_names.length < maxPlayers) {
      _names.add(TextEditingController(text: name));
    }
  });

  void _start() {
    final names = _entered;
    final problem = names.any((name) => name.isEmpty)
        ? Strings.counterNeedNames
        : names.toSet().length != names.length
        ? Strings.counterDistinctNames
        : null;
    if (problem != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(problem)));
      return;
    }
    widget.onStart(
      CounterGame(
        players: names,
        firstLeader: _firstLeader,
        scoring: _scoring,
        loot: _loot,
        piratePowers: _powers,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(Strings.counterNew)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(Tokens.space4),
                children: [
                  const Text(
                    Strings.counterPlayers,
                    style: TextStyle(color: Tokens.text),
                  ),
                  for (final (index, name) in _names.indexed)
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            key: Key('counter-name-$index'),
                            controller: name,
                            maxLength: AppSettings.maxNameLength,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: Strings.counterPlayerHint(index + 1),
                              counterText: '',
                            ),
                          ),
                        ),
                        if (_names.length > minPlayers)
                          IconButton(
                            tooltip: Strings.counterRemovePlayer,
                            onPressed: () => setState(() {
                              _names.removeAt(index).dispose();
                              // The first leader stays the same person, or
                              // goes back to the first player if they left.
                              if (index == _firstLeader) {
                                _firstLeader = 0;
                              } else if (index < _firstLeader) {
                                _firstLeader--;
                              }
                            }),
                            icon: const Icon(Icons.close),
                          ),
                      ],
                    ),
                  if (_names.length < maxPlayers)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        key: const Key('counter-add-player'),
                        onPressed: () =>
                            setState(() => _names.add(TextEditingController())),
                        icon: const Icon(Icons.add),
                        label: const Text(Strings.counterAddPlayer),
                      ),
                    ),
                  if (_suggestions.isNotEmpty)
                    Wrap(
                      spacing: Tokens.space2,
                      children: [
                        for (final name in _suggestions)
                          ActionChip(
                            label: Text(name),
                            onPressed: () => _suggest(name),
                          ),
                      ],
                    ),
                  const SizedBox(height: Tokens.space3),
                  const Text(
                    Strings.counterFirstLeader,
                    style: TextStyle(color: Tokens.text),
                  ),
                  DropdownButton<int>(
                    value: _firstLeader,
                    isExpanded: true,
                    items: [
                      for (final (index, name) in _entered.indexed)
                        DropdownMenuItem(
                          value: index,
                          child: Text(
                            name.isEmpty
                                ? Strings.counterPlayerHint(index + 1)
                                : name,
                          ),
                        ),
                    ],
                    onChanged: (index) =>
                        setState(() => _firstLeader = index ?? 0),
                  ),
                  const SizedBox(height: Tokens.space3),
                  const Text(
                    Strings.scoringLabel,
                    style: TextStyle(color: Tokens.text),
                  ),
                  const SizedBox(height: Tokens.space2),
                  SegmentedButton<Scoring>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                        value: Scoring.classic,
                        label: Text(Strings.scoringClassic),
                      ),
                      ButtonSegment(
                        value: Scoring.rascal,
                        label: Text(Strings.scoringRascal),
                      ),
                    ],
                    selected: {_scoring},
                    onSelectionChanged: (choice) =>
                        setState(() => _scoring = choice.single),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(Strings.optionLoot),
                    subtitle: const Text(Strings.optionLootHelp),
                    value: _loot,
                    onChanged: (on) => setState(() => _loot = on),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(Strings.optionPowers),
                    subtitle: const Text(Strings.optionPowersHelp),
                    value: _powers,
                    onChanged: (on) => setState(() => _powers = on),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(Tokens.space4),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const Key('counter-start'),
                  onPressed: _start,
                  child: const Text(Strings.counterStart),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
