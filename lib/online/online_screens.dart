import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../bots/bot_level.dart';
import '../engine/engine.dart';
import '../game/game_controller.dart';
import '../game/seat_feed.dart';
import '../game/seat_identity.dart';
import '../game/table_screen.dart';
import '../rules/rules_screen.dart';
import '../settings/app_settings.dart';
import '../settings/profile_dialog.dart';
import '../setup/setup_screen.dart';
import '../theme/tokens.dart';
import '../ui/pirate_loader.dart';
import '../ui/player_icons.dart';
import '../ui/rules_content.dart';
import '../ui/strings.dart';
import 'online_game.dart';
import 'room_chat.dart';
import 'room_transport.dart';

/// Makes the connection a phone known as `selfId` uses to reach its room.
typedef TransportFactory = RoomTransport Function(String selfId);

/// Who sits at each seat of an online game. [Seating.occupants] mixes people
/// and bots; the ghost sits in when two play.
List<SeatIdentity> onlineSeats(Seating seating, {Random? random}) {
  final seats = tableHands(seating.config.players);
  final ghost = seats > seating.config.players ? seats - 1 : null;
  final botCount = [
    for (var seat = 0; seat < seats; seat++)
      if (seat != ghost && seating.occupantAt(seat) == null) seat,
  ].length;
  final botNames = Strings.shuffledBotNames(botCount, random);
  final botIcons = SeatIdentity.botIcons(botCount, random);
  var bots = 0;
  return [
    for (var seat = 0; seat < seats; seat++)
      if (seat == ghost)
        SeatIdentity.ghost
      else if (seating.occupantAt(seat) case final person?)
        SeatIdentity(
          person.name,
          Tokens.playerColors[person.color % Tokens.playerColors.length],
          icon: PlayerIcons.glyph(person.icon),
        )
      else
        SeatIdentity(
          botNames[bots],
          Tokens.botColors[bots % Tokens.botColors.length],
          icon: botIcons[bots++],
        ),
  ];
}

/// The way into online play: create a room, or join one with its code.
class OnlineHomeScreen extends StatefulWidget {
  const OnlineHomeScreen({
    super.key,
    required this.settings,
    required this.transports,
    this.random,
  });

  final AppSettings settings;
  final TransportFactory transports;

  /// Draws room codes and seeds; a fixed one makes tests repeatable.
  final Random? random;

  @override
  State<OnlineHomeScreen> createState() => _OnlineHomeScreenState();
}

class _OnlineHomeScreenState extends State<OnlineHomeScreen> {
  late final _code = TextEditingController(text: widget.settings.lastRoomCode);
  late final Random _random = widget.random ?? Random();

  @override
  void initState() {
    super.initState();
    widget.settings.addListener(_onSettings);
  }

  /// The room just joined is offered again once the player is back here.
  void _onSettings() {
    final code = widget.settings.lastRoomCode;
    if (code.isNotEmpty && _code.text != code) _code.text = code;
  }

  @override
  void dispose() {
    widget.settings.removeListener(_onSettings);
    _code.dispose();
    super.dispose();
  }

  Future<RoomPlayer> _self() async => RoomPlayer(
    id: await widget.settings.onlineId(_random),
    name: widget.settings.playerName,
    color: widget.settings.playerColor,
    icon: widget.settings.playerIcon,
  );

  /// Online, the others only know a player by their name: « Toi » is never
  /// allowed, so anyone still carrying it must pick another.
  Future<void> _askName() async {
    if (!AppSettings.isForbiddenName(widget.settings.playerName)) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: ProfileDialog(
          settings: widget.settings,
          prompt: Strings.onlineNamePrompt,
          requireRealName: true,
        ),
      ),
    );
  }

  Future<void> _create() async {
    await _askName();
    if (!mounted) return;
    await _openSetup();
  }

  Future<void> _openSetup() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (setupContext) => SetupScreen(
        settings: widget.settings,
        online: true,
        onLaunch: (setup, level) async {
          final self = await _self();
          if (!setupContext.mounted) return;
          unawaited(widget.settings.setLastSetup(setup));
          unawaited(
            Navigator.of(setupContext).pushReplacement(
              MaterialPageRoute<void>(
                builder: (context) => HostRoomScreen(
                  host: OnlineHost(
                    transport: widget.transports(self.id),
                    self: self,
                    config: setup,
                    bot: botFor(level, _random),
                  ),
                  code: newRoomCode(_random),
                  speed: widget.settings.botSpeed.table,
                  settings: widget.settings,
                  random: _random,
                ),
              ),
            ),
          );
        },
      ),
    ),
  );

  Future<void> _join() async {
    final code = _code.text.trim().toUpperCase();
    if (code.isEmpty) return;
    await _askName();
    if (!mounted) return;
    final navigator = Navigator.of(context);
    final self = await _self();
    unawaited(
      navigator.push(
        MaterialPageRoute<void>(
          builder: (context) => GuestRoomScreen(
            guest: OnlineGuest(
              transport: widget.transports(self.id),
              self: self,
            ),
            code: code,
            speed: widget.settings.botSpeed.table,
            settings: widget.settings,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(Strings.online)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(Tokens.space6),
          children: [
            const Text(
              Strings.onlineIntro,
              textAlign: TextAlign.center,
              style: TextStyle(color: Tokens.mutedText),
            ),
            const SizedBox(height: Tokens.space6),
            FilledButton(
              key: const Key('online-create'),
              onPressed: _create,
              child: const Text(Strings.onlineCreate),
            ),
            const SizedBox(height: Tokens.space6 * 2),
            TextField(
              key: const Key('online-code'),
              controller: _code,
              textAlign: TextAlign.center,
              textCapitalization: TextCapitalization.characters,
              maxLength: 4,
              style: const TextStyle(
                fontSize: 28,
                letterSpacing: 8,
                fontWeight: FontWeight.w800,
              ),
              decoration: const InputDecoration(
                labelText: Strings.onlineCodeLabel,
                hintText: Strings.onlineCodeHint,
                counterText: '',
              ),
              onSubmitted: (_) => _join(),
            ),
            const SizedBox(height: Tokens.space3),
            OutlinedButton(
              key: const Key('online-join'),
              onPressed: _join,
              child: const Text(Strings.onlineJoin),
            ),
          ],
        ),
      ),
    );
  }
}

/// The people of a room, one per line.
class _PlayerList extends StatelessWidget {
  const _PlayerList({required this.lobby, required this.selfId});

  final Lobby lobby;
  final String selfId;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final player in lobby.players)
          ListTile(
            leading: PlayerAvatar(
              radius: 18,
              color: Tokens
                  .playerColors[player.color % Tokens.playerColors.length],
              glyph: PlayerIcons.glyph(player.icon),
            ),
            title: Text(player.name),
            subtitle: Text(
              [
                if (player.id == lobby.hostId) Strings.onlineHostTag,
                if (player.id == selfId) Strings.onlineYouTag,
                if (!player.connected) Strings.onlineAwayTag,
              ].join(' · '),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(Tokens.space3),
          child: Text(
            Strings.onlineSeats(lobby.players.length, maxPlayers),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Tokens.mutedText),
          ),
        ),
      ],
    );
  }
}

/// A message in the middle of the screen, with a way back.
class _Notice extends StatelessWidget {
  const _Notice(this.message);

  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(Tokens.space6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Tokens.text, fontSize: 16),
          ),
          const SizedBox(height: Tokens.space4),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(Strings.close),
          ),
        ],
      ),
    ),
  );
}

/// What a room says while it waits: a turning wheel and a line, large and
/// in the app's gold, in the middle.
class _Waiting extends StatelessWidget {
  const _Waiting(this.message);

  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(Tokens.space4),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const PirateLoader(key: Key('pirate-loader')),
        const SizedBox(height: Tokens.space3),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Tokens.gold,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

/// The rules in a few lines, to read while the others arrive.
class _RulesReminder extends StatelessWidget {
  const _RulesReminder();

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('rules-reminder'),
    margin: const EdgeInsets.symmetric(horizontal: Tokens.space4),
    padding: const EdgeInsets.all(Tokens.space4),
    decoration: BoxDecoration(
      color: Tokens.panel,
      borderRadius: BorderRadius.circular(Tokens.radiusButton),
      border: Border.all(color: Tokens.outline),
    ),
    child: Column(
      children: [
        const Text(
          Strings.rulesReminderTitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Tokens.gold,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: Tokens.space2),
        for (final line in RulesContent.reminder)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Tokens.space1),
            child: Text(
              line,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Tokens.text,
                fontSize: 15,
                height: 1.35,
              ),
            ),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (context) => const RulesScreen()),
          ),
          child: const Text(Strings.rulesReminderMore),
        ),
      ],
    ),
  );
}

/// The table of an online game, for the seat [feed] is for.
Widget _onlineTable({
  required Seating seating,
  required SeatFeed feed,
  required TableSpeed speed,
  required AppSettings settings,
  required String leaveWarning,
  ValueListenable<String?>? banner,
  required Stream<List<Absence>> absences,
  List<Absence> initialAbsences = const [],
  String selfId = '',
  String? roomCode,
  bool canFinishEarly = false,
  RoomChat? chat,
  VoidCallback? onPlayAgain,
  String? gameOverNote,
  void Function(String id)? onKeepWaiting,
  void Function(String id)? onReplaceNow,
}) => TableScreen(
  controller: GameController.onFeed(feed, speed: speed),
  seatIdentities: onlineSeats(seating, random: Random(seating.config.seed)),
  settings: settings,
  banner: banner,
  notices: AbsenceNotices(
    absences: absences,
    initial: initialAbsences,
    selfId: selfId,
    onKeepWaiting: onKeepWaiting,
    onReplaceNow: onReplaceNow,
  ),
  leaveWarning: leaveWarning,
  roomCode: roomCode,
  canFinishEarly: canFinishEarly,
  chat: chat,
  onPlayAgain: onPlayAgain,
  gameOverNote: gameOverNote,
);

/// Says who dropped out of the game and what becomes of their seat: the
/// seconds left before a bot takes it, and, for the host, the way to wait
/// for them instead or to put the bot there at once.
class AbsenceNotices extends StatefulWidget {
  const AbsenceNotices({
    super.key,
    required this.absences,
    this.initial = const [],
    this.selfId = '',
    this.onKeepWaiting,
    this.onReplaceNow,
  });

  final Stream<List<Absence>> absences;
  final List<Absence> initial;

  /// This phone's own player: it is never told about itself.
  final String selfId;

  /// Set on the host's phone only: its player decides.
  final void Function(String id)? onKeepWaiting;
  final void Function(String id)? onReplaceNow;

  @override
  State<AbsenceNotices> createState() => _AbsenceNoticesState();
}

class _AbsenceNoticesState extends State<AbsenceNotices> {
  late List<Absence> _absences = widget.initial;
  StreamSubscription<List<Absence>>? _subscription;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _subscription = widget.absences.listen(
      (absences) => setState(() => _absences = absences),
    );
    // The countdown moves by itself.
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_absences.any((a) => a.state == AbsenceState.counting)) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shown = _absences.where((a) => a.id != widget.selfId).toList();
    if (shown.isEmpty) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [for (final absence in shown) _line(absence)],
    );
  }

  Widget _line(Absence absence) {
    final left = absence.until?.difference(DateTime.now()).inSeconds ?? 0;
    final (text, label, action) = switch (absence.state) {
      AbsenceState.counting => (
        Strings.onlineAwayCounting(absence.name, left < 0 ? 0 : left),
        Strings.onlineKeepWaiting,
        widget.onKeepWaiting,
      ),
      AbsenceState.held => (
        Strings.onlineAwayHeld(absence.name),
        Strings.onlineReplaceNow,
        widget.onReplaceNow,
      ),
      AbsenceState.replaced => (
        Strings.onlineAwayReplaced(absence.name),
        Strings.onlineKeepWaiting,
        widget.onKeepWaiting,
      ),
    };
    return Container(
      key: Key('absence-${absence.id}'),
      width: double.infinity,
      color: Tokens.panelRaised,
      padding: const EdgeInsets.symmetric(
        horizontal: Tokens.space3,
        vertical: Tokens.space1,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Tokens.text, fontSize: 13),
            ),
          ),
          if (action != null)
            TextButton(
              key: Key('absence-action-${absence.id}'),
              onPressed: () => action(absence.id),
              child: Text(label),
            ),
        ],
      ),
    );
  }
}

/// The room of the phone that created it: its code, who came, and the
/// button that starts the game.
class HostRoomScreen extends StatefulWidget {
  const HostRoomScreen({
    super.key,
    required this.host,
    required this.code,
    required this.speed,
    required this.settings,
    required this.random,
  });

  final OnlineHost host;
  final String code;
  final TableSpeed speed;
  final AppSettings settings;
  final Random random;

  @override
  State<HostRoomScreen> createState() => _HostRoomScreenState();
}

class _HostRoomScreenState extends State<HostRoomScreen> {
  late Lobby _lobby = widget.host.currentLobby;
  StreamSubscription<Lobby>? _subscription;
  bool _connected = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _subscription = widget.host.lobby.listen(
      (lobby) => setState(() => _lobby = lobby),
    );
    widget.host
        .open(widget.code)
        .then((_) {
          if (mounted) setState(() => _connected = true);
        })
        .catchError((Object _) {
          if (mounted) setState(() => _failed = true);
        });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    // Closing the room is what ends the game for everyone.
    unawaited(widget.host.close());
    super.dispose();
  }

  /// Asks how many bots join the table, when it has room for some. Null when
  /// the host thinks better of starting.
  Future<int?> _askBots() {
    final room = widget.host.botsRoom;
    if (room <= 0) return Future.value(0);
    final people = _lobby.players.length;
    var bots = 0;
    return showDialog<int>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Tokens.panel,
          title: const Text(Strings.onlineBotsTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(Strings.onlineBotsBody(people, room)),
              const SizedBox(height: Tokens.space3),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    key: const Key('online-bots-minus'),
                    onPressed: bots > 0
                        ? () => setDialogState(() => bots--)
                        : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  SizedBox(
                    width: Tokens.tapTarget,
                    child: Text(
                      '$bots',
                      key: const Key('online-bots'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Tokens.text,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    key: const Key('online-bots-plus'),
                    onPressed: bots < room
                        ? () => setDialogState(() => bots++)
                        : null,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
              if (people + bots == minPlayers)
                const Padding(
                  padding: EdgeInsets.only(top: Tokens.space2),
                  child: Text(
                    Strings.twoPlayersNote,
                    style: TextStyle(color: Tokens.mutedText, fontSize: 12),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(Strings.cancel),
            ),
            FilledButton(
              key: const Key('online-bots-confirm'),
              onPressed: () => Navigator.pop(context, bots),
              child: const Text(Strings.onlineStart),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _start() async {
    final bots = await _askBots();
    if (bots == null || !mounted) return;
    var feed = widget.host.start(widget.random, bots: bots);
    // One table per game of the room: « Rejouer » closes the table of the
    // game that is over, and the next one is dealt to the same seats.
    while (true) {
      final again = await _playGame(feed);
      if (!again || !mounted) break;
      feed = widget.host.rematch(widget.random);
    }
    // The table was left: so is the room.
    if (mounted) Navigator.of(context).pop();
  }

  /// Shows the table of the game [feed] is for until it is left. True when
  /// it was left to play again.
  Future<bool> _playGame(SeatFeed feed) async {
    final again = await Navigator.of(context).push(
      MaterialPageRoute<bool>(
        builder: (context) => _onlineTable(
          onPlayAgain: () => Navigator.of(context).pop(true),
          seating: Seating(
            config: feed.config,
            seat: feed.seat,
            occupants: widget.host.currentOccupants,
          ),
          feed: feed,
          speed: widget.speed,
          settings: widget.settings,
          leaveWarning: Strings.onlineLeaveHost,
          roomCode: widget.code,
          canFinishEarly: true,
          chat: RoomChat(
            transport: widget.host.transport,
            selfId: widget.host.self.id,
          ),
          absences: widget.host.absences,
          initialAbsences: widget.host.currentAbsences,
          selfId: widget.host.self.id,
          onKeepWaiting: widget.host.keepWaiting,
          onReplaceNow: widget.host.replaceNow,
        ),
      ),
    );
    return again ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final guests = _lobby.players.length - 1;
    return Scaffold(
      appBar: AppBar(title: const Text(Strings.onlineRoomTitle)),
      body: SafeArea(
        child: _failed
            ? const _Notice(Strings.onlineCannotConnect)
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(Tokens.space4),
                    child: Column(
                      children: [
                        SelectableText(
                          _connected ? widget.code : Strings.onlineConnecting,
                          key: const Key('online-room-code'),
                          style: const TextStyle(
                            color: Tokens.gold,
                            fontSize: 44,
                            letterSpacing: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Text(
                          Strings.onlineShareCode,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Tokens.text, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _PlayerList(
                            lobby: _lobby,
                            selfId: widget.host.self.id,
                          ),
                          _Waiting(
                            guests == 0
                                ? Strings.onlineNeedGuest
                                : Strings.onlineWaitingGuests,
                          ),
                          const _RulesReminder(),
                          const SizedBox(height: Tokens.space4),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(Tokens.space4),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        key: const Key('online-start'),
                        onPressed: _connected && guests > 0 ? _start : null,
                        child: const Text(Strings.onlineStart),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// The room as a guest sees it: who is there, until the host starts.
class GuestRoomScreen extends StatefulWidget {
  const GuestRoomScreen({
    super.key,
    required this.guest,
    required this.code,
    required this.speed,
    required this.settings,
  });

  final OnlineGuest guest;
  final String code;
  final TableSpeed speed;
  final AppSettings settings;

  @override
  State<GuestRoomScreen> createState() => _GuestRoomScreenState();
}

class _GuestRoomScreenState extends State<GuestRoomScreen> {
  Lobby? _lobby;
  String? _problem;
  final List<StreamSubscription<Object?>> _subscriptions = [];

  /// What the table is told while the game cannot go on.
  final _banner = ValueNotifier<String?>(null);

  @override
  void initState() {
    super.initState();
    final guest = widget.guest;
    _subscriptions
      ..add(
        guest.lobby.listen((lobby) {
          // A room that answers is one worth coming back to.
          unawaited(widget.settings.setLastRoomCode(widget.code));
          setState(() => _lobby = lobby);
        }),
      )
      ..add(
        guest.refused.listen(
          (reason) => setState(() => _problem = Strings.onlineRefused(reason)),
        ),
      )
      ..add(
        guest.hostPresent.listen((present) {
          if (_banner.value != Strings.onlineClosed) {
            _banner.value = present ? null : Strings.onlineHostAway;
          }
        }),
      );
    guest.closed.then((_) {
      _banner.value = Strings.onlineClosed;
      if (mounted) setState(() => _problem ??= Strings.onlineClosed);
    });
    guest.join(widget.code).catchError((Object _) {
      if (mounted) setState(() => _problem = Strings.onlineCannotConnect);
    });
    _subscriptions.add(guest.games.listen(_openTable));
  }

  /// How many games of the room this phone has been shown a table for.
  int _tables = 0;

  /// Opens the table of a game that starts: the first, or the next when the
  /// host plays again, which then takes the place of the one before.
  Future<void> _openTable((Seating, SeatFeed) start) async {
    if (!mounted) return;
    final (seating, feed) = start;
    final table = ++_tables;
    final navigator = Navigator.of(context);
    final room = ModalRoute.of(context);
    // Whatever is open over the room belongs to the game that is over.
    navigator.popUntil((route) => route == room || route.isFirst);
    await navigator.push(
      MaterialPageRoute<void>(
        builder: (context) => _onlineTable(
          seating: seating,
          feed: feed,
          speed: widget.speed,
          settings: widget.settings,
          gameOverNote: Strings.onlineRematchWait,
          leaveWarning: Strings.onlineLeaveGuest,
          banner: _banner,
          roomCode: widget.code,
          chat: RoomChat(
            transport: widget.guest.transport,
            selfId: widget.guest.self.id,
          ),
          absences: widget.guest.absences,
          selfId: widget.guest.self.id,
        ),
      ),
    );
    // Left by the player, not replaced by the next game: so is the room.
    if (mounted && table == _tables) navigator.pop();
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    unawaited(widget.guest.leave());
    _banner.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lobby = _lobby;
    return Scaffold(
      appBar: AppBar(title: Text(Strings.onlineCode(widget.code))),
      body: SafeArea(
        child: _problem != null
            ? _Notice(_problem!)
            : lobby == null
            ? const Center(child: _Waiting(Strings.onlineConnecting))
            : SingleChildScrollView(
                child: Column(
                  children: [
                    _PlayerList(lobby: lobby, selfId: widget.guest.self.id),
                    const _Waiting(Strings.onlineWaitingHost),
                    const _RulesReminder(),
                    const SizedBox(height: Tokens.space4),
                  ],
                ),
              ),
      ),
    );
  }
}
