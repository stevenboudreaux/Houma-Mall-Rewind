/* WHIRLWIND game rules (play/whirlwind.html). Pure functions, no DOM, so they can be
 * tested with plain Node (tests/unit/whirlwind/logic.test.js).
 *
 * Every number here comes from Steven's video of a working light-ring ticket game
 * (cyclone-ticket-redemption-game-from-ice-arcade-game-review.mp4, Oct 9 2026):
 * - the chase light laps the ring in 1.62 s (measured over 20 s of play; the narrator
 *   says "about a second and a half");
 * - the operator's difficulty is the number of milliseconds the player has to press while
 *   the light is on the bonus, 1 (hardest) to 20; the factory setting is 3;
 * - the bonus starts at 100, goes up 1 for every game that misses it, and goes back to 100
 *   when it is won;
 * - after a bonus win the lights flash for about 11.5 s, then TICKETS OWED counts down as
 *   the dispenser feeds about 2.5 tickets a second, in short runs with small stalls.
 * The ring of 64 lamps and its values are the mall cabinet's (paint_cyclone.py ring_values).
 */
(function (root) {
  'use strict';

  var CONFIG = {
    lamps: 64,             // lamps round the ring; lamp 0 is the BONUS slot at the front
    lapMs: 1620,           // one lap of the chase while a game is running
    windowMs: 3,           // the bonus window, centred on the bonus lamp (factory setting 3)
    bonusStart: 100,       // the bonus after it is won
    bonusStep: 1,          // added for every game that does not win it
    plays: 4,              // $1.00 in quarters
    priceCents: 100,       // ECON (Nov 3): START takes $1.00 from the wallet for the four plays (the price it had)
    lockoutMs: 350,        // presses this soon after a game starts are ignored
    celebrateBonusMs: 11500,
    celebrateWinMs: 1500,
    ticketMs: 360,         // one ticket's feed time in a run
    stallChance: 0.06,     // chance of a short stall after any ticket
    stallMinMs: 500,
    stallMaxMs: 1000
  };

  /** Ticket value next to each lamp: 0 for the BONUS lamp, then 10, 8, 7 ... 1 and back up,
   *  the same on both sides (the mall cabinet's ring, paint_cyclone.py ring_values). */
  function ringValues(n) {
    n = n || CONFIG.lamps;
    var near = [10, 8, 7, 6, 5, 5, 4, 4, 3, 3, 2, 2, 2, 1, 1, 1, 1, 2, 2, 3, 3, 4, 4, 5, 4, 3, 3, 2, 2, 1, 1, 2];
    var v = [0];
    for (var i = 1; i < n; i++) v.push(near[Math.min(i, n - i) - 1]);
    return v;
  }

  function lampMs(cfg) { return cfg.lapMs / cfg.lamps; }

  /** Where the light is, in lamps (fractional), `ms` after a game's chase started from
   *  lamp `startLamp`. The chase runs toward higher lamp numbers. */
  function position(ms, startLamp, cfg) {
    cfg = cfg || CONFIG;
    var p = startLamp + ms / lampMs(cfg);
    return ((p % cfg.lamps) + cfg.lamps) % cfg.lamps;
  }

  /** Judges a press `ms` after the chase started. The bonus is won only inside the window
   *  (windowMs wide, centred on the middle of the bonus lamp's lit time). A press while
   *  the bonus lamp is lit but outside the window stops the light on the next lamp. */
  function judge(ms, startLamp, cfg) {
    cfg = cfg || CONFIG;
    var pos = position(ms, startLamp, cfg);
    var lamp = Math.floor(pos);
    var off = (pos - lamp - 0.5) * lampMs(cfg);        // ms from the lamp's centre
    if (lamp === 0) {
      if (Math.abs(off) <= cfg.windowMs / 2) return { lamp: 0, bonus: true, offMs: off };
      return { lamp: 1, bonus: false, offMs: off, skipped: true };
    }
    return { lamp: lamp, bonus: false, offMs: off };
  }

  /** The tickets a stop pays: the bonus, or the value by the lamp. */
  function payout(result, bonus, values) {
    return result.bonus ? bonus : values[result.lamp];
  }

  /** The bonus after a game. */
  function nextBonus(result, bonus, cfg) {
    cfg = cfg || CONFIG;
    return result.bonus ? cfg.bonusStart : bonus + cfg.bonusStep;
  }

  /** A small seeded random generator (mulberry32), so a payout's rhythm can be replayed. */
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

  /** Times (ms after the payout starts) at which each of `n` tickets finishes coming out. */
  function feedTimes(n, rand, cfg) {
    cfg = cfg || CONFIG;
    var t = 0, out = [];
    for (var i = 0; i < n; i++) {
      t += cfg.ticketMs;
      out.push(t);
      if (rand() < cfg.stallChance) t += cfg.stallMinMs + rand() * (cfg.stallMaxMs - cfg.stallMinMs);
    }
    return out;
  }

  /** PRIZES (Nov 3 2026): the cabinets that run this page. "pc" is Pocket Change's (1995, $1.00 for four);
   *  "gi" is games, inc.'s 2026 copy, "literally the same machine" (Steven), slightly faded, at $2 for
   *  four plays. Each keeps its own plays left, bonus and best in the browser (key), and names its own
   *  payouts (pay), so a play paid at one machine never shows on the other. */
  var CABINETS = {
    pc: { priceCents: 100, key: 'whirlwind', pay: 'whirlwind', faded: false },
    gi: { priceCents: 200, key: 'whirlwind.gi', pay: 'whirlwind-gi', faded: true }
  };

  /** The cabinet called `name` (?cab=, default "pc"): {name, cfg (CONFIG with its price), key, pay, faded}. */
  function cabinet(name) {
    var id = Object.prototype.hasOwnProperty.call(CABINETS, name) ? name : 'pc';
    var c = CABINETS[id], cfg = {};
    for (var k in CONFIG) cfg[k] = CONFIG[k];
    cfg.priceCents = c.priceCents;
    return { name: id, cfg: cfg, key: c.key, pay: c.pay, faded: c.faded };
  }

  var api = { CONFIG: CONFIG, ringValues: ringValues, position: position, judge: judge,
              payout: payout, nextBonus: nextBonus, rng: rng, feedTimes: feedTimes, lampMs: lampMs,
              CABINETS: CABINETS, cabinet: cabinet };
  if (typeof module !== 'undefined' && module.exports) module.exports = api;
  else root.WW = api;
})(this);
