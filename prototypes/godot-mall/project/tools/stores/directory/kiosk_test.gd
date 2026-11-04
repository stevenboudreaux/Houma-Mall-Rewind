## The directory kiosk, end to end, natively and unbaked (design/godot-directory.md "Reading the
## directory"): the kiosk alone in tools/qa/preview.gd's room with a stand-in player (a whole wing
## does not fit the shared cloud box's memory; tools/stores/directory/ui_test.gd is the in-wing jump).
## Every press goes through the real input path (root.push_input, window pixels, so --hidpi checks
## the device-pixel mapping too):
##   open (the camera glides to the sign; the year switch lit for this year) -> the list -> swipe a page
##   and back -> tap a store's name (lit, the camera on its block) -> tap the lit block (the question,
##   in the menu's style) -> Yes (player.jump_to with the store's spot) -> reopen -> keys (Esc, Enter,
##   Down) -> tap the other year's key on the switch (the time-travel trip starts).
##   xvfb-run -a -s "-screen 0 1600x2600x24" godot --path . --rendering-driver opengl3 \
##     --resolution 390x844 --script res://tools/stores/directory/kiosk_test.gd -- --year=2026 --out=/tmp/k/p26
##   --hidpi=3 with --resolution 1170x2532: an iPhone at device pixels (scripts/hidpi.gd).
## Prints KIOSK TEST OK (n checks), or KIOSK TEST FAILED and the failed checks; writes <out>-<step>.png.
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
var vr_on := false
var prompt = null
var buttons := []
var jumped := []
func _apply_rot() -> void:
	cam.global_transform = Transform3D(Basis.from_euler(Vector3(pitch, yaw, 0.0), EULER_ORDER_YXZ), position + Vector3(0, 1.6, 0))
func jump_to(w, yr, x, z, yd) -> void:
	jumped = [w, yr, x, z, yd]
"""

var out := "/tmp/k/x"
var year := "2026"
var hidpi := 1.0
var player
var kiosk
var ui
var step := 0
var clock := 0.0
var plan: Array = []
var errors := []
var oks := 0
var pick_name := ""
var pick := ""

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.substr(6)
		elif a.begins_with("--year="): year = a.substr(7)
		elif a.begins_with("--hidpi="): hidpi = float(a.substr(8))
	DirAccess.make_dir_recursive_absolute(out.get_base_dir())
	Engine.set_meta("hidpi", hidpi)
	var hd = root.get_node_or_null("Hidpi")
	if hd: hd._apply()
	else:
		root.content_scale_factor = hidpi
		root.scaling_3d_scale = 1.0 / hidpi
	raw_tex = true
	mall = Node3D.new(); mall.name = "Mini"
	light_root = Node3D.new(); light_root.name = "Lights"
	mall.add_child(light_root)
	mall.set_meta("gen", "res://gen/w1y26/" if year == "2026" else "res://gen/w1/")
	root.add_child(mall)
	build_prop("res://tools/stores/directory/kiosk.gd", {"year": year})
	commit_meshes()
	setup_env("lit", false)
	kiosk = Node3D.new()
	kiosk.name = "DirectoryKiosk0"
	kiosk.set_meta("face", Vector2(0, 1))
	kiosk.set_meta("year", year)
	kiosk.set_script(load("res://scripts/directory_kiosk.gd"))
	mall.add_child(kiosk)
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
	var other := "1995" if year == "2026" else "2026"
	plan = [
		[1.5, func():
			ui = mall.get_meta("directory_ui")
			player.position = Vector3(0, 0, 2.1); player.yaw = 0.0; player.pitch = deg_to_rad(-4); player._apply_rot()
			_check(kiosk.switch_node != null and kiosk.switch_node.get_node_or_null("Key2026") != null and kiosk.switch_node.get_node_or_null("Key1990s") != null, "the year switch is on the kiosk, keys 1990s and 2026")
			var lit = kiosk.switch_node.get_node("Key" + ("1990s" if year == "1995" else "2026"))
			_check(lit.modulate == Color.WHITE, "this year's key is lit")],
		[0.5, func(): _shot("1-approach"); kiosk.interact(player)],
		[0.3, func():
			_check(ui.is_open and player.frozen, "open, the player frozen")
			_check(get_viewport_cam() == ui.cam, "the reader's camera has the view")
			_shot("2-camera-moving")],
		[0.6, func():
			_check(ui.settled and ui.state == "whole", "arrived on the whole sign")
			_check(is_equal_approx(root.scaling_3d_scale, 1.0), "3D at full resolution on the sign")
			_shot("3-whole-sign")],
		[1.6, func():
			_check(ui.state == "list" and ui.page == 0, "moved in to the list (page 0)")
			_check(ui._scale() > 0.6, "the list at reading size (%.2f screen px per panel px)" % ui._scale())
			_shot("4-list")
			_swipe(Vector2(0.8, 0.5), Vector2(0.2, 0.5))],
		[1.0, func():
			_check(ui.page == 1, "a swipe turns the page (%d)" % ui.page)
			_shot("5-list-page2")
			_swipe(Vector2(0.2, 0.5), Vector2(0.8, 0.5))],
		[1.0, func():
			_check(ui.page == 0, "a swipe back")
			pick = ui.id_of(pick_name)
			_check(pick != "", "the store " + pick_name)
			# its line's page first, as a reader would turn to it
			ui._show_page(ui._page_of(pick))],
		[1.0, func():
			_tap(ui.screen_of(pick, "list"))],
		[1.3, func():
			_check(ui.sel == pick, "a tap on the name lights it")
			_check(ui.state == "map", "the camera goes to its block")
			_shot("6-on-map")
			_tap(ui.screen_of(pick, "map"))],
		[0.4, func():
			_check(ui.confirm and ui.dlg.visible, "a tap on the lit block asks")
			_check(ui.dlg_name.text.ends_with(pick_name), "the question names the store (%s)" % ui.dlg_name.text)
			_shot("7-confirm")
			_tap(ui.dlg.position + ui.dlg_yes.position + ui.dlg_yes.size * 0.5)],
		[0.3, func():
			var j: Array = ui._stall(pick).jump
			_check(player.jumped.size() == 5 and int(player.jumped[0]) == int(j[0]) and int(player.jumped[1]) == int(year) and is_equal_approx(float(player.jumped[2]), float(j[1])), "Yes jumps to the store's spot (%s)" % str(player.jumped))
			_check(not ui.is_open and not player.frozen, "closed, the player free")
			_check(get_viewport_cam() == player.cam, "the player's camera back")
			_check(is_equal_approx(root.scaling_3d_scale, 1.0 / hidpi), "3D scale back (%.2f)" % root.scaling_3d_scale)
			player.jumped = []
			kiosk.interact(player)],
		[1.0, func():
			_key(KEY_ENTER)],
		[1.0, func():
			_check(ui.state == "list", "Enter moves in to the list")
			_key(KEY_DOWN)],
		[0.6, func():
			_check(ui.sel != "", "Down lights the first store")
			_key(KEY_ESCAPE)],
		[0.8, func():
			_check(ui.state == "whole", "Esc backs out to the whole sign")
			_shot("8-whole-sign-again")
			_tap(ui.cam.unproject_position(kiosk.switch_key_pos(year)))],
		[0.3, func():
			_check(ui.is_open and root.get_node_or_null("TimeTravelTrip") == null, "this year's key does nothing")
			_tap(ui.cam.unproject_position(kiosk.switch_key_pos(other)))],
		[0.0, func():
			_check(root.get_node_or_null("TimeTravelTrip") != null, "the other year's key starts the trip")
			_check(not ui.is_open, "the sign closes for the trip")],
		[0.5, func(): _shot("9-trip-begins")],
	]

func get_viewport_cam() -> Camera3D:
	return root.get_viewport().get_camera_3d()

func _check(ok: bool, what: String) -> void:
	printerr(("ok   " if ok else "FAIL ") + what)
	if ok: oks += 1
	else: errors.append(what)

func _shot(name: String) -> void:
	root.get_texture().get_image().save_png("%s-%s.png" % [out, name])
	printerr("shot " + name)

## Window pixels from the 2D (content-scaled) position.
func _win(p: Vector2) -> Vector2:
	return p * hidpi

func _tap(p: Vector2) -> void:
	for down in [true, false]:
		var e := InputEventScreenTouch.new()
		e.index = 0
		e.pressed = down
		e.position = _win(p)
		root.push_input(e)

func _swipe(a: Vector2, b: Vector2) -> void:
	var vp := root.get_visible_rect().size
	var e := InputEventScreenTouch.new()
	e.index = 0; e.pressed = true; e.position = _win(a * vp)
	root.push_input(e)
	for i in 6:
		var d := InputEventScreenDrag.new()
		d.index = 0
		d.position = _win(a.lerp(b, (i + 1) / 6.0) * vp)
		root.push_input(d)
	var u := InputEventScreenTouch.new()
	u.index = 0; u.pressed = false; u.position = _win(b * vp)
	root.push_input(u)

func _key(k: int) -> void:
	for down in [true, false]:
		var e := InputEventKey.new()
		e.pressed = down
		e.physical_keycode = k
		e.keycode = k
		root.push_input(e)

func _process(dt):
	clock += dt
	if step >= plan.size():
		printerr(("KIOSK TEST OK (%d checks)" % oks) if errors.is_empty() else ("KIOSK TEST FAILED: " + str(errors)))
		quit(0 if errors.is_empty() else 1)
		return true
	if clock >= float(plan[step][0]):
		var c: Callable = plan[step][1]
		step += 1
		clock = 0.0
		c.call()
	return false
