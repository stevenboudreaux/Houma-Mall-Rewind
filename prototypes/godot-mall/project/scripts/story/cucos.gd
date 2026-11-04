## Workstream CUCOS (Nov 3 2026; design/godot-cucos.md): the football lady, the coupon and the
## Cuco's bar. Made by scripts/dialogue/story.gd as its child "Cucos", every wing and year. Reads
## data/story/cucos/cucos.json:
##  - every year: "travels", the items that stay with the player across years (the doubloon);
##  - 1995, any wing with shoppers: the football lady (scripts/story/football_lady.gd);
##  - 1995, wing 1: the bartender (scripts/story/bartender.gd) and the two patrons on their stools
##    with their drinks (runtime nodes: nothing here is baked).
## Steven writes the story; the patrons, the bartender's name and skin are PLACEHOLDERs.
extends Node

const CFG := "res://data/story/cucos/cucos.json"
const Lady = preload("res://scripts/story/football_lady.gd")
const Bartender = preload("res://scripts/story/bartender.gd")

var player: Node3D
var story: Node
var cfg := {}
var lady: Node3D
var bartender: Node3D
var patrons: Array = []      # NpcBody
var drinks: Array = []       # Node3D

func _ready() -> void:
	if FileAccess.file_exists(CFG):
		var j = JSON.parse_string(FileAccess.get_file_as_string(CFG))
		if j is Dictionary:
			cfg = j
	if cfg.is_empty() or player == null:
		return
	travel()
	if not story.in_year(cfg.get("years", [1995]), int(player.year)):
		return
	_spawn.call_deferred()

## The items that travel: one into this year's bag when its flag says it was received and this year
## has none (carried, in the hand or lying on this year's floor). Returns how many were added.
func travel() -> int:
	var m = player.mall if player else null
	if m == null or not ("flags" in m) or m.flags == null:
		return 0
	var n := 0
	var tv = cfg.get("travels", {})
	if not (tv is Dictionary):
		return 0
	for id in tv:
		if not m.flags.has(str(tv[id])):
			continue
		if m.has(str(id)) or m.where(str(id), null) != null:
			continue
		m.add(str(id), 1, true)     # quiet: no "You received" card, it was received in 1995
		n += 1
	if n > 0:
		m.save()
	return n

func _spawn() -> void:
	await get_tree().process_frame       # after the shoppers and the attendants (story.gd)
	await get_tree().process_frame
	var crowd = player.get_parent().get_node_or_null("Shoppers")
	# the lady: wherever she walks (any wing whose crowd has her skin)
	var le: Dictionary = cfg.get("lady", {})
	if not le.is_empty():
		lady = Lady.new()
		add_child(lady)
		lady.setup(player, story, le)
		_owner_debug()
	# the bar: wing 1 only
	var be: Dictionary = cfg.get("bartender", {})
	if be.is_empty() or (int(be.get("wing", 1)) != int(player.wing) and int(player.wing) != 0):
		return
	if not story.in_year(be.get("years", [1995]), int(player.year)):
		return
	_reserve(crowd, str(be.get("skin", "")))
	bartender = Bartender.new()
	add_child(bartender)
	if not bartender.setup(player, story, be):
		bartender.queue_free()
		bartender = null
	else:
		story.attendants.append(bartender)
	for pe in cfg.get("patrons", []):
		_patron(crowd, pe)

## Keep a skin out of the crowd: mark it in use, and take a shopper already wearing it away.
func _reserve(crowd, skin: String) -> void:
	if crowd == null or skin == "":
		return
	if "in_use" in crowd:
		crowd.in_use[skin] = true
	if "shoppers" in crowd and crowd.has_method("_remove"):
		for x in crowd.shoppers.duplicate():
			if x.body and str(x.body.get("id")) == skin and x.role == "":
				crowd._remove(x)
				crowd.in_use[skin] = true

## A patron on a bar stool with a drink in front of them on the counter. No dialogue.
func _patron(crowd, pe: Dictionary) -> void:
	var skin := {}
	for e in NpcBody.manifest().get("skins", []):
		if str(e.id) == str(pe.get("skin", "")):
			skin = e
	if skin.is_empty() or not ResourceLoader.exists(str(skin.get("scn", ""))):
		push_warning("cucos: patron skin %s not in this pack" % pe.get("skin"))
		return
	_reserve(crowd, str(skin.id))
	var b := NpcBody.new()
	b.name = str(pe.get("id", "patron"))
	b.top_level = true
	add_child(b)
	b.set_skin(skin)
	var st: Array = pe.get("seat", [0, 0])
	b.global_position = Vector3(float(st[0]), float(pe.get("y", 0.36)), float(st[1]))
	var f: Array = pe.get("face", [-1, 0])
	b.face(Vector3(float(f[0]), 0, float(f[1])))
	b.play(str(pe.get("clip", "sit")) if NpcBody.has_clip(str(pe.get("clip", "sit"))) else "sit")
	patrons.append(b)
	# the drink on the counter in front of them (the stand-in item scene: FOOD's cu_* replace it)
	var scn := "res://scripts/items/cucos/cu_%s.tscn" % str(pe.get("drink", "beer"))
	var it = player.interact
	if it and it.get("db"):
		var di: Dictionary = it.db.get_item("cu_" + str(pe.get("drink", "beer")))
		if di.has("scene"):
			scn = str(di.scene)
	if ResourceLoader.exists(scn):
		var d: Node3D = load(scn).instantiate()
		d.name = b.name + "_drink"
		d.top_level = true
		add_child(d)
		d.global_position = Vector3(float(cfg.get("drinks_x", 23.42)), float(cfg.get("drinks_y", 1.1)), float(st[1]) + 0.1)
		drinks.append(d)

# ------------------------------------------------------------------ the owner's debug helper
var _js_cb      # keeps the JavaScript callback alive
## Owner mode on the web only (as mallFlags, design/godot-quests.md): `mallLady()` in the browser
## console puts the player next to the football lady, facing her, and returns where she is
## ("" when she isn't in this wing's crowd). Used by tools/qa/cucos_webtest.py.
func _owner_debug() -> void:
	if not OS.has_feature("web") or not (player.has_method("is_owner") and player.is_owner()):
		return
	_js_cb = JavaScriptBridge.create_callback(func(_args): return to_lady())
	var w = JavaScriptBridge.get_interface("window")
	w.mallLady = _js_cb

## Put the player ~1.1 m from the lady on open floor, facing her. Returns "x,z" of her, or "".
func to_lady() -> String:
	var s = lady.find() if lady else null
	if s == null:
		return ""
	var crowd = lady.crowd
	for k in 16:
		var a := TAU * k / 16.0
		var dir := Vector3(sin(a), 0, cos(a))
		var p: Vector3 = s.pos + dir * 1.1
		if crowd.has_method("_open") and not (crowd._open(p) and crowd._open(s.pos + dir * 0.55)):
			continue
		player.position = Vector3(p.x, player.position.y, p.z)
		player.yaw = atan2(dir.x, dir.z)
		player.pitch = deg_to_rad(-4.0)
		player._apply_rot()
		return "%.2f,%.2f" % [s.pos.x, s.pos.z]
	return ""
