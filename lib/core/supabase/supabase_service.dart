import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/env.dart';

/// Thin wrapper around the global Supabase client. All access is guarded so
/// callers never crash when the backend is unconfigured.
class SupabaseService {
  SupabaseService._();

  static bool _initialized = false;

  static bool get isConfigured => Env.isSupabaseConfigured;
  static bool get isReady => _initialized;

  static Future<void> initialize() async {
    if (_initialized || !Env.isSupabaseConfigured) return;
    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
      // 기본 세션 키(sb-<ref>-auth-token)는 같은 도메인(hongsytop-tech.github.io)에서
      // 같은 Supabase 프로젝트를 쓰는 다른 앱과 공유돼, 그 앱의 로그인이 이 앱에
      // 그대로 적용된다. 앱 전용 키로 분리해 이 앱에서 따로 로그인하게 한다.
      authOptions: FlutterAuthClientOptions(
        localStorage: SharedPreferencesLocalStorage(
          persistSessionKey:
              'sb-${Uri.parse(Env.supabaseUrl).host.split('.').first}'
              '-wine-tasting-auth-token',
        ),
      ),
    );
    _initialized = true;
  }

  static SupabaseClient get client => Supabase.instance.client;

  static GoTrueClient get auth => Supabase.instance.client.auth;

  /// Null when the backend isn't ready or nobody is signed in.
  static User? get currentUser {
    if (!_initialized) return null;
    return Supabase.instance.client.auth.currentUser;
  }

  static bool get isSignedIn => currentUser != null;
}
