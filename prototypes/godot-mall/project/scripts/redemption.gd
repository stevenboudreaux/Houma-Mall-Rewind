## Pocket Change's ticket redemption screen (workstream R, Steven Nov 2 2026; design/godot-prize-counter.md
## "Redemption"). Made by scripts/interact.gd next to the player's carried state, in every wing and year;
## reachable as mall.redemption (scripts/inventory.gd).
##
##   mall.redemption.open()    shows the counter's stock (scripts/redemption.json: every prize of
##                             scripts/prizes.json plus the Blender prizes), each with its icon, name and
##                             ticket price, and the player's tickets at the top.
##   BUY (Enter/E/Space, a pad's A, a tap on BUY): when tickets >= price, the tickets go down, the item is
##   added to the bag (mall.add: put away, not in the hand) and the "You received" pop-up shows
##   (scripts/received_popup.gd, through mall.received). What you can't afford is greyed out.
##   Back (Esc/Q/Backspace, a pad's B, the Back button) closes. "Look at the prizes" (L, a pad's Y, its
##   button) closes this and opens the counter's closer look (scripts/prizes.gd), when the counter is here.
##
## Who opens it: the counter glass (prizes.gd's prompt, now "Redeem tickets") and the Pocket Change
## attendant (workstream Q's hook: it calls mall.redemption.open() if it exists).
## Keyboard, gamepad, mouse and touch (touches are handled here: the project doesn't emulate the mouse).
extends Node

const STOCK_FILE := "res://scripts/redemption.json"
const PRIZES_FILE := "res://scripts/prizes.json"

var player: Node3D           # scripts/player.gd (may be null in a unit test)
var mall                     # scripts/inventory.gd
var db                       # scripts/items/item_db.gd
var stock: Array = []        # [{item, name, tickets, icon}] for this year, in redemption.json order

var is_open := false
var sel := 0
var input_kind := "kb"
var _froze := false
var _saved_vis := []
var _stick_latch := false
var _touch_at := Vector2.ZERO
var _touch_moved := false

# ui
var ui: CanvasLayer
var shade: ColorRect
var panel: PanelContainer
var tickets_l: Label
var hint_l: Label
var scroll: ScrollContainer
var grid: GridContainer
var btn_back: Button
var btn_look: Button
var cards: Array = []        # [{card: PanelContainer, buy: Button, i: int}]
var sb_card: StyleBoxFlat
var sb_card_sel: StyleBoxFlat

## Wire it to the carried state and the item list; reads the stock. Returns self.
func setup(p: Node3D, m, item_db):
	player = p
	mall = m
	db = item_db
	mall.redemption = self
	stock = read_stock(db, int(mall.year))
	return self

# ------------------------------------------------------------------ the stock (pure data)
## The stock for a year: redemption.json's entries whose item exists in that year, each
## {item, name, tickets, icon}. Name and price: prizes.json's when the entry names a "prize", the
## entry's own "tickets" when it has one (it wins), else the item file's "tickets".
static func read_stock(item_db, year: int) -> Array:
	var out: Array = []
	var sj = JSON.parse_string(FileAccess.get_file_as_string(STOCK_FILE)) if FileAccess.file_exists(STOCK_FILE) else null
	var pj = JSON.parse_string(FileAccess.get_file_as_string(PRIZES_FILE)) if FileAccess.file_exists(PRIZES_FILE) else null
	var prizes: Dictionary = pj.get("items", {}) if pj is Dictionary else {}
	if not (sj is Dictionary):
		return out
	for s in sj.get("stock", []):
		if not (s is Dictionary):
			continue
		var id := str(s.get("item", ""))
		var e: Dictionary = item_db.get_item(id)
		if e.is_empty() or not item_db.in_year(e, year):
			continue
		var pz: Dictionary = prizes.get(str(s.get("prize", "")), {})
		var tk := int(s.get("tickets", pz.get("tickets", e.get("tickets", 0))))
		var nm := str(pz.get("name", e.get("name", id))) if s.has("prize") else str(e.get("name", id))
		if tk <= 0:
			push_warning("redemption: %s has no ticket price; left out" % id)
			continue
		out.append({"item": id, "name": nm, "tickets": tk, "icon": str(e.get("icon", ""))})
	return out

func price(i: int) -> int:
	return int(stock[i].tickets) if i >= 0 and i < stock.size() else 0

func can_buy(i: int) -> bool:
	return i >= 0 and i < stock.size() and int(mall.tickets) >= price(i)

## Redeem stock entry i: false (nothing changes) when the tickets don't cover it. Else the tickets go
## down, the item goes into the bag (mall.add, which shows the pop-up) and the state is saved.
func buy(i: int) -> bool:
	if not can_buy(i):
		return false
	mall.tickets = int(mall.tickets) - price(i)
	mall.add(str(stock[i].item))
	mall.save()
	if is_open:
		_refresh()
	return true

# ------------------------------------------------------------------ open / close
func open() -> void:
	if is_open:
		return
	if ui == null:
		_build_ui()
	stock = read_stock(db, int(mall.year))
	is_open = true
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
	sel = clampi(sel, 0, maxi(0, stock.size() - 1))
	_fill()
	ui.visible = true
	_paint_sel()

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

func _prizes_node() -> Node:
	if player == null or player.get_parent() == null:
		return null
	return player.get_parent().get_node_or_null("Prizes")

func look_at_prizes() -> void:
	var pz := _prizes_node()
	if pz == null or not pz.has_method("open_look"):
		return
	close()
	pz.open_look()

# ------------------------------------------------------------------ ui
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
	ui.layer = 16              # over the prizes' look screen (15) and the HUD (12)
	ui.visible = false
	add_child(ui)
	shade = ColorRect.new()
	shade.color = Color(0, 0, 0, 0.45)
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
	# header: the title and the tickets, Back
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	col.add_child(head)
	var tcol := VBoxContainer.new()
	tcol.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tcol.add_theme_constant_override("separation", 0)
	head.add_child(tcol)
	var title := Label.new()
	title.text = "Prize redemption"
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", Color(0.93, 0.85, 0.66))
	tcol.add_child(title)
	tickets_l = Label.new()
	tickets_l.add_theme_font_size_override("font_size", 24)
	tickets_l.add_theme_color_override("font_color", Color(1, 0.97, 0.9))
	tcol.add_child(tickets_l)
	btn_look = _btn("Look at the prizes", func(): look_at_prizes(), 14)
	btn_look.custom_minimum_size = Vector2(0, 40)
	head.add_child(btn_look)
	btn_back = _btn("Back", func(): close(), 15)
	btn_back.custom_minimum_size = Vector2(76, 40)
	head.add_child(btn_back)
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
	get_viewport().size_changed.connect(_layout)

## Fits the panel to the screen: up to 640 x 560, never wider or taller than the screen less a margin.
func _layout() -> void:
	if panel == null:
		return
	var vp := get_viewport().get_visible_rect().size
	var w := minf(640.0, vp.x - 16.0)
	var h := minf(560.0, vp.y - 16.0)
	panel.position = Vector2((vp.x - w) * 0.5, (vp.y - h) * 0.5)
	panel.size = Vector2(w, h)
	panel.custom_minimum_size = Vector2(w, h)
	grid.columns = maxi(2, int((w - 24.0) / 150.0))
	var cw := (w - 24.0 - 8.0 * (grid.columns - 1) - 14.0) / grid.columns
	for c in cards:
		c.card.custom_minimum_size = Vector2(cw, 0)
	btn_look.visible = _prizes_node() != null
	btn_look.text = "Look at the prizes" if w >= 420.0 else "Look"

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
		ic.custom_minimum_size = Vector2(0, 72)
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
		var tk := Label.new()
		tk.text = "%s tickets" % _commas(int(s.tickets))
		tk.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tk.add_theme_font_size_override("font_size", 14)
		tk.add_theme_color_override("font_color", Color(1, 0.55, 0.5))
		v.add_child(tk)
		var k := i
		var b := _btn("BUY", func(): buy(k), 15)
		b.custom_minimum_size = Vector2(0, 38)
		v.add_child(b)
		grid.add_child(card)
		cards.append({"card": card, "buy": b, "i": i, "icon": ic})
	_layout()
	_refresh()

## Ticket count, greyed-out cards and the hint for the current input.
func _refresh() -> void:
	if tickets_l == null:
		return
	tickets_l.text = "Your tickets: %s" % _commas(int(mall.tickets))
	for c in cards:
		var ok := can_buy(c.i)
		c.buy.disabled = not ok
		c.card.modulate = Color(1, 1, 1, 1) if ok else Color(0.6, 0.6, 0.6, 0.55)
	hint_l.text = {"pad": "D-pad to choose · A buy · Y look at the prizes · B back",
		"touch": "Tap BUY to redeem · drag to scroll · Back when done"}.get(input_kind,
		"Arrows / WASD to choose · Enter buy · L look at the prizes · Esc back")

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

static func _commas(n: int) -> String:
	var s := str(n)
	return s if s.length() <= 3 else s.substr(0, s.length() - 3) + "," + s.substr(s.length() - 3)

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
			KEY_L:
				if not e.echo and btn_look.visible: look_at_prizes()
			_: handled = false
	elif e is InputEventJoypadButton and e.pressed:
		match e.button_index:
			JOY_BUTTON_DPAD_LEFT: _move(-1, 0)
			JOY_BUTTON_DPAD_RIGHT: _move(1, 0)
			JOY_BUTTON_DPAD_UP: _move(0, -1)
			JOY_BUTTON_DPAD_DOWN: _move(0, 1)
			JOY_BUTTON_A: buy(sel)
			JOY_BUTTON_B, JOY_BUTTON_BACK: close()
			JOY_BUTTON_Y:
				if btn_look.visible: look_at_prizes()
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
		elif not _touch_moved:
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

## A tap: a button under it is pressed; a card selects; outside the panel closes.
func _tap(at: Vector2) -> void:
	for b in [btn_back, btn_look]:
		if b.is_visible_in_tree() and b.get_global_rect().has_point(at):
			b.pressed.emit()
			return
	if not panel.get_global_rect().has_point(at):
		close()
		return
	var sr := scroll.get_global_rect()
	if not sr.has_point(at):
		return
	for c in cards:
		if c.card.get_global_rect().has_point(at):
			sel = c.i
			_paint_sel()
			if c.buy.get_global_rect().has_point(at) and not c.buy.disabled:
				buy(c.i)
			return
