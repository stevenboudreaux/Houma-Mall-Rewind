## Headless checks of money and tickets (workstream ECON, Steven Nov 3 2026; design/godot-economy.md):
##   1. scripts/bank.gd against tests/unit/econ/cases.json (the same cases the pages' play/lib/mallbank.js runs)
##   2. the carried state's API for round 2: mall.money, can_afford, spend, add_money, tickets, add_tickets
##   3. year separation: 1995 tickets don't spend in 2026; the wallet is one for both years
##   4. migration through a real load (load_saved): old tickets and quarters folded in once, nothing lost
##   5. the redemption counter spends this year's tickets; the boom box costs 5,000, the plush 700
##   6. ItemDB.price: the data-driven price field
##   godot --headless --path . --script res://tools/qa/econ_test.gd
## Prints ECON TEST OK (n checks), or the failed checks. Exit code 0 / 1.
extends SceneTree

const Bank = preload("res://scripts/bank.gd")
const Inventory = preload("res://scripts/inventory.gd")
const ItemDB = preload("res://scripts/items/item_db.gd")
const Redemption = preload("res://scripts/redemption.gd")

var oks := 0
var errors: Array = []

func _check(ok: bool, what: String) -> void:
	printerr(("ok   " if ok else "FAIL ") + what)
	if ok:
		oks += 1
	else:
		errors.append(what)

func _mall(store: Dictionary, year := 1995):
	var m = Inventory.new()
	m.year = year
	m.backend = store
	return m

func _initialize() -> void:
	_test_cases()
	_test_api()
	_test_years()
	_test_migration_load()
	_test_redemption()
	_test_price()
	printerr("ECON TEST OK (%d checks)" % oks if errors.is_empty() else "ECON TEST FAILED: " + str(errors))
	quit(0 if errors.is_empty() else 1)

## 1. The shared cases.
func _test_cases() -> void:
	var path := ProjectSettings.globalize_path("res://").path_join("../../../tests/unit/econ/cases.json").simplify_path()
	var j = JSON.parse_string(FileAccess.get_file_as_string(path))
	_check(j is Dictionary and j.cases.size() >= 8, "the shared cases are read (%s)" % path)
	if not (j is Dictionary):
		return
	for c in j.cases:
		var store := {}
		for k in c.start:
			store[k] = str(c.start[k])
		var b = Bank.new()
		b.backend = store
		var bad := []
		for op in c.ops:
			var want = op[op.size() - 1]
			var got
			match str(op[0]):
				"money": got = b.money()
				"can_afford": got = b.can_afford(int(op[1]))
				"spend": got = b.spend(int(op[1]), str(op[2]))
				"earn": got = b.earn(int(op[1]), str(op[2]))
				"tickets": got = b.tickets(int(op[1]))
				"credit": got = b.credit(int(op[1]), int(op[2]), str(op[3]), str(op[4]))
				"spend_tickets": got = b.spend_tickets(int(op[1]), int(op[2]), str(op[3]))
				"migrate": got = b.migrate()
				_: got = "unknown op"
			if not (str(got) == str(want) or (typeof(want) == TYPE_FLOAT and typeof(got) == TYPE_INT and int(want) == got)):
				bad.append("%s -> %s, want %s" % [str(op), str(got), str(want)])
		for k in c.get("end", {}):
			var want = c.end[k]
			var got = store.get(k, null)
			if want == null:
				if got != null: bad.append("%s should be gone, is %s" % [k, got])
			elif want is Dictionary:
				var g = JSON.parse_string(str(got)) if got != null else null
				if not (g is Dictionary) or JSON.stringify(g, "", true) != JSON.stringify(want, "", true):
					bad.append("%s is %s, want %s" % [k, str(got), JSON.stringify(want)])
			elif str(got) != str(want):
				bad.append("%s is %s, want %s" % [k, str(got), str(want)])
		_check(bad.is_empty(), "case: %s %s" % [c.name, "" if bad.is_empty() else str(bad)])

## 2. The API round 2 will use, on the carried state.
func _test_api() -> void:
	var store := {}
	var m = _mall(store)
	var n := [0]
	m.changed.connect(func(): n[0] += 1)
	_check(m.money == 10000 and m.money is int, "a new player: mall.money is 10000 cents ($100.00), an int")
	_check(m.can_afford(10000) and not m.can_afford(10001) and not m.can_afford(-1), "can_afford: up to what is there; never a negative price")
	_check(m.spend(299, "PLACEHOLDER: a test purchase") and m.money == 9701 and n[0] == 1, "spend(299) takes $2.99 and tells the panels")
	_check(not m.spend(9702, "too much") and m.money == 9701 and n[0] == 1, "spend more than there is: false, nothing changes, no signal")
	_check(m.add_money(99, "change") and m.money == 9800, "add_money puts money back")
	_check(Inventory.money_text(m.money) == "$98.00" and Inventory.money_text(5) == "$0.05", "money_text: $98.00, $0.05")
	m.tickets = 140
	_check(m.tickets == 140 and store.get("mall.tickets-1995") == "140", "mall.tickets = 140 is this year's tickets, saved at once")
	_check(m.add_tickets(25, "test", "t:1") and not m.add_tickets(25, "test", "t:1") and m.tickets == 165, "add_tickets with an id counts once")
	_check(m.spend_tickets(65, "test") and m.tickets == 100 and not m.spend_tickets(101, "test") and m.tickets == 100, "spend_tickets: down by n; never below 0")
	var d: Dictionary = m.to_dict()
	_check(not d.has("tickets") and not d.has("money") and not d.has("quarters"), "the per-year record no longer carries tickets, money or quarters")
	# a second state on the same storage (a game page writing while the mall runs) is seen at once
	var page = Bank.new()
	page.backend = store
	page.spend(25, "COIN COMET drop")
	page.credit(1995, 50, "COIN COMET cup", "p:1")
	_check(m.money == 9775 and m.tickets == 150, "what a game page writes is what the mall reads next (nothing cached)")
	m.save()
	var again = _mall(store)
	_check(again.load_saved() and again.tickets == 150 and again.money == 9775, "a reload reads the same money and tickets")

## 3. Tickets stay in their year; the wallet goes back and forth.
func _test_years() -> void:
	var store := {}
	var a = _mall(store, 1995)
	var b = _mall(store, 2026)
	a.add_tickets(600, "Pocket Change")
	_check(a.tickets == 600 and b.tickets == 0, "Pocket Change tickets aren't in 2026")
	b.add_tickets(30, "Games, Inc.")
	_check(not b.spend_tickets(600, "redeem") and b.tickets == 30 and a.tickets == 600, "2026 can't spend 1995's tickets")
	a.spend(1000, "1995 spending")
	_check(b.money == 9000 and a.money == 9000, "one wallet: $10 spent in 1995 is gone in 2026 too")
	b.add_money(500, "2026 change")
	_check(a.money == 9500, "and money made in 2026 is there in 1995")

## 4. A save from before ECON, loaded the way the mall loads it.
func _test_migration_load() -> void:
	var store := {
		"mall-state-1995": JSON.stringify({"v": 1, "year": 1995, "inventory": [{"id": "pogs", "count": 2}], "tickets": 600, "hand": "folse_stick", "moved": {"folse_stick": {}}, "quarters": 18}),
		"mall-state-2026": JSON.stringify({"v": 1, "year": 2026, "inventory": [], "tickets": 40, "hand": "", "moved": {}}),
		"mall.tickets": "35",
	}
	var m = _mall(store, 1995)
	_check(m.load_saved(), "an old 1995 save loads")
	_check(m.count("pogs") == 2 and m.hand == "folse_stick" and m.where("folse_stick", {"pos": [0, 0, 0]}) == null, "the things carried are kept")
	_check(m.tickets == 635, "1995 tickets: the record's 600 + the claw's 35 = %d" % m.tickets)
	_check(m.money == 10000 + 18 * 25, "money: $100.00 + the 18 free quarters left ($4.50) = %d" % m.money)
	var y26 = _mall(store, 2026)
	y26.load_saved()
	_check(y26.tickets == 40, "2026 keeps its own 40")
	m.save()
	var rec = JSON.parse_string(store["mall-state-1995"])
	_check(not rec.has("tickets") and not rec.has("quarters") and not store.has("mall.tickets"), "the old fields are gone after the next save")
	var m2 = _mall(store, 1995)
	m2.load_saved()
	_check(m2.tickets == 635 and m2.money == 10450, "loading again doesn't count them twice")

## 5. The redemption counter.
func _test_redemption() -> void:
	var db = ItemDB.new().load_dir()
	var stock: Array = Redemption.read_stock(db, 1995)
	var by := {}
	for s in stock:
		by[s.item] = s
	_check(by.has("bl_pc_boombox") and int(by.bl_pc_boombox.tickets) == 5000, "the boom box costs 5,000 tickets (the wall's tags)")
	_check(int(db.get_item("bl_pc_boombox").get("tickets", 0)) == 5000, "its item file says 5,000 too")
	_check(by.has("bl_pc_plush_bear") and int(by.bl_pc_plush_bear.tickets) == 700, "the plush stay at 700")
	var store := {}
	var m = _mall(store, 1995)
	var r = Redemption.new()
	r.setup(null, m, db)
	var bb := -1
	for i in r.stock.size():
		if r.stock[i].item == "bl_pc_boombox": bb = i
	m.tickets = 4999
	_check(not r.buy(bb) and m.tickets == 4999 and not m.has("bl_pc_boombox"), "4,999 tickets: no boom box")
	m.tickets = 5100
	_check(r.buy(bb) and m.tickets == 100 and m.has("bl_pc_boombox"), "5,100 tickets: the boom box, 100 left")
	var y26 = _mall(store, 2026)
	y26.tickets = 9000
	_check(m.tickets == 100, "2026 tickets don't show at the 1995 counter")
	r.free()

## 6. The price field.
func _test_price() -> void:
	var e := {"id": "a", "name": "A", "class": "pocket", "scene": "", "icon": "", "year": 1995, "price": 299}
	_check(ItemDB.check(e) == "" and ItemDB.price(e) == 299, "an item with \"price\": 299 costs 299 cents")
	_check(ItemDB.price({"id": "b"}) == -1, "no price: -1 (not for sale)")
	for bad in [-1, 2.5, "3"]:
		var x := e.duplicate()
		x.price = bad
		_check(ItemDB.check(x) != "", "a price of %s is refused" % str(bad))
