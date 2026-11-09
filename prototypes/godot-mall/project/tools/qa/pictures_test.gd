## OWNER (design/godot-owner-mode.md "Pictures"): the owner's own pictures on posters and ad panels,
## natively, unbaked, with the picture chooser and the publisher mocked (scripts/pictures.gd picker_fn /
## publisher_fn; web/shell.html's side is tools/qa/pictures_publish_test.js). Wing 1 (1995) has the
## framed Courier ads and wall poster panels.
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script res://tools/qa/pictures_test.gd -- --wing=1 --out=/tmp/pic/w1 [--year=2026]
## Prints PICTURES TEST OK (n checks) or the failures; writes <out>-<name>.png.
extends SceneTree

var out := "/tmp/pic/w"
var wing := 1
var year := 1995
var scn: Node
var player: Node3D
var pics: Node
var errors := []
var oks := 0
var q := []
var qi := 0
var wait := 0.0
var framed_id := ""
var panel_id := ""
var black_before := 0
var pick_answer = {}
var published_with = null

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.substr(6)
		elif a.begins_with("--wing="): wing = int(a.substr(7))
		elif a.begins_with("--year="): year = int(a.substr(7))
	DirAccess.make_dir_recursive_absolute(out.get_base_dir())
	Engine.set_meta("mall_state_1995", "")
	Engine.set_meta("mall_state_2026", "")
	Engine.set_meta("mall_player_name", "TESTER")
	Engine.set_meta("mall_controls", "")
	Engine.set_meta("menu_opening", false)
	Engine.set_meta("mall_pictures_draft", "")
	# CHAR-STRIP: the player's record (scripts/cast.gd), first person, the default cast member
	Cast.save_player({"cast": str(Cast.roster().default), "view": "first"})
	_plan()

func _load(owner: bool) -> void:
	Engine.set_meta("mall_owner", owner)
	if scn and is_instance_valid(scn):
		scn.free()
	scn = load("res://wing%d%s.tscn" % [wing, "_2026" if year == 2026 else ""]).instantiate()
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

func _do(c: Callable, w := 0.0) -> void:
	q.append([c, w])

func _tap(p: Vector2) -> void:
	for d in [true, false]:
		var t := InputEventScreenTouch.new()
		t.index = 0; t.position = p; t.pressed = d
		Input.parse_input_event(t)

## Stand d metres in front of slot id, facing it, eyes level with it.
func _face(id: String, d: float) -> void:
	var s: Dictionary = pics.slots[id]
	var n: Vector3 = s.n
	var at: Vector3 = s.c + Vector3(n.x, 0, n.z).normalized() * d
	player.position = Vector3(at.x, 0, at.z)
	player.yaw = atan2(n.x, n.z)
	player.pitch = atan2(s.c.y - player.cam.position.y, d)
	player._apply_rot()

## A test picture: w x h, a colour field with a white frame line and a diagonal, as PNG base64.
func _picture(w: int, h: int, col: Color) -> Dictionary:
	var im := Image.create(w, h, false, Image.FORMAT_RGB8)
	im.fill(col)
	for x in w:
		for t in 6:
			im.set_pixel(x, t, Color.WHITE); im.set_pixel(x, h - 1 - t, Color.WHITE)
		var y := int(float(x) / w * (h - 1))
		for t in 5:
			im.set_pixel(x, clampi(y + t, 0, h - 1), Color(1, 0.85, 0.2))
	for y in h:
		for t in 6:
			im.set_pixel(t, y, Color.WHITE); im.set_pixel(w - 1 - t, y, Color.WHITE)
	# a big dark disc: easy to see the aspect
	var c := Vector2(w * 0.5, h * 0.5)
	var r := minf(w, h) * 0.3
	for y in range(int(c.y - r), int(c.y + r)):
		for x in range(int(c.x - r), int(c.x + r)):
			if Vector2(x, y).distance_to(c) < r:
				im.set_pixel(x, y, Color(0.08, 0.1, 0.25))
	return {"data": "data:image/png;base64," + Marshalls.raw_to_base64(im.save_png_to_buffer()), "w": w, "h": h}

func _black_tris() -> int:
	var mi: MeshInstance3D = pics.framed_mi
	if mi == null: return -1
	for i in mi.mesh.get_surface_count():
		var m = mi.mesh.surface_get_material(i)
		if m and m.resource_name == "black":
			return mi.mesh.surface_get_arrays(i)[Mesh.ARRAY_INDEX].size() / 3
	return 0

func _print_node(id: String) -> MeshInstance3D:
	for nd in pics.made.get(id, []):
		if is_instance_valid(nd) and not nd.is_queued_for_deletion() and str(nd.get_meta("pic_part", "")) == "PicPrint":
			return nd
	return null

func _hook() -> void:
	pics = scn.get_node("Pictures")
	pics.picker_fn = func(_id): return pick_answer
	pics.publisher_fn = func(d): published_with = d; return "ok"

func _plan() -> void:
	_do(func(): _load(true), 4.0)
	_do(func():
		_hook()
		player.hint.visible = false
		var framed: Array = []
		var panels: Array = []
		for id in pics.order:
			if pics.slots[id].kind == "framed": framed.append(id)
			else: panels.append(id)
		print("SLOTS framed ", framed)
		print("SLOTS panels ", panels)
		if year == 1995 and wing == 1:
			_check(framed.size() == 9, "wing 1: the nine framed Courier ads are slots (%d)" % framed.size())
		_check(panels.size() > 0, "poster / ad panels found (%d)" % panels.size())
		framed_id = "ad.gryders" if "ad.gryders" in framed else (framed[0] if not framed.is_empty() else "")
		panel_id = panels[0] if not panels.is_empty() else ""
		for id in panels:
			if String(id).contains("cin_posters") or String(id).contains("f26_posters_lit"):
				panel_id = id; break
		var ok := true
		for id in framed:
			var s: Dictionary = pics.slots[id]
			if absf(maxf(s.w, s.h) - 1.15) > 0.02: ok = false
		_check(ok, "each framed ad's print measures 1.15 m on its longer side (read back from the mesh)")
		if framed_id != "":
			_face(framed_id, 2.6)
		, 1.0)
	if true:     # the framed ads (1990s, wing 1)
		_do(func():
			if framed_id == "": return
			_shot("framed-before")
			black_before = _black_tris()
			pick_answer = _picture(1024, 600, Color(0.75, 0.15, 0.2))
			pics.set_editing(true)
			_check(pics.editing, "Edit pictures on")
			var cam: Camera3D = player.cam
			_tap(cam.unproject_position(pics.slots[framed_id].c)), 0.8)
		_do(func():
			if framed_id == "": return
			_check(pics.is_custom(framed_id) and pics.source_of(framed_id) == "draft", "a tap on the ad puts the chosen picture on it at once (draft)")
			var pn := _print_node(framed_id)
			var ab := pn.get_aabb() if pn else AABB()
			var s: Dictionary = pics.slots[framed_id]
			var sz := ab.size
			var w: float = absf(sz.dot(s.r.abs()))
			var h := sz.y
			_check(pn != null and absf(w / h - 1024.0 / 600.0) < 0.02 and absf(maxf(w, h) - 1.15) < 0.01, "the print takes the picture's aspect, 1.15 m long side (%.3f x %.3f)" % [w, h])
			_check(_black_tris() < black_before and _black_tris() > 0, "the old frame is taken out of the mesh, the other frames stay (%d -> %d triangles)" % [black_before, _black_tris()])
			var frame_ok := false
			for nd in pics.made[framed_id]:
				if str(nd.get_meta("pic_part", "")) == "PicFrame":
					var fa: AABB = nd.get_aabb()
					frame_ok = absf(fa.size.y - (h + 2 * 0.06 + 2 * 0.045)) < 0.01
			_check(frame_ok, "the new frame wraps the picture with the same mat and rails")
			var dj = JSON.parse_string(str(Engine.get_meta("mall_pictures_draft", "")))
			_check(dj is Dictionary and dj.has(framed_id), "the draft is kept in this browser's storage")
			_shot("framed-after"), 0.3)
		# a portrait picture: the frame follows
		_do(func():
			if framed_id == "": return
			pick_answer = _picture(500, 900, Color(0.15, 0.45, 0.3))
			pics.choose(framed_id), 0.5)
		_do(func():
			if framed_id == "": return
			var pn := _print_node(framed_id)
			_check(pn != null and pn.get_aabb().size.y > 1.14, "a portrait picture: the frame turns upright")
			_shot("framed-portrait"), 0.3)
		# a reload keeps the draft
		_do(func(): _load(true), 4.0)
		_do(func():
			if framed_id == "": return
			_hook()
			_check(pics.is_custom(framed_id), "after a reload the draft picture is still up")
			_face(framed_id, 2.6), 0.6)
		# reset to the original
		_do(func():
			if framed_id == "": return
			pick_answer = {"reset": true}
			pics.choose(framed_id), 0.5)
		_do(func():
			if framed_id == "": return
			_check(not pics.is_custom(framed_id) and not pics.draft.has(framed_id) and pics.framed_mi.mesh == pics.framed_orig, "Original picture: the ad and its frame are back as built")
			_shot("framed-reset"), 0.3)
		# publish (mocked)
		_do(func():
			if framed_id == "": return
			pick_answer = _picture(1024, 600, Color(0.75, 0.15, 0.2))
			pics.choose(framed_id)
			pics.publish(), 0.5)
		_do(func():
			if framed_id == "": return
			_check(published_with is Dictionary and published_with.has(framed_id) and str(published_with[framed_id].data).begins_with("data:image/"), "Publish hands the draft (the picture data) to the publisher")
			_check(pics.draft.is_empty() and pics.published.has(framed_id) and pics.is_custom(framed_id), "after publishing: no draft left, the picture is the published one and still up")
			# a published picture reset: a draft "reset" until published
			pick_answer = {"reset": true}
			pics.choose(framed_id)
			_check(pics.draft.get(framed_id, {}).get("reset", false) and not pics.is_custom(framed_id), "resetting a published picture: the original shows, a reset waits to be published")
			, 0.3)
	_do(func():
		_hook()      # (after a reload, the scene's new Pictures node)
		if panel_id != "":
			_face(panel_id, 2.2)
		, 0.8)
	_do(func():
		if panel_id == "":
			return
		_shot("panel-before")
		pick_answer = _picture(800, 800, Color(0.85, 0.55, 0.1))
		pics.set_editing(true)     # (the reload above made a new Pictures node)
		var cc: Vector2 = player.cam.unproject_position(pics.slots[panel_id].c)
		_tap(player.cam.unproject_position(pics.slots[panel_id].c)), 0.8)
	_do(func():
		if panel_id == "":
			return
		_check(pics.is_custom(panel_id), "a tap on a poster panel (%s) puts the picture on it" % panel_id)
		var s: Dictionary = pics.slots[panel_id]
		var pn := _print_node(panel_id)
		var ab: AABB = pn.get_aabb() if pn else AABB()
		var w: float = absf(ab.size.dot(s.r.abs()))
		var h: float = absf(ab.size.dot(s.u.abs()))
		_check(pn != null and w <= s.w + 0.001 and h <= s.h + 0.001 and absf(w - h) < 0.01, "the picture fits inside the panel, its aspect kept (%.2f x %.2f in %.2f x %.2f)" % [w, h, s.w, s.h])
		_shot("panel-after")
		pics.set_editing(false), 0.3)
	# a visitor: no editing
	_do(func(): _load(false), 4.0)
	_do(func():
		_hook()
		pics.set_editing(true)
		_check(not pics.is_owner and not pics.editing, "a visitor can't turn Edit pictures on")
		_check(pics.draft.is_empty(), "a visitor has no draft (the owner's browser keeps it)"), 0.3)
	_do(func():
		if errors.is_empty():
			print("PICTURES TEST OK (%d checks)" % oks)
		else:
			print("PICTURES TEST FAILED: ", errors)
		quit(0 if errors.is_empty() else 1), 0.0)

func _process(dt: float) -> bool:
	wait -= dt
	while wait <= 0.0 and qi < q.size():
		var s: Array = q[qi]
		qi += 1
		s[0].call()
		wait = s[1]
	return false
