import '../../../core/supabase/supabase_service.dart';
import '../models/wine_search_result.dart';

class WineSearchUnavailable implements Exception {
  const WineSearchUnavailable(this.message);
  final String message;
  @override
  String toString() => message;
}

class WineSearchResponse {
  const WineSearchResponse({required this.results, this.errors = const {}});

  final List<WineSearchResult> results;

  /// 소스별 실패 사유 (일부 소스가 실패해도 나머지 결과는 보여준다).
  final Map<String, String> errors;
}

/// 와인 검색 — Supabase Edge Function `wine-search` 프록시 호출.
/// 외부 소스 호출(CORS·User-Agent·API 키)과 캐시는 서버가 담당한다.
class WineSearchService {
  /// [query] 가 8~14자리 숫자면 바코드(EAN/UPC) 조회로 처리한다.
  Future<WineSearchResponse> search(String query) async {
    if (!SupabaseService.isReady) {
      throw const WineSearchUnavailable(
        '검색 서버에 연결되지 않은 빌드입니다.\n'
        'GitHub Secrets 에 SUPABASE_URL / SUPABASE_ANON_KEY 를 등록한 뒤 '
        'Deploy Web 을 다시 실행하세요 (docs/SETUP.md 4~5단계).',
      );
    }
    final q = query.trim();
    if (q.isEmpty) return const WineSearchResponse(results: []);
    final isBarcode = RegExp(r'^\d{8,14}$').hasMatch(q);

    final res = await SupabaseService.client.functions.invoke(
      'wine-search',
      body: isBarcode ? {'barcode': q} : {'q': q},
    );
    final data = res.data;
    if (data is! Map) {
      throw Exception('검색 서버 응답 형식 오류');
    }
    if (data['error'] != null) {
      throw Exception('${data['error']}');
    }
    final results = ((data['results'] as List?) ?? const [])
        .whereType<Map>()
        .map((e) => WineSearchResult.fromJson(Map<String, dynamic>.from(e)))
        .where((r) => r.name.isNotEmpty)
        .toList();
    final errors = <String, String>{
      for (final e in ((data['errors'] as Map?) ?? const {}).entries)
        '${e.key}': '${e.value}',
    };
    return WineSearchResponse(results: results, errors: errors);
  }
}
