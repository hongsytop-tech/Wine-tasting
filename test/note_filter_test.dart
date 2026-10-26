import 'package:flutter_test/flutter_test.dart';
import 'package:wine_tasting/features/tasting/models/note_filter.dart';
import 'package:wine_tasting/features/tasting/models/tasting_note.dart';
import 'package:wine_tasting/features/wines/models/wine.dart';
import 'package:wine_tasting/features/wines/models/wine_type.dart';

void main() {
  final t = DateTime.utc(2026, 10, 1);
  Wine wine(String id,
          {String country = '',
          String producer = '',
          int? vintage,
          List<String> grapes = const [],
          WineType type = WineType.red}) =>
      Wine(
          id: id,
          name: 'W$id',
          producer: producer,
          country: country,
          vintage: vintage,
          grapes: grapes,
          type: type,
          createdAt: t,
          updatedAt: t);
  TastingNote note(String id, String wineId, {String comment = ''}) =>
      TastingNote(
          id: id,
          wineId: wineId,
          tastedAt: t,
          comment: comment,
          createdAt: t,
          updatedAt: t);

  final wines = {
    'a': wine('a',
        country: '프랑스',
        producer: 'Château A',
        vintage: 2015,
        grapes: ['카베르네 소비뇽', '메를로']),
    'b': wine('b',
        country: 'France', producer: 'B', vintage: 2019, grapes: ['메를로']),
    'c':
        wine('c', country: '', producer: 'C', grapes: [], type: WineType.white),
  };
  final notes = [
    note('1', 'a', comment: '타닌이 부드럽다'),
    note('2', 'b'),
    note('3', 'c'),
    note('4', 'a'),
  ];

  test('facet values normalize names and mark missing ones', () {
    expect(NoteFacet.country.valuesOf(wines['b']!), ['프랑스']);
    expect(NoteFacet.country.valuesOf(wines['c']!), [NoteFacet.missing]);
    expect(NoteFacet.vintage.valuesOf(wines['c']!), ['NV']);
    expect(NoteFacet.grape.valuesOf(wines['a']!), ['카베르네 소비뇽', '메를로']);
  });

  test('OR within a facet, AND across facets', () {
    var f = const NoteFilter().withSelection(NoteFacet.country, {'프랑스'});
    expect(f.apply(notes, wines).map((n) => n.id), ['1', '2', '4']);
    f = f.withSelection(NoteFacet.grape, {'카베르네 소비뇽'});
    expect(f.apply(notes, wines).map((n) => n.id), ['1', '4']);
    f = const NoteFilter().withSelection(NoteFacet.vintage, {'2015', '2019'});
    expect(f.apply(notes, wines).map((n) => n.id), ['1', '2', '4']);
  });

  test('query searches wine name, producer and comment', () {
    expect(const NoteFilter(query: 'chateau a').apply(notes, wines).length, 2);
    expect(const NoteFilter(query: '부드럽').apply(notes, wines).single.id, '1');
  });

  test('counts and grouping (blend counted under each grape)', () {
    final counts = facetCounts(NoteFacet.grape, notes, wines);
    expect(counts, {'카베르네 소비뇽': 2, '메를로': 3, NoteFacet.missing: 1});
    final groups = groupNotes(NoteFacet.grape, notes, wines);
    expect(groups.map((g) => g.key), ['메를로', '카베르네 소비뇽', NoteFacet.missing]);
  });

  test('vintage groups: newest first, NV after years', () {
    final order = sortedFacetValues(
      NoteFacet.vintage,
      facetCounts(NoteFacet.vintage, notes, wines),
    );
    expect(order, ['2019', '2015', 'NV']);
  });

  test('cleared keeps the grouping', () {
    final f = const NoteFilter(query: 'x', groupBy: NoteFacet.country)
        .withSelection(NoteFacet.type, {'레드'});
    final c = f.cleared();
    expect(c.isActive, isFalse);
    expect(c.groupBy, NoteFacet.country);
  });
}
