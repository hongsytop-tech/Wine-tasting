import 'wine.dart';
import 'wine_reference.dart';

/// 사용자가 직접 입력해 기준 목록([WineReference])에 없는 값.
/// 선택 시트에서 기준 항목과 구분해 보여주기 위한 표식.
class CustomRefItem extends RefItem {
  const CustomRefItem(super.label);
}

/// 내 와인들에 쓰인 값 중 기준 목록에 없는 국가·지역·품종.
///
/// 별도 저장 없이 내 와인에서 매번 계산한다 — 그래서 기기 간 동기화도 와인과
/// 함께 되고, 그 값을 쓰는 와인이 모두 지워지면 목록에서도 빠진다.
class CustomRefs {
  const CustomRefs({
    this.countries = const [],
    this.regionsByCountry = const {},
    this.grapes = const [],
  });

  final List<String> countries;

  /// 국가(정규화된 라벨) → 그 국가로 입력된 지역. 국가 없이 입력된 지역은 키 ''.
  final Map<String, List<String>> regionsByCountry;
  final List<String> grapes;

  factory CustomRefs.fromWines(Iterable<Wine> wines) {
    bool known(List<RefItem> items, String v) =>
        items.any((i) => i.isExactly(v));

    final countries = <String>{};
    final regions = <String, Set<String>>{};
    final grapes = <String>{};
    for (final w in wines) {
      final c = WineReference.canonicalCountry(w.country);
      if (c.isNotEmpty && !known(WineReference.countries, c)) countries.add(c);
      final r = WineReference.canonicalRegion(w.region);
      if (r.isNotEmpty && !known(WineReference.allRegions, r)) {
        (regions[c] ??= {}).add(r);
      }
      for (final g in w.grapes) {
        final cg = WineReference.canonicalGrape(g);
        if (cg.isNotEmpty && !known(WineReference.grapes, cg)) grapes.add(cg);
      }
    }
    List<String> sorted(Iterable<String> s) => s.toList()..sort();
    return CustomRefs(
      countries: sorted(countries),
      regionsByCountry: {
        for (final e in regions.entries) e.key: sorted(e.value),
      },
      grapes: sorted(grapes),
    );
  }

  List<RefItem> get countryItems =>
      [for (final c in countries) CustomRefItem(c)];

  List<RefItem> get grapeItems => [for (final g in grapes) CustomRefItem(g)];

  /// [country] 로 입력했던 지역 (+ 국가 없이 입력한 지역). 국가가 비면 전부.
  List<RefItem> regionItemsFor(String country) {
    final c = WineReference.canonicalCountry(country);
    final names = c.isEmpty
        ? regionsByCountry.values.expand((e) => e).toSet()
        : {...?regionsByCountry[c], ...?regionsByCountry['']};
    return [for (final r in names.toList()..sort()) CustomRefItem(r)];
  }

  /// 직접 입력한 지역이 어느 국가로 입력됐었는지 (국가 자동 채우기용).
  String? countryOfRegion(String region) {
    for (final e in regionsByCountry.entries) {
      if (e.key.isNotEmpty && e.value.contains(region.trim())) return e.key;
    }
    return null;
  }
}
