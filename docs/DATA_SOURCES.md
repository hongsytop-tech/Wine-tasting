# 와인 데이터 연동 가능성 조사 (Wine-Searcher · Vivino · 대안)

조사일: 2026-10-21

> **조사 한계**: 조사 환경의 네트워크 정책 때문에 wine-searcher.com · vivino.com ·
> openfoodfacts.org 페이지를 직접 열지 못했습니다. 아래 내용은 웹 검색엔진이 색인한
> **공식 페이지 발췌**가 근거입니다. 확인하지 못한 항목은 **미확인**으로 표시했습니다.
> 가격과 약관 같은 수치는 계약이나 출시 전에 각 링크를 직접 열어 다시 확인해야 합니다.

## 결론 요약

| 소스 | 공식 API | 앱에 반영 여부 | 이유 |
|---|---|---|---|
| **Open Food Facts** | 있음, 무료 | ✅ **구현됨** (`wine-search` 함수) | 공개 API, ODbL 라이선스. 다만 와인 전용 필드가 빈약함 |
| **Wine-Searcher** | 있음, **유료 B2B** | ⏸ 미구현 (계약하면 추가 가능) | 평점·가격을 합법적으로 받는 거의 유일한 경로. 약관상 스크래핑 금지 |
| **Vivino** | **없음** | ❌ 넣지 않음 | 약관이 자동 접근(스크래핑, 봇)을 명시적으로 금지 |
| **LWIN (Liv-ex)** | DB 무료 다운로드 | ⏸ 다음 단계 후보 | 와인 식별 정보(생산자·이름·색·지역) 20만여 건. 평점·가격·이미지 없음 |

## 1. Wine-Searcher

- **공식 API가 있습니다.** 업계(trade)용 유료 상품입니다.
  - https://www.wine-searcher.com/trade/api
  - 문서: https://www.wine-searcher.com/trade/ws-api
- 상품과 가격은 검색 발췌 기준입니다. 공식 페이지를 직접 열어 확인하지는 못했습니다.
  - **Wine Check API**: 월 $335부터, 하루 500회 호출
  - **Market Price API**: 월 $350부터, 하루 1,000회 호출
  - 5일 무료 체험이 있습니다.
- 호출 방식: REST GET에 `api_key`, `winename`, 선택값 `vintage`를 보냅니다. 응답은 XML 또는 JSON입니다.
- Wine Check가 반환하는 정보: 평론가 점수 집계, 지역, 품종, 최저·최고·평균가, 알코올 도수.
- Market Price가 반환하는 정보: 최저가 순으로 판매처와 가격 최대 24곳.
- 라벨 이미지를 반환하는지는 **미확인**입니다.
- 개인 개발자도 가입할 수 있는지, API 데이터의 캐싱이나 표시 의무가 있는지는 **미확인**입니다.
- **스크래핑은 약관 위반입니다.**
  - https://www.wine-searcher.com/user-terms : robot·spider·scraper 등으로 접근하는 것을 금지합니다.
  - https://www.wine-searcher.com/policies : 자동 질의 소프트웨어로 데이터를 수집하는 것을 허가하지 않는다고 명시합니다.

**앱에 붙이는 방법**: `supabase/functions/wine-search/types.ts`의 `WineSource` 인터페이스로
`wineSearcher.ts`를 추가하고, API 키는 Supabase secret(`WINE_SEARCHER_API_KEY`)으로 둡니다.
응답 필드 이름은 계약 후 받는 실제 문서를 보고 매핑해야 합니다. 지금 추측으로 작성하지 않았습니다.

## 2. Vivino

- **공식 공개 API는 없습니다.** 공식 개발자 포털을 찾지 못했습니다.
  아래 제3자 출처도 모두 "공식 API 없음"으로 적고 있습니다.
  - https://apis.io/providers/vivino/
  - https://apify.com/mrbridge/vivino-wine-data-scraper
- **약관이 자동 접근을 금지합니다.**
  - https://www.vivino.com/legal/terms-of-service : 명시적 허가가 없으면 자동화 수단, 스크래핑 도구, 크롤러, 봇으로 접근할 수 없습니다. rate limit 우회도 금지입니다.
  - 구 약관 https://www.vivino.com/terms 도 같은 취지입니다.
- 비공식 내부 엔드포인트는 존재합니다. 오픈소스 `vivino-mcp`가 문서화했습니다. https://pypi.org/project/vivino-mcp/
  - 엔드포인트: `/api/explore/explore`, `/api/vintages/{id}`, `/api/wines/{id}/tastes`, `/api/wines/{id}/reviews`
  - 다만 이 패키지의 작성자도 "공식 API가 아니고 예고 없이 바뀔 수 있으니 약관을 준수하라"고 경고합니다.
  - explore에는 자유 텍스트 검색 파라미터가 없습니다. 이름 검색 경로는 **미확인**입니다.
- 머천트 입점과 어필리에이트 프로그램은 판매자용이며 데이터 API가 아닙니다. https://vivino.com/merchants/signup

**판단**: 앱에 Vivino 연동을 넣지 않았습니다. 비공식 엔드포인트를 쓰면 약관 위반이고,
엔드포인트가 언제든 막힐 수 있어 유지보수 리스크도 큽니다.
대신 와인 상세 화면에서 원본 페이지 링크를 여는 방식(사용자가 직접 방문)은 문제없습니다.

## 3. 합법적 대안

| 소스 | 접근 | 데이터 | 라이선스·조건 |
|---|---|---|---|
| Open Food Facts | 공개 API, 키 불필요 | 바코드, 제품명, 브랜드, 사진. 와인 카테고리 약 1.2만 건(집계 시점 불명) | DB는 ODbL, 사진은 CC BY-SA. **출처 표시 필수** — https://world.openfoodfacts.org/terms-of-use |
| LWIN (Liv-ex) | DB 무료 다운로드 | 생산자, 와인명, 색, 지역, 식별코드 | Creative Commons(버전 **미확인**) — https://www.liv-ex.com/lwin-database-download/ |
| db.wine (Global Wine Database) | 문의 후 API 제공 | 생산자가 입력한 와인 정보 | 가격·조건 미공개 — https://www.db.wine/ |
| Wine.com API | 2009년 공개 | — | 현재 운영 여부 **미확인** |
| 네이버 쇼핑 검색 API | — | 상품명, 최저가, 이미지 | 2026-07-31 종료 보고(제3자 출처). **공식 확인 필요** |
| 와인21 / 와인나라 | 공개 API 못 찾음 | — | 제휴 문의 필요 |

### Open Food Facts의 한계 (현재 구현 기준)

- 사용자가 기여한 데이터입니다. 국내 수입 와인은 등록이 안 되어 있거나 정보가 비어 있는 경우가 많을 수 있습니다. 실제 커버리지는 측정하지 않았습니다.
- 품종, 산지, 빈티지를 담는 체계적인 필드가 없습니다. 그래서 구현에서는 다음 원칙을 따랐습니다.
  - `countries_tags`는 **판매 국가**이지 원산지가 아닙니다. 사용하지 않습니다.
  - 빈티지는 제품명에 4자리 연도가 그대로 적혀 있을 때만 추출합니다.
  - 평점과 가격은 제공되지 않습니다.
- 그래서 앱은 **"검색해서 추가 → 부족한 정보는 직접 수정"** 흐름을 전제로 합니다.

## 4. 라벨 사진 인식 (선택 기능 후보)

- Vivino와 Wine-Searcher의 라벨 스캔은 각 사의 소비자 앱 기능입니다. 외부 개발자용 API는 찾지 못했습니다(**미확인**).
- **LLM 비전**(예: Claude API)으로 라벨 사진에서 이름, 생산자, 빈티지 텍스트를 뽑아
  검색어로 쓰는 방식은 기술적으로 가능합니다. Youtube-Filtering의 `tag-feed`처럼 Edge Function에서
  `ANTHROPIC_API_KEY`로 호출하는 구조입니다. 인식 정확도는 측정하지 않았습니다.
- TinEye WineEngine은 상용 라벨 매칭 API입니다. 다만 매칭 대상이 "내가 등록한 라벨 컬렉션"이고, 가격은 **미확인**입니다.
  https://help.tineye.com/article/201-what-is-wineengine
