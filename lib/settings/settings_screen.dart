import 'package:flutter/material.dart';

import 'profile_dialog.dart';
import '../theme/tokens.dart';
import '../ui/strings.dart';
import 'app_settings.dart';

/// Where the player sets how the game plays and who they are.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.settings});

  final AppSettings settings;

  static String _speedName(BotSpeed speed) => switch (speed) {
    BotSpeed.normal => Strings.speedNormal,
    BotSpeed.fast => Strings.speedFast,
    BotSpeed.instant => Strings.speedInstant,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(Strings.settings)),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: settings,
          builder: (context, _) => ListView(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(
                  Tokens.space4,
                  Tokens.space4,
                  Tokens.space4,
                  Tokens.space2,
                ),
                child: Text(Strings.botSpeedLabel),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Tokens.space4),
                child: SegmentedButton<BotSpeed>(
                  showSelectedIcon: false,
                  segments: [
                    for (final speed in BotSpeed.values)
                      ButtonSegment(
                        value: speed,
                        label: FittedBox(child: Text(_speedName(speed))),
                      ),
                  ],
                  selected: {settings.botSpeed},
                  onSelectionChanged: (selection) =>
                      settings.setBotSpeed(selection.single),
                ),
              ),
              const SizedBox(height: Tokens.space2),
              SwitchListTile(
                title: const Text(Strings.singleTapPlay),
                subtitle: const Text(Strings.singleTapPlayHelp),
                value: settings.singleTapPlay,
                onChanged: settings.setSingleTapPlay,
              ),
              SwitchListTile(
                title: const Text(Strings.hapticsLabel),
                value: settings.haptics,
                onChanged: settings.setHaptics,
              ),
              SwitchListTile(
                title: const Text(Strings.reduceMotionLabel),
                value: settings.reduceMotion,
                onChanged: settings.setReduceMotion,
              ),
              SwitchListTile(
                key: const Key('setting-trick-tokens'),
                title: const Text(Strings.trickTokensLabel),
                subtitle: const Text(Strings.trickTokensHelp),
                value: settings.trickTokens,
                onChanged: settings.setTrickTokens,
              ),
              SwitchListTile(
                key: const Key('setting-auto-harry'),
                title: const Text(Strings.autoHarryLabel),
                subtitle: const Text(Strings.autoHarryHelp),
                value: settings.autoHarry,
                onChanged: settings.setAutoHarry,
              ),
              const Divider(),
              ListTile(
                leading: CircleAvatar(
                  radius: 14,
                  backgroundColor: Tokens.playerColors[settings.playerColor],
                ),
                title: const Text(Strings.profileTitle),
                subtitle: Text(settings.playerName),
                onTap: () => showDialog<void>(
                  context: context,
                  builder: (context) => ProfileDialog(settings: settings),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: const Text(Strings.licenses),
                subtitle: const Text(Strings.licensesHelp),
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: Strings.appTitle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
