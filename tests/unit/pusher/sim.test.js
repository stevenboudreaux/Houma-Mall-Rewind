// node tests/unit/pusher/sim.test.js : the COIN COMET physics world (prototypes/godot-mall/play/pusher/sim.js)
// headless on Rapier: the crank, a fresh fill, a drop that lands on the deck, the save/restore
// round trip, the side holes, and that nothing goes through the shelf. ~30 s.
const assert = require('assert');
let n = 0;
function t(name, f) { f(); n++; console.log('ok', name); }

(async () => {
  const R = (await import('../../../prototypes/godot-mall/play/lib/rapier3d-compat.mjs')).default;
  const { createSim, deckZ, GEOM } = await import('../../../prototypes/godot-mall/play/pusher/sim.js');
  await R.init({});

  t('the crank: period and travel from GEOM (tuned Nov 2: 2.5 s, 9.5 cm) about deckFront, back at t = 0', () => {
    const z0 = deckZ(0), zh = deckZ(GEOM.period / 2), z1 = deckZ(GEOM.period);
    assert.ok(Math.abs(z0 - z1) < 1e-9, 'periodic');
    let lo = 1e9, hi = -1e9;
    for (let k = 0; k < 900; k++) { const z = deckZ(k * GEOM.period / 900); lo = Math.min(lo, z); hi = Math.max(hi, z); }
    // the deck's travel: the crank's throw plus the drive's play it snaps across at each end (5.0 cm measured)
    assert.ok(Math.abs((hi - lo) - (GEOM.stroke + 2 * GEOM.snap)) < 0.02 && Math.abs((hi - lo) - 9.5) < 0.05, 'travel ' + (hi - lo).toFixed(3));
    assert.ok(z0 > GEOM.deckFront && zh < GEOM.deckFront, 'back at 0, forward at half');
  });

  const sim = createSim(R, { lipMm: 2.5 }).fresh(7, 540, 2);
  t('a fresh machine: about 540 coins, every one on a tier (none fallen), both tiers packed', () => {
    assert.ok(Math.abs(sim.count() - 540) <= 45, 'count ' + sim.count());      // (45: the tuned 9 cm stroke settles a few more over the edge) the fill gives back what settled over the edge or into a hole
    let deck = 0, shelf = 0;
    for (const c of sim.coins.values()) { const p = c.body.translation(); assert.ok(p.y > -0.5, 'below the shelf'); if (p.y > GEOM.deckY - 0.5) deck++; else shelf++; }
    assert.ok(shelf > 250 && deck > 200, 'shelf ' + shelf + ' deck ' + deck);
  });

  t('a drop at x = 5 lands on the deck near the wall and stays on the field', () => {
    const before = sim.count();
    const id = sim.drop(5);
    sim.run(1.5);
    const ev = sim.step(0);
    // a fresh heap at this friction still sheds a few coins into the holes while it settles
    assert.ok(sim.count() <= before + 1 && sim.count() > before - 40, 'count ' + sim.count() + ' from ' + before);
    assert.ok(!ev.some(e => e.type === 'tunnel' || e.type === 'lost'), 'no tunnel/lost');
    let c = null; for (const k of sim.coins.values()) if (k.id === id) c = k;
    const p = c.body.translation();
    assert.ok(p.y > GEOM.deckY - 0.5 && p.y < GEOM.deckY + 2, 'on the deck, y ' + p.y.toFixed(2));
    assert.ok(p.z > GEOM.wallZ - 8 && p.z < GEOM.wallZ, 'near the wall, z ' + p.z.toFixed(1));
    assert.ok(Math.abs(p.x - 5) < 6, 'under the slot, x ' + p.x.toFixed(1));
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
    const sim2 = createSim(R, { lipMm: 2.5 }).restore(JSON.parse(JSON.stringify(s)));
    assert.strictEqual(sim2.count(), sim.count());
    const p = sim2.coins.values().next().value.body.translation();
    assert.ok(Math.abs(p.x - first[0]) < 1e-3 && Math.abs(p.y - first[1]) < 1e-3 && Math.abs(p.z - first[2]) < 1e-3, 'first coin pose');
    assert.ok(Math.abs(sim2.t - s.t) < 1e-9, 'phase');
    sim2.run(2.0); const ev = sim2.step(0);
    assert.ok(!ev.some(e => e.type === 'tunnel' || e.type === 'lost'), 'settles without losing coins');
    sim2.free();
  });

  t('the gate: coins over the front edge go to the cup, or to the house while the gate is over', () => {
    const s3 = createSim(R, { lipMm: 0 }).fresh(3, 540, 2);
    const got = {};
    for (let i = 0; i < 40; i++) { s3.nudge(0, 1, 1); s3.run(0.6); for (const e of s3.step(0)) got[e.type] = (got[e.type] || 0) + 1; }
    assert.ok((got.cup || 0) >= 1, 'bumps at lip 0 send coins to the cup: ' + JSON.stringify(got));
    assert.ok(!got.tunnel && !got.lost, 'no tunnel/lost: ' + JSON.stringify(got));
    s3.free();
    const s4 = createSim(R, { lipMm: 0 }).fresh(4, 540, 2);
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
