import 'package:flutter/foundation.dart';

import '../engine/engine.dart';
import 'game_controller.dart';

/// What the player is doing at the table of a [GameController]: the card
/// they lifted or are looking at, whether it may be played, and what the
/// game needs asked or shown to them.
///
/// It notifies its listeners of every change, the game's own included, so a
/// table listens to this alone.
class TableInteraction extends ChangeNotifier {
  TableInteraction(this._game, {bool Function()? autoHarry})
    : _autoHarry = autoHarry ?? (() => false) {
    _game.addListener(_onGameChanged);
  }

  final GameController _game;

  /// Whether Harry's power is used without asking. Read each time, since the
  /// player may change their mind during the game.
  final bool Function() _autoHarry;

  /// Called once each time the turn to play comes to the player.
  VoidCallback? onTurn;

  /// Called once for each pirate power the player must be asked about.
  void Function(AfterTrickQuestion question)? onPower;

  /// Called once with the stock Juanita shows the player.
  void Function(List<Card> stock)? onStock;

  /// The card lifted, waiting to be played. It stays lifted while the others
  /// play, for as long as it is in the hand.
  Card? get selected => _selected;
  Card? _selected;

  /// A card the player only looks at, since it cannot be played now.
  Card? get inspected => _inspected;
  Card? _inspected;

  /// The card to tell the player about, lifted or looked at.
  Card? get shown => _selected ?? _inspected;

  /// Whether the lifted card may be played right now.
  bool get canPlay => _selected != null && _playable(_selected!);

  bool _turnSignalled = false;
  AfterTrickQuestion? _powerHandled;
  List<Card>? _stockHandled;

  bool _playable(Card card) {
    // A card Mary forces is then the only legal one.
    return _game.playQuestion?.legalCards.contains(card) ?? false;
  }

  /// Lifts [card], or puts it back if it was lifted.
  void tap(Card card) {
    _selected = card == _selected ? null : card;
    _inspected = null;
    notifyListeners();
  }

  /// Looks at [card], or stops looking at it.
  void inspect(Card card) {
    _inspected = card == _inspected ? null : card;
    notifyListeners();
  }

  /// Puts back whatever card is lifted or looked at.
  void clear() {
    _selected = null;
    _inspected = null;
    notifyListeners();
  }

  /// What Harry does to a bid of [bid] after [tricksWon] tricks when left to
  /// himself: he moves it towards the tricks taken, if [changes] allow.
  static int harryChange(int bid, int tricksWon, List<int> changes) {
    final wanted = (tricksWon - bid).clamp(-1, 1);
    return changes.contains(wanted) ? wanted : 0;
  }

  void _onGameChanged() {
    if (!_game.hand.contains(_selected)) _selected = null;
    if (!_game.hand.contains(_inspected)) _inspected = null;
    // A card looked at while waiting becomes the selection once it may be
    // played.
    if (_selected == null && _inspected != null && _playable(_inspected!)) {
      _selected = _inspected;
      _inspected = null;
    }
    final turnBegins = _game.playQuestion != null && !_turnSignalled;
    _turnSignalled = _game.playQuestion != null;
    notifyListeners();
    if (turnBegins) onTurn?.call();

    final power = _game.afterTrickQuestion;
    if (power != null && !identical(power, _powerHandled)) {
      _powerHandled = power;
      if (power case AdjustBidQuestion(:final seat, :final changes)
          when _autoHarry()) {
        _game.answerAfterTrick(
          AdjustBidAnswer(
            seat: seat,
            change: harryChange(
              _game.bids[seat] ?? 0,
              _game.tricksWon[seat],
              changes,
            ),
          ),
        );
      } else {
        onPower?.call(power);
      }
    }
    final stock = _game.revealedStock;
    if (stock != null && !identical(stock, _stockHandled)) {
      _stockHandled = stock;
      onStock?.call(stock);
    }
  }

  @override
  void dispose() {
    _game.removeListener(_onGameChanged);
    super.dispose();
  }
}
