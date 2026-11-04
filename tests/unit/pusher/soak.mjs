// node tests/unit/pusher/soak.mjs <lipMm> <coins> <drops> [seed] [warm] [geomJSON] [gapSeconds] [phase]
// phase: 'random' (default), 'out' (every drop lands while the deck is out: the gap open) or 'in'.
// geomJSON overrides sim.js GEOM for a tuning sweep, e.g. '{"coinFriction":0.10,"tiltDeg":2}'.
// The COIN COMET soak (design/storefronts/pocket-change.md "COIN COMET plays like a pusher"): one
// position (play/pusher/sim.js) headless, a quarter dropped every `gap` seconds of machine time
// (default 1.6) at a random x, fast-forwarded. `warm` drops first bring the heaps to their
// steady state (a fresh machine stores coins until its heaps are full), then `drops` are
// measured:
//   RTP        return to player: coins into the cup / coins dropped
//   pay%       drops followed by at least one coin into the cup before the next drop
//   cascades   runs of cup coins less than 1.2 s apart, of 3 or more; the biggest run
//   side/tunnel/lost  physics failures (the sides are walled: side must be 0)
//   storing    coins on the field at the end less at the start of the measured run
//   ms/step    the wall time of one 120 Hz step (what a phone pays; the cloud box is one slow core)
import R from '../../../prototypes/godot-mall/play/lib/rapier3d-compat.mjs';
import { createSim } from '../../../prototypes/godot-mall/play/pusher/sim.js';
await R.init({});
const [lip, N, drops, seed = 1, warm = 150] = process.argv.slice(2, 7).map(Number);
const geom = process.argv[7] ? JSON.parse(process.argv[7]) : {};
const gap = process.argv[8] ? Number(process.argv[8]) : 1.6;
const phase = process.argv[9] || 'random';
// the coin takes ~0.17 s from the chute's foot to the deck: aim it so it lands at the phase asked
function waitPhase() { if (phase === 'random') return; let k = 0; while (k++ < 1000) { const o = sim.outness(); if ((phase === 'out' && o > 0.85) || (phase === 'in' && o < 0.15)) return; sim.run(1 / 60); } }
const sim = createSim(R, { lipMm: lip, geom }).fresh(seed, N, 3);
const cap = sim.capacity;
sim.seed(seed * 7 + 3);
let rs = 12345 + seed; const rnd = () => { rs = (rs * 1664525 + 1013904223) >>> 0; return rs / 4294967296; };
const t0 = performance.now();
const cupTimes = [];
function play(n, L, keep) {
  let paid = 0;
  for (let d = 1; d <= n; d++) {
    waitPhase(); sim.drop((rnd() * 2 - 1) * 18); sim.run(gap);
    let got = 0;
    for (const e of sim.step(0)) { L[e.type] = (L[e.type] || 0) + 1; if (e.type === 'cup') { got++; if (keep) cupTimes.push(e.t); } }
    if (got) paid++;
  }
  return paid;
}
const Lw = {}; play(warm, Lw, false);
const start = sim.count();
const s0 = sim.steps, w0 = performance.now();
const L = { cup: 0, side: 0, tunnel: 0, lost: 0 }; const paid = play(drops, L, true);
const msStep = (performance.now() - w0) / Math.max(1, sim.steps - s0);
// cascades: cup coins less than 1.2 s apart
let runs = [], run = 0, last = -1e9;
for (const tc of cupTimes) { if (tc - last < 1.2) run++; else { if (run) runs.push(run); run = 1; } last = tc; }
if (run) runs.push(run);
const casc = runs.filter(r => r >= 3), big = runs.length ? Math.max(...runs) : 0;
const T = (performance.now() - t0) / 1000;
console.log(`geom=${JSON.stringify(geom)} phase=${phase} lip=${lip}mm coins=${N}/${cap} gap=${gap}s warm=${warm}(${JSON.stringify(Lw)}) drops=${drops}: ` +
  `RTP=${(100 * L.cup / drops).toFixed(1)}% pay=${(100 * paid / drops).toFixed(0)}% cascades=${casc.length}(3+)/${drops} big=${big} ` +
  `side=${L.side} tunnel=${L.tunnel} lost=${L.lost} storing=${sim.count() - start} onfield=${sim.count()} ms/step=${msStep.toFixed(2)} wall=${T.toFixed(0)}s`);
