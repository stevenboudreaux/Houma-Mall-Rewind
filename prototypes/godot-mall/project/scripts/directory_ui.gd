## The mall directory, read up close (design/godot-directory.md). Opened from a directory kiosk
## (scripts/directory_kiosk.gd). There is no separate menu: what you see is the kiosk's own lit
## panel (tex/dir/panel_<year>.png, the same picture as on the 3D sign; 2026 is the real directory
## redrawn from IMG_4455), in its aluminium frame. Click or tap a store's name in the list, or its
## place on the map, and it asks "Jump to this store?".
##
## The click areas come with the panel (tex/dir/hotspots.json, tools/stores/directory/paint_dir.py);
## where each store's jump puts you comes from the wing build (gen/<wing>/directory.json, from the
## layout files), so a jump always lands in front of the store as the wing was built.
## The only things added to the sign: the year on show with a toggle beside it, and a close button
## on the frame. MENU2 (Nov 3 2026, design/godot-menu.md "Time travel at the directory"): the toggle
## is the only way to change year. Pressing it closes the sign and travels in time from where you
## stand (scripts/timetravel_trip.gd) to this directory's twin in the other year. The sign shows only
## the year you are in.
##
## Controls: mouse or touch (tap a name or a block; drag to pan and pinch or the wheel to zoom once
## zoomed in); arrow keys / d-pad / stick move from store to store, Enter / A asks, Enter / A again
## jumps, Esc / B backs out; Y (key or a gamepad's Y) or the toggle travels in time; +/- zoom.
extends CanvasLayer

const LAYER := 25
const FRAME := Color("#b3babc")      # the kiosk's aluminium (sampled from the footage)
const FRAME_D := Color("#7d8487")
const PINK := Color("#b5676d")
const HILITE := Color("#ff2d6f")

var data := {}                 # gen/<wing>/directory.json: {"years": {"1995": {stalls...}, ...}}
var spots := {}                # tex/dir/hotspots.json: {"size": [w, h], "1995": [...], "2026": [...]}
var stall_by_id := {}          # year -> {unit id: stall}
var player: Node = null
var kiosk: Node = null
var is_open := false
var map_year := "2026"
var sel := ""                  # the selected store's unit id
var hover := ""
var confirm := false
var confirm_yes := true
var zoom := 1.0
var pan := Vector2.ZERO        # panel pixel at the view's centre

var root: Control
var view: Control
var f_sans: Font

var touches := {}
var drag_from := Vector2.ZERO
var drag_moved := false
var look_rect := Rect2()       # PROTOTYPE ws/directory (dirlook=c): the 3D panel's place on screen
var look_owner: Node = null    # ... and the camera reader to hand back to on close
var pressed_in := false        # the press began while the sign was open (the tap that opened it does not count)
var pinch_d := 0.0
var last_touch_ms := -100000

# the fallback prompt (remove when interact.gd lands: workstream B+C's shared interaction system)
var fallback := true
var near_kiosk: Node = null
var prompt_rect := Rect2()

func _ready() -> void:
	layer = LAYER
	fallback = not ResourceLoader.exists("res://scripts/interact.gd")
	f_sans = load("res://fonts/sans.otf")
	var scn := get_parent()
	var gen: String = scn.get_meta("gen", "res://gen/") if scn else "res://gen/"
	if FileAccess.file_exists(gen + "directory.json"):
		data = JSON.parse_string(FileAccess.get_file_as_string(gen + "directory.json"))
	if FileAccess.file_exists("res://tex/dir/hotspots.json"):
		spots = JSON.parse_string(FileAccess.get_file_as_string("res://tex/dir/hotspots.json"))
	for y in data.get("years", {}):
		var m := {}
		for st in data.years[y].stalls:
			m[st.id] = st
		stall_by_id[y] = m
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	view = Control.new()
	view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	view.draw.connect(_draw_view)
	root.add_child(view)

# ------------------------------------------------------------------ open / close
func open(p: Node, k: Node) -> void:
	if data.is_empty() or spots.is_empty() or is_open:
		return
	player = p
	kiosk = k
	is_open = true
	confirm = false
	sel = ""
	hover = ""
	map_year = str(p.get("year")) if p and p.get("year") != null else "1995"
	if not stall_by_id.has(map_year):
		map_year = "1995"
	if p:
		p.set("frozen", true)
	pressed_in = false
	touches.clear()
	_fit()
	view.queue_redraw()

func close() -> void:
	is_open = false
	confirm = false
	if look_owner:
		# PROTOTYPE ws/directory: the camera reader takes the camera back to the player
		var lo := look_owner
		look_owner = null
		look_rect = Rect2()
		view.queue_redraw()
		lo.flat_closed()
		return
	if player:
		player.set("frozen", false)
	view.queue_redraw()

## Both years' panels. Every wing's export carries both (export_presets.cfg includes tex/dir/*):
## a wing's own kiosks only reference their year's panel, and the toggle shows the other.
var tex := {}
func _panel() -> Texture2D:
	if not tex.has(map_year):
		var p := "res://tex/dir/panel_%s.png" % map_year
		tex[map_year] = load(p) if ResourceLoader.exists(p) else null
	return tex[map_year]

func _psize() -> Vector2:
	var s: Array = spots.get("size", [2048, 2290])
	return Vector2(s[0], s[1])

func _hot() -> Array:
	return spots.get(map_year, [])

func _stall(id: String):
	return stall_by_id.get(map_year, {}).get(id, null)

# ------------------------------------------------------------------ layout: the panel on screen
func _vp() -> Vector2:
	return get_viewport().get_visible_rect().size

func _narrow() -> bool:
	return _vp().x < 760.0

## The frame's width round the panel, in screen pixels.
func _fw() -> float:
	return 10.0 if _narrow() else 18.0

func _fit_scale() -> float:
	if look_rect.size.x > 0:
		return look_rect.size.x / _psize().x
	var vp := _vp()
	var m := _fw() + (6.0 if _narrow() else 20.0)
	var top := 44.0 if _narrow() else 0.0     # phones: the toggle sits above the sign
	return min((vp.x - 2 * m) / _psize().x, (vp.y - 2 * m - top) / _psize().y)

func _fit() -> void:
	zoom = 1.0
	pan = _psize() * 0.5

func _scale() -> float:
	return _fit_scale() * zoom

func _centre() -> Vector2:
	if look_rect.size.x > 0:
		return look_rect.get_center()
	var c := _vp() * 0.5
	if _narrow():
		c.y += 22.0
	return c

func _p2s(p: Vector2) -> Vector2:
	return _centre() + (p - pan) * _scale()

func _s2p(s: Vector2) -> Vector2:
	return pan + (s - _centre()) / _scale()

func _clamp_pan() -> void:
	var half := _vp() * 0.5 / _scale()
	var ps := _psize()
	pan.x = ps.x * 0.5 if half.x * 2 >= ps.x else clamp(pan.x, half.x, ps.x - half.x)
	pan.y = ps.y * 0.5 if half.y * 2 >= ps.y else clamp(pan.y, half.y, ps.y - half.y)

func _zoom_by(f: float, about := Vector2(-1, -1)) -> void:
	if about.x < 0:
		about = _centre()
	var pp := _s2p(about)
	zoom = clamp(zoom * f, 1.0, 6.0)
	pan = pp - (about - _centre()) / _scale()
	_clamp_pan()
	view.queue_redraw()

## The buttons on the frame: [rect, what]. MENU2: the year on show ("year", a label) with the time
## travel toggle ("travel") beside it, and close.
func _buttons() -> Array:
	var vp := _vp()
	var pr := _panel_rect() if zoom <= 1.01 else Rect2(Vector2(_fw() + 26, 26), vp - Vector2(2 * _fw() + 52, 52))
	var h := 34.0
	var y: float = 6.0 if _narrow() else max(6.0, pr.position.y - _fw() - h * 0.5)
	var xr: float = min(vp.x - 8.0, pr.end.x + _fw()) - 44.0
	var tw := 112.0
	var yw := 70.0
	return [[Rect2(xr, y, 44, h), "close"], [Rect2(xr - 10 - tw, y, tw, h), "travel"], [Rect2(xr - 10 - tw - 6 - yw, y, yw, h), "year"]]

func _panel_rect() -> Rect2:
	var a := _p2s(Vector2.ZERO)
	return Rect2(a, _psize() * _scale())

# ------------------------------------------------------------------ drawing
func _draw_view() -> void:
	var c := view
	if not is_open:
		_draw_prompt(c)
		return
	var vp := _vp()
	var pr := _panel_rect()
	var fw := _fw()
	if look_rect.size.x > 0:
		pass   # PROTOTYPE ws/directory: the 3D kiosk is the frame; no dimming, no drawn frame
	else:
		_draw_frame(c, pr, fw, vp)
	var ptex := _panel()
	if ptex:
		c.draw_texture_rect(ptex, pr, false)
	_draw_marks(c, vp)

func _draw_frame(c: Control, pr: Rect2, fw: float, vp: Vector2) -> void:
	c.draw_rect(Rect2(Vector2.ZERO, vp), Color(0, 0, 0, 0.62))
	# the kiosk's frame round the lit panel: grey cabinet edge, the red pinstripe on top, the
	# aluminium frame with a lighter inner lip, and the dark gasket
	var outer := pr.grow(fw)
	c.draw_rect(outer.grow(4), Color("#a7b1b3"))
	c.draw_rect(Rect2(outer.position.x - 4, outer.position.y - 9, outer.size.x + 8, 5), PINK)
	c.draw_rect(outer, FRAME)
	c.draw_rect(outer, FRAME_D, false, 1.5)
	c.draw_rect(pr.grow(3), Color("#d5dadb"))
	c.draw_rect(pr.grow(1.5), Color("#1c1d20"))

func _draw_marks(c: Control, vp: Vector2) -> void:
	# the selected / hovered store: every place it appears on the sign
	for pass_id in [hover, sel]:
		if pass_id == "":
			continue
		var col := HILITE if pass_id == sel else Color(HILITE, 0.55)
		for h in _hot():
			if h.id == pass_id:
				var r := _hrect(h)
				c.draw_rect(r.grow(2), Color(HILITE, 0.18 if pass_id == sel else 0.10))
				c.draw_rect(r.grow(2), col, false, 2.5 if pass_id == sel else 1.5)
	# the store's name, on a small tag over its place on the map
	var shown := sel if sel != "" else hover
	if shown != "":
		var st = _stall(shown)
		var mr := Rect2()
		for h in _hot():
			if h.id == shown and h.kind == "map":
				mr = _hrect(h)
				break
		if st and mr.size.x > 0:
			var txt := String(st.name)
			if map_year == "1995" and int(st.num) > 0:
				txt = "%d  %s" % [int(st.num), st.name]
			var fs := 15
			var tw := f_sans.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			var tr := Rect2(mr.get_center().x - tw * 0.5 - 8, mr.position.y - 30, tw + 16, 24)
			tr.position.x = clamp(tr.position.x, 4, vp.x - tr.size.x - 4)
			tr.position.y = max(tr.position.y, 4)
			c.draw_rect(tr, Color(0.08, 0.08, 0.1, 0.88))
			c.draw_string(f_sans, tr.position + Vector2(8, 17), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE)
	# the frame's buttons: the year with the time-travel toggle beside it, and close
	for b in _buttons():
		var r: Rect2 = b[0]
		var what: String = b[1]
		match what:
			"year":
				c.draw_rect(r, Color(0.12, 0.13, 0.15, 0.85))
				c.draw_rect(r, Color(1, 1, 1, 0.8), false, 1.5)
				_text_c(c, map_year, r.get_center(), 19, Color.WHITE)
			"travel":
				_draw_toggle(c, r)
			_:
				c.draw_rect(r, Color(0.12, 0.13, 0.15, 0.85))
				c.draw_rect(r, Color(1, 1, 1, 0.8), false, 1.5)
				_text_c(c, "X", r.get_center(), 15, Color.WHITE)
	if confirm:
		_draw_confirm(c)

## MENU2: the toggle, a switch with both years on it, the knob on the year you are in. A keyboard or
## gamepad gets its key (Y) on the knob's far side.
func _draw_toggle(c: Control, r: Rect2) -> void:
	var on_right := map_year == "2026"
	var rad := r.size.y * 0.5
	var track := Color(0.12, 0.13, 0.15, 0.9)
	c.draw_rect(Rect2(r.position + Vector2(rad, 0), r.size - Vector2(2 * rad, 0)), track)
	c.draw_circle(r.position + Vector2(rad, rad), rad, track)
	c.draw_circle(r.position + Vector2(r.size.x - rad, rad), rad, track)
	var kw := r.size.x * 0.5
	var kr := Rect2(r.position + Vector2(r.size.x - kw if on_right else 0.0, 0), Vector2(kw, r.size.y)).grow(-3)
	var knob := Color("#2f93c3")
	var kh := kr.size.y * 0.5
	c.draw_rect(Rect2(kr.position + Vector2(kh, 0), kr.size - Vector2(2 * kh, 0)), knob)
	c.draw_circle(kr.position + Vector2(kh, kh), kh, knob)
	c.draw_circle(kr.position + Vector2(kr.size.x - kh, kh), kh, knob)
	_text_c(c, map_year, kr.get_center(), 14, Color.WHITE)
	var other := "1995" if on_right else "2026"
	var oc := r.position + Vector2(kw * 0.5 if on_right else r.size.x - kw * 0.5, rad)
	var kind: String = str(player.get("input_kind")) if player else "kb"
	_text_c(c, other + (" Y" if kind != "touch" else ""), oc, 13, Color(1, 1, 1, 0.75))

## MENU2: the toggle. The sign closes and the trip begins from this kiosk.
func _travel() -> void:
	if player == null or confirm:
		return
	var p := player
	var k: Node3D = kiosk if kiosk is Node3D else null
	close()
	if k == null:
		k = Node3D.new()
		k.position = p.position
	load("res://scripts/timetravel_trip.gd").begin(p, k)

func _hrect(h: Dictionary) -> Rect2:
	var a := _p2s(Vector2(h.rect[0], h.rect[1]))
	var b := _p2s(Vector2(h.rect[2], h.rect[3]))
	return Rect2(a, b - a)

func _text_c(c: CanvasItem, t: String, p: Vector2, size: int, col: Color) -> void:
	var sz := f_sans.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, size)
	c.draw_string(f_sans, p + Vector2(-sz.x * 0.5, size * 0.36), t, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)

var r_yes := Rect2()
var r_no := Rect2()
func _draw_confirm(c: Control) -> void:
	var vp := _vp()
	var st = _stall(sel)
	if st == null:
		return
	c.draw_rect(Rect2(Vector2.ZERO, vp), Color(0, 0, 0, 0.4))
	var dw: float = min(400.0, vp.x - 24)
	var dlg := Rect2((vp.x - dw) * 0.5, vp.y * 0.5 - 90, dw, 176)
	c.draw_rect(dlg, Color("#f3f6f7"))
	c.draw_rect(Rect2(dlg.position, Vector2(dlg.size.x, 8)), Color("#2f93c3") if map_year == "2026" else Color("#1f5c66"))
	c.draw_rect(dlg, FRAME_D, false, 2.0)
	_text_c(c, "Jump to this store?", dlg.position + Vector2(dw * 0.5, 40), 21, Color("#262626"))
	var nm := String(st.name)
	if map_year == "1995" and int(st.num) > 0:
		nm = "%d  %s" % [int(st.num), st.name]
	_text_c(c, nm, dlg.position + Vector2(dw * 0.5, 70), 17, HILITE.darkened(0.25))
	var j: Array = st.jump
	if player and (int(j[0]) != int(player.get("wing")) or map_year != str(player.get("year"))):
		_text_c(c, "Loads Wing %d, %s" % [int(j[0]), map_year], dlg.position + Vector2(dw * 0.5, 92), 12, Color("#666666"))
	r_yes = Rect2(dlg.position.x + 16, dlg.end.y - 58, dw * 0.5 - 24, 44)
	r_no = Rect2(dlg.position.x + dw * 0.5 + 8, dlg.end.y - 58, dw * 0.5 - 24, 44)
	for b in [[r_yes, "Yes, go there", confirm_yes], [r_no, "Cancel", not confirm_yes]]:
		var rr: Rect2 = b[0]
		c.draw_rect(rr, Color("#262a30") if b[2] else Color.WHITE)
		c.draw_rect(rr, Color("#262a30"), false, 2.0)
		_text_c(c, b[1], rr.get_center(), 16, Color.WHITE if b[2] else Color("#262a30"))

# ------------------------------------------------------------------ the fallback prompt
## Remove when interact.gd lands (workstream B+C): their action button calls interact() on us.
func _draw_prompt(c: Control) -> void:
	prompt_rect = Rect2()
	if near_kiosk == null:
		return
	var vp := _vp()
	var kind: String = str(player.get("input_kind")) if player else "kb"
	var key: String = {"pad": "X", "touch": "Tap", "kb": "E"}.get(kind, "E")
	var w := 280.0
	# where the seam's prompt goes (scripts/player.gd); the two never show together
	prompt_rect = Rect2((vp.x - w) * 0.5, vp.y - 132, w, 54)
	c.draw_rect(prompt_rect, Color(0.08, 0.06, 0.05, 0.78))
	c.draw_rect(prompt_rect, Color(0.93, 0.85, 0.66, 0.85), false, 2.0)
	var kr := Rect2(prompt_rect.position + Vector2(14, 10), Vector2(50 if key == "Tap" else 36, 34))
	c.draw_rect(kr, Color(0.95, 0.89, 0.74))
	_text_c(c, key, kr.get_center(), 16, Color(0.1, 0.08, 0.06))
	c.draw_string(f_sans, Vector2(kr.end.x + 12, prompt_rect.position.y + 33), "Read the Mall Directory", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 0.97, 0.9))

func _process(_dt: float) -> void:
	if is_open or not fallback:
		return
	if player == null:
		player = get_parent().get_node_or_null("Player")
	var nk: Node = null
	if player and not player.get("frozen") and not player.get("leaving"):
		var seam_prompt = player.get("prompt")
		if not (seam_prompt and seam_prompt.visible):
			for k in get_tree().get_nodes_in_group("directory_kiosk"):
				if k.in_reach(player.position):
					nk = k
					break
	if nk != near_kiosk or nk != null:
		near_kiosk = nk
		view.queue_redraw()   # every frame while near: the key cap follows the input (E, X, Tap)

# ------------------------------------------------------------------ input
func _input(e: InputEvent) -> void:
	if not is_open:
		_fallback_input(e)
		return
	get_viewport().set_input_as_handled()
	if e is InputEventKey and e.pressed:
		_key(e)
	elif e is InputEventJoypadButton and e.pressed:
		_pad(e.button_index)
	elif e is InputEventJoypadMotion:
		_stick(e)
	elif e is InputEventScreenTouch:
		last_touch_ms = Time.get_ticks_msec()
		_touch(e)
	elif e is InputEventScreenDrag:
		last_touch_ms = Time.get_ticks_msec()
		_touch_drag(e)
	elif e is InputEventMouseButton:
		if Time.get_ticks_msec() - last_touch_ms < 600:
			return
		if e.button_index == MOUSE_BUTTON_WHEEL_UP and e.pressed:
			_zoom_by(1.2, e.position)
		elif e.button_index == MOUSE_BUTTON_WHEEL_DOWN and e.pressed:
			_zoom_by(1.0 / 1.2, e.position)
		elif e.button_index == MOUSE_BUTTON_LEFT:
			if e.pressed:
				_press(e.position)
			else:
				_release(e.position)
	elif e is InputEventMouseMotion:
		if Time.get_ticks_msec() - last_touch_ms < 600:
			return
		if e.button_mask & MOUSE_BUTTON_MASK_LEFT:
			_move(e.position, e.relative)
		else:
			var h := _hit(e.position)
			if h != hover:
				hover = h
				view.queue_redraw()

func _fallback_input(e: InputEvent) -> void:
	if not fallback or near_kiosk == null or player == null:
		return
	var go := false
	if e is InputEventKey and e.pressed and not e.echo and e.physical_keycode == KEY_E:
		go = true
	elif e is InputEventJoypadButton and e.pressed and e.button_index == JOY_BUTTON_X:
		go = true
	elif e is InputEventScreenTouch and e.pressed and prompt_rect.has_point(e.position):
		go = true
	elif e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT and prompt_rect.has_point(e.position):
		go = true
	if go:
		get_viewport().set_input_as_handled()
		near_kiosk.interact(player)

## The store under a screen point: a list line before a map place, the smallest place first.
func _hit(s: Vector2) -> String:
	var p := _s2p(s)
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

func _key(e: InputEventKey) -> void:
	var k := e.physical_keycode
	if confirm:
		if k in [KEY_LEFT, KEY_RIGHT, KEY_A, KEY_D, KEY_TAB]:
			confirm_yes = not confirm_yes
		elif k in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
			_choose(confirm_yes)
		elif k in [KEY_ESCAPE, KEY_BACKSPACE]:
			confirm = false
		view.queue_redraw()
		return
	match k:
		KEY_ESCAPE, KEY_BACKSPACE:
			close()
		KEY_LEFT:
			_step(Vector2(-1, 0))
		KEY_RIGHT:
			_step(Vector2(1, 0))
		KEY_UP:
			_step(Vector2(0, -1))
		KEY_DOWN:
			_step(Vector2(0, 1))
		KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
			_ask()
		KEY_Y:
			_travel()
			return
		KEY_EQUAL, KEY_KP_ADD:
			_zoom_on_sel(1.4)
		KEY_MINUS, KEY_KP_SUBTRACT:
			_zoom_by(1.0 / 1.4)
	view.queue_redraw()

func _pad(b: int) -> void:
	if confirm:
		match b:
			JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_DPAD_RIGHT:
				confirm_yes = not confirm_yes
			JOY_BUTTON_A:
				_choose(confirm_yes)
			JOY_BUTTON_B:
				confirm = false
		view.queue_redraw()
		return
	match b:
		JOY_BUTTON_B, JOY_BUTTON_BACK:
			close()
		JOY_BUTTON_DPAD_LEFT:
			_step(Vector2(-1, 0))
		JOY_BUTTON_DPAD_RIGHT:
			_step(Vector2(1, 0))
		JOY_BUTTON_DPAD_UP:
			_step(Vector2(0, -1))
		JOY_BUTTON_DPAD_DOWN:
			_step(Vector2(0, 1))
		JOY_BUTTON_A:
			_ask()
		JOY_BUTTON_Y:
			_travel()
			return
		JOY_BUTTON_X:
			if zoom < 5.0:
				_zoom_on_sel(1.5)
			else:
				_fit()
	view.queue_redraw()

var _stick_held := false
func _stick(e: InputEventJoypadMotion) -> void:
	if e.axis != JOY_AXIS_LEFT_X and e.axis != JOY_AXIS_LEFT_Y:
		return
	if abs(e.axis_value) < 0.3:
		_stick_held = false
		return
	if _stick_held or abs(e.axis_value) < 0.6:
		return
	_stick_held = true
	var d := Vector2(signf(e.axis_value), 0) if e.axis == JOY_AXIS_LEFT_X else Vector2(0, signf(e.axis_value))
	if confirm:
		if d.x != 0:
			confirm_yes = not confirm_yes
	else:
		_step(d)
	view.queue_redraw()

## A store's point on the sign for moving between stores: its place on the map, else its first
## list line.
func _anchor(id: String) -> Vector2:
	var lst := Vector2(-1, -1)
	for h in _hot():
		if h.id == id:
			var c := Vector2((h.rect[0] + h.rect[2]) * 0.5, (h.rect[1] + h.rect[3]) * 0.5)
			if h.kind == "map":
				return c
			if lst.x < 0:
				lst = c
	return lst

func _ids() -> Array:
	var out := []
	for h in _hot():
		if not (h.id in out) and _stall(h.id) != null:
			out.append(h.id)
	return out

## Move the selection to the nearest store in direction d on the sign.
func _step(d: Vector2) -> void:
	var ids := _ids()
	if ids.is_empty():
		return
	if sel == "":
		sel = ids[0]
		if kiosk:
			# start at the store nearest the kiosk
			var bd := 1e12
			for id in ids:
				var st = _stall(id)
				var dd := Vector2(st.label[0], st.label[1]).distance_to(Vector2(kiosk.position.x, kiosk.position.z))
				if dd < bd:
					bd = dd
					sel = id
		return
	var p0 := _anchor(sel)
	var best := ""
	var best_cost := 1e12
	for id in ids:
		if id == sel:
			continue
		var v := _anchor(id) - p0
		var along := v.dot(d)
		if along <= 1.0:
			continue
		var off := absf(v.dot(Vector2(-d.y, d.x)))
		if off > along * 2.5:
			continue
		var cost := along + off * 2.0
		if cost < best_cost:
			best_cost = cost
			best = id
	if best != "":
		sel = best

func _zoom_on_sel(f: float) -> void:
	if sel != "":
		_zoom_by(f, _p2s(_anchor(sel)))
	else:
		_zoom_by(f)

func _ask() -> void:
	if sel != "" and _stall(sel) != null:
		confirm = true
		confirm_yes = true
		view.queue_redraw()

func _choose(yes: bool) -> void:
	confirm = false
	if not yes:
		view.queue_redraw()
		return
	var st = _stall(sel)
	var j: Array = st.jump
	print("directory jump: ", st.name, " (", map_year, ") -> wing ", j[0], " at ", j[1], ",", j[2], " yaw ", j[3])
	var p := player
	close()
	if p and p.has_method("jump_to"):
		p.jump_to(int(j[0]), int(map_year), float(j[1]), float(j[2]), float(j[3]))

# pointer (mouse and touch)
func _press(p: Vector2) -> void:
	drag_from = p
	drag_moved = false
	pressed_in = true

func _move(p: Vector2, rel: Vector2) -> void:
	if (p - drag_from).length() > 8.0:
		drag_moved = true
	if drag_moved and zoom > 1.01 and not confirm:
		pan -= rel / _scale()
		_clamp_pan()
		view.queue_redraw()

func _release(p: Vector2) -> void:
	if not pressed_in:
		return
	pressed_in = false
	if drag_moved:
		drag_moved = false
		return
	if confirm:
		if r_yes.has_point(p):
			_choose(true)
		elif r_no.has_point(p):
			_choose(false)
		view.queue_redraw()
		return
	for b in _buttons():
		if (b[0] as Rect2).has_point(p):
			if b[1] == "close":
				close()
			elif b[1] == "travel":
				_travel()
			return
	if zoom <= 1.01 and not _panel_rect().grow(_fw()).has_point(p):
		close()
		return
	var id := _hit(p)
	if id != "":
		sel = id
		_ask()
	view.queue_redraw()

func _touch(e: InputEventScreenTouch) -> void:
	if e.pressed:
		touches[e.index] = e.position
		if touches.size() == 1:
			_press(e.position)
		elif touches.size() == 2:
			var ps := touches.values()
			pinch_d = (ps[0] as Vector2).distance_to(ps[1])
			drag_moved = true
	else:
		touches.erase(e.index)
		if touches.is_empty():
			_release(e.position)

func _touch_drag(e: InputEventScreenDrag) -> void:
	var prev: Vector2 = touches.get(e.index, e.position)
	touches[e.index] = e.position
	if touches.size() >= 2:
		var ps := touches.values()
		var d := (ps[0] as Vector2).distance_to(ps[1])
		if pinch_d > 0.0 and d > 0.0:
			_zoom_by(d / pinch_d, ((ps[0] as Vector2) + (ps[1] as Vector2)) * 0.5)
		pinch_d = d
		return
	_move(e.position, e.position - prev)
