## The 2026 "through the glass" fronts (Steven's Oct 28 sprint, workstream G): each store's front
## and the first 6-10 m inside that you see from the hall, built from the Oct 23 2026 footage.
## Not walk-in: the store tiles stay shut in the walk grid. Notes, sources and guesses per store:
## design/storefronts/fronts-2026.md.
##
## A recipe per store (RECIPES) lays the front out as seen from the hall, LEFT TO RIGHT: x = 0 is
## the viewer's left end of the frontage whichever way the store faces (U() maps it to the edge's
## own u). d runs into the store, y up. Stores with several frontage edges (Claire's, DJS,
## Cakelicious) build their room once, from the store's 2026 rect, and each edge's front.
## Materials "f26_<key>" (fill_mat), textures tex/f26/ (paint.py). The fixtures reuse the apparel
## kit (racks, face-outs, mannequins) and the shoe-wall kit (small/shoes.gd).

const K = preload("res://tools/stores/media/kit.gd")
const AK = preload("res://tools/stores/apparel/kit.gd")
const SH = preload("res://tools/stores/small/shoes.gd")
const S26 = preload("res://tools/stores/signs/sign_2026.gd")
const GAC = preload("res://tools/stores/gac/case.gd")
const UP = Vector3.UP

const RECIPES = {
	"SPENCER'S": "spencers", "GREAT AMERICAN COOKIES": "gac", "LIDS": "lids", "JOURNEYS": "journeys",
	"CLAIRE'S": "claires", "THE BILLIARD ROOM": "billiard", "DJS JEWELERS": "djs", "FOOT LOCKER": "footlocker",
	"AÉROPOSTALE": "aero", "RAINBOW": "rainbow", "BATH & BODY WORKS": "bbw", "CAKELICIOUS": "cake",
	"AUNTIE ANNE'S": "auntie", "AT&T": "att",
}
## Stores whose room is built once (with the first edge's call) from their 2026 outline in world
## x, z (eras_2026.json's rect, minus the corner the hall takes): "poly" the floor and ceiling,
## "walls" the non-frontage sides, "c" a point every corner can be seen from (fan triangulation).
const ROOMS = {
	"CLAIRE'S": {"poly": [[2, -18], [20, -18], [20, -6], [12, -6], [12, -10], [2, -10]], "c": [12, -14],
		"walls": [[[2, -18], [20, -18]], [[20, -18], [20, -6]]]},
	"DJS JEWELERS": {"poly": [[-20, 36], [-10, 36], [-10, 48], [-20, 48]], "c": [-15, 42],
		"walls": [[[-20, 36], [-10, 36]], [[-20, 36], [-20, 48]]]},
	"CAKELICIOUS": {"poly": [[-130, 60], [-124, 60], [-124, 68], [-138, 68], [-138, 66], [-136, 66]], "c": [-129, 65],
		"walls": [[[-124, 60], [-124, 68]], [[-124, 68], [-138, 68]], [[-138, 68], [-138, 66]], [[-138, 66], [-136, 66]]]},
}
static var done_rooms = {}

static var a0: Vector3
static var tt: Vector3
static var nn: Vector3
static var bb
static var LN = 0.0
static var FLIP = false
static var G = "f26"
static var GS = "f26_small"
static var GD = "f26_dyn"

static func has(name):
	return RECIPES.has(name)

static func build(b, g, e, a, b2, n, t, Ln, sd):
	bb = b
	a0 = a
	tt = t
	nn = n
	LN = Ln
	# x runs left to right as seen from the hall: the viewer faces -n, their right is (-n) x up
	FLIP = t.dot((-n).cross(UP)) < 0.0
	G = g
	GS = g + "_f26s"
	GD = g + "_f26d"
	load("res://tools/stores/fronts26/store.gd").call(RECIPES[sd.name], sd, e)

# ------------------------------------------------------------------ frame helpers
static func U(x):
	return LN - x if FLIP else x

static func P(x, y, d):
	return a0 + tt * U(x) - nn * d + UP * y

## A box in the left-to-right frame: x0..x0+w, y..y+h, d..d+dd.
static func bx(g, m, x0, y, d, w, h, dd, skip = [], dyn = false):
	var u0 = min(U(x0), U(x0 + w))
	K.lbox(bb, g, m, a0, tt, -nn, u0, y, d, w, h, dd, skip, dyn)

static func col(c):
	bb.cur_color = Color(c)

static func cbx(c, x0, y, d, w, h, dd, g = "", m = "vcolor"):
	col(c)
	bx(G if g == "" else g, m, x0, y, d, w, h, dd)
	bb.cur_color = Color.WHITE

## A textured quad facing the hall (normal +n) at depth d, x0..x1 / y0..y1, texture rect ua..ub, va..vb.
static func front_q(g, m, x0, x1, y0, y1, d, ua = 0.0, va = 0.0, ub = 1.0, vb = 1.0, dyn = false):
	bb.quad(g, m, [P(x0, y0, d), P(x1, y0, d), P(x1, y1, d), P(x0, y1, d)], nn,
		[Vector2(ua, vb), Vector2(ub, vb), Vector2(ub, va), Vector2(ua, va)], dyn)

## A world-scaled textured quad facing the hall (tile tw x th metres).
static func front_t(g, m, x0, x1, y0, y1, d, tw, th):
	front_q(g, m, x0, x1, y0, y1, d, x0 / tw, -y1 / th, x1 / tw, -y0 / th)

## A quad on a side wall (x = const) facing into the room (+x if `f` > 0), d0..d1 / y0..y1.
static func side_q(g, m, x, d0, d1, y0, y1, f, ua = 0.0, va = 0.0, ub = 1.0, vb = 1.0, dyn = false):
	var nrm = (P(x + 1.0, 0, 0) - P(x, 0, 0)) * f
	var pa = P(x, y0, d0) if f > 0 else P(x, y0, d1)
	var pb = P(x, y0, d1) if f > 0 else P(x, y0, d0)
	var pc = P(x, y1, d1) if f > 0 else P(x, y1, d0)
	var pd = P(x, y1, d0) if f > 0 else P(x, y1, d1)
	bb.quad(g, m, [pa, pb, pc, pd], nrm, [Vector2(ua, vb), Vector2(ub, vb), Vector2(ub, va), Vector2(ua, va)], dyn)

static func glass(x0, x1, y0, y1, d = 0.0):
	bb.quad("glass", "glass", [P(x0, y0, d), P(x1, y0, d), P(x1, y1, d), P(x0, y1, d)], nn, [Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)], true)

## A glazing run x0..x1 with mullions every `step` m (0: none), a sill `base` high, a head at y1.
static func glazing(x0, x1, y1, mull_col, base = 0.4, base_col = "", step = 1.6, t = 0.05, d = 0.0):
	glass(x0, x1, base, y1, d)
	col(mull_col)
	bx(G, "vcolor", x0, base, d - t, x1 - x0, t, t * 2)
	bx(G, "vcolor", x0, y1 - t, d - t, x1 - x0, t, t * 2)
	if step > 0.0:
		var n = max(1, int(round((x1 - x0) / step)))
		for k in n + 1:
			var x = x0 + (x1 - x0) * k / n
			bx(G, "vcolor", x - t * 0.5, base, d - t, t, y1 - base, t * 2)
	if base > 0.0:
		col(base_col if base_col != "" else mull_col)
		bx(G, "vcolor", x0, 0.0, d - 0.04, x1 - x0, base, 0.08)
	bb.cur_color = Color.WHITE

## The band over the front, from y0 to the lane ceiling, `proud` m into the hall; and the store's
## own Demo 43 sign on it (build_mall.gd sign_2026).
static func band(sd, c, y0 = 3.2, proud = 0.16, m = "vcolor_matte", with_sign = true):
	col(c)
	bx(G, m, 0.0, y0, -proud, LN, bb.LANE_H - y0, proud)
	bb.cur_color = Color.WHITE
	if with_sign:
		bb.sign_2026(G, sd.name, a0 + tt * (LN * 0.5), nn, tt, LN)

## The room behind the front, x 0..LN, d 0..D: floor, ceiling, side and back walls, lights.
## ceil: "white" lay-in with troffers, "black" open (painted deck with track heads).
static func room(D, wall_c, floor_c, ceil_kind = "white", ceil_y = 3.2, light = 1.0, floor_m = "vcolor"):
	col(floor_c)
	bb.quad(G, floor_m, [P(0, 0.003, 0), P(LN, 0.003, 0), P(LN, 0.003, D), P(0, 0.003, D)], UP)
	col(wall_c)
	side_q(G, "vcolor_matte", 0.02, 0.0, D, 0.0, ceil_y, 1.0)
	side_q(G, "vcolor_matte", LN - 0.02, 0.0, D, 0.0, ceil_y, -1.0)
	bb.quad(G, "vcolor_matte", [P(LN, 0, D), P(0, 0, D), P(0, ceil_y, D), P(LN, ceil_y, D)], nn)
	if ceil_kind == "black":
		col("#151517")
		bb.quad(G, "vcolor_matte", [P(0, ceil_y, 0), P(LN, ceil_y, 0), P(LN, ceil_y, D), P(0, ceil_y, D)], Vector3.DOWN)
		col("#2a2a2c")
		var d = 1.2
		while d < D - 0.5:
			bx(GS, "vcolor", 0.3, ceil_y - 0.06, d, LN - 0.6, 0.03, 0.04)
			var x = 0.8
			while x < LN - 0.6:
				bb.cyl(GS, "vcolor", P(x, ceil_y - 0.2, d + 0.02), 0.04, 0.05, 0.14, 8, true, true)
				x += 1.4
			d += 2.2
		bb.cur_color = Color.WHITE
	else:
		bb.cur_color = Color.WHITE
		var cp = [P(0, ceil_y, 0), P(LN, ceil_y, 0), P(LN, ceil_y, D), P(0, ceil_y, D)]
		var cuv = []
		for p in cp:
			cuv.append(Vector2(p.x / 0.61, p.z / 1.22))
		bb.quad(G, "kb_ceiling", cp, Vector3.DOWN, cuv)
		var d2 = 1.0
		while d2 + 1.22 < D - 0.3:
			var x2 = 1.0
			while x2 + 0.61 < LN - 0.6:
				var tq = [P(x2, ceil_y - 0.006, d2), P(x2 + 0.61, ceil_y - 0.006, d2), P(x2 + 0.61, ceil_y - 0.006, d2 + 1.22), P(x2, ceil_y - 0.006, d2 + 1.22)]
				bb.quad(G, "gb_troffer", tq, Vector3.DOWN, [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)])
				x2 += 2.4
			d2 += 2.6
	bb.cur_color = Color.WHITE
	# light: a few soft omnis down the middle (the generic interior was lit the same way)
	var d3 = 1.5
	while d3 < D:
		var l = bb.add_omni(P(LN * 0.5, ceil_y - 0.4, d3), 0.45 * light, max(4.0, LN * 0.8), Color(1.0, 0.96, 0.9))
		bb.tag(l, "", 0.4 * light, 0.45 * light)
		d3 += 3.5

## A merchandise wall on a side (x = side's face) or the back: a textured panel d0..d1, y0..y1.
static func side_merch(m, x, f, d0, d1, y0, y1, tw, th, dyn = false):
	var n = (d1 - d0) / tw
	side_q(GS if dyn else G, m, x + 0.03 * f, d0, d1, y0, y1, f, 0.0, 0.0, n, (y1 - y0) / th, dyn)

static func back_merch(m, x0, x1, D, y0, y1, tw, th):
	front_q(G, m, x0, x1, y0, y1, D - 0.03, 0.0, 0.0, (x1 - x0) / tw, (y1 - y0) / th)

## A display table: a top (colour or textured top `top_m`) on a base, at x, d (centre), w x dd.
static func table(x, d, w, dd, h, base_c, top_c, top_m = ""):
	cbx(base_c, x - w * 0.5 + 0.06, 0.0, d - dd * 0.5 + 0.06, w - 0.12, h - 0.04, dd - 0.12)
	if top_m != "":
		bx(G, top_m, x - w * 0.5, h - 0.04, d - dd * 0.5, w, 0.04, dd)
	else:
		cbx(top_c, x - w * 0.5, h - 0.04, d - dd * 0.5, w, 0.04, dd)

## Small coloured boxes/stacks on a table top (folded goods, boxes, bottles): rng-varied.
static func goods(x, d, w, dd, y, cols, rng, size = 0.16, hmax = 0.25):
	var nx = max(1, int(w / (size * 1.5)))
	var nz = max(1, int(dd / (size * 1.5)))
	for i in nx:
		for k in nz:
			col(cols[rng.randi_range(0, cols.size() - 1)])
			var hh = rng.randf_range(0.04, hmax)
			bx(GS, "vcolor", x - w * 0.5 + (i + 0.2) * w / nx, y, d - dd * 0.5 + (k + 0.2) * dd / nz, size, hh, size * 0.8)
	bb.cur_color = Color.WHITE

## A glass showcase: a base, a glass box on top with a textured floor (jewellery, cakes), lit.
static func showcase(x, d, w, dd, base_c, top_m, h = 0.95, glass_h = 0.3, top_c = "#e8e6e0"):
	cbx(base_c, x - w * 0.5, 0.0, d - dd * 0.5, w, h - glass_h, dd)
	bb.quad(GS, top_m, [P(x - w * 0.5 + 0.03, h - glass_h + 0.005, d - dd * 0.5 + 0.03), P(x + w * 0.5 - 0.03, h - glass_h + 0.005, d - dd * 0.5 + 0.03),
		P(x + w * 0.5 - 0.03, h - glass_h + 0.005, d + dd * 0.5 - 0.03), P(x - w * 0.5 + 0.03, h - glass_h + 0.005, d + dd * 0.5 - 0.03)], UP,
		[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)], true)
	bx(GD, "f26_glass", x - w * 0.5, h - glass_h, d - dd * 0.5, w, glass_h, dd, ["-y"], true)
	cbx(top_c, x - w * 0.5, h - 0.01, d - dd * 0.5, w, 0.012, dd, GS)

## A lit poster stand in front of a store: black frame on feet, two poster panels.
static func poster_stand(x, d, k0, k1):
	cbx("#141414", x - 0.34, 0.0, d - 0.18, 0.68, 0.04, 0.36)
	cbx("#141414", x - 0.32, 0.04, d - 0.03, 0.64, 1.74, 0.06)
	front_q(GD, "f26_posters_lit", x - 0.28, x + 0.28, 0.95, 1.72, d - 0.035, k0 * 0.25, 0.0, k0 * 0.25 + 0.25, 1.0, true)
	front_q(GD, "f26_posters_lit", x - 0.28, x + 0.28, 0.12, 0.89, d - 0.035, k1 * 0.25, 0.0, k1 * 0.25 + 0.25, 1.0, true)
	K.ob(bb, P(x - 0.4, 0, d - 0.25), P(x + 0.4, 0, d + 0.25), 0.02)

## A shoe wall (small/shoes.gd) along a side wall (side = "L"/"R") or the back ("B").
static func shoe_wall(side, d0, d1, lk, rng, wall_c):
	if side == "B":
		var o = P(0.05, 0, d1)
		var r = (P(1, 0, 0) - P(0, 0, 0))
		SH.shoe_wall(bb, G, o, r, nn, LN - 0.1, lk, rng, Color(wall_c))
	elif side == "L":
		SH.shoe_wall(bb, G, P(0.04, 0, d0), -nn, (P(1, 0, 0) - P(0, 0, 0)), d1 - d0, lk, rng, Color(wall_c))
	else:
		SH.shoe_wall(bb, G, P(LN - 0.04, 0, d1), nn, -(P(1, 0, 0) - P(0, 0, 0)), d1 - d0, lk, rng, Color(wall_c))

static func ob_room(D):
	K.ob(bb, P(0, 0, 0.05), P(LN, 0, D), 0.0)

# ------------------------------------------------------------------ the stores
## Spencer's (n35, 12 m): faux red brick with a rusty steel-angle frame on a concrete plinth, a
## weathered plank lintel; left to right a display window, the open entry under the half-raised
## graffiti shutter (the Demo 43 spec on it), a second window with the yellow "enter" banner on
## its pier, then 3.4 m of solid brick with a rusty bracket. Lit poster stands and a lit vending
## machine at the entry. Inside: black walls of printed tees, black ceiling, dark floor
## (IMG_4440 f001-f002, IMG_4439 f034-f036).
static func spencers(sd, e):
	room(9.0, "#141416", "#2a2626", "black", 3.4, 0.7)
	var LH = bb.LANE_H
	# the cream mall wall above the brick
	col("#e6dcc6")
	bx(G, "vcolor_matte", 0.0, 3.4, -0.1, LN, LH - 3.4, 0.1)
	bb.cur_color = Color.WHITE
	# brick piers and the solid wall, with the plinth
	for pr in [[0.0, 0.5], [2.4, 3.0], [6.2, 6.8], [8.6, LN]]:
		bx(G, "f26_brick", pr[0], 0.0, -0.22, pr[1] - pr[0], 3.4, 0.22)
		bx(G, "f26_concrete", pr[0] - 0.01, 0.0, -0.26, pr[1] - pr[0] + 0.02, 0.55, 0.05)
		col("#6a3a1e")
		for xx in [pr[0], pr[1] - 0.05]:
			if xx > 0.01 and xx < LN - 0.06:
				bx(G, "vcolor", xx, 0.55, -0.25, 0.05, 2.45, 0.05)
		bb.cur_color = Color.WHITE
	# the plank lintel and the steel angle under it
	bx(G, "f26_planks", 0.5, 3.0, -0.2, 8.1, 0.4, 0.2)
	col("#6a3a1e")
	bx(G, "vcolor", 0.5, 2.95, -0.24, 8.1, 0.05, 0.06)
	bb.cur_color = Color.WHITE
	# the two windows, black framed, on brick sills
	for w in [[0.5, 2.4], [6.8, 8.6]]:
		bx(G, "f26_brick", w[0], 0.0, -0.1, w[1] - w[0], 0.45, 0.1)
		glazing(w[0], w[1], 2.95, "#1a1a1a", 0.45, "#1a1a1a", 0.0, 0.04, -0.06)
	# the entry: the half-raised shutter (slats, graffiti wash) with the sign spec over it
	front_q(G, "f26_shutter", 3.0, 6.2, 1.95, 2.95, -0.08)
	col("#1a1a1a")
	bx(G, "vcolor", 3.0, 2.95, -0.18, 3.2, 0.05, 0.12)
	bx(G, "vcolor", 3.0, 1.9, -0.1, 3.2, 0.06, 0.06)
	bb.cur_color = Color.WHITE
	S26.build(bb, G + "_sg26", "SPENCER'S", P(4.6, 2.45, -0.15), nn, 2.9, 1.0)
	# the "enter" banner on the second window's right pier: yellow with dark chevrons
	cbx("#f2c81e", 8.62, 1.3, -0.25, 0.34, 1.5, 0.02)
	for k in 4:
		cbx("#1a1a1a", 8.7, 1.45 + k * 0.33, -0.255, 0.18, 0.08, 0.01, GS)
	# the rusty bracket on the solid wall
	col("#7a4220")
	bx(GS, "vcolor", 9.6, 2.4, -0.26, 1.6, 0.06, 0.04)
	bx(GS, "vcolor", 11.15, 1.6, -0.26, 0.06, 0.86, 0.04)
	bb.cur_color = Color.WHITE
	poster_stand(2.7, -0.55, 0, 1)
	poster_stand(6.5, -0.55, 1, 0)
	# the lit vending machine just inside the entry
	cbx("#141414", 3.2, 0.0, 0.15, 0.7, 1.75, 0.55)
	front_q(GD, "f26_posters_lit", 3.25, 3.85, 0.7, 1.65, 0.14, 0.0, 0.0, 0.25, 1.0, true)
	# inside: tee walls on both sides and the back, two gondolas of novelties, hanging tees
	var rng = RandomNumberGenerator.new()
	rng.seed = 35
	side_merch("f26_tees_dark", 0.02, 1.0, 1.0, 9.0, 0.3, 2.9, 3.6, 0.9)
	side_merch("f26_tees_dark", LN - 0.02, -1.0, 1.0, 9.0, 0.3, 2.9, 3.6, 0.9)
	back_merch("f26_tees_dark", 0.3, LN - 0.3, 9.0, 0.3, 2.9, 3.6, 0.9)
	for g2 in [[4.5, 4.5], [7.5, 6.0]]:
		cbx("#1c1c1e", g2[0] - 0.9, 0.0, g2[1] - 0.4, 1.8, 1.4, 0.8)
		goods(g2[0], g2[1], 1.7, 0.7, 1.4, ["#e8302a", "#f2c81e", "#30c8e8", "#a040e0", "#f0f0f0", "#202020"], rng, 0.18, 0.3)
		goods(g2[0], g2[1] - 0.41, 1.7, 0.02, 0.4, ["#e8302a", "#f2c81e", "#30c8e8", "#a040e0"], rng, 0.2, 0.9)
	for k in 3:
		var l = bb.add_omni(P(2.0 + k * 4.0, 2.6, 4.0), 0.3, 4.0, [Color(0.9, 0.3, 0.6), Color(0.4, 0.4, 1.0), Color(0.9, 0.2, 0.3)][k])
		bb.tag(l, "", 0.25, 0.3)
	ob_room(9.0)

## Great American Cookies (6 m, open front): the cookie case module (tools/stores/gac/case.gd),
## the same case in both years; 2026: the red soffit band with downlights, the white wave wall
## with the blue script on the left, the ice-cream cabinet and the red back counter with drink
## machines under menu screens (IMG_4439 f013, the sign crop).
static func gac(sd, e):
	GAC.build_2026(bb, G, a0, tt, nn, LN, FLIP)
	bb.sign_2026(G, sd.name, a0 + tt * (LN * 0.5), nn, tt, LN)
	ob_room(6.0)

## Lids (6 m): navy fascia from 2.8 m, navy piers, a glass window on the right with cap shelves
## behind it, the entry on the left; inside cap walls all round, light wood floor, white ceiling,
## two cap tables, the counter at the back (IMG_4439 f005, IMG_4438).
static func lids(sd, e):
	room(7.0, "#2a3046", "#c8a878", "white", 3.0)
	band(sd, "#1f2c5a", 2.8, 0.18)
	cbx("#1f2c5a", 0.0, 0.0, -0.18, 0.35, 2.8, 0.18)
	cbx("#1f2c5a", LN - 0.35, 0.0, -0.18, 0.35, 2.8, 0.18)
	cbx("#1f2c5a", 3.0, 0.0, -0.18, 0.25, 2.8, 0.18)
	glazing(3.25, LN - 0.35, 2.8, "#20242c", 0.35, "#1f2c5a", 1.2)
	# the entry's gold-tone side panel (f005, right of the door)
	cbx("#d8b850", 2.9, 0.0, 0.0, 0.1, 2.6, 0.6)
	side_merch("f26_caps", 0.02, 1.0, 0.5, 7.0, 0.3, 2.8, 1.6, 1.0)
	side_merch("f26_caps", LN - 0.02, -1.0, 0.5, 7.0, 0.3, 2.8, 1.6, 1.0)
	back_merch("f26_caps", 0.3, LN - 0.3, 7.0, 0.3, 2.8, 1.6, 1.0)
	# shelves in the window: four tiers of caps facing out
	for k in 4:
		cbx("#e8e8ea", 3.4, 0.6 + k * 0.5, 0.3, LN - 3.9, 0.02, 0.3)
		front_q(GS, "f26_caps", 3.45, LN - 0.45, 0.62 + k * 0.5, 0.98 + k * 0.5, 0.29, 0.0, k * 0.25, (LN - 3.9) / 1.6, k * 0.25 + 0.2)
	table(1.6, 3.0, 1.2, 0.8, 0.85, "#2a2a2c", "#c8a878")
	bb.quad(GS, "f26_caps", [P(1.05, 0.86, 2.65), P(2.15, 0.86, 2.65), P(2.15, 0.86, 3.35), P(1.05, 0.86, 3.35)], UP)
	cbx("#1f2c5a", 1.0, 0.0, 6.0, 4.0, 1.0, 0.6)
	ob_room(7.0)

## Journeys (6 m): the purple fascia with the lime paint-splash band, an open front with a glass
## display window on the left; the oval sign hangs over the opening (Demo 43 spec, ws/g scale);
## inside olive-green slatwall walls of shoes and boots, a red-brick accent at the back left, grey
## slate-look floor, a black open ceiling with a corrugated steel soffit, two honey-oak tables
## on casters with boots at the entry, galvanised chairs, green display towers out front (IMG_4440
## f012-f019, full/journeys f005-f017).
static func journeys(sd, e):
	room(8.0, "#5a6a3a", "#5c6266", "black", 3.4)
	band(sd, "#4b3d8f", 3.2, 0.16)
	front_q(G, "f26_splash", 0.0, LN, 3.25, 3.9, -0.165)
	cbx("#3a2e70", 0.0, 0.0, -0.16, 0.3, 3.2, 0.16)
	cbx("#3a2e70", LN - 0.3, 0.0, -0.16, 0.3, 3.2, 0.16)
	glazing(0.3, 2.2, 3.2, "#2a2a2c", 0.3, "#2a2a2c", 0.0)
	var lk = {"kinds": ["boot", "boot", "trainer", "casual"], "cols": ["#c8902a", "#1c1c20", "#f4f4f2", "#7a4a2a", "#c83a5a", "#e8c8a8", "#2a3a6a"],
		"trim": ["#2a2a2c", "#c8902a"], "seed": 45}
	var rng = RandomNumberGenerator.new()
	rng.seed = 45
	shoe_wall("L", 0.6, 7.6, lk, rng, "#6a7a44")
	shoe_wall("R", 0.6, 7.6, lk, rng, "#6a7a44")
	front_t(G, "f26_brick", 0.05, 2.6, 0.0, 3.4, 7.96, 0.9, 0.6)
	# corrugated steel soffit with a lit cove down the middle
	col("#9aa0a4")
	bx(G, "vcolor", 1.6, 3.0, 1.0, LN - 3.2, 0.06, 6.5)
	col("#fff2d8")
	bx(GD, "f26_glow", 1.7, 2.98, 1.0, LN - 3.4, 0.02, 6.5, [], true)
	bb.cur_color = Color.WHITE
	for tb in [[1.6, 1.4], [4.0, 2.0]]:
		table(tb[0], tb[1], 1.0, 0.6, 0.9, "#a86a2a", "#c89050")
		for k in 3:
			SH.shoe(bb, P(tb[0] - 0.3 + k * 0.3, 0.9, tb[1]), (P(1, 0, 0) - P(0, 0, 0)), nn, lk, rng, 0.3)
	for c in [[2.4, 4.5], [3.6, 4.6], [3.0, 5.4]]:
		cbx("#a8acb0", c[0] - 0.2, 0.0, c[1] - 0.2, 0.4, 0.45, 0.4, GS)
	# the green display tower just outside (f005)
	col("#3a9a3a")
	bb.cyl(GS, "vcolor", P(2.6, 0, -0.5), 0.25, 0.25, 0.08, 8, true, false)
	bb.cyl(GS, "vcolor", P(2.6, 0, -0.5), 0.03, 0.03, 1.6, 6, false, false)
	col("#6aa0d8")
	for k in 3:
		bb.cyl(GS, "vcolor", P(2.6, 0.5 + k * 0.45, -0.5), 0.26, 0.26, 0.02, 12, true, true)
	bb.cur_color = Color.WHITE
	K.ob(bb, P(2.3, 0, -0.8), P(2.9, 0, -0.2), 0.02)
	ob_room(8.0)

## Claire's (s29, the double end cap on the Shoe Dept court's corner, four frontage edges): white
## fascia with a silver crumpled-metal trim band, all-glass storefronts in white mullions that wrap
## the corner; purple/pink inside: accessory walls, earring spinners, a piercing chair, plush
## (IMG_4484 f007-f011, IMG_4492 f017).
static func claires(sd, e):
	rect_room("CLAIRE'S", "#f2e6f2", "#ece8ec", 3.0, "f26_accessories", 1.2, 1.2)
	band(sd, "#f6f4f4", 3.0, 0.14, "vcolor_matte", LN >= 7.5)
	front_t(G, "f26_crumple", 0.0, LN, 3.0, 3.18, -0.145, 0.6, 0.6)
	glazing(0.0, LN, 3.0, "#f2f2f2", 0.3, "#f2f2f2", 1.25)
	# spinners and a table of plush just inside each glass run
	var rng = RandomNumberGenerator.new()
	rng.seed = int(LN * 10.0)
	var x = 1.0
	while x < LN - 0.8:
		col("#c8c8cc")
		bb.cyl(GS, "vcolor", P(x, 0, 1.2), 0.03, 0.03, 1.6, 6, false, false)
		for k in 3:
			col(["#e878b8", "#b080e0", "#f8f8f8"][k])
			bb.cyl(GS, "vcolor", P(x, 0.6 + k * 0.38, 1.2), 0.22, 0.18, 0.3, 10, true, true)
		x += 2.4
	bb.cur_color = Color.WHITE
	if LN >= 8.0:
		table(LN * 0.5, 2.6, 1.4, 0.8, 0.8, "#f4f4f4", "#f4c8e0")
		goods(LN * 0.5, 2.6, 1.3, 0.7, 0.8, ["#f080c0", "#c090f0", "#f8f8f8", "#80d0f0"], rng, 0.14, 0.18)

## The Billiard Room (s13, the old Woolworth, 32 m on the Shoe Dept court): a glossy black fascia
## with the gold serif sign on its black panel, frameless black-edged glass both sides of an open
## entry with a black faux-marble square column; inside blue-felt pool tables under pendant lights,
## grey concrete floor, a black ceiling, APL banners and dart boards on the walls (IMG_4484 f013-f016,
## IMG_4492 f020, refs/new/woolworth_corner). The 1995 Woolworth interior is workstream D's; this is
## only the 2026 front and the first 10 m behind it.
static func billiard(sd, e):
	room(10.0, "#1c1c1e", "#7a7874", "black", 3.4, 0.8)
	band(sd, "#0e0e10", 3.2, 0.18, "f26_gloss")
	var c = LN * 0.5
	glazing(0.0, c - 2.2, 3.2, "#111111", 0.0, "", 0.0, 0.03)
	glazing(c + 2.2, LN, 3.2, "#111111", 0.0, "", 0.0, 0.03)
	cbx("#111111", c - 2.3, 0.0, -0.1, 0.1, 3.2, 0.1)
	cbx("#111111", c + 2.2, 0.0, -0.1, 0.1, 3.2, 0.1)
	bx(G, "f26_marble", c - 0.25, 0.0, -0.05, 0.5, 3.2, 0.5)
	# APL banners behind the glass on the left, dart lanes with toe lines
	for k in 3:
		front_q(G, "f26_banners", 1.0 + k * 1.6, 2.3 + k * 1.6, 1.0, 2.4, 0.6, (k % 2) * 0.5, 0.0, (k % 2) * 0.5 + 0.5, 1.0)
	for k in 3:
		cbx("#e8e8e8", 1.2 + k * 1.6, 0.003, 2.6, 0.9, 0.006, 0.05, GS)
	# pool tables
	var x = 3.0
	var k2 = 0
	while x < LN - 2.0:
		pool_table(x, 5.5 if k2 % 2 == 0 else 7.6)
		x += 3.2
		k2 += 1
	ob_room(10.0)

static func pool_table(x, d):
	cbx("#2a1a12", x - 1.3, 0.62, d - 0.72, 2.6, 0.18, 1.44)
	bb.quad(G, "f26_felt", [P(x - 1.15, 0.805, d - 0.57), P(x + 1.15, 0.805, d - 0.57), P(x + 1.15, 0.805, d + 0.57), P(x - 1.15, 0.805, d + 0.57)], UP)
	for q in [[-1.1, -0.55], [1.1, -0.55], [-1.1, 0.55], [1.1, 0.55]]:
		cbx("#2a1a12", x + q[0] - 0.08, 0.0, d + q[1] - 0.08, 0.16, 0.62, 0.16)
	col("#1a1a1a")
	bb.cyl(GS, "vcolor", P(x, 2.4, d), 0.01, 0.01, 1.0, 4, false, false)
	bx(GS, "vcolor", x - 0.9, 2.3, d - 0.15, 1.8, 0.12, 0.3)
	col("#fff0d0")
	bx(GD, "f26_glow", x - 0.85, 2.28, d - 0.12, 1.7, 0.02, 0.24, [], true)
	bb.cur_color = Color.WHITE
	var l = bb.add_spot(P(x, 2.25, d), Vector3.DOWN, 1.0, 3.5, 70.0, Color(1.0, 0.95, 0.85))
	bb.tag(l, "", 0.9, 1.0)

## DJS Jewelers (s8, Gumballs' old corner, two edges): black fascia with the gold letters, tall
## olive-brown panel pilasters on a travertine base, the open front between; inside warm walls,
## a U of lit glass jewellery cases, a pendant lantern, framed portrait posters, stanchions (IMG_4438
## f014, IMG_4477).
static func djs(sd, e):
	rect_room("DJS JEWELERS", "#6a5038", "#d8cbb4", 3.2, "", 1.0, 1.0)
	band(sd, "#121212", 3.2, 0.16)
	var npan = max(2, int(LN / 2.4))
	for k in npan + 1:
		var x = LN * k / npan
		x = clamp(x - 0.25, 0.0, LN - 0.5)
		bx(G, "f26_travertine", x, 0.0, -0.18, 0.5, 0.5, 0.18)
		cbx("#5a4a2e", x, 0.5, -0.16, 0.5, 2.7, 0.16)
	if LN >= 11.0:
		# the cases, once (on the long east edge)
		for k in 3:
			showcase(2.5 + k * 2.6, 3.0, 2.2, 0.6, "#1a1a1a", "f26_jewelry")
		showcase(1.2, 5.0, 0.6, 2.2, "#1a1a1a", "f26_jewelry")
		showcase(LN - 1.2, 5.0, 0.6, 2.2, "#1a1a1a", "f26_jewelry")
		for k in 3:
			front_q(G, "f26_posters", 2.5 + k * 2.6, 3.6 + k * 2.6, 1.2, 2.6, 9.95, 0.25, 0.0, 0.5, 1.0)
		col("#b08a3a")
		bb.cyl(GS, "vcolor", P(LN * 0.5, 2.3, 4.5), 0.3, 0.25, 0.5, 8, true, true)
		bb.cur_color = Color.WHITE
		var l = bb.add_omni(P(LN * 0.5, 2.2, 4.5), 0.4, 4.0, Color(1.0, 0.85, 0.6))
		bb.tag(l, "", 0.35, 0.4)
		for s in [[1.5, 1.0], [3.0, 1.0]]:
			col("#c8a040")
			bb.cyl(GS, "vcolor", P(s[0], 0, s[1]), 0.02, 0.02, 0.95, 6, true, false)
			bb.cyl(GS, "vcolor", P(s[0], 0, s[1]), 0.15, 0.15, 0.03, 10, true, false)
		col("#6a1a1a")
		bx(GS, "vcolor", 1.5, 0.85, 0.99, 1.5, 0.03, 0.03)
		bb.cur_color = Color.WHITE

## Foot Locker (n34, 6 m): the brushed-metal fascia with red letters (Demo 43 spec), a glass front
## with the entry in the middle; inside black walls with white-lit shelves of trainers, a
## referee-stripe header, a pale wood floor, benches (brand look; the footage only shows the front).
static func footlocker(sd, e):
	room(8.0, "#1a1a1c", "#c8b090", "white", 3.2)
	band(sd, "#a8acb0", 3.2, 0.16, "f26_brushed")
	glazing(0.2, 2.0, 3.2, "#2a2a2c", 0.3, "#2a2a2c", 0.0)
	glazing(LN - 2.0, LN - 0.2, 3.2, "#2a2a2c", 0.3, "#2a2a2c", 0.0)
	var lk = {"kinds": ["trainer", "trainer", "trainer", "casual"], "cols": ["#f4f4f2", "#1c1c20", "#c8202c", "#1f3f8f", "#f2c81e", "#8a8a90"],
		"trim": ["#1c1c20", "#f4f4f2"], "seed": 34}
	var rng = RandomNumberGenerator.new()
	rng.seed = 34
	shoe_wall("L", 0.6, 7.7, lk, rng, "#1a1a1c")
	shoe_wall("R", 0.6, 7.7, lk, rng, "#1a1a1c")
	shoe_wall("B", 0.0, 7.95, lk, rng, "#1a1a1c")
	front_q(G, "f26_ref", 0.05, LN - 0.05, 2.7, 3.0, 7.9, 0.0, 0.0, LN / 0.6, 1.0)
	SH.bench(bb, G, P(LN * 0.5, 0, 4.0), (P(1, 0, 0) - P(0, 0, 0)), -nn, 2.0, Color("#1a1a1c"))
	ob_room(8.0)

## Aéropostale (s10a, 10 m): a black riveted-steel grid portal with the red letters, an open
## centre with glass both sides; inside white walls of face-out tops, tables of folded tees and
## hoodies, a pale wood floor, white lay-in ceiling (IMG_4476-4483, IMG_4492 f009).
static func aero(sd, e):
	room(9.0, "#f2f2f0", "#c8a87a", "white", 3.2)
	band(sd, "#151515", 3.2, 0.16)
	steel_grid(0.0, LN, 3.2)
	glazing(0.4, 3.0, 3.1, "#151515", 0.3, "#151515", 0.0)
	glazing(LN - 3.0, LN - 0.4, 3.1, "#151515", 0.3, "#151515", 0.0)
	apparel_inside(9.0, 10, ["#1f2c5a", "#c8202c", "#f2f2f0", "#8a8a90", "#2a6a3a"])
	front_q(G, "f26_posters_lit", 0.8, 1.6, 1.0, 2.6, 0.25, 0.5, 0.0, 0.75, 1.0)

## Rainbow (s10, 10 m): white beadboard facade with the blue script (Demo 43 spec), sky-blue door
## frames at two entries, two display windows with mannequins; inside pinks and brights on racks
## (IMG_4482, IMG_4492 f003).
static func rainbow(sd, e):
	room(9.0, "#f6eef2", "#d8d0c8", "white", 3.2)
	band(sd, "#f4f3ee", 3.2, 0.16)
	front_t(G, "f26_beadboard", 0.0, LN, 3.2, bb.LANE_H, -0.165, 0.4, 0.4)
	for sq in [[0.0, 0.68], [2.72, 2.9], [6.1, 6.28], [8.32, 8.5], [9.6, LN]]:
		front_t(G, "f26_beadboard", sq[0], sq[1], 0.0, 2.8, -0.141, 0.4, 0.4)
	front_t(G, "f26_beadboard", 0.0, LN, 2.8, 3.2, -0.141, 0.4, 0.4)
	# the white wall carries the openings: entries at x 0.8-2.6 and 6.4-8.2, windows between
	for w in [[2.9, 6.1], [8.5, 9.6]]:
		glazing(w[0], w[1], 2.8, "#f4f3ee", 0.5, "#f4f3ee", 0.0, 0.05, -0.14)
	for en in [[0.8, 2.6], [6.4, 8.2]]:
		col("#5aaee8")
		bx(G, "vcolor", en[0] - 0.12, 0.0, -0.2, 0.12, 2.9, 0.08)
		bx(G, "vcolor", en[1], 0.0, -0.2, 0.12, 2.9, 0.08)
		bx(G, "vcolor", en[0] - 0.12, 2.8, -0.2, en[1] - en[0] + 0.24, 0.12, 0.08)
		bb.cur_color = Color.WHITE
	# the wall's back face (the room starts behind it) where it is not glass or an entry
	col("#f4f3ee")
	for s in [[0.0, 0.68], [2.72, 2.9], [6.1, 6.28], [8.32, 8.5], [9.6, LN]]:
		bx(G, "vcolor_matte", s[0], 0.0, -0.14, s[1] - s[0], 3.2, 0.12)
	bx(G, "vcolor_matte", 0.0, 2.8, -0.14, LN, 0.4, 0.12)
	bb.cur_color = Color.WHITE
	for m in [[3.8, 0.6], [5.2, 0.6], [9.05, 0.6]]:
		AK.mannequin(bb, P(m[0], 0, m[1]), nn, ["#f080b0", "#5aaee8", "#f2c81e"][int(m[0]) % 3], "#2a3a6a")
	apparel_inside(9.0, 11, ["#f080b0", "#5aaee8", "#f2c81e", "#f2f2f0", "#c070e0"], 1.6)

## Bath & Body Works (s62, 8 m): the blue/white gingham surround framing a recessed white portal
## with the sign over the opening (Demo 43 spec); inside white tables and wall shelves of pastel
## bottles under bright light, white floor (IMG_4440 f009).
static func bbw(sd, e):
	room(8.0, "#f8f6f2", "#e8e4dc", "white", 3.3, 1.3)
	for gq in [[0.0, 1.0, 0.0, 3.3], [LN - 1.0, LN, 0.0, 3.3], [0.0, LN, 3.3, bb.LANE_H]]:
		front_t(G, "f26_gingham", gq[0], gq[1], gq[2], gq[3], -0.3, 0.4, 0.4)
	# the gingham is the surround: the portal is cut through it (x 1.2..LN-1.2, up to 3.4)
	col("#f6f6f4")
	bx(G, "vcolor_matte", 1.0, 3.3, -0.3, LN - 2.0, 0.9, 0.06)
	bb.cur_color = Color.WHITE
	bb.sign_2026(G + "_bbw", sd.name, a0 + tt * (LN * 0.5) + nn * 0.14 - UP * 0.15, nn, tt, LN - 2.0)
	_gingham_cut(1.2, LN - 1.2, 3.3)
	side_merch("f26_bottles", 0.02, 1.0, 0.5, 8.0, 0.3, 2.3, 1.2, 1.0)
	side_merch("f26_bottles", LN - 0.02, -1.0, 0.5, 8.0, 0.3, 2.3, 1.2, 1.0)
	back_merch("f26_bottles", 0.3, LN - 0.3, 8.0, 0.3, 2.3, 1.2, 1.0)
	var rng = RandomNumberGenerator.new()
	rng.seed = 62
	for t2 in [[LN * 0.5, 1.6], [LN * 0.5 - 1.6, 3.6], [LN * 0.5 + 1.6, 3.6], [LN * 0.5, 5.6]]:
		table(t2[0], t2[1], 1.3, 0.8, 0.8, "#f4f4f2", "#ffffff")
		goods(t2[0], t2[1], 1.2, 0.7, 0.8, ["#f0a0c0", "#a8d0f0", "#f8dc96", "#c8aae6", "#a0dcb4", "#ffffff"], rng, 0.08, 0.2)
	ob_room(8.0)

## The gingham panel is one quad: blank out the portal with the room seen through it by covering
## its edges (the reveal) — the quad stays behind the portal's white reveal frame.
static func _gingham_cut(x0, x1, y1):
	col("#f6f6f4")
	bx(G, "vcolor", x0 - 0.1, 0.0, -0.32, 0.1, y1, 0.32)
	bx(G, "vcolor", x1, 0.0, -0.32, 0.1, y1, 0.32)
	bx(G, "vcolor", x0 - 0.1, y1, -0.32, x1 - x0 + 0.2, 0.1, 0.32)
	bb.cur_color = Color.WHITE

## Cakelicious (n39, Gold 'n Gifts + Babbage's merged, the court corner with a clipped face):
## salmon fascia with the yellow script (Demo 43 spec), white Tuscan columns, a glass front;
## inside a lit cake case, a pink menu board, bistro tables (IMG_4459 f011, IMG_4461).
static func cake(sd, e):
	rect_room("CAKELICIOUS", "#fbeef0", "#ece2dc", 3.2, "", 1.0, 1.0)
	band(sd, "#e88a7a", 3.2, 0.16)
	glazing(0.4, LN - 0.4, 3.2, "#f4f4f4", 0.4, "#e88a7a", 1.8)
	for x in [0.0, LN - 0.4]:
		tuscan(x + 0.2, -0.2)
	if LN < 7.0:
		showcase(LN * 0.5, 2.2, LN - 1.6, 0.7, "#f4f4f4", "f26_cakes", 1.2, 0.5)
		front_q(G, "f26_cakes", LN * 0.5 - (LN - 1.6) * 0.5 + 0.03, LN * 0.5 + (LN - 1.6) * 0.5 - 0.03, 0.72, 1.18, 1.849, 0.0, 0.0, 1.0, 1.0)
		front_q(G, "f26_menus", LN * 0.5 - 0.6, LN * 0.5 + 0.6, 1.9, 2.6, 5.6, 0.5, 0.0, 0.75, 1.0)
	else:
		for t2 in [[2.5, 2.0], [5.0, 2.4]]:
			col("#f4f4f4")
			bb.cyl(GS, "vcolor", P(t2[0], 0.72, t2[1]), 0.35, 0.35, 0.03, 14, true, true)
			col("#2a2a2a")
			bb.cyl(GS, "vcolor", P(t2[0], 0, t2[1]), 0.03, 0.03, 0.72, 6, false, false)
		bb.cur_color = Color.WHITE

static func tuscan(x, d):
	var c = P(x, 0, d)
	bb.box(G, "f26_white", c + UP * 0.07, Vector3(0.36, 0.14, 0.36))
	bb.cyl(G, "f26_white", c + UP * 0.14, 0.15, 0.13, 2.9, 16, false, false)
	bb.cyl(G, "f26_white", c + UP * 3.04, 0.13, 0.17, 0.08, 16, true, true)
	bb.box(G, "f26_white", c + UP * 3.15, Vector3(0.38, 0.1, 0.38))

## Auntie Anne's (n56, 4 m, the counter stall west of Cell Xpert): navy fascia with the sign
## (Demo 43 spec), an open counter front: a wood-look counter with the pretzel warmer on it, white
## and orange inside, a menu board, an oven and the rolling table behind (IMG_4439 f024-f025).
static func auntie(sd, e):
	room(4.0, "#f4f2ec", "#c8bca8", "white", 3.0, 1.2)
	band(sd, "#1f2c6a", 3.0, 0.16)
	cbx("#1f2c6a", 0.0, 0.0, -0.16, 0.2, 3.0, 0.16)
	cbx("#1f2c6a", LN - 0.2, 0.0, -0.16, 0.2, 3.0, 0.16)
	cbx("#c89a5a", 0.2, 0.0, 0.3, LN - 0.4, 1.0, 0.6)
	cbx("#f0ece4", 0.15, 1.0, 0.25, LN - 0.3, 0.04, 0.7)
	cbx("#e88a2a", 0.2, 0.85, 0.28, LN - 0.4, 0.06, 0.02)
	# the warmer: a lit glass box of pretzels on the counter
	cbx("#c8c8c8", 0.5, 1.04, 0.35, 1.3, 0.05, 0.5, GS)
	front_q(GD, "f26_pretzels_lit", 0.52, 1.78, 1.1, 1.6, 0.34, 0.0, 0.0, 1.0, 1.0, true)
	bx(GD, "f26_glass", 0.5, 1.09, 0.35, 1.3, 0.55, 0.5, ["-y"], true)
	front_q(G, "f26_menus", 0.6, LN - 0.6, 1.8, 2.6, 3.95, 0.25, 0.0, 0.5, 1.0)
	cbx("#b8babc", 0.5, 0.0, 3.2, 1.2, 1.6, 0.7, "", "wl_steel")
	cbx("#e8e6e0", 2.0, 0.0, 2.0, 1.4, 0.9, 0.7)
	ob_room(4.0)

## AT&T (s48, 8 m): the black graphite fascia with the globe sign (Demo 45 spec), slate-grey tile
## pilasters, a glass front with the entry on the left; inside grey carpet tile, white wall bays of
## phones, a big lit poster on the left wall, round white tables with phones, a counter at the
## back, a dark open ceiling with track lights (IMG_4442 f008, notes in y26/parts/att.json).
static func att(sd, e):
	room(9.0, "#e8e8e6", "#6a6c70", "black", 3.4, 1.1)
	band(sd, "#222525", 3.2, 0.16, "f26_gloss")
	cbx("#4a4e52", 0.0, 0.0, -0.16, 0.4, 3.2, 0.16)
	cbx("#4a4e52", LN - 0.4, 0.0, -0.16, 0.4, 3.2, 0.16)
	glazing(2.6, LN - 0.4, 3.2, "#1c1c1c", 0.3, "#1c1c1c", 1.8)
	side_q(GD, "f26_phone_poster", 0.05, 1.0, 4.0, 0.6, 2.8, 1.0, 0.0, 0.0, 1.0, 1.0, true)
	for k in 3:
		cbx("#f4f4f4", 0.05, 0.9, 4.5 + k * 1.4, 0.4, 1.4, 1.2)
		phones_row(0.5, 4.6 + k * 1.4, 1.0, 1.25, 4)
		cbx("#f4f4f4", LN - 0.45, 0.9, 1.5 + k * 1.8, 0.4, 1.4, 1.6)
	for t2 in [[3.6, 3.0], [5.6, 4.6]]:
		col("#f4f4f4")
		bb.cyl(GS, "vcolor", P(t2[0], 0.9, t2[1]), 0.55, 0.55, 0.04, 18, true, true)
		bb.cyl(GS, "vcolor", P(t2[0], 0, t2[1]), 0.08, 0.2, 0.9, 10, false, false)
		bb.cur_color = Color.WHITE
		for k in 4:
			var ang = k * PI * 0.5
			var p = P(t2[0], 0.95, t2[1]) + (P(1, 0, 0) - P(0, 0, 0)) * cos(ang) * 0.35 - nn * sin(ang) * 0.35
			col("#101012")
			bb.box(GS, "vcolor", p, Vector3(0.08, 0.01, 0.16))
		bb.cur_color = Color.WHITE
	cbx("#f4f4f4", 2.0, 0.0, 7.8, 4.0, 1.0, 0.6)
	ob_room(9.0)

static func phones_row(x, d, w, y, n):
	for k in n:
		col("#101012")
		bx(GS, "vcolor", x - 0.06, y, d + k * (w / n), 0.02, 0.18, 0.09)
	bb.cur_color = Color.WHITE

# ------------------------------------------------------------------ shared pieces
## A black riveted steel grid frame over the whole front (Aéropostale): verticals every 1.25 m,
## rails at 0.4 m and the head, rivet dots.
static func steel_grid(x0, x1, y1):
	col("#151515")
	var n = max(1, int(round((x1 - x0) / 1.25)))
	for k in n + 1:
		var x = x0 + (x1 - x0) * k / n
		bx(G, "vcolor", clamp(x - 0.08, x0, x1 - 0.16), 0.0, -0.2, 0.16, y1, 0.2)
	bx(G, "vcolor", x0, y1 - 0.2, -0.2, x1 - x0, 0.2, 0.2)
	col("#5a5a5c")
	for k in n + 1:
		var x = clamp(x0 + (x1 - x0) * k / n, x0 + 0.08, x1 - 0.08)
		for y in [0.3, 1.2, 2.1, 2.9]:
			bb.cyl(GS, "vcolor", P(x, y, -0.205), 0.012, 0.012, 0.01, 6, true, false)
	bb.cur_color = Color.WHITE

## A clothing store's first 9 m: face-out walls both sides, round racks, four-ways and tables.
static func apparel_inside(D, seed, cols, d0 = 1.2):
	var rng = RandomNumberGenerator.new()
	rng.seed = seed
	side_merch("f26_tees", 0.02, 1.0, d0, D, 0.3, 2.6, 3.84, 0.96)
	side_merch("f26_tees", LN - 0.02, -1.0, d0, D, 0.3, 2.6, 3.84, 0.96)
	back_merch("f26_tees", 0.3, LN - 0.3, D, 0.3, 2.6, 3.84, 0.96)
	for t2 in [[LN * 0.5 - 1.6, 2.4], [LN * 0.5 + 1.6, 2.4]]:
		table(t2[0], t2[1], 1.4, 0.8, 0.8, "#f2f2f0", "#c8a87a")
		goods(t2[0], t2[1], 1.3, 0.7, 0.8, cols, rng, 0.28, 0.14)
	AK.round_rack(bb, P(LN * 0.5, 0, 4.6), 0.55, rng.randi_range(0, 3))
	AK.fourway(bb, P(LN * 0.5 - 2.2, 0, 6.4), 0.4, rng.randi_range(0, 3))
	AK.fourway(bb, P(LN * 0.5 + 2.2, 0, 6.4), -0.4, rng.randi_range(0, 3))
	ob_room(D)

## The room of a multi-edge store (ROOMS), built once per build: floor and lay-in ceiling over the
## outline (a fan from "c"), its non-frontage walls facing in with the merchandise texture `wm`.
static func rect_room(name, wall_c, floor_c, ceil_y, wm, tw, th):
	if done_rooms.get(name, -1) == bb.get_instance_id():
		return
	done_rooms[name] = bb.get_instance_id()
	var R = ROOMS[name]
	var c = Vector3(R.c[0], 0, R.c[1])
	var pts = []
	for q in R.poly:
		pts.append(Vector3(q[0], 0, q[1]))
	var sf = bb.st(G, "vcolor")
	var sc = bb.st(G, "kb_ceiling")
	for i in pts.size():
		var A = pts[i]
		var B = pts[(i + 1) % pts.size()]
		col(floor_c)
		bb.tri(sf, c + UP * 0.003, A + UP * 0.003, B + UP * 0.003, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, UP)
		bb.cur_color = Color.WHITE
		var cy = UP * ceil_y
		bb.tri(sc, c + cy, A + cy, B + cy, Vector2(c.x / 0.61, c.z / 1.22), Vector2(A.x / 0.61, A.z / 1.22), Vector2(B.x / 0.61, B.z / 1.22), Vector3.DOWN)
	for w in R.walls:
		var A = Vector3(w[0][0], 0, w[0][1])
		var B = Vector3(w[1][0], 0, w[1][1])
		var dir = (B - A).normalized()
		var inward = dir.cross(UP)
		if inward.dot(c - A) < 0.0:
			inward = -inward
		var A2 = A + inward * 0.02
		var B2 = B + inward * 0.02
		col(wall_c)
		bb.quad(G, "vcolor_matte", [A2, B2, B2 + UP * ceil_y, A2 + UP * ceil_y], inward)
		bb.cur_color = Color.WHITE
		if wm != "":
			var L2 = (B - A).length()
			var o = inward * 0.01
			bb.quad(G, wm, [A2 + o + UP * 0.3, B2 + o + UP * 0.3, B2 + o + UP * 2.6, A2 + o + UP * 2.6], inward,
				[Vector2(0, 2.3 / th), Vector2(L2 / tw, 2.3 / th), Vector2(L2 / tw, 0), Vector2(0, 0)])
	var l = bb.add_omni(c + UP * (ceil_y - 0.5), 0.6, 9.0, Color(1.0, 0.96, 0.9))
	bb.tag(l, "", 0.5, 0.6)
	var mn = pts[0]
	var mx = pts[0]
	for p in pts:
		mn = Vector3(min(mn.x, p.x), 0, min(mn.z, p.z))
		mx = Vector3(max(mx.x, p.x), 0, max(mx.z, p.z))
	K.ob(bb, mn, mx, 0.0)

# ------------------------------------------------------------------ materials
## "f26_<key>" (build_mall.gd's mat() calls this).
static func fill_mat(m, key, b):
	match key:
		"brick", "concrete", "planks", "beadboard", "wave", "crumple", "travertine", "gingham":
			m.albedo_texture = b.tex("f26/%s.png" % key); m.roughness = 0.85 if key != "crumple" else 0.35
			if key == "crumple":
				m.metallic = 0.6
			if key in ["brick", "concrete", "planks", "travertine"]:
				m.uv1_triplanar = true
				var s = {"brick": Vector3(1.0 / 0.9, 1.0 / 0.6, 1.0 / 0.9), "concrete": Vector3(0.5, 0.5, 0.5), "planks": Vector3(1.0 / 1.2, 1.0 / 0.6, 1.0 / 1.2), "travertine": Vector3(0.8, 0.8, 0.8)}[key]
				m.uv1_scale = s
		"tees", "tees_dark", "caps", "bottles", "accessories", "jewelry", "cakes", "menus", "posters", "felt", "banners", "shutter", "cookies", "cookie_cakes":
			m.albedo_texture = b.tex("f26/%s.png" % key); m.roughness = 0.6
		"posters_lit":
			m.albedo_texture = b.tex("f26/posters.png"); m.roughness = 0.4
			K.emit_tex(m, 0.8)
		"pretzels_lit":
			m.albedo_texture = b.tex("f26/pretzels.png"); m.roughness = 0.4
			K.emit_tex(m, 0.7)
		"phone_poster":
			m.albedo_texture = b.tex("f26/menus.png"); m.roughness = 0.4
			m.uv1_scale = Vector3(0.25, 1, 1); m.uv1_offset = Vector3(0.75, 0, 0)
			K.emit_tex(m, 0.8)
		"splash":
			m.albedo_color = Color("#8cc63a"); m.roughness = 0.8
		"ref":
			m.albedo_texture = b.tex("f26/ref.png"); m.roughness = 0.5
		"glass":
			m.albedo_color = Color(0.86, 0.92, 0.94, 0.18); m.roughness = 0.05; m.metallic_specular = 0.9
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		"glow":
			m.albedo_color = Color("#fff4e0")
			K.emit(m, Color("#fff0d8"), 1.6)
		"gloss":
			m.albedo_color = Color("#141416"); m.roughness = 0.12; m.metallic_specular = 0.8
		"brushed":
			m.albedo_color = Color("#b0b4b8"); m.metallic = 0.7; m.roughness = 0.35
		"marble":
			m.albedo_color = Color("#1a1a1c"); m.roughness = 0.15; m.metallic_specular = 0.8
		"white":
			m.albedo_color = Color("#f2f0ea"); m.roughness = 0.5
		_:
			return false
	return true
