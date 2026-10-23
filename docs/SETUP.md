# 와인노트 백엔드 설정 가이드 (검색·로그인·동기화)

앱 주소: **https://hongsytop-tech.github.io/Wine-tasting/**

이 가이드를 마치기 전에는 앱이 "로그인 없이 기기에만 저장하는 모드"로 동작합니다. 검색은 되지 않습니다.
아래 순서대로 진행합니다. 0~3단계는 Supabase, 4~5단계는 GitHub에서 합니다.

> Supabase 대시보드 메뉴 이름은 버전에 따라 조금 다를 수 있습니다. 비슷한 이름의 메뉴를 찾으면 됩니다.

---

## 0단계. Supabase 프로젝트 정하기

### 새 프로젝트를 쓸 때
1. https://supabase.com/dashboard → **New project**를 누릅니다.
2. 이름(예: `wine-tasting`)과 **Database Password**를 입력합니다. 비밀번호는 따로 보관해 두세요.
3. Region은 **Northeast Asia (Seoul)**을 고릅니다.
4. 생성이 끝날 때까지 1~2분 기다립니다.

### 다른 앱(Youtube-Filtering, Mobile-Application-Maker)의 프로젝트를 같이 쓸 때
- 이 앱의 테이블(`wines`, `tasting_notes`, `wine_search_cache`)은 두 앱의 테이블과 이름이 겹치지 않습니다.
- **로그인 계정은 공유됩니다.** 같은 이메일로 세 앱에 모두 로그인하게 됩니다.
- 3단계에서 **Site URL은 바꾸지 말고**, Redirect URLs에 이 앱 주소만 추가하세요. Site URL을 바꾸면 다른 앱의 인증 메일 링크가 이 앱으로 오게 됩니다.

---

## 1단계. SQL 4개 실행 (테이블 만들기)

1. 대시보드 왼쪽 메뉴에서 **SQL Editor** → **New query**를 엽니다.
2. 아래 파일을 **순서대로** 하나씩 처리합니다.
   - 파일 링크를 열고 오른쪽 위 **Copy raw file**(복사 아이콘)을 누릅니다.
   - 편집기에 붙여넣고 **Run**을 누릅니다.

   | 순서 | 파일 | 하는 일 |
   |---|---|---|
   | 1 | [0001_wines.sql](https://github.com/hongsytop-tech/Wine-tasting/blob/claude/practical-dijkstra-i4je7l/supabase/migrations/0001_wines.sql) | 내 와인 테이블 |
   | 2 | [0002_tasting_notes.sql](https://github.com/hongsytop-tech/Wine-tasting/blob/claude/practical-dijkstra-i4je7l/supabase/migrations/0002_tasting_notes.sql) | 테이스팅 노트 테이블 |
   | 3 | [0003_wine_search_cache.sql](https://github.com/hongsytop-tech/Wine-tasting/blob/claude/practical-dijkstra-i4je7l/supabase/migrations/0003_wine_search_cache.sql) | 검색 결과 캐시 |
   | 4 | [0004_tasting_scores_0_10.sql](https://github.com/hongsytop-tech/Wine-tasting/blob/claude/practical-dijkstra-i4je7l/supabase/migrations/0004_tasting_scores_0_10.sql) | 특징 점수 0~10 척도 |

3. 각 실행 결과에 **Success. No rows returned**가 나오면 정상입니다.
   - `NOTICE ... does not exist, skipping` 같은 안내 문구가 같이 나와도 정상입니다.
   - 같은 파일을 두 번 실행해도 안전합니다.
4. 왼쪽 **Table Editor**에서 `wines`, `tasting_notes`, `wine_search_cache` 세 테이블이 보이면 끝입니다.

---

## 2단계. Edge Function `wine-search` 배포 (와인 검색 서버)

GitHub Actions로 배포합니다. PC에 아무것도 설치하지 않아도 됩니다.

### 2-1. Supabase 액세스 토큰 만들기
1. https://supabase.com/dashboard/account/tokens → **Generate new token**을 누릅니다.
2. 이름(예: `github-wine-tasting`)을 넣고 생성합니다.
3. 토큰(`sbp_...`)을 복사합니다. **이 화면을 닫으면 다시 볼 수 없습니다.**
   - ⚠️ 이 토큰은 내 Supabase 계정 전체를 조작할 수 있는 키입니다. GitHub Secrets 외의 곳(앱, `.env`, 메신저)에 넣지 마세요.

### 2-2. 프로젝트 ref 확인
- **Project Settings → General → Project ID**에 나오는 20자 정도의 영문 소문자입니다.
- Project URL `https://<이 부분>.supabase.co`에 있는 값과 같습니다.

### 2-3. GitHub Secrets 등록
1. https://github.com/hongsytop-tech/Wine-tasting/settings/secrets/actions → **New repository secret**을 누릅니다.
2. 아래 두 개를 각각 등록합니다. 이름은 대소문자까지 정확히 같아야 합니다.

   | Name | Secret |
   |---|---|
   | `SUPABASE_ACCESS_TOKEN` | 2-1에서 복사한 `sbp_...` |
   | `SUPABASE_PROJECT_REF` | 2-2의 프로젝트 ref |

### 2-4. 배포 실행
1. https://github.com/hongsytop-tech/Wine-tasting/actions → 왼쪽 목록에서 **Deploy Supabase Function (wine-search)**를 고릅니다.
2. **Run workflow** → Branch `claude/practical-dijkstra-i4je7l` → **Run workflow**를 누릅니다.
   - 왼쪽 목록에 이 워크플로우가 안 보이면 저장소의 기본 브랜치에 이 파일이 없는 것입니다. PR을 병합하면 나타납니다.
3. 초록색 체크가 뜨면 성공입니다.
4. Supabase 대시보드 **Edge Functions**에 `wine-search`가 보이는지 확인합니다.

### 2-5. (선택) Open Food Facts 식별 정보
- **Edge Functions → Secrets**(또는 Manage secrets)에 `OFF_USER_AGENT` = `WineNote/0.1 (본인 이메일)`을 추가합니다.
- Open Food Facts가 앱을 식별할 수 있는 User-Agent를 요청하기 때문입니다.
- 넣지 않으면 기본값 `WineTastingApp/0.1 (personal project)`가 쓰입니다.

> 대시보드의 "Via Editor"로 직접 붙여넣는 방법도 있습니다. 다만 이 함수는 여러 파일(`index.ts`, `openfoodfacts.ts`, `cache.ts`, `types.ts`, `../_shared/cors.ts`)로 되어 있고,
> 대시보드 편집기가 여러 파일을 지원하는지는 확인하지 못했습니다. 위의 Actions 방법을 권장합니다.

---

## 3단계. 로그인 인증 메일 설정

1. 대시보드 **Authentication → URL Configuration**을 엽니다.
2. **Redirect URLs** → **Add URL** → `https://hongsytop-tech.github.io/Wine-tasting/`를 추가하고 저장합니다. **(필수)**
   - 회원가입 인증 메일의 링크는 이 주소로 돌아오도록 앱에 설정되어 있습니다. 목록에 없으면 Supabase가 Site URL로 보냅니다.
3. **Site URL**은 이 앱 전용 프로젝트일 때만 앱 주소로 바꿉니다. 다른 앱과 같이 쓰는 프로젝트라면 그대로 두세요(0단계 참고).
4. 인증 메일 관련 참고
   - 기본 설정은 가입하면 인증 메일을 보내고, 링크를 눌러야 로그인할 수 있습니다.
   - Supabase 기본 메일 발송에는 **시간당 발송 수 제한**이 있습니다. 메일이 안 오면 스팸함을 확인하거나 잠시 뒤 다시 시도하세요.
   - 혼자 쓰는 앱이라면 **Authentication → Sign In / Providers → Email → Confirm email**을 끄는 방법도 있습니다. 대신 이메일 확인 없이 누구나 가입할 수 있게 됩니다. 다른 사람이 가입해도 각자 자기 데이터만 보도록 막혀 있습니다(RLS).

---

## 4단계. 앱용 Supabase 키를 GitHub Secrets에 등록

1. 대시보드 **Project Settings → API Keys**(또는 **API**)에서 두 값을 확인합니다.
   - **Project URL**: `https://<ref>.supabase.co` (끝에 `/` 없이)
   - **anon public 키**: `eyJ`로 시작하는 긴 문자열입니다. 새 형식 키(`sb_publishable_...`)만 보이면 **Legacy API Keys** 탭에서 찾으세요.
     - 이 앱은 `eyJ...` 형식 anon 키로만 만들었습니다. 새 형식 키로는 테스트하지 않았습니다.
2. https://github.com/hongsytop-tech/Wine-tasting/settings/secrets/actions 에 등록합니다.

   | Name | Secret |
   |---|---|
   | `SUPABASE_URL` | Project URL |
   | `SUPABASE_ANON_KEY` | anon public 키 |

   - 앞뒤 공백이나 줄바꿈이 들어가지 않게 주의하세요.
   - anon 키는 원래 웹앱에 포함되는 공개용 키입니다. 데이터는 RLS(본인 행만 접근)로 보호됩니다.

---

## 5단계. 웹 다시 배포

키는 **빌드할 때** 앱에 들어갑니다. 그래서 4단계 다음에 한 번 다시 배포해야 합니다.

1. https://github.com/hongsytop-tech/Wine-tasting/actions → **Deploy Web (GitHub Pages)** → **Run workflow** → Branch `claude/practical-dijkstra-i4je7l`를 실행합니다.
2. 초록색 체크가 뜰 때까지 2~3분 기다립니다.
3. 앱을 새로고침합니다. 홈 화면에 추가한 앱은 완전히 닫았다가 다시 엽니다.

---

## 6단계. 동작 확인 체크리스트

| 확인 | 정상 | 아니면 |
|---|---|---|
| 앱을 열면 **로그인 화면**이 나온다 | 키가 적용됨 | 4단계 Secret 이름 확인 → 5단계 다시 실행 |
| **계정 만들기** → 메일 → 링크 클릭 → 앱으로 돌아온다 | 3단계 정상 | 링크가 localhost 등으로 가면 3단계 Redirect URLs 확인 |
| 로그인 후 **검색** 탭에서 `Barolo` 검색 | 결과 목록 또는 "검색 결과가 없습니다" | 아래 문제 해결 표 참고 |
| 와인 하나를 추가하고, 다른 기기나 브라우저에서 같은 계정으로 로그인 | 같은 와인이 보인다 | 마이 탭 → **지금 동기화** |

- 이 단계 전에 "기기에만 저장" 모드로 쌓은 기록은 처음 로그인할 때 그 계정으로 올라가도록 만들어 두었습니다. 실제 Supabase에서는 아직 검증하지 못했으니, 처음 로그인한 뒤 기록이 남아 있는지 확인해 주세요.

### 문제 해결
| 증상 | 원인 | 해결 |
|---|---|---|
| 검색 시 "검색 서버가 설정되지 않았습니다" | 앱에 Supabase 키가 없음 | 4·5단계 |
| 검색 시 404 / Function not found | 함수 미배포 | 2-4단계 |
| 검색 시 401 / Invalid JWT | anon 키 형식 문제 | 4단계에서 `eyJ...` 키 사용 |
| 와인·노트가 서버에 안 올라감, `PGRST205` | 테이블 없음 또는 스키마 캐시 | 1단계 확인 후 SQL Editor에서 `NOTIFY pgrst, 'reload schema';` 실행 |
| 0~10점 노트만 동기화 안 됨 | 0004 미실행 | 1단계 4번 파일 실행 |
| Actions "Deploy Supabase Function" 실패 | Secret 누락 또는 토큰 만료 | 로그의 `::error::` 메시지 확인, 2-1·2-3 다시 하기 |
