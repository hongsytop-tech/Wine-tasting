import 'package:flutter_test/flutter_test.dart';
import 'package:wine_tasting/features/tasting/models/taste_attr.dart';
import 'package:wine_tasting/features/tasting/models/tasting_note.dart';
import 'package:wine_tasting/features/tasting/models/tasting_vocab.dart';
import 'package:wine_tasting/features/tasting/services/tasting_suggest_service.dart';

void main() {
  final t = DateTime.utc(2026, 10, 1);
  TastingNote note(
          {List<String> aromas = const [], List<String> flavors = const []}) =>
      TastingNote(
          id: 'n',
          wineId: 'w',
          tastedAt: t,
          aromas: aromas,
          flavors: flavors,
          createdAt: t,
          updatedAt: t);

  test('keywords merge old aromas and flavors without duplicates', () {
    final n = note(aromas: ['체리', '후추'], flavors: ['후추', '바닐라']);
    expect(n.keywords, ['체리', '후추', '바닐라']);
    final m = n.withKeywords(['체리', '오크']);
    expect(m.aromas, ['체리', '오크']);
    expect(m.flavors, isEmpty);
    expect(m.keywords, ['체리', '오크']);
  });

  test('vocabulary list is flat and unique', () {
    final v = TastingVocab.allDescriptors;
    expect(v.toSet().length, v.length);
    expect(v, contains('후추'));
  });

  test('AI suggestion JSON is parsed and clamped', () {
    final s = TastingSuggestion.fromJson({
      'scores': {
        'tannin': {'value': 7, 'evidence': '평균 이상'},
        'body': {'value': 12, 'evidence': '끈적'},
        'unknown': {'value': 3},
      },
      'keywords': ['후추', '바닐라'],
      'color': '루비',
    });
    expect(s.scores[TasteAttr.tannin]!.value, 7);
    expect(s.scores[TasteAttr.tannin]!.evidence, '평균 이상');
    expect(s.scores[TasteAttr.body]!.value, 10);
    expect(s.scores.length, 2);
    expect(s.keywords, ['후추', '바닐라']);
    expect(s.color, '루비');
    expect(TastingSuggestion.fromJson({}).isEmpty, isTrue);
  });
}
