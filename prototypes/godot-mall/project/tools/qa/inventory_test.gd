## Unit checks for the carried state (scripts/inventory.gd) and the item files (scripts/items/item_db.gd),
## headless, no scene: design/godot-interaction.md.
##   godot --headless --path . --script res://tools/qa/inventory_test.gd
## Prints INVENTORY TEST OK (n checks), or the failed checks. Exit code 0 / 1.
extends SceneTree

const Inventory = preload("res://scripts/inventory.gd")
const ItemDB = preload("res://scripts/items/item_db.gd")

var oks := 0
var errors: Array = []

func _check(ok: bool, what: String) -> void:
	printerr(("ok   " if ok else "FAIL ") + what)
	if ok:
		oks += 1
	else:
		errors.append(what)

## A fresh state on its own in-memory store (no localStorage, no Engine meta).
func _fresh(year := 1995) -> Object:
	var m = Inventory.new()
	m.year = year
	m.backend = {}
	return m

func _initialize() -> void:
	_test_add_remove()
	_test_hand()
	_test_world()
	_test_round_trip()
	_test_persist()
	_test_bad_input()
	_test_item_files()
	printerr("INVENTORY TEST OK (%d checks)" % oks if errors.is_empty() else "INVENTORY TEST FAILED: " + str(errors))
	quit(0 if errors.is_empty() else 1)

func _test_add_remove() -> void:
	var m = _fresh()
	var fired := [0]
	m.changed.connect(func(): fired[0] += 1)
	m.add("pogs")
	m.add("pogs", 2)
	m.add("slap")
	_check(m.count("pogs") == 3 and m.count("slap") == 1, "add counts up (pogs 3, slap 1)")
	_check(m.inventory.size() == 2 and m.inventory[0].id == "pogs", "one entry per id, in pickup order")
	_check(m.remove("pogs", 2) and m.count("pogs") == 1, "remove 2 of 3")
	_check(not m.remove("pogs", 5) and m.count("pogs") == 1, "removing more than carried fails and changes nothing")
	_check(m.remove("pogs") and not m.has("pogs") and m.inventory.size() == 1, "removing the last drops the entry")
	_check(not m.remove("nothing"), "removing an id not carried fails")
	m.add("", 1)
	m.add("x", 0)
	_check(m.inventory.size() == 1, "empty ids and zero counts are ignored")
	_check(fired[0] == 5, "changed fires on each real change (%d)" % fired[0])

func _test_hand() -> void:
	var m = _fresh()
	m.take("folse_stick", true)
	_check(m.hand == "folse_stick" and m.has("folse_stick") and m.inventory.is_empty(), "a hand item picked up goes to the hand")
	m.take("spring", true)
	_check(m.hand == "spring" and m.count("folse_stick") == 1 and m.inventory[0].id == "folse_stick", "a second hand item: the first goes into the bag")
	m.put_away()
	_check(m.hand == "" and m.count("spring") == 1, "put away: hand empty, item in the bag")
	_check(m.hold("folse_stick") and m.hand == "folse_stick" and m.count("folse_stick") == 1, "hold takes it out of the bag")
	_check(not m.hold("dice"), "can't hold what isn't carried")
	m.take("pogs", false)
	_check(m.hand == "folse_stick" and m.count("pogs") == 1, "a pocket item goes to the bag, hand unchanged")

func _test_world() -> void:
	var m = _fresh()
	var place := {"wing": 2, "year": 1995, "pos": [1, 0, 2], "yaw": 0}
	_check(m.where("spring", place) == place, "an untouched item is at its data place")
	_check(m.where("spring", null) == null, "an item with no place isn't in the world")
	m.take("spring", true)
	_check(m.where("spring", place) == null, "a taken item is not in the world")
	_check(m.drop("spring", 2, Vector3(3.333, 0, 4.0), 45.0) and m.hand == "", "drop from the hand")
	var w = m.where("spring", place)
	_check(w is Dictionary and int(w.wing) == 2 and is_equal_approx(float(w.pos[0]), 3.33) and float(w.yaw) == 45.0, "a dropped item lies where it was dropped")
	_check(not m.drop("spring", 2, Vector3.ZERO, 0.0), "can't drop what isn't carried")
	m.take("pogs", false)
	m.add("pogs")
	_check(m.drop("pogs", 1, Vector3.ZERO, 0.0) and m.count("pogs") == 1, "drop one of two from the bag")

func _test_round_trip() -> void:
	var m = _fresh()
	m.take("folse_stick", true)
	m.take("pogs", false)
	m.add("pogs", 2)
	m.tickets = 125
	m.take("spring", true)
	m.drop("spring", 2, Vector3(1, 0, 2), 10.0)
	m.hold("folse_stick")
	var s: String = m.to_json()
	var d = JSON.parse_string(s)
	_check(d is Dictionary and int(d.v) == 1 and int(d.year) == 1995 and d.inventory is Array and d.has("tickets") and d.has("hand") and d.moved is Dictionary,
		"JSON shape: v, year, inventory, tickets, hand, moved")
	var n = _fresh()
	_check(n.from_json(s), "read back")
	_check(n.to_json() == s, "round trip is exact")
	_check(n.count("pogs") == 3 and n.tickets == 125 and n.hand == "folse_stick" and n.where("spring", null) is Dictionary and n.where("folse_stick", {"pos": [0, 0, 0]}) == null,
		"round trip keeps counts, tickets, hand and the world")
	# the field names the 2D game will join on
	_check(d.inventory[0].has("id") and d.inventory[0].has("count"), "inventory entries are {id, count}")

func _test_persist() -> void:
	var store := {}
	var a = Inventory.new()
	a.year = 1995
	a.backend = store
	a.take("pogs", false)
	a.tickets = 7
	a.save()
	_check(store.has("mall-state-1995"), "saved under mall-state-1995")
	var b = Inventory.new()
	b.year = 1995
	b.backend = store
	_check(b.load_saved() and b.count("pogs") == 1 and b.tickets == 7, "a new state loads what was saved (a wing load / reload)")
	var c = Inventory.new()
	c.year = 2026
	c.backend = store
	_check(not c.load_saved() and c.inventory.is_empty() and c.year == 2026, "each year keeps its own state")
	c.add("x")
	c.save()
	_check(store.has("mall-state-2026") and b.load_saved() and b.count("x") == 0, "saving 2026 leaves 1995 alone")

func _test_bad_input() -> void:
	var m = _fresh()
	m.add("keep")
	_check(not m.from_json("") and not m.from_json("{nope") and not m.from_json("[1,2]") and not m.from_json('{"v": 99}'), "junk, other shapes and other versions are refused")
	_check(m.count("keep") == 1, "a refused load changes nothing")
	_check(m.from_json('{"v":1,"inventory":[{"id":"a","count":2},{"id":"","count":1},{"id":"b","count":0},"x"],"tickets":-5}'), "a messy but valid state loads")
	_check(m.count("a") == 2 and m.inventory.size() == 1 and m.tickets == 0 and m.hand == "" and m.moved.is_empty(), "bad entries dropped, tickets floored at 0, defaults filled")

func _test_item_files() -> void:
	var db = ItemDB.new().load_dir()
	_check(db.order.size() >= 6, "items read from data/items/*.json: %d" % db.order.size())
	var bad := []
	for id in db.order:
		var e: Dictionary = db.get_item(id)
		if not ResourceLoader.exists(str(e.scene)):
			bad.append(id + " scene")
		if not ResourceLoader.exists(str(e.icon)):
			bad.append(id + " icon")
	_check(bad.is_empty(), "every item's scene and icon exist " + str(bad))
	_check(db.get_item("folse_stick").get("class") == "hand", "Martin Folse's stick is a hand item")
	_check(ItemDB.check({"id": "a", "name": "A", "class": "belt", "scene": "", "icon": "", "year": 1995}) != "", "a wrong class is refused")
	_check(ItemDB.check({"id": "a", "name": "A", "class": "pocket", "scene": "", "icon": "", "year": "both"}) == "", "year \"both\" is fine")
	_check(ItemDB.check({"id": "a", "name": "A", "class": "pocket", "scene": "", "icon": "", "year": 1995, "place": {"wing": 1}}) != "", "a place without pos is refused")
	_check(db.ids_for_year(2026).is_empty() or db.ids_for_year(2026).all(func(i): return ItemDB.in_year(db.get_item(i), 2026)), "ids_for_year filters by year")
