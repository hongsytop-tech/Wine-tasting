import 'package:flutter_test/flutter_test.dart';
import 'package:wine_tasting/features/wines/models/custom_refs.dart';
import 'package:wine_tasting/features/wines/models/wine.dart';

void main() {
  final t = DateTime.utc(2026, 10, 1);
  Wine wine(String id,
          {String country = '',
          String region = '',
          List<String> grapes = const []}) =>
      Wine(
          id: id,
          name: id,
          country: country,
          region: region,
          grapes: grapes,
          createdAt: t,
          updatedAt: t);

  final refs = CustomRefs.fromWines([
    wine('a', country: '미국', region: 'California', grapes: ['쁘띠 시라']),
    wine('b', country: 'USA', region: 'Lodi', grapes: ['Saperavi']),
    wine('c', country: '몰타', region: 'Gozo'),
    wine('d', region: 'Somewhere'),
  ]);

  test('only values missing from the reference lists are collected', () {
    expect(refs.countries, ['몰타']); // 미국/USA 는 기준 목록에 있음
    expect(refs.grapes, ['Saperavi']); // 쁘띠 시라는 기준 목록에 있음
    // Lodi 는 기준 목록(로다이)에 있으므로 제외
    expect(refs.regionsByCountry['미국'], ['California']);
  });

  test('regions are offered for the country they were entered with', () {
    expect(refs.regionItemsFor('미국').map((e) => e.label),
        ['California', 'Somewhere']);
    expect(refs.regionItemsFor('United States').map((e) => e.label),
        ['California', 'Somewhere']);
    expect(
        refs.regionItemsFor('몰타').map((e) => e.label), ['Gozo', 'Somewhere']);
    expect(refs.regionItemsFor('').length, 3);
  });

  test('countryOfRegion fills the country from earlier input', () {
    expect(refs.countryOfRegion('California'), '미국');
    expect(refs.countryOfRegion('Somewhere'), isNull);
  });

  test('items are marked as custom', () {
    expect(refs.countryItems.single, isA<CustomRefItem>());
  });
}
