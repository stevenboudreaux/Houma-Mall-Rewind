## Seamless streaming between wings (workstream SEAMLESS, Nov 13 2026; design/godot-wings.md
## "Seamless streaming"; settings in data/stream.json).
##
## Steven, Nov 13: "walk from the inside of Dillard's to the inside of Sears, and then all the way to
## Corn Dog 7, all without a load screen". The wings stay separate scenes, packs and bakes. This node
## brings the wing on the other side of a border into the running game in the background, in place of
## the pictures that stood in for it, so the border is just floor:
##
##  1. fetch: on the web the page downloads the neighbour's pack (web/shell.html window.mallStream,
##     the same Cache Storage as the old prefetch) and copies it into the engine's file system;
##  2. mount: the pack is mounted with replace_files = false (the running wing's copies win; the two
##     packs' shared files are byte-identical);
##  3. load: every resource the neighbour's scene names is loaded a few milliseconds per frame, then
##     the scene is instanced without its Player / Runtime / Signs / Env / Sun and its nodes enter
##     the tree a batch per frame; its lightmap is set last;
##  4. swap: both wings hide their copy of the other's halls and their pictures of its storefronts;
##     the player's walk grid and obstacles become the two wings' union and the seam prompt goes;
##  5. handoff: when the player is past the border, the systems that belong to a wing (the player's
##     own nodes, shops, attendants, items, shoppers, signs, prizes ...) are remade for the wing they
##     now stand in, in one frame, exactly as a page load into that wing would make them; the
##     geometry of both wings stays where it is. State lives outside the scene already (the old
##     crossing reloaded the page), so nothing is lost.
##
## A neighbour that is not in yet leaves everything as it was: the stand-in pictures, the seam's
## wall and the old prompt, which still loads the other wing the old way.
## Phones and tablets unload a neighbour that is far behind (data/stream.json far_m).
##
## One of these lives under /root for the whole run (make(); scripts/player.gd attaches each new
## Player to it).
extends Node

const NODE_NAME := "WingStream"
const CFG_PATH := "res://data/stream.json"
## Nodes of a wing scene that exist once for the whole game: taken out of a neighbour.
const SOLO := ["Player", "Runtime", "Signs", "Env", "Sun"]

var cfg := {}
var enabled := false
var kind := "desktop"          # "desktop" or "mobile": which column of the settings applies
var player: Node3D
var home: Node                 # the wing scene the player's systems belong to (current_scene)
var home_wing := 0
var year := 1995
## wing -> {state, root, deps, held, pending, t0, ms, border}; state: "", "fetch", "load", "enter", "in", "failed"
var nb := {}
## wing -> the wing's own wing.json / collide.json (walk grid, obstacles), read once
var info := {}
## Resources held so ResourceLoader's cache keeps them between the load and the instancing (and
## across handoffs): wing -> Array
var held := {}
var _hidden := {}              # wing -> Array of nodes this streamer hid (that wing's stand-in of others)
var _discard: StandardMaterial3D
var _t_start := 0.0
var _busy := false
var _scale := 1.0
## Measurements for tools/qa (and ?debug=1): wing -> {fetch_ms, mount_ms, load_ms, load_max_ms,
## inst_ms, enter_ms, enter_max_ms, handoff_ms}
var stats := {}

## The streamer under /root, made on first use.
static func make(tree: SceneTree) -> Node:
	var n = tree.root.get_node_or_null(NODE_NAME)
	if n == null:
		n = load("res://scripts/wing_stream.gd").new()
		n.name = NODE_NAME
		tree.root.add_child.call_deferred(n)
	return n

func _init() -> void:
	if FileAccess.file_exists(CFG_PATH):
		var j = JSON.parse_string(FileAccess.get_file_as_string(CFG_PATH))
		if j is Dictionary:
			cfg = j
	var q := ""
	if OS.has_feature("web"):
		q = str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('stream') || ''"))
		kind = str(JavaScriptBridge.eval("window.__mallPack || 'desktop'"))
	if Engine.has_meta("mall_stream_kind"):
		kind = str(Engine.get_meta("mall_stream_kind"))
	# "enabled": true / false, or one per kind of device {"desktop": true, "mobile": false}
	var en = cfg.get("enabled", false)
	enabled = bool(en.get(kind, false)) if en is Dictionary else bool(en)
	if Engine.has_meta("mall_stream"):          # tests and native runs
		enabled = bool(Engine.get_meta("mall_stream"))
	if q == "1": enabled = true
	elif q == "0": enabled = false

func _num(key: String, def: float) -> float:
	var v = cfg.get(key, def)
	if v is Dictionary:
		return float(v.get(kind, def))
	return float(v)

## A new Player (the first one, or the one a handoff made) says where it stands.
func attach(p: Node3D) -> void:
	player = p
	home = p.get_parent()
	home_wing = int(p.wing)
	year = int(p.year)
	_t_start = Time.get_ticks_msec() / 1000.0
	if not enabled:
		return
	# a wing that is already in (after a handoff): its borders are open at once
	for w in nb:
		if nb[w].state == "in":
			_open_border(int(w))
	_js_state()

## The borders of the home wing that stream: [{to, kind, line [x0, z, x1], side}]
func borders() -> Array:
	var out := []
	for b in cfg.get("borders", []):
		if not (year in (b.get("years", []) as Array).map(func(v): return int(v))):
			continue
		var a := int(b.a); var c := int(b.b)
		if home_wing != a and home_wing != c:
			continue
		var to := c if home_wing == a else a
		if str(b.get("kind", "seam")) == "seam":
			var wj: Dictionary = wing_info(home_wing)
			var s: Array = wj.get("seam", [])
			if s.size() >= 3:
				out.append({"to": to, "kind": "seam", "line": s, "side": float(wj.get("other_side", 1.0))})
	return out

func _gen(w: int) -> String:
	return "res://gen/w%d%s/" % [w, "y26" if year == 2026 else ""]

func scene_path(w: int) -> String:
	return ("res://wing%d_2026.tscn" if year == 2026 else "res://wing%d.tscn") % w

## A wing's wing.json plus its obstacles, cached (only readable once its pack is mounted).
func wing_info(w: int) -> Dictionary:
	if info.has(w):
		return info[w]
	var g := _gen(w)
	if not FileAccess.file_exists(g + "wing.json"):
		return {}
	var wj = JSON.parse_string(FileAccess.get_file_as_string(g + "wing.json"))
	if not (wj is Dictionary):
		return {}
	var col = JSON.parse_string(FileAccess.get_file_as_string(g + "collide.json")) if FileAccess.file_exists(g + "collide.json") else null
	wj["static"] = col.get("static", []) if col is Dictionary else []
	wj["fixtures"] = col.get("fixtures", []) if col is Dictionary else []
	info[w] = wj
	return wj

## Signed distance from the player to a border line, positive on the home side.
func _dist(b: Dictionary) -> float:
	var ln: Array = b.line
	return (float(ln[1]) - player.position.z) * float(b.side)

## How far the player is from a border line, whichever side.
func _away(b: Dictionary) -> float:
	var ln: Array = b.line
	var dx := 0.0
	if player.position.x < float(ln[0]): dx = float(ln[0]) - player.position.x
	elif player.position.x > float(ln[2]): dx = player.position.x - float(ln[2])
	return Vector2(dx, float(ln[1]) - player.position.z).length()

func _process(dt: float) -> void:
	# a slow renderer (a long frame) gets a proportionally bigger share per frame, or the load would
	# take as many frames on a 5 fps device as on a 60 fps one
	_scale = clampf(dt / 0.0167, 1.0, 400.0)
	if not enabled or player == null or not is_instance_valid(player) or _busy:
		return
	if bool(player.get("leaving")):
		return
	var now := Time.get_ticks_msec() / 1000.0
	for b in borders():
		var to := int(b.to)
		var d := _dist(b)
		var st: String = nb.get(to, {}).get("state", "")
		if st == "" and now - _t_start > _num("start_delay_s", 2.0) and _away(b) < _num("near_m", 60.0):
			_start(to, b)
		elif st == "in":
			if d < -_num("handoff_past_m", 1.0) and _stands_in(to):
				_handoff.call_deferred(to)
				_busy = true
				return
			if _away(b) > _num("far_m", 1e9):
				unload(to)
	for w in nb.keys():
		if str(nb[w].state) == "in":
			# "Benches & plants" (the player's HUD switch) shows or hides every wing's fixtures
			var fx = nb[w].root.get_node_or_null("Dynamic/dyn_fixtures")
			if fx and fx.visible != bool(player.fixtures_on):
				fx.visible = bool(player.fixtures_on)
		match str(nb[w].state):
			"fetch": _poll_fetch(int(w))
			"load": _step_load(int(w))
			"enter": _step_enter(int(w))

## Whether the floor under the player is wing w's own and not the home wing's (their walk grids): past
## a border line alone is not enough, a store of the home wing can reach past the line beside it.
func _stands_in(w: int) -> bool:
	return _on_grid(w, player.position) and not _on_grid(home_wing, player.position)

func _on_grid(w: int, p: Vector3) -> bool:
	var wj: Dictionary = wing_info(w)
	var rows: Array = wj.get("walk", [])
	var o: Array = wj.get("origin", [148.0, 100.0])
	var tx := int(floor(p.x / 2.0 + float(o[0]))); var ty := int(floor(p.z / 2.0 + float(o[1])))
	return ty >= 0 and ty < rows.size() and tx >= 0 and tx < str(rows[ty]).length() and str(rows[ty])[tx] == "1"

# ------------------------------------------------------------------ 1-2: fetch and mount
func _start(w: int, b: Dictionary) -> void:
	nb[w] = {"state": "fetch", "border": b, "t0": Time.get_ticks_msec()}
	stats[w] = {}
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.mallStream && window.mallStream(%d)" % w, true)
	_js_state()

func _poll_fetch(w: int) -> void:
	var path := ""
	if OS.has_feature("web"):
		var s := str(JavaScriptBridge.eval("(window.__mallStream && window.__mallStream[%d]) || ''" % w, true))
		if s == "error" or s == "":
			if s == "error" or Time.get_ticks_msec() - int(nb[w].t0) > 3000:
				_fail(w, "the page could not fetch the pack")
			return
		if not s.begins_with("/"):
			return        # "fetching"
		path = s
		stats[w]["fetch_ms"] = Time.get_ticks_msec() - int(nb[w].t0)
		var t := Time.get_ticks_msec()
		var sp = get_node_or_null("/root/SharedPacks")
		var ok: bool = sp.mount(path) if sp else ProjectSettings.load_resource_pack(path, false)
		stats[w]["mount_ms"] = Time.get_ticks_msec() - t
		if not ok:
			_fail(w, "the pack did not mount")
			return
	if not ResourceLoader.exists(scene_path(w)):
		_fail(w, "no scene " + scene_path(w))
		return
	# 3: what the scene needs, loaded a little per frame
	var deps: Array = []
	for d in ResourceLoader.get_dependencies(scene_path(w)):
		var p := str(d)
		if p.contains("::"):
			p = p.get_slice("::", 2)
		if p != "" and not ResourceLoader.has_cached(p):
			deps.append(p)
	nb[w].pending = deps
	nb[w].n_deps = deps.size()
	nb[w].state = "load"
	nb[w].t0 = Time.get_ticks_msec()
	stats[w]["load_max_ms"] = 0
	if not held.has(w):
		held[w] = []
	_js_state()

func _fail(w: int, why: String) -> void:
	push_warning("wing_stream: wing %d not streamed: %s" % [w, why])
	nb[w].state = "failed"
	_js_state()

# ------------------------------------------------------------------ 3: load and instance
func _step_load(w: int) -> void:
	var t := Time.get_ticks_msec()
	var budget := int(_num("load_budget_ms", 6.0) * _scale)
	var pend: Array = nb[w].pending
	while not pend.is_empty() and Time.get_ticks_msec() - t < budget:
		var p: String = pend.pop_back()
		var r = ResourceLoader.load(p) if ResourceLoader.exists(p) else null
		if r:
			held[w].append(r)
	stats[w]["load_max_ms"] = maxi(int(stats[w]["load_max_ms"]), Time.get_ticks_msec() - t)
	if not pend.is_empty():
		return
	stats[w]["load_ms"] = Time.get_ticks_msec() - int(nb[w].t0)
	t = Time.get_ticks_msec()
	var ps = ResourceLoader.load(scene_path(w))
	if not (ps is PackedScene):
		_fail(w, "the scene did not load")
		return
	held[w].append(ps)
	var root: Node = ps.instantiate()
	root.name = "Wing%d" % w
	for nm in SOLO:
		var n := root.get_node_or_null(nm)
		if n:
			root.remove_child(n)
			n.free()
	# the lightmap goes on last, once every mesh is in the tree
	var lm = root.get_node_or_null("LightmapGI")
	if lm:
		lm.light_data = null
	# the nodes enter the tree a batch per frame: the big groups are emptied here and refilled
	var queue := []
	for gname in ["Static", "Dynamic"]:
		var g := root.get_node_or_null(gname)
		if g:
			for c in g.get_children():
				c.owner = null
				g.remove_child(c)
				queue.append([g, c])
	nb[w].root = root
	nb[w].queue = queue
	_hide_standin(root, w, home_wing)
	_dedupe(root, w, home, home_wing)
	nb[w].state = "enter"
	nb[w].t0 = Time.get_ticks_msec()
	stats[w]["inst_ms"] = Time.get_ticks_msec() - t
	stats[w]["enter_max_ms"] = 0
	get_tree().root.add_child(root)

func _step_enter(w: int) -> void:
	var t := Time.get_ticks_msec()
	var q: Array = nb[w].queue
	var n := int(_num("nodes_per_frame", 24.0) * _scale)
	while n > 0 and not q.is_empty():
		var e: Array = q.pop_back()
		e[0].add_child(e[1])
		n -= 1
	if q.is_empty():
		var root: Node = nb[w].root
		var mode := _mode()
		load("res://scripts/time_of_day.gd").apply(root, mode)
		var rt = home.get_node_or_null("Runtime")
		if rt and rt.has_method("adopt"):
			rt.adopt(root)
		nb[w].state = "in"
		stats[w]["enter_ms"] = Time.get_ticks_msec() - int(nb[w].t0)
		_open_border(w)
		print("wing_stream: wing %d is in %s" % [w, JSON.stringify(stats[w])])
		_js_state()
	stats[w]["enter_max_ms"] = maxi(int(stats[w].get("enter_max_ms", 0)), Time.get_ticks_msec() - t)

func _mode() -> String:
	var rt = home.get_node_or_null("Runtime") if home else null
	return str(rt.mode) if rt and "mode" in rt and _started_light(rt) else "day"

func _started_light(rt) -> bool:
	return rt.get("_env_base") != null or str(rt.mode) != "night" or not _day_only()

func _day_only() -> bool:
	var j = JSON.parse_string(FileAccess.get_file_as_string("res://scripts/lighting.json")) if FileAccess.file_exists("res://scripts/lighting.json") else null
	return j is Dictionary and bool(j.get("day_only", false))

# ------------------------------------------------------------------ 4: the swap at the border
## The zones (halls and courts) that belong to mall wing w.
func _own_zone(zone: String, w: int) -> bool:
	var w2: Array = cfg.get("wing2_zones", [])
	return (zone in w2) == (w == 2)

func _zone_ids() -> Array:
	if not has_meta("zones"):
		var ids := []
		var lay = JSON.parse_string(FileAccess.get_file_as_string("res://layout_mall.json")) if FileAccess.file_exists("res://layout_mall.json") else null
		if lay is Dictionary:
			for z in lay.get("zones", []):
				ids.append(str(z.get("id", "")))
		set_meta("zones", ids)
	return get_meta("zones")

## In the scene `root` of wing w: hide its copy of wing `other`'s halls and courts (meshes named by
## zone, and their floors) and its pictures of that wing's storefronts (the surfaces of the
## "dyn_standin" mesh with material standin_w<other>). Remembered, so unload() can show them again.
func _hide_standin(root: Node, w: int, other: int) -> void:
	var list: Array = _hidden.get(w, [])
	var zones := _zone_ids()
	for c in _group_nodes(root):
		var nm := str(c.name)
		var z := nm.trim_suffix("_fl")
		if z in zones and _own_zone(z, other) and not _own_zone(z, w):
			if c.visible:
				c.visible = false
				list.append(c)
		elif nm.ends_with("standin") and c.mesh:
			for i in c.mesh.get_surface_count():
				var m = c.mesh.surface_get_material(i)
				if m and m.resource_name == "standin_w%d" % other and c.get_surface_override_material(i) == null:
					c.set_surface_override_material(i, _discard_mat())
					list.append([c, i])
	_hidden[w] = list

func _hid(w: int, what) -> void:
	if not _hidden.has(w):
		_hidden[w] = []
	_hidden[w].append(what)

## A material that draws nothing, for one surface of a mesh that must stay (the other surfaces show).
## Transparent with alpha 0, not a shader that discards: a fragment shader with no output makes WebGL
## raise an error on every draw.
func _discard_mat() -> Material:
	if _discard == null:
		_discard = StandardMaterial3D.new()
		_discard.resource_name = "stream_hidden"
		_discard.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_discard.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_discard.albedo_color = Color(0, 0, 0, 0)
	return _discard

## The meshes of a wing scene's Static and Dynamic groups, in the tree or still queued to enter it.
func _group_nodes(root: Node) -> Array:
	var out := []
	for g in ["Static", "Dynamic"]:
		var st := root.get_node_or_null(g)
		if st:
			for c in st.get_children() + _queued_for(st):
				if c is MeshInstance3D:
					out.append(c)
	return out

func _surf_counts(m: Mesh) -> Dictionary:
	var d := {}
	for i in m.get_surface_count():
		var mt = m.surface_get_material(i)
		var k: String = mt.resource_name if mt else "-"
		d[k] = int(d.get(k, 0)) + m.surface_get_array_len(i)
	return d

## Which mall wing's floor a point stands over (its walk grid), or 0.
func _owner_of(p: Vector3) -> int:
	for w in [1, 2]:
		if _on_grid(w, p):
			return w
	return 0

## Each wing's build also carries the parts of the whole mall that are not in a zone mesh (the shell
## seen through the skylights, the skylight frames, lanterns, the information desk, leftover floor):
## with two wings in, those are there twice, one on top of the other. Same name, same box, and per
## material the same number of vertices = the same geometry: one copy is hidden (the one whose wing
## the thing does not stand in; home's is kept when it spans both). Labels and reflection probes at
## the same spot likewise. Hidden in `root` (wing w) unless the twin in `other_root` is the stand-in.
func _dedupe(root: Node, w: int, other_root: Node, other: int) -> void:
	var zones := _zone_ids()
	var twins := {}
	for d in _group_nodes(other_root):
		twins[str(d.get_parent().name if d.get_parent() else "") + "/" + str(d.name)] = d
	for c in _group_nodes(root):
		var nm := str(c.name)
		if nm.trim_suffix("_fl") in zones or nm.ends_with("standin") or c.mesh == null:
			continue
		var gname := "Static" if not nm.begins_with("dyn_") else "Dynamic"
		var d = twins.get(gname + "/" + nm)
		if d == null or d.mesh == null:
			continue
		var a: AABB = c.mesh.get_aabb(); var b: AABB = d.mesh.get_aabb()
		if a.position.distance_to(b.position) > 0.3 or a.size.distance_to(b.size) > 0.3:
			continue
		var ca := _surf_counts(c.mesh); var cb := _surf_counts(d.mesh)
		var same := ca.keys().filter(func(k): return cb.has(k) and cb[k] == ca[k])
		if same.size() == ca.size() and ca.size() == cb.size():
			var own := _owner_of(a.get_center()) if a.size.x < 40.0 and a.size.z < 40.0 else other
			if own == w and d.visible:
				d.visible = false
				_hid(other, d)
			elif c.visible:
				c.visible = false
				_hid(w, c)
		else:
			for i in c.mesh.get_surface_count():
				var mt = c.mesh.surface_get_material(i)
				if mt and mt.resource_name in same and c.get_surface_override_material(i) == null:
					c.set_surface_override_material(i, _discard_mat())
					_hid(w, [c, i])
	for c in root.get_children():
		if not (c is Label3D or c is ReflectionProbe):
			continue
		for d in other_root.get_children():
			if d.get_class() == c.get_class() and d.visible and d.position.distance_to(c.position) < 0.1:
				c.visible = false
				_hid(w, c)
				break

func _queued_for(parent: Node) -> Array:
	var out := []
	for w in nb:
		for e in nb[w].get("queue", []):
			if e[0] == parent:
				out.append(e[1])
	return out

func _show_standin(w: int) -> void:
	for e in _hidden.get(w, []):
		if e is Array:
			if is_instance_valid(e[0]):
				e[0].set_surface_override_material(e[1], null)
		elif is_instance_valid(e):
			e.visible = true
	_hidden.erase(w)

## Wing w is in: the home wing drops its stand-in of w, the player may walk both, no prompt.
func _open_border(w: int) -> void:
	_hide_standin(home, home_wing, w)
	var a: Dictionary = wing_info(home_wing)
	var b: Dictionary = wing_info(w)
	if a.is_empty() or b.is_empty():
		return
	var ra: PackedStringArray = PackedStringArray(a.get("walk", []))
	var rb: PackedStringArray = PackedStringArray(b.get("walk", []))
	var rows := PackedStringArray()
	for y in ra.size():
		var s := ra[y]
		if y < rb.size() and rb[y].contains("1"):
			var t := rb[y]
			var o := ""
			for x in s.length():
				o += "1" if s[x] == "1" or (x < t.length() and t[x] == "1") else "0"
			s = o
		rows.append(s)
	player.walk_rows = rows
	player.obstacles = (a.get("static", []) as Array) + (b.get("static", []) as Array)
	player.fx_obstacles = (a.get("fixtures", []) as Array) + (b.get("fixtures", []) as Array)
	if str(nb[w].border.get("kind", "")) == "seam" or int(nb[w].get("was_home", 0)) != 0:
		player.seam = []

## Take a neighbour out again (phones and tablets, far behind): the stand-in comes back.
func unload(w: int) -> void:
	if not nb.has(w):
		return
	var root = nb[w].get("root")
	if root and is_instance_valid(root):
		root.queue_free()
	_hidden.erase(w)
	nb.erase(w)
	held.erase(w)
	_show_standin(home_wing)
	var a: Dictionary = wing_info(home_wing)
	if not a.is_empty() and player and is_instance_valid(player):
		player.walk_rows = PackedStringArray(a.get("walk", []))
		player.obstacles = a.get("static", [])
		player.fx_obstacles = a.get("fixtures", [])
		player.seam = a.get("seam", [])
	print("wing_stream: wing %d unloaded" % w)
	_js_state()

func is_in(w: int) -> bool:
	return enabled and nb.has(w) and str(nb[w].state) == "in"

# ------------------------------------------------------------------ 5: the handoff
## The player now stands in wing w (already in): w becomes the home wing. Everything a page load
## into w would make is made again for w; the two wings' geometry stays as it is.
## at: {x, z, yaw, pitch} to stand somewhere else in w (a jump); empty keeps the player's spot.
func _handoff(w: int, at := {}) -> void:
	var t0 := Time.get_ticks_msec()
	var old_home := home
	var old_wing := home_wing
	var root: Node = nb[w].root
	var op := player
	# what the new Player takes over: the spot and view, the walking finger, the HUD toggles
	var keep := {"x": at.get("x", op.position.x), "z": at.get("z", op.position.z), "yaw": at.get("yaw", op.yaw), "pitch": at.get("pitch", op.pitch)}
	var carry := {}
	for k in ["move_touch", "move_vec", "look_touch", "last_pos", "input_kind", "rmb_run"]:
		if k in op:
			carry[k] = op.get(k)
	var toggles := []
	for b in op.buttons:
		toggles.append(b.button_pressed if b is BaseButton else false)
	var mode := _mode()
	# the old wing's systems go: every node that is not part of its scene file
	for c in old_home.get_children():
		if c.owner == null and not (str(c.name) in ["Env", "Sun"]):
			old_home.remove_child(c)
			c.queue_free()
	for nm in ["Player", "Runtime", "Signs"]:
		var n := old_home.get_node_or_null(nm)
		if n:
			old_home.remove_child(n)
			n.queue_free()
	if old_home.has_meta("directory_ui"):      # scripts/directory_kiosk.gd: its reader was one of those nodes
		old_home.remove_meta("directory_ui")
	# the sky and the sun exist once: they move to the new home
	for nm in ["Env", "Sun"]:
		var n := old_home.get_node_or_null(nm)
		if n:
			n.owner = null
			old_home.remove_child(n)
			root.add_child(n)
			n.owner = root
	# the roles swap: the old home is now a neighbour, w is the scene
	nb[old_wing] = {"state": "in", "root": old_home, "border": {"kind": "seam"}, "was_home": 1}
	nb.erase(w)
	get_tree().current_scene = root
	home = root
	home_wing = w
	Engine.set_meta("mall_xfer", keep)
	Engine.set_meta("mall_handoff", {"carry": carry, "toggles": toggles, "mode": mode})
	# the systems, as tools/build_mall.gd makes them: Player, Runtime, Signs
	var p = load("res://scripts/player.gd").new()
	p.name = "Player"
	root.add_child(p)
	var rt := Node.new()
	rt.set_script(load("res://scripts/mall_runtime.gd"))
	rt.name = "Runtime"
	root.add_child(rt)
	var sg := Node.new()
	sg.set_script(load("res://scripts/signs.gd"))
	sg.name = "Signs"
	root.add_child(sg)
	rt.adopt(old_home)
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.mallStreamHome && window.mallStreamHome(%d)" % w, true)
	stats[w] = stats.get(w, {})
	stats[w]["handoff_ms"] = Time.get_ticks_msec() - t0
	print("wing_stream: handoff %d -> %d in %d ms" % [old_wing, w, Time.get_ticks_msec() - t0])
	_busy = false
	_js_state()

## scripts/player.gd _go_to_wing: wing w is in, so stand there now instead of loading its file.
func go(w: int, x: float, z: float, yaw: float, pitch: float) -> bool:
	if not is_in(w) or _busy:
		return false
	_busy = true
	_handoff.call_deferred(w, {"x": x, "z": z, "yaw": yaw, "pitch": pitch})
	return true

## For tools/qa: window.__mallStreamState = {home, wings: {w: state}, stats}
func _js_state() -> void:
	if not OS.has_feature("web"):
		return
	var st := {}
	for w in nb:
		st[str(w)] = str(nb[w].state)
	JavaScriptBridge.eval("window.__mallStreamState = %s;" % JSON.stringify({"home": home_wing, "wings": st, "stats": stats}), true)
