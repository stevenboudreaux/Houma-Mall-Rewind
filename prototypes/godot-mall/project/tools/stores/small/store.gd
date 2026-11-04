## The Wave 5 small shops: Coach House Gifts (s21), General Nutrition Center (s21c) and
## MasterCuts (s24mc) on the west side of the east hall, Wicks 'N' Sticks (s44) on the north
## side, and Chick-fil-A (s64) by Pocket Change, built to design/storefronts/coach-house.md,
## gnc.md, mastercuts.md, wicks-n-sticks.md and chick-fil-a.md.
##
## The fronts follow the Southland facade records (made from Steven's photos) and the 1993
## Hammond Square commercial; the insides are period types laid out on the media kit
## (tools/stores/media/kit.gd) and the apparel kit's letters and neon. Layouts are guessed.
##
## Frame: P(a, t, n, u, y, d) = a + t u - n d + y up, u along the frontage from the edge's
## start, d into the store.

const CH = preload("res://tools/stores/signs/channel.gd")
const K = preload("res://tools/stores/media/kit.gd")
const AK = preload("res://tools/stores/apparel/kit.gd")
const M2 = preload("res://tools/stores/apparel/more.gd")
const UP = Vector3.UP
const SIDE = 0.12
const CFG = {
	"COACH HOUSE GIFTS": {"W": 10.0, "D": 24.0, "seed": 21},
	"GENERAL NUTRITION CENTER": {"W": 4.0, "D": 14.0, "seed": 22},
	"MASTERCUTS": {"W": 4.0, "D": 14.0, "seed": 24},
	"WICKS 'N' STICKS": {"W": 6.0, "D": 12.0, "seed": 44},
	"CHICK-FIL-A": {"W": 8.0, "D": 16.0, "seed": 64},
}

static func P(a, t, n, u, y, d):
	return a + t * u - n * d + Vector3(0, y, 0)

static func build(b, g, e, a, bb, n, t, Ln, sd):
	var c = CFG[sd.name]
	var rng = RandomNumberGenerator.new()
	rng.seed = c.seed
	# ws/interiors (Nov 4): never wider than the front; Wicks' front was narrowed to 5 m (27f5c378)
	# but CFG kept 6 m, and its right wall shelves stood 1 m inside Great American Cookie Co.
	var W = minf(c.W, a.distance_to(bb))
	var D = c.D
	match sd.name:
		"COACH HOUSE GIFTS": coach_house(b, a, t, n, W, D, rng)
		"GENERAL NUTRITION CENTER": gnc(b, a, t, n, W, D, rng)
		"MASTERCUTS": mastercuts(b, a, t, n, W, D, rng)
		"WICKS 'N' STICKS": wicks(b, a, t, n, W, D, rng)
		"CHICK-FIL-A": chick(b, a, t, n, W, D, rng)
	var rp = ReflectionProbe.new()
	rp.position = P(a, t, n, W * 0.5, 1.6, D * 0.5)
	rp.size = (t * W + n * D).abs() + Vector3(0.1, 3.3, 0.1)
	rp.box_projection = true
	rp.interior = true
	rp.update_mode = ReflectionProbe.UPDATE_ONCE
	rp.intensity = 0.6
	b.light_root.add_child(rp)

## The wall over a front, from `y0` to the lane ceiling.
static func upper(b, G, a, t, n, W, y0, m, proud = 0.12):
	b.box(G, m, P(a, t, n, W * 0.5, (y0 + b.LANE_H) * 0.5, -proud * 0.5), b.abs_size(t, W, b.LANE_H - y0, proud, n))

## A hanging card from sm/cards.png (4 x 4 cells), both faces.
static func card(b, c, facing, cell, w, h, ceil):
	var r = facing.cross(UP)
	var cu = (cell % 4) * 0.25
	var cv = (cell / 4) * 0.25
	for s in [1.0, -1.0]:
		var f = facing * s
		var rr = r * s
		K.fq(b, "sm_small", "sm_cards", c - rr * (w * 0.5) + f * 0.004, rr, f, 0.0, w, 0.0, h, 0.0, cu, cv, cu + 0.25, cv + 0.25, true)
	b.cur_color = Color("#c8c8c8")
	for sd in [-0.4, 0.4]:
		b.box("sm_small", "vcolor", c + r * (w * sd) + UP * ((ceil - c.y - h) * 0.5 + h), Vector3(0.006, ceil - c.y - h, 0.006), Transform3D.IDENTITY, [], true)
	b.cur_color = Color.WHITE

## Wall bays down both side walls from d0 to d1 (media kit), stock sheets per side.
static func side_bays(b, G, a, t, n, W, d0, d1, sheets_l, sheets_r, rng, back_mat = "md_white", boards = [0.4, 0.75, 1.1, 1.45, 1.8], depth = 0.34, frame_mat = "md_white"):
	var d = d0
	while d + 1.22 <= d1:
		var g1 = G if d < 10.0 else G + "2"
		K.bay(b, g1, g1, P(a, t, n, SIDE, 0, d + 1.22), n, t, 1.22, boards, sheets_r, rng, depth, back_mat, frame_mat)
		K.bay(b, g1, g1, P(a, t, n, W - SIDE, 0, d), -n, -t, 1.22, boards, sheets_l, rng, depth, back_mat, frame_mat)
		d += 1.22
	K.ob(b, P(a, t, n, SIDE, 0, d0), P(a, t, n, SIDE + depth + 0.05, 0, d), 0.08)
	K.ob(b, P(a, t, n, W - SIDE, 0, d0), P(a, t, n, W - SIDE - depth - 0.05, 0, d), 0.08)
	return d

# ------------------------------------------------------------------ GNC
## A portal of honed stone tile with three red letters standing off the lintel, glass either
## side on black plinths stacked with tubs, the bright shop of shelves beyond (record).
static func gnc(b, a, t, n, W, D, rng):
	var G = "smg_fix"
	var F = "smgf_props"
	var head = 2.6
	upper(b, F, a, t, n, W, head, "sm_stone", 0.2)
	for s in [[0.0, 0.2], [1.1, 1.3], [2.7, 2.9], [W - 0.2, W]]:
		b.box(F, "sm_stone", P(a, t, n, (s[0] + s[1]) * 0.5, head * 0.5, -0.1), b.abs_size(t, s[1] - s[0], head, 0.2, n), Transform3D.IDENTITY, ["-y"])
	AK.letters(b, F, "res://tools/stores/small/gnc_letters.json", P(a, t, n, W * 0.5, head + 0.42, -0.2), n, "sm_red_letter", "sm_red_side", 0.04, 0.07)
	for s in [[0.2, 1.1], [2.9, W - 0.2]]:
		b.box(F, "md_black", P(a, t, n, (s[0] + s[1]) * 0.5, 0.25, 0.0), b.abs_size(t, s[1] - s[0], 0.5, 0.2, n), Transform3D.IDENTITY, ["-y"])
		b.quad("glass", "glass", [P(a, t, n, s[0], 0.5, -0.02), P(a, t, n, s[1], 0.5, -0.02), P(a, t, n, s[1], head, -0.02), P(a, t, n, s[0], head, -0.02)], n,
			[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)], true)
		# tubs stacked on the plinth behind the glass
		K.stock_row(b, F, P(a, t, n, s[0], 0, 0.1), t, n, 0.02, s[1] - s[0] - 0.02, 0.5, 0.3, -0.05, "hba", rng)
		K.ob(b, P(a, t, n, s[0], 0, -0.1), P(a, t, n, s[1], 0, 0.4), 0.05)
	M2.shell2(b, "smg_shell", a, t, n, W, D, 3.0, 0.0, "md_vinyl", 0.61, "md_wall", "kb_ceiling", [1.7], 1.0)
	side_bays(b, G, a, t, n, W, 1.0, D - 2.6, ["hba"], ["hba", "boxes"], rng)
	# the counter across the back
	K.counter(b, G, "smg_small", P(a, t, n, W - 0.6, 0, D - 2.0), -t, n, W - 1.8, "md_ss_counter", rng)
	card(b, P(a, t, n, W * 0.5, 2.1, 3.0), -n, 2, 0.55, 0.55, 3.0)
	card(b, P(a, t, n, W * 0.5, 2.1, 7.5), -n, 1, 0.55, 0.55, 3.0)

# ------------------------------------------------------------------ MasterCuts
## A band of sea-green terrazzo with two brass lines, white condensed lettering standing off on
## black returns, a fluted cherry rail and cherry piers (record); a glass front with the door
## open; styling stations, a shampoo bay, product shelves, a reception desk.
static func mastercuts(b, a, t, n, W, D, rng):
	var G = "smm_fix"
	var F = "smmf_props"
	var head = 2.7
	upper(b, F, a, t, n, W, head + 0.6, "md_fascia_white", 0.12)
	K.fq(b, F, "sm_terrazzo", P(a, t, n, W, 0, 0), -t, n, 0.0, W, head + 0.1, head + 0.6, 0.14)
	K.lbox(b, F, "sm_terrazzo", P(a, t, n, 0, 0, 0), t, n, 0.0, head + 0.1, 0.0, W, 0.5, 0.135, ["-z"])
	AK.letters(b, F, "res://tools/stores/small/mc_letters.json", P(a, t, n, W * 0.5, head + 0.22, -0.14), n, "ap_letterwhite", "ap_black", 0.03, 0.06)
	# the fluted cherry rail and the cherry piers
	K.lbox(b, F, "sm_cherry", P(a, t, n, 0, 0, 0), t, n, 0.0, head, -0.02, W, 0.1, 0.16)
	for s in [[0.0, 0.3], [W - 0.3, W]]:
		b.box(F, "sm_cherry", P(a, t, n, (s[0] + s[1]) * 0.5, head * 0.5, -0.05), b.abs_size(t, s[1] - s[0], head, 0.22, n), Transform3D.IDENTITY, ["-y"])
	b.box(F, "sm_cherry", P(a, t, n, 1.15, 0.2, -0.02), b.abs_size(t, 1.7, 0.4, 0.12, n), Transform3D.IDENTITY, ["-y"])
	b.quad("glass", "glass", [P(a, t, n, 0.3, 0.4, -0.02), P(a, t, n, 2.0, 0.4, -0.02), P(a, t, n, 2.0, head, -0.02), P(a, t, n, 0.3, head, -0.02)], n,
		[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)], true)
	b.box(F, "sm_cherry", P(a, t, n, 2.03, head * 0.5, -0.02), b.abs_size(t, 0.06, head, 0.1, n))
	K.ob(b, P(a, t, n, 0.0, 0, -0.15), P(a, t, n, 2.05, 0, 0.1), 0.05)
	M2.shell2(b, "smm_shell", a, t, n, W, D, 3.0, 0.0, "md_vinyl", 0.61, "md_wall", "kb_ceiling", [1.7], 3.3)
	# the reception desk and product shelves by the door (record: shelves of bottles)
	K.counter(b, G, "smm_small", P(a, t, n, 0.9, 0, 2.0), -n, t, 1.4, "md_ss_counter", rng, 1.0, 0.55)
	K.bay(b, G, G, P(a, t, n, SIDE, 0, 3.6), n, t, 1.2, [0.5, 0.85, 1.2, 1.55], ["hba"], rng, 0.3)
	K.ob(b, P(a, t, n, SIDE, 0, 2.3), P(a, t, n, SIDE + 0.35, 0, 3.6), 0.05)
	# three styling stations along the left wall: a counter, a mirror, a hydraulic chair
	for k in 3:
		var d = 4.0 + k * 1.6
		var o = P(a, t, n, W - SIDE, 0, d)
		K.lbox(b, G, "sm_cherry", o, -n, -t, 0.1, 0.0, 0.0, 1.2, 0.85, 0.45)
		b.quad(G, "ap_mirror", [K.L(o, -n, -t, 0.15, 1.0, 0.01), K.L(o, -n, -t, 1.15, 1.0, 0.01), K.L(o, -n, -t, 1.15, 2.1, 0.01), K.L(o, -n, -t, 0.15, 2.1, 0.01)], -t)
		var cc = K.L(o, -n, -t, 0.7, 0.0, 1.1)
		b.cur_color = Color("#2a2a2c")
		b.cyl("smm_small", "vcolor", cc, 0.28, 0.24, 0.06, 14, true, false)
		b.cyl("smm_small", "vcolor", cc, 0.05, 0.05, 0.45, 8, false, false)
		b.box("smm_small", "vcolor", cc + UP * 0.52, Vector3(0.5, 0.12, 0.5))
		b.box("smm_small", "vcolor", cc + t * 0.22 + UP * 0.85, b.abs_size(-n, 0.48, 0.6, 0.1, t))
		b.cur_color = Color.WHITE
		K.ob(b, cc - Vector3(0.3, 0, 0.3), cc + Vector3(0.3, 0, 0.3), 0.05)
	K.ob(b, P(a, t, n, W - SIDE, 0, 4.0), P(a, t, n, W - SIDE - 0.5, 0, 8.9), 0.05)
	# the shampoo bay at the back: two basins on a cabinet, reclining chairs
	var so = P(a, t, n, SIDE, 0, D - 3.4)
	K.lbox(b, G, "sm_cherry", so, n, t, 0.0, 0.0, 0.0, 2.6, 0.85, 0.5)
	b.cur_color = Color("#1e1e20")
	for k in 2:
		b.cyl("smm_small", "vcolor", K.L(so, n, t, 0.65 + k * 1.3, 0.85, 0.25) - n * 0.0, 0.2, 0.2, 0.08, 14, false, false)
	b.cur_color = Color.WHITE
	K.ob(b, P(a, t, n, SIDE, 0, D - 3.4), P(a, t, n, SIDE + 0.6, 0, D - 0.8), 0.05)
	# a style poster and price cards
	K.fq(b, G, "sm_cards", P(a, t, n, SIDE, 0, 8.6), n, t, 0.0, 0.9, 1.1, 2.0, 0.01, 0.75, 0.25, 1.0, 0.5)
	card(b, P(a, t, n, W * 0.5, 2.05, 3.0), -n, 4, 0.5, 0.5, 3.0)

# ------------------------------------------------------------------ Coach House Gifts
## A course of small black tile, a smooth grey fascia with white serif capitals, black tile
## piers (record; Hammond 15.9 s: the name in white caps over one big window); inside, sea-
## green slat walls, hanging banners, tables and towers of gifts, dolls in a glass case.
static func coach_house(b, a, t, n, W, D, rng):
	var G = "smc_fix"
	var F = "smcf_props"
	var head = 2.7
	# Steven's sign pass (Oct 7: design/storefronts/photos/coach-house): the structure of photo 01
	# (columns either side of a centred entrance, an arched hood over it) in the colours of photo 02:
	# all cream, dark mahogany on the columns only; COACH HOUSE GIFTS in white 3D letters, one line
	upper(b, F, a, t, n, W, head + 0.25, "sg_ch_cream", 0.14)
	b.box(F, "sg_ch_cream", P(a, t, n, W * 0.5, head + 0.125, -0.07), b.abs_size(t, W, 0.25, 0.14, n))
	var hc = P(a, t, n, W * 0.5, head - 0.05, -0.14)
	CH.build(b, "smcf_sign", "res://tools/stores/signs/ch_hood_logo.json", hc, n, "sg_ch_cream_lt", "sg_ch_cream", "", 0.0, 0.45, 0.0)
	CH.build(b, "smcf_sign", "res://tools/stores/signs/ch_cornice_logo.json", hc, n, "sg_ch_trim", "sg_ch_trim", "", 0.0, 0.52, 0.0)
	CH.build(b, "smcf_sign", "res://tools/stores/signs/ch_name_logo.json", hc + UP * 0.4 + n * 0.45, n, "sg_ch_white", "sg_ch_return", "", 0.0, 0.05, 0.0, "sg_ch_glow")
	b.quad(F, "sg_ch_cream_lt", [P(a, t, n, W * 0.5 - 2.1, head - 0.05, -0.59), P(a, t, n, W * 0.5 + 2.1, head - 0.05, -0.59), P(a, t, n, W * 0.5 + 2.1, head - 0.05, -0.14), P(a, t, n, W * 0.5 - 2.1, head - 0.05, -0.14)], Vector3.DOWN)
	# the columns: cream shafts, mahogany plinths and capitals
	for u in [W * 0.5 - 1.85, W * 0.5 + 1.85]:
		var cb = P(a, t, n, u, 0, -0.35)
		b.box(F, "sg_ch_mahogany", cb + UP * 0.2, b.abs_size(t, 0.56, 0.4, 0.56, n))
		b.cyl(F, "sg_ch_mahogany", cb + UP * 0.4, 0.25, 0.22, 0.08, 20, false, false)
		b.cyl(F, "sg_ch_cream", cb + UP * 0.48, 0.2, 0.19, head - 0.05 - 0.48 - 0.3, 24, false, false)
		b.cyl(F, "sg_ch_mahogany", cb + UP * (head - 0.35), 0.19, 0.26, 0.18, 20, false, false)
		b.box(F, "sg_ch_mahogany", cb + UP * (head - 0.11), b.abs_size(t, 0.6, 0.12, 0.6, n))
		K.ob(b, cb - t * 0.3 - n * 0.3, cb + t * 0.3 + n * 0.3, 0.05)
	# cream piers at the ends, windows on low cream bases either side of the entrance
	for s in [[0.0, 0.3], [W - 0.3, W]]:
		b.box(F, "sg_ch_cream", P(a, t, n, (s[0] + s[1]) * 0.5, head * 0.5, -0.07), b.abs_size(t, s[1] - s[0], head, 0.14, n), Transform3D.IDENTITY, ["-y"])
	for s in [[0.3, W * 0.5 - 1.6], [W * 0.5 + 1.6, W - 0.3]]:
		b.box(F, "sg_ch_cream", P(a, t, n, (s[0] + s[1]) * 0.5, 0.25, -0.02), b.abs_size(t, s[1] - s[0], 0.5, 0.14, n), Transform3D.IDENTITY, ["-y"])
		b.quad("glass", "glass", [P(a, t, n, s[0], 0.5, -0.02), P(a, t, n, s[1], 0.5, -0.02), P(a, t, n, s[1], head, -0.02), P(a, t, n, s[0], head, -0.02)], n,
			[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)], true)
		b.box(F, "sg_ch_mahogany", P(a, t, n, s[1] if s[0] < 1.0 else s[0], head * 0.5, -0.02), b.abs_size(t, 0.06, head, 0.08, n))
		K.ob(b, P(a, t, n, s[0], 0, -0.15), P(a, t, n, s[1], 0, 0.1), 0.05)
	M2.shell2(b, "smc_shell", a, t, n, W, D, 3.1, 0.0, "a2_carpet_grey", 1.0, "sm_slat_green", "kb_ceiling", [2.0, 5.0, 8.0], 1.2)
	# window displays either side of the entrance: low white risers with gifts
	for s in [[0.5, W * 0.5 - 1.8], [W * 0.5 + 1.8, W - 0.5]]:
		K.lbox(b, G, "md_white", P(a, t, n, s[0], 0, 0.3), t, -n, 0.0, 0.0, 0.0, s[1] - s[0], 0.45, 0.8)
		K.stock_row(b, G, P(a, t, n, s[1] - 0.1, 0, 0.3), -t, n, 0.05, s[1] - s[0] - 0.2, 0.45, 0.3, -0.4, "gifts", rng)
		K.ob(b, P(a, t, n, s[0], 0, 0.2), P(a, t, n, s[1], 0, 1.1), 0.05)
	side_bays(b, G, a, t, n, W, 1.6, D - 2.4, ["gifts", "gcards"], ["gifts"], rng, "sm_slat_green")
	# tables and towers of gifts down the middle (gondolas with gifts), the glass doll case
	for row in [[3.0, 4.3], [3.0, 8.5], [6.6, 6.4], [6.6, 10.6], [3.0, 13.0], [6.6, 15.0]]:
		K.gondola(b, G + ("2" if row[1] > 10.0 else ""), G + ("2" if row[1] > 10.0 else ""), P(a, t, n, row[0] + 1.22, 0, row[1]), -t, n, 1.22, 1, [0.45, 0.85, 1.25], ["gifts", "candles"], rng, 0.3)
	var dc = P(a, t, n, 4.6, 0, 18.5)
	b.box(G + "2", "sm_cherry", dc + UP * 0.2, Vector3(1.0, 0.4, 0.5))
	for y in [0.75, 1.15, 1.55]:
		b.box(G + "2", "md_white", dc + UP * y, Vector3(0.96, 0.02, 0.46))
	K.stock_row(b, G + "2", dc - t * 0.45 + Vector3(0, 0, 0), t, -n, 0.0, 0.9, 0.42, 0.3, 0.0, "gifts", rng)
	K.stock_row(b, G + "2", dc - t * 0.45, t, -n, 0.0, 0.9, 0.77, 0.3, 0.0, "gifts", rng)
	b.box("glass", "glass", dc + UP * 1.2, Vector3(1.0, 1.6, 0.5), Transform3D.IDENTITY, ["-y"], true)
	K.ob(b, dc - Vector3(0.5, 0, 0.25), dc + Vector3(0.5, 0, 0.25), 0.1)
	# the cash wrap at the back right, banners overhead
	K.counter(b, G + "2", "smc_small", P(a, t, n, SIDE + 1.6, 0, D - 4.8), -n, t, 2.4, "md_bb_counter", rng)
	for s in [[2.8, 4.0, 8], [7.2, 9.0, 9], [5.0, 14.0, 10], [3.0, 17.0, 11]]:
		card(b, P(a, t, n, s[0], 2.15, s[1]), -n, s[2], 0.6, 0.6, 3.1)

# ------------------------------------------------------------------ Wicks 'N' Sticks
## A cedar-board front with a round-shouldered black fascia, white rounded letters with an
## arch and a red flame over each word, a bay window crammed with candles on stepped oak
## tiers (record; history slideshow 0:41-0:59); inside, light-oak étagères and tiered
## tables of candles, wood-panelled walls, warm light.
static func wicks(b, a, t, n, W, D, rng):
	var G = "smw_fix"
	var F = "smwf_props"
	var head = 2.5
	upper(b, F, a, t, n, W, head, "sm_cedar", 0.16)
	var fo = P(a, t, n, 0, 0, 0)
	K.lbox(b, F, "md_black", fo, t, n, 0.6, head + 0.15, 0.16, W - 1.2, 0.95, 0.06)
	for s in [-1.0, 1.0]:
		# the round shoulders: quarter discs at the panel's top corners
		var cc = P(a, t, n, W * 0.5 + s * (W * 0.5 - 0.6), head + 0.85, -0.19)
		var rv = (-n).cross(UP)
		var sf = b.st(F, "md_black", true)
		for k in 6:
			var a0 = PI * 0.5 * k / 6.0
			var a1 = PI * 0.5 * (k + 1) / 6.0
			b.tri(sf, cc, cc + rv * (s * sin(a0) * 0.25) + UP * cos(a0) * 0.25, cc + rv * (s * sin(a1) * 0.25) + UP * cos(a1) * 0.25, Vector2(0, 0), Vector2(0, 0), Vector2(0, 0), n)
	var lc = P(a, t, n, W * 0.5, head + 0.38, -0.22)
	AK.letters(b, F, "res://tools/stores/small/ws_letters.json", lc, n, "ap_letterwhite", "ap_letterwhite", 0.0, 0.04)
	# an arch with a red flame over "Wicks" and over "Sticks"
	var rv2 = (-n).cross(UP)
	for x in [-0.95, 0.95]:
		var ac = lc + rv2 * x + UP * 0.34 + n * 0.02
		for k in 10:
			var a0 = PI * k / 10.0
			var a1 = PI * (k + 1) / 10.0
			var p0 = ac + rv2 * cos(a0) * 0.42 + UP * sin(a0) * 0.16
			var p1 = ac + rv2 * cos(a1) * 0.42 + UP * sin(a1) * 0.16
			var dvec = p1 - p0
			b.box(F, "ap_letterwhite", Vector3.ZERO, Vector3(0.03, dvec.length() + 0.02, 0.03), Transform3D(Basis(dvec.normalized().cross(n).normalized(), dvec.normalized(), n), (p0 + p1) * 0.5), [], true)
		var fl = ac + UP * 0.2
		var s2 = b.st(F, "sm_flame", true)
		b.tri(s2, fl + rv2 * -0.05, fl + rv2 * 0.05, fl + UP * 0.16, Vector2(0, 0), Vector2(0, 0), Vector2(0, 0), n)
		b.tri(s2, fl + rv2 * -0.05, fl + rv2 * 0.05, fl - UP * 0.04, Vector2(0, 0), Vector2(0, 0), Vector2(0, 0), n)
	# cedar piers, the bay window with oak tiers of candles, the open door bay on the right (1.8 m:
	# the window takes the rest; Oct 7 the front was narrowed from 6 m to 5 m, narrow_stores.py)
	var wx = W - 2.1
	for s in [[0.0, 0.3], [wx, wx + 0.3], [W - 0.3, W]]:
		b.box(F, "sm_cedar", P(a, t, n, (s[0] + s[1]) * 0.5, head * 0.5, -0.08), b.abs_size(t, s[1] - s[0], head, 0.16, n), Transform3D.IDENTITY, ["-y"])
	b.box(F, "sm_cedar", P(a, t, n, (0.3 + wx) * 0.5, 0.3, -0.05), b.abs_size(t, wx - 0.3, 0.6, 0.2, n), Transform3D.IDENTITY, ["-y"])
	b.quad("glass", "glass", [P(a, t, n, 0.3, 0.6, -0.04), P(a, t, n, wx, 0.6, -0.04), P(a, t, n, wx, head, -0.04), P(a, t, n, 0.3, head, -0.04)], n,
		[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)], true)
	for k in 3:
		var y = 0.6 + k * 0.35
		K.lbox(b, G, "sm_oak", P(a, t, n, 0.35, 0, 0.1 + k * 0.3), t, -n, 0.0, 0.0, 0.0, wx - 0.4, y, 0.3)
		K.stock_row(b, G, P(a, t, n, wx - 0.05, 0, 0.1 + k * 0.3), -t, n, 0.0, wx - 0.4, y, 0.3, -0.05, "candles", rng)
	K.ob(b, P(a, t, n, 0.0, 0, -0.15), P(a, t, n, wx + 0.3, 0, 1.1), 0.05)
	M2.shell2(b, "smw_shell", a, t, n, W, D, 2.9, 0.0, "a2_carpet_mauve", 1.0, "sm_oak_wall", "kb_ceiling", [1.6, 4.0], 1.0, 0.9)
	side_bays(b, G, a, t, n, W, 1.4, D - 2.3, ["candles"], ["candles", "gifts"], rng, "sm_oak", [0.4, 0.75, 1.1, 1.45, 1.8], 0.36, "sm_oak")
	# tiered tables of candles in the middle: three stepped oak tiers each
	for dd in [3.5, 6.6]:
		var c0 = P(a, t, n, W * 0.5, 0, dd)
		for k in 3:
			var w = 1.4 - k * 0.4
			b.box(G, "sm_oak", c0 + UP * (0.35 + k * 0.25), b.abs_size(t, w, 0.04, w * 0.6, n))
			K.stock_row(b, G, c0 - t * (w * 0.5), t, -n, 0.02, w - 0.02, 0.37 + k * 0.25, 0.24, w * 0.3 - 0.02, "candles", rng)
			K.stock_row(b, G, c0 + t * (w * 0.5), -t, n, 0.02, w - 0.02, 0.37 + k * 0.25, 0.24, w * 0.3 - 0.02, "candles", rng)
		b.box(G, "sm_oak", c0 + UP * 0.17, b.abs_size(t, 1.3, 0.34, 0.7, n), Transform3D.IDENTITY, ["-y"])
		K.ob(b, c0 - Vector3(0.7, 0, 0.7), c0 + Vector3(0.7, 0, 0.7), 0.1)
	K.counter(b, G, "smw_small", P(a, t, n, W - 0.6, 0, D - 1.8), -t, n, W - 2.2, "md_bb_counter", rng)
	# warm light: the store glows amber at night
	var l = b.add_omni(P(a, t, n, W * 0.5, 2.4, D * 0.5), 0.6, 8.0, Color(1.0, 0.84, 0.6))
	b.tag(l, "", 0.5, 0.7)

# ------------------------------------------------------------------ Chick-fil-A
## A bulkhead of tan tile set on the diagonal, a deep red sign box with the script name in
## hot pink-white neon (record; Hammond 19.2 s); inside, a dining room with striped
## wallpaper over a dark wainscot, brass sconces and framed pictures (Hammond), tables and
## chairs, and the long timber counter across the back under a row of lit menu panels.
static func chick(b, a, t, n, W, D, rng):
	var G = "smk_fix"
	var F = "smkf_props"
	var head = 2.7
	upper(b, F, a, t, n, W, head, "sm_tan_diag", 0.14)
	K.lbox(b, F, "sm_red_box", P(a, t, n, 0, 0, 0), t, n, 1.2, head + 0.35, 0.14, W - 2.4, 1.05, 0.2)
	AK.neon(b, F, "res://tools/stores/small/cfa_letters.json", P(a, t, n, W * 0.5, head + 0.62, -0.34), n, "sm_neon_pink", 0.02, 0.018, 0.02)
	for s in [[0.0, 0.35], [W - 0.35, W]]:
		b.box(F, "sm_tan_diag", P(a, t, n, (s[0] + s[1]) * 0.5, head * 0.5, -0.07), b.abs_size(t, s[1] - s[0], head, 0.14, n), Transform3D.IDENTITY, ["-y"])
	M2.shell2(b, "smk_shell", a, t, n, W, D, 3.0, 0.0, "wl_rest_floor", 0.61, "sm_stripes", "kb_ceiling", [2.0, 5.4], 7.2, 1.0)
	M2.soffit(b, F, a, t, n, W, head, "sm_tan_diag")
	# a dark wainscot round the dining room, sconces and framed pictures
	for w in [[SIDE, 0.8, SIDE, D - 4.0, t], [W - SIDE, D - 4.0, W - SIDE, 0.8, -t]]:
		var pa = P(a, t, n, w[0], 0, w[1])
		var pb = P(a, t, n, w[2], 0, w[3])
		b.quad(G, "sm_wainscot", [pa + w[4] * 0.01, pb + w[4] * 0.01, pb + w[4] * 0.01 + UP * 0.9, pa + w[4] * 0.01 + UP * 0.9], w[4])
	for k in 3:
		var d = 2.2 + k * 2.6
		for s in [[SIDE, t, n], [W - SIDE, -t, -n]]:
			var wc = P(a, t, n, s[0], 1.85, d)
			b.cur_color = Color("#b88d3e")
			b.box("smk_small", "vcolor", wc + s[1] * 0.05, Vector3(0.06, 0.16, 0.06))
			b.cur_color = Color.WHITE
			K.column(b, "smk_small", "wl_globe", wc + s[1] * 0.1 + UP * 0.02, 0.07, 0.12, 10)
			K.fq(b, G, "wl_food_photos", P(a, t, n, s[0], 0, d + 0.6), s[2], s[1], 0.0, 0.6, 1.3, 1.9, 0.01, (k % 4) * 0.25, 0.0, (k % 4) * 0.25 + 0.25, 1.0)
	# tables with chairs in two rows
	for c in [[2.0, 2.6], [2.0, 5.2], [2.0, 7.8], [6.0, 2.6], [6.0, 5.2], [6.0, 7.8]]:
		var tc = P(a, t, n, c[0], 0, c[1])
		var WL = load("res://tools/stores/woolworth/store.gd")
		WL.table(b, G, tc)
		for s in [-1.0, 1.0]:
			WL.chair(b, "smk_small", tc + t * 0.6 * s, -t * s)
	# the timber counter across the back with dark inset rounds, menu panels above it
	var co = P(a, t, n, W - 0.5, 0, D - 4.6)
	K.lbox(b, G, "sm_cherry", co, -t, n, 0.0, 0.0, 0.0, W - 1.6, 1.05, 0.65, ["-y"])
	b.cur_color = Color("#3a2a20")
	var x = 0.4
	while x < W - 1.8:
		b.cyl("smk_small", "vcolor", K.L(co, -t, n, x, 0.55, 0.66) - n * 0.0, 0.16, 0.16, 0.01, 14, true, false)
		x += 0.7
	b.cur_color = Color.WHITE
	K.register(b, "smk_small", K.L(co, -t, n, 1.0, 1.05, 0.1), -t, n)
	K.register(b, "smk_small", K.L(co, -t, n, 3.6, 1.05, 0.1), -t, n)
	K.ob(b, P(a, t, n, 0.5, 0, D - 4.7), P(a, t, n, W - 0.5, 0, D - 0.2), 0.1)
	var mo = P(a, t, n, W - 0.8, 0, D - 0.15)
	for k in 4:
		K.fq(b, G, "sm_cards", mo, -t, n, k * 1.6, k * 1.6 + 1.5, 1.7, 2.6, 0.02, k * 0.25, 0.75, k * 0.25 + 0.25, 1.0)
	# the kitchen line behind the counter: stainless steel
	K.lbox(b, G, "wl_steel", P(a, t, n, W - 0.5, 0, D - SIDE), -t, n, 0.0, 0.0, 0.0, W - 1.0, 0.9, 0.7)

# ------------------------------------------------------------------ materials
## "sm_<key>" (build_mall.gd's mat() calls this).
static func fill_mat(m, key, b):
	match key:
		"stone":
			m.albedo_texture = b.tex("sm/stone.png"); m.roughness = 0.35; m.metallic_specular = 0.5
		"terrazzo":
			m.albedo_texture = b.tex("sm/terrazzo.png"); m.roughness = 0.2; m.metallic_specular = 0.6
		"slat_green":
			m.albedo_texture = b.tex("sm/slat_green.png"); m.roughness = 0.6
		"cedar":
			m.albedo_texture = b.tex("sm/cedar.png"); m.roughness = 0.8
		"tan_diag":
			m.albedo_texture = b.tex("sm/tan_diag.png"); m.roughness = 0.4; m.metallic_specular = 0.5
		"stripes":
			m.albedo_texture = b.tex("sm/stripes.png"); m.roughness = 0.8
		"cards":
			m.albedo_texture = b.tex("sm/cards.png"); m.roughness = 0.6
			K.emit_tex(m, 0.35)
		"grey":
			m.albedo_color = Color("#6e6e72"); m.roughness = 0.45; m.metallic_specular = 0.45
		"cherry":
			m.albedo_texture = b.tex("wood_dark.png"); m.roughness = 0.35; m.metallic_specular = 0.5
			m.albedo_color = Color(1.25, 0.9, 0.8)
		"oak":
			m.albedo_texture = b.tex("wood_dark.png"); m.roughness = 0.5
			m.albedo_color = Color(2.0, 1.7, 1.25)
		"oak_wall":
			m.albedo_texture = b.tex("wood_dark.png"); m.roughness = 0.7
			m.albedo_color = Color(1.6, 1.3, 1.0)
		"wainscot":
			m.albedo_color = Color("#3e2618"); m.roughness = 0.5
		"red_box":
			m.albedo_color = Color("#8e1424"); m.roughness = 0.4; m.metallic_specular = 0.5
		"red_letter":
			m.albedo_color = Color("#d8202c"); m.roughness = 0.35
			K.emit(m, Color("#ff2a30"), 1.0)
		"red_side":
			m.albedo_color = Color("#7a1218"); m.roughness = 0.5
		"flame":
			m.albedo_color = Color("#e83a10")
			K.emit(m, Color("#ff2a08"), 1.3)
		"neon_pink":
			m.albedo_color = Color("#ffe0ee")
			m.emission_enabled = true; m.emission = Color("#ff9ac8"); m.emission_energy_multiplier = 3.0
			m.set_meta("e_day", 2.5); m.set_meta("e_night", 3.0)
		_:
			return false
	return true
