import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../tasting/providers/tasting_providers.dart';
import '../../tasting/widgets/label_photo.dart';
import '../models/wine.dart';
import 'wine_thumb.dart';

/// 와인 썸네일 — 검색에서 가져온 이미지가 있으면 그것, 없으면 가장 최근
/// 테이스팅 노트의 라벨 사진, 둘 다 없으면 종류별 아이콘.
class WineAvatar extends ConsumerWidget {
  const WineAvatar({super.key, required this.wine, this.size = 56});

  final Wine wine;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (wine.imageUrl.isEmpty) {
      final photo = ref.watch(latestPhotoByWineProvider)[wine.id];
      if (photo != null) return LabelPhoto(path: photo, size: size);
    }
    return WineThumb(imageUrl: wine.imageUrl, type: wine.type, size: size);
  }
}
