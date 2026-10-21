import 'package:flutter_test/flutter_test.dart';
import 'package:wine_tasting/core/sync/synced_repo.dart';

class _Item {
  const _Item(this.id, this.updatedAt, [this.tag = '']);
  final String id;
  final DateTime updatedAt;
  final String tag;
}

MergeResult<_Item> _merge(List<_Item> local, List<_Item> remote) => mergeById(
      local,
      remote,
      idOf: (e) => e.id,
      updatedAtOf: (e) => e.updatedAt,
    );

void main() {
  final t0 = DateTime(2026, 1, 1);
  final t1 = DateTime(2026, 1, 2);

  test('local-only items are kept and pushed', () {
    final r = _merge([_Item('a', t0)], []);
    expect(r.merged.map((e) => e.id), ['a']);
    expect(r.toPush.map((e) => e.id), ['a']);
  });

  test('remote-only items are pulled, nothing pushed', () {
    final r = _merge([], [_Item('a', t0)]);
    expect(r.merged.map((e) => e.id), ['a']);
    expect(r.toPush, isEmpty);
  });

  test('newer local wins and is pushed', () {
    final r = _merge([_Item('a', t1, 'local')], [_Item('a', t0, 'remote')]);
    expect(r.merged.single.tag, 'local');
    expect(r.toPush.single.tag, 'local');
  });

  test('newer remote wins and is not pushed', () {
    final r = _merge([_Item('a', t0, 'local')], [_Item('a', t1, 'remote')]);
    expect(r.merged.single.tag, 'remote');
    expect(r.toPush, isEmpty);
  });

  test('equal timestamps keep remote', () {
    final r = _merge([_Item('a', t0, 'local')], [_Item('a', t0, 'remote')]);
    expect(r.merged.single.tag, 'remote');
    expect(r.toPush, isEmpty);
  });
}
