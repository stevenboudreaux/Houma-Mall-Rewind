## The player's carried state, "mall" (workstream B+C, Nov 1 2026; design/godot-interaction.md).
## Pure data, no nodes: interact.gd owns one as player.mall, the inventory panel shows it, and
## tools/qa/inventory_test.gd checks it headless.
##
## Named so it can later be joined with the 2D game's state (index.html): the object is "mall",
## its fields mall.inventory and mall.tickets. Persisted per year in localStorage under
## "mall-state-<year>" (and mirrored to window.mall on the web), so it survives wing loads, year
## switches and reloads. The JSON shape (version 1):
##   {"v": 1, "year": 1995,
##    "inventory": [{"id": "pogs", "count": 1}, ...],   # carried, not in the hand; pickup order
##    "tickets": 0,                                      # the ticket balance (nothing earns any yet)
##    "hand": "folse_stick",                             # the item in the hand, "" for none
##    "moved": {"folse_stick": {},                        # {} = not in the world (carried)
##              "spring": {"wing": 2, "year": 1995, "pos": [x, y, z], "yaw": 30.0}}}  # dropped here
## Item ids are the "id"s of data/items/*.json. An item with no "moved" entry is at its
## data-file "place" (if it has one).
extends RefCounted

signal changed

const VERSION := 1

var year := 1995
var inventory: Array = []      # [{"id": String, "count": int}]
var tickets := 0
var hand := ""
var moved := {}
## ---- M (design/godot-menu.md): the player's name and the held item, read by other workstreams.
## mall.player_name: a plain String ("" until the player types one in the menu's AVATAR tab). One
## name for both years, so it is kept apart from the per-year state, in localStorage
## "mall.player_name" (Engine meta off the web; the backend Dictionary in unit tests), loaded by
## load_saved(). Setting it saves it and emits player_name_changed(name).
signal player_name_changed(name: String)
const NAME_KEY := "mall.player_name"
const NAME_MAX := 20
var player_name := "":
	set(v):
		v = clean_name(v)
		if v == player_name:
			return
		player_name = v
		_save_name()
		player_name_changed.emit(player_name)

## The item in the hand ("" when nothing is held). Session Q's dialogue reads it.
func held_id() -> String:
	return hand

## A name as typed, made safe: no control characters, trimmed, at most NAME_MAX characters.
static func clean_name(v) -> String:
	var out := ""
	for ch in str(v):
		if ch.unicode_at(0) >= 32 and ch.unicode_at(0) != 127:
			out += ch
	return out.strip_edges().left(NAME_MAX).strip_edges()

func _save_name() -> void:
	if backend is Dictionary:
		backend[NAME_KEY] = player_name
	elif OS.has_feature("web"):
		JavaScriptBridge.eval("(function(){try{localStorage.setItem(%s,%s)}catch(e){}try{window.mall=Object.assign(window.mall||{},{player_name:%s})}catch(e){}})()" % [JSON.stringify(NAME_KEY), JSON.stringify(player_name), JSON.stringify(player_name)], true)
	else:
		Engine.set_meta("mall_player_name", player_name)

func load_player_name() -> void:
	var s = ""
	if backend is Dictionary:
		s = str(backend.get(NAME_KEY, ""))
	elif OS.has_feature("web"):
		s = JavaScriptBridge.eval("(function(){try{return localStorage.getItem(%s)||''}catch(e){return ''}})()" % JSON.stringify(NAME_KEY), true)
	else:
		s = str(Engine.get_meta("mall_player_name", ""))
	player_name = s if s is String else ""
## ---- end M

## Where save()/load_saved() keep the JSON. null: localStorage on the web, else Engine metadata
## (survives a scene change in the editor or a test). A Dictionary: kept in it (unit tests).
var backend = null

# ------------------------------------------------------------------ counting
## How many of item id are carried (the hand counts as one).
func count(id: String) -> int:
	var n := 1 if hand == id else 0
	for e in inventory:
		if e.id == id:
			n += int(e.count)
	return n

## Carried in the inventory or the hand.
func has(id: String) -> bool:
	return count(id) > 0

## Put n of item id into the inventory (not the hand).
func add(id: String, n := 1) -> void:
	if id == "" or n <= 0:
		return
	for e in inventory:
		if e.id == id:
			e.count = int(e.count) + n
			changed.emit()
			return
	inventory.append({"id": id, "count": n})
	changed.emit()

## Take n of item id out of the inventory (not the hand). False, and nothing changes, when fewer
## than n are there.
func remove(id: String, n := 1) -> bool:
	for i in inventory.size():
		var e: Dictionary = inventory[i]
		if e.id == id:
			if int(e.count) < n:
				return false
			e.count = int(e.count) - n
			if int(e.count) <= 0:
				inventory.remove_at(i)
			changed.emit()
			return true
	return false

# ------------------------------------------------------------------ the hand
## Take id out of the inventory into the hand; whatever was in the hand goes into the inventory.
func hold(id: String) -> bool:
	if hand == id:
		return true
	if not remove(id):
		return false
	if hand != "":
		add(hand)
	hand = id
	changed.emit()
	return true

## The hand's item into the inventory.
func put_away() -> void:
	if hand == "":
		return
	var id := hand
	hand = ""
	add(id)

# ------------------------------------------------------------------ the world
## Picked up from the world: no longer there; into the hand when to_hand and the hand is empty
## (else into the inventory).
func take(id: String, to_hand: bool) -> void:
	moved[id] = {}
	if to_hand:
		if hand != "":
			add(hand)
		hand = id
		changed.emit()
	else:
		add(id)

## Dropped: out of the hand (or one out of the inventory) onto the floor at pos.
func drop(id: String, wing: int, pos: Vector3, yaw_deg: float) -> bool:
	if hand == id:
		hand = ""
	elif not remove(id):
		return false
	moved[id] = {"wing": wing, "year": year, "pos": [snappedf(pos.x, 0.01), snappedf(pos.y, 0.01), snappedf(pos.z, 0.01)], "yaw": snappedf(yaw_deg, 0.1)}
	changed.emit()
	return true

## Where item id lies in the world: its data "place" unless it has been moved; null when it is
## carried (or was never placed).
func where(id: String, place) -> Variant:
	if moved.has(id):
		var m: Dictionary = moved[id]
		return null if m.is_empty() else m
	return place

# ------------------------------------------------------------------ JSON
func to_dict() -> Dictionary:
	return {"v": VERSION, "year": year, "inventory": inventory.duplicate(true), "tickets": tickets,
		"hand": hand, "moved": moved.duplicate(true)}

func to_json() -> String:
	return JSON.stringify(to_dict())

## Read a saved state. False (and nothing changes) when it isn't one.
func from_dict(d) -> bool:
	if not (d is Dictionary) or int(d.get("v", 0)) != VERSION:
		return false
	var inv: Array = []
	for e in d.get("inventory", []):
		if e is Dictionary and str(e.get("id", "")) != "" and int(e.get("count", 0)) > 0:
			inv.append({"id": str(e.id), "count": int(e.count)})
	inventory = inv
	tickets = maxi(0, int(d.get("tickets", 0)))
	hand = str(d.get("hand", ""))
	# JSON numbers come back as floats: put the ints back, so a round trip is exact
	moved = {}
	var mv = d.get("moved", {})
	if mv is Dictionary:
		for id in mv:
			var m = mv[id]
			if not (m is Dictionary):
				continue
			if m.is_empty() or not (m.get("pos") is Array) or m.pos.size() < 3:
				moved[str(id)] = {}
				continue
			moved[str(id)] = {"wing": int(m.get("wing", 0)), "year": int(m.get("year", year)),
				"pos": [float(m.pos[0]), float(m.pos[1]), float(m.pos[2])], "yaw": float(m.get("yaw", 0.0))}
	if d.has("year"):
		year = int(d.year)
	changed.emit()
	return true

func from_json(s: String) -> bool:
	return from_dict(JSON.parse_string(s)) if s != "" else false

# ------------------------------------------------------------------ storage
func storage_key() -> String:
	return "mall-state-%d" % year

func save() -> void:
	var s := to_json()
	if backend is Dictionary:
		backend[storage_key()] = s
	elif OS.has_feature("web"):
		JavaScriptBridge.eval("(function(){try{localStorage.setItem(%s,%s)}catch(e){}try{var m=JSON.parse(%s);window.mall=Object.assign(window.mall||{},{inventory:m.inventory,tickets:m.tickets,hand:m.hand,year:m.year})}catch(e){}})()" % [JSON.stringify(storage_key()), JSON.stringify(s), JSON.stringify(s)], true)
	else:
		Engine.set_meta("mall_state_%d" % year, s)

## Load this year's saved state, if any. True when one was read.
func load_saved() -> bool:
	load_player_name()   # M: the name, kept apart from the per-year state
	var s := ""
	if backend is Dictionary:
		s = str(backend.get(storage_key(), ""))
	elif OS.has_feature("web"):
		var v = JavaScriptBridge.eval("(function(){try{return localStorage.getItem(%s)||''}catch(e){return ''}})()" % JSON.stringify(storage_key()), true)
		s = v if v is String else ""
	else:
		s = str(Engine.get_meta("mall_state_%d" % year, ""))
	var y := year
	var ok := from_json(s)
	year = y      # a state saved under this key is this year's
	return ok
