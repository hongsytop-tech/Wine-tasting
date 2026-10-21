import 'package:flutter/material.dart';

/// 0.5 단위 별점. [onChanged] 가 null 이면 읽기 전용.
/// 별의 왼쪽 절반을 누르면 .5, 오른쪽 절반은 정수. 같은 값을 다시 누르면 지운다.
class RatingStars extends StatelessWidget {
  const RatingStars({
    super.key,
    required this.value,
    this.onChanged,
    this.size = 28,
  });

  final double? value;
  final ValueChanged<double?>? onChanged;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final v = value ?? 0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: onChanged == null
                ? null
                : (d) {
                    final half = d.localPosition.dx < size / 2;
                    final next = half ? i - 0.5 : i.toDouble();
                    onChanged!(next == value ? null : next);
                  },
            child: Icon(
              v >= i
                  ? Icons.star_rounded
                  : v >= i - 0.5
                      ? Icons.star_half_rounded
                      : Icons.star_outline_rounded,
              size: size,
              color: color,
            ),
          ),
      ],
    );
  }
}

/// "4.5" 처럼 표시. null 이면 '-'.
String ratingText(double? v) =>
    v == null ? '-' : (v % 1 == 0 ? v.toStringAsFixed(1) : '$v');
