// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $GamesTable extends Games with TableInfo<$GamesTable, StoredGame> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GamesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _configMeta = const VerificationMeta('config');
  @override
  late final GeneratedColumn<String> config = GeneratedColumn<String>(
    'config',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _answersMeta = const VerificationMeta(
    'answers',
  );
  @override
  late final GeneratedColumn<String> answers = GeneratedColumn<String>(
    'answers',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _roundMeta = const VerificationMeta('round');
  @override
  late final GeneratedColumn<int> round = GeneratedColumn<int>(
    'round',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _humanScoreMeta = const VerificationMeta(
    'humanScore',
  );
  @override
  late final GeneratedColumn<int> humanScore = GeneratedColumn<int>(
    'human_score',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _finishedAtMeta = const VerificationMeta(
    'finishedAt',
  );
  @override
  late final GeneratedColumn<DateTime> finishedAt = GeneratedColumn<DateTime>(
    'finished_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _finalScoresMeta = const VerificationMeta(
    'finalScores',
  );
  @override
  late final GeneratedColumn<String> finalScores = GeneratedColumn<String>(
    'final_scores',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _winnerMeta = const VerificationMeta('winner');
  @override
  late final GeneratedColumn<int> winner = GeneratedColumn<int>(
    'winner',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _playerNameMeta = const VerificationMeta(
    'playerName',
  );
  @override
  late final GeneratedColumn<String> playerName = GeneratedColumn<String>(
    'player_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _roundsPlayedMeta = const VerificationMeta(
    'roundsPlayed',
  );
  @override
  late final GeneratedColumn<int> roundsPlayed = GeneratedColumn<int>(
    'rounds_played',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bidsMadeMeta = const VerificationMeta(
    'bidsMade',
  );
  @override
  late final GeneratedColumn<int> bidsMade = GeneratedColumn<int>(
    'bids_made',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _zeroBidsMeta = const VerificationMeta(
    'zeroBids',
  );
  @override
  late final GeneratedColumn<int> zeroBids = GeneratedColumn<int>(
    'zero_bids',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _zeroBidsMadeMeta = const VerificationMeta(
    'zeroBidsMade',
  );
  @override
  late final GeneratedColumn<int> zeroBidsMade = GeneratedColumn<int>(
    'zero_bids_made',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    startedAt,
    config,
    answers,
    round,
    humanScore,
    finishedAt,
    finalScores,
    winner,
    playerName,
    roundsPlayed,
    bidsMade,
    zeroBids,
    zeroBidsMade,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'games';
  @override
  VerificationContext validateIntegrity(
    Insertable<StoredGame> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    }
    if (data.containsKey('config')) {
      context.handle(
        _configMeta,
        config.isAcceptableOrUnknown(data['config']!, _configMeta),
      );
    } else if (isInserting) {
      context.missing(_configMeta);
    }
    if (data.containsKey('answers')) {
      context.handle(
        _answersMeta,
        answers.isAcceptableOrUnknown(data['answers']!, _answersMeta),
      );
    }
    if (data.containsKey('round')) {
      context.handle(
        _roundMeta,
        round.isAcceptableOrUnknown(data['round']!, _roundMeta),
      );
    }
    if (data.containsKey('human_score')) {
      context.handle(
        _humanScoreMeta,
        humanScore.isAcceptableOrUnknown(data['human_score']!, _humanScoreMeta),
      );
    }
    if (data.containsKey('finished_at')) {
      context.handle(
        _finishedAtMeta,
        finishedAt.isAcceptableOrUnknown(data['finished_at']!, _finishedAtMeta),
      );
    }
    if (data.containsKey('final_scores')) {
      context.handle(
        _finalScoresMeta,
        finalScores.isAcceptableOrUnknown(
          data['final_scores']!,
          _finalScoresMeta,
        ),
      );
    }
    if (data.containsKey('winner')) {
      context.handle(
        _winnerMeta,
        winner.isAcceptableOrUnknown(data['winner']!, _winnerMeta),
      );
    }
    if (data.containsKey('player_name')) {
      context.handle(
        _playerNameMeta,
        playerName.isAcceptableOrUnknown(data['player_name']!, _playerNameMeta),
      );
    }
    if (data.containsKey('rounds_played')) {
      context.handle(
        _roundsPlayedMeta,
        roundsPlayed.isAcceptableOrUnknown(
          data['rounds_played']!,
          _roundsPlayedMeta,
        ),
      );
    }
    if (data.containsKey('bids_made')) {
      context.handle(
        _bidsMadeMeta,
        bidsMade.isAcceptableOrUnknown(data['bids_made']!, _bidsMadeMeta),
      );
    }
    if (data.containsKey('zero_bids')) {
      context.handle(
        _zeroBidsMeta,
        zeroBids.isAcceptableOrUnknown(data['zero_bids']!, _zeroBidsMeta),
      );
    }
    if (data.containsKey('zero_bids_made')) {
      context.handle(
        _zeroBidsMadeMeta,
        zeroBidsMade.isAcceptableOrUnknown(
          data['zero_bids_made']!,
          _zeroBidsMadeMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StoredGame map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoredGame(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      config: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}config'],
      )!,
      answers: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}answers'],
      )!,
      round: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}round'],
      )!,
      humanScore: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}human_score'],
      )!,
      finishedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}finished_at'],
      ),
      finalScores: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}final_scores'],
      ),
      winner: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}winner'],
      ),
      playerName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}player_name'],
      ),
      roundsPlayed: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rounds_played'],
      ),
      bidsMade: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bids_made'],
      ),
      zeroBids: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}zero_bids'],
      ),
      zeroBidsMade: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}zero_bids_made'],
      ),
    );
  }

  @override
  $GamesTable createAlias(String alias) {
    return $GamesTable(attachedDatabase, alias);
  }
}

class StoredGame extends DataClass implements Insertable<StoredGame> {
  final int id;
  final DateTime startedAt;

  /// The game's `GameConfig`, as JSON.
  final String config;

  /// Every answer given so far, in order, as a JSON list.
  final String answers;

  /// Where the game stands, to describe it without replaying it.
  final int round;
  final int humanScore;
  final DateTime? finishedAt;

  /// Final score of each seat, as a JSON list. Set when the game is over.
  final String? finalScores;
  final int? winner;

  /// What the human was called when the game ended.
  final String? playerName;

  /// How the human bid over the game, for the statistics. All four are set
  /// together when the game ends; null for a game kept before version 2.
  final int? roundsPlayed;
  final int? bidsMade;
  final int? zeroBids;
  final int? zeroBidsMade;
  const StoredGame({
    required this.id,
    required this.startedAt,
    required this.config,
    required this.answers,
    required this.round,
    required this.humanScore,
    this.finishedAt,
    this.finalScores,
    this.winner,
    this.playerName,
    this.roundsPlayed,
    this.bidsMade,
    this.zeroBids,
    this.zeroBidsMade,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['started_at'] = Variable<DateTime>(startedAt);
    map['config'] = Variable<String>(config);
    map['answers'] = Variable<String>(answers);
    map['round'] = Variable<int>(round);
    map['human_score'] = Variable<int>(humanScore);
    if (!nullToAbsent || finishedAt != null) {
      map['finished_at'] = Variable<DateTime>(finishedAt);
    }
    if (!nullToAbsent || finalScores != null) {
      map['final_scores'] = Variable<String>(finalScores);
    }
    if (!nullToAbsent || winner != null) {
      map['winner'] = Variable<int>(winner);
    }
    if (!nullToAbsent || playerName != null) {
      map['player_name'] = Variable<String>(playerName);
    }
    if (!nullToAbsent || roundsPlayed != null) {
      map['rounds_played'] = Variable<int>(roundsPlayed);
    }
    if (!nullToAbsent || bidsMade != null) {
      map['bids_made'] = Variable<int>(bidsMade);
    }
    if (!nullToAbsent || zeroBids != null) {
      map['zero_bids'] = Variable<int>(zeroBids);
    }
    if (!nullToAbsent || zeroBidsMade != null) {
      map['zero_bids_made'] = Variable<int>(zeroBidsMade);
    }
    return map;
  }

  GamesCompanion toCompanion(bool nullToAbsent) {
    return GamesCompanion(
      id: Value(id),
      startedAt: Value(startedAt),
      config: Value(config),
      answers: Value(answers),
      round: Value(round),
      humanScore: Value(humanScore),
      finishedAt: finishedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(finishedAt),
      finalScores: finalScores == null && nullToAbsent
          ? const Value.absent()
          : Value(finalScores),
      winner: winner == null && nullToAbsent
          ? const Value.absent()
          : Value(winner),
      playerName: playerName == null && nullToAbsent
          ? const Value.absent()
          : Value(playerName),
      roundsPlayed: roundsPlayed == null && nullToAbsent
          ? const Value.absent()
          : Value(roundsPlayed),
      bidsMade: bidsMade == null && nullToAbsent
          ? const Value.absent()
          : Value(bidsMade),
      zeroBids: zeroBids == null && nullToAbsent
          ? const Value.absent()
          : Value(zeroBids),
      zeroBidsMade: zeroBidsMade == null && nullToAbsent
          ? const Value.absent()
          : Value(zeroBidsMade),
    );
  }

  factory StoredGame.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoredGame(
      id: serializer.fromJson<int>(json['id']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      config: serializer.fromJson<String>(json['config']),
      answers: serializer.fromJson<String>(json['answers']),
      round: serializer.fromJson<int>(json['round']),
      humanScore: serializer.fromJson<int>(json['humanScore']),
      finishedAt: serializer.fromJson<DateTime?>(json['finishedAt']),
      finalScores: serializer.fromJson<String?>(json['finalScores']),
      winner: serializer.fromJson<int?>(json['winner']),
      playerName: serializer.fromJson<String?>(json['playerName']),
      roundsPlayed: serializer.fromJson<int?>(json['roundsPlayed']),
      bidsMade: serializer.fromJson<int?>(json['bidsMade']),
      zeroBids: serializer.fromJson<int?>(json['zeroBids']),
      zeroBidsMade: serializer.fromJson<int?>(json['zeroBidsMade']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'config': serializer.toJson<String>(config),
      'answers': serializer.toJson<String>(answers),
      'round': serializer.toJson<int>(round),
      'humanScore': serializer.toJson<int>(humanScore),
      'finishedAt': serializer.toJson<DateTime?>(finishedAt),
      'finalScores': serializer.toJson<String?>(finalScores),
      'winner': serializer.toJson<int?>(winner),
      'playerName': serializer.toJson<String?>(playerName),
      'roundsPlayed': serializer.toJson<int?>(roundsPlayed),
      'bidsMade': serializer.toJson<int?>(bidsMade),
      'zeroBids': serializer.toJson<int?>(zeroBids),
      'zeroBidsMade': serializer.toJson<int?>(zeroBidsMade),
    };
  }

  StoredGame copyWith({
    int? id,
    DateTime? startedAt,
    String? config,
    String? answers,
    int? round,
    int? humanScore,
    Value<DateTime?> finishedAt = const Value.absent(),
    Value<String?> finalScores = const Value.absent(),
    Value<int?> winner = const Value.absent(),
    Value<String?> playerName = const Value.absent(),
    Value<int?> roundsPlayed = const Value.absent(),
    Value<int?> bidsMade = const Value.absent(),
    Value<int?> zeroBids = const Value.absent(),
    Value<int?> zeroBidsMade = const Value.absent(),
  }) => StoredGame(
    id: id ?? this.id,
    startedAt: startedAt ?? this.startedAt,
    config: config ?? this.config,
    answers: answers ?? this.answers,
    round: round ?? this.round,
    humanScore: humanScore ?? this.humanScore,
    finishedAt: finishedAt.present ? finishedAt.value : this.finishedAt,
    finalScores: finalScores.present ? finalScores.value : this.finalScores,
    winner: winner.present ? winner.value : this.winner,
    playerName: playerName.present ? playerName.value : this.playerName,
    roundsPlayed: roundsPlayed.present ? roundsPlayed.value : this.roundsPlayed,
    bidsMade: bidsMade.present ? bidsMade.value : this.bidsMade,
    zeroBids: zeroBids.present ? zeroBids.value : this.zeroBids,
    zeroBidsMade: zeroBidsMade.present ? zeroBidsMade.value : this.zeroBidsMade,
  );
  StoredGame copyWithCompanion(GamesCompanion data) {
    return StoredGame(
      id: data.id.present ? data.id.value : this.id,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      config: data.config.present ? data.config.value : this.config,
      answers: data.answers.present ? data.answers.value : this.answers,
      round: data.round.present ? data.round.value : this.round,
      humanScore: data.humanScore.present
          ? data.humanScore.value
          : this.humanScore,
      finishedAt: data.finishedAt.present
          ? data.finishedAt.value
          : this.finishedAt,
      finalScores: data.finalScores.present
          ? data.finalScores.value
          : this.finalScores,
      winner: data.winner.present ? data.winner.value : this.winner,
      playerName: data.playerName.present
          ? data.playerName.value
          : this.playerName,
      roundsPlayed: data.roundsPlayed.present
          ? data.roundsPlayed.value
          : this.roundsPlayed,
      bidsMade: data.bidsMade.present ? data.bidsMade.value : this.bidsMade,
      zeroBids: data.zeroBids.present ? data.zeroBids.value : this.zeroBids,
      zeroBidsMade: data.zeroBidsMade.present
          ? data.zeroBidsMade.value
          : this.zeroBidsMade,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoredGame(')
          ..write('id: $id, ')
          ..write('startedAt: $startedAt, ')
          ..write('config: $config, ')
          ..write('answers: $answers, ')
          ..write('round: $round, ')
          ..write('humanScore: $humanScore, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('finalScores: $finalScores, ')
          ..write('winner: $winner, ')
          ..write('playerName: $playerName, ')
          ..write('roundsPlayed: $roundsPlayed, ')
          ..write('bidsMade: $bidsMade, ')
          ..write('zeroBids: $zeroBids, ')
          ..write('zeroBidsMade: $zeroBidsMade')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    startedAt,
    config,
    answers,
    round,
    humanScore,
    finishedAt,
    finalScores,
    winner,
    playerName,
    roundsPlayed,
    bidsMade,
    zeroBids,
    zeroBidsMade,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoredGame &&
          other.id == this.id &&
          other.startedAt == this.startedAt &&
          other.config == this.config &&
          other.answers == this.answers &&
          other.round == this.round &&
          other.humanScore == this.humanScore &&
          other.finishedAt == this.finishedAt &&
          other.finalScores == this.finalScores &&
          other.winner == this.winner &&
          other.playerName == this.playerName &&
          other.roundsPlayed == this.roundsPlayed &&
          other.bidsMade == this.bidsMade &&
          other.zeroBids == this.zeroBids &&
          other.zeroBidsMade == this.zeroBidsMade);
}

class GamesCompanion extends UpdateCompanion<StoredGame> {
  final Value<int> id;
  final Value<DateTime> startedAt;
  final Value<String> config;
  final Value<String> answers;
  final Value<int> round;
  final Value<int> humanScore;
  final Value<DateTime?> finishedAt;
  final Value<String?> finalScores;
  final Value<int?> winner;
  final Value<String?> playerName;
  final Value<int?> roundsPlayed;
  final Value<int?> bidsMade;
  final Value<int?> zeroBids;
  final Value<int?> zeroBidsMade;
  const GamesCompanion({
    this.id = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.config = const Value.absent(),
    this.answers = const Value.absent(),
    this.round = const Value.absent(),
    this.humanScore = const Value.absent(),
    this.finishedAt = const Value.absent(),
    this.finalScores = const Value.absent(),
    this.winner = const Value.absent(),
    this.playerName = const Value.absent(),
    this.roundsPlayed = const Value.absent(),
    this.bidsMade = const Value.absent(),
    this.zeroBids = const Value.absent(),
    this.zeroBidsMade = const Value.absent(),
  });
  GamesCompanion.insert({
    this.id = const Value.absent(),
    this.startedAt = const Value.absent(),
    required String config,
    this.answers = const Value.absent(),
    this.round = const Value.absent(),
    this.humanScore = const Value.absent(),
    this.finishedAt = const Value.absent(),
    this.finalScores = const Value.absent(),
    this.winner = const Value.absent(),
    this.playerName = const Value.absent(),
    this.roundsPlayed = const Value.absent(),
    this.bidsMade = const Value.absent(),
    this.zeroBids = const Value.absent(),
    this.zeroBidsMade = const Value.absent(),
  }) : config = Value(config);
  static Insertable<StoredGame> custom({
    Expression<int>? id,
    Expression<DateTime>? startedAt,
    Expression<String>? config,
    Expression<String>? answers,
    Expression<int>? round,
    Expression<int>? humanScore,
    Expression<DateTime>? finishedAt,
    Expression<String>? finalScores,
    Expression<int>? winner,
    Expression<String>? playerName,
    Expression<int>? roundsPlayed,
    Expression<int>? bidsMade,
    Expression<int>? zeroBids,
    Expression<int>? zeroBidsMade,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (startedAt != null) 'started_at': startedAt,
      if (config != null) 'config': config,
      if (answers != null) 'answers': answers,
      if (round != null) 'round': round,
      if (humanScore != null) 'human_score': humanScore,
      if (finishedAt != null) 'finished_at': finishedAt,
      if (finalScores != null) 'final_scores': finalScores,
      if (winner != null) 'winner': winner,
      if (playerName != null) 'player_name': playerName,
      if (roundsPlayed != null) 'rounds_played': roundsPlayed,
      if (bidsMade != null) 'bids_made': bidsMade,
      if (zeroBids != null) 'zero_bids': zeroBids,
      if (zeroBidsMade != null) 'zero_bids_made': zeroBidsMade,
    });
  }

  GamesCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? startedAt,
    Value<String>? config,
    Value<String>? answers,
    Value<int>? round,
    Value<int>? humanScore,
    Value<DateTime?>? finishedAt,
    Value<String?>? finalScores,
    Value<int?>? winner,
    Value<String?>? playerName,
    Value<int?>? roundsPlayed,
    Value<int?>? bidsMade,
    Value<int?>? zeroBids,
    Value<int?>? zeroBidsMade,
  }) {
    return GamesCompanion(
      id: id ?? this.id,
      startedAt: startedAt ?? this.startedAt,
      config: config ?? this.config,
      answers: answers ?? this.answers,
      round: round ?? this.round,
      humanScore: humanScore ?? this.humanScore,
      finishedAt: finishedAt ?? this.finishedAt,
      finalScores: finalScores ?? this.finalScores,
      winner: winner ?? this.winner,
      playerName: playerName ?? this.playerName,
      roundsPlayed: roundsPlayed ?? this.roundsPlayed,
      bidsMade: bidsMade ?? this.bidsMade,
      zeroBids: zeroBids ?? this.zeroBids,
      zeroBidsMade: zeroBidsMade ?? this.zeroBidsMade,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (config.present) {
      map['config'] = Variable<String>(config.value);
    }
    if (answers.present) {
      map['answers'] = Variable<String>(answers.value);
    }
    if (round.present) {
      map['round'] = Variable<int>(round.value);
    }
    if (humanScore.present) {
      map['human_score'] = Variable<int>(humanScore.value);
    }
    if (finishedAt.present) {
      map['finished_at'] = Variable<DateTime>(finishedAt.value);
    }
    if (finalScores.present) {
      map['final_scores'] = Variable<String>(finalScores.value);
    }
    if (winner.present) {
      map['winner'] = Variable<int>(winner.value);
    }
    if (playerName.present) {
      map['player_name'] = Variable<String>(playerName.value);
    }
    if (roundsPlayed.present) {
      map['rounds_played'] = Variable<int>(roundsPlayed.value);
    }
    if (bidsMade.present) {
      map['bids_made'] = Variable<int>(bidsMade.value);
    }
    if (zeroBids.present) {
      map['zero_bids'] = Variable<int>(zeroBids.value);
    }
    if (zeroBidsMade.present) {
      map['zero_bids_made'] = Variable<int>(zeroBidsMade.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GamesCompanion(')
          ..write('id: $id, ')
          ..write('startedAt: $startedAt, ')
          ..write('config: $config, ')
          ..write('answers: $answers, ')
          ..write('round: $round, ')
          ..write('humanScore: $humanScore, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('finalScores: $finalScores, ')
          ..write('winner: $winner, ')
          ..write('playerName: $playerName, ')
          ..write('roundsPlayed: $roundsPlayed, ')
          ..write('bidsMade: $bidsMade, ')
          ..write('zeroBids: $zeroBids, ')
          ..write('zeroBidsMade: $zeroBidsMade')
          ..write(')'))
        .toString();
  }
}

class $CounterGamesTable extends CounterGames
    with TableInfo<$CounterGamesTable, StoredCounterGame> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CounterGamesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _finishedAtMeta = const VerificationMeta(
    'finishedAt',
  );
  @override
  late final GeneratedColumn<DateTime> finishedAt = GeneratedColumn<DateTime>(
    'finished_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _gameMeta = const VerificationMeta('game');
  @override
  late final GeneratedColumn<String> game = GeneratedColumn<String>(
    'game',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, startedAt, finishedAt, game];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'counter_games';
  @override
  VerificationContext validateIntegrity(
    Insertable<StoredCounterGame> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    }
    if (data.containsKey('finished_at')) {
      context.handle(
        _finishedAtMeta,
        finishedAt.isAcceptableOrUnknown(data['finished_at']!, _finishedAtMeta),
      );
    }
    if (data.containsKey('game')) {
      context.handle(
        _gameMeta,
        game.isAcceptableOrUnknown(data['game']!, _gameMeta),
      );
    } else if (isInserting) {
      context.missing(_gameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StoredCounterGame map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoredCounterGame(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      finishedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}finished_at'],
      ),
      game: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}game'],
      )!,
    );
  }

  @override
  $CounterGamesTable createAlias(String alias) {
    return $CounterGamesTable(attachedDatabase, alias);
  }
}

class StoredCounterGame extends DataClass
    implements Insertable<StoredCounterGame> {
  final int id;
  final DateTime startedAt;
  final DateTime? finishedAt;

  /// The whole `CounterGame`, as JSON.
  final String game;
  const StoredCounterGame({
    required this.id,
    required this.startedAt,
    this.finishedAt,
    required this.game,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || finishedAt != null) {
      map['finished_at'] = Variable<DateTime>(finishedAt);
    }
    map['game'] = Variable<String>(game);
    return map;
  }

  CounterGamesCompanion toCompanion(bool nullToAbsent) {
    return CounterGamesCompanion(
      id: Value(id),
      startedAt: Value(startedAt),
      finishedAt: finishedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(finishedAt),
      game: Value(game),
    );
  }

  factory StoredCounterGame.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoredCounterGame(
      id: serializer.fromJson<int>(json['id']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      finishedAt: serializer.fromJson<DateTime?>(json['finishedAt']),
      game: serializer.fromJson<String>(json['game']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'finishedAt': serializer.toJson<DateTime?>(finishedAt),
      'game': serializer.toJson<String>(game),
    };
  }

  StoredCounterGame copyWith({
    int? id,
    DateTime? startedAt,
    Value<DateTime?> finishedAt = const Value.absent(),
    String? game,
  }) => StoredCounterGame(
    id: id ?? this.id,
    startedAt: startedAt ?? this.startedAt,
    finishedAt: finishedAt.present ? finishedAt.value : this.finishedAt,
    game: game ?? this.game,
  );
  StoredCounterGame copyWithCompanion(CounterGamesCompanion data) {
    return StoredCounterGame(
      id: data.id.present ? data.id.value : this.id,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      finishedAt: data.finishedAt.present
          ? data.finishedAt.value
          : this.finishedAt,
      game: data.game.present ? data.game.value : this.game,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoredCounterGame(')
          ..write('id: $id, ')
          ..write('startedAt: $startedAt, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('game: $game')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, startedAt, finishedAt, game);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoredCounterGame &&
          other.id == this.id &&
          other.startedAt == this.startedAt &&
          other.finishedAt == this.finishedAt &&
          other.game == this.game);
}

class CounterGamesCompanion extends UpdateCompanion<StoredCounterGame> {
  final Value<int> id;
  final Value<DateTime> startedAt;
  final Value<DateTime?> finishedAt;
  final Value<String> game;
  const CounterGamesCompanion({
    this.id = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.finishedAt = const Value.absent(),
    this.game = const Value.absent(),
  });
  CounterGamesCompanion.insert({
    this.id = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.finishedAt = const Value.absent(),
    required String game,
  }) : game = Value(game);
  static Insertable<StoredCounterGame> custom({
    Expression<int>? id,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? finishedAt,
    Expression<String>? game,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (startedAt != null) 'started_at': startedAt,
      if (finishedAt != null) 'finished_at': finishedAt,
      if (game != null) 'game': game,
    });
  }

  CounterGamesCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? startedAt,
    Value<DateTime?>? finishedAt,
    Value<String>? game,
  }) {
    return CounterGamesCompanion(
      id: id ?? this.id,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      game: game ?? this.game,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (finishedAt.present) {
      map['finished_at'] = Variable<DateTime>(finishedAt.value);
    }
    if (game.present) {
      map['game'] = Variable<String>(game.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CounterGamesCompanion(')
          ..write('id: $id, ')
          ..write('startedAt: $startedAt, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('game: $game')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings
    with TableInfo<$SettingsTable, StoredSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<StoredSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  StoredSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoredSetting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class StoredSetting extends DataClass implements Insertable<StoredSetting> {
  final String key;
  final String value;
  const StoredSetting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(key: Value(key), value: Value(value));
  }

  factory StoredSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoredSetting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  StoredSetting copyWith({String? key, String? value}) =>
      StoredSetting(key: key ?? this.key, value: value ?? this.value);
  StoredSetting copyWithCompanion(SettingsCompanion data) {
    return StoredSetting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoredSetting(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoredSetting &&
          other.key == this.key &&
          other.value == this.value);
}

class SettingsCompanion extends UpdateCompanion<StoredSetting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<StoredSetting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $GamesTable games = $GamesTable(this);
  late final $CounterGamesTable counterGames = $CounterGamesTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    games,
    counterGames,
    settings,
  ];
}

typedef $$GamesTableCreateCompanionBuilder = GamesCompanion Function({
  Value<int> id,
  Value<DateTime> startedAt,
  required String config,
  Value<String> answers,
  Value<int> round,
  Value<int> humanScore,
  Value<DateTime?> finishedAt,
  Value<String?> finalScores,
  Value<int?> winner,
  Value<String?> playerName,
  Value<int?> roundsPlayed,
  Value<int?> bidsMade,
  Value<int?> zeroBids,
  Value<int?> zeroBidsMade,
});
typedef $$GamesTableUpdateCompanionBuilder = GamesCompanion Function({
  Value<int> id,
  Value<DateTime> startedAt,
  Value<String> config,
  Value<String> answers,
  Value<int> round,
  Value<int> humanScore,
  Value<DateTime?> finishedAt,
  Value<String?> finalScores,
  Value<int?> winner,
  Value<String?> playerName,
  Value<int?> roundsPlayed,
  Value<int?> bidsMade,
  Value<int?> zeroBids,
  Value<int?> zeroBidsMade,
});

class $$GamesTableFilterComposer extends Composer<_$AppDatabase, $GamesTable> {
  $$GamesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get config => $composableBuilder(
    column: $table.config,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get answers => $composableBuilder(
    column: $table.answers,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get round => $composableBuilder(
    column: $table.round,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get humanScore => $composableBuilder(
    column: $table.humanScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get finalScores => $composableBuilder(
    column: $table.finalScores,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get winner => $composableBuilder(
    column: $table.winner,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get playerName => $composableBuilder(
    column: $table.playerName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get roundsPlayed => $composableBuilder(
    column: $table.roundsPlayed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bidsMade => $composableBuilder(
    column: $table.bidsMade,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get zeroBids => $composableBuilder(
    column: $table.zeroBids,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get zeroBidsMade => $composableBuilder(
    column: $table.zeroBidsMade,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GamesTableOrderingComposer
    extends Composer<_$AppDatabase, $GamesTable> {
  $$GamesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get config => $composableBuilder(
    column: $table.config,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get answers => $composableBuilder(
    column: $table.answers,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get round => $composableBuilder(
    column: $table.round,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get humanScore => $composableBuilder(
    column: $table.humanScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get finalScores => $composableBuilder(
    column: $table.finalScores,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get winner => $composableBuilder(
    column: $table.winner,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get playerName => $composableBuilder(
    column: $table.playerName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get roundsPlayed => $composableBuilder(
    column: $table.roundsPlayed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bidsMade => $composableBuilder(
    column: $table.bidsMade,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get zeroBids => $composableBuilder(
    column: $table.zeroBids,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get zeroBidsMade => $composableBuilder(
    column: $table.zeroBidsMade,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GamesTableAnnotationComposer
    extends Composer<_$AppDatabase, $GamesTable> {
  $$GamesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<String> get config =>
      $composableBuilder(column: $table.config, builder: (column) => column);

  GeneratedColumn<String> get answers =>
      $composableBuilder(column: $table.answers, builder: (column) => column);

  GeneratedColumn<int> get round =>
      $composableBuilder(column: $table.round, builder: (column) => column);

  GeneratedColumn<int> get humanScore => $composableBuilder(
    column: $table.humanScore,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get finalScores => $composableBuilder(
    column: $table.finalScores,
    builder: (column) => column,
  );

  GeneratedColumn<int> get winner =>
      $composableBuilder(column: $table.winner, builder: (column) => column);

  GeneratedColumn<String> get playerName => $composableBuilder(
    column: $table.playerName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get roundsPlayed => $composableBuilder(
    column: $table.roundsPlayed,
    builder: (column) => column,
  );

  GeneratedColumn<int> get bidsMade =>
      $composableBuilder(column: $table.bidsMade, builder: (column) => column);

  GeneratedColumn<int> get zeroBids =>
      $composableBuilder(column: $table.zeroBids, builder: (column) => column);

  GeneratedColumn<int> get zeroBidsMade => $composableBuilder(
    column: $table.zeroBidsMade,
    builder: (column) => column,
  );
}

class $$GamesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GamesTable,
          StoredGame,
          $$GamesTableFilterComposer,
          $$GamesTableOrderingComposer,
          $$GamesTableAnnotationComposer,
          $$GamesTableCreateCompanionBuilder,
          $$GamesTableUpdateCompanionBuilder,
          (StoredGame, BaseReferences<_$AppDatabase, $GamesTable, StoredGame>),
          StoredGame,
          PrefetchHooks Function()
        > {
  $$GamesTableTableManager(_$AppDatabase db, $GamesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GamesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GamesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GamesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<String> config = const Value.absent(),
                Value<String> answers = const Value.absent(),
                Value<int> round = const Value.absent(),
                Value<int> humanScore = const Value.absent(),
                Value<DateTime?> finishedAt = const Value.absent(),
                Value<String?> finalScores = const Value.absent(),
                Value<int?> winner = const Value.absent(),
                Value<String?> playerName = const Value.absent(),
                Value<int?> roundsPlayed = const Value.absent(),
                Value<int?> bidsMade = const Value.absent(),
                Value<int?> zeroBids = const Value.absent(),
                Value<int?> zeroBidsMade = const Value.absent(),
              }) => GamesCompanion(
                id: id,
                startedAt: startedAt,
                config: config,
                answers: answers,
                round: round,
                humanScore: humanScore,
                finishedAt: finishedAt,
                finalScores: finalScores,
                winner: winner,
                playerName: playerName,
                roundsPlayed: roundsPlayed,
                bidsMade: bidsMade,
                zeroBids: zeroBids,
                zeroBidsMade: zeroBidsMade,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                required String config,
                Value<String> answers = const Value.absent(),
                Value<int> round = const Value.absent(),
                Value<int> humanScore = const Value.absent(),
                Value<DateTime?> finishedAt = const Value.absent(),
                Value<String?> finalScores = const Value.absent(),
                Value<int?> winner = const Value.absent(),
                Value<String?> playerName = const Value.absent(),
                Value<int?> roundsPlayed = const Value.absent(),
                Value<int?> bidsMade = const Value.absent(),
                Value<int?> zeroBids = const Value.absent(),
                Value<int?> zeroBidsMade = const Value.absent(),
              }) => GamesCompanion.insert(
                id: id,
                startedAt: startedAt,
                config: config,
                answers: answers,
                round: round,
                humanScore: humanScore,
                finishedAt: finishedAt,
                finalScores: finalScores,
                winner: winner,
                playerName: playerName,
                roundsPlayed: roundsPlayed,
                bidsMade: bidsMade,
                zeroBids: zeroBids,
                zeroBidsMade: zeroBidsMade,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$GamesTable, StoredGame>(table),
                  BaseReferences<_$AppDatabase, $GamesTable, StoredGame>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GamesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GamesTable,
      StoredGame,
      $$GamesTableFilterComposer,
      $$GamesTableOrderingComposer,
      $$GamesTableAnnotationComposer,
      $$GamesTableCreateCompanionBuilder,
      $$GamesTableUpdateCompanionBuilder,
      (StoredGame, BaseReferences<_$AppDatabase, $GamesTable, StoredGame>),
      StoredGame,
      PrefetchHooks Function()
    >;
typedef $$CounterGamesTableCreateCompanionBuilder =
    CounterGamesCompanion Function({
      Value<int> id,
      Value<DateTime> startedAt,
      Value<DateTime?> finishedAt,
      required String game,
    });
typedef $$CounterGamesTableUpdateCompanionBuilder =
    CounterGamesCompanion Function({
      Value<int> id,
      Value<DateTime> startedAt,
      Value<DateTime?> finishedAt,
      Value<String> game,
    });

class $$CounterGamesTableFilterComposer
    extends Composer<_$AppDatabase, $CounterGamesTable> {
  $$CounterGamesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get game => $composableBuilder(
    column: $table.game,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CounterGamesTableOrderingComposer
    extends Composer<_$AppDatabase, $CounterGamesTable> {
  $$CounterGamesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get game => $composableBuilder(
    column: $table.game,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CounterGamesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CounterGamesTable> {
  $$CounterGamesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get game =>
      $composableBuilder(column: $table.game, builder: (column) => column);
}

class $$CounterGamesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CounterGamesTable,
          StoredCounterGame,
          $$CounterGamesTableFilterComposer,
          $$CounterGamesTableOrderingComposer,
          $$CounterGamesTableAnnotationComposer,
          $$CounterGamesTableCreateCompanionBuilder,
          $$CounterGamesTableUpdateCompanionBuilder,
          (
            StoredCounterGame,
            BaseReferences<
              _$AppDatabase,
              $CounterGamesTable,
              StoredCounterGame
            >,
          ),
          StoredCounterGame,
          PrefetchHooks Function()
        > {
  $$CounterGamesTableTableManager(_$AppDatabase db, $CounterGamesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CounterGamesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CounterGamesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CounterGamesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> finishedAt = const Value.absent(),
                Value<String> game = const Value.absent(),
              }) => CounterGamesCompanion(
                id: id,
                startedAt: startedAt,
                finishedAt: finishedAt,
                game: game,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> finishedAt = const Value.absent(),
                required String game,
              }) => CounterGamesCompanion.insert(
                id: id,
                startedAt: startedAt,
                finishedAt: finishedAt,
                game: game,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CounterGamesTable, StoredCounterGame>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $CounterGamesTable,
                    StoredCounterGame
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CounterGamesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CounterGamesTable,
      StoredCounterGame,
      $$CounterGamesTableFilterComposer,
      $$CounterGamesTableOrderingComposer,
      $$CounterGamesTableAnnotationComposer,
      $$CounterGamesTableCreateCompanionBuilder,
      $$CounterGamesTableUpdateCompanionBuilder,
      (
        StoredCounterGame,
        BaseReferences<_$AppDatabase, $CounterGamesTable, StoredCounterGame>,
      ),
      StoredCounterGame,
      PrefetchHooks Function()
    >;
typedef $$SettingsTableCreateCompanionBuilder = SettingsCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$SettingsTableUpdateCompanionBuilder = SettingsCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsTable,
          StoredSetting,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (
            StoredSetting,
            BaseReferences<_$AppDatabase, $SettingsTable, StoredSetting>,
          ),
          StoredSetting,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => SettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) => SettingsCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SettingsTable, StoredSetting>(table),
                  BaseReferences<_$AppDatabase, $SettingsTable, StoredSetting>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsTable,
      StoredSetting,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (
        StoredSetting,
        BaseReferences<_$AppDatabase, $SettingsTable, StoredSetting>,
      ),
      StoredSetting,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$GamesTableTableManager get games =>
      $$GamesTableTableManager(_db, _db.games);
  $$CounterGamesTableTableManager get counterGames =>
      $$CounterGamesTableTableManager(_db, _db.counterGames);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
}
