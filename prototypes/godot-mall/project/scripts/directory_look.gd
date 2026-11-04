## PROTOTYPE (ws/directory, Nov 4 2026; design/godot-directory-legibility.md). Not the final feature:
## three ways to read the directory kiosk with the camera on the sign, for Steven to choose from.
## Off unless asked for:   web  ?dirlook=a|b|c       native  -- --dirlook=a|b|c
##
##   a  "Face the sign": the camera glides to the kiosk and frames the whole lit panel (a 4x
##      texture, tex/dir/hi/). Wheel / pinch dolly the camera in, drag pans, a tap on the sign picks
##      the store (lit on the sign itself), a second tap jumps.
##   b  "List, then map": the camera frames the whole sign, then moves in to the store list at
##      reading size (a page: one column on a phone, the list and part of the map on a computer).
##      Swipe / arrows turn the page. Picking a line lights it and the camera glides across the sign
##      to the store's block on the map, lit; a second tap jumps, back returns to the list.
##   c  "Camera in, then the flat copy": the camera glides to the kiosk as in a, and on arrival the
##      existing reading view (scripts/directory_ui.gd) takes over, its panel laid exactly over the
##      3D one so nothing jumps; then its own zoom, pan, tap and "Jump to this store?" work as today.
##      On a phone it opens zoomed to the list.
## No new words on the screen: the only things drawn over the view are a close (X) and, in b, a back
## (<) box. Store names are the sign's own type.
extends Node

const ART_W := 1.02          # tools/stores/directory/kiosk.gd: the lit art
const ART_H := 1.14
const ART_Y := 1.15          # the art's centre above the floor (PLINTH_H + frame + ART_H / 2)
const FACE_Z := 0.153        # the art's face in front of the kiosk's centre (CAB_D / 2 + 0.003)
const CAM_T := 0.6
const FOV := 40.0
const READ_SCALE := 0.72     # b: screen px per panel px (2048 wide panel) on the list: caps ~10 px
const HI := Color("#ff2d6f")

var mode := ""
var player: Node = null
var kiosk: Node3D = null
var is_open := false
var year := "2026"
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

# the view: the panel rectangle (panel px) the camera frames; smoothed toward `want`
var view := Rect2()
var want := Rect2()
var intro := 0.0             # 0..1 while the camera comes in
var settled := false

var sel := ""
var page := 0
var pages: Array = []        # b: the list pages (Rect2, panel px)
var at_map := false          # b: looking at the selected store's block

var s3d := 1.0               # the 3D render scale outside the directory (see _sharp)
var touches := {}
var drag_from := Vector2.ZERO
var drag_moved := false
var pinch_d := 0.0
var last_touch_ms := -100000

static func flag() -> String:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--dirlook="):
			return a.substr(10)
	if Engine.has_meta("dirlook"):
		return str(Engine.get_meta("dirlook"))
	if OS.has_feature("web"):
		return str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('dirlook') || ''"))
	return ""

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
	layer.layer = 26
	add_child(layer)
	hud = Control.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.draw.connect(_draw_hud)
	layer.add_child(hud)

# ------------------------------------------------------------------ geometry
func _face() -> Vector3:
	var f: Vector2 = kiosk.get_meta("face", Vector2(0, 1))
	return Vector3(f.x, 0, f.y).normalized()

func _right() -> Vector3:
	return (-_face()).cross(Vector3.UP).normalized()

## A panel pixel to its point on the 3D sign.
func _p2w(p: Vector2) -> Vector3:
	var c := kiosk.global_position + _face() * FACE_Z + Vector3.UP * ART_Y
	return c + _right() * (p.x / psize.x - 0.5) * ART_W + Vector3.UP * (0.5 - p.y / psize.y) * ART_H

func _vp() -> Vector2:
	return get_viewport().get_visible_rect().size

## The camera that frames panel rect r (centred, whole rect visible).
func _frame(r: Rect2) -> Transform3D:
	var vp := _vp()
	var tv := tan(deg_to_rad(FOV) * 0.5)
	var th := tv * vp.x / vp.y
	var w := r.size.x / psize.x * ART_W
	var h := r.size.y / psize.y * ART_H
	var d: float = max(h * 0.5 / tv, w * 0.5 / th)
	var at := _p2w(r.get_center()) + _face() * d
	return Transform3D(Basis.looking_at(-_face(), Vector3.UP), at)

## A rect of the viewport's aspect, centred at c, s screen px per panel px.
func _rect_at(c: Vector2, s: float) -> Rect2:
	var sz := _vp() / s
	return Rect2(c - sz * 0.5, sz)

## The whole sign with a margin round the frame.
func _whole() -> Rect2:
	var vp := _vp()
	var s: float = min(vp.x / (psize.x * 1.16), vp.y / (psize.y * 1.16))
	return _rect_at(psize * 0.5, s)

## Screen px per panel px for the current view.
func _scale() -> float:
	return _vp().x / view.size.x

func _s2p(s: Vector2) -> Vector2:
	return view.position + s / _scale()

func _p2s(p: Vector2) -> Vector2:
	return (p - view.position) * _scale()

# ------------------------------------------------------------------ open / close
func open(p: Node, k: Node3D, m: String) -> void:
	if is_open or spots.is_empty():
		return
	player = p
	kiosk = k
	mode = m
	is_open = true
	sel = ""
	at_map = false
	page = 0
	year = str(p.get("year")) if p and p.get("year") != null else "1995"
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
	view = _whole()
	want = view
	if mode == "b":
		_make_pages()
	intro = 0.0
	settled = false
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tw.tween_method(_intro_step, 0.0, 1.0, CAM_T)
	tw.tween_callback(_arrived)
	hud.queue_redraw()

func _intro_step(t: float) -> void:
	intro = t
	cam.global_transform = from_xf.interpolate_with(_frame(view), t)
	cam.fov = lerp(from_fov, FOV, t)

func _arrived() -> void:
	settled = true
	match mode:
		"b":
			# a beat on the whole sign, then in to the list
			await get_tree().create_timer(0.5).timeout
			if is_open and not pages.is_empty():
				want = pages[0]
		"c":
			_hand_to_flat()
	hud.queue_redraw()

func close() -> void:
	if not is_open:
		return
	is_open = false
	settled = false
	var from := cam.global_transform
	var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tw.tween_method(func(t: float): cam.global_transform = from.interpolate_with(from_xf, t), 0.0, 1.0, CAM_T * 0.8)
	tw.tween_property(cam, "fov", from_fov, CAM_T * 0.8)
	await tw.finished
	if is_instance_valid(from_cam):
		from_cam.current = true
	if quad:
		quad.visible = false
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
			if n != layer and n.visible and n.layer < 100 and n.name != "DirectoryUI":
				n.visible = false
				hidden.append(n)
	else:
		for n in hidden:
			if is_instance_valid(n):
				n.visible = true
		hidden.clear()
		player.set("frozen", false)

## On a device-pixel (hidpi) screen the 3D world may be drawn at a lower scale to save the GPU; while
## the camera is on the sign (a, b) it is drawn at full device resolution, since the sign fills the
## view and is unshaded (cheap). c reads on the 2D layer, which is always at device resolution.
func _sharp(on: bool) -> void:
	var vpt := get_viewport()
	if on:
		s3d = vpt.scaling_3d_scale
		if mode != "c":
			vpt.scaling_3d_scale = 1.0
	else:
		vpt.scaling_3d_scale = s3d

# ------------------------------------------------------------------ the sharper sign
## A quad 3 mm in front of the kiosk's panel with the 4x texture and the lit selection. Only while
## reading, so the big texture is only in memory then.
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
	quad.visible = mode != "c"
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

# ------------------------------------------------------------------ c: the flat copy takes over
func _hand_to_flat() -> void:
	var ui: Node = kiosk._ui()
	# the 3D panel's rectangle on screen, from the camera
	var a := cam.unproject_position(_p2w(Vector2.ZERO))
	var b := cam.unproject_position(_p2w(psize))
	ui.set("look_rect", Rect2(a, b - a))
	ui.set("look_owner", self)
	ui.view.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS   # no shimmer when drawn small
	ui.open(player, kiosk)
	if ui.get("_narrow") != null and ui._narrow():
		# phones: open on the list, at reading size
		var lst := _list_bounds()
		ui._zoom_by(READ_SCALE / ui._scale(), ui._p2s(lst.position + Vector2(lst.size.x * 0.25, 0)))
		ui.pan = Vector2(lst.position.x + ui._vp().x * 0.5 / ui._scale() - 20.0, lst.position.y + ui._vp().y * 0.5 / ui._scale() - 40.0)
		ui._clamp_pan()
		ui.view.queue_redraw()

## directory_ui.gd calls this when its view closes (c).
func flat_closed() -> void:
	close()

# ------------------------------------------------------------------ b: the pages
func _list_bounds() -> Rect2:
	var r := Rect2()
	for h in _hot():
		if h.kind != "list":
			continue
		var hr := Rect2(h.rect[0], h.rect[1], h.rect[2] - h.rect[0], h.rect[3] - h.rect[1])
		r = hr if r.size == Vector2.ZERO else r.merge(hr)
	return r.grow_individual(40, 90, 20, 30)

## The list's columns (list lines clustered by x), each with room for its headings.
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
## screen at READ_SCALE, then down the columns a screen at a time.
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

func _show_page(i: int) -> void:
	page = clampi(i, 0, pages.size() - 1)
	at_map = false
	want = pages[page]

## The selected store's block on the map, framed with its neighbours.
func _show_map() -> void:
	for h in _hot():
		if h.id == sel and h.kind == "map":
			var c := Vector2((h.rect[0] + h.rect[2]) * 0.5, (h.rect[1] + h.rect[3]) * 0.5)
			want = _rect_at(c, READ_SCALE * 0.75)
			at_map = true
			return

# ------------------------------------------------------------------ every frame
func _process(dt: float) -> void:
	if not is_open or not settled or mode == "c":
		return
	var k := 1.0 - exp(-dt * 7.0)
	view = Rect2(view.position.lerp(want.position, k), view.size.lerp(want.size, k))
	cam.global_transform = _frame(view)

# ------------------------------------------------------------------ the two boxes over the view
func _btns() -> Array:
	var vp := _vp()
	var out := [[Rect2(vp.x - 52, 8, 44, 36), "X"]]
	if mode == "b" and at_map:
		out.append([Rect2(8, 8, 44, 36), "<"])
	return out

func _draw_hud() -> void:
	if not is_open or not settled or mode == "c":
		return
	var f: Font = load("res://fonts/sans.otf")
	for b in _btns():
		var r: Rect2 = b[0]
		hud.draw_rect(r, Color(0.12, 0.13, 0.15, 0.85))
		hud.draw_rect(r, Color(1, 1, 1, 0.8), false, 1.5)
		var sz := f.get_string_size(b[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 16)
		hud.draw_string(f, r.get_center() + Vector2(-sz.x * 0.5, 6), b[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)

# ------------------------------------------------------------------ input
func _input(e: InputEvent) -> void:
	if not is_open or mode == "c":
		return
	get_viewport().set_input_as_handled()
	if not settled:
		return
	if e is InputEventKey and e.pressed and not e.echo:
		_key(e.physical_keycode)
	elif e is InputEventScreenTouch:
		last_touch_ms = Time.get_ticks_msec()
		if e.pressed:
			touches[e.index] = e.position
			if touches.size() == 1:
				drag_from = e.position
				drag_moved = false
			else:
				var ps := touches.values()
				pinch_d = (ps[0] as Vector2).distance_to(ps[1])
				drag_moved = true
		else:
			touches.erase(e.index)
			if touches.is_empty():
				_release(e.position)
	elif e is InputEventScreenDrag:
		last_touch_ms = Time.get_ticks_msec()
		var prev: Vector2 = touches.get(e.index, e.position)
		touches[e.index] = e.position
		if touches.size() >= 2:
			var ps := touches.values()
			var d := (ps[0] as Vector2).distance_to(ps[1])
			if pinch_d > 0.0 and d > 0.0:
				_zoom(d / pinch_d, ((ps[0] as Vector2) + (ps[1] as Vector2)) * 0.5)
			pinch_d = d
		else:
			_drag(e.position, e.position - prev)
	elif e is InputEventMouseButton:
		if Time.get_ticks_msec() - last_touch_ms < 600:
			return
		if e.button_index == MOUSE_BUTTON_WHEEL_UP and e.pressed:
			_zoom(1.2, e.position)
		elif e.button_index == MOUSE_BUTTON_WHEEL_DOWN and e.pressed:
			_zoom(1.0 / 1.2, e.position)
		elif e.button_index == MOUSE_BUTTON_LEFT:
			if e.pressed:
				drag_from = e.position
				drag_moved = false
			else:
				_release(e.position)
	elif e is InputEventMouseMotion and e.button_mask & MOUSE_BUTTON_MASK_LEFT:
		if Time.get_ticks_msec() - last_touch_ms < 600:
			return
		_drag(e.position, e.relative)

func _key(k: int) -> void:
	match k:
		KEY_ESCAPE, KEY_BACKSPACE:
			if mode == "b" and at_map:
				_show_page(page)
			else:
				close()
		KEY_RIGHT, KEY_DOWN:
			if mode == "b" and not at_map:
				_show_page(page + 1)
			else:
				_step(1)
		KEY_LEFT, KEY_UP:
			if mode == "b" and not at_map:
				_show_page(page - 1)
			else:
				_step(-1)
		KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
			if sel != "":
				_pick(sel)
		KEY_EQUAL, KEY_KP_ADD:
			_zoom(1.4, _vp() * 0.5)
		KEY_MINUS, KEY_KP_SUBTRACT:
			_zoom(1.0 / 1.4, _vp() * 0.5)
	hud.queue_redraw()

## a: the next / previous store in the sign's own list order.
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

func _zoom(f: float, about: Vector2) -> void:
	if mode == "b":
		return
	var p := _s2p(about) if settled else want.get_center()
	var whole := _whole()
	var ns: Vector2 = (want.size / f).clamp(whole.size / 10.0, whole.size)
	var t := (about / _vp())
	want = Rect2(p - ns * t, ns)
	_clamp_want()

func _clamp_want() -> void:
	var whole := _whole()
	if want.size.x >= whole.size.x * 0.999:
		want = whole
		return
	want.position = want.position.clamp(Vector2(-want.size.x * 0.1, -want.size.y * 0.1), psize - want.size * 0.9)

func _drag(p: Vector2, rel: Vector2) -> void:
	if (p - drag_from).length() > 8.0:
		drag_moved = true
	if not drag_moved:
		return
	if mode == "a":
		want.position -= rel / _scale()
		_clamp_want()
		view.position = want.position

func _release(p: Vector2) -> void:
	if drag_moved:
		drag_moved = false
		# b: a sideways swipe turns the page
		if mode == "b" and not at_map and absf(p.x - drag_from.x) > 60.0 and absf(p.x - drag_from.x) > absf(p.y - drag_from.y):
			_show_page(page + (1 if p.x < drag_from.x else -1))
		return
	for b in _btns():
		if (b[0] as Rect2).has_point(p):
			if b[1] == "X":
				close()
			else:
				_show_page(page)
			hud.queue_redraw()
			return
	var id := _hit(p)
	if id == "":
		if mode == "b" and at_map:
			_show_page(page)
			hud.queue_redraw()
		return
	_pick(id)

## Pick a store: the first time it lights on the sign (b: the camera goes to its block); picking
## the lit store again jumps there.
func _pick(id: String) -> void:
	if id == sel and (mode != "b" or at_map):
		_jump()
		return
	sel = id
	_light()
	if mode == "b":
		_show_map()
	hud.queue_redraw()

func _hit(s: Vector2) -> String:
	# the ray from the camera through the tap, onto the sign's plane
	var o := cam.project_ray_origin(s)
	var d := cam.project_ray_normal(s)
	var f := _face()
	var c := kiosk.global_position + f * FACE_Z + Vector3.UP * ART_Y
	var den := d.dot(f)
	if absf(den) < 1e-5:
		return ""
	var t := (c - o).dot(f) / den
	var w := o + d * t - c
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

func _jump() -> void:
	var st = _stall(sel)
	if st == null:
		return
	var j: Array = st.jump
	print("directory look jump: ", st.name, " (", year, ") -> wing ", j[0])
	var p := player
	is_open = false
	if is_instance_valid(from_cam):
		from_cam.current = true
	quad.visible = false
	_sharp(false)
	_freeze(false)
	hud.queue_redraw()
	if p and p.has_method("jump_to"):
		p.jump_to(int(j[0]), int(year), float(j[1]), float(j[2]), float(j[3]))
