import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_service.dart';

/// Emits Supabase auth state changes. Empty stream when backend is off.
final authStateProvider = StreamProvider<AuthState?>((ref) {
  if (!SupabaseService.isReady) return const Stream<AuthState?>.empty();
  return SupabaseService.auth.onAuthStateChange;
});

/// Current signed-in user (falls back to the synchronous getter so a
/// provider created while already-authenticated still sees the user).
final currentUserProvider = Provider<User?>((ref) {
  final state = ref.watch(authStateProvider);
  return state.maybeWhen(
    data: (s) => s?.session?.user ?? SupabaseService.currentUser,
    orElse: () => SupabaseService.currentUser,
  );
});

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>(
  (ref) => AuthController(),
);

class AuthController extends StateNotifier<AsyncValue<void>> {
  AuthController() : super(const AsyncData(null));

  bool get _ok {
    if (!SupabaseService.isReady) {
      state = AsyncError(
        '백엔드가 설정되지 않았습니다. .env(SUPABASE_URL/ANON_KEY)를 확인하세요.',
        StackTrace.current,
      );
      return false;
    }
    return true;
  }

  Future<bool> signIn(String email, String password) async {
    if (!_ok) return false;
    state = const AsyncLoading();
    try {
      await SupabaseService.auth
          .signInWithPassword(email: email.trim(), password: password);
      state = const AsyncData(null);
      return true;
    } catch (e, s) {
      state = AsyncError(e, s);
      return false;
    }
  }

  Future<bool> signUp(String email, String password) async {
    if (!_ok) return false;
    state = const AsyncLoading();
    try {
      // 인증 메일 링크가 Supabase "Site URL" 이 아니라 지금 열려 있는 이 앱 주소로
      // 돌아오게 한다 — 다른 앱과 Supabase 프로젝트를 같이 쓸 때 Site URL 을 바꾸지
      // 않아도 된다. 이 주소는 Authentication → URL Configuration → Redirect URLs 에
      // 등록돼 있어야 한다 (없으면 Supabase 가 Site URL 로 보냄).
      await SupabaseService.auth.signUp(
        email: email.trim(),
        password: password,
        emailRedirectTo: kIsWeb ? Uri.base.removeFragment().toString() : null,
      );
      state = const AsyncData(null);
      return true;
    } catch (e, s) {
      state = AsyncError(e, s);
      return false;
    }
  }

  Future<void> signOut() async {
    if (!SupabaseService.isReady) return;
    await SupabaseService.auth.signOut();
  }
}
