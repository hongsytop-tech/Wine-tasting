import '../storage/local_storage.dart';
import '../supabase/supabase_service.dart';

/// Result of reconciling the local cache with the server rows.
class MergeResult<T> {
  const MergeResult({required this.merged, required this.toPush});

  /// Union of both sides, newest `updatedAt` winning per id.
  final List<T> merged;

  /// Local items the server doesn't have yet (or has an older copy of).
  final List<T> toPush;
}

/// Row-level persistence: local `List<String>` cache + one Supabase row per
/// item (`(user_id, id)` primary key, RLS = own rows only).
///
/// Offline-first: writes land locally first and are upserted best-effort.
/// A write that failed to reach the server (offline) is retried on the next
/// [SyncedRepo.merge] because its local `updatedAt` is newer than the server
/// copy. Deletes are soft (`deleted_at`) so they propagate instead of being
/// resurrected by another device's cache.
class SyncedRepo<T> {
  SyncedRepo({
    required LocalStorage local,
    required this.localKey,
    required this.table,
    required this.fromJson,
    required this.toJson,
    required this.toRow,
    required this.idOf,
    required this.updatedAtOf,
  }) : _local = local;

  final LocalStorage _local;
  final String localKey;
  final String table;
  final T Function(Map<String, dynamic>) fromJson;
  final Map<String, dynamic> Function(T) toJson;
  final Map<String, dynamic> Function(T, String userId) toRow;
  final String Function(T) idOf;
  final DateTime Function(T) updatedAtOf;

  List<T> loadLocal() => _local.getJsonList(localKey).map(fromJson).toList();

  Future<void> saveLocal(List<T> items) =>
      _local.setJsonList(localKey, items.map(toJson).toList());

  /// Returns null when signed-out.
  Future<List<T>?> pull() async {
    final user = SupabaseService.currentUser;
    if (user == null) return null;
    final rows = await SupabaseService.client
        .from(table)
        .select()
        .eq('user_id', user.id);
    return (rows as List)
        .map((e) => fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> upsert(List<T> items) async {
    final user = SupabaseService.currentUser;
    if (user == null || items.isEmpty) return;
    await SupabaseService.client.from(table).upsert(
      [for (final e in items) toRow(e, user.id)],
      onConflict: 'user_id,id',
    );
  }

  MergeResult<T> merge(List<T> local, List<T> remote) =>
      mergeById(local, remote, idOf: idOf, updatedAtOf: updatedAtOf);
}

/// Pure merge so it can be unit-tested without a backend.
MergeResult<T> mergeById<T>(
  List<T> local,
  List<T> remote, {
  required String Function(T) idOf,
  required DateTime Function(T) updatedAtOf,
}) {
  final byId = <String, T>{for (final r in remote) idOf(r): r};
  final toPush = <T>[];
  for (final l in local) {
    final r = byId[idOf(l)];
    if (r == null || updatedAtOf(l).isAfter(updatedAtOf(r))) {
      byId[idOf(l)] = l;
      toPush.add(l);
    }
  }
  return MergeResult(merged: byId.values.toList(), toPush: toPush);
}
