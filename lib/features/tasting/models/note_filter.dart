import '../../wines/models/wine.dart';
import '../../wines/models/wine_reference.dart';
import 'tasting_note.dart';

/// 노트를 모아 보고 거르는 기준 — 노트가 연결된 와인의 정보.
enum NoteFacet {
  country('국가'),
  region('지역'),
  producer('생산자'),
  vintage('빈티지'),
  grape('품종'),
  type('종류');

  const NoteFacet(this.label);
  final String label;

  /// 비어 있는 값을 모으는 항목 이름.
  static const missing = '미입력';

  /// 와인 1병이 이 기준에서 갖는 값들 (품종은 블렌드면 여러 개).
  List<String> valuesOf(Wine w) {
    String orMissing(String v) => v.trim().isEmpty ? missing : v.trim();
    switch (this) {
      case NoteFacet.country:
        return [orMissing(WineReference.canonicalCountry(w.country))];
      case NoteFacet.region:
        return [orMissing(WineReference.canonicalRegion(w.region))];
      case NoteFacet.producer:
        return [orMissing(w.producer)];
      case NoteFacet.vintage:
        return [w.vintageLabel];
      case NoteFacet.grape:
        if (w.grapes.isEmpty) return const [missing];
        return [for (final g in w.grapes) WineReference.canonicalGrape(g)];
      case NoteFacet.type:
        return [w.type.label];
    }
  }
}

class NoteFilter {
  const NoteFilter({
    this.query = '',
    this.selected = const {},
    this.groupBy,
  });

  /// 와인 이름·생산자·총평·키워드에서 찾을 글자.
  final String query;

  /// 기준별 선택값. 같은 기준 안에서는 OR, 기준끼리는 AND.
  final Map<NoteFacet, Set<String>> selected;

  /// 모아보기 기준 (null = 시음일순 목록).
  final NoteFacet? groupBy;

  bool get isActive =>
      query.trim().isNotEmpty || selected.values.any((s) => s.isNotEmpty);

  NoteFilter copyWith({
    String? query,
    Map<NoteFacet, Set<String>>? selected,
    Object? groupBy = _keep,
  }) =>
      NoteFilter(
        query: query ?? this.query,
        selected: selected ?? this.selected,
        groupBy:
            identical(groupBy, _keep) ? this.groupBy : groupBy as NoteFacet?,
      );

  static const _keep = Object();

  NoteFilter withSelection(NoteFacet f, Set<String> values) =>
      copyWith(selected: {...selected, f: values});

  NoteFilter cleared() => NoteFilter(groupBy: groupBy);

  bool matches(TastingNote n, Wine? w) {
    final q = foldText(query);
    if (q.isNotEmpty) {
      final hay = [
        w?.name ?? '',
        w?.producer ?? '',
        n.comment,
        n.keywords.join(' '),
      ].map(foldText);
      if (!hay.any((h) => h.contains(q))) return false;
    }
    for (final e in selected.entries) {
      if (e.value.isEmpty) continue;
      if (w == null) return false;
      if (!e.key.valuesOf(w).any(e.value.contains)) return false;
    }
    return true;
  }

  List<TastingNote> apply(
    List<TastingNote> notes,
    Map<String, Wine> winesById,
  ) =>
      [
        for (final n in notes)
          if (matches(n, winesById[n.wineId])) n
      ];
}

/// 기준별 값 → 노트 수 (선택 시트에 보여줄 목록).
Map<String, int> facetCounts(
  NoteFacet facet,
  List<TastingNote> notes,
  Map<String, Wine> winesById,
) {
  final out = <String, int>{};
  for (final n in notes) {
    final w = winesById[n.wineId];
    if (w == null) continue;
    for (final v in facet.valuesOf(w).toSet()) {
      out[v] = (out[v] ?? 0) + 1;
    }
  }
  return out;
}

/// 정렬된 값 목록: 빈티지는 최근 연도 먼저(NV 다음, 미입력 마지막),
/// 나머지는 노트 많은 순 → 이름순, "미입력"은 맨 끝.
List<String> sortedFacetValues(NoteFacet facet, Map<String, int> counts) {
  final keys = counts.keys.toList();
  int rank(String k) => k == NoteFacet.missing ? 2 : (k == 'NV' ? 1 : 0);
  keys.sort((a, b) {
    final r = rank(a).compareTo(rank(b));
    if (r != 0) return r;
    if (facet == NoteFacet.vintage) {
      return (int.tryParse(b) ?? 0).compareTo(int.tryParse(a) ?? 0);
    }
    final c = counts[b]!.compareTo(counts[a]!);
    return c != 0 ? c : a.compareTo(b);
  });
  return keys;
}

/// 모아보기: 기준값별 노트 목록 (블렌드 와인의 노트는 품종마다 들어간다).
List<MapEntry<String, List<TastingNote>>> groupNotes(
  NoteFacet facet,
  List<TastingNote> notes,
  Map<String, Wine> winesById,
) {
  final groups = <String, List<TastingNote>>{};
  for (final n in notes) {
    final w = winesById[n.wineId];
    if (w == null) continue;
    for (final v in facet.valuesOf(w).toSet()) {
      (groups[v] ??= []).add(n);
    }
  }
  final order = sortedFacetValues(
    facet,
    {for (final e in groups.entries) e.key: e.value.length},
  );
  return [for (final k in order) MapEntry(k, groups[k]!)];
}
