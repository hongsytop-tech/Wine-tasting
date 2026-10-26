import 'package:flutter_test/flutter_test.dart';
import 'package:wine_tasting/features/tasting/models/tasting_note.dart';
import 'package:wine_tasting/features/wines/models/wine.dart';
import 'package:wine_tasting/features/wines/models/wine_type.dart';

void main() {
  final t = DateTime.utc(2026, 10, 1, 12);

  Wine wine() => Wine(
        id: 'w1',
        name: 'Château Test',
        producer: 'Test Estate',
        vintage: 2019,
        type: WineType.red,
        country: 'France',
        region: 'Bordeaux',
        grapes: const ['Merlot', 'Cabernet Franc'],
        source: 'openfoodfacts',
        sourceId: '3000000000000',
        isFavorite: true,
        myRating: 4.5,
        createdAt: t,
        updatedAt: t,
      );

  test('Wine survives local JSON round-trip', () {
    final back = Wine.fromJson(wine().toJson());
    expect(back.toJson(), wine().toJson());
  });

  test('Wine parses a snake_case Supabase row', () {
    final back = Wine.fromJson(wine().toRow('u1'));
    expect(back.toJson(), wine().toJson());
  });

  test('Wine.copyWith can clear nullable fields', () {
    final w = wine().copyWith(vintage: null, myRating: null);
    expect(w.vintage, isNull);
    expect(w.vintageLabel, 'NV');
    expect(w.myRating, isNull);
    expect(wine().copyWith().myRating, 4.5);
  });

  test('unknown wine type falls back to other', () {
    expect(WineType.parse('beer'), WineType.other);
    expect(WineType.parse(null), WineType.other);
  });

  test('TastingNote round-trips and clears scales', () {
    final n = TastingNote(
      id: 'n1',
      wineId: 'w1',
      tastedAt: t,
      rating: 4,
      acidity: 4,
      tannin: 3,
      aromas: const ['체리', '바닐라'],
      price: 45000,
      comment: '좋음',
      createdAt: t,
      updatedAt: t,
    );
    expect(TastingNote.fromJson(n.toJson()).toJson(), n.toJson());
    expect(TastingNote.fromJson(n.toRow('u1')).toJson(), n.toJson());
    final cleared = n.copyWith(tannin: null, rating: null);
    expect(cleared.tannin, isNull);
    expect(cleared.rating, isNull);
    expect(cleared.acidity, 4);
  });

  test('blend percents and label photos survive both JSON forms', () {
    final w = wine().copyWith(
      grapes: ['메를로', '카베르네 프랑'],
      grapePercents: {'메를로': 70, '카베르네 프랑': 30},
    );
    expect(Wine.fromJson(w.toJson()).grapePercents, {'메를로': 70, '카베르네 프랑': 30});
    expect(
        Wine.fromJson(w.toRow('u1')).grapePercents, {'메를로': 70, '카베르네 프랑': 30});
    expect(w.isBlend, isTrue);
    expect(w.grapesLabel, '메를로 70% · 카베르네 프랑 30%');

    final n = TastingNote(
      id: 'n1',
      wineId: 'w1',
      tastedAt: t,
      photos: const ['u1/n1/a.jpg'],
      createdAt: t,
      updatedAt: t,
    );
    expect(TastingNote.fromJson(n.toRow('u1')).photos, ['u1/n1/a.jpg']);
    expect(n.copyWith(wineId: 'w2').wineId, 'w2');
  });

  test('older data without the new fields still loads', () {
    final w = Wine.fromJson({
      'id': 'x',
      'name': 'Old',
      'grapes': ['메를로']
    });
    expect(w.grapePercents, isEmpty);
    expect(w.grapesLabel, '메를로');
    final n = TastingNote.fromJson({'id': 'n', 'wineId': 'x'});
    expect(n.photos, isEmpty);
  });
}
