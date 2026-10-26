import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/supabase/supabase_service.dart';
import '../../../core/sync/synced_repo.dart';
import '../../auth/providers/auth_providers.dart';
import '../../search/models/wine_search_result.dart';
import '../models/wine.dart';
import '../models/wine_reference.dart';

const _uuid = Uuid();

final winesRepoProvider = Provider<SyncedRepo<Wine>>(
  (ref) => SyncedRepo<Wine>(
    local: ref.watch(localStorageProvider),
    localKey: 'wines_v1',
    table: 'wines',
    fromJson: Wine.fromJson,
    toJson: (w) => w.toJson(),
    toRow: (w, uid) => w.toRow(uid),
    idOf: (w) => w.id,
    updatedAtOf: (w) => w.updatedAt,
  ),
);

/// 전체 와인 (soft-delete 포함). 로그인 사용자가 바뀌면 다시 만들어져
/// 서버와 재동기화된다.
final winesProvider = StateNotifierProvider<WinesNotifier, List<Wine>>((ref) {
  ref.watch(currentUserProvider.select((u) => u?.id));
  return WinesNotifier(ref.watch(winesRepoProvider));
});

/// 화면에 보일 와인 (삭제 제외), 최근 수정순.
final visibleWinesProvider = Provider<List<Wine>>((ref) {
  final list = ref.watch(winesProvider).where((w) => !w.isDeleted).toList()
    ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  return list;
});

final wineByIdProvider = Provider.family<Wine?, String>((ref, id) {
  for (final w in ref.watch(winesProvider)) {
    if (w.id == id && !w.isDeleted) return w;
  }
  return null;
});

/// 내 와인에 있는 생산자 목록 (자동완성용, 가나다/ABC 순).
final knownProducersProvider = Provider<List<String>>((ref) {
  final set = <String>{
    for (final w in ref.watch(visibleWinesProvider))
      if (w.producer.trim().isNotEmpty) w.producer.trim(),
  };
  return set.toList()..sort();
});

class WinesNotifier extends StateNotifier<List<Wine>> {
  WinesNotifier(this._repo) : super(const []) {
    _init();
  }

  final SyncedRepo<Wine> _repo;

  Future<void> _init() async {
    state = _repo.loadLocal();
    await sync();
  }

  /// 로컬 ↔ 서버 병합 (최신 updatedAt 우선). 로그아웃 상태면 no-op.
  /// 다른 계정의 캐시가 남아 있으면 병합하지 않고 버린다.
  /// 반환: 실패 사유 (성공·로그아웃 상태면 null).
  Future<String?> sync() async {
    final user = SupabaseService.currentUser;
    if (user == null) return null;
    if (_repo.isForeignCache(user.id)) {
      state = const [];
      await _repo.clearLocal();
    }
    try {
      final merged = await _repo.pullAndMerge(state);
      if (merged != null) state = merged;
      return null;
    } catch (e) {
      // keep local on sync failure; retried on next launch/login
      return '$e';
    }
  }

  Future<void> _put(Wine w) async {
    final exists = state.any((e) => e.id == w.id);
    state =
        exists ? [for (final e in state) e.id == w.id ? w : e] : [...state, w];
    await _repo.saveLocal(state);
    try {
      await _repo.upsert([w]);
    } catch (_) {}
  }

  Wine? _find(String id) {
    for (final e in state) {
      if (e.id == id) return e;
    }
    return null;
  }

  /// 같은 소스의 같은 항목이 이미 셀러에 있으면 그걸 돌려준다.
  Wine? findBySource(String source, String sourceId) {
    if (sourceId.isEmpty) return null;
    for (final e in state) {
      if (!e.isDeleted && e.source == source && e.sourceId == sourceId) {
        return e;
      }
    }
    return null;
  }

  Future<Wine> addFromSearch(
    WineSearchResult r, {
    bool favorite = false,
  }) async {
    final existing = findBySource(r.source, r.sourceId);
    if (existing != null) {
      if (favorite && !existing.isFavorite) {
        await toggleFavorite(existing.id);
        return _find(existing.id)!;
      }
      return existing;
    }
    final now = DateTime.now();
    final origin = WineReference.parseOrigin(r.country, r.region);
    final w = Wine(
      id: _uuid.v4(),
      name: r.name,
      producer: r.producer,
      vintage: r.vintage,
      type: r.type,
      country: origin.country,
      region: origin.region,
      grapes: [for (final g in r.grapes) WineReference.canonicalGrape(g)],
      imageUrl: r.imageUrl,
      source: r.source,
      sourceId: r.sourceId,
      sourceUrl: r.sourceUrl,
      barcode: r.barcode,
      isFavorite: favorite,
      createdAt: now,
      updatedAt: now,
    );
    await _put(w);
    return w;
  }

  /// 직접 입력한 새 와인 (id 는 여기서 발급).
  Future<Wine> addManual(Wine draft) async {
    final now = DateTime.now();
    final w = Wine(
      id: _uuid.v4(),
      name: draft.name,
      producer: draft.producer,
      vintage: draft.vintage,
      type: draft.type,
      country: draft.country,
      region: draft.region,
      grapes: draft.grapes,
      grapePercents: draft.grapePercents,
      imageUrl: draft.imageUrl,
      isFavorite: draft.isFavorite,
      myRating: draft.myRating,
      memo: draft.memo,
      createdAt: now,
      updatedAt: now,
    );
    await _put(w);
    return w;
  }

  Future<void> update(Wine w) => _put(w.copyWith(updatedAt: DateTime.now()));

  Future<void> toggleFavorite(String id) async {
    final w = _find(id);
    if (w == null) return;
    await update(w.copyWith(isFavorite: !w.isFavorite));
  }

  /// [rating] null = 평점 지우기.
  Future<void> setRating(String id, double? rating) async {
    final w = _find(id);
    if (w == null) return;
    await update(w.copyWith(myRating: rating));
  }

  Future<void> delete(String id) async {
    final w = _find(id);
    if (w == null) return;
    await update(w.copyWith(deletedAt: DateTime.now()));
  }
}
