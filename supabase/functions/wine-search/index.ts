// 와인 검색 통합 프록시
//
// 요청: POST { q: string } 또는 { barcode: string }  (GET ?q= / ?barcode= 도 허용)
//       nocache: true 면 캐시 무시
// 응답: { results: WineResult[], errors: { [source]: message } }
//
// 소스: 현재 Open Food Facts (공개 API, ODbL).
// Vivino 는 공식 API 가 없고 약관이 자동 접근을 금지하므로 넣지 않는다.
// Wine-Searcher 는 유료 B2B API(키 필요)만 허용 — 계약 후 WineSource 로 추가.
// 자세한 근거: docs/DATA_SOURCES.md

import { corsHeaders } from '../_shared/cors.ts';
import { getCached, setCached } from './cache.ts';
import { openFoodFacts } from './openfoodfacts.ts';
import type { WineResult, WineSource } from './types.ts';

const SOURCES: WineSource[] = [openFoodFacts];

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const input = await readInput(req);
    const q = input.q.trim();
    const barcode = input.barcode.replace(/\D/g, '');
    if (!q && !barcode) {
      return json({ error: 'q or barcode is required' }, 400);
    }
    if (q.length > 100) {
      return json({ error: 'q is too long' }, 400);
    }

    const results: WineResult[] = [];
    const errors: Record<string, string> = {};

    await Promise.all(
      SOURCES.filter((s) => s.enabled()).map(async (s) => {
        const key = barcode
          ? `${s.id}:barcode:${barcode}`
          : `${s.id}:q:${q.toLowerCase().replace(/\s+/g, ' ')}`;
        try {
          if (!input.nocache) {
            const cached = await getCached(key).catch(() => null);
            if (cached) {
              results.push(...cached);
              return;
            }
          }
          const found = barcode ? await s.searchByBarcode(barcode) : await s.searchByName(q);
          results.push(...found);
          await setCached(key, found).catch((e) => console.error('Cache write failed:', e));
        } catch (e) {
          console.error(`${s.id} failed:`, e);
          errors[s.id] = String(e);
        }
      }),
    );

    return json({ results, errors });
  } catch (e) {
    console.error('Unhandled error:', e);
    return json({ error: String(e) }, 500);
  }
});

async function readInput(
  req: Request,
): Promise<{ q: string; barcode: string; nocache: boolean }> {
  const url = new URL(req.url);
  let body: Record<string, unknown> = {};
  if (req.method === 'POST') {
    try {
      body = await req.json();
    } catch {
      body = {};
    }
  }
  const pick = (k: string) => String(body[k] ?? url.searchParams.get(k) ?? '');
  return {
    q: pick('q'),
    barcode: pick('barcode'),
    nocache: body.nocache === true || url.searchParams.get('nocache') === '1',
  };
}

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}
