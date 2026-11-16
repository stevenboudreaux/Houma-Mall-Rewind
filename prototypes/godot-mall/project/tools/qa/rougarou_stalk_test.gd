## Checks the Rougarou's stalk mode (scripts/rougarou_ai.gd) natively in Wing 1 at night, from the
## game's default spawn (the main entrance hall, looking west):
##   1. after stalk_first_s (not before) it stands ahead, stalk_m off, in line of sight, inside the view cone;
##   2. the player walks at it: it runs before they get within flee_m, goes out of sight and stays
##      away reappear_s (random), then is back ahead;
##   3. the player turns round: within 3 s it is ahead of them again.
##   xvfb-run -a godot --path . --rendering-driver opengl3 --script res://tools/qa/rougarou_stalk_test.gd -- --fast --out=/tmp/st
## (--fast: the first sighting after 2 s instead of 30; a software-GL wing render runs far slower
## than real time, so the real 30 s wait takes ~25 min here)
## Prints STALK TEST OK, or the failed checks.
## TEST-DEBT (Nov 16 2026): the game stopped making the Rougarou on Oct 16 (the Runner replaced it);
## this suite makes it itself (tools/qa/rg_spawn.gd), so it checks the kept code, not the shipped game.
extends SceneTree
const RgSpawn = preload("res://tools/qa/rg_spawn.gd")
var out := "/tmp/st"
var player: Node3D
var ai: Node
var fig: Node3D
var step := 0
var clock := 0.0
var errors := []
var oks := 0
var min_d := 1e9
var fled := false
var first := 0.0
var fast := false
var tick := 0.0

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.substr(6)
		elif a == "--fast": fast = true      # skip the 30 s wait before the first sighting
	Engine.set_meta("mall_xfer", {"x": 33.0, "z": 0.0, "yaw": deg_to_rad(90.0), "pitch": deg_to_rad(3.0)})
	var scn = load("res://wing1.tscn").instantiate()
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
	printerr("STALK TEST OK (%d checks)" % oks if errors.is_empty() else "STALK TEST FAILED: " + str(errors))
	return true

func _process(dt: float) -> bool:
	clock += dt
	tick += dt
	if tick > 5.0 and ai:
		tick = 0.0
		printerr("t step %d state %s d %.1f clock %.1f" % [step, ai.state, ai._dist(), clock])
	if ai == null:
		# TEST-DEBT: the game no longer makes the Rougarou (tools/qa/rg_spawn.gd); make it here once
		# the wing's own nodes are in (the Player's walk grid is read in its _ready)
		if current_scene.get_node_or_null("Stockrooms") == null:
			if clock > 60.0:
				_check(false, "the wing did not finish loading in 60 s"); return _done()
			return false
		printerr("the game made a RougarouAI itself: ", RgSpawn.game_made_one(current_scene))
		ai = RgSpawn.spawn(current_scene, player, "stalk")
		if ai:
			fig = ai.fig
			first = float(ai.cfg.stalk_first_s)
			if fast:
				first = 2.0; ai.timer = 2.0
			clock = 0.0
		return false
	match step:
		0:
			if fig.visible and ai.state == "keep":
				var d = ai._dist()
				_check(clock >= first - 0.5 and clock < first + 3.0, "first seen %.1f s after spawn (want %.0f)" % [clock, first])
				_check(d >= float(ai.cfg.stalk_m[0]) and d <= float(ai.cfg.stalk_m[1]), "ahead at %.1f m (%s)" % [d, str(fig.position)])
				_check(ai._angle() < 30.0, "inside the view (%.0f°)" % ai._angle())
				_check(ai._los(player.position, fig.position), "in line of sight")
				step = 1; clock = 0.0
			elif clock > first + 5.0:
				_check(false, "not visible %.0f s after spawn" % (first + 5.0)); return _done()
			elif fig.visible:
				_check(false, "visible before %.0f s" % first); return _done()
		1:
			if clock > 0.5:
				_shot("1-spawn")
				step = 2; clock = 0.0
		2:
			# walk straight at it, 5 m/s, through the walk grid like the player does
			if ai.state == "keep" and not fled:
				var to = fig.position - player.position; to.y = 0
				player.yaw = atan2(-to.x, -to.z); player._apply_rot()
				var stp = to.normalized() * 5.0 * dt
				player._try_move(Vector3(stp.x, 0, 0)); player._try_move(Vector3(0, 0, stp.z))
			min_d = min(min_d, ai._dist())
			if ai.state == "run" and not fled:
				fled = true
				_check(ai._dist() > float(ai.cfg.flee_m) - 3.0, "runs at %.1f m" % ai._dist())
				_shot("2-running")
			if fled and ai.state == "hidden":
				_check(not fig.visible, "gone after running (%.1f s)" % clock)
				_check(ai.timer >= float(ai.cfg.reappear_s[0]) and ai.timer <= float(ai.cfg.reappear_s[1]), "stays away %.0f s" % ai.timer)
				_check(min_d > float(ai.cfg.flee_m) - 3.0, "never closer than %.1f m" % min_d)
				_shot("3-after-run")
				ai.timer = 0.3          # skip the wait for the test
				step = 3; clock = 0.0
			elif clock > 25.0:
				_check(false, "no run within 25 s (state %s, d %.1f)" % [ai.state, ai._dist()]); return _done()
		3:
			if clock > 1.0:
				_check(ai.state == "keep" and fig.visible, "back, ahead at %.1f m (%.0f°)" % [ai._dist(), ai._angle()])
				_shot("3b-back")
				player.yaw += PI; player._apply_rot()
				step = 4; clock = 0.0
		4:
			if clock > 3.0:
				# ahead again, or (when the view is too short for its distance) out of sight: never behind
				var ok = (not fig.visible) or ai._angle() < 50.0
				_check(ok, "after turning round: %s" % ("waiting out of sight (short view)" if not fig.visible else "ahead again (%.0f°, %.1f m)" % [ai._angle(), ai._dist()]))
				_shot("4-turned")
				return _done()
	return false
