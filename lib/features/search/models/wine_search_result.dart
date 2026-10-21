import '../../../core/utils/json_utils.dart';
import '../../wines/models/wine_type.dart';

/// `wine-search` Edge Function 이 돌려주는 정규화된 검색 결과 1건.
/// 소스마다 채워지는 필드가 다르므로 대부분 비어 있을 수 있다.
class WineSearchResult {
  const WineSearchResult({
    required this.source,
    required this.sourceId,
    required this.name,
    this.producer = '',
    this.vintage,
    this.type = WineType.other,
    this.country = '',
    this.region = '',
    this.grapes = const [],
    this.imageUrl = '',
    this.sourceUrl = '',
    this.barcode = '',
  });

  final String source;
  final String sourceId;
  final String name;
  final String producer;
  final int? vintage;
  final WineType type;
  final String country;
  final String region;
  final List<String> grapes;
  final String imageUrl;
  final String sourceUrl;
  final String barcode;

  String get originLabel =>
      [region, country].where((e) => e.isNotEmpty).join(', ');

  factory WineSearchResult.fromJson(Map<String, dynamic> j) => WineSearchResult(
        source: J.str(j, 'source'),
        sourceId: J.str(j, 'sourceId'),
        name: J.str(j, 'name'),
        producer: J.str(j, 'producer'),
        vintage: J.intOrNull(j, 'vintage'),
        type: WineType.parse(J.strOrNull(j, 'type')),
        country: J.str(j, 'country'),
        region: J.str(j, 'region'),
        grapes: J.strList(j, 'grapes'),
        imageUrl: J.str(j, 'imageUrl'),
        sourceUrl: J.str(j, 'sourceUrl'),
        barcode: J.str(j, 'barcode'),
      );
}

/// 검색 소스 표시용 라벨.
String sourceLabel(String source) {
  switch (source) {
    case 'openfoodfacts':
      return 'Open Food Facts';
    case 'manual':
      return '직접 입력';
    default:
      return source;
  }
}
