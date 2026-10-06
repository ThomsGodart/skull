import 'package:flutter/material.dart';

import '../engine/engine.dart';
import '../settings/app_settings.dart';
import '../theme/tokens.dart';
import '../ui/strings.dart';

enum _Preset { classic, full, custom }

/// Where a new game is set up. Calls [onLaunch] with what to play; the seed
/// it carries means nothing.
class SetupScreen extends StatefulWidget {
  const SetupScreen({
    super.key,
    required this.settings,
    required this.onLaunch,
  });

  final AppSettings settings;
  final ValueChanged<GameConfig> onLaunch;

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  late GameConfig _setup = widget.settings.lastSetup;
  late _Preset _preset = _setup.usesFullExpansion
      ? _Preset.full
      : _setup.usesExpansion
      ? _Preset.custom
      : _Preset.classic;

  static int _lastRoundCards(int players) =>
      cardsDealt(round: standardRounds, players: players);

  void _choosePreset(_Preset preset) => setState(() {
    _preset = preset;
    if (preset == _Preset.custom) return;
    final on = preset == _Preset.full;
    _setup = _setup.copyWith(
      kraken: on,
      whiteWhale: on,
      loot: on,
      piratePowers: on,
    );
  });

  void _change(GameConfig setup) => setState(() => _setup = setup);

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(top: Tokens.space4, bottom: Tokens.space2),
    child: Text(text, style: const TextStyle(color: Tokens.text)),
  );

  Widget _option(
    String title,
    String help,
    bool value,
    GameConfig Function(bool) change,
  ) => SwitchListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(title),
    subtitle: Text(help),
    value: value,
    onChanged: (on) => _change(change(on)),
  );

  @override
  Widget build(BuildContext context) {
    final players = _setup.players;
    return Scaffold(
      appBar: AppBar(title: const Text(Strings.setupTitle)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: Tokens.space6),
                children: [
                  _label(Strings.opponents),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: players - 1 > AppSettings.minOpponents
                            ? () =>
                                  _change(_setup.copyWith(players: players - 1))
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      SizedBox(
                        width: Tokens.tapTarget,
                        child: Text(
                          '${players - 1}',
                          key: const Key('opponents'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Tokens.text,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: players - 1 < AppSettings.maxOpponents
                            ? () =>
                                  _change(_setup.copyWith(players: players + 1))
                            : null,
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                  _label(Strings.presetLabel),
                  SegmentedButton<_Preset>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                        value: _Preset.classic,
                        label: FittedBox(child: Text(Strings.presetClassic)),
                      ),
                      ButtonSegment(
                        value: _Preset.full,
                        label: FittedBox(child: Text(Strings.presetFull)),
                      ),
                      ButtonSegment(
                        value: _Preset.custom,
                        label: FittedBox(child: Text(Strings.presetCustom)),
                      ),
                    ],
                    selected: {_preset},
                    onSelectionChanged: (choice) =>
                        _choosePreset(choice.single),
                  ),
                  if (_preset == _Preset.custom) ...[
                    _option(
                      Strings.optionKraken,
                      Strings.optionKrakenHelp,
                      _setup.kraken,
                      (on) => _setup.copyWith(kraken: on),
                    ),
                    _option(
                      Strings.optionWhale,
                      Strings.optionWhaleHelp,
                      _setup.whiteWhale,
                      (on) => _setup.copyWith(whiteWhale: on),
                    ),
                    _option(
                      Strings.optionLoot,
                      Strings.optionLootHelp,
                      _setup.loot,
                      (on) => _setup.copyWith(loot: on),
                    ),
                    _option(
                      Strings.optionPowers,
                      Strings.optionPowersHelp,
                      _setup.piratePowers,
                      (on) => _setup.copyWith(piratePowers: on),
                    ),
                  ],
                  _label(Strings.scoringLabel),
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
                    selected: {_setup.scoring},
                    onSelectionChanged: (choice) =>
                        _change(_setup.copyWith(scoring: choice.single)),
                  ),
                  if (_setup.scoring == Scoring.rascal)
                    const Padding(
                      padding: EdgeInsets.only(top: Tokens.space2),
                      child: Text(
                        Strings.scoringRascalHelp,
                        style: TextStyle(color: Tokens.mutedText),
                      ),
                    ),
                  const SizedBox(height: Tokens.space4),
                  Text(
                    Strings.setupSummary(_setup),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Tokens.mutedText),
                  ),
                  if (players == minPlayers) ...[
                    const SizedBox(height: Tokens.space2),
                    const Text(
                      Strings.twoPlayersNote,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Tokens.mutedText),
                    ),
                  ],
                  if (_lastRoundCards(players) < standardRounds) ...[
                    const SizedBox(height: Tokens.space2),
                    Text(
                      Strings.fewerCardsNote(players, _lastRoundCards(players)),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Tokens.mutedText),
                    ),
                  ],
                  const SizedBox(height: Tokens.space4),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(Tokens.space4),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const Key('launch'),
                  onPressed: () => widget.onLaunch(_setup),
                  child: const Text(Strings.launch),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
