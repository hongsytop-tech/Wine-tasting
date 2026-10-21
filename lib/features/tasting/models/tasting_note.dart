import '../../../core/utils/json_utils.dart';

/// 와인 1병에 대한 테이스팅 기록 1회.
///
/// 구조는 WSET 체계적 시음법(외관 → 향 → 맛 → 결론)을 단순화한 것.
/// 1~5 척도 항목은 null 이면 "기록 안 함".
class TastingNote {
  const TastingNote({
    required this.id,
    required this.wineId,
    required this.tastedAt,
    this.place = '',
    this.companions = '',
    this.rating,
    this.color = '',
    this.colorIntensity,
    this.aromaIntensity,
    this.aromas = const [],
    this.sweetness,
    this.acidity,
    this.tannin,
    this.alcohol,
    this.body,
    this.finish,
    this.flavors = const [],
    this.pairing = '',
    this.price,
    this.comment = '',
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String wineId;
  final DateTime tastedAt;
  final String place;
  final String companions;

  /// 이번 시음의 점수 0.5 ~ 5.0. 와인 자체의 종합 평점은 [Wine.myRating].
  final double? rating;

  // 외관
  final String color;
  final int? colorIntensity;

  // 향
  final int? aromaIntensity;
  final List<String> aromas;

  // 맛 (구조)
  final int? sweetness;
  final int? acidity;
  final int? tannin;
  final int? alcohol;
  final int? body;
  final int? finish;
  final List<String> flavors;

  // 결론
  final String pairing;

  /// 구매가 (원). null = 미기록.
  final int? price;
  final String comment;

  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  factory TastingNote.create({required String id, required String wineId}) {
    final now = DateTime.now();
    return TastingNote(
      id: id,
      wineId: wineId,
      tastedAt: now,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory TastingNote.fromJson(Map<String, dynamic> j) {
    final now = DateTime.now();
    return TastingNote(
      id: J.str(j, 'id'),
      wineId: J.str(j, 'wineId', 'wine_id'),
      tastedAt: J.date(j, 'tastedAt', 'tasted_at') ?? now,
      place: J.str(j, 'place'),
      companions: J.str(j, 'companions'),
      rating: J.doubleOrNull(j, 'rating'),
      color: J.str(j, 'color'),
      colorIntensity: J.intOrNull(j, 'colorIntensity', 'color_intensity'),
      aromaIntensity: J.intOrNull(j, 'aromaIntensity', 'aroma_intensity'),
      aromas: J.strList(j, 'aromas'),
      sweetness: J.intOrNull(j, 'sweetness'),
      acidity: J.intOrNull(j, 'acidity'),
      tannin: J.intOrNull(j, 'tannin'),
      alcohol: J.intOrNull(j, 'alcohol'),
      body: J.intOrNull(j, 'body'),
      finish: J.intOrNull(j, 'finish'),
      flavors: J.strList(j, 'flavors'),
      pairing: J.str(j, 'pairing'),
      price: J.intOrNull(j, 'price'),
      comment: J.str(j, 'comment'),
      createdAt: J.date(j, 'createdAt', 'created_at') ?? now,
      updatedAt: J.date(j, 'updatedAt', 'updated_at') ?? now,
      deletedAt: J.date(j, 'deletedAt', 'deleted_at'),
    );
  }

  /// Local-cache JSON (camelCase).
  Map<String, dynamic> toJson() => {
        'id': id,
        'wineId': wineId,
        'tastedAt': J.iso(tastedAt),
        'place': place,
        'companions': companions,
        'rating': rating,
        'color': color,
        'colorIntensity': colorIntensity,
        'aromaIntensity': aromaIntensity,
        'aromas': aromas,
        'sweetness': sweetness,
        'acidity': acidity,
        'tannin': tannin,
        'alcohol': alcohol,
        'body': body,
        'finish': finish,
        'flavors': flavors,
        'pairing': pairing,
        'price': price,
        'comment': comment,
        'createdAt': J.iso(createdAt),
        'updatedAt': J.iso(updatedAt),
        'deletedAt': J.iso(deletedAt),
      };

  /// Supabase row (snake_case columns).
  Map<String, dynamic> toRow(String userId) => {
        'user_id': userId,
        'id': id,
        'wine_id': wineId,
        'tasted_at': J.iso(tastedAt),
        'place': place,
        'companions': companions,
        'rating': rating,
        'color': color,
        'color_intensity': colorIntensity,
        'aroma_intensity': aromaIntensity,
        'aromas': aromas,
        'sweetness': sweetness,
        'acidity': acidity,
        'tannin': tannin,
        'alcohol': alcohol,
        'body': body,
        'finish': finish,
        'flavors': flavors,
        'pairing': pairing,
        'price': price,
        'comment': comment,
        'created_at': J.iso(createdAt),
        'updated_at': J.iso(updatedAt),
        'deleted_at': J.iso(deletedAt),
      };

  static const _keep = Object();

  TastingNote copyWith({
    DateTime? tastedAt,
    String? place,
    String? companions,
    Object? rating = _keep,
    String? color,
    Object? colorIntensity = _keep,
    Object? aromaIntensity = _keep,
    List<String>? aromas,
    Object? sweetness = _keep,
    Object? acidity = _keep,
    Object? tannin = _keep,
    Object? alcohol = _keep,
    Object? body = _keep,
    Object? finish = _keep,
    List<String>? flavors,
    String? pairing,
    Object? price = _keep,
    String? comment,
    DateTime? updatedAt,
    Object? deletedAt = _keep,
  }) {
    T? pick<T>(Object? v, T? current) =>
        identical(v, _keep) ? current : v as T?;
    return TastingNote(
      id: id,
      wineId: wineId,
      tastedAt: tastedAt ?? this.tastedAt,
      place: place ?? this.place,
      companions: companions ?? this.companions,
      rating: pick<double>(rating, this.rating),
      color: color ?? this.color,
      colorIntensity: pick<int>(colorIntensity, this.colorIntensity),
      aromaIntensity: pick<int>(aromaIntensity, this.aromaIntensity),
      aromas: aromas ?? this.aromas,
      sweetness: pick<int>(sweetness, this.sweetness),
      acidity: pick<int>(acidity, this.acidity),
      tannin: pick<int>(tannin, this.tannin),
      alcohol: pick<int>(alcohol, this.alcohol),
      body: pick<int>(body, this.body),
      finish: pick<int>(finish, this.finish),
      flavors: flavors ?? this.flavors,
      pairing: pairing ?? this.pairing,
      price: pick<int>(price, this.price),
      comment: comment ?? this.comment,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: pick<DateTime>(deletedAt, this.deletedAt),
    );
  }
}
