// node tests/unit/econ/bank.test.js : the arcade pages' money and tickets (prototypes/godot-mall/play/lib/mallbank.js),
// against the cases the Godot side also runs (tests/unit/econ/cases.json; tools/qa/econ_test.gd).
const assert = require('assert');
const B = require('../../../prototypes/godot-mall/play/lib/mallbank.js');
const CASES = require('./cases.json').cases;
let n = 0;
function t(name, f) { f(); n++; console.log('ok', name); }

function fakeStorage(init) {
  const m = new Map(Object.entries(init || {}));
  return { getItem: (k) => (m.has(k) ? m.get(k) : null), setItem: (k, v) => m.set(k, String(v)), removeItem: (k) => m.delete(k), _m: m };
}
const OPS = {
  money: (b) => b.money(), can_afford: (b, c) => b.canAfford(c), spend: (b, c, r) => b.spend(c, r), earn: (b, c, r) => b.earn(c, r),
  tickets: (b, y) => b.tickets(y), credit: (b, y, k, r, id) => b.credit(y, k, r, id), spend_tickets: (b, y, k, r) => b.spendTickets(y, k, r),
  migrate: (b) => b.migrate(),
};

for (const c of CASES) {
  t('case: ' + c.name, () => {
    const st = fakeStorage(c.start);
    const b = B.make(st);
    c.ops.forEach((op, i) => {
      const [name, ...rest] = op, want = rest.pop();
      assert.ok(OPS[name], 'unknown op ' + name);
      assert.deepStrictEqual(OPS[name](b, ...rest), want, `op ${i} ${JSON.stringify(op)}`);
    });
    for (const [k, want] of Object.entries(c.end || {})) {
      const got = st.getItem(k);
      if (want === null) assert.strictEqual(got, null, k + ' should be gone');
      else if (typeof want === 'object') assert.deepStrictEqual(JSON.parse(got), want, k);
      else assert.strictEqual(got, want, k);
    }
  });
}

t('fmt: cents as the player reads them', () => {
  assert.strictEqual(B.fmt(10000), '$100.00');
  assert.strictEqual(B.fmt(25), '$0.25');
  assert.strictEqual(B.fmt(0), '$0.00');
  assert.strictEqual(B.fmt(123456789), '$1,234,567.89');
});
t('a storage that throws (private mode) does not break a page', () => {
  const bad = { getItem() { throw new Error('no'); }, setItem() { throw new Error('no'); }, removeItem() { throw new Error('no'); } };
  const b = B.make(bad);
  assert.strictEqual(b.money(), 10000);
  assert.strictEqual(b.tickets(1995), 0);
});
t('the ledger keeps the last 40 changes and 200 ids', () => {
  const st = fakeStorage({ 'mall.econ': '1', 'mall.money': '100000' });
  const b = B.make(st);
  for (let i = 0; i < 250; i++) b.credit(1995, 1, 'x', 'id' + i);
  const l = JSON.parse(st.getItem('mall.ledger'));
  assert.strictEqual(l.log.length, 40);
  assert.strictEqual(l.ids.length, 200);
  assert.strictEqual(b.tickets(1995), 250);
  assert.strictEqual(b.credit(1995, 1, 'x', 'id249'), false, 'a recent id is still refused');
});
t('the game prices are data: pusher 25, claw 25, Skee-Ball 25, WHIRLWIND 100 for 4 plays', () => {
  const P = '../../../prototypes/godot-mall/play/';
  assert.strictEqual(require(P + 'pusher/logic.js').CONFIG.priceCents, 25);
  assert.strictEqual(require(P + 'claw/logic.js').CONFIG.priceCents, 25);
  assert.strictEqual(require(P + 'skeeball/logic.js').CONFIG.priceCents, 25);
  const W = require(P + 'whirlwind/logic.js').CONFIG;
  assert.strictEqual(W.priceCents, 100); assert.strictEqual(W.plays, 4);
});
console.log(`ECON BANK OK (${n} tests)`);
