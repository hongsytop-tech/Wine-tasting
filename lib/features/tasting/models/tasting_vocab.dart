import '../../wines/models/wine_type.dart';

/// 테이스팅 노트 입력용 선택지. 저장값 = 화면에 보이는 한글 라벨.
class TastingVocab {
  TastingVocab._();

  /// 종류별 외관 색상 선택지 (WSET 색상 용어 기준).
  static List<String> colorsFor(WineType type) {
    switch (type) {
      case WineType.red:
        return const ['퍼플', '루비', '가넷', '토니', '브라운'];
      case WineType.rose:
        return const ['핑크', '살몬', '오렌지'];
      case WineType.white:
      case WineType.sparkling:
        return const ['레몬', '골드', '앰버', '브라운'];
      case WineType.dessert:
      case WineType.fortified:
      case WineType.other:
        return const [
          '레몬',
          '골드',
          '앰버',
          '핑크',
          '살몬',
          '루비',
          '가넷',
          '토니',
          '브라운',
        ];
    }
  }

  /// 향/맛 묘사어 (그룹 → 묘사어).
  static const aromaGroups = <String, List<String>>{
    '시트러스': ['레몬', '라임', '자몽', '오렌지 껍질'],
    '녹색/핵과': ['청사과', '배', '복숭아', '살구', '멜론'],
    '열대과일': ['파인애플', '망고', '패션프루트', '리치', '바나나'],
    '붉은 과일': ['딸기', '라즈베리', '체리', '크랜베리', '석류'],
    '검은 과일': ['블랙베리', '블랙커런트', '블루베리', '자두', '블랙체리'],
    '말린 과일': ['건포도', '무화과', '건자두', '대추'],
    '꽃': ['장미', '제비꽃', '아카시아', '오렌지꽃', '라벤더'],
    '허브/식물': ['풀', '피망', '민트', '유칼립투스', '토마토잎', '건초'],
    '향신료': ['후추', '감초', '정향', '시나몬', '바닐라', '팔각'],
    '오크/숙성': ['토스트', '스모크', '커피', '초콜릿', '캐러멜', '삼나무', '코코넛'],
    '효모/숙성': ['브리오슈', '비스킷', '버터', '견과류', '꿀'],
    '흙/미네랄': ['흙', '버섯', '가죽', '담배', '젖은 돌', '부싯돌', '석유'],
  };
}
