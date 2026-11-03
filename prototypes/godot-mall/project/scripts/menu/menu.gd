## Workstream M (design/godot-menu.md): the full-screen menu. Made by scripts/player.gd as its child
## "Menu" (every wing, both years), after Avatar.
##
## Tabs, left to right: INVENTORY (below), AVATAR (the creator, scripts/avatar_creator.gd, inside the tab, and the NAME
## field: mall.player_name), CONTROLS (every action with its keyboard key, gamepad button and touch
## control, read from the InputMap; click a key or button to remap it: scripts/menu/controls.gd),
## INVENTORY (the TICKETS count and the carried items with HELD / PUT AWAY and Drop) and YEAR (1995 /
## 2026; a change plays the time-travel transition, player.gd _time_travel).
##
## Open / close: Tab (remappable), a gamepad's Start, the Menu button; Esc and B close too. Tabs: Q / E,
## LB / RB, a swipe, or a tap on the tab. The old ways in still work and open their tab: I and the Bag
## button (INVENTORY), C and the Avatar button (AVATAR), Y and the year button (YEAR). The player is
## frozen while it is open. Not in VR (a flat overlay isn't seen in the headset).
##
## Input: one catcher node sits last under the root, so it sees every event before anything else;
## while the menu (or the opening) is open it takes them all and taps / clicks its own buttons by hand
## (the project turns touch-to-mouse emulation off); while closed it lets the controls' translation
## layer re-send remapped keys (controls.gd filter()).
##
## The opening (scripts/menu/opening.gd, words from data/story/opening.json) shows on a first start.
extends Node

const Controls = preload("res://scripts/menu/controls.gd")
const Opening = preload("res://scripts/menu/opening.gd")
const CREATOR := "res://scripts/avatar_creator.tscn"
const OPENING_KEY := "mall-opening-1"     # localStorage: "skipped" once the opening was skipped
## Steven, Nov 2: INVENTORY first (far left, and what the menu opens on), then the avatar builder.
const TABS := ["inventory", "avatar", "controls", "year"]
const TAB_NAMES := {"avatar": "AVATAR", "controls": "CONTROLS", "inventory": "INVENTORY", "year": "YEAR"}
const YEARS := [1995, 2026]
const BG := Color(0.07, 0.055, 0.045, 0.97)
const INK := Color(1, 0.97, 0.9)
const GOLD := Color(0.93, 0.85, 0.66)
const AMBER := Color(0.85, 0.62, 0.22)

var player: Node3D
var controls: Controls
var is_open := false
var tab := "inventory"
var opening: CanvasLayer = null

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
var _creator: Node = null
var _name_lbl: Label = null
var _name_box: PanelContainer = null
var _typing := false
var _caret_t := 0.0
var _touch := {}                 # touch index -> {"at": Vector2, "scroll": int, "moved": bool, "creator": bool}
var _menu_btn: Button
var _built_for := Vector2.ZERO
var _input_kind := "kb"

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
	# now, before avatar.gd's deferred first-visit creator asks (request_creator waits for START)
	_maybe_opening()

func _mall():
	return player.mall if player and "mall" in player else null

# ------------------------------------------------------------------ open / close
## Open the menu on tab t (one of TABS), or switch to it when open.
func open_tab(t: String) -> void:
	if not (t in TABS):
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
	_sel = Vector2i(1, 0) if t == "avatar" else Vector2i.ZERO   # AVATAR: the creator's rows (0 = NAME)
	_build()

## The avatar's "open the creator" (avatar.gd open_creator: C, the Avatar button, a first visit).
func request_creator() -> void:
	if opening != null:
		return       # the opening's START opens the AVATAR tab
	open_tab("avatar")

func close() -> void:
	if not is_open:
		return
	_stop_typing(true)
	_capture = {}
	if _creator != null and is_instance_valid(_creator):
		_creator._done()      # closing keeps what was made (the creator's Done)
	_drop_creator()
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
func _build_menu_button() -> void:
	_menu_btn = Button.new()
	_menu_btn.text = "Menu (%s)" % _first_key("menu", "Tab")
	_menu_btn.focus_mode = Control.FOCUS_NONE
	_menu_btn.add_theme_font_size_override("font_size", 14)
	_menu_btn.position = Vector2(10, 8)
	_menu_btn.size = Vector2(110, 32)
	_menu_btn.pressed.connect(func(): open_tab("inventory"))
	player._cl.add_child(_menu_btn)

func _process(dt: float) -> void:
	# entering VR: the flat menu and opening can't be seen in the headset, so they close (the opening
	# comes back next time, as it wasn't skipped)
	if player and player.vr_on:
		if opening != null:
			_opening_done("later")
		if is_open:
			close()
	if _menu_btn:
		_menu_btn.visible = not is_open and opening == null and not player.vr_on and not (player.frozen and not _froze)
		# the owner's fps readout is top left: go under it
		_menu_btn.position.y = 34.0 if (player.hud and player.hud.visible) else 8.0
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
	# the background: the whole screen except the creator's own area (it draws its own)
	var bg := ColorRect.new()
	bg.color = BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(bg)
	# the tab bar
	var close_w := 44.0
	var tw := (vs.x - pad * 2 - close_w - 6.0 * TABS.size()) / TABS.size()
	var fs_tab := int(clampf(tw / 7.2, 11, 17))
	for i in TABS.size():
		var t: String = TABS[i]
		var b := _button(_root, TAB_NAMES[t], Rect2(pad + i * (tw + 6.0), pad * 0.5, tw, bar_h), fs_tab, func(): open_tab(t))
		_paint(b, AMBER if t == tab else Color(0.2, 0.16, 0.12), Color(0.1, 0.07, 0.04) if t == tab else INK)
	var cb := _button(_root, "×", Rect2(vs.x - pad - close_w, pad * 0.5, close_w, bar_h), 18, close)
	cb.tooltip_text = "Close"
	var foot_h := 0.0 if _input_kind == "touch" else 22.0
	_content = Rect2(pad, pad * 0.5 + bar_h + pad, vs.x - pad * 2, vs.y - (pad * 0.5 + bar_h + pad) - pad - foot_h)
	if foot_h > 0.0:
		var foot := Label.new()
		foot.text = "%s / %s or LB / RB: tabs  ·  arrows + Enter or d-pad + A: choose  ·  %s, Esc or B: close" % [
			_first_key("tab_prev", "Q"), _first_key("tab_next", "E"), _first_key("menu", "Tab")]
		foot.position = Vector2(pad, vs.y - pad - foot_h)
		foot.size = Vector2(vs.x - pad * 2, foot_h)
		foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		foot.clip_text = true
		foot.add_theme_font_size_override("font_size", 12)
		foot.add_theme_color_override("font_color", Color(GOLD, 0.8))
		_root.add_child(foot)
	match tab:
		"avatar": _build_avatar(narrow)
		"controls": _build_controls(narrow)
		"inventory": _build_inventory(narrow)
		"year": _build_year(narrow)
	if tab != "avatar" and _creator != null:
		_creator.visible = false
	if tab != "avatar":
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

# ------------------------------------------------------------------ AVATAR
func _build_avatar(narrow: bool) -> void:
	var name_h := 44.0
	var row := HBoxContainer.new()
	row.position = _content.position
	row.size = Vector2(_content.size.x, name_h)
	row.add_theme_constant_override("separation", 10)
	_root.add_child(row)
	var nl := _label(row, "NAME", 16, GOLD)
	nl.custom_minimum_size = Vector2(60, name_h)
	_name_box = PanelContainer.new()
	_name_box.custom_minimum_size = Vector2(minf(_content.size.x - 80.0, 360.0), name_h - 4.0)
	_name_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_name_box)
	_name_lbl = Label.new()
	_name_lbl.add_theme_font_size_override("font_size", 18)
	_name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_name_lbl.clip_text = true
	_name_box.add_child(_name_lbl)
	_hits.append([_name_box, _name_tapped])
	_nav.append([[_name_box, _name_tapped]])
	_name_text()
	# the creator below, in its own layer, inside the frame we give it
	var fr := Rect2(_content.position + Vector2(0, name_h + 6.0), _content.size - Vector2(0, name_h + 6.0))
	if _creator == null or not is_instance_valid(_creator):
		_make_creator()
	if _creator:
		_creator.visible = true
		_creator.frame = fr
		_creator._built_for = Vector2.ZERO
		_creator._layout()

func _make_creator() -> void:
	var av = player.avatar
	if av == null:
		return
	# B2 (design/godot-character-editor.md): the character editor in its player mode replaces V's
	# creator here when the pack ships the B1 bodies (same contract: frame, embedded, feed, sel, closed)
	if AvatarChar.available():
		_creator = load("res://scripts/chars/char_editor.gd").new()
		_creator.setup("player", AvatarChar.preset_for(av.look, player.year))
	else:
		var ps: PackedScene = load(CREATOR)
		_creator = ps.instantiate()
	_creator.year = player.year
	_creator.look = av.look.duplicate(true)
	_creator.first_time = not bool(av.look.get("done", false))
	_creator.embedded = true
	_creator.closed.connect(_creator_closed)
	# avatar.gd owns what happens to the look (save, wear, first-time third person)
	av.creator = _creator
	add_child(_creator)
	_creator.layer = 46     # over the menu (45), after its _ready (which sets 40); it covers only its frame

func _creator_closed(look: Dictionary, how: String) -> void:
	var av = player.avatar
	var c := _creator
	_creator = null
	if av and av.creator == c:
		av._creator_closed(look, how)      # saves and wears it; frees the creator
	elif c and is_instance_valid(c):
		c.queue_free()
	if is_open and tab == "avatar":
		close()

func _drop_creator() -> void:
	if _creator != null and is_instance_valid(_creator):
		var av = player.avatar
		if av and av.creator == _creator:
			av.creator = null
		_creator.queue_free()
	_creator = null

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
	# a phone: the browser's own text box, so its keyboard comes up (as the creator's "Type")
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
	# the owner's setting: the opening screen again (design/godot-menu.md)
	if player.has_method("is_owner") and player.is_owner():
		var ob := _button(foot, "Show the opening again", Rect2(), fs + 1, _owner_opening)
		ob.custom_minimum_size = Vector2(200, 38)
		nav_last.append([ob, _owner_opening])
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
	_menu_btn.text = "Menu (%s)" % _first_key("menu", "Tab")
	_build()
	_say("Back to the defaults.")

func _owner_opening() -> void:
	_store_set(OPENING_KEY, "")
	close()
	show_opening()

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
	if is_open and tab == "inventory":
		(func():
			var keep := _sel
			_build()
			_sel = Vector2i(clampi(keep.x, 0, maxi(0, _nav.size() - 1)), keep.y)
			_paint_sel()).call_deferred()

# ------------------------------------------------------------------ YEAR
func _build_year(narrow: bool) -> void:
	var col := VBoxContainer.new()
	col.position = _content.position
	col.size = _content.size
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 18)
	_root.add_child(col)
	var big := _label(col, str(player.year), 64 if not narrow else 48, GOLD)
	big.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	col.add_child(row)
	var nav_row: Array = []
	for y in YEARS:
		var yy: int = y
		var cb := func(): _go_year(yy)
		var b := _button(row, str(y), Rect2(), 26, cb)
		b.custom_minimum_size = Vector2(150 if not narrow else 130, 64)
		_paint(b, AMBER if y == player.year else Color(0.2, 0.16, 0.12), Color(0.1, 0.07, 0.04) if y == player.year else INK)
		nav_row.append([b, cb])
	_nav.append(nav_row)
	_sel = Vector2i(0, 1 if player.year == 1995 else 0)

func _go_year(y: int) -> void:
	if y == player.year:
		return
	close()
	player._switch_year()

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
	open_tab(TABS[posmod(TABS.find(tab) + d, TABS.size())])

# ------------------------------------------------------------------ input
func _catch(e: InputEvent) -> void:
	if e is InputEventJoypadButton or (e is InputEventJoypadMotion and absf(e.axis_value) > 0.4):
		_input_kind = "pad"
	elif e is InputEventKey or e is InputEventMouseButton:
		_input_kind = "kb"
	elif e is InputEventScreenTouch:
		_input_kind = "touch"
	if opening != null:
		get_viewport().set_input_as_handled()
		opening.handle(e)
		return
	if is_open:
		get_viewport().set_input_as_handled()
		_menu_input(e)
		return
	if player == null or player.vr_on:
		return
	if controls.filter(e):
		get_viewport().set_input_as_handled()
		return
	if _is(e, "menu"):
		if _can_open():
			get_viewport().set_input_as_handled()
			open_tab("inventory")
		return
	if e is InputEventScreenTouch and e.pressed:
		if _menu_btn.is_visible_in_tree() and _menu_btn.get_global_rect().has_point(e.position):
			get_viewport().set_input_as_handled()
			open_tab("inventory")
		elif player.year_btn and player.year_btn.is_visible_in_tree() and player.year_btn.get_global_rect().has_point(e.position) and _can_open():
			get_viewport().set_input_as_handled()
			open_tab("year")

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
		if tab == "avatar" and _creator and _sel.x != 0:
			if e.keycode == KEY_UP and _creator.sel == 0:
				_sel.x = 0; _paint_sel(); return
			_creator.feed(e)
			return
		if tab == "avatar" and e.keycode == KEY_DOWN and _creator:
			_sel.x = 1; _paint_sel(); return
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
		if tab == "avatar" and _creator and _sel.x != 0:
			if e.button_index == JOY_BUTTON_DPAD_UP and _creator.sel == 0:
				_sel.x = 0; _paint_sel(); return
			_creator.feed(e)
			return
		if tab == "avatar" and e.button_index == JOY_BUTTON_DPAD_DOWN and _creator:
			_sel.x = 1; _paint_sel(); return
		match e.button_index:
			JOY_BUTTON_DPAD_UP: _move_sel(-1, 0)
			JOY_BUTTON_DPAD_DOWN: _move_sel(1, 0)
			JOY_BUTTON_DPAD_LEFT: _move_sel(0, -1)
			JOY_BUTTON_DPAD_RIGHT: _move_sel(0, 1)
			JOY_BUTTON_A: _activate()
		return
	if e is InputEventMouseButton:
		if e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			if _hit(e.position):
				return
			if _creator_has(e.position):
				_creator_click(e)
		elif not e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			if _creator:
				_creator.feed(e)
		elif e.pressed and tab == "avatar" and _creator and (e.button_index == MOUSE_BUTTON_WHEEL_UP or e.button_index == MOUSE_BUTTON_WHEEL_DOWN):
			_creator.feed(e)      # B2: the editor's zoom / list scroll
		elif e.pressed and _scroll and (e.button_index == MOUSE_BUTTON_WHEEL_UP or e.button_index == MOUSE_BUTTON_WHEEL_DOWN):
			_scroll.scroll_vertical += -48 if e.button_index == MOUSE_BUTTON_WHEEL_UP else 48
		return
	if e is InputEventMouseMotion:
		if _creator and tab == "avatar":
			_creator.feed(e)
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
		if t.creator:
			_creator.feed(e)
			return
		var d: Vector2 = e.position - t.at
		if d.length() > 14.0:
			t.moved = true
		if _scroll and absf(d.y) > absf(d.x):
			_scroll.scroll_vertical = int(t.scroll - d.y)

func _touch_input(e: InputEventScreenTouch) -> void:
	if e.pressed:
		var in_creator := tab == "avatar" and _creator != null and _creator_has(e.position) and not _over_menu(e.position)
		_touch[e.index] = {"at": e.position, "scroll": _scroll.scroll_vertical if _scroll else 0, "moved": false, "creator": in_creator}
		if in_creator:
			_creator.feed(e)
		return
	var t = _touch.get(e.index)
	_touch.erase(e.index)
	if t == null:
		return
	if t.creator:
		_creator.feed(e)
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

func _creator_has(p: Vector2) -> bool:
	return _creator != null and is_instance_valid(_creator) and _creator.visible and _creator.root and _creator.root.get_global_rect().has_point(p)

## A mouse click in the creator: its buttons (it lists them for touches), else the preview drag.
func _creator_click(e: InputEventMouseButton) -> void:
	for i in range(_creator.hits.size() - 1, -1, -1):
		var c: Control = _creator.hits[i][0]
		if is_instance_valid(c) and c.is_visible_in_tree() and not (c is BaseButton and c.disabled) and c.get_global_rect().has_point(e.position):
			(_creator.hits[i][1] as Callable).call()
			return
	_creator.feed(e)

# ------------------------------------------------------------------ the opening
func _maybe_opening() -> void:
	if player == null or player.vr_on:
		return
	var force := false
	var cam_q := false
	if OS.has_feature("web"):
		force = str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('opening') || ''")) == "1"
		cam_q = str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('cam') || ''")) != ""
	else:
		force = bool(Engine.get_meta("menu_opening", false))   # tests: once
		Engine.remove_meta("menu_opening") if Engine.has_meta("menu_opening") else null
		cam_q = true        # editor and tests: only when asked for
	var m = _mall()
	var named: bool = m != null and m.player_name != ""
	if force or (not cam_q and not named and _store_get(OPENING_KEY) != "skipped"):
		show_opening()

func show_opening() -> void:
	if opening != null:
		return
	if is_open:
		close()
	opening = Opening.new()
	opening.done.connect(_opening_done)
	add_child(opening)
	if not player.frozen:
		player.frozen = true
		_froze = true

func _opening_done(how: String) -> void:
	opening.queue_free()
	opening = null
	if _froze:
		player.frozen = false
		_froze = false
	if how == "skip":
		_store_set(OPENING_KEY, "skipped")
		return
	if how != "start":
		return
	# START: the creator, on the AVATAR tab, with the NAME field focused
	open_tab("avatar")
	_sel = Vector2i.ZERO
	_paint_sel()
	if _input_kind != "touch":
		start_typing()
	else:
		_name_text()
		if _name_box:
			var sb := _name_box.get_theme_stylebox("panel") as StyleBoxFlat
			if sb:
				sb.border_color = AMBER

# ------------------------------------------------------------------ storage
func _store_get(k: String) -> String:
	if OS.has_feature("web"):
		var v = JavaScriptBridge.eval("(function(){try{return localStorage.getItem(%s)||''}catch(e){return ''}})()" % JSON.stringify(k), true)
		return v if v is String else ""
	return str(Engine.get_meta("menu_" + k.replace("-", "_"), ""))

func _store_set(k: String, v: String) -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("(function(){try{if(%s)localStorage.setItem(%s,%s);else localStorage.removeItem(%s)}catch(e){}})()" % ["true" if v != "" else "false", JSON.stringify(k), JSON.stringify(v), JSON.stringify(k)], true)
	else:
		Engine.set_meta("menu_" + k.replace("-", "_"), v)
