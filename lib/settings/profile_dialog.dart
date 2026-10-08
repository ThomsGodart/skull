import 'package:flutter/material.dart';

import 'app_settings.dart';
import '../theme/tokens.dart';
import '../ui/strings.dart';

/// Lets the player choose their name and colour, and saves them.
class ProfileDialog extends StatefulWidget {
  const ProfileDialog({
    super.key,
    required this.settings,
    this.prompt,
    this.requireRealName = false,
  });

  final AppSettings settings;

  /// Why the player is asked, when the dialog opens by itself.
  final String? prompt;

  /// When true, « Toi » and a blank name cannot be saved, and cancel is hidden.
  final bool requireRealName;

  @override
  State<ProfileDialog> createState() => _ProfileDialogState();
}

class _ProfileDialogState extends State<ProfileDialog> {
  late final _name = TextEditingController(
    text: AppSettings.isForbiddenName(widget.settings.playerName)
        ? ''
        : widget.settings.playerName,
  );
  late int _color = widget.settings.playerColor;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    if (widget.requireRealName && AppSettings.isForbiddenName(_name.text)) {
      setState(() => _error = Strings.nameForbidden);
      return;
    }
    widget.settings.setPlayer(name: _name.text, color: _color);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(Strings.profileTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.prompt case final prompt?)
            Padding(
              padding: const EdgeInsets.only(bottom: Tokens.space3),
              child: Text(prompt),
            ),
          TextField(
            key: const Key('profile-name'),
            controller: _name,
            maxLength: AppSettings.maxNameLength,
            decoration: InputDecoration(
              labelText: Strings.playerNameLabel,
              errorText: _error,
            ),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
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
        if (!widget.requireRealName)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(Strings.cancel),
          ),
        FilledButton(
          key: const Key('profile-save'),
          onPressed: _save,
          child: const Text(Strings.save),
        ),
      ],
    );
  }
}
