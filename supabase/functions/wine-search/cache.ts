import { createClient, SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2';

import type { WineResult } from './types.ts';

const TTL_MS = 7 * 24 * 60 * 60 * 1000;

let _client: SupabaseClient | null = null;

function client(): SupabaseClient | null {
  if (_client) return _client;
  const url = Deno.env.get('SUPABASE_URL') ?? '';
  const key = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
  if (!url || !key) return null;
  _client = createClient(url, key, { auth: { persistSession: false } });
  return _client;
}

/** 캐시 조회. 만료됐거나 없으면 null. */
export async function getCached(key: string): Promise<WineResult[] | null> {
  const c = client();
  if (!c) return null;
  const { data, error } = await c
    .from('wine_search_cache')
    .select('results, expires_at')
    .eq('key', key)
    .maybeSingle();
  if (error || !data) return null;
  if (new Date(data.expires_at).getTime() < Date.now()) return null;
  return (data.results as WineResult[]) ?? [];
}

/** 캐시 저장 (upsert). 빈 결과는 저장하지 않는다 (등록 직후 재검색 허용). */
export async function setCached(key: string, results: WineResult[]): Promise<void> {
  const c = client();
  if (!c || results.length === 0) return;
  const now = new Date();
  await c.from('wine_search_cache').upsert({
    key,
    results,
    cached_at: now.toISOString(),
    expires_at: new Date(now.getTime() + TTL_MS).toISOString(),
  });
}
