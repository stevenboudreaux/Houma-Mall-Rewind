## Workstream V (design/godot-avatar.md): the avatar creator, shown when the game starts for a
## visitor who has never made one, and from the "Avatar (C)" button / C / a gamepad's Start.
## scripts/avatar_creator.tscn is this script on a CanvasLayer; scripts/avatar.gd makes it.
##
## Rows, in the spirit of the 2D game's character creator (index.html lk-engine: skin, hair, clothes):
##   Body (the shoppers' bodies, < >), Skin, Hair, Top and Bottom (swatches; the first, "own", keeps the
##   body's own colour; Top and Bottom are this year's palette, scripts/avatar_look.gd), Words (the
##   shirt words: < > through a few, or Type), then Random · Skip · Done.
## A turning preview of the avatar on the left (on top when the screen is taller than wide); drag it
## to turn it. Fits an iPhone held either way (390 px wide portrait, 390 px tall landscape).
## Input: mouse, touch (tapped by hand: touches skip mouse emulation), keyboard (↑↓ rows, ←→ change,
## Enter Done, Esc Skip / back), gamepad (d-pad, A Done, B Skip / back, X Random).
extends CanvasLayer

signal closed(look: Dictionary, how: String)   # how: "done", "skip", "cancel"

const Look = preload("res://scripts/avatar_look.gd")
const AvatarBody = preload("res://scripts/avatar_body.gd")

var year := 1995
var look := {}
var first_time := true

var rng := RandomNumberGenerator.new()
var root: Control
var vp: SubViewport
var vpc: SubViewportContainer
var pv_body: AvatarBody
var pv_cam: Camera3D
var pv_yaw := 0.4
var pv_drag := -2            # touch index dragging the preview (-1 the mouse, -2 none)
var spin := true
var hits: Array = []         # [Control, Callable], tapped by hand for touches
var rows: Array = []         # [{name, panel, cycle: Callable(dir)}]
var sel := 0
var body_lbl: Label
var words_lbl: Label
var swatches := {}           # row name -> [[Button, value]]
var action_btns: Array = []  # [Button, Callable]
var act_sel := 2
var _built_for := Vector2.ZERO
## M (design/godot-menu.md): inside the menu's AVATAR tab the creator lays out in this rect (screen
## pixels) instead of the whole screen, and the menu feeds it its input (embedded: no _input of its own).
var frame := Rect2()
var embedded := false

func _ready() -> void:
	layer = 40
	rng.randomize()
	if look.is_empty():
		look = Look.default_look()
	_make_preview()
	_layout()
	get_viewport().size_changed.connect(_layout)

# ------------------------------------------------------------------ the preview
func _make_preview() -> void:
	vp = SubViewport.new()
	vp.own_world_3d = true
	vp.transparent_bg = false
	vp.msaa_3d = Viewport.MSAA_2X
	vp.size = Vector2i(300, 400)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var w := Node3D.new()
	vp.add_child(w)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.16, 0.13, 0.11)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(1.0, 0.95, 0.88)
	e.ambient_light_energy = 0.75
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = e
	w.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35, 25, 0)
	sun.light_energy = 1.1
	w.add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-15, 200, 0)
	fill.light_energy = 0.35
	w.add_child(fill)
	var fl := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.75; cyl.bottom_radius = 0.75; cyl.height = 0.04
	fl.mesh = cyl
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color(0.55, 0.47, 0.38)   # the mall's terrazzo, roughly
	fl.material_override = fm
	fl.position.y = -0.02
	w.add_child(fl)
	pv_cam = Camera3D.new()
	pv_cam.fov = 30.0
	w.add_child(pv_cam)
	pv_cam.current = true
	pv_body = AvatarBody.new()
	w.add_child(pv_body)
	pv_body.wear(look, year)
	pv_body.play("idle", 0.0, false)
	_frame_cam()

func _frame_cam() -> void:
	var h := float(pv_body.info.get("height_m", 1.7))
	var asp := float(vp.size.x) / maxf(float(vp.size.y), 1.0)
	# fit the body's height (or its width, on a wide preview) with a little room
	var need := (h * 1.12) * 0.5 / tan(deg_to_rad(pv_cam.fov * 0.5))
	if asp < 0.55: need /= asp / 0.55
	pv_cam.position = Vector3(0, h * 0.53, need)
	pv_cam.rotation = Vector3.ZERO

func _process(dt: float) -> void:
	if spin and pv_drag == -2:
		pv_yaw += dt * 0.5
	if pv_body:
		pv_body.rotation.y = pv_yaw

# ------------------------------------------------------------------ layout
func _layout() -> void:
	var vs := get_viewport().get_visible_rect().size
	if frame.has_area():
		vs = frame.size   # M: the menu's tab
	if vs == _built_for:
		return
	_built_for = vs
	if root:
		root.queue_free()
	hits = []; rows = []; swatches = {}; action_btns = []
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if frame.has_area():   # M
		root.set_anchors_preset(Control.PRESET_TOP_LEFT)
		root.position = frame.position
		root.size = frame.size
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)
	var bg := ColorRect.new()
	bg.color = Color(0.07, 0.055, 0.045, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)
	var tall := vs.y > vs.x
	var pad := 10.0
	# the preview: left third (wide screens) or the top ~36 % (tall ones)
	var pr: Rect2
	var cr: Rect2
	if tall:
		var ph := clampf(vs.y * 0.36, 180.0, 360.0)
		pr = Rect2(pad, pad, vs.x - pad * 2, ph)
		cr = Rect2(pad, pad * 2 + ph, vs.x - pad * 2, vs.y - ph - pad * 3)
	else:
		var pw := clampf(vs.x * 0.34, 160.0, 420.0)
		pr = Rect2(pad, pad, pw, vs.y - pad * 2)
		cr = Rect2(pad * 2 + pw, pad, vs.x - pw - pad * 3, vs.y - pad * 2)
	if vp.get_parent():
		vp.get_parent().remove_child(vp)
	vpc = SubViewportContainer.new()
	vpc.position = pr.position
	vpc.size = pr.size
	vpc.mouse_filter = Control.MOUSE_FILTER_PASS
	vp.size = Vector2i(maxi(64, int(pr.size.x)), maxi(64, int(pr.size.y)))
	vpc.add_child(vp)
	root.add_child(vpc)
	vpc.stretch = true
	_frame_cam()
	# the controls
	# title (0.85 row), 6 rows, the actions, and 7 gaps of 0.12 row
	var rh := clampf(cr.size.y / 8.75, 28.0, 56.0)
	var col := VBoxContainer.new()
	col.position = cr.position
	col.size = Vector2(cr.size.x, 0)
	col.add_theme_constant_override("separation", int(maxf(2.0, rh * 0.12)))
	root.add_child(col)
	var title := Label.new()
	title.text = ("Make your shopper · %d" % year) if first_time else ("Your shopper · %d" % year)
	title.add_theme_font_size_override("font_size", int(clampf(rh * 0.5, 16, 24)))
	title.add_theme_color_override("font_color", Color(1, 0.95, 0.78))
	title.custom_minimum_size.y = rh * 0.85
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	col.add_child(title)
	var lw := clampf(cr.size.x * 0.17, 54.0, 90.0)       # row label width
	var fs := int(clampf(rh * 0.36, 13, 18))
	var cw := cr.size.x - lw - 8.0                       # content width
	# body
	var r := _row(col, "Body", lw, rh, fs)
	_arrow(r, "<", rh, fs, func(): _cycle_body(-1))
	body_lbl = Label.new()
	body_lbl.custom_minimum_size = Vector2(maxf(80.0, cw - rh * 2.4), rh * 0.8)
	body_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	body_lbl.add_theme_font_size_override("font_size", fs)
	r.add_child(body_lbl)
	_arrow(r, ">", rh, fs, func(): _cycle_body(1))
	rows.append({"name": "body", "panel": r, "cycle": _cycle_body})
	# swatch rows
	var y := Look.pal_year(year)
	_swatch_row(col, "skin", "Skin", Look.SKIN, lw, rh, fs, cw)
	_swatch_row(col, "hair", "Hair", Look.HAIR[y], lw, rh, fs, cw)
	_swatch_row(col, "top", "Top", Look.TOP[y], lw, rh, fs, cw)
	_swatch_row(col, "bottom", "Bottom", Look.BOTTOM[y], lw, rh, fs, cw)
	# words
	r = _row(col, "Words", lw, rh, fs)
	_arrow(r, "<", rh, fs, func(): _cycle_words(-1))
	words_lbl = Label.new()
	words_lbl.custom_minimum_size = Vector2(maxf(70.0, cw - rh * 2.4 - 70.0), rh * 0.8)
	words_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	words_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	words_lbl.add_theme_font_size_override("font_size", fs)
	r.add_child(words_lbl)
	_arrow(r, ">", rh, fs, func(): _cycle_words(1))
	var tb := _button(r, "Type", Vector2(64, rh * 0.8), fs, _type_words)
	tb.tooltip_text = "Type your own words (up to %d letters)" % Look.WORDS_MAX
	rows.append({"name": "words", "panel": r, "cycle": _cycle_words})
	# actions
	var ar := HBoxContainer.new()
	ar.add_theme_constant_override("separation", 8)
	ar.alignment = BoxContainer.ALIGNMENT_END
	ar.custom_minimum_size.y = rh
	col.add_child(ar)
	var bw := clampf((cr.size.x - 16.0) / 3.0, 80.0, 150.0)
	for a in [["Random", _randomize], ["Skip", _skip], ["Done", _done]]:
		var b := _button(ar, a[0], Vector2(bw, rh * 0.9), fs + 1, a[1])
		action_btns.append([b, a[1]])
	var done_sb := StyleBoxFlat.new()
	done_sb.bg_color = Color(0.85, 0.62, 0.22)
	done_sb.set_corner_radius_all(8)
	action_btns[2][0].add_theme_stylebox_override("normal", done_sb)
	action_btns[2][0].add_theme_color_override("font_color", Color(0.1, 0.07, 0.04))
	rows.append({"name": "actions", "panel": ar, "cycle": func(d: int): act_sel = posmod(act_sel + d, 3); _refresh()})
	if not first_time:
		action_btns[1][0].text = "Back"
	_refresh()

func _row(col: VBoxContainer, label: String, lw: float, rh: float, fs: int) -> HBoxContainer:
	var r := HBoxContainer.new()
	r.add_theme_constant_override("separation", 4)
	r.custom_minimum_size.y = rh
	col.add_child(r)
	var l := Label.new()
	l.text = label
	l.custom_minimum_size = Vector2(lw, rh)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", Color(0.93, 0.85, 0.66))
	r.add_child(l)
	return r

func _arrow(r: Control, t: String, rh: float, fs: int, cb: Callable) -> Button:
	return _button(r, t, Vector2(rh * 1.1, rh * 0.8), fs, cb)

func _button(parent: Control, t: String, sz: Vector2, fs: int, cb: Callable) -> Button:
	var b := Button.new()
	b.text = t
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = sz
	b.add_theme_font_size_override("font_size", fs)
	b.pressed.connect(cb)
	parent.add_child(b)
	hits.append([b, cb])
	return b

func _swatch_row(col: VBoxContainer, key: String, label: String, pal: Array, lw: float, rh: float, fs: int, cw: float) -> void:
	var r := _row(col, label, lw, rh, fs)
	var n := pal.size()
	var s := clampf((cw - 3.0 * (n - 1)) / n, 18.0, rh * 0.85)
	r.add_theme_constant_override("separation", 3)
	var list := []
	for c in pal:
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(s, s)
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var v: String = c
		var cb := func(): _put(key, v)
		b.pressed.connect(cb)
		r.add_child(b)
		hits.append([b, cb])
		list.append([b, v])
	swatches[key] = list
	rows.append({"name": key, "panel": r, "cycle": func(d: int): _step_swatch(key, d)})

## A swatch's look: its colour (or the body's own, marked), a light ring when chosen.
func _paint_swatch(b: Button, col: Color, chosen: bool, own: bool) -> void:
	for st in ["normal", "hover", "pressed", "disabled"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = col if st != "disabled" else Color(col, 0.18)
		sb.set_corner_radius_all(int(b.custom_minimum_size.x * 0.5))
		sb.set_border_width_all(3 if chosen else 1)
		sb.border_color = Color(1, 0.92, 0.6) if chosen else Color(0, 0, 0, 0.5)
		if st == "hover": sb.bg_color = col.lightened(0.1)
		b.add_theme_stylebox_override(st, sb)
	b.text = "•" if own else ""
	b.add_theme_color_override("font_color", Color(1, 1, 1) if col.get_luminance() < 0.5 else Color(0, 0, 0))
	b.add_theme_font_size_override("font_size", int(b.custom_minimum_size.x * 0.6))
	b.tooltip_text = "Its own colour" if own else ""

# ------------------------------------------------------------------ changes
func _clothes() -> Dictionary:
	var yk := Look.year_key(year)
	if not (look.get(yk) is Dictionary):
		look[yk] = {"top": "", "bottom": "", "words": ""}
	return look[yk]

func _val(key: String) -> String:
	if key == "skin" or key == "hair":
		return str(look.get(key, ""))
	return str(_clothes().get(key, ""))

func _put(key: String, v: String) -> void:
	if key == "skin" or key == "hair":
		look[key] = v
	else:
		_clothes()[key] = v
	spin = false
	_apply()

func _step_swatch(key: String, d: int) -> void:
	var list: Array = swatches.get(key, [])
	var i := 0
	for k in list.size():
		if list[k][1] == _val(key): i = k
	_put(key, list[posmod(i + d, list.size())][1])

func _cycle_body(d: int) -> void:
	var bs := Look.bodies()
	if bs.is_empty(): return
	var i := 0
	for k in bs.size():
		if str(bs[k].id) == str(look.get("body", "")): i = k
	look.body = str(bs[posmod(i + d, bs.size())].id)
	spin = true
	_apply()
	_frame_cam()

func _cycle_words(d: int) -> void:
	var list: Array = Look.WORDS[Look.pal_year(year)]
	var cur := _val("words")
	var i := list.find(cur)
	if i < 0: i = 0 if d > 0 else 1
	_put("words", list[posmod(i + d, list.size())])
	pv_yaw = 0.0

## Type the words: the browser's own text box (works with a phone's keyboard); off the web, nothing.
func _type_words() -> void:
	if not OS.has_feature("web"):
		return
	var v = JavaScriptBridge.eval("(function(){var r=window.prompt('Words on your shirt (up to %d letters, blank for none)',%s);return r===null?'\\u0000':r})()" % [Look.WORDS_MAX, JSON.stringify(_val("words"))], true)
	if v is String and v != "\u0000":
		_put("words", Look.clean_words(v))
		pv_yaw = 0.0

func _randomize() -> void:
	var r := Look.random_look(year, rng)
	look.body = r.body; look.skin = r.skin; look.hair = r.hair
	look[Look.year_key(year)] = r[Look.year_key(year)]
	spin = true
	_apply()
	_frame_cam()

func _apply() -> void:
	pv_body.wear(look, year)
	if pv_body.clip == "":
		pv_body.play("idle", 0.0, false)
	_refresh()

func _refresh() -> void:
	var bs := Look.bodies()
	var bi := 0
	for k in bs.size():
		if str(bs[k].id) == str(look.get("body", "")): bi = k
	if body_lbl:
		body_lbl.text = "%d of %d" % [bi + 1, bs.size()]
	if words_lbl:
		var w := _val("words")
		words_lbl.text = w if w != "" else "(none)"
	for key in swatches:
		var own := Color.from_string(str(pv_body.info.get(key, "#808080")) if str(pv_body.info.get(key, "")) != "" else "#808080", Color.GRAY)
		for pair in swatches[key]:
			var v: String = pair[1]
			_paint_swatch(pair[0], own if v == "" else Color.from_string(v, Color.GRAY), v == _val(key), v == "")
		# a body with no hair of its own: the hair row can't change anything
		if key == "hair":
			var none: bool = str(pv_body.info.get("hair", "")) == ""
			for pair in swatches[key]: pair[0].disabled = none
	for i in rows.size():
		var p: Control = rows[i].panel
		p.modulate = Color(1.15, 1.08, 0.9) if i == sel else Color(1, 1, 1)
	for i in action_btns.size():
		action_btns[i][0].modulate = Color(1.2, 1.1, 0.85) if (rows.size() > 0 and str(rows[sel].name) == "actions" and i == act_sel) else Color(1, 1, 1)

# ------------------------------------------------------------------ closing
func _done() -> void:
	closed.emit(look, "done")

func _skip() -> void:
	if first_time:
		var L := Look.default_look()
		closed.emit(L, "skip")
	else:
		closed.emit(look, "cancel")

# ------------------------------------------------------------------ input
func _input(e: InputEvent) -> void:
	if embedded and not has_meta("_fed"):
		return     # M: the menu calls feed()
	var used := true
	if e is InputEventScreenTouch:
		if e.pressed:
			for i in range(hits.size() - 1, -1, -1):
				var c: Control = hits[i][0]
				if c.is_visible_in_tree() and not (c is BaseButton and c.disabled) and c.get_global_rect().has_point(e.position):
					(hits[i][1] as Callable).call()
					get_viewport().set_input_as_handled()
					return
			if vpc and vpc.get_global_rect().has_point(e.position):
				pv_drag = e.index
		elif e.index == pv_drag:
			pv_drag = -2
	elif e is InputEventScreenDrag:
		if e.index == pv_drag:
			pv_yaw += e.relative.x * 0.01
			spin = false
	elif e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		if e.pressed and vpc and vpc.get_global_rect().has_point(e.position):
			pv_drag = -1
		elif not e.pressed:
			pv_drag = -2
		used = false        # buttons still get their clicks
	elif e is InputEventMouseMotion:
		if pv_drag == -1:
			pv_yaw += e.relative.x * 0.01
			spin = false
		used = false
	elif e is InputEventKey and e.pressed:
		match e.physical_keycode:
			KEY_UP, KEY_W: _sel(-1)
			KEY_DOWN, KEY_S: _sel(1)
			KEY_LEFT, KEY_A: rows[sel].cycle.call(-1)
			KEY_RIGHT, KEY_D: rows[sel].cycle.call(1)
			KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_E:
				if str(rows[sel].name) == "actions": action_btns[act_sel][1].call()
				elif str(rows[sel].name) == "words" and e.physical_keycode == KEY_SPACE: _type_words()
				else: _done()
			KEY_ESCAPE: _skip()
			KEY_R: _randomize()
	elif e is InputEventJoypadButton and e.pressed:
		match e.button_index:
			JOY_BUTTON_DPAD_UP: _sel(-1)
			JOY_BUTTON_DPAD_DOWN: _sel(1)
			JOY_BUTTON_DPAD_LEFT: rows[sel].cycle.call(-1)
			JOY_BUTTON_DPAD_RIGHT: rows[sel].cycle.call(1)
			JOY_BUTTON_A:
				if str(rows[sel].name) == "actions": action_btns[act_sel][1].call()
				else: _done()
			JOY_BUTTON_B: _skip()
			JOY_BUTTON_X: _randomize()
	if used and is_inside_tree():
		get_viewport().set_input_as_handled()

func _sel(d: int) -> void:
	sel = posmod(sel + d, rows.size())
	_refresh()

## M: an event from the menu (scripts/menu/menu.gd), which owns the input while it is open.
func feed(e: InputEvent) -> void:
	set_meta("_fed", true)
	_input(e)
	remove_meta("_fed")
