-- 와인별 테이스팅 노트 (WSET 체계적 시음법을 단순화한 구조).
-- 1~5 척도 컬럼은 null = 기록 안 함. 삭제는 deleted_at soft-delete.
create table if not exists public.tasting_notes (
  user_id          uuid not null references auth.users (id) on delete cascade,
  id               text not null,
  wine_id          text not null,
  tasted_at        timestamptz not null default now(),
  place            text not null default '',
  companions       text not null default '',
  rating           numeric(2,1) check (rating is null or (rating >= 0 and rating <= 5)),
  color            text not null default '',
  color_intensity  smallint check (color_intensity between 1 and 5),
  aroma_intensity  smallint check (aroma_intensity between 1 and 5),
  aromas           jsonb not null default '[]'::jsonb,
  sweetness        smallint check (sweetness between 1 and 5),
  acidity          smallint check (acidity between 1 and 5),
  tannin           smallint check (tannin between 1 and 5),
  alcohol          smallint check (alcohol between 1 and 5),
  body             smallint check (body between 1 and 5),
  finish           smallint check (finish between 1 and 5),
  flavors          jsonb not null default '[]'::jsonb,
  pairing          text not null default '',
  price            integer check (price is null or price >= 0),
  comment          text not null default '',
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  deleted_at       timestamptz,
  primary key (user_id, id)
);

create index if not exists tasting_notes_user_wine_idx
  on public.tasting_notes (user_id, wine_id, tasted_at desc);

alter table public.tasting_notes enable row level security;

drop policy if exists "tasting_notes_select_own" on public.tasting_notes;
create policy "tasting_notes_select_own"
  on public.tasting_notes for select
  using (auth.uid() = user_id);

drop policy if exists "tasting_notes_insert_own" on public.tasting_notes;
create policy "tasting_notes_insert_own"
  on public.tasting_notes for insert
  with check (auth.uid() = user_id);

drop policy if exists "tasting_notes_update_own" on public.tasting_notes;
create policy "tasting_notes_update_own"
  on public.tasting_notes for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "tasting_notes_delete_own" on public.tasting_notes;
create policy "tasting_notes_delete_own"
  on public.tasting_notes for delete
  using (auth.uid() = user_id);
