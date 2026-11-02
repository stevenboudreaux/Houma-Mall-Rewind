## The book reader (workstream Q; design/godot-dialogue.md "Books"): runs a .dialogue file as a
## choose-your-own-adventure book. Each line of the file is one page; a line with responses is a
## branch point, its responses the choices printed at the foot of the page. "Turn page" (E / X / A /
## Enter / Space / → / a tap or click on the page) goes on; 1–3, arrows + Enter, d-pad + A or a tap
## picks a choice; Esc / B / the ✕ closes the book (it opens at the start again next time).
## Mutations in the file (set a flag, give, unlock …) work as in conversations.
## Opened by scripts/dialogue/story.gd read_item(): a book item held in the hand (the action
## button's "Read …") or the bag's "Read" button. Steven writes the books; the one shipped is a
## PLACEHOLDER.
extends CanvasLayer

const Runner = preload("res://scripts/dialogue/dialogue_runner.gd")

const PAGE_MAX := Vector2(620, 760)

signal finished

var player: Node3D
var story: Node
var active := false
var res: Resource = null
var state = null
var line = null
var page := 0
var sel := 0
var _busy := false
var _hidden: Array = []
var _froze := false

var panel: PanelContainer
var title_l: Label
var text_l: RichTextLabel
var page_l: Label
var turn_b: Button
var close_b: Button
var choice_box: VBoxContainer
var choice_btns: Array = []

func _ready() -> void:
	layer = 31
	_build()
	visible = false

func open(path: String, title: String) -> bool:
	if active:
		return false
	res = Runner.load_dialogue(path)
	if res == null:
		push_warning("book: can't load " + path)
		return false
	active = true
	state = story.make_state(res) if story else null
	title_l.text = title
	page = 0
	_freeze(true)
	visible = true
	Runner.manager(get_tree())
	_next(Runner.first_cue(res))
	return true

func close() -> void:
	if not active:
		return
	active = false
	line = null
	visible = false
	_freeze(false)
	finished.emit()

func _freeze(on: bool) -> void:
	if on:
		if not player.frozen:
			player.frozen = true
			_froze = true
		player.move_vec = Vector2.ZERO
		player.move_touch = -1
		player.look_touch = -1
		player.dragging = false
		if player.stick:
			player.stick.visible = false
		_hidden.clear()
		for n in get_tree().root.find_children("*", "CanvasLayer", true, false):
			if n != self and n.visible and n.layer < 100:
				n.visible = false
				_hidden.append(n)
	else:
		for n in _hidden:
			if is_instance_valid(n):
				n.visible = true
		_hidden.clear()
		if _froze:
			player.frozen = false
			_froze = false

# ------------------------------------------------------------------ pages
func _next(id: String) -> void:
	if id == "" or id.begins_with("END"):
		_the_end()
		return
	_busy = true
	var l = await Runner.next_line(get_tree(), res, id, state)
	_busy = false
	if l == null:
		_the_end()
		return
	line = l
	page += 1
	text_l.text = str(l.text)
	page_l.text = "%d" % page
	_clear_choices()
	var has := l.responses.size() > 0
	turn_b.visible = not has
	turn_b.text = "Turn page ▸"
	if has:
		for i in l.responses.size():
			var b := Button.new()
			b.text = "%d.  %s" % [i + 1, str(l.responses[i].text)]
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			b.focus_mode = Control.FOCUS_NONE
			b.custom_minimum_size = Vector2(0, 52)
			b.add_theme_font_size_override("font_size", 18)
			var k := i
			b.pressed.connect(func(): _choose(k))
			choice_box.add_child(b)
			choice_btns.append(b)
		sel = 0
		_paint()

## The last page was read: "The end" and a Close button.
func _the_end() -> void:
	line = null
	_clear_choices()
	if page == 0:
		close()
		return
	turn_b.visible = true
	turn_b.text = "Close the book"

func _turn() -> void:
	if _busy:
		return
	if line == null:
		close()
		return
	if line.responses.size() > 0:
		_choose(sel)
		return
	_next(str(line.next_id))

func _choose(i: int) -> void:
	if line == null or i < 0 or i >= line.responses.size() or _busy:
		return
	var r = line.responses[i]
	_next(str(r.next_id))

func _clear_choices() -> void:
	for b in choice_btns:
		b.queue_free()
	choice_btns.clear()

func _paint() -> void:
	for i in choice_btns.size():
		choice_btns[i].modulate = Color(1, 1, 1) if i == sel else Color(0.75, 0.72, 0.68)

# ------------------------------------------------------------------ input
func _input(e: InputEvent) -> void:
	if not active:
		return
	var vp := get_viewport()
	var has := line != null and line.responses.size() > 0
	if e is InputEventKey and e.pressed and not e.echo:
		var k: int = e.physical_keycode
		if k == KEY_ESCAPE:
			close()
		elif has and k >= KEY_1 and k <= KEY_9:
			_choose(k - KEY_1)
		elif has and k in [KEY_UP, KEY_W]:
			sel = (sel - 1 + choice_btns.size()) % choice_btns.size(); _paint()
		elif has and k in [KEY_DOWN, KEY_S]:
			sel = (sel + 1) % choice_btns.size(); _paint()
		elif k in [KEY_E, KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_RIGHT, KEY_D]:
			_turn()
		vp.set_input_as_handled()
	elif e is InputEventJoypadButton and e.pressed:
		match e.button_index:
			JOY_BUTTON_A, JOY_BUTTON_X:
				_turn()
			JOY_BUTTON_B:
				close()
			JOY_BUTTON_DPAD_UP:
				if has:
					sel = (sel - 1 + choice_btns.size()) % choice_btns.size(); _paint()
			JOY_BUTTON_DPAD_DOWN:
				if has:
					sel = (sel + 1) % choice_btns.size(); _paint()
		vp.set_input_as_handled()
	elif e is InputEventScreenTouch:
		if e.pressed:
			if close_b.get_global_rect().has_point(e.position):
				close()
			elif has:
				for i in choice_btns.size():
					if choice_btns[i].get_global_rect().has_point(e.position):
						_choose(i)
						break
			elif panel.get_global_rect().has_point(e.position):
				_turn()
		vp.set_input_as_handled()

# ------------------------------------------------------------------ building
func _build() -> void:
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.55)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	panel = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.96, 0.93, 0.85)          # paper
	sb.border_color = Color(0.45, 0.36, 0.25)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(4)
	sb.content_margin_left = 28; sb.content_margin_right = 28
	sb.content_margin_top = 18; sb.content_margin_bottom = 18
	panel.add_theme_stylebox_override("panel", sb)
	add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	panel.add_child(v)
	var top := HBoxContainer.new()
	v.add_child(top)
	title_l = Label.new()
	title_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_l.add_theme_font_size_override("font_size", 15)
	title_l.add_theme_color_override("font_color", Color(0.4, 0.32, 0.22))
	top.add_child(title_l)
	close_b = Button.new()
	close_b.text = "✕"
	close_b.focus_mode = Control.FOCUS_NONE
	close_b.custom_minimum_size = Vector2(44, 44)
	close_b.pressed.connect(close)
	top.add_child(close_b)
	text_l = RichTextLabel.new()
	text_l.bbcode_enabled = true
	text_l.scroll_active = true
	text_l.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text_l.add_theme_font_size_override("normal_font_size", 21)
	text_l.add_theme_color_override("default_color", Color(0.13, 0.1, 0.07))
	text_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(text_l)
	choice_box = VBoxContainer.new()
	v.add_child(choice_box)
	var foot := HBoxContainer.new()
	v.add_child(foot)
	page_l = Label.new()
	page_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page_l.add_theme_color_override("font_color", Color(0.4, 0.32, 0.22))
	foot.add_child(page_l)
	turn_b = Button.new()
	turn_b.focus_mode = Control.FOCUS_NONE
	turn_b.custom_minimum_size = Vector2(170, 52)
	turn_b.add_theme_font_size_override("font_size", 18)
	turn_b.pressed.connect(_turn)
	foot.add_child(turn_b)
	get_viewport().size_changed.connect(_layout)
	_layout()

func _layout() -> void:
	var sz := get_viewport().get_visible_rect().size
	var w := minf(sz.x - 32.0, PAGE_MAX.x)
	var h := minf(sz.y - 32.0, PAGE_MAX.y)
	panel.position = Vector2((sz.x - w) * 0.5, (sz.y - h) * 0.5)
	panel.size = Vector2(w, h)
	panel.custom_minimum_size = Vector2(w, h)
