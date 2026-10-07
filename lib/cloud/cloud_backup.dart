import 'dart:async';

/// What is sent to the cloud for one thing kept on the phone.
typedef CloudValue = Map<String, Object?>;

/// The kinds of things backed up.
abstract final class CloudKind {
  static const setting = 'setting';
  static const game = 'game';
  static const counter = 'counter';
}

/// A copy, in the cloud, of what the phone keeps: its user's settings, games
/// and counted games. The phone stays the one place the app reads from; the
/// copy follows it when the network allows, and never stands in its way.
abstract interface class CloudBackup {
  /// Copies the thing [key] of [kind]. [read] is called when the copy is
  /// actually made, which may be a moment later: several changes in a row
  /// make one copy. A null value means there is nothing to copy any more.
  void put(String kind, String key, Future<CloudValue?> Function() read);

  /// Forgets the copy of the thing [key] of [kind].
  void remove(String kind, String key);
}

/// No copy at all: for tests, and when the cloud cannot be reached.
final class NoCloudBackup implements CloudBackup {
  const NoCloudBackup();

  @override
  void put(String kind, String key, Future<CloudValue?> Function() read) {}

  @override
  void remove(String kind, String key) {}
}

/// Where the copies go. Both may throw: the network is never a given.
abstract interface class CloudTable {
  Future<void> upsert(String kind, String key, CloudValue value);

  Future<void> delete(String kind, String key);
}

/// A backup that waits a little before each copy, so that a game does not
/// call the network at every card, and that gives up quietly on any failure:
/// the next change, or the next launch, makes the copy again.
final class DebouncedCloudBackup implements CloudBackup {
  DebouncedCloudBackup(this._table, {this.delay = const Duration(seconds: 3)});

  final CloudTable _table;
  final Duration delay;
  final Map<(String, String), Timer> _timers = {};

  @override
  void put(String kind, String key, Future<CloudValue?> Function() read) {
    _timers.remove((kind, key))?.cancel();
    _timers[(kind, key)] = Timer(delay, () {
      _timers.remove((kind, key));
      unawaited(_copy(kind, key, read));
    });
  }

  Future<void> _copy(
    String kind,
    String key,
    Future<CloudValue?> Function() read,
  ) async {
    try {
      final value = await read();
      if (value != null) await _table.upsert(kind, key, value);
    } on Object {
      // Offline, signed out, or the thing is gone: nothing to do about it.
    }
  }

  @override
  void remove(String kind, String key) {
    _timers.remove((kind, key))?.cancel();
    unawaited(_table.delete(kind, key).catchError((Object _) {}));
  }

  /// Drops the copies still waiting to be made.
  void dispose() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
  }
}
