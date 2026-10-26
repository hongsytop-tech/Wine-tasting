import { assertEquals } from 'jsr:@std/assert@1';

import {
  barcodeVariants,
  mapProduct,
  openFoodFacts,
  typeFromCategories,
  vintageFromName,
} from './openfoodfacts.ts';

Deno.test('typeFromCategories prefers the most specific wine type', () => {
  assertEquals(typeFromCategories(['en:wines', 'en:red-wines']), 'red');
  assertEquals(
    typeFromCategories(['en:wines', 'en:sparkling-wines', 'en:white-wines']),
    'sparkling',
  );
  assertEquals(typeFromCategories(['en:wines']), 'other');
  assertEquals(typeFromCategories(undefined), 'other');
});

Deno.test('vintageFromName only takes an explicit 4-digit year', () => {
  assertEquals(vintageFromName('Château Margaux 2015'), 2015);
  assertEquals(vintageFromName('Cuvée 1855 Brut'), null);
  assertEquals(vintageFromName('Rioja Reserva'), null);
  assertEquals(vintageFromName('Wine 2999'), null);
  assertEquals(vintageFromName('Bin 75012'), null);
});

Deno.test('mapProduct maps known fields and leaves unknowns empty', () => {
  const r = mapProduct({
    code: '3000000000017',
    product_name: 'Bordeaux Rouge 2019',
    brands: 'Some Château, Other',
    categories_tags: ['en:wines', 'en:red-wines'],
    image_front_small_url: 'https://images.example/x.jpg',
  });
  assertEquals(r?.name, 'Bordeaux Rouge 2019');
  assertEquals(r?.producer, 'Some Château');
  assertEquals(r?.vintage, 2019);
  assertEquals(r?.type, 'red');
  assertEquals(r?.country, '');
  assertEquals(r?.sourceUrl, 'https://world.openfoodfacts.org/product/3000000000017');
  assertEquals(mapProduct({ code: '1' }), null);
});

Deno.test('barcodeVariants adds the 12-digit UPC form', () => {
  assertEquals(barcodeVariants('0067058000817'), ['0067058000817', '067058000817']);
  assertEquals(barcodeVariants('3262151001757'), ['3262151001757']);
});

function stubFetch(responses: Array<{ status: number; body: string }>) {
  const urls: string[] = [];
  const orig = globalThis.fetch;
  let i = 0;
  globalThis.fetch = ((input: string | URL | Request) => {
    urls.push(String(input));
    const r = responses[Math.min(i++, responses.length - 1)];
    return Promise.resolve(new Response(r.body, { status: r.status }));
  }) as typeof fetch;
  return { urls, restore: () => (globalThis.fetch = orig) };
}

Deno.test('barcode not found (404 + status 0) is an empty result, not an error', async () => {
  const s = stubFetch([
    { status: 404, body: '{"status":0,"status_verbose":"product not found"}' },
  ]);
  try {
    assertEquals(await openFoodFacts.searchByBarcode('0067058000817'), []);
    assertEquals(s.urls.length, 2); // 13자리 → 12자리 재시도
  } finally {
    s.restore();
  }
});

Deno.test('barcode found on the 12-digit retry', async () => {
  const s = stubFetch([
    { status: 404, body: '{"status":0}' },
    {
      status: 200,
      body: '{"status":1,"product":{"product_name":"Petite Sirah","brands":"McManis"}}',
    },
  ]);
  try {
    const r = await openFoodFacts.searchByBarcode('0067058000817');
    assertEquals(r.length, 1);
    assertEquals(r[0].sourceId, '067058000817');
    assertEquals(r[0].producer, 'McManis');
  } finally {
    s.restore();
  }
});

Deno.test('non-JSON error responses surface status and body for diagnosis', async () => {
  const s = stubFetch([{ status: 404, body: '<html>Not Found</html>' }]);
  try {
    let msg = '';
    try {
      await openFoodFacts.searchByBarcode('3262151001757');
    } catch (e) {
      msg = String(e);
    }
    assertEquals(msg.includes('HTTP 404'), true);
    assertEquals(msg.includes('Not Found'), true);
  } finally {
    s.restore();
  }
});
