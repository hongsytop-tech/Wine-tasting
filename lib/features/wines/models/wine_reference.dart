/// 와인 정보 입력용 기준 목록 (국가·주요 산지·품종).
///
/// 저장값은 한글 [RefItem.label]. 영문·현지어 표기는 [RefItem.aliases] 로 두어
/// 검색과 정규화(예: 검색 결과의 "France" → "프랑스")에 쓴다.
/// 목록에 없는 값도 직접 입력할 수 있으므로, 여기에는 널리 알려진 항목만 둔다.
class RefItem {
  const RefItem(this.label, [this.aliases = const []]);

  final String label;
  final List<String> aliases;

  bool matches(String query) {
    final q = foldText(query);
    if (q.isEmpty) return true;
    return foldText(label).contains(q) ||
        aliases.any((a) => foldText(a).contains(q));
  }

  bool isExactly(String value) {
    final v = foldText(value);
    return foldText(label) == v || aliases.any((a) => foldText(a) == v);
  }
}

enum GrapeColor { red, white }

class GrapeRef extends RefItem {
  const GrapeRef(super.label, this.color, [super.aliases]);

  final GrapeColor color;
}

/// 비교용 정규화: 소문자, 공백·하이픈·구두점 제거, 악센트 제거.
String foldText(String s) {
  const accents = {
    'à': 'a',
    'á': 'a',
    'â': 'a',
    'ä': 'a',
    'ã': 'a',
    'å': 'a',
    'è': 'e',
    'é': 'e',
    'ê': 'e',
    'ë': 'e',
    'ì': 'i',
    'í': 'i',
    'î': 'i',
    'ï': 'i',
    'ò': 'o',
    'ó': 'o',
    'ô': 'o',
    'ö': 'o',
    'õ': 'o',
    'ù': 'u',
    'ú': 'u',
    'û': 'u',
    'ü': 'u',
    'ñ': 'n',
    'ç': 'c',
    'ß': 'ss',
  };
  final b = StringBuffer();
  for (final ch in s.toLowerCase().split('')) {
    final c = accents[ch] ?? ch;
    if (_ignored.hasMatch(c)) continue;
    b.write(c);
  }
  return b.toString();
}

final _ignored = RegExp(r"[\s\-_.,'’·/()]");

class WineReference {
  WineReference._();

  static const countries = <RefItem>[
    RefItem('프랑스', ['France', 'Francia']),
    RefItem('이탈리아', ['Italy', 'Italia']),
    RefItem('스페인', ['Spain', 'España', 'Espana']),
    RefItem('포르투갈', ['Portugal']),
    RefItem('독일', ['Germany', 'Deutschland']),
    RefItem('오스트리아', ['Austria', 'Österreich']),
    RefItem('그리스', ['Greece']),
    RefItem('헝가리', ['Hungary']),
    RefItem('미국', ['United States', 'USA', 'US', 'America']),
    RefItem('캐나다', ['Canada']),
    RefItem('칠레', ['Chile']),
    RefItem('아르헨티나', ['Argentina']),
    RefItem('호주', ['Australia']),
    RefItem('뉴질랜드', ['New Zealand']),
    RefItem('남아프리카공화국', ['South Africa', '남아공']),
    RefItem('조지아', ['Georgia']),
    RefItem('레바논', ['Lebanon']),
    RefItem('이스라엘', ['Israel']),
    RefItem('슬로베니아', ['Slovenia']),
    RefItem('크로아티아', ['Croatia']),
    RefItem('루마니아', ['Romania']),
    RefItem('몰도바', ['Moldova']),
    RefItem('스위스', ['Switzerland']),
    RefItem('영국', ['United Kingdom', 'UK', 'England']),
    RefItem('우루과이', ['Uruguay']),
    RefItem('브라질', ['Brazil']),
    RefItem('멕시코', ['Mexico']),
    RefItem('중국', ['China']),
    RefItem('일본', ['Japan']),
    RefItem('한국', ['South Korea', 'Korea']),
  ];

  /// 국가(한글 라벨) → 주요 산지.
  static const regionsByCountry = <String, List<RefItem>>{
    '프랑스': [
      RefItem('보르도', ['Bordeaux']),
      RefItem('부르고뉴', ['Bourgogne', 'Burgundy']),
      RefItem('샹파뉴', ['Champagne']),
      RefItem('론', ['Rhône', 'Rhone', 'Rhône Valley']),
      RefItem('루아르', ['Loire', 'Loire Valley']),
      RefItem('알자스', ['Alsace']),
      RefItem('랑그독-루시용', ['Languedoc-Roussillon', 'Languedoc']),
      RefItem('프로방스', ['Provence']),
      RefItem('보졸레', ['Beaujolais']),
      RefItem('쥐라', ['Jura']),
      RefItem('사부아', ['Savoie']),
      RefItem('남서부', ['Sud-Ouest', 'South West France']),
      RefItem('코르시카', ['Corse', 'Corsica']),
    ],
    '이탈리아': [
      RefItem('피에몬테', ['Piemonte', 'Piedmont']),
      RefItem('토스카나', ['Toscana', 'Tuscany']),
      RefItem('베네토', ['Veneto']),
      RefItem('시칠리아', ['Sicilia', 'Sicily']),
      RefItem('풀리아', ['Puglia', 'Apulia']),
      RefItem('캄파니아', ['Campania']),
      RefItem('롬바르디아', ['Lombardia', 'Lombardy']),
      RefItem('트렌티노-알토 아디제', ['Trentino-Alto Adige']),
      RefItem('프리울리-베네치아 줄리아', ['Friuli-Venezia Giulia', 'Friuli']),
      RefItem('아브루초', ['Abruzzo']),
      RefItem('사르데냐', ['Sardegna', 'Sardinia']),
      RefItem('마르케', ['Marche']),
      RefItem('움브리아', ['Umbria']),
    ],
    '스페인': [
      RefItem('리오하', ['Rioja']),
      RefItem('리베라 델 두에로', ['Ribera del Duero']),
      RefItem('프리오랏', ['Priorat']),
      RefItem('리아스 바이사스', ['Rías Baixas', 'Rias Baixas']),
      RefItem('페네데스', ['Penedès', 'Penedes']),
      RefItem('헤레스', ['Jerez', 'Sherry']),
      RefItem('토로', ['Toro']),
      RefItem('루에다', ['Rueda']),
      RefItem('라 만차', ['La Mancha']),
      RefItem('후미야', ['Jumilla']),
      RefItem('나바라', ['Navarra']),
    ],
    '포르투갈': [
      RefItem('도우루', ['Douro']),
      RefItem('알렌테주', ['Alentejo']),
      RefItem('비뉴 베르드', ['Vinho Verde']),
      RefItem('다웅', ['Dão', 'Dao']),
      RefItem('마데이라', ['Madeira']),
      RefItem('바이하다', ['Bairrada']),
      RefItem('리스보아', ['Lisboa']),
    ],
    '독일': [
      RefItem('모젤', ['Mosel']),
      RefItem('라인가우', ['Rheingau']),
      RefItem('팔츠', ['Pfalz']),
      RefItem('라인헤센', ['Rheinhessen']),
      RefItem('나헤', ['Nahe']),
      RefItem('바덴', ['Baden']),
      RefItem('프랑켄', ['Franken']),
    ],
    '오스트리아': [
      RefItem('바하우', ['Wachau']),
      RefItem('캄프탈', ['Kamptal']),
      RefItem('크렘스탈', ['Kremstal']),
      RefItem('부르겐란트', ['Burgenland']),
      RefItem('바인피어텔', ['Weinviertel']),
    ],
    '미국': [
      RefItem('나파 밸리', ['Napa Valley', 'Napa']),
      RefItem('소노마', ['Sonoma']),
      RefItem('파소 로블레스', ['Paso Robles']),
      RefItem('산타 바바라', ['Santa Barbara']),
      RefItem('로다이', ['Lodi']),
      RefItem('윌래밋 밸리', ['Willamette Valley']),
      RefItem('워싱턴', ['Washington', 'Washington State']),
      RefItem('핑거 레이크스', ['Finger Lakes']),
    ],
    '칠레': [
      RefItem('마이포 밸리', ['Maipo Valley', 'Maipo']),
      RefItem('콜차과 밸리', ['Colchagua Valley', 'Colchagua']),
      RefItem('카사블랑카 밸리', ['Casablanca Valley', 'Casablanca']),
      RefItem('카차포알 밸리', ['Cachapoal Valley', 'Cachapoal']),
      RefItem('아콩카과', ['Aconcagua']),
      RefItem('쿠리코', ['Curicó', 'Curico']),
      RefItem('마울레', ['Maule']),
      RefItem('이타타', ['Itata']),
      RefItem('비오비오', ['Bío-Bío', 'Bio Bio']),
    ],
    '아르헨티나': [
      RefItem('멘도사', ['Mendoza']),
      RefItem('우코 밸리', ['Uco Valley', 'Valle de Uco']),
      RefItem('살타', ['Salta']),
      RefItem('산 후안', ['San Juan']),
      RefItem('파타고니아', ['Patagonia']),
    ],
    '호주': [
      RefItem('바로사 밸리', ['Barossa Valley', 'Barossa']),
      RefItem('맥라렌 베일', ['McLaren Vale']),
      RefItem('쿠나와라', ['Coonawarra']),
      RefItem('클레어 밸리', ['Clare Valley']),
      RefItem('에덴 밸리', ['Eden Valley']),
      RefItem('애들레이드 힐스', ['Adelaide Hills']),
      RefItem('헌터 밸리', ['Hunter Valley']),
      RefItem('야라 밸리', ['Yarra Valley']),
      RefItem('마가렛 리버', ['Margaret River']),
      RefItem('태즈메이니아', ['Tasmania']),
    ],
    '뉴질랜드': [
      RefItem('말보로', ['Marlborough']),
      RefItem('센트럴 오타고', ['Central Otago']),
      RefItem('호크스 베이', ["Hawke's Bay", 'Hawkes Bay']),
      RefItem('마틴버러', ['Martinborough']),
      RefItem('넬슨', ['Nelson']),
      RefItem('기즈번', ['Gisborne']),
    ],
    '남아프리카공화국': [
      RefItem('스텔렌보스', ['Stellenbosch']),
      RefItem('팔', ['Paarl']),
      RefItem('콘스탄시아', ['Constantia']),
      RefItem('스와트랜드', ['Swartland']),
      RefItem('프란슈후크', ['Franschhoek']),
      RefItem('워커 베이', ['Walker Bay']),
    ],
  };

  static const grapes = <GrapeRef>[
    // 적포도
    GrapeRef('카베르네 소비뇽', GrapeColor.red, ['Cabernet Sauvignon']),
    GrapeRef('메를로', GrapeColor.red, ['Merlot', '멀롯']),
    GrapeRef('피노 누아', GrapeColor.red, ['Pinot Noir', 'Spätburgunder']),
    GrapeRef('시라', GrapeColor.red, ['Syrah', 'Shiraz', '쉬라즈']),
    GrapeRef('그르나슈', GrapeColor.red, ['Grenache', 'Garnacha', '가르나차']),
    GrapeRef('템프라니요', GrapeColor.red, ['Tempranillo', 'Tinta Roriz']),
    GrapeRef('산지오베제', GrapeColor.red, ['Sangiovese']),
    GrapeRef('네비올로', GrapeColor.red, ['Nebbiolo']),
    GrapeRef('말벡', GrapeColor.red, ['Malbec', 'Côt', 'Cot']),
    GrapeRef('카베르네 프랑', GrapeColor.red, ['Cabernet Franc']),
    GrapeRef('진판델', GrapeColor.red, ['Zinfandel', 'Primitivo', '프리미티보']),
    GrapeRef('카르메네르', GrapeColor.red, ['Carménère', 'Carmenere', '까르메네르']),
    GrapeRef('피노타주', GrapeColor.red, ['Pinotage']),
    GrapeRef('가메', GrapeColor.red, ['Gamay']),
    GrapeRef('무르베드르', GrapeColor.red, ['Mourvèdre', 'Monastrell', '모나스트렐']),
    GrapeRef('바르베라', GrapeColor.red, ['Barbera']),
    GrapeRef('돌체토', GrapeColor.red, ['Dolcetto']),
    GrapeRef('몬테풀치아노', GrapeColor.red, ['Montepulciano']),
    GrapeRef('네로 다볼라', GrapeColor.red, ["Nero d'Avola"]),
    GrapeRef('알리아니코', GrapeColor.red, ['Aglianico']),
    GrapeRef('투리가 나시오날', GrapeColor.red, ['Touriga Nacional']),
    GrapeRef('쁘띠 베르도', GrapeColor.red, ['Petit Verdot', '프티 베르도']),
    GrapeRef('카리냥', GrapeColor.red, ['Carignan', 'Cariñena', 'Carignano']),
    GrapeRef('생소', GrapeColor.red, ['Cinsault', 'Cinsaut']),
    GrapeRef('블라우프랭키쉬', GrapeColor.red, ['Blaufränkisch', 'Lemberger']),
    GrapeRef('츠바이겔트', GrapeColor.red, ['Zweigelt']),
    GrapeRef('코르비나', GrapeColor.red, ['Corvina']),
    GrapeRef('타나', GrapeColor.red, ['Tannat']),
    GrapeRef('쁘띠 시라', GrapeColor.red, ['Petite Sirah', 'Durif']),
    GrapeRef('피노 뫼니에', GrapeColor.red, ['Pinot Meunier', 'Meunier']),
    // 청포도
    GrapeRef('샤르도네', GrapeColor.white, ['Chardonnay', '샤도네이']),
    GrapeRef('소비뇽 블랑', GrapeColor.white, ['Sauvignon Blanc']),
    GrapeRef('리슬링', GrapeColor.white, ['Riesling']),
    GrapeRef(
        '피노 그리', GrapeColor.white, ['Pinot Gris', 'Pinot Grigio', '피노 그리지오']),
    GrapeRef('슈냉 블랑', GrapeColor.white, ['Chenin Blanc', 'Steen']),
    GrapeRef(
        '게뷔르츠트라미너', GrapeColor.white, ['Gewürztraminer', 'Gewurztraminer']),
    GrapeRef('비오니에', GrapeColor.white, ['Viognier']),
    GrapeRef('세미용', GrapeColor.white, ['Sémillon', 'Semillon']),
    GrapeRef(
        '뮈스카', GrapeColor.white, ['Muscat', 'Moscato', 'Moscatel', '모스카토']),
    GrapeRef(
        '그뤼너 벨트리너', GrapeColor.white, ['Grüner Veltliner', 'Gruner Veltliner']),
    GrapeRef('알바리뇨', GrapeColor.white, ['Albariño', 'Albarino', 'Alvarinho']),
    GrapeRef('베르데호', GrapeColor.white, ['Verdejo']),
    GrapeRef('마르산', GrapeColor.white, ['Marsanne']),
    GrapeRef('루산', GrapeColor.white, ['Roussanne']),
    GrapeRef('피노 블랑', GrapeColor.white, ['Pinot Blanc', 'Pinot Bianco']),
    GrapeRef('뮐러 투르가우', GrapeColor.white, ['Müller-Thurgau', 'Muller Thurgau']),
    GrapeRef('트레비아노', GrapeColor.white, ['Trebbiano', 'Ugni Blanc', '위니 블랑']),
    GrapeRef('베르멘티노', GrapeColor.white, ['Vermentino', 'Rolle']),
    GrapeRef('가르가네가', GrapeColor.white, ['Garganega']),
    GrapeRef('코르테제', GrapeColor.white, ['Cortese']),
    GrapeRef('글레라', GrapeColor.white, ['Glera', 'Prosecco']),
    GrapeRef('토론테스', GrapeColor.white, ['Torrontés', 'Torrontes']),
    GrapeRef('아시르티코', GrapeColor.white, ['Assyrtiko']),
    GrapeRef('푸르민트', GrapeColor.white, ['Furmint']),
    GrapeRef('마카베오', GrapeColor.white, ['Macabeo', 'Viura']),
    GrapeRef('파레야다', GrapeColor.white, ['Parellada']),
    GrapeRef('자렐로', GrapeColor.white, ['Xarel·lo', 'Xarello']),
    GrapeRef('피아노', GrapeColor.white, ['Fiano']),
    GrapeRef('믈롱 드 부르고뉴', GrapeColor.white,
        ['Melon de Bourgogne', 'Muscadet', '뮈스카데']),
    GrapeRef('실바너', GrapeColor.white, ['Silvaner', 'Sylvaner']),
  ];

  static List<RefItem> regionsFor(String country) =>
      regionsByCountry[canonicalCountry(country)] ?? const [];

  static List<RefItem> get allRegions =>
      regionsByCountry.values.expand((e) => e).toList(growable: false);

  /// 목록의 항목과 정확히 일치하면 한글 라벨로, 아니면 입력값 그대로(공백 정리).
  static String canonicalCountry(String v) => _canonical(countries, v);

  static String canonicalRegion(String v) => _canonical(allRegions, v);

  static String canonicalGrape(String v) => _canonical(grapes, v);

  /// 산지 라벨/별칭 → 그 산지가 속한 국가 라벨. 모르면 null.
  static String? countryOfRegion(String region) {
    for (final e in regionsByCountry.entries) {
      if (e.value.any((r) => r.isExactly(region))) return e.key;
    }
    return null;
  }

  /// 검색 결과의 원산지 텍스트(예: "Bordeaux, France", "France")를 국가·지역으로
  /// 나눈다. 목록과 정확히 일치하는 부분만 인식하고, 인식 못 한 텍스트는 지역에 남긴다.
  static ({String country, String region}) parseOrigin(
    String country,
    String region,
  ) {
    var c = canonicalCountry(country);
    var r = '';
    final leftovers = <String>[];
    for (final part in region.split(RegExp(r'[,/;]'))) {
      final t = part.trim();
      if (t.isEmpty) continue;
      if (countries.any((x) => x.isExactly(t))) {
        if (c.isEmpty) c = canonicalCountry(t);
      } else if (allRegions.any((x) => x.isExactly(t))) {
        if (r.isEmpty) r = canonicalRegion(t);
        c = c.isEmpty ? (countryOfRegion(t) ?? '') : c;
      } else {
        leftovers.add(t);
      }
    }
    if (r.isEmpty) r = leftovers.join(', ');
    return (country: c, region: r);
  }

  static String _canonical(List<RefItem> items, String v) {
    final t = v.trim();
    if (t.isEmpty) return t;
    for (final i in items) {
      if (i.isExactly(t)) return i.label;
    }
    return t;
  }
}
