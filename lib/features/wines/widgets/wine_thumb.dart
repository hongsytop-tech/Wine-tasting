import 'package:flutter/material.dart';

import '../models/wine_type.dart';

/// 라벨 이미지 썸네일. 이미지가 없거나 로드 실패 시 종류별 색 아이콘.
class WineThumb extends StatelessWidget {
  const WineThumb({
    super.key,
    required this.imageUrl,
    required this.type,
    this.size = 56,
  });

  final String imageUrl;
  final WineType type;
  final double size;

  static Color colorFor(WineType t) {
    switch (t) {
      case WineType.red:
        return const Color(0xFF7B1E3A);
      case WineType.white:
        return const Color(0xFFD4B24C);
      case WineType.rose:
        return const Color(0xFFE48A9A);
      case WineType.sparkling:
        return const Color(0xFFC9B87A);
      case WineType.dessert:
        return const Color(0xFFB7792B);
      case WineType.fortified:
        return const Color(0xFF6B3B2A);
      case WineType.other:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colorFor(type).withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.wine_bar, color: colorFor(type), size: size * 0.55),
    );
    if (imageUrl.isEmpty) return fallback;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      ),
    );
  }
}
