## The shoppers: the mall's crowd (Steven, Oct 15 2026: "an engine for NPCs where they walk through
## the mall on the sides, not in the middle of the walkways, and go into stores"; Oct 16: "use as
## many of these animations as possible to make truly unique interactions of NPCs").
##
## One node under the wing, made by player.gd, that owns every NPC (a small Shopper record plus
## a NpcBody). There are no physics bodies: NPCs walk the same 2 m walk grid as the player and
## the Rougarou, split into 1 m cells with the wing's columns, benches and planters closed off.
##
## Lanes. A distance-to-wall field over the cells gives every cell a path cost: cheapest 1.5–4 m
## from a wall, dearer toward the middle of a hall, dear right against a wall. AStarGrid2D (C++)
## finds routes with those costs, so people keep to the sides on their own, and a keep-right
## nudge while following the route makes the two directions pass each other like real mall
## traffic.
##
## Who is who (scripts/npcs.json): one of each Mixamo character per wing ("unique"), each with a
## sex-matched walk and idle. Shopper types: browser (windows), shopper (stores), heavy shopper
## (long store visits, shopping-bag walk), confused (looks around nervously, shakes their head),
## each with their own browsing loops and gestures. Special roles: the drunk (drunk walk and
## sways, hall only), pairs who meet to talk (on a bench: stand-to-sit, sitting and talking,
## sit-to-stand; or standing: talking, arguing, nodding), and the Pocket Change players (the
## "play" loop from Texting While Standing, hands on the stick and buttons, eyes on the screen,
## a cheer or a groan now and then). Goals: a store with an open interior, a closed store's
## window, a far hall point, then the next. Spawning happens out of the player's sight; NPCs
## never block the player; they step aside and slow for the player and for each other.
## Regis (Oct 16 2026, Steven: "too many people congregating at Regis ... only have one woman at a
## time and make her sit in one of those chairs ... don't put a stylist with them"): Regis is no
## longer a store or window goal for the crowd; instead one woman at a time walks in, sits in a
## random styling chair for a few minutes (stand-to-sit, a sitting loop, sit-to-stand) and walks
## back out into the crowd; a while later another comes ("salons" in npcs.json).
## MasterCuts (Oct 20 2026, Steven: "make the logic of regis apply to mastercuts. only 1-2 women in
## chair at a time, no other congregating here"; "don't have any NPCs congregate inside KaramelKorn
## either"): the same salon logic with two slots, and "no_browse" keeps the crowd out of Regis,
## MasterCuts and Karmelkorn (no store or window goals there).
## URL: ?npcs=0 turns them off, ?npcs=40 sets the count (tests, screenshots).
extends Node

const CFG := "res://scripts/npcs.json"
const LAYOUT := "res://layout_mall.json"
const PANELS := "res://scripts/arcade_panels.json"
var cfg := {
	"count": 17, "hours": {"6": 0.0, "8": 0.2, "10": 0.6, "12": 1.0, "17": 1.0, "19": 0.7, "20": 0.4, "21": 0.15, "22": 0.0},
	"speed_mps": [1.0, 1.45], "lane_m": [1.5, 4.0], "centre_penalty": 0.5, "wall_hug_penalty": 1.6,
	"keep_right_m": 0.5, "separation_m": 1.3, "player_m": 1.8, "goals": {"store": 0.5, "window": 0.25, "hall": 0.25},
	"shop_s": [20.0, 60.0], "window_s": [5.0, 15.0], "pause_s": [1.0, 4.0], "store_max_m": 70.0,
	"spawn_min_m": 22.0, "see_m": 70.0, "see_cone_deg": 70.0, "recycle_unseen_s": 8.0, "recycle_m": 55.0,
	"lod_anim_m": 45.0, "groups": {"mixamo": 1.0}, "exclude": [], "retire_after_goals": [4, 9],
	"self_light_day": 0.0, "self_light_night": 0.3, "mannequins": false, "mannequin_skins": ["Ch36"], "mannequin_pose": ["idle", 0.4],
	"outside": false,   # EXT-LOT: shoppers outside (wing 3); off "at this time" (Steven, Nov 9 2026)
	"unique": true, "skin_sex": {}, "walks": {"m": ["walk_m"], "f": ["walk_f"]}, "idles": {"m": ["idle"], "f": ["idle"]},
	"hall_pause": {"phone": 0.2}, "types": {},
	"drunk": {}, "pairs": [], "pair_talk_s": [50.0, 120.0], "pair_apart_s": [60.0, 150.0], "pair_gestures": [],
	"arcade_ids": [], "arcade_fill": 0.5, "arcade_mods": ["video"], "arcade_max": 5, "arcade_back_m": 0.22,
	"arcade_yield_m": 0.9, "arcade_bases": ["play"], "arcade_react_s": [10.0, 28.0], "arcade_reacts": ["cheer"],
}
var players := []             # arcade: {body, pos, face, x, L, R, screen, t, react, aside}
var mannequins := []          # frozen bodies in the windows (off since Oct 16 2026)
var pairs := []               # {kind, ids, m: [Shopper, Shopper], state, timer, spots}
var light_mode := ""
var player: Node3D
var force := ""              # ?npcs=
var rows: PackedStringArray
var map_scale := 2.0
var map_origin := Vector2(148, 100)
var cell := 1.0
var W := 0
var H := 0
var oc := Vector2.ZERO        # cell offset of world origin
var open := PackedByteArray()
var wdist := PackedInt32Array()
var grid: AStarGrid2D
var skins := []               # the crowd pool
var all_skins := {}           # id -> manifest entry
var weights := []             # cumulative
var in_use := {}              # unique mode: skin id -> true while someone wears it
var reserved := {}            # ids kept for the drunk, the pairs and the arcade
var stores := []              # {door, n, spots, name}
var windows := []             # {door, n, spot, name}
var benches := []             # {pos, face, shown}
var hall_cells := []          # open cells 2+ m from walls (Vector2i)
var salons := []             # salon slots: {on, c (its cfg), door, s (Shopper), chair, timer, sitting, clip}
var shoppers := []
var rt = null
var want := 0
var tick := 0.0
var rng := RandomNumberGenerator.new()
var disabled := false
## ---- M (design/godot-menu.md): NPC density by year, npcs.json "years":
##   {"1995": {}, "2026": {"count": 3, "ids": [], "roles": false, "layout": "res://layout_2026.json"}}
## count: how many in the crowd; ids: which characters (empty = the first `count` of the crowd pool,
## in npc/skins.json order); roles false: no drunk, pairs, arcade players or salon visitors; layout: the
## year's store doors. A year not listed keeps the defaults (1995: today's numbers).
var layout_path := LAYOUT
var year_ids: Array = []      # only these characters (empty: anyone in the pool)
var year_roles := true

func _year_cfg() -> void:
	var y := str(int(player.year)) if player and "year" in player else "1995"
	var yc = cfg.get("years", {}).get(y, {}) if cfg.get("years", {}) is Dictionary else {}
	if not (yc is Dictionary) or yc.is_empty():
		return
	if yc.has("count"): cfg.count = int(yc.count)
	if yc.has("layout") and FileAccess.file_exists(str(yc.layout)): layout_path = str(yc.layout)
	year_roles = bool(yc.get("roles", true))
	var ids = yc.get("ids", [])
	if ids is Array and not ids.is_empty():
		for i in ids: year_ids.append(str(i))
	elif yc.has("count"):
		# the first `count` of the crowd pool (npc/skins.json order, groups with weight, minus exclude)
		for e in NpcBody.manifest().get("skins", []):
			if year_ids.size() >= int(cfg.count): break
			if str(e.id) in cfg.exclude or float(cfg.groups.get(str(e.group), 0.0)) <= 0.0: continue
			if ResourceLoader.exists(str(e.get("scn", ""))): year_ids.append(str(e.id))
	# warm up only those (scripts/npc_warmup.gd)
	var only: Array[String] = []
	for e in NpcBody.manifest().get("skins", []):
		if str(e.id) in year_ids: only.append(str(e.get("scn", "")))
	load("res://scripts/npc_warmup.gd").only = only
## ---- end M
var spawn_all_now := false   # tests: fill the mall at once, in sight too

class Shopper:
	var body: NpcBody
	var pos := Vector3.ZERO
	var path := PackedVector3Array()
	var pi := 0
	var state := "dwell"
	var timer := 1.0
	var speed := 1.2
	var goal := {}          # type, spots, i, face
	var unseen := 0.0
	var stuck := 0.0
	var goals := 0
	var retire := 6
	var type := {}          # one of cfg.types (or the drunk's)
	var type_name := ""
	var sex := "m"
	var role := ""          # "", "drunk", "pair", "salon"
	var sal = null          # the salon slot Dictionary
	var pair = null         # the pair Dictionary
	var slot := 0           # 0 / 1 in the pair
	var gest_t := 5.0       # seconds to the next gesture while dwelling

func _ready() -> void:
	var t_ready := Time.get_ticks_msec()   # workstream H: load-time breakdown (design/godot-performance.md)
	rng.randomize()
	if FileAccess.file_exists(CFG):
		var j = JSON.parse_string(FileAccess.get_file_as_string(CFG))
		if j is Dictionary:
			for k in j: cfg[k] = j[k]
	_year_cfg()   # M
	# ---- EXT-LOT (Nov 9 2026, Steven: no NPCs outside the mall "at this time"): a flag, not a deletion. Outside
	# (wing 3, both years) the crowd stays off unless npcs.json sets "outside": true. ?npcs=N does not override it.
	if int(player.wing) == 3 and not bool(cfg.get("outside", false)):
		disabled = true
		print("npcs: off outside (npcs.json \"outside\": false)")
		load("res://scripts/npc_warmup.gd").ready_now()
		return
	# ---- end EXT-LOT
	if force == "0":
		disabled = true
		load("res://scripts/npc_warmup.gd").ready_now()   # workstream H: no warm-up, lift the card
		return
	if force.is_valid_int():
		cfg.count = int(force)
	var dt: Array = cfg.get("day_tint", [1, 1, 1])
	NpcBody.tint = Color(float(dt[0]), float(dt[1]), float(dt[2]))
	rows = player.walk_rows
	map_scale = player.map_scale
	map_origin = player.map_origin
	# ---- workstream H (Nov 1 2026): packs without shopper skins (the outside, the 2026 wings)
	# skip the path grid; it cost seconds of load for nobody (design/godot-performance.md). The
	# runner only asks this node for the grid when it has a body, which needs the same skins.
	if load("res://scripts/npc_warmup.gd").skin_paths().is_empty():
		disabled = true
		print("npcs: grid 0x0, no shopper skins in this pack")
		load("res://scripts/npc_warmup.gd").ready_now()
		return
	# ---- end workstream H
	_build_grid()
	_load_places()
	_load_benches()
	print("load: npcs grid+places %d ms" % (Time.get_ticks_msec() - t_ready))   # workstream H
	# ---- workstream H (Nov 1 2026): warm every skin up behind the loading card before the first
	# spawn, so no shopper's first appearance stalls a frame (scripts/npc_warmup.gd,
	# design/godot-performance.md). Web only; ?warm=0 skips it.
	var warm := OS.has_feature("web") and str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('warm') || ''")) != "0"
	if warm:
		set_process(false)
		var wu = load("res://scripts/npc_warmup.gd").new()
		var lj = JSON.parse_string(FileAccess.get_file_as_string("res://scripts/lighting.json"))
		var day_only: bool = lj is Dictionary and bool(lj.get("day_only", false))
		wu.self_light_on = float(cfg.self_light_day if day_only else cfg.self_light_night)
		wu.self_light_now = float(cfg.self_light_day)
		add_child(wu)
		await wu.finished
		wu.queue_free()
	else:
		load("res://scripts/npc_warmup.gd").ready_now()
	# ---- end workstream H
	rt = get_tree().current_scene.get_node_or_null("Runtime")
	var machines := _arcade_machines()
	_load_skins(not machines.is_empty())
	_place_mannequins()
	if year_roles:   # M: per-year roles (npcs.json "years")
		_place_players(machines)
		_spawn_drunk()
		_spawn_pairs()
	print("load: npcs roles spawned %d ms after _ready" % (Time.get_ticks_msec() - t_ready))   # workstream H
	# ---- workstream H: the first crowd too, while the card is still up, then lift it
	if warm:
		_balance()
		load("res://scripts/npc_warmup.gd").ready_now()
	# ---- end workstream H
	print("npcs: grid %dx%d, %d open cells, %d stores, %d windows, %d benches, %d crowd skins, %d pairs" % [W, H, _count_open(), stores.size(), windows.size(), benches.size(), skins.size(), pairs.size()])
	set_process(true)

# ------------------------------------------------------------------ SEAMLESS: one crowd for every wing that is in
## SEAMLESS (Nov 13 2026, scripts/wing_stream.gd _remake; design/godot-wings.md "Seamless streaming"): the
## crowd is one node for the whole run. When the player's systems are remade (a wing came in or went, or
## the player walked into another wing) the streamer hands this node the new Player, the floor the
## crowd may walk (the union of the wings that are in) and those wings' gen folders. Nobody is
## respawned: the grid and the places are rebuilt only when the floor changed, a shopper left standing
## on floor that is gone is taken out, and Pocket Change gets its players the first time its wing is in.
var _gens: Array = []
func rebind(p: Node3D, floor_rows: PackedStringArray, gens: Array) -> void:
	player = p
	_gens = gens
	rt = get_tree().current_scene.get_node_or_null("Runtime") if get_tree().current_scene else null
	if disabled:
		return
	if floor_rows != rows and floor_rows.size() > 0:
		rows = floor_rows
		hall_cells.clear()
		_build_grid()
		stores.clear(); windows.clear(); benches.clear()
		_load_places()
		_load_benches()
		for s in shoppers.duplicate():
			if not _open(s.pos):
				if s.role == "":
					_remove(s)
			elif s.role == "" and s.state != "dwell":
				_decide(s)
	if players.is_empty() and year_roles:
		var machines := _arcade_machines()
		if not machines.is_empty():
			# its characters are the arcade's now: out of the crowd pool, and off anyone walking as one
			if bool(cfg.get("unique", false)):
				for i in cfg.get("arcade_ids", []):
					reserved[str(i)] = true
				for s in shoppers.duplicate():
					if s.role == "" and reserved.has(str(s.body.id)):
						_remove(s)
				var kept := []; var total := 0.0
				weights.clear()
				for e in skins:
					if reserved.has(str(e.id)): continue
					kept.append(e); total += float(cfg.groups.get(str(e.group), 0.0)); weights.append(total)
				skins = kept
			_place_players(machines)
# ---- end SEAMLESS

# ------------------------------------------------------------------ the grid
## 1 m cells from the wing's 2 m walk tiles, with the columns and fixtures closed off, a
## distance-to-wall field, and an AStarGrid2D whose costs make the sides of a hall the cheap way.
func _build_grid() -> void:
	cell = map_scale * 0.5
	W = rows[0].length() * 2 if rows.size() > 0 else 0
	H = rows.size() * 2
	oc = map_origin * 2.0
	open.resize(W * H); open.fill(0)
	var obs: Array = player.obstacles + player.fx_obstacles
	# ---- workstream H (Nov 1 2026): the same cells as before, 6-12x faster (design/godot-performance.md).
	# Was: every walkable cell tested against every obstacle (~2.5M tests in Wing 1, 0.5 s native,
	# seconds on a phone). Now each obstacle tests only the cells inside its bounding box (+1 cell),
	# with the identical test, so the result cannot differ.
	for cy in range(H):
		var r: String = rows[cy / 2]
		for cx in range(W):
			if r[cx / 2] == "1": open[cy * W + cx] = 1
	var inv := 1.0 / cell
	for o in obs:
		var x0: float; var x1: float; var z0: float; var z1: float
		var circle := false
		if o.size() == 3 and not (o[0] is String):
			var rr := float(o[2]) + 0.45
			x0 = o[0] - rr; x1 = o[0] + rr; z0 = o[1] - rr; z1 = o[1] + rr; circle = true
		elif o[0] == "rect":
			x0 = o[1] - 0.4; x1 = o[3] + 0.4; z0 = o[2] - 0.4; z1 = o[4] + 0.4
		else:
			continue
		# centre x = (cx + 0.5 - oc.x) * cell  =>  cx = x / cell + oc.x - 0.5
		var ca := maxi(0, int(floor(x0 * inv + oc.x - 0.5)) - 1); var cb := mini(W - 1, int(ceil(x1 * inv + oc.x - 0.5)) + 1)
		var ra := maxi(0, int(floor(z0 * inv + oc.y - 0.5)) - 1); var rb := mini(H - 1, int(ceil(z1 * inv + oc.y - 0.5)) + 1)
		for cy in range(ra, rb + 1):
			for cx in range(ca, cb + 1):
				var i := cy * W + cx
				if open[i] == 0: continue
				var c := _centre(Vector2i(cx, cy))
				if circle:
					if Vector2(c.x - o[0], c.z - o[1]).length() < float(o[2]) + 0.45: open[i] = 0
				elif c.x > o[1] - 0.4 and c.x < o[3] + 0.4 and c.z > o[2] - 0.4 and c.z < o[4] + 0.4:
					open[i] = 0
	# distance to the nearest closed cell (4-neighbour BFS). Seeded from the closed cells that touch
	# an open one (was: from every closed cell): every path from a closed cell into the open passes
	# such a cell, so the distances are the same, and the queue is ~30x shorter.
	wdist.resize(W * H); wdist.fill(-1)
	var q := PackedInt32Array(); var qi := 0
	for i in range(W * H):
		if open[i] == 0:
			wdist[i] = 0
			var x := i % W; var y := i / W
			if (x > 0 and open[i - 1] == 1) or (x < W - 1 and open[i + 1] == 1) or (y > 0 and open[i - W] == 1) or (y < H - 1 and open[i + W] == 1):
				q.append(i)
	# ---- end workstream H
	while qi < q.size():
		var i := q[qi]; qi += 1
		var x := i % W; var y := i / W
		for nb: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var ux: int = x + nb.x; var uy: int = y + nb.y
			if ux < 0 or uy < 0 or ux >= W or uy >= H: continue
			var u: int = uy * W + ux
			if wdist[u] < 0: wdist[u] = wdist[i] + 1; q.append(u)
	grid = AStarGrid2D.new()
	grid.region = Rect2i(0, 0, W, H)
	grid.cell_size = Vector2(1, 1)
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	grid.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	grid.jumping_enabled = false
	grid.update()
	var lane: Array = cfg.lane_m
	var lo := int(round(float(lane[0]) / cell)); var hi := int(round(float(lane[1]) / cell))
	for cy in range(H):
		for cx in range(W):
			var i := cy * W + cx
			var p := Vector2i(cx, cy)
			if open[i] == 0:
				grid.set_point_solid(p, true); continue
			var d := wdist[i]
			var w := 1.0
			if d < lo: w = float(cfg.wall_hug_penalty)
			elif d > hi: w = minf(1.0 + float(cfg.centre_penalty) * float(d - hi), 4.0)
			grid.set_point_weight_scale(p, w)
			if d >= lo: hall_cells.append(p)

func _count_open() -> int:
	var n := 0
	for i in range(open.size()): n += open[i]
	return n

func _cell(p: Vector3) -> Vector2i:
	return Vector2i(int(floor(p.x / cell + oc.x)), int(floor(p.z / cell + oc.y)))

func _centre(c: Vector2i) -> Vector3:
	return Vector3((c.x + 0.5 - oc.x) * cell, 0.0, (c.y + 0.5 - oc.y) * cell)

func _open(p: Vector3) -> bool:
	var c := _cell(p)
	if c.x < 0 or c.y < 0 or c.x >= W or c.y >= H: return false
	return open[c.y * W + c.x] == 1

func _open_c(c: Vector2i) -> bool:
	if c.x < 0 or c.y < 0 or c.x >= W or c.y >= H: return false
	return open[c.y * W + c.x] == 1

## Straight line over open cells (the Rougarou's test, on the finer grid).
func _los(a: Vector3, b: Vector3) -> bool:
	var d := Vector2(b.x - a.x, b.z - a.z)
	var n := int(ceil(d.length() / 0.8))
	for i in range(1, n):
		var p: Vector2 = Vector2(a.x, a.z) + d * (float(i) / n)
		if not _open(Vector3(p.x, 0, p.y)): return false
	return true

# ------------------------------------------------------------------ skins and places
## The crowd pool: manifest skins whose group has weight, minus exclusions and the reserved roles
## (the drunk, the pairs, and the arcade players when this wing has Pocket Change).
func _load_skins(arcade_here: bool) -> void:
	var m := NpcBody.manifest()
	if bool(cfg.get("unique", false)):
		var d: Dictionary = cfg.get("drunk", {})
		if d.has("id"): reserved[str(d.id)] = true
		for p in cfg.get("pairs", []):
			for i in p.ids: reserved[str(i)] = true
		if arcade_here:
			for i in cfg.get("arcade_ids", []): reserved[str(i)] = true
	var total := 0.0
	for e in m.get("skins", []):
		all_skins[str(e.id)] = e
		if str(e.id) in cfg.exclude or reserved.has(str(e.id)): continue
		if not year_ids.is_empty() and not (str(e.id) in year_ids): continue   # M
		var w := float(cfg.groups.get(str(e.group), 0.0))
		if w <= 0.0: continue
		skins.append(e); total += w; weights.append(total)

func _pick_skin() -> Dictionary:
	if bool(cfg.get("unique", false)):
		# one of each character (Steven, Oct 16 2026: "just 1 of each character for now")
		var free := []
		for e in skins:
			if not in_use.has(str(e.id)): free.append(e)
		if free.is_empty(): return {}
		var e: Dictionary = free[rng.randi() % free.size()]
		# CUCOS (design/godot-cucos.md): "always" skins (the football lady) come first, so she is
		# always somewhere in the mall in the years whose crowd has her
		for f in free:
			if str(f.id) in cfg.get("always", []): e = f; break
		in_use[str(e.id)] = true
		return e
	if weights.is_empty(): return {}
	var r: float = rng.randf() * float(weights[weights.size() - 1])
	for i in range(weights.size()):
		if r <= weights[i]: return skins[i]
	return skins[skins.size() - 1]

func _sex(id: String) -> String:
	return str(cfg.skin_sex.get(id, "m"))

func _pick(list: Array, fallback := "idle") -> String:
	var ok := []
	for c in list:
		if NpcBody.has_clip(str(c)): ok.append(str(c))
	return ok[rng.randi() % ok.size()] if not ok.is_empty() else fallback

## A body for a skin, dressed with its sex's walk and idle and a gesture hook.
func _make_body(e: Dictionary, s: Shopper = null) -> NpcBody:
	# the crowd stays Mixamo (CHAR-STRIP, Nov 8 2026: B2's per-shopper presets went with the editor)
	var b := NpcBody.new()
	b.set_skin(e)
	add_child(b)
	var sx := _sex(str(e.id))
	b.walk_clip = _pick(cfg.walks.get(sx, ["walk_m"]), "walk_m")
	b.play(_pick(cfg.idles.get(sx, ["idle"])))
	if s:
		s.sex = sx
		b.gesture_done.connect(func(n: String): _on_gesture_done(s, n))
	return b

## Store doors from the layout: a store is "open" when cells inside its door are walkable in this
## wing (the 3D interiors of design/godot-wings.md); otherwise its window is a place to stop.
func _load_places() -> void:
	if not FileAccess.file_exists(layout_path): return   # M: layout_path (the year's layout)
	var lay = JSON.parse_string(FileAccess.get_file_as_string(layout_path))
	if not (lay is Dictionary): return
	var names: Dictionary = lay.get("stores", {})
	for e in lay.get("edges", []):
		if e.get("kind", "") != "store": continue
		var a: Array = e.a; var b: Array = e.b; var nn: Array = e.n
		var door := Vector3((float(a[0]) + float(b[0])) * 0.5, 0, (float(a[1]) + float(b[1])) * 0.5)
		var n := Vector3(float(nn[0]), 0, float(nn[1]))     # points into the hall
		if not _open(door + n * 1.2): continue              # not in this wing (or walled)
		var sid := str(e.get("store", ""))
		var name := str(names.get(sid, {}).get("name", sid))
		for sc in (cfg.get("salons", []) if year_roles else []):   # M: per-year roles
			if name == str(sc.get("store", "")) and not _has_salon(name):
				for k in int(sc.get("slots", 1)):
					salons.append({"on": true, "c": sc, "door": door, "s": null, "chair": -1, "timer": rng.randf_range(4.0, 12.0) + k * rng.randf_range(20.0, 60.0), "sitting": false, "clip": ""})
		if name in cfg.get("no_browse", []): continue
		var spots := []
		var depth := float(e.get("depth", 6.0))
		for d in [2.5, 4.5, 7.0, 9.5]:
			if d > depth - 1.0: break
			var p: Vector3 = door - n * d
			if _open(p): spots.append(p)
			elif spots.size() > 0: break
		if spots.size() >= 1:
			stores.append({"door": door, "n": n, "spots": spots, "name": name})
		else:
			windows.append({"door": door, "n": n, "spot": door + n * 1.3, "name": name})

## Benches from the wing's fixture obstacles (radius 0.85 m, tools/build_mall.gd bench()). A hall
## bench faces the planter it is paired across; the shoe court's benches sit back to its palm bed.
## The hall benches are only drawn when "Benches & plants" is on; the court's always are.
func _load_benches() -> void:
	var fx: Array = player.fx_obstacles
	var court := Vector2(1.0, -2.0)       # the shoe court C2 (layout_mall.json), palm bed in the middle
	for o in fx:
		if o.size() != 3 or o[0] is String or absf(float(o[2]) - 0.85) > 0.01: continue
		var p := Vector2(float(o[0]), float(o[1]))
		var f := Vector2.ZERO
		# the court's benches are drawn by wing 1 only (zone C2); wing 2 lists them but has no court props
		var in_court := p.distance_to(court) < 3.0 and (str(get_tree().current_scene.get_meta("gen", "res://gen/w1/")).contains("/w1/") or _gens.any(func(g): return str(g).contains("/w1/")))   # SEAMLESS: wing 1 is in
		if in_court:
			f = Vector2(signf(p.x - court.x), 0.0)
		else:
			var best := 9.0
			for q in fx:
				if q.size() != 3 or q[0] is String or absf(float(q[2]) - 0.6) > 0.01: continue
				var d := p.distance_to(Vector2(float(q[0]), float(q[1])))
				if d < best: best = d; f = (Vector2(float(q[0]), float(q[1])) - p).normalized()
		if f == Vector2.ZERO: continue
		benches.append({"pos": Vector3(p.x, 0, p.y), "face": Vector3(f.x, 0, f.y), "court": in_court})

func _bench_shown(_b: Dictionary) -> bool:
	# every bench (the court's too) is in the fixtures mesh, off unless "Benches & plants" is on
	return bool(player.get("fixtures_on"))

# ------------------------------------------------------------------ the crowd
func _process(dt: float) -> void:
	if disabled or player == null: return
	tick += dt
	if tick > 1.0:
		tick = 0.0
		_balance()
		_light_check()
		_pairs_tick()
		for sl in salons:
			_salon_tick(sl)
	for s in shoppers:
		_step(s, dt)
	for p in players:
		_step_player(p, dt)

## Day or night changed: every body's own light follows (see NpcBody.set_self_light).
func _light_check() -> void:
	var m := "night"
	if rt and "mode" in rt: m = str(rt.mode)
	if m == light_mode: return
	light_mode = m
	var k := float(cfg.self_light_night if m == "night" else cfg.self_light_day)
	for s in shoppers: s.body.set_self_light(k)
	for b in mannequins: b.set_self_light(k)
	for p in players: p.body.set_self_light(k)

## Window mannequins (off since Oct 16 2026: "delete all the mannequin NPCs").
func _place_mannequins() -> void:
	if not bool(cfg.get("mannequins", true)): return
	var gen := str(get_tree().current_scene.get_meta("gen", "res://gen/"))
	var path := gen + "mannequins.json"
	if not FileAccess.file_exists(path): return
	var j = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (j is Dictionary): return
	var pool := []
	for id in cfg.mannequin_skins:
		if all_skins.has(str(id)): pool.append(all_skins[str(id)])
	if pool.is_empty(): return
	var i := 0
	for m in j.get("mannequins", []):
		var b := NpcBody.new()
		b.set_skin(pool[i % pool.size()]); i += 1
		add_child(b)
		var p: Array = m.pos
		b.position = Vector3(float(p[0]), float(p[1]), float(p[2]))
		var f: Array = m.face
		b.face(Vector3(float(f[0]), 0, float(f[1])))
		var pose: Array = cfg.mannequin_pose
		b.freeze(str(pose[0]), float(pose[1]) + 0.37 * (i % 3))
		mannequins.append(b)

# ------------------------------------------------------------------ Pocket Change
## The upright video cabinets this wing's builder recorded (gen/w*/machines.json) whose style has a
## player position in scripts/arcade_panels.json.
func _arcade_machines() -> Array:
	var gen := str(get_tree().current_scene.get_meta("gen", "res://gen/"))
	var paths := [gen + "machines.json"]
	for g in _gens:   # SEAMLESS: every wing that is in (rebind)
		if not ((str(g) + "machines.json") in paths):
			paths.append(str(g) + "machines.json")
	if not FileAccess.file_exists(PANELS): return []
	var pj = JSON.parse_string(FileAccess.get_file_as_string(PANELS))
	if not (pj is Dictionary): return []
	var list := []
	for path in paths:
		if not FileAccess.file_exists(path): continue
		var j = JSON.parse_string(FileAccess.get_file_as_string(path))
		if not (j is Dictionary): continue
		for m in j.get("machines", []):
			if not (str(m.get("mod", "")) in cfg.arcade_mods): continue
			var st: Dictionary = pj.styles.get(str(int(m.get("opts", {}).get("style", 0))), {})
			if st.is_empty() or st.get("skip", false) or not st.has("L"): continue
			var mm: Dictionary = m.duplicate()
			mm["panel"] = st
			list.append(mm)
	return list

## A share of the machines get a player: body centred on their controls, set back from the panel
## (arcade_back_m) so the legs stay clear of the cabinet, hands on the stick and buttons, eyes on
## the screen. Players are the arcade_ids characters (one of each), then the crowd.
func _place_players(list: Array) -> void:
	if list.is_empty(): return
	list.shuffle()
	var n := int(round(list.size() * float(cfg.arcade_fill)))
	n = mini(n, int(cfg.get("arcade_max", 999)))
	var ids := []
	for i in cfg.get("arcade_ids", []):
		if all_skins.has(str(i)): ids.append(str(i))
	n = mini(n, ids.size()) if bool(cfg.get("unique", false)) else n
	# spread them out: never two neighbours
	var chosen := []
	for m in list:
		if chosen.size() >= n: break
		var pa: Array = m.pos
		var p := Vector3(float(pa[0]), 0, float(pa[2]))
		var near := false
		for c in chosen:
			if c.p.distance_to(p) < 1.6: near = true
		if not near: chosen.append({"m": m, "p": p})
	for i in range(chosen.size()):
		var m: Dictionary = chosen[i].m
		var e: Dictionary = all_skins[ids[i % ids.size()]] if not ids.is_empty() else _pick_skin()
		in_use[str(e.id)] = true
		var b := _make_body(e)
		var fa: Array = m.face
		var pos: Vector3 = chosen[i].p
		var f := Vector3(float(fa[0]), 0, float(fa[1])).normalized()
		var X := f.cross(Vector3.UP)                     # the player's right (video.gd X())
		var st: Dictionary = m.panel
		var w := func(a: Array) -> Vector3: return pos + X * float(a[0]) + Vector3.UP * float(a[1]) + f * float(a[2])
		var L: Vector3 = w.call(st.L); var R: Vector3 = w.call(st.R)
		var xc := (float(st.L[0]) + float(st.R[0])) * 0.5
		var stand := pos + X * xc - f * float(cfg.arcade_back_m)
		b.position = stand
		b.face(f)
		var base := _pick(cfg.arcade_bases, "play")
		b.play(base)
		var p := {"body": b, "pos": stand, "face": f, "L": L, "R": R, "screen": w.call(st.screen), "base": base, "style": int(m.get("opts", {}).get("style", 0)),
			"react": rng.randf_range(float(cfg.arcade_react_s[0]), float(cfg.arcade_react_s[1])), "aside": false}
		b.hands_to(L, R)
		b.look_at_point(p.screen)
		b.gesture_done.connect(func(_n: String):
			if not p.aside:
				b.hands_to(p.L, p.R); b.look_at_point(p.screen))
		players.append(p)
	print("npcs: ", players.size(), " of ", list.size(), " cabinets have players")

## A player at a machine: hands on the controls, a reaction now and then (a cheer, a groan),
## steps aside when the real player wants the machine.
func _step_player(p: Dictionary, dt: float) -> void:
	var b: NpcBody = p.body
	var d: float = Vector2(player.global_position.x - p.pos.x, player.global_position.z - p.pos.z).length()
	b.visible = d < float(cfg.see_m)
	b.set_animated(d < float(cfg.lod_anim_m))
	if not b.visible: return
	var want_aside: bool = d < float(cfg.arcade_yield_m)
	if want_aside != p.aside:
		p.aside = want_aside
		var right: Vector3 = p.face.cross(Vector3.UP)
		b.position = p.pos + (right * 0.9 - p.face * 0.3 if want_aside else Vector3.ZERO)
		if want_aside:
			b.hands_off(); b.look_at_point(Vector3.INF); b.play(_pick(cfg.idles.get(_sex(b.id), ["idle"])))
		else:
			b.play(p.base); b.hands_to(p.L, p.R); b.look_at_point(p.screen)
	if p.aside: return
	p.react -= dt
	if p.react <= 0.0 and not b.busy():
		p.react = rng.randf_range(float(cfg.arcade_react_s[0]), float(cfg.arcade_react_s[1]))
		b.hands_off(); b.look_at_point(Vector3.INF)
		b.gesture(_pick(cfg.arcade_reacts, "clap"))

# ------------------------------------------------------------------ special people
## The drunk: one character, the drunk walk and sways, wandering the hall.
func _spawn_drunk() -> void:
	var d: Dictionary = cfg.get("drunk", {})
	if not d.has("id") or not all_skins.has(str(d.id)): return
	var s := _new_shopper(all_skins[str(d.id)], _free_hall_point(true))
	if s == null: return
	s.role = "drunk"
	s.type = d
	s.type_name = "drunk"
	s.body.walk_clip = "walk_drunk"
	var sp: Array = d.get("speed_mps", [0.75, 0.9])
	s.speed = rng.randf_range(float(sp[0]), float(sp[1]))
	s.body.play(_pick(d.get("idles", ["drunk_idle"])))

## Pairs who meet to talk: on a bench (shown) or standing in the hall.
func _spawn_pairs() -> void:
	for pc in cfg.get("pairs", []):
		var ids: Array = pc.ids
		if ids.size() != 2 or not all_skins.has(str(ids[0])) or not all_skins.has(str(ids[1])): continue
		var pr := {"kind": str(pc.kind), "m": [], "state": "", "timer": 0.0, "spots": []}
		if not _pair_spots(pr): continue
		for i in range(2):
			var sp: Dictionary = pr.spots[i]
			var s := _new_shopper(all_skins[str(ids[i])], sp.stand)
			if s == null: continue
			s.role = "pair"; s.pair = pr; s.slot = i
			_pick_type(s)
			pr.m.append(s)
		if pr.m.size() != 2: continue
		pairs.append(pr)
		_pair_start(pr, true)

## Spots for a pair: two seats on one shown bench, or two hall points 1.1 m apart facing each other.
func _pair_spots(pr: Dictionary) -> bool:
	pr.spots = []
	var kind := str(pr.kind)
	if kind == "bench":
		var shown := []
		for b in benches:
			if _bench_shown(b): shown.append(b)
		if shown.is_empty(): kind = "chat"
		else:
			var b: Dictionary = shown[rng.randi() % shown.size()]
			var f: Vector3 = b.face
			var side := f.cross(Vector3.UP)
			for k in [-1.0, 1.0]:
				var seat: Vector3 = b.pos + side * 0.42 * k - f * 0.05
				pr.spots.append({"seat": seat, "stand": seat + f * 0.48, "face": f})
			pr.cur = "bench"
			return true
	for i in range(40):
		var c: Vector2i = hall_cells[rng.randi() % hall_cells.size()]
		var p := _centre(c)
		var dv := Vector3(1, 0, 0) if rng.randf() < 0.5 else Vector3(0, 0, 1)
		var a := p - dv * 0.55; var b := p + dv * 0.55
		if _open(a) and _open(b) and _open(a - dv * 0.6) and _open(b + dv * 0.6):
			pr.spots = [{"stand": a, "face": dv}, {"stand": b, "face": -dv}]
			pr.cur = "chat"
			return true
	return false

## Both are at their spots: sit down (bench) or start talking (standing). `now` skips the walk-in.
func _pair_start(pr: Dictionary, now := false) -> void:
	pr.state = "together"
	pr.timer = rng.randf_range(float(cfg.pair_talk_s[0]), float(cfg.pair_talk_s[1]))
	for s in pr.m:
		var sp: Dictionary = pr.spots[s.slot]
		s.state = "pair"; s.path = PackedVector3Array()
		s.body.set_speed(0.0)
		s.body.face(sp.face)
		s.gest_t = rng.randf_range(3.0, 8.0)
		if pr.cur == "bench":
			if now:
				var sc: String = ["sit_talk", "sit_talk_2"][s.slot]
				s.pos = sp.seat; s.body.play(sc); s.body.place_at(sp.seat, sc)
			else:
				s.body.gesture("stand_to_sit")
		else:
			s.pos = sp.stand; s.body.position = sp.stand
			s.body.play(_pick(["talk", "talk_2", "talk_3", "talk_4", "talk_5", "argue", "argue_3"]))

## Once a second: pairs end their talk, walk apart for a while, then meet again somewhere else.
func _pairs_tick() -> void:
	var shown := bool(player.get("fixtures_on"))
	for pr in pairs:
		pr.timer -= 1.0
		# benches switched off under a sitting pair, or on while a bench pair stands: change now
		if str(pr.state) == "together" and ((pr.cur == "bench" and not shown) or (pr.cur == "chat" and pr.kind == "bench" and shown)):
			pr.timer = 0.0
		if str(pr.state) == "apart" and pr.kind == "bench" and shown and pr.timer > 8.0:
			pr.timer = 8.0
		match str(pr.state):
			"together":
				if pr.timer <= 0.0:
					pr.state = "parting"
					for s in pr.m:
						if pr.cur == "bench": s.body.gesture("sit_to_stand")
						else: _pair_release(s)
			"apart":
				if pr.timer <= 0.0 and _pair_spots(pr):
					pr.state = "gather"
					for s in pr.m:
						s.goal = {"type": "pair"}
						if s.state == "pair" or not _route(s, pr.spots[s.slot].stand):
							s.pos = pr.spots[s.slot].stand; s.body.position = s.pos; s.state = "pairwait"
			"gather":
				var ready := true
				for s in pr.m:
					if s.state != "pairwait": ready = false
				if ready: _pair_start(pr)

func _pair_release(s: Shopper) -> void:
	var pr: Dictionary = s.pair
	s.state = "dwell"; s.timer = rng.randf_range(0.5, 2.0); s.goal = {"type": "start"}
	s.body.play(_pick(cfg.idles.get(s.sex, ["idle"])))
	var all_free := true
	for o in pr.m:
		if o.state == "pair": all_free = false
	if all_free:
		pr.state = "apart"
		pr.timer = rng.randf_range(float(cfg.pair_apart_s[0]), float(cfg.pair_apart_s[1]))

## A one-shot finished on a shopper's body: transitions move the body to where the clip left it.
func _on_gesture_done(s: Shopper, n: String) -> void:
	if s.role == "salon":
		_salon_gesture_done(s, n); return
	if s.pair == null: return
	var sp: Dictionary = s.pair.spots[s.slot] if s.slot < s.pair.spots.size() else {}
	if n == "stand_to_sit" and not sp.is_empty():
		var sc: String = ["sit_talk", "sit_talk_2"][s.slot]
		s.pos = sp.seat
		s.body.play(sc, 0.15)
		s.body.place_at(sp.seat, sc)
	elif n == "sit_to_stand" and not sp.is_empty():
		s.pos = sp.stand; s.body.position = sp.stand
		_pair_release(s)

# ------------------------------------------------------------------ the salon customers
## Regis has one slot, MasterCuts two (npcs.json "salons"); each slot sends one woman at a time
## to a chair no other slot is using.
func _has_salon(store: String) -> bool:
	for sl in salons:
		if str(sl.c.get("store", "")) == store: return true
	return false

func _salon_face(sl: Dictionary) -> Vector3:
	var f: Array = sl.c.get("face", [1, 0])
	return Vector3(float(f[0]), 0, float(f[1])).normalized()

func _salon_seat(sl: Dictionary) -> Vector3:
	var c: Array = sl.c.chairs[int(sl.chair)]
	return Vector3(float(c[0]), 0, float(c[1]))

func _salon_stand(sl: Dictionary) -> Vector3:
	return _salon_seat(sl) + _salon_face(sl) * float(sl.c.get("stand_m", 0.55))

## Once a second per slot: when the slot is empty and its gap is over, a woman from the crowd (one
## the player can't see, else a new one out of sight) is sent to a random free chair.
func _salon_tick(sl: Dictionary) -> void:
	if not sl.get("on", false) or sl.s != null: return
	sl.timer -= 1.0
	if sl.timer > 0.0: return
	var chairs: Array = sl.c.get("chairs", [])
	var free_ch := []
	for i in chairs.size():
		var used := false
		for o in salons:
			if o != sl and o.s != null and o.c == sl.c and int(o.chair) == i: used = true
		if not used: free_ch.append(i)
	if free_ch.is_empty(): sl.timer = 10.0; return
	var cand: Shopper = null
	for s in shoppers:
		if s.role == "" and s.sex == "f" and s.state in ["walk", "dwell"] and not s.body.busy():
			if cand == null or (s.unseen > 1.0 and cand.unseen <= 1.0) or s.pos.distance_to(sl.door) < cand.pos.distance_to(sl.door):
				cand = s
	if cand == null:
		var free := []
		for e in skins:
			if not in_use.has(str(e.id)) and _sex(str(e.id)) == "f": free.append(e)
		if free.is_empty(): sl.timer = 10.0; return
		cand = _new_shopper(free[rng.randi() % free.size()], _free_hall_point())
		if cand == null: sl.timer = 5.0; return
		_pick_type(cand)
	sl.chair = free_ch[rng.randi() % free_ch.size()]
	cand.role = "salon"
	cand.sal = sl
	sl.s = cand
	if not _salon_route(cand):
		print("npcs: no route to ", sl.c.get("store", ""), " chair ", sl.chair)
		_salon_release(cand); sl.timer = 10.0
		return
	print("npcs: salon customer ", cand.body.id, " to ", sl.c.get("store", ""), " chair ", sl.chair)

## A route to the spot in front of the chair: the walk grid to the nearest open cell, then the
## last step straight in (the chair itself is an obstacle on the grid).
func _salon_route(s: Shopper) -> bool:
	var stand := _salon_stand(s.sal)
	# a narrow salon (MasterCuts) is cut off on the coarse grid by its own desk and chairs: walk to
	# its "via" point inside the door, then straight along the free aisle to the chair
	var via: Array = s.sal.c.get("via", [])
	if not via.is_empty():
		var v0 := Vector3(float(via[0]), 0, float(via[1]))
		if not _route(s, v0): return false
		s.path.append(Vector3(stand.x, 0, float(via[1])) if absf(stand.z - float(via[1])) > 0.05 else stand)
		s.path.append(stand)
		s.goal = {"type": "salon"}
		return true
	var best := Vector3.INF
	for r in [0.0, 0.5, 1.0, 1.5]:
		for a in range(8):
			var q: Vector3 = stand + Vector3(cos(a * PI / 4.0), 0, sin(a * PI / 4.0)) * float(r)
			if _open(q) and (best == Vector3.INF or q.distance_to(stand) < best.distance_to(stand)): best = q
		if best != Vector3.INF: break
	if best == Vector3.INF or not _route(s, best): return false
	s.path.append(stand)
	s.goal = {"type": "salon"}
	return true

func _salon_gesture_done(s: Shopper, n: String) -> void:
	var sl: Dictionary = s.sal
	if n == "stand_to_sit":
		var clip := _pick(sl.c.get("clips", ["sit_idle_2"]), "sit_idle_2")
		sl.clip = clip
		s.pos = _salon_seat(sl)
		s.body.play(clip, 0.15)
		s.body.place_at(_salon_seat(sl), clip)
		s.body.position.y = float(sl.c.get("seat_y", 0.0))
		var st: Array = sl.c.get("stay_s", [150, 330])
		sl.timer = rng.randf_range(float(st[0]), float(st[1]))
		sl.sitting = true
	elif n == "sit_to_stand":
		s.body.position = _salon_stand(sl); s.body.position.y = 0.0
		s.pos = _salon_stand(sl)
		_salon_release(s)

## Back into the crowd as an ordinary shopper; the slot stays empty for a while.
func _salon_release(s: Shopper) -> void:
	var sl: Dictionary = s.sal
	s.role = ""
	s.sal = null
	s.state = "dwell"; s.timer = rng.randf_range(0.5, 2.0); s.goal = {"type": "start"}
	s.body.play(_pick(cfg.idles.get(s.sex, ["idle"])))
	if sl == null: return
	sl.s = null; sl.sitting = false
	var gp: Array = sl.c.get("gap_s", [20, 60])
	sl.timer = rng.randf_range(float(gp[0]), float(gp[1]))

# ------------------------------------------------------------------ the general crowd
## How many people the hour wants, and spawn or retire unseen ones to get there.
func _balance() -> void:
	var h := 13.0
	if rt and "hour" in rt: h = float(rt.hour)
	var dens := _density(h)
	want = int(round(float(cfg.count) * dens))
	if force.is_valid_int() and int(force) > 0: want = int(force)
	var crowd := 0
	for s in shoppers:
		if s.role == "": crowd += 1
	if bool(cfg.get("unique", false)):
		var free := 0
		for e in skins:
			if not in_use.has(str(e.id)): free += 1
		want = mini(want, crowd + free)
	var tries := 0
	while crowd < want and tries < (200 if spawn_all_now else 20):
		tries += 1
		if _spawn() != null: crowd += 1
	if crowd > want:
		for s in shoppers:
			if s.role == "" and s.unseen > 2.0:
				_remove(s); break

func _density(h: float) -> float:
	var keys := []
	for k in cfg.hours: keys.append(float(k))
	keys.sort()
	if keys.is_empty(): return 1.0
	if h <= keys[0]: return float(cfg.hours[str(int(keys[0]))])
	for i in range(1, keys.size()):
		if h <= keys[i]:
			var a := float(cfg.hours[str(int(keys[i - 1]))]); var b := float(cfg.hours[str(int(keys[i]))])
			return lerpf(a, b, (h - keys[i - 1]) / (keys[i] - keys[i - 1]))
	return float(cfg.hours[str(int(keys[keys.size() - 1]))])

## Whether the player would see a point now: in front, within see_m, nothing in the way.
func _seen(p: Vector3) -> bool:
	var pp: Vector3 = player.global_position
	var to := p - pp; to.y = 0
	var d := to.length()
	if d > float(cfg.see_m): return false
	if d < 2.5: return true
	var fwd: Vector3 = -player.global_transform.basis.z; fwd.y = 0
	if fwd.normalized().dot(to / d) < cos(deg_to_rad(float(cfg.see_cone_deg))): return false
	return _los(pp, p)

## A hall point out of the player's sight (or anywhere 6 m+ away when `any`).
func _free_hall_point(any := false) -> Vector3:
	if hall_cells.is_empty(): return Vector3.INF
	for i in range(40):
		var p := _centre(hall_cells[rng.randi() % hall_cells.size()])
		var d := Vector2(p.x - player.global_position.x, p.z - player.global_position.z).length()
		if any or spawn_all_now:
			if d > 6.0: return p
			continue
		if d < float(cfg.spawn_min_m) or _seen(p): continue
		return p
	return Vector3.INF

## A shopper record with a body at p.
func _new_shopper(e: Dictionary, p: Vector3) -> Shopper:
	if p == Vector3.INF or e.is_empty(): return null
	var s := Shopper.new()
	in_use[str(e.id)] = true
	s.body = _make_body(e, s)
	s.body.set_self_light(float(cfg.self_light_night if light_mode == "night" else cfg.self_light_day))
	s.pos = p
	s.body.position = p
	s.body.face(Vector3(rng.randf() - 0.5, 0, rng.randf() - 0.5))
	s.speed = rng.randf_range(float(cfg.speed_mps[0]), float(cfg.speed_mps[1]))
	s.state = "dwell"; s.timer = rng.randf_range(0.2, 2.0); s.goal = {"type": "start"}
	shoppers.append(s)
	return s

## A new crowd shopper somewhere the player cannot see, with a type (browser, shopper, …).
func _spawn() -> Shopper:
	if hall_cells.is_empty(): return null
	var p := _free_hall_point()
	if p == Vector3.INF: return null
	var e := _pick_skin()
	if e.is_empty(): return null
	var s := _new_shopper(e, p)
	_pick_type(s)
	var sp: Array = s.type.get("speed_mps", cfg.speed_mps)
	s.speed = rng.randf_range(float(sp[0]), float(sp[1]))
	var wk: Array = s.type.get("walks", [])
	if not wk.is_empty() and rng.randf() < float(s.type.get("walks_p", 0.5)):
		s.body.walk_clip = _pick(wk, s.body.walk_clip)
	var ra: Array = cfg.retire_after_goals
	s.retire = rng.randi_range(int(ra[0]), int(ra[1]))
	return s

## A browser, a shopper, a heavy shopper or a confused one (scripts/npcs.json "types", by "w").
func _pick_type(s: Shopper) -> void:
	var total := 0.0
	for k in cfg.types: total += float(cfg.types[k].get("w", 1.0))
	var r := rng.randf() * total
	for k in cfg.types:
		r -= float(cfg.types[k].get("w", 1.0))
		if r <= 0.0:
			s.type = cfg.types[k]; s.type_name = k; return
	if not cfg.types.is_empty():
		s.type_name = cfg.types.keys()[0]; s.type = cfg.types[s.type_name]

func _remove(s: Shopper) -> void:
	if s.sal != null:
		s.sal.s = null; s.sal.sitting = false; s.sal.timer = 20.0
	shoppers.erase(s)
	in_use.erase(s.body.id)
	s.body.queue_free()

## The next goal: a store to go into, a window to look in, or a far point of the hall.
func _decide(s: Shopper) -> void:
	if s.role == "salon":
		if _salon_route(s): return
		_salon_release(s)
	s.goals += 1
	if s.pair and str(s.pair.state) == "gather":
		s.goal = {"type": "pair"}
		if _route(s, s.pair.spots[s.slot].stand): return
	var g: Dictionary = s.type.get("goals", cfg.goals)
	var r := rng.randf() * (float(g.get("store", 0)) + float(g.get("window", 0)) + float(g.get("hall", 1)))
	var target := Vector3.ZERO
	if r < float(g.get("store", 0)) and not stores.is_empty():
		var st: Dictionary = _near_place(stores, s.pos)
		s.goal = {"type": "store", "spots": st.spots, "i": 0, "name": st.name, "face": -st.n}
		target = st.spots[0]
	elif r < float(g.get("store", 0)) + float(g.get("window", 0)) and not windows.is_empty():
		var wn: Dictionary = _near_place(windows, s.pos)
		s.goal = {"type": "window", "name": wn.name, "face": -wn.n}
		target = wn.spot
	else:
		var c: Vector2i = hall_cells[rng.randi() % hall_cells.size()]
		for i in range(20):
			c = hall_cells[rng.randi() % hall_cells.size()]
			if _centre(c).distance_to(s.pos) > 15.0: break
		s.goal = {"type": "hall"}
		target = _centre(c)
	if not _route(s, target):
		s.state = "dwell"; s.timer = 1.0; s.goal = {"type": "start"}

## A random place among the nearer ones (within store_max_m when any are).
func _near_place(list: Array, from: Vector3) -> Dictionary:
	var near := []
	for p in list:
		if p.door.distance_to(from) < float(cfg.store_max_m) and p.door.distance_to(from) > 4.0: near.append(p)
	if near.is_empty(): near = list
	return near[rng.randi() % near.size()]

func _route(s: Shopper, target: Vector3) -> bool:
	var a := _cell(s.pos); var b := _cell(target)
	if not _open_c(a) or not _open_c(b): return false
	var ids := grid.get_id_path(a, b)
	if ids.size() < 2: return false
	s.path = PackedVector3Array()
	for i in range(1, ids.size()):
		s.path.append(_centre(ids[i]))
	s.path[s.path.size() - 1] = target
	s.pi = 0
	s.state = "walk"
	s.stuck = 0.0
	return true

## Arrived: the type's loop for the place, and a timer.
func _arrive(s: Shopper) -> void:
	var g := s.goal
	s.body.set_speed(0.0)
	s.gest_t = rng.randf_range(2.0, 6.0)
	match str(g.get("type", "")):
		"salon":
			s.state = "salon"
			s.body.face(_salon_face(s.sal))
			s.pos = _salon_stand(s.sal); s.body.position = s.pos
			s.body.gesture("stand_to_sit")
		"pair":
			s.state = "pairwait"
			s.body.face(s.pair.spots[s.slot].face)
			s.body.play(_pick(cfg.idles.get(s.sex, ["idle"])))
		"store":
			var spots: Array = g.spots
			s.state = "dwell"
			var ss: Array = s.type.get("shop_s", cfg.shop_s)
			s.timer = rng.randf_range(float(ss[0]), float(ss[1])) / spots.size()
			s.body.face(Vector3(rng.randf() - 0.5, 0, rng.randf() - 0.5))
			s.body.play(_pick(s.type.get("store_clips", ["look"])))
		"window":
			s.state = "dwell"
			var ws: Array = s.type.get("window_s", cfg.window_s)
			s.timer = rng.randf_range(float(ws[0]), float(ws[1]))
			s.body.face(g.face)
			s.body.play(_pick(s.type.get("window_clips", ["look"])))
		_:
			s.state = "dwell"
			s.timer = rng.randf_range(float(cfg.pause_s[0]), float(cfg.pause_s[1]))
			var hp: Dictionary = s.type.get("hall_pause", cfg.hall_pause)
			var r := rng.randf()
			for k in hp:
				r -= float(hp[k])
				if r < 0.0 and NpcBody.has_clip(k):
					# a once clip in the hall (checking the phone): stay for all of it
					s.body.gesture(k)
					s.timer = maxf(s.timer, NpcBody.clip_len(k) - 0.3)
					return
			s.body.play(_pick(s.type.get("idles", cfg.idles.get(s.sex, ["idle"]))))

func _dwell_done(s: Shopper) -> void:
	var g := s.goal
	if g.get("type", "") == "store" and int(g.i) + 1 < g.spots.size():
		g.i = int(g.i) + 1
		if _route(s, g.spots[g.i]): return
	if s.role == "" and s.goals >= s.retire and s.unseen > 1.0:
		_remove(s); return
	_decide(s)

func _step(s: Shopper, dt: float) -> void:
	# seen / unseen bookkeeping, far-away housekeeping
	var pp: Vector3 = player.global_position
	var d := Vector2(s.pos.x - pp.x, s.pos.z - pp.z).length()
	var seen := _seen(s.pos) if d < float(cfg.see_m) else false
	s.unseen = 0.0 if seen else s.unseen + dt
	if s.role == "" and s.unseen > float(cfg.recycle_unseen_s) and d > float(cfg.recycle_m) and s.goals >= 1 and rng.randf() < dt * 0.1:
		_remove(s); return
	s.body.visible = d < float(cfg.see_m) + 10.0
	s.body.set_animated(d < float(cfg.lod_anim_m))
	match s.state:
		"dwell":
			s.timer -= dt
			_maybe_gesture(s, dt, s.type.get("gestures", []))
			if s.timer <= 0.0 and not s.body.busy():
				_dwell_done(s)
		"salon":
			if s.sal != null and s.sal.get("sitting", false) and not s.body.busy():
				s.sal.timer -= dt
				if s.sal.timer <= 0.0:
					s.sal.sitting = false
					s.body.gesture("sit_to_stand")
		"pair":
			if s.pair and str(s.pair.cur) == "chat":
				_maybe_gesture(s, dt, cfg.pair_gestures)
		"walk":
			_follow(s, dt)

## Now and then a one-shot from `list` over the loop (a nod, a point, a head shake).
func _maybe_gesture(s: Shopper, dt: float, list: Array) -> void:
	if list.is_empty() or s.body.busy(): return
	s.gest_t -= dt
	if s.gest_t > 0.0: return
	s.gest_t = rng.randf_range(4.0, 10.0)
	if rng.randf() < 0.6:
		s.body.gesture(_pick(list, "head_yes"))

## Walk the route: keep right, step round people and the player, never through a wall.
func _follow(s: Shopper, dt: float) -> void:
	if s.pi >= s.path.size():
		_arrive(s); return
	var wp := s.path[s.pi]
	var to := wp - s.pos; to.y = 0
	var last := s.pi == s.path.size() - 1
	if to.length() < (0.35 if last else 0.6):
		s.pi += 1
		if s.pi >= s.path.size():
			s.pos = Vector3(wp.x, 0, wp.z) if last else s.pos
			s.body.position = s.pos
			_arrive(s); return
		wp = s.path[s.pi]; to = wp - s.pos; to.y = 0
	var dir := to.normalized()
	var want_dir := dir
	var spd := s.speed
	# keep right
	var right := dir.cross(Vector3.UP)
	if not last and _open(s.pos + right * float(cfg.keep_right_m)) and _open(wp + right * float(cfg.keep_right_m)):
		want_dir += right * 0.22
	# other shoppers
	var sep := float(cfg.separation_m)
	for o in shoppers:
		if o == s: continue
		var dv: Vector3 = s.pos - o.pos; dv.y = 0
		var dd: float = dv.length()
		if dd < sep and dd > 0.01:
			want_dir += dv / dd * (sep - dd) / sep * 0.9
			if dir.dot(-dv / dd) > 0.75 and dd < 1.0: spd *= 0.35
	# the player
	var pv := s.pos - player.global_position; pv.y = 0
	var pd := pv.length()
	if pd < float(cfg.player_m) and pd > 0.01:
		want_dir += pv / pd * (float(cfg.player_m) - pd) / float(cfg.player_m) * 1.5
		if dir.dot(-pv / pd) > 0.6: spd *= 0.3
	want_dir = want_dir.normalized()
	var step := want_dir * spd * dt
	var np := s.pos + step
	var moved := 0.0
	if _open(np):
		s.pos = np; moved = step.length()
	elif _open(s.pos + dir * spd * dt):
		s.pos += dir * spd * dt; moved = spd * dt
	else:
		s.stuck += dt
		if s.stuck > 1.5:
			s.stuck = 0.0
			if not _route(s, s.path[s.path.size() - 1]):
				_decide(s)
			return
	s.pos.y = 0
	s.body.position = s.pos
	s.body.face(want_dir, 9.0, dt)
	s.body.set_speed(moved / dt if dt > 0.0 else 0.0)
