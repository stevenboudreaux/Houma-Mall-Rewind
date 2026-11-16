## Plays the Rougarou's sighting cycle natively and checks it (scripts/rougarou_ai.gd):
## a far sighting in the player's line of sight, the bolt once the player turns and looks, the
## vanish; then a behind-you sighting and its bolt. Writes screenshots at each beat.
##   xvfb-run -a godot --path . --rendering-driver opengl3 --script res://tools/qa/rougarou_test.gd -- --out=/tmp/rgt
## Prints ROUGAROU TEST OK, or the failed check.
## TEST-DEBT (Nov 16 2026): the game stopped making the Rougarou on Oct 16 (the Runner replaced it);
## this suite makes it itself (tools/qa/rg_spawn.gd), so it checks the kept code, not the shipped game.
extends SceneTree
const RgSpawn = preload("res://tools/qa/rg_spawn.gd")
var out := "/tmp/rgt"
var player: Node3D
var ai: Node
var fig: Node3D
var step := 0
var clock := 0.0
var errors := []
var notes := []

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.substr(6)
	Engine.set_meta("mall_xfer", {"x": -4.0, "z": -91.0, "yaw": deg_to_rad(90.0), "pitch": 0.0})
	var scn = load("res://wing1.tscn").instantiate()
	root.add_child(scn)
	current_scene = scn
	load("res://scripts/time_of_day.gd").apply(scn, "night")
	player = scn.get_node("Player")

func _shot(name: String) -> void:
	root.get_texture().get_image().save_png("%s-%s.png" % [out, name])
	print("wrote ", name)

func _check(ok: bool, what: String) -> void:
	if ok: notes.append(what)
	else: errors.append(what)
	print(("ok   " if ok else "FAIL ") + what)

func _face_fig() -> void:
	var d = fig.position - player.position
	player.yaw = atan2(-d.x, -d.z)
	player.pitch = 0.0
	player._apply_rot()

func _process(dt: float) -> bool:
	clock += dt
	if ai == null:
		# TEST-DEBT: the game no longer makes the Rougarou (tools/qa/rg_spawn.gd); make it here once
		# the wing's own nodes are in (the Player's walk grid is read in its _ready)
		if current_scene.get_node_or_null("Stockrooms") == null:
			if clock > 60.0:
				_check(false, "the wing did not finish loading in 60 s"); return _done()
			return false
		print("the game made a RougarouAI itself: ", RgSpawn.game_made_one(current_scene))
		ai = RgSpawn.spawn(current_scene, player, "sightings")
		fig = ai.fig
		ai.mode = "sightings"; ai.state = "hidden"; fig.visible = false
		ai.cfg.first_sighting_s = 0.0
		ai.timer = 0.0
		clock = 0.0
		return false
	match step:
		0:
			# the far sighting
			if ai.state == "far":
				var d = Vector2(fig.position.x - player.position.x, fig.position.z - player.position.z).length()
				_check(d >= 25.0 and d <= 45.0, "far sighting %.1f m away at %s" % [d, str(fig.position)])
				_check(fig.visible, "figure visible")
				_check(ai._los(player.position, fig.position), "in line of sight")
				step = 1; clock = 0.0
			elif clock > 20.0:
				_check(false, "no far sighting within 20 s (state %s)" % ai.state); return _done()
		1:
			# look away for a second (it must stay), then turn and look at it
			if clock > 1.0 and ai.state == "far":
				_shot("far-unseen")
				_face_fig()
				step = 2; clock = 0.0
			elif ai.state != "far":
				_check(false, "left the far sighting before being looked at"); return _done()
		2:
			if clock > 0.4 and not notes.has("seen when looked at"):
				_check(ai._seen(), "seen when looked at")
				_shot("far-seen")
			if ai.state == "bolt":
				_check(true, "bolts after being looked at for %.1f s" % clock)
				step = 3; clock = 0.0
			elif clock > 4.0:
				_check(false, "did not bolt within 4 s of being looked at (looked %.2f)" % ai.looked); return _done()
		3:
			if clock > 0.5 and not notes.has("mid-bolt shot"):
				notes.append("mid-bolt shot"); _shot("bolt")
				_face_fig()
			if ai.state == "hidden":
				_check(not fig.visible, "gone after the bolt (%.1f s)" % clock)
				# now the behind-you sighting
				ai.force = "behind"; ai.timer = 0.0
				step = 4; clock = 0.0
			elif clock > 15.0:
				_check(false, "still bolting after 15 s"); return _done()
		4:
			if ai.state == "behind":
				var d = Vector2(fig.position.x - player.position.x, fig.position.z - player.position.z).length()
				_check(d > 2.0 and d < 4.5, "behind-you sighting %.1f m away" % d)
				_check(not ai._seen(), "not seen while behind")
				step = 5; clock = 0.0
			elif ai.state == "far":
				_check(true, "no floor behind the player: a far sighting instead (allowed)")
				return _done()
			elif clock > 5.0:
				_check(false, "no behind sighting within 5 s (state %s)" % ai.state); return _done()
		5:
			if clock > 0.5 and not notes.has("behind shot"):
				notes.append("behind shot"); _shot("behind-unseen")
				player.yaw += PI; player._apply_rot()
			if ai.state == "bolt":
				_check(true, "bolts when the player turns round")
				_shot("behind-seen")
				step = 6; clock = 0.0
			elif clock > 4.0:
				_check(false, "did not bolt after the turn"); return _done()
		6:
			if ai.state == "hidden":
				_check(true, "gone again")
				return _done()
			elif clock > 15.0:
				_check(false, "still bolting after 15 s (behind)"); return _done()
	return false

func _done() -> bool:
	if errors.is_empty():
		print("ROUGAROU TEST OK (%d checks)" % notes.size())
	else:
		print("ROUGAROU TEST FAILED: ", errors)
	return true
