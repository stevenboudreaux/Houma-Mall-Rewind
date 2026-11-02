/* COIN COMET game rules (play/pusher.html). Pure functions, no DOM and no physics, so they
 * can be tested with plain Node (tests/unit/pusher/logic.test.js). The playfield physics is
 * pusher/sim.js (Rapier); this file is the money, the coin slot, the tilt and the saves.
 *
 * From Steven's teardown video of a Silver Falls quarter pusher (refs/coin_pusher, Nov 2026):
 * - quarters only: a bigger token won't go in; a penny or a dime goes in and is lost (425-450 s);
 * - the tilt: a hanging weight closes a circuit when the cabinet is shaken; the alarm sounds
 *   for 3 s and the chute's flipper gate swings so falling coins go to the house (675-700 s);
 * - the lip at the drop edge is the house's payout control, set with a screwdriver (250-300 s);
 * - the deck's crank: period and stroke measured from 607-612 s (sim.js GEOM).
 * Guessed: how much shaking trips the tilt, the gate's settle time after the alarm, the
 * starting stake, the heap size.
 */
(function (root) {
  'use strict';

  var CONFIG = {
    currency: 'quarters',     // 'quarters' (the count in the player's mall state) or 'tickets'
    startQuarters: 20,        // $5.00 to a new player
    ticketsPerCoin: 1,        // when currency is 'tickets': one ticket plays, one ticket per coin won
    lipMm: 0,                 // the lip's height over the shelf (owner setting). 0 for now: with any lip this sim's
                              // heaps store every coin and pay nothing (soak table in the design note); the real
                              // machine's lip is the house's control and the setting stays for when the flow is right
    lipRange: [0, 6],
    tiltWindowMs: 6000,       // nudges inside this window add up (6 s: at the low friction the sim needs, bumps pay) ...
    tiltTrip: 2.6,            // ... and trip the tilt when their power passes this
    nudgeMinMs: 220,          // a nudge sooner than this after the last is ignored (the cabinet is still rocking)
    tiltAlarmMs: 3000,        // the alarm (measured: "set up for three seconds")
    tiltGateMs: 4000,         // the gate stays on the house side this long (alarm + a settle; guess)
    gateSwingMs: 180,         // the flipper's swing, for the clunk and the picture (guess)
    coinSizes: { quarter: 24.26, token: 25.0, penny: 19.05, dime: 17.91, nickel: 21.21 },   // mm
    slotMm: 24.5,             // a bigger coin won't go in; a smaller one goes in and is lost
    slotHalfW: 23.0,          // cm the coin mechanism slides to either side of the centre
    slotSpeed: 30,            // cm/s with the keys or a stick
    quality: { low: 540, medium: 620, high: 720 },   // coins in a fresh machine (sim.js fresh(): both single layers full at 525, then the ridges)
    positions: 6,             // three per side
    saveVersion: 1,
  };

  // ------------------------------------------------------------------ the coin slot
  /** What the slot does with a coin: 'play' (a quarter drops), 'reject' (too big, back to the
   *  player) or 'lost' (small: it goes in and the house keeps it). */
  function accept(kind, cfg) {
    cfg = cfg || CONFIG;
    var mm = cfg.coinSizes[kind];
    if (mm === undefined) return 'reject';
    if (mm > cfg.slotMm) return 'reject';
    if (kind === 'quarter') return 'play';
    return 'lost';
  }

  /** The slider's new x after dt seconds with an axis input -1..1 (keys, stick). */
  function slide(x, axis, dt, cfg) {
    cfg = cfg || CONFIG;
    var nx = x + axis * cfg.slotSpeed * dt;
    return Math.max(-cfg.slotHalfW, Math.min(cfg.slotHalfW, nx));
  }

  // ------------------------------------------------------------------ the wallet
  /** The player's stake in the mall state (design/godot-interaction.md "mall"): quarters, or
   *  tickets when cfg.currency is 'tickets'. A state with no quarters gets the starting stake. */
  function balance(state, cfg) {
    cfg = cfg || CONFIG;
    if (cfg.currency === 'tickets') return Math.max(0, (state && +state.tickets) || 0);
    if (!state || typeof state.quarters !== 'number' || !(state.quarters >= 0)) return cfg.startQuarters;
    return Math.floor(state.quarters);
  }

  /** The state after the player pays one coin in (null when they cannot). */
  function payIn(state, cfg) {
    cfg = cfg || CONFIG;
    var b = balance(state, cfg);
    var cost = cfg.currency === 'tickets' ? cfg.ticketsPerCoin : 1;
    if (b < cost) return null;
    return setBalance(state, b - cost, cfg);
  }

  /** The state after n coins are paid out to the player. */
  function payOut(state, n, cfg) {
    cfg = cfg || CONFIG;
    var gain = cfg.currency === 'tickets' ? n * cfg.ticketsPerCoin : n;
    return setBalance(state, balance(state, cfg) + gain, cfg);
  }

  function setBalance(state, v, cfg) {
    cfg = cfg || CONFIG;
    var s = Object.assign({}, state || {});
    if (cfg.currency === 'tickets') s.tickets = v; else s.quarters = v;
    return s;
  }

  // ------------------------------------------------------------------ the tilt
  /** A nudge log: {hits: [{t, p}], last}. A nudge of power p at time t (ms) is added when the
   *  cabinet has settled; returns {log, accepted, tripped, power}. power is the summed power
   *  of the nudges inside the window: the HUD's tilt meter. */
  function nudge(log, t, p, cfg) {
    cfg = cfg || CONFIG;
    log = log || { hits: [], last: -1e9 };
    if (t - log.last < cfg.nudgeMinMs) return { log: log, accepted: false, tripped: false, power: tiltPower(log, t, cfg) };
    var hits = log.hits.filter(function (h) { return t - h.t <= cfg.tiltWindowMs; });
    hits.push({ t: t, p: Math.max(0, Math.min(1, p)) });
    var nl = { hits: hits, last: t };
    var pw = tiltPower(nl, t, cfg);
    return { log: nl, accepted: true, tripped: pw >= cfg.tiltTrip, power: pw };
  }

  function tiltPower(log, t, cfg) {
    cfg = cfg || CONFIG;
    var s = 0;
    for (var i = 0; i < log.hits.length; i++) if (t - log.hits[i].t <= cfg.tiltWindowMs) s += log.hits[i].p;
    return s;
  }

  /** The tilt's timeline from the trip at t0: when the alarm stops and where the gate is at
   *  time t ('house' while the gate is over). */
  function tiltState(t0, t, cfg) {
    cfg = cfg || CONFIG;
    if (t0 === null || t0 === undefined || t < t0) return { alarm: false, gate: 'player', swinging: false };
    var dt = t - t0;
    return {
      alarm: dt < cfg.tiltAlarmMs,
      gate: dt < cfg.tiltGateMs ? 'house' : 'player',
      swinging: dt < cfg.gateSwingMs || (dt >= cfg.tiltGateMs && dt < cfg.tiltGateMs + cfg.gateSwingMs),
    };
  }

  // ------------------------------------------------------------------ accounting
  /** A fresh ledger. in: coins dropped by the player; cup: paid to the player; side: into the
   *  house's side holes; tilt: over the front edge while the gate was over; lost: not quarters. */
  function ledger() { return { in: 0, cup: 0, side: 0, tilt: 0, lost: 0, nudges: 0, tilts: 0 }; }

  /** The ledger after a sim event ('cup' | 'side' | 'house-tilt' | 'lost'). */
  function book(l, ev) {
    var n = Object.assign({}, l);
    if (ev === 'cup') n.cup++;
    else if (ev === 'side') n.side++;
    else if (ev === 'house-tilt') n.tilt++;
    else if (ev === 'lost') n.lost++;
    return n;
  }

  /** Return to player, as a fraction of coins put in (0 when none). */
  function rtp(l) { return l.in > 0 ? l.cup / l.in : 0; }

  // ------------------------------------------------------------------ saves
  /** The key a position's machine is kept under in the browser. */
  function machineKey(pos) { return 'pusher.machine.' + Math.max(1, Math.min(CONFIG.positions, pos | 0)); }

  /** Pack a machine for localStorage: the sim's save() plus the ledger and the lip. */
  function packMachine(simSave, l, lipMm, cfg) {
    cfg = cfg || CONFIG;
    return { v: cfg.saveVersion, t: simSave.t, coins: simSave.coins, ledger: l, lipMm: lipMm, when: Date.now() };
  }

  /** Read a packed machine back; null when it is not one (a fresh machine then). */
  function unpackMachine(s, cfg) {
    cfg = cfg || CONFIG;
    if (!s || typeof s !== 'object' || s.v !== cfg.saveVersion) return null;
    if (!Array.isArray(s.coins) || s.coins.length % 7 !== 0 || s.coins.length < 7 * 20) return null;
    for (var i = 0; i < s.coins.length; i++) if (typeof s.coins[i] !== 'number' || !isFinite(s.coins[i])) return null;
    var l = Object.assign(ledger(), s.ledger || {});
    var lip = typeof s.lipMm === 'number' ? Math.max(cfg.lipRange[0], Math.min(cfg.lipRange[1], s.lipMm)) : cfg.lipMm;
    return { t: +s.t || 0, coins: s.coins, ledger: l, lipMm: lip };
  }

  var api = { CONFIG: CONFIG, accept: accept, slide: slide, balance: balance, payIn: payIn, payOut: payOut,
              nudge: nudge, tiltPower: tiltPower, tiltState: tiltState, ledger: ledger, book: book, rtp: rtp,
              machineKey: machineKey, packMachine: packMachine, unpackMachine: unpackMachine };
  if (typeof module !== 'undefined' && module.exports) module.exports = api;
  else root.PUSHER = api;
})(this);
