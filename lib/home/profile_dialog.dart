import 'package:flutter/material.dart';

import '../settings/app_settings.dart';
import '../theme/tokens.dart';
import '../ui/strings.dart';

/// Lets the player choose their name and colour, and saves them.
class ProfileDialog extends StatefulWidget {
  const ProfileDialog({super.key, required this.settings});

  final AppSettings settings;

  @override
  State<ProfileDialog> createState() => _ProfileDialogState();
}

class _ProfileDialogState extends State<ProfileDialog> {
  late final _name = TextEditingController(text: widget.settings.playerName);
  late int _color = widget.settings.playerColor;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(Strings.profileTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _name,
            maxLength: AppSettings.maxNameLength,
            decoration: const InputDecoration(
              labelText: Strings.playerNameLabel,
            ),
          ),
          const SizedBox(height: Tokens.space2),
          const Text(Strings.playerColorLabel),
          const SizedBox(height: Tokens.space2),
          Wrap(
            spacing: Tokens.space2,
            children: [
              for (final (index, color) in Tokens.playerColors.indexed)
                InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => setState(() => _color = index),
                  child: Container(
                    width: Tokens.tapTarget,
                    height: Tokens.tapTarget,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: index == _color ? Tokens.text : Tokens.outline,
                        width: index == _color ? 3 : 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(Strings.cancel),
        ),
        FilledButton(
          onPressed: () {
            widget.settings.setPlayer(name: _name.text, color: _color);
            Navigator.pop(context);
          },
          child: const Text(Strings.save),
        ),
      ],
    );
  }
}
