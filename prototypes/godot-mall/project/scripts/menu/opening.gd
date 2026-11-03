## Workstream M (design/godot-menu.md): the opening screen, shown once at a first start (no
## mall.player_name yet, not skipped before; scripts/menu/menu.gd decides). One panel of text from
## data/story/opening.json (Steven writes it; the file ships with PLACEHOLDER slots) and two buttons:
## START (then the menu's AVATAR tab opens with the NAME field focused) and Skip.
## Input comes from menu.gd's catcher (handle()), as the menu's does.
extends CanvasLayer

signal done(how: String)     # "start" or "skip"

const DATA := "res://data/story/opening.json"

var words := {"title": "", "text": "", "start": "START", "skip": "Skip"}
var root: Control
var hits: Array = []         # [Button, Callable]
var start_btn: Button
var skip_btn: Button
var _sel := 0                # 0 START, 1 Skip

func _ready() -> void:
	layer = 50
	if FileAccess.file_exists(DATA):
		var j = JSON.parse_string(FileAccess.get_file_as_string(DATA))
		if j is Dictionary:
			for k in words:
				if j.has(k):
					words[k] = str(j[k])
	_layout()
	get_viewport().size_changed.connect(_layout)

func _layout() -> void:
	var vs := get_viewport().get_visible_rect().size
	if root:
		root.queue_free()
	hits = []
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.04, 0.035, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bg)
	var w := minf(vs.x - 32.0, 640.0)
	var col := VBoxContainer.new()
	col.position = Vector2((vs.x - w) * 0.5, 16)
	col.size = Vector2(w, vs.y - 32)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 14 if vs.y > 500 else 8)
	root.add_child(col)
	var small := vs.y < 500
	if words.title != "":
		var t := Label.new()
		t.text = words.title
		t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		t.add_theme_font_size_override("font_size", 22 if small else 30)
		t.add_theme_color_override("font_color", Color(1, 0.95, 0.78))
		col.add_child(t)
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sc.custom_minimum_size = Vector2(w, minf(vs.y * 0.5, 420.0))
	col.add_child(sc)
	var body := Label.new()
	body.text = words.text
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size.x = w - 12.0
	body.add_theme_font_size_override("font_size", 16 if small else 19)
	body.add_theme_color_override("font_color", Color(1, 0.97, 0.9))
	sc.add_child(body)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 18)
	col.add_child(row)
	skip_btn = _btn(row, words.skip, Vector2(120, 48), func(): done.emit("skip"))
	start_btn = _btn(row, words.start, Vector2(180, 56), func(): done.emit("start"))
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.85, 0.62, 0.22)
	sb.set_corner_radius_all(10)
	for st in ["normal", "hover", "pressed", "focus"]:
		start_btn.add_theme_stylebox_override(st, sb)
	for c in ["font_color", "font_hover_color", "font_pressed_color"]:
		start_btn.add_theme_color_override(c, Color(0.1, 0.07, 0.04))
	_paint()

func _btn(parent: Control, t: String, sz: Vector2, cb: Callable) -> Button:
	var b := Button.new()
	b.text = t
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = sz
	b.add_theme_font_size_override("font_size", 20)
	b.pressed.connect(cb)
	parent.add_child(b)
	hits.append([b, cb])
	return b

func _paint() -> void:
	if start_btn and skip_btn:
		start_btn.modulate = Color(1.2, 1.1, 0.85) if _sel == 0 else Color(1, 1, 1)
		skip_btn.modulate = Color(1.2, 1.1, 0.85) if _sel == 1 else Color(1, 1, 1)

## Keys: Enter / Space START (or the chosen button), Esc Skip, ←→ choose. Pad: A, B, d-pad.
## Mouse and touch: the buttons.
func handle(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo:
		match e.keycode:
			KEY_ENTER, KEY_KP_ENTER, KEY_SPACE: done.emit("start" if _sel == 0 else "skip")
			KEY_ESCAPE: done.emit("skip")
			KEY_LEFT, KEY_RIGHT, KEY_TAB: _sel = 1 - _sel; _paint()
	elif e is InputEventJoypadButton and e.pressed:
		match e.button_index:
			JOY_BUTTON_A, JOY_BUTTON_START: done.emit("start" if _sel == 0 else "skip")
			JOY_BUTTON_B: done.emit("skip")
			JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_DPAD_RIGHT: _sel = 1 - _sel; _paint()
	elif (e is InputEventScreenTouch and e.pressed) or (e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT):
		for h in hits:
			var b: Button = h[0]
			if b.is_visible_in_tree() and b.get_global_rect().has_point(e.position):
				(h[1] as Callable).call()
				return
