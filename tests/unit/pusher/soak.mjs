// node tests/unit/pusher/soak.mjs <lipMm> <coins> <drops> [seed] [warm] [geomJSON]
// geomJSON overrides sim.js GEOM for a tuning sweep, e.g. '{"coinFriction":0.10,"steelFriction":0.10}'.
// The COIN COMET soak (design/storefronts/pocket-change.md "COIN COMET is playable"): one position
// (play/pusher/sim.js) headless, a quarter dropped every 1.6 s of machine time at a random x,
// fast-forwarded. `warm` drops first bring the heaps to their steady state (a fresh machine stores
// coins until its heaps are full), then `drops` are measured: the return to player (cup / drops),
// the side holes' take, coins a minute, and the physics checks (tunnel = through the shelf, lost =
// out of the world). About 0.5 s of wall time a drop with 450 coins on one core.
import R from '../../../prototypes/godot-mall/play/lib/rapier3d-compat.mjs';
import { createSim } from '../../../prototypes/godot-mall/play/pusher/sim.js';
await R.init({});
const [lip, N, drops, seed = 1, warm = 600] = process.argv.slice(2, 7).map(Number);
const geom = process.argv[7] ? JSON.parse(process.argv[7]) : {};
const sim = createSim(R, { lipMm: lip, geom }).fresh(seed, N, 3);
const cap = sim.capacity;
sim.seed(seed * 7 + 3);
let rs = 12345 + seed; const rnd = () => { rs = (rs * 1664525 + 1013904223) >>> 0; return rs / 4294967296; };
const gap = 1.6, t0 = performance.now();
function play(n, L) { for (let d = 1; d <= n; d++) { sim.drop((rnd() * 2 - 1) * 18); sim.run(gap); for (const e of sim.step(0)) L[e.type] = (L[e.type] || 0) + 1; } }
const Lw = {}; play(warm, Lw);
const L = { cup: 0, side: 0, tunnel: 0, lost: 0 }; play(drops, L);
const T = (performance.now() - t0) / 1000;
console.log(`geom=${JSON.stringify(geom)} lip=${lip}mm coins=${N}/${cap} warm=${warm}(${JSON.stringify(Lw)}) drops=${drops}: RTP=${(100 * L.cup / drops).toFixed(1)}% side=${(100 * L.side / drops).toFixed(1)}% tunnel=${L.tunnel} lost=${L.lost} onfield=${sim.count()} cup/min=${(L.cup / (drops * gap / 60)).toFixed(2)} wall=${T.toFixed(0)}s`);
