import 'package:flutter/material.dart' hide Card;
import 'package:flutter/services.dart';

import '../engine/engine.dart';
import '../rules/rules_screen.dart';
import '../settings/app_settings.dart';
import '../theme/tokens.dart';
import '../ui/cards/card_look.dart';
import '../ui/cards/card_view.dart';
import '../ui/cards/hand_fan.dart';
import '../ui/pictogram.dart';
import '../ui/strings.dart';
import 'bid_panel.dart';
import 'game_controller.dart';
import 'power_dialog.dart';
import 'score_views.dart';
import 'screen_awake.dart';
import 'seat_chip.dart';
import 'seat_identity.dart';
import 'trick_area.dart';

/// The table of a game in progress. Owns [controller] from here on.
class TableScreen extends StatefulWidget {
  const TableScreen({
    super.key,
    required this.controller,
    required this.onPlayAgain,
    this.human = const SeatIdentity(Strings.you, Tokens.gold),
    this.settings,
    this.screenAwake = const WakelockScreenAwake(),
  });

  /// The player's play options. Defaults apply when there are none.
  final AppSettings? settings;

  /// Keeps the screen on for as long as the table is open.
  final ScreenAwake screenAwake;

  /// Who the human is, as shown at their seat.
  final SeatIdentity human;

  final GameController controller;

  /// Starts a fresh game with the same setup.
  final VoidCallback onPlayAgain;

  @override
  State<TableScreen> createState() => _TableScreenState();
}

class _TableScreenState extends State<TableScreen> {
  late final List<SeatIdentity> _seats = SeatIdentity.table(
    widget.controller.seats,
    human: widget.human,
    ghostSeat: widget.controller.ghostSeat,
  );

  /// The seats that appear on a score sheet: every one but the ghost's.
  late final List<SeatIdentity> _scoringSeats = _seats
      .take(widget.controller.scoringSeats)
      .toList();

  /// The card lifted by a first tap, waiting for the second.
  Card? _selected;

  GameController get _game => widget.controller;

  @override
  void initState() {
    super.initState();
    _game.addListener(_onGameChanged);
    _game.start();
    _openTables++;
    widget.screenAwake.keepOn();
  }

  /// Tables currently open. When one replaces another, the new one opens
  /// before the old one closes: the screen must stay on in between.
  static int _openTables = 0;

  bool get _singleTap => widget.settings?.singleTapPlay ?? false;

  void _vibrate(Future<void> Function() feedback) {
    if (widget.settings?.haptics ?? true) feedback();
  }

  @override
  void dispose() {
    if (--_openTables == 0) widget.screenAwake.release();
    _game
      ..removeListener(_onGameChanged)
      ..dispose();
    super.dispose();
  }

  void _onGameChanged() {
    if (_game.playQuestion == null) _selected = null;
    setState(() {});
    final power = _game.powerQuestion;
    if (power != null && !identical(power, _powerShown)) {
      _powerShown = power;
      _askPower(power);
    }
    final stock = _game.revealedStock;
    if (stock != null && !identical(stock, _stockShown)) {
      _stockShown = stock;
      _showStock(stock);
    }
  }

  /// The power question and the stock a dialog was already opened for.
  PowerQuestion? _powerShown;
  List<Card>? _stockShown;

  bool get _namedPirates => _game.config.piratePowers;

  /// Dialogs that show cards take nearly the whole width of the screen.
  static const _dialogInset = EdgeInsets.symmetric(
    horizontal: Tokens.space3,
    vertical: Tokens.space6,
  );

  /// A pirate just won the human a trick: a dialog asks how to use its power.
  /// It cannot be dismissed, since the game waits for the answer.
  Future<void> _askPower(PowerQuestion question) async {
    final answer = await showDialog<Answer>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: PowerDialog(
          question: question,
          seats: _seats,
          bid: _game.bids[_game.humanSeat] ?? 0,
          tricksWon: _game.tricksWon[_game.humanSeat],
          namedPirates: _namedPirates,
        ),
      ),
    );
    if (answer != null) _game.answerPower(answer);
  }

  /// Juanita's power: the cards nobody was dealt.
  Future<void> _showStock(List<Card> stock) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Tokens.panel,
        insetPadding: _dialogInset,
        title: Text(Strings.pirateName(Pirate.juanita)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(Strings.stockBody),
              const SizedBox(height: Tokens.space3),
              Wrap(
                spacing: Tokens.space1,
                runSpacing: Tokens.space1,
                children: [
                  for (final card in sortedHand(stock))
                    CardView(card, width: 62, namedPirates: _namedPirates),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            key: const Key('stock-close'),
            onPressed: () => Navigator.pop(context),
            child: const Text(Strings.close),
          ),
        ],
      ),
    );
    _game.dismissStock();
  }

  Future<void> _onCardTap(Card card) async {
    if (card != _selected && !_singleTap) {
      _vibrate(HapticFeedback.selectionClick);
      setState(() => _selected = card);
      return;
    }
    TigressMode? mode;
    if (card.kind == CardKind.tigress) {
      mode = await _askTigressMode();
      if (mode == null || !mounted) return;
    }
    _vibrate(HapticFeedback.lightImpact);
    _game.play(card, tigressAs: mode);
  }

  Future<TigressMode?> _askTigressMode() => showDialog<TigressMode>(
    context: context,
    builder: (context) => SimpleDialog(
      title: const Text(Strings.tigressTitle),
      children: [
        SimpleDialogOption(
          key: const Key('tigress-pirate'),
          onPressed: () => Navigator.pop(context, TigressMode.pirate),
          child: _tigressChoice(CardKind.pirate, Strings.asPirate),
        ),
        SimpleDialogOption(
          key: const Key('tigress-escape'),
          onPressed: () => Navigator.pop(context, TigressMode.escape),
          child: _tigressChoice(CardKind.escape, Strings.asEscape),
        ),
      ],
    ),
  );

  /// One of the two ways to play the tigress, under the emblem of the card
  /// she then stands for.
  static Widget _tigressChoice(CardKind kind, String label) {
    final look = CardLook.of(Card.special(kind));
    return Row(
      children: [
        Pictogram(look.emblem, size: 24, color: look.color),
        const SizedBox(width: Tokens.space3),
        Text(label),
      ],
    );
  }

  /// The game is saved as it goes, so leaving loses nothing.
  Future<void> _pause() async {
    final navigator = Navigator.of(context);
    final quit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(Strings.pause),
        content: const Text(Strings.gameIsSaved),
        actionsOverflowButtonSpacing: Tokens.space1,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const RulesScreen()),
            ),
            child: const Text(Strings.rules),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(Strings.quit),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(Strings.resume),
          ),
        ],
      ),
    );
    if (quit ?? false) navigator.pop();
  }

  /// The whole score sheet, on nearly the full screen.
  void _showScoreSheet() => showModalBottomSheet<void>(
    context: context,
    backgroundColor: Tokens.panel,
    showDragHandle: true,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => FractionallySizedBox(
      heightFactor: 0.92,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: Tokens.space4),
            child: Text(
              Strings.scoreSheet,
              style: TextStyle(
                color: Tokens.text,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(Tokens.space3),
              child: ScoreSheet(
                rounds: _game.scoredRounds,
                seats: _scoringSeats,
                large: true,
              ),
            ),
          ),
        ],
      ),
    ),
  );

  void _showLastTrick() => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: Tokens.panel,
      insetPadding: _dialogInset,
      title: const Text(Strings.lastTrick),
      content: _game.lastTrick == null
          ? const Text(Strings.noLastTrick)
          : SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: TrickArea(
                  plays: _game.lastTrick!,
                  seats: _seats,
                  winner: _game.lastTrickWinner,
                  cardWidth: 78,
                  namedPirates: _namedPirates,
                ),
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(Strings.close),
        ),
      ],
    ),
  );

  String _status() {
    final game = _game;
    if (game.trickWinner case final winner?) {
      if (game.trickDestroyed) {
        return winner == game.humanSeat
            ? Strings.trickDestroyedYouLead
            : Strings.trickDestroyed(_seats[winner].name);
      }
      return winner == game.humanSeat
          ? Strings.trickForYou
          : Strings.trickFor(_seats[winner].name);
    }
    if (_powerNotice() case final notice?) return notice;
    if (game.bidQuestion != null) {
      final lead = game.leader == game.humanSeat
          ? Strings.youLeadRound
          : Strings.leadsRound(_seats[game.leader].name);
      return '$lead\n${Strings.bidsHidden}';
    }
    if (game.playQuestion case final question?) {
      if (_selected != null) return Strings.tapAgain;
      final suit = game.leadSuit;
      // No suit to follow: either the human leads, or a character or a
      // creature already on the table lifted the obligation.
      if (suit == null) {
        return game.trick.isEmpty ? Strings.yourLead : Strings.playAnything;
      }
      return question.legalCards.any((card) => card.suit == suit)
          ? Strings.followSuit(suit)
          : Strings.noSuitHeld(suit);
    }
    if (game.currentSeat case final seat?) {
      return Strings.thinking(_seats[seat].name);
    }
    return '';
  }

  /// Cards in hand are as large as their number allows: few cards, big cards.
  static double _handCardWidth(int cards) => switch (cards) {
    <= 4 => 96,
    <= 6 => 88,
    <= 8 => 80,
    _ => 74,
  };

  /// What a pirate's power just did, in words.
  String? _powerNotice() {
    String name(int seat) => _seats[seat].name;
    return switch (_game.powerNotice) {
      // Harry only acts once the round is played out: say so.
      PowerUsed(:final seat, pirate: Pirate.harry) =>
        seat == _game.humanSeat
            ? Strings.harryLaterYou
            : Strings.harryLater(name(seat)),
      PowerUsed(:final seat, :final pirate) => Strings.usesPower(
        name(seat),
        pirate,
      ),
      LeaderChosen(:final leader) => Strings.leaderChosen(name(leader)),
      CardsDiscarded(:final seat, :final count) => Strings.cardsDiscarded(
        name(seat),
        count,
      ),
      WagerPlaced(:final seat, :final amount) => Strings.wagerPlaced(
        name(seat),
        amount,
      ),
      BidChanged(:final seat, :final bid) => Strings.bidChanged(
        name(seat),
        bid,
      ),
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final game = _game;
    final over = game.result != null && game.roundSummary == null;
    return PopScope(
      canPop: over,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _pause();
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // Outside the overlays: the score sheet and the last trick stay
              // within reach while a round summary is shown.
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Tokens.space2,
                  Tokens.space2,
                  Tokens.space2,
                  0,
                ),
                child: _topBar(),
              ),
              Expanded(
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(Tokens.space2),
                      child: Column(
                        children: [
                          _opponents(),
                          Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: game.skipHold,
                              child: Center(
                                child: SingleChildScrollView(child: _center()),
                              ),
                            ),
                          ),
                          Text(
                            _status(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Tokens.text,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: Tokens.space2),
                          SizedBox(
                            width: 220,
                            child: _seatChip(game.humanSeat, showCards: false),
                          ),
                          const SizedBox(height: Tokens.space2),
                          HandFan(
                            cards: game.hand,
                            legal: game.playQuestion?.legalCards,
                            selected: _selected,
                            onTap: _onCardTap,
                            cardWidth: _handCardWidth(game.hand.length),
                            namedPirates: _namedPirates,
                          ),
                        ],
                      ),
                    ),
                    if (game.roundSummary case final summary?)
                      _roundOver(summary),
                    if (over) _gameOver(game.result!),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    final title = _game.round > standardRounds
        ? Strings.tieBreakTitle(_game.cardsDealt)
        : Strings.roundTitle(_game.round, _game.cardsDealt);
    return Row(
      children: [
        IconButton(
          tooltip: Strings.pause,
          onPressed: _pause,
          icon: const Icon(Icons.pause),
        ),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Tokens.text,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        IconButton(
          tooltip: Strings.lastTrick,
          onPressed: _showLastTrick,
          icon: const Icon(Icons.history),
        ),
        IconButton(
          tooltip: Strings.scoreSheet,
          onPressed: _showScoreSheet,
          icon: const Icon(Icons.leaderboard_outlined),
        ),
      ],
    );
  }

  /// The opponents, in rows of two to four so that each tile stays wide
  /// enough to read at a glance.
  Widget _opponents() => LayoutBuilder(
    builder: (context, constraints) {
      final opponents = _game.seats - 1;
      final perRow = switch (opponents) {
        <= 3 => opponents,
        4 => 2,
        <= 6 => 3,
        _ => 4,
      };
      const gap = Tokens.space2;
      final width = (constraints.maxWidth - gap * (perRow - 1)) / perRow;
      return Wrap(
        alignment: WrapAlignment.center,
        spacing: gap,
        runSpacing: gap,
        children: [
          for (var seat = 0; seat < _game.seats; seat++)
            if (seat != _game.humanSeat)
              SizedBox(width: width, child: _seatChip(seat, showCards: true)),
        ],
      );
    },
  );

  Widget _seatChip(int seat, {required bool showCards}) => SeatChip(
    identity: _seats[seat],
    bid: _game.bids.elementAtOrNull(seat),
    tricksWon: _game.tricksWon.elementAtOrNull(seat) ?? 0,
    score: _game.scores[seat],
    cardsLeft: showCards ? _game.handSizes.elementAtOrNull(seat) : null,
    isCurrent: _game.currentSeat == seat,
    isDealer: _game.dealer == seat,
    // Between two tricks, and while bids are open: who plays first.
    leadsNext:
        _game.leader == seat &&
        _game.trick.isEmpty &&
        _game.roundSummary == null &&
        _game.result == null,
  );

  Widget _center() {
    // Nothing is on the table while bids are open: the bid goes there.
    if (_game.bidQuestion case final question?) {
      return BidPanel(
        key: ValueKey('bid-panel-${_game.round}'),
        maxBid: question.maxBid,
        onBid: _game.bid,
      );
    }
    final bonuses = _game.trickBonuses;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            // Three or four cards to a row, as wide as the table allows.
            final perRow = _game.trick.length.clamp(3, 4);
            const gap = Tokens.space2;
            final width = ((constraints.maxWidth - gap * (perRow - 1)) / perRow)
                .clamp(56.0, 104.0);
            return TrickArea(
              plays: _game.trick,
              seats: _seats,
              winner: _game.trickDestroyed ? null : _game.trickWinner,
              cardWidth: width,
              namedPirates: _namedPirates,
            );
          },
        ),
        for (final alliance in _game.trickAlliances)
          Padding(
            padding: const EdgeInsets.only(top: Tokens.space2),
            child: Text(
              Strings.alliance(
                _seats[alliance.lootSeat].name,
                _seats[alliance.winnerSeat].name,
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Tokens.gold, fontSize: 12),
            ),
          ),
        if (bonuses.isNotEmpty) ...[
          const SizedBox(height: Tokens.space2),
          Text(
            Strings.trickBonus(bonuses),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Tokens.gold, fontSize: 12),
          ),
        ],
      ],
    );
  }

  /// A panel over the table. [body] scrolls when it is too tall, so that
  /// [header] and [actions] always stay on screen.
  Widget _overlay({
    required List<Widget> header,
    required Widget body,
    required List<Widget> actions,
  }) => Positioned.fill(
    child: ColoredBox(
      color: Tokens.scrim,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(Tokens.space3),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            padding: const EdgeInsets.all(Tokens.space4),
            decoration: BoxDecoration(
              color: Tokens.panel,
              borderRadius: BorderRadius.circular(Tokens.radiusPanel),
              border: Border.all(color: Tokens.outline),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ...header,
                Flexible(child: SingleChildScrollView(child: body)),
                const SizedBox(height: Tokens.space3),
                ...actions,
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _roundOver(RoundScored summary) => _overlay(
    header: [
      Text(
        Strings.roundOver(summary.round),
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Tokens.text,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: Tokens.space3),
    ],
    body: RoundSummaryTable(round: summary, seats: _scoringSeats),
    actions: [
      FilledButton(
        key: const Key('continue'),
        onPressed: _game.continueAfterRound,
        child: const Text(Strings.continueGame),
      ),
    ],
  );

  Widget _gameOver(GameFinished result) => _overlay(
    header: [
      const Text(
        Strings.gameOver,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Tokens.gold,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 2,
        ),
      ),
      const SizedBox(height: Tokens.space2),
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          result.winner == _game.humanSeat
              ? Strings.youWin
              : Strings.wins(_seats[result.winner].name),
          style: const TextStyle(
            color: Tokens.text,
            fontSize: 30,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      const SizedBox(height: Tokens.space3),
    ],
    body: Standings(scores: result.scores, seats: _scoringSeats),
    actions: [
      FilledButton(
        onPressed: widget.onPlayAgain,
        child: const Text(Strings.playAgain),
      ),
      const SizedBox(height: Tokens.space2),
      OutlinedButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text(Strings.home),
      ),
      TextButton(
        onPressed: _showScoreSheet,
        child: const Text(Strings.scoreSheet),
      ),
    ],
  );
}
