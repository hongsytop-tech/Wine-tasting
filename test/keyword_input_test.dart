import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wine_tasting/features/tasting/widgets/keyword_input.dart';

void main() {
  testWidgets('frequent chip, typed keyword and delete all update the list',
      (tester) async {
    var selected = <String>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) => KeywordInput(
            selected: selected,
            frequent: const ['오크', '체리'],
            onChanged: (v) => setState(() => selected = v),
          ),
        ),
      ),
    ));

    // 자주 쓴 칩 탭 → 추가
    await tester.tap(find.widgetWithText(ActionChip, '오크'));
    await tester.pump();
    expect(selected, ['오크']);

    // 직접 입력 후 Enter → 추가 (목록에 없는 단어도 허용)
    await tester.enterText(find.byType(TextField), '흑연');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(selected, ['오크', '흑연']);

    // 이미 고른 키워드는 자주 쓴 칩에서 빠짐
    expect(find.widgetWithText(ActionChip, '오크'), findsNothing);

    // 칩의 x 로 삭제
    await tester.tap(find.descendant(
      of: find.widgetWithText(InputChip, '오크'),
      matching: find.byIcon(Icons.clear),
    ));
    await tester.pump();
    expect(selected, ['흑연']);
  });
}
