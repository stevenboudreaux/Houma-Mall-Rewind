## Workstream M (design/godot-menu.md): the full-screen menu. Made by scripts/player.gd as its child
## "Menu" (every wing, both years), after Avatar.
##
## MENU2 (Steven, Nov 3 2026): tabs, left to right: MAIN (the current character, their name, money
## and tickets, and the Character row; CHAR-STRIP, Nov 8 2026, below), INVENTORY (the TICKETS count and the carried items with HELD /
## PUT AWAY and Drop) and CONTROLS (every action with its keyboard key, gamepad button and touch
## control, read from the InputMap; click a key or button to remap it: scripts/menu/controls.gd).
## There is no YEAR tab: the year changes only at a mall directory (scripts/timetravel_trip.gd).
## A JOURNAL tab is planned after CONTROLS (not built).
##
## Open / close: Tab (remappable), a gamepad's Start, the Menu button; Esc and B close too. Tabs: Q / E,
## LB / RB (and the triggers LT / RT), a swipe, or a tap on the tab. The old ways in still work and
## open their tab: I and the Bag button (INVENTORY), C (MAIN). The
## player is frozen while it is open. Not in VR (a flat overlay isn't seen in the headset).
##
## Input: one catcher node sits last under the root, so it sees every event before anything else;
## while the menu is open it takes them all and taps / clicks its own buttons by hand
## (the project turns touch-to-mouse emulation off); while closed it lets the controls' translation
## layer re-send remapped keys (controls.gd filter()).
##
## No opening (ws/items, Steven Nov 4 2026: the placeholder intro is gone; the game just starts in the mall).
##
## CHAR-STRIP (Steven, Nov 8 2026; design/godot-avatar.md): the character editor is gone (no Edit, no
## sliders, no colours). MAIN's Character row shows the 3-4 cast members of data/cast.json, each a small
## portrait and its name; picking one saves it (Cast, "mall-player-2") and makes the world's body anew
## through the one loader (scripts/avatar.gd choose()). The NAME is typed on MAIN (tap the NAME field).
extends Node

const Controls = preload("res://scripts/menu/controls.gd")
## MENU2 (Steven, Nov 3): MAIN, INVENTORY, CONTROLS. A later "journal" (JOURNAL) goes last; not built.
const TABS := ["main", "inventory", "controls"]
const TAB_NAMES := {"main": "MAIN", "controls": "CONTROLS", "inventory": "INVENTORY", "owner": "OWNER"}
const Portrait = preload("res://scripts/menu/portrait.gd")
const BG := Color(0.07, 0.055, 0.045, 0.97)
const INK := Color(1, 0.97, 0.9)
const GOLD := Color(0.93, 0.85, 0.66)
const AMBER := Color(0.85, 0.62, 0.22)

var player: Node3D
var controls: Controls
var is_open := false
var tab := "main"
var _trig := {}                  # trigger axis -> held (LT / RT change tabs once per pull)

var _layer: CanvasLayer
var _root: Control
var _catcher: Node
var _froze := false
var _hits: Array = []            # [Control, Callable]: tapped / clicked by hand
var _nav: Array = []             # rows of [Control, Callable] for keys and pad
var _sel := Vector2i.ZERO        # row, column in _nav
var _hover: Control = null
var _content := Rect2()
var _scroll: ScrollContainer = null
var _msg: Label = null
var _capture := {}               # {"id", "kind": "key" | "pad"} while waiting for a key / button
var _name_lbl: Label = null
var _name_box: PanelContainer = null
var _typing := false
var _caret_t := 0.0
var _touch := {}                 # touch index -> {"at": Vector2, "scroll": int, "moved": bool}
var _menu_btn: Button
var _built_for := Vector2.ZERO
var _input_kind := "kb"
var _tuck_t := 0.0
## UI-OFFSCREEN (Steven, Nov 4): the menu icon shows on touch devices only (a touch screen, or once a
## touch arrives); a desktop opens the menu with Tab / Esc, a pad with Start.
var touch_device := false

class Catcher extends Node:
	var menu: Node
	func _input(e: InputEvent) -> void:
		if menu and is_instance_valid(menu):
			menu._catch(e)

func _ready() -> void:
	controls = Controls.new()
	controls.setup()
	_layer = CanvasLayer.new()
	_layer.layer = 45
	_layer.visible = false
	add_child(_layer)
	_build_menu_button()
	# the catcher goes last under the root (after the wing), so its _input runs first
	_catcher = Catcher.new()
	_catcher.name = "MenuInputCatcher"
	_catcher.menu = self
	get_tree().root.add_child.call_deferred(_catcher)
	tree_exiting.connect(func():
		if is_instance_valid(_catcher):
			_catcher.queue_free())
	get_viewport().size_changed.connect(func():
		if is_open:
			_build())

func _mall():
	return player.mall if player and "mall" in player else null

# ------------------------------------------------------------------ open / close
## Open the menu on tab t (one of TABS), or switch to it when open. "avatar" and "year" (gone) open MAIN.
func open_tab(t: String) -> void:
	if t == "avatar" or t == "year":
		t = "main"
	if not (t in tabs()):
		t = tab
	if not is_open:
		if not _can_open():
			return
		is_open = true
		if not player.frozen:
			player.frozen = true
			_froze = true
		player.move_vec = Vector2.ZERO
		player.move_touch = -1
		player.look_touch = -1
		player.dragging = false
		player.rmb_run = false
		if player.stick:
			player.stick.visible = false
		if player.jump_panel and player.jump_panel.visible:
			player._jump_show(false)
		_layer.visible = true
	if tab != t:
		_stop_typing(true)
		_capture = {}
	tab = t
	_sel = Vector2i.ZERO
	_build()

## The tabs this visitor gets: TABS, and for the owner OWNER last (design/godot-owner-mode.md).
func tabs() -> Array:
	return TABS + ["owner"] if is_owner() else TABS.duplicate()

## The Character row picked cast member `id` (CHAR-STRIP): saved, and the world's body made anew
## through the loader (scripts/avatar.gd choose()); MAIN is rebuilt so its portrait shows the same id.
func choose_cast(id: String) -> void:
	var av = player.avatar
	if av and av.has_method("choose"):
		av.choose(id)
	else:
		Cast.set_player_id(id)
	if is_open and tab == "main":
		_build()

func close() -> void:
	if not is_open:
		return
	_stop_typing(true)
	_capture = {}
	is_open = false
	_layer.visible = false
	if _froze:
		player.frozen = false
		_froze = false

func _can_open() -> bool:
	if player == null or player.leaving or player.vr_on:
		return false
	if player.frozen and not _froze:
		return false      # someone else has the screen (the prize counter's closer look, the directory)
	return true

# ------------------------------------------------------------------ the HUD button
## UI-OFFSCREEN (Steven, Nov 4 2026: "no text on the game screen; everything goes in the menu"):
## the Menu button is a small unlabelled icon (three bars) top left, the one thing left in the
## corners. Tab / Start open the menu too. The corner buttons it replaces (Jump to, Bag, View, Avatar)
## are tucked away by _tuck_corner_buttons() and reached from MAIN / INVENTORY.
func _build_menu_button() -> void:
	_menu_btn = Button.new()
	_menu_btn.text = ""
	_menu_btn.tooltip_text = "Menu (%s)" % _first_key("menu", "Tab")
	_menu_btn.focus_mode = Control.FOCUS_NONE
	_menu_btn.position = Vector2(10, 8)
	_menu_btn.size = Vector2(ICON_SIZE, ICON_SIZE)
	if is_owner():
		# OWNER (design/godot-owner-mode.md): the owner keeps the old labelled Menu button
		_menu_btn.text = "Menu (%s)" % _first_key("menu", "Tab")
		_menu_btn.add_theme_font_size_override("font_size", 14)
		_menu_btn.size = Vector2(110, 32)
		_menu_btn.pressed.connect(func(): open_tab("main"))
		player._cl.add_child(_menu_btn)
		touch_device = DisplayServer.is_touchscreen_available()
		_tuck_corner_buttons.call_deferred()
		return
	for st in ["normal", "hover", "pressed", "focus"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0, 0, 0, 0.42 if st == "hover" or st == "pressed" else 0.28)
		sb.set_corner_radius_all(9)
		_menu_btn.add_theme_stylebox_override(st, sb)
	_menu_btn.draw.connect(func():
		var s := _menu_btn.size
		var w := s.x * 0.46
		for i in 3:
			var y := s.y * (0.34 + 0.16 * i)
			_menu_btn.draw_line(Vector2((s.x - w) * 0.5, y), Vector2((s.x + w) * 0.5, y), Color(1, 1, 1, 0.82), 2.6, true))
	_menu_btn.pressed.connect(func(): open_tab("main"))
	player._cl.add_child(_menu_btn)
	touch_device = DisplayServer.is_touchscreen_available()
	_tuck_corner_buttons.call_deferred()
	_hint_sync.call_deferred()

## UI-OFFSCREEN: on a desktop (no icon) the existing first-start walk hint also names the menu key, so a
## mouse player finds the menu; no new words on the screen. Touch devices keep the hint as it was.
func _hint_sync() -> void:
	var h = player.get("hint")
	if h == null or not is_instance_valid(h):
		return
	if not h.has_meta("base_text"):
		h.set_meta("base_text", h.text)
	var base: String = h.get_meta("base_text")
	h.text = base if touch_device else "%s  ·  %s or Esc: menu" % [base, _first_key("menu", "Tab")]
	if not touch_device:
		h.offset_left = minf(h.offset_left, -320.0)
		h.offset_right = maxf(h.offset_right, 320.0)

func _icon_sync() -> void:
	# OWNER: the owner's labelled Menu button shows on every device (design/godot-owner-mode.md)
	_menu_btn.visible = (touch_device or is_owner()) and not is_open and not player.vr_on \
			and not (player.frozen and not _froze)

const ICON_SIZE := 42.0
const OFFSCREEN := "OffscreenHud"

## UI-OFFSCREEN: the old corner buttons go into a hidden holder beside them. They keep working
## (their code still sets .visible, lays out round them and reads them), but nothing draws them and
## a tap can't reach them (every hit test checks is_visible_in_tree()). MAIN: Jump to, View;
## INVENTORY: the Bag.
func corner_buttons() -> Array:
	var out: Array = []
	var it = player.interact
	var av = player.avatar
	for b in [player.jump_open_btn, player.year_btn, it.bag_btn if it and "bag_btn" in it else null,
			av.view_btn if av and "view_btn" in av else null]:
		if b != null and is_instance_valid(b):
			out.append(b)
	return out

## OWNER (design/godot-owner-mode.md): the owner's loose tool buttons that the OWNER tab replaces:
## the Reflections / Benches & plants / Lighting toggles (player.gd), Edit signs / Publish signs /
## Arcade (signs.gd) and Shirt words (npc_shirt.gd). Tucked like the corner buttons, so their own
## code (and VR's menu, which reads player.buttons[2].visible) is unchanged.
func owner_tool_buttons() -> Array:
	var out: Array = []
	for b in player.buttons:
		out.append(b)
	var scn: Node = player.get_parent()
	var sg = scn.get_node_or_null("Signs") if scn else null
	if sg:
		for k in ["b_edit", "b_pub", "b_arc"]:
			if sg.get(k) is Button:
				out.append(sg.get(k))
	var sw = scn.get_node_or_null("ShirtWords") if scn else null
	if sw and sw.get("btn") is Button:
		out.append(sw.get("btn"))
	return out.filter(func(b): return b != null and is_instance_valid(b))

## OWNER (design/godot-owner-mode.md): owner mode, as player.is_owner() (localStorage
## "southland-editor" = "1", ?owner=1, the hallway code; tests: Engine meta "mall_owner").
func is_owner() -> bool:
	return player != null and player.has_method("is_owner") and player.is_owner()

## What goes into the hidden holder: a visitor's corner buttons (UI-OFFSCREEN); for the owner, who
## keeps every corner button on screen, the loose owner-tool buttons instead (owner_tool_buttons(),
## reached from the OWNER tab).
func _tuck_list() -> Array:
	return owner_tool_buttons() if is_owner() else corner_buttons()

func _tuck_corner_buttons() -> void:
	for b in _tuck_list():
		var par: Node = b.get_parent()
		if par == null or par.name == OFFSCREEN:
			continue
		var hold: Control = par.get_node_or_null(OFFSCREEN)
		if hold == null:
			hold = Control.new()
			hold.name = OFFSCREEN
			hold.visible = false
			hold.mouse_filter = Control.MOUSE_FILTER_IGNORE
			hold.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			par.add_child(hold)
		b.reparent(hold, false)

## MAIN's Jump to: the quick-jump panel, on the game screen (as J).
func menu_jump() -> void:
	if not _jump_ok():
		return
	close()
	player._jump_show(true)

func _jump_ok() -> bool:
	var jb = player.jump_open_btn
	return jb != null and jb.visible and not player.jump_locked and not player.leaving

## MAIN's View: first / third person (as V); the menu closes so you see it.
func menu_view() -> void:
	close()
	if player.avatar:
		player.avatar.toggle_view()

func _hint(id: String, fallback: String) -> String:
	return "" if _input_kind == "touch" else "  (%s)" % _first_key(id, fallback)

func _process(dt: float) -> void:
	# entering VR: the flat menu can't be seen in the headset, so it closes
	if player and player.vr_on:
		if is_open:
			close()
	# OWNER: tools made later (Signs, ShirtWords are added deferred) are tucked as they appear
	_tuck_t += dt
	if _tuck_t > 0.5:
		_tuck_t = 0.0
		_tuck_corner_buttons()
	if _menu_btn:
		_icon_sync()
		# the owner's fps readout is top left: go under it
		_menu_btn.position.y = 34.0 if (player.hud and player.hud.visible) else 8.0
		_menu_btn.tooltip_text = "Menu (%s)" % _first_key("menu", "Tab")
	if _typing and _name_lbl:
		_caret_t += dt
		_name_text()

func _first_key(id: String, fallback: String) -> String:
	var k: Array = controls.keys(id) if controls else []
	return Controls.key_name(int(k[0])) if not k.is_empty() else fallback

# ------------------------------------------------------------------ building
func _build() -> void:
	var vs := get_viewport().get_visible_rect().size
	_built_for = vs
	if _root:
		_root.queue_free()
	_hits = []
	_nav = []
	_scroll = null
	_msg = null
	_name_lbl = null
	_name_box = null
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(_root)
	var narrow := vs.x < 600.0
	var bar_h := 44.0
	var pad := 8.0 if narrow else 12.0
	# the background
	var bg := ColorRect.new()
	bg.color = BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(bg)
	# the tab bar
	var close_w := 44.0
	var TB := tabs()
	var tw := (vs.x - pad * 2 - close_w - 6.0 * TB.size()) / TB.size()
	var fs_tab := int(clampf(tw / 7.2, 11, 17))
	for i in TB.size():
		var t: String = TB[i]
		var b := _button(_root, TAB_NAMES[t], Rect2(pad + i * (tw + 6.0), pad * 0.5, tw, bar_h), fs_tab, func(): open_tab(t))
		_paint(b, AMBER if t == tab else Color(0.2, 0.16, 0.12), Color(0.1, 0.07, 0.04) if t == tab else INK)
	var cb := _button(_root, "×", Rect2(vs.x - pad - close_w, pad * 0.5, close_w, bar_h), 18, close)
	cb.tooltip_text = "Close"
	var foot_h := 0.0 if _input_kind == "touch" else 22.0
	_content = Rect2(pad, pad * 0.5 + bar_h + pad, vs.x - pad * 2, vs.y - (pad * 0.5 + bar_h + pad) - pad - foot_h)
	if foot_h > 0.0:
		var foot := Label.new()
		foot.text = "%s / %s, LB / RB or LT / RT: tabs  ·  arrows + Enter or d-pad + A: choose  ·  %s, Esc or B: close" % [
			_first_key("tab_prev", "Q"), _first_key("tab_next", "E"), _first_key("menu", "Tab")]
		foot.position = Vector2(pad, vs.y - pad - foot_h)
		foot.size = Vector2(vs.x - pad * 2, foot_h)
		foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		foot.clip_text = true
		foot.add_theme_font_size_override("font_size", 12)
		foot.add_theme_color_override("font_color", Color(GOLD, 0.8))
		_root.add_child(foot)
	match tab:
		"main": _build_main(narrow)
		"controls": _build_controls(narrow)
		"inventory": _build_inventory(narrow)
		"owner": _build_owner(narrow)
	_sel.x = clampi(_sel.x, 0, maxi(0, _nav.size() - 1))
	_paint_sel()

func _button(parent: Control, t: String, r: Rect2, fs: int, cb: Callable) -> Button:
	var b := Button.new()
	b.text = t
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", fs)
	b.clip_text = true
	if r.has_area():
		b.position = r.position
		b.size = r.size
	b.pressed.connect(cb)
	parent.add_child(b)
	_hits.append([b, cb])
	return b

func _paint(b: Button, bg: Color, fg: Color) -> void:
	for st in ["normal", "hover", "pressed", "disabled", "focus"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = bg if st != "hover" else bg.lightened(0.08)
		if st == "disabled":
			sb.bg_color = Color(bg, 0.35)
		sb.set_corner_radius_all(8)
		sb.content_margin_left = 6; sb.content_margin_right = 6
		b.add_theme_stylebox_override(st, sb)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(c, fg)
	b.add_theme_color_override("font_disabled_color", Color(fg, 0.45))

func _label(parent: Control, t: String, fs: int, col := INK) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", col)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	parent.add_child(l)
	return l

## A scrolling column filling the content area.
func _column() -> VBoxContainer:
	_scroll = ScrollContainer.new()
	_scroll.position = _content.position
	_scroll.size = _content.size
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_scroll)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 6)
	_scroll.add_child(col)
	return col

func _note(parent: Control, fs: int) -> void:
	_msg = _label(parent, "", fs, Color(1, 0.8, 0.55))
	_msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_msg.custom_minimum_size.x = maxf(100.0, _content.size.x - 20.0)

func _say(t: String) -> void:
	if _msg:
		_msg.text = t

# ------------------------------------------------------------------ MAIN
## The contract with workstream ECON: mall.money, the current year's balance (mall is per year).
## Until ECON is merged the field doesn't exist: then 0, stub = true. Read only here.
func money() -> Dictionary:
	var m = _mall()
	if m != null and "money" in m and m.get("money") != null:
		return {"value": float(m.get("money")), "stub": false}
	return {"value": 0.0, "stub": true}

## mall.tickets, the current year's ticket balance.
func tickets() -> int:
	var m = _mall()
	return int(m.tickets) if m != null and "tickets" in m else 0

func money_text() -> String:
	return "$%.2f" % float(money().value)

## MAIN: the current character turning on the left (on top on a tall screen), and beside it their
## name (tap to type), money and tickets, the Character row (CHAR-STRIP), View and Jump to.
func _build_main(narrow: bool) -> void:
	var tall := _content.size.y > _content.size.x
	var pr: Rect2
	var ir: Rect2
	if tall:
		var ph := clampf(_content.size.y * 0.4, 150.0, 380.0)
		pr = Rect2(_content.position, Vector2(_content.size.x, ph))
		ir = Rect2(_content.position + Vector2(0, ph + 8.0), Vector2(_content.size.x, _content.size.y - ph - 8.0))
	else:
		var pw := clampf(minf(_content.size.x * 0.34, _content.size.y * 0.7), 140.0, 380.0)
		pr = Rect2(_content.position, Vector2(pw, _content.size.y))
		ir = Rect2(_content.position + Vector2(pw + 18.0, 0), Vector2(_content.size.x - pw - 18.0, _content.size.y))
	var por := Portrait.new()
	por.name = "MainPortrait"
	por.position = pr.position
	_root.add_child(por)
	por.fit(pr.size)
	var av = player.avatar
	var cur: String = av.cast_id if av and "cast_id" in av and str(av.cast_id) != "" else Cast.player_id()
	por.show_cast(cur)
	var col := VBoxContainer.new()
	col.position = ir.position
	col.size = ir.size
	col.alignment = BoxContainer.ALIGNMENT_CENTER if not tall else BoxContainer.ALIGNMENT_BEGIN
	col.add_theme_constant_override("separation", 4 if narrow else 8)
	_root.add_child(col)
	# a short screen (a phone held sideways): each label beside its value, one line each
	var compact := ir.size.y < 520.0
	var fs_l := 13 if narrow or compact else 15
	var fs_v := 20 if compact else (24 if narrow else 30)
	for row in [["NAME", ""], ["MONEY", money_text()], ["TICKETS", str(tickets())]]:
		var holder: Control = col
		if compact:
			var hb := HBoxContainer.new()
			hb.add_theme_constant_override("separation", 12)
			col.add_child(hb)
			holder = hb
		var l := _label(holder, row[0], fs_l, Color(GOLD, 0.8))
		l.custom_minimum_size = Vector2(80 if compact else 0, 16)
		var vw := minf(ir.size.x - (92.0 if compact else 0.0), 420.0)
		if row[0] == "NAME":
			# the NAME field (mall.player_name): tap / Enter types it
			_name_box = PanelContainer.new()
			_name_box.name = "MainName"
			_name_box.custom_minimum_size = Vector2(minf(vw, 320.0), fs_v + 14)
			_name_box.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			holder.add_child(_name_box)
			_name_lbl = Label.new()
			_name_lbl.add_theme_font_size_override("font_size", fs_v - 2)
			_name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			_name_lbl.clip_text = true
			_name_box.add_child(_name_lbl)
			_hits.append([_name_box, _name_tapped])
			_nav.append([[_name_box, _name_tapped]])
			_name_text()
			continue
		var v := _label(holder, row[1], fs_v, GOLD)
		v.clip_text = true
		v.custom_minimum_size = Vector2(vw, fs_v + 8)
		v.name = "Main" + String(row[0]).capitalize()
	# CHAR-STRIP: the Character row, one portrait + name per cast member (data/cast.json "player")
	var ids := Cast.player_ids()
	if not ids.is_empty():
		var cl := _label(col, "CHARACTER", fs_l, Color(GOLD, 0.8))
		cl.custom_minimum_size.y = 18
		var crow := HBoxContainer.new()
		crow.name = "MainCharacters"
		crow.add_theme_constant_override("separation", 8)
		col.add_child(crow)
		var n := ids.size()
		var tw := clampf((minf(ir.size.x, 560.0) - 8.0 * (n - 1)) / n, 64.0, 120.0)
		var room_h := ir.size.y - (3 * (fs_v + 18) if not compact else 3 * (fs_v + 12)) - 18 - 50 - 30
		var ph := clampf(minf(tw * 1.3, room_h - 24.0), 70.0, 160.0)
		var nr: Array = []
		for id in ids:
			var cid := str(id)
			var cb := _button(crow, "", Rect2(), 12, choose_cast.bind(cid))
			cb.name = "Cast_" + cid
			cb.tooltip_text = Cast.display_name(cid)
			cb.custom_minimum_size = Vector2(tw, ph + 24)
			cb.clip_text = false
			var on := cid == cur
			_paint(cb, Color(0.2, 0.16, 0.12), INK)
			if on:
				for st in ["normal", "hover", "pressed", "focus"]:
					var sb: StyleBoxFlat = cb.get_theme_stylebox(st).duplicate()
					sb.set_border_width_all(3)
					sb.border_color = AMBER
					cb.add_theme_stylebox_override(st, sb)
			var th := Portrait.new()
			th.spin = false
			th.position = Vector2(4, 4)
			cb.add_child(th)
			th.fit(Vector2(tw - 8, ph - 4))
			th.show_cast(cid)
			var nl := Label.new()
			nl.text = Cast.display_name(cid)
			nl.clip_text = true
			nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			nl.add_theme_font_size_override("font_size", 11 if tw < 90 else 13)
			nl.add_theme_color_override("font_color", AMBER if on else INK)
			nl.position = Vector2(2, ph + 2)
			nl.size = Vector2(tw - 4, 20)
			nl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			cb.add_child(nl)
			nr.append([cb, choose_cast.bind(cid)])
		_nav.append(nr)
	var gap := Control.new()
	gap.custom_minimum_size.y = 2 if compact else (4 if narrow else 8)
	col.add_child(gap)
	# UI-OFFSCREEN: View and Jump to (were corner buttons)
	var fl := HFlowContainer.new()
	fl.add_theme_constant_override("h_separation", 8)
	fl.add_theme_constant_override("v_separation", 8)
	fl.custom_minimum_size.x = minf(ir.size.x, 560.0)
	col.add_child(fl)
	var fs_b := 16 if narrow or compact else 18
	var bh := 42.0 if compact else 46.0
	var third: bool = player.avatar != null and bool(player.avatar.third)
	var vb := _button(fl, "View: %s%s" % ["3rd person" if third else "1st person", _hint("view", "V")], Rect2(), fs_b, menu_view)
	vb.name = "MainView"
	vb.custom_minimum_size = Vector2(150, bh)
	_paint(vb, Color(0.2, 0.16, 0.12), INK)
	var jb := _button(fl, "Jump to" + _hint("jump", "J"), Rect2(), fs_b, menu_jump)
	jb.name = "MainJump"
	jb.custom_minimum_size = Vector2(120, bh)
	jb.disabled = not _jump_ok()
	_paint(jb, Color(0.2, 0.16, 0.12), INK)
	for b in [vb, jb]:
		b.clip_text = false       # grow to fit (the key hint, "3rd person")
	var br: Array = [[vb, menu_view]]
	if not jb.disabled:
		br.append([jb, menu_jump])
	_nav.append(br)
	var mm = _mall()
	if mm and not mm.changed.is_connected(_inv_changed):
		mm.changed.connect(_inv_changed)

func _name_text() -> void:
	if _name_lbl == null:
		return
	var m = _mall()
	var n: String = (m.player_name if m else "")
	if _typing:
		n = _name_buf + ("|" if fmod(_caret_t, 1.0) < 0.55 else " ")
	_name_lbl.text = n if n != "" else " "
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.16, 0.13, 0.1)
	sb.set_border_width_all(2)
	sb.border_color = AMBER if _typing else Color(GOLD, 0.5)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 10; sb.content_margin_right = 10
	_name_box.add_theme_stylebox_override("panel", sb)
	_name_lbl.add_theme_color_override("font_color", INK)

var _name_buf := ""

func _name_tapped() -> void:
	# a phone: the browser's own text box, so its keyboard comes up
	if _input_kind == "touch" and OS.has_feature("web"):
		var m = _mall()
		var cur: String = m.player_name if m else ""
		var v = JavaScriptBridge.eval("(function(){var r=window.prompt('NAME',%s);return r===null?'\\u0000':r})()" % JSON.stringify(cur), true)
		if v is String and v != "\u0000" and m:
			m.player_name = v
		_name_text()
		return
	if _typing:
		_stop_typing(true)
	else:
		start_typing()

## Focus the NAME field: typed keys go into it until Enter, Tab or Esc.
func start_typing() -> void:
	var m = _mall()
	_name_buf = m.player_name if m else ""
	_typing = true
	_caret_t = 0.0
	_name_text()

func _stop_typing(keep: bool) -> void:
	if not _typing:
		return
	_typing = false
	var m = _mall()
	if keep and m:
		m.player_name = _name_buf
	_name_text()

func _type_key(e: InputEventKey) -> void:
	match e.keycode:
		KEY_ENTER, KEY_KP_ENTER, KEY_TAB:
			_stop_typing(true)
		KEY_ESCAPE:
			_stop_typing(false)
		KEY_BACKSPACE:
			_name_buf = _name_buf.left(maxi(0, _name_buf.length() - 1))
		_:
			if e.unicode >= 32 and _name_buf.length() < 20:
				_name_buf += String.chr(e.unicode)
	_caret_t = 0.0
	_name_text()

# ------------------------------------------------------------------ CONTROLS
func _build_controls(narrow: bool) -> void:
	var col := _column()
	var fs := 12 if narrow else 15
	var w := _content.size.x - 14.0
	var cw := [w * 0.31, w * 0.23, w * 0.23, w * 0.23] if narrow else [w * 0.3, w * 0.22, w * 0.22, w * 0.26]
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 0)
	col.add_child(head)
	for i in 4:
		var l := _label(head, ["ACTION", "KEYBOARD", "GAMEPAD", "TOUCH"][i], fs, GOLD)
		l.custom_minimum_size = Vector2(cw[i], 26)
	for e in controls.list:
		var id := str(e.id)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 0)
		row.custom_minimum_size.y = 40 if narrow else 36
		col.add_child(row)
		var l := _label(row, str(e.label), fs)
		l.custom_minimum_size = Vector2(cw[0], 0)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var nav_row: Array = []
		for k in 2:
			var kind := "key" if k == 0 else "pad"
			var t: String = controls.key_text(id) if k == 0 else controls.pad_text(id)
			if _capture.get("id", "") == id and _capture.get("kind", "") == kind:
				t = "Press a key…" if kind == "key" else "Press a button…"
			if controls.remappable(id) if k == 0 else controls.pad_remappable(id):
				var cbk := func(): _start_capture(id, kind)
				var b := _button(row, t, Rect2(), fs, cbk)
				b.custom_minimum_size = Vector2(cw[k + 1] - 4.0, 34)
				b.alignment = HORIZONTAL_ALIGNMENT_LEFT
				b.clip_text = false
				b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				b.tooltip_text = "Click, then press the new %s" % ("key" if kind == "key" else "gamepad button")
				_paint(b, AMBER if _capture.get("id", "") == id and _capture.get("kind", "") == kind else Color(0.2, 0.16, 0.12), Color(0.1, 0.07, 0.04) if _capture.get("id", "") == id and _capture.get("kind", "") == kind else INK)
				var gap := Control.new(); gap.custom_minimum_size.x = 4.0; row.add_child(gap)
				nav_row.append([b, cbk])
			else:
				var fl := _label(row, t, fs, Color(INK, 0.75))
				fl.custom_minimum_size = Vector2(cw[k + 1], 0)
				fl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var tl := _label(row, str(e.get("touch", "")) if str(e.get("touch", "")) != "" else "—", fs, Color(INK, 0.75))
		tl.custom_minimum_size = Vector2(cw[3], 0)
		tl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if not nav_row.is_empty():
			_nav.append(nav_row)
	_note(col, fs)
	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", 10)
	col.add_child(foot)
	var rb := _button(foot, "Reset to defaults", Rect2(), fs + 1, _reset_controls)
	rb.custom_minimum_size = Vector2(170, 38)
	rb.disabled = controls.is_default()
	var nav_last: Array = [[rb, _reset_controls]]
	_nav.append(nav_last)

func _start_capture(id: String, kind: String) -> void:
	_capture = {"id": id, "kind": kind}
	_say("")
	var keep := _sel
	_build()
	_sel = keep
	_paint_sel()

func _finish_capture(code: int) -> void:
	var c := _capture
	_capture = {}
	var err: String = controls.rebind(str(c.id), str(c.kind), code)
	_hint_sync()      # UI-OFFSCREEN: the walk hint names the menu key
	var keep := _sel
	var sv := _scroll.scroll_vertical if _scroll else 0
	_build()
	_sel = keep
	_paint_sel()
	if _scroll:
		_scroll.set_deferred("scroll_vertical", sv)
	_say(err)

func _reset_controls() -> void:
	controls.reset()
	_hint_sync()
	_build()
	_say("Back to the defaults.")

# ------------------------------------------------------------------ OWNER
## OWNER (design/godot-owner-mode.md): the owner's directory and tools (scripts/menu/owner_tab.gd).
const OwnerTab = preload("res://scripts/menu/owner_tab.gd")
var owner_tab: OwnerTab = null

func _build_owner(narrow: bool) -> void:
	if not is_owner():
		return
	if owner_tab == null:
		owner_tab = OwnerTab.new(self)
	owner_tab.build(narrow)

# ------------------------------------------------------------------ INVENTORY
func _build_inventory(narrow: bool) -> void:
	var col := _column()
	var m = _mall()
	var it = player.interact
	var fs := 14 if narrow else 16
	var tk := _label(col, "TICKETS  %d" % (int(m.tickets) if m else 0), fs + 4, GOLD)
	tk.custom_minimum_size.y = 34
	if m == null or it == null:
		return
	if not m.changed.is_connected(_inv_changed):
		m.changed.connect(_inv_changed)
	var ids: Array = []
	if m.hand != "":
		ids.append([m.hand, 1, true])
	for en in m.inventory:
		ids.append([str(en.id), int(en.count), false])
	if ids.is_empty():
		var l := _label(col, "Nothing yet. Things you can pick up show a prompt when you're close.", fs)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = _content.size.x - 20.0
		return
	var bw := 84.0 if narrow else 110.0
	for r in ids:
		var id: String = r[0]
		var held: bool = r[2]
		var e: Dictionary = it.db.get_item(id)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		row.custom_minimum_size.y = 52
		col.add_child(row)
		var ic := TextureRect.new()
		ic.custom_minimum_size = Vector2(46, 46)
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var icon := str(e.get("icon", ""))
		if icon != "" and ResourceLoader.exists(icon):
			ic.texture = load(icon)
		row.add_child(ic)
		var l := _label(row, str(e.get("name", id)) + ("  ×%d" % r[1] if int(r[1]) > 1 else ""), fs)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = 80
		var nav_row: Array = []
		# HELD / PUT AWAY: one at a time in the hand. A "pocket" item (data/items class) can't be held.
		var can_hold := str(e.get("class", "")) == "hand"
		var hold_cb := func():
			if not held and can_hold:
				m.hold(id); m.save()
		var away_cb := func():
			if held:
				it._put_away()
		var hb := _button(row, "HELD", Rect2(), fs - 1, hold_cb)
		hb.custom_minimum_size = Vector2(bw * 0.8, 40)
		hb.disabled = not can_hold
		_paint(hb, AMBER if held else Color(0.2, 0.16, 0.12), Color(0.1, 0.07, 0.04) if held else INK)
		var ab := _button(row, "PUT AWAY", Rect2(), fs - 1, away_cb)
		ab.custom_minimum_size = Vector2(bw, 40)
		_paint(ab, AMBER if not held else Color(0.2, 0.16, 0.12), Color(0.1, 0.07, 0.04) if not held else INK)
		var drop_cb := func(): it.drop(id)
		var db := _button(row, "Drop", Rect2(), fs - 1, drop_cb)
		db.custom_minimum_size = Vector2(bw * 0.62, 40)
		if can_hold:
			nav_row.append([hb, hold_cb])
		nav_row.append([ab, away_cb])
		nav_row.append([db, drop_cb])
		_nav.append(nav_row)

func _inv_changed() -> void:
	if is_open and (tab == "inventory" or (tab == "main" and not _typing)):
		(func():
			var keep := _sel
			_build()
			_sel = Vector2i(clampi(keep.x, 0, maxi(0, _nav.size() - 1)), keep.y)
			_paint_sel()).call_deferred()

# ------------------------------------------------------------------ selection (keys, pad)
func _paint_sel() -> void:
	for r in _nav.size():
		for c in _nav[r].size():
			var ctl: Control = _nav[r][c][0]
			if is_instance_valid(ctl):
				var on: bool = r == _sel.x and c == _sel.y and _input_kind != "touch"
				ctl.modulate = Color(1.25, 1.12, 0.8) if on else (Color(1.1, 1.06, 0.96) if ctl == _hover else Color(1, 1, 1))
	if _scroll and _sel.x < _nav.size() and not _nav[_sel.x].is_empty():
		var c: Control = _nav[_sel.x][mini(_sel.y, _nav[_sel.x].size() - 1)][0]
		if is_instance_valid(c) and _scroll.is_ancestor_of(c):
			_scroll.ensure_control_visible.call_deferred(c)

func _move_sel(dr: int, dc: int) -> void:
	if _nav.is_empty():
		return
	_sel.x = clampi(_sel.x + dr, 0, _nav.size() - 1)
	_sel.y = clampi(_sel.y + dc, 0, _nav[_sel.x].size() - 1)
	_paint_sel()

func _activate() -> void:
	if _sel.x < _nav.size() and not _nav[_sel.x].is_empty():
		var p: Array = _nav[_sel.x][clampi(_sel.y, 0, _nav[_sel.x].size() - 1)]
		if not (p[0] is BaseButton and p[0].disabled):
			(p[1] as Callable).call()

func _next_tab(d: int) -> void:
	var TB := tabs()
	open_tab(TB[posmod(TB.find(tab) + d, TB.size())])

# ------------------------------------------------------------------ input
func _catch(e: InputEvent) -> void:
	if e is InputEventJoypadButton or (e is InputEventJoypadMotion and absf(e.axis_value) > 0.4):
		_input_kind = "pad"
	elif e is InputEventKey or e is InputEventMouseButton:
		_input_kind = "kb"
	elif e is InputEventScreenTouch:
		_input_kind = "touch"
		if not touch_device:
			touch_device = true      # a touch screen after all: the icon, and the hint as it was
			_hint_sync()
			if _menu_btn:
				_icon_sync()
	if is_open:
		get_viewport().set_input_as_handled()
		_menu_input(e)
		return
	if player == null or player.vr_on:
		return
	if controls.filter(e):
		get_viewport().set_input_as_handled()
		return
	if _is(e, "menu") or _esc_opens(e):
		if _can_open():
			get_viewport().set_input_as_handled()
			open_tab("main")
		return
	if e is InputEventScreenTouch and e.pressed:
		if _menu_btn.is_visible_in_tree() and _menu_btn.get_global_rect().has_point(e.position):
			get_viewport().set_input_as_handled()
			open_tab("main")

## UI-OFFSCREEN: Esc opens the menu too (Steven, Nov 4), when nothing on the game screen uses it
## (the jump panel closes with Esc; the shops, prize counter, directory and talk freeze the player).
func _esc_opens(e: InputEvent) -> bool:
	if not (e is InputEventKey and e.pressed and not e.echo and e.keycode == KEY_ESCAPE):
		return false
	var jp = player.get("jump_panel")
	return not (jp != null and is_instance_valid(jp) and jp.visible)

func _is(e: InputEvent, id: String) -> bool:
	if not (e is InputEventKey or e is InputEventJoypadButton) or not e.is_pressed() or e.is_echo():
		return false
	return InputMap.has_action(Controls.PREFIX + id) and e.is_action_pressed(Controls.PREFIX + id, false, true)

func _menu_input(e: InputEvent) -> void:
	# waiting for the new key / button of a remap
	if not _capture.is_empty():
		if e is InputEventKey and e.pressed and not e.echo and str(_capture.kind) == "key":
			if e.keycode == KEY_ESCAPE:
				_capture = {}; _build(); _say("")
			else:
				_finish_capture(e.physical_keycode if e.physical_keycode != KEY_NONE else e.keycode)
			return
		if e is InputEventJoypadButton and e.pressed and str(_capture.kind) == "pad":
			_finish_capture(e.button_index)
			return
		if (e is InputEventMouseButton and e.pressed) or (e is InputEventScreenTouch and e.pressed) \
				or (e is InputEventKey and e.pressed and e.keycode == KEY_ESCAPE) \
				or (e is InputEventJoypadButton and e.pressed and e.button_index == JOY_BUTTON_B):
			_capture = {}; _build(); _say("")
		return
	# the triggers (LT / RT, L2 / R2) change tabs too, once per pull
	if e is InputEventJoypadMotion and (e.axis == JOY_AXIS_TRIGGER_LEFT or e.axis == JOY_AXIS_TRIGGER_RIGHT):
		if e.axis_value > 0.6 and not _trig.get(e.axis, false):
			_trig[e.axis] = true
			_next_tab(-1 if e.axis == JOY_AXIS_TRIGGER_LEFT else 1)
		elif e.axis_value < 0.3:
			_trig[e.axis] = false
		return
	# typing the name
	if _typing and e is InputEventKey:
		if e.pressed:
			_type_key(e)
		return
	if e is InputEventKey and e.pressed and not e.echo:
		if _is(e, "menu") or e.keycode == KEY_ESCAPE:
			close(); return
		if _is(e, "tab_prev"):
			_next_tab(-1); return
		if _is(e, "tab_next"):
			_next_tab(1); return
		match e.keycode:
			KEY_UP, KEY_W: _move_sel(-1, 0)
			KEY_DOWN, KEY_S: _move_sel(1, 0)
			KEY_LEFT, KEY_A: _move_sel(0, -1)
			KEY_RIGHT, KEY_D: _move_sel(0, 1)
			KEY_ENTER, KEY_KP_ENTER, KEY_SPACE: _activate()
		return
	if e is InputEventJoypadButton and e.pressed:
		if _is(e, "menu") or e.button_index == JOY_BUTTON_B:
			close(); return
		if _is(e, "tab_prev"):
			_next_tab(-1); return
		if _is(e, "tab_next"):
			_next_tab(1); return
		match e.button_index:
			JOY_BUTTON_DPAD_UP: _move_sel(-1, 0)
			JOY_BUTTON_DPAD_DOWN: _move_sel(1, 0)
			JOY_BUTTON_DPAD_LEFT: _move_sel(0, -1)
			JOY_BUTTON_DPAD_RIGHT: _move_sel(0, 1)
			JOY_BUTTON_A: _activate()
		return
	if e is InputEventMouseButton:
		if e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			_hit(e.position)
		elif e.pressed and _scroll and (e.button_index == MOUSE_BUTTON_WHEEL_UP or e.button_index == MOUSE_BUTTON_WHEEL_DOWN):
			_scroll.scroll_vertical += -48 if e.button_index == MOUSE_BUTTON_WHEEL_UP else 48
		return
	if e is InputEventMouseMotion:
		var h: Control = null
		for p in _hits:
			var c: Control = p[0]
			if is_instance_valid(c) and c.is_visible_in_tree() and c.get_global_rect().has_point(e.position):
				h = c
		if h != _hover:
			_hover = h
			_paint_sel()
		return
	if e is InputEventScreenTouch:
		_touch_input(e)
		return
	if e is InputEventScreenDrag:
		var t = _touch.get(e.index)
		if t == null:
			return
		var d: Vector2 = e.position - t.at
		if d.length() > 14.0:
			t.moved = true
		if _scroll and absf(d.y) > absf(d.x):
			_scroll.scroll_vertical = int(t.scroll - d.y)

func _touch_input(e: InputEventScreenTouch) -> void:
	if e.pressed:
		_touch[e.index] = {"at": e.position, "scroll": _scroll.scroll_vertical if _scroll else 0, "moved": false}
		return
	var t = _touch.get(e.index)
	_touch.erase(e.index)
	if t == null:
		return
	var d: Vector2 = e.position - t.at
	# a sideways swipe changes the tab (left: next, right: previous)
	if absf(d.x) > 70.0 and absf(d.x) > absf(d.y) * 1.5:
		_next_tab(1 if d.x < 0 else -1)
		return
	if not t.moved:
		_hit(e.position)

func _over_menu(p: Vector2) -> bool:
	for h in _hits:
		var c: Control = h[0]
		if is_instance_valid(c) and c.is_visible_in_tree() and c.get_global_rect().has_point(p):
			return true
	return false

## Click / tap one of the menu's own controls at p. True when one was hit.
func _hit(p: Vector2) -> bool:
	for i in range(_hits.size() - 1, -1, -1):
		var c: Control = _hits[i][0]
		if not is_instance_valid(c) or not c.is_visible_in_tree():
			continue
		if c is BaseButton and c.disabled:
			continue
		if _scroll and _scroll.is_ancestor_of(c) and not _scroll.get_global_rect().has_point(p):
			continue
		if c.get_global_rect().has_point(p):
			(_hits[i][1] as Callable).call()
			return true
	return false
