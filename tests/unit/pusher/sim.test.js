// node tests/unit/pusher/sim.test.js : the COIN COMET physics world (prototypes/godot-mall/play/pusher/sim.js)
// headless on Rapier: the crank and the gap, a fresh fill on two walled tiers, a drop into the gap
// while the deck is out, the deck's sweep onto the main tier, the save/restore round trip, the
// gate, the lip, and that nothing leaves at the sides or through the tier. ~40 s.
const assert = require('assert');
let n = 0;
function t(name, f) { f(); n++; console.log('ok', name); }

(async () => {
  const R = (await import('../../../prototypes/godot-mall/play/lib/rapier3d-compat.mjs')).default;
  const { createSim, deckZ, wallZ, deckTravel, deckOutness, GEOM } = await import('../../../prototypes/godot-mall/play/pusher/sim.js');
  await R.init({});
  const WZ = wallZ(GEOM);

  t('the crank: periodic, travel = stroke + the drive\'s play, in at t = 0 and out at half a turn', () => {
    const z0 = deckZ(0), zh = deckZ(GEOM.period / 2), z1 = deckZ(GEOM.period);
    assert.ok(Math.abs(z0 - z1) < 1e-9, 'periodic');
    let lo = 1e9, hi = -1e9;
    for (let k = 0; k < 900; k++) { const z = deckZ(k * GEOM.period / 900); lo = Math.min(lo, z); hi = Math.max(hi, z); }
    assert.ok(Math.abs((hi - lo) - (GEOM.stroke + 2 * GEOM.snap)) < 0.02, 'travel ' + (hi - lo).toFixed(3));
    assert.ok(z0 > GEOM.deckFront && zh < GEOM.deckFront, 'in at 0, out at half');
    // the drive's play: the deck snaps to its dead point just after the crank passes it
    assert.ok(deckOutness(0.02 * GEOM.period) < 0.05 && deckOutness(0.52 * GEOM.period) > 0.95, 'outness 0 in, 1 out');
  });

  t('the gap: the deck top in front of the wall is deckOut when out and deckOut - stroke when in', () => {
    const [zOut, zIn] = deckTravel(GEOM);
    assert.ok(Math.abs((WZ - zOut) - GEOM.deckOut) < 0.01, 'out: ' + (WZ - zOut).toFixed(2));
    assert.ok(Math.abs((WZ - zIn) - (GEOM.deckOut - GEOM.stroke - 2 * GEOM.snap)) < 0.05, 'in: ' + (WZ - zIn).toFixed(2));
    assert.ok(WZ - zIn > 2 * GEOM.coinR, 'a coin still fits on the deck when it is in');
  });

  const sim = createSim(R, { lipMm: 1 }).fresh(7, 400, 2);
  t('a fresh machine: the asked coins (to its capacity), every one on a tier, both tiers packed, none at the sides', () => {
    const want = Math.min(400, sim.capacity);
    assert.ok(sim.count() <= want + 1 && sim.count() >= want - 40, 'count ' + sim.count() + ' of ' + want);   // (40: what settles over the edge is taken back)
    let deck = 0, shelf = 0;
    for (const c of sim.coins.values()) {
      const p = c.body.translation();
      assert.ok(p.y > -0.5, 'below the tier');
      assert.ok(Math.abs(p.x) < GEOM.halfW, 'outside the walls');
      if (p.y > GEOM.deckY - 0.5) deck++; else shelf++;
    }
    assert.ok(shelf > 120 && deck > 60, 'shelf ' + shelf + ' deck ' + deck);
  });

  t('a drop while the deck is out lands in the gap at the wall, on the deck, and stays on the field', () => {
    while (sim.outness() < 0.9) sim.run(1 / 60);
    const before = sim.count();
    const id = sim.drop(5);
    sim.run(0.4);
    let c = null; for (const k of sim.coins.values()) if (k.id === id) c = k;
    const p = c.body.translation();
    assert.ok(p.y > GEOM.deckY - 0.3 && p.y < GEOM.deckY + 2, 'on the deck, y ' + p.y.toFixed(2));
    assert.ok(p.z > WZ - 2 * GEOM.coinR - 1.5 && p.z < WZ, 'at the wall, z ' + p.z.toFixed(1) + ' (wall ' + WZ.toFixed(1) + ')');
    assert.ok(Math.abs(p.x - 5) < 6, 'under the slot, x ' + p.x.toFixed(1));
    sim.run(1.5);
    const ev = sim.step(0);
    assert.ok(!ev.some(e => e.type === 'tunnel' || e.type === 'lost' || e.type === 'side'), 'no tunnel/lost/side: ' + JSON.stringify(ev));
    assert.ok(sim.count() <= before + 1 && sim.count() >= before - 6, 'count ' + sim.count() + ' from ' + before);
  });

  t('the deck sweeps: over twenty cycles of drops into the gap, the wall pushes coins off the deck onto the main tier and the heap moves toward the edge', () => {
    const s2 = createSim(R, { lipMm: 1 }).fresh(11, 400, 2);
    const onDeck = () => { let d = 0; for (const c of s2.coins.values()) if (c.body.translation().y > GEOM.deckY - 0.5) d++; return d; };
    const frontZ = () => { let z = 1e9; for (const c of s2.coins.values()) { const p = c.body.translation(); if (p.y < GEOM.deckY - 0.5 && Math.abs(p.x) < 8) z = Math.min(z, p.z); } return z; };
    const got = {};
    const deck0 = onDeck(), front0 = frontZ();
    for (let i = 0; i < 20; i++) {
      while (s2.outness() < 0.9) s2.run(1 / 60);
      s2.drop((i % 5 - 2) * 6);
      s2.run(GEOM.period);
      for (const e of s2.step(0)) got[e.type] = (got[e.type] || 0) + 1;
    }
    const swept = deck0 + 20 - onDeck();
    assert.ok(swept >= 3, 'coins swept off the deck: ' + swept + ' (deck ' + deck0 + ' -> ' + onDeck() + ')');
    assert.ok(frontZ() <= front0 + 0.3 || (got.cup || 0) >= 1, 'the main heap did not go backward: front ' + front0.toFixed(2) + ' -> ' + frontZ().toFixed(2));
    assert.ok(!got.side && !got.tunnel && !got.lost, 'nothing lost at the sides or through the tier: ' + JSON.stringify(got));
    assert.ok(onDeck() < s2.count(), 'coins on both tiers');
    s2.free();
  });

  t('the slot clamps to the position: a drop at x = 99 lands inside the walls', () => {
    const id = sim.drop(99); sim.run(1.0); sim.step(0);
    let c = null; for (const k of sim.coins.values()) if (k.id === id) c = k;
    assert.ok(Math.abs(c.body.translation().x) < GEOM.halfW, 'x ' + c.body.translation().x.toFixed(1));
  });

  t('save/restore: the same coins come back where they were, asleep, and the phase is kept', () => {
    sim.run(1.0); sim.step(0);
    const s = sim.save();
    assert.strictEqual(s.coins.length, sim.count() * 7);
    const first = s.coins.slice(0, 3);
    const sim2 = createSim(R, { lipMm: 1 }).restore(JSON.parse(JSON.stringify(s)));
    assert.strictEqual(sim2.count(), sim.count());
    const p = sim2.coins.values().next().value.body.translation();
    assert.ok(Math.abs(p.x - first[0]) < 1e-3 && Math.abs(p.y - first[1]) < 1e-3 && Math.abs(p.z - first[2]) < 1e-3, 'first coin pose');
    assert.ok(Math.abs(sim2.t - s.t) < 1e-9, 'phase');
    sim2.run(2.0); const ev = sim2.step(0);
    assert.ok(!ev.some(e => e.type === 'tunnel' || e.type === 'lost' || e.type === 'side'), 'settles without losing coins');
    sim2.free();
  });

  t('restore drops a coin saved off this field (an older machine\'s side hole, say) instead of spawning it in a wall', () => {
    const s = sim.save();
    const a = s.coins.slice();
    a.push(GEOM.halfW + 1, 0.5, 8, 0, 0, 0, 1);      // past the wall
    a.push(0, 0.5, WZ + 10, 0, 0, 0, 1);              // behind the wall
    const sim3 = createSim(R, { lipMm: 1 }).restore({ t: 0, coins: a });
    assert.strictEqual(sim3.count(), sim.count());
    sim3.free();
  });

  t('the gate: coins over the front edge go to the cup, or to the house while the gate is over', () => {
    const s3 = createSim(R, { lipMm: 0 }).fresh(3, 400, 2);
    const got = {};
    for (let i = 0; i < 40; i++) { s3.nudge(0, 1, 1); s3.run(0.6); for (const e of s3.step(0)) got[e.type] = (got[e.type] || 0) + 1; }
    assert.ok((got.cup || 0) >= 1, 'bumps at lip 0 send coins to the cup: ' + JSON.stringify(got));
    assert.ok(!got.tunnel && !got.lost && !got.side, 'no tunnel/lost/side: ' + JSON.stringify(got));
    s3.free();
    const s4 = createSim(R, { lipMm: 0 }).fresh(4, 400, 2);
    s4.setGate('house');
    const got2 = {};
    for (let i = 0; i < 40; i++) { s4.nudge(0, 1, 1); s4.run(0.6); for (const e of s4.step(0)) got2[e.type] = (got2[e.type] || 0) + 1; }
    assert.ok((got2['house-tilt'] || 0) >= 1 && !got2.cup, 'with the gate over they go to the house: ' + JSON.stringify(got2));
    s4.free();
  });

  t('setLip moves the lip and wakes the heap; lipMm reads back', () => {
    sim.setLip(4); assert.strictEqual(sim.lipMm, 4); assert.ok(sim.awake() > 100);
    sim.setLip(0); assert.strictEqual(sim.lipMm, 0);
  });

  sim.free();
  console.log(n + ' tests passed');
})().catch(e => { console.error(e); process.exit(1); });
