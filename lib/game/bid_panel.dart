import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import '../ui/strings.dart';

/// Lets the human pick a bid from 0 to [maxBid] and confirm it.
class BidPanel extends StatefulWidget {
  const BidPanel({
    super.key,
    required this.maxBid,
    required this.onBid,
    this.initialBid,
  });

  /// The bid already placed, when it is being changed.
  final int? initialBid;
  final int maxBid;
  final ValueChanged<int> onBid;

  @override
  State<BidPanel> createState() => _BidPanelState();
}

class _BidPanelState extends State<BidPanel> {
  late int? _bid = widget.initialBid;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          Strings.chooseBid,
          style: TextStyle(color: Tokens.text, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: Tokens.space2),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: Tokens.space2,
          runSpacing: Tokens.space2,
          children: [
            for (var bid = 0; bid <= widget.maxBid; bid++)
              SizedBox(
                width: Tokens.tapTarget,
                height: Tokens.tapTarget,
                child: Material(
                  color: bid == _bid ? Tokens.gold : Tokens.panelRaised,
                  shape: const CircleBorder(),
                  child: InkWell(
                    key: Key('bid-$bid'),
                    customBorder: const CircleBorder(),
                    onTap: () => setState(() => _bid = bid),
                    child: Center(
                      child: Text(
                        '$bid',
                        style: TextStyle(
                          color: bid == _bid ? Tokens.sea : Tokens.text,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: Tokens.space3),
        FilledButton(
          key: const Key('place-bid'),
          onPressed: _bid == null ? null : () => widget.onBid(_bid!),
          child: Text(
            _bid == null ? Strings.pickBidFirst : Strings.placeBid(_bid!),
          ),
        ),
      ],
    );
  }
}
