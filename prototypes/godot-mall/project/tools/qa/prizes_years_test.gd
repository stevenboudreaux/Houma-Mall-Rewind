## Headless checks of the two prize counters (workstream PRIZES, Steven Nov 3 2026; design/godot-prize-counter.md
## "PRIZES"): Pocket Change 1995 and games, inc. 2026.
##   1. every prize in each year's catalogue (prizes.json, prizes_2026.json) is on that year's redemption list,
##      and every entry there is an item of that year, with a scene that loads and builds a model, and an icon;
##   2. the shared prizes are one item in both years; no year shows the other's own prizes;
##   3. prices: from the catalogue; the boom box 5,000 and the plush 700 (Steven); every other price marked
##      "guess" in redemption.json;
##   4. redemption in both years spends only that year's tickets (year separation), into that year's bag;
##   5. the 1995 counter's bins: no level holds more than three bins, every catalogue slot names a prize.
##   godot --headless --path . --script res://tools/qa/prizes_years_test.gd
## Prints PRIZES YEARS TEST OK (n checks), or the failed checks.
extends SceneTree

const ItemDB = preload("res://scripts/items/item_db.gd")
const Inventory = preload("res://scripts/inventory.gd")
const Redemption = preload("res://scripts/redemption.gd")

var errors := []
var oks := 0

func _check(ok: bool, what: String) -> void:
	printerr(("ok   " if ok else "FAIL ") + what)
	if ok: oks += 1
	else: errors.append(what)

func _json(p: String):
	return JSON.parse_string(FileAccess.get_file_as_string(p))

func _mall(store: Dictionary, year: int):
	var m = Inventory.new()
	m.year = year
	m.backend = store
	return m

func _initialize() -> void:
	var db = ItemDB.new().load_dir()
	var sj = _json("res://scripts/redemption.json")
	var cats := {1995: _json("res://scripts/prizes.json"), 2026: _json("res://scripts/prizes_2026.json")}
	var lists := {1995: "stock", 2026: "stock_2026"}
	var stocks := {}
	for y in [1995, 2026]:
		var cat: Dictionary = cats[y].items
		var rows: Array = sj.get(lists[y], [])
		var covered := {}
		for s in rows:
			covered[str(s.get("prize", ""))] = true
		var missing := []
		for k in cat:
			if not covered.has(k): missing.append(k)
		_check(missing.is_empty(), "%d: every catalogue prize is on the redemption list %s" % [y, str(missing)])
		var st: Array = Redemption.read_stock(db, y)
		stocks[y] = st
		var lost := []
		var have := st.map(func(s): return s.item)
		for s in rows:
			if not (str(s.item) in have): lost.append(s.item)
		_check(lost.is_empty() and st.size() == rows.size(), "%d: every entry is an item of that year (%d of %d) %s" % [y, st.size(), rows.size(), str(lost)])
		var bad := []
		var price_bad := []
		for s in st:
			var e: Dictionary = db.get_item(s.item)
			if not ResourceLoader.exists(str(s.icon)) or not ResourceLoader.exists(str(e.scene)):
				bad.append(s.item)
			var pk := ""
			for r in rows:
				if str(r.item) == str(s.item): pk = str(r.get("prize", ""))
			if pk != "" and int(s.tickets) != int(cat[pk].tickets):
				price_bad.append(s.item)
		_check(bad.is_empty(), "%d: every prize has an icon and a scene %s" % [y, str(bad)])
		_check(price_bad.is_empty(), "%d: the screen's prices are the catalogue's (the tags in the case) %s" % [y, str(price_bad)])
		# guesses: everything but the boom box and the plush (Steven's)
		var unmarked := []
		for r in rows:
			var steven: bool = str(r.get("prize", "")) in ["boombox", "plush_bear", "plush_bunny", "plush_dog"] and y == 1995
			if steven == bool(r.get("guess", false)):
				unmarked.append(r.item)
		_check(unmarked.is_empty(), "%d: every price Steven hasn't given is marked a guess, his are not %s" % [y, str(unmarked)])
	# Steven's two numbers
	var by95 := {}
	for s in stocks[1995]: by95[s.item] = s
	_check(by95.has("bl_pc_boombox") and int(by95.bl_pc_boombox.tickets) == 5000, "the boom box is 5,000 tickets")
	_check(by95.has("bl_pc_plush_bear") and int(by95.bl_pc_plush_bear.tickets) == 700 and int(by95.bl_pc_plush_dog.tickets) == 700, "the plush are 700")
	# every model builds (the item scenes: prize_model.gd units and the Blender models): checked a frame later
	for y in [1995, 2026]:
		for s in stocks[y]:
			var sc = load(str(db.get_item(s.item).scene))
			if not (sc is PackedScene):
				models.append([s.item, null])
				continue
			var n: Node = sc.instantiate()
			root.add_child(n)
			models.append([s.item, n])
	# 2. shared and own prizes
	var ids95: Array = (stocks[1995] as Array).map(func(s): return s.item)
	var ids26: Array = (stocks[2026] as Array).map(func(s): return s.item)
	var shared: Array = ids95.filter(func(i): return i in ids26)
	var shared_bad: Array = shared.filter(func(i): return str(db.get_item(i).year) != "both")
	_check(shared.size() >= 8 and shared_bad.is_empty(), "%d prizes are shared, each one item for both years %s" % [shared.size(), str(shared_bad)])
	var own95: Array = ids95.filter(func(i): return not (i in ids26))
	var own26: Array = ids26.filter(func(i): return not (i in ids95))
	_check(own95.size() >= 20 and own26.size() >= 20, "each counter has prizes of its own (1995 %d, 2026 %d)" % [own95.size(), own26.size()])
	_check(own95.all(func(i): return str(db.get_item(i).year) != "both" and int(db.get_item(i).year) == 1995) \
		and own26.all(func(i): return str(db.get_item(i).year) != "both" and int(db.get_item(i).year) == 2026),
		"a counter's own prizes belong to its year only")
	_check(not ("pogs" in ids26) and not ("pc_vpet" in ids26) and not ("gi_console" in ids95) and not ("gi_popper_key" in ids95),
		"no Pog packs or virtual pets in 2026, no consoles or poppers in 1995")
	# 4. redemption in both years, year separation
	var store := {}
	var a = _mall(store, 1995)
	var b = _mall(store, 2026)
	a.tickets = 300
	b.tickets = 1000
	var ra = Redemption.new().setup(null, a, db)
	var rb = Redemption.new().setup(null, b, db)
	_check(ra.stock.size() == stocks[1995].size() and rb.stock.size() == stocks[2026].size(), "each year's screen shows its own stock")
	var i_slap := -1
	for i in ra.stock.size():
		if ra.stock[i].item == "slap": i_slap = i
	var j_dough := -1
	var j_slap := -1
	for i in rb.stock.size():
		if rb.stock[i].item == "bl_gi_doughball": j_dough = i
		if rb.stock[i].item == "slap": j_slap = i
	_check(i_slap >= 0 and j_slap >= 0 and ra.price(i_slap) != rb.price(j_slap), "a shared prize has each year's price (slap bracelet %d / %d)" % [ra.price(i_slap) if i_slap >= 0 else -1, rb.price(j_slap) if j_slap >= 0 else -1])
	_check(ra.buy(i_slap) and a.tickets == 300 - ra.price(i_slap) and b.tickets == 1000, "1995: buying spends 1995's tickets only (%d left, 2026 still %d)" % [a.tickets, b.tickets])
	_check(a.count("slap") == 1 and b.count("slap") == 0, "1995: the prize goes into 1995's bag")
	_check(rb.buy(j_dough) and b.tickets == 1000 - rb.price(j_dough) and a.tickets == 300 - ra.price(i_slap), "2026: buying spends 2026's tickets only (%d left)" % b.tickets)
	_check(b.count("bl_gi_doughball") == 1 and a.count("bl_gi_doughball") == 0, "2026: the prize goes into 2026's bag")
	a.tickets = 5000
	b.tickets = 0
	var j_big: int = rb.stock.size() - 1
	_check(not rb.can_buy(j_big) and not rb.buy(j_big) and b.tickets == 0 and a.tickets == 5000, "2026 can't spend 1995's tickets (5,000 in 1995, 0 in 2026)")
	var a2 = _mall(store, 1995)
	var b2 = _mall(store, 2026)
	_check(a2.load_saved() and b2.load_saved() and a2.count("slap") == 1 and b2.count("bl_gi_doughball") == 1 and b2.count("slap") == 0,
		"the bags come back from the save, each in its year")
	# 5. the 1995 bins
	var per := {}
	for c in cats[1995].case:
		var key := "%s/%d/%d" % [c[0], int(c[1]), int(c[2])]
		per[key] = per.get(key, 0) + 1
		if not cats[1995].items.has(str(c[4])):
			_check(false, "slot %s names a prize (%s)" % [key, c[4]])
	var crowded := per.keys().filter(func(k): return per[k] > 3)
	_check(crowded.is_empty() and per.size() == 15, "1995: 15 levels filled, none with more than three bins %s" % str(crowded))
	var per26 := {}
	for c in cats[2026].case:
		var key2 := "%s/%d/%d" % [c[0], int(c[1]), int(c[2])]
		per26[key2] = true
	_check(per26.size() == 18, "2026: the three showcases' 18 bays x levels are all filled (%d)" % per26.size())

var models := []
var frames := 0

func _process(_dt: float) -> bool:
	frames += 1
	if frames < 3:
		return false
	var nomodel := []
	for m in models:
		if m[1] == null:
			nomodel.append(m[0])
			continue
		var vis: int = m[1].find_children("*", "GeometryInstance3D", true, false).size()
		if vis == 0: nomodel.append(m[0])
	_check(nomodel.is_empty(), "every prize's item scene builds a visible model (%d) %s" % [models.size(), str(nomodel)])
	if errors.is_empty():
		print("PRIZES YEARS TEST OK (%d checks)" % oks)
	else:
		print("PRIZES YEARS TEST FAILED: %d of %d\n  %s" % [errors.size(), errors.size() + oks, "\n  ".join(errors)])
	quit(0 if errors.is_empty() else 1)
	return true
