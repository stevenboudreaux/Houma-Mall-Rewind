// node tests/unit/whirlwind/logic.test.js : the WHIRLWIND rules (prototypes/godot-mall/play/whirlwind/logic.js)
const assert = require('assert');
const WW = require('../../../prototypes/godot-mall/play/whirlwind/logic.js');
const C = WW.CONFIG;
const L = WW.lampMs(C);                       // 25.3125 ms per lamp
let n = 0;
function t(name, f) { f(); n++; console.log('ok', name); }

t('ring values: bonus 0, then 10 beside it on both sides, 64 lamps', () => {
  const v = WW.ringValues();
  assert.strictEqual(v.length, 64);
  assert.strictEqual(v[0], 0);
  assert.strictEqual(v[1], 10); assert.strictEqual(v[63], 10);
  assert.strictEqual(v[2], 8); assert.strictEqual(v[62], 8);
  assert.ok(v.slice(1).every(x => x >= 1 && x <= 10));
});
t('one lap is 1.62 s', () => {
  assert.ok(Math.abs(WW.position(1620, 0) - 0) < 1e-9);
  assert.ok(Math.abs(WW.position(810, 0) - 32) < 1e-9);
});
t('a press at the centre of the bonus lamp wins', () => {
  const r = WW.judge(0.5 * L, 0);
  assert.strictEqual(r.bonus, true); assert.strictEqual(r.lamp, 0);
});
t('the window is 3 ms wide: +-1.5 ms wins, +-1.6 ms does not', () => {
  assert.strictEqual(WW.judge(0.5 * L + 1.49, 0).bonus, true);
  assert.strictEqual(WW.judge(0.5 * L - 1.49, 0).bonus, true);
  assert.strictEqual(WW.judge(0.5 * L + 1.6, 0).bonus, false);
  assert.strictEqual(WW.judge(0.5 * L - 1.6, 0).bonus, false);
});
t('on the bonus lamp but outside the window, the light stops on the next lamp', () => {
  const r = WW.judge(0.1 * L, 0);
  assert.strictEqual(r.bonus, false); assert.strictEqual(r.lamp, 1); assert.strictEqual(r.skipped, true);
  assert.strictEqual(WW.payout(r, 100, WW.ringValues()), 10);
});
t('other lamps pay their value', () => {
  const r = WW.judge(5.5 * L, 0);
  assert.strictEqual(r.lamp, 5);
  assert.strictEqual(WW.payout(r, 100, WW.ringValues()), WW.ringValues()[5]);
});
t('wins come round once a lap from any start lamp', () => {
  const r = WW.judge((64 - 20 + 0.5) * L + 3 * 1620, 20);
  assert.strictEqual(r.bonus, true);
});
t('bonus: +1 per miss, back to 100 when won', () => {
  assert.strictEqual(WW.nextBonus({ bonus: false }, 102), 103);
  assert.strictEqual(WW.nextBonus({ bonus: true }, 137), 100);
  assert.strictEqual(WW.payout({ bonus: true, lamp: 0 }, 102, WW.ringValues()), 102);
});
t('payout averages about 2.5 tickets a second (video: 57 in 23 s)', () => {
  const ft = WW.feedTimes(1000, WW.rng(7));
  const rate = 1000 / (ft[999] / 1000);
  assert.ok(rate > 2.3 && rate < 2.7, 'rate ' + rate);
  const f2 = WW.feedTimes(102, WW.rng(1));
  assert.strictEqual(f2.length, 102);
  for (let i = 1; i < f2.length; i++) assert.ok(f2[i] > f2[i - 1]);
});
t('random presses win about 3/1620 of the time', () => {
  const r = WW.rng(3); let w = 0; const N = 200000;
  for (let i = 0; i < N; i++) if (WW.judge(r() * 1620 * 10, Math.floor(r() * 64)).bonus) w++;
  const p = w / N;
  assert.ok(Math.abs(p - 3 / 1620) < 0.0006, 'p ' + p);
});
t('PRIZES: Pocket Change\'s cabinet is $1.00 for four plays (the default)', () => {
  for (const name of [undefined, null, 'pc', 'nope', 'constructor']) {
    const c = WW.cabinet(name);
    assert.strictEqual(c.name, 'pc');
    assert.strictEqual(c.cfg.priceCents, 100);
    assert.strictEqual(c.cfg.plays, 4);
    assert.strictEqual(c.key, 'whirlwind');
    assert.strictEqual(c.faded, false);
  }
});
t('PRIZES: games, inc.\'s copy is the same game at $2.00 for four plays, with its own keys', () => {
  const g = WW.cabinet('gi'), p = WW.cabinet('pc');
  assert.strictEqual(g.cfg.priceCents, 200);
  assert.strictEqual(g.cfg.plays, 4);
  assert.strictEqual(g.faded, true);
  assert.notStrictEqual(g.key, p.key);
  assert.notStrictEqual(g.pay, p.pay);
  for (const k of Object.keys(C)) if (k !== 'priceCents') assert.strictEqual(g.cfg[k], C[k], k);
  assert.strictEqual(C.priceCents, 100, 'CONFIG itself is untouched');
});
console.log(n + ' passed');
