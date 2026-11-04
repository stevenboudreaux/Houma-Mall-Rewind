## PROTOTYPE ws/directory (design/godot-directory-legibility.md): unbaked screenshots of the three
## directory-reading options (scripts/directory_look.gd). The kiosk alone in tools/qa/preview.gd's
## room with a stand-in player (a whole wing was OOM-killed on the shared cloud box); --mode= (empty)
## shows today's reader. --hidpi=3 with --resolution 1170x2532 draws like an iPhone at device pixels.
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 390x844 \
##     --script res://tools/qa/dirlook_mini.gd -- --mode=b --year=2026 --out=/tmp/d/b26p
extends "res://tools/qa/preview.gd"

const FAKE := """
extends Node3D
var frozen := false
var year := 2026
var wing := 1
var cam: Camera3D
var move_vec := Vector2.ZERO
var move_touch := -1
var look_touch := -1
var dragging := false
var stick = null
var input_kind := "touch"
var yaw := 0.0
var pitch := 0.0
var leaving := false
var prompt = null
func _apply_rot() -> void:
	cam.global_transform = Transform3D(Basis.from_euler(Vector3(pitch, yaw, 0.0), EULER_ORDER_YXZ), position + Vector3(0, 1.6, 0))
func jump_to(w, yr, x, z, yd) -> void:
	print("JUMP ", w, " ", yr, " ", x, " ", z)
"""


var out := "/tmp/d/x"
var mode := "b"
var year := "2026"
var hidpi := 1.0
var scn: Node
var player
var kiosk
var lk: Node
var step := 0
var clock := 0.0
var plan: Array = []
var pick_name := ""

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.substr(6)
		elif a.begins_with("--mode="): mode = a.substr(7)
		elif a.begins_with("--year="): year = a.substr(7)
		elif a.begins_with("--hidpi="): hidpi = float(a.substr(8))
	DirAccess.make_dir_recursive_absolute(out.get_base_dir())
	raw_tex = true
	mall = Node3D.new(); mall.name = "Mini"
	light_root = Node3D.new(); light_root.name = "Lights"
	mall.add_child(light_root)
	Engine.set_meta("dirlook", mode)
	Engine.set_meta("mall_state_1995", "")
	Engine.set_meta("mall_flags", "")
	if hidpi > 1.0:
		root.content_scale_factor = hidpi
		root.scaling_3d_scale = 1.0 / hidpi
	mall.set_meta("gen", "res://gen/w1y26/" if year == "2026" else "res://gen/w1/")
	root.add_child(mall)
	build_prop("res://tools/stores/directory/kiosk.gd", {"year": year})
	commit_meshes()
	setup_env("lit", false)
	scn = mall
	var k := Node3D.new()
	k.name = "DirectoryKiosk0"
	k.set_meta("face", Vector2(0, 1))
	k.set_script(load("res://scripts/directory_kiosk.gd"))
	mall.add_child(k)
	var gs := GDScript.new()
	gs.source_code = FAKE
	gs.reload()
	player = Node3D.new()
	player.name = "Player"
	player.set_script(gs)
	player.year = int(year)
	mall.add_child(player)
	player.cam = Camera3D.new()
	player.cam.fov = 70.0
	mall.add_child(player.cam)
	player.cam.current = true
	pick_name = "Foot Locker" if year == "2026" else "Radio Shack"
	plan = [
		[2.5, func():
			kiosk = get_nodes_in_group("directory_kiosk")[0]
			_at(0.0, 2.1, 0.0, -4.0)],
		[1.0, func(): _shot("1-approach"); kiosk.interact(player)],
		[0.3, func(): _shot("2-camera-moving")],
		[0.6, func(): _shot("3-arrived")],
	]
	match mode:
		"a":
			plan += [
				[0.2, func():
					# what a pinch then a drag ends on: the list's top at reading size
					lk = scn.get_meta("directory_look"); lk.want = lk._rect_at(Vector2(440, 760) + lk._vp() * 0.5 / lk.READ_SCALE - Vector2(380, 300), lk.READ_SCALE)],
				[1.2, func(): _shot("4-zoomed-list"); lk._pick(_id(pick_name))],
				[0.3, func(): lk.want = lk._rect_at(_map_c(pick_name), lk._scale())],
				[1.2, func(): _shot("5-picked-on-map")],
			]
		"b":
			plan += [
				[2.0, func(): lk = scn.get_meta("directory_look"); _shot("4-list-page1"); lk._show_page(1)],
				[1.3, func(): _shot("5-list-page2"); lk._pick(_id(pick_name))],
				[0.35, func(): _shot("6-gliding-to-map")],
				[1.3, func(): _shot("7-picked-on-map")],
			]
		"c":
			plan += [
				[0.5, func():
					var ui = scn.get_meta("directory_ui")
					_shot("4-flat-copy")
					for h in ui._hot():
						var st = ui._stall(h.id)
						if st and String(st.name) == pick_name:
							ui.sel = h.id
					ui.view.queue_redraw()],
				[0.3, func():
					var ui = scn.get_meta("directory_ui")
					_shot("5-selected"); ui._zoom_on_sel(2.5); ui.view.queue_redraw()],
				[0.3, func():
					var ui = scn.get_meta("directory_ui")
					_shot("6-zoomed"); ui._ask()],
				[0.3, func(): _shot("7-confirm")],
			]

func _id(name: String) -> String:
	for h in lk._hot():
		var st = lk._stall(h.id)
		if st and String(st.name) == name:
			return h.id
	push_error("no store " + name)
	return ""

func _map_c(name: String) -> Vector2:
	var id := _id(name)
	for h in lk._hot():
		if h.id == id and h.kind == "map":
			return Vector2((h.rect[0] + h.rect[2]) * 0.5, (h.rect[1] + h.rect[3]) * 0.5)
	return lk.psize * 0.5

func _at(x: float, z: float, yaw: float, pitch: float) -> void:
	player.position = Vector3(x, 0, z)
	player.yaw = deg_to_rad(yaw); player.pitch = deg_to_rad(pitch); player._apply_rot()

func _shot(name: String) -> void:
	root.get_texture().get_image().save_png("%s-%s.png" % [out, name])
	printerr("shot " + name)

func _process(dt):
	clock += dt
	if step >= plan.size():
		printerr("DIRLOOK SHOTS OK")
		return true
	if clock >= float(plan[step][0]):
		var c: Callable = plan[step][1]
		step += 1
		clock = 0.0
		c.call()
	return false
