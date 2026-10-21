-- wine-search Edge Function 결과 캐시.
-- 키 = "<source>:q:<정규화된 검색어>" 또는 "<source>:barcode:<코드>".
-- 외부 API 호출 절감 + 응답 속도 향상 (book_toc_cache 와 같은 방식).
create table if not exists public.wine_search_cache (
  key         text primary key,
  results     jsonb       not null default '[]'::jsonb,
  cached_at   timestamptz not null default now(),
  expires_at  timestamptz not null default now() + interval '7 days'
);

create index if not exists wine_search_cache_expires_at_idx
  on public.wine_search_cache (expires_at);

-- RLS 활성화: service_role(Edge Function)만 접근, 일반 클라이언트 차단.
alter table public.wine_search_cache enable row level security;
-- (정책 없음 = anon/authenticated 접근 불가, service_role은 RLS 우회)
