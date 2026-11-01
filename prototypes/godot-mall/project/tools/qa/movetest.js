// Node port of tools/qa/movetest.py (python playwright is not installed in this container).
// node movetest.js <url-path> <out-prefix>   env CAMS, WALK_CAM like the python one
const { chromium } = require('playwright');
const [path, out] = process.argv.slice(2);
const CAMS = JSON.parse(process.env.CAMS || '{"shoe":"0,14,0,-8"}');
const ARGS = ["--use-angle=swiftshader", "--enable-unsafe-swiftshader", "--ignore-gpu-blocklist"];
const sleep = ms => new Promise(r => setTimeout(r, ms));
const url = c => `http://127.0.0.1:8765/${path}${path.includes('?') ? '&' : '?'}cam=${c}`;
async function ready(pg, logs, t = 300) {
  const t0 = Date.now();
  while (Date.now() - t0 < t * 1000) {
    if (logs.some(l => l.includes('fps') || l.includes('DBG'))) return (Date.now() - t0) / 1000;
    const hid = await pg.evaluate(() => { const s = document.querySelector('#status'); if (!s) return true; const c = getComputedStyle(s); return c.display === 'none' || c.visibility === 'hidden'; });
    if (hid) return (Date.now() - t0) / 1000;
    await sleep(1000);
  }
  return null;
}
(async () => {
  const b = await chromium.launch({ args: ARGS });
  let total = 0;
  for (const [name, cam] of Object.entries(CAMS)) {
    const ctx = await b.newContext({ viewport: { width: 1280, height: 720 } });
    const pg = await ctx.newPage(); const logs = [];
    pg.on('console', m => logs.push(m.text()));
    pg.on('pageerror', e => logs.push('ERROR pageerror ' + e.message));
    await pg.goto(url(cam), { timeout: 180000 });
    const took = await ready(pg, logs);
    await sleep(15000);
    await pg.screenshot({ path: `${out}-${name}.png`, timeout: 180000 });
    const errs = logs.filter(l => l.toUpperCase().includes('ERROR'));
    total += errs.length;
    console.log(name, 'ready_s', took, 'errors', errs.length, errs.slice(0, 3));
    await ctx.close();
  }
  const ctx = await b.newContext({ viewport: { width: 844, height: 390 }, hasTouch: true, isMobile: true });
  const pg = await ctx.newPage(); const logs = [];
  pg.on('console', m => logs.push(m.text()));
  await pg.goto(url(process.env.WALK_CAM || '0,14,0,0') + '&debug=1', { timeout: 180000 });
  await ready(pg, logs); await sleep(10000);
  const cdp = await ctx.newCDPSession(pg);
  const touch = (t, x, y) => cdp.send('Input.dispatchTouchEvent', { type: t, touchPoints: t === 'touchEnd' ? [] : [{ x, y, id: 1 }] });
  const last = () => logs.filter(l => l.startsWith('DBG')).slice(-1);
  const before = last();
  await touch('touchStart', 200, 300); await sleep(200);
  for (let i = 1; i <= 10; i++) { await touch('touchMove', 200, 300 - i * 6); await sleep(50); }
  await sleep(4000);
  const during = last();
  await touch('touchEnd', 0, 0); await sleep(1000);
  const pos = s => s.length ? (s[0].match(/pos=\(([^)]*)\)/) || [])[1] : null;
  console.log('walk before:', before, '\nwalk during:', during);
  // the DBG line only prints once the player moves: with no "before" line, compare with the start camera
  const wc = (process.env.WALK_CAM || '0,14,0,0').split(',').map(Number);
  const p1 = pos(during) ? pos(during).split(',').map(Number) : null;
  const p0 = pos(before) ? pos(before).split(',').map(Number) : [wc[0], 0, wc[1]];
  const moved = p1 && Math.hypot(p1[0] - p0[0], p1[2] - p0[2]) > 0.5;
  console.log(moved ? 'MOVED' : 'DID NOT MOVE');
  const errs = logs.filter(l => l.toUpperCase().includes('ERROR'));
  console.log('walk errors', errs.length, errs.slice(0, 3), 'TOTAL cam errors', total);
  await b.close();
})();
