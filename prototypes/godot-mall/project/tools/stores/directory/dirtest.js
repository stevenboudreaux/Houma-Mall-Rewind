// Headless browser check of the mall directory (design/godot-directory.md) in a web export.
// Usage: node tools/stores/directory/dirtest.js <build-url-dir> <out-prefix>   (repo root served on :8765)
//   e.g. node tools/stores/directory/dirtest.js prototypes/godot-mall/project/.scratch/builds/wsa production/qa/evidence/wsA
// ONLY=<part of a step name> runs one step: 1995-h2, 2026-h2, 1995-h6, 2026-h6, 1995-h3, 1995-silverman, phone, jump.
// Shots (PNG, convert to JPEG afterwards): <out>-kiosk-<name>-unbaked, <out>-map-<year>-desktop,
// <out>-map-<year>-phone, <out>-jump-before / -after (a cross-wing jump; positions printed).
const { chromium } = require('playwright');
const [base, out] = process.argv.slice(2);
const URL = 'http://127.0.0.1:8765/' + base.replace(/^\/|\/$/g, '') + '/index.html';
const ARGS = ['--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'];
// kiosk 1 (-3,-82.5) faces north; kiosk 2 (-142,71.5) faces south (tools/stores/directory/directory_data.json)
const K1 = '-3.0,-83.9,180,-6', K2 = '-142.0,72.9,0,-6';   // within scripts/interact.gd's 1.6 m REACH (Demo 50)
const sleep = (s) => new Promise((r) => setTimeout(r, s * 1000));
// where a store's click area is on screen (scripts/directory_ui.gd's fit: frame + margin round the sign)
const HOT = JSON.parse(require('fs').readFileSync(__dirname + '/../../../tex/dir/hotspots.json', 'utf8'));
function spot(year, id, kind, vw, vh) {
  const narrow = vw < 760, fw = narrow ? 10 : 18, m = fw + (narrow ? 6 : 20), top = narrow ? 44 : 0;
  const [W, H] = HOT.size, s = Math.min((vw - 2 * m) / W, (vh - 2 * m - top) / H);
  const cx = vw / 2, cy = vh / 2 + (narrow ? 22 : 0);
  const h = HOT[year].find((q) => q.id === id && q.kind === kind);
  return [cx + ((h.rect[0] + h.rect[2]) / 2 - W / 2) * s, cy + ((h.rect[1] + h.rect[3]) / 2 - H / 2) * s];
}
const only = process.env.ONLY || '';
const want = (n) => !only || n.includes(only);

async function openPage(b, q, phone) {
  const ctx = await b.newContext(phone ? { viewport: { width: 390, height: 844 }, hasTouch: true, isMobile: true }
    : { viewport: { width: 1280, height: 720 } });
  const pg = await ctx.newPage();
  const logs = [];
  pg.on('console', (m) => logs.push(m.text()));
  await pg.goto(URL + '?' + q + '&debug=1&time=day');
  const t0 = Date.now();
  while (Date.now() - t0 < 300000 && !logs.some((l) => l.includes('DBG') || l.includes('fps'))) await sleep(1);
  const took = (Date.now() - t0) / 1000;
  await sleep(14);
  return { ctx, pg, logs, took };
}
const lastPos = (logs) => { for (let i = logs.length - 1; i >= 0; i--) { const m = logs[i].match(/DBG pos=\(([^)]*)\)/); if (m) return m[1]; } return null; };
const errs = (logs) => logs.filter((l) => /error/i.test(l) && !l.includes('DBG'));
const shot = (pg, name) => pg.screenshot({ path: name + '.png', timeout: 180000 });
async function tap(ctx, pg, x, y) {
  const cdp = await ctx.newCDPSession(pg);
  await cdp.send('Input.dispatchTouchEvent', { type: 'touchStart', touchPoints: [{ x, y, id: 1 }] });
  await sleep(0.15);
  await cdp.send('Input.dispatchTouchEvent', { type: 'touchEnd', touchPoints: [] });
  await sleep(1.5);
}

(async () => {
  const b = await chromium.launch({ args: ARGS });
  for (const [year, q, cam, name] of [['1995', 'wing=1', K1, '1995-h2'], ['2026', 'wing=1&year=2026', K1, '2026-h2'],
    ['1995', 'wing=2', K2, '1995-h6'], ['2026', 'wing=2&year=2026', K2, '2026-h6'],
    ['1995', 'wing=1', '28.7,3.2,90,-6', '1995-h3'], ['1995', 'wing=2', '-41.0,59.5,0,-8', '1995-silverman']]) {
    if (!want(name)) continue;
    const { ctx, pg, logs, took } = await openPage(b, q + '&cam=' + cam);
    await shot(pg, `${out}-kiosk-${name}-unbaked`);
    if (name.endsWith('h2')) {
      await pg.keyboard.press('e');
      await sleep(3);
      const [x, y] = spot(year, year === '2026' ? 's25' : 's18', 'map', 1280, 720);   // Hypervelocity / Kay-Bee Toys
      await pg.mouse.move(x, y); await sleep(2);
      await shot(pg, `${out}-map-${year}-desktop`);
      for (let i = 0; i < 4; i++) { await pg.mouse.wheel(0, -200); await sleep(0.4); }
      await sleep(2);
      await shot(pg, `${out}-map-${year}-desktop-zoom`);
    }
    console.log(name, 'ready_s', took, 'pos', lastPos(logs), 'errors', errs(logs).length, errs(logs).slice(0, 3));
    await ctx.close();
  }
  if (want('phone')) {
    const { ctx, pg, logs, took } = await openPage(b, 'wing=1&cam=' + K1, true);
    await shot(pg, `${out}-phone-prompt`);
    await tap(ctx, pg, 195, 844 - 105);          // the "Read the Mall Directory" prompt
    await sleep(2);
    await shot(pg, `${out}-map-1995-phone`);
    await tap(ctx, pg, 299, 23);                  // the 2026 button on the frame
    await sleep(2);
    await shot(pg, `${out}-map-2026-phone`);
    const [x, y] = spot('2026', 's25', 'map', 390, 844);   // Hypervelocity's block on the sign's map
    await tap(ctx, pg, x, y);
    await sleep(2);
    await shot(pg, `${out}-map-2026-phone-confirm`);
    const before = lastPos(logs);
    await tap(ctx, pg, 107, 472);                 // "Yes, go there": 2026, the same wing
    const t0 = Date.now();
    while (Date.now() - t0 < 300000 && !logs.some((l) => l.includes('crossing to'))) await sleep(1);
    const n0 = logs.length;
    while (Date.now() - t0 < 400000 && !logs.slice(n0).some((l) => l.includes('DBG pos'))) await sleep(1);
    await sleep(12);
    await shot(pg, `${out}-phone-jump-after`);
    console.log('phone jump', logs.filter((l) => l.includes('directory jump')).slice(0, 2));
    console.log('PHONE JUMP before', before, '| after', lastPos(logs), '| url', await pg.evaluate('location.search'));
    console.log('phone ready_s', took, 'errors', errs(logs).length, errs(logs).slice(0, 3));
    await ctx.close();
  }
  if (want('jump')) {
    const { ctx, pg, logs } = await openPage(b, 'wing=1&cam=' + K1);
    const before = lastPos(logs);
    await pg.keyboard.press('e'); await sleep(2);
    const [x, y] = spot('1995', 's2', 'list', 1280, 720);    // "67 - Dillard's" in the list
    await pg.mouse.click(x, y); await sleep(2);
    await shot(pg, `${out}-jump-before`);
    await pg.keyboard.press('Enter');
    const t0 = Date.now();
    while (Date.now() - t0 < 300000 && !logs.some((l) => l.includes('crossing to'))) await sleep(1);
    const n0 = logs.length;
    while (Date.now() - t0 < 400000) {
      const s = await pg.evaluate('location.search').catch(() => '');
      if (s.includes('wing=2') && logs.slice(n0).some((l) => l.includes('DBG pos'))) break;
      await sleep(1);
    }
    await sleep(14);
    await shot(pg, `${out}-jump-after`);
    console.log('jump', logs.filter((l) => l.includes('directory jump') || l.includes('crossing to')).slice(0, 3));
    console.log('JUMP before', before, '| after', lastPos(logs), '| url', await pg.evaluate('location.search'));
    console.log('errors', errs(logs).length, errs(logs).slice(0, 3));
    await ctx.close();
  }
  await b.close();
})();
