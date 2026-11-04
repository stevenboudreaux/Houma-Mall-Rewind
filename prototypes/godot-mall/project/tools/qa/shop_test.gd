## Headless checks of the shops (workstream SHOPS, Steven Nov 3 2026; design/godot-shops.md):
##   1. the data: every shop in data/story/shops.json has its attendant (attendants.json, a preset, PLACEHOLDER),
##      its greeting, whole-cent prices and items that exist in 1995 with a model and an icon; Steven's lines
##      word for word; the stand-ins and estimates are marked
##   2. a buy: the money comes off once, the item is in the bag, the ready line is said, it is saved (a fresh
##      load from the same storage has it, and the same wallet)
##   3. can't afford: nothing changes; the card is greyed out
##   4. the shelves: nothing in the four stores lies about to be picked up any more (no "place"); their stock
##      on show is a "display"
##   5. the screen (no player): open / buy / close, an unknown or closed shop doesn't open, 2026 has none
##   godot --headless --path . --script res://tools/qa/shop_test.gd
## Prints SHOP TEST OK (n checks), or the failed checks. Exit code 0 / 1.
extends SceneTree

const Inventory = preload("res://scripts/inventory.gd")
const ItemDB = preload("res://scripts/items/item_db.gd")
const Shop = preload("res://scripts/shop.gd")

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
	var db = ItemDB.new().load_dir()
	_test_data(db)
	_test_buy(db)
	_test_cant_afford(db)
	_test_shelves(db)
	await _test_screen(db)
	printerr("SHOP TEST OK (%d checks)" % oks if errors.is_empty() else "SHOP TEST FAILED: " + str(errors))
	quit(0 if errors.is_empty() else 1)

func _json(p: String):
	return JSON.parse_string(FileAccess.get_file_as_string(p))

## 1. The data.
func _test_data(db) -> void:
	var shops := Shop.read_shops()
	# int-51: Cuco's (workstream CUCOS) is a fifth entry with its own story bartender; tools/qa/cucos_test.gd checks it
	_check(shops.has("woolworth") and shops.has("corn_dog_7") and shops.has("radioshack") and shops.has("b_dalton"),
		"the four counters: %s" % str(shops.keys()))
	var att := {}
	for a in _json("res://data/story/attendants.json").attendants:
		att[str(a.id)] = a
	var want_store := {"woolworth": "WOOLWORTH", "corn_dog_7": "CORN DOG 7", "radioshack": "RADIO SHACK", "b_dalton": "B. DALTON BOOKSELLER"}
	var want_wing := {"woolworth": 1, "corn_dog_7": 2, "radioshack": 1, "b_dalton": 2}
	for id in want_store:
		var s: Dictionary = shops[id]
		var a: Dictionary = att.get(str(s.attendant), {})
		_check(not a.is_empty() and str(a.get("shop", "")) == id, "%s: its attendant names it" % id)
		_check(str(a.get("name", "")) == "PLACEHOLDER", "%s: the attendant is named PLACEHOLDER" % id)
		_check(str(a.get("look", "")) == "preset" and FileAccess.file_exists("res://data/characters/%s.json" % a.get("preset", "?")),
			"%s: the attendant wears a preset (%s)" % [id, a.get("preset", "?")])
		_check(str(a.get("store", "")) == want_store[id] and int(a.get("wing", 0)) == want_wing[id] and _years(a) == [1995],
			"%s: %s, wing %d, 1995 only" % [id, want_store[id], want_wing[id]])
		var pr = _json("res://data/characters/%s.json" % a.get("preset", "?"))
		_check(pr is Dictionary and str(pr.get("name", "")) == "PLACEHOLDER" and (pr.outfit.has("full") or (pr.outfit.has("bottom") and (pr.outfit.has("top") or pr.outfit.has("outer")))),
			"%s: the preset is PLACEHOLDER and clothed" % id)
		_check(_years(s) == [1995] and str(s.get("greeting", "")) != "", "%s: 1995, a greeting" % id)
		var st := Shop.read_stock(s, db, 1995)
		_check(st.size() == s.items.size() and st.size() > 0, "%s: every entry is an item of 1995 (%d of %d)" % [id, st.size(), s.items.size()])
		for x in s.items:
			var e: Dictionary = db.get_item(str(x.item))
			var pc = x.get("price_cents", -1)
			_check((pc is int or pc is float) and float(pc) == floor(float(pc)) and float(pc) > 0, "%s %s: price %s whole cents" % [id, x.item, str(pc)])
			_check(str(x.get("price_note", "")) != "" and str(x.get("ready_line", "")) != "", "%s %s: a price note and a ready line" % [id, x.item])
			_check(ResourceLoader.exists(str(e.get("scene", ""))) and ResourceLoader.exists(str(e.get("icon", ""))),
				"%s %s: model and icon load" % [id, x.item])
			if str(x.item).begins_with("standin_"):
				_check(bool(x.get("standin", false)) and bool(e.get("standin", false)), "%s %s: marked a stand-in" % [id, x.item])
			if id == "radioshack":
				_check(str(x.price_note).begins_with("estimate"), "radioshack %s: the price is marked an estimate" % x.item)
	# Steven's words, exactly
	var w: Dictionary = shops.get("woolworth", {})
	_check(w.get("greeting") == "Welcome to Woolworth, sha! What can I get for you?", "Woolworth's greeting, word for word")
	_check(_line(w, "bl_wl_rootbeer_float") == "One root beer float coming right up.", "Woolworth: the float line")
	_check(_line(w, "wl_fries") == "Order of fries coming up.", "Woolworth: the fries line")
	_check(_price(w, "bl_wl_rootbeer_float") == 200, "Woolworth: root beer float $2")
	var c: Dictionary = shops.get("corn_dog_7", {})
	_check(c.get("greeting") == "Hi, welcome to Corn Dog 7. What can I get for you?", "Corn Dog 7's greeting, word for word")
	_check(_line(c, "bl_cd7_corndog") == "One corn dog coming right up.", "Corn Dog 7: the corn dog line")
	_check(_price(c, "bl_cd7_corndog") == 200, "Corn Dog 7: corn dog $2")
	_check(shops.get("radioshack", {}).get("greeting") == "Welcome to RadioShack. What can I get for you?", "RadioShack's greeting, word for word")
	var b: Dictionary = shops.get("b_dalton", {})
	_check(str(b.get("greeting_by", "")).begins_with("PLACEHOLDER"), "B. Dalton's greeting is marked PLACEHOLDER")
	var books := 0
	for x in b.get("items", []):
		books += 1 if int(x.price_cents) == 1000 else 0
	_check(books == b.get("items", []).size() and books >= 5, "B. Dalton: every book at $10 (%d; int-51: FOOD's four, Moby-Dick, the paperback)" % books)
	_check(db.get_item("bd_moby_dick").get("name") == "Moby-Dick", "Moby-Dick keeps its title")
	# RadioShack: every standalone item kind in the store is sold
	var rs_ids := []
	for x in shops.get("radioshack", {}).get("items", []):
		rs_ids.append(str(x.item))
	for e in _json("res://data/items/radioshack.json"):
		_check(rs_ids.has(str(e.id)), "RadioShack sells %s" % e.id)

func _years(d: Dictionary) -> Array:
	return Array(d.get("years", [])).map(func(y): return int(y))

func _line(s: Dictionary, item: String) -> String:
	for x in s.get("items", []):
		if str(x.item) == item:
			return str(x.ready_line)
	return ""

func _price(s: Dictionary, item: String) -> int:
	for x in s.get("items", []):
		if str(x.item) == item:
			return int(x.price_cents)
	return -1

## 2. A buy, and it is saved.
func _test_buy(db) -> void:
	var store := {}
	var m = _mall(store)
	var sh = Shop.new()
	sh.setup(null, m, db)
	_check(m.shop == sh, "mall.shop is the shop screen")
	var cards := [0]
	m.received.connect(func(_id): cards[0] += 1)
	_check(m.money == 10000, "a new player has $100.00")
	sh.shop_id = "woolworth"
	sh.stock = Shop.read_stock(sh.shops.woolworth, db, 1995)
	var i := _idx(sh, "bl_wl_rootbeer_float")
	_check(sh.buy(i), "buy a root beer float")
	_check(m.money == 9800, "the money comes off once: $98.00 (is %s)" % m.money_text(m.money))
	_check(m.count("bl_wl_rootbeer_float") == 1 and m.hand == "", "one float in the bag, not in the hand")
	_check(cards[0] == 1, "one \"You received\" card")
	_check(sh.line == "One root beer float coming right up.", "the attendant says the ready line")
	var log: Array = JSON.parse_string(str(store.get("mall.ledger", "{}"))).get("log", [])
	var n := 0
	for l in log:
		if str(l).contains("Shop woolworth: bl_wl_rootbeer_float") or (l is Dictionary and str(l.get("reason", "")).contains("bl_wl_rootbeer_float")):
			n += 1
	_check(n == 1, "one ledger entry for it (%d)" % n)
	# a fresh load from the same storage: the float and the wallet are there
	var m2 = _mall(store)
	m2.load_saved()
	_check(m2.count("bl_wl_rootbeer_float") == 1, "saved: the float is in the bag after a reload")
	_check(m2.money == 9800, "saved: the wallet after a reload is $98.00")
	# a second buy is a second float
	_check(sh.buy(i) and m.money == 9600 and m.count("bl_wl_rootbeer_float") == 2, "a second buy: two floats, $96.00")
	# 2026's wallet is the same one (design/godot-economy.md), its bag is not
	var m26 = _mall(store, 2026)
	m26.load_saved()
	_check(m26.money == 9600 and m26.count("bl_wl_rootbeer_float") == 0, "2026: the same wallet, its own bag")

func _idx(sh, item: String) -> int:
	for i in sh.stock.size():
		if sh.stock[i].item == item:
			return i
	return -1

## 3. Can't afford.
func _test_cant_afford(db) -> void:
	var store := {"mall.money": "150", "mall.econ": "1"}
	var m = _mall(store)
	var sh = Shop.new()
	sh.setup(null, m, db)
	sh.shop_id = "corn_dog_7"
	sh.stock = Shop.read_stock(sh.shops.corn_dog_7, db, 1995)
	var dog := _idx(sh, "bl_cd7_corndog")
	var fries := _idx(sh, "cd7_crinkle_fries")
	_check(not sh.can_buy(dog) and not sh.buy(dog), "$1.50: a $2.00 corn dog can't be bought")
	_check(m.money == 150 and m.count("bl_cd7_corndog") == 0, "nothing changed: $1.50, no corn dog")
	_check(sh.can_buy(fries) and sh.buy(fries) and m.money == 51, "the 99-cent fries can: $0.51 left")
	_check(not sh.buy(fries) and m.money == 51 and m.count("cd7_crinkle_fries") == 1, "a second order can't: still $0.51, one order")
	var exact := {"mall.money": "200", "mall.econ": "1"}
	var me = _mall(exact)
	var she = Shop.new()
	she.setup(null, me, db)
	she.stock = Shop.read_stock(she.shops.corn_dog_7, db, 1995)
	_check(she.buy(_idx(she, "bl_cd7_corndog")) and me.money == 0, "exactly $2.00 buys the corn dog, $0.00 left")

## 4. The shelves.
func _test_shelves(db) -> void:
	var stores := ["WOOLWORTH", "CORN DOG 7", "RADIO SHACK", "B. DALTON BOOKSELLER"]
	var rs := []
	for e in _json("res://data/items/radioshack.json"):
		rs.append(str(e.id))
	var placed := []
	var shown := 0
	for id in db.order:
		var e: Dictionary = db.get_item(id)
		var mine: bool = stores.has(str(e.get("store", ""))) or rs.has(id) or id.begins_with("standin_")
		if not mine:
			continue
		if e.has("place") and (str(e.place.get("year", e.year)) == "both" or int(e.place.get("year", e.year)) != 2026):   # 2026 has no shops (Steven, Nov 4: the corn dog pick-up stays there)
			placed.append(id)
		if e.has("display"):
			shown += 1
	_check(placed.is_empty(), "nothing in the four stores can be picked up off a shelf in 1995 (%s)" % str(placed))
	var cd: Dictionary = db.get_item("bl_cd7_corndog")
	_check(int(cd.display.year) == 1995 and int(cd.place.year) == 2026, "the corn dog: on show in 1995, a pick-up in 2026")
	_check(shown == 13, "13 items stand on show (8 RadioShack, the float, the corn dog, 3 paperbacks): %d" % shown)

## 5. The screen without a player.
func _test_screen(db) -> void:
	var m = _mall({})
	var sh = Shop.new()
	root.add_child(sh)
	await process_frame
	sh.setup(null, m, db)
	_check(not sh.open("nowhere"), "an unknown shop doesn't open")
	_check(sh.open("radioshack") and sh.is_open and sh.stock.size() == 18, "RadioShack opens with 18 things")
	await process_frame
	_check(sh.line_l.text == "Welcome to RadioShack. What can I get for you?", "the greeting shows")
	_check(sh.money_l.text == "Your money: $100.00", "the money shows: %s" % sh.money_l.text)
	var scan := _idx(sh, "rs_scanner")
	_check(sh.cards.size() == 18, "a card per thing")
	_check(sh.cards[scan].buy.disabled and sh.cards[scan].card.modulate.a < 1.0, "$199.99 scanner: greyed out at $100.00")
	var bat := _idx(sh, "rs_battery_card")
	_check(not sh.cards[bat].buy.disabled, "$3.49 batteries: not greyed out")
	sh.cards[bat].buy.pressed.emit()
	_check(m.money == 9651 and m.count("rs_battery_card") == 1, "BUY on the card: $96.51, batteries in the bag")
	_check(sh.line_l.text == "One pack of batteries coming right up.", "the ready line shows")
	_check(sh.money_l.text == "Your money: $96.51", "the money updates")
	sh.close()
	_check(not sh.is_open and not sh.ui.visible, "Back closes")
	var m26 = _mall({}, 2026)
	var s26 = Shop.new()
	root.add_child(s26)
	await process_frame
	s26.setup(null, m26, db)
	_check(not s26.open("woolworth") and not s26.open("corn_dog_7"), "2026: no shop opens (1995 only)")
	sh.queue_free()
	s26.queue_free()
