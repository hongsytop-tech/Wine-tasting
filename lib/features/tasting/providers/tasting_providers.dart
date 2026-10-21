import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/supabase/supabase_service.dart';
import '../../../core/sync/synced_repo.dart';
import '../../auth/providers/auth_providers.dart';
import '../models/tasting_note.dart';

const _uuid = Uuid();

final tastingRepoProvider = Provider<SyncedRepo<TastingNote>>(
  (ref) => SyncedRepo<TastingNote>(
    local: ref.watch(localStorageProvider),
    localKey: 'tasting_notes_v1',
    table: 'tasting_notes',
    fromJson: TastingNote.fromJson,
    toJson: (n) => n.toJson(),
    toRow: (n, uid) => n.toRow(uid),
    idOf: (n) => n.id,
    updatedAtOf: (n) => n.updatedAt,
  ),
);

/// 전체 노트 (soft-delete 포함).
final tastingNotesProvider =
    StateNotifierProvider<TastingNotesNotifier, List<TastingNote>>((ref) {
  ref.watch(currentUserProvider.select((u) => u?.id));
  return TastingNotesNotifier(ref.watch(tastingRepoProvider));
});

/// 화면용 노트 (삭제 제외), 시음일 최신순.
final visibleNotesProvider = Provider<List<TastingNote>>((ref) {
  final list = ref
      .watch(tastingNotesProvider)
      .where((n) => !n.isDeleted)
      .toList()
    ..sort((a, b) => b.tastedAt.compareTo(a.tastedAt));
  return list;
});

final notesForWineProvider =
    Provider.family<List<TastingNote>, String>((ref, wineId) {
  return ref
      .watch(visibleNotesProvider)
      .where((n) => n.wineId == wineId)
      .toList();
});

class TastingNotesNotifier extends StateNotifier<List<TastingNote>> {
  TastingNotesNotifier(this._repo) : super(const []) {
    _init();
  }

  final SyncedRepo<TastingNote> _repo;

  Future<void> _init() async {
    state = _repo.loadLocal();
    await sync();
  }

  Future<void> sync() async {
    if (!SupabaseService.isSignedIn) return;
    try {
      final remote = await _repo.pull();
      if (remote == null) return;
      final r = _repo.merge(state, remote);
      state = r.merged;
      await _repo.saveLocal(state);
      await _repo.upsert(r.toPush);
    } catch (_) {
      // keep local on sync failure; retried on next launch/login
    }
  }

  Future<void> _putAll(List<TastingNote> changed) async {
    if (changed.isEmpty) return;
    final byId = {for (final n in changed) n.id: n};
    final next = [for (final e in state) byId.remove(e.id) ?? e];
    state = [...next, ...byId.values];
    await _repo.saveLocal(state);
    try {
      await _repo.upsert(changed);
    } catch (_) {}
  }

  TastingNote newDraft(String wineId) =>
      TastingNote.create(id: _uuid.v4(), wineId: wineId);

  /// 새 노트 추가 또는 기존 노트 수정.
  Future<void> save(TastingNote n) =>
      _putAll([n.copyWith(updatedAt: DateTime.now())]);

  Future<void> delete(String id) async {
    final now = DateTime.now();
    await _putAll([
      for (final n in state)
        if (n.id == id) n.copyWith(deletedAt: now, updatedAt: now),
    ]);
  }

  /// 와인을 지울 때 그 와인의 노트도 함께 지운다.
  Future<void> deleteForWine(String wineId) async {
    final now = DateTime.now();
    await _putAll([
      for (final n in state)
        if (n.wineId == wineId && !n.isDeleted)
          n.copyWith(deletedAt: now, updatedAt: now),
    ]);
  }
}
