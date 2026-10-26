import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/supabase/supabase_service.dart';

class LabelPhotoError implements Exception {
  const LabelPhotoError(this.message);
  final String message;
  @override
  String toString() => message;
}

class PhotoUploadResult {
  const PhotoUploadResult({
    this.paths = const [],
    this.errors = const [],
    this.skipped = 0,
  });

  /// 업로드된 저장 경로.
  final List<String> paths;

  /// 실패한 사진별 사유.
  final List<String> errors;

  /// 최대 장수를 넘어 올리지 않은 사진 수.
  final int skipped;
}

/// 라벨 사진 저장소 — Supabase Storage 비공개 버킷 `wine-labels`.
/// 경로: `<user_id>/<note_id>/<uuid>.<ext>` (RLS: 본인 폴더만 읽기·쓰기).
class LabelPhotoService {
  static const bucket = 'wine-labels';
  static const _uuid = Uuid();
  static const _allowed = {
    'image/jpeg': 'jpg',
    'image/png': 'png',
    'image/webp': 'webp',
  };

  StorageFileApi get _store => SupabaseService.client.storage.from(bucket);

  bool get isAvailable => SupabaseService.isSignedIn;

  /// 노트 하나에 붙일 수 있는 최대 사진 수.
  static const maxPerNote = 10;

  /// 사진 고르기(앨범은 여러 장, 카메라는 한 장) → 긴 변 1600px·품질 85 로
  /// 줄여서 차례로 업로드. [remaining] 장을 넘는 사진은 올리지 않는다.
  /// 한 장이 실패해도 나머지는 계속 올린다.
  Future<PhotoUploadResult> pickAndUpload({
    required String noteId,
    required ImageSource source,
    required int remaining,
    void Function(int done, int total)? onProgress,
  }) async {
    final user = SupabaseService.currentUser;
    if (user == null) {
      throw const LabelPhotoError('사진은 로그인 후 올릴 수 있습니다.');
    }
    if (remaining <= 0) return const PhotoUploadResult();
    final picker = ImagePicker();
    final List<XFile> files;
    if (source == ImageSource.camera) {
      final f = await picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      files = f == null ? const [] : [f];
    } else {
      files = await picker.pickMultiImage(
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
        // image_picker 는 limit 을 2 이상만 받는다 (웹은 limit 을 무시하므로 아래에서 자름).
        limit: remaining >= 2 ? remaining : null,
      );
    }
    final take = files.take(remaining).toList();
    final paths = <String>[];
    final errors = <String>[];
    for (var i = 0; i < take.length; i++) {
      onProgress?.call(i, take.length);
      try {
        paths.add(await _upload(user.id, noteId, take[i]));
      } catch (e) {
        errors.add('${take[i].name}: $e');
      }
    }
    return PhotoUploadResult(
      paths: paths,
      errors: errors,
      skipped: files.length - take.length,
    );
  }

  Future<String> _upload(String userId, String noteId, XFile file) async {
    final mime = _mimeOf(file);
    final ext = _allowed[mime];
    if (ext == null) {
      throw LabelPhotoError('지원하지 않는 형식 ($mime). JPG·PNG·WEBP 만 가능합니다.');
    }
    final bytes = await file.readAsBytes();
    final path = '$userId/$noteId/${_uuid.v4()}.$ext';
    await _store.uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(contentType: mime, upsert: false),
    );
    return path;
  }

  /// 화면 표시용 임시 주소 (24시간 유효).
  Future<String> signedUrl(String path) =>
      _store.createSignedUrl(path, 60 * 60 * 24);

  /// 사진 파일 삭제 (실패해도 무시 — 저장 공간만 남는다).
  Future<void> remove(Iterable<String> paths) async {
    final list = paths.toList();
    if (list.isEmpty || !SupabaseService.isSignedIn) return;
    try {
      await _store.remove(list);
    } catch (_) {}
  }

  static String _mimeOf(XFile f) {
    final m = f.mimeType;
    if (m != null && m.isNotEmpty) return m == 'image/jpg' ? 'image/jpeg' : m;
    final name = f.name.toLowerCase();
    if (name.endsWith('.png')) return 'image/png';
    if (name.endsWith('.webp')) return 'image/webp';
    if (name.endsWith('.heic') || name.endsWith('.heif')) return 'image/heic';
    return 'image/jpeg';
  }
}
