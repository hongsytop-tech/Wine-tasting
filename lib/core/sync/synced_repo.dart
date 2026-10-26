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
///
/// The local cache remembers which account it was last synced with
/// ([ownerKey]). When a *different* account signs in on the same browser, the
/// cache is discarded instead of being merged — otherwise the previous user's
/// wines would be uploaded into the new user's account. A cache with no owner
/// (made before any sign-in) is merged into the first account that signs in.
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

  String get ownerKey => '${localKey}_owner';

  List<T> loadLocal() => _local.getJsonList(localKey).map(fromJson).toList();

  /// True when the local cache belongs to an account other than [userId].
  bool isForeignCache(String userId) {
    final owner = _local.getString(ownerKey);
    return owner != null && owner != userId;
  }

  /// Drop the local cache and its owner (sign-out, or another account's cache).
  Future<void> clearLocal() async {
    await _local.remove(localKey);
    await _local.remove(ownerKey);
  }

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

  /// Pull → merge with [local] → save → push local-newer items, then mark the
  /// cache as owned by the signed-in user. Returns the merged list, or null when
  /// signed-out. Callers must drop a foreign cache first ([isForeignCache]).
  Future<List<T>?> pullAndMerge(List<T> local) async {
    final user = SupabaseService.currentUser;
    if (user == null) return null;
    final remote = await pull();
    if (remote == null) return null;
    final r = merge(local, remote);
    await saveLocal(r.merged);
    await upsert(r.toPush);
    await _local.setString(ownerKey, user.id);
    return r.merged;
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
