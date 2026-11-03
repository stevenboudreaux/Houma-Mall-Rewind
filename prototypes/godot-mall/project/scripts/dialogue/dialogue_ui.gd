## The conversation screen, Fallout 3 / New Vegas style (workstream Q; design/godot-dialogue.md).
## Made once per wing by scripts/dialogue/story.gd. Steven writes every word; this only shows them.
##
## talk(npc, path, cue):
##  1. the player stops (player.frozen), the HUD hides (every other CanvasLayer), the NPC stops,
##     turns to the player and plays its idle (npc.talk_begin);
##  2. a camera of our own tweens (CAM_T s) from wherever the view is to FACE_DIST m in front of the
##     NPC's eyes, looking LOOK_DROP m below them, so the face sits front and centre above the box;
##  3. the box at the bottom: the speaker's name, the line typed out (CPS characters a second; a
##     press finishes it), then "continue" (E / X / A / Enter / Space / a click / a tap); one line
##     per screen;
##  4. a line that ends in responses lists them (up to three expected, any number shown): 1–3,
##     arrows/W-S + Enter, d-pad + A, a click or a tap; any depth the file has;
##  5. at END (or when the file runs out) the camera tweens back, the HUD returns, the player can
##     move, the NPC goes back to what it was doing (npc.talk_end).
## Phones: the box spans the width (16 px gutters), text 20 px, response rows 56 px tall.
extends CanvasLayer

const Runner = preload("res://scripts/dialogue/dialogue_runner.gd")
const State = preload("res://scripts/dialogue/dialogue_state.gd")

const CAM_T := 0.5           # s, the camera's move in and out
const FACE_DIST := 0.85      # m in front of the eyes
const LOOK_DROP := 0.12      # m below the eyes the camera aims (puts the face above the box)
const CAM_FOV := 45.0        # degrees (vertical); the walking camera is 70
const CPS := 50.0            # typing speed, characters per second
const BOX_MAX_W := 900.0

signal finished

var player: Node3D
var story: Node              # scripts/dialogue/story.gd
var active := false
var npc: Node3D = null
var res: Resource = null
var state = null
var line = null              # the DialogueLine on screen
var typing := false
var sel := 0
var _shown := 0.0
var _hidden: Array = []      # CanvasLayers we hid
var _cam: Camera3D
var _from_cam: Camera3D
var _from_xf := Transform3D()
var _from_fov := 70.0
var _froze := false
var _busy := false           # waiting on the next line

var root: Control
var box: PanelContainer
var name_l: Label
var text_l: RichTextLabel
var more_l: Label
var resp_box: VBoxContainer
var resp_btns: Array = []

func _ready() -> void:
	layer = 30
	_build()
	visible = false

# ------------------------------------------------------------------ start / end
## Start a conversation with npc (a Node3D with optional talk_begin(player) / talk_end() and
## face_point() -> Vector3) from a .dialogue file.
func talk(who: Node3D, path: String, cue := "") -> bool:
	if active:
		return false
	res = Runner.load_dialogue(path)
	if res == null:
		push_warning("dialogue: can't load " + path)
		return false
	active = true
	npc = who
	state = story.make_state(res) if story else State.new(player.mall)
	_freeze(true)
	if npc and npc.has_method("talk_begin"):
		npc.talk_begin(player)
	_camera_in()
	visible = true
	box.visible = false
	_clear_responses()
	Runner.manager(get_tree())
	await get_tree().create_timer(CAM_T * 0.6).timeout
	_next(cue if cue != "" else Runner.first_cue(res))
	return true

func _end() -> void:
	if not active:
		return
	line = null
	box.visible = false
	_clear_responses()
	if npc and npc.has_method("talk_end"):
		npc.talk_end()
	await _camera_out()
	visible = false
	_freeze(false)
	active = false
	npc = null
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

# ------------------------------------------------------------------ the camera
## Where the face camera goes for an NPC: in front of its eyes on the line to the player.
static func face_shot(eye: Vector3, toward: Vector3) -> Transform3D:
	var f := Vector3(toward.x - eye.x, 0, toward.z - eye.z)
	f = f.normalized() if f.length() > 0.01 else Vector3.FORWARD
	var at := eye + f * FACE_DIST
	var look := eye - Vector3(0, LOOK_DROP, 0)
	return Transform3D(Basis.looking_at(look - at, Vector3.UP), at)

func _eye() -> Vector3:
	if npc and npc.has_method("face_point"):
		return npc.face_point()
	return npc.global_position + Vector3(0, 1.6, 0) if npc else Vector3.ZERO

func _camera_in() -> void:
	_from_cam = get_viewport().get_camera_3d()
	if _from_cam == null:
		_from_cam = player.cam
	_from_xf = _from_cam.global_transform
	_from_fov = _from_cam.fov
	if _cam == null:
		_cam = Camera3D.new()
		_cam.name = "TalkCam"
		_cam.near = 0.03
		_cam.far = 200.0
		player.get_parent().add_child(_cam)
	_cam.global_transform = _from_xf
	_cam.fov = _from_fov
	_cam.current = true
	var to := face_shot(_eye(), player.global_position)
	var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tw.tween_method(func(t: float): _cam.global_transform = _from_xf.interpolate_with(to, t), 0.0, 1.0, CAM_T)
	tw.tween_property(_cam, "fov", CAM_FOV, CAM_T)

func _camera_out() -> void:
	if _cam == null:
		return
	var from := _cam.global_transform
	var back := _from_cam.global_transform if is_instance_valid(_from_cam) else _from_xf
	var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tw.tween_method(func(t: float): _cam.global_transform = from.interpolate_with(back, t), 0.0, 1.0, CAM_T)
	tw.tween_property(_cam, "fov", _from_fov, CAM_T)
	await tw.finished
	if is_instance_valid(_from_cam):
		_from_cam.current = true

# ------------------------------------------------------------------ lines
func _next(id: String) -> void:
	if id == "" or id == "END" or id == "END!" or res == null:
		_end()
		return
	_busy = true
	var l = await Runner.next_line(get_tree(), res, id, state)
	_busy = false
	if l == null:
		_end()
		return
	_show(l)

func _show(l) -> void:
	line = l
	box.visible = true
	name_l.text = str(l.character)
	name_l.visible = str(l.character) != ""
	text_l.text = str(l.text)
	text_l.visible_characters = 0
	_shown = 0.0
	typing = true
	more_l.visible = false
	_clear_responses()

func _process(dt: float) -> void:
	if not active or line == null or not typing:
		return
	_shown += dt * CPS
	var total := text_l.get_total_character_count()
	text_l.visible_characters = int(_shown)
	if int(_shown) >= total:
		_typed()

func _typed() -> void:
	typing = false
	text_l.visible_characters = -1
	if line.responses.size() > 0:
		_show_responses()
	else:
		more_l.visible = true

func _advance() -> void:
	if line == null or _busy:
		return
	if typing:
		_typed()
		return
	if line.responses.size() > 0:
		_choose(sel)
		return
	_next(str(line.next_id))

func _choose(i: int) -> void:
	if line == null or typing or i < 0 or i >= line.responses.size():
		return
	var r = line.responses[i]
	_clear_responses()
	_next(str(r.next_id))

# ------------------------------------------------------------------ responses
func _show_responses() -> void:
	_clear_responses()
	more_l.visible = false
	for i in line.responses.size():
		var r = line.responses[i]
		var b := Button.new()
		b.text = "%d.  %s" % [i + 1, str(r.text)]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(0, 56)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.add_theme_font_size_override("font_size", 19)
		for st in ["normal", "hover", "pressed", "focus", "disabled"]:
			b.add_theme_stylebox_override(st, _resp_style(false))
		b.add_theme_color_override("font_color", Color(0.93, 0.85, 0.66))
		b.add_theme_color_override("font_hover_color", Color(1, 0.97, 0.9))
		var k: int = i
		b.pressed.connect(func(): _choose(k))
		b.mouse_entered.connect(func(): sel = k; _paint())
		resp_box.add_child(b)
		resp_btns.append(b)
	sel = 0
	_paint()

func _clear_responses() -> void:
	for b in resp_btns:
		b.queue_free()
	resp_btns.clear()

func _paint() -> void:
	for i in resp_btns.size():
		var on: bool = i == sel
		for st in ["normal", "hover", "pressed", "focus"]:
			resp_btns[i].add_theme_stylebox_override(st, _resp_style(on))
		resp_btns[i].add_theme_color_override("font_color", Color(1, 0.97, 0.9) if on else Color(0.93, 0.85, 0.66))

# ------------------------------------------------------------------ input
func _input(e: InputEvent) -> void:
	if not active:
		return
	var vp := get_viewport()
	var has_resp: bool = line != null and not typing and line.responses.size() > 0
	if e is InputEventKey and e.pressed and not e.echo:
		var k: int = e.physical_keycode
		if has_resp and k >= KEY_1 and k <= KEY_9:
			_choose(k - KEY_1)
		elif has_resp and k in [KEY_UP, KEY_W]:
			sel = (sel - 1 + resp_btns.size()) % resp_btns.size(); _paint()
		elif has_resp and k in [KEY_DOWN, KEY_S]:
			sel = (sel + 1) % resp_btns.size(); _paint()
		elif k in [KEY_E, KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
			_advance()
		vp.set_input_as_handled()
	elif e is InputEventJoypadButton and e.pressed:
		match e.button_index:
			JOY_BUTTON_A, JOY_BUTTON_X:
				_advance()
			JOY_BUTTON_DPAD_UP:
				if has_resp:
					sel = (sel - 1 + resp_btns.size()) % resp_btns.size(); _paint()
			JOY_BUTTON_DPAD_DOWN:
				if has_resp:
					sel = (sel + 1) % resp_btns.size(); _paint()
		vp.set_input_as_handled()
	elif e is InputEventJoypadMotion and e.axis == JOY_AXIS_LEFT_Y and has_resp:
		if absf(e.axis_value) > 0.6 and not _stick_held:
			_stick_held = true
			sel = (sel + (1 if e.axis_value > 0 else -1) + resp_btns.size()) % resp_btns.size(); _paint()
		elif absf(e.axis_value) < 0.3:
			_stick_held = false
		vp.set_input_as_handled()
	elif e is InputEventScreenTouch:
		# touches skip mouse emulation (project setting): tap the rows by hand
		if e.pressed:
			if has_resp:
				for i in resp_btns.size():
					if resp_btns[i].get_global_rect().has_point(e.position):
						sel = i; _paint()
						_choose(i)
						break
			else:
				_advance()
		vp.set_input_as_handled()
	elif e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		if not has_resp:
			_advance()
			vp.set_input_as_handled()
		# with responses the buttons take the click themselves

var _stick_held := false

## A short notice above the box ("Received: …" until session R's pop-up), the HUD being hidden.
func toast(t: String) -> void:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", 22)
	l.add_theme_color_override("font_color", Color(1, 0.95, 0.75))
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("outline_size", 6)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	l.offset_left = -300; l.offset_right = 300; l.offset_top = 24; l.offset_bottom = 60
	root.add_child(l)
	var tw := create_tween()
	tw.tween_interval(2.2)
	tw.tween_property(l, "modulate:a", 0.0, 0.5)
	tw.tween_callback(l.queue_free)

# ------------------------------------------------------------------ building
func _style(bg: Color, border: Color, radius: int, pad: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(2)
	s.set_corner_radius_all(radius)
	s.content_margin_left = pad; s.content_margin_right = pad
	s.content_margin_top = pad * 0.7; s.content_margin_bottom = pad * 0.7
	return s

func _resp_style(on: bool) -> StyleBoxFlat:
	var s := _style(Color(0.95, 0.85, 0.55, 0.16) if on else Color(0, 0, 0, 0), Color(0.93, 0.85, 0.66, 0.8 if on else 0.0), 6, 12)
	s.set_border_width_all(1 if on else 0)
	return s

func _build() -> void:
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	box = PanelContainer.new()
	box.add_theme_stylebox_override("panel", _style(Color(0.06, 0.05, 0.04, 0.86), Color(0.93, 0.85, 0.66, 0.85), 10, 20))
	box.mouse_filter = Control.MOUSE_FILTER_PASS
	root.add_child(box)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	box.add_child(v)
	name_l = Label.new()
	name_l.add_theme_font_size_override("font_size", 18)
	name_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART     # a long name wraps at phone width
	name_l.add_theme_color_override("font_color", Color(0.95, 0.78, 0.4))
	v.add_child(name_l)
	text_l = RichTextLabel.new()
	text_l.bbcode_enabled = true
	text_l.fit_content = true
	text_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_l.scroll_active = false
	text_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_l.add_theme_font_size_override("normal_font_size", 21)
	text_l.add_theme_color_override("default_color", Color(1, 0.97, 0.9))
	text_l.custom_minimum_size = Vector2(0, 30)
	v.add_child(text_l)
	resp_box = VBoxContainer.new()
	resp_box.add_theme_constant_override("separation", 4)
	v.add_child(resp_box)
	more_l = Label.new()
	more_l.text = "continue >"
	more_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	more_l.add_theme_font_size_override("font_size", 15)
	more_l.add_theme_color_override("font_color", Color(0.93, 0.85, 0.66, 0.85))
	v.add_child(more_l)
	get_viewport().size_changed.connect(_layout)
	_layout()

## The box hugs the bottom: full width less 16 px gutters on a phone, at most BOX_MAX_W wide.
func _layout() -> void:
	var sz := get_viewport().get_visible_rect().size
	var w := minf(sz.x - 32.0, BOX_MAX_W)
	box.anchor_left = 0.5; box.anchor_right = 0.5; box.anchor_top = 1.0; box.anchor_bottom = 1.0
	box.offset_left = -w * 0.5; box.offset_right = w * 0.5
	box.offset_bottom = -16.0
	box.offset_top = -16.0
	box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	box.custom_minimum_size = Vector2(w, 0)
