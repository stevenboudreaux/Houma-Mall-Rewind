## UPFRONT (Nov 14 2026, scripts/wing_stream.gd, data/stream.json "upfront", design/godot-wings.md "Everything up
## front"): natively, headless: wing 1 is loaded with the build's own settings for a computer; the streamer must
## hold "the load screen" (its _up_active) until every interior wing of the year is in and peopled, with the cinema
## lobby left out behind its shut gate (--open: the gate is open, the lobby comes in too). Then, with no waiting, the
## player walks (forward held, turned toward waypoints) across the seam, into Dillard's and out, back across the seam,
## into Sears / Lynn's and out: it must never stop within 3 m of a border, no prompt may show there and no old
## crossing may start.
##   godot --headless --path . --script res://tools/qa/stream_upfront_test.gd [-- --year=2026 --open --kind=mobile]
## --kind=mobile: the build's settings for a phone: streaming is off, nothing comes in, the seam prompt is the old one.
## Prints UPFRONT TEST OK, or the failures.
extends SceneTree

var year := 1995
var kind := "desktop"
var gate_open := false
var ws
var t := 0.0
var phase := 0
var errs := []
var path := []
var still := 0.0
var last := Vector3.ZERO
var up_s := -1.0
var homes := []

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--year="): year = int(a.substr(7))
		if a.begins_with("--kind="): kind = a.substr(7)
		if a == "--open": gate_open = true
	Engine.set_meta("mall_state_%d" % year, "")
	Engine.set_meta("mall_stream_kind", kind)       # the settings are the build's own (no mall_stream / mall_upfront)
	if gate_open:
		Engine.set_meta("mall_flags", {"v": 1, "flags": {"cinema_unlocked": true}})
	var scn: Node = load("res://wing1_2026.tscn" if year == 2026 else "res://wing1.tscn").instantiate()
	root.add_child(scn); current_scene = scn
	# straight lines down the halls (the web test finds its way on the walk grid; here the legs are short)
	path = [[-9.0, 30.0], [-9.0, 56.0], [-4.0, 70.0], [-4.0, 88.0], [-4.0, 70.0], [-9.0, 56.0], [-9.0, 40.0],
		[-4.0, -60.0], [-4.0, -88.0], [-4.0, -103.0], [-4.0, -88.0]]

func _player() -> Node3D:
	return current_scene.get_node_or_null("Player") if current_scene else null

func _fail(s: String) -> void:
	if not (s in errs):
		errs.append(s); print("FAIL ", s)

func _process(dt: float) -> bool:
	t += dt
	ws = root.get_node_or_null("WingStream")
	var p := _player()
	if ws == null or p == null:
		return false
	match phase:
		0:
			if kind == "mobile":
				if t > 3.0:
					if ws.enabled: _fail("mobile: streaming is on in the build's settings")
					if not ws.nb.is_empty(): _fail("mobile: a wing was started")
					return _done()
				return false
			if not ws.upfront: _fail("upfront is off for a computer in the build's settings"); return _done()
			if t > 0.2 and not ws._up_active:
				up_s = t
				var want := [1, 2, 4, 5, 6] if gate_open else [1, 2, 4, 5]
				for w in want:
					if not (w == ws.home_wing or ws.is_in(w)): _fail("wing %d is not in when the load screen would lift" % w)
				if not gate_open and ws.nb.has(6): _fail("the cinema lobby came in behind a shut gate")
				if ws._span_changed(): _fail("the wings' people are not made when the load screen would lift")
				print("up front: wings %s in and peopled after %.1f s" % [str(ws.span()), t])
				p.position = Vector3(-9.0, 0, 20.0)      # (the long east hall is not walked natively)
				last = p.position
				Input.action_press("ui_up"); phase = 1; t = 0.0
			elif t > 240.0:
				_fail("the interior was not in after 240 s: %s" % str(ws.nb.keys())); return _done()
		1:
			if not (ws.home_wing in homes): homes.append(int(ws.home_wing))
			if bool(p.leaving): _fail("an old crossing started at (%.1f, %.1f)" % [p.position.x, p.position.z])
			if p.prompt and p.prompt.visible and str(p.prompt_text.text).begins_with("Enter "): _fail("a prompt shows: %s" % p.prompt_text.text)
			while not path.is_empty() and Vector2(float(path[0][0]) - p.position.x, float(path[0][1]) - p.position.z).length() < maxf(1.6, 6.0 * dt):
				path.pop_front()
			if path.is_empty():
				Input.action_release("ui_up")
				for w in [2, 5, 4]:
					if not (w in homes): _fail("the walk never stood in wing %d (homes %s)" % [w, str(homes)])
				return _done()
			p.yaw = atan2(-(float(path[0][0]) - p.position.x), -(float(path[0][1]) - p.position.z)); p._apply_rot()
			if p.position.distance_to(last) > 0.02:
				still = 0.0; last = p.position
			else:
				still += dt
				if still > 1.5:
					_fail("stopped at (%.1f, %.1f) on the way to %s, wings %s" % [p.position.x, p.position.z, str(path[0]), str(ws.span())]); return _done()
			if t > 240.0: _fail("the walk took more than 240 s"); return _done()
	return false

func _done() -> bool:
	Input.action_release("ui_up")
	if ws:
		for w in ws.stats:
			if ws.stats[w] is Dictionary: print("  wing %s: %s" % [w, JSON.stringify(ws.stats[w])])
	print(("UPFRONT TEST OK (%s, %d%s)" % [kind, year, ", gate open" if gate_open else ""]) if errs.is_empty() else "UPFRONT TEST FAILED (%s, %d): %d" % [kind, year, errs.size()])
	return true
