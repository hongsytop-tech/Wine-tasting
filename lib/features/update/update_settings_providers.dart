import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/core_providers.dart';
import '../../core/storage/local_storage.dart';

/// Whether new builds auto-reload. Defaults to ON; persisted locally.
final autoUpdateProvider =
    StateNotifierProvider<AutoUpdateNotifier, bool>((ref) {
  return AutoUpdateNotifier(ref.watch(localStorageProvider));
});

class AutoUpdateNotifier extends StateNotifier<bool> {
  AutoUpdateNotifier(this._store) : super(_store.getString(_key) != 'false');

  // 같은 도메인(hongsytop-tech.github.io)의 다른 앱(Youtube-Filtering)과 저장소를
  // 공유하므로 앱 전용 접두사를 붙인다.
  static const _key = 'wine_auto_update_enabled';
  final LocalStorage _store;

  void set(bool enabled) {
    state = enabled;
    _store.setString(_key, enabled ? 'true' : 'false');
  }
}
