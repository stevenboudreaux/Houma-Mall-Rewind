/* SKEE-BALL rules and ball physics (play/skeeball.html). Pure functions, no DOM, so they can be
 * tested with plain Node (tests/unit/skeeball/logic.test.js).
 *
 * The alley is the mall's own (tools/stores/pocket_change/skee.gd, paint_skee.py): a ten-foot
 * alley 0.64 m wide inside, a lane rising about 8.4 degrees to a ramp hump, then an inclined
 * scoring board with raised rims: rings 10, 20, 30 round a 40 cup, a 50 cup above, and two
 * 100 pockets in the top corners. Each ring's hole is at the bottom of its band.
 *
 * Read from Steven's video (tnt-amusements-382-10-foot-classic-skeeball..., Oct 11 2026):
 * - 9 balls a game; the LED shows the score (3 digits, always a multiple of 10) and the
 *   balls played; a good roller takes about 2.4 s a ball (250 in 9 balls, 92 s to 111 s);
 * - balls are counted when they drop through a hole; balls are rolled one after another, often
 *   with the last one still on the board.
 * Not in the video (guesses, all here in CONFIG): the ticket table, the 100-pocket bonus, the
 * power meter and every physics constant (tuned so a held-and-released roll behaves like the
 * real lane: too soft rolls back, a firm roll lands in the rings, too hard hits the cage).
 *
 * Frame: x = the player's right, y = up, z = into the machine (the front face is z = 0).
 */
(function (root) {
  'use strict';

  var CONFIG = {
    balls: 9,              // balls per game (video)
    priceCents: 25,        // ECON (Nov 3): 1 token a game = 25 cents from the wallet (the coin door: 1 TOKEN)
    // ---- the roll: hold to fill the meter, let go to roll (Steven, Oct 11)
    meterUpMs: 950,        // the meter fills from empty to full in this long ...
    meterPingPong: true,   // ... then falls back and rises again while held
    vMin: 2.6,             // release speed (m/s) at an empty meter
    vMax: 5.0,             // ... and at a full one
    jitterV: 0.012,        // a real lane is not perfect: +-1.2 % speed ...
    jitterDeg: 0.35,       // ... and +-0.35 degrees of line, from the roll's seed
    // ---- tickets (guess; the mall's front panel says "TICKETS PAID ON SCORE" and
    // "100 POCKETS = BONUS")
    pointsPerTicket: 30,
    pocketBonus: 5,        // extra tickets for each ball in a 100 pocket
    ticketMs: 400,         // the dispenser: about 2.5 tickets a second (as WHIRLWIND)
    // ---- physics
    g: 9.81,
    dt: 1 / 600,
    maxT: 9,               // a ball still loose after this long is counted where it lies
    sampleHz: 60           // positions returned for drawing
  };

  // ------------------------------------------------------------------ the alley (skee.gd)
  var A = {
    RX: 0.32, SX: 0.38, W: 0.76, D: 3.12,
    Z_LANE: 0.32, Y_LANE: 0.80, SLOPE: 0.147,
    Z_HUMP: 1.95, Z_LIP: 2.17, HUMP_RISE: 0.085,
    PB: [0, 1.02, 2.24], PT: [0, 1.62, 3.06],
    CAGE_LO: [2.30, 1.40], CAGE_HI: [2.82, 1.80],
    BACK_Z: 3.08, R: 0.036
  };
  (function () {
    var dy = A.PT[1] - A.PB[1], dz = A.PT[2] - A.PB[2], L = Math.sqrt(dy * dy + dz * dz);
    A.BL = L;
    A.DV = [0, dy / L, dz / L];          // up the board
    A.NB = [0, dz / L, -dy / L];         // out of the board (up and toward the player)
    var cy = A.CAGE_HI[1] - A.CAGE_LO[1], cz = A.CAGE_HI[0] - A.CAGE_LO[0], cl = Math.sqrt(cy * cy + cz * cz);
    A.CN = [0, -cz / cl, cy / cl];       // the cage front's face toward the board (down, inward)
  })();

  /** Rims on the board: [u, v, r, height, open top?]. u = 0..0.64 across from the left wall,
   *  v = 0..BL up the slope (paint_skee.py RINGS/HOLES; skee.gd rims). The 10 ring's top half is
   *  open: a ball landing above the rings rolls down into the 10 band. */
  var RIMS = [
    [0.32, 0.40, 0.28, 0.045, true, 99, 1.25],
    [0.32, 0.44, 0.20, 0.040, false, 2.1, 1.25],
    [0.32, 0.47, 0.13, 0.035, false, 2.1, 1.25],
    [0.32, 0.49, 0.058, 0.030, false, 1.9, 2.4],
    [0.32, 0.79, 0.058, 0.030, false, 1.9, 2.4],
    [0.075, 0.875, 0.052, 0.030, false, 1.9, 2.4],
    [0.565, 0.875, 0.052, 0.030, false, 1.9, 2.4]
  ];
  // [5]: how fast a ball inside must hit the rim to hop out (the bands are dished, so a ball in
  // a band is held better than one rolling in; the 10 ring's lower wall keeps every ball in);
  // [6]: how fast a ball outside must hit it to hop in (a cup's lip is rolled: a ball rolling
  // into it from the board glances off; it has to come down into the cup)

  /** Holes: [value, u, v, radius]. A ball drops when its centre is over the hole and it is
   *  slow enough not to skip across. */
  var HOLES = [
    [10, 0.32, 0.180, 0.046], [20, 0.32, 0.290, 0.046], [30, 0.32, 0.386, 0.046],
    [40, 0.32, 0.49, 0.046], [50, 0.32, 0.79, 0.048], [100, 0.075, 0.875, 0.042], [100, 0.565, 0.875, 0.042]
  ];
  var PHYS = {
    eLane: 0.25,           // restitution off the lane, hump and board
    eWall: 0.45,           // off the side walls
    eRim: 0.35,            // off a rim
    eCage: 0.30,           // off the wire cage and the back
    roll: 5 / 7,           // a rolling solid ball accelerates at 5/7 of g's slope component
    crrLane: 0.10,         // rolling resistance, m/s^2 (waxed hardwood)
    crrBoard: 0.55,        // on the painted board (it is rougher, and the bands are dished)
    vDrop: 1.6,            // slower than this over a hole, it drops in
    holeIn: 0.008          // the centre must be this far inside the hole's edge
  };

  function laneY(z) { return A.Y_LANE + (z - A.Z_LANE) * A.SLOPE; }
  function humpY(t) { return laneY(A.Z_HUMP + (A.Z_LIP - A.Z_HUMP) * t) + A.HUMP_RISE * t * t; }
  function humpN(t) {
    var dz = A.Z_LIP - A.Z_HUMP, dy = A.SLOPE * dz + 2 * A.HUMP_RISE * t, l = Math.sqrt(dz * dz + dy * dy);
    return [0, dz / l, -dy / l];
  }
  function dot(a, b) { return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]; }
  function sub(a, b) { return [a[0] - b[0], a[1] - b[1], a[2] - b[2]]; }

  /** Board coordinates of a point: u across, v up the slope, h out of the board. */
  function toBoard(p) {
    var r = sub(p, A.PB);
    return { u: p[0] + A.RX, v: dot(r, A.DV), h: dot(r, A.NB) };
  }
  function fromBoard(u, v, h) {
    return [u - A.RX, A.PB[1] + A.DV[1] * v + A.NB[1] * h, A.PB[2] + A.DV[2] * v + A.NB[2] * h];
  }

  /** The release speed for a meter reading 0..1. */
  function speedFor(power, cfg) {
    cfg = cfg || CONFIG;
    var p = Math.max(0, Math.min(1, power));
    return cfg.vMin + (cfg.vMax - cfg.vMin) * p;
  }

  /** The meter's reading after holding `ms`: fills in meterUpMs, then falls back and rises again. */
  function meter(ms, cfg) {
    cfg = cfg || CONFIG;
    var x = Math.max(0, ms) / cfg.meterUpMs;
    if (!cfg.meterPingPong) return Math.min(1, x);
    var k = x % 2;
    return k <= 1 ? k : 2 - k;
  }

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

  /** Rolls one ball. x0 = where it leaves the hand across the lane (m, clamped to the lane),
   *  power = the meter 0..1, seed = this roll's small imperfection (0 = none).
   *  Returns { value, where, t, pocket, path: [[t, x, y, z], ...], events: [{t, kind, s}] }.
   *  value is 0 for a ball that rolls back or drops short into the gutter. */
  function roll(x0, power, seed, cfg) {
    cfg = cfg || CONFIG;
    var R = A.R, g = cfg.g, dt = cfg.dt;
    var lim = A.RX - R - 0.001;
    var r = seed ? rng(seed) : function () { return 0.5; };
    var v0 = speedFor(power, cfg) * (1 + (r() * 2 - 1) * cfg.jitterV);
    var ang = (r() * 2 - 1) * cfg.jitterDeg * Math.PI / 180;
    var x = Math.max(-lim, Math.min(lim, x0));
    var cs = 1 / Math.sqrt(1 + A.SLOPE * A.SLOPE), sn = A.SLOPE * cs;
    var p = [x, laneY(A.Z_LANE + 0.06) + R / cs, A.Z_LANE + 0.06];
    var v = [v0 * Math.sin(ang), v0 * Math.cos(ang) * sn, v0 * Math.cos(ang) * cs];
    var path = [[0, p[0], p[1], p[2]]], events = [];
    var nextSample = 1 / cfg.sampleHz, t = 0;
    var onBoard = false, landed = false, airborne = false, side = [], crossing = [];
    var res = null;
    function ev(kind, s) { events.push({ t: t, kind: kind, s: s }); }

    // contact with a plane through `o` with unit normal `n` (the ball's side is +n)
    function plane(o, n, e, crr) {
      var d = dot(sub(p, o), n);
      if (d >= R) return false;
      p[0] += n[0] * (R - d); p[1] += n[1] * (R - d); p[2] += n[2] * (R - d);
      var vn = dot(v, n);
      if (vn < 0) {
        var k = -vn > 0.35 ? (1 + e) : 1;   // slow impacts just settle into rolling
        v[0] -= k * vn * n[0]; v[1] -= k * vn * n[1]; v[2] -= k * vn * n[2];
        if (-vn > 0.35) ev('hit', -vn);
      }
      // rolling: only 5/7 of gravity's slope component, less a rolling resistance
      var gn = -g * n[1];                             // g = (0, -g, 0); g.n
      var gt = [0 - gn * n[0], -g - gn * n[1], 0 - gn * n[2]];
      var f = (1 - PHYS.roll);
      v[0] -= gt[0] * f * dt; v[1] -= gt[1] * f * dt; v[2] -= gt[2] * f * dt;
      var vt = [v[0] - dot(v, n) * n[0], v[1] - dot(v, n) * n[1], v[2] - dot(v, n) * n[2]];
      var s = Math.sqrt(dot(vt, vt));
      if (s > 1e-6) {
        var dv = Math.min(s, crr * dt);
        v[0] -= vt[0] / s * dv; v[1] -= vt[1] / s * dv; v[2] -= vt[2] / s * dv;
      }
      return true;
    }

    var steps = Math.ceil(cfg.maxT / dt);
    for (var i = 0; i < steps && !res; i++) {
      t += dt;
      v[1] -= g * dt;
      p[0] += v[0] * dt; p[1] += v[1] * dt; p[2] += v[2] * dt;

      // side walls (the lane's bumpers, then the board's walls)
      if (p[0] > lim) { p[0] = lim; if (v[0] > 0) { if (v[0] > 0.3) ev('wall', v[0]); v[0] = -v[0] * PHYS.eWall; } }
      if (p[0] < -lim) { p[0] = -lim; if (v[0] < 0) { if (v[0] < -0.3) ev('wall', -v[0]); v[0] = -v[0] * PHYS.eWall; } }

      var z = p[2], touching = false;
      if (z < A.Z_HUMP) {
        touching = plane([0, A.Y_LANE, A.Z_LANE], [0, cs, -sn], PHYS.eLane, PHYS.crrLane);
      } else if (z < A.Z_LIP + 0.004) {
        var tt = Math.max(0, Math.min(1, (z - A.Z_HUMP) / (A.Z_LIP - A.Z_HUMP)));
        var n = humpN(tt);
        // the contact is behind the centre on this upward curve: look it up there
        var tc = Math.max(0, Math.min(1, (z - n[2] * R - A.Z_HUMP) / (A.Z_LIP - A.Z_HUMP)));
        n = humpN(tc);
        var zc = A.Z_HUMP + (A.Z_LIP - A.Z_HUMP) * tc;
        touching = plane([0, humpY(tc), zc], n, PHYS.eLane, PHYS.crrLane);
      }

      // the gap between the hump's lip and the board: short balls drop into the gutter
      if (z > A.Z_LIP + 0.01 && z < A.PB[2] + 0.02 && p[1] < A.PB[1] - 0.005) {
        res = { value: 0, where: 'gutter' }; ev('gutter', 0); break;
      }
      // rolled back down to the player
      if (z < A.Z_LANE + 0.02 && v[2] < 0) { res = { value: 0, where: 'back' }; ev('back', 0); break; }

      // the board, its rims and holes
      var b = toBoard(p);
      if (z > A.PB[2] - 0.05 && b.v > -0.02) {
        if (b.v < 0 && b.h < R + 0.01 && v[1] < 0) { res = { value: 0, where: 'gutter' }; ev('gutter', 0); break; }
        var wasAir = b.h > R + 0.004;
        if (b.v >= 0 && b.v <= A.BL && plane(A.PB, A.NB, PHYS.eLane, PHYS.crrBoard)) {
          touching = true;
          if (!landed) { landed = true; ev('land', Math.abs(dot(v, A.NB))); }
          else if (wasAir && airborne) ev('bounce', 0);
          onBoard = true;
          b = toBoard(p);
        }
        // rims: a rim is a wall as high as it is; the ball touches it a ball's radius (plus half
        // the rim) away from the rim's line. A ball above the rim passes over it. A ball rolling
        // into one faster than vHop hops it (it is then crossing until it is clear on the far side).
        var vu = v[0], vv = dot(v, A.DV);
        for (var k = 0; k < RIMS.length; k++) {
          var rm = RIMS[k];
          var du = b.u - rm[0], dvv = b.v - rm[1], dc = Math.sqrt(du * du + dvv * dvv);
          var ri = rm[2] - R - 0.006, ro = rm[2] + R + 0.006;
          if (side[k] === undefined || b.h > R + rm[3]) { side[k] = dc < rm[2]; crossing[k] = false; continue; }
          if (crossing[k]) {
            if (dc < ri) { side[k] = true; crossing[k] = false; }
            else if (dc > ro) { side[k] = false; crossing[k] = false; }
            continue;
          }
          if (rm[4] && b.v > rm[1]) { side[k] = dc < rm[2]; continue; }   // the 10 ring's open top
          var hit = side[k] ? dc > ri : dc < ro;
          if (!hit || dc < 1e-6) continue;
          var nu = du / dc, nv = dvv / dc;
          var vr = vu * nu + vv * nv;                        // + outward
          var into = side[k] ? vr : -vr;                     // speed into the wall
          if (into <= 0) {                                   // already moving away: just keep it out of the wall
            var nr0 = side[k] ? ri : ro;
            p = fromBoard(rm[0] + nu * nr0, rm[1] + nv * nr0, b.h); b = toBoard(p);
            continue;
          }
          if (into > (side[k] ? rm[5] : rm[6])) {                            // hops over: up off the board, slower
            crossing[k] = true;
            var vh = dot(v, A.NB) + 0.35 * into;
            vu = vu - vr * nu * 0.4; vv = vv - vr * nv * 0.4;
            v = [vu, A.DV[1] * vv + A.NB[1] * vh, A.DV[2] * vv + A.NB[2] * vh];
            ev('rim', into);
            continue;
          }
          // bounces off; a ball sitting right on top of a cup is never balanced for long
          if (!side[k] && Math.abs(nu) < 0.06) { nu += (du >= 0 ? 0.06 : -0.06); var nl = Math.sqrt(nu * nu + nv * nv); nu /= nl; nv /= nl; }
          var nr = side[k] ? ri : ro;
          var vr2 = -vr * PHYS.eRim;
          vu = vu - vr * nu + vr2 * nu; vv = vv - vr * nv + vr2 * nv;
          var vh2 = dot(v, A.NB);
          p = fromBoard(rm[0] + nu * nr, rm[1] + nv * nr, b.h);
          v = [vu, A.DV[1] * vv + A.NB[1] * vh2, A.DV[2] * vv + A.NB[2] * vh2];
          if (into > 0.25) ev('rim', into);
          b = toBoard(p);
        }
        // holes
        if (b.h < R + 0.006) {
          var vt2 = Math.sqrt(v[0] * v[0] + dot(v, A.DV) * dot(v, A.DV));
          for (var hI = 0; hI < HOLES.length; hI++) {
            var ho = HOLES[hI];
            var hu = b.u - ho[1], hv = b.v - ho[2];
            if (Math.sqrt(hu * hu + hv * hv) < ho[3] - PHYS.holeIn && vt2 < PHYS.vDrop) {
              res = { value: ho[0], where: 'hole', hole: hI, u: ho[1], v: ho[2] }; ev('hole', ho[0]); break;
            }
          }
          if (res) break;
        }
      }
      // the wire cage over the board and the back above it
      if (z > A.CAGE_LO[0] && z < A.CAGE_HI[0]) plane([0, A.CAGE_LO[1], A.CAGE_LO[0]], A.CN, PHYS.eCage, 0);
      if (p[2] > A.BACK_Z - R) { p[2] = A.BACK_Z - R; if (v[2] > 0) { if (v[2] > 0.3) ev('back', v[2]); v[2] = -v[2] * PHYS.eCage; } }
      airborne = !touching;

      if (t >= nextSample) { path.push([t, p[0], p[1], p[2]]); nextSample += 1 / cfg.sampleHz; }
    }
    if (!res) {
      // still loose: counted in the band it lies in (the machine's sensors would wait it out)
      var bb = toBoard(p), val = 0;
      if (bb.v >= 0 && bb.v <= A.BL) {
        val = 10;
        for (var q = 1; q < 4; q++) {
          var rq = RIMS[q], ddu = bb.u - rq[0], ddv = bb.v - rq[1];
          if (Math.sqrt(ddu * ddu + ddv * ddv) < rq[2]) val = [0, 20, 30, 40][q];
        }
      }
      res = { value: val, where: 'stuck' };
    }
    path.push([t, p[0], p[1], p[2]]);
    res.t = t; res.path = path; res.events = events; res.pocket = res.value === 100;
    res.v0 = v0;
    return res;
  }

  /** Tickets for a finished game: the score table plus the bonus for 100 pockets. */
  function tickets(score, pockets, cfg) {
    cfg = cfg || CONFIG;
    return Math.floor(score / cfg.pointsPerTicket) + pockets * cfg.pocketBonus;
  }

  /** Times (ms after the payout starts) at which each of `n` tickets finishes coming out. */
  function feedTimes(n, cfg) {
    cfg = cfg || CONFIG;
    var out = [];
    for (var i = 0; i < n; i++) out.push((i + 1) * cfg.ticketMs);
    return out;
  }

  var api = { CONFIG: CONFIG, A: A, RIMS: RIMS, HOLES: HOLES, PHYS: PHYS, laneY: laneY, humpY: humpY, humpN: humpN,
              toBoard: toBoard, fromBoard: fromBoard, speedFor: speedFor, meter: meter, rng: rng, roll: roll,
              tickets: tickets, feedTimes: feedTimes };
  if (typeof module !== 'undefined' && module.exports) module.exports = api;
  else root.SKEE = api;
})(this);
