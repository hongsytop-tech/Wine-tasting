import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/photo_providers.dart';

final _retried = <String>{};

/// Storage 경로의 라벨 사진을 보여준다 (서명 URL 을 받아 로드).
class LabelPhoto extends ConsumerWidget {
  const LabelPhoto({
    super.key,
    required this.path,
    this.size,
    this.fit = BoxFit.cover,
    this.radius = 8,
  });

  final String path;
  final double? size;
  final BoxFit fit;
  final double radius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final url = ref.watch(photoUrlProvider(path));
    final placeholder = Container(
      width: size,
      height: size,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: url.isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.broken_image_outlined),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: url.maybeWhen(
        data: (u) => Image.network(
          u,
          width: size,
          height: size,
          fit: fit,
          errorBuilder: (_, __, ___) {
            // 만료된 서명 URL 일 수 있으니 한 번만 새로 받아 본다
            // (파일 자체가 깨졌으면 무한 재요청이 되지 않도록 경로당 1회).
            if (_retried.add(path)) {
              Future.microtask(() => ref.invalidate(photoUrlProvider(path)));
            }
            return placeholder;
          },
        ),
        orElse: () => placeholder,
      ),
    );
  }
}

/// 사진 전체 화면 보기 (핀치 확대).
void showPhotoViewer(BuildContext context, String path) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: InteractiveViewer(
            maxScale: 5,
            child: LabelPhoto(path: path, fit: BoxFit.contain, radius: 0),
          ),
        ),
      ),
    ),
  );
}
