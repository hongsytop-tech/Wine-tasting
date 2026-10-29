import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wine_tasting/features/tasting/models/taste_attr.dart';
import 'package:wine_tasting/features/tasting/models/tasting_note.dart';
import 'package:wine_tasting/features/tasting/services/tasting_suggest_service.dart';
import 'package:wine_tasting/features/tasting/widgets/suggestion_sheet.dart';

void main() {
  final t = DateTime.utc(2026, 10, 1);

  testWidgets(
      'existing values are unchecked by default; apply uses the selection',
      (tester) async {
    // 기존 노트: 산미 4 가 이미 있고, 키워드 "후추" 가 이미 있음.
    final note = TastingNote(
      id: 'n',
      wineId: 'w',
      tastedAt: t,
      acidity: 4,
      aromas: const ['후추'],
      createdAt: t,
      updatedAt: t,
    );
    const suggestion = TastingSuggestion(
      scores: {
        TasteAttr.tannin: ScoreSuggestion(7, '평균 이상'),
        TasteAttr.acidity: ScoreSuggestion(8, '산미 높음'),
      },
      keywords: ['후추', '바닐라'],
      color: '루비',
    );
    TastingNote? result;
    await tester.binding.setSurfaceSize(const Size(400, 900));
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            result = await showSuggestionSheet(context,
                note: note, suggestion: suggestion);
          },
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // 이미 있는 산미(현재 4)는 체크 안 됨, 새 타닌은 체크됨
    final tannin = tester.widget<CheckboxListTile>(
        find.widgetWithText(CheckboxListTile, '타닌 7'));
    final acidity = tester.widget<CheckboxListTile>(
        find.widgetWithText(CheckboxListTile, '산미 8  (현재 4)'));
    expect(tannin.value, isTrue);
    expect(acidity.value, isFalse);
    // 이미 있는 키워드는 다시 제안하지 않음
    expect(find.widgetWithText(FilterChip, '후추'), findsNothing);
    expect(find.widgetWithText(FilterChip, '바닐라'), findsOneWidget);

    await tester.tap(find.text('선택한 항목 적용'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.tannin, 7);
    expect(result!.acidity, 4); // 체크 안 했으니 그대로
    expect(result!.keywords, ['후추', '바닐라']);
    expect(result!.color, '루비');
  });
}
