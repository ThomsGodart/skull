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
          ..write('winner: $winner')
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
          other.winner == this.winner);
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
          ..write('winner: $winner')
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
  late final $SettingsTable settings = $SettingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [games, settings];
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
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
}
