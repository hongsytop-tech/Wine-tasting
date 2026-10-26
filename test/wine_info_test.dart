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

  test('Vivino rating parsing', () {
    expect(WineInfo.parseVivino(''), (null, null));
    expect(WineInfo.parseVivino('3.8'), (3.8, null));
    expect(WineInfo.parseVivino('3,8'), (3.8, null));
    expect(WineInfo.parseVivino('4.25').$1, 4.3);
    expect(WineInfo.parseVivino('5.1').$2, isNotNull);
  });

  test('Vivino date is set only when the rating changes', () {
    final rated =
        w.copyWith(vivinoRating: 3.8, vivinoRatedAt: DateTime.utc(2026, 1, 1));
    // 같은 값이면 입력 날짜 유지
    final same = WineInfo.fromWine(rated).applyTo(rated);
    expect(same.vivinoRatedAt, DateTime.utc(2026, 1, 1));
    expect(WineInfo.fromWine(rated).differsFrom(rated), isFalse);
    // 값이 바뀌면 지금으로
    final changed =
        WineInfo.fromWine(rated).copyWith(vivinoRating: 3.9).applyTo(rated);
    expect(changed.vivinoRating, 3.9);
    expect(changed.vivinoRatedAt!.isAfter(DateTime.utc(2026, 1, 2)), isTrue);
    // 지우면 날짜도 지움
    final cleared =
        WineInfo.fromWine(rated).copyWith(vivinoRating: null).applyTo(rated);
    expect(cleared.vivinoRating, isNull);
    expect(cleared.vivinoRatedAt, isNull);
  });

  test('Vivino rating survives both JSON forms', () {
    final rated =
        w.copyWith(vivinoRating: 3.8, vivinoRatedAt: DateTime.utc(2026, 1, 1));
    expect(Wine.fromJson(rated.toJson()).vivinoRating, 3.8);
    expect(Wine.fromJson(rated.toRow('u')).vivinoRatedAt,
        DateTime.utc(2026, 1, 1).toLocal());
  });
}
