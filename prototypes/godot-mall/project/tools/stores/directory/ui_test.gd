## Headless check of the mall directory (design/godot-directory.md): loads a wing, opens its first
## kiosk's sign, selects the store named by the letters given, asks and confirms, and prints where
## the player stands before and after (a jump into the other wing changes the scene).
##   godot --headless --path . --script res://tools/stores/directory/ui_test.gd -- wing1.tscn dil [1995|2026]
extends SceneTree

var phase := 0
var t := 0
var args := []

func _initialize():
	args = OS.get_cmdline_user_args()
	change_scene_to_file("res://" + (args[0] if args.size() > 0 else "wing1.tscn"))

func _key(code: int, uni := 0) -> void:
	var e := InputEventKey.new()
	e.pressed = true
	e.physical_keycode = code
	e.keycode = code
	e.unicode = uni
	root.push_input(e)
	var u := e.duplicate()
	u.pressed = false
	root.push_input(u)

func _process(_dt):
	t += 1
	var scn = current_scene
	if scn == null:
		return false
	var pl = scn.get_node_or_null("Player")
	match phase:
		0:
			if t < 5:
				return false
			var ks = get_nodes_in_group("directory_kiosk")
			print("kiosks: ", ks.size(), " interactable: ", get_nodes_in_group("interactable").size())
			if ks.is_empty():
				print("FAIL no kiosk"); quit(1); return true
			print("before: wing ", pl.wing, " year ", pl.year, " pos ", pl.position)
			ks[0].interact(pl)
			phase = 1; t = 0
		1:
			if t < 3:
				return false
			var ui = scn.get_meta("directory_ui")
			print("open: ", ui.is_open, " frozen: ", pl.frozen, " year ", ui.map_year, " click areas ", ui._hot().size())
			if args.size() > 2 and args[2] != ui.map_year:
				_key(KEY_TAB)
			phase = 2; t = 0
		2:
			if t < 3:
				return false
			var ui = scn.get_meta("directory_ui")
			# select the store whose name starts with the letters given, as a click on its name would
			var want: String = (args[1] if args.size() > 1 else "dil").to_lower()
			for h in ui._hot():
				var st = ui._stall(h.id)
				if st and String(st.name).to_lower().begins_with(want):
					ui.sel = h.id
					break
			print("found: ", ui._stall(ui.sel).name, " jump ", ui._stall(ui.sel).jump, " map ", ui.map_year)
			_key(KEY_RIGHT); _key(KEY_LEFT)   # a step away and back
			print("after step: ", ui._stall(ui.sel).name)
			for h in ui._hot():
				var st = ui._stall(h.id)
				if st and String(st.name).to_lower().begins_with(want):
					ui.sel = h.id
					break
			_key(KEY_ENTER)
			phase = 3; t = 0
		3:
			if t < 3:
				return false
			var ui = scn.get_meta("directory_ui")
			print("confirm shown: ", ui.confirm)
			_key(KEY_ENTER)
			phase = 4; t = 0
		4:
			if t < 90:
				return false
			print("after: scene ", scn.scene_file_path, " wing ", pl.wing, " year ", pl.year, " pos ", pl.position, " yaw ", rad_to_deg(pl.yaw), " frozen ", pl.frozen)
			print("UI TEST DONE")
			quit()
	return false
