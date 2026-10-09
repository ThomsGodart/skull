import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'pictogram.dart';

/// Something to look at while waiting: a ship's wheel that keeps turning.
/// It stands still for whoever asked the phone for less motion.
class PirateLoader extends StatefulWidget {
  const PirateLoader({super.key, this.size = 56});

  final double size;

  @override
  State<PirateLoader> createState() => _PirateLoaderState();
}

class _PirateLoaderState extends State<PirateLoader>
    with SingleTickerProviderStateMixin {
  late final _turn = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _turn.stop();
    } else if (!_turn.isAnimating) {
      _turn.repeat();
    }
  }

  @override
  void dispose() {
    _turn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RotationTransition(
    turns: _turn,
    // The ship's wheel of the bundled font.
    child: Pictogram('☸', size: widget.size, color: Tokens.gold),
  );
}
