## OWNER (Steven, Nov 4 2026; design/godot-owner-mode.md): the menu's OWNER tab, shown only in owner
## mode (player.is_owner(): localStorage "southland-editor" = "1", ?owner=1 or the hallway code).
## Built by scripts/menu/menu.gd (_build_owner) into the menu's content area, with the menu's own
## buttons, hit list and key / pad rows, so it reads and works like every other tab.
##
## Two views, switched by the two keys at its top:
##   DIRECTORY: the mall directory's store list (the stores on the kiosk's sign, tex/dir/hotspots.json,
##     with each store's jump spot from gen/<wing>/directory.json; design/godot-directory.md), for either
##     year: the 1990s / 2026 keys pick whose stores are listed, "Travel to <year> here" switches the
##     year where you stand (player._switch_year(), the time-travel trip). Tapping a store asks "Jump to
##     this store?" (the kiosk's question, option B) and Yes jumps there (player.jump_to), into the
##     other wing or year when it is there. Visitors have none of this: they walk to a kiosk.
##   TOOLS: every owner tool in one place (the loose buttons they replace are tucked away by menu.gd):
##     the fps line, quick jump, the year, Edit / Publish signs, Arcade, Edit / Publish pictures,
##     Shirt words, the character editor, Reflections, Benches & plants, Lighting, the opening again.
extends RefCounted

const DIR_FALLBACK := "res://gen/w1/directory.json"
const HOTSPOTS := "res://tex/dir/hotspots.json"

var menu: Node
var view := "directory"          # "directory" or "tools"
var list_year := ""              # the year whose stores are listed ("1995" / "2026")
var ask: Dictionary = {}         # the stall the jump question is about, {} when none
var data: Dictionary = {}        # gen/<wing>/directory.json
var on_sign := {}                # year -> {unit id: true}, the stores on the kiosk's sign
## How a jump is made (tests swap it): jump_fn.call(wing, year, x, z, yaw_deg).
var jump_fn: Callable
## How the year is switched where you stand (tests swap it).
var year_fn: Callable

func _init(m: Node) -> void:
	menu = m
	var p = m.player
	jump_fn = func(w, y, x, z, yaw): p.jump_to(w, y, x, z, yaw)
	year_fn = func(): p._switch_year()

func _player():
	return menu.player

# ------------------------------------------------------------------ data
func load_data() -> void:
	if not data.is_empty():
		return
	var scn: Node = _player().get_parent()
	var gen: String = scn.get_meta("gen", "res://gen/") if scn else "res://gen/"
	var path := gen + "directory.json"
	if not FileAccess.file_exists(path):
		path = DIR_FALLBACK      # wings without a kiosk (outside, the cinema lobby): every wing's file lists the whole mall
	if FileAccess.file_exists(path):
		var j = JSON.parse_string(FileAccess.get_file_as_string(path))
		if j is Dictionary:
			data = j
	if FileAccess.file_exists(HOTSPOTS):
		var h = JSON.parse_string(FileAccess.get_file_as_string(HOTSPOTS))
		if h is Dictionary:
			for y in ["1995", "2026"]:
				var m := {}
				for e in h.get(y, []):
					m[str(e.id)] = true
				on_sign[y] = m

## The stores listed for year y, by name: [{id, name, num, jump: [wing, x, z, yaw]}].
func stores(y: String) -> Array:
	load_data()
	var out: Array = []
	var sign: Dictionary = on_sign.get(y, {})
	for st in data.get("years", {}).get(y, {}).get("stalls", []):
		if bool(st.get("vacant", false)):
			continue
		if not sign.is_empty() and not sign.has(str(st.id)):
			continue
		out.append(st)
	out.sort_custom(func(a, b): return String(a.name).naturalnocasecmp_to(String(b.name)) < 0)
	return out

func _year_now() -> String:
	return str(int(_player().year))

# ------------------------------------------------------------------ building
func build(narrow: bool) -> void:
	if list_year == "":
		list_year = _year_now()
	var col: VBoxContainer = menu._column()
	var fs := 14 if narrow else 16
	# the view switch
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 8)
	col.add_child(top)
	var row0: Array = []
	for v in [["directory", "DIRECTORY"], ["tools", "TOOLS"]]:
		var vv: String = v[0]
		var cb := func(): show_view(vv)
		var b: Button = menu._button(top, v[1], Rect2(), fs, cb)
		b.name = "Owner" + String(v[1]).capitalize()
		b.custom_minimum_size = Vector2(130, 40)
		menu._paint(b, menu.AMBER if view == vv else Color(0.2, 0.16, 0.12), Color(0.1, 0.07, 0.04) if view == vv else menu.INK)
		row0.append([b, cb])
	menu._nav.append(row0)
	if view == "tools":
		_build_tools(col, fs, narrow)
	else:
		_build_directory(col, fs, narrow)
	menu._note(col, fs)
	if not ask.is_empty():
		_build_ask(narrow)

func show_view(v: String) -> void:
	view = v
	ask = {}
	menu._sel = Vector2i.ZERO
	menu._build()

# ------------------------------------------------------------------ DIRECTORY
func _build_directory(col: VBoxContainer, fs: int, narrow: bool) -> void:
	var yr := HBoxContainer.new()
	yr.add_theme_constant_override("separation", 8)
	col.add_child(yr)
	var yl: Label = menu._label(yr, "STORES IN", fs - 2, Color(menu.GOLD, 0.85))
	yl.custom_minimum_size = Vector2(0 if narrow else 84, 38)
	var row: Array = []
	for y in [["1995", "1990s"], ["2026", "2026"]]:
		var yy: String = y[0]
		var cb := func(): set_list_year(yy)
		var b: Button = menu._button(yr, y[1], Rect2(), fs, cb)
		b.name = "OwnerYear" + yy
		b.custom_minimum_size = Vector2(84, 38)
		menu._paint(b, menu.AMBER if list_year == yy else Color(0.2, 0.16, 0.12), Color(0.1, 0.07, 0.04) if list_year == yy else menu.INK)
		row.append([b, cb])
	var other := "2026" if _year_now() == "1995" else "1995"
	var tcb := func(): travel()
	var tb: Button = menu._button(yr, "Travel to %s here" % ("the 1990s" if other == "1995" else "2026"), Rect2(), fs, tcb)
	tb.name = "OwnerTravel"
	tb.custom_minimum_size = Vector2(150, 38)
	tb.clip_text = false
	tb.disabled = _player().leaving
	menu._paint(tb, Color(0.2, 0.16, 0.12), menu.INK)
	if not tb.disabled:
		row.append([tb, tcb])
	menu._nav.append(row)
	var here: Label = menu._label(col, "You are in %s, wing %d. Tap a store to jump there." % [
		"the 1990s" if _year_now() == "1995" else "2026", int(_player().wing)], fs - 2, Color(menu.INK, 0.75))
	here.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	here.custom_minimum_size.x = menu._content.size.x - 20.0
	# the stores: one per row on a phone, two side by side on a wider screen
	var per := 1 if narrow else (3 if menu._content.size.x > 1100.0 else 2)
	var bw: float = (menu._content.size.x - 24.0 - 8.0 * (per - 1)) / per
	var hb: HBoxContainer = null
	var nav_row: Array = []
	var list := stores(list_year)
	for i in list.size():
		var st: Dictionary = list[i]
		if i % per == 0:
			hb = HBoxContainer.new()
			hb.add_theme_constant_override("separation", 8)
			col.add_child(hb)
			nav_row = []
			menu._nav.append(nav_row)
		var cb := func(): ask_jump(st)
		var b: Button = menu._button(hb, store_line(st, list_year), Rect2(), fs, cb)
		b.name = "OwnerStore_" + str(st.id)
		b.custom_minimum_size = Vector2(bw, 40)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		menu._paint(b, Color(0.2, 0.16, 0.12), menu.INK)
		nav_row.append([b, cb])
	if list.is_empty():
		menu._label(col, "No directory for %s in this build." % list_year, fs, Color(menu.INK, 0.75))

## "26  Lane Bryant · wing 1" (the 1990s carry the 1994 list's numbers, as on the sign).
func store_line(st: Dictionary, y: String) -> String:
	var nm := String(st.name)
	if y == "1995" and int(st.get("num", 0)) > 0:
		nm = "%d  %s" % [int(st.num), nm]
	return "%s  · wing %d" % [nm, int(st.jump[0])]

func set_list_year(y: String) -> void:
	list_year = y
	ask = {}
	var keep: Vector2i = menu._sel
	menu._build()
	menu._sel = Vector2i(1, keep.y) if keep.x == 1 else Vector2i(1, 0)
	menu._paint_sel()

## The kiosk's question (scripts/directory_ui.gd _ask): "Jump to this store?" with the store's name
## and, when it is elsewhere, which wing or year loads.
func ask_jump(st: Dictionary) -> void:
	ask = st
	menu._build()

func ask_note(st: Dictionary) -> String:
	var w := int(st.jump[0])
	var notes: Array = []
	if list_year != _year_now():
		notes.append("Travels to " + ("the 1990s" if list_year == "1995" else "2026"))
	if w != int(_player().wing):
		notes.append("Loads Wing %d" % w)
	return " · ".join(notes)

func _build_ask(narrow: bool) -> void:
	var vs: Vector2 = menu._root.get_viewport_rect().size
	# a blocker over the whole menu: a tap outside the question is No
	var block := ColorRect.new()
	block.color = Color(0, 0, 0, 0.5)
	block.position = Vector2.ZERO
	block.size = vs
	block.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu._root.add_child(block)
	menu._hits.append([block, answer.bind(false)])
	var w: float = minf(420.0, vs.x - 32.0)
	var h := 196.0
	var dlg := Panel.new()
	dlg.name = "OwnerAsk"
	var sb := StyleBoxFlat.new()
	sb.bg_color = menu.BG
	sb.border_color = menu.GOLD
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	dlg.add_theme_stylebox_override("panel", sb)
	dlg.position = Vector2((vs.x - w) * 0.5, vs.y * 0.5 - h * 0.5)
	dlg.size = Vector2(w, h)
	dlg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu._root.add_child(dlg)
	var lines := [["Jump to this store?", 20, menu.GOLD, 18], [store_line(ask, list_year).get_slice("  · ", 0), 18, menu.INK, 54], [ask_note(ask), 13, Color(menu.INK, 0.7), 84]]
	for ln in lines:
		var l := Label.new()
		l.text = ln[0]
		l.add_theme_font_size_override("font_size", ln[1])
		l.add_theme_color_override("font_color", ln[2])
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.position = Vector2(0, ln[3]); l.size = Vector2(w, 28)
		l.clip_text = true
		dlg.add_child(l)
	var bw := (w - 48.0) * 0.5
	var yes: Button = menu._button(dlg, "Yes", Rect2(16, h - 66, bw, 48), 18, answer.bind(true))
	yes.name = "OwnerAskYes"
	menu._paint(yes, menu.AMBER, Color(0.1, 0.07, 0.04))
	var no: Button = menu._button(dlg, "No", Rect2(32 + bw, h - 66, bw, 48), 18, answer.bind(false))
	no.name = "OwnerAskNo"
	menu._paint(no, Color(0.2, 0.16, 0.12), menu.INK)
	menu._nav = [[[yes, answer.bind(true)], [no, answer.bind(false)]]]
	menu._sel = Vector2i.ZERO

## Yes: the menu closes and the jump is made (player.jump_to: at once in this wing and year,
## otherwise that wing's / year's file loads there, with the time-travel trip across years).
func answer(yes: bool) -> void:
	var st := ask
	ask = {}
	if not yes or st.is_empty():
		menu._build()
		return
	var j: Array = st.jump
	print("owner directory jump: ", st.name, " (", list_year, ") -> wing ", j[0], " at ", j[1], ",", j[2], " yaw ", j[3])
	menu.close()
	jump_fn.call(int(j[0]), int(list_year), float(j[1]), float(j[2]), float(j[3]))

## The year where you stand (the owner's year switch).
func travel() -> void:
	if _player().leaving:
		return
	menu.close()
	year_fn.call()

# ------------------------------------------------------------------ TOOLS
## The tools that exist in this wing / year, each [label, state, [[button text, callable, enabled]...]].
func tools() -> Array:
	var p = _player()
	var scn: Node = p.get_parent()
	var out: Array = []
	out.append(["Owner HUD (fps line)", "on" if p.owner_hud_on else "off",
		[["Turn " + ("off" if p.owner_hud_on else "on"), _t_hud, true]]])
	out.append(["Quick jump (Sears, the entrance, Dillard's, JCPenney)", "",
		[["Open", menu.menu_jump, menu._jump_ok()]]])
	var other := 2026 if int(p.year) == 1995 else 1995
	out.append(["Year", "the 1990s" if int(p.year) == 1995 else "2026",
		[["Travel to %s here" % ("2026" if other == 2026 else "the 1990s"), travel, not p.leaving]]])
	var sg = scn.get_node_or_null("Signs") if scn else null
	if sg and sg.get("is_owner"):
		var n: int = sg.draft_count()
		out.append(["Signs (arcade titles, Kay-Bee boards)", "editing: tap a sign" if sg.editing else "",
			[["Edit signs: " + ("on" if sg.editing else "off"), _t_close_after.bind(sg.set_editing.bind(not sg.editing)), true],
			 ["Publish signs" + (" (%d)" % n if n > 0 else ""), _t_rebuild_after.bind(sg.publish), n > 0 and not sg.publishing]]])
		out.append(["Arcade (put an NES game on a PLAYABLE cabinet)", "on: tap a cabinet" if sg.arcade_mode else "",
			[["Arcade: " + ("on" if sg.arcade_mode else "off"), _t_close_after.bind(sg.set_arcade.bind(not sg.arcade_mode)), true]]])
	var pc = scn.get_node_or_null("Pictures") if scn else null
	if pc and pc.has_method("set_editing"):
		var n2: int = pc.draft_count()
		out.append(["Pictures on posters and ad panels (%d here)" % pc.slot_count(), "editing: tap a poster" if pc.editing else "",
			[["Edit pictures: " + ("on" if pc.editing else "off"), _t_close_after.bind(pc.set_editing.bind(not pc.editing)), true],
			 ["Publish pictures" + (" (%d)" % n2 if n2 > 0 else ""), _t_rebuild_after.bind(pc.publish), n2 > 0 and not pc.publishing]]])
	var sw = scn.get_node_or_null("ShirtWords") if scn else null
	if sw and sw.get("is_owner") and sw.has_method("_open_dialog"):
		out.append(["Shirt words (Ch02's sweatshirt)", "", [["Edit", _t_close_first.bind(sw._open_dialog), true]]])
	var co = p.get_node_or_null("CharOwner")
	if co and co.has_method("open"):
		var near: bool = not co.nearest().is_empty()
		out.append(["Character editor (K, by a shopper in a preset)", "a shopper is close" if near else "nobody close",
			[["Open", _t_close_first.bind(co.open), near]]])
	if p.buttons.size() > 2:
		out.append(["Reflections", "on" if p.buttons[0].button_pressed else "off",
			[["Turn " + ("off" if p.buttons[0].button_pressed else "on"), _t_toggle.bind(0), true]]])
		out.append(["Benches & plants", "on" if p.buttons[1].button_pressed else "off",
			[["Turn " + ("off" if p.buttons[1].button_pressed else "on"), _t_toggle.bind(1), true]]])
		if p._light_btn_ok:
			out.append(["Lighting", "night" if p.buttons[2].button_pressed else "day",
				[["Switch to " + ("day" if p.buttons[2].button_pressed else "night"), _t_toggle.bind(2), true]]])
	out.append(["The opening screen", "", [["Show it again", menu._owner_opening, true]]])
	return out

func _t_hud() -> void:
	_player().set_owner_hud(not _player().owner_hud_on)
	menu._build()

## player.gd's toggle i (0 Reflections, 1 Benches & plants, 2 Lighting), as a tap on it did.
func _t_toggle(i: int) -> void:
	var b: Button = _player().buttons[i]
	b.button_pressed = not b.button_pressed
	menu._build()

## A tool that works on the game screen: switch it, then close the menu so you can tap.
func _t_close_after(f: Callable) -> void:
	f.call()
	menu.close()

func _t_close_first(f: Callable) -> void:
	menu.close()
	f.call()

func _t_rebuild_after(f: Callable) -> void:
	f.call()
	menu._build()

func _build_tools(col: VBoxContainer, fs: int, narrow: bool) -> void:
	for t in tools():
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		row.custom_minimum_size.y = 44
		col.add_child(row)
		var l: Label = menu._label(row, String(t[0]) + ("" if String(t[1]) == "" else "  ·  " + String(t[1])), fs - (1 if narrow else 0))
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.custom_minimum_size.x = 120 if narrow else 260
		var nav_row: Array = []
		for bt in t[2]:
			var b: Button = menu._button(row, bt[0], Rect2(), fs - 1, bt[1])
			b.name = "OwnerTool_" + String(bt[0]).get_slice(":", 0).get_slice(" (", 0).capitalize().replace(" ", "")
			b.custom_minimum_size = Vector2(96 if narrow else 150, 40)
			b.clip_text = false
			b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if narrow else TextServer.AUTOWRAP_OFF
			b.disabled = not bool(bt[2])
			menu._paint(b, Color(0.2, 0.16, 0.12), menu.INK)
			if not b.disabled:
				nav_row.append([b, bt[1]])
		if not nav_row.is_empty():
			menu._nav.append(nav_row)
