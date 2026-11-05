## The mall directory, read at the kiosk (design/godot-directory.md "Reading the directory";
## Steven chose option B on Nov 4 2026, design/godot-directory-legibility.md). Opened from a
## directory kiosk (scripts/directory_kiosk.gd).
##
## The camera leaves the player and glides to the kiosk, like the talk camera
## (design/godot-dialogue.md), and frames the whole lit sign with the year switch on its frame.
## Then it moves in to the store list at reading size: one column at a time on a phone; the list,
## the legend and the map's edge on a computer. Swipe or the arrows turn the page.
## Picking a name lights it on the sign itself (every list line and map block it has) and the camera
## glides across the sign to the store's block on the map, also lit. Picking the lit store again asks
## "Jump to this store?" in the game menu's style, then jumps (player.jump_to).
##
## No words are added on screen while you read: the sign is the text. The only things drawn over the
## view are an X box (close) and a < box (back), and the jump question. The sign is drawn from a 4x
## picture (tex/dir/hi/panel_<year>.png, tools/stores/directory/paint_dir.py DIR_K=4) on a quad just
## in front of the kiosk's panel, only while reading.
##
## The year switch (MENU2's time travel, scripts/timetravel_trip.gd) is on the kiosk itself: two lit
## keys, 1990s and 2026, on the frame's bottom rail (built by directory_kiosk.gd). Tap a key on the
## whole-sign view, or press Y (keyboard or gamepad) at any time: the sign closes and the trip
## begins from this kiosk.
##
## Controls:
##   touch / mouse: tap a name (or a block on the map); tap the lit store again to ask; swipe left /
##     right to turn the page; < goes back (map -> list -> whole sign); X closes.
##   keys / gamepad: up / down (W S, d-pad, stick) move from store to store down the list, turning the
##     pages; left / right turn the page; Enter / Space / A picks, then asks; Esc / Backspace / B go
##     back, then close; Y travels in time.
##
## Sharpness: on a hidpi screen (scripts/hidpi.gd) the 3D world is drawn at a lower scale; while the
## camera is on the sign it is drawn at full device resolution (the view is then one unshaded quad).
extends Node

const ART_W := 1.02          # tools/stores/directory/kiosk.gd: the lit art
const ART_H := 1.14
const ART_Y := 1.15          # the art's centre above the floor (PLINTH_H + frame + ART_H / 2)
const FACE_Z := 0.153        # the art's face in front of the kiosk's centre (CAB_D / 2 + 0.003)
const CAM_T := 0.6
const FOV := 40.0
const READ_SCALE := 0.72     # screen px per panel px (2048-wide panel) on the list: capitals ~10 px
const MAP_SCALE := 0.54      # the store's block on the map, with its neighbours
const SWITCH_LOW := 0.46     # m: the year switch's lower edge (directory_kiosk.gd), kept in the whole view
const HOLD := 0.8            # s on the whole sign before moving in to the list
const HILITE := Color("#ff2d6f")
# the game menu's colours (scripts/menu/menu.gd)
const M_BG := Color(0.07, 0.055, 0.045, 0.97)
const M_INK := Color(1, 0.97, 0.9)
const M_GOLD := Color(0.93, 0.85, 0.66)
const M_AMBER := Color(0.85, 0.62, 0.22)
const M_BTN := Color(0.2, 0.16, 0.12)
const M_DARK := Color(0.1, 0.07, 0.04)

var player: Node = null
var kiosk: Node3D = null
var is_open := false
var year := "1995"
var spots := {}
var data := {}
var stall_by_id := {}
var psize := Vector2(2048, 2290)

var cam: Camera3D
var from_cam: Camera3D
var from_xf := Transform3D()
var from_fov := 70.0
var quad: MeshInstance3D
var mat: ShaderMaterial
var hidden: Array = []
var layer: CanvasLayer
var hud: Control
var s3d := 1.0

# the view: the panel rectangle (panel px) the camera frames, smoothed toward `want`
var view := Rect2()
var want := Rect2()
var settled := false
var state := "whole"         # "whole", "list", "map"
var sel := ""                # the lit store's unit id
var page := 0
var pages: Array = []        # the list's pages (Rect2, panel px)
var hold_t := 0.0

# the jump question
var confirm := false
var confirm_yes := true
var dlg: Panel
var dlg_title: Label
var dlg_name: Label
var dlg_note: Label
var dlg_yes: Button
var dlg_no: Button

var touches := {}
var drag_from := Vector2.ZERO
var drag_moved := false
var pressed_in := false
var last_touch_ms := -100000
var _stick_held := false

func _ready() -> void:
	var scn := get_parent()
	var gen: String = scn.get_meta("gen", "res://gen/") if scn else "res://gen/"
	if FileAccess.file_exists(gen + "directory.json"):
		data = JSON.parse_string(FileAccess.get_file_as_string(gen + "directory.json"))
	if FileAccess.file_exists("res://tex/dir/hotspots.json"):
		spots = JSON.parse_string(FileAccess.get_file_as_string("res://tex/dir/hotspots.json"))
		psize = Vector2(spots.size[0], spots.size[1])
	for y in data.get("years", {}):
		var m := {}
		for st in data.years[y].stalls:
			m[st.id] = st
		stall_by_id[y] = m
	layer = CanvasLayer.new()
	layer.layer = 25
	add_child(layer)
	hud = Control.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.draw.connect(_draw_hud)
	layer.add_child(hud)
	_build_dialog()

# ------------------------------------------------------------------ geometry
func _face() -> Vector3:
	var f: Vector2 = kiosk.get_meta("face", Vector2(0, 1))
	return Vector3(f.x, 0, f.y).normalized()

func _right() -> Vector3:
	return (-_face()).cross(Vector3.UP).normalized()

## A panel pixel (may be outside the panel) to its point on the 3D sign's plane.
func _p2w(p: Vector2) -> Vector3:
	var c := kiosk.global_position + _face() * FACE_Z + Vector3.UP * ART_Y
	return c + _right() * (p.x / psize.x - 0.5) * ART_W + Vector3.UP * (0.5 - p.y / psize.y) * ART_H

func _vp() -> Vector2:
	return get_viewport().get_visible_rect().size

## The camera that frames panel rect r (centred, all of it visible).
func _frame(r: Rect2) -> Transform3D:
	var vp := _vp()
	var tv := tan(deg_to_rad(FOV) * 0.5)
	var th := tv * vp.x / vp.y
	var w := r.size.x / psize.x * ART_W
	var h := r.size.y / psize.y * ART_H
	var d: float = max(h * 0.5 / tv, w * 0.5 / th)
	return Transform3D(Basis.looking_at(-_face(), Vector3.UP), _p2w(r.get_center()) + _face() * d)

## A rect of the viewport's shape, centred at c, s screen px per panel px.
func _rect_at(c: Vector2, s: float) -> Rect2:
	var sz := _vp() / s
	return Rect2(c - sz * 0.5, sz)

## The smallest view of the viewport's shape holding r, with a margin.
func _fit(r: Rect2, margin := 1.08) -> Rect2:
	var vp := _vp()
	var s: float = min(vp.x / (r.size.x * margin), vp.y / (r.size.y * margin))
	return _rect_at(r.get_center(), s)

## The whole sign with the year switch below it (directory_kiosk.gd SWITCH_Y: 0.06 m under the art).
func _whole() -> Rect2:
	var below := (ART_Y - ART_H * 0.5 - SWITCH_LOW) / ART_H * psize.y
	return _fit(Rect2(Vector2(0, 0), Vector2(psize.x, psize.y + below)), 1.1)

func _scale() -> float:
	return _vp().x / view.size.x

func _p2s(p: Vector2) -> Vector2:
	return (p - view.position) * _scale()

# ------------------------------------------------------------------ open / close
func open(p: Node, k: Node3D) -> void:
	if is_open or spots.is_empty() or data.is_empty():
		return
	if p and p.get("vr_on"):
		return
	player = p
	kiosk = k
	is_open = true
	sel = ""
	confirm = false
	dlg.visible = false
	state = "whole"
	page = 0
	year = str(p.get("year")) if p and p.get("year") != null else "1995"
	if not stall_by_id.has(year):
		year = "1995"
	_freeze(true)
	_sharp(true)
	_make_quad()
	from_cam = get_viewport().get_camera_3d()
	if from_cam == null and p:
		from_cam = p.get("cam")
	from_xf = from_cam.global_transform
	from_fov = from_cam.fov
	if cam == null:
		cam = Camera3D.new()
		cam.name = "DirectoryCam"
		cam.near = 0.02
		cam.far = 200.0
		get_parent().add_child(cam)
	cam.global_transform = from_xf
	cam.fov = from_fov
	cam.current = true
	_make_pages()
	view = _whole()
	want = view
	settled = false
	hold_t = HOLD
	pressed_in = false
	touches.clear()
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tw.tween_method(_intro_step, 0.0, 1.0, CAM_T)
	tw.tween_callback(func(): settled = true; hud.queue_redraw())
	hud.queue_redraw()

func _intro_step(t: float) -> void:
	cam.global_transform = from_xf.interpolate_with(_frame(view), t)
	cam.fov = lerp(from_fov, FOV, t)

## Close: the camera glides back to the player.
func close() -> void:
	if not is_open:
		return
	is_open = false
	settled = false
	confirm = false
	dlg.visible = false
	hud.queue_redraw()
	var from := cam.global_transform
	var back := from_cam.global_transform if is_instance_valid(from_cam) else from_xf
	var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tw.tween_method(func(t: float): cam.global_transform = from.interpolate_with(back, t), 0.0, 1.0, CAM_T * 0.8)
	tw.tween_property(cam, "fov", from_fov, CAM_T * 0.8)
	await tw.finished
	if is_open:
		return
	_restore()

## Back to the player's own view at once (a jump or a trip takes over).
func _restore() -> void:
	is_open = false
	settled = false
	if is_instance_valid(from_cam):
		from_cam.current = true
	if quad:
		quad.visible = false
		mat.set_shader_parameter("tex", null)   # the 4x picture is only in memory while reading
	_sharp(false)
	_freeze(false)
	hud.queue_redraw()

func _freeze(on: bool) -> void:
	if on:
		player.set("frozen", true)
		player.set("move_vec", Vector2.ZERO)
		player.set("move_touch", -1)
		player.set("look_touch", -1)
		player.set("dragging", false)
		var st = player.get("stick")
		if st:
			st.visible = false
		hidden.clear()
		for n in get_tree().root.find_children("*", "CanvasLayer", true, false):
			if n != layer and n.visible and n.layer < 100:
				n.visible = false
				hidden.append(n)
	else:
		for n in hidden:
			if is_instance_valid(n):
				n.visible = true
		hidden.clear()
		player.set("frozen", false)

func _sharp(on: bool) -> void:
	var vpt := get_viewport()
	if on:
		add_to_group("hidpi_full")       # scripts/hidpi.gd leaves the scale alone meanwhile
		s3d = vpt.scaling_3d_scale
		vpt.scaling_3d_scale = 1.0
	else:
		remove_from_group("hidpi_full")
		vpt.scaling_3d_scale = s3d

# ------------------------------------------------------------------ the sign, sharper and lit
const SHADER := """
shader_type spatial;
render_mode unshaded, cull_back;
uniform sampler2D tex : source_color, filter_linear_mipmap_anisotropic;
uniform vec4 rects[16];
uniform int n = 0;
uniform vec4 hi : source_color = vec4(1.0, 0.176, 0.435, 1.0);
void fragment() {
	vec3 c = texture(tex, UV).rgb * vec3(0.93, 0.95, 0.97);
	vec2 px = fwidth(UV);
	for (int i = 0; i < 16; i++) {
		if (i >= n) { break; }
		vec4 r = rects[i];
		if (UV.x >= r.x && UV.x <= r.z && UV.y >= r.y && UV.y <= r.w) {
			c = mix(c, hi.rgb, 0.16);
			float e = min(min(UV.x - r.x, r.z - UV.x) / px.x, min(UV.y - r.y, r.w - UV.y) / px.y);
			if (e < 2.5) { c = hi.rgb; }
		}
	}
	ALBEDO = c;
}
"""

func _make_quad() -> void:
	if quad == null:
		quad = MeshInstance3D.new()
		var qm := QuadMesh.new()
		qm.size = Vector2(ART_W, ART_H)
		quad.mesh = qm
		mat = ShaderMaterial.new()
		var sh := Shader.new()
		sh.code = SHADER
		mat.shader = sh
		quad.material_override = mat
		quad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		get_parent().add_child(quad)
	var f := _face()
	quad.global_transform = Transform3D(Basis(_right(), Vector3.UP, f), kiosk.global_position + f * (FACE_Z + 0.003) + Vector3.UP * ART_Y)
	var path := "res://tex/dir/hi/panel_%s.png" % year
	if not ResourceLoader.exists(path):
		path = "res://tex/dir/panel_%s.png" % year
	mat.set_shader_parameter("tex", load(path))
	quad.visible = true
	_light()

func _light() -> void:
	var rs: Array = []
	if sel != "":
		for h in _hot():
			if h.id == sel and rs.size() < 16:
				var g := 4.0
				rs.append(Vector4((h.rect[0] - g) / psize.x, (h.rect[1] - g) / psize.y, (h.rect[2] + g) / psize.x, (h.rect[3] + g) / psize.y))
	var n := rs.size()
	while rs.size() < 16:
		rs.append(Vector4.ZERO)
	mat.set_shader_parameter("rects", rs)
	mat.set_shader_parameter("n", n)

func _hot() -> Array:
	return spots.get(year, [])

func _stall(id: String):
	return stall_by_id.get(year, {}).get(id, null)

# ------------------------------------------------------------------ the pages and the map
## The list's columns (its lines clustered by x), with room for the headings and the title.
func _columns() -> Array:
	var xs := []
	for h in _hot():
		if h.kind == "list":
			xs.append(h)
	xs.sort_custom(func(a, b): return a.rect[0] < b.rect[0])
	var cols := []
	for h in xs:
		var hr := Rect2(h.rect[0], h.rect[1], h.rect[2] - h.rect[0], h.rect[3] - h.rect[1])
		if cols.is_empty() or h.rect[0] - cols[-1].position.x > 150:
			cols.append(hr)
		else:
			cols[-1] = cols[-1].merge(hr)
	var out := []
	for c in cols:
		out.append(c.grow_individual(40, 150, 20, 30))   # 150: the STORES BY CATEGORY title above
	return out

## Reading-size views over the list, in reading order: as many columns side by side as fit the
## screen at READ_SCALE, then down those columns a screen at a time.
func _make_pages() -> void:
	pages.clear()
	var vsz := _vp() / READ_SCALE
	var cols := _columns()
	var i := 0
	while i < cols.size():
		var grp: Rect2 = cols[i]
		var j := i + 1
		while j < cols.size() and grp.merge(cols[j]).size.x <= vsz.x:
			grp = grp.merge(cols[j])
			j += 1
		var x := grp.get_center().x - vsz.x * 0.5
		var y := grp.position.y
		if vsz.y >= grp.size.y:
			y = grp.get_center().y - vsz.y * 0.5
		while true:
			if y + vsz.y > grp.end.y and y > grp.position.y:
				y = max(grp.position.y, grp.end.y - vsz.y)   # the last page ends with the list
			pages.append(Rect2(Vector2(x, y), vsz))
			if y + vsz.y >= grp.end.y:
				break
			y += vsz.y * 0.88
		i = j

func _show_whole() -> void:
	state = "whole"
	want = _whole()
	hud.queue_redraw()

func _show_page(i: int) -> void:
	if pages.is_empty():
		return
	if i < 0:
		_show_whole()
		return
	page = clampi(i, 0, pages.size() - 1)
	state = "list"
	hold_t = 0.0
	want = pages[page]
	hud.queue_redraw()

## The page holding the selected store's first list line.
func _page_of(id: String) -> int:
	for h in _hot():
		if h.id == id and h.kind == "list":
			var c := Vector2((h.rect[0] + h.rect[2]) * 0.5, (h.rect[1] + h.rect[3]) * 0.5)
			for i in pages.size():
				if pages[i].grow(-10).has_point(c):
					return i
	return page

## The selected store's block on the map. When its lit list line fits in the same view at a readable
## size (a computer, a phone held sideways), the camera keeps both; otherwise the block and its
## neighbours (the line stays lit on the page it came from).
func _show_map() -> void:
	var blk := Rect2()
	var lines := []
	for h in _hot():
		if h.id != sel:
			continue
		var r := Rect2(h.rect[0], h.rect[1], h.rect[2] - h.rect[0], h.rect[3] - h.rect[1])
		if h.kind == "map" and blk.size == Vector2.ZERO:
			blk = r
		elif h.kind == "list":
			lines.append(r)
	if blk.size == Vector2.ZERO:
		return
	state = "map"
	hold_t = 0.0
	# of the store's list lines (a store can be listed twice), the one that frames closest with its block
	var both := Rect2()
	for line in lines:
		var b := _fit(blk.merge(line).grow(60), 1.0)
		if both.size == Vector2.ZERO or b.size.x < both.size.x:
			both = b
	if both.size != Vector2.ZERO and _vp().x / both.size.x >= 0.5:
		want = both
	else:
		want = _rect_at(blk.get_center(), MAP_SCALE)
	hud.queue_redraw()

# ------------------------------------------------------------------ every frame
func _process(dt: float) -> void:
	if not is_open or not settled:
		return
	if state == "whole" and hold_t > 0.0:
		hold_t -= dt
		if hold_t <= 0.0:
			_show_page(0)
	var k := 1.0 - exp(-dt * 7.0)
	view = Rect2(view.position.lerp(want.position, k), view.size.lerp(want.size, k))
	cam.global_transform = _frame(view)

# ------------------------------------------------------------------ the boxes and the question
func _btns() -> Array:
	if confirm:
		return []
	var vp := _vp()
	var out := [[Rect2(vp.x - 52, 8, 44, 36), "X"]]
	if state != "whole":
		out.append([Rect2(8, 8, 44, 36), "<"])
	return out

func _draw_hud() -> void:
	if not is_open or not settled:
		return
	var f: Font = load("res://fonts/sans.otf")
	for b in _btns():
		var r: Rect2 = b[0]
		hud.draw_rect(r, Color(0.12, 0.13, 0.15, 0.85))
		hud.draw_rect(r, Color(1, 1, 1, 0.8), false, 1.5)
		var sz := f.get_string_size(b[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 16)
		hud.draw_string(f, r.get_center() + Vector2(-sz.x * 0.5, 6), b[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)

## The jump question, in the game menu's look (scripts/menu/menu.gd: its brown ground, cream and
## gold type, amber for the chosen button, rounded corners). Its buttons are hit by hand in _input.
func _build_dialog() -> void:
	dlg = Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = M_BG
	sb.set_border_width_all(2)
	sb.border_color = Color(M_GOLD, 0.5)
	sb.set_corner_radius_all(10)
	dlg.add_theme_stylebox_override("panel", sb)
	dlg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dlg.visible = false
	layer.add_child(dlg)
	dlg_title = _label("Jump to this store?", 21, M_INK)
	dlg_name = _label("", 19, M_GOLD)
	dlg_note = _label("", 13, Color(M_INK, 0.6))
	dlg_yes = _button("Yes, go there")
	dlg_no = _button("Cancel")

func _label(t: String, fs: int, col: Color) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", col)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dlg.add_child(l)
	return l

func _button(t: String) -> Button:
	var b := Button.new()
	b.text = t
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_theme_font_size_override("font_size", 17)
	dlg.add_child(b)
	return b

func _paint(b: Button, on: bool) -> void:
	var bg := M_AMBER if on else M_BTN
	var fg := M_DARK if on else M_INK
	for st in ["normal", "hover", "pressed", "disabled", "focus"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = bg
		sb.set_corner_radius_all(8)
		b.add_theme_stylebox_override(st, sb)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(c, fg)

func _ask() -> void:
	var st = _stall(sel)
	if st == null:
		return
	confirm = true
	confirm_yes = true
	var nm := String(st.name)
	if year == "1995" and int(st.num) > 0:
		nm = "%d  %s" % [int(st.num), st.name]
	dlg_name.text = nm
	var j: Array = st.jump
	var other := player and (int(j[0]) != int(player.get("wing")) or year != str(player.get("year")))
	dlg_note.text = ("Loads Wing %d" % int(j[0])) if other else ""
	_layout_dialog()
	dlg.visible = true
	hud.queue_redraw()

func _layout_dialog() -> void:
	var vp := _vp()
	var w: float = min(420.0, vp.x - 32.0)
	var h := 196.0
	dlg.position = Vector2((vp.x - w) * 0.5, vp.y * 0.5 - h * 0.5)
	dlg.size = Vector2(w, h)
	dlg_title.position = Vector2(0, 18); dlg_title.size = Vector2(w, 30)
	dlg_name.position = Vector2(0, 54); dlg_name.size = Vector2(w, 28)
	dlg_note.position = Vector2(0, 84); dlg_note.size = Vector2(w, 20)
	var bw := (w - 48.0) * 0.5
	dlg_yes.position = Vector2(16, h - 66); dlg_yes.size = Vector2(bw, 48)
	dlg_no.position = Vector2(32 + bw, h - 66); dlg_no.size = Vector2(bw, 48)
	_paint(dlg_yes, confirm_yes)
	_paint(dlg_no, not confirm_yes)

func _answer(yes: bool) -> void:
	confirm = false
	dlg.visible = false
	hud.queue_redraw()
	if yes:
		_jump()

func _jump() -> void:
	var st = _stall(sel)
	if st == null:
		return
	var j: Array = st.jump
	print("directory jump: ", st.name, " (", year, ") -> wing ", j[0], " at ", j[1], ",", j[2], " yaw ", j[3])
	var p := player
	_restore()
	if p and p.has_method("jump_to"):
		p.jump_to(int(j[0]), int(year), float(j[1]), float(j[2]), float(j[3]))

## The year switch: the sign closes and the trip to this kiosk's twin in the other year begins
## (scripts/timetravel_trip.gd, MENU2).
func travel() -> void:
	if player == null or confirm or not is_open:
		return
	var p := player
	var k := kiosk
	print("directory: year switch -> trip from ", year)
	_restore()
	load("res://scripts/timetravel_trip.gd").begin(p, k)

# ------------------------------------------------------------------ input
func _input(e: InputEvent) -> void:
	if not is_open:
		return
	get_viewport().set_input_as_handled()
	if not settled:
		return
	if e is InputEventKey and e.pressed and not e.echo:
		_key(e.physical_keycode)
	elif e is InputEventJoypadButton and e.pressed:
		_pad(e.button_index)
	elif e is InputEventJoypadMotion:
		_stick(e)
	elif e is InputEventScreenTouch:
		last_touch_ms = Time.get_ticks_msec()
		if e.pressed:
			touches[e.index] = e.position
			if touches.size() == 1:
				_press(e.position)
		else:
			touches.erase(e.index)
			if touches.is_empty():
				_release(e.position)
	elif e is InputEventScreenDrag:
		last_touch_ms = Time.get_ticks_msec()
		touches[e.index] = e.position
		_move(e.position)
	elif e is InputEventMouseButton:
		if Time.get_ticks_msec() - last_touch_ms < 600 or e.button_index != MOUSE_BUTTON_LEFT:
			return
		if e.pressed:
			_press(e.position)
		else:
			_release(e.position)
	elif e is InputEventMouseMotion and e.button_mask & MOUSE_BUTTON_MASK_LEFT:
		if Time.get_ticks_msec() - last_touch_ms < 600:
			return
		_move(e.position)

func _key(k: int) -> void:
	if confirm:
		match k:
			KEY_LEFT, KEY_RIGHT, KEY_A, KEY_D, KEY_TAB:
				confirm_yes = not confirm_yes
				_layout_dialog()
			KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_E:
				_answer(confirm_yes)
			KEY_ESCAPE, KEY_BACKSPACE:
				_answer(false)
		return
	match k:
		KEY_ESCAPE, KEY_BACKSPACE:
			_back()
		KEY_UP, KEY_W:
			_step(-1)
		KEY_DOWN, KEY_S:
			_step(1)
		KEY_LEFT, KEY_A:
			_turn(-1)
		KEY_RIGHT, KEY_D:
			_turn(1)
		KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_E:
			_enter()
		KEY_Y:
			travel()

func _pad(b: int) -> void:
	if confirm:
		match b:
			JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_DPAD_RIGHT:
				confirm_yes = not confirm_yes
				_layout_dialog()
			JOY_BUTTON_A:
				_answer(confirm_yes)
			JOY_BUTTON_B:
				_answer(false)
		return
	match b:
		JOY_BUTTON_B, JOY_BUTTON_BACK:
			_back()
		JOY_BUTTON_DPAD_UP:
			_step(-1)
		JOY_BUTTON_DPAD_DOWN:
			_step(1)
		JOY_BUTTON_DPAD_LEFT:
			_turn(-1)
		JOY_BUTTON_DPAD_RIGHT:
			_turn(1)
		JOY_BUTTON_A:
			_enter()
		JOY_BUTTON_Y:
			travel()

func _stick(e: InputEventJoypadMotion) -> void:
	if e.axis != JOY_AXIS_LEFT_X and e.axis != JOY_AXIS_LEFT_Y:
		return
	if abs(e.axis_value) < 0.3:
		_stick_held = false
		return
	if _stick_held or abs(e.axis_value) < 0.6:
		return
	_stick_held = true
	var d := int(signf(e.axis_value))
	if confirm:
		if e.axis == JOY_AXIS_LEFT_X:
			confirm_yes = not confirm_yes
			_layout_dialog()
	elif e.axis == JOY_AXIS_LEFT_Y:
		_step(d)
	else:
		_turn(d)

## Back: the map to the list, the list to the whole sign, the whole sign closes.
func _back() -> void:
	match state:
		"map":
			_show_page(page)
		"list":
			_show_whole()
		_:
			close()

## Enter / A: the whole sign moves in to the list; a store lit on the list goes to its block; on the
## map it asks.
func _enter() -> void:
	if state == "whole":
		_show_page(0)
	elif state == "map" and sel != "":
		_ask()
	elif sel != "":
		_show_map()
	else:
		_step(1)

## Turn the page (on the map: back to the list first).
func _turn(d: int) -> void:
	if state == "map":
		_show_page(page)
	elif state == "whole":
		if d > 0:
			_show_page(0)
	else:
		_show_page(page + d)

## The next / previous store down the list (the sign's own order), turning the pages with it.
func _step(d: int) -> void:
	var ids := []
	for h in _hot():
		if h.kind == "list" and not (h.id in ids) and _stall(h.id) != null:
			ids.append(h.id)
	if ids.is_empty():
		return
	var i := ids.find(sel)
	sel = ids[(i + d + ids.size()) % ids.size()] if i >= 0 else ids[0]
	_light()
	_show_page(_page_of(sel))

func _press(p: Vector2) -> void:
	drag_from = p
	drag_moved = false
	pressed_in = true

func _move(p: Vector2) -> void:
	if (p - drag_from).length() > 12.0:
		drag_moved = true

func _release(p: Vector2) -> void:
	if not pressed_in:
		return
	pressed_in = false
	if confirm:
		if Rect2(dlg.position + dlg_yes.position, dlg_yes.size).has_point(p):
			_answer(true)
		elif Rect2(dlg.position + dlg_no.position, dlg_no.size).has_point(p):
			_answer(false)
		elif not Rect2(dlg.position, dlg.size).has_point(p):
			_answer(false)
		return
	if drag_moved:
		drag_moved = false
		# a sideways swipe turns the page
		var dx := p.x - drag_from.x
		if absf(dx) > 50.0 and absf(dx) > absf(p.y - drag_from.y):
			_turn(1 if dx < 0 else -1)
		return
	for b in _btns():
		if (b[0] as Rect2).has_point(p):
			if b[1] == "X":
				close()
			else:
				_back()
			return
	if kiosk.has_method("switch_key_at"):
		var y: String = kiosk.switch_key_at(cam.project_ray_origin(p), cam.project_ray_normal(p))
		if y != "":
			if y != year:
				travel()
			return
	var id := _hit(p)
	if id == "":
		if state == "map":
			_show_page(page)
		elif state == "whole":
			_show_page(0)
		return
	_pick(id)

## A tap on a store: on the list it lights and the camera goes to its block; on the map a tap on the
## lit store asks, a tap on another block lights that one.
func _pick(id: String) -> void:
	if id == sel and state == "map":
		_ask()
		return
	sel = id
	_light()
	if state != "map":
		page = _page_of(id)
	_show_map()

## The store under a screen point: the ray from the camera onto the sign's plane, then the click
## areas (a list line before a map block, the smallest block first).
func _hit(s: Vector2) -> String:
	var o := cam.project_ray_origin(s)
	var d := cam.project_ray_normal(s)
	var f := _face()
	var c := kiosk.global_position + f * FACE_Z + Vector3.UP * ART_Y
	var den := d.dot(f)
	if absf(den) < 1e-5:
		return ""
	var w := o + d * ((c - o).dot(f) / den) - c
	var p := Vector2((w.dot(_right()) / ART_W + 0.5) * psize.x, (0.5 - w.y / ART_H) * psize.y)
	var best := ""
	var best_a := 1e12
	for h in _hot():
		var r: Array = h.rect
		if p.x >= r[0] and p.x <= r[2] and p.y >= r[1] and p.y <= r[3]:
			var a: float = (r[2] - r[0]) * (r[3] - r[1]) * (0.01 if h.kind == "list" else 1.0)
			if a < best_a and _stall(h.id) != null:
				best_a = a
				best = h.id
	return best

## Where a store's click area is on screen now (tests).
func screen_of(id: String, kind: String) -> Vector2:
	for h in _hot():
		if h.id == id and h.kind == kind:
			return cam.unproject_position(_p2w(Vector2((h.rect[0] + h.rect[2]) * 0.5, (h.rect[1] + h.rect[3]) * 0.5)))
	return Vector2(-1, -1)

## A store's unit id by its name on the sign (tests).
func id_of(name: String) -> String:
	for h in _hot():
		var st = _stall(h.id)
		if st and String(st.name) == name:
			return h.id
	return ""
