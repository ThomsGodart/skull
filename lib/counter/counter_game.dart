import '../engine/engine.dart';

/// What one player did in one round of a game counted by hand.
final class CounterEntry {
  const CounterEntry({
    required this.bid,
    required this.tricksWon,
    this.bonuses = const {},
    this.wager = 0,
    this.bidChange = 0,
    this.manualBonus = 0,
  });

  factory CounterEntry.fromJson(Map<String, Object?> json) => CounterEntry(
    bid: json['bid']! as int,
    tricksWon: json['tricksWon']! as int,
    bonuses: {
      for (final MapEntry(:key, :value)
          in (json['bonuses'] as Map<String, Object?>? ?? const {}).entries)
        Bonus.values.byName(key): value! as int,
    },
    wager: json['wager'] as int? ?? 0,
    bidChange: json['bidChange'] as int? ?? 0,
    manualBonus: json['manualBonus'] as int? ?? 0,
  );

  /// The bid as announced, before Harry.
  final int bid;
  final int tricksWon;

  /// How many of each bonus were in the tricks this player won.
  final Map<Bonus, int> bonuses;

  /// What was staked with Rascal the gambler: 0, 10 or 20.
  final int wager;

  /// What Harry the giant did to the bid: -1, 0 or +1.
  final int bidChange;

  /// Points the players added up themselves. Taken as they are, whatever the
  /// bid did: the app checks nothing about them.
  final int manualBonus;

  CounterEntry copyWith({
    int? bid,
    int? tricksWon,
    Map<Bonus, int>? bonuses,
    int? wager,
    int? bidChange,
    int? manualBonus,
  }) => CounterEntry(
    bid: bid ?? this.bid,
    tricksWon: tricksWon ?? this.tricksWon,
    bonuses: bonuses ?? this.bonuses,
    wager: wager ?? this.wager,
    bidChange: bidChange ?? this.bidChange,
    manualBonus: manualBonus ?? this.manualBonus,
  );

  Map<String, Object?> toJson() => {
    'bid': bid,
    'tricksWon': tricksWon,
    if (bonuses.isNotEmpty)
      'bonuses': {
        for (final MapEntry(:key, :value) in bonuses.entries) key.name: value,
      },
    if (wager != 0) 'wager': wager,
    if (bidChange != 0) 'bidChange': bidChange,
    if (manualBonus != 0) 'manualBonus': manualBonus,
  };
}

/// One round as entered: an entry per player, and the loot alliances made.
final class CounterRound {
  const CounterRound({required this.entries, this.alliances = const []});

  factory CounterRound.fromJson(Map<String, Object?> json) => CounterRound(
    entries: [
      for (final entry in json['entries']! as List)
        CounterEntry.fromJson(entry as Map<String, Object?>),
    ],
    alliances: [
      for (final pair in json['alliances'] as List? ?? const [])
        ((pair as List)[0] as int, pair[1] as int),
    ],
  );

  final List<CounterEntry> entries;

  /// Pairs of players a loot card allied this round.
  final List<(int, int)> alliances;

  /// Tricks the players say they took, to check against the cards dealt.
  int get tricksClaimed =>
      entries.fold(0, (sum, entry) => sum + entry.tricksWon);

  Map<String, Object?> toJson() => {
    'entries': [for (final entry in entries) entry.toJson()],
    if (alliances.isNotEmpty)
      'alliances': [
        for (final (first, second) in alliances) [first, second],
      ],
  };
}

/// A game played with the real cards, of which the app only keeps the score.
///
/// Only what the players enter is kept; every point is worked out again from
/// it, so correcting a past round corrects all that follows.
final class CounterGame {
  CounterGame({
    required List<String> players,
    this.firstLeader = 0,
    this.scoring = Scoring.classic,
    this.loot = false,
    this.piratePowers = false,
    this.manualBonuses = false,
    this.secondExpansion = false,
    List<CounterRound> rounds = const [],
    this.draftBids,
  }) : players = List.unmodifiable(players),
       _rounds = [] {
    if (players.length < minPlayers || players.length > maxPlayers) {
      throw ArgumentError.value(
        players.length,
        'players',
        'must be $minPlayers to $maxPlayers',
      );
    }
    // Stored rounds go through the same checks as entered ones, which would
    // also forget the bids being entered: those are put back afterwards.
    final draft = draftBids;
    for (final round in rounds) {
      saveRound(nextRound, round);
    }
    if (!isOver) draftBids = draft;
  }

  factory CounterGame.fromJson(Map<String, Object?> json) => CounterGame(
    players: (json['players']! as List).cast<String>(),
    firstLeader: json['firstLeader'] as int? ?? 0,
    scoring: Scoring.values.byName(
      json['scoring'] as String? ?? Scoring.classic.name,
    ),
    loot: json['loot'] as bool? ?? false,
    piratePowers: json['piratePowers'] as bool? ?? false,
    manualBonuses: json['manualBonuses'] as bool? ?? false,
    secondExpansion: json['secondExpansion'] as bool? ?? false,
    rounds: [
      for (final round in json['rounds'] as List? ?? const [])
        CounterRound.fromJson(round as Map<String, Object?>),
    ],
    draftBids: (json['draftBids'] as List?)?.cast<int>(),
  );

  final List<String> players;

  /// Who leads round one; the lead then moves one player each round.
  final int firstLeader;
  final Scoring scoring;

  /// Loot cards are in the deck: alliances may be entered.
  final bool loot;

  /// Pirate powers are in play: wagers and bid changes may be entered.
  final bool piratePowers;

  /// The players add up their bonuses themselves and enter the total, rather
  /// than say which cards they took.
  final bool manualBonuses;

  /// The cards of the second expansion are in the deck: their bonuses may be
  /// entered, and the deck is large enough for ten cards each at any table.
  final bool secondExpansion;

  final List<CounterRound> _rounds;

  /// The bids of the round being played, entered before its tricks are known.
  /// Cleared when that round is saved.
  List<int>? draftBids;

  /// The round to enter next, numbered from 1.
  int get nextRound => _rounds.length + 1;

  /// Cards each player holds in [round].
  int cardsIn(int round) => secondExpansion
      ? (round < standardRounds ? round : standardRounds)
      : cardsDealt(round: round, players: players.length);

  /// The player who leads [round].
  int leaderOf(int round) => (firstLeader + round - 1) % players.length;

  /// What was entered for [round], if it was.
  CounterRound? round(int round) =>
      round >= 1 && round <= _rounds.length ? _rounds[round - 1] : null;

  /// Enters [round], or corrects it when it was entered before.
  void saveRound(int round, CounterRound entered) {
    if (round < 1 || round > nextRound) {
      throw ArgumentError.value(round, 'round', 'rounds are entered in order');
    }
    if (entered.entries.length != players.length) {
      throw ArgumentError.value(entered, 'entered', 'one entry per player');
    }
    for (final (first, second) in entered.alliances) {
      final atTable = [
        first,
        second,
      ].every((player) => player >= 0 && player < players.length);
      if (!atTable || first == second) {
        throw ArgumentError.value(
          entered.alliances,
          'alliances',
          'an alliance joins two different players of the game',
        );
      }
    }
    if (round == nextRound) {
      _rounds.add(entered);
      draftBids = null;
    } else {
      _rounds[round - 1] = entered;
    }
    // No further round will be played: bids entered for one are void.
    if (isOver) draftBids = null;
  }

  /// Every round entered so far, scored, with running totals.
  List<RoundScored> get scoredRounds {
    final totals = List.filled(players.length, 0);
    final scored = <RoundScored>[];
    for (final (index, round) in _rounds.indexed) {
      final entries = round.entries;
      final cards = cardsIn(index + 1);
      scored.add(
        RoundScored(
          round: index + 1,
          results: [
            for (final (player, entry) in entries.indexed)
              () {
                final bid = _scoredBid(entry, cards);
                bool made(int other) =>
                    _scoredBid(entries[other], cards) ==
                    entries[other].tricksWon;
                final byTheRules = scoreRound(
                  bid: bid,
                  tricksWon: entry.tricksWon,
                  cardsDealt: cards,
                  bonuses: _bonusList(entry),
                  scoring: scoring,
                  alliancesMade: alliancesMadeBy(player, [
                    for (final (first, second) in round.alliances)
                      Alliance(lootSeat: first, winnerSeat: second),
                  ], made),
                  wager: entry.wager,
                );
                final score = RoundScore(
                  bidPoints: byTheRules.bidPoints,
                  bonusPoints: byTheRules.bonusPoints + entry.manualBonus,
                  alliancePoints: byTheRules.alliancePoints,
                  wagerPoints: byTheRules.wagerPoints,
                );
                totals[player] += score.total;
                return SeatResult(
                  bid: bid,
                  tricksWon: entry.tricksWon,
                  bonuses: _bonusList(entry),
                  score: score,
                  totalScore: totals[player],
                );
              }(),
          ],
        ),
      );
    }
    return scored;
  }

  /// The bid [entry] is scored on: Harry may move it, but never out of what
  /// a round of [cards] cards allows.
  static int _scoredBid(CounterEntry entry, int cards) =>
      (entry.bid + entry.bidChange).clamp(0, cards);

  static List<Bonus> _bonusList(CounterEntry entry) => [
    for (final MapEntry(key: bonus, value: count) in entry.bonuses.entries)
      for (var i = 0; i < count; i++) bonus,
  ];

  /// Total score of each player.
  List<int> get totals => _rounds.isEmpty
      ? List.filled(players.length, 0)
      : [for (final result in scoredRounds.last.results) result.totalScore];

  /// Ten rounds were entered and one player is ahead alone.
  bool get isOver => winner != null;

  /// The winner, once ten rounds give a single leader.
  int? get winner =>
      _rounds.length >= standardRounds ? soleLeader(totals) : null;

  Map<String, Object?> toJson() => {
    'players': players,
    'firstLeader': firstLeader,
    'scoring': scoring.name,
    'loot': loot,
    'piratePowers': piratePowers,
    if (manualBonuses) 'manualBonuses': true,
    if (secondExpansion) 'secondExpansion': true,
    'rounds': [for (final round in _rounds) round.toJson()],
    'draftBids': ?draftBids,
  };
}
