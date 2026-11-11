## WOOL-FRONT (Nov 11 2026; design/storefronts/woolworth.md "WOOL-FRONT"): Woolworth's new front end and
## lunch counter walked natively, headless, unbaked. Wing 1, 1990s; first-person walks (forward held),
## each printing where the player stops:
##   0. from the mall court straight into the store on the right side (u 16), through the floor the
##      checkouts used to stand on: reaches the first gondola (d > 4.6);
##   1. down the main aisle (u 22.5): well into the store;
##   2. in through a checkout lane on the left (between counters 2 and 3): out the far end (d > 4.6);
##   3. in the restaurant, between the lunch counter's end and the window booths, toward the right
##      wall: reaches the wall (u < 1.5). Before WOOL-FRONT the curve's last stools stopped this.
##   4. nothing walks into the kitchen behind the pass-through: from the store, toward its side wall.
##   godot --headless --path . --script res://tools/qa/wool_front_walk_test.gd
## Prints WOOL FRONT WALK OK or the failures. Exit code 0 / 1.
## Woolworth's frame: x = -10 - d, z = -14 + u (tools/stores/woolworth/store.gd).
extends SceneTree

var scn: Node
var player: Node3D
var t := 0.0
var leg := -1
var errs := []
# name, start, yaw (deg; 90 looks -x into the store, 0 looks -z toward the restaurant's right wall), secs
var legs := [
	["court straight into the right side", Vector3(-6, 0, 2), 90.0, 3.0],
	["the main aisle", Vector3(-6, 0, 8.5), 90.0, 4.0],
	["a checkout lane on the left", Vector3(-9, 0, 16.3), 90.0, 2.5],
	["between the counter's end and the window booths", Vector3(-11.95, 0, -9.0), 0.0, 2.5],
	["the kitchen's side wall holds", Vector3(-24.5, 0, -6.0), 0.0, 3.0],
]

func _initialize() -> void:
	Engine.set_meta("mall_state_1995", "")
	scn = load("res://wing1.tscn").instantiate()
	root.add_child(scn); current_scene = scn
	player = scn.get_node("Player")

func _start() -> void:
	var L = legs[leg]
	player.position = L[1]; player.yaw = deg_to_rad(L[2]); player.pitch = 0.0; player._apply_rot()
	var free: bool = player._free(L[1].x, L[1].z)
	print("leg %d %s: start free=%s" % [leg, L[0], free])
	if not free: errs.append("%s: the start spot is not free floor" % L[0])
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
	var u := p.z + 14.0
	var d := -10.0 - p.x
	print("leg %d %s: stopped at x=%.2f z=%.2f (u %.2f, d %.2f)" % [leg, nm, p.x, p.z, u, d])
	if leg == 0 and d < 4.6: errs.append("%s: stopped at d %.2f, where the checkouts stood" % [nm, d])
	if leg == 1 and d < 9.0: errs.append("%s: stopped at d %.2f" % [nm, d])
	if leg == 2 and d < 4.6: errs.append("%s: stopped inside the lane at d %.2f" % [nm, d])
	if leg == 3 and u > 1.5: errs.append("%s: stopped at u %.2f, short of the wall" % [nm, u])
	if leg == 4 and u < 4.4: errs.append("%s: walked into the kitchen (u %.2f)" % [nm, u])
	leg += 1
	if leg >= legs.size():
		if errs.is_empty(): print("WOOL FRONT WALK OK")
		else:
			for e in errs: print("FAIL: ", e)
		quit(0 if errs.is_empty() else 1)
		return true
	_start()
	return false
