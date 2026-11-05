## The one item system (ws/items, Steven Nov 4 2026; design/godot-items.md), headless, no scene:
##   godot --headless --path . --script res://tools/qa/items_test.gd
## 1. The schema: every data/items entry loads through scripts/items/item_db.gd with a known category
##    and a subcategory, no id twice, none skipped, every int-51 id still there unchanged
##    (tools/qa/fixtures/item_ids_int51.txt), the files split by store (no workstream files left).
## 2. Hand by default: a holdable thing received from each source (a shop, the redemption counter, a
##    dialogue's give and buy, a game page's inbox, a pick-up) lands in the hand, the held one goes into
##    the bag, a "pocket" thing goes into the bag; the root beer float, the corn dog and the Bayou Bruiser
##    figure are holdable; every holdable can be bagged and held again; the card says where.
## 3. The years' names: 1995 is shown as "1990s", 2026 as "2026" (scripts/years.gd).
## 4. No opening: scripts/menu/opening.gd and data/story/opening.json are gone.
## Prints ITEMS TEST OK (n checks), or the failed checks. Exit code 0 / 1.
extends SceneTree

const Inventory = preload("res://scripts/inventory.gd")
const ItemDB = preload("res://scripts/items/item_db.gd")
const Shop = preload("res://scripts/shop.gd")
const Redemption = preload("res://scripts/redemption.gd")
const Years = preload("res://scripts/years.gd")
const FIXTURE := "res://tools/qa/fixtures/item_ids_int51.txt"

var oks := 0
var errors: Array = []

func _check(ok: bool, what: String) -> void:
	printerr(("ok   " if ok else "FAIL ") + what)
	if ok:
		oks += 1
	else:
		errors.append(what)

func _fresh(db, year := 1995) -> Object:
	var m = Inventory.new()
	m.year = year
	m.backend = {"mall.econ": "1"}    # bank.gd: no old saves to fold in
	m.db = db
	return m

func _initialize() -> void:
	var db = ItemDB.new().load_dir()
	_test_schema(db)
	_test_files()
	_test_sources(db)
	_test_holdables(db)
	_test_years()
	_check(not FileAccess.file_exists("res://scripts/menu/opening.gd") and not FileAccess.file_exists("res://data/story/opening.json"), "no opening: its script and words are gone")
	printerr("ITEMS TEST OK (%d checks)" % oks if errors.is_empty() else "ITEMS TEST FAILED: " + str(errors))
	quit(0 if errors.is_empty() else 1)

## 1. The schema.
func _test_schema(db) -> void:
	var raw := 0
	var bad := []
	var ids := {}
	var da := DirAccess.open(ItemDB.DIR)
	for f in da.get_files():
		if not f.ends_with(".json"):
			continue
		var j = JSON.parse_string(FileAccess.get_file_as_string(ItemDB.DIR + f))
		var list = j.get("items", []) if j is Dictionary else j
		for e in list:
			raw += 1
			var why := ItemDB.check(e)
			if why != "":
				bad.append("%s %s: %s" % [f, e.get("id", "?"), why])
			ids[str(e.get("id", ""))] = int(ids.get(str(e.get("id", "")), 0)) + 1
	_check(bad.is_empty(), "every entry has the schema (category, subcategory, class, scene, icon, year) %s" % str(bad))
	_check(raw == db.order.size() and db.dupes.is_empty(), "every entry loads, none skipped, no id twice (%d entries, %d loaded, dupes %s)" % [raw, db.order.size(), str(db.dupes)])
	var twice: Array = ids.keys().filter(func(k): return int(ids[k]) > 1)
	_check(twice.is_empty(), "ids are unique across the files %s" % str(twice))
	var cats := {}
	for id in db.order:
		var e: Dictionary = db.get_item(id)
		cats[str(e.category)] = int(cats.get(str(e.category), 0)) + 1
	_check(cats.keys().all(func(c): return ItemDB.CATEGORIES.has(c)), "every category is one of ItemDB.CATEGORIES %s" % str(cats))
	_check(db.ids_in("book").has("bd_moby_dick") and not db.ids_in("food").has("bd_moby_dick"), "Moby-Dick is a book, not food")
	_check(db.ids_in("drink").has("bl_wl_rootbeer_float") and db.ids_in("food").has("bl_cd7_corndog"), "the root beer float is a drink, the corn dog food")
	# no id changed or went since int-51
	var old := []
	for line in FileAccess.get_file_as_string(FIXTURE).split("\n"):
		if line != "" and not line.begins_with("#"):
			old.append(line.strip_edges())
	var gone: Array = old.filter(func(i): return not db.items.has(i))
	_check(old.size() == 135 and gone.is_empty(), "all %d int-51 ids are still items %s" % [old.size(), str(gone)])
	var added: Array = db.order.filter(func(i): return not old.has(i))
	_check(added.is_empty(), "no new ids beside the int-51 ones (a new item is fine later: add it to the fixture) %s" % str(added))
	# every reference into the item list resolves
	var refs := []
	for s in Shop.read_shops().values():
		for x in s.get("items", []):
			if not db.items.has(str(x.item)):
				refs.append("shop " + str(x.item))
	var sj = JSON.parse_string(FileAccess.get_file_as_string("res://scripts/redemption.json"))
	for k in ["stock", "stock_2026"]:
		for x in sj.get(k, []):
			if not db.items.has(str(x.item)):
				refs.append("redemption " + str(x.item))
	var cj = JSON.parse_string(FileAccess.get_file_as_string("res://data/story/cucos/cucos.json"))
	for id in cj.get("travels", {}):
		if not db.items.has(str(id)):
			refs.append("cucos " + str(id))
	_check(refs.is_empty(), "every shop, redemption and Cuco's id is an item %s" % str(refs))
	_check(ItemDB.check({"id": "a", "name": "A", "class": "pocket", "scene": "", "icon": "", "year": 1995}) != "", "an entry without a category is refused")
	_check(ItemDB.check({"id": "a", "name": "A", "category": "gizmo", "subcategory": "x", "class": "pocket", "scene": "", "icon": "", "year": 1995}) != "", "an unknown category is refused")
	_check(ItemDB.check({"id": "a", "name": "A", "category": "toy", "subcategory": "", "class": "pocket", "scene": "", "icon": "", "year": 1995}) != "", "an empty subcategory is refused")
	_check(ItemDB.shared() == ItemDB.shared() and ItemDB.shared().order.size() == db.order.size(), "ItemDb.shared() is one list, read once")

## The files are split by store (or place), not by the workstream that made them.
func _test_files() -> void:
	var files: Array = Array(DirAccess.open(ItemDB.DIR).get_files()).filter(func(f): return f.ends_with(".json"))
	var old := ["blender_props.json", "blender_props_2.json", "claw_prizes.json", "food.json", "games_inc_stock.json",
		"pocket_change_more.json", "pocket_change_stock.json", "radioshack.json", "shop_standins.json"]
	_check(old.all(func(f): return not files.has(f)), "no workstream files left %s" % str(files))
	for f in ["pocket_change.json", "games_inc.json", "b_dalton.json", "woolworth.json", "corn_dog_7.json", "cucos.json", "radio_shack.json", "stockrooms.json"]:
		_check(files.has(f), "the store file " + f)

## 2. Hand by default, from each source.
func _test_sources(db) -> void:
	# a shop (scripts/shop.gd buy): the corn dog
	var m = _fresh(db)
	m.add_money(1000, "test")
	var sh = Shop.new()
	sh.mall = m
	sh.db = db
	sh.shops = Shop.read_shops()
	sh.shop_id = "corn_dog_7"
	sh.stock = Shop.read_stock(sh.shops.corn_dog_7, db, 1995)
	var cards := []
	m.received.connect(func(id): cards.append([id, m.hand]))
	var i := -1
	for k in sh.stock.size():
		if str(sh.stock[k].item) == "bl_cd7_corndog":
			i = k
	_check(i >= 0 and sh.buy(i), "a shop sells the corn dog")
	_check(m.hand == "bl_cd7_corndog" and m.inventory.is_empty(), "bought: the corn dog is in the hand, not the bag")
	_check(cards.size() == 1 and cards[0] == ["bl_cd7_corndog", "bl_cd7_corndog"], "one card, fired once it is in the hand %s" % str(cards))
	# a second thing bought: into the hand, the corn dog into the bag
	var j := -1
	for k in sh.stock.size():
		if str(sh.stock[k].item) != "bl_cd7_corndog" and ItemDB.holdable(db.get_item(str(sh.stock[k].item))):
			j = k
	if j >= 0:
		var id2 := str(sh.stock[j].item)
		_check(sh.buy(j) and m.hand == id2 and m.count("bl_cd7_corndog") == 1 and m.hand != "bl_cd7_corndog", "the next thing bought takes the hand; the corn dog goes into the bag")
	# the same thing twice: the held one stays, the new one is bagged
	var m2 = _fresh(db)
	m2.receive("bl_wl_rootbeer_float", 1, "shop")
	_check(m2.receive("bl_wl_rootbeer_float", 1, "shop") == "bag" and m2.hand == "bl_wl_rootbeer_float" and m2.count("bl_wl_rootbeer_float") == 2, "a second root beer float goes into the bag beside the held one")
	_check(m2.receive("wl_hot_dog", 3, "shop") == "hand" and m2.hand == "wl_hot_dog" and m2.count("wl_hot_dog") == 3 and m2.count("bl_wl_rootbeer_float") == 2, "three at once: one in the hand, two in the bag")
	# the redemption counter (scripts/redemption.gd buy): a plush (hand), a lollipop (pocket)
	var m3 = _fresh(db)
	m3.add_tickets(10000, "test")
	var r = Redemption.new()
	r.mall = m3
	r.db = db
	r.stock = Redemption.read_stock(db, 1995)
	var bear := -1
	var pop := -1
	for k in r.stock.size():
		if str(r.stock[k].item) == "bl_pc_plush_bear": bear = k
		if str(r.stock[k].item) == "pc_lollipop": pop = k
	_check(bear >= 0 and r.buy(bear) and m3.hand == "bl_pc_plush_bear", "won at the counter: the plush bear is in the hand")
	_check(pop >= 0 and r.buy(pop) and m3.hand == "bl_pc_plush_bear" and m3.count("pc_lollipop") == 1, "a lollipop (pocket) goes into the bag, the bear stays in the hand")
	# a game page's inbox (bank.gd give -> inventory.gd collect): the Bayou Bruiser figure from the claw
	var m4 = _fresh(db)
	m4.receive("bl_pc_boombox", 1, "test")
	m4.backend["mall.inbox-1995"] = JSON.stringify([{"id": "claw-item:t:1", "item": "pc_claw_bruiser", "n": 1}, {"id": "claw-item:t:2", "item": "pc_claw_pogEye", "n": 1}])   # what play/lib/mallbank.js give() writes
	_check(m4.collect() == 2, "the claw's two prizes arrive")
	_check(m4.hand == "pc_claw_bruiser" and m4.count("bl_pc_boombox") == 1 and m4.count("pc_claw_pogEye") == 1 and m4.hand != "pc_claw_pogEye", "won in a game page: the Bayou Bruiser figure in the hand, the boom box put in the bag, the POGs in the bag")
	# a dialogue's give and buy (scripts/dialogue/dialogue_state.gd)
	var m5 = _fresh(db)
	var st = load("res://scripts/dialogue/dialogue_state.gd").new()
	st.mall = m5
	st.give("cu_topshelf")
	_check(m5.hand == "cu_topshelf", "given in a dialogue: the margarita is in the hand")
	st.give("cu_doubloon")
	_check(m5.hand == "cu_topshelf" and m5.count("cu_doubloon") == 1, "the doubloon (pocket) goes into the bag")
	m5.add_money(500, "test")
	_check(st.buy("cu_beer", 200) and m5.hand == "cu_beer" and m5.count("cu_topshelf") == 1, "bought in a dialogue: the beer in the hand, the margarita into the bag")
	# picked up (interact.gd pick_up -> mall.take)
	var m6 = _fresh(db)
	m6.receive("pc_claw_gator", 1, "test")
	m6.take("folse_stick")
	_check(m6.hand == "folse_stick" and m6.count("pc_claw_gator") == 1 and m6.moved.has("folse_stick"), "picked up: the stick in the hand, the gator plush into the bag")
	# a move between the hand and the bag is no card
	var n6 := [0]
	m6.received.connect(func(_id): n6[0] += 1)
	m6.put_away()
	m6.hold("pc_claw_gator")
	_check(n6[0] == 0 and m6.hand == "pc_claw_gator" and m6.count("folse_stick") == 1, "put away / hold: no card")
	# Cuco's doubloon travelling between years stays a quiet move into the bag
	var m7 = _fresh(db, 2026)
	var n7 := [0]
	m7.received.connect(func(_id): n7[0] += 1)
	m7.add("cu_doubloon", 1, true)
	_check(n7[0] == 0 and m7.hand == "" and m7.count("cu_doubloon") == 1, "a quiet add (the doubloon travelling) goes into the bag with no card")
	# the old name: add() without quiet is receive()
	var m8 = _fresh(db)
	m8.add("bl_kk_caramelcorn")
	_check(m8.hand == "bl_kk_caramelcorn", "mall.add() is the same receive path (caramel corn in the hand)")
	# the card says where it went
	var pop_ui = load("res://scripts/received_popup.gd").new()
	var m9 = _fresh(db)
	pop_ui.setup(null, m9, db)
	root.add_child(pop_ui)
	m9.receive("bl_oj_cup", 1, "shop")
	_check(pop_ui.current == "bl_oj_cup" and pop_ui.where_l.text.begins_with("In your hand"), "the card: In your hand (%s)" % pop_ui.where_l.text)
	m9.receive("pc_lollipop", 1, "prize")
	pop_ui.shown_for = 1.0
	pop_ui.dismiss()
	_check(pop_ui.current == "pc_lollipop" and pop_ui.where_l.text == "In your bag", "the next card: In your bag")
	pop_ui.shown_for = 1.0
	pop_ui.dismiss()
	pop_ui.queue_free()

## Every holdable thing can be held and bagged; the named ones are holdable.
func _test_holdables(db) -> void:
	for id in ["bl_wl_rootbeer_float", "bl_cd7_corndog", "pc_claw_bruiser"]:
		_check(ItemDB.holdable(db.get_item(id)), "%s is held in the hand" % id)
	var bad := []
	for id in db.order:
		var e: Dictionary = db.get_item(id)
		var m = _fresh(db)
		var w: String = m.receive(id, 1, "test")
		if ItemDB.holdable(e):
			m.put_away()
			var ok: bool = w == "hand" and m.hand == "" and m.count(id) == 1 and m.hold(id) and m.hand == id and m.inventory.is_empty()
			if not ok:
				bad.append(id)
		elif w != "bag" or m.hand != "":
			bad.append(id)
	_check(bad.is_empty(), "every holdable item goes into the hand, can be put in the bag and held again; every pocket item goes into the bag %s" % str(bad))

## 3. The years' names.
func _test_years() -> void:
	_check(Years.label(1995) == "1990s" and Years.label("1995") == "1990s", "1995 is shown as 1990s")
	_check(Years.label(2026) == "2026" and Years.label("2026") == "2026", "2026 is shown as 2026")
	_check(Years.other(1995) == 2026 and Years.other(2026) == 1995, "the other year")
