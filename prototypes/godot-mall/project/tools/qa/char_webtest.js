// B2 (design/godot-character-editor.md): the character pack and the editors in the web build.
// node tools/qa/char_webtest.js <url-path> <out-prefix>   (server on :8765 serving the repo root)
//   url-path: the build's index.html with ?wing=1, e.g.
//   prototypes/godot-mall/project/.scratch/builds/b2v2/index.html?wing=1
// Wing 1 1995, owner mode, at the Sound Shop counter: the map's character pack is fetched and
// mounted (console "char_pack: mounted"), both attendants dressed from presets and baked, K opens the
// owner's editor, the menu's AVATAR tab shows the character editor; then phone portrait by touch.
// Prints CHAR WEB OK / FAILED and the console errors.
const { chromium } = require('playwright');
const [path, out] = process.argv.slice(2);
const ARGS = ["--use-angle=swiftshader", "--enable-unsafe-swiftshader", "--ignore-gpu-blocklist"];
const CAM = "-12.9,-61.6,180,-4";
const sleep = ms => new Promise(r => setTimeout(r, ms));
const url = q => `http://127.0.0.1:8765/${path}${path.includes('?') ? '&' : '?'}${q}`;
const fails = [];
const check = (ok, what) => { console.log((ok ? 'ok   ' : 'FAIL ') + what); if (!ok) fails.push(what); };
async function waitFor(logs, needle, t) {
  const t0 = Date.now();
  while (Date.now() - t0 < t * 1000) { if (logs.some(l => l.includes(needle))) return (Date.now() - t0) / 1000; await sleep(1000); }
  return null;
}
const errsOf = logs => logs.filter(l => l.toUpperCase().includes('ERROR'));
(async () => {
  const b = await chromium.launch({ args: ARGS });
  let ctx = await b.newContext({ viewport: { width: 1280, height: 720 } });
  let pg = await ctx.newPage(); let logs = [];
  pg.on('console', m => logs.push(m.text()));
  pg.on('pageerror', e => logs.push('ERROR pageerror ' + e.message));
  await pg.goto(url(`cam=${CAM}&owner=1`), { timeout: 180000 });
  let took = await waitFor(logs, 'char_pack: mounted', 480);
  check(took !== null, `desktop: the character pack is fetched and mounted (${took === null ? '-' : Math.round(took) + ' s'})`);
  await waitFor(logs, 'kay_bee dressed and baked', 120);
  check(logs.some(l => l.includes('kay_bee dressed and baked')) && logs.some(l => l.includes('sound_shop dressed and baked')),
    'both wing 1 attendants dressed from their presets and baked');
  await sleep(20000);
  await pg.screenshot({ path: `${out}-attendant.png`, timeout: 180000 });
  await pg.keyboard.press('k');
  await sleep(30000);
  await pg.screenshot({ path: `${out}-owner-editor.png`, timeout: 180000 });
  await pg.keyboard.press('Escape');
  await sleep(10000);
  await pg.keyboard.press('Tab');
  await sleep(8000);
  await pg.keyboard.press('e');
  await sleep(30000);
  await pg.screenshot({ path: `${out}-menu-avatar.png`, timeout: 180000 });
  let errs = errsOf(logs);
  check(errs.length === 0, `desktop: 0 console errors (${errs.length}) ${errs.slice(0, 3).join(' | ')}`);
  console.log('desktop char lines: ' + logs.filter(l => l.includes('char_')).join(' | '));
  await ctx.close();
  // phone portrait: the creator in the menu by touch
  ctx = await b.newContext({ viewport: { width: 390, height: 844 }, hasTouch: true, isMobile: true });
  pg = await ctx.newPage(); logs = [];
  pg.on('console', m => logs.push(m.text()));
  pg.on('pageerror', e => logs.push('ERROR pageerror ' + e.message));
  await pg.goto(url(`cam=${CAM}`), { timeout: 180000 });
  took = await waitFor(logs, 'char_pack: mounted', 480);
  check(took !== null, 'phone: the character pack mounted (from the cache this time)');
  await sleep(15000);
  await pg.touchscreen.tap(60, 24);       // the Menu button (top left)
  await sleep(8000);
  await pg.touchscreen.tap(140, 26);      // the AVATAR tab
  await sleep(30000);
  await pg.screenshot({ path: `${out}-phone-menu-avatar.png`, timeout: 180000 });
  errs = errsOf(logs);
  check(errs.length === 0, `phone: 0 console errors (${errs.length}) ${errs.slice(0, 3).join(' | ')}`);
  await ctx.close(); await b.close();
  console.log(fails.length ? 'CHAR WEB FAILED: ' + fails.join('; ') : 'CHAR WEB OK');
})();
