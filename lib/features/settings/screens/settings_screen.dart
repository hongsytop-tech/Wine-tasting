import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/supabase/supabase_service.dart';
import '../../auth/providers/auth_providers.dart';
import '../../tasting/providers/tasting_providers.dart';
import '../../update/update_section.dart';
import '../../wines/providers/wines_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _signOut(WidgetRef ref) async {
    // 로그아웃 시 이 기기의 캐시를 비운다 — 다음에 다른 계정으로 로그인했을 때
    // 이전 계정의 데이터가 병합(업로드)되는 것을 막기 위함. 데이터는 서버에 남아 있다.
    final store = ref.read(localStorageProvider);
    await store.remove(ref.read(winesRepoProvider).localKey);
    await store.remove(ref.read(tastingRepoProvider).localKey);
    await ref.read(authControllerProvider.notifier).signOut();
  }

  Future<void> _syncNow(BuildContext context, WidgetRef ref) async {
    await ref.read(winesProvider.notifier).sync();
    await ref.read(tastingNotesProvider.notifier).sync();
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('동기화했습니다')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final wineCount = ref.watch(visibleWinesProvider).length;
    final noteCount = ref.watch(visibleNotesProvider).length;

    return Scaffold(
      appBar: AppBar(title: const Text('마이')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.account_circle),
            title: Text(user?.email ?? '로그인 안 함 (이 기기에만 저장)'),
            subtitle: Text('와인 $wineCount개 · 노트 $noteCount개'),
          ),
          if (SupabaseService.isSignedIn) ...[
            ListTile(
              leading: const Icon(Icons.sync),
              title: const Text('지금 동기화'),
              onTap: () => _syncNow(context, ref),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('로그아웃'),
              onTap: () => _signOut(ref),
            ),
          ],
          const Divider(),
          if (kIsWeb) const UpdateSection(),
          const AboutListTile(
            icon: Icon(Icons.info_outline),
            applicationName: '와인노트',
            aboutBoxChildren: [
              Text(
                '와인 검색 데이터: Open Food Facts (Open Database License).\n'
                '내 평점·테이스팅 노트는 내 계정에만 저장됩니다.',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
