import 'package:flutter_test/flutter_test.dart';
import 'package:wine_tasting/features/wines/models/wine.dart';
import 'package:wine_tasting/features/wines/widgets/wine_info_form.dart';

void main() {
  final t = DateTime.utc(2026, 10, 1);
  final w = Wine(
    id: 'w',
    name: 'A',
    producer: 'P',
    vintage: 2018,
    country: '프랑스',
    grapes: const ['메를로'],
    memo: '셀러 2층',
    createdAt: t,
    updatedAt: t,
  );

  test('unchanged info is not a difference', () {
    expect(WineInfo.fromWine(w).differsFrom(w), isFalse);
  });

  test('changing grapes or percents is a difference; other fields kept', () {
    final i = WineInfo.fromWine(w).copyWith(
      grapes: ['메를로', '카베르네 프랑'],
      grapePercents: {'메를로': 60},
    );
    expect(i.differsFrom(w), isTrue);
    final applied = i.applyTo(w);
    expect(applied.memo, '셀러 2층');
    expect(applied.grapePercents, {'메를로': 60});
  });

  test('vintage validation', () {
    expect(WineInfo.vintageError(''), isNull);
    expect(WineInfo.vintageError('2019'), isNull);
    expect(WineInfo.vintageError('1700'), isNotNull);
    expect(WineInfo.vintageError('${DateTime.now().year + 1}'), isNotNull);
  });
}
