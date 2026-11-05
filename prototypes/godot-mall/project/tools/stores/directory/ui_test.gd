## Headless check of the mall directory's jump in a real wing (design/godot-directory.md): loads a
## wing, opens its first kiosk (the camera goes to the sign), picks the store named by the letters
## given as the keys would (Down through the list, Enter: its block, Enter: the question, Enter: yes),
## and prints where the player stands before and after (a jump into the other wing changes the scene).
## The whole reader, touch and the year switch: tools/stores/directory/kiosk_test.gd.
##   godot --headless --path . --script res://tools/stores/directory/ui_test.gd -- wing1.tscn dil
## Prints UI TEST OK, or UI TEST FAILED.
extends SceneTree

var phase := 0
var t0 := 0
var args := []
var want := "dil"
var ok := true

func _initialize():
	args = OS.get_cmdline_user_args()
	want = (args[1] if args.size() > 1 else "dil").to_lower()
	change_scene_to_file("res://" + (args[0] if args.size() > 0 else "wing1.tscn"))
	t0 = Time.get_ticks_msec()

func _key(code: int) -> void:
	for down in [true, false]:
		var e := InputEventKey.new()
		e.pressed = down
		e.physical_keycode = code
		e.keycode = code
		root.push_input(e)

func _wait(ms: int) -> bool:
	return Time.get_ticks_msec() - t0 < ms

func _next() -> void:
	phase += 1
	t0 = Time.get_ticks_msec()

func _fail(why: String) -> void:
	print("FAIL ", why)
	ok = false

func _process(_dt):
	var scn = current_scene
	if scn == null:
		return false
	var pl = scn.get_node_or_null("Player")
	match phase:
		0:
			if _wait(1500):
				return false
			var ks = get_nodes_in_group("directory_kiosk")
			print("kiosks: ", ks.size())
			if ks.is_empty():
				_fail("no kiosk"); print("UI TEST FAILED"); quit(1); return true
			print("before: wing ", pl.wing, " year ", pl.year, " pos ", pl.position)
			ks[0].interact(pl)
			_next()
		1:
			if _wait(2600):
				return false
			var ui = scn.get_meta("directory_ui")
			# a loaded wing can hitch for seconds on its first frames (characters baking): wait for the list
			if ui.state != "list" and _wait(12000):
				return false
			print("open: ", ui.is_open, " frozen: ", pl.frozen, " year ", ui.year, " state ", ui.state, " click areas ", ui._hot().size())
			if not (ui.is_open and pl.frozen and ui.state == "list"):
				_fail("not open on the list")
			# Down through the list to the store, as a keyboard would
			for i in 200:
				_key(KEY_DOWN)
				var st = ui._stall(ui.sel)
				if st and String(st.name).to_lower().begins_with(want):
					break
			var st = ui._stall(ui.sel)
			print("found: ", st.name if st else "-", " jump ", st.jump if st else "-")
			if st == null or not String(st.name).to_lower().begins_with(want):
				_fail("no store " + want)
			_key(KEY_ENTER)
			_next()
		2:
			if _wait(1200):
				return false
			var ui = scn.get_meta("directory_ui")
			print("on the map: ", ui.state)
			if ui.state != "map":
				_fail("not on the map")
			_key(KEY_ENTER)
			_next()
		3:
			if _wait(300):
				return false
			var ui = scn.get_meta("directory_ui")
			print("confirm shown: ", ui.confirm, " ", ui.dlg_name.text)
			if not ui.confirm:
				_fail("no question")
			_key(KEY_ENTER)
			_next()
		4:
			if _wait(6000):
				return false
			print("after: scene ", scn.scene_file_path, " wing ", pl.wing, " year ", pl.year, " pos ", pl.position, " yaw ", rad_to_deg(pl.yaw), " frozen ", pl.frozen)
			if pl.frozen:
				_fail("still frozen")
			print("UI TEST OK" if ok else "UI TEST FAILED")
			quit(0 if ok else 1)
	return false
