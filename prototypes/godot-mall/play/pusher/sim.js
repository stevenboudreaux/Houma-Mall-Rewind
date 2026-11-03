/* COIN COMET playfield physics (play/pusher.html). One player position of the two-tier
 * pusher, as a Rapier world. No DOM and no three.js: the page draws what this moves, and
 * the Node soak (tests/unit/pusher/soak.mjs) runs the very same world headless.
 *
 * Units: centimetres, grams, seconds (gravity 981 cm/s^2). The quarter is 2.426 cm across,
 * 0.175 cm thick and 5.67 g (US Mint). Frame: x to the player's right, y up, z into the
 * machine; z = 0 is the main tier's front (drop) edge, y = 0 its top.
 *
 * The machine, as Steven described it (Nov 3, 2026; design/research/coin-pusher-mechanics.md):
 * two tiers. The top tier is a motorised shelf (the deck) that slides out toward the glass
 * and back in under a fixed back wall. A dropped coin lands on the deck; while the deck is
 * out, a gap stands open between the wall and the coins riding the deck, and a coin that
 * lands in it is the one that moves things: when the deck slides back in, the wall holds
 * that coin and it shoves the deck's row forward, and the front-most coins fall off the
 * deck's edge onto the main tier, an inch or so lower. When the deck slides out again its
 * front face pushes the main tier's heap toward the drop edge, and whatever hangs over the
 * lip falls into the payout chute. The sides are walled: no side holes (workstream PUSHER
 * rebuild; the Nov 1 build copied the teardown machine's holes to the house and lost a fifth
 * of the coins there).
 *
 * What is measured and what is guessed: design/storefronts/pocket-change.md "COIN COMET
 * plays like a pusher". The numbers in GEOM are the game's: the teardown machine's stroke
 * (~50 mm) and period (~4.5 s) are the starting point, the tier step and the main tier's
 * depth are the video's proportions (about an inch; about eight rows), and the rest is tuned
 * for play (tests/unit/pusher/soak.mjs).
 *
 * The world is built from GEOM (below) and one config object (CONFIG in logic.js passes
 * lipMm, quality, ...). Usage:
 *   const sim = createSim(RAPIER, { lipMm: 2.5, geom: {...} });
 *   sim.fresh(seed) or sim.restore(saved);
 *   sim.drop(x);            // a quarter leaves the coin chute at x (cm)
 *   sim.step(dt);           // fixed 120 Hz steps inside; returns events since the last call
 *   sim.nudge(dir, power);  // a bump of the cabinet
 *   sim.setGate('house'|'player');
 *   sim.save();             // coin poses for localStorage
 */

export const GEOM = {
  halfW: 25.2,        // inner half width (COIN COMET's 0.527 m position less its fins)
  shelfLen: 60,       // the main tier runs back under the deck
  deckY: 3.0,         // the deck's top above the main tier ("an inch or two lower"; the video's step looks like one)
  deckFront: 22.0,    // mean z of the deck's front face: 9 rows of quarters to the drop edge (the video's shelf: ~8)
  deckLen: 40,        // deck block length (its back always stays under the back wall)
  stroke: 6.0,        // cm, the deck's travel (the teardown machine: ~50 mm; a little more reads better at this size)
  period: 3.0,        // s per crank turn (the teardown machine: ~4.5 s; faster plays better)
  rod: 11,            // connecting rod (guess; it only shapes the motion a little)
  rumble: 0.01,       // cm: the deck's vertical shake from the gear motor (the video: "kind of loud", a bearing rattle)
  rumbleHz: 23,
  snap: 0.25,         // cm: the backlash in the crank's drive. At each reversal the deck stands for a moment and then
                      //     snaps through the play (the clunk); the jolt is what makes the loose top coins slide
  deckOut: 14.0,      // cm of deck top in front of the back wall when the deck is fully out (the gap the player aims
                      //     for); when it is in, deckOut - stroke stays exposed
  wallGap: 0.05,      // the wall's bottom edge above the deck: well under a coin's half thickness
  chuteBack: 1.5,     // the coin lands this far in front of the back wall's face (right in the gap)
  chuteY: 9.0,        // the coin chute's foot above the deck
  tiltDeg: 0,         // the whole playfield's forward tilt (a real cabinet's playfield slopes a little toward the glass)
  coinR: 1.213,
  coinHH: 0.0875,     // half thickness
  coinDensity: 7.01,  // g/cm^3 -> 5.67 g
  coinFriction: 0.06, // coin on coin (TUNED; dry cupronickel is ~0.3: at real friction a rigid-body heap climbs instead of flowing)
  coinRest: 0.12,
  steelFriction: 0.06, // coin on the deck and tier
  nudgeV0: 1.5,       // cm/s the heap is jolted by the lightest bump ...
  nudgeV1: 2.5,       // ... plus this at full power
  guideFoot: 20.7,    // |x| where the side guides (the blue art ramps) meet the main tier ...
  guideTop: 5.3,      // ... rising this high at the side wall: a coin pushed sideways rides up and slides back
  guideLen: 38,       // the guides run from the drop edge this far back (past the riser)
  fillTilt: 0.45,     // rad: how far the fill's coins are tilted (a jumble flows; a perfect lattice jams)
  fillJitter: 0.5,    // cm
};

/** Deck front z at time t (crank-slider, throw stroke/2, rod G.rod). */
export function deckZ(t, G = GEOM) {
  const r = G.stroke / 2, l = G.rod;
  const th = 2 * Math.PI * t / G.period;
  const s = Math.sin(th);
  // slider from the crank centre, minus its mean, so deckFront is the middle of the stroke
  const x = r * Math.cos(th) + Math.sqrt(l * l - r * r * s * s);
  const mean = l - (r * r) / (4 * l);   // close enough to the mean of the term above
  // the drive's play: the deck sits a little behind the crank in its direction of travel, so at
  // each reversal it stands still while the crank takes up the slack, then snaps across it
  const vsign = -Math.sin(th) >= 0 ? 1 : -1;      // sign of dx/dt
  const snap = (G.snap || 0) * vsign;
  return G.deckFront + (x - mean) - snap;
}


/** The deck's travel: [zOut, zIn] of its front face (sampled once per geometry; the rod makes the
 *  stroke a little asymmetric about deckFront). */
const travelCache = new WeakMap();
export function deckTravel(G = GEOM) {
  let r = travelCache.get(G);
  if (r) return r;
  let lo = 1e9, hi = -1e9;
  for (let k = 0; k < 720; k++) { const z = deckZ(k * G.period / 720, G); lo = Math.min(lo, z); hi = Math.max(hi, z); }
  r = [lo, hi]; travelCache.set(G, r);
  return r;
}

/** The fixed back wall's front face: deckOut in front of the deck's face when it is fully out. */
export function wallZ(G = GEOM) { return deckTravel(G)[0] + G.deckOut; }

/** How far the deck is out, 0 (fully in) .. 1 (fully out), at time t. */
export function deckOutness(t, G = GEOM) {
  const [zOut, zIn] = deckTravel(G);
  return Math.max(0, Math.min(1, (zIn - deckZ(t, G)) / (zIn - zOut)));
}

export function createSim(R, opts = {}) {
  const G = Object.assign({}, GEOM, opts.geom || {});
  const HZ = opts.hz || 120;
  const DT = 1 / HZ;
  let lipH = Math.max(0, (opts.lipMm ?? 2.5) / 10);    // cm
  const tilt = (G.tiltDeg || 0) * Math.PI / 180;
  const world = new R.World({ x: 0, y: -981 * Math.cos(tilt), z: -981 * Math.sin(tilt) });
  world.timestep = DT;
  const ip = world.integrationParameters;
  if (ip) {
    if ('numSolverIterations' in ip) ip.numSolverIterations = opts.iters || 4;
    if ('numInternalPgsIterations' in ip) ip.numInternalPgsIterations = opts.pgs || 1;
    if ('lengthUnit' in ip) ip.lengthUnit = 1.0;
  }
  const WZ = wallZ(G);

  const fixed = world.createRigidBody(R.RigidBodyDesc.fixed());
  const box = (cx, cy, cz, hx, hy, hz, fr, body = fixed) =>
    world.createCollider(R.ColliderDesc.cuboid(hx, hy, hz).setTranslation(cx, cy, cz)
      .setFriction(fr ?? G.steelFriction).setRestitution(0.05), body);

  // ---- the main tier: one slab, walled on both sides from below it to the glass (no side holes)
  const T = 1.0, W = G.halfW, L = G.shelfLen;
  box(0, -T, L / 2, W, T, L / 2);
  for (const s of [-1, 1]) {
    box(s * (W + 0.5), 20, L / 2 - 4, 0.5, 30, L / 2 + 4);
    // the side guide: a slab tilted up from the tier at guideFoot to the wall at guideTop
    if (G.guideFoot && G.guideFoot < W) {
      const run = W - G.guideFoot, rise = G.guideTop, ang = Math.atan2(rise, run), len = Math.hypot(run, rise);
      const cx = s * (G.guideFoot + run / 2), cy = rise / 2;
      const half = Math.sin(ang / 2), c2 = Math.cos(ang / 2);
      // rotate about z by -s*ang: the slab's +x climbs toward the wall; thick enough underneath that nothing tunnels
      const th = 1.5;
      const nx = s * Math.sin(ang) * th / 2, ny = -Math.cos(ang) * th / 2;   // shift down along the slab's normal (it rises toward the wall)
      world.createCollider(R.ColliderDesc.cuboid(len / 2, th / 2, G.guideLen / 2).setTranslation(cx + nx, cy + ny, G.guideLen / 2 - 1.0)
        .setRotation({ x: 0, y: 0, z: s * half, w: c2 }).setFriction(G.steelFriction).setRestitution(0.05), fixed);
    }
  }
  // the back wall: fixed, reaching down into the deck (the two ignore each other), so no coin
  // squeezed against it can slip under its edge; what the player sees is its bottom edge wallGap
  // over the deck
  box(0, G.deckY + 19, WZ + 0.5, W, 20, 0.5);
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
  // the block reaches down into the tier (a fixed and a kinematic body ignore each other), so
  // no coin can get under the riser
  world.createCollider(R.ColliderDesc.cuboid(W - 0.02, (G.deckY + 1.0) / 2, G.deckLen / 2)
    .setTranslation(0, (G.deckY - 1.0) / 2, 0).setFriction(G.steelFriction).setRestitution(0.05), deck);

  // ---- coins
  const coins = new Map();       // handle -> {body, id, born, ccd}
  let nextId = 1;
  // a rounded cylinder: the same size, and a quarter cheaper in the narrow phase than a sharp one
  const cdesc = () => (G.sharp ? R.ColliderDesc.cylinder(G.coinHH, G.coinR) : R.ColliderDesc.roundCylinder(G.coinHH - 0.02, G.coinR - 0.02, 0.02))
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
    const y = G.rumble * Math.sin(2 * Math.PI * G.rumbleHz * t);
    deck.setNextKinematicTranslation({ x: 0, y, z: deckZ(t, G) + G.deckLen / 2 });
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
        if (p.z < 1.5 && Math.abs(p.x) <= W) where = gate === 'player' ? 'cup' : 'house-tilt';
        else if (Math.abs(p.x) > W) where = 'side';     // past a side wall: a physics failure now that the sides are walled
        else where = 'tunnel';     // through the tier: a physics failure, counted so the soak sees it
        out.push([c, where, p.x]);
      } else if (p.y > 60 || Math.abs(p.x) > W + 3 || p.z > WZ + 30) {
        out.push([c, 'lost', p.x]);
      }
    });
    for (const [c, where, x] of out) { removeCoin(c); events.push({ type: where, t, x, id: c.id }); }
  }

  const api = {
    G, world, coins,
    get t() { return t; }, set t(v) { t = v; moveDeck(); },
    get gate() { return gate; },
    get lipMm() { return lipH * 10; },
    get wallZ() { return WZ; },
    setLip(mm) { lipH = Math.max(0, mm / 10); makeLip(); for (const c of coins.values()) c.body.wakeUp(); },
    setGate(g) { gate = g; },
    deckZ: () => deckZ(t, G),
    outness: () => deckOutness(t, G),
    count: () => coins.size,
    get steps() { return stepCount; },
    awake() { let n = 0; world.forEachActiveRigidBody(() => n++); return n; },

    /** A fresh machine: n coins laid on both tiers (the main tier's layer first, from the lip
     *  back to the riser; then the deck's, from the wall forward; then second layers on the
     *  main tier's front half and the deck's back; then third layers over the middle of each),
     *  then settled. A primed machine (operators fill theirs by hand before play) holds about
     *  three layers: logic.js CONFIG.quality.high asks for that many, low for two. */
    fresh(seed = 1, n = 400, settle = 4) {      // n: logic.js CONFIG.quality
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
      const zMin = G.deckFront + G.stroke / 2 - 1.35;   // the main heap reaches the riser (the deck starts at the back of its stroke)
      const shelfW = (G.guideFoot && G.guideFoot < W ? G.guideFoot : W) - 1.4;
      const s1 = layer(2.0, zMin, 0.4, shelfW);      // the first row a little back from the lip, so the fill does not pay by itself
      const d1 = layer(G.deckFront + 1.6, WZ - 1.28, G.deckY + 0.4, shelfW);
      const s2 = layer(2.0 + rowP / 2, zMin * 0.55, 0.75, shelfW - pitch / 2);
      const d2 = layer(G.deckFront + 1.6 + (WZ - G.deckFront) * 0.4, WZ - 1.28 - rowP / 2, G.deckY + 0.75, shelfW - pitch / 2);
      const s3 = layer(2.0 + rowP, zMin * 0.8, 1.1, shelfW - pitch / 2);
      const d3 = layer(G.deckFront + 1.6 + (WZ - G.deckFront) * 0.25, WZ - 1.28 - rowP, G.deckY + 1.1, shelfW - pitch);
      spots.push(...s1, ...d1, ...s2, ...d2, ...s3, ...d3);
      const take = Math.min(n, spots.length);
      // the lattice is broken up on purpose: a perfect hex packing between two walls jams like a
      // crystal (pushes arch across it and the pushing coin climbs instead); a jumble of tilted,
      // overlapping coins, as a real heap is, flows
      for (let i = 0; i < take; i++) {
        const [x, y, z] = spots[i];
        const j = G.fillJitter;
        addCoin({ x: x + (rnd() - 0.5) * j, y: y + rnd() * 0.6, z: z + (rnd() - 0.5) * j },
          flatQ(rnd() * 6.283, rnd() * G.fillTilt, rnd() * 6.283), null, false, false);
      }
      api.capacity = spots.length;
      api.run(settle, true);
      // a fresh machine must not pay by itself: whatever settled hanging over the drop edge goes
      // back to the house before the player sees it
      for (const c of [...coins.values()]) {
        const p = c.body.translation();
        if (p.y < 3 && p.z < 1.3) removeCoin(c);
      }
      api.run(1.0, true);
      events.length = 0;
      return api;
    },

    /** Run for s seconds of machine time (no events kept when quiet). */
    run(s, quiet) {
      const n = Math.round(s * HZ);
      for (let i = 0; i < n; i++) api.tick();
      if (quiet) { api.lastEvents = events.splice(0); }
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

    /** A quarter leaves the chute's foot at x (cm, clamped inside the position), falling
     *  straight down just in front of the back wall: into the gap when the deck is out. */
    drop(x) {
      x = Math.max(-W + 1.5, Math.min(W - 1.5, x));
      const q = flatQ(rnd() * 6.283, 1.2 + rnd() * 0.3, Math.PI / 2);   // on edge-ish, rolling out of the chute
      const c = addCoin({ x, y: G.deckY + G.chuteY, z: WZ - G.chuteBack }, q, { x: (rnd() - 0.5) * 6, y: -40, z: -(rnd() * 3) }, false, true);
      return c.id;
    },

    /** A bump of the cabinet: every coin on the playfield gets a jolt (the cabinet moves, the
     *  coins slide on); dir is the push direction in the xz plane, power 0..1. */
    nudge(dx, dz, power) {
      const v = G.nudgeV0 + G.nudgeV1 * Math.max(0, Math.min(1, power));    // cm/s, a hand's shove (tuned, see GEOM)
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

    /** Put back coins saved by save(); they start asleep where they were. A coin saved off this
     *  geometry's field (an older machine's) is dropped. */
    restore(s) {
      for (const c of [...coins.values()]) removeCoin(c);
      t = +s.t || 0; moveDeck();
      const a = s.coins || [];
      for (let i = 0; i + 6 < a.length; i += 7) {
        const q = { x: a[i + 3], y: a[i + 4], z: a[i + 5], w: a[i + 6] };
        const n = Math.hypot(q.x, q.y, q.z, q.w) || 1;
        if (Math.abs(a[i]) > W - G.coinR * 0.5 || a[i + 2] < -1 || a[i + 2] > WZ + 2 || a[i + 1] < -1) continue;
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
