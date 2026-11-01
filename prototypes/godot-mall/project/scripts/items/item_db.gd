## Item definitions (workstream B+C; design/godot-interaction.md): every data/items/*.json, read
## once at start. A file is {"items": [entry, ...]} (or a bare array of entries). Entry:
##   {"id": "pogs", "name": "Pog pack", "class": "hand" | "pocket",
##    "scene": "res://scripts/items/pogs.tscn", "icon": "res://tex/items/pogs.png",
##    "year": 1995 | 2026 | "both", "tickets": 100,                       # tickets: optional
##    "place": {"wing": 2, "year": 1995, "pos": [x, y, z], "yaw": 90}}   # place: optional
## Later files win on a repeated id. Bad entries are skipped with a warning.
extends RefCounted

const DIR := "res://data/items/"

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
		if not items.has(e.id):
			order.append(e.id)
		items[e.id] = e

## "" when e is a usable entry, else why not.
static func check(e) -> String:
	if not (e is Dictionary):
		return "not an object"
	for k in ["id", "name", "class", "scene", "icon", "year"]:
		if not e.has(k):
			return "no " + k
	if not (str(e["class"]) in ["hand", "pocket"]):
		return "class must be hand or pocket"
	var y = e.year
	if not (str(y) == "both" or int(y) in [1995, 2026]):
		return "year must be 1995, 2026 or both"
	if e.has("place"):
		var p = e.place
		if not (p is Dictionary) or not (p.get("pos") is Array) or p.pos.size() < 3:
			return "place needs pos [x, y, z]"
	return ""

## The entry for id, or {}.
func get_item(id: String) -> Dictionary:
	return items.get(id, {})

## Whether an entry belongs to the year on show.
static func in_year(e: Dictionary, year: int) -> bool:
	return str(e.get("year", "")) == "both" or int(e.get("year", 0)) == year

func ids_for_year(year: int) -> Array:
	return order.filter(func(id): return in_year(items[id], year))
