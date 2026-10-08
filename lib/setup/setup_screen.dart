import 'package:flutter/material.dart';

import '../bots/bot_level.dart';
import '../engine/engine.dart';
import '../settings/app_settings.dart';
import '../theme/tokens.dart';
import '../ui/strings.dart';

enum _Preset { classic, full, custom }

/// Where a new game is set up. Calls [onLaunch] with what to play and how
/// good the bots are; the seed the setup carries means nothing.
class SetupScreen extends StatefulWidget {
  const SetupScreen({
    super.key,
    required this.settings,
    required this.onLaunch,
    this.online = false,
  });

  /// The game is set up for a room: who plays is only known once it starts,
  /// so the number of players is not asked here.
  final bool online;

  final AppSettings settings;
  final void Function(GameConfig setup, BotLevel level) onLaunch;

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  late GameConfig _setup = widget.settings.lastSetup;
  late BotLevel _level = widget.settings.botLevel;
  late _Preset _preset = _setup.usesFullExpansion
      ? _Preset.full
      : _setup.usesExpansion
      ? _Preset.custom
      : _Preset.classic;

  int _lastRoundCards(int players) => cardsDealt(
    round: standardRounds,
    players: players,
    secondExpansion: _setup.playsSecondExpansion,
  );

  int _cardsForRound(int round, int players) => cardsDealt(
    round: round,
    players: players,
    secondExpansion: _setup.playsSecondExpansion,
  );

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

  bool _firstCardOn(CardKind kind) => switch (kind) {
    CardKind.kraken => _setup.kraken,
    CardKind.whiteWhale => _setup.whiteWhale,
    CardKind.loot => _setup.loot,
    _ => false,
  };

  void _setFirstCard(CardKind kind, bool on) => _change(switch (kind) {
    CardKind.kraken => _setup.copyWith(kraken: on),
    CardKind.whiteWhale => _setup.copyWith(whiteWhale: on),
    CardKind.loot => _setup.copyWith(loot: on),
    _ => _setup,
  });

  String _firstCardTitle(CardKind kind) => switch (kind) {
    CardKind.kraken => Strings.optionKraken,
    CardKind.whiteWhale => Strings.optionWhale,
    CardKind.loot => Strings.optionLoot,
    _ => kind.name,
  };

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
    final online = widget.online;
    // Online, any option may end up applying: the table can be of any size.
    final players = online ? maxPlayers : _setup.players;
    final maxStart = standardRounds;
    return Scaffold(
      appBar: AppBar(title: const Text(Strings.setupTitle)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: Tokens.space6),
                children: [
                  if (online)
                    const Padding(
                      padding: EdgeInsets.only(top: Tokens.space4),
                      child: Text(
                        Strings.onlineSetupNote,
                        style: TextStyle(color: Tokens.mutedText),
                      ),
                    )
                  else ...[
                    _label(Strings.opponents),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: players - 1 > AppSettings.minOpponents
                              ? () => _change(
                                  _setup.copyWith(players: players - 1),
                                )
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
                              ? () => _change(
                                  _setup.copyWith(players: players + 1),
                                )
                              : null,
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                      ],
                    ),
                  ],
                  _label(Strings.botLevelLabel),
                  SegmentedButton<BotLevel>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                        value: BotLevel.easy,
                        label: FittedBox(child: Text(Strings.levelEasy)),
                      ),
                      ButtonSegment(
                        value: BotLevel.normal,
                        label: FittedBox(child: Text(Strings.levelNormal)),
                      ),
                      ButtonSegment(
                        value: BotLevel.hard,
                        label: FittedBox(child: Text(Strings.levelHard)),
                      ),
                    ],
                    selected: {_level},
                    onSelectionChanged: (choice) =>
                        setState(() => _level = choice.single),
                  ),
                  if (_level != BotLevel.normal)
                    Padding(
                      padding: const EdgeInsets.only(top: Tokens.space2),
                      child: Text(
                        _level == BotLevel.hard
                            ? Strings.levelHardHelp
                            : Strings.levelEasyHelp,
                        style: const TextStyle(color: Tokens.mutedText),
                      ),
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
                    _label(Strings.optionFirstExpansion),
                    Text(
                      Strings.optionFirstExpansionHelp,
                      style: const TextStyle(color: Tokens.mutedText),
                    ),
                    for (final kind in GameConfig.firstExpansionKinds)
                      if (kind != CardKind.loot || players > minPlayers)
                        CheckboxListTile(
                          key: Key('first-${kind.name}'),
                          dense: true,
                          contentPadding: const EdgeInsets.only(
                            left: Tokens.space4,
                          ),
                          title: Text(_firstCardTitle(kind)),
                          value: _firstCardOn(kind),
                          onChanged: (on) =>
                              _setFirstCard(kind, on ?? false),
                        ),
                    _option(
                      Strings.optionPowers,
                      Strings.optionPowersHelp,
                      _setup.piratePowers,
                      (on) => _setup.copyWith(piratePowers: on),
                    ),
                  ],
                  if (players > minPlayers)
                    _option(
                      Strings.optionSecondExpansion,
                      Strings.optionSecondExpansionHelp,
                      _setup.secondExpansion,
                      (on) => _setup.copyWith(secondExpansion: on),
                    ),
                  if (_setup.secondExpansion && players > minPlayers)
                    for (final kind in GameConfig.optionalKinds)
                      CheckboxListTile(
                        key: Key('optional-${kind.name}'),
                        dense: true,
                        contentPadding: const EdgeInsets.only(
                          left: Tokens.space4,
                        ),
                        title: Text(Strings.optionalCard(kind)),
                        value: !_setup.leftOut.contains(kind),
                        onChanged: (on) => _change(
                          _setup.copyWith(
                            leftOut: on ?? true
                                ? ({..._setup.leftOut}..remove(kind))
                                : {..._setup.leftOut, kind},
                          ),
                        ),
                      ),
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
                  _label(Strings.startingRoundLabel),
                  DropdownButton<int>(
                    key: const Key('starting-round'),
                    value: _setup.startingRound.clamp(1, maxStart),
                    isExpanded: true,
                    items: [
                      for (var round = 1; round <= maxStart; round++)
                        DropdownMenuItem(
                          value: round,
                          child: Text(
                            Strings.startingRoundOption(
                              round,
                              _cardsForRound(round, online ? 4 : players),
                            ),
                          ),
                        ),
                    ],
                    onChanged: (round) {
                      if (round != null) {
                        _change(_setup.copyWith(startingRound: round));
                      }
                    },
                  ),
                  const SizedBox(height: Tokens.space4),
                  Text(
                    online
                        ? Strings.modeName(_setup)
                        : Strings.setupSummary(_setup),
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
                  if (!online && _lastRoundCards(players) < standardRounds) ...[
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
                  onPressed: () => widget.onLaunch(_setup, _level),
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
