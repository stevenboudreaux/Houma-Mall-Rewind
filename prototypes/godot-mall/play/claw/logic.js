/* CLAW machine rules (play/claw.html). Pure functions, no DOM, testable with plain Node
 * (tests/unit/claw/logic.test.js).
 *
 * The machine is the mall's own (tools/stores/pocket_change/crane.gd): a 0.80 x 0.90 m cabinet
 * with a glass prize box 0.74 m wide x 0.70 m deep above a deck at 0.955 m, the prize chute in
 * the front-left corner, a gantry on rails under the lit ceiling and a three-prong claw on a
 * string.
 *
 * From Steven's video (claw-machine-repair-watch-us-diagnose-and-fix-this-claw-machine.mp4,
 * Oct 11 2026, a Galaxy Games 843 repair): the cycle. On a drop the claw pays out string until
 * it reaches the bottom; the string goes slack, a swing arm trips a switch and THAT closes the
 * claw (not a timer). The claw winds up until the head trips the up-switch, the gantry runs
 * home to the corner over the chute and the claw opens. On power-up it does the same: wind
 * up, go home. If the up-switch never trips the board stops and shows error 01.
 * Not in the video (guesses, all in CONFIG): price, the play clock, gantry speed, claw strength
 * and the operator's payout schedule, and the prizes.
 *
 * Frame: x = the player's right, y = up, z = into the machine (the panel's front edge is z = 0).
 */
(function (root) {
  'use strict';

  var CONFIG = {
    priceCents: 25,        // ECON (Nov 3): 1 token a play = 25 cents from the wallet (the cabinet: 1 TOKEN PER PLAY; $1 = 4 tokens)
    playMs: 30000,         // the play clock: at zero the claw drops where it is (standard)
    speed: 0.14,           // gantry m/s (guess; a 1990s crane crawls)
    dropSpeed: 0.28,       // claw descent m/s
    liftSpeed: 0.22,       // claw winding up m/s
    closeMs: 550,          // the prongs closing
    openMs: 450,
    homeSpeed: 0.20,       // the return home runs a little faster than the joystick
    // the box the claw can reach (gantry limits)
    xMin: -0.30, xMax: 0.30, zMin: 0.27, zMax: 0.82,
    home: [-0.28, 0.29],   // over the chute
    deckY: 0.955,
    clawTopY: 1.52,        // the claw head when wound fully up (housing top)
    clawReach: 0.062,      // a prize's centre must be this close to the claw's axis to be grabbed
    // the chute: anything the claw lets go over this falls to the player
    chute: { x0: -0.39, x1: -0.165, z0: 0.17, z1: 0.405 },
    // ---- the operator's settings (guesses; the mall's cabinets say "EVERY PRIZE CAN BE WON")
    strongEvery: 7,        // every 7th play the claw grips at full strength ("payout")
    weakMin: 0.30, weakMax: 0.55,   // otherwise the grip is somewhere here
    holdWin: 0.62,         // a hold this good carries all the way home
    holdLift: 0.22,        // below this the claw does not even lift the prize
    refillBelow: 9         // the attendant refills the machine when fewer than this are left
  };

  /** Prize kinds. r, h: footprint radius and height in m (how they stack); lift: how well the
   *  claw holds them (1 = a light capsule, less for big or slippery things). All the characters
   *  are this mall's own. */
  var KINDS = {
    gator:     { name: 'Gator plush',          kind: 'plush',   r: 0.062, h: 0.070, lift: 0.70 },
    crawfish:  { name: 'Crawfish plush',       kind: 'plush',   r: 0.050, h: 0.060, lift: 0.80 },
    pelican:   { name: 'Pelican plush',        kind: 'plush',   r: 0.055, h: 0.090, lift: 0.75 },
    nutria:    { name: 'Nutria plush',         kind: 'plush',   r: 0.050, h: 0.062, lift: 0.80 },
    rougarou:  { name: 'Rougarou plush',       kind: 'plush',   r: 0.060, h: 0.110, lift: 0.50 },
    bruiser:   { name: 'Bayou Bruiser stretch figure', kind: 'figure', r: 0.040, h: 0.120, lift: 0.60 },
    comet:     { name: 'Captain Comet plush',  kind: 'plush',   r: 0.055, h: 0.110, lift: 0.65 },
    t75:       { name: '75 tickets',           kind: 'tickets', tickets: 75,  r: 0.038, h: 0.076, lift: 0.92, capsule: true },
    t100:      { name: '100 tickets',          kind: 'tickets', tickets: 100, r: 0.038, h: 0.076, lift: 0.92, capsule: true },
    t200:      { name: '200 tickets',          kind: 'tickets', tickets: 200, r: 0.038, h: 0.076, lift: 0.92, capsule: true },
    pogSkull:  { name: 'POGs: Swamp Skull (3)', kind: 'pogs', pogs: ['Swamp Skull', 'Swamp Skull', 'Swamp Skull'], r: 0.038, h: 0.076, lift: 0.92, capsule: true },
    pogGator:  { name: 'POGs: Gator Bite + Lightning', kind: 'pogs', pogs: ['Gator Bite', 'Lightning', 'Gator Bite'], r: 0.038, h: 0.076, lift: 0.92, capsule: true },
    pogEye:    { name: 'POGs: Eye Spy + 8-Ball', kind: 'pogs', pogs: ['Eye Spy', '8-Ball', 'Eye Spy'], r: 0.038, h: 0.076, lift: 0.92, capsule: true },
    slammer:   { name: 'Hologram Eye slammer', kind: 'slammer', pogs: ['Hologram Eye slammer'], rare: true, r: 0.038, h: 0.076, lift: 0.92, capsule: true }
  };

  /** What a fresh fill holds: [kind, count]. The slammer goes in first, so it is at the bottom. */
  var FILL = [['slammer', 1], ['gator', 3], ['crawfish', 3], ['pelican', 2], ['nutria', 3], ['rougarou', 1], ['bruiser', 2], ['comet', 2],
              ['t75', 4], ['t100', 3], ['t200', 1], ['pogSkull', 2], ['pogGator', 1], ['pogEye', 1]];

  /** A small seeded random generator (mulberry32). */
  function rng(seed) {
    var a = seed >>> 0;
    return function () {
      a = (a + 0x6D2B79F5) >>> 0;
      var t = a;
      t = Math.imul(t ^ (t >>> 15), t | 1);
      t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
      return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
    };
  }

  function clamp(v, a, b) { return Math.max(a, Math.min(b, v)); }
  function inChute(x, z, cfg) { cfg = cfg || CONFIG; var c = cfg.chute; return x > c.x0 && x < c.x1 && z > c.z0 && z < c.z1; }

  /** Stacks the pile: each item's y (its bottom) rests on the highest earlier item it overlaps,
   *  else the deck. Items are in placement order, so the first in is at the bottom. Mutates y. */
  function settle(items, cfg) {
    cfg = cfg || CONFIG;
    for (var i = 0; i < items.length; i++) {
      var it = items[i], k = KINDS[it.kind], y = cfg.deckY;
      for (var j = 0; j < i; j++) {
        var o = items[j], ko = KINDS[o.kind];
        var d = Math.hypot(it.x - o.x, it.z - o.z);
        if (d < (k.r + ko.r) * 0.75) y = Math.max(y, o.y + ko.h * 0.85);
      }
      it.y = y;
    }
    return items;
  }

  /** A fresh fill of the box, placed at random but never over the chute. */
  function fill(seed, cfg) {
    cfg = cfg || CONFIG;
    var r = rng(seed), items = [], id = 0;
    FILL.forEach(function (f) {
      for (var n = 0; n < f[1]; n++) {
        var k = KINDS[f[0]], x, z, tries = 0;
        do {
          x = cfg.xMin + 0.02 + r() * (cfg.xMax - cfg.xMin - 0.04);
          z = cfg.zMin - 0.04 + r() * (cfg.zMax - cfg.zMin + 0.06);
          tries++;
        } while (inChute(x - k.r, z - k.r, cfg) && tries < 50);
        items.push({ id: 'p' + (seed >>> 0).toString(36) + '-' + (id++), kind: f[0], x: x, z: z, y: cfg.deckY, rot: r() * Math.PI * 2 });
      }
    });
    return settle(items, cfg);
  }

  /** The item the claw meets when it drops at (x, z): the highest top within reach. Returns
   *  { item, dist, top } or null (the claw reaches the deck). */
  function target(items, x, z, cfg) {
    cfg = cfg || CONFIG;
    var best = null;
    items.forEach(function (it) {
      var k = KINDS[it.kind], d = Math.hypot(it.x - x, it.z - z);
      if (d > cfg.clawReach + k.r * 0.5) return;
      var top = it.y + k.h;
      if (!best || top > best.top + 0.012 || (Math.abs(top - best.top) <= 0.012 && d < best.dist)) best = { item: it, dist: d, top: top };
    });
    return best;
  }

  /** The grip for play number `n` (1-based): full strength every strongEvery-th play, else weak. */
  function grip(n, rand, cfg) {
    cfg = cfg || CONFIG;
    if (n % cfg.strongEvery === 0) return 1.0;
    return cfg.weakMin + rand() * (cfg.weakMax - cfg.weakMin);
  }

  /** Judges a grab. quality is how centred the claw was (1 = dead centre). The hold decides
   *  whether the prize is lifted at all, and how far along the way home it slips (carry 0..1,
   *  1 = all the way). */
  function judge(tgt, g, cfg) {
    cfg = cfg || CONFIG;
    if (!tgt) return { lifted: false, carry: 0, hold: 0, quality: 0 };
    var k = KINDS[tgt.item.kind];
    var q = clamp(1 - tgt.dist / (cfg.clawReach + k.r * 0.5), 0, 1);
    var hold = g * (0.55 + 0.45 * q) * k.lift;
    if (hold < cfg.holdLift) return { lifted: false, carry: 0, hold: hold, quality: q, item: tgt.item };
    var carry = clamp((hold - cfg.holdLift) / (cfg.holdWin - cfg.holdLift), 0, 1);
    return { lifted: true, carry: carry, hold: hold, quality: q, item: tgt.item };
  }

  /** Where a slipped prize lands: `carry` of the way from the grab point to home. */
  function slipPoint(x, z, carry, cfg) {
    cfg = cfg || CONFIG;
    return [x + (cfg.home[0] - x) * carry, z + (cfg.home[1] - z) * carry];
  }

  /** Applies a finished play to the pile. Returns { won: item|null, moved: item|null }. */
  function resolve(items, x, z, res, cfg) {
    cfg = cfg || CONFIG;
    if (!res.lifted) return { won: null, moved: null, items: items };
    var it = res.item, rest = items.filter(function (o) { return o !== it; });
    if (res.carry >= 1) return { won: it, moved: null, items: settle(rest, cfg) };
    var p = slipPoint(x, z, res.carry, cfg);
    if (inChute(p[0], p[1], cfg)) return { won: it, moved: null, items: settle(rest, cfg), fellIn: true };
    var moved = { id: it.id, kind: it.kind, x: p[0], z: p[1], y: cfg.deckY, rot: it.rot + 1.3 };
    rest.push(moved);                       // dropped on top: last placed is highest
    return { won: null, moved: moved, items: settle(rest, cfg) };
  }

  /** Moves the gantry by a joystick vector for dt seconds, inside the limits. */
  function move(pos, jx, jz, dt, cfg) {
    cfg = cfg || CONFIG;
    var l = Math.hypot(jx, jz); if (l > 1) { jx /= l; jz /= l; }
    return [clamp(pos[0] + jx * cfg.speed * dt, cfg.xMin, cfg.xMax), clamp(pos[1] + jz * cfg.speed * dt, cfg.zMin, cfg.zMax)];
  }

  /** The inventory record for a won prize. */
  function record(item, machine, when) {
    var k = KINDS[item.kind];
    var rec = { id: item.id, kind: k.kind, name: k.name, from: 'claw' + machine, when: when };
    if (k.tickets) rec.tickets = k.tickets;
    if (k.pogs) rec.pogs = k.pogs.slice();
    if (k.rare) rec.rare = true;
    return rec;
  }

  var api = { CONFIG: CONFIG, KINDS: KINDS, FILL: FILL, rng: rng, fill: fill, settle: settle, target: target, grip: grip,
              judge: judge, slipPoint: slipPoint, resolve: resolve, move: move, inChute: inChute, record: record };
  if (typeof module !== 'undefined' && module.exports) module.exports = api;
  else root.CLAW = api;
})(this);
