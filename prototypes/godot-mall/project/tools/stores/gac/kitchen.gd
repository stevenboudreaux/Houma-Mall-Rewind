## Great American Cookies' work area, the same kit in 1995 and 2026 (ws/interiors, Nov 4 2026; Steven:
## "the kiosk for Great American Cookie ... pretty perfect ... the same in both eras").
## From the tour video refs/new/cookie_co (Steven's pick, not Southland): gacc_t000_011-015 (the counter
## from the court: white 15 cm tile with scattered maroon / black / yellow / green squares, lit menu
## pictures on a white valance over the back counter, a drink fountain), 126 and 150 (the work area:
## a stainless prep table with a cookie cake being piped, sheet-pan racks, white buckets, a stainless
## convection oven stack), 146 (the menu pictures, the valance downlights). Pictures and goods are
## invented generic paintings (gac/paint.py; IP rule: no drink brands). design/storefronts/great-american-cookie.md.
##
## Every piece takes a local frame: o (floor corner), r (along), f (into the work area, away from
## the customer), y up; x along r, z along f, metres.

const K = preload("res://tools/stores/media/kit.gd")
const UP = Vector3.UP

static func L(o, r, f, x, y, z):
	return o + r * x + UP * y + f * z

static func box(b, g, m, o, r, f, x, y, z, w, h, d, c = "", dyn = false):
	if c != "":
		b.cur_color = Color(c)
	K.lbox(b, g, m, o, r, f, x, y, z, w, h, d, [], dyn)
	b.cur_color = Color.WHITE

## The white tile with scattered coloured squares (gac/tile_sq.png: 1.2 x 1.2 m, 8 x 8 tiles), on a
## wall from x0 to x1 (local), y0..y1, facing -f (towards the customer side of the frame).
static func tile_wall(b, g, o, r, f, x0, x1, y0, y1, z = 0.0):
	var nrm = -f
	var p = [L(o, r, f, x0, y0, z), L(o, r, f, x1, y0, z), L(o, r, f, x1, y1, z), L(o, r, f, x0, y1, z)]
	var flip = r.dot(nrm.cross(UP)) > 0.0
	var ua = x0 / 1.2
	var ub = x1 / 1.2
	if flip:
		ua = -ua; ub = -ub
	b.quad(g, "gac_tile_sq", p, nrm, [Vector2(ua, -y0 / 1.2), Vector2(ub, -y0 / 1.2), Vector2(ub, -y1 / 1.2), Vector2(ua, -y1 / 1.2)])

## The row of lit menu pictures on a white valance with downlights (gacc 011-015, 146): `n` panels
## 1.15 x 0.62 m from x0, bottom at y, standing `z` out from the wall (they face -f).
static func menu_pics(b, g, gs, o, r, f, x0, y, z, n):
	var w = 1.15
	var gap = 0.06
	var run = n * w + (n - 1) * gap
	box(b, g, "vcolor", o, r, f, x0 - 0.08, y - 0.06, z - 0.02, run + 0.16, 0.76, 0.06, "#f6f4ee")
	var flip = r.dot((-f).cross(UP)) > 0.0     # (checked by looking: the captions read the right way)
	for k in n:
		var x = x0 + k * (w + gap)
		var u0 = float(k % 4) / 4.0
		var u1 = u0 + 0.25
		if flip:
			var tmp = u0; u0 = u1; u1 = tmp
		b.quad(gs, "gac_pics", [L(o, r, f, x, y, z - 0.025), L(o, r, f, x + w, y, z - 0.025), L(o, r, f, x + w, y + 0.62, z - 0.025), L(o, r, f, x, y + 0.62, z - 0.025)], -f,
			[Vector2(u0, 1), Vector2(u1, 1), Vector2(u1, 0), Vector2(u0, 0)], true)
	# the valance over them: a white soffit lip with small round downlights
	box(b, g, "vcolor", o, r, f, x0 - 0.1, y + 0.72, z - 0.45, run + 0.2, 0.1, 0.45, "#f8f6f0")
	var xx = x0 + 0.3
	while xx < x0 + run:
		b.cur_color = Color("#fff4dc")
		b.cyl(gs, "gac_led", L(o, r, f, xx, y + 0.715, z - 0.25), 0.035, 0.035, 0.006, 10, false, true, true)
		xx += 0.6
	b.cur_color = Color.WHITE
	var l = b.add_omni(L(o, r, f, x0 + run * 0.5, y + 0.3, z - 0.6), 0.35, max(2.5, run * 0.7), Color(1.0, 0.95, 0.85))
	b.tag(l, "", 0.3, 0.35)

## A stainless convection oven stack (two decks on a stand), 0.95 wide, door facing -f.
static func oven(b, g, gs, o, r, f, x):
	box(b, g, "wl_steel", o, r, f, x + 0.05, 0.0, 0.05, 0.08, 0.5, 0.08)
	box(b, g, "wl_steel", o, r, f, x + 0.82, 0.0, 0.05, 0.08, 0.5, 0.08)
	box(b, g, "wl_steel", o, r, f, x + 0.05, 0.0, 0.7, 0.08, 0.5, 0.08)
	box(b, g, "wl_steel", o, r, f, x + 0.82, 0.0, 0.7, 0.08, 0.5, 0.08)
	for k in 2:
		var y = 0.5 + k * 0.62
		box(b, g, "wl_steel", o, r, f, x, y, 0.0, 0.95, 0.6, 0.85)
		# the door: a dark window in a steel frame, the handle, the control strip on the right
		box(b, gs, "vcolor", o, r, f, x + 0.08, y + 0.12, -0.012, 0.6, 0.34, 0.012, "#1c1c20", true)
		box(b, gs, "wl_steel", o, r, f, x + 0.1, y + 0.5, -0.04, 0.56, 0.025, 0.03, "", true)
		box(b, gs, "vcolor", o, r, f, x + 0.74, y + 0.08, -0.012, 0.16, 0.44, 0.012, "#2a2a2e", true)
		for j in 3:
			box(b, gs, "vcolor", o, r, f, x + 0.79, y + 0.36 - j * 0.1, -0.022, 0.06, 0.04, 0.01, ["#e83a2a", "#3ad06a", "#f2c81e"][j], true)
	box(b, g, "wl_steel", o, r, f, x - 0.02, 1.74, -0.02, 0.99, 0.08, 0.9)
	K.ob(b, L(o, r, f, x, 0, 0), L(o, r, f, x + 0.95, 0, 0.85), 0.05)

## A sheet-pan rack (chrome, 0.55 wide x 0.7 deep x 1.75 high), `n_full` of its 12 pans carrying
## rows of baked cookies; on casters.
static func rack(b, g, gs, o, r, f, x, z, n_full = 7):
	for c in [[0.0, 0.0], [0.52, 0.0], [0.0, 0.66], [0.52, 0.66]]:
		box(b, gs, "vcolor", o, r, f, x + c[0], 0.06, z + c[1], 0.03, 1.69, 0.03, "#c8cacc", true)
		box(b, gs, "vcolor", o, r, f, x + c[0] - 0.01, 0.0, z + c[1] - 0.01, 0.05, 0.06, 0.05, "#2a2a2c", true)
	for k in 12:
		var y = 0.2 + k * 0.125
		box(b, gs, "vcolor", o, r, f, x + 0.03, y, z + 0.02, 0.49, 0.012, 0.65, "#b8b4ac", true)
		if k < n_full:
			var p0 = L(o, r, f, x + 0.05, y + 0.014, z + 0.05)
			var uo = float(k % 4) * 0.25
			b.quad(gs, "gac_cookies", [p0, p0 + r * 0.45, p0 + r * 0.45 + f * 0.6, p0 + f * 0.6], UP,
				[Vector2(uo, 0.0), Vector2(uo + 0.25, 0.0), Vector2(uo + 0.25, 0.5), Vector2(uo, 0.5)], true)
	K.ob(b, L(o, r, f, x, 0, z), L(o, r, f, x + 0.55, 0, z + 0.7), 0.05)

## The stainless prep table (w x 0.76, 0.9 high, an undershelf) with a sheet cookie cake being piped
## (gacc 071-126): the cake, a piping bag lying by it, a roll of parchment, tubs of icing.
static func prep_table(b, g, gs, o, r, f, x, z, w):
	box(b, g, "wl_steel", o, r, f, x, 0.87, z, w, 0.04, 0.76)
	box(b, g, "wl_steel", o, r, f, x + 0.04, 0.2, z + 0.04, w - 0.08, 0.025, 0.68)
	for c in [[0.03, 0.03], [w - 0.07, 0.03], [0.03, 0.69], [w - 0.07, 0.69]]:
		box(b, g, "wl_steel", o, r, f, x + c[0], 0.0, z + c[1], 0.04, 0.87, 0.04)
	# the board and the cookie cake on it (a 40 x 30 cm sheet, piped border, lettering)
	box(b, gs, "vcolor", o, r, f, x + 0.25, 0.91, z + 0.14, 0.5, 0.012, 0.42, "#f4f2ee", true)
	var p0 = L(o, r, f, x + 0.3, 0.945, z + 0.2)
	box(b, gs, "vcolor", o, r, f, x + 0.3, 0.922, z + 0.2, 0.4, 0.022, 0.3, "#b8783c", true)
	b.quad(gs, "gac_cake_top", [p0, p0 + r * 0.4, p0 + r * 0.4 + f * 0.3, p0 + f * 0.3], UP,
		[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)], true)
	# the piping bag, tubs, a stack of cake boards
	b.cur_color = Color("#f6f6f4")
	b.cyl(gs, "vcolor", L(o, r, f, x + 0.85, 0.91, z + 0.3), 0.03, 0.008, 0.2, 8, true, true, true)
	for k in 3:
		b.cur_color = [Color("#f8f8f6"), Color("#5a3220"), Color("#e86a9a")][k]
		b.cyl(gs, "vcolor", L(o, r, f, x + w - 0.5 + k * 0.14, 0.91, z + 0.18), 0.055, 0.06, 0.09, 12, true, false, true)
	b.cur_color = Color.WHITE
	box(b, gs, "vcolor", o, r, f, x + w - 0.48, 0.91, z + 0.4, 0.36, 0.06, 0.3, "#e8e4dc", true)
	# white icing buckets under it
	for k in 2:
		b.cur_color = Color("#f4f4f2")
		b.cyl(gs, "vcolor", L(o, r, f, x + 0.3 + k * 0.36, 0.0, z + 0.4), 0.15, 0.16, 0.36, 14, true, false, true)
	b.cur_color = Color.WHITE
	K.ob(b, L(o, r, f, x, 0, z), L(o, r, f, x + w, 0, z + 0.76), 0.05)

## The back counter under the menu pictures: a white counter (0.95 high, 0.7 deep, its front in
## the tile) with a drink fountain (generic lit panel), cup stacks, a cookie warmer, a register.
static func back_counter(b, g, gs, o, r, f, x, z, w):
	box(b, g, "vcolor", o, r, f, x, 0.0, z, w, 0.9, 0.7, "#f6f4ee")
	tile_wall(b, g, o, r, f, x, x + w, 0.12, 0.88, z - 0.003)
	box(b, g, "vcolor", o, r, f, x - 0.02, 0.9, z - 0.03, w + 0.04, 0.04, 0.74, "#e8e2d6")
	box(b, g, "vcolor", o, r, f, x, 0.0, z + 0.04, w, 0.12, 0.62, "#2a2a2c")
	# the fountain: a dark body, a lit picture panel, six valves, a drip tray
	var fx = x + w - 1.0
	box(b, g, "vcolor", o, r, f, fx, 0.94, z + 0.15, 0.8, 0.8, 0.5, "#c8202c")
	b.quad(gs, "gac_fountain", [L(o, r, f, fx + 0.05, 1.3, z + 0.145), L(o, r, f, fx + 0.75, 1.3, z + 0.145), L(o, r, f, fx + 0.75, 1.7, z + 0.145), L(o, r, f, fx + 0.05, 1.7, z + 0.145)], -f,
		[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)] if r.dot(f.cross(UP)) > 0.0 else [Vector2(1, 1), Vector2(0, 1), Vector2(0, 0), Vector2(1, 0)], true)
	for k in 6:
		box(b, gs, "vcolor", o, r, f, fx + 0.08 + k * 0.115, 1.17, z + 0.1, 0.06, 0.1, 0.06, ["#1a1a1c", "#c8202c", "#2a5ac8", "#f2c81e", "#3ab04a", "#e86a2a"][k], true)
	box(b, gs, "vcolor", o, r, f, fx + 0.05, 0.94, z + 0.05, 0.7, 0.04, 0.16, "#3a3a3e", true)
	# cups, lids
	for k in 3:
		b.cur_color = Color("#fbfbf8")
		b.cyl(gs, "vcolor", L(o, r, f, x + 0.3 + k * 0.15, 0.94, z + 0.4), 0.045, 0.05, 0.45, 10, true, false, true)
	b.cur_color = Color.WHITE
	# the cookie warmer: a small glass box of cookies on the counter
	box(b, gs, "vcolor", o, r, f, x + 0.85, 0.94, z + 0.15, 0.6, 0.06, 0.45, "#d0d0d4", true)
	var p0 = L(o, r, f, x + 0.88, 1.005, z + 0.18)
	b.quad(gs, "gac_cookies", [p0, p0 + r * 0.54, p0 + r * 0.54 + f * 0.39, p0 + f * 0.39], UP,
		[Vector2(0, 0.5), Vector2(0.25, 0.5), Vector2(0.25, 1.0), Vector2(0, 1.0)], true)
	K.lbox(b, "glass", "glass", o, r, f, x + 0.85, 1.0, z + 0.15, 0.6, 0.32, 0.45, ["-y"], true)
	K.ob(b, L(o, r, f, x, 0, z), L(o, r, f, x + w, 0, z + 0.7), 0.05)

## Staff-side clutter seen in the video: a stack of flat cake boxes, a glove box, a phone-sized
## ticket printer; and a hand sink on the wall.
static func sink(b, g, gs, o, r, f, x, z):
	box(b, g, "wl_steel", o, r, f, x, 0.75, z, 0.45, 0.2, 0.4)
	box(b, gs, "vcolor", o, r, f, x + 0.05, 0.9, z + 0.05, 0.35, 0.05, 0.3, "#8a8c90", true)
	box(b, gs, "wl_steel", o, r, f, x + 0.2, 0.95, z + 0.33, 0.04, 0.25, 0.04, "", true)
	box(b, gs, "vcolor", o, r, f, x + 0.05, 1.35, z + 0.36, 0.3, 0.34, 0.06, "#f4f4f2", true)

# ------------------------------------------------------------------ the 1995 store (wave7 cookie())
## The work area of the 1995 shop behind the case (the case at 2.6 m, the shop 6 x 12 m): a tiled
## menu wall across the shop at d = MW with the back counter and the lit menu pictures (the record:
## "the ovens' steel along the back, under a row of lit menu pictures"), its doorway on the right
## into the kitchen behind (ovens, racks, the prep table with a cookie cake being piped).
const MW = 6.4
static func build_1995(b, G, GS, a, t, n, W, D, SIDE):
	var o = a + t * SIDE - n * MW
	var r = t
	var f = -n
	var w = W - 2.0 * SIDE
	var door0 = w - 1.25
	# the menu wall: tile both faces, a doorway on the right
	tile_wall(b, G, o, r, f, 0.0, door0, 0.0, 3.0)
	tile_wall(b, G, o, r, f, door0 + 1.0, w, 0.0, 3.0)
	tile_wall(b, G, o, r, f, door0, door0 + 1.0, 2.2, 3.0)
	box(b, G, "vcolor", o, r, f, door0 - 0.04, 0.0, -0.01, 0.04, 2.24, 0.16, "#f6f4ee")
	box(b, G, "vcolor", o, r, f, door0 + 1.0, 0.0, -0.01, 0.04, 2.24, 0.16, "#f6f4ee")
	box(b, G, "vcolor", o, r, f, door0, 2.2, -0.01, 1.0, 0.04, 0.16, "#f6f4ee")
	b.cur_color = Color("#f2f0ea")
	b.quad(G, "vcolor_matte", [L(o, r, f, 0, 0, 0.14), L(o, r, f, 0, 3.0, 0.14), L(o, r, f, door0, 3.0, 0.14), L(o, r, f, door0, 0, 0.14)], f)
	b.quad(G, "vcolor_matte", [L(o, r, f, door0 + 1.0, 0, 0.14), L(o, r, f, door0 + 1.0, 3.0, 0.14), L(o, r, f, w, 3.0, 0.14), L(o, r, f, w, 0, 0.14)], f)
	b.cur_color = Color.WHITE
	K.ob(b, L(o, r, f, 0, 0, 0), L(o, r, f, door0, 0, 0.15), 0.02)
	K.ob(b, L(o, r, f, door0 + 1.0, 0, 0), L(o, r, f, w, 0, 0.15), 0.02)
	# the back counter against it (the customer side), the lit pictures over it
	var bc = o - f * 0.7
	back_counter(b, G, GS, bc, r, f, 0.1, 0.0, door0 - 0.2)
	menu_pics(b, G, GS, o, r, f, 0.25, 1.85, -0.01, 3)
	# the kitchen behind: the oven stack on the left, two racks, the prep table, a sink
	var ko = o + f * 0.15
	var kz = D - MW - 0.15 - SIDE      # the kitchen's depth to the back wall
	oven(b, G, GS, L(ko, r, f, 0, 0, kz - 0.9), r, f, 0.15)
	oven(b, G, GS, L(ko, r, f, 0, 0, kz - 0.9), r, f, 1.2)
	rack(b, G, GS, ko, r, f, 2.45, kz - 0.8)
	rack(b, G, GS, ko, r, f, 3.1, kz - 0.8, 4)
	prep_table(b, G, GS, ko, r, f, w - 1.9, 1.1, 1.6)
	sink(b, G, GS, ko, r, f, w - 0.6, kz - 0.45)
	var l = b.add_omni(L(ko, r, f, w * 0.5, 2.6, 2.4), 0.5, 5.0, Color(1.0, 0.98, 0.94))
	b.tag(l, "", 0.4, 0.5)

# ------------------------------------------------------------------ the 2026 store (case.gd build_2026)
## Between the case and the red back counter (d 1.4..5.2) the 2026 shop was an empty floor; the
## video's work area goes there, along the plain right wall: the oven stack against it, a rack, and
## the prep table in the middle with the cookie cake being piped. P is the 2026 frame's P(x, y, d).
static func build_2026(b, G, GS, a0, tt, nn, LN, flip):
	var P = func(x, y, d): return a0 + tt * ((LN - x) if flip else x) - nn * d + UP * y
	var o = P.call(LN - 0.12, 0.0, 1.6)
	var r = (P.call(LN - 0.12, 0.0, 2.6) - o).normalized()     # along the right wall, into the shop
	var f = (P.call(LN - 1.12, 0.0, 1.6) - o).normalized()     # away from the wall
	# the oven stack against the wall (its door facing into the shop), a rack nearer the case
	oven(b, G, GS, L(o, r, f, 1.6, 0, 0.9), r, -f, 0.0)
	rack(b, G, GS, o, r, f, 0.15, 0.1)
	# the prep table across the middle, the cake on it
	var po = P.call(LN - 1.25, 0.0, 2.0)
	var pr = (P.call(LN - 2.25, 0.0, 2.0) - po).normalized()
	var pf = (P.call(LN - 1.25, 0.0, 3.0) - po).normalized()
	prep_table(b, G, GS, po, pr, pf, 0.0, 0.0, 1.5)

# ------------------------------------------------------------------ materials
static func fill_mat(m, key, b):
	match key:
		"tile_sq":
			# world triplanar, so every wall it is on lines up (1.2 m repeat)
			m.albedo_texture = b.tex("gac/tile_sq.png"); m.roughness = 0.35
			m.uv1_triplanar = true; m.uv1_world_triplanar = true
			m.uv1_scale = Vector3.ONE / 1.2
		"pics":
			m.albedo_texture = b.tex("gac/pics.png"); m.roughness = 0.4
			K.emit_tex(m, 0.7)
		"cake_top":
			m.albedo_texture = b.tex("gac/cake_top.png"); m.roughness = 0.6
		"fountain":
			m.albedo_texture = b.tex("gac/fountain.png")
			K.emit_tex(m, 0.8)
		_:
			return false
	return true
