import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import '../ui/rules_content.dart';
import '../ui/strings.dart';

/// The rules of the base game, to read at any time.
class RulesScreen extends StatelessWidget {
  const RulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(Strings.rulesTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(Tokens.space4),
          children: [
            for (final section in RulesContent.sections) ...[
              Text(
                section.title,
                style: const TextStyle(
                  color: Tokens.gold,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: Tokens.space2),
              Text(
                section.body,
                style: const TextStyle(color: Tokens.text, height: 1.4),
              ),
              const SizedBox(height: Tokens.space6),
            ],
          ],
        ),
      ),
    );
  }
}
