## TEST-DEBT (Nov 16 2026): the Rougarou in Woolworth's aisles after the Demo 54 layout (Woolworth
## front and lunch counter), natively in Wing 1 at night. Story stage 3 (scripts/rougarou_ai.gd):
## it lurks at the back, ducks out of sight, and after a close look (or three ducks) walks to the
## back corner and through the wall (the Stockrooms door). Checks:
##   the aisles: every lurk spot in the back half is on free floor and joined to the store's front
##     on free floor (the player can walk to it, it can come to the player);
##   every lurk spot has a route to the back corner (its exit walk is not a straight line through
##     shelves);
##   live: the player walks in along free floor; it ducks (each run ends, never stuck >6 s), it
##     stays on free floor while running, the exit walk reaches the corner, it steps into the wall,
##     the route ends (stage 0) and the Stockrooms door is open.
## The game no longer makes the Rougarou (the Runner replaced it, Oct 16): this suite makes it
## itself (tools/qa/rg_spawn.gd). A pass says the kept code works on today's Woolworth, not that
## players meet it.
##   xvfb-run -a godot --path . --rendering-driver opengl3 --script res://tools/qa/rougarou_woolworth_test.gd -- --out=/tmp/rw
## Prints WOOLWORTH RG TEST OK, or the failed checks. Screenshots at each beat.
extends SceneTree
const RgSpawn = preload("res://tools/qa/rg_spawn.gd")
const ENTRY := Vector3(-13.0, 0, 4.0)     # just inside Woolworth's front (WOOL is x -45..-11, z -13..21)
var out := "/tmp/rw"
var scn: Node
var player: Node3D
var ai: Node
var fig: Node3D
var sr: Node
var step := 0
var clock := 0.0
var errors := []
var oks := 0
var route := []            # the player's walk, tile centres
var route_t := 0.0
var off_floor := 0         # frames the running figure stood on blocked floor
var run_frames := 0
var state_t := 0.0
var last_state := ""
var max_run_s := 0.0
var shots_done := {}
var ducks_seen := 0
var stall := 0.0
var snaps := 0
var tick := 0.0
var t0 := 0

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.substr(6)
	if Engine.has_meta("mall_rg"): Engine.remove_meta("mall_rg")
	# Woolworth is all in wing 1: no wing streaming (a software-GL frame with wing 2 in takes minutes)
	Engine.set_meta("mall_stream", false)
	Engine.set_meta("mall_xfer", {"x": ENTRY.x, "z": ENTRY.z, "yaw": deg_to_rad(90.0), "pitch": 0.0})
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
	if shots_done.has(name): return
	shots_done[name] = true
	root.get_texture().get_image().save_png("%s-%s.png" % [out, name])
	printerr("wrote ", name)

func _done() -> bool:
	printerr("WOOLWORTH RG TEST OK (%d checks)" % oks if errors.is_empty() else "WOOLWORTH RG TEST FAILED: " + str(errors))
	return true

func _face(p: Vector3) -> void:
	var d = p - player.position
	player.yaw = atan2(-d.x, -d.z); player.pitch = deg_to_rad(-3.0); player._apply_rot()

## Free floor: the tile centre is free for the player (walk grid, obstacles, fixtures).
func _free_t(t: Vector2i) -> bool:
	var c = ai._centre(t.x, t.y)
	return ai.WOOL.grow(1.1).has_point(Vector2(c.x, c.z)) and player._free(c.x, c.z)

## BFS over free tiles from a to b (Woolworth only). [] if there is no way; else tile centres.
func _path(a: Vector2i, b: Vector2i, goal_free := true) -> Array:
	var prev = {a: null}; var q = [a]; var i = 0
	while i < q.size():
		var t = q[i]; i += 1
		if t == b: break
		for nb in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var u = t + nb
			if prev.has(u): continue
			if not _free_t(u) and not (u == b and not goal_free): continue
			prev[u] = t; q.append(u)
	if not prev.has(b): return []
	var p = []; var t = b
	while t != null:
		p.push_front(ai._centre(t.x, t.y)); t = prev[t]
	return p

## The player walks along free floor toward the figure (route re-found each second).
func _walk_to_fig(dt: float) -> void:
	_face(fig.position)
	route_t -= dt
	if route_t <= 0.0 or route.is_empty():
		route_t = 1.0
		route = _path(ai._tile(player.position), ai._tile(fig.position))
		if not route.is_empty(): route.pop_front()
	if route.is_empty(): return
	var tgt: Vector3 = route[0]
	var to = tgt - player.position; to.y = 0
	if to.length() < 0.3:
		route.pop_front(); return
	var s = to.normalized() * min(to.length(), 4.0 * dt)
	var before = player.position
	player._try_move(s)
	if player.position == before:
		player._try_move(Vector3(s.x, 0, 0)); player._try_move(Vector3(0, 0, s.z))
	# the harness's walk can snag on a shelf end between two free tile centres: after 1.5 s without
	# progress it steps onto the next centre (counted; the game's own walk is not under test here)
	if player.position.distance_to(before) > 0.001: stall = 0.0
	else:
		stall += dt
		if stall > 1.5:
			player.position = tgt; stall = 0.0; snaps += 1

func _process(dt: float) -> bool:
	clock += dt
	if ai == null:
		sr = scn.get_node_or_null("Stockrooms")
		if sr == null:
			if clock > 60.0:
				_check(false, "the wing did not finish loading in 60 s"); return _done()
			return false
		printerr("the game made a RougarouAI itself: ", RgSpawn.game_made_one(scn))
		ai = RgSpawn.spawn(scn, player, "s3")
		t0 = Time.get_ticks_msec()
		fig = ai.fig
		clock = 0.0
		return false
	tick += dt
	if tick > 5.0:
		tick = 0.0
		printerr("t %.0f s game, %.0f s real: step %d, %s, ducks %d, d %.1f, snaps %d" % [clock, (Time.get_ticks_msec() - t0) / 1000.0, step, ai.state, ai.ducks, ai._dist(), snaps])
	# watch every frame while it moves: on free floor (the wall step excepted), and never stuck
	if ai.state == last_state: state_t += dt
	else:
		if last_state in ["dart", "exit_walk", "gone_run"]: max_run_s = max(max_run_s, state_t)
		last_state = ai.state; state_t = 0.0
	if ai.state in ["dart", "exit_walk", "gone_run"]:
		run_frames += 1
		if not player._free(fig.position.x, fig.position.z) and not ai._walk(fig.position.x, fig.position.z):
			off_floor += 1
		if state_t > 6.0:
			_check(false, "stuck in %s for 6 s at %s (path %d)" % [ai.state, str(fig.position), ai.path.size()])
			return _done()
	match step:
		0:
			if clock > 0.5:
				_check(ai.stage == 3 and ai.state == "lurk" and fig.visible, "stage 3: lurking in Woolworth (stage %d, %s)" % [ai.stage, ai.state])
				_check(ai.WOOL_BACK.has_point(Vector2(fig.position.x, fig.position.z)) and player._free(fig.position.x, fig.position.z),
					"at the back, on free floor %s" % str(fig.position))
				printerr("woolworth: %d shelf rects for its line of sight, %d fixture obstacles in the store" % [ai.wool_obs.size(), _fx_in_wool()])
				# the aisles: every lurk spot joined to the front on free floor, and to the corner
				var spots = ai._wool_spots(ai.WOOL_BACK)
				var entry_t = ai._tile(player.position)
				_check(_free_t(entry_t), "the player stands on free floor at the front %s" % str(player.position))
				var cut = []; var no_exit = []
				var goal = ai._tile(Vector3(-45.0, 0, 21.0))
				for c in spots:
					var t = ai._tile(c)
					if _path(entry_t, t).is_empty(): cut.append(c)
					if _path(t, goal, false).is_empty(): no_exit.append(c)
				_check(spots.size() >= 10, "%d lurk spots in the back half" % spots.size())
				_check(cut.is_empty(), "every lurk spot joined to the front on free floor (cut off: %s)" % str(cut))
				_check(no_exit.is_empty(), "every lurk spot has a route to the back corner (none: %s)" % str(no_exit))
				_face(fig.position)
				step = 1; clock = 0.0
		1:
			if clock > 0.6:
				_shot("1-lurk")
				step = 2; clock = 0.0
		2:
			# walk in after it: it ducks, then walks off to the corner
			_walk_to_fig(dt)
			if ai.state == "dart" and ai.ducks > ducks_seen:
				ducks_seen = ai.ducks
				if ducks_seen == 1: _shot("2-duck")
			if ai.state == "exit_walk":
				_check(true, "the exit walk starts after %d ducks (%.0f s)" % [ai.ducks, clock])
				_shot("3-exit-walk")
				step = 3; clock = 0.0
			elif ai.stage != 3:
				_check(false, "left stage 3 without the exit walk (stage %d, %s)" % [ai.stage, ai.state]); return _done()
			elif clock > 120.0:
				_check(false, "no exit walk within 120 s (%s, %d ducks)" % [ai.state, ai.ducks]); return _done()
		3:
			_walk_to_fig(dt)
			if ai.state == "wall_wait":
				var d = fig.position.distance_to(ai.WOOL_EXIT[0])
				_check(d < 1.0, "it reaches the back corner (%.2f m off)" % d)
				_face(fig.position)
				step = 4; clock = 0.0
			elif clock > 30.0:
				_check(false, "the exit walk did not reach the corner in 30 s (at %s)" % str(fig.position)); return _done()
		4:
			_face(fig.position)
			if clock > 0.3: _shot("4-wall-wait")
			if ai.state == "wall_go":
				_shot("5-into-the-wall")
			if ai.stage == 0:
				_check(not fig.visible, "through the wall and gone")
				_check(sr.unlocked, "the Stockrooms door is open")
				_check(run_frames > 0 and off_floor * 20 <= run_frames, "on free floor while running (%d of %d frames off)" % [off_floor, run_frames])
				_check(max_run_s <= 6.0, "every run ended (longest %.1f s)" % max_run_s)
				printerr("the harness's walk snapped past a snag %d times" % snaps)
				_shot("6-after")
				return _done()
			elif clock > 10.0:
				_check(false, "did not go through the wall in 10 s (%s)" % ai.state); return _done()
	return false

func _fx_in_wool() -> int:
	var n = 0
	for o in player.fx_obstacles:
		if o.size() == 5 and o[0] is String and o[0] == "rect":
			if Rect2(o[1], o[2], o[3] - o[1], o[4] - o[2]).intersects(ai.WOOL): n += 1
		elif o.size() == 3 and not (o[0] is String):
			if ai.WOOL.has_point(Vector2(o[0], o[1])): n += 1
	return n
