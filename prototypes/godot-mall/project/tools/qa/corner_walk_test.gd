## ws/corner-2026 (design/corner-2026-c2.md): the C2 / main-entrance corner walked natively, headless, unbaked.
## Wing 1, one year; four first-person walks (forward held 4 s), each printing where the player stops:
##   0. north to south across the court patch (x 2..12, z 6..10): reaches Franks' / Zales bay C front (z >= 9);
##   1. east along the patch at Orange Julius' court side (x = 12): 1995 the plain wall (a "solid" collider)
##      holds, 2026 Zales bay B's front holds (Zales is open but not walk-in);
##   2. south in the entrance hall at OJ's / Zales bay A front (z = 6): 1995 OJ's walk-up front lets you in,
##      2026 Zales' front holds;
##   3. east out of the east hall (H4) across the patch: the patch is reachable from H4.
##   godot --headless --path . --script res://tools/qa/corner_walk_test.gd -- --year=1995|2026
## Prints CORNER WALK OK (<year>) or the failures.
extends SceneTree

var year := 1995
var scn: Node
var player: Node3D
var t := 0.0
var leg := 0
var errs := []
# name, start x,z,yaw ; hold forward secs ; check(pos) -> [ok, text]
var legs := []

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--year="): year = int(a.substr(7))
	Engine.set_meta("mall_state_%d" % year, "")
	scn = load("res://wing1_2026.tscn" if year == 2026 else "res://wing1.tscn").instantiate()
	root.add_child(scn); current_scene = scn
	player = scn.get_node("Player")
	legs = [
		["court patch to Franks' front (south)", Vector3(7, 0, 4), 180.0, 4.0],
		["court patch east at OJ/Zales court side", Vector3(8, 0, 8), -90.0, 4.0],
		["entrance hall south at OJ/Zales hall front", Vector3(14, 0, 3), 180.0, 4.0],
		["H4 north onto the court patch", Vector3(-4, 0, 9), -90.0, 4.0],
	]
	leg = -1   # start after a few frames: the player's _ready places it at its spawn

func _start() -> void:
	var L = legs[leg]
	player.position = L[1]; player.yaw = deg_to_rad(L[2]); player.pitch = 0.0; player._apply_rot()
	print("leg %d %s: start free=%s" % [leg, L[0], player._free(L[1].x, L[1].z)])
	Input.action_press("ui_up"); t = 0.0

func _process(dt: float) -> bool:
	t += dt
	if leg == -1:
		if t > 1.0:
			leg = 0; _start()
		return false
	if t < legs[leg][3]: return false
	Input.action_release("ui_up")
	var p: Vector3 = player.position
	var nm: String = legs[leg][0]
	print("leg %d %s: stopped at x=%.2f z=%.2f" % [leg, nm, p.x, p.z])
	if leg == 0 and p.z < 9.0: errs.append("%s: did not reach Franks' front (z %.2f)" % [nm, p.z])
	if leg == 1 and year == 1995 and p.x >= 12.0: errs.append("%s: walked through OJ's plain court wall (x %.2f)" % [nm, p.x])
	if leg == 1 and year == 2026 and p.x >= 12.0: errs.append("%s: walked into Zales (not walk-in) (x %.2f)" % [nm, p.x])
	if leg == 2 and year == 2026 and p.z >= 6.0: errs.append("%s: walked into Zales bay A (z %.2f)" % [nm, p.z])
	if leg == 2 and year == 1995 and p.z < 6.0: errs.append("%s: OJ's walk-up front is shut (z %.2f)" % [nm, p.z])
	if leg == 3 and p.x < 2.0: errs.append("%s: could not step from H4 onto the court patch (x %.2f)" % [nm, p.x])
	leg += 1
	if leg >= legs.size():
		if errs.is_empty(): print("CORNER WALK OK (%d)" % year)
		else:
			for e in errs: print("FAIL: ", e)
		quit(0 if errs.is_empty() else 1)
		return true
	_start()
	return false
