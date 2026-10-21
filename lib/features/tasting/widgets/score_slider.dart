import 'package:flutter/material.dart';

import '../models/taste_attr.dart';

/// 특징 점수 0~10 입력. null = 기록 안 함 (슬라이더를 흐리게 표시).
/// 슬라이더를 움직이면 기록되고, ✕ 를 누르면 다시 "기록 안 함".
class ScoreSlider extends StatelessWidget {
  const ScoreSlider({
    super.key,
    required this.attr,
    required this.value,
    required this.onChanged,
  });

  final TasteAttr attr;
  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final small = theme.textTheme.bodySmall?.copyWith(color: theme.hintColor);
    final v = value;
    return Row(
      children: [
        SizedBox(width: 52, child: Text(attr.label)),
        Expanded(
          child: Column(
            children: [
              Opacity(
                opacity: v == null ? 0.35 : 1,
                child: Slider(
                  value: (v ?? 0).toDouble(),
                  min: 0,
                  max: TasteAttr.maxScore.toDouble(),
                  divisions: TasteAttr.maxScore,
                  label: '${v ?? 0}',
                  onChanged: (d) => onChanged(d.round()),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('0 ${attr.low}', style: small),
                    Text('${attr.high} 10', style: small),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          width: 28,
          child: Text(
            v == null ? '-' : '$v',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
        ),
        IconButton(
          tooltip: '기록 안 함',
          visualDensity: VisualDensity.compact,
          onPressed: v == null ? null : () => onChanged(null),
          icon: Icon(Icons.close,
              size: 18, color: v == null ? Colors.transparent : null),
        ),
      ],
    );
  }
}
