-- 특징 점수(색 농도·향 강도·당도·산미·타닌·알코올·바디·여운)를 1~5 → 0~10 척도로 변경.
--
-- 기존 행은 scale = 5 로 남겨 두고, 앱이 읽을 때 0~10 으로 환산한다
-- (TastingNote.fromLegacyScale: 1→0, 2→3, 3→5, 4→8, 5→10). 앱이 다시 저장하면
-- 0~10 값과 scale = 10 으로 덮어쓴다. 서버에서 일괄 변환하지 않는 이유: 기기의
-- 로컬 캐시에도 구버전 값이 있어 앱 쪽 환산이 어차피 필요하고, 두 곳에서
-- 변환하면 이중 환산 위험이 생긴다.
--
-- ⚠ 이 마이그레이션을 실행하기 전에는 새 앱의 노트 저장(scale 컬럼, 6~10 값)이
--   서버에서 거부된다 (로컬에는 저장되고 실행 후 다음 동기화 때 올라감).

alter table public.tasting_notes
  add column if not exists scale smallint not null default 5;

alter table public.tasting_notes
  drop constraint if exists tasting_notes_scale_check,
  add constraint tasting_notes_scale_check check (scale in (5, 10));

-- 0002 에서 컬럼 check 로 만든 제약(이름: <table>_<column>_check)을 0~10 으로 교체.
-- 구버전 값(1~5)도 0~10 범위 안이라 기존 행은 그대로 통과한다.
alter table public.tasting_notes
  drop constraint if exists tasting_notes_color_intensity_check,
  drop constraint if exists tasting_notes_aroma_intensity_check,
  drop constraint if exists tasting_notes_sweetness_check,
  drop constraint if exists tasting_notes_acidity_check,
  drop constraint if exists tasting_notes_tannin_check,
  drop constraint if exists tasting_notes_alcohol_check,
  drop constraint if exists tasting_notes_body_check,
  drop constraint if exists tasting_notes_finish_check,
  add constraint tasting_notes_color_intensity_check check (color_intensity between 0 and 10),
  add constraint tasting_notes_aroma_intensity_check check (aroma_intensity between 0 and 10),
  add constraint tasting_notes_sweetness_check check (sweetness between 0 and 10),
  add constraint tasting_notes_acidity_check check (acidity between 0 and 10),
  add constraint tasting_notes_tannin_check check (tannin between 0 and 10),
  add constraint tasting_notes_alcohol_check check (alcohol between 0 and 10),
  add constraint tasting_notes_body_check check (body between 0 and 10),
  add constraint tasting_notes_finish_check check (finish between 0 and 10);
