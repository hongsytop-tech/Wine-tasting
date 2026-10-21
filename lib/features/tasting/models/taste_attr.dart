import '../../wines/models/wine_type.dart';
import 'tasting_note.dart';

/// 0~10 점으로 기록하는 와인 특징. 노트 편집·프로필 표시가 모두 이 목록을 쓴다.
/// [low] / [high] 는 0점·10점 쪽 끝 설명.
enum TasteAttr {
  colorIntensity('색', '옅음', '진함'),
  aromaIntensity('향', '약함', '강함'),
  sweetness('당도', '드라이', '스위트'),
  acidity('산미', '낮음', '높음'),
  tannin('타닌', '낮음', '높음'),
  alcohol('알코올', '낮음', '높음'),
  body('바디', '가벼움', '무거움'),
  finish('여운', '짧음', '긺');

  const TasteAttr(this.label, this.low, this.high);

  final String label;
  final String low;
  final String high;

  static const maxScore = 10;

  int? of(TastingNote n) {
    switch (this) {
      case TasteAttr.colorIntensity:
        return n.colorIntensity;
      case TasteAttr.aromaIntensity:
        return n.aromaIntensity;
      case TasteAttr.sweetness:
        return n.sweetness;
      case TasteAttr.acidity:
        return n.acidity;
      case TasteAttr.tannin:
        return n.tannin;
      case TasteAttr.alcohol:
        return n.alcohol;
      case TasteAttr.body:
        return n.body;
      case TasteAttr.finish:
        return n.finish;
    }
  }

  /// 타닌은 레드 계열에서 주로 평가하므로 화이트·스파클링에서는 입력란을 숨긴다
  /// (이미 기록된 값은 그대로 표시).
  bool appliesTo(WineType t) =>
      this != TasteAttr.tannin ||
      (t != WineType.white && t != WineType.sparkling);

  /// 맛(Palate) 항목.
  static const palate = [sweetness, acidity, tannin, alcohol, body, finish];
}

/// 여러 노트의 특징 점수 평균 (기록된 값만 평균, 하나도 없으면 키 없음).
Map<TasteAttr, double> averageProfile(Iterable<TastingNote> notes) {
  final out = <TasteAttr, double>{};
  for (final a in TasteAttr.values) {
    final vs = [for (final n in notes) a.of(n)].whereType<int>().toList();
    if (vs.isNotEmpty) out[a] = vs.reduce((x, y) => x + y) / vs.length;
  }
  return out;
}

/// 정수면 "7", 아니면 "6.5".
String scoreText(num v) =>
    v == v.roundToDouble() ? '${v.round()}' : v.toStringAsFixed(1);
