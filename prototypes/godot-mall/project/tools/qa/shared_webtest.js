// CHARS (Nov 3 2026, design/godot-build-hosting.md "Shared packs"): every wing and year of a web export
// loads with its shared packs. Per map: the page loads, the "start" packs (items) are mounted before the
// scene ("shared_packs: mounted /mall/items.pck"), the character packs arrive and mount
// ("char_pack: mounted"), the attendants of that map are dressed from their presets, 0 console errors,
// and a screenshot is kept.
// node tools/qa/shared_webtest.js <url-path> <out-prefix> [maps] [kind]
//   url-path: the build's index.html, e.g. prototypes/godot-mall/project/.scratch/builds/chars/index.html
//   maps: comma list (default every map: w1,w2,w3,w4,w5,w6,w1y26,...,w6y26); kind: desktop (default) | mobile
//   (server on :8765 serving the repo root). Prints SHARED WEB OK / FAILED.
//   env THIRD=1: switch to third person (V) once the characters are in, so the shot shows the player's
//   preset body; env PHONE=1: a 390x844 touch phone instead of a 1280x720 desktop.
const { chromium } = require('playwright');
const [path, out, mapsArg, kindArg] = process.argv.slice(2);
const ARGS = ["--use-angle=swiftshader", "--enable-unsafe-swiftshader", "--ignore-gpu-blocklist"];
const MAPS = (mapsArg || 'w1,w2,w3,w4,w5,w6,w1y26,w2y26,w3y26,w4y26,w5y26,w6y26').split(',');
const KIND = kindArg || 'desktop';
// cameras (x,z,yaw,pitch): facing the attendants where a map has them, else the map's own start
const CAM = { w1: '-12.9,-61.6,180,-4', w2: '-106.5,66.8,270,-4' };
// the attendants dressed from presets in each map (data/story/attendants.json "look": "preset")
const DRESSED = { w1: ['kay_bee', 'sound_shop'], w2: ['pocket_change'] };
const sleep = ms => new Promise(r => setTimeout(r, ms));
const fails = [];
const check = (ok, what) => { console.log((ok ? 'ok   ' : 'FAIL ') + what); if (!ok) fails.push(what); };
async function waitFor(logs, needle, t) {
  const t0 = Date.now();
  while (Date.now() - t0 < t * 1000) { if (logs.some(l => l.includes(needle))) return (Date.now() - t0) / 1000; await sleep(1000); }
  return null;
}
(async () => {
  const b = await chromium.launch({ args: ARGS });
  for (const m of MAPS) {
    const wing = m.match(/^w(\d)/)[1], y26 = m.endsWith('y26');
    const q = `wing=${wing}${y26 ? '&year=2026' : ''}&pack=${KIND}${CAM[m] ? '&cam=' + CAM[m] : ''}`;
    const ctx = await b.newContext(process.env.PHONE ? { viewport: { width: 390, height: 844 }, hasTouch: true, isMobile: true } : { viewport: { width: 1280, height: 720 } });
    const pg = await ctx.newPage(); const logs = [];
    pg.on('console', msg => logs.push(msg.text()));
    pg.on('pageerror', e => logs.push('ERROR pageerror ' + e.message));
    const t0 = Date.now();
    await pg.goto(`http://127.0.0.1:8765/${path}?${q}`, { timeout: 180000 });
    const items = await waitFor(logs, 'shared_packs: mounted /mall/items.pck', 480);
    check(items !== null, `${m} ${KIND}: items pack mounted before the scene`);
    const chars = await waitFor(logs, 'char_pack: mounted', 600);
    check(chars !== null, `${m} ${KIND}: character pack(s) mounted (${chars === null ? '-' : Math.round((Date.now() - t0) / 1000) + ' s after load'})`);
    for (const a of DRESSED[m] || []) {
      await waitFor(logs, `${a} dressed and baked`, 120);
      check(logs.some(l => l.includes(`${a} dressed and baked`)), `${m}: attendant ${a} dressed from its preset`);
    }
    // without ?cam= a first start shows the opening (scripts/menu/opening.gd): Esc = Skip
    if (!CAM[m]) { await sleep(5000); await pg.keyboard.press('Escape'); await sleep(3000); }
    if (process.env.THIRD) { await sleep(5000); await pg.keyboard.press('v'); }
    await sleep(15000);
    await pg.screenshot({ path: `${out}-${m}-${KIND}${process.env.PHONE ? '-phone' : ''}${process.env.THIRD ? '-third' : ''}.png`, timeout: 180000 });
    const st = await pg.evaluate(() => ({ now: window.__mallMountNow, later: window.__mallLater }));
    console.log(`${m} ${KIND}: page mounted at start ${JSON.stringify(st.now)}, later ${JSON.stringify(st.later)}`);
    const errs = logs.filter(l => l.toUpperCase().includes('ERROR'));
    check(errs.length === 0, `${m} ${KIND}: 0 console errors (${errs.length}) ${errs.slice(0, 3).join(' | ')}`);
    const warns = logs.filter(l => l.includes('shared_packs') || l.includes('char_pack'));
    console.log(`${m} ${KIND}: ${warns.join(' | ')}`);
    await ctx.close();
  }
  await b.close();
  console.log(fails.length ? 'SHARED WEB FAILED: ' + fails.join('; ') : 'SHARED WEB OK');
})();
