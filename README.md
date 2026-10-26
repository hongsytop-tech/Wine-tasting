# 와인노트 (Wine Tasting)

와인을 검색해 내 셀러에 저장하고, **즐겨찾기 · 평점 · 테이스팅 노트**를 기록하는 Flutter PWA / Android 앱.

구조와 배포 방식은 `Youtube-Filtering`(core 구조, go_router, 행 단위 Supabase 동기화, 자가 업데이트)과
`Mobile-Application-Maker`(외부 데이터용 Supabase Edge Function 프록시 + Postgres 캐시, APK 빌드)를 따릅니다.

## 기능

| 탭 | 기능 |
|---|---|
| 내 와인 | 저장한 와인 목록, **전체 / 즐겨찾기 / 마신 와인** 필터, 최근 수정·최근 시음·평점·이름 정렬, 직접 추가 |
| 검색 | 와인 이름 또는 바코드(EAN/UPC)로 검색 → **마셨어요 · 평가 남기기** / 내 와인에 추가 / 즐겨찾기 |
| 노트 | 전체 테이스팅 노트 — 검색, **국가·지역·생산자·빈티지·품종·종류 필터**(다중 선택), **기준별 모아보기**, 와인을 정하지 않고 **새 노트** 시작 |
| 마이 | 계정, 지금 동기화, 로그아웃, 웹 자동 업데이트 |

- **와인 상세**: 정보, 내 평점(0.5 단위 별점), 즐겨찾기, 메모, 원본 출처 링크
  - **마신 기록**: 마신 횟수, 마지막 시음일, 노트 평균 평점
  - **특징 프로필**: 0~10점 막대 그래프. 노트가 여러 개면 기록된 값의 평균입니다.
- **와인 정보 입력**: 와인 추가·수정 화면과 테이스팅 노트 화면에서 같은 폼을 씁니다.
  - 국가·지역·품종은 목록에서 고릅니다. 한글이나 영문으로 검색할 수 있고, 목록에 없으면 직접 입력합니다.
    - 지역은 선택한 국가의 주요 산지만 보여줍니다. 산지를 먼저 고르면 국가가 자동으로 채워집니다.
    - 기준 목록: `lib/features/wines/models/wine_reference.dart`
  - 생산자는 내 와인에 이미 있는 이름을 자동완성으로 제안합니다.
  - **직접 입력한 값 재사용:** 목록에 없어 직접 입력한 국가·지역·품종(예: California)은 다음 와인 입력 때 검색 목록에 "내가 직접 입력했던 값"으로 나옵니다.
    - 따로 저장하지 않고 내 와인들에서 계산합니다. 그래서 기기 간에 함께 동기화되고, 그 값을 쓰는 와인을 모두 지우면 목록에서도 빠집니다.
    - 직접 입력한 지역은 함께 입력했던 국가를 기억해서, 그 지역을 고르면 국가가 자동으로 채워집니다.
  - **Vivino 평점:** Vivino에서 본 평점(0.0~5.0)을 직접 입력합니다. 평점이 바뀔 수 있어 입력한 날짜를 함께 저장합니다.
    - Vivino 페이지에서 자동으로 가져오지는 않습니다(Vivino 약관이 자동 수집을 금지).
  - **블렌드**: 품종을 여러 개 넣고, 알면 비율(%)도 입력합니다. 합계가 100%가 아니면 경고합니다.
  - 검색 결과의 원산지 텍스트(예: "Bordeaux, France")는 목록과 정확히 일치할 때만 국가·지역으로 나눕니다.
- **테이스팅 노트 = 마신 기록 1회**: WSET 체계적 시음법을 단순화한 구조
  - 화면 순서: **평점 → 총평 → 외관(색)·향·맛 점수** → 와인 정보 → 라벨 사진 → 시음일·페어링·구매가
  - **와인 정보**: 내 와인에서 고르거나 새 와인을 입력합니다. 여기서 고친 정보는 와인에도 반영됩니다. 와인 이름 없이 저장하면 이 칸으로 이동합니다.
  - **라벨 사진**: 카메라(1장)나 앨범(**여러 장 한 번에 선택**)에서 올립니다. 노트당 최대 10장이며 로그인이 필요합니다. Supabase Storage 비공개 버킷에 저장되고, 본인만 볼 수 있습니다.
    - 사진은 긴 변 1600px로 줄여 올립니다.
    - 저장하지 않고 나가거나 사진을 빼거나 노트를 지우면 파일도 삭제합니다.
  - **특징 점수 0~10** (슬라이더, ✕로 "기록 안 함")
    - 외관: 색(옅음↔진함). 색상 이름(루비·가넷 등)은 별도 선택
    - 향: 향 강도(약함↔강함)
    - 맛: 당도(드라이↔스위트), 산미, 타닌, 알코올, 바디, 여운
    - 타닌 입력은 화이트·스파클링에서 숨깁니다.
  - 향·맛 묘사어: 12개 그룹 프리셋에서 고르거나 직접 입력
- 노트가 1개 이상 있는 와인이 "마신 와인"입니다. 따로 상태 값을 두지 않고 노트에서 계산합니다.

## 와인 데이터 출처

조사 결과는 [`docs/DATA_SOURCES.md`](./docs/DATA_SOURCES.md)에 있습니다. 요약하면 다음과 같습니다.

- **Vivino**: 공식 API가 없고, 약관이 자동 접근을 금지합니다. **연동하지 않았습니다.**
- **Wine-Searcher**: 유료 B2B API만 있습니다. 계약하면 `WineSource`로 추가할 수 있게 구조만 열어 두었습니다.
- **Open Food Facts**: 공개 API(ODbL)입니다. **현재 검색 소스입니다.** 와인 전용 정보가 빈약하므로
  "검색해서 추가 → 부족한 정보는 직접 수정" 흐름을 전제로 합니다.

## 아키텍처

- **Flutter Web (PWA)**: GitHub Pages로 배포합니다.
  - `--pwa-strategy none`과 `version-info.json`으로 자가 업데이트합니다.
- **Android APK**: 수동 워크플로우로 빌드합니다.
- **Riverpod** (`StateNotifier` / `Provider`)
- **go_router**: ShellRoute 하단 탭을 쓰고, 상세·편집 화면은 전체 화면으로 띄웁니다.
- **Supabase**: 이메일 인증, Postgres(RLS), Edge Function(Deno)을 씁니다.
- **오프라인 우선 동기화** (`lib/core/sync/synced_repo.dart`)
  - 로컬(shared_preferences)에 즉시 저장하고, 서버에는 best-effort로 upsert합니다.
  - 앱 시작, 로그인, 앱 복귀 시 id별로 `updated_at`이 최신인 쪽을 남기고 병합합니다. 오프라인에서 수정한 내용은 다음 동기화 때 올라갑니다.
  - 삭제는 `deleted_at` soft-delete입니다. 다른 기기의 캐시 때문에 삭제한 항목이 되살아나지 않게 하기 위해서입니다.

### 데이터 모델

| 타입 | 저장 | 테이블 |
|---|---|---|
| `Wine` (셀러·즐겨찾기·내 평점) | 행 단위 `(user_id, id)` | `wines` |
| `TastingNote` | 행 단위 `(user_id, id)` | `tasting_notes` |
| 라벨 사진 | 비공개 버킷, `<user_id>/<note_id>/<uuid>.jpg` | Storage `wine-labels` |
| 검색 결과 캐시 (7일) | service_role 전용 | `wine_search_cache` |

```
lib/
  core/{config,supabase,storage,sync,providers,router,theme,utils}
  features/{auth,wines,search,tasting,settings,update}/{models,services,providers,screens,widgets}
  shell/app_shell.dart · app.dart · main.dart
supabase/
  migrations/0001 ~ 0006 (wines · tasting_notes · 검색 캐시 · 0~10점 · 블렌드·라벨 사진 · Vivino 평점)
  functions/wine-search/{index,openfoodfacts,cache,types}.ts
.github/workflows/{deploy-web,deploy-supabase-function,build-apk,cleanup-artifacts}.yml
web_assets/        # 웹 아이콘(파비콘·PWA·iOS) + 원본 icon.svg — CI가 web/ 에 복사
android_assets/    # 안드로이드 런처 아이콘(mipmap-*) — APK 빌드 시 복사
scripts/generate_icons.mjs  # icon.svg → 위 PNG 전부 생성 (아이콘 바꿀 때만 실행)
```

## 첫 세팅 (직접 하셔야 하는 것)

앱 주소: **https://hongsytop-tech.github.io/Wine-tasting/**

단계별 상세 설명은 [`docs/SETUP.md`](./docs/SETUP.md)에 있습니다. 요약하면 다음과 같습니다.

1. Supabase SQL Editor에서 `supabase/migrations/0001` ~ `0006`을 순서대로 실행합니다.
2. GitHub Secrets에 `SUPABASE_ACCESS_TOKEN`, `SUPABASE_PROJECT_REF`를 등록하고, Actions → **Deploy Supabase Function (wine-search)**를 실행합니다.
3. Supabase Authentication → URL Configuration → Redirect URLs에 앱 주소를 추가합니다.
4. GitHub Secrets에 `SUPABASE_URL`, `SUPABASE_ANON_KEY`를 등록합니다.
5. Actions → **Deploy Web (GitHub Pages)**를 실행합니다.
6. (선택) Actions → **Build Android APK**를 실행하고 Artifact에서 APK를 받습니다.

### 로컬 실행
```bash
cp .env.example .env   # 값 채우기 (비워 두면 로그인 없이 로컬 저장 모드)
flutter create --platforms web,android --project-name wine_tasting .
flutter pub get
flutter run -d chrome
```

## 테스트

```bash
flutter analyze && flutter test                        # 동기화 병합, 모델 직렬화, 0~10 점수·구버전 환산
deno test --allow-env=OFF_USER_AGENT supabase/functions/wine-search/  # Open Food Facts 매핑·바코드 조회
```

## 다음 단계 후보

- [ ] LWIN DB(무료)를 Postgres에 적재해 이름 검색 보강 (라이선스 버전 확인 후)
- [ ] Wine-Searcher API 계약 시 `WineSource` 추가 (평론가 점수·가격)
- [ ] 올린 라벨 사진 → Claude 비전으로 이름·빈티지 추출해 와인 정보 자동 입력
- [ ] 바코드 카메라 스캔 (`mobile_scanner`)
- [ ] 통계: 종류별/국가별 분포, 평점 추이, 마신 와인들의 특징 비교(레이더 차트)
