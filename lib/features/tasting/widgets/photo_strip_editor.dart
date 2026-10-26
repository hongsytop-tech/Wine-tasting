import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'label_photo.dart';

/// 노트의 라벨 사진 목록 편집 (추가·삭제·크게 보기).
class PhotoStripEditor extends StatelessWidget {
  const PhotoStripEditor({
    super.key,
    required this.photos,
    required this.onAdd,
    required this.onRemove,
    required this.enabled,
    this.uploading = false,
    this.uploadProgress,
    this.maxPhotos = 10,
  });

  final List<String> photos;
  final ValueChanged<ImageSource> onAdd;
  final ValueChanged<String> onRemove;

  /// false 면 (로그인 안 됨) 추가 버튼 대신 안내 문구.
  final bool enabled;
  final bool uploading;

  /// "2/5" 처럼 업로드 진행 상황.
  final String? uploadProgress;
  final int maxPhotos;

  static const _size = 96.0;

  Future<void> _chooseSource(BuildContext context) async {
    final src = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('카메라로 찍기'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('앨범에서 고르기 (여러 장 선택 가능)'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (src != null) onAdd(src);
  }

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return Text(
        '라벨 사진은 로그인한 상태에서 올릴 수 있습니다.',
        style: Theme.of(context).textTheme.bodySmall,
      );
    }
    return SizedBox(
      height: _size,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final p in photos)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: () => showPhotoViewer(context, p),
                    child: LabelPhoto(path: p, size: _size),
                  ),
                  Positioned(
                    top: 2,
                    right: 2,
                    child: InkWell(
                      onTap: () => onRemove(p),
                      child: const CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.black54,
                        child: Icon(Icons.close, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (photos.length < maxPhotos || uploading)
            InkWell(
              onTap: uploading ? null : () => _chooseSource(context),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: _size,
                height: _size,
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: uploading
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          if (uploadProgress != null) ...[
                            const SizedBox(height: 6),
                            Text(uploadProgress!,
                                style: const TextStyle(fontSize: 12)),
                          ],
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_a_photo_outlined),
                          const SizedBox(height: 4),
                          Text(
                            '라벨 사진\n${photos.length}/$maxPhotos',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
              ),
            ),
        ],
      ),
    );
  }
}
