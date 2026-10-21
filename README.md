# 와인노트 (Wine Tasting)

와인을 검색해 내 셀러에 저장하고, **즐겨찾기 · 평점 · 테이스팅 노트**를 기록하는 Flutter PWA / Android 앱.

구조와 배포 방식은 `Youtube-Filtering`(core 구조, go_router, 행 단위 Supabase 동기화, 자가 업데이트)과
`Mobile-Application-Maker`(외부 데이터용 Supabase Edge Function 프록시 + Postgres 캐시, APK 빌드)를 따릅니다.

## 기능

| 탭 | 기능 |
|---|---|
| 내 와인 | 저장한 와인 목록, 전체/즐겨찾기 필터, 최근·평점·이름 정렬, 직접 추가 |
| 검색 | 와인 이름 또는 바코드(EAN/UPC)로 검색 → 내 와인에 추가 / 즐겨찾기 |
| 노트 | 전체 테이스팅 노트 (시음일 최신순) |
| 마이 | 계정, 지금 동기화, 로그아웃, 웹 자동 업데이트 |

- **와인 상세**: 정보, 내 평점(0.5 단위 별점), 즐겨찾기, 메모, 원본 출처 링크, 해당 와인의 노트 목록
- **테이스팅 노트**: WSET 체계적 시음법을 단순화한 구조
  - 날짜·장소·동석자, 이번 시음 평점
  - 외관: 색상, 농도
  - 향: 강도, 묘사어
  - 맛: 당도, 산도, 타닌, 알코올, 바디, 여운(1~5), 풍미
  - 결론: 페어링, 구매가, 총평
  - 묘사어는 12개 그룹 프리셋 중에서 고르거나 직접 입력합니다.

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
| 검색 결과 캐시 (7일) | service_role 전용 | `wine_search_cache` |

```
lib/
  core/{config,supabase,storage,sync,providers,router,theme,utils}
  features/{auth,wines,search,tasting,settings,update}/{models,services,providers,screens,widgets}
  shell/app_shell.dart · app.dart · main.dart
supabase/
  migrations/0001_wines.sql · 0002_tasting_notes.sql · 0003_wine_search_cache.sql
  functions/wine-search/{index,openfoodfacts,cache,types}.ts
.github/workflows/{deploy-web,build-apk,cleanup-artifacts}.yml
```

## 첫 세팅 체크리스트 (직접 하셔야 하는 것)

### A. Supabase
1. 프로젝트를 만들고 `SUPABASE_URL`과 `anon key`를 확보합니다.
2. SQL Editor에서 `supabase/migrations/000*.sql`을 순서대로 실행합니다.
   - 404 PGRST205가 나면 `NOTIFY pgrst, 'reload schema';`를 실행합니다.
3. Edge Function `wine-search`를 배포합니다. `supabase functions deploy wine-search`로 하거나, 대시보드에 4개 파일을 붙여넣습니다.
4. (선택) Secret `OFF_USER_AGENT`에 앱 이름과 연락처를 넣습니다. Open Food Facts가 식별 가능한 User-Agent를 요청하기 때문입니다.

### B. GitHub
1. 저장소 Secrets에 `SUPABASE_URL`, `SUPABASE_ANON_KEY`를 등록합니다.
2. Settings → Pages → Source를 **GitHub Actions**로 바꿉니다.
3. `main`이나 `claude/**`에 push하면 자동 배포됩니다.
   - 배포 주소는 `https://<owner>.github.io/<repo>/`입니다.
4. APK가 필요하면 Actions → **Build Android APK** → Run workflow를 실행합니다. 결과는 Artifact로 내려받습니다.
   - 서명 키를 설정하지 않으면 debug 키로 서명됩니다.

### 로컬 실행
```bash
cp .env.example .env   # 값 채우기 (비워 두면 로그인 없이 로컬 저장 모드)
flutter create --platforms web,android --project-name wine_tasting .
flutter pub get
flutter run -d chrome
```

## 테스트

```bash
flutter analyze && flutter test                        # 동기화 병합 로직, 모델 직렬화
deno test supabase/functions/wine-search/              # Open Food Facts 매핑
```

## 다음 단계 후보

- [ ] LWIN DB(무료)를 Postgres에 적재해 이름 검색 보강 (라이선스 버전 확인 후)
- [ ] Wine-Searcher API 계약 시 `WineSource` 추가 (평론가 점수·가격)
- [ ] 라벨 사진 → Claude 비전으로 텍스트 추출 → 검색어 자동 입력
- [ ] 바코드 카메라 스캔 (`mobile_scanner`)
- [ ] 통계: 종류별/국가별 분포, 평점 추이
- [ ] 앱 아이콘·브랜딩 이미지 (현재 Flutter 기본 아이콘)
