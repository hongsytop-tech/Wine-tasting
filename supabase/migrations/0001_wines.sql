-- 내 셀러에 저장한 와인. 검색 결과의 메타데이터를 스냅샷으로 저장하고
-- 즐겨찾기·내 평점·메모를 함께 둔다.
-- 클라이언트가 직접 읽고 쓴다 (RLS: 본인 행만). 삭제는 deleted_at soft-delete.
create table if not exists public.wines (
  user_id      uuid not null references auth.users (id) on delete cascade,
  id           text not null,
  name         text not null default '',
  producer     text not null default '',
  vintage      integer,
  type         text not null default 'other',
  country      text not null default '',
  region       text not null default '',
  grapes       jsonb not null default '[]'::jsonb,
  image_url    text not null default '',
  source       text not null default 'manual',
  source_id    text not null default '',
  source_url   text not null default '',
  barcode      text not null default '',
  is_favorite  boolean not null default false,
  my_rating    numeric(2,1) check (my_rating is null or (my_rating >= 0 and my_rating <= 5)),
  memo         text not null default '',
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  deleted_at   timestamptz,
  primary key (user_id, id)
);

create index if not exists wines_user_updated_idx
  on public.wines (user_id, updated_at desc);

alter table public.wines enable row level security;

-- drop-then-create so the migration is safe to re-run.
drop policy if exists "wines_select_own" on public.wines;
create policy "wines_select_own"
  on public.wines for select
  using (auth.uid() = user_id);

drop policy if exists "wines_insert_own" on public.wines;
create policy "wines_insert_own"
  on public.wines for insert
  with check (auth.uid() = user_id);

drop policy if exists "wines_update_own" on public.wines;
create policy "wines_update_own"
  on public.wines for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "wines_delete_own" on public.wines;
create policy "wines_delete_own"
  on public.wines for delete
  using (auth.uid() = user_id);
