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
import '../settings/app_settings.dart';
import '../setup/setup_screen.dart';
import '../theme/tokens.dart';
import '../ui/strings.dart';
import 'online_game.dart';
import 'room_transport.dart';

/// Makes the connection a phone known as `selfId` uses to reach its room.
typedef TransportFactory = RoomTransport Function(String selfId);

/// Who sits at each seat of an online game: the people of the room first,
/// then bots, and the ghost when two play.
List<SeatIdentity> onlineSeats(Seating seating) {
  final seats = tableHands(seating.config.players);
  final ghost = seats > seating.config.players ? seats - 1 : null;
  var bots = 0;
  return [
    for (var seat = 0; seat < seats; seat++)
      if (seat == ghost)
        const SeatIdentity(Strings.ghostName, Tokens.ghost, isGhost: true)
      else if (seat < seating.people.length)
        SeatIdentity(
          seat == seating.seat ? Strings.you : seating.people[seat].name,
          Tokens.playerColors[seating.people[seat].color %
              Tokens.playerColors.length],
        )
      else
        SeatIdentity(
          Strings.botNames[bots % Strings.botNames.length],
          Tokens.botColors[bots++ % Tokens.botColors.length],
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
  final _code = TextEditingController();
  late final Random _random = widget.random ?? Random();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<RoomPlayer> _self() async => RoomPlayer(
    id: await widget.settings.onlineId(_random),
    name: widget.settings.playerName,
    color: widget.settings.playerColor,
  );

  void _create() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (setupContext) => SetupScreen(
        settings: widget.settings,
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
            leading: CircleAvatar(
              backgroundColor: Tokens
                  .playerColors[player.color % Tokens.playerColors.length],
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
            Strings.onlineSeats(lobby.players.length, lobby.config.players),
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

/// The table of an online game, for the seat [feed] is for.
Widget _onlineTable({
  required Seating seating,
  required SeatFeed feed,
  required TableSpeed speed,
  required AppSettings settings,
  required String leaveWarning,
  ValueListenable<String?>? banner,
}) => TableScreen(
  controller: GameController.onFeed(feed, speed: speed),
  seatIdentities: onlineSeats(seating),
  settings: settings,
  banner: banner,
  leaveWarning: leaveWarning,
);

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

  Future<void> _start() async {
    final feed = widget.host.start(widget.random);
    final lobby = widget.host.currentLobby;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => _onlineTable(
          seating: Seating(
            config: feed.config,
            seat: feed.seat,
            people: lobby.players,
          ),
          feed: feed,
          speed: widget.speed,
          settings: widget.settings,
          leaveWarning: Strings.onlineLeaveHost,
        ),
      ),
    );
    // The table was left: so is the room.
    if (mounted) Navigator.of(context).pop();
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
                          style: TextStyle(color: Tokens.mutedText),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: _PlayerList(
                        lobby: _lobby,
                        selfId: widget.host.self.id,
                      ),
                    ),
                  ),
                  if (guests == 0)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: Tokens.space4),
                      child: Text(
                        Strings.onlineNeedGuest,
                        style: TextStyle(color: Tokens.mutedText),
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
      ..add(guest.lobby.listen((lobby) => setState(() => _lobby = lobby)))
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
    guest.started.then(_openTable);
  }

  Future<void> _openTable((Seating, SeatFeed) start) async {
    if (!mounted) return;
    final (seating, feed) = start;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => _onlineTable(
          seating: seating,
          feed: feed,
          speed: widget.speed,
          settings: widget.settings,
          leaveWarning: Strings.onlineLeaveGuest,
          banner: _banner,
        ),
      ),
    );
    if (mounted) Navigator.of(context).pop();
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
            ? const Center(child: Text(Strings.onlineConnecting))
            : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: _PlayerList(
                        lobby: lobby,
                        selfId: widget.guest.self.id,
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(Tokens.space4),
                    child: Text(
                      Strings.onlineWaitingHost,
                      style: TextStyle(color: Tokens.mutedText),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
