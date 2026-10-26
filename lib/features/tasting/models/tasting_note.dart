import '../../../core/utils/json_utils.dart';
import 'taste_attr.dart';

/// 와인 1병에 대한 테이스팅 기록 1회.
///
/// 구조는 WSET 체계적 시음법(외관 → 향 → 맛 → 결론)을 단순화한 것.
/// 특징 점수([TasteAttr])는 0~10, null 이면 "기록 안 함".
///
/// 초기 버전은 1~5 척도였다. 저장 데이터의 `scale` 이 10 이 아니면(없거나 5)
/// 읽을 때 0~10 으로 환산하고(1→0, 3→5, 5→10), 다음 저장부터 `scale: 10` 으로 쓴다.
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
    this.photos = const [],
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

  // 외관 (색상 이름 + 색 농도 0~10)
  final String color;
  final int? colorIntensity;

  // 향
  final int? aromaIntensity;
  final List<String> aromas;

  // 맛 (구조, 0~10)
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

  /// 라벨 사진 — Supabase Storage(wine-labels 버킷) 안의 경로 목록.
  final List<String> photos;

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

  /// 현재 저장 척도 (0~[scale]).
  static const scale = TasteAttr.maxScore;

  /// 구버전 1~5 점수를 0~10 으로 환산.
  static int fromLegacyScale(int v) => ((v - 1) * 2.5).round().clamp(0, 10);

  factory TastingNote.fromJson(Map<String, dynamic> j) {
    final now = DateTime.now();
    final legacy = (J.intOrNull(j, 'scale') ?? 5) != scale;
    int? score(String camel, [String? snake]) {
      final v = J.intOrNull(j, camel, snake);
      if (v == null) return null;
      return legacy ? fromLegacyScale(v) : v.clamp(0, scale);
    }

    return TastingNote(
      id: J.str(j, 'id'),
      wineId: J.str(j, 'wineId', 'wine_id'),
      tastedAt: J.date(j, 'tastedAt', 'tasted_at') ?? now,
      place: J.str(j, 'place'),
      companions: J.str(j, 'companions'),
      rating: J.doubleOrNull(j, 'rating'),
      color: J.str(j, 'color'),
      colorIntensity: score('colorIntensity', 'color_intensity'),
      aromaIntensity: score('aromaIntensity', 'aroma_intensity'),
      aromas: J.strList(j, 'aromas'),
      sweetness: score('sweetness'),
      acidity: score('acidity'),
      tannin: score('tannin'),
      alcohol: score('alcohol'),
      body: score('body'),
      finish: score('finish'),
      flavors: J.strList(j, 'flavors'),
      pairing: J.str(j, 'pairing'),
      price: J.intOrNull(j, 'price'),
      comment: J.str(j, 'comment'),
      photos: J.strList(j, 'photos'),
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
        'scale': scale,
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
        'photos': photos,
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
        'scale': scale,
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
        'photos': photos,
        'created_at': J.iso(createdAt),
        'updated_at': J.iso(updatedAt),
        'deleted_at': J.iso(deletedAt),
      };

  /// 특징 점수 하나만 바꾼 사본.
  TastingNote withAttr(TasteAttr a, int? v) {
    switch (a) {
      case TasteAttr.colorIntensity:
        return copyWith(colorIntensity: v);
      case TasteAttr.aromaIntensity:
        return copyWith(aromaIntensity: v);
      case TasteAttr.sweetness:
        return copyWith(sweetness: v);
      case TasteAttr.acidity:
        return copyWith(acidity: v);
      case TasteAttr.tannin:
        return copyWith(tannin: v);
      case TasteAttr.alcohol:
        return copyWith(alcohol: v);
      case TasteAttr.body:
        return copyWith(body: v);
      case TasteAttr.finish:
        return copyWith(finish: v);
    }
  }

  static const _keep = Object();

  TastingNote copyWith({
    String? wineId,
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
    List<String>? photos,
    DateTime? updatedAt,
    Object? deletedAt = _keep,
  }) {
    T? pick<T>(Object? v, T? current) =>
        identical(v, _keep) ? current : v as T?;
    return TastingNote(
      id: id,
      wineId: wineId ?? this.wineId,
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
      photos: photos ?? this.photos,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: pick<DateTime>(deletedAt, this.deletedAt),
    );
  }
}
