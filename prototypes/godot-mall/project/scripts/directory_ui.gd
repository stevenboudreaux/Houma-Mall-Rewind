## The mall directory's map (design/godot-directory.md). Opened from a directory kiosk
## (scripts/directory_kiosk.gd). Shows every stall of the year on show, drawn from GEN/directory.json
## (written by the wing build from the layout files, tools/stores/directory/map_data.gd), so it is
## always the map the wing was built from. A toggle at the top switches the map between 1995 and
## 2026; each year looks like its own real directory (2026: the cyan "Welcome!" panel, stores by
## category in colour; 1995: the mall's March 1994 Merchant List & Map, numbered stores, the
## SOUTHLAND MALL fan logo, special locations A-G).
##
## Controls: arrow keys / d-pad / left stick move from stall to stall; Enter / A asks "Jump to this
## store?" and jumps (player.jump_to, across wings and years); Esc / B closes; Tab, Y, LB / RB or
## the toggle switch years; +/- , the mouse wheel or a pinch zoom; dragging pans; typing a store's
## first letters finds it. Touch: tap a stall, tap Jump, drag to pan, pinch or +/- to zoom.
extends CanvasLayer

const LAYER := 25
const BG_DIM := Color(0, 0, 0, 0.55)

var data := {}                 # {"years": {"1995": {...}, "2026": {...}}}
var player: Node = null
var kiosk: Node = null
var is_open := false
var map_year := "2026"
var sel := -1                  # index into stalls of map_year
var confirm := false
var confirm_yes := true
var zoom := 1.0
var pan := Vector2.ZERO        # world (x, z) at the map's centre
var list_scroll := 0.0
var typed := ""
var typed_t := 0.0

var root: Control
var back: Control              # the dimmed game and the card's aluminium frame, under the map
var map_c: Control
var list_c: Control
var chrome: Control
var f_sans: Font
var f_serif: Font

# pointer state (mouse and touch share it)
var touches := {}              # index -> position
var drag_from := Vector2.ZERO
var drag_moved := false
var drag_target := ""          # "map", "list" or ""
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
	f_serif = load("res://fonts/serif.ttf")
	var scn := get_parent()
	var gen: String = scn.get_meta("gen", "res://gen/") if scn else "res://gen/"
	if FileAccess.file_exists(gen + "directory.json"):
		data = JSON.parse_string(FileAccess.get_file_as_string(gen + "directory.json"))
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	map_c = Control.new()
	map_c.clip_contents = true
	map_c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map_c.draw.connect(_draw_map)
	list_c = Control.new()
	list_c.clip_contents = true
	list_c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	list_c.draw.connect(_draw_list)
	back = Control.new()
	back.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	back.draw.connect(_draw_back)
	chrome = Control.new()
	chrome.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	chrome.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chrome.draw.connect(_draw_chrome)
	root.add_child(back)
	root.add_child(map_c)
	root.add_child(list_c)
	root.add_child(chrome)
	get_viewport().size_changed.connect(_relayout)
	_relayout()

# ------------------------------------------------------------------ open / close
func open(p: Node, k: Node) -> void:
	if data.is_empty() or is_open:
		return
	player = p
	kiosk = k
	is_open = true
	confirm = false
	map_year = str(p.get("year")) if p and p.get("year") != null else "1995"
	if not data.years.has(map_year):
		map_year = "1995"
	if p:
		p.set("frozen", true)
	_relayout()
	_fit()
	sel = _nearest_stall(Vector2(k.position.x, k.position.z)) if k else 0
	if narrow and k:
		# a phone: start close in, on You are here
		zoom = 2.2
		pan = Vector2(k.position.x, k.position.z)
		_clamp_pan()
	_redraw()

func close() -> void:
	is_open = false
	confirm = false
	if player:
		player.set("frozen", false)
	_redraw()

func _year() -> Dictionary:
	return data.years.get(map_year, {})

func _stalls() -> Array:
	return _year().get("stalls", [])

func _selectable(i: int) -> bool:
	var s: Array = _stalls()
	return i >= 0 and i < s.size() and not s[i].vacant

# ------------------------------------------------------------------ layout
var r_card := Rect2()
var r_head := Rect2()
var r_foot := Rect2()
var r_list := Rect2()
var r_map := Rect2()
var r_close := Rect2()
var r_y95 := Rect2()
var r_y26 := Rect2()
var r_jump := Rect2()
var r_zin := Rect2()
var r_zout := Rect2()
var r_yes := Rect2()
var r_no := Rect2()
var narrow := false

func _relayout() -> void:
	if root == null:
		return
	var vp := get_viewport().get_visible_rect().size
	narrow = vp.x < 760.0
	var m := 8.0 if narrow else 36.0
	r_card = Rect2(m, m, vp.x - 2 * m, vp.y - 2 * m)
	var hh := 58.0 if narrow else 72.0
	var fh := 64.0
	r_head = Rect2(r_card.position, Vector2(r_card.size.x, hh))
	r_foot = Rect2(r_card.position.x, r_card.end.y - fh, r_card.size.x, fh)
	var body := Rect2(r_card.position.x, r_head.end.y, r_card.size.x, r_foot.position.y - r_head.end.y)
	if narrow:
		r_list = Rect2()
		r_map = body
	else:
		var lw: float = clamp(body.size.x * 0.27, 230.0, 320.0)
		r_list = Rect2(body.position, Vector2(lw, body.size.y))
		r_map = Rect2(body.position.x + lw, body.position.y, body.size.x - lw, body.size.y)
	var cb := 44.0
	r_close = Rect2(r_head.end.x - cb - 8, r_head.position.y + (hh - cb) * 0.5, cb, cb)
	var tw := 62.0
	var th := 34.0
	var tx := r_close.position.x - 12 - tw * 2
	r_y95 = Rect2(tx, r_head.position.y + (hh - th) * 0.5, tw, th)
	r_y26 = Rect2(tx + tw, r_y95.position.y, tw, th)
	r_jump = Rect2(r_foot.end.x - 150, r_foot.position.y + 10, 140, fh - 20)
	r_zin = Rect2(r_map.end.x - 54, r_map.end.y - 104, 44, 44)
	r_zout = Rect2(r_map.end.x - 54, r_map.end.y - 54, 44, 44)
	var dw: float = min(420.0, vp.x - 24)
	var dlg := Rect2((vp.x - dw) * 0.5, vp.y * 0.5 - 90, dw, 180)
	r_yes = Rect2(dlg.position.x + 16, dlg.end.y - 60, dw * 0.5 - 24, 46)
	r_no = Rect2(dlg.position.x + dw * 0.5 + 8, dlg.end.y - 60, dw * 0.5 - 24, 46)
	map_c.position = r_map.position
	map_c.size = r_map.size
	list_c.position = r_list.position
	list_c.size = r_list.size
	_redraw()

func _redraw() -> void:
	if root == null:
		return
	map_c.visible = is_open
	list_c.visible = is_open and not narrow
	back.queue_redraw()
	map_c.queue_redraw()
	list_c.queue_redraw()
	chrome.queue_redraw()

# ------------------------------------------------------------------ map transform
func _fit_scale() -> float:
	var b: Array = _year().get("bounds", [-160, -140, 40, 100])
	return min((r_map.size.x - 24) / (b[2] - b[0]), (r_map.size.y - 24) / (b[3] - b[1]))

func _fit() -> void:
	var b: Array = _year().get("bounds", [-160, -140, 40, 100])
	pan = Vector2((b[0] + b[2]) * 0.5, (b[1] + b[3]) * 0.5)
	zoom = 1.0

func _w2s(x: float, z: float) -> Vector2:
	var s := _fit_scale() * zoom
	return r_map.size * 0.5 + (Vector2(x, z) - pan) * s

func _s2w(p: Vector2) -> Vector2:
	var s := _fit_scale() * zoom
	return pan + (p - r_map.size * 0.5) / s

func _zoom_by(f: float, about := Vector2(-1, -1)) -> void:
	if about.x < 0:
		about = r_map.size * 0.5
	var wpt := _s2w(about)
	zoom = clamp(zoom * f, 1.0, 9.0)
	var s := _fit_scale() * zoom
	pan = wpt - (about - r_map.size * 0.5) / s
	_clamp_pan()
	_redraw()

func _clamp_pan() -> void:
	var b: Array = _year().get("bounds", [-160, -140, 40, 100])
	pan.x = clamp(pan.x, b[0], b[2])
	pan.y = clamp(pan.y, b[1], b[3])

## Keep the selected stall on screen.
func _show_sel() -> void:
	if sel < 0:
		return
	var lp: Array = _stalls()[sel].label
	var p := _w2s(lp[0], lp[1])
	var pad := 50.0
	if p.x < pad or p.y < pad or p.x > r_map.size.x - pad or p.y > r_map.size.y - pad:
		pan = Vector2(lp[0], lp[1])
		_clamp_pan()

# ------------------------------------------------------------------ look of each year
func _col(h: String) -> Color:
	return Color(h)

func _theme() -> Dictionary:
	if map_year == "2026":
		return {"head": Color("#2fb3dc"), "head2": Color("#1d9cc8"), "stripe": Color("#1d9cc8"), "body": Color("#f4f7f9"),
			"hall": Color("#c9ccd1"), "edge": Color("#ffffff"), "anchor": Color("#232325"), "vacant": Color("#e4e7ea"),
			"text": Color("#262626"), "title": "MALL DIRECTORY", "sub": "Welcome!", "accent": Color("#1d9cc8"), "font": f_sans}
	return {"head": Color("#1f5c66"), "head2": Color("#1f5c66"), "stripe": Color("#b0607e"), "body": Color("#f5f1e6"),
		"hall": Color("#e2dccd"), "edge": Color("#3b3a36"), "anchor": Color("#6b6f7a"), "vacant": Color("#f6f2e8"),
		"text": Color("#2b2b2b"), "title": "Merchant List & Map", "sub": "SOUTHLAND MALL", "accent": Color("#1f5c66"), "font": f_serif}

func _cat_color(st: Dictionary) -> Color:
	var th := _theme()
	if st.vacant:
		return th.vacant
	var c0: String = st.cats[0]
	if c0 == "dept":
		return th.anchor
	for c in _year().get("cats", []):
		if c[0] == c0:
			return Color(c[2])
	return Color("#999999")

func _cat_title(id: String) -> String:
	for c in _year().get("cats", []):
		if c[0] == id:
			return c[1]
	return ""

# ------------------------------------------------------------------ drawing
func _draw_map() -> void:
	if not is_open:
		return
	var th := _theme()
	var c := map_c
	c.draw_rect(Rect2(Vector2.ZERO, r_map.size), th.body)
	var s := _fit_scale() * zoom
	for h in _year().get("halls", []):
		var a := _w2s(h[0], h[1])
		c.draw_rect(Rect2(a, Vector2(h[2] - h[0], h[3] - h[1]) * s), th.hall)
	var stalls := _stalls()
	for i in stalls.size():
		var st: Dictionary = stalls[i]
		var col := _cat_color(st)
		for r in st.rects:
			c.draw_rect(Rect2(_w2s(r[0], r[1]), Vector2(r[2] - r[0], r[3] - r[1]) * s), col)
		for r in st.rects:
			c.draw_rect(Rect2(_w2s(r[0], r[1]), Vector2(r[2] - r[0], r[3] - r[1]) * s), th.edge, false, 1.0)
	# the selection: a bright outline and a soft wash
	if sel >= 0 and sel < stalls.size():
		for r in stalls[sel].rects:
			var rr := Rect2(_w2s(r[0], r[1]), Vector2(r[2] - r[0], r[3] - r[1]) * s)
			c.draw_rect(rr, Color(1, 1, 1, 0.35))
			c.draw_rect(rr.grow(1.5), Color("#ff3b6b"), false, 3.0)
	# labels: anchors always; numbers (1995) or names when there is room
	for i in stalls.size():
		var st: Dictionary = stalls[i]
		if st.vacant:
			continue
		var lp := _w2s(st.label[0], st.label[1])
		var big := _biggest(st)
		var bw: float = (big[2] - big[0]) * s
		var bh: float = (big[3] - big[1]) * s
		var anchor: bool = st.cats[0] == "dept"
		var txt: String = st.name
		var fs := 15 if anchor else 11
		var tw: float = th.font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var light := _cat_color(st).get_luminance() < 0.55
		var tc := Color.WHITE if light else Color("#1a1a1a")
		if tw < bw - 4 and fs + 2 < bh:
			_text_c(c, th.font, txt, lp, fs, tc)
		elif map_year == "1995" and int(st.num) > 0 and bw > 13 and bh > 11:
			_text_c(c, f_sans, str(int(st.num)), lp, 10 if bw < 22 else 12, tc, true)
		elif anchor and bh > tw + 4:
			# a tall, narrow anchor (Dillard's): its name on its side
			c.draw_set_transform(lp, -PI * 0.5, Vector2.ONE)
			_text_c(c, th.font, txt, Vector2.ZERO, fs, tc)
			c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# 1995: the special locations A-G
	for p in _year().get("places", []):
		var pp := _w2s(p[2], p[3])
		c.draw_circle(pp, 9, Color("#1f5c66"))
		c.draw_arc(pp, 9, 0, TAU, 20, Color.WHITE, 1.5)
		_text_c(c, f_sans, p[0], pp, 11, Color.WHITE)
	# You are here (on this year's map)
	if kiosk and player and str(player.get("year")) == map_year:
		var kp := _w2s(kiosk.position.x, kiosk.position.z)
		var t := Time.get_ticks_msec() / 1000.0
		var pulse := 10.0 + 6.0 * (0.5 + 0.5 * sin(t * 4.0))
		c.draw_circle(kp, pulse, Color(0.9, 0.1, 0.2, 0.25))
		c.draw_circle(kp, 7, Color("#e0202f"))
		c.draw_arc(kp, 7, 0, TAU, 20, Color.WHITE, 2.0)
		_text_shadow(c, f_sans, "You are here", kp + Vector2(12, 5), 13, Color("#e0202f"))
	# zoom buttons
	for b in [[r_zin, "+"], [r_zout, "-"]]:
		var rr: Rect2 = b[0]
		var lr := Rect2(rr.position - r_map.position, rr.size)
		c.draw_rect(lr, Color(1, 1, 1, 0.92))
		c.draw_rect(lr, th.accent, false, 2.0)
		_text_c(c, f_sans, b[1], lr.get_center(), 24, th.accent)

func _biggest(st: Dictionary) -> Array:
	var best: Array = st.rects[0]
	for r in st.rects:
		if (r[2] - r[0]) * (r[3] - r[1]) > (best[2] - best[0]) * (best[3] - best[1]):
			best = r
	return best

func _text_c(c: CanvasItem, f: Font, t: String, p: Vector2, size: int, col: Color, outline := false) -> void:
	var sz := f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, size)
	var pos := p + Vector2(-sz.x * 0.5, size * 0.36)
	if outline:
		c.draw_string_outline(f, pos, t, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 3, Color(0, 0, 0, 0.55))
	c.draw_string(f, pos, t, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)

func _text_shadow(c: CanvasItem, f: Font, t: String, p: Vector2, size: int, col: Color) -> void:
	c.draw_string_outline(f, p, t, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 4, Color(1, 1, 1, 0.9))
	c.draw_string(f, p, t, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)

## The list beside the map (wide screens): each category with its stores, as on the real panels.
const ROW_H := 22.0
func _list_rows() -> Array:
	var rows := []
	var stalls := _stalls()
	for c in _year().get("cats", []):
		var items := []
		for i in stalls.size():
			if not stalls[i].vacant and c[0] in stalls[i].cats:
				items.append(i)
		if items.is_empty():
			continue
		if map_year == "1995":
			items.sort_custom(func(a, b): return int(stalls[a].num) < int(stalls[b].num))
		else:
			items.sort_custom(func(a, b): return String(stalls[a].name).naturalnocasecmp_to(stalls[b].name) < 0)
		rows.append({"head": c[1], "color": Color(c[2])})
		for i in items:
			rows.append({"i": i})
	return rows

func _draw_list() -> void:
	if not is_open or narrow:
		return
	var th := _theme()
	var c := list_c
	c.draw_rect(Rect2(Vector2.ZERO, r_list.size), th.body.darkened(0.03))
	c.draw_line(Vector2(r_list.size.x - 1, 0), Vector2(r_list.size.x - 1, r_list.size.y), th.hall.darkened(0.1), 2.0)
	var y := 12.0 - list_scroll
	var hdr := "STORES BY CATEGORY" if map_year == "2026" else "Merchant List"
	c.draw_string(th.font, Vector2(14, y + 18), hdr, HORIZONTAL_ALIGNMENT_LEFT, r_list.size.x - 20, 17, th.text)
	y += 34
	var stalls := _stalls()
	for row in _list_rows():
		if row.has("head"):
			if map_year == "1995":
				c.draw_rect(Rect2(10, y + 2, r_list.size.x - 22, ROW_H - 2), row.color)
				c.draw_string(f_sans, Vector2(16, y + 16), row.head, HORIZONTAL_ALIGNMENT_LEFT, r_list.size.x - 30, 12, Color.WHITE)
			else:
				c.draw_string(f_sans, Vector2(12, y + 17), String(row.head).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, r_list.size.x - 20, 12, th.text)
			y += ROW_H + 2
		else:
			var st: Dictionary = stalls[row.i]
			if row.i == sel:
				c.draw_rect(Rect2(6, y, r_list.size.x - 14, ROW_H), Color("#ff3b6b", 0.18))
			var x := 18.0
			if map_year == "1995":
				c.draw_string(f_sans, Vector2(x, y + 15), "%d" % int(st.num), HORIZONTAL_ALIGNMENT_RIGHT, 24, 12, th.text)
				x += 30
			else:
				c.draw_circle(Vector2(x + 2, y + 11), 4, _cat_color(st))
				x += 12
			c.draw_string(f_sans, Vector2(x, y + 15), st.name, HORIZONTAL_ALIGNMENT_LEFT, r_list.size.x - x - 12, 13, th.text)
			y += ROW_H

func _list_height() -> float:
	return 46.0 + _list_rows().size() * (ROW_H + 1) + 20

func _list_hit(p: Vector2) -> int:
	var y := 12.0 - list_scroll + 34
	for row in _list_rows():
		var h := ROW_H + 2 if row.has("head") else ROW_H
		if not row.has("head") and p.y >= y and p.y < y + h:
			return row.i
		y += h
	return -1

func _draw_chrome() -> void:
	var c := chrome
	if not is_open:
		_draw_prompt(c)
		return
	var th := _theme()
	# header
	c.draw_rect(r_head, th.head)
	if map_year == "2026":
		c.draw_rect(Rect2(r_head.position.x, r_head.end.y - 6, r_head.size.x, 6), th.head2)
		c.draw_string(f_sans, r_head.position + Vector2(16, r_head.size.y * 0.5 + 10), "Welcome!", HORIZONTAL_ALIGNMENT_LEFT, -1, 28 if narrow else 34, Color.WHITE)
		if not narrow:
			c.draw_string(f_sans, r_head.position + Vector2(200, r_head.size.y * 0.5 + 8), "MALL DIRECTORY", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(1, 1, 1, 0.9))
	else:
		c.draw_rect(Rect2(r_head.position.x, r_head.end.y - 5, r_head.size.x, 5), th.stripe)
		var lc := r_head.position + Vector2(44, r_head.size.y * 0.62)
		_fan_logo(c, lc, 0.62 if narrow else 0.78, Color("#f5f1e6"))
		if not narrow:
			c.draw_string(f_serif, r_head.position + Vector2(92, r_head.size.y * 0.5 + 9), "Merchant List & Map", HORIZONTAL_ALIGNMENT_LEFT, r_y95.position.x - r_head.position.x - 100, 24, Color.WHITE)
		else:
			c.draw_string(f_serif, r_head.position + Vector2(84, r_head.size.y * 0.5 + 6), "Directory", HORIZONTAL_ALIGNMENT_LEFT, r_y95.position.x - r_head.position.x - 88, 15, Color.WHITE)
	# the year toggle
	for yb in [[r_y95, "1995"], [r_y26, "2026"]]:
		var on: bool = map_year == yb[1]
		var rr: Rect2 = yb[0]
		c.draw_rect(rr, Color.WHITE if on else Color(1, 1, 1, 0.18))
		c.draw_rect(rr, Color.WHITE, false, 2.0)
		_text_c(c, f_sans, yb[1], rr.get_center(), 15, th.head if on else Color.WHITE)
	# close
	c.draw_rect(r_close, Color(0, 0, 0, 0.18))
	_text_c(c, f_sans, "X", r_close.get_center(), 20, Color.WHITE)
	# footer: the selected stall and Jump
	c.draw_rect(r_foot, th.head)
	if map_year == "1995":
		c.draw_rect(Rect2(r_foot.position.x, r_foot.position.y, r_foot.size.x, 4), th.stripe)
	var stalls := _stalls()
	var name := "Choose a store"
	var sub := "Arrow keys, d-pad or tap a store" if not narrow else "Tap a store · drag to move · pinch to zoom"
	if sel >= 0 and sel < stalls.size():
		var st: Dictionary = stalls[sel]
		name = ("%d  %s" % [int(st.num), st.name]) if map_year == "1995" and int(st.num) > 0 else String(st.name)
		var cats := []
		for k in st.cats:
			cats.append(_cat_title(k))
		sub = ", ".join(cats)
	var tw := r_jump.position.x - r_foot.position.x - 24
	c.draw_string(f_sans, r_foot.position + Vector2(16, 28), name, HORIZONTAL_ALIGNMENT_LEFT, tw, 20 if not narrow else 17, Color.WHITE)
	c.draw_string(f_sans, r_foot.position + Vector2(16, 50), sub, HORIZONTAL_ALIGNMENT_LEFT, tw, 12, Color(1, 1, 1, 0.85))
	var can := _selectable(sel)
	c.draw_rect(r_jump, Color.WHITE if can else Color(1, 1, 1, 0.3))
	_text_c(c, f_sans, "Jump  " + ("(Enter)" if not narrow and player and player.get("input_kind") == "kb" else ("(A)" if player and player.get("input_kind") == "pad" else "")), r_jump.get_center(), 15, th.head)
	# the type-to-find letters
	if typed != "":
		_text_shadow(c, f_sans, "Find: " + typed, r_map.position + Vector2(12, 24), 16, th.text)
	if confirm:
		_draw_confirm(c, th)

func _draw_back() -> void:
	if not is_open:
		return
	var vp := get_viewport().get_visible_rect().size
	back.draw_rect(Rect2(Vector2.ZERO, vp), BG_DIM)
	# the cabinet's frame round the card (the kiosk's satin aluminium)
	back.draw_rect(r_card.grow(6), Color("#cfd2d6"))
	back.draw_rect(r_card.grow(6), Color("#8d9096"), false, 2.0)

func _draw_confirm(c: Control, th: Dictionary) -> void:
	var vp := get_viewport().get_visible_rect().size
	c.draw_rect(Rect2(Vector2.ZERO, vp), Color(0, 0, 0, 0.45))
	var dlg := Rect2(r_yes.position.x - 16, r_yes.position.y - 120, r_no.end.x - r_yes.position.x + 32, 180)
	c.draw_rect(dlg, th.body)
	c.draw_rect(Rect2(dlg.position, Vector2(dlg.size.x, 8)), th.head)
	c.draw_rect(dlg, th.head, false, 3.0)
	var st: Dictionary = _stalls()[sel]
	_text_c(c, th.font, "Jump to this store?", dlg.position + Vector2(dlg.size.x * 0.5, 40), 22, th.text)
	_text_c(c, f_sans, String(st.name), dlg.position + Vector2(dlg.size.x * 0.5, 72), 17, th.accent)
	var j: Array = st.jump
	var note := ""
	if player and (int(j[0]) != int(player.get("wing")) or map_year != str(player.get("year"))):
		note = "Loads %s, %s" % ["Wing %d" % int(j[0]), map_year]
	if note != "":
		_text_c(c, f_sans, note, dlg.position + Vector2(dlg.size.x * 0.5, 94), 12, th.text.lightened(0.3))
	for b in [[r_yes, "Yes, go there", confirm_yes], [r_no, "Cancel", not confirm_yes]]:
		var rr: Rect2 = b[0]
		c.draw_rect(rr, th.head if b[2] else Color(1, 1, 1, 0.9))
		c.draw_rect(rr, th.head, false, 2.0)
		_text_c(c, f_sans, b[1], rr.get_center(), 16, Color.WHITE if b[2] else th.head)

## The SOUTHLAND MALL fan logo (the 1994 Merchant List & Map): an arch with a fan in it.
func _fan_logo(c: CanvasItem, p: Vector2, s: float, col: Color) -> void:
	var r := 34.0 * s
	c.draw_arc(p, r, PI, TAU, 24, col, 3.0 * s)
	for i in 7:
		var a := -PI * 0.5 + (i - 3) * deg_to_rad(17)
		var L := (26.0 if i in [2, 3, 4] else 20.0) * s
		var tip := p + Vector2(cos(a), sin(a)) * L + Vector2(0, -3 * s)
		var nrm := Vector2(-sin(a), cos(a)) * 2.6 * s
		c.draw_colored_polygon(PackedVector2Array([p + Vector2(0, 2 * s), tip + nrm, tip - nrm]), col)

# ------------------------------------------------------------------ the fallback prompt
## Remove when interact.gd lands (workstream B+C): their action button calls interact() on us.
func _draw_prompt(c: Control) -> void:
	prompt_rect = Rect2()
	if near_kiosk == null:
		return
	var vp := get_viewport().get_visible_rect().size
	var kind: String = str(player.get("input_kind")) if player else "kb"
	var key: String = {"pad": "X", "touch": "Tap", "kb": "E"}.get(kind, "E")
	var w := 280.0
	# where the seam's prompt goes (scripts/player.gd); the two never show together
	prompt_rect = Rect2((vp.x - w) * 0.5, vp.y - 132, w, 54)
	var sb := Color(0.08, 0.06, 0.05, 0.78)
	c.draw_rect(prompt_rect, sb)
	c.draw_rect(prompt_rect, Color(0.93, 0.85, 0.66, 0.85), false, 2.0)
	var kr := Rect2(prompt_rect.position + Vector2(14, 10), Vector2(50 if key == "Tap" else 36, 34))
	c.draw_rect(kr, Color(0.95, 0.89, 0.74))
	_text_c(c, f_sans, key, kr.get_center(), 16, Color(0.1, 0.08, 0.06))
	c.draw_string(f_sans, Vector2(kr.end.x + 12, prompt_rect.position.y + 33), "Read the Mall Directory", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 0.97, 0.9))

func _process(dt: float) -> void:
	if typed != "":
		typed_t -= dt
		if typed_t <= 0:
			typed = ""
			chrome.queue_redraw()
	if is_open:
		map_c.queue_redraw()   # the You-are-here pulse
		return
	if not fallback:
		return
	if player == null:
		player = get_parent().get_node_or_null("Player")
	var nk: Node = null
	if player and not player.get("frozen") and not player.get("leaving"):
		var pp: Vector3 = player.position
		var seam_prompt = player.get("prompt")
		if not (seam_prompt and seam_prompt.visible):
			for k in get_tree().get_nodes_in_group("directory_kiosk"):
				if k.in_reach(pp):
					nk = k
					break
	if nk != near_kiosk:
		near_kiosk = nk
		chrome.queue_redraw()

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
			if r_list.has_point(e.position):
				_scroll_list(-60)
			else:
				_zoom_by(1.2, e.position - r_map.position)
		elif e.button_index == MOUSE_BUTTON_WHEEL_DOWN and e.pressed:
			if r_list.has_point(e.position):
				_scroll_list(60)
			else:
				_zoom_by(1.0 / 1.2, e.position - r_map.position)
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

func _key(e: InputEventKey) -> void:
	var k := e.physical_keycode
	if confirm:
		if k in [KEY_LEFT, KEY_RIGHT, KEY_A, KEY_D, KEY_TAB]:
			confirm_yes = not confirm_yes
		elif k in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
			_confirm_choose(confirm_yes)
		elif k in [KEY_ESCAPE, KEY_BACKSPACE]:
			confirm = false
		_redraw()
		return
	match k:
		KEY_ESCAPE:
			close()
		KEY_LEFT:
			_step(Vector2(-1, 0))
		KEY_RIGHT:
			_step(Vector2(1, 0))
		KEY_UP:
			_step(Vector2(0, -1))
		KEY_DOWN:
			_step(Vector2(0, 1))
		KEY_ENTER, KEY_KP_ENTER:
			_ask()
		KEY_TAB:
			_toggle_year()
		KEY_EQUAL, KEY_KP_ADD:
			_zoom_by(1.3)
		KEY_MINUS, KEY_KP_SUBTRACT:
			_zoom_by(1.0 / 1.3)
		KEY_BACKSPACE:
			if typed != "":
				typed = typed.substr(0, typed.length() - 1)
				_find()
		_:
			if e.unicode >= 32 and not e.echo:
				typed += char(e.unicode)
				typed_t = 2.0
				_find()
	_redraw()

func _pad(b: int) -> void:
	if confirm:
		match b:
			JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_DPAD_RIGHT:
				confirm_yes = not confirm_yes
			JOY_BUTTON_A:
				_confirm_choose(confirm_yes)
			JOY_BUTTON_B:
				confirm = false
		_redraw()
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
		JOY_BUTTON_Y, JOY_BUTTON_LEFT_SHOULDER, JOY_BUTTON_RIGHT_SHOULDER:
			_toggle_year()
		JOY_BUTTON_X:
			_zoom_by(1.4 if zoom < 8.0 else 0.01)
	_redraw()

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
	_redraw()

## Move the selection to the nearest store in direction d (screen: +x right, +y down = south).
func _step(d: Vector2) -> void:
	var stalls := _stalls()
	if sel < 0:
		sel = _nearest_stall(pan)
		_show_sel()
		return
	var p0 := Vector2(stalls[sel].label[0], stalls[sel].label[1])
	var best := -1
	var best_cost := 1e9
	for i in stalls.size():
		if i == sel or stalls[i].vacant:
			continue
		var v := Vector2(stalls[i].label[0], stalls[i].label[1]) - p0
		var dist := v.length()
		if dist < 0.01:
			continue
		var along := v.dot(d)
		if along <= 0.0:
			continue
		var off := absf(v.dot(Vector2(-d.y, d.x)))
		if off > along * 2.2:
			continue
		var cost := along + off * 2.0
		if cost < best_cost:
			best_cost = cost
			best = i
	if best >= 0:
		sel = best
		_show_sel()

func _nearest_stall(w: Vector2) -> int:
	var stalls := _stalls()
	var best := -1
	var bd := 1e9
	for i in stalls.size():
		if stalls[i].vacant:
			continue
		var dd := w.distance_to(Vector2(stalls[i].label[0], stalls[i].label[1]))
		if dd < bd:
			bd = dd
			best = i
	return best

## The first store whose name (or 1995 number) starts with the letters typed.
func _find() -> void:
	if typed == "":
		return
	var t := typed.to_lower()
	var stalls := _stalls()
	for pass_i in 2:
		for i in stalls.size():
			if stalls[i].vacant:
				continue
			var nm := String(stalls[i].name).to_lower()
			var hit := (nm.begins_with(t) or str(int(stalls[i].num)) == t) if pass_i == 0 else nm.contains(t)
			if hit:
				sel = i
				_show_sel()
				return

func _toggle_year() -> void:
	var cur_name := ""
	if sel >= 0 and sel < _stalls().size():
		cur_name = _stalls()[sel].id
	map_year = "2026" if map_year == "1995" else "1995"
	_fit()
	confirm = false
	# keep the same space selected (the same unit id) if it is a store in the other year
	sel = -1
	for i in _stalls().size():
		if _stalls()[i].id == cur_name and not _stalls()[i].vacant:
			sel = i
	if sel < 0 and kiosk:
		sel = _nearest_stall(Vector2(kiosk.position.x, kiosk.position.z))
	list_scroll = 0.0
	_redraw()

func _ask() -> void:
	if _selectable(sel):
		confirm = true
		confirm_yes = true
		_redraw()

func _confirm_choose(yes: bool) -> void:
	confirm = false
	if not yes:
		_redraw()
		return
	var st: Dictionary = _stalls()[sel]
	var j: Array = st.jump
	print("directory jump: ", st.name, " (", map_year, ") -> wing ", j[0], " at ", j[1], ",", j[2], " yaw ", j[3])
	var p := player
	close()
	if p and p.has_method("jump_to"):
		p.jump_to(int(j[0]), int(map_year), float(j[1]), float(j[2]), float(j[3]))

# pointer: press on chrome buttons, tap or drag on the map / list
func _press(p: Vector2) -> void:
	drag_from = p
	drag_moved = false
	drag_target = ""
	if confirm:
		return
	if r_map.has_point(p) and not r_zin.has_point(p) and not r_zout.has_point(p):
		drag_target = "map"
	elif r_list.has_point(p):
		drag_target = "list"

func _move(p: Vector2, rel: Vector2) -> void:
	if (p - drag_from).length() > 8.0:
		drag_moved = true
	if not drag_moved:
		return
	if drag_target == "map":
		pan -= rel / (_fit_scale() * zoom)
		_clamp_pan()
		map_c.queue_redraw()
	elif drag_target == "list":
		_scroll_list(-rel.y)

func _release(p: Vector2) -> void:
	var was_drag := drag_moved
	var tgt := drag_target
	drag_target = ""
	drag_moved = false
	if was_drag:
		return
	if confirm:
		if r_yes.has_point(p):
			_confirm_choose(true)
		elif r_no.has_point(p):
			_confirm_choose(false)
		return
	if r_close.has_point(p):
		close()
	elif r_y95.has_point(p) and map_year != "1995":
		_toggle_year()
	elif r_y26.has_point(p) and map_year != "2026":
		_toggle_year()
	elif r_jump.has_point(p):
		_ask()
	elif r_zin.has_point(p):
		_zoom_by(1.4)
	elif r_zout.has_point(p):
		_zoom_by(1.0 / 1.4)
	elif tgt == "map":
		var w := _s2w(p - r_map.position)
		var hit := _stall_at(w)
		if hit >= 0:
			sel = hit
	elif tgt == "list":
		var i := _list_hit(p - r_list.position)
		if i >= 0:
			sel = i
			_show_sel()
	elif not r_card.has_point(p):
		close()
	_redraw()

func _stall_at(w: Vector2) -> int:
	var stalls := _stalls()
	for i in stalls.size():
		if stalls[i].vacant:
			continue
		for r in stalls[i].rects:
			if w.x >= r[0] and w.x <= r[2] and w.y >= r[1] and w.y <= r[3]:
				return i
	return -1

func _scroll_list(d: float) -> void:
	list_scroll = clamp(list_scroll + d, 0.0, max(0.0, _list_height() - r_list.size.y))
	list_c.queue_redraw()

func _touch(e: InputEventScreenTouch) -> void:
	if e.pressed:
		touches[e.index] = e.position
		if touches.size() == 1:
			_press(e.position)
		elif touches.size() == 2:
			var ps := touches.values()
			pinch_d = (ps[0] as Vector2).distance_to(ps[1])
			drag_moved = true   # a pinch is never a tap
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
			var mid: Vector2 = ((ps[0] as Vector2) + (ps[1] as Vector2)) * 0.5
			_zoom_by(d / pinch_d, mid - r_map.position)
		pinch_d = d
		return
	_move(e.position, e.position - prev)
