import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wine_tasting/core/storage/local_storage.dart';
import 'package:wine_tasting/core/sync/synced_repo.dart';

void main() {
  late LocalStorage store;
  late SyncedRepo<Map<String, dynamic>> repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = await LocalStorage.getInstance();
    repo = SyncedRepo<Map<String, dynamic>>(
      local: store,
      localKey: 'wines_v1',
      table: 'wines',
      fromJson: (j) => j,
      toJson: (e) => e,
      toRow: (e, uid) => {...e, 'user_id': uid},
      idOf: (e) => '${e['id']}',
      updatedAtOf: (e) => DateTime.parse('${e['updatedAt']}'),
    );
  });

  test('cache without owner (made before sign-in) is not foreign', () async {
    await repo.saveLocal([
      {'id': 'a', 'updatedAt': '2026-10-01T00:00:00Z'},
    ]);
    expect(repo.isForeignCache('user-a'), isFalse);
  });

  test("another account's cache is foreign, own cache is not", () async {
    await store.setString(repo.ownerKey, 'user-a');
    expect(repo.isForeignCache('user-a'), isFalse);
    expect(repo.isForeignCache('user-b'), isTrue);
  });

  test('clearLocal removes the data and the owner', () async {
    await repo.saveLocal([
      {'id': 'a', 'updatedAt': '2026-10-01T00:00:00Z'},
    ]);
    await store.setString(repo.ownerKey, 'user-a');
    await repo.clearLocal();
    expect(repo.loadLocal(), isEmpty);
    expect(repo.isForeignCache('user-b'), isFalse);
  });
}
