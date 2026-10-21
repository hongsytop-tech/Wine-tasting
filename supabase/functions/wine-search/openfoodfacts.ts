// Open Food Facts — 공개 API (키 불필요). 데이터 라이선스 ODbL, 사진 CC BY-SA.
// https://world.openfoodfacts.org/terms-of-use
//
// 주의: 사용자 기여 데이터라 와인 전용 필드(품종·산지·빈티지)가 체계적으로
// 없다. 여기서는 확실한 필드만 옮기고, 없는 값은 비워 둔다.
//   - countries_tags 는 "판매 국가"이지 원산지가 아니므로 쓰지 않는다.
//   - 원산지는 사용자가 입력한 origins(자유 텍스트)가 있을 때만 사용.
//   - 빈티지는 제품명에 4자리 연도가 그대로 적혀 있을 때만 추출.

import type { WineResult, WineSource, WineType } from './types.ts';

const BASE = 'https://world.openfoodfacts.org';
const FIELDS = [
  'code',
  'product_name',
  'product_name_ko',
  'product_name_en',
  'brands',
  'image_front_small_url',
  'image_front_url',
  'categories_tags',
  'origins',
].join(',');

// OFF 는 앱 이름이 담긴 User-Agent 를 요청한다.
function userAgent(): string {
  return Deno.env.get('OFF_USER_AGENT') ?? 'WineTastingApp/0.1 (personal project)';
}

interface OffProduct {
  code?: string;
  product_name?: string;
  product_name_ko?: string;
  product_name_en?: string;
  brands?: string;
  image_front_small_url?: string;
  image_front_url?: string;
  categories_tags?: string[];
  origins?: string;
}

const TYPE_BY_CATEGORY: [string, WineType][] = [
  ['en:sparkling-wines', 'sparkling'],
  ['en:champagnes', 'sparkling'],
  ['en:rose-wines', 'rose'],
  ['en:fortified-wines', 'fortified'],
  ['en:ports', 'fortified'],
  ['en:sherries', 'fortified'],
  ['en:dessert-wines', 'dessert'],
  ['en:sweet-wines', 'dessert'],
  ['en:red-wines', 'red'],
  ['en:white-wines', 'white'],
];

export function typeFromCategories(tags: string[] = []): WineType {
  for (const [tag, type] of TYPE_BY_CATEGORY) {
    if (tags.includes(tag)) return type;
  }
  return 'other';
}

export function vintageFromName(name: string): number | null {
  const m = name.match(/(?:^|\D)((?:19|20)\d{2})(?:\D|$)/);
  if (!m) return null;
  const y = Number(m[1]);
  return y <= new Date().getFullYear() ? y : null;
}

export function mapProduct(p: OffProduct): WineResult | null {
  const code = (p.code ?? '').trim();
  const name = (p.product_name_ko || p.product_name || p.product_name_en || '').trim();
  if (!code || !name) return null;
  return {
    source: 'openfoodfacts',
    sourceId: code,
    name,
    producer: (p.brands ?? '').split(',')[0].trim(),
    vintage: vintageFromName(name),
    type: typeFromCategories(p.categories_tags),
    country: '',
    region: (p.origins ?? '').trim(),
    grapes: [],
    imageUrl: p.image_front_small_url || p.image_front_url || '',
    sourceUrl: `${BASE}/product/${code}`,
    barcode: code,
  };
}

async function getJson(url: string): Promise<unknown> {
  const res = await fetch(url, { headers: { 'User-Agent': userAgent() } });
  if (!res.ok) throw new Error(`Open Food Facts HTTP ${res.status}`);
  return await res.json();
}

export const openFoodFacts: WineSource = {
  id: 'openfoodfacts',
  enabled: () => true,

  async searchByName(q: string): Promise<WineResult[]> {
    const params = new URLSearchParams({
      search_terms: q,
      search_simple: '1',
      action: 'process',
      json: '1',
      page_size: '24',
      tagtype_0: 'categories',
      tag_contains_0: 'contains',
      tag_0: 'wines',
      fields: FIELDS,
    });
    const body = (await getJson(`${BASE}/cgi/search.pl?${params}`)) as {
      products?: OffProduct[];
    };
    return (body.products ?? [])
      .map(mapProduct)
      .filter((r): r is WineResult => r != null);
  },

  async searchByBarcode(code: string): Promise<WineResult[]> {
    const body = (await getJson(
      `${BASE}/api/v2/product/${encodeURIComponent(code)}?fields=${FIELDS}`,
    )) as { status?: number; product?: OffProduct };
    if (body.status !== 1 || !body.product) return [];
    // 바코드 조회는 사용자가 병을 직접 찍은 것 — 와인 카테고리가 안 붙어 있어도 돌려준다.
    const r = mapProduct({ code, ...body.product });
    return r ? [r] : [];
  },
};
