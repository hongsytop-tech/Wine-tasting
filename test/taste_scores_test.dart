import 'package:flutter_test/flutter_test.dart';
import 'package:wine_tasting/features/tasting/models/taste_attr.dart';
import 'package:wine_tasting/features/tasting/models/tasting_note.dart';
import 'package:wine_tasting/features/wines/models/wine_type.dart';

void main() {
  final t = DateTime.utc(2026, 10, 1);

  TastingNote note(
          {int? sweetness, int? acidity, int? tannin, double? rating}) =>
      TastingNote(
        id: 'n',
        wineId: 'w',
        tastedAt: t,
        sweetness: sweetness,
        acidity: acidity,
        tannin: tannin,
        rating: rating,
        createdAt: t,
        updatedAt: t,
      );

  test('legacy 1~5 data (no scale field) is converted to 0~10', () {
    final n = TastingNote.fromJson({
      'id': 'n',
      'wineId': 'w',
      'sweetness': 1,
      'acidity': 3,
      'tannin': 5,
      'body': 2,
      'finish': 4,
    });
    expect(n.sweetness, 0);
    expect(n.acidity, 5);
    expect(n.tannin, 10);
    expect(n.body, 3);
    expect(n.finish, 8);
  });

  test('legacy Supabase row (scale = 5) is converted', () {
    final n = TastingNote.fromJson(
        {'id': 'n', 'wine_id': 'w', 'scale': 5, 'acidity': 4});
    expect(n.acidity, 8);
  });

  test('0~10 data is kept as-is, 0 is a real value, and saved with scale 10',
      () {
    final n = note(sweetness: 0, acidity: 7, tannin: 10);
    final back = TastingNote.fromJson(n.toJson());
    expect(back.sweetness, 0);
    expect(back.acidity, 7);
    expect(back.tannin, 10);
    expect(n.toJson()['scale'], 10);
    expect(n.toRow('u')['scale'], 10);
  });

  test('out-of-range values are clamped', () {
    final n = TastingNote.fromJson(
        {'id': 'n', 'wineId': 'w', 'scale': 10, 'acidity': 14});
    expect(n.acidity, 10);
  });

  test('withAttr sets and clears a single score', () {
    final n = note(acidity: 5).withAttr(TasteAttr.tannin, 6);
    expect(TasteAttr.tannin.of(n), 6);
    expect(TasteAttr.acidity.of(n), 5);
    expect(TasteAttr.acidity.of(n.withAttr(TasteAttr.acidity, null)), isNull);
  });

  test('averageProfile averages only recorded values', () {
    final p = averageProfile([
      note(sweetness: 2, acidity: 7),
      note(sweetness: 3),
      note(tannin: 0),
    ]);
    expect(p[TasteAttr.sweetness], 2.5);
    expect(p[TasteAttr.acidity], 7);
    expect(p[TasteAttr.tannin], 0);
    expect(p.containsKey(TasteAttr.body), isFalse);
  });

  test('tannin input is hidden for white and sparkling only', () {
    expect(TasteAttr.tannin.appliesTo(WineType.white), isFalse);
    expect(TasteAttr.tannin.appliesTo(WineType.sparkling), isFalse);
    expect(TasteAttr.tannin.appliesTo(WineType.red), isTrue);
    expect(TasteAttr.acidity.appliesTo(WineType.white), isTrue);
  });

  test('scoreText', () {
    expect(scoreText(7), '7');
    expect(scoreText(7.0), '7');
    expect(scoreText(6.25), '6.3');
  });
}
