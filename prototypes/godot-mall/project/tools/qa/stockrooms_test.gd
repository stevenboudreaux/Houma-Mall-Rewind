## Checks the Stockrooms (scripts/stockrooms.gd) natively in Wing 1 and takes pictures:
##   the door open from the start; walking into Woolworth's back corner goes in; the start room;
##   the code reachable on the grid (spawn to the stick); a wrong turn's seam puts you in the real
##   entry; the stick's caption within 2 m; walking into the start room's wall comes back out to
##   Woolworth with the mall, the walk grid and the buttons back.
##   xvfb-run -a godot --path . --rendering-driver opengl3 --script res://tools/qa/stockrooms_test.gd -- --out=/tmp/sr [--stream]
## Prints STOCKROOMS TEST OK, or the failed checks.
extends SceneTree
var out := "/tmp/sr"
var scn: Node
var player: Node3D
var sr: Node
var step := 0
var clock := 0.0
var errors := []
var oks := 0
var shots := []        # [name, pos(grid x, y), yaw deg, pitch deg]
var shot_i := 0
var hud_before := []

func _initialize() -> void:
	var stream := false
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.substr(6)
		elif a == "--stream": stream = true
	# TEST-DEBT: wing streaming (scripts/wing_stream.gd) off by default, as on phones: deterministic,
	# and a software-GL frame of the mall with wing 2 streamed in takes minutes here. --stream keeps
	# it on; wing 2 then arrives while you are inside (finding F1 in
	# production/session-handoff-2026-11-16-TEST-DEBT.md) and "the mall still hidden" can fail.
	Engine.set_meta("mall_stream", stream)
	Engine.set_meta("mall_xfer", {"x": -40.0, "z": 18.0, "yaw": deg_to_rad(-60.0), "pitch": 0.0})
	scn = load("res://wing1.tscn").instantiate()
	root.add_child(scn)
	current_scene = scn
	load("res://scripts/time_of_day.gd").apply(scn, "night")
	player = scn.get_node("Player")

func _check(ok: bool, what: String) -> void:
	printerr(("ok   " if ok else "FAIL ") + what)
	if ok: oks += 1
	else: errors.append(what)

func _shot(name: String) -> void:
	root.get_texture().get_image().save_png("%s-%s.png" % [out, name])

func _done() -> bool:
	printerr("STOCKROOMS TEST OK (%d checks)" % oks if errors.is_empty() else "STOCKROOMS TEST FAILED: " + str(errors))
	return true

func _at(gx: float, gy: float, yaw_deg: float, pitch_deg := 0.0) -> void:
	player.position = sr.ORIGIN + Vector3(gx, 0, gy)
	player.yaw = deg_to_rad(yaw_deg); player.pitch = deg_to_rad(pitch_deg); player._apply_rot()
	sr.prev = player.position

## The HUD's visible flags: each corner button, then the Jump button.
func _hud_state() -> Array:
	var a = []
	for b in player.buttons: a.append(b.visible)
	a.append(player.jump_open_btn.visible if player.jump_open_btn else null)
	return a

## Grid BFS from a to b over walkable cells.
func _reach(a: Vector2i, b: Vector2i) -> bool:
	var rows = sr.rows
	var seen = {a: true}; var q = [a]; var i = 0
	while i < q.size():
		var c = q[i]; i += 1
		if c == b: return true
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var u = c + d
			if seen.has(u) or u.y < 0 or u.y >= rows.size() or u.x < 0 or u.x >= rows[0].length(): continue
			if rows[u.y][u.x] != "1": continue
			seen[u] = true; q.append(u)
	return false

func _process(dt: float) -> bool:
	clock += dt
	if sr == null:
		sr = scn.get_node_or_null("Stockrooms")
		clock = 0.0
		return false
	match step:
		0:
			if clock > 0.5:
				# since Oct 16 2026 the door is open for everyone from the start (stockrooms.gd _ready)
				_check(sr.unlocked and not sr.inside, "the door is open from the start")
				# the HUD as it is in the mall, to compare with on the way out
				hud_before = _hud_state()
				player.position = Vector3(-45.6, 0, 21.55)        # walk into the patch of wall
				step = 3; clock = 0.0
		3:
			if sr.inside and not sr.busy:
				_check(true, "walking into Woolworth's back corner goes in")
				_check(player.map_scale == 1.0 and player.walk_rows.size() > 100, "the maze's walk grid is in use")
				var vis = []
				for c in scn.get_children():
					if c is Node3D and c != sr and c != player and c.visible: vis.append(str(c.name))
				_check(vis.is_empty(), "the mall is hidden (visible: %s)" % str(vis))
				_check(not player.buttons[2].visible, "lighting button hidden")
				_check(player.jump_locked, "Jump locked for a visitor")
				var sp = sr.J.notes.spawn
				var st = sr.J.notes.stick
				_check(_reach(Vector2i(int(sp[0]), int(sp[1])), Vector2i(int(st[0]), int(st[1]))), "the stick can be reached from the start room")
				step = 4; clock = 0.0
				shots = [
					["1-start-room", Vector2(49.5, 197.0), 0.0, 0.0],
					["2-start-door", Vector2(49.5, 193.0), 180.0, -4.0],
					["3-s1-bay", Vector2(49.5, 186.0), 0.0, 0.0],
					["4-s1-bay-west", Vector2(46.0, 171.5), 90.0, 0.0],
					["5-long-corridor", Vector2(26.5, 170.0), 0.0, 0.0],
					["6-s2-ladder", Vector2(131.0, 168.5), -61.0, 12.0],
					["7-s3-rooms", Vector2(229.0, 171.5), -90.0, 0.0],
					["8-code-room", Vector2(243.5, 168.5), 10.0, 0.0],
					["9-stick-room", Vector2(299.5, 55.0), -20.0, -6.0],
					["10-stick-close", Vector2(303.6, 45.7), -35.0, -22.0],
				]
				shot_i = 0
				_at(shots[0][1].x, shots[0][1].y, shots[0][2], shots[0][3])
			elif clock > 6.0:
				_check(false, "did not go in"); return _done()
		4:
			if clock > 0.6:
				_shot(shots[shot_i][0])
				if shots[shot_i][0] == "10-stick-close":
					# TEST-DEBT: since Nov 1 (B+C) the stick is a pick-up item; the action prompt names it
					# and the old caption stays off (stockrooms.gd stick_is_item). Caption only without it.
					if sr.stick_is_item:
						var ia = player.interact
						var said: String = ia.prompt_text.text if ia and ia.prompt.visible else ""
						_check(said == "Pick up Martin Folse's stick" and not sr.caption.visible,
							"the prompt names the stick within reach (\"%s\")" % said)
					else:
						_check(sr.caption.visible, "the caption shows within 2 m of the stick")
				shot_i += 1; clock = 0.0
				if shot_i < shots.size():
					_at(shots[shot_i][1].x, shots[shot_i][1].y, shots[shot_i][2], shots[shot_i][3])
				else:
					# a wrong turn: just south of S1-W's seam, step north across it
					var s = sr.seams[0]
					var r = s.rect
					_at(float(r[0]) + 1.5, float(r[1]) + 0.9, 0.0)
					step = 5
		5:
			if clock > 0.3:
				var before = player.position
				player._try_move(Vector3(0, 0, -0.8))
				step = 6; clock = 0.0
		6:
			if clock > 0.3:
				var s = sr.seams[0]
				var g = player.position - sr.ORIGIN
				var r = s.rect
				var want_y = float(r[1]) + 0.1 + float(s.dy)
				_check(abs(g.x - (float(r[0]) + 1.5 + float(s.dx))) < 0.05 and abs(g.z - want_y) < 0.3,
					"the seam %s moved you into the real entry (%.1f, %.1f)" % [s.name, g.x, g.z])
				_shot("11-after-seam")
				var vis3 = []
				for c in scn.get_children():
					if c is Node3D and c != sr and c != player and c.visible: vis3.append(str(c.name))
				_check(vis3.is_empty(), "the mall still hidden before leaving (visible: %s)" % str(vis3))
				# home: stand in the start room facing the door wall and walk into it
				_at(49.5, 199.3, 180.0)
				step = 7; clock = 0.0
		7:
			if clock > 0.2 and not sr.busy and sr.inside:
				player._try_move(Vector3(0, 0, 0.5))
			if not sr.inside and not sr.busy:
				_check(player.position.distance_to(sr.WOOL_BACK_OUT) < 0.1, "back out in Woolworth")
				_check(player.map_scale == 2.0, "the mall's walk grid is back")
				# TEST-DEBT: the corner buttons are the owner's since Nov 4 (player.gd owner_hud_sync), so a
				# visitor has none in the mall either: "back" means as they were before going in
				var hud_after = _hud_state()
				_check(hud_after == hud_before and not player.jump_locked, "buttons and Jump back as before (%s)" % str(hud_after))
				_shot("12-back-in-woolworth")
				# TEST-DEBT: in again (a second visit in one session hid all but one mall node in the
				# old test's in-out-in run): the mall must be hidden the second time too
				player.position = Vector3(-45.6, 0, 21.55)
				step = 8; clock = 0.0
		8:
			if sr.inside and not sr.busy:
				var vis2 = []
				for c in scn.get_children():
					if c is Node3D and c != sr and c != player and c.visible: vis2.append(str(c.name))
				_check(vis2.is_empty(), "a second visit: the mall is hidden again (visible: %s)" % str(vis2))
				_shot("13-second-visit")
				return _done()
			elif clock > 6.0:
				_check(false, "did not go in a second time"); return _done()
			elif clock > 8.0:
				_check(false, "the start room's wall did not take you home"); return _done()
	return false
