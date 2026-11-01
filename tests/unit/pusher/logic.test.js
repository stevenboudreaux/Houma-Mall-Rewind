// node tests/unit/pusher/logic.test.js : the COIN COMET rules (prototypes/godot-mall/play/pusher/logic.js)
const assert = require('assert');
const P = require('../../../prototypes/godot-mall/play/pusher/logic.js');
const C = P.CONFIG;
let n = 0;
function t(name, f) { f(); n++; console.log('ok', name); }

// ---- the coin slot
t('slot: a quarter plays, a bigger token is rejected, a penny or a dime is lost', () => {
  assert.strictEqual(P.accept('quarter'), 'play');
  assert.strictEqual(P.accept('token'), 'reject');
  assert.strictEqual(P.accept('penny'), 'lost');
  assert.strictEqual(P.accept('dime'), 'lost');
  assert.strictEqual(P.accept('nickel'), 'lost');
  assert.strictEqual(P.accept('button'), 'reject');
});
t('slider: moves at slotSpeed and stops at the ends of the slot', () => {
  assert.ok(Math.abs(P.slide(0, 1, 0.5) - C.slotSpeed * 0.5) < 1e-9);
  assert.strictEqual(P.slide(C.slotHalfW - 1, 1, 1), C.slotHalfW);
  assert.strictEqual(P.slide(-C.slotHalfW + 1, -1, 1), -C.slotHalfW);
  assert.strictEqual(P.slide(3, 0, 1), 3);
});

// ---- the wallet
t('wallet: a new player has the starting stake; a saved count is kept whole', () => {
  assert.strictEqual(P.balance(null), C.startQuarters);
  assert.strictEqual(P.balance({ v: 1, inventory: [] }), C.startQuarters);
  assert.strictEqual(P.balance({ quarters: 7.9 }), 7);
  assert.strictEqual(P.balance({ quarters: -3 }), C.startQuarters);
});
t('wallet: paying in takes one quarter, paying out adds, and the rest of the state is kept', () => {
  const s0 = { v: 1, year: 1995, inventory: [{ id: 'pogs', count: 1 }], tickets: 5, quarters: 2 };
  const s1 = P.payIn(s0);
  assert.strictEqual(s1.quarters, 1);
  assert.deepStrictEqual(s1.inventory, s0.inventory);
  assert.strictEqual(s1.tickets, 5);
  assert.strictEqual(s0.quarters, 2, 'no mutation');
  const s2 = P.payIn(s1);
  assert.strictEqual(s2.quarters, 0);
  assert.strictEqual(P.payIn(s2), null, 'broke');
  assert.strictEqual(P.payOut(s2, 3).quarters, 3);
});
t('wallet: in tickets mode the stake is mall.tickets at ticketsPerCoin each', () => {
  const cfg = Object.assign({}, C, { currency: 'tickets', ticketsPerCoin: 2 });
  assert.strictEqual(P.balance({ tickets: 9 }, cfg), 9);
  assert.strictEqual(P.balance({}, cfg), 0);
  assert.strictEqual(P.payIn({ tickets: 9 }, cfg).tickets, 7);
  assert.strictEqual(P.payIn({ tickets: 1 }, cfg), null);
  const s = P.payOut({ tickets: 1, quarters: 4 }, 3, cfg);
  assert.strictEqual(s.tickets, 7);
  assert.strictEqual(s.quarters, 4, 'quarters untouched in tickets mode');
});

// ---- the tilt
t('tilt: small nudges spread out never trip; the meter forgets them after the window', () => {
  let log = null, r;
  for (let i = 0; i < 10; i++) { r = P.nudge(log, i * 2000, 0.4); log = r.log; assert.strictEqual(r.tripped, false, 'nudge ' + i); }
  assert.ok(r.power < C.tiltTrip);
  assert.strictEqual(P.tiltPower(log, 18000 + C.tiltWindowMs + 1), 0);
});
t('tilt: nudges inside the window add up and trip at tiltTrip', () => {
  let log = null, r, t0 = 1000, k = 0;
  do { r = P.nudge(log, t0 + k * C.nudgeMinMs, 1); log = r.log; k++; } while (!r.tripped && k < 20);
  assert.strictEqual(r.tripped, true);
  assert.strictEqual(k, Math.ceil(C.tiltTrip), 'full-power nudges to trip');
  assert.ok((k - 1) * C.nudgeMinMs < C.tiltWindowMs, 'they fit in the window');
});
t('tilt: a nudge too soon after the last is ignored', () => {
  const a = P.nudge(null, 1000, 1);
  const b = P.nudge(a.log, 1000 + C.nudgeMinMs - 1, 1);
  assert.strictEqual(b.accepted, false);
  assert.strictEqual(b.log, a.log);
  const c = P.nudge(a.log, 1000 + C.nudgeMinMs, 1);
  assert.strictEqual(c.accepted, true);
  assert.strictEqual(c.log.hits.length, 2);
});
t('tilt: the alarm lasts 3 s and the gate is over for tiltGateMs, swinging at both ends', () => {
  const t0 = 5000;
  assert.deepStrictEqual(P.tiltState(null, 1e6), { alarm: false, gate: 'player', swinging: false });
  assert.deepStrictEqual(P.tiltState(t0, t0 - 1), { alarm: false, gate: 'player', swinging: false });
  let s = P.tiltState(t0, t0 + 10);
  assert.strictEqual(s.alarm, true); assert.strictEqual(s.gate, 'house'); assert.strictEqual(s.swinging, true);
  s = P.tiltState(t0, t0 + 2999);
  assert.strictEqual(s.alarm, true); assert.strictEqual(s.gate, 'house'); assert.strictEqual(s.swinging, false);
  s = P.tiltState(t0, t0 + 3000);
  assert.strictEqual(s.alarm, false); assert.strictEqual(s.gate, 'house');
  s = P.tiltState(t0, t0 + C.tiltGateMs);
  assert.strictEqual(s.gate, 'player'); assert.strictEqual(s.swinging, true);
  s = P.tiltState(t0, t0 + C.tiltGateMs + C.gateSwingMs);
  assert.strictEqual(s.swinging, false);
});

// ---- accounting
t('ledger: events are booked where they went and rtp is cup over in', () => {
  let l = P.ledger();
  l.in = 10;
  for (const e of ['cup', 'cup', 'side', 'house-tilt', 'lost', 'nothing']) l = P.book(l, e);
  assert.strictEqual(l.cup, 2); assert.strictEqual(l.side, 1); assert.strictEqual(l.tilt, 1); assert.strictEqual(l.lost, 1);
  assert.strictEqual(P.rtp(l), 0.2);
  assert.strictEqual(P.rtp(P.ledger()), 0);
});

// ---- saves
t('save: a machine packs and unpacks whole; the lip is clamped; junk is refused', () => {
  const coins = [];
  for (let i = 0; i < 30; i++) coins.push(i, 1.5, 2.5, 0, 0, 0, 1);
  const l = P.book(P.ledger(), 'cup');
  const packed = P.packMachine({ t: 1.25, coins }, l, 9);
  const s = JSON.parse(JSON.stringify(packed));
  const u = P.unpackMachine(s);
  assert.deepStrictEqual(u.coins, coins);
  assert.strictEqual(u.t, 1.25);
  assert.deepStrictEqual(u.ledger, l);
  assert.strictEqual(u.lipMm, C.lipRange[1], 'clamped');
  assert.strictEqual(P.unpackMachine(null), null);
  assert.strictEqual(P.unpackMachine({ v: 99, coins }), null);
  assert.strictEqual(P.unpackMachine({ v: 1, coins: coins.slice(0, 13) }), null, 'not a multiple of 7');
  assert.strictEqual(P.unpackMachine({ v: 1, coins: coins.slice(0, 14) }), null, 'too few to be a machine');
  assert.strictEqual(P.unpackMachine({ v: 1, coins: coins.concat(['x', 0, 0, 0, 0, 0, 1]) }), null);
});
t('save: one key per position, 1..6', () => {
  assert.strictEqual(P.machineKey(1), 'pusher.machine.1');
  assert.strictEqual(P.machineKey(6), 'pusher.machine.6');
  assert.strictEqual(P.machineKey(9), 'pusher.machine.6');
  assert.strictEqual(P.machineKey(0), 'pusher.machine.1');
});

console.log(n + ' tests passed');
