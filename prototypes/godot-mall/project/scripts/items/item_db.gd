## THE item list (one schema, ws/items Nov 4 2026; design/godot-items.md): every data/items/*.json,
## one file per store (or place), read once at start. The one loader: everything that needs an item's
## name, class, icon or price asks this (ItemDb.shared() reads it once per run). A file is
## {"_": "...", "items": [entry, ...]} (or a bare array of entries). Entry:
##   {"id": "pogs", "name": "Pog pack",
##    "category": "toy", "subcategory": "pogs",      # CATEGORIES below; subcategory: free, lower case
##    "class": "hand" | "pocket",                     # hand = can be held (and bagged); pocket = bag only
##    "scene": "res://scripts/items/pogs.tscn", "icon": "res://tex/items/pogs.png",
##    "year": 1995 | 2026 | "both", "store": "POCKET CHANGE",              # store: optional
##    "tickets": 100, "prize": "pogs",    # optional: a redemption prize (catalogue key in scripts/prizes*.json)
##    "price": 299,                       # ECON: optional; what a store asks, in whole cents ($2.99)
##    "place": {"wing": 2, "year": 1995, "pos": [x, y, z], "yaw": 90},   # optional: lies in the world
##    "display": {...}}                   # optional: shown on a counter (built into the scene)
## Ids never change (saves, shops, quests and tests name them; tools/qa/items_test.gd).
## A repeated id is an error (skipped with a warning; the first file read keeps it). Bad entries are
## skipped with a warning.
extends RefCounted

const DIR := "res://data/items/"

## The categories (design/godot-items.md "Categories"): what the thing is, not where it came from (a
## prize is any item with "tickets"; a shop's stock is data/story/shops.json). Label = the bag's heading.
const CATEGORIES := {
	"food": "Food", "drink": "Drinks", "book": "Books", "toy": "Toys", "electronics": "Electronics",
	"home": "Lamps and lights", "clothing": "Things to wear", "stationery": "School supplies",
	"token": "Coupons and coins", "story": "Story",
}

static var _shared = null
## The item list, read once per run and shared by every system (inventory.gd, shop.gd, redemption.gd,
## the pop-up, interact.gd, cucos.gd, the tests). reload = read the files again.
static func shared(reload := false):
	if _shared == null or reload:
		_shared = load("res://scripts/items/item_db.gd").new().load_dir()
	return _shared

var dupes: Array = []  # ids found twice (an error: items_test.gd fails on it)

var items := {}        # id -> entry
var order: Array = []  # ids, in file order

## Read every *.json in dir. Returns self for chaining.
func load_dir(dir := DIR):
	var files: Array = []
	var da := DirAccess.open(dir)
	if da:
		for f in da.get_files():
			# in an export the listing can show "x.json.remap"-style names; take the json ones
			var name := f.trim_suffix(".remap")
			if name.ends_with(".json") and not files.has(name):
				files.append(name)
	files.sort()
	for f in files:
		load_file(dir + f)
	return self

func load_file(path: String) -> void:
	if not FileAccess.file_exists(path):
		return
	var j = JSON.parse_string(FileAccess.get_file_as_string(path))
	var list = j.get("items", []) if j is Dictionary else j
	if not (list is Array):
		push_warning("items: %s is not a list of items" % path)
		return
	for e in list:
		var why := check(e)
		if why != "":
			push_warning("items: %s: skipped %s (%s)" % [path, str(e.get("id", "?")) if e is Dictionary else "?", why])
			continue
		if items.has(e.id):
			dupes.append(str(e.id))
			push_warning("items: %s: id %s is already an item; skipped (ids are unique)" % [path, e.id])
			continue
		order.append(e.id)
		items[e.id] = e

## "" when e is a usable entry, else why not.
static func check(e) -> String:
	if not (e is Dictionary):
		return "not an object"
	for k in ["id", "name", "category", "subcategory", "class", "scene", "icon", "year"]:
		if not e.has(k):
			return "no " + k
	if not CATEGORIES.has(str(e.category)):
		return "category must be one of " + ", ".join(CATEGORIES.keys())
	if str(e.subcategory) == "" or str(e.subcategory) != str(e.subcategory).to_lower():
		return "subcategory must be a lower-case word"
	if not (str(e["class"]) in ["hand", "pocket"]):
		return "class must be hand or pocket"
	var y = e.year
	if not (str(y) == "both" or int(y) in [1995, 2026]):
		return "year must be 1995, 2026 or both"
	if e.has("price"):   # ECON: whole cents
		var pr = e.price
		if not (pr is float or pr is int) or float(pr) < 0.0 or float(pr) != floor(float(pr)):
			return "price must be whole cents, 0 or more"
	if e.has("place"):
		var p = e.place
		if not (p is Dictionary) or not (p.get("pos") is Array) or p.pos.size() < 3:
			return "place needs pos [x, y, z]"
	return ""

## The entry for id, or {}.
func get_item(id: String) -> Dictionary:
	return items.get(id, {})

## Can it be held? ("hand" class.) A holdable thing goes into the hand when received and can be put
## in the bag and held again; a "pocket" thing (too small or too big to carry in the hand) goes into
## the bag (design/godot-items.md "Hand by default").
static func holdable(e: Dictionary) -> bool:
	return str(e.get("class", "")) == "hand"

## The ids of one category, in file order.
func ids_in(category: String) -> Array:
	return order.filter(func(id): return str(items[id].get("category", "")) == category)

## The bag's heading for an entry's category ("" for none).
static func category_label(e: Dictionary) -> String:
	return str(CATEGORIES.get(str(e.get("category", "")), ""))

## Whether an entry belongs to the year on show.
static func in_year(e: Dictionary, year: int) -> bool:
	return str(e.get("year", "")) == "both" or int(e.get("year", 0)) == year

## ECON (design/godot-economy.md): what a store asks for the item, in whole cents; -1 when it has no
## "price" (not for sale). The buying code pairs it with mall.can_afford() / mall.spend().
static func price(e: Dictionary) -> int:
	return int(e.price) if e.has("price") and (e.price is float or e.price is int) and float(e.price) >= 0 else -1

func ids_for_year(year: int) -> Array:
	return order.filter(func(id): return in_year(items[id], year))
