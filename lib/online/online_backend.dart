import 'package:supabase/supabase.dart';

/// Where the rooms of online games live: a Supabase project of its own.
///
/// Both values are meant to ship with the app: the key only lets a phone use
/// what the project opens to everyone.
abstract final class OnlineBackend {
  static const url = 'https://amzcprgqqwvnrrrvckai.supabase.co';
  static const publishableKey =
      'sb_publishable_QzLBVo27Qt9-ad0-pcidLg_XgSzHXYb';
}

SupabaseClient? _client;

/// The app's one connection to the online backend, made when first needed.
SupabaseClient onlineClient() =>
    _client ??= SupabaseClient(OnlineBackend.url, OnlineBackend.publishableKey);
