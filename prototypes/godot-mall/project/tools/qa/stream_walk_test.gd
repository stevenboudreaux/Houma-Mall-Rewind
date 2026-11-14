## SEAMLESS stage 3 (Nov 13 2026, scripts/wing_stream.gd, design/godot-wings.md "Seamless streaming"): every interior
## border walked natively, headless, in one run with no scene change:
##   Dillard's (wing 5) -> the Dillard's court (2) -> the east hall (1) -> Sears / Lynn's (4) -> back to wing 1
##   -> the cinema lobby (6, its gate opened for the test) -> wing 1 -> wing 2 and on to Corn Dog 7.
##   godot --headless --path . --script res://tools/qa/stream_walk_test.gd [-- --year=2026 --kind=mobile --locked]
## --locked: the cinema's gate is left shut: its two legs are skipped and its lobby must never come in.
## Each border is walked for real (forward held from a few metres before the line until the handoff); between
## borders the test places the player a few metres before the next one (the long halls are not walked).
## Checks at every border: the wing beyond is in before the player gets there (the test waits for it at the line and
## fails if it takes too long), no prompt shows, no old crossing starts (player.leaving never true, the scene is only
## ever changed by the streamer), the handoff makes the wing the home wing, the crowd is the same node all the way
## (when there is one), and the wing's own people stand in it before the crossing (1990s wing 2 and wing 1).
## Desktop: every interior wing ends up in. Mobile: far wings are unloaded on the way.
## Prints the streamer's timings and STREAM WALK OK, or the failures.
extends SceneTree

var kind := "desktop"
var year := 1995
var ws
var t := 0.0
var leg := -1
var phase := 0
var errs := []
var worst_ms := 0
var _last := 0
var crowd_id := 0
var legs := []
var seen_max := 1
var old_cross := false
var ready_t := -1.0
var locked := false       # --locked: the cinema's gate stays shut; its lobby must never come in

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--kind="): kind = a.substr(7)
		if a.begins_with("--year="): year = int(a.substr(7))
		if a == "--locked": locked = true
	Engine.set_meta("mall_state_%d" % year, "")
	Engine.set_meta("mall_stream", true)
	Engine.set_meta("mall_stream_kind", kind)
	# the cinema's gate is open for this walk (scripts/cinema_gate.gd reads the same store off the web)
	if not locked:
		Engine.set_meta("mall_flags", {"v": 1, "flags": {"cinema_unlocked": true}})
	# [to wing, x, z before the line, yaw to walk (deg), what it is]
	legs = [
		[2, -4.0, 84.0, 0.0, "Dillard's -> the Dillard's court"],
		[1, -9.0, 52.0, 0.0, "wing 2 -> wing 1 across the seam"],
		[4, -4.0, -92.0, 0.0, "wing 1 -> Sears / Lynn's"],
		[1, -4.0, -99.5, 180.0, "Sears / Lynn's -> wing 1"],
		[6, -60.0, -89.5, 180.0, "wing 1 -> the cinema lobby"],
		[1, -60.0, -83.0, 0.0, "the cinema lobby -> wing 1"],
		[2, -9.0, 44.0, 180.0, "wing 1 -> wing 2 across the seam"],
	]
	if locked:
		legs = legs.filter(func(l): return int(l[0]) != 6 and not str(l[4]).begins_with("the cinema"))
	var path := ("res://wing5_2026.tscn" if year == 2026 else "res://wing5.tscn")
	var scn: Node = load(path).instantiate()
	root.add_child(scn); current_scene = scn

func _player() -> Node3D:
	return current_scene.get_node_or_null("Player") if current_scene else null

func _place(x: float, z: float, yaw_deg: float) -> void:
	var p := _player()
	p.position = Vector3(x, 0, z); p.yaw = deg_to_rad(yaw_deg); p.pitch = 0.0; p._apply_rot()

func _fail(s: String) -> void:
	errs.append(s); print("FAIL ", s)

func _home() -> int:
	return int(ws.home_wing) if ws else 0

func _process(dt: float) -> bool:
	t += dt
	var now := Time.get_ticks_msec()
	if _last != 0 and leg >= 0:
		worst_ms = maxi(worst_ms, now - _last)
	_last = now
	ws = root.get_node_or_null("WingStream")
	var p := _player()
	if ws == null or p == null:
		return false
	if bool(p.leaving) and not old_cross:
		old_cross = true
		_fail("an old crossing (fade and load) started at leg %d" % leg)
	seen_max = maxi(seen_max, ws.span().size())
	if leg == -1:
		if t > 1.0:
			ws.cfg["start_delay_s"] = 0.0
			leg = 0; phase = 0; t = 0.0
		return false
	if leg >= legs.size():
		return _finish()
	var L: Array = legs[leg]
	var to := int(L[0])
	match phase:
		0:
			_place(float(L[1]), float(L[2]), float(L[3]))
			phase = 1; t = 0.0
		1:
			# at the line: the wing beyond must come in (and be peopled) with the player standing here
			if ws.is_in(to) and not ws._span_changed() and ready_t < 0.0:
				ready_t = t      # its people are made a frame or two after the remake
			if ws.is_in(to) and not ws._span_changed() and ready_t >= 0.0 and t - ready_t > 0.7:
				ready_t = -1.0
				if p.prompt and p.prompt.visible: _fail("%s: a prompt shows at the open border" % L[4])
				if year == 1995 and to in [1, 2]:
					var st = p.get_node_or_null("Story")
					var n := 0
					if st:
						for a in st.attendants:
							if is_instance_valid(a) and (a.global_position.z > 48.0) == (to == 2): n += 1   # the seam is z = 48
					if n == 0: _fail("%s: none of wing %d's attendants stand in it before the crossing" % [L[4], to])
				var cr = current_scene.get_node_or_null("Shoppers")
				if cr and not bool(cr.disabled):
					if crowd_id == 0: crowd_id = cr.get_instance_id()
					elif cr.get_instance_id() != crowd_id: _fail("%s: the crowd is a new node" % L[4])
				print("leg %d (%s): wing %d in after %.1f s at the line; in now: %s" % [leg, L[4], to, t, str(ws.span())])
				Input.action_press("ui_up"); phase = 2; t = 0.0
			elif t > 90.0 or ws._state(to) == "failed":
				_fail("%s: wing %d did not come in (state '%s')" % [L[4], to, ws._state(to)]); leg = 99
			elif t > 0.5 and not ws.is_in(to):
				# not in yet: the border must hold and the streamer must own it (the cue, no prompt)
				if not ws.holds(to): _fail("%s: the streamer does not hold the border while wing %d comes in" % [L[4], to])
				if p.prompt and p.prompt.visible and to != 6: _fail("%s: the old prompt shows while wing %d comes in" % [L[4], to])
		2:
			if _home() == to:
				print("  handoff -> %d at (%.1f, %.1f), %s ms" % [to, _player().position.x, _player().position.z, ws.stats.get(to, {}).get("handoff_ms", "?")])
				phase = 3; t = 0.0
			elif t > 20.0:
				_fail("%s: no handoff after 20 s walking (at %.1f, %.1f)" % [L[4], p.position.x, p.position.z]); leg = 99
		3:
			if t > 1.0:
				Input.action_release("ui_up")
				if int(current_scene.get_meta("wing", 0)) != to: _fail("%s: the scene is not wing %d" % [L[4], to])
				if int(_player().wing) != to: _fail("%s: the Player's wing is %d" % [L[4], int(_player().wing)])
				if root.find_children("Player", "", false, false).size() > 0: _fail("a Player sits under /root")
				var players := 0
				for w in ws.span():
					if ws.root_of(w).get_node_or_null("Player"): players += 1
				if players != 1: _fail("%s: %d Players" % [L[4], players])
				leg += 1; phase = 0; t = 0.0
	return false

func _finish() -> bool:
	Input.action_release("ui_up")
	if leg < 99:
		# on to Corn Dog 7 (wing 2): a spot in front of it is walkable and wing 2 is the home wing
		_place(-97.6, 54.5, 180.0)
		if _home() != 2: _fail("the walk did not end in wing 2")
		if not _player()._free(-97.6, 54.5): _fail("the spot in front of Corn Dog 7 is not walkable")
		if locked:
			if ws.nb.has(6): _fail("the cinema lobby came in behind a shut gate")
			if ws.home_wing == 1 and ws.holds(6): _fail("the streamer holds the cinema's border while its gate is shut")
		if kind == "desktop":
			for w in ([1, 2, 4, 5] if locked else [1, 2, 4, 5, 6]):
				if not (w == _home() or ws.is_in(w)): _fail("desktop: wing %d is not in at the end" % w)
		else:
			print("mobile: most wings in at once: %d" % seen_max)
			if seen_max >= 5: _fail("mobile: every interior wing was in at once (nothing was unloaded)")
	print("in at the end: %s; remakes %s; resync max %s ms; worst frame %d ms" % [str(ws.span()), ws.stats.get("remakes", 0), ws.stats.get("resync_max_ms", "?"), worst_ms])
	for w in ws.stats:
		if ws.stats[w] is Dictionary: print("  wing %s: %s" % [w, JSON.stringify(ws.stats[w])])
	print(("STREAM WALK OK (%s, %d)" % [kind, year]) if errs.is_empty() else "STREAM WALK FAILED (%s, %d): %d" % [kind, year, errs.size()])
	return true
