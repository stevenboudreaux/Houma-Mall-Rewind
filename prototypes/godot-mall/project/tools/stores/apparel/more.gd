## The Wave 4 clothing stores, on the apparel kit (kit.gd): Lerner Shop (s10), Lane Bryant
## (n10) and Miller's Outpost (s17) on the east hall, Gadzooks (n35) and The Limited (s50)
## on the north side, built to design/storefronts/lerner.md, lane-bryant.md,
## millers-outpost.md, gadzooks.md and limited.md.
##
## The fronts follow the regional videos Steven sent: the 1993 Hammond Square commercial
## (Lerner's white script, The Limited's black capsule with white neon, Lane Bryant's white
## lit letters and open front with cream columns), the 1992 Pecanland Mall opening-day video
## (Miller's Outpost's wood front and outlined serif letters with a star; Lerner's dark
## fascia) and the Gadzooks photo slideshow (black tile grid, red neon name, red and blue
## neon bands, the checker floor and red ceiling grid inside). The insides are laid out on
## the kit: slatwall walls of face-outs, round racks, four-ways, tables, a cash wrap and
## fitting rooms. Layouts are guessed and marked so in the specs.
##
## Frame: kit.gd's. P(a, t, n, u, y, d) = a + t u - n d + y up; u along the frontage from
## the edge's start, d into the store.

const K = preload("res://tools/stores/apparel/kit.gd")
const UP = Vector3.UP
const SIDE = 0.12

const CFG = {
	"LERNER SHOP": {"W": 14.0, "D": 28.0, "seed": 10, "floor": "a2_carpet_mauve", "tile": 1.0, "wall": "ap_cream", "ceil": "kb_ceiling", "rows": [2.0, 5.5, 8.5, 11.5], "door": 12.6,
		"slat": "gb_slat_white", "cash": "left", "cards": [0, 1, 2, 3], "cols": [4.6, 9.4], "fit": 3},
	"LANE BRYANT": {"W": 8.0, "D": 24.0, "seed": 11, "floor": "a2_carpet_teal", "tile": 1.0, "wall": "ap_cream", "ceil": "kb_ceiling", "rows": [1.6, 5.8], "door": 7.0,
		"slat": "gb_slat_white", "cash": "right", "cards": [12, 13], "cols": [4.0], "fit": 3},
	"MILLER'S OUTPOST": {"W": 12.0, "D": 28.0, "seed": 17, "floor": "ap_wood", "tile": 1.0, "wall": "ap_cream", "ceil": "kb_ceiling", "rows": [1.8, 5.4, 9.4], "door": 11.0,
		"slat": "gb_slat_black", "cash": "right", "cards": [14, 15], "cols": [3.9, 8.1], "fit": 3},
	"GADZOOKS": {"W": 12.0, "D": 24.0, "seed": 35, "floor": "a2_carpet_grey", "tile": 1.0, "wall": "ap_charcoal", "ceil": "a2_gz_ceiling", "rows": [1.8, 9.6], "door": 1.0,
		"slat": "gb_slat_black", "cash": "left", "cards": [8, 9, 10, 11], "cols": [3.6, 8.4], "fit": 3},
	"THE LIMITED": {"W": 10.0, "D": 28.0, "seed": 50, "floor": "a2_carpet_grey", "tile": 1.0, "wall": "ap_white", "ceil": "kb_ceiling", "rows": [1.8, 7.6], "door": 9.0,
		"slat": "gb_slat_white", "cash": "right", "cards": [4, 5, 6, 7], "cols": [3.4, 6.6], "fit": 3},
}

static func P(a, t, n, u, y, d):
	return a + t * u - n * d + Vector3(0, y, 0)

static func build(b, g, e, a, bb, n, t, Ln, sd):
	var c = CFG[sd.name]
	if Ln < c.W - 0.5:
		# The Limited's short stepped edges beside its main front: plain mall wall
		b.plain_wall(g, a, bb, n)
		return
	var rng = RandomNumberGenerator.new()
	rng.seed = c.seed
	var W = c.W
	var D = c.D
	match sd.name:
		"LERNER SHOP": front_lerner(b, "a2f_props", a, t, n, W)
		"LANE BRYANT": front_lane(b, "a2f_props", a, t, n, W)
		"MILLER'S OUTPOST": front_millers(b, "a2f_props", a, t, n, W)
		"GADZOOKS": front_gadzooks(b, "a2f_props", a, t, n, W)
		"THE LIMITED": front_limited(b, "a2f_props", a, t, n, W)
	shell2(b, "a2_shell", a, t, n, W, D, 3.2, 0.0, c.floor, c.tile, c.wall, c.ceil, c.rows, c.door)
	if sd.name == "GADZOOKS":
		gadzooks_extras(b, a, t, n, W, D)
		# ws/g (Steven, Oct 28): the white half VW Beetle in the left window, the ads on the walls
		load("res://tools/stores/y95/extras.gd").beetle(b, "a2_small_beetle", P(a, t, n, 0.15, 0, 2.4), t)
		load("res://tools/stores/y95/extras.gd").gz_ads(b, a, t, n, W, D)
	inside(b, a, t, n, W, D, c, rng)
	var rp = ReflectionProbe.new()
	rp.position = P(a, t, n, W * 0.5, 1.6, D * 0.5)
	rp.size = (t * W + n * D).abs() + Vector3(0.1, 3.3, 0.1)
	rp.box_projection = true
	rp.interior = true
	rp.update_mode = ReflectionProbe.UPDATE_ONCE
	rp.intensity = 0.6
	b.light_root.add_child(rp)

## kit.gd's shell with the ceiling's material as a parameter (Gadzooks' red grid).
## `open_u1`: leave the u = W side open (a corner shop with a second front there).
## `open_u0_to`: leave the u = 0 side open from the front to this depth (a second front there).
static func shell2(b, G, a, t, n, W, D, ceil, d_front, floor_mat, floor_tile, wall_mat, ceil_mat, rows, door_u, light = 1.3, open_u1 = false, open_u0_to = 0.0):
	var u0 = SIDE
	var u1 = W - SIDE
	var dB = D - SIDE
	var fp = [P(a, t, n, u0, 0, 0), P(a, t, n, u1, 0, 0), P(a, t, n, u1, 0, dB), P(a, t, n, u0, 0, dB)]
	var fuv = []
	for p in fp:
		fuv.append(Vector2(p.x / floor_tile, p.z / floor_tile))
	b.quad(G, floor_mat, fp, UP, fuv)
	var cp = [P(a, t, n, u0, ceil, 1.0), P(a, t, n, u1, ceil, 1.0), P(a, t, n, u1, ceil, dB), P(a, t, n, u0, ceil, dB)]
	var cuv = []
	for p in cp:
		cuv.append(Vector2(p.x / 0.61, p.z / 1.22))
	b.quad(G, ceil_mat, cp, Vector3.DOWN, cuv)
	var j = 0
	var dd = 2.2
	while dd + 1.22 < dB - 0.4:
		for uu in rows:
			var tq = [P(a, t, n, uu, ceil - 0.006, dd), P(a, t, n, uu + 0.61, ceil - 0.006, dd), P(a, t, n, uu + 0.61, ceil - 0.006, dd + 1.22), P(a, t, n, uu, ceil - 0.006, dd + 1.22)]
			b.quad(G, "gb_troffer", tq, Vector3.DOWN, [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)])
			if j % 2 == 0:
				var l = b.add_spot(P(a, t, n, uu + 0.3, ceil - 0.08, dd + 0.61), Vector3.DOWN, light, 6.0, 62.0, Color(1.0, 0.98, 0.93))
				b.tag(l, "", light, light)
		dd += 2.44
		j += 1
	b.quad(G, wall_mat, [P(a, t, n, u0, 0, open_u0_to), P(a, t, n, u0, 0, dB), P(a, t, n, u0, ceil, dB), P(a, t, n, u0, ceil, open_u0_to)], t)
	if not open_u1:
		b.quad(G, wall_mat, [P(a, t, n, u1, 0, dB), P(a, t, n, u1, 0, 0), P(a, t, n, u1, ceil, 0), P(a, t, n, u1, ceil, dB)], -t)
	b.quad(G, wall_mat, [P(a, t, n, u1, 0, dB), P(a, t, n, u0, 0, dB), P(a, t, n, u0, ceil, dB), P(a, t, n, u1, ceil, dB)], n)
	b.cur_color = Color("#8c8a86")
	b.box(G, "vcolor", P(a, t, n, door_u, 1.05, dB - 0.02), b.abs_size(t, 0.95, 2.1, 0.04, n))
	b.cur_color = Color.WHITE
	b.box(G, "exit_sign", P(a, t, n, door_u, 2.35, dB - 0.05), b.abs_size(t, 0.36, 0.16, 0.06, n))

## The soffit just inside a front, at `head`, stepping up to the 3.2 m ceiling at d 1.
static func soffit(b, G, a, t, n, W, head, mat = "ap_white"):
	b.quad(G, mat, [P(a, t, n, SIDE, head, 0), P(a, t, n, W - SIDE, head, 0), P(a, t, n, W - SIDE, head, 1.0), P(a, t, n, SIDE, head, 1.0)], Vector3.DOWN)
	b.quad("a2_shell", mat, [P(a, t, n, SIDE, head, 1.0), P(a, t, n, W - SIDE, head, 1.0), P(a, t, n, W - SIDE, 3.2, 1.0), P(a, t, n, SIDE, 3.2, 1.0)], -n)
	var u = 1.0
	while u < W - 0.5:
		b.box(G, "gb_can", P(a, t, n, u, head - 0.005, 0.5), b.abs_size(t, 0.2, 0.01, 0.2, n), Transform3D.IDENTITY, ["+y"])
		u += 2.0

## Glass windows from u0..u1 over a bulkhead, dark frames; a mannequin or two behind.
## own_k / own_group: the form at index own_k goes in a mesh group of its own (the Rougarou's).
static func windows(b, G, a, t, n, u0, u1, head, frame_mat, base_mat, rng, cols = ["#e8e2d2", "#2e3a5c"], own_k = -1, own_group = ""):
	b.box(G, base_mat, P(a, t, n, (u0 + u1) * 0.5, 0.2, 0.05), b.abs_size(t, u1 - u0, 0.4, 0.1, n), Transform3D.IDENTITY, ["-y"])
	b.quad("glass", "glass", [P(a, t, n, u0, 0.4, 0.02), P(a, t, n, u1, 0.4, 0.02), P(a, t, n, u1, head, 0.02), P(a, t, n, u0, head, 0.02)], n,
		[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)], true)
	for u in [u0, u1]:
		b.box(G, frame_mat, P(a, t, n, u, head * 0.5, 0.05), b.abs_size(t, 0.08, head, 0.1, n))
	b.box(G, frame_mat, P(a, t, n, (u0 + u1) * 0.5, head - 0.04, 0.05), b.abs_size(t, u1 - u0, 0.08, 0.1, n))
	b.box(G, "ap_white", P(a, t, n, (u0 + u1) * 0.5, 0.2, 0.55), b.abs_size(t, u1 - u0 - 0.2, 0.4, 0.8, n), Transform3D.IDENTITY, ["-y"])
	var k = 0
	var u = u0 + 0.7
	while u < u1 - 0.5:
		K.mannequin(b, P(a, t, n, u, 0.4, 0.55), -n, cols[k % cols.size()], cols[(k + 1) % cols.size()], 1.0, own_group if k == own_k else "ap_small")
		u += 1.2
		k += 1
	K.ob(b, P(a, t, n, u0, 0, -0.1), P(a, t, n, u1, 0, 1.0), 0.1)

## A hanging card from a2/cards.png (4 x 4 cells), both faces, on two wires.
static func card(b, c, facing, cell, w, h, ceil):
	var r = facing.cross(UP)
	var cu = (cell % 4) * 0.25
	var cv = (cell / 4) * 0.25
	for s in [1.0, -1.0]:
		var f = facing * s
		var rr = r * s
		var o = c - rr * (w * 0.5) + f * 0.004
		K.fq(b, "ap_small", "a2_cards", o, rr, f, 0.0, w, 0.0, h, 0.0, cu, cv, cu + 0.25, cv + 0.25, true)
	b.cur_color = Color("#c8c8c8")
	for sd in [-0.4, 0.4]:
		b.box("ap_small", "vcolor", c + r * (w * sd) + UP * ((ceil - c.y - h) * 0.5 + h), Vector3(0.006, ceil - c.y - h, 0.006), Transform3D.IDENTITY, [], true)
	b.cur_color = Color.WHITE

# ------------------------------------------------------------------ the fronts
## Lerner Shop: a dark wood fascia with "Lerner" in white lit script and NEW YORK under it
## (Hammond 22.4 s, Pecanland 16:37), glass windows each side of a wide doorway.
static func front_lerner(b, G, a, t, n, W):
	var LH = b.LANE_H
	var head = 2.8
	b.box(G, "a2_wood_dark", P(a, t, n, W * 0.5, (head + 4.1) * 0.5, -0.08), b.abs_size(t, W, 4.1 - head, 0.16, n))
	b.quad("a2_shell", "ap_cream", [P(a, t, n, 0, 4.1, 0), P(a, t, n, W, 4.1, 0), P(a, t, n, W, LH, 0), P(a, t, n, 0, LH, 0)], n)
	var c = P(a, t, n, W * 0.5, head + 0.42, -0.16)
	K.letters(b, G, "res://tools/stores/apparel/lerner_letters.json", c, n, "ap_letterwhite", "ap_letterwhite", 0.0, 0.06)
	K.letters(b, G, "res://tools/stores/apparel/lerner_ny_letters.json", P(a, t, n, W * 0.5 + 0.35, head + 0.16, -0.16), n, "ap_letterwhite", "ap_letterwhite", 0.0, 0.03)
	var rng = RandomNumberGenerator.new()
	windows(b, G, a, t, n, 0.1, 4.4, head, "a2_wood_dark", "a2_wood_dark", rng, ["#c84a8a", "#2e2e34", "#e8e2d2"])
	windows(b, G, a, t, n, W - 4.4, W - 0.1, head, "a2_wood_dark", "a2_wood_dark", rng, ["#7a3a8a", "#e8e2d2", "#c8b48c"])
	soffit(b, G, a, t, n, W, head)

## Lane Bryant: a cream fascia with white lit serif letters, an open front between cream
## square columns, mannequins on low platforms (Hammond 5.2-5.9 s).
static func front_lane(b, G, a, t, n, W):
	var LH = b.LANE_H
	var head = 2.9
	b.box(G, "a2_cream_panel", P(a, t, n, W * 0.5, (head + LH) * 0.5, -0.06), b.abs_size(t, W, LH - head, 0.12, n))
	K.letters(b, G, "res://tools/stores/apparel/lb_letters.json", P(a, t, n, W * 0.5, head + 0.5, -0.12), n, "a2_letter_glow", "ap_letterwhite", 0.02, 0.07)
	# a halo glow behind the letters
	var rv = (-n).cross(UP)
	b.quad(G, "a2_halo", [P(a, t, n, W * 0.5, head + 0.4, -0.125) - rv * 2.3, P(a, t, n, W * 0.5, head + 0.4, -0.125) + rv * 2.3, P(a, t, n, W * 0.5, head + 1.1, -0.125) + rv * 2.3, P(a, t, n, W * 0.5, head + 1.1, -0.125) - rv * 2.3], n)
	for u in [0.25, W * 0.5 - 1.3, W * 0.5 + 1.3, W - 0.25]:
		b.box(G, "a2_cream_panel", P(a, t, n, u, head * 0.5, 0.0), b.abs_size(t, 0.5, head, 0.5, n), Transform3D.IDENTITY, ["-y"])
		K.ob(b, P(a, t, n, u - 0.25, 0, -0.25), P(a, t, n, u + 0.25, 0, 0.25), 0.1)
	# mannequin platforms just inside, left and right of the middle way in
	for s in [[1.6, ["#2e3a5c", "#e8e2d2"]], [W - 1.6, ["#8a2a3a", "#2e2e34"]]]:
		var pc = P(a, t, n, s[0], 0, 1.0)
		b.box(G, "ap_white", pc + UP * 0.12, b.abs_size(t, 1.8, 0.24, 1.0, n), Transform3D.IDENTITY, ["-y"])
		K.mannequin(b, pc + UP * 0.24 - t * 0.4, -n, s[1][0], s[1][1])
		K.mannequin(b, pc + UP * 0.24 + t * 0.4, -n, s[1][1], "#2e2e34")
		K.ob(b, pc - t * 0.9 - n * 0.5, pc + t * 0.9 + n * 0.5, 0.1)
	soffit(b, G, a, t, n, W, head)

## Miller's Outpost: a wood fascia with outlined serif letters and a star between the words,
## wide open between wood piers (Pecanland 9:13-9:19).
static func front_millers(b, G, a, t, n, W):
	var LH = b.LANE_H
	var head = 2.9
	b.box(G, "a2_wood", P(a, t, n, W * 0.5, (head + LH) * 0.5, -0.08), b.abs_size(t, W, LH - head, 0.16, n))
	var c = P(a, t, n, W * 0.5, head + 0.4, -0.16)
	K.letters(b, G, "res://tools/stores/apparel/mo_letters.json", c, n, "a2_mo_letter", "a2_mo_edge", 0.0, 0.07)
	# the star between the words
	var rv = (-n).cross(UP)
	var sc = c + UP * 0.17 + n * 0.08
	var pts = []
	for k in 10:
		var rr = 0.2 if k % 2 == 0 else 0.085
		var ang = PI * 0.5 + TAU * k / 10.0
		pts.append(Vector2(cos(ang) * rr, sin(ang) * rr))
	var s = b.st(G, "a2_star", true)
	for k in 10:
		var p0 = sc + rv * pts[k].x + UP * pts[k].y
		var p1 = sc + rv * pts[(k + 1) % 10].x + UP * pts[(k + 1) % 10].y
		b.tri(s, sc, p0, p1, Vector2(0, 0), Vector2(0, 0), Vector2(0, 0), n)
	for u in [0.3, W * 0.5, W - 0.3]:
		b.box(G, "a2_wood", P(a, t, n, u, head * 0.5, 0.0), b.abs_size(t, 0.6, head, 0.5, n), Transform3D.IDENTITY, ["-y"])
		K.ob(b, P(a, t, n, u - 0.3, 0, -0.25), P(a, t, n, u + 0.3, 0, 0.25), 0.1)
	soffit(b, G, a, t, n, W, head, "a2_wood")

## Gadzooks: the 90s black tile grid fascia and piers, the name in red neon with red and blue
## neon bands above and below it, glass windows and a wide doorway (slideshow 0:02, 0:16).
static func front_gadzooks(b, G, a, t, n, W):
	var LH = b.LANE_H
	var head = 2.7
	var o = P(a, t, n, 0, 0, 0)
	b.box(G, "a2_gz_tile", P(a, t, n, W * 0.5, (head + LH) * 0.5, -0.08), b.abs_size(t, W, LH - head, 0.16, n))
	var c = P(a, t, n, W * 0.5, head + 0.5, -0.16)
	K.neon(b, G, "res://tools/stores/apparel/gz_letters.json", c, n, "a2_neon_red", 0.03, 0.02, 0.04)
	var rv = (-n).cross(UP)
	for band in [[head + 0.22, "a2_neon_red"], [head + 0.32, "a2_neon_blue"], [head + 1.12, "a2_neon_blue"], [head + 1.22, "a2_neon_red"]]:
		b.box(G, band[1], P(a, t, n, W * 0.5, band[0], -0.2), b.abs_size(t, W - 0.6, 0.035, 0.035, n), Transform3D.IDENTITY, [], true)
	# black tile piers and the glass
	for u in [0.3, 3.9, W - 3.9, W - 0.3]:
		b.box(G, "a2_gz_tile", P(a, t, n, u, head * 0.5, 0.0), b.abs_size(t, 0.6, head, 0.4, n), Transform3D.IDENTITY, ["-y"])
	var rng = RandomNumberGenerator.new()
	windows(b, G, a, t, n, 0.6, 3.6, head, "ap_black", "a2_gz_tile", rng, ["#3a8a4a", "#e8e2d2", "#2e3a5c"])
	windows(b, G, a, t, n, W - 3.6, W - 0.6, head, "ap_black", "a2_gz_tile", rng, ["#e04a30", "#2e2e34", "#e8c040"])
	soffit(b, G, a, t, n, W, head, "ap_black")

## The red neon round the top of the walls and the red-and-white checker aisle down the
## middle of the dark grey carpet (slideshow 0:36, 0:42).
static func gadzooks_extras(b, a, t, n, W, D):
	var G = "a2_shell"
	var q = [P(a, t, n, W * 0.5 - 1.0, 0.003, 0.0), P(a, t, n, W * 0.5 + 1.0, 0.003, 0.0), P(a, t, n, W * 0.5 + 1.0, 0.003, D - 3.0), P(a, t, n, W * 0.5 - 1.0, 0.003, D - 3.0)]
	var uv = []
	for p in q:
		uv.append(Vector2(p.x / 0.61, p.z / 0.61))
	b.quad(G, "a2_checker", q, UP, uv)
	for s in [[SIDE + 0.03, t], [W - SIDE - 0.03, -t]]:
		var p0 = P(a, t, n, s[0], 3.05, 1.0)
		var p1 = P(a, t, n, s[0], 3.05, D - 0.2)
		b.box("a2f_props", "a2_neon_red", (p0 + p1) * 0.5, b.abs_size(-n, D - 1.2, 0.03, 0.03, t), Transform3D.IDENTITY, [], true)

## The Limited: a black capsule sign with chrome ends, "the limited" in white neon script,
## over a wide open front (Hammond 3.8-4.05 s).
static func front_limited(b, G, a, t, n, W):
	var LH = b.LANE_H
	var head = 2.85
	b.box(G, "ap_charcoal", P(a, t, n, W * 0.5, (head + LH) * 0.5, -0.06), b.abs_size(t, W, LH - head, 0.12, n))
	var cw = 5.6
	var ch = 0.8
	var cc = P(a, t, n, W * 0.5, head + 0.62, 0.0)
	b.box(G, "a2_capsule", cc + n * 0.2, b.abs_size(t, cw - ch, ch, 0.28, n))
	var rv = (-n).cross(UP)
	for s in [-1.0, 1.0]:
		# the rounded chrome ends: half cylinders lying along the hall normal
		var ec = cc + rv * ((cw - ch) * 0.5 * s) + n * 0.06
		var seg = 8
		for k in seg:
			var a0 = -PI * 0.5 + PI * k / seg
			var a1 = -PI * 0.5 + PI * (k + 1) / seg
			var d0 = rv * (cos(a0) * s) * ch * 0.5 + UP * sin(a0) * ch * 0.5
			var d1 = rv * (cos(a1) * s) * ch * 0.5 + UP * sin(a1) * ch * 0.5
			var nn = (d0 + d1).normalized()
			b.quad(G, "ap_chrome", [ec + d0, ec + d1, ec + d1 + n * 0.28, ec + d0 + n * 0.28], nn, [], true)
			var sf = b.st(G, "ap_chrome", true)
			b.tri(sf, ec + n * 0.28, ec + d0 + n * 0.28, ec + d1 + n * 0.28, Vector2(0, 0), Vector2(0, 0), Vector2(0, 0), n)
	K.neon(b, G, "res://tools/stores/apparel/limited_letters.json", cc + UP * -0.16 + n * 0.34, n, "ap_neon", 0.025, 0.014, 0.02)
	for u in [0.2, W - 0.2]:
		b.box(G, "ap_charcoal", P(a, t, n, u, head * 0.5, 0.0), b.abs_size(t, 0.4, head, 0.4, n), Transform3D.IDENTITY, ["-y"])
		K.ob(b, P(a, t, n, u - 0.2, 0, -0.2), P(a, t, n, u + 0.2, 0, 0.2), 0.1)
	soffit(b, G, a, t, n, W, head, "ap_charcoal")

# ------------------------------------------------------------------ inside
static func inside(b, a, t, n, W, D, c, rng):
	var uL = SIDE
	var uR = W - SIDE
	var dEnd = D - 2.6
	var cash_u = uR if c.cash == "right" else uL
	var cash_face = -t if c.cash == "right" else t
	var other_u = uL if c.cash == "right" else uR
	var other_face = t if c.cash == "right" else -t
	var dc = clamp(D * 0.35, 6.0, 9.0)
	# face-out walls; the cash wrap breaks one side (staff stand between it and the wall)
	K.faceout_wall(b, a, t, n, other_u, other_face, 1.4, dEnd, 0 if c.seed % 2 else 1, rng, c.slat)
	K.faceout_wall(b, a, t, n, cash_u, cash_face, 1.4, dc - 0.4, 1, rng, c.slat)
	K.faceout_wall(b, a, t, n, cash_u, cash_face, dc + 3.2, dEnd, 0, rng, c.slat)
	var o = P(a, t, n, cash_u + cash_face.dot(t) * 1.3, 0, dc)
	K.cash_wrap(b, o, -n, cash_face, 2.6, 0.6)
	# fitting rooms across the back, the stockroom door in the corridor beside them
	var fu0 = uL if c.door > W * 0.5 else W * 0.5 - 1.0
	var fu1 = W * 0.5 + 1.0 if c.door > W * 0.5 else uR
	if W <= 8.0:
		fu0 = uL
		fu1 = uR - 1.4
	K.fitting_rooms(b, a, t, n, fu0, fu1, D - SIDE, 2.0, c.fit)
	# the floor: columns of round racks, four-ways and tables, cards hung over them
	var kinds = ["round", "four", "table", "round", "four", "round"]
	var ci = 0
	for cu in c.cols:
		var d = 3.0
		var k = ci
		while d < dEnd - 1.0:
			var kd = kinds[k % kinds.size()]
			var pc = P(a, t, n, cu, 0, d)
			if kd == "round":
				K.round_rack(b, pc, 0.62, k % 2)
			elif kd == "four":
				K.fourway(b, pc, 0.4 * (k % 2), k % 2)
			else:
				K.table(b, pc, 0.0, 1.5, 0.9, k % 2)
			d += 2.9
			k += 1
		ci += 1
	var cards = c.cards
	var j = 0
	for cu in c.cols:
		var d = 4.4
		while d < dEnd - 2.0:
			card(b, P(a, t, n, cu, 2.25, d), -n, cards[j % cards.size()], 0.5, 0.5, 3.2)
			d += 5.8
			j += 1

# ------------------------------------------------------------------ materials
## "a2_<key>" (build_mall.gd's mat() calls this).
static func fill_mat(m, key, b):
	match key:
		"cards":
			m.albedo_texture = b.tex("a2/cards.png"); m.roughness = 0.6
			m.emission_enabled = true; m.emission_texture = m.albedo_texture
			m.emission = Color.WHITE; m.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY
			m.emission_energy_multiplier = 0.35
			m.set_meta("e_day", 0.35); m.set_meta("e_night", 0.35)
		"carpet_mauve", "carpet_grey", "carpet_teal":
			m.albedo_texture = b.tex("a2/" + key + ".png"); m.roughness = 0.95; m.metallic_specular = 0.1
		"checker":
			m.albedo_texture = b.tex("a2/checker.png"); m.roughness = 0.2; m.metallic_specular = 0.6
		"gz_tile":
			m.albedo_texture = b.tex("a2/gz_tile.png"); m.roughness = 0.2; m.metallic_specular = 0.6
		"gz_ceiling":
			m.albedo_texture = b.tex("a2/gz_ceiling.png"); m.roughness = 0.9
		"capsule":
			m.albedo_texture = b.tex("a2/capsule.png"); m.roughness = 0.25; m.metallic_specular = 0.6
		"wood_dark":
			m.albedo_texture = b.tex("wood_dark.png"); m.roughness = 0.45
		"wood":
			m.albedo_texture = b.tex("wood_dark.png"); m.roughness = 0.5
			m.albedo_color = Color(1.15, 0.95, 0.8)
		"cream_panel":
			m.albedo_color = Color("#8f877a"); m.roughness = 0.6; m.metallic_specular = 0.4
		"halo":
			m.albedo_color = Color("#8f877a")
			m.emission_enabled = true; m.emission = Color("#fff4e0"); m.emission_energy_multiplier = 0.25
			m.set_meta("e_day", 0.1); m.set_meta("e_night", 0.3)
		"neon_blue":
			m.albedo_color = Color("#50a0ff")
			m.emission_enabled = true; m.emission = Color("#3080ff"); m.emission_energy_multiplier = 3.0
			m.set_meta("e_day", 2.5); m.set_meta("e_night", 3.0)
		"neon_red":
			# Gadzooks: a true red tube (period-art-director: the shared neon read pink)
			m.albedo_color = Color("#ff2a2a")
			m.emission_enabled = true; m.emission = Color("#ff1208"); m.emission_energy_multiplier = 2.2
			m.set_meta("e_day", 1.8); m.set_meta("e_night", 2.2)
		"letter_glow":
			# Lane Bryant: white letters lit from inside against the warm grey fascia (Hammond 5.2 s)
			m.albedo_color = Color("#fbfaf6"); m.roughness = 0.35
			m.emission_enabled = true; m.emission = Color("#fffaf0"); m.emission_energy_multiplier = 1.4
			m.set_meta("e_day", 1.0); m.set_meta("e_night", 1.4)
		"mo_letter":
			# Miller's Outpost: orange-red letter faces with a cream outline (Pecanland 9:13)
			m.albedo_color = Color("#d0562a"); m.roughness = 0.35
			m.emission_enabled = true; m.emission = Color("#e06030"); m.emission_energy_multiplier = 0.6
			m.set_meta("e_day", 0.4); m.set_meta("e_night", 0.8)
		"mo_edge":
			m.albedo_color = Color("#f2e2b8"); m.roughness = 0.4
			m.emission_enabled = true; m.emission = Color("#f2e2b8"); m.emission_energy_multiplier = 0.4
			m.set_meta("e_day", 0.3); m.set_meta("e_night", 0.5)
		"star":
			m.albedo_color = Color("#f2e2b8"); m.roughness = 0.4
			m.emission_enabled = true; m.emission = Color("#f6e6b8"); m.emission_energy_multiplier = 0.7
			m.set_meta("e_day", 0.5); m.set_meta("e_night", 0.9)
		_:
			return false
	return true
