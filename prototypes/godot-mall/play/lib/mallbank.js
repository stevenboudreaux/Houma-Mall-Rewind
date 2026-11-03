/* The player's money and tickets, for the arcade pages (workstream ECON, Steven Nov 3 2026;
 * design/godot-economy.md). The Godot mall keeps the same records with the same rules in
 * scripts/bank.gd; tests/unit/econ/cases.json runs both against the same cases.
 *
 * Kept in this browser's localStorage, one key each, read and written at the moment of use
 * (nothing is cached, so the mall page and a game page in its frame never overwrite each other):
 *   "mall.money"          the wallet, whole cents. ONE wallet for both years. A new player: 10000 ($100.00).
 *   "mall.tickets-1995"   Pocket Change tickets (spend only in 1995)
 *   "mall.tickets-2026"   Games, Inc. tickets (spend only in 2026)
 *   "mall.ledger"         {"log": the last 40 changes, "ids": the last 200 credit ids}: a credit with an
 *                         id that is already there is refused, so a payout can never be counted twice
 *   "mall.econ"           "1" once older saves have been folded in (migrate(), below)
 *
 * Usage: var B = MALLBANK.make(localStorage);  B.spend(25, 'COIN COMET drop') -> true | false;
 *        B.credit(1995, 50, 'COIN COMET cup', 'pusher:...') -> true | false;  B.money();  B.tickets(1995)
 * Pure apart from the storage object it is given (anything with getItem/setItem/removeItem).
 */
(function (root) {
  'use strict';
  var K = {
    money: 'mall.money', tickets: 'mall.tickets-', ledger: 'mall.ledger', migrated: 'mall.econ',
    legacyClaw: 'mall.tickets', state: 'mall-state-'
  };
  var START_CENTS = 10000, QUARTER = 25, YEARS = [1995, 2026], LOG_MAX = 40, IDS_MAX = 200;

  function int(v) { var n = Math.floor(Number(v)); return isFinite(n) ? n : 0; }
  function num(v) { return v !== null && v !== undefined && v !== '' && isFinite(Number(v)); }
  function json(s) { try { return JSON.parse(s); } catch (e) { return null; } }

  function make(store) {
    function get(k) { try { return store.getItem(k); } catch (e) { return null; } }
    function set(k, v) { try { store.setItem(k, String(v)); } catch (e) {} }
    function del(k) { try { store.removeItem(k); } catch (e) {} }

    /** Fold older saves in, once: the pusher's free quarters (mall-state-<year>.quarters, 25 cents
     *  each) into the wallet, each year's mall-state-<year>.tickets into that year's tickets, and the
     *  claw's old "mall.tickets" count (1995 Pocket Change capsules) into 1995. Additive, so it is
     *  right whichever page runs first; the old fields are removed as they are read. */
    function migrate() {
      if (get(K.migrated) === '1') return false;
      var money = num(get(K.money)) ? int(get(K.money)) : START_CENTS;
      var add = {};
      YEARS.forEach(function (y) {
        add[y] = 0;
        var rec = json(get(K.state + y));
        if (!rec || typeof rec !== 'object' || Array.isArray(rec)) return;
        var touched = false;
        if ('quarters' in rec) { if (num(rec.quarters) && rec.quarters > 0) money += int(rec.quarters) * QUARTER; delete rec.quarters; touched = true; }
        if ('tickets' in rec) { if (num(rec.tickets) && rec.tickets > 0) add[y] += int(rec.tickets); delete rec.tickets; touched = true; }
        if (touched) set(K.state + y, JSON.stringify(rec));
      });
      var claw = get(K.legacyClaw);
      if (claw !== null) { if (num(claw) && Number(claw) > 0) add[1995] += int(claw); del(K.legacyClaw); }
      set(K.money, Math.max(0, money));
      YEARS.forEach(function (y) { if (add[y] > 0) set(K.tickets + y, tickets(y, true) + add[y]); });
      set(K.migrated, '1');
      note('migrate', 0, 0, 'older saves folded in');
      return true;
    }
    function ready() { if (get(K.migrated) !== '1') migrate(); }

    function ledger() {
      var l = json(get(K.ledger));
      if (!l || typeof l !== 'object') l = {};
      if (!Array.isArray(l.log)) l.log = [];
      if (!Array.isArray(l.ids)) l.ids = [];
      return l;
    }
    function note(what, year, amount, reason, id) {
      var l = ledger();
      l.log.push({ t: Date.now(), what: what, year: year, n: amount, reason: String(reason || '') });
      if (l.log.length > LOG_MAX) l.log = l.log.slice(-LOG_MAX);
      if (id) { l.ids.push(String(id)); if (l.ids.length > IDS_MAX) l.ids = l.ids.slice(-IDS_MAX); }
      set(K.ledger, JSON.stringify(l));
    }
    function seen(id) { return !!id && ledger().ids.indexOf(String(id)) >= 0; }

    /** The wallet in cents (a new player gets START_CENTS). */
    function money() {
      ready();
      var v = get(K.money);
      if (!num(v)) { set(K.money, START_CENTS); return START_CENTS; }
      return Math.max(0, int(v));
    }
    function canAfford(cents) { cents = int(cents); return cents >= 0 && money() >= cents; }
    /** Take cents out of the wallet. False, and nothing changes, when it doesn't cover them. */
    function spend(cents, reason) {
      cents = int(cents);
      if (cents < 0 || !canAfford(cents)) return false;
      set(K.money, money() - cents);
      note('spend', 0, cents, reason);
      return true;
    }
    /** Put cents into the wallet (a refund, change, a payout in money). */
    function earn(cents, reason) {
      cents = int(cents);
      if (cents <= 0) return false;
      set(K.money, money() + cents);
      note('earn', 0, cents, reason);
      return true;
    }
    function tickets(year, raw) {
      if (!raw) ready();
      return Math.max(0, int(get(K.tickets + int(year))));
    }
    /** n tickets won in year. id: a name for this one payout ("whirlwind:<session>:<play>"); a second
     *  credit with the same id is refused (false), so a payout counts once. */
    function credit(year, n, reason, id) {
      n = int(n); year = int(year);
      if (n <= 0 || YEARS.indexOf(year) < 0 || seen(id)) return false;
      set(K.tickets + year, tickets(year) + n);
      note('tickets', year, n, reason, id);
      return true;
    }
    /** Spend n of year's tickets. False, and nothing changes, when there are fewer. */
    function spendTickets(year, n, reason) {
      n = int(n); year = int(year);
      if (n < 0 || YEARS.indexOf(year) < 0 || tickets(year) < n) return false;
      set(K.tickets + year, tickets(year) - n);
      note('redeem', year, n, reason);
      return true;
    }
    return { money: money, canAfford: canAfford, spend: spend, earn: earn, tickets: tickets, credit: credit,
             spendTickets: spendTickets, migrate: migrate, seen: seen, ledger: ledger };
  }

  /** 1234 -> "$12.34" */
  function fmt(cents) {
    cents = int(cents);
    var s = String(Math.abs(cents) % 100); if (s.length < 2) s = '0' + s;
    var d = String(Math.floor(Math.abs(cents) / 100)).replace(/\B(?=(\d{3})+(?!\d))/g, ',');
    return (cents < 0 ? '-$' : '$') + d + '.' + s;
  }
  /** A unique-enough id for one page visit, for credit ids. */
  function session() { return Date.now().toString(36) + Math.floor(Math.random() * 1e9).toString(36); }

  var api = { make: make, fmt: fmt, session: session, KEYS: K, START_CENTS: START_CENTS, YEARS: YEARS };
  if (typeof module !== 'undefined' && module.exports) module.exports = api;
  else root.MALLBANK = api;
})(this);
