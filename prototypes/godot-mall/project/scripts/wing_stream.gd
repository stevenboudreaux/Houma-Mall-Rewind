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
##  2. mount: the pack is mounted with replace_files = false (the running wing's copies win; the
##     packs' shared files are byte-identical);
##  3. load: every resource the neighbour's scene names is loaded a few milliseconds per frame, then
##     the scene is instanced without its Player / Runtime / Signs / Env / Sun and its nodes enter
##     the tree a batch per frame; its lightmap is set last;
##  4. swap: every wing that is in hides its copy of the others' halls and its pictures of their
##     storefronts (_resync); the player's walk grid and obstacles become the wings' union;
##  5. handoff: when the player stands on a neighbour's own floor, past the border, that wing becomes
##     the home wing: the player's own nodes and the systems made per wing are remade for it in one
##     frame, exactly as a page load into that wing would make them; every wing's geometry stays
##     where it is. State lives outside the scene already (the old crossing reloaded the page).
##
## Stage 3 (Nov 13 2026): every interior border streams, in both years (data/stream.json "borders": the
## seam 1-2, the thresholds 1-4 Sears / Lynn's, 2-5 Dillard's, 1-6 the cinema once its gate is open),
## and wings chain: a wing next to any wing that is in can come in (one at a time, nearest first).
## Desktop keeps going until the whole interior of the year is in; phones and tablets keep the wing
## you are in plus the ones whose border is near (near_m) and unload the far ones (far_m).
## People and things: a wing's own content (attendants, pick-up items, shop stock) is made for every
## wing that is in (player.has_wing()), by remaking the player's systems when the set of wings
## changes and the player is not in a menu or a conversation; the crowd (scripts/npcs.gd) is one
## node that outlives every remake and walks the union of the wings' floors.
## A neighbour that is not in yet: the border holds (the stand-in pictures and the wall stay) and a
## wordless cue, a soft pulse along the floor line, shows while it loads. Only when the pack could
## not be fetched does the old load happen, by itself, as the player reaches the line.
##
## One of these lives under /root for the whole run (make(); scripts/player.gd attaches each new
## Player to it).
extends Node

const NODE_NAME := "WingStream"
const CFG_PATH := "res://data/stream.json"
## Nodes of a wing scene that exist once for the whole game: taken out of a neighbour.
const SOLO := ["Player", "Runtime", "Signs", "Env", "Sun"]
## The mall wings (they own the halls and courts); the others are room wings.
const MALL := [1, 2]

var cfg := {}
var enabled := false
var kind := "desktop"          # "desktop" or "mobile": which column of the settings applies
var player: Node3D
var home: Node                 # the wing scene the player's systems belong to (current_scene)
var home_wing := 0
var year := 1995
## wing -> {state, root, pending, queue, t0}; state: "fetch", "load", "enter", "in", "failed"
var nb := {}
## wing -> the wing's own wing.json / collide.json (walk grid, obstacles), read once
var info := {}
## Resources held so ResourceLoader's cache keeps them between the load and the instancing (and
## across handoffs): wing -> Array
var held := {}
var _hid_nodes := []           # nodes _resync hid (shown again before each resync)
var _hid_surfs := []           # [mesh instance, surface] given the draws-nothing material
var _trimmed := []             # [mesh instance, its own mesh] where shared triangles were cut out
var _fx_off := {}              # instance id -> true: a wing's "Benches & plants" mesh that is a twin of one shown
var _discard: StandardMaterial3D
var _t_start := 0.0
var _busy := false
var _scale := 1.0
var _peopled := []             # the wings whose own content the player's systems were last made for
var _cue: MeshInstance3D
var _cue_t := 0.0
var _in_remake := false        # attach() is being called by a Player this streamer made
var _was_away := false         # the player was in the Stockrooms (a level built far off) last frame
var _qa := false               # ?qa=1 (tools/qa): the page may place the player (window.__mallTeleport) and reads where it is
var _qa_t := 0.0
## Measurements for tools/qa (and ?debug=1): wing -> {fetch_ms, mount_ms, load_ms, load_max_ms,
## inst_ms, enter_ms, enter_max_ms, handoff_ms}; "remakes": how many times the systems were remade
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
		_qa = str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('qa') || ''")) == "1"
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

## A new Player (the first one, or the one a remake made) says where it stands.
func attach(p: Node3D) -> void:
	if not _in_remake:
		# a Player from a scene load (the start, an old crossing in the editor or a test, the year switch):
		# whatever was streamed in belonged to the scene before
		for w in nb.keys():
			var r = nb[w].get("root")
			_drop_probes(w)
			if r and is_instance_valid(r):
				r.queue_free()
		nb.clear(); held.clear(); info.clear()
		_hid_nodes.clear(); _hid_surfs.clear(); _trimmed.clear(); _fx_off.clear()
		_t_start = Time.get_ticks_msec() / 1000.0
	player = p
	home = p.get_parent()
	home_wing = int(p.wing)
	year = int(p.year)
	if not enabled:
		return
	_peopled = span()
	_resync()
	_apply_grid()
	_js_state()

# ------------------------------------------------------------------ the wings and their borders
## The wings that are in: the home wing, then the neighbours whose scene is whole.
func span() -> Array:
	var out := [home_wing]
	for w in nb:
		if str(nb[w].state) == "in":
			out.append(int(w))
	return out

## Whether wing w's own content is to be made now (scripts/player.gd has_wing).
func spans(w: int) -> bool:
	return enabled and (w == home_wing or is_in(w))

func is_in(w: int) -> bool:
	return enabled and nb.has(w) and str(nb[w].state) == "in"

func _state(w: int) -> String:
	return str(nb[w].state) if nb.has(w) else ""

## The scene of a wing that is in (or coming in), or null.
func root_of(w: int) -> Node:
	if w == home_wing:
		return home
	return nb[w].get("root") if nb.has(w) else null

## The borders that stream in the year on show: [{a, b, kind, gate}]
func _edges() -> Array:
	var out := []
	for b in cfg.get("borders", []):
		if year in (b.get("years", []) as Array).map(func(v): return int(v)):
			out.append(b)
	return out

func _edge(u: int, v: int):
	for e in _edges():
		if (int(e.a) == u and int(e.b) == v) or (int(e.a) == v and int(e.b) == u):
			return e
	return null

## A border's line, from whichever of its two wings' wing.json is readable (its pack is mounted):
## {line [x0, z, x1], wing, toward}: `toward` is the side (+1: +z) on which the other wing lies, seen
## from `wing`. {} when neither is readable.
func _edge_line(e: Dictionary) -> Dictionary:
	for pair in [[int(e.a), int(e.b)], [int(e.b), int(e.a)]]:
		var wj: Dictionary = wing_info(pair[0])
		if wj.is_empty():
			continue
		if str(e.get("kind", "seam")) == "seam":
			var s: Array = wj.get("seam", [])
			if s.size() >= 3:
				return {"line": s, "wing": pair[0], "toward": float(wj.get("other_side", 1.0))}
		else:
			for th in wj.get("thresholds", []):
				if int(th.to) == pair[1]:
					return {"line": th.line, "wing": pair[0], "toward": float(th.side)}
	return {}

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

## Signed distance from the player to a border line, positive on wing u's side of it.
func _side_dist(el: Dictionary, u: int) -> float:
	var t := float(el.toward) if int(el.wing) == u else -float(el.toward)
	return (float(el.line[1]) - player.position.z) * t

## How far the player is from a border line, whichever side.
func _away(ln: Array) -> float:
	var dx := 0.0
	if player.position.x < float(ln[0]): dx = float(ln[0]) - player.position.x
	elif player.position.x > float(ln[2]): dx = player.position.x - float(ln[2])
	return Vector2(dx, float(ln[1]) - player.position.z).length()

## A border a gate holds shut (the cinema doors, scripts/cinema_gate.gd): its wing is not brought in
## and the gate's own prompt stays, until the gate is open.
func _locked(e: Dictionary) -> bool:
	if not bool(e.get("gate", false)):
		return false
	var room := int(e.b) if int(e.b) > 2 else int(e.a)
	if home_wing == room or is_in(room):
		return false
	var any := false
	for g in get_tree().get_nodes_in_group("gate"):
		if g.has_method("locks_threshold"):
			any = true
			if g.locks_threshold(room):
				return true
	return not any     # no gate node yet (the gate's wing is not peopled): shut until one says otherwise

## scripts/player.gd _update_prompt: the border from the home wing to wing `to` is the streamer's (no
## "Enter ..." prompt): it is in, or coming in behind the wordless cue. False when streaming is off,
## the border does not stream, a gate holds it, or its pack could not be fetched (the old prompt).
func holds(to: int) -> bool:
	if not enabled or player == null:
		return false
	var e = _edge(home_wing, to)
	if e == null or _locked(e):
		return false
	return _state(to) != "failed"

func _loading() -> bool:
	for w in nb:
		if str(nb[w].state) in ["fetch", "load", "enter"]:
			return true
	return false

func _process(dt: float) -> void:
	# a slow renderer (a long frame) gets a proportionally bigger share per frame, or the load would
	# take as many frames on a 5 fps device as on a 60 fps one
	_scale = clampf(dt / 0.0167, 1.0, 400.0)
	if not enabled or player == null or not is_instance_valid(player) or _busy:
		return
	if bool(player.get("leaving")):
		return
	if _qa:
		_qa_step(dt)
	# back from the Stockrooms (scripts/stockrooms.gd puts back the walk grid it saved on the way in, which may
	# be from before a wing came in or went): the grid of the wings that are in now
	var away_now := absf(player.position.x) > 1000.0 or absf(player.position.z) > 1000.0
	if _was_away and not away_now:
		_apply_grid()
	_was_away = away_now
	var now := Time.get_ticks_msec() / 1000.0
	var S := span()
	var loading := _loading()
	var best := {}
	var cue := {}
	var waiting := false       # a wing is still to come in (desktop: the rest of the interior)
	for e in _edges():
		var el := _edge_line(e)
		if el.is_empty():
			continue
		var away := _away(el.line)
		for pair in [[int(e.a), int(e.b)], [int(e.b), int(e.a)]]:
			var u: int = pair[0]; var v: int = pair[1]
			if not (u in S) or v in S:
				continue
			var st := _state(v)
			if st == "" and not _locked(e) and away < _num("near_m", 60.0):
				waiting = true
				if not loading and now - _t_start > _num("start_delay_s", 2.0) and (best.is_empty() or away < float(best.d)):
					best = {"v": v, "d": away}
			if u == home_wing and st != "failed" and not _locked(e) and away < _num("cue_m", 14.0) and _side_dist(el, u) > -0.3:
				if cue.is_empty() or away < float(cue.d):
					cue = {"el": el, "d": away}
			if u == home_wing and st == "failed":
				_fallback(el, u, v)
	if not best.is_empty():
		_start(int(best.v))
	_show_cue(cue, dt)
	# the handoff: the player stands on a neighbour's own floor, past the border
	for v in S:
		if v == home_wing:
			continue
		var e = _edge(home_wing, v)
		if e == null:
			continue
		var el := _edge_line(e)
		if not el.is_empty() and _side_dist(el, home_wing) < -_num("handoff_past_m", 1.0) and _stands_in(v):
			_busy = true
			_remake.call_deferred(v)
			return
	# phones and tablets: a neighbour whose every border is far is unloaded
	for v in S:
		if v == home_wing:
			continue
		var near := 1e9
		for e in _edges():
			if int(e.a) != v and int(e.b) != v:
				continue
			var o := int(e.b) if int(e.a) == v else int(e.a)
			var el := _edge_line(e)
			if o in S and not el.is_empty():
				near = minf(near, _away(el.line))
		if near > _num("far_m", 1e9):
			unload(v)
			return
	# people and things follow the wings: remake the player's systems when the set changed
	if _span_changed() and _idle():
		var gone := _peopled.any(func(w): return not (w in S))
		var close := false
		for v in S:
			if v in _peopled:
				continue
			for e in _edges():
				if int(e.a) == v or int(e.b) == v:
					var el := _edge_line(e)
					if not el.is_empty() and _away(el.line) < _num("people_m", 45.0):
						close = true
		if gone or close or not (loading or waiting or not best.is_empty()):
			_busy = true
			_remake.call_deferred(home_wing)
			return
	for w in nb.keys():
		match str(nb[w].state):
			"fetch": _poll_fetch(int(w))
			"load": _step_load(int(w))
			"enter": _step_enter(int(w))
	_sync_fixtures()

func _span_changed() -> bool:
	var S := span()
	if S.size() != _peopled.size():
		return true
	for w in S:
		if not (w in _peopled):
			return true
	return false

## Whether the player's systems can be remade now without taking a screen away from them: not in a
## menu, a conversation, a shop, the prize counter, a book, a time trip (all freeze the player), VR
## or the Stockrooms (a level built far off).
func _idle() -> bool:
	if player == null or not is_instance_valid(player):
		return false
	if bool(player.get("frozen")) or bool(player.get("leaving")) or bool(player.get("vr_on")):
		return false
	return absf(player.position.x) < 1000.0 and absf(player.position.z) < 1000.0

## "Benches & plants" (the player's HUD switch) shows or hides every wing's fixtures; a wing whose
## fixtures mesh is the twin of one already shown stays off.
func _sync_fixtures() -> void:
	var on := bool(player.fixtures_on)
	for w in span():
		var r := root_of(w)
		var fx = r.get_node_or_null("Dynamic/dyn_fixtures") if r else null
		if fx:
			var want: bool = on and not _fx_off.has(fx.get_instance_id())
			if fx.visible != want:
				fx.visible = want

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
func _start(w: int) -> void:
	nb[w] = {"state": "fetch", "t0": Time.get_ticks_msec()}
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

## The pack could not be fetched: the old load, by itself, as the player reaches the line (the same
## spot player.gd _cross() would land on).
func _fallback(el: Dictionary, u: int, v: int) -> void:
	var ln: Array = el.line
	if player.position.x < float(ln[0]) - 0.6 or player.position.x > float(ln[2]) + 0.6:
		return
	var d := _side_dist(el, u)
	if d < -0.2 or d > _num("fallback_m", 1.0):
		return
	var t := float(el.toward) if int(el.wing) == u else -float(el.toward)
	print("wing_stream: wing %d could not be streamed: loading it the old way" % v)
	player._go_to_wing(v, clampf(player.position.x, float(ln[0]) + 0.5, float(ln[2]) - 0.5), float(ln[1]) + t * 1.3, player.yaw, player.pitch)

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
	# the reflection probes go on last too: they are UPDATE_ONCE and take their picture when they enter the
	# tree; entered with the first batch they saw an empty room and the sky (a department store's polished
	# floor then mirrored blue sky instead of its own ceiling)
	var probes := []
	_pull_probes(root, probes)
	nb[w].probes = probes
	nb[w].root = root
	nb[w].queue = queue
	nb[w].state = "enter"
	_resync()      # its copies of what is already here are hidden before they are ever drawn
	nb[w].t0 = Time.get_ticks_msec()
	stats[w]["inst_ms"] = Time.get_ticks_msec() - t
	stats[w]["enter_max_ms"] = 0
	get_tree().root.add_child(root)

## A wing dropped before it was all in: its probes are still out of the tree and would leak.
func _drop_probes(w) -> void:
	if not nb.has(w):
		return
	for pr in nb[w].get("probes", []):
		if is_instance_valid(pr[1]):
			pr[1].free()
	nb[w].erase("probes")

## Take every ReflectionProbe under n out of the tree-to-be: [[parent, probe]], put back by _step_enter.
func _pull_probes(n: Node, out: Array) -> void:
	for c in n.get_children():
		if c is ReflectionProbe:
			c.owner = null
			n.remove_child(c)
			out.append([n, c])
		else:
			_pull_probes(c, out)

func _step_enter(w: int) -> void:
	var t := Time.get_ticks_msec()
	var q: Array = nb[w].queue
	var n := int(_num("nodes_per_frame", 24.0) * _scale)
	while n > 0 and not q.is_empty():
		var e: Array = q.pop_back()
		e[0].add_child(e[1])
		n -= 1
	if q.is_empty() and nb[w].has("settle"):
		# the probes are taking their pictures: the wing stays "coming" (the border holds, its storefront
		# picture still covers the opening) until they have, so nobody sees the floor mirror the sky
		nb[w].settle = int(nb[w].settle) - 1
		if int(nb[w].settle) > 0:
			return
	if q.is_empty():
		var root: Node = nb[w].root
		if not nb[w].has("settle"):
			var mode := _mode()
			load("res://scripts/time_of_day.gd").apply(root, mode)
			var rt = home.get_node_or_null("Runtime")
			if rt and rt.has_method("adopt"):
				rt.adopt(root)
			for pr in nb[w].get("probes", []):
				if is_instance_valid(pr[0]) and is_instance_valid(pr[1]):
					pr[0].add_child(pr[1])
			nb[w].erase("probes")
			# data/stream.json "settle_frames": a room wing (a threshold: Sears, Dillard's, the cinema lobby)
			# waits this many frames for its reflection probes; a mall wing does not (its halls are already
			# in sight across the seam, and the other wing's copy of them must not stay beside the real ones)
			nb[w].settle = 0 if w in MALL else int(_num("settle_frames", 0.0))
			if int(nb[w].settle) > 0:
				stats[w]["enter_max_ms"] = maxi(int(stats[w].get("enter_max_ms", 0)), Time.get_ticks_msec() - t)
				return
		nb[w].erase("settle")
		nb[w].state = "in"
		stats[w]["enter_ms"] = Time.get_ticks_msec() - int(nb[w].t0)
		_resync()
		_apply_grid()
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

# ------------------------------------------------------------------ 4: the swap (who draws what)
## The mall wing a zone (a hall or court) belongs to.
func _zone_owner(zone: String) -> int:
	return 2 if zone in (cfg.get("wing2_zones", []) as Array) else 1

func _zone_ids() -> Array:
	if not has_meta("zones"):
		var ids := []
		var lay = JSON.parse_string(FileAccess.get_file_as_string("res://layout_mall.json")) if FileAccess.file_exists("res://layout_mall.json") else null
		if lay is Dictionary:
			for z in lay.get("zones", []):
				ids.append(str(z.get("id", "")))
		set_meta("zones", ids)
	return get_meta("zones")

## The zone a mesh belongs to by its name ("H5", "H5_fl", "H5_f26s", "dyn_H7_sg26", ...), or "".
func _zone_of(nm: String) -> String:
	var z := nm.trim_prefix("dyn_").get_slice("_", 0)
	return z if z in _zone_ids() else ""

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

func _queued_for(parent: Node) -> Array:
	var out := []
	for w in nb:
		for e in nb[w].get("queue", []):
			if e[0] == parent:
				out.append(e[1])
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
	for w in MALL:
		if _on_grid(w, p):
			return w
	return 0

func _hide(n: Node) -> void:
	if n.visible:
		n.visible = false
		_hid_nodes.append(n)

func _hide_surf(c: MeshInstance3D, i: int) -> void:
	if c.get_surface_override_material(i) == null:
		c.set_surface_override_material(i, _discard_mat())
		_hid_surfs.append([c, i])

## Who draws what, worked out afresh for the wings that are in (and, for its own meshes only, a wing
## that is coming in, so its copies are never drawn on top of what is here).
##
## Every wing's build carries the whole mall: its own zones (halls and courts) for real, the other mall
## wing's zones as a coarse stand-in, pictures of the other wings' storefronts ("dyn_standin", one
## material per wing: standin_w<n>), and the parts of the mall that are in no zone (the shell seen
## through the skylights, skylight frames and glass, lanterns, the information desk, leftover floor,
## labels, reflection probes). With several wings in:
##  - a zone's meshes show in the wing that owns the zone; when that wing is not in, in one wing only
##    (the other mall wing if it is in, else the home wing), as its stand-in;
##  - a wing's storefront pictures show only while that wing is not in, in that same one wing;
##  - a part that is the same in several wings (same name, box and vertices per material) shows once:
##    in the mall wing it stands in if that wing is in and has it, else in the home wing;
##  - a part that is partly the same (the glass: the mall's skylight panes plus each wing's own shop
##    glass) keeps its own triangles and loses the ones an earlier wing already draws.
func _resync() -> void:
	var t_rs := Time.get_ticks_msec()
	_resync_now()
	stats["resync_ms"] = Time.get_ticks_msec() - t_rs
	stats["resync_max_ms"] = maxi(int(stats.get("resync_max_ms", 0)), Time.get_ticks_msec() - t_rs)

func _resync_now() -> void:
	for n in _hid_nodes:
		if is_instance_valid(n):
			n.visible = true
	_hid_nodes.clear()
	for e in _hid_surfs:
		if is_instance_valid(e[0]):
			e[0].set_surface_override_material(e[1], null)
	_hid_surfs.clear()
	for e in _trimmed:
		if is_instance_valid(e[0]):
			e[0].mesh = e[1]
	_trimmed.clear()
	_fx_off.clear()
	if home == null or not is_instance_valid(home):
		return
	var S := span()
	var coming := []
	for w in nb:
		if str(nb[w].state) == "enter":
			coming.append(int(w))
	if S.size() + coming.size() < 2:
		return
	# home first, then the mall wings, then the rooms: the order in which a shared part is kept
	var order := [home_wing]
	for w in MALL + S + coming:
		if not (w in order) and (w in S or w in coming):
			order.append(w)
	var groups := {}            # "Static/misc" -> [[wing, mesh instance], ...] in `order`
	for w in order:
		var root := root_of(w)
		if root == null or not is_instance_valid(root):
			continue
		var here: Array = S if w in S else S + [w]       # a wing coming in sees itself as in
		for c in _group_nodes(root):
			var nm := str(c.name)
			var z := _zone_of(nm)
			if z != "":
				var o := _zone_owner(z)
				if o != w and (o in here or w != _shower(o, here)):
					_hide(c)
				continue
			if nm.ends_with("standin"):
				if c.mesh:
					for i in c.mesh.get_surface_count():
						var m = c.mesh.surface_get_material(i)
						var mn: String = m.resource_name if m else ""
						if mn.begins_with("standin_w"):
							var o := int(mn.trim_prefix("standin_w"))
							if o in here or (o in MALL and w != _shower(o, here)):
								_hide_surf(c, i)
				continue
			if c.mesh == null:
				continue
			var key := ("Dynamic/" if nm.begins_with("dyn_") else "Static/") + nm
			if not groups.has(key):
				groups[key] = []
			groups[key].append([w, c])
		# a wing's own extra hides (data/stream.json "hide": a mesh that only makes sense without wing `when`)
		for h in cfg.get("hide", []):
			if int(h.get("in", 0)) == w and int(h.get("when", 0)) in S:
				for nm in h.get("nodes", []):
					for g in ["Static/", "Dynamic/"]:
						var n = root.get_node_or_null(g + str(nm))
						if n:
							_hide(n)
	var trim: Array = cfg.get("trim", ["dyn_glass"])
	for key in groups:
		var list: Array = groups[key]
		if list.size() < 2:
			continue
		var first: MeshInstance3D = list[0][1]
		var a: AABB = first.mesh.get_aabb()
		var ca := _surf_counts(first.mesh)
		var whole := true
		for i in range(1, list.size()):
			var b: AABB = list[i][1].mesh.get_aabb()
			var cb := _surf_counts(list[i][1].mesh)
			if a.position.distance_to(b.position) > 0.3 or a.size.distance_to(b.size) > 0.3 or ca != cb:
				whole = false
		if whole:
			# the same thing in every wing: one copy shows
			var keep := 0
			if a.size.x < 40.0 and a.size.z < 40.0:
				var own := _owner_of(a.get_center())
				for i in list.size():
					if int(list[i][0]) == own and own in S:
						keep = i
			for i in list.size():
				if i == keep:
					continue
				if str(list[i][1].name) == "dyn_fixtures":
					_fx_off[list[i][1].get_instance_id()] = true
					list[i][1].visible = false
				else:
					_hide(list[i][1])
			continue
		# partly the same: each later copy drops what an earlier one already draws
		var seen := {}          # material -> {vertex count -> true} of the earlier copies' surfaces
		var tris := {}          # material -> {triangle key -> true}, only for the meshes that are trimmed
		var do_trim: bool = str(first.name) in trim
		for i in list.size():
			var c: MeshInstance3D = list[i][1]
			var cut := {}
			for si in c.mesh.get_surface_count():
				var mt = c.mesh.surface_get_material(si)
				var k: String = mt.resource_name if mt else "-"
				var n: int = c.mesh.surface_get_array_len(si)
				if i > 0 and seen.has(k) and seen[k].has(n):
					_hide_surf(c, si)
				elif do_trim:
					if i > 0 and tris.has(k):
						cut[si] = tris[k]
					if not tris.has(k):
						tris[k] = {}
				if not seen.has(k):
					seen[k] = {}
				seen[k][n] = true
			if do_trim:
				var t_tr := Time.get_ticks_msec()
				var own_mesh: Mesh = c.mesh
				if not cut.is_empty():
					_trim(c, cut)
				if i < list.size() - 1:
					for si in own_mesh.get_surface_count():
						var mt = own_mesh.surface_get_material(si)
						var k: String = mt.resource_name if mt else "-"
						if tris.has(k):
							_tri_keys(own_mesh, si, tris[k])
				stats["trim_ms"] = int(stats.get("trim_ms", 0)) + Time.get_ticks_msec() - t_tr
	# labels and reflection probes at the same spot: one of each
	var spots := []
	for w in order:
		var root := root_of(w)
		if root == null or not is_instance_valid(root):
			continue
		for c in root.get_children():
			if not (c is Label3D or c is ReflectionProbe) or not c.visible:
				continue
			var dup := false
			for d in spots:
				if d.get_class() == c.get_class() and d.position.distance_to(c.position) < 0.1:
					dup = true
					break
			if dup:
				_hide(c)
			else:
				spots.append(c)

## The one wing that shows mall wing o's zones and storefront pictures while o itself is not in: the
## other mall wing if it is in, else the home wing.
func _shower(o: int, here: Array) -> int:
	var other := 3 - o
	return other if other in here else home_wing

## The triangles of one surface, as keys (see _tri_key), added to `into`.
func _tri_keys(m: Mesh, si: int, into: Dictionary) -> void:
	var arr := m.surface_get_arrays(si)
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var idx = arr[Mesh.ARRAY_INDEX]
	var has_idx: bool = idx != null and idx.size() > 0
	var n: int = idx.size() if has_idx else v.size()
	for t in range(0, n - 2, 3):
		var a: Vector3 = v[idx[t]] if has_idx else v[t]
		var b: Vector3 = v[idx[t + 1]] if has_idx else v[t + 1]
		var c: Vector3 = v[idx[t + 2]] if has_idx else v[t + 2]
		into[_tri_key(a, b, c)] = true

## A triangle as a number: its centre to 2 cm and the sum of its squared sides.
func _tri_key(a: Vector3, b: Vector3, c: Vector3) -> int:
	var s := (a + b + c) * (50.0 / 3.0)
	var e := (a - b).length_squared() + (b - c).length_squared() + (c - a).length_squared()
	return hash(Vector4i(int(round(s.x)), int(round(s.y)), int(round(s.z)), int(round(e * 100.0))))

## Cut out of mesh instance c the triangles another wing already draws: cut = {surface -> keys}. The
## instance gets a copy of its mesh with those surfaces re-indexed; its own mesh is put back by the
## next _resync.
func _trim(c: MeshInstance3D, cut: Dictionary) -> void:
	var src: Mesh = c.mesh
	var out := ArrayMesh.new()
	var changed := false
	for si in src.get_surface_count():
		var arr := src.surface_get_arrays(si)
		if cut.has(si):
			var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var idx = arr[Mesh.ARRAY_INDEX]
			var has_idx: bool = idx != null and idx.size() > 0
			var n: int = idx.size() if has_idx else v.size()
			var kept := PackedInt32Array()
			for t in range(0, n - 2, 3):
				var i0: int = idx[t] if has_idx else t
				var i1: int = idx[t + 1] if has_idx else t + 1
				var i2: int = idx[t + 2] if has_idx else t + 2
				if not cut[si].has(_tri_key(v[i0], v[i1], v[i2])):
					kept.append(i0); kept.append(i1); kept.append(i2)
			if kept.size() != n:
				changed = true
				print("wing_stream: %s surface %d: %d of %d triangles are another wing's too, cut" % [c.name, si, (n - kept.size()) / 3, n / 3])
			if kept.is_empty():
				# nothing of its own in this surface: one degenerate triangle keeps the surface slot
				kept.append(0); kept.append(0); kept.append(0)
			arr[Mesh.ARRAY_INDEX] = kept
		out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		out.surface_set_material(out.get_surface_count() - 1, src.surface_get_material(si))
	if changed:
		_trimmed.append([c, src])
		c.mesh = out

## The player may walk every wing that is in: the walk grid and obstacles are their union.
func _apply_grid() -> void:
	if player == null or not is_instance_valid(player):
		return
	var a: Dictionary = wing_info(home_wing)
	if a.is_empty():
		return
	if absf(player.position.x) > 1000.0 or absf(player.position.z) > 1000.0:
		return       # in the Stockrooms (their own grid; the wing's comes back when they are left)
	player.walk_rows = _union_rows(span())
	var obs := []
	var fx := []
	for w in span():
		var wj: Dictionary = wing_info(w)
		obs += wj.get("static", []) as Array
		fx += wj.get("fixtures", []) as Array
	player.obstacles = obs
	player.fx_obstacles = fx

func _union_rows(wings: Array) -> PackedStringArray:
	var rows := PackedStringArray(wing_info(home_wing).get("walk", []))
	for w in wings:
		if w == home_wing:
			continue
		var rb := PackedStringArray(wing_info(w).get("walk", []))
		for y in mini(rows.size(), rb.size()):
			if not rb[y].contains("1"):
				continue
			var s := rows[y]; var t := rb[y]
			var o := ""
			for x in s.length():
				o += "1" if s[x] == "1" or (x < t.length() and t[x] == "1") else "0"
			rows[y] = o
	return rows

## The floor the crowd walks (scripts/npcs.gd rebind): every wing that is in, but not a wing listed in
## "no_crowd" (the cinema lobby is one empty room).
func crowd_rows() -> PackedStringArray:
	var skip: Array = (cfg.get("no_crowd", [6]) as Array).map(func(v): return int(v))
	if home_wing in skip:
		return PackedStringArray(wing_info(home_wing).get("walk", []))
	return _union_rows(span().filter(func(w): return not (w in skip)))

## Take a neighbour out again (phones and tablets, far behind), and any wing that was only reachable
## through it: the stand-ins come back.
func unload(w: int) -> void:
	if not nb.has(w):
		return
	var drop := [w]
	# what is still joined to the home wing without w
	var reach := [home_wing]
	var grew := true
	while grew:
		grew = false
		for e in _edges():
			for pair in [[int(e.a), int(e.b)], [int(e.b), int(e.a)]]:
				if pair[0] in reach and not (pair[1] in reach) and pair[1] != w and nb.has(pair[1]):
					reach.append(pair[1]); grew = true
	for v in nb.keys():
		if not (int(v) in reach) and not (int(v) in drop):
			drop.append(int(v))
	for v in drop:
		var root = nb[v].get("root")
		_drop_probes(v)
		if root and is_instance_valid(root):
			root.queue_free()
		nb.erase(v)
		held.erase(v)
		print("wing_stream: wing %d unloaded" % v)
	_resync()
	_apply_grid()
	_js_state()

# ------------------------------------------------------------------ the wordless cue
## A soft pulse along the floor at a border whose wing is still coming in (the border holds until it
## is in). No words.
func _show_cue(cue: Dictionary, dt: float) -> void:
	if cue.is_empty():
		if _cue and is_instance_valid(_cue):
			_cue.visible = false
		return
	if _cue == null or not is_instance_valid(_cue):
		_cue = MeshInstance3D.new()
		_cue.name = "StreamCue"
		var q := PlaneMesh.new()
		q.size = Vector2(1, 1)
		_cue.mesh = q
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.albedo_color = Color(1.0, 0.93, 0.75, 0.0)
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		_cue.material_override = m
		_cue.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(_cue)
	var ln: Array = cue.el.line
	var t := float(cue.el.toward) if int(cue.el.wing) == home_wing else -float(cue.el.toward)
	_cue.visible = true
	_cue.position = Vector3((float(ln[0]) + float(ln[2])) * 0.5, 0.03, float(ln[1]) - t * 0.35)
	_cue.scale = Vector3(absf(float(ln[2]) - float(ln[0])), 1.0, 0.5)
	_cue_t += dt
	var fade := clampf(1.0 - float(cue.d) / _num("cue_m", 14.0), 0.0, 1.0)
	(_cue.material_override as StandardMaterial3D).albedo_color.a = (0.18 + 0.22 * (0.5 + 0.5 * sin(_cue_t * 2.6))) * sqrt(fade)

# ------------------------------------------------------------------ 5: the remake (and the handoff)
## The player's systems are made again, for home wing w: w is the home wing already (the set of wings
## changed: their attendants, items and shop stock are made or dropped), or a neighbour the player
## now stands in (the handoff: w becomes the scene). Everything a page load into w would make is made
## again; every wing's geometry stays as it is; the crowd is the same node before and after.
## at: {x, z, yaw, pitch} to stand somewhere else in w (a jump); empty keeps the player's spot.
func _remake(w: int, at := {}) -> void:
	var t0 := Time.get_ticks_msec()
	var old_home := home
	var old_wing := home_wing
	var move := w != old_wing
	var root: Node = nb[w].root if move else home
	var op := player
	# what the new Player takes over: the spot and view, the walking finger, the HUD toggles
	var keep := {"x": at.get("x", op.position.x), "z": at.get("z", op.position.z), "yaw": at.get("yaw", op.yaw), "pitch": at.get("pitch", op.pitch)}
	var carry := {}
	for k in ["move_touch", "move_vec", "move_origin", "look_touch", "last_pos", "input_kind", "rmb_run", "dragging"]:
		if k in op:
			carry[k] = op.get(k)
	var toggles := []
	for b in op.buttons:
		toggles.append(b.button_pressed if b is BaseButton else false)
	var mode := _mode()
	# the crowd outlives the remake (scripts/npcs.gd): one node, moved to the new home
	var crowd = old_home.get_node_or_null("Shoppers")
	if crowd and (bool(crowd.get("disabled")) or not crowd.has_method("rebind")):
		crowd = null
	# the old systems go: every node that is not part of the scene file
	var stay := ["Env", "Sun"] if move else ["Env", "Sun", "Runtime", "Signs"]
	for c in old_home.get_children():
		if c == crowd:
			continue
		if c.owner == null and not (str(c.name) in stay):
			old_home.remove_child(c)
			c.queue_free()
	for nm in (["Player", "Runtime", "Signs"] if move else ["Player"]):
		var n: Node = old_home.get_node_or_null(str(nm))
		if n:
			old_home.remove_child(n)
			n.queue_free()
	if old_home.has_meta("directory_ui"):      # scripts/directory_kiosk.gd: its reader was one of those nodes
		old_home.remove_meta("directory_ui")
	if move:
		# the sky and the sun exist once: they move to the new home
		for nm in ["Env", "Sun"]:
			var n: Node = old_home.get_node_or_null(str(nm))
			if n:
				n.owner = null
				old_home.remove_child(n)
				root.add_child(n)
				n.owner = root
		if crowd:
			old_home.remove_child(crowd)
			root.add_child(crowd)
		# the roles swap: the old home is now a neighbour, w is the scene
		nb[old_wing] = {"state": "in", "root": old_home}
		nb.erase(w)
		get_tree().current_scene = root
		home = root
		home_wing = w
	if crowd:
		Engine.set_meta("mall_crowd", true)      # scripts/player.gd: do not make another
	Engine.set_meta("mall_xfer", keep)
	Engine.set_meta("mall_handoff", {"carry": carry, "toggles": toggles, "mode": mode})
	# the systems, as tools/build_mall.gd makes them: Player (and, in a new home, Runtime and Signs)
	var p = load("res://scripts/player.gd").new()
	p.name = "Player"
	_in_remake = true
	root.add_child(p)
	_in_remake = false
	if move:
		var rt := Node.new()
		rt.set_script(load("res://scripts/mall_runtime.gd"))
		rt.name = "Runtime"
		root.add_child(rt)
		var sg := Node.new()
		sg.set_script(load("res://scripts/signs.gd"))
		sg.name = "Signs"
		root.add_child(sg)
		for v in nb:
			if str(nb[v].state) == "in":
				rt.adopt(nb[v].root)
		if OS.has_feature("web"):
			JavaScriptBridge.eval("window.mallStreamHome && window.mallStreamHome(%d)" % w, true)
	if Engine.has_meta("mall_crowd"):
		Engine.remove_meta("mall_crowd")
	if crowd:
		crowd.rebind(p, crowd_rows(), _gens())
	stats[w] = stats.get(w, {})
	stats[w]["handoff_ms" if move else "remake_ms"] = Time.get_ticks_msec() - t0
	stats["remakes"] = int(stats.get("remakes", 0)) + 1
	if move:
		print("wing_stream: handoff %d -> %d in %d ms" % [old_wing, w, Time.get_ticks_msec() - t0])
	else:
		print("wing_stream: systems remade for wings %s in %d ms" % [str(span()), Time.get_ticks_msec() - t0])
	_busy = false
	_js_state()

## The gen folders of the wings that are in (scripts/npcs.gd: arcade machines, the shoe court).
func _gens() -> Array:
	return span().map(func(w): return _gen(w))

## scripts/player.gd _go_to_wing: wing w is in, so stand there now instead of loading its file.
func go(w: int, x: float, z: float, yaw: float, pitch: float) -> bool:
	if _busy or not enabled:
		return false
	if w == home_wing:
		return false
	if not is_in(w):
		return false
	_busy = true
	_remake.call_deferred(w, {"x": x, "z": z, "yaw": yaw, "pitch": pitch})
	return true

## ?qa=1 (tools/qa/stream_walk_webtest.py): window.__mallTeleport = [x, z, yaw_deg] places the player once (the
## long halls between borders are not walked by the test; each border is); window.__mallPos = [x, z, home wing,
## cue showing, prompt showing] is refreshed a few times a second.
func _qa_step(dt: float) -> void:
	var tp := str(JavaScriptBridge.eval("(function(){var t=window.__mallTeleport;window.__mallTeleport=null;return t?JSON.stringify(t):''})()", true))
	if tp != "":
		var a = JSON.parse_string(tp)
		if a is Array and a.size() >= 3:
			player.position = Vector3(float(a[0]), 0, float(a[1]))
			player.yaw = deg_to_rad(float(a[2])); player.pitch = 0.0
			player._apply_rot()
	_qa_t += dt
	if _qa_t > 0.25 or tp != "":
		_qa_t = 0.0
		var cue_on: bool = _cue != null and is_instance_valid(_cue) and _cue.visible
		var pr: bool = player.prompt != null and player.prompt.visible
		JavaScriptBridge.eval("window.__mallPos = [%.2f, %.2f, %d, %s, %s];" % [player.position.x, player.position.z, home_wing, str(cue_on).to_lower(), str(pr).to_lower()], true)
		_js_state()

## For tools/qa: window.__mallStreamState = {home, wings: {w: state}, peopled, stats}
func _js_state() -> void:
	if not OS.has_feature("web"):
		return
	var st := {}
	for w in nb:
		st[str(w)] = str(nb[w].state)
	JavaScriptBridge.eval("window.__mallStreamState = %s;" % JSON.stringify({"home": home_wing, "wings": st, "peopled": _peopled, "stats": stats}), true)
