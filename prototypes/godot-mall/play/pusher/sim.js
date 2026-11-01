/* COIN COMET playfield physics (play/pusher.html). One player position of the two-tier
 * pusher, as a Rapier world. No DOM and no three.js: the page draws what this moves, and
 * the Node soak (tests/unit/pusher/soak.mjs) runs the very same world headless.
 *
 * Units: centimetres, grams, seconds (gravity 981 cm/s^2). The quarter is 2.426 cm across,
 * 0.175 cm thick and 5.67 g (US Mint). Frame: x to the player's right, y up, z into the
 * machine; z = 0 is the shelf's front (drop) edge, y = 0 the shelf's top.
 *
 * What is measured and what is guessed: design/storefronts/pocket-change.md,
 * "COIN COMET is playable". The proportions are COIN COMET's (tools/stores/pocket_change/
 * pusher.gd: a 0.527 m position, the shelf 0.38 m to the deck face, the deck 7.5 cm above
 * the shelf, the translite 0.30 m behind the deck face). The deck's crank (period, stroke)
 * is measured from Steven's teardown video (refs/coin_pusher, 607.2-611.9 s).
 *
 * The world is built from GEOM (below) and one config object (CONFIG in logic.js passes
 * lipMm, quality, ...). Usage:
 *   const sim = createSim(RAPIER, { lipMm: 2.5 });
 *   sim.fresh(seed) or sim.restore(saved);
 *   sim.drop(x);            // a quarter leaves the coin chute at x (cm)
 *   sim.step(dt);           // fixed 120 Hz steps inside; returns events since the last call
 *   sim.nudge(dir, power);  // a bump of the cabinet
 *   sim.setGate('house'|'player');
 *   sim.save();             // coin poses for localStorage
 */

export const GEOM = {
  halfW: 25.2,        // inner half width (COIN COMET's 0.527 m position less its fins)
  shelfLen: 72,       // the shelf runs back under the deck
  deckY: 7.5,         // the deck's top above the shelf (pusher.gd Y_PT - Y_SH)
  deckFront: 35.5,    // mean z of the deck's front face (pusher.gd Z_PUSH - Z_DROP, less half the stroke)
  deckLen: 46,        // deck block length (its back always stays under the back wall)
  stroke: 5.0,        // cm, crank throw x 2 (measured: ~50 mm)
  period: 4.5,        // s per crank turn (measured: 4.46-4.62 s)
  rod: 11,            // connecting rod (guess; it only shapes the motion a little)
  wallZ: 66,          // the fixed back wall's front face (deckFront + the translite's 0.30 m)
  wallGap: 0.05,      // the wall's bottom edge above the deck: well under a coin's half thickness
  holeZ0: 3.0,        // the side holes: from 3 cm behind the drop edge ...
  holeZ1: 17.0,       // ... to 17 cm
  holeW: 2.8,         // gap between the shelf and the side wall (a quarter falls in flat)
  chuteY: 11.0,       // the coin chute's foot above the deck
  chuteZ: 64.4,       // ... right at the back wall: a coin lands in the gap that opens behind the heap
                      //     when the deck is forward, and ratchets the heap forward (the real mechanism)
  coinR: 1.213,
  coinHH: 0.0875,     // half thickness
  coinDensity: 7.01,  // g/cm^3 -> 5.67 g
  coinFriction: 0.32, // cupronickel on cupronickel / steel, dry (guess, tuned)
  coinRest: 0.12,
  steelFriction: 0.28,
};

/** Deck front z at time t (crank-slider, throw stroke/2, rod G.rod). */
export function deckZ(t, G = GEOM) {
  const r = G.stroke / 2, l = G.rod;
  const th = 2 * Math.PI * t / G.period;
  const s = Math.sin(th);
  // slider from the crank centre, minus its mean, so deckFront is the middle of the stroke
  const x = r * Math.cos(th) + Math.sqrt(l * l - r * r * s * s);
  const mean = l - (r * r) / (4 * l);   // close enough to the mean of the term above
  return G.deckFront + (x - mean);
}

export function createSim(R, opts = {}) {
  const G = Object.assign({}, GEOM, opts.geom || {});
  const HZ = opts.hz || 120;
  const DT = 1 / HZ;
  let lipH = Math.max(0, (opts.lipMm ?? 2.5) / 10);    // cm
  const world = new R.World({ x: 0, y: -981, z: 0 });
  world.timestep = DT;
  const ip = world.integrationParameters;
  if (ip) {
    if ('numSolverIterations' in ip) ip.numSolverIterations = opts.iters || 4;
    if ('lengthUnit' in ip) ip.lengthUnit = 1.0;
  }

  const fixed = world.createRigidBody(R.RigidBodyDesc.fixed());
  const box = (cx, cy, cz, hx, hy, hz, fr, body = fixed) =>
    world.createCollider(R.ColliderDesc.cuboid(hx, hy, hz).setTranslation(cx, cy, cz)
      .setFriction(fr ?? G.steelFriction).setRestitution(0.05), body);

  // ---- the shelf: a centre slab and side strips, with the two side holes cut out
  const T = 1.0, W = G.halfW, hw = G.holeW, L = G.shelfLen;
  box(0, -T, L / 2, W - hw, T, L / 2);
  for (const s of [-1, 1]) {
    const xc = s * (W - hw / 2);
    box(xc, -T, G.holeZ0 / 2, hw / 2, T, G.holeZ0 / 2);
    box(xc, -T, (G.holeZ1 + L) / 2, hw / 2, T, (L - G.holeZ1) / 2);
    // side walls, from below the shelf to the glass
    box(s * (W + 0.5), 20, L / 2 - 4, 0.5, 30, L / 2 + 4);
  }
  // the back wall: fixed, its bottom edge just over the deck
  const wallB = G.deckY + G.wallGap;
  box(0, wallB + 20, G.wallZ + 0.5, W, 20, 0.5);
  // a lid over the deck behind the chute so nothing escapes over the wall
  // the lip: a ridge along the drop edge, lipH tall (owner setting)
  let lip = null;
  function makeLip() {
    if (lip) world.removeCollider(lip, false);
    lip = lipH > 0.005 ? box(0, lipH / 2, 0.3, W, lipH / 2, 0.3, 0.3) : null;
  }
  makeLip();
  // the cup's floor far below, so nothing falls forever (coins are removed long before)
  box(0, -60, 0, 80, 1, 120);

  // ---- the pusher deck: one kinematic block; its front face is the riser
  const deck = world.createRigidBody(R.RigidBodyDesc.kinematicPositionBased()
    .setTranslation(0, 0, deckZ(0, G) + G.deckLen / 2));
  // the block reaches down into the shelf (a fixed and a kinematic body ignore each other), so
  // no coin can get under the riser
  world.createCollider(R.ColliderDesc.cuboid(W - 0.02, (G.deckY + 1.0) / 2, G.deckLen / 2)
    .setTranslation(0, (G.deckY - 1.0) / 2, 0).setFriction(G.steelFriction).setRestitution(0.05), deck);

  // ---- coins
  const coins = new Map();       // handle -> {body, id, born, ccdUntil}
  let nextId = 1;
  // a rounded cylinder: the same size, and a quarter cheaper in the narrow phase than a sharp one
  const cdesc = () => R.ColliderDesc.roundCylinder(G.coinHH - 0.02, G.coinR - 0.02, 0.02)
    .setDensity(G.coinDensity).setFriction(G.coinFriction).setRestitution(G.coinRest);
  function addCoin(p, q, v, sleep, ccd) {
    const bd = R.RigidBodyDesc.dynamic().setTranslation(p.x, p.y, p.z)
      .setRotation(q).setLinearDamping(0.05).setAngularDamping(0.25).setCcdEnabled(!!ccd);
    if (v) bd.setLinvel(v.x, v.y, v.z);
    if (sleep) bd.setSleeping(true);
    const body = world.createRigidBody(bd);
    world.createCollider(cdesc(), body);
    const c = { body, id: nextId++, born: t, ccd: !!ccd };
    coins.set(body.handle, c);
    return c;
  }
  function removeCoin(c) { coins.delete(c.body.handle); world.removeRigidBody(c.body); }

  // ---- state
  let t = 0;                     // machine time (deck phase)
  let gate = 'player';           // the chute's flipper gate
  let stepCount = 0;
  const events = [];
  let rngState = 1;
  const rnd = () => { rngState = (rngState * 1664525 + 1013904223) >>> 0; return rngState / 4294967296; };

  // a quaternion from a tilt (lying nearly flat, random spin)
  function flatQ(spin, tiltA, tiltDir) {
    // rotate about y by spin, then about a horizontal axis by tiltA
    const cy = Math.cos(spin / 2), sy = Math.sin(spin / 2);
    const ax = Math.cos(tiltDir), az = Math.sin(tiltDir), ct = Math.cos(tiltA / 2), st = Math.sin(tiltA / 2);
    // q = qt * qy
    const qt = { w: ct, x: ax * st, y: 0, z: az * st };
    const qy = { w: cy, x: 0, y: sy, z: 0 };
    return {
      w: qt.w * qy.w - qt.x * qy.x - qt.y * qy.y - qt.z * qy.z,
      x: qt.w * qy.x + qt.x * qy.w + qt.y * qy.z - qt.z * qy.y,
      y: qt.w * qy.y - qt.x * qy.z + qt.y * qy.w + qt.z * qy.x,
      z: qt.w * qy.z + qt.x * qy.y - qt.y * qy.x + qt.z * qy.w,
    };
  }

  function moveDeck() {
    deck.setNextKinematicTranslation({ x: 0, y: 0, z: deckZ(t, G) + G.deckLen / 2 });
  }

  // classify and remove coins that have left the playfield
  function sweep() {
    const out = [];
    world.forEachActiveRigidBody((b) => {
      const c = coins.get(b.handle);
      if (!c) return;
      const p = b.translation();
      if (c.ccd && t - c.born > 1.5 && p.y > -0.5) { b.enableCcd(false); c.ccd = false; }
      if (p.y < -4) {
        let where;
        if (p.z < 1.5) where = gate === 'player' ? 'cup' : 'house-tilt';
        else if (Math.abs(p.x) > W - hw - 0.6 && p.z > G.holeZ0 - 1.5 && p.z < G.holeZ1 + 1.5) where = 'side';
        else where = 'tunnel';     // through the shelf: a physics failure, counted so the soak sees it
        out.push([c, where, p.x]);
      } else if (p.y > 60 || Math.abs(p.x) > W + 3 || p.z > G.wallZ + 30) {
        out.push([c, 'lost', p.x]);
      }
    });
    for (const [c, where, x] of out) { removeCoin(c); events.push({ type: where, t, x }); }
  }

  const api = {
    G, world, coins,
    get t() { return t; }, set t(v) { t = v; moveDeck(); },
    get gate() { return gate; },
    get lipMm() { return lipH * 10; },
    setLip(mm) { lipH = Math.max(0, mm / 10); makeLip(); for (const c of coins.values()) c.body.wakeUp(); },
    setGate(g) { gate = g; },
    deckZ: () => deckZ(t, G),
    count: () => coins.size,
    get steps() { return stepCount; },
    awake() { let n = 0; world.forEachActiveRigidBody(() => n++); return n; },

    /** A fresh machine: n coins laid in packed layers on both tiers (the shelf's heap first,
     *  full to the lip; then the deck's; then a second layer on the shelf's front half and the
     *  deck's back half, as in the video), then settled. */
    fresh(seed = 1, n = 600, settle = 2.5) {      // n: logic.js CONFIG.quality; ~785 fills every spot
      for (const c of [...coins.values()]) removeCoin(c);
      rngState = (seed >>> 0) || 1;
      t = 0; moveDeck();
      const pitch = 2.0 * G.coinR + 0.12, rowP = pitch * 0.866;
      const spots = [];
      const layer = (z0, z1, y, xw) => {      // rows from z1 back to z0, so the last row is at z1
        const out = [];
        let row = 0;
        for (let z = z1; z >= z0; z -= rowP, row++) {
          const off = (row % 2) * pitch / 2;
          for (let x = -xw + off; x <= xw; x += pitch) out.push([x, y, z]);
        }
        return out;
      };
      const zMin = G.deckFront + G.stroke / 2 - 1.35;   // the shelf heap reaches the riser (the deck starts at the back of its stroke)
      const shelfW = W - hw - 0.3;                      // keep off the side holes at first (the heap spreads)
      const s1 = layer(1.6, zMin, 0.4, shelfW);
      const d1 = layer(G.deckFront + 1.6, G.wallZ - 1.28, G.deckY + 0.4, W - 1.5);
      const s2 = layer(1.6 + rowP / 2, zMin * 0.55, 0.75, shelfW - pitch / 2);
      const d2 = layer(G.deckFront + 1.6 + (G.wallZ - G.deckFront) * 0.4, G.wallZ - 1.28 - rowP / 2, G.deckY + 0.75, W - 1.5 - pitch / 2);
      // the shelf's layer first (a pusher that pays needs it packed to the lip), then the deck
      // from the wall forward, then the second layers: a low coin count shortens the deck's heap
      spots.push(...s1, ...d1, ...s2, ...d2);
      const take = Math.min(n, spots.length);
      for (let i = 0; i < take; i++) {
        const [x, y, z] = spots[i];
        const j = 0.06;
        addCoin({ x: x + (rnd() - 0.5) * j, y: y + rnd() * 0.3, z: z + (rnd() - 0.5) * j },
          flatQ(rnd() * 6.283, rnd() * 0.08, rnd() * 6.283), null, false, false);
      }
      api.capacity = spots.length;
      api.run(settle, true);
      events.length = 0;
      return api;
    },

    /** Run for s seconds of machine time (no events kept when quiet). */
    run(s, quiet) {
      const n = Math.round(s * HZ);
      for (let i = 0; i < n; i++) api.tick();
      if (quiet) events.length = 0;
    },

    /** One fixed step. */
    tick() {
      t += DT; moveDeck();
      world.step();
      stepCount++;
      if (stepCount % 4 === 0) sweep();
    },

    /** Advance by dt seconds of real time in fixed steps. A slow frame gets at most 3 steps
     *  (the machine runs a little slow rather than the frame spiralling). Returns events. */
    step(dt) {
      api._acc = (api._acc || 0) + Math.min(dt, 0.05);
      let k = 0;
      while (api._acc >= DT && k < 3) { api.tick(); api._acc -= DT; k++; }
      if (k === 3) api._acc = 0;
      return events.splice(0);
    },

    /** A quarter leaves the chute's foot at x (cm, clamped inside the position). */
    drop(x) {
      x = Math.max(-W + 1.5, Math.min(W - 1.5, x));
      const q = flatQ(rnd() * 6.283, 1.2 + rnd() * 0.3, Math.PI / 2);   // on edge-ish, rolling out of the chute
      const c = addCoin({ x, y: G.deckY + G.chuteY, z: G.chuteZ }, q, { x: (rnd() - 0.5) * 6, y: -40, z: -3 - rnd() * 4 }, false, true);
      return c.id;
    },

    /** A bump of the cabinet: every coin on the playfield gets a jolt (the cabinet moves, the
     *  coins slide on); dir is the push direction in the xz plane, power 0..1. */
    nudge(dx, dz, power) {
      const v = 9 + 14 * Math.max(0, Math.min(1, power));    // cm/s, a hand's shove (guess)
      for (const c of coins.values()) {
        const b = c.body;
        const lv = b.linvel();
        const j = 0.75 + 0.5 * rnd();
        b.setLinvel({ x: lv.x - dx * v * j, y: lv.y + 4 * j * power, z: lv.z - dz * v * j }, true);
      }
    },

    /** Coin poses for saving: [x, y, z, qx, qy, qz, qw] rounded, flat array. */
    save() {
      const a = [];
      for (const c of coins.values()) {
        const p = c.body.translation(), q = c.body.rotation();
        a.push(+p.x.toFixed(3), +p.y.toFixed(3), +p.z.toFixed(3), +q.x.toFixed(4), +q.y.toFixed(4), +q.z.toFixed(4), +q.w.toFixed(4));
      }
      return { t: +(t % G.period).toFixed(3), coins: a };
    },

    /** Put back coins saved by save(); they start asleep where they were. */
    restore(s) {
      for (const c of [...coins.values()]) removeCoin(c);
      t = +s.t || 0; moveDeck();
      const a = s.coins || [];
      for (let i = 0; i + 6 < a.length; i += 7) {
        const q = { x: a[i + 3], y: a[i + 4], z: a[i + 5], w: a[i + 6] };
        const n = Math.hypot(q.x, q.y, q.z, q.w) || 1;
        addCoin({ x: a[i], y: a[i + 1], z: a[i + 2] }, { x: q.x / n, y: q.y / n, z: q.z / n, w: q.w / n }, null, false, false);
      }
      events.length = 0;
      return api;
    },

    seed(s) { rngState = (s >>> 0) || 1; },
    free() { world.free(); },
  };
  return api;
}
