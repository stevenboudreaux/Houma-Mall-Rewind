## Spencer's, walk-in (2026 map, store n35: 12 m on the Concourse's north side between maurices and the
## service corridor, the 1995 Gadzooks unit; wing 2). ws/interiors, Nov 4 2026. design/storefronts/spencers.md.
##
## Steven (voice note, Nov 3): "detailed renderings built off of the inside interior of Spencer's Gifts".
## From refs/new/spencers (spencers_t000_NNN, 0.5 fps; Spencer's to ~255, other stores after): a dark open
## ceiling with black ducts and track heads, red-brown brick piers between black wall bays, a stained
## amber concrete floor (011, 049, 129-145), the wall of framed tees in black frames (027, 257), black
## shelving with rough plank shelves (031, 099-117) and the mug wall with red shelf-edge strips (169-185),
## galvanized corrugated panels hung with carded goods (063-073), black gondolas and tiered tables of
## folded tees (013-021, 205-209), chrome spinner towers (127, 147), bins of plush (129-133), a jacket
## rounder (193-227), a drinks cooler at the front (047-051). The merchandise is invented and generic
## (the video is full of licensed characters, brand logos and packaging: none copied; paint.py).
## The front (brick, windows, the half-raised shutter, the sign) stays fronts26/store.gd spencers().
##
## Uses fronts26's frame (x 0..12 left to right from the hall, d into the store). Walk-in: the 2026 walk
## grid opens tiles x 117-122, y 112-123 (d 0..24, tools/make_layout_2026.py); the stock room behind.
## Materials "in_sp_<key>", textures tex/spencers/.

const K = preload("res://tools/stores/media/kit.gd")
const AK = preload("res://tools/stores/apparel/kit.gd")
const UP = Vector3.UP
const D = 24.0
const CY = 3.4
const NEON = ["#f03c78", "#3cdc78", "#fadc28", "#3caafa", "#aa50f0", "#fa8228", "#f5f5f0", "#1c1c1e", "#1c1c1e"]
const MUG = ["#1c1c1e", "#f4f4f0", "#f0a0c0", "#fadc28", "#3cdc78", "#3caafa", "#e83a3a", "#8a5ad0", "#1c1c1e", "#f4f4f0"]

static var F
static var b

static func X(): return F.P(1, 0, 0) - F.P(0, 0, 0)
static func Z(): return F.P(0, 0, 1) - F.P(0, 0, 0)

## The room (called first, in place of fronts26's room(9.0, ...)).
static func room(F_):
	F = F_
	b = F.bb
	var LN = F.LN
	var G = F.G
	b.quad(G, "in_sp_concrete", [F.P(0, 0.003, 0), F.P(LN, 0.003, 0), F.P(LN, 0.003, D), F.P(0, 0.003, D)], UP)
	# the black deck, ducts and track runs
	F.col("#141416")
	b.quad(G, "vcolor_matte", [F.P(0, CY, 0), F.P(LN, CY, 0), F.P(LN, CY, D), F.P(0, CY, D)], Vector3.DOWN)
	F.col("#1e1e20")
	F.side_q(G, "vcolor_matte", 0.02, 0.0, D, 0.0, CY, 1.0)
	F.side_q(G, "vcolor_matte", LN - 0.02, 0.0, D, 0.0, CY, -1.0)
	b.quad(G, "vcolor_matte", [F.P(LN, 0, D), F.P(0, 0, D), F.P(0, CY, D), F.P(LN, CY, D)], F.nn)
	b.cur_color = Color.WHITE
	# two black ducts down the store
	for x in [3.0, 9.0]:
		F.cbx("#232325", x - 0.25, CY - 0.6, 1.0, 0.5, 0.5, D - 2.0)
	var d = 2.0
	while d < D - 1.0:
		F.cbx("#2a2a2c", 0.6, CY - 0.08, d, LN - 1.2, 0.03, 0.04)
		var x2 = 1.2
		while x2 < LN - 1.0:
			b.cur_color = Color("#1a1a1c")
			b.cyl(F.GS, "vcolor", F.P(x2, CY - 0.24, d + 0.02), 0.045, 0.055, 0.16, 8, true, true)
			x2 += 1.8
		d += 3.0
	b.cur_color = Color.WHITE

## Everything inside, behind the front (called last, in place of fronts26's inside block and ob_room).
static func inside(F_):
	F = F_
	b = F.bb
	var LN = F.LN
	var G = F.G
	var GS = F.GS
	var rng = RandomNumberGenerator.new()
	rng.seed = 35
	# ---------------------------------------------------------------- the walls (left, right, back)
	# brick piers every ~5 m on both side walls, black bays between them
	for pd in [7.4, 13.6, 19.8]:
		pier(G, 0.02, pd, 1.0)
		pier(G, LN - 0.02, pd, -1.0)
	# left wall: framed tees, the mug wall, the corrugated peg wall
	F.side_q(G, "in_sp_tee_grid", 0.04, 1.4, 7.3, 0.4, 3.0, 1.0, 0.0, 0.0, 5.9 / 2.4, 1.0)
	mug_wall(G, GS, 0.04, 7.95, 13.5, 1.0, rng, false)
	F.side_q(G, "in_sp_corrugated", 0.04, 14.15, 19.7, 0.3, 2.9, 1.0, 0.0, 0.0, 5.55 / 2.4, 1.0)
	mug_wall(G, GS, 0.04, 20.35, D - 0.4, 1.0, rng, true)
	# right wall: tees face-out, tumblers and bottles, hoodies
	F.side_merch("in_sp_tee_rail", LN - 0.02, -1.0, 1.4, 7.3, 0.3, 2.9, 2.4, 2.6)
	mug_wall(G, GS, LN - 0.04, 7.95, 13.5, -1.0, rng, true)
	F.side_merch("in_sp_tee_rail", LN - 0.02, -1.0, 14.15, 19.7, 0.3, 2.9, 2.4, 2.6)
	F.side_q(G, "in_sp_corrugated", LN - 0.04, 20.35, D - 0.4, 0.3, 2.9, -1.0, 0.0, 0.0, 3.25 / 2.4, 1.0)
	# back wall: brick with the framed tees over the cash wrap, the stock-room door at the left
	F.front_q(G, "f26_brick", 0.0, LN, 0.0, CY, D - 0.03, 0.0, 0.0, LN / 0.9, CY / 0.6)
	F.front_q(GS, "in_sp_tee_grid", 4.0, 10.8, 1.3, 3.1, D - 0.05, 0.0, 0.0, 6.8 / 2.4, 0.75, true)
	F.cbx("#141416", 1.0, 0.0, D - 0.06, 1.0, 2.15, 0.04)
	F.cbx("#5a3a20", 0.94, 2.15, D - 0.07, 1.12, 0.06, 0.05)
	# ---------------------------------------------------------------- the floor fixtures
	# black gondolas of plank shelves down two lines, with a cross aisle in the middle
	for gx in [3.2, 7.8]:
		for run in [[2.6, 9.6], [12.0, 19.0]]:
			gondola(G, GS, gx, run[0], run[1], rng)
	# a tiered round table of folded tees at the front, two more mid-store
	for t in [[5.9, 2.4], [1.9, 11.0], [10.1, 16.2]]:
		tiers(G, GS, t[0], t[1], rng)
	# spinner towers, plush bins, the jacket rounder
	for s in [[5.9, 11.0], [5.9, 20.3], [10.2, 3.2]]:
		spinner(GS, s[0], s[1], rng)
	for p in [[5.9, 15.6], [1.9, 3.0]]:
		bin(G, GS, p[0], p[1], rng)
	rounder(GS, 10.0, 11.0, rng)
	# the cash wrap at the back: black with a plank top, a register, an impulse rack
	F.cbx("#141416", 4.6, 0.0, D - 2.3, 4.0, 0.98, 0.7)
	F.bx(G, "f26_planks", 4.55, 0.98, D - 2.33, 4.1, 0.05, 0.76)
	K.register(b, GS, F.P(6.4, 1.03, D - 1.95), -X(), F.nn)
	F.cbx("#1c1c1e", 4.7, 1.03, D - 2.2, 0.8, 0.4, 0.3, GS)
	goods_face(GS, 4.72, D - 2.21, 0.76, 1.08, 1.4, rng)
	K.ob(b, F.P(4.5, 0, D - 2.35), F.P(8.7, 0, D), 0.05)
	# colour washes (the video's pink and blue accent light) and the room light
	for k in 4:
		var l = b.add_omni(F.P(2.5 + (k % 2) * 7.0, 2.7, 4.0 + k * 5.0), 0.35, 5.0, [Color(0.95, 0.4, 0.7), Color(0.45, 0.5, 1.0), Color(1.0, 0.75, 0.45), Color(0.6, 0.4, 1.0)][k])
		b.tag(l, "", 0.3, 0.35)
	var d = 3.0
	while d < D - 1.0:
		for x in [3.0, 9.0]:
			var sl = b.add_spot(F.P(x, CY - 0.3, d), Vector3.DOWN, 0.7, 5.5, 60.0, Color(1.0, 0.9, 0.78))
			b.tag(sl, "", 0.6, 0.7)
		d += 4.0
	# obstacles: the side and back walls' fixtures
	K.ob(b, F.P(0, 0, 1.2), F.P(0.5, 0, D), 0.05)
	K.ob(b, F.P(LN - 0.5, 0, 1.2), F.P(LN, 0, D), 0.05)
	K.ob(b, F.P(0, 0, D - 0.4), F.P(LN, 0, D), 0.05)

## The window displays and the vending cooler: obstacles across the front except the 3.2 m entry.
static func front_obstacles(LN):
	K.ob(b, F.P(0, 0, -0.3), F.P(3.0, 0, 1.2), 0.03)
	K.ob(b, F.P(6.2, 0, -0.3), F.P(LN, 0, 1.2), 0.03)
	K.ob(b, F.P(3.2, 0, 0.15), F.P(3.9, 0, 0.7), 0.05)
	# black risers with goods in both windows
	var rng = RandomNumberGenerator.new()
	rng.seed = 350
	for w in [[0.6, 2.3], [6.9, 8.5]]:
		F.cbx("#141416", w[0], 0.0, 0.2, w[1] - w[0], 0.35, 0.8)
		F.cbx("#141416", w[0] + 0.3, 0.35, 0.5, w[1] - w[0] - 0.6, 0.3, 0.4)
		F.goods((w[0] + w[1]) * 0.5, 0.45, w[1] - w[0] - 0.1, 0.4, 0.35, NEON, rng, 0.16, 0.3)
	F.cbx("#141416", 8.6, 0.0, 0.1, 3.3, 0.12, 1.0)

## A brick pier, 0.6 m along the wall at d, 0.3 m proud.
static func pier(G, x, d, s):
	F.bx(G, "f26_brick", x if s > 0 else x - 0.3, 0.0, d - 0.3, 0.3, CY, 0.6)

## Black open shelving against a wall at x (facing +x if s > 0), d0..d1: six rough plank shelves,
## mugs (or tumblers) standing on them, red shelf-edge strips with their words.
static func mug_wall(G, GS, x, d0, d1, s, rng, tumblers):
	var ux = X()
	F.col("#141416")
	F.bx(G, "vcolor", x if s > 0 else x - 0.38, 0.0, d0, 0.38, 0.3, d1 - d0)
	for e in [d0, d1 - 0.04]:
		F.bx(G, "vcolor", x if s > 0 else x - 0.38, 0.0, e, 0.38, 2.6, 0.04)
	b.cur_color = Color.WHITE
	for k in 6:
		var y = 0.35 + k * 0.38
		F.bx(G, "f26_planks", x if s > 0 else x - 0.36, y, d0 + 0.04, 0.36, 0.035, d1 - d0 - 0.08)
		# the red strip on the edge, its words facing out
		var fx = x + 0.362 * s
		F.side_q(GS, "in_sp_strip", fx, d0 + 0.04, d1 - 0.04, y - 0.045, y + 0.005, s, 0.0, 0.0, (d1 - d0) / 1.2, 1.0, true)
		if k == 5:
			continue
		var dd = d0 + 0.14
		while dd < d1 - 0.12:
			var c = F.P(x + 0.18 * s, y + 0.035, dd)
			b.cur_color = Color(MUG[rng.randi_range(0, MUG.size() - 1)])
			if tumblers:
				b.cyl(GS, "vcolor", c, 0.042, 0.05, rng.randf_range(0.2, 0.26), 8, true, false, true)
				dd += 0.13
			else:
				b.cyl(GS, "vcolor", c, 0.045, 0.048, 0.1, 8, true, false, true)
				b.box(GS, "vcolor", c + ux * (0.06 * s) + UP * 0.05, Vector3(0.025, 0.06, 0.012), Transform3D.IDENTITY, [], true)
				dd += 0.12
	b.cur_color = Color.WHITE

## A black gondola from d0 to d1 at x (its centre line), 1.0 m deep, 1.6 m high, plank shelves both
## sides with folded tees and boxed gifts.
static func gondola(G, GS, x, d0, d1, rng):
	F.cbx("#141416", x - 0.5, 0.0, d0, 1.0, 0.25, d1 - d0)
	F.cbx("#141416", x - 0.03, 0.25, d0, 0.06, 1.35, d1 - d0)
	for k in 3:
		var y = 0.25 + k * 0.45
		F.bx(G, "f26_planks", x - 0.5, y, d0, 1.0, 0.03, d1 - d0)
		for s in [-1.0, 1.0]:
			var fx = x + 0.48 * s
			F.side_q(GS, "in_sp_folded", fx, d0 + 0.05, d1 - 0.05, y + 0.03, y + 0.4, s, 0.0, 0.0, (d1 - d0) / 1.2, 1.0, true)
	F.bx(G, "f26_planks", x - 0.5, 1.6, d0, 1.0, 0.03, d1 - d0)
	F.goods(x, (d0 + d1) * 0.5, 0.9, d1 - d0 - 0.2, 1.63, NEON, rng, 0.2, 0.28)
	for e in [d0, d1 - 0.04]:
		F.cbx("#141416", x - 0.5, 0.0, e, 1.0, 1.63, 0.04)
	K.ob(b, F.P(x - 0.5, 0, d0), F.P(x + 0.5, 0, d1), 0.08)

## A three-tier round table of folded tees: black bases, plank tops.
static func tiers(G, GS, x, d, rng):
	var c = F.P(x, 0, d)
	for k in 3:
		var r = 0.7 - k * 0.2
		var y = 0.45 + k * 0.3
		b.cur_color = Color("#141416")
		b.cyl(G, "vcolor", c + UP * (y - 0.3), r - 0.05, r - 0.05, 0.3, 16, false, false)
		b.cur_color = Color.WHITE
		b.cyl(G, "f26_planks", c + UP * (y - 0.03), r, r, 0.03, 16, true, false)
		for j in int(6 - k * 1.5):
			var a = TAU * j / int(6 - k * 1.5) + k * 0.4
			var p = c + (X().normalized() * cos(a) + Z().normalized() * sin(a)) * (r - 0.15) + UP * y
			b.cur_color = Color(NEON[rng.randi_range(0, NEON.size() - 1)])
			b.box(GS, "vcolor", Vector3.ZERO, Vector3(0.24, 0.14, 0.2), Transform3D(Basis(UP, -a), p + UP * 0.07), [], true)
	b.cur_color = Color.WHITE
	K.ob(b, F.P(x - 0.7, 0, d - 0.7), F.P(x + 0.7, 0, d + 0.7), 0.05)

## A chrome spinner tower (0.5 m square, 1.9 m) hung with carded goods on its four faces.
static func spinner(GS, x, d, rng):
	var c = F.P(x, 0, d)
	b.cur_color = Color("#c8cacc")
	b.cyl(GS, "vcolor", c, 0.28, 0.28, 0.04, 12, true, false, true)
	b.cyl(GS, "vcolor", c, 0.025, 0.025, 1.95, 8, true, false, true)
	b.cur_color = Color.WHITE
	for fdir in [X(), -X(), Z(), -Z()]:
		var fn = fdir.normalized()
		var side = fn.cross(UP).normalized()
		for j in 5:
			for i in 2:
				var p = c + fn * 0.22 + side * (-0.1 + i * 0.2) + UP * (0.5 + j * 0.3)
				b.cur_color = Color(NEON[rng.randi_range(0, 6)])
				b.box(GS, "vcolor", p, Vector3(0.0, 0.0, 0.0) + (side.abs() * 0.14 + UP * 0.2 + fn.abs() * 0.015), Transform3D.IDENTITY, [], true)
	b.cur_color = Color.WHITE
	K.ob(b, F.P(x - 0.3, 0, d - 0.3), F.P(x + 0.3, 0, d + 0.3), 0.05)

## A low black bin heaped with plush (soft balls of colour).
static func bin(G, GS, x, d, rng):
	F.cbx("#141416", x - 0.6, 0.0, d - 0.45, 1.2, 0.6, 0.9)
	for k in 14:
		b.cur_color = Color(NEON[rng.randi_range(0, 6)])
		var p = F.P(x + rng.randf_range(-0.45, 0.45), 0.62 + rng.randf_range(0.0, 0.1), d + rng.randf_range(-0.32, 0.32))
		b.cyl(GS, "vcolor", p - UP * 0.08, 0.11, 0.06, 0.2, 8, true, false, true)
	b.cur_color = Color.WHITE
	K.ob(b, F.P(x - 0.6, 0, d - 0.45), F.P(x + 0.6, 0, d + 0.45), 0.05)

## A chrome jacket rounder of black, pink and white varsity-style jackets (the apparel kit's rack).
static func rounder(GS, x, d, rng):
	var c = F.P(x, 0, d)
	AK.round_rack(b, c, 0.55, 1)
	K.ob(b, F.P(x - 0.65, 0, d - 0.65), F.P(x + 0.65, 0, d + 0.65), 0.05)

## Small carded goods on the impulse rack's face at x0.., depth d, width w, y0..y1.
static func goods_face(GS, x0, d, w, y0, y1, rng):
	var x = x0 + 0.04
	while x < x0 + w - 0.1:
		var y = y0 + 0.04
		while y < y1 - 0.12:
			F.cbx(NEON[rng.randi_range(0, 6)], x, y, d - 0.012, 0.09, 0.12, 0.01, GS)
			y += 0.15
		x += 0.12

static func fill_mat(m, key, b_):
	match key:
		"concrete":
			m.albedo_texture = b_.tex("spencers/concrete.png"); m.roughness = 0.35; m.metallic_specular = 0.6
			m.uv1_triplanar = true; m.uv1_world_triplanar = true; m.uv1_scale = Vector3.ONE * 0.25
		"tee_grid", "corrugated", "folded", "tee_rail":
			m.albedo_texture = b_.tex("spencers/%s.png" % key); m.roughness = 0.55 if key != "corrugated" else 0.4
			if key == "corrugated":
				m.metallic = 0.4
		"strip":
			m.albedo_texture = b_.tex("spencers/strip.png"); m.roughness = 0.5
		_:
			return false
	return true
