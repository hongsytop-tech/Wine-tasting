import '../../../core/utils/json_utils.dart';
import 'wine_type.dart';

/// 내 셀러에 저장한 와인 1병(=1 라벨+빈티지).
///
/// 외부 소스(검색 결과)에서 가져온 경우 그 시점의 메타데이터를 스냅샷으로
/// 저장한다 — 소스가 사라지거나 바뀌어도 내 기록은 유지된다.
/// 삭제는 [deletedAt] 를 찍는 soft-delete (기기 간 동기화 시 부활 방지).
class Wine {
  const Wine({
    required this.id,
    required this.name,
    this.producer = '',
    this.vintage,
    this.type = WineType.other,
    this.country = '',
    this.region = '',
    this.grapes = const [],
    this.grapePercents = const {},
    this.imageUrl = '',
    this.source = 'manual',
    this.sourceId = '',
    this.sourceUrl = '',
    this.barcode = '',
    this.isFavorite = false,
    this.myRating,
    this.memo = '',
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String name;
  final String producer;

  /// null = NV(논빈티지) 또는 미상.
  final int? vintage;
  final WineType type;
  final String country;
  final String region;

  /// 품종 (블렌드면 여러 개, 입력 순서 유지).
  final List<String> grapes;

  /// 블렌드 비율(%) — 품종 이름 → 비율. 비율을 모르면 비어 있거나 일부만 있다.
  final Map<String, int> grapePercents;
  final String imageUrl;

  /// 'manual' | 'openfoodfacts' | ... (Edge Function 의 source 값)
  final String source;
  final String sourceId;
  final String sourceUrl;
  final String barcode;

  final bool isFavorite;

  /// 내 평점 0.5 ~ 5.0 (0.5 단위). null = 아직 안 매김.
  final double? myRating;
  final String memo;

  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  String get vintageLabel => vintage == null ? 'NV' : '$vintage';

  bool get isBlend => grapes.length > 1;

  /// "카베르네 소비뇽 60% · 메를로 40%" (비율 없는 품종은 이름만).
  String get grapesLabel => [
        for (final g in grapes)
          grapePercents[g] == null ? g : '$g ${grapePercents[g]}%',
      ].join(' · ');

  /// 리스트에 한 줄로 보여줄 산지 (지역, 국가).
  String get originLabel =>
      [region, country].where((e) => e.isNotEmpty).join(', ');

  factory Wine.fromJson(Map<String, dynamic> j) {
    final now = DateTime.now();
    return Wine(
      id: J.str(j, 'id'),
      name: J.str(j, 'name'),
      producer: J.str(j, 'producer'),
      vintage: J.intOrNull(j, 'vintage'),
      type: WineType.parse(J.strOrNull(j, 'type')),
      country: J.str(j, 'country'),
      region: J.str(j, 'region'),
      grapes: J.strList(j, 'grapes'),
      grapePercents: J.intMap(j, 'grapePercents', 'grape_percents'),
      imageUrl: J.str(j, 'imageUrl', 'image_url'),
      source: J.strOrNull(j, 'source') ?? 'manual',
      sourceId: J.str(j, 'sourceId', 'source_id'),
      sourceUrl: J.str(j, 'sourceUrl', 'source_url'),
      barcode: J.str(j, 'barcode'),
      isFavorite: J.boolean(j, 'isFavorite', 'is_favorite'),
      myRating: J.doubleOrNull(j, 'myRating', 'my_rating'),
      memo: J.str(j, 'memo'),
      createdAt: J.date(j, 'createdAt', 'created_at') ?? now,
      updatedAt: J.date(j, 'updatedAt', 'updated_at') ?? now,
      deletedAt: J.date(j, 'deletedAt', 'deleted_at'),
    );
  }

  /// Local-cache JSON (camelCase).
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'producer': producer,
        'vintage': vintage,
        'type': type.name,
        'country': country,
        'region': region,
        'grapes': grapes,
        'grapePercents': grapePercents,
        'imageUrl': imageUrl,
        'source': source,
        'sourceId': sourceId,
        'sourceUrl': sourceUrl,
        'barcode': barcode,
        'isFavorite': isFavorite,
        'myRating': myRating,
        'memo': memo,
        'createdAt': J.iso(createdAt),
        'updatedAt': J.iso(updatedAt),
        'deletedAt': J.iso(deletedAt),
      };

  /// Supabase row (snake_case columns).
  Map<String, dynamic> toRow(String userId) => {
        'user_id': userId,
        'id': id,
        'name': name,
        'producer': producer,
        'vintage': vintage,
        'type': type.name,
        'country': country,
        'region': region,
        'grapes': grapes,
        'grape_percents': grapePercents,
        'image_url': imageUrl,
        'source': source,
        'source_id': sourceId,
        'source_url': sourceUrl,
        'barcode': barcode,
        'is_favorite': isFavorite,
        'my_rating': myRating,
        'memo': memo,
        'created_at': J.iso(createdAt),
        'updated_at': J.iso(updatedAt),
        'deleted_at': J.iso(deletedAt),
      };

  // `_keep` distinguishes "argument omitted" from "explicitly set to null" so
  // nullable fields (vintage, myRating, deletedAt) can be cleared via copyWith.
  static const _keep = Object();

  Wine copyWith({
    String? name,
    String? producer,
    Object? vintage = _keep,
    WineType? type,
    String? country,
    String? region,
    List<String>? grapes,
    Map<String, int>? grapePercents,
    String? imageUrl,
    bool? isFavorite,
    Object? myRating = _keep,
    String? memo,
    DateTime? updatedAt,
    Object? deletedAt = _keep,
  }) =>
      Wine(
        id: id,
        name: name ?? this.name,
        producer: producer ?? this.producer,
        vintage: identical(vintage, _keep) ? this.vintage : vintage as int?,
        type: type ?? this.type,
        country: country ?? this.country,
        region: region ?? this.region,
        grapes: grapes ?? this.grapes,
        grapePercents: grapePercents ?? this.grapePercents,
        imageUrl: imageUrl ?? this.imageUrl,
        source: source,
        sourceId: sourceId,
        sourceUrl: sourceUrl,
        barcode: barcode,
        isFavorite: isFavorite ?? this.isFavorite,
        myRating:
            identical(myRating, _keep) ? this.myRating : myRating as double?,
        memo: memo ?? this.memo,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: identical(deletedAt, _keep)
            ? this.deletedAt
            : deletedAt as DateTime?,
      );
}
