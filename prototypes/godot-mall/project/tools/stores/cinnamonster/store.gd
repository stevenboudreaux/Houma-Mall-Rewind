## Cinnamonster (2026, store s57: KarmelKorn's corner stall at the Dillard's court's west side,
## open to the hall on its north face and to the court on its east face). Built from Steven's
## photos IMG_4464-4468 (Oct 23 2026, shot upside down: rotated 180 for reading).
## Notes and guesses: design/storefronts/cinnamonster-2026.md.
##
## What the photos show: a gold/tan fascia over both open faces with burgundy/cream 4" checker
## bands top and bottom, the round cinnamonster plaques on it (Demo 43 spec y26/parts/
## cinnamonster.json); inside, a white lay-in ceiling with troffers, cans, track heads and red
## cone pendants; burgundy walls with a two-course checker band over white 4" tile; a curved
## counter faced in mahogany laminate on a checker kick with a white top, running along the north
## face and round the corner down the east face, a glass bakery case on the east run; one brown
## Tuscan column at the corner; hanging Bakery/Smoothies menus, posters, a coffee oval on planks;
## espresso, grinders, a freezer and dispensers on the back counter; a red sign stand by the
## column.
##
## Frame: the north frontage edge (x -28 -> -20 at z 60, facing the hall). P(u, y, d) = a + t u -
## n d + y up; u = 0 at the west end (your right facing the store), d into the store (south). The
## east face is the plane u = 8 (x -20), facing +t. Materials "cm_<key>", textures tex/cm/.

const K = preload("res://tools/stores/media/kit.gd")
const S26 = preload("res://tools/stores/signs/sign_2026.gd")
const UP = Vector3.UP
const W = 8.0             # north face
const EAST_OPEN = 6.5     # the east face is open from the corner to here (d): the long run
const EAST_LEN = 10.0     # the east frontage
const BACK = 6.5          # the stall's south wall (d)
const WEST = 3.5          # the stall's back wall (u): the burgundy wall with the coffee oval
const NORTH_OPEN = 3.5    # the north face is open from here (u) to the corner: the short run
const FAS0 = 2.75         # bottom of the fascia = the stall's ceiling
const FAS1 = 4.15         # top of the fascia's upper checker band
const FT = 0.12           # fascia thickness, proud of the frontage
const TOP_Y = 1.0
const CDEP = 0.6
const GS = "cm_shell"
const G = "cm_fix"
const SM = "cm_small"
const DY = "cmf_dyn"

static var a0: Vector3
static var tt: Vector3
static var nn: Vector3
static var bb

static func P(u, y, d):
	return a0 + tt * u - nn * d + UP * y

static func bx(g, m, u, y, d, wu, h, dd, skip = [], dyn = false):
	K.lbox(bb, g, m, a0, tt, -nn, u, y, d, wu, h, dd, skip, dyn)

static func col(c):
	bb.cur_color = Color(c)

## A quad on the plane d = const between u0..u1, y0..y1, facing the hall (f > 0) or into the
## store; UVs in metres / (tw, th).
static func qd(g, m, d, u0, u1, y0, y1, f, tw, th, dyn = false):
	var pts = [P(u0, y0, d), P(u1, y0, d), P(u1, y1, d), P(u0, y1, d)]
	var s = 1.0 if f > 0 else -1.0
	var uvs = [Vector2(-s * u0 / tw, -y0 / th), Vector2(-s * u1 / tw, -y0 / th), Vector2(-s * u1 / tw, -y1 / th), Vector2(-s * u0 / tw, -y1 / th)]
	bb.quad(g, m, pts, nn * f, uvs, dyn)

## A quad on the plane u = const between d0..d1, facing +t (f > 0) or -t.
static func qu(g, m, u, d0, d1, y0, y1, f, tw, th, dyn = false):
	var pts = [P(u, y0, d0), P(u, y0, d1), P(u, y1, d1), P(u, y1, d0)]
	var s = 1.0 if f > 0 else -1.0
	var uvs = [Vector2(s * d0 / tw, -y0 / th), Vector2(s * d1 / tw, -y0 / th), Vector2(s * d1 / tw, -y1 / th), Vector2(s * d0 / tw, -y1 / th)]
	bb.quad(g, m, pts, tt * f, uvs, dyn)

static func ob(u0, d0, u1, d1, pad = 0.08):
	K.ob(bb, P(u0, 0, d0), P(u1, 0, d1), pad)

# ------------------------------------------------------------------ entry point
## Called for the north edge only; the east edge's call returns (build_mall.gd).
static func build(b, g, e, a, b2, n, t, Ln, sd):
	bb = b
	a0 = a
	tt = t
	nn = n
	fascia()
	shell()
	counter()
	back_counter()
	column(7.45, 0.55)
	sign_stand(7.9, -0.25)
	var rp = ReflectionProbe.new()
	rp.position = P(W * 0.5, 1.4, BACK * 0.5)
	rp.size = (t * W + n * BACK).abs() + Vector3(0.1, FAS0 + 0.1, 0.1)
	rp.box_projection = true
	rp.interior = true
	rp.update_mode = ReflectionProbe.UPDATE_ONCE
	rp.intensity = 0.5
	b.light_root.add_child(rp)

# ------------------------------------------------------------------ the fascia
static func fascia():
	var LH = bb.LANE_H
	# north face: the gold band with its checker bands, cream mall wall above
	bx(GS, "cm_gold", 0.0, FAS0, -FT, W + FT, FAS1 - FAS0, FT)
	bx(GS, "cream", 0.0, FAS1, -FT * 0.5, W + FT * 0.5, LH - FAS1, FT * 0.5, ["-y"])
	for y in [FAS0, FAS1 - 0.2]:
		qd(GS, "cm_checker", -FT - 0.003, 0.0, W + FT, y, y + 0.2, 1.0, 0.4, 0.2)
	# east face: the same band the whole frontage, a closed cream wall under it past the opening
	bx(GS, "cm_gold", W, FAS0, -FT, FT, FAS1 - FAS0, EAST_LEN + FT)
	bx(GS, "cream", W, FAS1, -FT * 0.5, FT * 0.5, LH - FAS1, EAST_LEN + FT * 0.5, ["-y"])
	for y in [FAS0, FAS1 - 0.2]:
		qu(GS, "cm_checker", W + FT + 0.003, -FT, EAST_LEN, y, y + 0.2, 1.0, 0.4, 0.2)
	bx(GS, "cream", W, 0.0, EAST_OPEN, FT, FAS0, EAST_LEN - EAST_OPEN, ["-y"])
	col("#8a8478")
	bx(SM, "vcolor", W + FT, 0.0, EAST_OPEN, 0.01, 0.1, EAST_LEN - EAST_OPEN, ["-y"])
	col("#ffffff")
	# north face west of the opening: a closed cream wall under the band
	bx(GS, "cream", 0.0, 0.0, -0.06, NORTH_OPEN, FAS0, 0.06, ["-y"])
	col("#8a8478")
	bx(SM, "vcolor", 0.0, 0.0, -0.07, NORTH_OPEN, 0.1, 0.01, ["-y"])
	col("#ffffff")
	# the round plaques (one on each face: IMG_4467 top left on the east face, top right on the
	# north face near the corner)
	S26.build(bb, "cm_sg26", "CINNAMONSTER", P(5.6, (FAS0 + FAS1) * 0.5 + 0.02, -FT - 0.005), nn, 1.6, 0.95)
	S26.build(bb, "cm_sg26", "CINNAMONSTER", P(W + FT + 0.005, (FAS0 + FAS1) * 0.5 + 0.02, 5.0), tt, 1.6, 0.95)

# ------------------------------------------------------------------ the room
static func shell():
	# floor, ceiling with troffers and cans
	col("#cbbfae")
	bb.quad(GS, "vcolor_matte", [P(WEST, 0.003, 0.0), P(W, 0.003, 0.0), P(W, 0.003, BACK), P(WEST, 0.003, BACK)], UP)
	col("#ffffff")
	var cp = [P(WEST, FAS0, 0.0), P(W, FAS0, 0.0), P(W, FAS0, BACK), P(WEST, FAS0, BACK)]
	var cuv = []
	for p in cp:
		cuv.append(Vector2(p.x / 0.61, p.z / 1.22))
	bb.quad(GS, "kb_ceiling", cp, Vector3.DOWN, cuv)
	var j = 0
	for tr in [[4.0, 1.0], [6.2, 1.2], [4.0, 3.2], [6.2, 3.4], [4.0, 5.2], [6.2, 5.4]]:
		var tq = [P(tr[0], FAS0 - 0.006, tr[1]), P(tr[0] + 1.22, FAS0 - 0.006, tr[1]), P(tr[0] + 1.22, FAS0 - 0.006, tr[1] + 0.61), P(tr[0], FAS0 - 0.006, tr[1] + 0.61)]
		bb.quad(GS, "gb_troffer", tq, Vector3.DOWN, [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)])
		if j % 2 == 0:
			var l = bb.add_spot(P(tr[0] + 0.6, FAS0 - 0.08, tr[1] + 0.3), Vector3.DOWN, 0.9, 4.5, 62.0, Color(1.0, 0.96, 0.9))
			bb.tag(l, "", 0.9, 0.9)
		j += 1
	for c in [[5.2, 0.5], [7.3, 2.6], [7.3, 4.6], [5.4, 2.6], [5.4, 4.6], [7.3, 6.1]]:
		col("#e8e6e0")
		bb.cyl(SM, "vcolor", P(c[0], FAS0 - 0.01, c[1]), 0.09, 0.09, 0.01, 12, false, true)
		col("#fff6e0")
		bb.cyl(SM, "cm_glow", P(c[0], FAS0 - 0.012, c[1]), 0.06, 0.06, 0.002, 12, false, true)
	col("#ffffff")
	# red cone pendants over the north run (IMG_4467, receding along the concourse side)
	for u in [4.3, 5.2, 6.1]:
		var c = P(u, 1.85, 1.35)
		col("#2a2a2a")
		bb.cyl(SM, "vcolor", c + UP * 0.2, 0.004, 0.004, FAS0 - 2.05, 4, false, false)
		col("#ffffff")
		bb.cyl(SM, "cm_shade", c, 0.12, 0.03, 0.2, 14, true, false)
		bb.cyl(SM, "cm_glow", c - UP * 0.005, 0.1, 0.1, 0.005, 12, false, true)
	var lp = bb.add_omni(P(5.2, 1.6, 1.4), 0.3, 2.2, Color(1.0, 0.8, 0.6))
	bb.tag(lp, "", 0.25, 0.3)
	# track heads along the back
	col("#e8e6e0")
	for d in [2.0, 2.4, 2.8, 4.6, 5.0]:
		bx(SM, "vcolor", 4.3, FAS0 - 0.16, d, 0.12, 0.14, 0.08)
	col("#ffffff")
	# walls: burgundy over a checker band over white tile (west and back)
	for wdef in [["d", BACK, WEST, W, 1.0], ["u", WEST, 0.0, BACK, 1.0], ["d", 0.0, 0.0, WEST, -1.0]]:
		if wdef[0] == "d":
			qd(GS, "cm_burg", wdef[1], wdef[2], wdef[3], 1.05, FAS0, wdef[4], 1.0, 1.0)
			qd(GS, "cm_checker", wdef[1], wdef[2], wdef[3], 0.85, 1.05, wdef[4], 0.4, 0.2)
			qd(GS, "cm_wtile", wdef[1], wdef[2], wdef[3], 0.0, 0.85, wdef[4], 0.4, 0.4)
		else:
			qu(GS, "cm_burg", wdef[1], wdef[2], wdef[3], 1.05, FAS0, wdef[4], 1.0, 1.0)
			qu(GS, "cm_checker", wdef[1], wdef[2], wdef[3], 0.85, 1.05, wdef[4], 0.4, 0.2)
			qu(GS, "cm_wtile", wdef[1], wdef[2], wdef[3], 0.0, 0.85, wdef[4], 0.4, 0.4)
	# wall pieces on the back (west) wall, south to north as photographed from the court (IMG_4467):
	# the coffee oval on planks, "From the Oven", "Rich & Gooey"; a speaker, a thermostat
	poster(5.3, 6.2, 1.55, 2.5, 0.0)
	poster(3.6, 4.4, 1.6, 2.4, 1.0)
	poster(0.9, 1.8, 1.4, 2.4, 2.0)
	col("#1a1a1a")
	bx(SM, "vcolor", WEST, 2.3, 2.9, 0.12, 0.22, 0.16)
	col("#ece8de")
	bx(SM, "vcolor", WEST, 1.55, 3.1, 0.03, 0.1, 0.14)
	col("#ffffff")
	# hanging menus (Bakery, Smoothies) behind the east run, facing the court
	var mu = 6.3
	bx(G, "cm_dark", mu - 0.04, 1.8, 2.0, 0.04, 0.72, 1.6)
	var mq = [P(mu + 0.002, 1.83, 3.57), P(mu + 0.002, 1.83, 2.03), P(mu + 0.002, 2.49, 2.03), P(mu + 0.002, 2.49, 3.57)]
	bb.quad(DY, "cm_menu", mq, tt, [Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)], true)
	col("#2a2a2a")
	for d in [2.2, 3.4]:
		bb.cyl(SM, "vcolor", P(mu - 0.02, 2.52, d), 0.004, 0.004, FAS0 - 2.52, 4, false, false)
	col("#ffffff")

## A third of posters.png on the back wall (u = WEST, facing +t) between d0 (south end) and d1.
static func poster(d0, d1, y0, y1, k):
	var pts = [P(WEST + 0.01, y0, d0), P(WEST + 0.01, y0, d1), P(WEST + 0.01, y1, d1), P(WEST + 0.01, y1, d0)]
	var ua = k / 3.0
	var ub = (k + 1.0) / 3.0
	bb.quad(G, "cm_posters", pts, tt, [Vector2(ub, 1), Vector2(ua, 1), Vector2(ua, 0), Vector2(ub, 0)])

# ------------------------------------------------------------------ the counter
## The customer-face path in (u, d): along the north face (a slight angle back to the west wall),
## round the corner, down the east face.
static func path():
	var cu = 6.2
	var cd = 1.85
	var r = 0.8
	var pts = [Vector2(WEST, 1.05), Vector2(cu, cd - r)]
	for k in range(1, 9):
		var th = PI * 0.5 * k / 8.0
		pts.append(Vector2(cu + r * sin(th), cd - r * cos(th)))
	pts.append(Vector2(cu + r, 4.2))
	pts.append(Vector2(cu + r - 0.3, BACK))
	return pts

static func counter():
	var pts = path()
	var s = 0.0
	for i in pts.size() - 1:
		var p0 = pts[i]
		var p1 = pts[i + 1]
		var dl = p1 - p0
		var L = dl.length()
		var inw = Vector2(-dl.y, dl.x) / L          # into the stall
		var w0 = P(p0.x, 0, p0.y)
		var w1 = P(p1.x, 0, p1.y)
		var dw = (w1 - w0).normalized()
		var out = -(tt * inw.x - nn * inw.y)          # towards the customers
		var zc = dw.cross(UP)
		var bas = Basis(dw, UP, zc)
		var ctr = (w0 + w1) * 0.5 - out * (CDEP * 0.5)
		var ext = 0.03
		bb.box(G, "cm_dark", Vector3(0, TOP_Y * 0.5, 0), Vector3(L + ext, TOP_Y - 0.02, CDEP), Transform3D(bas, ctr))
		# the white top with a lip over the customer face
		bb.box(G, "cm_top", Vector3(0, 0, 0), Vector3(L + ext + 0.02, 0.05, CDEP + 0.08), Transform3D(bas, ctr + UP * (TOP_Y + 0.0) + out * 0.03))
		# the mahogany face and the checker kick, as quads just proud of the body
		var f0 = w0 + out * (0.004)
		var f1 = w1 + out * (0.004)
		bb.quad(G, "cm_mahog", [f0 + UP * 0.2, f1 + UP * 0.2, f1 + UP * (TOP_Y - 0.03), f0 + UP * (TOP_Y - 0.03)], out,
			[Vector2(s / 1.2, 1.0), Vector2((s + L) / 1.2, 1.0), Vector2((s + L) / 1.2, 0.0), Vector2(s / 1.2, 0.0)])
		bb.quad(G, "cm_checker", [f0, f1, f1 + UP * 0.2, f0 + UP * 0.2], out,
			[Vector2(s / 0.4, 1.0), Vector2((s + L) / 0.4, 1.0), Vector2((s + L) / 0.4, 0.0), Vector2(s / 0.4, 0.0)])
		# a dark rail between the face and the kick
		col("#2a1410")
		bb.box(SM, "vcolor", Vector3(0, 0.205, 0), Vector3(L + ext, 0.03, 0.03), Transform3D(bas, f0.lerp(f1, 0.5) + out * 0.01))
		col("#ffffff")
		s += L
		K.ob(bb, w0 - out * 0.05, w1 - out * (CDEP + 0.05), 0.06)
	# on the north run: the register, cup towers, a tip jar, napkins
	# on the east run (facing the court): the register, cup towers, a tip jar
	K.register(bb, SM, P(6.7, TOP_Y + 0.025, 4.6), nn, -tt)
	col("#f6f4ee")
	for c in [[6.85, 3.3], [6.8, 3.45], [6.6, 5.6]]:
		bb.cyl(SM, "vcolor", P(c[0], TOP_Y + 0.025, c[1]), 0.045, 0.05, 0.36, 10, true, false)
	col("#c8202a")
	bb.cyl(SM, "vcolor", P(6.8, TOP_Y + 0.025, 3.7), 0.045, 0.05, 0.28, 10, true, false)
	col("#ffffff")
	bb.cyl(SM, "cm_glass", P(6.8, TOP_Y + 0.025, 4.0), 0.07, 0.07, 0.18, 12, true, false, true)
	# the glass bakery case on the north run (under the pendants): steel base, glass hood, rolls
	var cd = 1.1
	bx(SM, "wl_steel", 4.0, TOP_Y + 0.025, cd, 1.6, 0.06, 0.5)
	var rng = RandomNumberGenerator.new()
	rng.seed = 57
	for tray in 2:
		for k in 7:
			var c = P(4.12 + k * 0.21, TOP_Y + 0.09 + tray * 0.17, cd + 0.12 + tray * 0.2 + rng.randf() * 0.03)
			col("#c27a3a")
			bb.cyl(SM, "vcolor", c, 0.075, 0.07, 0.05, 10, true, false)
			col("#faf6ee")
			bb.cyl(SM, "vcolor", c + UP * 0.05, 0.06, 0.03, 0.012, 10, true, false)
		col("#d8d8d8")
		bx(SM, "vcolor", 4.02, TOP_Y + 0.08 + tray * 0.17, cd + 0.02, 1.56, 0.008, 0.46)
	col("#ffffff")
	bx(DY, "cm_glass", 4.0, TOP_Y + 0.085, cd, 1.6, 0.42, 0.5, ["-y"], true)
	var lc = bb.add_omni(P(4.8, TOP_Y + 0.4, cd + 0.25), 0.15, 1.0, Color(1.0, 0.92, 0.8))
	bb.tag(lc, "", 0.12, 0.15)
	ob(WEST, 0.9, W - 0.2, BACK, 0.02)

# ------------------------------------------------------------------ the back counter
static func back_counter():
	# along the back (west) wall, from the north run's end to the south wall; the frame is turned so
	# the gear below can be laid out as along a wall (u' = d, d' = u - WEST)
	col("#3a2a24")
	bx(G, "vcolor", WEST, 0.0, 1.7, 0.62, 0.9, BACK - 1.7, ["-y"])
	col("#ffffff")
	bx(G, "cm_top", WEST, 0.9, 1.68, 0.64, 0.04, BACK - 1.68)
	var sa = a0
	var st = tt
	var sn = nn
	# turn: new u axis = old "into store" (-nn) reversed so the gear runs north->south ... the wall
	# is u = WEST; things sit at u' along -nn from d 1.8, depth into the room along +tt
	a0 = P(WEST, 0, BACK)
	tt = nn
	nn = -st
	var d0 = 0.0
	var y = 0.94
	# a cup rack with sleeves (left), espresso machine, grinders, a black merchandiser, a freezer,
	# drink dispensers, an oven
	col("#1c1c1e")
	bx(SM, "vcolor", 0.6, y, d0 + 0.1, 0.6, 0.28, 0.4)
	col("#d8d8dc")
	for k in 4:
		bb.cyl(SM, "vcolor", P(0.68 + k * 0.14, y + 0.28, d0 + 0.25), 0.04, 0.05, 0.14, 8, true, false)
	col("#ffffff")
	bx(SM, "wl_steel", 1.5, y, d0 + 0.08, 0.75, 0.48, 0.48)
	col("#c8501e")
	bx(SM, "vcolor", 1.5, y + 0.48, d0 + 0.1, 0.75, 0.04, 0.44)
	col("#ffffff")
	for k in 3:
		bb.cyl(SM, "cm_glass", P(2.45 + k * 0.17, y, d0 + 0.3), 0.07, 0.07, 0.42, 10, true, false, true)
	col("#141416")
	bx(SM, "vcolor", 3.05, y, d0 + 0.05, 0.62, 0.78, 0.5)
	col("#f0eee8")
	bx(SM, "vcolor", 3.8, y, d0 + 0.05, 0.7, 0.42, 0.5)
	col("#ffffff")
	for k in 2:
		bx(DY, "cm_glass", 4.3 + k * 0.28, y, d0 + 0.12, 0.26, 0.5, 0.36, [], true)
	col("#e86a2a")
	bx(SM, "vcolor", 4.32, y + 0.05, d0 + 0.14, 0.22, 0.25, 0.32)
	col("#f2d24a")
	bx(SM, "vcolor", 4.6, y + 0.05, d0 + 0.14, 0.22, 0.25, 0.32)
	col("#ffffff")
	a0 = sa
	tt = st
	nn = sn
	var l = bb.add_omni(P(5.4, 2.2, 3.2), 0.5, 4.0, Color(1.0, 0.92, 0.82))
	bb.tag(l, "", 0.4, 0.5)

# ------------------------------------------------------------------ the column and the stand
## The brown Tuscan column at the corner (IMG_4467): square plinth, torus, tapered shaft, a necking
## ring, the echinus and a square abacus, up to the fascia's soffit.
static func column(u, d):
	var c = P(u, 0, d)
	bb.box(G, "cm_column", c + UP * 0.07, Vector3(0.42, 0.14, 0.42))
	bb.cyl(G, "cm_column", c + UP * 0.14, 0.2, 0.2, 0.07, 18, true, false)
	bb.cyl(G, "cm_column", c + UP * 0.21, 0.17, 0.145, FAS0 - 0.21 - 0.3, 18, false, false)
	bb.cyl(G, "cm_column", c + UP * (FAS0 - 0.3), 0.16, 0.16, 0.04, 18, true, true)
	bb.cyl(G, "cm_column", c + UP * (FAS0 - 0.24), 0.15, 0.2, 0.1, 18, true, true)
	bb.box(G, "cm_column", c + UP * (FAS0 - 0.07), Vector3(0.44, 0.14, 0.44))
	K.ob(bb, c - Vector3(0.22, 0, 0.22), c + Vector3(0.22, 0, 0.22), 0.05)

## The red sign stand by the column: a low red box with a black easel and a small sign.
static func sign_stand(u, d):
	col("#8e1e24")
	bx(SM, "vcolor", u - 0.28, 0.0, d - 0.22, 0.56, 0.42, 0.44, ["-y"])
	col("#151515")
	bx(SM, "vcolor", u - 0.03, 0.42, d - 0.03, 0.06, 1.0, 0.06)
	bx(SM, "vcolor", u - 0.3, 1.0, d - 0.04, 0.6, 0.46, 0.03)
	col("#7a2a38")
	bx(SM, "vcolor", u - 0.26, 1.05, d - 0.06, 0.52, 0.12, 0.02)
	col("#ffffff")
	ob(u - 0.3, d - 0.25, u + 0.3, d + 0.25, 0.02)

# ------------------------------------------------------------------ materials
## "cm_<key>" (build_mall.gd's mat() calls this).
static func fill_mat(m, key, b):
	match key:
		"gold":
			m.albedo_texture = b.tex("cm/gold.png"); m.roughness = 0.75
			m.uv1_triplanar = true; m.uv1_scale = Vector3(0.6, 0.6, 0.6)
		"checker":
			m.albedo_texture = b.tex("cm/checker.png"); m.roughness = 0.25; m.metallic_specular = 0.65
		"wtile":
			m.albedo_texture = b.tex("cm/white_tile.png"); m.roughness = 0.25; m.metallic_specular = 0.6
		"mahog":
			m.albedo_texture = b.tex("cm/mahogany.png"); m.roughness = 0.28; m.metallic_specular = 0.6
		"burg":
			m.albedo_color = Color("#7a1c26"); m.roughness = 0.75
		"dark":
			m.albedo_color = Color("#3a1a16"); m.roughness = 0.45
		"top":
			m.albedo_color = Color("#ece6da"); m.roughness = 0.3; m.metallic_specular = 0.6
		"column":
			m.albedo_color = Color("#4a2c20"); m.roughness = 0.45; m.metallic_specular = 0.55
		"posters":
			m.albedo_texture = b.tex("cm/posters.png"); m.roughness = 0.35
		"menu":
			m.albedo_texture = b.tex("cm/menu.png"); m.roughness = 0.4
			K.emit_tex(m, 0.7)
		"shade":
			m.albedo_color = Color("#c8401e"); m.roughness = 0.3
			K.emit(m, Color("#e05a20"), 0.5)
		"glow":
			m.albedo_color = Color("#fff4e0")
			K.emit(m, Color("#fff0d8"), 2.0)
		"glass":
			m.albedo_color = Color(0.86, 0.92, 0.94, 0.2); m.roughness = 0.05; m.metallic_specular = 0.9
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_:
			return false
	return true
