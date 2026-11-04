## Shops: buy from the attendant at the counter (workstream SHOPS, Steven Nov 3 2026; design/godot-shops.md).
## "Like Fallout": you don't take things off the shelves; you talk to the attendant, a list opens, you pick,
## the money comes off and they hand it to you (into the bag). Made by scripts/interact.gd beside the
## redemption screen, in every wing and year; reachable as mall.shop (scripts/inventory.gd).
##
##   mall.shop.open(shop_id, attendant = null) -> bool
##       opens shop_id's list (data/story/shops.json) when that shop is open this year; false otherwise.
##       With the attendant node (scripts/attendants/attendant.gd), the camera turns to their face as in a
##       conversation and the list sits beside it.
##   mall.shop.buy(i) -> bool     buys entry i once: false, and nothing changes, when the wallet doesn't
##       cover it (mall.can_afford / mall.spend, design/godot-economy.md). Else the money comes off, the item
##       goes into the bag (mall.add: the "You received" card) and the state is saved; the attendant says the
##       entry's ready_line.
##   mall.shop.close()
##
## The look is the redemption screen's (scripts/redemption.gd): the same panel, cards and buttons, prices in
## dollars, greyed out when you can't afford it. No basket, no leaving-the-store check (later).
## Also here: items whose data has "display": {"runtime": true, ...} are shown at that spot, not picked up
## (the stock on the counter; RadioShack's display copies are built into the wing scene instead).
## Keyboard, gamepad, mouse and touch.
extends Node

const SHOPS_FILE := "res://data/story/shops.json"
const DialogueUI = preload("res://scripts/dialogue/dialogue_ui.gd")
const CAM_T := 0.5

var player: Node3D           # scripts/player.gd (may be null in a unit test)
var mall                     # scripts/inventory.gd
var db                       # scripts/items/item_db.gd
var shops := {}              # id -> the shops.json entry

var is_open := false
var shop_id := ""
var stock: Array = []        # [{item, name, price, icon, line}] of the open shop, this year
var sel := 0
var line := ""               # what the attendant says now
var speaker := ""
var input_kind := "kb"
var attendant: Node3D = null
var _froze := false
var _saved_vis := []
var _stick_latch := false
var _touch_at := Vector2.ZERO
var _touch_moved := false
var _touch_live := false
var _cam: Camera3D
var _from_cam: Camera3D
var _from_xf := Transform3D()
var _from_fov := 70.0
var bought := 0              # purchases made (tests)
var _opened_at := -1         # the frame it opened: the press that opened it doesn't also buy

# ui
var ui: CanvasLayer
var shade: ColorRect
var panel: PanelContainer
var title_l: Label
var money_l: Label
var name_l: Label
var line_l: Label
var hint_l: Label
var scroll: ScrollContainer
var grid: GridContainer
var btn_back: Button
var cards: Array = []
var sb_card: StyleBoxFlat
var sb_card_sel: StyleBoxFlat

## Wire it to the carried state and the item list; reads shops.json. Returns self.
func setup(p: Node3D, m, item_db):
	player = p
	mall = m
	db = item_db
	if "shop" in mall:
		mall.shop = self
	shops = read_shops()
	if player:
		_spawn_displays.call_deferred()
	return self

# ------------------------------------------------------------------ the data (pure)
## shops.json's shops by id.
static func read_shops(path := SHOPS_FILE) -> Dictionary:
	var out := {}
	var j = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null
	if not (j is Dictionary):
		return out
	for s in j.get("shops", []):
		if s is Dictionary and str(s.get("id", "")) != "":
			out[str(s.id)] = s
	return out

## Whether shop s is open in year.
static func open_in(s: Dictionary, year: int) -> bool:
	for y in s.get("years", [1995]):
		if str(y) == "both" or int(y) == year:
			return true
	return false

## A shop's list for a year: entries whose item exists that year and has a whole-cent price >= 0,
## each {item, name, price, icon, line}. Bad entries are left out with a warning.
static func read_stock(s: Dictionary, item_db, year: int) -> Array:
	var out: Array = []
	for x in s.get("items", []):
		if not (x is Dictionary):
			continue
		var id := str(x.get("item", ""))
		var e: Dictionary = item_db.get_item(id)
		var pr = x.get("price_cents", -1)
		if e.is_empty() or not item_db.in_year(e, year):
			push_warning("shop %s: %s is not an item of %d; left out" % [s.get("id"), id, year])
			continue
		if not (pr is float or pr is int) or float(pr) < 0.0 or float(pr) != floor(float(pr)):
			push_warning("shop %s: %s has no whole-cent price; left out" % [s.get("id"), id])
			continue
		out.append({"item": id, "name": str(e.get("name", id)), "price": int(pr), "icon": str(e.get("icon", "")),
			"line": str(x.get("ready_line", ""))})
	return out

func price(i: int) -> int:
	return int(stock[i].price) if i >= 0 and i < stock.size() else -1

func can_buy(i: int) -> bool:
	return i >= 0 and i < stock.size() and mall.can_afford(price(i))

## Buy stock entry i (see the header). One call = one purchase.
func buy(i: int) -> bool:
	if not can_buy(i):
		return false
	var it: Dictionary = stock[i]
	if not mall.spend(price(i), "Shop %s: %s" % [shop_id, it.item]):
		return false
	mall.add(str(it.item))
	mall.save()
	bought += 1
	line = str(it.line)
	if is_open:
		_refresh()
	return true

# ------------------------------------------------------------------ open / close
func open(id: String, who: Node3D = null) -> bool:
	if is_open or not shops.has(id):
		return false
	var s: Dictionary = shops[id]
	if not open_in(s, int(mall.year)):
		return false
	shop_id = id
	stock = read_stock(s, db, int(mall.year))
	line = str(s.get("greeting", ""))
	speaker = str(who.display_name) if who and "display_name" in who and str(who.display_name) != "" else ""
	attendant = who
	if ui == null:
		_build_ui()
	is_open = true
	_opened_at = Engine.get_process_frames()
	_touch_live = false
	if player:
		if not player.frozen:
			player.frozen = true
			_froze = true
		for k in ["move_vec"]:
			if k in player: player.set(k, Vector2.ZERO)
		for k in ["move_touch", "look_touch"]:
			if k in player: player.set(k, -1)
		if "dragging" in player: player.dragging = false
		_saved_vis = []
		var hide: Array = []
		for k in ["buttons"]:
			if k in player and player.get(k) is Array: hide += player.get(k)
		for k in ["jump_open_btn", "hint", "stick", "year_btn"]:
			if k in player and player.get(k) is Control: hide.append(player.get(k))
		var root := player.get_parent()
		var sg = root.get_node_or_null("Signs") if root else null
		if sg and sg.get("ui") is CanvasLayer:
			hide.append(sg.ui)
		for c in hide:
			if c and is_instance_valid(c):
				_saved_vis.append([c, c.visible])
				c.visible = false
	if attendant:
		if attendant.has_method("talk_begin"):
			attendant.talk_begin(player)
		_camera_in()
	sel = 0
	_fill()
	ui.visible = true
	_paint_sel()
	_scroll_top.call_deferred()
	return true

func _scroll_top() -> void:
	await get_tree().process_frame
	scroll.scroll_vertical = 0

func close() -> void:
	if not is_open:
		return
	is_open = false
	ui.visible = false
	for e in _saved_vis:
		if is_instance_valid(e[0]) and not (player and "hint" in player and e[0] == player.hint):
			e[0].visible = e[1]
	_saved_vis = []
	if _froze and player:
		player.frozen = false
	_froze = false
	_camera_out()
	if attendant and is_instance_valid(attendant) and attendant.has_method("talk_end"):
		attendant.talk_end()
	attendant = null

# ------------------------------------------------------------------ the camera (as in a conversation)
func _camera_in() -> void:
	if player == null or not attendant.has_method("face_point"):
		return
	_from_cam = get_viewport().get_camera_3d()
	if _from_cam == null:
		_from_cam = player.cam
	_from_xf = _from_cam.global_transform
	_from_fov = _from_cam.fov
	if _cam == null:
		_cam = Camera3D.new()
		_cam.name = "ShopCam"
		_cam.near = 0.03
		_cam.far = 200.0
		player.get_parent().add_child(_cam)
	_cam.global_transform = _from_xf
	_cam.fov = _from_fov
	_cam.current = true
	var to := _shot()
	var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tw.tween_method(func(t: float): _cam.global_transform = _from_xf.interpolate_with(to, t), 0.0, 1.0, CAM_T)
	tw.tween_property(_cam, "fov", DialogueUI.CAM_FOV, CAM_T)

## The face shot, turned so the face sits in the part of the screen the list leaves free (left on a wide
## screen, top on a tall one).
func _shot() -> Transform3D:
	var xf := DialogueUI.face_shot(attendant.face_point(), player.global_position)
	var vp := get_viewport().get_visible_rect().size
	if vp.x > vp.y * 1.2:
		xf.basis = xf.basis.rotated(Vector3.UP, deg_to_rad(-17.0))   # look right of the face: it lands left
	else:
		xf.basis = xf.basis * Basis(Vector3.RIGHT, deg_to_rad(-8.0))
	return xf

func _camera_out() -> void:
	if _cam == null or not _cam.current:
		return
	var from := _cam.global_transform
	var back := _from_cam.global_transform if is_instance_valid(_from_cam) else _from_xf
	var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tw.tween_method(func(t: float): _cam.global_transform = from.interpolate_with(back, t), 0.0, 1.0, CAM_T)
	tw.tween_property(_cam, "fov", _from_fov, CAM_T)
	await tw.finished
	if is_open:
		return
	if is_instance_valid(_from_cam):
		_from_cam.current = true

# ------------------------------------------------------------------ stock on show
## Items with "display": {"runtime": true, "wing", "year", "pos", "yaw"} stand at that spot as plain
## models (not interactable): what the shop sells, on its counter or table.
func _spawn_displays() -> void:
	await get_tree().process_frame
	if player == null or player.get_parent() == null:
		return
	var holder := Node3D.new()
	holder.name = "ShopDisplays"
	player.get_parent().add_child(holder)
	var wing := int(player.wing) if "wing" in player else 0
	for id in db.order:
		var e: Dictionary = db.get_item(id)
		var d = e.get("display", null)
		if not (d is Dictionary) or not bool(d.get("runtime", false)) or not (d.get("pos") is Array):
			continue
		var y = d.get("year", e.year)
		if str(y) != "both" and int(y) != int(mall.year):
			continue
		if wing != 0 and int(d.get("wing", 0)) != 0 and int(d.get("wing", 0)) != wing:
			continue
		if not ResourceLoader.exists(str(e.scene)):
			continue
		var inst = load(str(e.scene)).instantiate()
		if not (inst is Node3D):
			inst.queue_free()
			continue
		inst.name = "show_" + id
		holder.add_child(inst)
		inst.global_position = Vector3(float(d.pos[0]), float(d.pos[1]), float(d.pos[2]))
		inst.rotation_degrees.y = float(d.get("yaw", 0.0))

# ------------------------------------------------------------------ ui (the redemption screen's look)
func _box(bg: Color, border: Color, radius: int, bw := 2) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(bw)
	sb.set_corner_radius_all(radius)
	return sb

func _btn(t: String, cb: Callable, fs := 15) -> Button:
	var b := Button.new()
	b.text = t
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", fs)
	var n := _box(Color(0.95, 0.89, 0.74), Color(0.08, 0.06, 0.05, 0.6), 8)
	n.content_margin_left = 10; n.content_margin_right = 10; n.content_margin_top = 4; n.content_margin_bottom = 4
	var d := n.duplicate()
	d.bg_color = Color(0.45, 0.42, 0.38, 0.6)
	for st in ["normal", "hover", "pressed", "focus"]:
		b.add_theme_stylebox_override(st, n)
	b.add_theme_stylebox_override("disabled", d)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(c, Color(0.1, 0.08, 0.06))
	b.add_theme_color_override("font_disabled_color", Color(0.15, 0.13, 0.11, 0.7))
	b.pressed.connect(cb)
	return b

func _build_ui() -> void:
	ui = CanvasLayer.new()
	ui.layer = 16              # as the redemption screen: over the HUD (12), under the pop-up (20)
	ui.visible = false
	add_child(ui)
	shade = ColorRect.new()
	shade.color = Color(0, 0, 0, 0.2)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	ui.add_child(shade)
	panel = PanelContainer.new()
	var pb := _box(Color(0.08, 0.06, 0.05, 0.94), Color(0.93, 0.85, 0.66, 0.85), 12)
	pb.set_content_margin_all(12)
	panel.add_theme_stylebox_override("panel", pb)
	ui.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	panel.add_child(col)
	# header: the store and the money, Back
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	col.add_child(head)
	var tcol := VBoxContainer.new()
	tcol.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tcol.add_theme_constant_override("separation", 0)
	head.add_child(tcol)
	title_l = Label.new()
	title_l.add_theme_font_size_override("font_size", 15)
	title_l.add_theme_color_override("font_color", Color(0.93, 0.85, 0.66))
	tcol.add_child(title_l)
	money_l = Label.new()
	money_l.add_theme_font_size_override("font_size", 24)
	money_l.add_theme_color_override("font_color", Color(1, 0.97, 0.9))
	tcol.add_child(money_l)
	btn_back = _btn("Back", func(): close(), 15)
	btn_back.custom_minimum_size = Vector2(76, 40)
	head.add_child(btn_back)
	# what the attendant says (the conversation box's gold name over the line)
	var say := VBoxContainer.new()
	say.add_theme_constant_override("separation", 0)
	col.add_child(say)
	name_l = Label.new()
	name_l.add_theme_font_size_override("font_size", 14)
	name_l.add_theme_color_override("font_color", Color(1, 0.84, 0.4))
	say.add_child(name_l)
	line_l = Label.new()
	line_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	line_l.add_theme_font_size_override("font_size", 18)
	line_l.add_theme_color_override("font_color", Color(1, 0.97, 0.9))
	say.add_child(line_l)
	# the stock
	scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(scroll)
	grid = GridContainer.new()
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	scroll.add_child(grid)
	hint_l = Label.new()
	hint_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_l.add_theme_font_size_override("font_size", 11)
	hint_l.add_theme_color_override("font_color", Color(0.93, 0.85, 0.66, 0.85))
	col.add_child(hint_l)
	sb_card = _box(Color(0.16, 0.13, 0.11, 0.95), Color(0.93, 0.85, 0.66, 0.25), 8, 1)
	sb_card.set_content_margin_all(6)
	sb_card_sel = _box(Color(0.24, 0.19, 0.14, 0.98), Color(1, 0.84, 0.4), 8, 3)
	sb_card_sel.set_content_margin_all(4)
	if get_viewport():
		get_viewport().size_changed.connect(_layout)

## Wide screen: the list on the right, the attendant's face free on the left. Tall (a phone): the list
## on the lower part, the face above it.
func _layout() -> void:
	if panel == null:
		return
	var vp := get_viewport().get_visible_rect().size if get_viewport() else Vector2(1280, 720)
	var w: float
	var h: float
	var at: Vector2
	if vp.x > vp.y * 1.2:
		w = minf(560.0, vp.x * 0.55)
		h = minf(620.0, vp.y - 16.0)
		at = Vector2(vp.x - w - maxf(8.0, vp.x * 0.04), (vp.y - h) * 0.5)
	else:
		w = minf(640.0, vp.x - 16.0)
		h = minf(560.0, vp.y * 0.62)
		at = Vector2((vp.x - w) * 0.5, vp.y - h - 8.0)
	panel.position = at
	panel.size = Vector2(w, h)
	panel.custom_minimum_size = Vector2(w, h)
	grid.columns = maxi(2, int((w - 24.0) / 150.0))
	var cw := (w - 24.0 - 8.0 * (grid.columns - 1) - 14.0) / grid.columns
	var short := h < 460.0
	for c in cards:
		c.card.custom_minimum_size = Vector2(cw, 0)
		c.icon.custom_minimum_size = Vector2(0, 44 if short else 64)
		c.name.custom_minimum_size = Vector2(0, 20 if short else 36)

func _fill() -> void:
	for c in grid.get_children():
		c.queue_free()
	cards.clear()
	for i in stock.size():
		var s: Dictionary = stock[i]
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", sb_card)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 3)
		card.add_child(v)
		var ic := TextureRect.new()
		ic.custom_minimum_size = Vector2(0, 64)
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if s.icon != "" and ResourceLoader.exists(s.icon):
			ic.texture = load(s.icon)
		v.add_child(ic)
		var nm := Label.new()
		nm.text = s.name
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		nm.custom_minimum_size = Vector2(0, 36)
		nm.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		nm.add_theme_font_size_override("font_size", 14)
		nm.add_theme_color_override("font_color", Color(1, 0.97, 0.9))
		v.add_child(nm)
		var pl := Label.new()
		pl.text = mall.money_text(int(s.price))
		pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pl.add_theme_font_size_override("font_size", 15)
		pl.add_theme_color_override("font_color", Color(1, 0.55, 0.5))
		v.add_child(pl)
		var k := i
		var b := _btn("BUY", func(): buy(k), 15)
		b.custom_minimum_size = Vector2(0, 38)
		v.add_child(b)
		grid.add_child(card)
		cards.append({"card": card, "buy": b, "i": i, "icon": ic, "name": nm})
	_layout()
	_refresh()

## Money, the attendant's line, greyed-out cards and the hint for the current input.
func _refresh() -> void:
	if money_l == null:
		return
	var s: Dictionary = shops.get(shop_id, {})
	title_l.text = str(s.get("title", s.get("store", "")))
	money_l.text = "Your money: %s" % mall.money_text(int(mall.money))
	name_l.text = speaker
	name_l.visible = speaker != ""
	line_l.text = line
	for c in cards:
		var ok := can_buy(c.i)
		c.buy.disabled = not ok
		c.card.modulate = Color(1, 1, 1, 1) if ok else Color(0.6, 0.6, 0.6, 0.55)
	hint_l.text = {"pad": "D-pad to choose · A buy · B back",
		"touch": "Tap BUY · drag to scroll · Back when done"}.get(input_kind,
		"Arrows / WASD to choose · Enter buy · Esc back")

func _paint_sel() -> void:
	for c in cards:
		c.card.add_theme_stylebox_override("panel", sb_card_sel if (c.i == sel and input_kind != "touch") else sb_card)
	if sel >= 0 and sel < cards.size() and input_kind != "touch":
		scroll.ensure_control_visible.call_deferred(cards[sel].card)

func _move(dx: int, dy: int) -> void:
	if stock.is_empty():
		return
	var n := stock.size()
	var cols: int = grid.columns
	var s := sel + dx + dy * cols
	if dy != 0 and (s < 0 or s >= n):
		s = sel
	sel = clampi(s, 0, n - 1)
	_paint_sel()

# ------------------------------------------------------------------ input
func _input(e: InputEvent) -> void:
	if not is_open:
		return
	var was := input_kind
	if e is InputEventJoypadButton or (e is InputEventJoypadMotion and abs(e.axis_value) > 0.4):
		input_kind = "pad"
	elif e is InputEventKey or e is InputEventMouseButton:
		input_kind = "kb"
	elif e is InputEventScreenTouch:
		input_kind = "touch"
	if was != input_kind:
		_refresh(); _paint_sel()
	# the pop-up (higher layer) takes input first while it shows
	if mall and mall.get_meta("popup_open", false):
		return
	if Engine.get_process_frames() == _opened_at and not (e is InputEventScreenDrag):
		get_viewport().set_input_as_handled()
		return
	var handled := true
	if e is InputEventKey and e.pressed:
		match e.physical_keycode:
			KEY_LEFT, KEY_A: _move(-1, 0)
			KEY_RIGHT, KEY_D: _move(1, 0)
			KEY_UP, KEY_W: _move(0, -1)
			KEY_DOWN, KEY_S: _move(0, 1)
			KEY_ENTER, KEY_KP_ENTER, KEY_E, KEY_SPACE:
				if not e.echo: buy(sel)
			KEY_ESCAPE, KEY_Q, KEY_BACKSPACE, KEY_TAB:
				if not e.echo: close()
			_: handled = false
	elif e is InputEventJoypadButton and e.pressed:
		match e.button_index:
			JOY_BUTTON_DPAD_LEFT: _move(-1, 0)
			JOY_BUTTON_DPAD_RIGHT: _move(1, 0)
			JOY_BUTTON_DPAD_UP: _move(0, -1)
			JOY_BUTTON_DPAD_DOWN: _move(0, 1)
			JOY_BUTTON_A: buy(sel)
			JOY_BUTTON_B, JOY_BUTTON_BACK: close()
			_: pass
	elif e is InputEventJoypadMotion:
		if e.axis in [JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y]:
			if abs(e.axis_value) > 0.6 and not _stick_latch:
				_stick_latch = true
				var d := 1 if e.axis_value > 0 else -1
				if e.axis == JOY_AXIS_LEFT_X: _move(d, 0)
				else: _move(0, d)
			elif abs(e.axis_value) < 0.3:
				_stick_latch = false
	elif e is InputEventScreenTouch:
		if e.pressed:
			_touch_at = e.position
			_touch_moved = false
			_touch_live = true
		elif _touch_live and not _touch_moved:
			_touch_live = false
			_tap(e.position)
	elif e is InputEventScreenDrag:
		if e.position.distance_to(_touch_at) > 12.0:
			_touch_moved = true
		scroll.scroll_vertical -= int(e.relative.y)
	elif e is InputEventMouseButton:
		# clicks reach the buttons; a click outside the panel closes
		if e.pressed and e.button_index == MOUSE_BUTTON_LEFT and not panel.get_global_rect().has_point(e.position):
			close()
		else:
			handled = false
	else:
		handled = false
	if handled:
		get_viewport().set_input_as_handled()

## A tap: Back; a card selects, its BUY buys; outside the panel closes.
func _tap(at: Vector2) -> void:
	if btn_back.is_visible_in_tree() and btn_back.get_global_rect().has_point(at):
		close()
		return
	if not panel.get_global_rect().has_point(at):
		close()
		return
	if not scroll.get_global_rect().has_point(at):
		return
	for c in cards:
		if c.card.get_global_rect().has_point(at):
			sel = c.i
			_paint_sel()
			if c.buy.get_global_rect().has_point(at) and not c.buy.disabled:
				buy(c.i)
			return
