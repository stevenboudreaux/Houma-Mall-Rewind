## Wicked Wingz (2026, store s64: the 1995 Chick-fil-A unit, 8 m of frontage on the Concourse's
## south side between the vacant aqua-tile unit and the black vacant front). Steven (Oct 28):
## "same stall and same layout as Chick-fil-A, a little older-looking". Built from his Oct 23
## 2026 footage: IMG_4441 f003-f006 (the counter square on), IMG_4461 f028-f034 (from the hall),
## the sign crop wingz_IMG_4441_f006.jpg. Notes and guesses: design/storefronts/wicked-wingz-2026.md.
##
## What the footage shows: the whole front open under a cream soffit (no storefront glass), a
## black panel with yellow WICKED WINGZ on the soffit (y26/parts/wingz.json), an eggcrate grille
## strip just inside; grey 12" floor tile from the front line; a long counter facing the hall
## about 2 m in, faced in white 4" tile with a row of black accent tiles, a black kick, a
## copper-edged steel top and a steel-post sneeze guard carrying four black printed panels; the
## kitchen behind it (a white wall with a porthole swing door, a steel hood over the fryers),
## a hanging band of five lit menu boards; to the left (east) the white dining room: chair rail,
## white two-tops, yellow molded chairs, a wall TV, a door at the back with a wire rack by it,
## a lay-in ceiling with a dark trim band (Chick-fil-A's, kept). The red A-frame menu stands in
## front.
##
## Frame (as tools/stores/cfa/store.gd): P(u, y, d) = a + t u - n d + y up; u along the frontage
## from x -102 (the right hand of someone facing the store, west), d into the store.
## Materials "ww_<key>" (build_mall.gd's mat() calls fill_mat), textures tex/ww/ (paint.py).

const K = preload("res://tools/stores/media/kit.gd")
const S26 = preload("res://tools/stores/signs/sign_2026.gd")
const UP = Vector3.UP
const W = 8.0
const SIDE = 0.12
const SOFF = 3.0          # bottom of the cream front soffit
const CEIL = 2.9          # the store's lay-in ceiling
const CF = 1.9            # the counter's customer face (d)
const CD = 0.7            # counter depth
const CU1 = 4.75          # the counter's straight run ends here (then a 45-degree corner)
const KW = 5.25           # the kitchen / dining partition (u)
const BACK = 7.2          # the back wall of the kitchen and the dining room (the door is in it)
const TOP_Y = 1.02
const GS = "ww_shell"     # baked: floor, walls, ceiling, front
const G = "ww_fix"        # baked: counter, furniture
const GK = "ww_kitchen"   # baked: the kitchen line
const SM = "ww_small"     # baked: small things
const DY = "wwf_dyn"      # unbaked: lit menu, guard panels, glass

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

## A textured wall quad on the plane u = const (facing +u if `f` > 0) or d = const.
static func wall_u(g, m, u, d0, d1, y0, y1, f, tile_w, tile_h):
	var pts = [P(u, y0, d0), P(u, y0, d1), P(u, y1, d1), P(u, y1, d0)]
	var uvs = [Vector2(d0 / tile_w, -y0 / tile_h), Vector2(d1 / tile_w, -y0 / tile_h), Vector2(d1 / tile_w, -y1 / tile_h), Vector2(d0 / tile_w, -y1 / tile_h)]
	bb.quad(g, m, pts, tt * f, uvs)

static func wall_d(g, m, d, u0, u1, y0, y1, f, tile_w, tile_h, dyn = false):
	var pts = [P(u0, y0, d), P(u1, y0, d), P(u1, y1, d), P(u0, y1, d)]
	var uvs = [Vector2(u0 / tile_w, -y0 / tile_h), Vector2(u1 / tile_w, -y0 / tile_h), Vector2(u1 / tile_w, -y1 / tile_h), Vector2(u0 / tile_w, -y1 / tile_h)]
	bb.quad(g, m, pts, -nn * f, uvs, dyn)

static func ob(u0, d0, u1, d1, pad = 0.1):
	K.ob(bb, P(u0, 0, d0), P(u1, 0, d1), pad)

# ------------------------------------------------------------------ entry point
static func build(b, g, e, a, b2, n, t, Ln, sd):
	bb = b
	a0 = a
	tt = t
	nn = n
	front()
	shell()
	counter()
	kitchen()
	dining()
	var rp = ReflectionProbe.new()
	rp.position = P(W * 0.5, 1.5, BACK * 0.5)
	rp.size = (t * W + n * BACK).abs() + Vector3(0.1, 3.1, 0.1)
	rp.box_projection = true
	rp.interior = true
	rp.update_mode = ReflectionProbe.UPDATE_ONCE
	rp.intensity = 0.5
	b.light_root.add_child(rp)

# ------------------------------------------------------------------ the front
static func front():
	var fz = -0.14
	# the cream soffit over the whole open front, with a 0.5 m underside, and the square piers
	bx(GS, "ww_cream", 0.0, SOFF, fz, W, bb.LANE_H - SOFF, 0.5)
	for u in [0.0, W - 0.32]:
		bx(GS, "ww_cream", u, 0.0, fz, 0.32, SOFF, 0.46, ["-y"])
		col("#8a8478")
		bx(SM, "vcolor", u - 0.005, 0.0, fz - 0.005, 0.33, 0.1, 0.47, ["-y"])
		col("#ffffff")
	# the eggcrate grille strip just inside the soffit (f006, IMG_4461 f033), lit
	var gq = [P(0.32, SOFF - 0.004, 0.36), P(W - 0.32, SOFF - 0.004, 0.36), P(W - 0.32, SOFF - 0.004, 0.68), P(0.32, SOFF - 0.004, 0.68)]
	bb.quad(DY, "ww_louver", gq, Vector3.DOWN, [Vector2(0, 0), Vector2((W - 0.64) / 0.5, 0), Vector2((W - 0.64) / 0.5, 1), Vector2(0, 1)], true)
	bx(GS, "ww_cream", 0.32, CEIL, 0.68, W - 0.64, SOFF - CEIL, 0.04)
	bx(GS, "ww_cream", 0.32, CEIL, 0.32, W - 0.64, SOFF - CEIL, 0.04)
	var l = bb.add_omni(P(W * 0.5, 2.6, 0.5), 0.45, 3.0, Color(1.0, 0.98, 0.94))
	bb.tag(l, "", 0.35, 0.45)
	# the sign: the black panel and yellow letters (Demo 43 spec y26/parts/wingz.json) centred over
	# the counter, its foot level with the soffit's
	S26.build(bb, "ww_sg26", "WICKED WINGZ", P(2.75, SOFF + 0.72, fz - 0.005), nn, 2.6, 1.5)
	aframe(4.35, -0.55)

## The red sidewalk A-frame with the printed menu (f004-f006), standing in front of the counter.
static func aframe(u, d):
	var c = P(u, 0, d)
	var f = -nn
	var r = tt
	for side in [-1.0, 1.0]:
		var basis = Basis(r, UP, f).rotated(r, -side * 0.2)
		var o = c + f * side * 0.14
		var xf = Transform3D(basis, o)
		col("#8c1c1c")
		bb.box(SM, "vcolor", Vector3(0, 0.55, 0), Vector3(0.62, 1.1, 0.03), xf)
		col("#ffffff")
		var face = o + basis * Vector3(0, 0, -0.017 * side)
		var nrm = basis * Vector3(0, 0, -side)
		var rr = basis * Vector3(1, 0, 0) * (-side)
		var up = basis * Vector3(0, 1, 0)
		var cc = face + up * 0.62
		bb.quad(SM, "ww_aframe", [cc - rr * 0.24 - up * 0.36, cc + rr * 0.24 - up * 0.36, cc + rr * 0.24 + up * 0.36, cc - rr * 0.24 + up * 0.36], nrm,
			[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])
	ob(u - 0.35, d - 0.35, u + 0.35, d + 0.35, 0.02)

# ------------------------------------------------------------------ the room
static func shell():
	var u0 = SIDE
	var u1 = W - SIDE
	# grey tile from the front line back
	var fp = [P(u0, 0, 0.0), P(u1, 0, 0.0), P(u1, 0, BACK), P(u0, 0, BACK)]
	var fuv = []
	for p in fp:
		fuv.append(Vector2(p.x / 0.6, p.z / 0.6))
	bb.quad(GS, "ww_floor", fp, UP, fuv)
	# lay-in ceiling, troffers over the counter, the kitchen and the dining strip
	var cp = [P(u0, CEIL, 0.68), P(u1, CEIL, 0.68), P(u1, CEIL, BACK), P(u0, CEIL, BACK)]
	var cuv = []
	for p in cp:
		cuv.append(Vector2(p.x / 0.61, p.z / 1.22))
	bb.quad(GS, "kb_ceiling", cp, Vector3.DOWN, cuv)
	var j = 0
	for tr in [[1.0, 1.0], [3.4, 1.0], [6.3, 1.4], [1.4, 4.0], [3.6, 4.0], [6.3, 3.6], [6.3, 5.7]]:
		var uu = tr[0]
		var dd = tr[1]
		var tq = [P(uu, CEIL - 0.006, dd), P(uu + 0.61, CEIL - 0.006, dd), P(uu + 0.61, CEIL - 0.006, dd + 1.22), P(uu, CEIL - 0.006, dd + 1.22)]
		bb.quad(GS, "gb_troffer", tq, Vector3.DOWN, [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)])
		if j % 2 == 0 or uu > 6.0:
			var l = bb.add_spot(P(uu + 0.3, CEIL - 0.08, dd + 0.61), Vector3.DOWN, 1.0, 5.0, 62.0, Color(1.0, 0.97, 0.92))
			bb.tag(l, "", 1.0, 1.0)
		j += 1
	# older than it was: two water-stained ceiling tiles
	for s in [[4.9, 1.4], [6.9, 4.8]]:
		col("#b8a888")
		bb.quad(SM, "vcolor_matte", [P(s[0], CEIL - 0.003, s[1]), P(s[0] + 0.55, CEIL - 0.003, s[1]), P(s[0] + 0.55, CEIL - 0.003, s[1] + 0.5), P(s[0], CEIL - 0.003, s[1] + 0.5)], Vector3.DOWN)
	col("#ffffff")
	# the dark trim band round the dining room (Chick-fil-A's, still there in f006)
	bx(G, "ww_trim", u1 - 0.03, CEIL - 0.12, 0.68, 0.03, 0.12, BACK - 0.68)
	bx(G, "ww_trim", KW, CEIL - 0.12, BACK - 0.03, u1 - KW, 0.12, 0.03)
	# walls: east (dining) white with a chair rail; west (kitchen) white FRP; the back wall
	wall_u(GS, "ww_wall", u1, BACK, 0.0, 0.0, CEIL, -1.0, 1.0, 1.0)
	wall_u(GS, "ww_wall", u0, 0.0, BACK, 0.0, CEIL, 1.0, 1.0, 1.0)
	wall_d(GS, "ww_wall", BACK, u1, u0, 0.0, CEIL, -1.0, 1.0, 1.0)
	bx(G, "ww_white", u1 - 0.025, 0.9, 0.3, 0.025, 0.06, BACK - 0.3)
	bx(G, "ww_white", KW, 0.9, BACK - 0.025, u1 - KW, 0.06, 0.025)
	col("#2a2a2a")
	bx(SM, "vcolor", u1 - 0.012, 0.0, 0.3, 0.012, 0.1, BACK - 0.3)
	col("#ffffff")
	# the side walls' fronts (the party walls behind the piers)
	bx(GS, "ww_cream", 0.0, 0.0, 0.32, SIDE, SOFF, BACK - 0.32, ["-y"])
	bx(GS, "ww_cream", W - SIDE, 0.0, 0.32, SIDE, SOFF, BACK - 0.32, ["-y"])
	# the back of house beyond BACK is not walkable
	ob(0.0, BACK - 0.05, W, BACK + 1.0, 0.0)

# ------------------------------------------------------------------ the counter
static func counter():
	var d0 = CF
	var d1 = CF + CD
	var u0 = SIDE
	# the straight run: a body, the tiled customer face, a black kick, the steel top with its
	# copper edge
	bx(G, "ww_white", u0, 0.12, d0, CU1 - u0, TOP_Y - 0.12, CD, ["-y"])
	col("#141414")
	bx(G, "vcolor", u0, 0.0, d0 + 0.06, CU1 - u0, 0.12, CD - 0.06, ["-y"])
	col("#ffffff")
	tile_face(P(u0, 0.12, d0), tt, nn, CU1 - u0)
	bx(G, "wl_steel", u0, TOP_Y, d0 - 0.04, CU1 - u0 + 0.02, 0.04, CD + 0.06)
	bx(G, "ww_copper", u0, TOP_Y - 0.025, d0 - 0.05, CU1 - u0, 0.03, 0.012)
	# the 45-degree corner to the partition
	var c0 = P(CU1, 0, d0)
	var c1 = P(KW, 0, d0 + (KW - CU1))
	var dirc = (c1 - c0).normalized()
	var len_c = (c1 - c0).length()
	var nrm_c = dirc.cross(UP)
	if nrm_c.dot(-nn) > 0.0:
		nrm_c = -nrm_c
	var zc = dirc.cross(UP)
	var bas = Basis(dirc, UP, zc)
	var away = sign((-nrm_c).dot(zc))
	var mid = (c0 + c1) * 0.5 - nrm_c * (CD * 0.5)
	bb.box(G, "ww_white", Vector3(0, (TOP_Y + 0.12) * 0.5, 0), Vector3(len_c, TOP_Y - 0.12, CD), Transform3D(bas, mid))
	col("#141414")
	bb.box(G, "vcolor", Vector3(0, 0.06, 0.03 * away), Vector3(len_c, 0.12, CD - 0.06), Transform3D(bas, mid))
	col("#ffffff")
	bb.box(G, "wl_steel", Vector3(0, TOP_Y + 0.02, -0.01 * away), Vector3(len_c + 0.1, 0.04, CD + 0.06), Transform3D(bas, mid))
	tile_face(c0 + nrm_c * 0.001, dirc, nrm_c, len_c)
	# the sneeze guard: steel posts, the four black printed panels, glass over them
	var gu0 = 0.35
	var gu1 = CU1 - 0.1
	var gy0 = TOP_Y + 0.05
	var gd = d0 + 0.08
	var nposts = 5
	for k in nposts:
		var uu = gu0 + (gu1 - gu0) * k / float(nposts - 1)
		bb.cyl(SM, "wl_steel", P(uu, TOP_Y + 0.04, gd + 0.02), 0.018, 0.018, 0.58, 8, true, false)
	K.fq(bb, DY, "ww_guard", P(0, 0, 0), tt, nn, gu0, gu1, gy0, gy0 + 0.36, -(gd), 0.0, 0.0, 1.0, 1.0, true)
	var gq = [P(gu0, gy0 + 0.36, gd), P(gu1, gy0 + 0.36, gd), P(gu1, gy0 + 0.56, gd + 0.04), P(gu0, gy0 + 0.56, gd + 0.04)]
	bb.quad(DY, "ww_glass", gq, -nn, [], true)
	bx(SM, "wl_steel", gu0, gy0 + 0.55, gd + 0.02, gu1 - gu0, 0.02, 0.04)
	# registers facing the hall and a card reader, cups and napkins
	for u in [1.3, 3.4]:
		K.register(bb, SM, P(u, TOP_Y + 0.04, d0 + 0.45), -tt, nn)
	col("#f4f2ec")
	bb.cyl(SM, "vcolor", P(2.3, TOP_Y + 0.04, d0 + 0.4), 0.045, 0.05, 0.3, 10, true, false)
	col("#c8202a")
	bb.cyl(SM, "vcolor", P(2.5, TOP_Y + 0.04, d0 + 0.42), 0.04, 0.045, 0.14, 10, true, false)
	col("#ffffff")
	ob(0.0, d0 - 0.06, KW, d1 + 0.6, 0.06)
	# the hanging menu band: a dark box, five lit boards (f006)
	var md = CF + 1.7
	bx(G, "ww_black", 0.4, 2.28, md, 4.6, 0.5, 0.12)
	K.fq(bb, DY, "ww_menu", P(0, 0, 0), tt, nn, 0.45, 4.95, 2.31, 2.75, -(md - 0.004), 0.0, 0.0, 1.0, 1.0, true)
	col("#3a3a3c")
	for u in [0.8, 4.6]:
		bb.cyl(SM, "vcolor", P(u, 2.78, md + 0.06), 0.006, 0.006, CEIL - 2.78, 4, false, false)
	col("#ffffff")
	var lm = bb.add_omni(P(2.7, 2.2, md - 0.8), 0.35, 3.0, Color(1.0, 0.86, 0.7))
	bb.tag(lm, "", 0.3, 0.35)

## The counter's tile face: from `o` (bottom-left at the top of the kick) along `r` for `w`,
## facing `f` (towards the customers), 0.9 m tall, one texture tile = 1.2 m.
static func tile_face(o, r, f, w):
	var h = TOP_Y - 0.12 - 0.02
	var p = o + f * 0.004
	bb.quad(G, "ww_tile", [p, p + r * w, p + r * w + UP * h, p + UP * h], f,
		[Vector2(0, 1), Vector2(w / 1.2, 1), Vector2(w / 1.2, 1.0 - h / 0.9), Vector2(0, 1.0 - h / 0.9)])

# ------------------------------------------------------------------ the kitchen
static func kitchen():
	var u0 = SIDE
	var kd = 5.0     # the kitchen's back wall (white FRP, the porthole door in it)
	bx(GS, "ww_white", u0, 0.0, kd, KW - u0, CEIL, 0.1)
	# the swing door with its porthole (f006), steel kick plate
	var du = 1.1
	col("#5a5a5c")
	bx(G, "vcolor", du - 0.05, 0.0, kd - 0.03, 1.0, 2.15, 0.03)
	col("#2a2a2c")
	bx(G, "vcolor", du, 0.0, kd - 0.04, 0.9, 2.08, 0.02)
	col("#ffffff")
	bb.cyl(SM, "ww_glass", P(du + 0.45, 1.45, kd - 0.045) - Vector3.ZERO, 0.13, 0.13, 0.005, 16, true, true)
	bx(SM, "wl_steel", du + 0.02, 0.0, kd - 0.045, 0.86, 0.3, 0.005)
	# the partition between the kitchen and the dining room
	bx(GS, "ww_white", KW, 0.0, CF + CD + (KW - CU1) - 0.05, 0.1, CEIL, BACK - (CF + CD + (KW - CU1) - 0.05))
	# the line along the back wall: two fryers, a flat top, a holding cabinet, under the hood
	var ld = kd - 0.75
	for k in 3:
		var uu = 2.3 + k * 0.65
		bx(GK, "wl_steel", uu, 0.0, ld, 0.6, 0.92, 0.75, ["-y"])
		col("#1e1e20")
		bx(SM, "vcolor", uu + 0.04, 0.6, ld - 0.005, 0.52, 0.2, 0.005)
		col("#ffffff")
	col("#18181a")
	bx(SM, "vcolor", 2.35, 0.92, ld + 0.08, 0.5, 0.01, 0.5)
	bx(SM, "vcolor", 3.0, 0.92, ld + 0.08, 0.5, 0.01, 0.5)
	col("#ffffff")
	bx(GK, "wl_steel", 4.3, 0.0, ld + 0.1, 0.85, 1.5, 0.65, ["-y"])
	col("#202024")
	for r in 3:
		bx(SM, "vcolor", 4.36, 0.25 + r * 0.42, ld + 0.095, 0.73, 0.34, 0.005)
	col("#ffffff")
	# the hood
	bx(GK, "wl_steel", 2.1, 1.95, kd - 1.05, 2.1, 0.55, 1.05)
	col("#3a3a3c")
	bx(SM, "vcolor", 2.2, 1.949, kd - 0.95, 1.9, 0.005, 0.85)
	col("#ffffff")
	# a shelf of squeeze bottles over the pass (red, green, white), a steel pass table behind
	# the counter
	bx(GK, "wl_steel", 0.3, 0.0, CF + CD + 0.35, 4.2, 0.9, 0.6, ["-y"])
	bx(SM, "wl_steel", 2.3, 1.55, kd - 0.25, 1.4, 0.03, 0.22)
	for k in 6:
		col(["#c8202a", "#3a9a3a", "#f2f0e8"][k % 3])
		bb.cyl(SM, "vcolor", P(2.45 + k * 0.22, 1.58, kd - 0.14), 0.035, 0.03, 0.2, 8, true, false)
	col("#ffffff")
	for k in 3:
		var c = P(1.0 + k * 1.3, 1.6, CF + CD + 0.65)
		bb.cyl(SM, "ww_lamp", c, 0.1, 0.05, 0.22, 12, true, false)
		col("#3a3a3c")
		bb.cyl(SM, "vcolor", c + UP * 0.22, 0.006, 0.006, CEIL - 1.82, 4, false, false)
		col("#ffffff")
		bb.cyl(SM, "ww_heatglow", c + UP * 0.01, 0.08, 0.08, 0.005, 12, false, true)
	var l = bb.add_omni(P(2.6, 2.3, 3.8), 0.55, 4.0, Color(1.0, 0.95, 0.88))
	bb.tag(l, "", 0.45, 0.55)
	ob(0.0, CF + CD, KW + 0.1, BACK, 0.05)

# ------------------------------------------------------------------ the dining room
static func dining():
	var u1 = W - SIDE
	# white two-tops with yellow chairs down the strip, one against the wall
	for d in [1.3, 3.4, 5.5]:
		two_top(6.55, d)
	# the TV on the east wall (f006), a wire rack by the back door, the door
	var tc = P(u1 - 0.05, 2.1, 2.6)
	col("#111111")
	bb.box(SM, "vcolor", tc, bb.abs_size(tt, 0.06, 0.62, 1.06, nn))
	K.fq(bb, DY, "ww_tv", P(u1 - 0.081, 0, 2.6), -nn, -tt, -0.5, 0.5, 1.82, 2.38, 0.0, 0.0, 0.0, 1.0, 1.0, true)
	var du = 6.2
	col("#c8b49a")
	bx(G, "vcolor", du, 0.0, BACK - 0.05, 0.92, 2.1, 0.05)
	col("#6a5a48")
	bx(SM, "vcolor", du + 0.15, 0.08, BACK - 0.06, 0.62, 0.42, 0.01)
	col("#f0ece2")
	bx(SM, "vcolor", du - 0.06, 0.0, BACK - 0.07, 0.06, 2.16, 0.07)
	bx(SM, "vcolor", du + 0.92, 0.0, BACK - 0.07, 0.06, 2.16, 0.07)
	bx(SM, "vcolor", du - 0.06, 2.1, BACK - 0.07, 1.04, 0.06, 0.07)
	col("#202020")
	bx(SM, "vcolor", du + 0.3, 1.85, BACK - 0.075, 0.32, 0.08, 0.01)
	col("#ffffff")
	rack(KW + 0.35, BACK - 0.5)
	# a trash can by the door
	col("#1a1a1a")
	bb.cyl(SM, "vcolor", P(7.5, 0, BACK - 0.4), 0.22, 0.24, 0.85, 14, true, false)
	col("#ffffff")
	ob(7.25, BACK - 0.65, 7.75, BACK - 0.15, 0.02)
	var l = bb.add_omni(P(6.6, 2.3, 3.5), 0.5, 6.0, Color(1.0, 0.95, 0.88))
	bb.tag(l, "", 0.4, 0.5)

## A black wire shelving rack (four shelves) with boxes on it.
static func rack(u, d):
	col("#1a1a1c")
	for q in [[0, 0], [0.9, 0], [0, 0.45], [0.9, 0.45]]:
		bx(SM, "vcolor", u + q[0], 0.0, d + q[1] - 0.45, 0.02, 1.6, 0.02)
	for k in 4:
		bx(SM, "vcolor", u, 0.15 + k * 0.45, d - 0.45, 0.92, 0.02, 0.47)
	col("#e8e4da")
	for k in 3:
		bx(SM, "vcolor", u + 0.1, 0.17 + k * 0.45, d - 0.38, 0.35, 0.18, 0.3)
		bx(SM, "vcolor", u + 0.5, 0.17 + k * 0.45, d - 0.36, 0.3, 0.12, 0.28)
	col("#ffffff")
	ob(u, d - 0.45, u + 0.92, d, 0.04)

## A white laminate two-top on a black pedestal, a yellow chair each side (along d).
static func two_top(u, d):
	var c = P(u, 0, d)
	col("#1c1c1e")
	bb.cyl(SM, "vcolor", c, 0.22, 0.22, 0.03, 10, true, false)
	bb.cyl(SM, "vcolor", c, 0.035, 0.035, 0.72, 8, false, false)
	col("#ffffff")
	bx(G, "ww_white", u - 0.38, 0.72, d - 0.38, 0.76, 0.035, 0.76)
	col("#9a9a9a")
	bx(SM, "vcolor", u - 0.385, 0.715, d - 0.385, 0.77, 0.012, 0.77)
	col("#ffffff")
	chair(u, d - 0.68, 1.0)
	chair(u, d + 0.68, -1.0)
	ob(u - 0.42, d - 0.95, u + 0.42, d + 0.95, 0.04)

## A yellow molded-shell chair on four chrome legs, facing +d (f = 1) or -d.
static func chair(u, d, f):
	var fw = -nn * f
	var r = tt
	var c = P(u, 0, d)
	col("#c8c8cc")
	for q in [Vector2(-0.18, -0.17), Vector2(0.18, -0.17), Vector2(-0.18, 0.17), Vector2(0.18, 0.17)]:
		bb.box(SM, "vcolor", c + r * q.x + fw * q.y + UP * 0.22, Vector3(0.02, 0.44, 0.02))
	col("#ffffff")
	var bas = Basis(r, UP, r.cross(UP))
	bb.box(G, "ww_yellow", Vector3(0, 0.46, 0), Vector3(0.44, 0.035, 0.42), Transform3D(bas, c))
	bb.box(G, "ww_yellow", Vector3(0, 0.22, 0), Vector3(0.44, 0.42, 0.035), Transform3D(bas, c - fw * 0.21 + UP * 0.48))

# ------------------------------------------------------------------ materials
## "ww_<key>" (build_mall.gd's mat() calls this).
static func fill_mat(m, key, b):
	match key:
		"cream":
			m.albedo_color = Color("#e6dcc6"); m.roughness = 0.8
		"white":
			m.albedo_color = Color("#ebe8de"); m.roughness = 0.55
		"black":
			m.albedo_color = Color("#151515"); m.roughness = 0.6
		"trim":
			m.albedo_color = Color("#3a2a20"); m.roughness = 0.55
		"copper":
			m.albedo_color = Color("#a8643a"); m.metallic = 0.6; m.roughness = 0.35
		"yellow":
			m.albedo_color = Color("#f2c02a"); m.roughness = 0.4; m.metallic_specular = 0.6
		"wall":
			m.albedo_texture = b.tex("ww/wall.png"); m.roughness = 0.85
		"floor":
			m.albedo_texture = b.tex("ww/floor.png"); m.roughness = 0.35; m.metallic_specular = 0.55
		"tile":
			m.albedo_texture = b.tex("ww/counter_tile.png"); m.roughness = 0.2; m.metallic_specular = 0.7
		"aframe":
			m.albedo_texture = b.tex("ww/aframe.png"); m.roughness = 0.5
		"guard":
			m.albedo_texture = b.tex("ww/guard.png"); m.roughness = 0.3; m.metallic_specular = 0.6
		"menu":
			m.albedo_texture = b.tex("ww/menu.png"); m.roughness = 0.4
			K.emit_tex(m, 0.9)
		"tv":
			m.albedo_texture = b.tex("ww/tv.png")
			K.emit_tex(m, 0.8)
		"louver":
			m.albedo_texture = b.tex("ww/louver.png")
			K.emit_tex(m, 1.1)
		"glass":
			m.albedo_color = Color(0.85, 0.92, 0.92, 0.22); m.roughness = 0.05; m.metallic_specular = 0.9
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		"lamp":
			m.albedo_color = Color("#9a9a9e"); m.metallic = 0.7; m.roughness = 0.3
		"heatglow":
			m.albedo_color = Color("#ffb070")
			K.emit(m, Color("#ff8a40"), 1.6)
		_:
			return false
	return true
