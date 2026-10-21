import 'package:flutter/material.dart';

/// 1~5 척도 선택. 선택된 값을 다시 누르면 지워진다 (null = 기록 안 함).
class ScalePicker extends StatelessWidget {
  const ScalePicker({
    super.key,
    required this.label,
    required this.value,
    required this.labels,
    required this.onChanged,
  });

  final String label;
  final int? value;

  /// 1~5 각각의 설명.
  final List<String> labels;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final desc = value == null ? '기록 안 함' : labels[value! - 1];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 64, child: Text(label)),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var i = 1; i <= 5; i++)
                  InkResponse(
                    onTap: () => onChanged(value == i ? null : i),
                    radius: 22,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: value != null && i <= value!
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surfaceContainerHighest,
                      child: Text(
                        '$i',
                        style: TextStyle(
                          fontSize: 13,
                          color: value != null && i <= value!
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            width: 80,
            child: Text(
              desc,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
