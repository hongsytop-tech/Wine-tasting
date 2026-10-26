import 'package:flutter_test/flutter_test.dart';
import 'package:wine_tasting/features/wines/models/wine_reference.dart';

void main() {
  test('canonical names accept English, accents and spacing variants', () {
    expect(WineReference.canonicalCountry('France'), '프랑스');
    expect(WineReference.canonicalCountry('  usa '), '미국');
    expect(WineReference.canonicalRegion('Rhone'), '론');
    expect(WineReference.canonicalRegion('Rhône'), '론');
    expect(WineReference.canonicalGrape('Shiraz'), '시라');
    expect(WineReference.canonicalGrape('cabernet-sauvignon'), '카베르네 소비뇽');
    expect(WineReference.canonicalGrape('Gruner Veltliner'), '그뤼너 벨트리너');
  });

  test('unknown values are kept as typed (trimmed)', () {
    expect(WineReference.canonicalCountry(' 몰타 '), '몰타');
    expect(WineReference.canonicalGrape('Saperavi'), 'Saperavi');
  });

  test('countryOfRegion', () {
    expect(WineReference.countryOfRegion('Barossa Valley'), '호주');
    expect(WineReference.countryOfRegion('보르도'), '프랑스');
    expect(WineReference.countryOfRegion('Somewhere'), isNull);
  });

  test('parseOrigin splits search-result origin text', () {
    var o = WineReference.parseOrigin('', 'Bordeaux, France');
    expect(o.country, '프랑스');
    expect(o.region, '보르도');
    o = WineReference.parseOrigin('', 'France');
    expect(o.country, '프랑스');
    expect(o.region, '');
    o = WineReference.parseOrigin('', 'Napa Valley');
    expect(o.country, '미국');
    expect(o.region, '나파 밸리');
    o = WineReference.parseOrigin('', 'Somewhere nice');
    expect(o.country, '');
    expect(o.region, 'Somewhere nice');
  });

  test('every region and grape label is unique', () {
    final regions = WineReference.allRegions.map((r) => r.label).toList();
    expect(regions.toSet().length, regions.length);
    final grapes = WineReference.grapes.map((g) => g.label).toList();
    expect(grapes.toSet().length, grapes.length);
  });

  test('no alias points to two different grapes', () {
    final seen = <String, String>{};
    for (final g in WineReference.grapes) {
      for (final k in [g.label, ...g.aliases].map(foldText)) {
        expect(seen[k] == null || seen[k] == g.label, isTrue,
            reason: '$k → ${seen[k]} / ${g.label}');
        seen[k] = g.label;
      }
    }
  });
}
