-- 블렌드 품종 비율 + 테이스팅 노트 라벨 사진.
--
-- ⚠ 이 마이그레이션을 실행하기 전에는 새 앱의 와인·노트 저장(grape_percents,
--   photos 컬럼)이 서버에서 거부된다 (로컬에는 저장되고 실행 후 다음 동기화 때 올라감).

-- 1) 블렌드 비율: {"카베르네 소비뇽": 60, "메를로": 40}
alter table public.wines
  add column if not exists grape_percents jsonb not null default '{}'::jsonb;

-- 2) 노트의 라벨 사진: Storage 경로 배열 ["<user_id>/<note_id>/<uuid>.jpg", ...]
alter table public.tasting_notes
  add column if not exists photos jsonb not null default '[]'::jsonb;

-- 3) 라벨 사진 버킷 (비공개 — 앱은 서명 URL 로만 표시). 장당 5MB, 이미지 형식만.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('wine-labels', 'wine-labels', false, 5242880,
        array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update
  set public = excluded.public,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

-- 4) 본인 폴더(<user_id>/...)만 읽기·올리기·수정·삭제.
drop policy if exists "wine_labels_select_own" on storage.objects;
create policy "wine_labels_select_own"
  on storage.objects for select to authenticated
  using (bucket_id = 'wine-labels'
         and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "wine_labels_insert_own" on storage.objects;
create policy "wine_labels_insert_own"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'wine-labels'
              and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "wine_labels_update_own" on storage.objects;
create policy "wine_labels_update_own"
  on storage.objects for update to authenticated
  using (bucket_id = 'wine-labels'
         and (storage.foldername(name))[1] = auth.uid()::text)
  with check (bucket_id = 'wine-labels'
              and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "wine_labels_delete_own" on storage.objects;
create policy "wine_labels_delete_own"
  on storage.objects for delete to authenticated
  using (bucket_id = 'wine-labels'
         and (storage.foldername(name))[1] = auth.uid()::text);
