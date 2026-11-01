## Saves a picture of the mall directory's map, rendered natively (for quick UI checks; the web
## shots are tools/stores/directory/dirtest.js).
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 390x844 \
##     --script res://tools/stores/directory/ui_shot.gd -- wing1.tscn 1995 out.png [typed-letters]
extends SceneTree

var t := 0
var args := []

func _initialize():
	args = OS.get_cmdline_user_args()
	change_scene_to_file("res://" + args[0])

func _process(_dt):
	t += 1
	var scn = current_scene
	if scn == null:
		return false
	if t == 8:
		var pl = scn.get_node("Player")
		var ks = get_nodes_in_group("directory_kiosk")
		ks[0].interact(pl)
	if t == 12:
		var ui = scn.get_meta("directory_ui")
		if ui.map_year != args[1]:
			ui._toggle_year()
		if args.size() > 3:
			ui.typed = args[3]
			ui._find()
			if args.size() > 4 and args[4] == "ask":
				ui._ask()
		ui._redraw()
	if t == 20:
		root.get_texture().get_image().save_png(args[2])
		print("saved ", args[2])
		quit()
	return false
