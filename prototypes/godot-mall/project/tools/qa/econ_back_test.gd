## ECON item 7 (Steven, Nov 3 2026; design/godot-economy.md): what "Back" does from the redemption screen's
## "Look at the prizes". Natively in Wing 2 (1995), unbaked: stand at the long case, open the counter
## (prizes.gd redeem(): the redemption screen), press "Look at the prizes", then leave the closer look each way
## it offers: its Back button, Esc, Q, B, Backspace, E and a pad's B. After each: the closer look is shut, the
## redemption screen is shut, the menu didn't open, the player isn't held, the player's own camera is current,
## the HUD buttons are back, and S (back) walks. Screenshots of the look and of the walk after.
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script res://tools/qa/econ_back_test.gd -- --out=/tmp/econ/back
## Prints ECON BACK OK (n checks), or the failed checks.
extends SceneTree

var out := "/tmp/econ/back"
var scn: Node
var player: Node3D
var pz: Node
var rd: Node
var menu: Node
var step := 0
var clock := 0.0
var errors := []
var oks := 0
var way := 0
var start_pos := Vector3.ZERO
const WAYS := ["button", "Esc", "Q", "B", "Backspace", "E", "pad B"]

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.substr(6)
	DirAccess.make_dir_recursive_absolute(out.get_base_dir())
	Engine.set_meta("mall_state_1995", "")
	var L: Dictionary = load("res://scripts/avatar_look.gd").default_look()
	L.done = true; L.view = "first"
	Engine.set_meta("mall_avatar", JSON.stringify(L))
	Engine.set_meta("mall_xfer", {"x": -104.8, "z": 64.2, "yaw": deg_to_rad(-90.0), "pitch": deg_to_rad(-18.0)})
	scn = load("res://wing2.tscn").instantiate()
	root.add_child(scn)
	current_scene = scn
	var lm = scn.find_child("LightmapGI", true, false)
	if lm: lm.get_parent().remove_child(lm); lm.free()
	load("res://scripts/time_of_day.gd").apply(scn, "night")
	player = scn.get_node("Player")

func _check(ok: bool, what: String) -> void:
	printerr(("ok   " if ok else "FAIL ") + what)
	if ok: oks += 1
	else: errors.append(what)

func _shot(name: String) -> void:
	root.get_texture().get_image().save_png("%s-%s.png" % [out, name])

func _key(k: Key, down: bool) -> void:
	var e := InputEventKey.new()
	e.keycode = k; e.physical_keycode = k; e.pressed = down
	Input.parse_input_event(e)

func _tap(k: Key) -> void:
	_key(k, true); _key(k, false)

func _leave() -> void:
	match WAYS[way]:
		"button": pz.btn_back.pressed.emit()
		"Esc": _tap(KEY_ESCAPE)
		"Q": _tap(KEY_Q)
		"B": _tap(KEY_B)
		"Backspace": _tap(KEY_BACKSPACE)
		"E": _tap(KEY_E)
		"pad B":
			var e := InputEventJoypadButton.new()
			e.button_index = JOY_BUTTON_B; e.pressed = true
			Input.parse_input_event(e)
			var u := e.duplicate(); u.pressed = false
			Input.parse_input_event(u)

func _at() -> void:
	player.position = Vector3(-104.8, 0, 64.2)
	player.yaw = deg_to_rad(-90.0); player.pitch = deg_to_rad(-18.0); player._apply_rot()

func _process(dt: float) -> bool:
	clock += dt
	if pz == null:
		pz = scn.get_node_or_null("Prizes")
		menu = player.get_node_or_null("Menu")
		clock = 0.0
		return false
	match step:
		0:   # open the counter, then the closer look from the screen's button
			if clock > (2.0 if way == 0 else 0.6):
				_at()
				rd = player.mall.redemption
				pz.redeem()
				step = 1; clock = 0.0
		1:
			if clock > 0.5:
				if way == 0: _check(rd.is_open and player.frozen, "the counter opens the redemption screen")
				rd.btn_look.pressed.emit()
				step = 2; clock = 0.0
		2:
			if clock > 1.0:
				_check(pz.looking and not rd.is_open, "[%s] \"Look at the prizes\" shuts the screen and opens the closer look" % WAYS[way])
				if way == 0: _shot("look")
				_leave()
				step = 3; clock = 0.0
		3:
			if clock > 1.2:
				var w: String = WAYS[way]
				var menu_open: bool = menu != null and bool(menu.get("is_open"))
				var btns_back: bool = player.buttons.is_empty() or player.buttons.any(func(b): return b.visible)
				_check(not pz.looking, "[%s] the closer look is shut" % w)
				_check(not rd.is_open, "[%s] the redemption screen did not come back" % w)
				_check(not menu_open, "[%s] the menu did not open" % w)
				_check(not player.frozen and player.cam.current, "[%s] the player is free, on their own camera" % w)
				_check(btns_back, "[%s] the HUD buttons are back" % w)
				start_pos = player.position
				_key(KEY_S, true)
				step = 4; clock = 0.0
		4:
			if clock > 0.6:
				_key(KEY_S, false)
				var moved: float = player.position.distance_to(start_pos)
				_check(moved > 0.3, "[%s] S walks (backing away from the counter): back to walking (%.2f m)" % [WAYS[way], moved])
				if way == 0: _shot("walking-after")
				way += 1
				if way >= WAYS.size():
					printerr("ECON BACK OK (%d checks)" % oks if errors.is_empty() else "ECON BACK FAILED: " + str(errors))
					return true
				if menu and bool(menu.get("is_open")): menu.close()
				step = 0; clock = 0.0
	return false
