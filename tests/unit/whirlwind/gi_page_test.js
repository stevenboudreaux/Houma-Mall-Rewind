// games, inc.'s WHIRLWIND (workstream PRIZES, Steven Nov 3 2026; design/godot-prize-counter.md "WHIRLWIND at
// games, inc."): the same page as Pocket Change's, opened by the mall as whirlwind.html?year=2026&cab=gi.
// Headless Chromium on the page itself (prototypes/godot-mall/play/whirlwind.html).
//
//   (cd prototypes/godot-mall/play && python3 -m http.server 8766 &)
//   node tests/unit/whirlwind/gi_page_test.js [out-prefix]
//
// Checks: START takes $2.00 (not $1.00) for four plays; the win of play 1 is in mall.tickets-2026 the moment the
// light stops and 1995's tickets don't move; the plays left are games, inc.'s own (whirlwind.gi.credits), so
// Pocket Change's machine still asks for its dollar; with $1.50 the start is refused and the card says
// "You need $2.00"; the page is the faded copy (html.faded); 0 page errors. Prints WHIRLWIND GI OK or FAILED.
const { chromium } = require('playwright');
const OUT = process.argv[2] || '/tmp/ww-gi';
const BASE = process.env.WW_BASE || 'http://localhost:8766/';
const fails = [], errors = [];
const check = (ok, what) => { console.log((ok ? 'ok   ' : 'FAIL ') + what); if (!ok) fails.push(what); };
const sleep = ms => new Promise(r => setTimeout(r, ms));

async function page(b, storage) {
  const ctx = await b.newContext({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 1 });
  const pg = await ctx.newPage();
  pg.on('pageerror', e => errors.push('pageerror: ' + e));
  pg.on('console', m => { if (m.type() === 'error' && !/Failed to load resource/.test(m.text())) errors.push('console: ' + m.text()); });
  pg.on('response', r => { if (r.status() >= 400 && !r.url().endsWith('favicon.ico')) errors.push('404 ' + r.url()); });
  await pg.goto(BASE + 'lib/mallbank.js');
  if (storage) await pg.evaluate(s => { for (const k in s) localStorage.setItem(k, s[k]); }, storage);
  return [ctx, pg];
}
async function go(pg, url) {
  await pg.goto(BASE + url, { waitUntil: 'load', timeout: 180000 });
  await pg.waitForFunction('window.__ww', null, { timeout: 180000 });
  await sleep(500);
}
const num = async (pg, k) => { const v = await pg.evaluate(k => localStorage.getItem(k), k); return v ? parseInt(v, 10) : 0; };

(async () => {
  const b = await chromium.launch({ args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader'] });
  let [ctx, pg] = await page(b, { 'mall.econ': '1', 'mall.money': '10000', 'mall.tickets-1995': '40' });
  await go(pg, 'whirlwind.html?year=2026&cab=gi&name=WHIRLWIND');
  check(await pg.evaluate("document.documentElement.classList.contains('faded')"), 'the games, inc. page is the faded copy');
  const card = await pg.evaluate("document.getElementById('msg').textContent");
  check(/\$2\.00/.test(card) && !/\$1\.00/.test(card), 'the card asks $2.00 for four plays');
  await pg.screenshot({ path: OUT + '-title.png' });
  await pg.evaluate("__ww.action(performance.now(), 'click')");
  check(await num(pg, 'mall.money') === 9800 && await pg.evaluate('__ww.S.mode') === 'chase', 'START takes $2.00 and play 1 runs ($' + (await num(pg, 'mall.money')) / 100 + ' left)');
  check(await pg.evaluate('__ww.S.credits') === 3, 'four plays for the $2.00 (3 left after the first)');
  await sleep(1200);
  await pg.evaluate("__ww.action(performance.now(), 'click')");
  const won = await pg.evaluate('__ww.S.won');
  check(won >= 1 && await num(pg, 'mall.tickets-2026') === won, 'the win (' + won + ') is in 2026\'s tickets at once (' + await num(pg, 'mall.tickets-2026') + ')');
  check(await num(pg, 'mall.tickets-1995') === 40, "1995's tickets don't move (40)");
  check(await num(pg, 'whirlwind.gi.credits') === 3 && await num(pg, 'whirlwind.credits') === 0, "the plays left are games, inc.'s own (whirlwind.gi.credits 3)");
  const ledger = JSON.parse(await pg.evaluate("localStorage.getItem('mall.ledger') || '{}'"));
  check((ledger.ids || []).some(i => /^whirlwind-gi:/.test(i)), 'the payout is named for this machine (whirlwind-gi:...)');
  await pg.screenshot({ path: OUT + '-win.png' });
  // Pocket Change's machine, same browser: its own price and its own plays
  await go(pg, 'whirlwind.html?year=1995');
  check(!(await pg.evaluate("document.documentElement.classList.contains('faded')")) && /\$1\.00/.test(await pg.evaluate("document.getElementById('msg').textContent")),
    "Pocket Change's machine (no cab) is still $1.00, not faded, with no plays carried over");
  await ctx.close();
  // no money
  [ctx, pg] = await page(b, { 'mall.econ': '1', 'mall.money': '150' });
  await go(pg, 'whirlwind.html?year=2026&cab=gi');
  await pg.evaluate("__ww.action(performance.now(), 'click')");
  check(await num(pg, 'mall.money') === 150 && await pg.evaluate('__ww.S.mode') === 'title', 'with $1.50 START is refused, nothing taken');
  const c2 = await pg.evaluate("document.getElementById('msg').textContent");
  check(/You need \$2\.00/.test(c2) && await pg.evaluate("document.getElementById('go').disabled"), "the card says 'You need $2.00' and START is greyed");
  await pg.screenshot({ path: OUT + '-nomoney.png' });
  await ctx.close();
  await b.close();
  check(errors.length === 0, '0 page errors ' + JSON.stringify(errors));
  console.log(fails.length ? 'WHIRLWIND GI FAILED (' + fails.length + ')' : 'WHIRLWIND GI OK');
  process.exit(fails.length ? 1 : 0);
})();
