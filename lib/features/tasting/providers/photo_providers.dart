import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/label_photo_service.dart';
import '../services/tasting_suggest_service.dart';

final labelPhotoServiceProvider = Provider((_) => LabelPhotoService());

final tastingSuggestServiceProvider = Provider((_) => TastingSuggestService());

/// 저장 경로 → 표시용 서명 URL (세션 동안 캐시, URL 은 24시간 유효).
final photoUrlProvider = FutureProvider.family<String, String>(
  (ref, path) => ref.read(labelPhotoServiceProvider).signedUrl(path),
);
