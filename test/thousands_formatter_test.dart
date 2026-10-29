import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wine_tasting/core/utils/thousands_formatter.dart';

TextEditingValue _type(String old, String now, [int? cursor]) =>
    const ThousandsSeparatorInputFormatter().formatEditUpdate(
      TextEditingValue(text: old),
      TextEditingValue(
        text: now,
        selection: TextSelection.collapsed(offset: cursor ?? now.length),
      ),
    );

void main() {
  test('format / parse', () {
    expect(formatThousands(45000), '45,000');
    expect(formatThousands(1234567), '1,234,567');
    expect(formatThousands(null), '');
    expect(parseThousands('1,234,567'), 1234567);
    expect(parseThousands(''), isNull);
  });

  test('typing adds commas and keeps the cursor at the end', () {
    final v = _type('4,500', '4,5000');
    expect(v.text, '45,000');
    expect(v.selection.baseOffset, 6);
    expect(_type('', '1').text, '1');
    expect(_type('999', '9999').text, '9,999');
  });

  test('deleting and editing in the middle keep the cursor on the same digit',
      () {
    // "45,000" 에서 끝 0 하나 지움 → "4,500"
    expect(_type('45,000', '45,00').text, '4,500');
    // "45,000" 의 4 와 5 사이에 1 입력 (커서는 1 뒤)
    final v = _type('45,000', '415,000', 2);
    expect(v.text, '415,000');
    expect(v.selection.baseOffset, 2);
  });

  test('non-digits, leading zeros and too many digits', () {
    expect(_type('', 'ab12').text, '12');
    expect(_type('', '007').text, '7');
    expect(_type('', '0').text, '0');
    expect(_type('', '').text, '');
    expect(_type('999,999,999,999', '9999999999999').text, '999,999,999,999');
  });
}
