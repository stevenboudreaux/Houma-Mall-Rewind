## Headless checks of the ws/interiors counter shops (Nov 4 2026; design/godot-shops.md "ws/interiors";
## design/storefronts/great-american-cookie.md, auntie-annes.md, payless.md, spencers.md):
##   1. the data: each shop has its attendant (a PLACEHOLDER clothed preset, wing 2, the shop's years), a
##      PLACEHOLDER greeting, whole-cent prices marked PLACEHOLDER guesses, items of its year with a model and
##      an icon, stand-ins marked; the cookie shop has a 1995 and a 2026 entry
##   2. year gating: each opens only in its years
##   3. buys: a holdable thing goes into the hand (hand by default, design/godot-items.md), a pocket thing
##      into the bag; the lava lamp (the Gumballs prize's id) is sold at Spencer's in 2026
##   4. nothing off the shelves: the sugar cookie is stock on show in 1995, no longer a pick-up
##   godot --headless --path . --script res://tools/qa/shop_interiors_test.gd
## Prints SHOP INTERIORS TEST OK (n checks), or the failed checks. Exit code 0 / 1.
extends SceneTree

const Inventory = preload("res://scripts/inventory.gd")
const ItemDB = preload("res://scripts/items/item_db.gd")
const Shop = preload("res://scripts/shop.gd")

## shop id -> [the layout's store name, years, how many things]
const SHOPS := {
	"great_american_cookie": ["GREAT AMERICAN COOKIE CO", [1995], 5],
	"great_american_cookie_2026": ["GREAT AMERICAN COOKIES", [2026], 4],
	"auntie_annes": ["AUNTIE ANNE'S", [2026], 4],
	"payless": ["PAYLESS SHOES", [1995], 6],
	"spencers": ["SPENCER'S", [2026], 5],
}

var oks := 0
var errors: Array = []

func _check(ok: bool, what: String) -> void:
	printerr(("ok   " if ok else "FAIL ") + what)
	if ok:
		oks += 1
	else:
		errors.append(what)

func _mall(store: Dictionary, year: int):
	var m = Inventory.new()
	m.year = year
	m.backend = store
	return m

func _json(p: String):
	return JSON.parse_string(FileAccess.get_file_as_string(p))

func _years(d: Dictionary) -> Array:
	return Array(d.get("years", [])).map(func(y): return int(y))

func _initialize() -> void:
	var db = ItemDB.new().load_dir()
	_test_data(db)
	_test_years()
	_test_buys(db)
	_test_shelves(db)
	printerr("SHOP INTERIORS TEST OK (%d checks)" % oks if errors.is_empty() else "SHOP INTERIORS TEST FAILED: " + str(errors))
	quit(0 if errors.is_empty() else 1)

## 1. The data.
func _test_data(db) -> void:
	var shops := Shop.read_shops()
	var att := {}
	for a in _json("res://data/story/attendants.json").attendants:
		att[str(a.id)] = a
	for id in SHOPS:
		_check(shops.has(id), "%s is a shop" % id)
		if not shops.has(id):
			continue
		var s: Dictionary = shops[id]
		var want: Array = SHOPS[id]
		_check(str(s.store) == want[0] and _years(s) == want[1], "%s: %s, %s" % [id, want[0], str(want[1])])
		_check(str(s.get("greeting", "")) != "" and str(s.get("greeting_by", "")).begins_with("PLACEHOLDER"), "%s: a greeting, marked PLACEHOLDER" % id)
		var a: Dictionary = att.get(str(s.attendant), {})
		_check(not a.is_empty() and str(a.get("shop", "")) == id, "%s: its attendant names it" % id)
		_check(str(a.get("name", "")) == "PLACEHOLDER" and int(a.get("wing", 0)) == 2 and _years(a) == want[1] and str(a.get("store", "")) == want[0],
			"%s: the attendant is PLACEHOLDER, wing 2, %s" % [id, str(want[1])])
		var ar: Array = a.get("area", [])
		var ta: Array = a.get("talk_at", [])
		_check(ar.size() == 4 and float(ar[0]) < float(ar[2]) and float(ar[1]) < float(ar[3]) and ta.size() == 2, "%s: an area behind the counter and a talk spot" % id)
		_check(((str(a.get("look", "")) == "cast" and Cast.has(str(a.get("cast", "")))) or (str(a.get("look", "")) == "mixamo" and ResourceLoader.exists("res://npc/skins/%s.scn" % a.get("skin", "?")))),
			"%s: the attendant's body comes through the loader (CHAR-STRIP: look %s, %s)" % [id, a.get("look", "?"), a.get("cast", a.get("skin", "?"))])
		var st := Shop.read_stock(s, db, int(want[1][0]))
		_check(st.size() == s.items.size() and st.size() == want[2], "%s: all %d things are items of %d (%d)" % [id, want[2], want[1][0], st.size()])
		for x in s.items:
			var e: Dictionary = db.get_item(str(x.item))
			var pc = x.get("price_cents", -1)
			_check((pc is int or pc is float) and float(pc) == floor(float(pc)) and float(pc) > 0, "%s %s: price %s whole cents" % [id, x.item, str(pc)])
			_check(str(x.get("price_note", "")).begins_with("PLACEHOLDER") and str(x.get("ready_line_by", "")).begins_with("PLACEHOLDER")
				and str(x.get("ready_line", "")) != "", "%s %s: the price and the line are marked PLACEHOLDER" % [id, x.item])
			_check(ResourceLoader.exists(str(e.get("scene", ""))) and ResourceLoader.exists(str(e.get("icon", ""))), "%s %s: model and icon load" % [id, x.item])
			if str(x.item).begins_with("standin_"):
				_check(bool(x.get("standin", false)) and bool(e.get("standin", false)) and str(e.get("store", "")) != "", "%s %s: marked a stand-in, in its store's file" % [id, x.item])
	# the cookie shop: the same things in both years (the sugar cookie is a 1995 item)
	var a95 := (shops.get("great_american_cookie", {}).get("items", []) as Array).map(func(x): return str(x.item)).filter(func(i): return i != "bl_gac_sugarcookie")
	var a26 := (shops.get("great_american_cookie_2026", {}).get("items", []) as Array).map(func(x): return str(x.item))
	a95.sort(); a26.sort()
	_check(a95 == a26, "the cookie shop sells the same things in 1995 and 2026 (and the sugar cookie in 1995)")

## 2. Each opens only in its years.
func _test_years() -> void:
	var shops := Shop.read_shops()
	for id in SHOPS:
		var y: int = SHOPS[id][1][0]
		var other := 2026 if y == 1995 else 1995
		_check(Shop.open_in(shops[id], y) and not Shop.open_in(shops[id], other), "%s opens in %d, not in %d" % [id, y, other])

## 3. Buys: into the hand (or the bag for a pocket thing); the lava lamp at Spencer's.
func _test_buys(db) -> void:
	for c in [["auntie_annes", 2026, "standin_aa_original_pretzel"], ["payless", 1995, "standin_pay_sneakers"],
			["great_american_cookie", 1995, "standin_gac_choc_chip_cookie"], ["great_american_cookie_2026", 2026, "standin_gac_choc_chip_cookie"],
			["spencers", 2026, "bl_gb_lavalamp"]]:
		var m = _mall({}, c[1])
		var sh = Shop.new()
		sh.setup(null, m, db)
		sh.shop_id = c[0]
		sh.stock = Shop.read_stock(sh.shops[c[0]], db, c[1])
		var i := _idx(sh, c[2])
		var p: int = sh.price(i)
		_check(i >= 0 and sh.buy(i), "%s (%d): buy %s" % [c[0], c[1], c[2]])
		_check(m.money == 10000 - p and m.hand == c[2] and m.inventory.is_empty(), "%s: $%s off once, %s in the hand" % [c[0], m.money_text(p), c[2]])
		_check(sh.line == str(sh.stock[i].line) and sh.line != "", "%s: the ready line" % c[0])
		sh.free()
	# a pocket thing goes into the bag, and what is held stays held
	var m2 = _mall({}, 1995)
	var s2 = Shop.new()
	s2.setup(null, m2, db)
	s2.shop_id = "payless"
	s2.stock = Shop.read_stock(s2.shops.payless, db, 1995)
	_check(s2.buy(_idx(s2, "standin_pay_boots")) and s2.buy(_idx(s2, "standin_pay_shoe_polish")), "payless: boots, then polish")
	_check(m2.hand == "standin_pay_boots" and m2.count("standin_pay_shoe_polish") == 1 and m2.hand != "standin_pay_shoe_polish",
		"the polish (pocket) is in the bag, the boots still in the hand")
	s2.free()
	var m3 = _mall({}, 2026)
	var s3 = Shop.new()
	s3.setup(null, m3, db)
	s3.shop_id = "spencers"
	s3.stock = Shop.read_stock(s3.shops.spencers, db, 2026)
	_check(s3.buy(_idx(s3, "standin_sp_stickers")) and m3.hand == "" and m3.count("standin_sp_stickers") == 1, "spencers: a sticker pack (pocket) into the bag")
	s3.free()
	var lamp: Dictionary = db.get_item("bl_gb_lavalamp")
	_check(str(lamp.year) == "both" and str(lamp.store) == "GUMBALLS" and int(lamp.place.year) == 1995,
		"the lava lamp: one id, year both, still the Gumballs pick-up in 1995")

func _idx(sh, item: String) -> int:
	for i in sh.stock.size():
		if sh.stock[i].item == item:
			return i
	return -1

## 4. The sugar cookie is stock on show, no longer a pick-up.
func _test_shelves(db) -> void:
	var c: Dictionary = db.get_item("bl_gac_sugarcookie")
	_check(not c.has("place") and c.has("display") and bool(c.display.get("runtime", false)) and int(c.display.year) == 1995 and int(c.display.wing) == 2,
		"the sugar cookie stands on show on the 1995 case (display, runtime), not a pick-up")
	for id in db.order:
		var e: Dictionary = db.get_item(id)
		if str(e.get("store", "")) in ["AUNTIE ANNE'S", "PAYLESS SHOES", "SPENCER'S", "GREAT AMERICAN COOKIE CO"]:
			_check(not e.has("place"), "%s: nothing in the four shops lies about to be picked up" % id)
