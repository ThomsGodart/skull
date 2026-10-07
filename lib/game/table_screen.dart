import 'package:flutter/foundation.dart';
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
    this.onPlayAgain,
    this.human = const SeatIdentity(Strings.you, Tokens.gold),
    this.seatIdentities,
    this.banner,
    this.notices,
    this.leaveWarning,
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

  /// Starts a fresh game with the same setup. Without it, the final
  /// standings offer no rematch.
  final VoidCallback? onPlayAgain;

  /// Who sits at each seat, when it is not simply [human] against bots.
  final List<SeatIdentity>? seatIdentities;

  /// Something to tell the player above the table for as long as it is not
  /// null: a paused online game, for instance.
  final ValueListenable<String?>? banner;

  /// Shown under the top bar: what an online game has to say about who is
  /// away.
  final Widget? notices;

  /// What leaving costs, when the game is not one that is saved and resumed.
  final String? leaveWarning;

  @override
  State<TableScreen> createState() => _TableScreenState();
}

class _TableScreenState extends State<TableScreen> {
  late final List<SeatIdentity> _seats =
      widget.seatIdentities ??
      SeatIdentity.table(
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

  /// A card the player tapped only to look at it, when it cannot be played.
  Card? _inspected;

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
    if (!_game.hand.contains(_inspected)) _inspected = null;
    setState(() {});
    final power = _game.afterTrickQuestion;
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
  AfterTrickQuestion? _powerShown;
  List<Card>? _stockShown;

  bool get _namedPirates => _game.config.piratePowers;

  /// Dialogs that show cards take nearly the whole width of the screen.
  static const _dialogInset = EdgeInsets.symmetric(
    horizontal: Tokens.space3,
    vertical: Tokens.space6,
  );

  /// A pirate just won the human a trick: a dialog asks how to use its power.
  /// It cannot be dismissed, since the game waits for the answer.
  Future<void> _askPower(AfterTrickQuestion question) async {
    // Left to himself, Harry moves the bid towards the tricks taken.
    if (question case AdjustBidQuestion(:final seat, :final changes)
        when widget.settings?.autoHarry ?? false) {
      _game.answerAfterTrick(
        AdjustBidAnswer(
          seat: seat,
          change: GameController.harryChange(
            _game.bids[seat] ?? 0,
            _game.tricksWon[seat],
            changes,
          ),
        ),
      );
      return;
    }
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
    if (answer != null) _game.answerAfterTrick(answer);
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

  /// A tap on a card that may be played lifts it, to read what it does; a
  /// second tap puts it back. It is played with the button, never by a tap
  /// meant to put it away — unless the player asked for single-tap play.
  Future<void> _onCardTap(Card card) async {
    if (_singleTap) return _play(card);
    _vibrate(HapticFeedback.selectionClick);
    setState(() {
      _selected = card == _selected ? null : card;
      _inspected = null;
    });
  }

  Future<void> _play(Card card) async {
    TigressMode? mode;
    int? value;
    Suit? suit;
    if (card.kind == CardKind.tigress) {
      mode = await _askTigressMode();
      if (mode == null || !mounted) return;
    } else if (card.kind == CardKind.zeroFourteen) {
      value = await _askChoice(Strings.zeroFourteenTitle, {
        for (final value in const [14, 0])
          value: (key: 'declare-$value', label: Text(Strings.asValue(value))),
      });
      if (value == null || !mounted) return;
    } else if (card.kind == CardKind.joker && suitIsOpen(_game.trick)) {
      suit = await _askChoice(Strings.jokerTitle, {
        for (final suit in jokerSuits)
          suit: (
            key: 'joker-${suit.name}',
            label: _emblemChoice(
              CardLook.of(Card.number(suit, 1)),
              Strings.jokerAs(suit),
            ),
          ),
      });
      if (suit == null || !mounted) return;
    }
    _vibrate(HapticFeedback.lightImpact);
    _game.play(card, tigressAs: mode, declaredValue: value, jokerSuit: suit);
  }

  /// Asks how a card that can be played several ways is played.
  Future<T?> _askChoice<T>(
    String title,
    Map<T, ({String key, Widget label})> choices,
  ) => showDialog<T>(
    context: context,
    builder: (context) => SimpleDialog(
      title: Text(title),
      children: [
        for (final MapEntry(key: choice, value: option) in choices.entries)
          SimpleDialogOption(
            key: Key(option.key),
            onPressed: () => Navigator.pop(context, choice),
            child: option.label,
          ),
      ],
    ),
  );

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
  static Widget _tigressChoice(CardKind kind, String label) =>
      _emblemChoice(CardLook.of(Card.special(kind)), label);

  static Widget _emblemChoice(CardLook look, String label) {
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
        content: Text(widget.leaveWarning ?? Strings.gameIsSaved),
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
                  overboard: _game.lastTrickOverboard,
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
      return lead;
    }
    if (game.playQuestion case final question?) {
      if (game.forcedCard case final forced?
          when question.legalCards.contains(forced)) {
        return Strings.forcedCard(
          Strings.cardName(forced, namedPirates: _namedPirates),
        );
      }
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

  Widget _trickZone(GameController game, {double maxCard = 104}) => Expanded(
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (_inspected != null || _selected != null) {
          setState(() {
            _inspected = null;
            _selected = null;
          });
        } else {
          game.skipHold();
        }
      },
      child: Center(
        child: SingleChildScrollView(child: _center(maxCard: maxCard)),
      ),
    ),
  );

  /// What the table says in a line — or, while a card is lifted, what that
  /// card does and the button that plays it. The game stays in view.
  Widget _statusLine() {
    final card = _selected ?? _inspected;
    if (card == null) {
      return Text(
        _status(),
        textAlign: TextAlign.center,
        style: const TextStyle(color: Tokens.text, fontWeight: FontWeight.w700),
      );
    }
    final name = Strings.cardName(card, namedPirates: _namedPirates);
    final hint = Strings.cardHint(card, powers: _namedPirates);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Tokens.space2,
        vertical: Tokens.space1,
      ),
      decoration: BoxDecoration(
        color: Tokens.panelRaised,
        borderRadius: BorderRadius.circular(Tokens.radiusButton),
        border: Border.all(color: Tokens.gold),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              hint == null ? name : '$name — $hint',
              key: const Key('card-hint'),
              style: const TextStyle(color: Tokens.text, fontSize: 13),
            ),
          ),
          if (card == _selected) ...[
            const SizedBox(width: Tokens.space2),
            FilledButton(
              key: const Key('play-card'),
              onPressed: () => _play(card),
              child: const Text(Strings.playCard),
            ),
          ],
        ],
      ),
    );
  }

  Widget _hand(GameController game, {double? cardWidth}) => HandFan(
    cards: game.hand,
    legal: game.playQuestion?.legalCards,
    selected: _selected ?? _inspected,
    onTap: _onCardTap,
    onInspect: (card) =>
        setState(() => _inspected = card == _inspected ? null : card),
    cardWidth: cardWidth ?? _handCardWidth(game.hand.length),
    namedPirates: _namedPirates,
  );

  /// Phone held upright: opponents on top, the trick, then the hand.
  Widget _portraitBody(GameController game) => Column(
    children: [
      _opponents(),
      _trickZone(game),
      _statusLine(),
      const SizedBox(height: Tokens.space2),
      SizedBox(width: 220, child: _seatChip(game.humanSeat, showCards: false)),
      const SizedBox(height: Tokens.space2),
      _hand(game),
    ],
  );

  /// Phone on its side: everyone on the left, the trick and the hand on the
  /// right, with cards sized to the little height there is.
  Widget _landscapeBody(GameController game, double height) => Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Expanded(
        flex: 4,
        child: Column(
          children: [
            Expanded(child: SingleChildScrollView(child: _opponents())),
            const SizedBox(height: Tokens.space1),
            _seatChip(game.humanSeat, showCards: false),
          ],
        ),
      ),
      const SizedBox(width: Tokens.space2),
      Expanded(
        flex: 7,
        child: Column(
          children: [
            // The height is shared between the trick and the hand, and the
            // cards are as large as their share allows.
            _trickZone(
              game,
              maxCard: ((height * 0.46 - 34) / CardView.aspect).clamp(64, 120),
            ),
            // On the wide side, where a card's text has room to be read.
            _statusLine(),
            _hand(
              game,
              cardWidth: ((height * 0.42 - 22) / CardView.aspect).clamp(
                60,
                110,
              ),
            ),
          ],
        ),
      ),
    ],
  );

  static bool _isLandscape(BoxConstraints constraints) =>
      constraints.maxWidth > constraints.maxHeight * 1.15;

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
      VictimChosen(:final victim) =>
        victim == _game.humanSeat
            ? Strings.victimChosenYou
            : Strings.victimChosen(name(victim)),
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
              if (widget.banner case final banner?)
                ValueListenableBuilder(
                  valueListenable: banner,
                  builder: (context, message, _) => message == null
                      ? const SizedBox.shrink()
                      : Container(
                          width: double.infinity,
                          color: Tokens.danger,
                          padding: const EdgeInsets.all(Tokens.space2),
                          child: Text(
                            message,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Tokens.sea,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                ),
              ?widget.notices,
              Expanded(
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(Tokens.space2),
                      child: LayoutBuilder(
                        builder: (context, constraints) =>
                            _isLandscape(constraints)
                            ? _landscapeBody(game, constraints.maxHeight)
                            : _portraitBody(game),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Tokens.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              // Once the bids are known: are there more tricks announced
              // than there are to take, or fewer?
              if (_game.totalBids case final total?)
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        Strings.bidsTotal(total, _game.cardsDealt),
                        key: const Key('bids-total'),
                        style: const TextStyle(
                          color: Tokens.gold,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      // Tricks nobody took: fewer are left to win.
                      if (_game.destroyedTricks > 0)
                        Padding(
                          padding: const EdgeInsets.only(left: Tokens.space2),
                          child: Tooltip(
                            message: Strings.destroyedTricks(
                              _game.destroyedTricks,
                            ),
                            child: Row(
                              key: const Key('destroyed-tricks'),
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Pictogram(
                                  CardLook.of(krakenCard).emblem,
                                  size: 16,
                                  color: Tokens.danger,
                                ),
                                Text(
                                  ' −${_game.destroyedTricks}',
                                  style: const TextStyle(
                                    color: Tokens.danger,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
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
    emphasizeBid: _game.revealingBids,
    wager: _game.wagers[seat],
    hasHarry: _game.harrySeats.contains(seat),
    showTokens: widget.settings?.trickTokens ?? false,
    // Between two tricks, and while bids are open: who plays first.
    leadsNext:
        _game.leader == seat &&
        _game.trick.isEmpty &&
        _game.roundSummary == null &&
        _game.result == null,
  );

  Widget _center({double maxCard = 104}) {
    // Nothing is on the table while bids are open: the bid goes there.
    if (_game.bidQuestion case final question?) {
      return BidPanel(
        key: ValueKey('bid-panel-${_game.round}'),
        maxBid: question.maxBid,
        initialBid: _game.placedBid,
        onBid: _game.bid,
      );
    }
    // The bid is in, the others' are not: say so, and let it be changed.
    if (_game.placedBid case final bid?) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            Strings.bidPlaced(bid),
            key: const Key('bid-placed'),
            style: const TextStyle(
              color: Tokens.gold,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: Tokens.space1),
          const Text(
            Strings.waitingForBids,
            style: TextStyle(color: Tokens.mutedText),
          ),
          TextButton(
            key: const Key('change-bid'),
            onPressed: _game.changeBid,
            child: const Text(Strings.changeBid),
          ),
        ],
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
                .clamp(44.0, maxCard);
            return TrickArea(
              plays: _game.trick,
              seats: _seats,
              winner: _game.trickDestroyed ? null : _game.trickWinner,
              cardWidth: width,
              namedPirates: _namedPirates,
              overboard: _game.trickOverboard,
              slideFromBelow: _game.humanSeat,
              animate: !(widget.settings?.reduceMotion ?? false),
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
        for (final (seat, bonus) in _game.trickSideBonuses)
          Padding(
            padding: const EdgeInsets.only(top: Tokens.space2),
            child: Text(
              Strings.sideBonus(_seats[seat].name, bonus),
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          // With little height, as on a phone on its side, the buttons sit
          // in a row and leave the room to the scores.
          final short = constraints.maxHeight < 420;
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(Tokens.space2),
              child: Container(
                constraints: BoxConstraints(maxWidth: short ? 680 : 560),
                padding: EdgeInsets.symmetric(
                  horizontal: Tokens.space3,
                  vertical: short ? Tokens.space2 : Tokens.space6,
                ),
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
                    if (short)
                      Row(
                        children: [
                          for (final (index, action) in actions.indexed) ...[
                            if (index > 0) const SizedBox(width: Tokens.space2),
                            Expanded(child: action),
                          ],
                        ],
                      )
                    else
                      for (final (index, action) in actions.indexed) ...[
                        if (index > 0) const SizedBox(height: Tokens.space2),
                        action,
                      ],
                  ],
                ),
              ),
            ),
          );
        },
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
          fontSize: 24,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: Tokens.space4),
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
              ? Strings.youWinWith(result.scores[result.winner])
              : Strings.winsWith(
                  _seats[result.winner].name,
                  result.scores[result.winner],
                ),
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
      if (widget.onPlayAgain case final playAgain?)
        FilledButton(
          onPressed: playAgain,
          child: const Text(Strings.playAgain),
        ),
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
