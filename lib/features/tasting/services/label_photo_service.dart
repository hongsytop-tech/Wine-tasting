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

  /// 사진 고르기 → 긴 변 1600px·품질 85 로 줄여서 업로드. 반환: 저장 경로.
  /// 사용자가 취소하면 null.
  Future<String?> pickAndUpload({
    required String noteId,
    required ImageSource source,
  }) async {
    final user = SupabaseService.currentUser;
    if (user == null) {
      throw const LabelPhotoError('사진은 로그인 후 올릴 수 있습니다.');
    }
    final file = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );
    if (file == null) return null;
    final mime = _mimeOf(file);
    final ext = _allowed[mime];
    if (ext == null) {
      throw LabelPhotoError('지원하지 않는 이미지 형식입니다 ($mime). JPG·PNG·WEBP 만 가능합니다.');
    }
    final bytes = await file.readAsBytes();
    final path = '${user.id}/$noteId/${_uuid.v4()}.$ext';
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
