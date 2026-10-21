import 'package:flutter/material.dart';

import '../models/taste_attr.dart';

/// 특징 점수(0~10) 막대 그래프. [values] 에 없는 항목은 표시하지 않는다.
class TasteProfileView extends StatelessWidget {
  const TasteProfileView({super.key, required this.values, this.dense = false});

  final Map<TasteAttr, num> values;

  /// true 면 끝 설명(드라이/스위트 등)을 생략한 좁은 표시.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final small = theme.textTheme.bodySmall?.copyWith(color: theme.hintColor);
    return Column(
      children: [
        for (final a in TasteAttr.values)
          if (values[a] != null)
            Padding(
              padding: EdgeInsets.symmetric(vertical: dense ? 2 : 4),
              child: Row(
                children: [
                  SizedBox(width: 52, child: Text(a.label)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: values[a]! / TasteAttr.maxScore,
                            minHeight: dense ? 6 : 8,
                            backgroundColor:
                                theme.colorScheme.surfaceContainerHighest,
                          ),
                        ),
                        if (!dense)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(a.low, style: small),
                              Text(a.high, style: small),
                            ],
                          ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    child: Text(
                      scoreText(values[a]!),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}

/// 한 줄 요약: "당도 3 · 산미 7 · 타닌 6".
String profileSummary(Map<TasteAttr, num> values, {int max = 4}) => [
      for (final a in TasteAttr.values)
        if (values[a] != null) '${a.label} ${scoreText(values[a]!)}',
    ].take(max).join(' · ');
