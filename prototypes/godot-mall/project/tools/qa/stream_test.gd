## SEAMLESS (Nov 13 2026, scripts/wing_stream.gd, design/godot-wings.md "Seamless streaming"): the wing 1 <-> wing 2
## border walked natively, headless, 1990s.
##   godot --headless --path . --script res://tools/qa/stream_test.gd [-- --kind=mobile]
## 1. starts in wing 1 beside the seam with streaming on; waits for wing 2 to come in;
## 2. checks: wing 2's scene is in the tree without a second Player / Runtime / Signs / Env / Sun; wing 1's copy of
##    wing 2's halls and its storefront pictures are hidden, and wing 2's of wing 1; the seam prompt is off;
## 3. walks south across the seam (forward held): the player gets past it, and the handoff makes wing 2 the scene,
##    with a new Player there (same spot and facing), wing 2's own systems (the prize counter) and none of wing 1's
##    (the Stockrooms);
## 4. walks back north: handoff to wing 1, the Stockrooms are back, the prize counter gone;
## 5. --kind=mobile: walks far up the east hall: wing 2 is unloaded, wing 1's stand-in and seam are back.
## Prints the streamer's timings and STREAM TEST OK, or the failures.
extends SceneTree

var kind := "desktop"
var scn: Node
var ws
var t := 0.0
var step := 0
var errs := []
var worst_ms := 0
var _last := 0

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--kind="): kind = a.substr(7)
	Engine.set_meta("mall_state_1995", "")
	Engine.set_meta("mall_stream", true)
	Engine.set_meta("mall_stream_kind", kind)
	scn = load("res://wing1.tscn").instantiate()
	root.add_child(scn); current_scene = scn

func _player() -> Node3D:
	return current_scene.get_node_or_null("Player")

func _place(x: float, z: float, yaw_deg: float) -> void:
	var p := _player()
	p.position = Vector3(x, 0, z); p.yaw = deg_to_rad(yaw_deg); p.pitch = 0.0; p._apply_rot()

func _fail(s: String) -> void:
	errs.append(s); print("FAIL ", s)

func _visible_named(r: Node, names: Array) -> Array:
	var out := []
	var st := r.get_node_or_null("Static")
	if st:
		for c in st.get_children():
			if (str(c.name).trim_suffix("_fl") in names) and c.visible:
				out.append(str(c.name))
	return out

func _process(dt: float) -> bool:
	t += dt
	var now := Time.get_ticks_msec()
	if _last != 0 and step >= 1:
		worst_ms = maxi(worst_ms, now - _last)
	_last = now
	ws = root.get_node_or_null("WingStream")
	match step:
		0:
			if t > 1.0:
				_place(-9.0, 40.0, 180.0)     # the east hall, 8 m north of the seam, facing south (+z)
				ws.cfg["start_delay_s"] = 0.0
				ws.cfg["near_m"] = 60
				ws.cfg["far_m"] = {"desktop": 100000, "mobile": 70}
				step = 1; t = 0.0
		1:
			if ws.is_in(2):
				print("wing 2 in after %.1f s: %s" % [t, JSON.stringify(ws.stats.get(2, {}))])
				var w2: Node = ws.nb[2].root
				for nm in ["Player", "Runtime", "Signs", "Env", "Sun"]:
					if w2.get_node_or_null(nm): _fail("wing 2 still has its own " + nm)
				var z2: Array = ws.cfg.wing2_zones
				var z1: Array = ws._zone_ids().filter(func(z): return not (z in z2))
				var v := _visible_named(scn, z2)
				if not v.is_empty(): _fail("wing 1 still shows its copy of wing 2's zones: %s" % [v])
				v = _visible_named(w2, z1)
				if not v.is_empty(): _fail("wing 2 still shows its copy of wing 1's zones: %s" % [v])
				if _visible_named(w2, z2).is_empty(): _fail("wing 2's own halls are not visible")
				if not _player().seam.is_empty(): _fail("the seam prompt is still on")
				if w2.get_node("LightmapGI").light_data == null: print("note: wing 2 has no lightmap here (unbaked run)")
				if not _player()._free(-9.0, 52.0): _fail("the floor past the seam is not walkable")
				Input.action_press("ui_up"); step = 2; t = 0.0
			elif t > 120.0 or (ws.nb.has(2) and str(ws.nb[2].state) == "failed"):
				_fail("wing 2 did not come in"); step = 99
		2:
			if int(current_scene.get_meta("wing", 0)) == 2 and _player() != null:
				var p := _player()
				print("handoff 1 -> 2 at z=%.2f, %s ms" % [p.position.z, ws.stats.get(2, {}).get("handoff_ms", "?")])
				if p.position.z < 48.0: _fail("the player is not past the seam after the handoff (z %.2f)" % p.position.z)
				if absf(p.position.x + 9.0) > 0.5: _fail("the player moved sideways in the handoff (x %.2f)" % p.position.x)
				if int(p.wing) != 2: _fail("the new Player's wing is %d" % int(p.wing))
				step = 3; t = 0.0
			elif t > 15.0:
				_fail("no handoff after 15 s walking south (z %.2f)" % (_player().position.z if _player() else -1.0)); step = 99
		3:
			if t > 1.5:    # the deferred systems have been added
				Input.action_release("ui_up")
				if current_scene.get_node_or_null("Prizes") == null: _fail("wing 2 has no prize counter after the handoff")
				if scn.get_node_or_null("Stockrooms") != null: _fail("wing 1's Stockrooms survived the handoff")
				if scn.get_node_or_null("Player") != null: _fail("wing 1 still has a Player")
				if root.find_children("Player", "", false, false).size() > 0: _fail("a Player sits under /root")
				if current_scene.get_node_or_null("Env") == null: _fail("the sky (Env) did not move to wing 2")
				if not ws.is_in(1): _fail("wing 1 is not kept in as the neighbour")
				_place(-9.0, 52.0, 0.0)       # facing north (-z), back toward wing 1
				Input.action_press("ui_up"); step = 4; t = 0.0
		4:
			if int(current_scene.get_meta("wing", 0)) == 1 and _player() != null:
				print("handoff 2 -> 1 at z=%.2f, %s ms" % [_player().position.z, ws.stats.get(1, {}).get("handoff_ms", "?")])
				step = 5; t = 0.0
			elif t > 15.0:
				_fail("no handoff back after 15 s walking north"); step = 99
		5:
			if t > 1.5:
				Input.action_release("ui_up")
				if current_scene.get_node_or_null("Stockrooms") == null: _fail("wing 1 has no Stockrooms after the handoff back")
				if ws.nb[2].root.get_node_or_null("Prizes") != null: _fail("wing 2's prize counter survived the handoff back")
				if kind == "mobile":
					_place(-9.0, -40.0, 0.0)   # far up the east hall
					step = 6; t = 0.0
				else:
					step = 99
		6:
			if not ws.nb.has(2):
				var v := _visible_named(current_scene, ws.cfg.wing2_zones)
				if v.is_empty(): _fail("wing 1's stand-in of wing 2 did not come back after the unload")
				if _player().seam.size() < 3: _fail("the seam did not come back after the unload")
				if _player()._free(-9.0, 52.0): _fail("the floor past the seam is still walkable after the unload")
				step = 99
			elif t > 5.0:
				_fail("wing 2 was not unloaded 80 m from the seam"); step = 99
		99:
			Input.action_release("ui_up")
			print("worst frame while streaming: %d ms" % worst_ms)
			print("STREAM TEST OK (%s)" % kind if errs.is_empty() else "STREAM TEST FAILED (%s): %d" % [kind, errs.size()])
			return true
	return false
