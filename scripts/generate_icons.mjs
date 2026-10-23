// web_assets/icon.svg → 웹(PWA)·안드로이드 아이콘 PNG 생성.
// 사용: node scripts/generate_icons.mjs   (Playwright + Chromium 필요)
// 결과물은 저장소에 커밋되어 있으므로 아이콘을 바꿀 때만 다시 실행하면 된다.
import { readFileSync, mkdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { chromium } from 'playwright';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const svg = readFileSync(join(root, 'web_assets/icon.svg'), 'utf8');

// rounded: 배경을 둥근 사각형으로 잘라 모서리를 투명하게 (일반 아이콘·파비콘).
// full-bleed: 배경을 꽉 채움 (maskable·iOS — OS 가 직접 모양을 자른다).
const targets = [
  ['web_assets/favicon.png', 64, 'rounded'],
  ['web_assets/icons/Icon-192.png', 192, 'rounded'],
  ['web_assets/icons/Icon-512.png', 512, 'rounded'],
  ['web_assets/icons/Icon-maskable-192.png', 192, 'full'],
  ['web_assets/icons/Icon-maskable-512.png', 512, 'full'],
  ['web_assets/apple-touch-icon.png', 180, 'full'],
  ['android_assets/mipmap-mdpi/ic_launcher.png', 48, 'rounded'],
  ['android_assets/mipmap-hdpi/ic_launcher.png', 72, 'rounded'],
  ['android_assets/mipmap-xhdpi/ic_launcher.png', 96, 'rounded'],
  ['android_assets/mipmap-xxhdpi/ic_launcher.png', 144, 'rounded'],
  ['android_assets/mipmap-xxxhdpi/ic_launcher.png', 192, 'rounded'],
];

const browser = await chromium.launch();
const page = await browser.newPage();
for (const [out, size, mode] of targets) {
  const radius = mode === 'rounded' ? Math.round(size * 0.22) : 0;
  await page.setViewportSize({ width: size, height: size });
  await page.setContent(`<!doctype html><html><body style="margin:0;background:transparent">
    <div style="width:${size}px;height:${size}px;border-radius:${radius}px;overflow:hidden">
      ${svg.replace('<svg ', `<svg width="${size}" height="${size}" `)}
    </div></body></html>`);
  mkdirSync(join(root, dirname(out)), { recursive: true });
  await page.screenshot({ path: join(root, out), omitBackground: true });
  console.log(`${out} (${size}px, ${mode})`);
}
await browser.close();
