import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/screens/login_screen.dart';
import '../../features/search/screens/search_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/tasting/screens/note_edit_screen.dart';
import '../../features/tasting/screens/notes_screen.dart';
import '../../features/wines/screens/cellar_screen.dart';
import '../../features/wines/screens/wine_detail_screen.dart';
import '../../features/wines/screens/wine_edit_screen.dart';
import '../../shell/app_shell.dart';
import '../supabase/supabase_service.dart';
import 'auth_refresh_notifier.dart';

class Routes {
  static const cellar = '/cellar';
  static const search = '/search';
  static const notes = '/notes';
  static const settings = '/settings';
  static const login = '/login';
  static const newWine = '/wine/new';

  static String wine(String id) => '/wine/$id';
  static String editWine(String id) => '/wine/$id/edit';
  static String newNote(String wineId) => '/wine/$wineId/note/new';
  static String note(String noteId) => '/note/$noteId';
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = AuthRefreshNotifier(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: Routes.cellar,
    refreshListenable: refresh,
    redirect: (context, state) {
      // Backend off → app is fully usable offline; skip the auth gate.
      if (!SupabaseService.isReady) return null;

      final loggedIn = SupabaseService.isSignedIn;
      final loggingIn = state.matchedLocation == Routes.login;

      if (!loggedIn && !loggingIn) return Routes.login;
      if (loggedIn && loggingIn) return Routes.cellar;
      return null;
    },
    routes: [
      GoRoute(
        path: Routes.login,
        builder: (_, __) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: Routes.cellar,
            builder: (_, __) => const CellarScreen(),
          ),
          GoRoute(
            path: Routes.search,
            builder: (_, __) => const SearchScreen(),
          ),
          GoRoute(
            path: Routes.notes,
            builder: (_, __) => const NotesScreen(),
          ),
          GoRoute(
            path: Routes.settings,
            builder: (_, __) => const SettingsScreen(),
          ),
        ],
      ),
      // Full-screen pages (no bottom bar). `/wine/new` must precede
      // `/wine/:id` so "new" isn't parsed as an id.
      GoRoute(
        path: Routes.newWine,
        builder: (_, state) =>
            WineEditScreen(initialName: state.uri.queryParameters['name']),
      ),
      GoRoute(
        path: '/wine/:id',
        builder: (_, state) =>
            WineDetailScreen(wineId: state.pathParameters['id']!),
        routes: [
          GoRoute(
            path: 'edit',
            builder: (_, state) =>
                WineEditScreen(wineId: state.pathParameters['id']),
          ),
          GoRoute(
            path: 'note/new',
            builder: (_, state) =>
                NoteEditScreen(wineId: state.pathParameters['id']),
          ),
        ],
      ),
      GoRoute(
        path: '/note/:noteId',
        builder: (_, state) =>
            NoteEditScreen(noteId: state.pathParameters['noteId']),
      ),
    ],
  );
});
