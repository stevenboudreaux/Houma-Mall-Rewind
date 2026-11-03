## The Wave 8 shops, from the Southland facade records (Steven's photos, ads and memory) and
## the game's own flat fronts: Cucos Border Cafe (s42) facing the Sears hall; Claire's
## Boutiques (s30, a corner open north and west) and Mitchell's Formal Wear (s31) beside it;
## Tee Tai's (s35) and Optical Outlet (s36) facing south onto the hall by Orange Julius;
## Saadi's (s20) on the east hall; Golden Chain Gang (s62) by the Concourse. Specs:
## design/storefronts/cucos.md, claires.md, mitchells.md, tee-tais.md, optical-outlet.md,
## saadis.md, golden-chain-gang.md. Insides are period types on the kits; layouts guessed.
##
## Frame: P(a, t, n, u, y, d) = a + t u - n d + y up, u along the frontage, d into the store.

const CH = preload("res://tools/stores/signs/channel.gd")
const K = preload("res://tools/stores/media/kit.gd")
const AK = preload("res://tools/stores/apparel/kit.gd")
const M2 = preload("res://tools/stores/apparel/more.gd")
const S1 = preload("res://tools/stores/small/store.gd")
const S2 = preload("res://tools/stores/small/store2.gd")
const W7 = preload("res://tools/stores/small/wave7.gd")
const UP = Vector3.UP
const SIDE = 0.12
const LET = "res://tools/stores/small/"

static func P(a, t, n, u, y, d):
	return a + t * u - n * d + Vector3(0, y, 0)

static func build(b, g, e, a, bb, n, t, Ln, sd):
	var rng = RandomNumberGenerator.new()
	rng.seed = 800 + int(Ln * 10)
	var W = Ln
	var D = 10.0
	match sd.name:
		"CUCOS BORDER CAFE":
			D = 16.0
			# laid out from the viewer's left (the bar on the right, as on the flat front)
			var a2 = a
			var t2 = t
			if (-n).cross(UP).dot(t) < 0.0:
				a2 = a + t * W
				t2 = -t
			cucos(b, a2, t2, n, W, D, rng)
			W7.probe(b, a2, t2, n, W, D)
			return
		"CLAIRE'S BOUTIQUES":
			if abs(n.x) > 0.5:
				return   # the corner's west edge: built with the north one
			D = 10.0
			claires(b, a, t, n, W, D, rng)
		"OPTICAL OUTLET":
			optical(b, a, t, n, W, D, rng)
		"TEE TAI'S":
			D = 8.0
			tee_tai(b, a, t, n, W, D, rng)
		"SAADI'S":
			D = 14.0
			saadi(b, a, t, n, W, D, rng)
		"MITCHELL'S FORMAL WEAR":
			D = 12.0
			mitchell(b, a, t, n, W, D, rng)
		"GOLDEN CHAIN GANG":
			D = 8.0
			gcg(b, a, t, n, W, D, rng)
	W7.probe(b, a, t, n, W, D)

## A textured panel facing the hall, centred on u = `uc` (shifted `shift` along the
## viewer's right), `w` wide, from y0 to y1, at depth d (negative: proud of the front).
static func sign_q(b, G, m, a, t, n, uc, w, y0, y1, d, ub = 1.0, shift = 0.0, dyn = false):
	var rv = (-n).cross(UP)
	K.fq(b, G, m, P(a, t, n, uc, 0, d) - rv * (w * 0.5 - shift), rv, n, 0.0, w, y0, y1, 0.0, 0.0, 0.0, ub, 1.0, dyn)

## A pane of glass across the front from u0 to u1.
static func glass(b, a, t, n, u0, u1, y0, y1, d):
	b.quad("glass", "glass", [P(a, t, n, u0, y0, d), P(a, t, n, u1, y0, d), P(a, t, n, u1, y1, d), P(a, t, n, u0, y1, d)], n,
		[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)], true)

## A post of the front, centred on u, from y0 to y1.
static func post(b, G, m, a, t, n, u, w, y0, y1, d, dp = 0.1):
	b.box(G, m, P(a, t, n, u, (y0 + y1) * 0.5, d), b.abs_size(t, w, y1 - y0, dp, n))

## A full-height pier of the front from u0 to u1, `dp` deep, standing proud of the line.
static func pier(b, G, m, a, t, n, u0, u1, head, dp):
	b.box(G, m, P(a, t, n, (u0 + u1) * 0.5, head * 0.5, -dp * 0.5), b.abs_size(t, u1 - u0, head, dp, n), Transform3D.IDENTITY, ["-y"])
	K.ob(b, P(a, t, n, u0, 0, -dp), P(a, t, n, u1, 0, 0.0), 0.05)

## A dark glass storefront from u0 to u1: a low kick, black frames, a doorway (dw wide,
## centred on du) left open.
static func glass_front(b, G, a, t, n, u0, u1, head, du, dw, frame_mat = "md_black", kick = 0.3):
	var d0 = du - dw * 0.5
	var d1 = du + dw * 0.5
	for seg in [[u0, d0], [d1, u1]]:
		if seg[1] - seg[0] < 0.1:
			continue
		b.box(G, frame_mat, P(a, t, n, (seg[0] + seg[1]) * 0.5, kick * 0.5, 0.0), b.abs_size(t, seg[1] - seg[0], kick, 0.12, n), Transform3D.IDENTITY, ["-y"])
		glass(b, a, t, n, seg[0], seg[1], kick, head, -0.01)
		var cnt = max(1, int(round((seg[1] - seg[0]) / 1.6)))
		for k in cnt + 1:
			post(b, G, frame_mat, a, t, n, seg[0] + (seg[1] - seg[0]) * k / cnt, 0.06, kick, head, 0.0)
		K.ob(b, P(a, t, n, seg[0], 0, -0.1), P(a, t, n, seg[1], 0, 0.1), 0.05)
	b.box(G, frame_mat, P(a, t, n, (u0 + u1) * 0.5, head - 0.04, 0.0), b.abs_size(t, u1 - u0, 0.08, 0.12, n))
	for u in [d0, d1]:
		post(b, G, frame_mat, a, t, n, u, 0.08, 0.0, head, 0.0, 0.14)

## A ceiling spot with its can, warm white.
static func spot(b, G, c, energy = 1.2, rng = 6.0, angle = 56.0):
	b.cyl(G, "gb_can", c + UP * 0.0, 0.09, 0.09, 0.01, 10, false, true)
	var l = b.add_spot(c - UP * 0.04, Vector3.DOWN, energy, rng, angle, Color(1.0, 0.95, 0.86))
	b.tag(l, "", energy, energy)

## The Cucos sign (Steven, Oct 7: "the most accurate neon Cucos Mexican Cafe sign"): the open-face
## neon channel script over the blue MEXICAN CAFE cabinet, traced from his photos and built as the
## real one is (tools/stores/signs/cucos_sign.gd), centred on the plank parapet above the teal line.
static func cucos_sign(b, a, t, n, W, head):
	var c = P(a, t, n, W * 0.5, head + 0.15, -0.34)
	load("res://tools/stores/signs/cucos_sign.gd").build(b, "w8cf_sign", "res://tools/stores/signs/cu_sign.json", c, n)

# ------------------------------------------------------------------ Cucos Border Cafe
## Warm vertical wood planks with teal-green trim and a stepped parapet; the sign board with
## pale peach stripes behind the big red swash name and MEXICAN CAFE; heavy wood lintels over
## dark double doors; a clay-tile awning on a green fascia over white-mullioned windows each
## side (record). Inside: saltillo tile, adobe walls under dark beams, booths and tables,
## papel picado, the bar on the right.
static func cucos(b, a, t, n, W, D, rng):
	var F = "w8cf_props"
	var G = "w8c_fix"
	var head = 2.9
	var mid = W * 0.5
	S1.upper(b, F, a, t, n, W, head, "w8_planks", 0.2)
	# the stepped parapet: a raised plank panel in the middle, teal caps stepping down each side
	b.box(F, "w8_planks", P(a, t, n, mid, (head + b.LANE_H) * 0.5, -0.27), b.abs_size(t, 5.4, b.LANE_H - head, 0.14, n), Transform3D.IDENTITY, ["-y"])
	for s in [-1.0, 1.0]:
		b.box(F, "w8_teal", P(a, t, n, mid + s * 2.72, (head + b.LANE_H) * 0.5, -0.27), b.abs_size(t, 0.08, b.LANE_H - head, 0.16, n))
		b.box(F, "w8_teal", P(a, t, n, mid + s * (2.7 + (W * 0.5 - 2.7) * 0.5), head + 1.15, -0.22), b.abs_size(t, W * 0.5 - 2.7, 0.08, 0.06, n))
	b.box(F, "w8_teal", P(a, t, n, mid, head + 0.04, -0.3), b.abs_size(t, W, 0.08, 0.2, n))
	cucos_sign(b, a, t, n, W, head)
	# the doorway: plank jambs, a heavy dark lintel, the dark double doors standing open inward
	var dw = 2.4
	for s in [-1.0, 1.0]:
		b.box(F, "w8_dark_wood", P(a, t, n, mid + s * (dw * 0.5 + 0.12), 1.25, -0.12), b.abs_size(t, 0.24, 2.5, 0.28, n), Transform3D.IDENTITY, ["-y"])
		b.box(F, "w8_dark_wood", P(a, t, n, mid + s * (dw * 0.5 - 0.04), 1.2, 0.65), b.abs_size(n, 1.15, 2.4, 0.06, t), Transform3D.IDENTITY, ["-y"])
		b.cur_color = Color("#c8a040")
		b.box(F, "vcolor", P(a, t, n, mid + s * (dw * 0.5 - 0.1), 1.1, 1.1), Vector3(0.04, 0.2, 0.04))
		b.cur_color = Color.WHITE
		K.ob(b, P(a, t, n, mid + s * (dw * 0.5 + 0.24), 0, -0.3), P(a, t, n, mid + s * (dw * 0.5 - 0.1), 0, 1.25), 0.03)
	b.box(F, "w8_dark_wood", P(a, t, n, mid, 2.7, -0.2), b.abs_size(t, dw + 1.0, 0.4, 0.4, n))
	# the windows each side: planks below, white mullions, a green fascia and clay awning above
	var wins = [[0.7, mid - dw * 0.5 - 0.6], [mid + dw * 0.5 + 0.6, W - 0.7]]
	var edges = [0.0, wins[0][0], wins[0][1], mid - dw * 0.5 - 0.24, mid + dw * 0.5 + 0.24, wins[1][0], wins[1][1], W]
	for k in [0, 2, 4, 6]:
		var u0 = edges[k]
		var u1 = edges[k + 1]
		if u1 - u0 > 0.02:
			pier(b, F, "w8_planks", a, t, n, u0, u1, head, 0.2)
	for wn in wins:
		var u0 = wn[0]
		var u1 = wn[1]
		var cu = (u0 + u1) * 0.5
		var ww = u1 - u0
		b.box(F, "w8_planks", P(a, t, n, cu, 0.35, -0.1), b.abs_size(t, ww, 0.7, 0.2, n), Transform3D.IDENTITY, ["-y"])
		b.box(F, "w8_teal", P(a, t, n, cu, 0.72, -0.14), b.abs_size(t, ww + 0.1, 0.05, 0.26, n))
		b.box(F, "w8_planks", P(a, t, n, cu, (2.3 + head) * 0.5, -0.1), b.abs_size(t, ww, head - 2.3, 0.2, n))
		glass(b, a, t, n, u0, u1, 0.74, 2.3, -0.02)
		var m = 0
		while m <= 6:
			post(b, F, "w8_white", a, t, n, u0 + ww * m / 6.0, 0.05, 0.74, 2.3, -0.03, 0.05)
			m += 1
		b.box(F, "w8_white", P(a, t, n, cu, 1.75, -0.03), b.abs_size(t, ww, 0.05, 0.05, n))
		# the awning: clay tile from the wall out over the green fascia board
		var p0 = P(a, t, n, u0 - 0.15, 3.0, -0.2)
		var p1 = P(a, t, n, u1 + 0.15, 3.0, -0.2)
		var p2 = P(a, t, n, u1 + 0.15, 2.6, -0.95)
		var p3 = P(a, t, n, u0 - 0.15, 2.6, -0.95)
		var slope_n = (n * 0.4 + UP * 0.75).normalized()
		var lu = (ww + 0.3) / 0.6
		b.quad(F, "w8_clay", [p3, p2, p1, p0], slope_n, [Vector2(0, 1.4), Vector2(lu, 1.4), Vector2(lu, 0), Vector2(0, 0)])
		b.quad(F, "w8_clay_under", [p0, p1, p2, p3], -slope_n, [Vector2(0, 0), Vector2(lu, 0), Vector2(lu, 1.4), Vector2(0, 1.4)])
		# the barrel-tile ends along the eave, over the green fascia board
		K.fq(b, F, "w8_clay", P(a, t, n, u0 - 0.15, 0, -0.97), t, n, 0.0, ww + 0.3, 2.6, 2.75, 0.0, 0.0, 0.75, lu, 1.0)
		b.box(F, "w8_green", P(a, t, n, cu, 2.48, -0.95), b.abs_size(t, ww + 0.3, 0.24, 0.06, n))
		for s in [u0 - 0.1, u1 + 0.1]:
			b.box(F, "w8_dark_wood", P(a, t, n, s, 2.7, -0.55), b.abs_size(t, 0.08, 0.08, 0.75, n))
		K.ob(b, P(a, t, n, u0, 0, -0.3), P(a, t, n, u1, 0, 0.0), 0.05)
	# the dining room
	M2.shell2(b, "w8c_shell", a, t, n, W, D, 3.0, 0.0, "w8_saltillo", 0.6, "w8_stucco", "w8_ceiling", [], mid, 1.0)
	M2.soffit(b, F, a, t, n, W, head, "w8_dark_wood")
	var d = 1.6
	while d < D - 0.4:
		b.box(G, "w8_dark_wood", P(a, t, n, mid, 2.9, d), b.abs_size(t, W - 2 * SIDE, 0.18, 0.2, n), Transform3D.IDENTITY, ["+y"])
		d += 1.8
	# a teal-tiled wainscot round the room
	for w in [[SIDE + 0.01, 0.4, D - 0.3, t], [W - SIDE - 0.01, D - 0.3, 0.4, -t]]:
		var pa = P(a, t, n, w[0], 0, w[1])
		var pb = P(a, t, n, w[0], 0, w[2])
		b.quad(G, "w8_teal_tile", [pa, pb, pb + UP * 0.9, pa + UP * 0.9], w[3], [Vector2(0, 0.9 / 0.3), Vector2(abs(w[2] - w[1]) / 0.3, 0.9 / 0.3), Vector2(abs(w[2] - w[1]) / 0.3, 0), Vector2(0, 0)])
	var WL = load("res://tools/stores/woolworth/store.gd")
	# booths down the left wall
	for k in 5:
		WL.booth(b, G, P(a, t, n, SIDE, 0, 2.6 + k * 2.4), -n, t, rng)
	# tables and chairs either side of the aisle from the door
	for c in [[3.9, 3.2], [3.9, 6.0], [3.9, 8.8], [3.9, 11.6], [9.4, 3.2], [9.4, 6.0], [9.4, 8.8]]:
		var tc = P(a, t, n, c[0], 0, c[1])
		b.cur_color = Color("#2a2a2c")
		b.cyl(G, "vcolor", tc, 0.22, 0.22, 0.03, 12, true, false)
		b.cyl(G, "vcolor", tc, 0.04, 0.04, 0.72, 8, false, false)
		b.cur_color = Color.WHITE
		b.box(G, "w8_dark_wood", tc + UP * 0.74, Vector3(0.78, 0.04, 0.78))
		b.box(G, "w8_teal_tile", tc + UP * 0.765, Vector3(0.7, 0.012, 0.7), Transform3D.IDENTITY, ["-y"])
		K.ob(b, tc - Vector3(0.39, 0, 0.39), tc + Vector3(0.39, 0, 0.39), 0.15)
		for s in [-1.0, 1.0]:
			wood_chair(b, "w8c_small", tc + t * 0.62 * s, -t * s)
	# the hostess stand by the door
	K.lbox(b, G, "w8_dark_wood", P(a, t, n, mid + 1.9, 0, 1.4), t, -n, 0.0, 0.0, 0.0, 0.6, 1.1, 0.45)
	K.ob_local(b, P(a, t, n, mid + 1.9, 0, 1.4), t, -n, 0.0, 0.0, 0.6, 0.45, 0.05)
	# the bar down the right wall at the back: the back bar of bottles, a counter, red stools
	var bu = W - SIDE
	var bd0 = 6.6
	var bd1 = D - 1.2
	K.lbox(b, G, "w8_dark_wood", P(a, t, n, bu, 0, bd0), -n, -t, 0.0, 0.0, 0.0, bd1 - bd0, 0.9, 0.4)
	K.fq(b, G, "w8_bar", P(a, t, n, bu, 0, bd0), -n, -t, 0.0, bd1 - bd0, 0.95, 2.15, 0.02, 0.0, 0.0, (bd1 - bd0) / 2.4, 1.0)
	var co = P(a, t, n, W - 1.7, 0, bd0 + 0.4)
	K.lbox(b, G, "w8_dark_wood", co, -n, -t, 0.0, 0.0, -0.55, bd1 - bd0 - 0.8, 1.05, 0.55, ["-y"])
	K.lbox(b, G, "w8_teal", co, -n, -t, -0.04, 1.05, -0.6, bd1 - bd0 - 0.72, 0.05, 0.65)
	K.ob(b, P(a, t, n, W - 2.4, 0, bd0 + 0.3), P(a, t, n, W - SIDE, 0, bd1), 0.05)
	var sd = bd0 + 0.9
	while sd < bd1 - 0.6:
		var sc = P(a, t, n, W - 2.45, 0, sd)
		b.cur_color = Color("#2a2a2c")
		b.cyl("w8c_small", "vcolor", sc, 0.03, 0.03, 0.72, 8, false, false)
		b.cyl("w8c_small", "vcolor", sc, 0.18, 0.18, 0.03, 10, true, false)
		b.cur_color = Color.WHITE
		b.cyl("w8c_small", "w8_red_vinyl", sc + UP * 0.72, 0.19, 0.19, 0.08, 12, true, true)
		sd += 0.9
	# --- CUCOS (Nov 3 2026, design/godot-cucos.md): the beer taps, a chrome tower on the bartender's
	# side of the counter top between the two patrons, three handles over a drip tray (the back bar's
	# bottles are the painted w8_bar shelves). No drinks waiting on the bar.
	var tp = P(a, t, n, W - 1.33, 1.1, 9.8)
	b.cur_color = Color("#b8bcc2")
	b.box("w8c_small", "vcolor", tp - (-t) * 0.08 + UP * 0.01, b.abs_size(-n, 0.42, 0.02, 0.16, -t))
	b.cur_color = Color("#2a2a2c")
	b.box("w8c_small", "vcolor", tp - (-t) * 0.08 + UP * 0.025, b.abs_size(-n, 0.38, 0.01, 0.12, -t))
	b.cur_color = Color("#c9ccd2")
	b.cyl("w8c_small", "vcolor", tp, 0.035, 0.035, 0.36, 10, true, false)
	b.box("w8c_small", "vcolor", tp + UP * 0.36, b.abs_size(-n, 0.36, 0.05, 0.05, -t))
	var handles = [Color("#c8202c"), Color("#f2c94c"), Color("#2e7d4f")]
	for k in 3:
		var hp = tp + (-n) * (-0.13 + 0.13 * k) + UP * 0.36
		b.cur_color = Color("#c9ccd2")
		b.box("w8c_small", "vcolor", hp - (-t) * 0.06 - UP * 0.02, b.abs_size(-n, 0.018, 0.018, 0.1, -t))
		b.cyl("w8c_small", "vcolor", hp - (-t) * 0.1 - UP * 0.07, 0.008, 0.008, 0.05, 6, false, true)
		b.cur_color = handles[k]
		b.cyl("w8c_small", "vcolor", hp - (-t) * 0.09 + UP * 0.0, 0.012, 0.016, 0.16, 8, true, false)
	b.cur_color = Color.WHITE
	# --- end CUCOS
	# arched niches on the back wall, either side of the kitchen door
	for nu in [2.4, W - 3.4]:
		arch(b, G, "w8_dark", P(a, t, n, nu, 0, D - SIDE - 0.01), t, n, 1.2, 1.9)
	# papel picado strung across the room
	var pd = 3.0
	while pd < D - 1.0:
		K.fq(b, "w8c_paper", "w8_papel", P(a, t, n, SIDE + 0.05, 0, pd), t, -n, 0.0, W - 2 * SIDE - 0.1, 2.3, 2.75, 0.0, 0.0, 0.0, (W - 0.34) / 4.0, 1.0, true)
		pd += 3.6
	# pendant lamps, warm
	for c in [[3.9, 4.6], [3.9, 10.2], [9.4, 4.6], [9.4, 10.2], [mid, 7.4], [W - 2.4, 11.0]]:
		var lc = P(a, t, n, c[0], 0, c[1])
		b.cur_color = Color("#222222")
		b.cyl(G, "vcolor", lc + UP * 2.45, 0.008, 0.008, 0.45, 4, false, false)
		b.cur_color = Color.WHITE
		b.cyl(G, "w8_copper", lc + UP * 2.2, 0.26, 0.07, 0.25, 14, true, false)
		b.cyl(G, "w8_bulb", lc + UP * 2.17, 0.1, 0.1, 0.03, 10, false, true)
		var l = b.add_omni(lc + UP * 2.0, 0.55, 5.5, Color(1.0, 0.82, 0.58))
		b.tag(l, "", 0.45, 0.6)

## An arched niche painted on a wall at o (r along the wall, f out of it): w wide, h to the
## spring of the half-round head.
static func arch(b, G, m, o, r, f, w, h):
	K.fq(b, G, m, o, r, f, 0.0, w, 0.0, h, 0.0)
	var s = b.st(G, m)
	var c = K.L(o, r, f, w * 0.5, h, 0.0)
	var seg = 10
	for i in seg:
		var a0 = PI * i / seg
		var a1 = PI * (i + 1) / seg
		b.tri(s, c, c + r * (cos(a0) * w * 0.5) + UP * (sin(a0) * w * 0.5), c + r * (cos(a1) * w * 0.5) + UP * (sin(a1) * w * 0.5),
			Vector2(0.5, 0.5), Vector2(0.5, 0.5), Vector2(0.5, 0.5), f)

## A dark wood ladder-back chair facing `f`.
static func wood_chair(b, S, c, f):
	var r = (-f).cross(UP)
	for q in [Vector2(-0.18, -0.18), Vector2(0.18, -0.18), Vector2(-0.18, 0.18), Vector2(0.18, 0.18)]:
		b.box(S, "w8_dark_wood", c + r * q.x + f * q.y + UP * 0.22, Vector3(0.035, 0.44, 0.035))
	b.box(S, "w8_rush", c + UP * 0.46, b.abs_size(r, 0.42, 0.05, 0.42, f))
	for sd in [-0.18, 0.18]:
		b.box(S, "w8_dark_wood", c - f * 0.19 + r * sd + UP * 0.7, Vector3(0.035, 0.5, 0.035))
	for y in [0.62, 0.78, 0.92]:
		b.box(S, "w8_dark_wood", c - f * 0.19 + UP * y, b.abs_size(r, 0.36, 0.05, 0.02, f))

# ------------------------------------------------------------------ Claire's
## A wall of pink-veined cream marble, a white sign box with the name in tall narrow dark-red
## letters lit red from behind and ACCESSORIES in spaced capitals, a wide opening under a
## dark soffit onto walls of carded jewellery, bags, hats and sale signs (record). A corner:
## open to the north hall (this edge) and, for its first 4 m, to the west hall at u = 0.
static func claires(b, a, t, n, W, D, rng):
	var F = "w8lf_props"
	var G = "w8l_fix"
	var head = 2.8
	S1.upper(b, F, a, t, n, W, head, "w8_marble", 0.16)
	# Steven's sign pass (Oct 7: design/storefronts/photos/claires): a white box sign, "Claire's" in
	# black letters on red returns (a red glow round them), ACCESSORIES in red, on both faces
	claires_sign(b, F, P(a, t, n, W * 0.5, 0, -0.16), n, head)
	# the west front: marble over a second opening, a smaller sign box
	var wn = -t
	b.box(F, "w8_marble", P(a, t, n, -0.08, (head + b.LANE_H) * 0.5, 2.0), b.abs_size(n, 4.0, b.LANE_H - head, 0.16, t))
	claires_sign(b, F, P(a, t, n, -0.16, 0, 2.0), wn, head)
	# piers: the corner (wrapping both fronts), the far end of each front
	b.box(F, "w8_marble", P(a, t, n, 0.17, head * 0.5, 0.17), b.abs_size(t, 0.66, head, 0.66, n), Transform3D.IDENTITY, ["-y"])
	K.ob(b, P(a, t, n, -0.16, 0, -0.16), P(a, t, n, 0.5, 0, 0.5), 0.05)
	pier(b, F, "w8_marble", a, t, n, W - 0.5, W, head, 0.16)
	b.box(F, "w8_marble", P(a, t, n, 0.0, head * 0.5, 3.8), b.abs_size(n, 0.4, head, 0.32, t), Transform3D.IDENTITY, ["-y"])
	K.ob(b, P(a, t, n, -0.16, 0, 3.6), P(a, t, n, 0.16, 0, 4.0), 0.05)
	# the dark soffits over both openings
	b.quad(F, "w8_dark", [P(a, t, n, 0.5, head, 0), P(a, t, n, W - 0.5, head, 0), P(a, t, n, W - 0.5, head, 1.0), P(a, t, n, 0.5, head, 1.0)], Vector3.DOWN)
	b.quad(F, "w8_dark", [P(a, t, n, 0.0, head, 0.5), P(a, t, n, 1.0, head, 0.5), P(a, t, n, 1.0, head, 3.6), P(a, t, n, 0.0, head, 3.6)], Vector3.DOWN)
	b.quad("w8l_shell", "w8_dark", [P(a, t, n, 0.5, head, 1.0), P(a, t, n, W - 0.5, head, 1.0), P(a, t, n, W - 0.5, 3.0, 1.0), P(a, t, n, 0.5, 3.0, 1.0)], -n)
	b.quad("w8l_shell", "w8_dark", [P(a, t, n, 1.0, head, 0.5), P(a, t, n, 1.0, head, 3.6), P(a, t, n, 1.0, 3.0, 3.6), P(a, t, n, 1.0, 3.0, 0.5)], t)
	M2.shell2(b, "w8l_shell", a, t, n, W, D, 3.0, 0.0, "w8_floor_pink", 0.61, "w8_blush", "w8_dark", [], W - 1.2, 1.0, false, 4.0)
	# spots on the dark ceiling
	for c in [[2.2, 2.4], [5.8, 2.4], [2.2, 5.4], [5.8, 5.4], [2.2, 8.2], [5.8, 8.2]]:
		spot(b, G, P(a, t, n, c[0], 2.99, c[1]), 1.15, 5.5, 64.0)
	# walls of carded jewellery: the right wall, the back wall, the left wall behind the west front
	card_wall(b, G, P(a, t, n, W - SIDE, 0, 1.2), -n, -t, D - 1.8, rng)
	card_wall(b, G, P(a, t, n, W - SIDE, 0, D - SIDE), -t, n, 3.6, rng)
	card_wall(b, G, P(a, t, n, SIDE, 0, D - 0.3), n, t, D - 4.4, rng)
	# the cash counter at the back on the left, white with a dark top
	K.counter(b, G, "w8l_small", P(a, t, n, SIDE + 3.7, 0, D - 1.9), -t, n, 3.0, "w8_white", rng)
	# two spinners of cards in the middle
	for c in [[3.0, 3.4], [5.0, 5.8]]:
		spinner(b, G, P(a, t, n, c[0], 0, c[1]))
	# SALE cards hung over the floor
	for c in [[4.0, 2.2], [3.0, 6.6], [6.0, 7.8]]:
		var hc = P(a, t, n, c[0], 2.2, c[1])
		for sg in [1.0, -1.0]:
			var f = n * sg
			var r = (-f).cross(UP)
			K.fq(b, "w8l_paper", "w8_sale", hc - r * 0.3 + f * 0.004, r, f, 0.0, 0.6, 0.0, 0.3, 0.0, 0.0, 0.0, 1.0, 1.0, true)
		b.cur_color = Color("#c8c8c8")
		b.box("w8l_paper", "vcolor", hc + UP * 0.65, Vector3(0.006, 0.7, 0.006), Transform3D.IDENTITY, [], true)
		b.cur_color = Color.WHITE
	# a SALE board on a stand at the north opening
	var sc = P(a, t, n, 1.2, 0, 0.6)
	b.cyl(G, "md_chrome", sc, 0.18, 0.18, 0.02, 10, true, false)
	b.cyl(G, "md_chrome", sc, 0.015, 0.015, 1.1, 6, false, false)
	K.lbox(b, G, "w8_sale_back", sc, t, n, -0.3, 1.1, -0.01, 0.6, 0.32, 0.02)
	sign_q(b, G, "w8_sale", a, t, n, 1.2, 0.6, 1.1, 1.42, 0.6 - 0.012)
	K.ob(b, sc - Vector3(0.2, 0, 0.2), sc + Vector3(0.2, 0, 0.2), 0.05)

## A wall run of carded jewellery from o along r for `ln`, facing f: a white base, the purple
## grid of cards, a shelf of hats and bags on top.
static func card_wall(b, G, o, r, f, ln, rng):
	K.lbox(b, G, "w8_white", o, r, f, 0.0, 0.0, 0.0, ln, 0.75, 0.45, ["-y"])
	K.fq(b, G, "w8_jewel_cards", o, r, f, 0.0, ln, 0.8, 2.0, 0.02, 0.0, 0.0, ln / 1.2, 1.0)
	K.lbox(b, G, "w8_white", o, r, f, 0.0, 2.02, 0.0, ln, 0.03, 0.32)
	K.fq(b, "w8l_paper", "w8_hats", o, r, f, 0.0, ln, 2.05, 2.55, 0.16, 0.0, 0.0, ln / 4.0, 1.0, true)
	K.ob(b, o, o + r * ln + f * 0.45, 0.05)

## A chrome spinner of carded jewellery, four faces.
static func spinner(b, G, c):
	b.cyl(G, "md_chrome", c, 0.24, 0.24, 0.03, 12, true, false)
	b.cyl(G, "md_chrome", c, 0.02, 0.02, 1.75, 8, false, false)
	for k in 4:
		var f = Vector3(cos(k * PI * 0.5 + 0.4), 0, sin(k * PI * 0.5 + 0.4))
		var r = (-f).cross(UP)
		K.fq(b, G, "w8_jewel_cards", c - r * 0.22 + f * 0.05, r, f, 0.0, 0.44, 0.5, 1.7, 0.0, k * 0.25, 0.0, k * 0.25 + 0.37, 1.0)
	K.ob(b, c - Vector3(0.32, 0, 0.32), c + Vector3(0.32, 0, 0.32), 0.05)

# ------------------------------------------------------------------ Optical Outlet
## A ribbed lilac-grey fascia with fat round letters glowing warm yellow; dark-framed glass and
## doors on a bright cream shop: walls of frames, lit cases, portraits of faces in glasses
## (record).
static func optical(b, a, t, n, W, D, rng):
	var F = "w8of_props"
	var G = "w8o_fix"
	var head = 2.7
	S1.upper(b, F, a, t, n, W, head, "w8_ribbed", 0.18)
	AK.letters(b, F, LET + "oo_letters.json", P(a, t, n, W * 0.5, head + 0.62, -0.18), n, "w8_yellow_letter", "w8_yellow_side", 0.03, 0.08)
	pier(b, F, "w8_ribbed", a, t, n, 0.0, 0.2, head, 0.18)
	pier(b, F, "w8_ribbed", a, t, n, W - 0.2, W, head, 0.18)
	glass_front(b, F, a, t, n, 0.2, W - 0.2, head, W * 0.5, 1.8)
	M2.shell2(b, "w8o_shell", a, t, n, W, D, 3.0, 0.0, "w8_floor_grey", 0.61, "w8_cream", "kb_ceiling", [2.0, 5.4], 1.4, 1.3)
	M2.soffit(b, F, a, t, n, W, head, "w8_cream")
	# walls of frames down both sides
	for s in [[SIDE, t, 1.2, D - 1.6], [W - SIDE, -t, 1.2, D - 1.6]]:
		var o = P(a, t, n, s[0], 0, s[2])
		var ln = s[3] - s[2]
		K.lbox(b, G, "w8_white", o, -n, s[1], 0.0, 0.0, 0.0, ln, 0.85, 0.42, ["-y"])
		K.fq(b, G, "w8_frames", o, -n, s[1], 0.0, ln, 0.9, 2.1, 0.03, 0.0, 0.0, ln / 1.2, 1.0)
		K.lbox(b, G, "w8_glow", o, -n, s[1], 0.0, 2.12, 0.0, ln, 0.06, 0.2)
		K.ob(b, o, o - n * ln + s[1] * 0.42, 0.05)
	# lit cases in the middle
	S2.jewel_case(b, G, P(a, t, n, 2.6, 0, 4.0), t, n, 2.8)
	# fitting desks with round mirrors and chairs near the back
	var WL = load("res://tools/stores/woolworth/store.gd")
	for du in [2.2, 5.8]:
		var c = P(a, t, n, du, 0, 6.6)
		K.lbox(b, G, "w8_white", c - t * 0.6, t, n, 0.0, 0.0, 0.0, 1.2, 0.74, 0.6)
		b.quad(G, "s6_jewels", [c + UP * 0.745 + n * 0.1 - t * 0.3, c + UP * 0.745 + n * 0.1 + t * 0.3, c + UP * 0.745 + n * 0.4 + t * 0.3, c + UP * 0.745 + n * 0.4 - t * 0.3], UP,
			[Vector2(0, 1), Vector2(0.6, 1), Vector2(0.6, 0), Vector2(0, 0)])
		K.ob(b, c - t * 0.6, c + t * 0.6 + n * 0.6, 0.05)
		WL.chair(b, "w8o_small", c + n * 0.75, -n)
	# portraits on the back wall
	K.fq(b, G, "w8_portraits", P(a, t, n, W * 0.5, 0, D - SIDE) + t * 1.8, -t, n, 0.0, 3.6, 1.4, 2.3, 0.02)

# ------------------------------------------------------------------ Tee Tai's
## A black sign box with the name in pale gold brush script, a black fretwork rail under it,
## red paper lanterns with gold bands and tassels along the front (record). Inside: a lacquer
## red counter with a steam table, menu boards over it, the kitchen behind.
static func tee_tai(b, a, t, n, W, D, rng):
	var F = "w8tf_props"
	var G = "w8t_fix"
	var head = 2.8
	S1.upper(b, F, a, t, n, W, head, "md_black", 0.2)
	AK.letters(b, F, LET + "tt_letters.json", P(a, t, n, W * 0.5, head + 0.75, -0.2), n, "w8_gold_letter", "w8_gold_letter", 0.02, 0.05)
	sign_q(b, F, "w8_fret", a, t, n, W * 0.5, W - 0.3, head - 0.3, head, -0.1, (W - 0.3) / 2.0, 0.0, true)
	pier(b, F, "md_black", a, t, n, 0.0, 0.15, head, 0.2)
	pier(b, F, "md_black", a, t, n, W - 0.15, W, head, 0.2)
	for lu in [1.0, W * 0.5, W - 1.0]:
		lantern(b, F, P(a, t, n, lu, 2.32, -0.35), head)
	M2.shell2(b, "w8t_shell", a, t, n, W, D, 3.0, 0.0, "s6_red_tile", 0.61, "w7_cream", "kb_ceiling", [1.6, 4.4], W - 0.8, 1.2)
	M2.soffit(b, F, a, t, n, W, head, "md_black")
	# the counter across the shop, its steam table under a sneeze guard
	var co = P(a, t, n, W - 0.2, 0, 2.5)
	K.lbox(b, G, "w8_tt_red", co, -t, n, 0.0, 0.0, 0.0, W - 0.4, 0.95, 0.7, ["-y"])
	K.fq(b, G, "w8_tt_counter", co, -t, n, 0.0, W - 0.4, 0.12, 0.92, 0.702, 0.0, 0.0, (W - 0.4) / 2.0, 1.0)
	K.lbox(b, G, "md_black", co, -t, n, 0.0, 0.0, 0.66, W - 0.4, 0.12, 0.05)
	b.quad(G, "w8_trays", [K.L(co, -t, n, 0.3, 0.96, 0.08), K.L(co, -t, n, W - 0.7, 0.96, 0.08), K.L(co, -t, n, W - 0.7, 0.96, 0.6), K.L(co, -t, n, 0.3, 0.96, 0.6)], UP,
		[Vector2(0, 1), Vector2((W - 1.0) / 2.4, 1), Vector2((W - 1.0) / 2.4, 0), Vector2(0, 0)])
	b.quad("glass", "glass", [K.L(co, -t, n, 0.2, 1.4, 0.75), K.L(co, -t, n, W - 0.6, 1.4, 0.75), K.L(co, -t, n, W - 0.6, 1.0, 0.7), K.L(co, -t, n, 0.2, 1.0, 0.7)], n,
		[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)], true)
	b.quad("glass", "glass", [K.L(co, -t, n, 0.2, 1.4, 0.75), K.L(co, -t, n, W - 0.6, 1.4, 0.75), K.L(co, -t, n, W - 0.6, 1.4, 0.3), K.L(co, -t, n, 0.2, 1.4, 0.3)], UP,
		[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)], true)
	K.register(b, "w8t_small", K.L(co, -t, n, W - 1.1, 0.95, 0.1), -t, n)
	K.ob_local(b, co, -t, n, -0.1, 0.0, W - 0.3, 0.75)
	# the menu boards hung over the back of the counter
	K.lbox(b, G, "md_black", P(a, t, n, W - 0.35, 0, 2.62), -t, n, 0.0, 1.95, -0.06, W - 0.7, 0.85, 0.06)
	K.fq(b, G, "w8_tt_menu", P(a, t, n, W - 0.4, 0, 2.62), -t, n, 0.0, W - 0.8, 2.0, 2.75, 0.002)
	for s in [0.6, W - 0.6]:
		b.cur_color = Color("#888888")
		b.box(G, "vcolor", P(a, t, n, s, 2.88, 2.6), Vector3(0.01, 0.24, 0.01))
		b.cur_color = Color.WHITE
	# the kitchen line on the back wall: steel counter, woks, a hood
	K.lbox(b, G, "wl_steel", P(a, t, n, W - SIDE, 0, D - SIDE), -t, n, 0.0, 0.0, 0.0, W - 2 * SIDE, 0.9, 0.75)
	K.lbox(b, G, "wl_steel", P(a, t, n, W - SIDE, 0, D - SIDE), -t, n, 0.3, 1.9, 0.0, W - 2 * SIDE - 0.6, 0.5, 0.9)
	b.cur_color = Color("#1c1c1e")
	for k in 3:
		b.cyl(G, "vcolor", P(a, t, n, 1.2 + k * 1.8, 0.9, D - 0.5), 0.12, 0.32, 0.14, 14, false, false)
	b.cur_color = Color.WHITE
	K.ob(b, P(a, t, n, SIDE, 0, 2.5), P(a, t, n, W - SIDE, 0, D - SIDE), 0.0)

## A red paper lantern hung at c (its centre) from the fascia above, gold bands, a tassel.
static func lantern(b, G, c, top):
	b.cur_color = Color("#222222")
	b.cyl(G, "vcolor", c + UP * 0.2, 0.006, 0.006, top - c.y - 0.2, 4, false, false)
	b.cur_color = Color.WHITE
	b.cyl(G, "w8_gold", c + UP * 0.17, 0.125, 0.125, 0.035, 14, true, false)
	b.cyl(G, "w8_lantern", c + UP * 0.06, 0.2, 0.12, 0.12, 16, false, false)
	b.cyl(G, "w8_lantern", c - UP * 0.06, 0.2, 0.2, 0.12, 16, false, false)
	b.cyl(G, "w8_lantern", c - UP * 0.18, 0.12, 0.2, 0.12, 16, false, false)
	b.cyl(G, "w8_gold", c - UP * 0.215, 0.125, 0.125, 0.035, 14, false, true)
	b.cyl(G, "w8_tassel", c - UP * 0.48, 0.012, 0.035, 0.26, 8, false, false)

# ------------------------------------------------------------------ Saadi's
## A black fascia: the name in heavy light-grey serif and, under it to the right, a grey box
## with 'haberdashery' in black bold serif, a fine grey rule in from the left and a small
## tick off its right side (record, from Steven's photo of the sign). Inside: a men's shop of
## wood cubbies of shirts, suits on the walls, a tie rack, tables of folded shirts.
static func saadi(b, a, t, n, W, D, rng):
	var F = "w8sf_props"
	var G = "w8s_fix"
	var head = 2.9
	S1.upper(b, F, a, t, n, W, head, "md_black", 0.16)
	AK.letters(b, F, LET + "saadi_letters.json", P(a, t, n, W * 0.5, head + 0.82, -0.16), n, "w8_saadi_grey", "w8_saadi_grey", 0.02, 0.06)
	sign_q(b, F, "w8_saadi_sub", a, t, n, W * 0.5, 3.2, head + 0.05, head + 0.65, -0.165, 1.0, 0.0)
	pier(b, F, "md_black", a, t, n, 0.0, 0.2, head, 0.16)
	pier(b, F, "md_black", a, t, n, W - 0.2, W, head, 0.16)
	glass_front(b, F, a, t, n, 0.2, W - 0.2, head, W * 0.5, 2.0, "w8_bronze", 0.35)
	M2.shell2(b, "w8s_shell", a, t, n, W, D, 3.1, 0.0, "ap_wood", 1.0, "w8_cream", "kb_ceiling", [2.0, 5.6], 2.0, 1.3)
	M2.soffit(b, F, a, t, n, W, head, "md_black")
	# suited forms in the windows
	AK.mannequin(b, P(a, t, n, 1.3, 0.0, 0.8), -n, "#2a2e3a", "#2a2e3a")
	AK.mannequin(b, P(a, t, n, W - 1.3, 0.0, 0.8), -n, "#5a5a5e", "#3a3a3e")
	# the left wall: wood cubbies of shirts, then suits; the right wall: suits, then the ties
	AK.cubbies(b, a, t, n, SIDE, t, 1.8, 6.6, 2.1)
	AK.faceout_wall(b, a, t, n, SIDE, t, 7.0, D - 3.0, 0, rng, "w7_warm_slat")
	AK.faceout_wall(b, a, t, n, W - SIDE, -t, 1.8, 7.4, 1, rng, "w7_warm_slat")
	var to = P(a, t, n, W - SIDE, 0, 7.8)
	K.lbox(b, G, "w8_walnut", to, -n, -t, 0.0, 0.0, 0.0, D - 3.0 - 7.8, 0.85, 0.4, ["-y"])
	K.fq(b, G, "w8_ties", to, -n, -t, 0.0, D - 3.0 - 7.8, 0.95, 2.15, 0.03, 0.0, 0.0, (D - 3.0 - 7.8) / 2.4, 1.0)
	K.ob(b, to, to - n * (D - 3.0 - 7.8) - t * 0.4, 0.05)
	# tables of folded shirts and a round rack down the middle
	AK.table(b, P(a, t, n, W * 0.5, 0, 3.6), 0.0, 1.5, 0.9, 0, "w8_walnut")
	AK.round_rack(b, P(a, t, n, W * 0.5, 0, 6.4), 0.62, 1)
	AK.table(b, P(a, t, n, W * 0.5, 0, 9.0), 0.0, 1.5, 0.9, 1, "w8_walnut")
	# the cash wrap and two fitting rooms at the back
	AK.cash_wrap(b, P(a, t, n, W - 0.9, 0, D - 2.6), -t, n, 2.6, 0.6, "w8_walnut")
	AK.fitting_rooms(b, a, t, n, SIDE, 3.4, D - SIDE, 1.9, 2)

# ------------------------------------------------------------------ Mitchell's Formal Wear
## The logo panel from the ad, black on white: the name in a heavy italic, a rule broken by a
## bow tie, FORMAL WEAR in spaced capitals (record). The front is a guess: a charcoal fascia,
## a glass front with the door on the left, a form in a tuxedo in the window. Inside: a narrow
## shop of tuxedos on the wall, cubbies of white shirts, a three-way mirror, fitting rooms.
static func mitchell(b, a, t, n, W, D, rng):
	var F = "w8mf_props"
	var G = "w8m_fix"
	var head = 2.8
	S1.upper(b, F, a, t, n, W, head, "w8_cream_front", 0.14)
	K.lbox(b, F, "w8_white", P(a, t, n, 0, 0, 0), t, n, W * 0.5 - 1.4, head + 0.25, 0.14, 2.8, 1.45, 0.06)
	sign_q(b, F, "w8_mitchell_sign", a, t, n, W * 0.5, 2.7, head + 0.3, head + 1.65, -0.205)
	pier(b, F, "w8_cream_front", a, t, n, 0.0, 0.15, head, 0.14)
	pier(b, F, "w8_cream_front", a, t, n, W - 0.15, W, head, 0.14)
	var rv = (-n).cross(UP)
	var door_u = 0.75 if rv.dot(t) > 0.0 else W - 0.75
	glass_front(b, F, a, t, n, 0.15, W - 0.15, head, door_u, 1.1)
	var win_u = W - 1.4 if door_u < W * 0.5 else 1.4
	b.box(F, "w8_charcoal", P(a, t, n, win_u, 0.2, 0.6), b.abs_size(t, 1.6, 0.4, 0.8, n), Transform3D.IDENTITY, ["-y"])
	AK.mannequin(b, P(a, t, n, win_u, 0.4, 0.6), -n, "#141416", "#141416")
	M2.shell2(b, "w8m_shell", a, t, n, W, D, 3.0, 0.0, "a2_carpet_grey", 1.0, "w8_cream", "kb_ceiling", [W * 0.5 - 0.3], W * 0.5, 1.3)
	M2.soffit(b, F, a, t, n, W, head, "w8_charcoal")
	var wall_far = W - SIDE if door_u < W * 0.5 else SIDE
	var face_far = -t if door_u < W * 0.5 else t
	var wall_near = SIDE if door_u < W * 0.5 else W - SIDE
	var face_near = t if door_u < W * 0.5 else -t
	var tw = P(a, t, n, wall_far, 0, 1.8)
	K.lbox(b, G, "gb_slat_black", tw, -n, face_far, 0.0, 0.0, 0.0, 6.0, 2.6, 0.04)
	K.fq(b, G, "w8_tux", tw, -n, face_far, 0.0, 6.0, 0.25, 2.45, 0.3, 0.0, 0.0, 6.0 / 2.4, 1.0)
	K.ob(b, tw, tw - n * 6.0 + face_far * 0.5, 0.05)
	var sw = P(a, t, n, wall_near, 0, 2.2)
	K.lbox(b, G, "w8_white", sw, -n, face_near, 0.0, 0.0, 0.0, 3.2, 2.1, 0.42, ["-y"])
	K.fq(b, G, "w8_tux_shirts", sw, -n, face_near, 0.05, 3.15, 0.15, 2.0, 0.425, 0.0, 0.0, 3.1 / 1.2, 1.0)
	K.ob(b, sw, sw - n * 3.2 + face_near * 0.42, 0.05)
	# tuxedos on two forms on a low riser
	var rc = P(a, t, n, W * 0.5, 0, 6.6)
	b.box(G, "w8_charcoal", rc + UP * 0.1, b.abs_size(t, 1.4, 0.2, 0.8, n), Transform3D.IDENTITY, ["-y"])
	AK.mannequin(b, rc + UP * 0.2 - t * 0.35, -n, "#141416", "#141416")
	AK.mannequin(b, rc + UP * 0.2 + t * 0.35, -n, "#e8e6e0", "#141416")
	K.ob(b, rc - t * 0.7 - n * 0.4, rc + t * 0.7 + n * 0.4, 0.05)
	# the three-way mirror on the near wall
	var mo = P(a, t, n, wall_near, 0, 6.0)
	K.fq(b, G, "ap_mirror", mo, -n, face_near, 0.0, 1.2, 0.2, 2.0, 0.02)
	# the counter and the fitting rooms at the back
	K.counter(b, G, "w8m_small", P(a, t, n, W - 0.4, 0, D - 3.1), -t, n, W - 1.6, "w8_charcoal", rng)
	AK.fitting_rooms(b, a, t, n, SIDE, W - SIDE, D - SIDE, 1.8, 2)

# ------------------------------------------------------------------ Golden Chain Gang
## The shop's mark painted in gold on a black front; below it an open counter of lit cases and
## chains on display busts (record; the colours are a guess, the ad is black and white). A
## counter shop: shoppers stand in the hall.
static func gcg(b, a, t, n, W, D, rng):
	var F = "w8gf_props"
	var G = "w8g_fix"
	var head = 2.6
	S1.upper(b, F, a, t, n, W, head, "md_black", 0.18)
	sign_q(b, F, "w8_gcg_sign", a, t, n, W * 0.5, W - 0.5, head + 0.05, head + 1.95, -0.185)
	pier(b, F, "md_black", a, t, n, 0.0, 0.25, head, 0.18)
	pier(b, F, "md_black", a, t, n, W - 0.25, W, head, 0.18)
	b.box(F, "w8_gold", P(a, t, n, W * 0.5, head + 0.02, -0.19), b.abs_size(t, W, 0.04, 0.03, n))
	# the counter of lit cases right at the front
	S2.jewel_case(b, G, P(a, t, n, 0.25, 0, 0.62), t, n, W - 0.5)
	K.ob(b, P(a, t, n, 0.0, 0, 0.0), P(a, t, n, W, 0, 0.8), 0.0)
	for k in 3:
		bust(b, G, P(a, t, n, 1.2 + k * 1.8, 1.07, 0.35), n, t)
	M2.shell2(b, "w8g_shell", a, t, n, W, D, 2.9, 0.0, "w7_taupe_carpet", 1.0, "w8_velvet", "kb_ceiling", [W * 0.5 - 0.3], W * 0.5, 1.0)
	M2.soffit(b, F, a, t, n, W, head, "md_black")
	# the chain walls: back and both sides, lit
	K.fq(b, G, "w8_chains", P(a, t, n, W - SIDE, 0, D - SIDE), -t, n, 0.0, W - 2 * SIDE, 0.95, 1.95, 0.02, 0.0, 0.0, (W - 0.24) / 4.0, 1.0)
	for s in [[SIDE, t], [W - SIDE, -t]]:
		K.fq(b, G, "w8_chains", P(a, t, n, s[0], 0, 1.4), -n, s[1], 0.0, D - 2.6, 0.95, 1.95, 0.02, 0.0, 0.0, (D - 2.6) / 4.0, 1.0)
	# a back counter with three velvet busts, chains round their necks
	K.lbox(b, G, "md_black", P(a, t, n, W - SIDE, 0, D - SIDE), -t, n, 0.0, 0.0, 0.0, W - 2 * SIDE, 0.85, 0.55)
	for k in 3:
		bust(b, G, P(a, t, n, 1.5 + k * 1.5, 0.85, D - 0.45), n, t)

## A black velvet neck bust with gold chains at c (its base).
static func bust(b, G, c, n, t):
	b.cyl(G, "w8_velvet_black", c, 0.1, 0.08, 0.06, 12, true, false)
	b.box(G, "w8_velvet_black", c + UP * 0.14, b.abs_size(t, 0.3, 0.14, 0.12, n))
	b.cyl(G, "w8_velvet_black", c + UP * 0.21, 0.055, 0.045, 0.2, 10, true, false)
	b.cyl(G, "w8_gold", c + UP * 0.31, 0.058, 0.058, 0.012, 12, false, false)
	b.cyl(G, "w8_gold", c + UP * 0.22, 0.1, 0.1, 0.01, 14, false, false)

## Claire's box sign on one face: c the foot's middle on the fascia, facing nn: 2.4 x 1.55 m, 0.14 deep.
static func claires_sign(b, F, c, nn, head):
	var r = (-nn).cross(UP)
	var y0 = head + 0.08
	b.box(F, "sg_cla_box", c + UP * (y0 + 0.775) + nn * 0.07, b.abs_size(r, 2.4, 1.55, 0.14, nn))
	CH.build(b, "w8lf_sign", "res://tools/stores/signs/cla_name_logo.json", c + UP * (y0 + 0.36) + nn * 0.14, nn, "sg_cla_black", "sg_cla_red", "", 0.0, 0.05, 0.0, "sg_cla_glow")
	CH.build(b, "w8lf_sign", "res://tools/stores/signs/cla_acc_logo.json", c + UP * (y0 + 0.12) + nn * 0.14, nn, "sg_cla_red", "sg_cla_red", "", 0.0, 0.015, 0.0)

# ------------------------------------------------------------------ materials
## "w8_<key>" (build_mall.gd's mat() calls this).
static func fill_mat(m, key, b):
	match key:
		"planks":
			m.albedo_texture = b.tex("w8/planks.png"); m.roughness = 0.7
			m.uv1_scale = Vector3(1.0 / 1.2, 1.0 / 2.4, 1.0)
		"teal":
			m.albedo_color = Color("#1f8a7a"); m.roughness = 0.5
		"teal_tile":
			m.albedo_texture = b.tex("wl/floor.png"); m.roughness = 0.25; m.metallic_specular = 0.55
			m.albedo_color = Color(0.45, 0.8, 0.74)
		"cucos_sign":
			m.albedo_texture = b.tex("w8/cucos_sign.png"); m.roughness = 0.5
			K.emit_tex(m, 0.75)
		"dark_wood":
			m.albedo_texture = b.tex("wood_dark.png"); m.roughness = 0.55
			m.albedo_color = Color(0.7, 0.55, 0.45)
		"white":
			m.albedo_color = Color("#f4f2ec"); m.roughness = 0.5
		"green":
			m.albedo_color = Color("#2f6e4a"); m.roughness = 0.5
		"clay":
			m.albedo_texture = b.tex("w8/clay.png"); m.roughness = 0.75
		"clay_under":
			m.albedo_texture = b.tex("w8/clay.png"); m.roughness = 0.85
			m.albedo_color = Color(0.7, 0.62, 0.58)
		"tassel":
			m.albedo_color = Color("#c0201a"); m.roughness = 0.8
			K.emit(m, Color("#5a0c08"), 0.8)
		"sale_back":
			m.albedo_color = Color("#e8285a"); m.roughness = 0.5
		"tux":
			m.albedo_texture = b.tex("w8/tux.png"); m.roughness = 0.6
			K.emit_tex(m, 0.2)
		"tux_shirts":
			m.albedo_texture = b.tex("w8/tux_shirts.png"); m.roughness = 0.7
		"cream_front":
			m.albedo_color = Color("#ece4d2"); m.roughness = 0.55
		"saltillo":
			m.albedo_texture = b.tex("w8/saltillo.png"); m.roughness = 0.4; m.metallic_specular = 0.45
		"stucco":
			m.albedo_texture = b.tex("plaster.png"); m.roughness = 0.9
			m.albedo_color = Color(1.0, 0.86, 0.68)
		"ceiling":
			m.albedo_texture = b.tex("wood_dark.png"); m.roughness = 0.8
			m.albedo_color = Color(0.85, 0.7, 0.56)
		"rush":
			m.albedo_color = Color("#b89a5a"); m.roughness = 0.9
		"red_vinyl":
			m.albedo_color = Color("#b02a22"); m.roughness = 0.35
			K.emit(m, Color(0.2, 0.04, 0.03), 1.0)
		"dark":
			m.albedo_color = Color("#1e1a1c"); m.roughness = 0.8
		"bar":
			m.albedo_texture = b.tex("w8/bar.png"); m.roughness = 0.3; m.metallic_specular = 0.6
			K.emit_tex(m, 0.25)
		"papel":
			m.albedo_texture = b.tex("w8/papel.png"); m.roughness = 0.8
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
			K.emit_tex(m, 0.55)
		"copper":
			m.albedo_color = Color("#b06a3a"); m.metallic = 0.6; m.roughness = 0.35
			K.emit(m, Color("#5a2a10"), 0.6)
		"bulb":
			m.albedo_color = Color("#fff0d0")
			K.emit(m, Color("#ffd8a0"), 2.0)
		"marble":
			m.albedo_texture = b.tex("w8/marble.png"); m.roughness = 0.2; m.metallic_specular = 0.6
			m.albedo_color = Color(1.0, 0.93, 0.86)
			m.uv1_scale = Vector3(1.0 / 0.8, 1.0 / 0.8, 1.0)
		"claire_sign":
			m.albedo_texture = b.tex("w8/claire_sign.png"); m.roughness = 0.4
			K.emit_tex(m, 0.9)
		"floor_pink":
			m.albedo_texture = b.tex("wl/floor.png"); m.roughness = 0.25; m.metallic_specular = 0.55
			m.albedo_color = Color(1.0, 0.9, 0.92)
		"blush":
			m.albedo_color = Color("#e8d4d8"); m.roughness = 0.85
		"jewel_cards":
			m.albedo_texture = b.tex("w8/jewel_cards.png"); m.roughness = 0.7
			K.emit_tex(m, 0.2)
		"hats":
			m.albedo_texture = b.tex("w8/hats.png"); m.roughness = 0.8
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
			K.emit_tex(m, 0.55)
		"sale":
			m.albedo_texture = b.tex("w8/sale.png"); m.roughness = 0.5
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
			K.emit_tex(m, 0.5)
		"ribbed":
			m.albedo_texture = b.tex("w8/ribbed.png"); m.roughness = 0.45; m.metallic_specular = 0.5
			m.uv1_scale = Vector3(1.0 / 0.6, 1.0 / 0.6, 1.0)
		"yellow_letter":
			m.albedo_color = Color("#ffe38a")
			m.emission_enabled = true; m.emission = Color("#ffc848"); m.emission_energy_multiplier = 2.2
			m.set_meta("e_day", 1.6); m.set_meta("e_night", 2.2)
		"yellow_side":
			m.albedo_color = Color("#c8a040"); m.roughness = 0.4
			K.emit(m, Color("#806020"), 0.6)
		"floor_grey":
			m.albedo_texture = b.tex("wl/floor.png"); m.roughness = 0.25; m.metallic_specular = 0.55
			m.albedo_color = Color(0.86, 0.86, 0.88)
		"cream":
			m.albedo_color = Color("#f2ead6"); m.roughness = 0.75
		"frames":
			m.albedo_texture = b.tex("w8/frames.png"); m.roughness = 0.35; m.metallic_specular = 0.5
			K.emit_tex(m, 0.25)
		"glow":
			m.albedo_color = Color("#fffaf0")
			K.emit(m, Color("#fff4e0"), 1.2)
		"portraits":
			m.albedo_texture = b.tex("w8/portraits.png"); m.roughness = 0.4
			K.emit_tex(m, 0.6)
		"gold_letter":
			m.albedo_color = Color("#f2e2b0"); m.metallic = 0.3; m.roughness = 0.3
			K.emit(m, Color("#d8c080"), 0.75)
		"fret":
			m.albedo_texture = b.tex("w8/fret.png"); m.roughness = 0.5
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
			K.emit(m, Color(0.05, 0.05, 0.05), 1.0)
		"lantern":
			m.albedo_color = Color("#c81414"); m.roughness = 0.6
			m.emission_enabled = true; m.emission = Color("#e01010"); m.emission_energy_multiplier = 0.9
			m.set_meta("e_day", 0.6); m.set_meta("e_night", 1.0)
		"gold":
			m.albedo_color = Color("#d8b048"); m.metallic = 0.7; m.roughness = 0.3
			K.emit(m, Color("#8a6a20"), 0.4)
		"tt_red":
			m.albedo_color = Color("#a8181a"); m.roughness = 0.25; m.metallic_specular = 0.6
		"tt_counter":
			m.albedo_texture = b.tex("w8/tt_counter.png"); m.roughness = 0.25; m.metallic_specular = 0.6
		"trays":
			m.albedo_texture = b.tex("w8/trays.png"); m.roughness = 0.4
			K.emit_tex(m, 0.35)
		"tt_menu":
			m.albedo_texture = b.tex("w8/tt_menu.png"); m.roughness = 0.4
			K.emit_tex(m, 1.0)
		"saadi_grey":
			m.albedo_color = Color("#c8c8c4"); m.roughness = 0.4; m.metallic = 0.3
			K.emit(m, Color("#9a9a96"), 0.45)
		"saadi_sub":
			m.albedo_texture = b.tex("w8/saadi_sub.png"); m.roughness = 0.4
			K.emit_tex(m, 0.45)
		"bronze":
			m.albedo_color = Color("#4a3a2a"); m.metallic = 0.5; m.roughness = 0.35
		"walnut":
			m.albedo_texture = b.tex("wood_dark.png"); m.roughness = 0.4
			m.albedo_color = Color(1.1, 0.85, 0.65)
		"ties":
			m.albedo_texture = b.tex("w8/ties.png"); m.roughness = 0.6
			K.emit_tex(m, 0.2)
		"charcoal":
			m.albedo_color = Color("#2c2c30"); m.roughness = 0.5
		"mitchell_sign":
			m.albedo_texture = b.tex("w8/mitchell_sign.png"); m.roughness = 0.4
			K.emit_tex(m, 0.7)
		"gcg_sign":
			m.albedo_texture = b.tex("w8/gcg_sign.png"); m.roughness = 0.4
			K.emit_tex(m, 0.9)
		"chains":
			m.albedo_texture = b.tex("w8/chains.png"); m.roughness = 0.35; m.metallic_specular = 0.7
			K.emit_tex(m, 0.45)
		"velvet":
			m.albedo_color = Color("#2e2236"); m.roughness = 0.95
		"velvet_black":
			m.albedo_color = Color("#141216"); m.roughness = 0.95
		_:
			return false
	return true
