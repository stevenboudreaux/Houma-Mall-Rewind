## The player's money and tickets (workstream ECON, Steven Nov 3 2026; design/godot-economy.md).
## Used through the carried state (scripts/inventory.gd): mall.money, mall.can_afford(), mall.spend(),
## mall.add_money(), mall.tickets, mall.add_tickets(). The arcade pages (play/*.html) keep the same
## records with the same rules in play/lib/mallbank.js; tests/unit/econ/cases.json checks both.
##
## One key each, read and written at the moment of use (nothing cached), so the mall and a game page in
## its frame never overwrite each other:
##   "mall.money"          the wallet in whole cents, ONE for both years; a new player has 10000 ($100.00)
##   "mall.tickets-1995"   Pocket Change tickets, spent only in 1995
##   "mall.tickets-2026"   Games, Inc. tickets, spent only in 2026
##   "mall.ledger"         {"log": the last 40 changes, "ids": the last 200 credit ids}; a credit whose id
##                         is already there is refused, so a payout counts once
##   "mall.econ"           "1" once older saves are folded in (migrate())
## Storage: a Dictionary backend (unit tests), else localStorage on the web, else Engine metadata (the
## editor, native tests). Off the web, "mall-state-<year>" maps onto inventory.gd's own metadata.
extends RefCounted

const MONEY_KEY := "mall.money"
const TICKETS_PREFIX := "mall.tickets-"
const LEDGER_KEY := "mall.ledger"
const MIGRATED_KEY := "mall.econ"
const LEGACY_CLAW_KEY := "mall.tickets"     # the claw page's old ticket count (1995 capsules)
const STATE_PREFIX := "mall-state-"
const START_CENTS := 10000
const QUARTER := 25
const YEARS := [1995, 2026]
const LOG_MAX := 40
const IDS_MAX := 200

## null (localStorage / Engine meta) or a Dictionary of String -> String (unit tests).
var backend = null

# ------------------------------------------------------------------ storage
func kv_get(k: String):
	if backend is Dictionary:
		var v = backend.get(k, null)
		return null if v == null else str(v)
	if OS.has_feature("web"):
		var v = JavaScriptBridge.eval("(function(){try{return localStorage.getItem(%s)}catch(e){return null}})()" % JSON.stringify(k), true)
		return v if v is String else null
	if k.begins_with(STATE_PREFIX) and k.trim_prefix(STATE_PREFIX).is_valid_int():
		var s := str(Engine.get_meta("mall_state_" + k.trim_prefix(STATE_PREFIX), ""))
		return null if s == "" else s
	var d: Dictionary = Engine.get_meta("mall_kv", {})
	return d.get(k, null)

func kv_set(k: String, v) -> void:
	var s := str(v)
	if backend is Dictionary:
		backend[k] = s
	elif OS.has_feature("web"):
		JavaScriptBridge.eval("(function(){try{localStorage.setItem(%s,%s)}catch(e){}})()" % [JSON.stringify(k), JSON.stringify(s)], true)
	elif k.begins_with(STATE_PREFIX) and k.trim_prefix(STATE_PREFIX).is_valid_int():
		Engine.set_meta("mall_state_" + k.trim_prefix(STATE_PREFIX), s)
	else:
		var d: Dictionary = Engine.get_meta("mall_kv", {})
		d[k] = s
		Engine.set_meta("mall_kv", d)

func kv_del(k: String) -> void:
	if backend is Dictionary:
		backend.erase(k)
	elif OS.has_feature("web"):
		JavaScriptBridge.eval("(function(){try{localStorage.removeItem(%s)}catch(e){}})()" % JSON.stringify(k), true)
	else:
		var d: Dictionary = Engine.get_meta("mall_kv", {})
		d.erase(k)
		Engine.set_meta("mall_kv", d)

static func _num(v) -> bool:
	if v == null:
		return false
	var s := str(v).strip_edges()
	return s.is_valid_int() or s.is_valid_float()

## JSON text to a value, or null; quiet about junk (a damaged save is not an error worth a console line).
static func _parse(s):
	if s == null or str(s) == "":
		return null
	var j := JSON.new()
	return j.data if j.parse(str(s)) == OK else null

static func _int(v) -> int:
	return int(floor(float(str(v)))) if _num(v) else 0

# ------------------------------------------------------------------ migration
## Fold older saves in, once: COIN COMET's free quarters (mall-state-<year>.quarters, 25 cents each) into
## the wallet; each year's mall-state-<year>.tickets into that year's tickets; the claw page's old
## "mall.tickets" (1995 capsules) into 1995. Additive, so it is right whichever side runs first; the old
## fields are removed as they are read. True when it ran.
func migrate() -> bool:
	if kv_get(MIGRATED_KEY) == "1":
		return false
	var m = kv_get(MONEY_KEY)
	var money := _int(m) if _num(m) else START_CENTS
	var add := {1995: 0, 2026: 0}
	for y in YEARS:
		var s = kv_get(STATE_PREFIX + str(y))
		var rec = _parse(s)
		if not (rec is Dictionary):
			continue
		var touched := false
		if rec.has("quarters"):
			if _num(rec.quarters) and float(rec.quarters) > 0:
				money += _int(rec.quarters) * QUARTER
			rec.erase("quarters")
			touched = true
		if rec.has("tickets"):
			if _num(rec.tickets) and float(rec.tickets) > 0:
				add[y] += _int(rec.tickets)
			rec.erase("tickets")
			touched = true
		if touched:
			kv_set(STATE_PREFIX + str(y), JSON.stringify(rec))
	var claw = kv_get(LEGACY_CLAW_KEY)
	if claw != null:
		if _num(claw) and float(claw) > 0:
			add[1995] += _int(claw)
		kv_del(LEGACY_CLAW_KEY)
	kv_set(MONEY_KEY, maxi(0, money))
	for y in YEARS:
		if add[y] > 0:
			kv_set(TICKETS_PREFIX + str(y), _raw_tickets(y) + add[y])
	kv_set(MIGRATED_KEY, "1")
	_note("migrate", 0, 0, "older saves folded in")
	return true

func ready() -> void:
	if kv_get(MIGRATED_KEY) != "1":
		migrate()

# ------------------------------------------------------------------ ledger
func ledger() -> Dictionary:
	var s = kv_get(LEDGER_KEY)
	var l = _parse(s)
	if not (l is Dictionary):
		l = {}
	if not (l.get("log") is Array):
		l["log"] = []
	if not (l.get("ids") is Array):
		l["ids"] = []
	return l

func _note(what: String, year: int, n: int, reason: String, id := "") -> void:
	var l := ledger()
	l.log.append({"t": int(Time.get_unix_time_from_system() * 1000.0), "what": what, "year": year, "n": n, "reason": reason})
	if l.log.size() > LOG_MAX:
		l.log = l.log.slice(l.log.size() - LOG_MAX)
	if id != "":
		l.ids.append(id)
		if l.ids.size() > IDS_MAX:
			l.ids = l.ids.slice(l.ids.size() - IDS_MAX)
	kv_set(LEDGER_KEY, JSON.stringify(l))

## True when a credit with this id has already been made.
func seen(id: String) -> bool:
	return id != "" and ledger().ids.has(id)

# ------------------------------------------------------------------ money
## The wallet in cents (a new player gets START_CENTS).
func money() -> int:
	ready()
	var v = kv_get(MONEY_KEY)
	if not _num(v):
		kv_set(MONEY_KEY, START_CENTS)
		return START_CENTS
	return maxi(0, _int(v))

func can_afford(cents: int) -> bool:
	return cents >= 0 and money() >= cents

## Take cents out of the wallet. False, and nothing changes, when it doesn't cover them.
func spend(cents: int, reason: String) -> bool:
	if not can_afford(cents):
		return false
	kv_set(MONEY_KEY, money() - cents)
	_note("spend", 0, cents, reason)
	return true

## Put cents into the wallet (change, a refund, a payout in money). False for cents <= 0.
func earn(cents: int, reason: String) -> bool:
	if cents <= 0:
		return false
	kv_set(MONEY_KEY, money() + cents)
	_note("earn", 0, cents, reason)
	return true

# ------------------------------------------------------------------ tickets
func _raw_tickets(year: int) -> int:
	return maxi(0, _int(kv_get(TICKETS_PREFIX + str(year))))

## The year's tickets (Pocket Change for 1995, Games, Inc. for 2026).
func tickets(year: int) -> int:
	ready()
	return _raw_tickets(year)

## Set the year's tickets outright (inventory.gd's `mall.tickets = n`, tests).
func set_tickets(year: int, n: int) -> void:
	if not (year in YEARS):
		return
	ready()
	kv_set(TICKETS_PREFIX + str(year), maxi(0, n))

## n tickets won in year. id names this one payout; a second credit with the same id is refused.
func credit(year: int, n: int, reason: String, id := "") -> bool:
	if n <= 0 or not (year in YEARS) or seen(id):
		return false
	kv_set(TICKETS_PREFIX + str(year), tickets(year) + n)
	_note("tickets", year, n, reason, id)
	return true

## Spend n of year's tickets. False, and nothing changes, when there are fewer.
func spend_tickets(year: int, n: int, reason: String) -> bool:
	if n < 0 or not (year in YEARS) or tickets(year) < n:
		return false
	kv_set(TICKETS_PREFIX + str(year), tickets(year) - n)
	_note("redeem", year, n, reason)
	return true

## 1234 -> "$12.34"
static func fmt(cents: int) -> String:
	var a := absi(cents)
	var d := str(a / 100)
	var out := ""
	while d.length() > 3:
		out = "," + d.right(3) + out
		d = d.left(d.length() - 3)
	return ("-$" if cents < 0 else "$") + d + out + "." + ("%02d" % (a % 100))
