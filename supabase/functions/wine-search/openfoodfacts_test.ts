import { assertEquals } from 'jsr:@std/assert@1';

import { mapProduct, typeFromCategories, vintageFromName } from './openfoodfacts.ts';

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
