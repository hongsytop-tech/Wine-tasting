import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

final _grouping = NumberFormat.decimalPattern('ko_KR');

/// 1234567 → "1,234,567". null 이면 빈 문자열.
String formatThousands(int? v) => v == null ? '' : _grouping.format(v);

/// "1,234,567" → 1234567. 숫자가 없으면 null.
int? parseThousands(String text) {
  final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
  return digits.isEmpty ? null : int.tryParse(digits);
}

/// 숫자만 받고 입력하는 동안 세 자리마다 쉼표를 넣는다.
/// 커서는 끝에서부터 같은 자리(숫자 개수 기준)에 유지한다.
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  const ThousandsSeparatorInputFormatter({this.maxDigits = 12});

  /// 너무 큰 수로 int 범위를 넘지 않게 자릿수 제한.
  final int maxDigits;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > maxDigits) return oldValue;
    // 앞자리 0 정리 ("007" → "7"), 단 "0" 하나는 허용.
    digits = digits.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(
          selection: TextSelection.collapsed(offset: 0));
    }
    final formatted = _grouping.format(int.parse(digits));

    // 커서 뒤에 있던 숫자 개수를 유지해 커서 위치를 다시 계산.
    final cursor = newValue.selection.end.clamp(0, newValue.text.length);
    final digitsAfter = newValue.text
        .substring(cursor)
        .replaceAll(RegExp(r'[^0-9]'), '')
        .length;
    var offset = formatted.length;
    var seen = 0;
    while (offset > 0 && seen < digitsAfter) {
      offset--;
      if (RegExp(r'[0-9]').hasMatch(formatted[offset])) seen++;
    }
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}
