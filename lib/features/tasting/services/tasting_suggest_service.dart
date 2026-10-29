import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_service.dart';
import '../../wines/models/wine_type.dart';
import '../models/taste_attr.dart';
import '../models/tasting_vocab.dart';

class SuggestError implements Exception {
  const SuggestError(this.message);
  final String message;
  @override
  String toString() => message;
}

/// 제안된 점수 하나 (근거가 된 메모 구절 포함).
class ScoreSuggestion {
  const ScoreSuggestion(this.value, this.evidence);
  final int value;
  final String evidence;
}

class TastingSuggestion {
  const TastingSuggestion({
    this.scores = const {},
    this.keywords = const [],
    this.color = '',
  });

  final Map<TasteAttr, ScoreSuggestion> scores;
  final List<String> keywords;
  final String color;

  bool get isEmpty => scores.isEmpty && keywords.isEmpty && color.isEmpty;

  factory TastingSuggestion.fromJson(Map<String, dynamic> j) {
    final scores = <TasteAttr, ScoreSuggestion>{};
    final raw = j['scores'];
    if (raw is Map) {
      for (final a in TasteAttr.values) {
        final s = raw[a.name];
        if (s is Map && s['value'] is num) {
          scores[a] = ScoreSuggestion(
            (s['value'] as num).round().clamp(0, TasteAttr.maxScore),
            '${s['evidence'] ?? ''}',
          );
        }
      }
    }
    return TastingSuggestion(
      scores: scores,
      keywords: [for (final k in (j['keywords'] as List? ?? const [])) '$k'],
      color: '${j['color'] ?? ''}',
    );
  }
}

/// 총평 → 점수·키워드·색상 제안 — Edge Function `tasting-suggest`(Claude API) 호출.
/// 결과는 제안일 뿐이고, 화면에서 사용자가 고른 것만 노트에 적용한다.
class TastingSuggestService {
  Future<TastingSuggestion> suggest({
    required String comment,
    required WineType type,
  }) async {
    if (!SupabaseService.isSignedIn) {
      throw const SuggestError('AI 제안은 로그인 후 사용할 수 있습니다.');
    }
    if (comment.trim().isEmpty) {
      throw const SuggestError('총평을 먼저 적어 주세요.');
    }
    try {
      final res = await SupabaseService.client.functions.invoke(
        'tasting-suggest',
        body: {
          'comment': comment.trim(),
          'vocabulary': TastingVocab.allDescriptors,
          'colors': TastingVocab.colorsFor(type),
        },
      );
      final data = res.data;
      if (data is! Map) throw const SuggestError('AI 응답 형식 오류');
      return TastingSuggestion.fromJson(Map<String, dynamic>.from(data));
    } on FunctionException catch (e) {
      throw SuggestError(_message(e));
    }
  }

  static String _message(FunctionException e) {
    final d = e.details;
    final code = d is Map ? '${d['error'] ?? ''}' : '';
    switch (code) {
      case 'no_api_key':
        return 'Supabase 에 ANTHROPIC_API_KEY secret 이 없습니다 (docs/SETUP.md 참고).';
      case 'bad_api_key':
        return 'ANTHROPIC_API_KEY 가 올바르지 않습니다.';
      case 'login_required':
        return '로그인이 필요합니다.';
      case 'rate_limited':
        return '요청이 많아 잠시 후 다시 시도해 주세요.';
      case 'refusal':
        return 'AI 가 이 메모를 처리하지 않았습니다.';
    }
    if (e.status == 404) {
      return '서버에 tasting-suggest 함수가 없습니다. Deploy Supabase Functions 를 실행하세요.';
    }
    return 'AI 제안 실패 (${e.status}): ${d ?? e.reasonPhrase ?? ''}';
  }
}
