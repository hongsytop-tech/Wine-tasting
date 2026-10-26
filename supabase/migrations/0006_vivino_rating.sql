-- Vivino 평점 (사용자가 Vivino 에서 보고 직접 입력, 0.0 ~ 5.0) + 입력 시점.
-- Vivino 평점은 시간이 지나며 바뀌므로 언제 본 값인지 함께 저장한다.
--
-- ⚠ 이 마이그레이션을 실행하기 전에는 새 앱의 와인 저장(vivino_rating 컬럼)이
--   서버에서 거부된다 (로컬에는 저장되고 실행 후 다음 동기화 때 올라감).

alter table public.wines
  add column if not exists vivino_rating numeric(2,1),
  add column if not exists vivino_rated_at timestamptz;

alter table public.wines
  drop constraint if exists wines_vivino_rating_check,
  add constraint wines_vivino_rating_check
    check (vivino_rating is null or (vivino_rating >= 0 and vivino_rating <= 5));
