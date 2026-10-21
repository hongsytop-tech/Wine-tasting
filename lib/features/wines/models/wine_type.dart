/// 와인 종류. 저장값은 [name] (영문) — 앱과 Edge Function 이 같은 값을 쓴다.
enum WineType {
  red('레드'),
  white('화이트'),
  rose('로제'),
  sparkling('스파클링'),
  dessert('디저트'),
  fortified('주정강화'),
  other('기타');

  const WineType(this.label);
  final String label;

  static WineType parse(String? v) {
    for (final t in WineType.values) {
      if (t.name == v) return t;
    }
    return WineType.other;
  }
}
