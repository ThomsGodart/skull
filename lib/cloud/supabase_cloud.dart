import 'dart:async';
import 'dart:convert';

import 'package:supabase/supabase.dart';

import '../storage/settings_store.dart';
import 'cloud_backup.dart';

/// The user of this phone, as the cloud knows them: an anonymous account made
/// the first time it is needed, with nothing to type. Its session is kept
/// with the settings, so the same account is found again at the next launch.
/// It is lost with the app's data: nothing ties it to another phone.
final class CloudAccount {
  CloudAccount(this._client, this._store);

  /// The setting the session is kept under. Never backed up itself.
  static const sessionKey = 'cloudSession';

  final SupabaseClient _client;
  final SettingsStore _store;
  Future<void>? _signingIn;
  StreamSubscription<AuthState>? _changes;

  /// Signs in if that is not done yet. Throws when it cannot be.
  Future<void> ensureSignedIn() =>
      _signingIn ??= _signIn().onError((Object error, StackTrace stack) {
        // Tried again the next time it is needed.
        _signingIn = null;
        Error.throwWithStackTrace(error, stack);
      });

  Future<void> _signIn() async {
    final auth = _client.auth;
    _changes ??= auth.onAuthStateChange.listen((state) {
      final session = state.session;
      if (session != null) {
        unawaited(
          _store
              .write(sessionKey, jsonEncode(session.toJson()))
              .catchError((Object _) {}),
        );
      }
    }, onError: (Object _) {});
    final saved = (await _store.readAll())[sessionKey];
    if (saved != null && auth.currentSession == null) {
      try {
        await auth.recoverSession(saved);
      } on AuthRetryableFetchException {
        // The network, not the account: it is tried again later.
        rethrow;
      } on AuthException {
        // Expired or revoked: a new account takes its place.
      }
    }
    if (auth.currentSession == null) await auth.signInAnonymously();
  }
}

/// The table of the Supabase project where each user's copies are kept.
final class SupabaseCloudTable implements CloudTable {
  SupabaseCloudTable(this._client, this._account);

  static const _name = 'user_data';

  final SupabaseClient _client;
  final CloudAccount _account;

  @override
  Future<void> upsert(String kind, String key, CloudValue value) async {
    await _account.ensureSignedIn();
    await _client.from(_name).upsert({
      'kind': kind,
      'key': key,
      'value': value,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'user_id,kind,key');
  }

  @override
  Future<void> delete(String kind, String key) async {
    await _account.ensureSignedIn();
    await _client.from(_name).delete().eq('kind', kind).eq('key', key);
  }
}
