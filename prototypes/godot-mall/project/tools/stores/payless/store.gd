## Payless ShoeSource, walk-in (1995 map, store s4: 16 m on the Dillard's court's east side at x = 2, the
## store running 28 m east to x = 30; wing 2). ws/interiors, Nov 4 2026. design/storefronts/payless.md.
##
## Steven (voice note, Nov 3): "that's from a going out of business, 2019 I think, but just remove all of
## going out of business stuff, but the layout ... that's exactly what it looked like, the shoes and all
## that stuff." From refs/new/payless (payless2019_t000_NNN, 0.5 fps): a wood-look plank floor in the
## front zone (001-009, 189, 307) with white display tables of single shoes (005, 189), long double-sided
## gondolas of sloped shelves of open shoe boxes running from the front to the back (017-047, 121, 237,
## 303-305) over a grey-brown loop carpet, white slatwall end caps of socks and hosiery facing the
## front aisle (005, 237), the same sloped box shelving round the walls, small upholstered try-on
## benches in the aisles (305) with orange oval try-on mats (177, 183), the bags and backpacks wall at
## the front (219-289). The sale signs, price cards and the 2019 goods are left out (phone chargers,
## licensed plush), the goods are invented (paint.py).
##
## Called from tools/stores/fronts26/store.gd payless_inside() (build_mall.gd interior()), whose frame
## it uses: x 0..LN (16) left to right as seen from the court, d into the store, y up. Walk-in: the
## tiles x 149-161, y 125-132 are opened (tools/open_interiors.py); every fixture is an obstacle.
## Materials "in_pay_<key>", textures tex/pay/.

const K = preload("res://tools/stores/media/kit.gd")
const SH = preload("res://tools/stores/small/shoes.gd")
const UP = Vector3.UP
const D = 26.0          # the sales floor's back wall (the stock room behind it, to the unit's 28 m)
const CY = 3.2          # the lay-in ceiling
const FZ = 4.6          # the front zone: wood-look floor, tables, the bags wall and the counter
const GH = 1.9          # gondola and wall-shelf height
const GW = 0.92         # a gondola's depth (two sides)
const AISLE = 1.36
const LK = {"kinds": ["casual", "pump", "trainer", "loafer", "boot", "dress"], "cols": ["#1c1c20", "#5a3218", "#f4f4f2", "#8a1e2a", "#1f3f8f", "#c8a070", "#e88aa8"],
	"trim": ["#f2c81e", "#c8202c", "#1c1c20"], "seed": 4}

static var F
static var b

static func X(): return F.P(1, 0, 0) - F.P(0, 0, 0)
static func Z(): return F.P(0, 0, 1) - F.P(0, 0, 0)

static func build(F_):
	F = F_
	b = F.bb
	var LN = F.LN
	var G = F.G
	var GS = F.GS
	var rng = RandomNumberGenerator.new()
	rng.seed = 4
	# ---------------------------------------------------------------- floor, ceiling, walls
	b.quad(G, "in_pay_wood", [F.P(0, 0.003, 0), F.P(LN, 0.003, 0), F.P(LN, 0.003, FZ), F.P(0, 0.003, FZ)], UP)
	b.quad(G, "in_pay_carpet", [F.P(0, 0.003, FZ), F.P(LN, 0.003, FZ), F.P(LN, 0.003, D), F.P(0, 0.003, D)], UP)
	var cp = [F.P(0, CY, 0.0), F.P(LN, CY, 0.0), F.P(LN, CY, D), F.P(0, CY, D)]
	var cuv = []
	for p in cp:
		cuv.append(Vector2(p.x / 0.61, p.z / 1.22))
	b.quad(G, "kb_ceiling", cp, Vector3.DOWN, cuv)
	F.col("#f4f2ec")
	F.side_q(G, "vcolor_matte", 0.02, 0.0, D, 0.0, CY, 1.0)
	F.side_q(G, "vcolor_matte", LN - 0.02, 0.0, D, 0.0, CY, -1.0)
	b.quad(G, "vcolor_matte", [F.P(LN, 0, D), F.P(0, 0, D), F.P(0, CY, D), F.P(LN, CY, D)], F.nn)
	b.cur_color = Color.WHITE
	# the stock-room door in the back wall, at the right
	F.cbx("#d8d4ca", LN - 2.4, 0.0, D - 0.05, 1.0, 2.15, 0.04)
	F.cbx("#9a968c", LN - 2.48, 2.15, D - 0.06, 1.16, 0.06, 0.05)
	# troffers in rows over the aisles, a light every other one
	var d2 = 1.2
	var j = 0
	while d2 + 1.22 < D - 0.3:
		var x2 = 1.4
		while x2 + 0.61 < LN - 0.8:
			var tq = [F.P(x2, CY - 0.006, d2), F.P(x2 + 0.61, CY - 0.006, d2), F.P(x2 + 0.61, CY - 0.006, d2 + 1.22), F.P(x2, CY - 0.006, d2 + 1.22)]
			b.quad(G, "gb_troffer", tq, Vector3.DOWN, [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)])
			if (j + int(x2)) % 2 == 0:
				var l = b.add_spot(F.P(x2 + 0.3, CY - 0.08, d2 + 0.61), Vector3.DOWN, 0.9, 6.0, 62.0, Color(1.0, 0.98, 0.94))
				b.tag(l, "", 0.9, 0.9)
			x2 += 3.0
		d2 += 2.44
		j += 1
	# ---------------------------------------------------------------- the walls of boxes
	# both side walls behind the front zone and the back wall, with category headers over them
	wall_run(G, GS, 0.03, FZ + 0.4, D - 0.5, 1.0, rng)
	wall_run(G, GS, LN - 0.03, FZ + 0.4, D - 0.5, -1.0, rng)
	back_run(G, GS, 0.6, LN - 2.7, D - 0.03, rng)
	for h in [[0.03, 1.0, FZ + 3.0, 0], [0.03, 1.0, FZ + 12.0, 2], [LN - 0.03, -1.0, FZ + 3.0, 1], [LN - 0.03, -1.0, FZ + 12.0, 3]]:
		F.side_q(GS, "in_pay_headers", h[0] + 0.05 * h[1], h[2], h[2] + 3.2, 2.15, 2.55, h[1], h[3] * 0.25, 0.0, h[3] * 0.25 + 0.25, 1.0, true)
	# ---------------------------------------------------------------- the gondolas
	# six double-sided runs front to back with a cross aisle in the middle; end caps of peg goods
	var n = 6
	var span = n * GW + (n + 1) * AISLE
	var x0 = (LN - span) * 0.5 + AISLE
	var runs = [[FZ + 0.6, 14.4], [15.8, D - 1.4]]
	for k in n:
		var gx = x0 + k * (GW + AISLE)
		for rr in runs:
			gondola(G, GS, gx, rr[0], rr[1], rng)
	# benches and try-on mats in the aisles
	for k in n + 1:
		var ax = x0 - AISLE * 0.5 + k * (GW + AISLE)
		if ax < 0.6 or ax > LN - 0.6:
			continue
		for bd in ([8.0, 19.5] if k % 2 == 0 else [11.5, 22.0]):
			bench(G, ax, bd)
			mat(GS, ax, bd + 0.75)
	# ---------------------------------------------------------------- the front zone
	# the bags and backpacks wall on the left, socks and shoe care on the right, the counter right
	F.side_q(G, "in_pay_bags", 0.05, 0.4, FZ + 0.3, 0.2, 2.6, 1.0, 0.0, 0.0, (FZ - 0.1) / 2.4, 1.0)
	F.side_q(G, "in_pay_pegs", LN - 0.05, 0.4, 2.4, 0.2, 2.6, -1.0, 0.0, 0.0, 2.0 / 1.2, 2.0)
	counter(G, GS, LN - 0.75, 2.6, 1.9)
	# three white display tables of single shoes, one nested pair
	for t in [[3.0, 2.2, 1.5], [6.6, 2.6, 1.8], [10.2, 2.2, 1.5]]:
		table(G, GS, t[0], t[1], t[2], rng)
	# lights for the front zone
	for x in [3.0, 8.0, 13.0]:
		var l = b.add_omni(F.P(x, CY - 0.4, 2.2), 0.5, 6.0, Color(1.0, 0.97, 0.92))
		b.tag(l, "", 0.45, 0.5)
	# obstacles: the walls of boxes, the back wall
	K.ob(b, F.P(0, 0, FZ + 0.3), F.P(0.5, 0, D), 0.05)
	K.ob(b, F.P(LN - 0.5, 0, FZ + 0.3), F.P(LN, 0, D), 0.05)
	K.ob(b, F.P(0, 0, 0.3), F.P(0.3, 0, FZ + 0.3), 0.05)
	K.ob(b, F.P(0, 0, D - 0.5), F.P(LN, 0, D), 0.05)

## Sloped shoe-box shelves along a side wall at x (facing +x if s > 0), d0..d1: seven shelves to GH.
static func wall_run(G, GS, x, d0, d1, s, rng):
	F.col("#f2f0ea")
	F.bx(G, "vcolor", x if s > 0 else x - 0.45, 0.0, d0, 0.45, 0.12, d1 - d0)
	F.side_q(G, "vcolor_matte", x + 0.01 * s, d0, d1, 0.0, GH + 0.25, s)
	b.cur_color = Color.WHITE
	shelves_side(G, GS, x, d0, d1, s, 0.45, rng)
	F.cbx("#f2f0ea", x if s > 0 else x - 0.47, GH, d0, 0.47, 0.04, d1 - d0)

## The same along the back wall, x0..x1 at depth d (facing the front).
static func back_run(G, GS, x0, x1, d, rng):
	F.cbx("#f2f0ea", x0, 0.0, d - 0.45, x1 - x0, 0.12, 0.45)
	var ux = X()
	var uz = Z()
	for k in 7:
		var y = 0.2 + k * 0.245
		var row = rng.randi_range(0, 3)
		var pa = F.P(x0, y, d - 0.44)
		var pb = F.P(x1, y, d - 0.44)
		var top = UP * 0.2 + uz * 0.34
		var flip = ux.dot((-F.nn).cross(UP)) < 0.0
		var u0 = 0.0
		var u1 = (x1 - x0) / 1.2
		if flip:
			var tmp = u0; u0 = u1; u1 = tmp
		box_rows(GS, pa, pb, top, (F.nn + UP * 0.6).normalized(), F.nn, u0, u1, row)
		F.cbx("#f6f6f4", x0, y - 0.02, d - 0.46, x1 - x0, 0.04, 0.02, GS)
	F.cbx("#f2f0ea", x0, GH, d - 0.47, x1 - x0, 0.04, 0.47)

## Sloped shelves on one side of a spine at x (the shelves standing out toward +x if s > 0), d0..d1,
## `dep` deep: each shelf a quad of open boxes leaning back to the spine and a white lip.
static func shelves_side(G, GS, x, d0, d1, s, dep, rng):
	var ux = X()
	for k in 7:
		var y = 0.2 + k * 0.245
		var row = rng.randi_range(0, 3)
		var front = x + dep * s
		var pa = F.P(front, y, d0)
		var pb = F.P(front, y, d1)
		var top = UP * 0.2 - ux * (s * (dep - 0.08))
		var nrm = (ux * s + UP * 0.6).normalized()
		# u runs to the viewer's right, (-nrm) x UP (checked by looking, Nov 4: nrm x UP mirrored the sizes)
		var flip = (pb - pa).dot((-nrm).cross(UP)) < 0.0
		var u0 = 0.0
		var u1 = (d1 - d0) / 1.2
		if flip:
			var tmp = u0; u0 = u1; u1 = tmp
		box_rows(GS, pa, pb, top, nrm, ux * s, u0, u1, row)
		F.cbx("#f6f6f4", front - (0.02 if s > 0 else 0.0), y - 0.02, d0, 0.02, 0.04, d1 - d0, GS)

## One shelf of open boxes from pa..pb (the shelf's front edge): the boxes' ends standing 9 cm up at the
## front (the size labels, texture row bottom), then the open boxes and lids leaning back along `top`.
static func box_rows(GS, pa, pb, top, nrm, out, u0, u1, row):
	var v0 = row * 0.25
	var e = UP * 0.09
	b.quad(GS, "in_pay_shelves", [pa, pb, pb + e, pa + e], out.normalized(),
		[Vector2(u0, v0 + 0.240), Vector2(u1, v0 + 0.240), Vector2(u1, v0 + 0.192), Vector2(u0, v0 + 0.192)], true)
	var t2 = top * 0.85
	b.quad(GS, "in_pay_shelves", [pa + e, pb + e, pb + e + t2, pa + e + t2], nrm,
		[Vector2(u0, v0 + 0.192), Vector2(u1, v0 + 0.192), Vector2(u1, v0 + 0.008), Vector2(u0, v0 + 0.008)], true)

## A double-sided gondola from d0 to d1 at x (its left side), with white slatwall end caps of peg
## goods at both ends.
static func gondola(G, GS, x, d0, d1, rng):
	var c = x + GW * 0.5
	F.cbx("#e8e6e0", x, 0.0, d0, GW, 0.12, d1 - d0)
	F.cbx("#f4f2ec", c - 0.03, 0.12, d0, 0.06, GH - 0.12, d1 - d0)
	shelves_side(G, GS, c - 0.03, d0, d1, -1.0, GW * 0.5 - 0.03, rng)
	shelves_side(G, GS, c + 0.03, d0, d1, 1.0, GW * 0.5 - 0.03, rng)
	F.cbx("#f2f0ea", x, GH, d0, GW, 0.04, d1 - d0)
	# end caps: slatwall panels to 2.1 m with peg goods
	for e in [[d0, -1.0], [d1, 1.0]]:
		var dd = e[0] - (0.06 if e[1] < 0 else 0.0)
		F.cbx("#f4f2ec", x - 0.02, 0.0, dd, GW + 0.04, 2.1, 0.06)
		var face = dd if e[1] < 0 else dd + 0.06
		if e[1] < 0:
			F.front_q(GS, "in_pay_pegs", x, x + GW, 0.15, 2.05, face - 0.003, 0.0, 0.0, GW / 1.2, 1.6, true)
		else:
			var nb = -F.nn
			var pa = F.P(x + GW, 0.15, face + 0.003)
			var pb = F.P(x, 0.15, face + 0.003)
			b.quad(GS, "in_pay_pegs", [pa, pb, pb + UP * 1.9, pa + UP * 1.9], nb,
				[Vector2(0, 1.6), Vector2(GW / 1.2, 1.6), Vector2(GW / 1.2, 0), Vector2(0, 0)], true)
	K.ob(b, F.P(x - 0.02, 0, d0 - 0.06), F.P(x + GW + 0.02, 0, d1 + 0.06), 0.06)

## A small upholstered try-on bench (brown seat on a dark wood base, 0.9 x 0.42), along the aisle.
static func bench(G, x, d):
	F.cbx("#3a2a20", x - 0.2, 0.0, d - 0.42, 0.4, 0.3, 0.84)
	F.cbx("#8a4a2a", x - 0.22, 0.3, d - 0.45, 0.44, 0.13, 0.9)
	K.ob(b, F.P(x - 0.22, 0, d - 0.45), F.P(x + 0.22, 0, d + 0.45), 0.04)

## The orange oval try-on mat on the floor.
static func mat(GS, x, d):
	var ux = X()
	var uz = Z()
	var c = F.P(x, 0.006, d)
	b.quad(GS, "in_pay_mat", [c - ux * 0.3 - uz * 0.18, c + ux * 0.3 - uz * 0.18, c + ux * 0.3 + uz * 0.18, c - ux * 0.3 + uz * 0.18], UP,
		[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)], true)

## The cash counter by the right wall, d0..d0+len, the register on it.
static func counter(G, GS, x, d0, ln):
	F.cbx("#f4f2ec", x - 0.3, 0.0, d0, 0.6, 0.95, ln)
	F.cbx("#c8202c", x - 0.31, 0.6, d0, 0.01, 0.12, ln)
	F.cbx("#e8e4dc", x - 0.34, 0.95, d0 - 0.02, 0.66, 0.04, ln + 0.04)
	K.register(b, GS, F.P(x - 0.1, 0.99, d0 + 0.4), Z(), -X())
	K.ob(b, F.P(x - 0.34, 0, d0), F.P(F.LN, 0, d0 + ln), 0.05)

## A white display table with a nested smaller one, single shoes on both.
static func table(G, GS, x, d, w, rng):
	F.cbx("#f6f6f2", x - w * 0.5, 0.74, d - 0.4, w, 0.04, 0.8)
	for c in [[-1, -1], [1, -1], [-1, 1], [1, 1]]:
		F.cbx("#d8d8d4", x + c[0] * (w * 0.5 - 0.05) - 0.02, 0.0, d + c[1] * 0.35 - 0.02, 0.04, 0.74, 0.04)
	F.cbx("#f6f6f2", x - w * 0.3, 0.46, d + 0.42, w * 0.6, 0.04, 0.5)
	for c in [[-1, 0], [1, 0]]:
		F.cbx("#d8d8d4", x + c[0] * (w * 0.3 - 0.04) - 0.02, 0.0, d + 0.62, 0.04, 0.46, 0.04)
	var ux = X()
	var uz = Z()
	for k in 3:
		SH.shoe(b, F.P(x - w * 0.33 + k * w * 0.33, 0.78, d), ux, -uz, LK, rng, rng.randf_range(-0.8, 0.8))
	for k in 2:
		SH.shoe(b, F.P(x - w * 0.15 + k * w * 0.3, 0.5, d + 0.66), ux, -uz, LK, rng, rng.randf_range(-0.8, 0.8))
	K.ob(b, F.P(x - w * 0.5, 0, d - 0.4), F.P(x + w * 0.5, 0, d + 0.92), 0.05)

static func fill_mat(m, key, b_):
	match key:
		"wood":
			m.albedo_texture = b_.tex("pay/wood.png"); m.roughness = 0.45
			m.uv1_triplanar = true; m.uv1_world_triplanar = true; m.uv1_scale = Vector3(1.0 / 2.4, 1.0, 1.0 / 1.2)
		"carpet":
			m.albedo_texture = b_.tex("pay/carpet.png"); m.roughness = 0.95
			m.uv1_triplanar = true; m.uv1_world_triplanar = true; m.uv1_scale = Vector3.ONE
		"shelves", "pegs", "bags", "headers":
			m.albedo_texture = b_.tex("pay/%s.png" % key); m.roughness = 0.6
		"mat":
			m.albedo_texture = b_.tex("pay/mat.png"); m.roughness = 0.8
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		_:
			return false
	return true
