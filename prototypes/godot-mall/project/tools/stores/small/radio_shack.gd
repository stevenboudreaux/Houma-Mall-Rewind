## Radio Shack's inside (s21b), rebuilt Oct 20, 2026 from the video Steven sent ("Christmas
## shopping at RadioShack in 1999", a mall store): design/storefronts/radio-shack.md.
##
## What the video shows, and where it went here:
## - Walls lined floor to 2.3 m with grey shelves whose lips carry red price strips, rows of black
##   out-of-box electronics on them (phones, answering machines, scanners, clock radios), boxed
##   goods on the low shelves, white pegboard of blister-packed parts above (0:00-0:44, 5:20-5:56).
## - A black-and-white striped valance over the wall sections and a navy band up to a dark
##   charcoal lay-in ceiling with bright 2 x 4 troffers (1:00-1:20, 3:24, 6:12-6:40).
## - The back wall: the red "PowerZone" header over the battery wall (0:56-1:20, 2:36-3:00).
## - The cash wrap: a long glass showcase counter on a black base with beige CRT terminals,
##   colour-keyed keyboards and a card swiper; the clerks stand between it and a wall of phones
##   (0:00-2:20, 4:00-6:40). Here it runs down the right side, the clerks' aisle behind it.
## - The floor: a low double-sided gondola of boxed goods, stacks of R/C truck boxes, a blue R/C
##   monster truck on a white pedestal at the door and a satellite dish display (0:48-0:56).
## - Dark grey carpet.
## Every product is invented (tools/stores/small/paint_rs.py); the only words are the store's own
## department headers.
##
## Frame: P(a, t, n, u, y, d) = a + t u - n d + y up, u along the frontage from its start (the
## viewer's left, where the door is), d into the store. The shell is 8 m wide; the walk grid stops
## at u 6.4 (tools/narrow_stores.py), so the clerks' aisle behind the counter is out of reach.

const K = preload("res://tools/stores/media/kit.gd")
const M2 = preload("res://tools/stores/apparel/more.gd")
const UP = Vector3.UP
const SIDE = 0.12
const CEIL = 3.0
const TOP = 2.3          # the wall units' top
const VAL0 = 2.36        # the valance band
const VAL1 = 2.62

static func P(a, t, n, u, y, d):
	return a + t * u - n * d + Vector3(0, y, 0)

static func inside(b, a, t, n, W, D, rng):
	var G = "s6r_fix"
	var G2 = "s6r_fix2"
	var S = "s6r_small"
	M2.shell2(b, "s6r_shell", a, t, n, W, D, CEIL, 0.0, "md_carpet_grey", 1.0, "md_wall", "s6_rs_ceiling", [1.4, 4.2], W - 1.6, 1.4)
	var dB = D - SIDE
	# --- the left wall: shelves of phones and boxes, parts above, from behind the window to the back
	var d = 1.3
	var k = 0
	while d + 1.22 <= dB - 0.05:
		var g = G if d < 8.0 else G2
		var sheets = [["rsboxes", "rsphones", "rsphones"], ["rsboxes", "rsphones", "rsboxes"]][k % 2]
		unit(b, g, P(a, t, n, SIDE, 0, d + 1.22), n, t, 1.22, sheets, rng)
		d += 1.22
		k += 1
	K.ob(b, P(a, t, n, SIDE, 0, 1.3), P(a, t, n, SIDE + 0.45, 0, d), 0.06)
	band(b, G, P(a, t, n, SIDE, 0, dB), n, t, dB - 0.9)
	header(b, G, P(a, t, n, SIDE, 0, 6.2), n, t, 2.4, 1)
	# --- the right wall, behind the counter: the phone wall
	d = 1.3
	k = 0
	while d + 1.22 <= dB - 1.4:
		var g2 = G if d < 8.0 else G2
		unit(b, g2, P(a, t, n, W - SIDE, 0, d), -n, -t, 1.22, ["rsboxes", "rsphones", "rsphones"], rng)
		d += 1.22
		k += 1
	band(b, G, P(a, t, n, W - SIDE, 0, 0.9), -n, -t, dB - 0.9)
	header(b, G, P(a, t, n, W - SIDE, 0, 3.0), -n, -t, 2.4, 2)
	# --- the back wall: PowerZone over the battery wall, the stockroom door at the right
	var bw = W - 2.3
	var x = 0.0
	while x + 1.22 <= bw + 0.01:
		unit(b, G2, P(a, t, n, SIDE + x, 0, dB), t, n, 1.22, ["rsbatt", "rsbatt", "rsboxes"], rng, "rsbatt")
		x += 1.22
	K.ob(b, P(a, t, n, SIDE, 0, dB), P(a, t, n, SIDE + x, 0, dB - 0.45), 0.06)
	band(b, G2, P(a, t, n, SIDE, 0, dB), t, n, W - 2 * SIDE)
	header(b, G2, P(a, t, n, SIDE + bw * 0.5 - 1.2, 0, dB), t, n, 2.4, 0)
	# --- the counter down the right side: glass showcases on a black base, two terminals
	counter(b, G, S, P(a, t, n, 5.65, 0, 2.6), -n, -t, 6.4, rng)
	# --- the floor
	gondola(b, G2, P(a, t, n, 2.75, 0, 5.0), -n, t, 4.88, rng)
	truck(b, S, P(a, t, n, 3.4, 0, 2.3), -n, rng)
	dish(b, S, P(a, t, n, 1.15, 0, 3.4), t - n * 0.3)
	for s in [[4.55, 2.4, 3], [2.75, 10.6, 2]]:
		stack(b, G, P(a, t, n, s[0], 0, s[1]), -n, t, s[2], rng)
	# promo cards on the wall over the counter end
	K.fq(b, G, "s6_rs_cards", P(a, t, n, W - SIDE, 0, 1.4), -n, -t, 0.0, 1.0, 2.02, 2.32, 0.01, 0.0, 0.0, 1.0, 1.0)
	# --- Nov 1, 2026 (workstream D): more from the back of the store in the 1999 video
	# (refs/new/radioshack_1999, 4:20-4:50): the wall of wire and cable spools on grey panels,
	# Christmas shipping cartons and the black podium at the counter's end where the R/C box
	# was opened
	spools(b, G2, P(a, t, n, 2.75, 0, 12.2), -n, t, 1.6, rng)
	cartons(b, G, P(a, t, n, 4.2, 0, 9.5), -n, t, rng)
	# --- the standalone items (data/items/radioshack.json): separate scenes on the counter,
	# for workstream B+C to pick up
	items(b)

## One wall unit, `w` wide along r from o, facing f: a white back, grey shelves at three
## levels with red lips (boxed goods low, electronics above), white pegboard of parts from
## 1.35 m to the top, a grey frame. `sheets`: the stock for the shelf levels, bottom first.
static func unit(b, G, o, r, f, w, sheets, rng, peg = "rsparts"):
	var dp = 0.42
	b.quad(G, "md_white", [K.L(o, r, f, 0, 0.12, 0.01), K.L(o, r, f, w, 0.12, 0.01), K.L(o, r, f, w, 1.36, 0.01), K.L(o, r, f, 0, 1.36, 0.01)], f)
	# the pegboard, its parts hanging a little off it (a stock sheet laid flat)
	K.stock_row(b, G, o, r, f, 0.02, w - 0.02, 1.36, TOP - 1.4, 0.07, peg, rng)
	K.lbox(b, G, "s6_rs_shelf", o, r, f, 0.0, 0.0, 0.0, w, 0.12, dp, ["-y", "-z"])
	for x in [0.0, w - 0.025]:
		K.lbox(b, G, "s6_rs_shelf", o, r, f, x, 0.12, 0.01, 0.025, TOP - 0.12, 0.06, ["-y", "-z"])
	var levels = [0.12, 0.5, 0.92, 1.32]
	for i in levels.size():
		var y = levels[i]
		var deep = dp if i < 2 else dp - 0.08
		if i > 0:
			K.lbox(b, G, "s6_rs_shelf", o, r, f, 0.025, y - 0.025, 0.01, w - 0.05, 0.025, deep, ["-z"])
		K.fq(b, G, "s6_rs_red", o, r, f, 0.025, w - 0.025, y - 0.03, y + 0.012, deep + 0.002)
		if i < levels.size() - 1:
			var room = levels[i + 1] - y - 0.04
			K.stock_row(b, G, o, r, f, 0.03, w - 0.03, y, room, deep - 0.04, sheets[i % sheets.size()], rng)
	K.lbox(b, G, "s6_rs_shelf", o, r, f, 0.0, TOP - 0.03, 0.0, w, 0.03, 0.12, [])

## The striped valance over the wall units and the navy band above it to the ceiling, `ln` long.
static func band(b, G, o, r, f, ln):
	K.fq(b, G, "s6_rs_valance", o, r, f, 0.0, ln, VAL0, VAL1, 0.08, 0.0, 0.0, ln / 1.0, 1.0)
	K.lbox(b, G, "s6_rs_black", o, r, f, 0.0, VAL1, 0.0, ln, 0.03, 0.08, [])
	K.fq(b, G, "s6_rs_navy", o, r, f, 0.0, ln, VAL1, CEIL, 0.005)
	K.fq(b, G, "s6_rs_navy", o, r, f, 0.0, ln, TOP, VAL0, 0.005)

## A department header standing on the valance: row `row` of rs_signs (0 PowerZone, 1 Telephones,
## 2 Cellular, 3 Computers), `w` wide, in a black box.
static func header(b, G, o, r, f, w, row):
	K.lbox(b, G, "s6_rs_black", o, r, f, -0.04, VAL1 - 0.02, 0.0, w + 0.08, 0.36, 0.14, [])
	K.fq(b, G, "s6_rs_signs", o, r, f, 0.0, w, VAL1, VAL1 + 0.32, 0.141, 0.0, row * 0.25, 1.0, (row + 1) * 0.25)

## The cash wrap: glass showcases on a black base along r from o (the shoppers' side faces f),
## a black top rail, phones and boxes on glass shelves inside, two beige terminals with their
## keyboards and a card swiper on the clerks' side, a radiused glass end at the front.
static func counter(b, G, S, o, r, f, ln, rng):
	var dp = 0.6
	var h = 0.98
	# the black kick base and the back cabinet (clerks' side)
	K.lbox(b, G, "s6_rs_black", o, r, f, 0.0, 0.0, -dp, ln, 0.32, dp, ["-y"])
	K.lbox(b, G, "md_laminate", o, r, f, 0.0, 0.32, -dp, ln, h - 0.32, 0.2, ["-y"])
	# the showcase: glass front and top, a glass shelf, stock inside
	b.quad("glass", "glass", [K.L(o, r, f, 0.0, 0.32, -0.01), K.L(o, r, f, ln, 0.32, -0.01), K.L(o, r, f, ln, h, -0.01), K.L(o, r, f, 0.0, h, -0.01)], f,
		[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)], true)
	b.quad("glass", "glass", [K.L(o, r, f, 0.0, h, -0.01), K.L(o, r, f, ln, h, -0.01), K.L(o, r, f, ln, h, -dp + 0.2), K.L(o, r, f, 0.0, h, -dp + 0.2)], UP,
		[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)], true)
	K.lbox(b, G, "md_white", o, r, f, 0.0, 0.32, -dp + 0.2, ln, 0.01, dp - 0.21, ["-y"])
	K.stock_row(b, G, o, r, f, 0.05, ln - 0.05, 0.33, 0.28, -0.08, "rsphones", rng)
	K.stock_row(b, G, o, r, f, 0.05, ln - 0.05, 0.66, 0.28, -0.14, "rsphones", rng)
	b.quad(G, "md_white", [K.L(o, r, f, 0.0, 0.65, -0.02), K.L(o, r, f, ln, 0.65, -0.02), K.L(o, r, f, ln, 0.65, -dp + 0.2), K.L(o, r, f, 0.0, 0.65, -dp + 0.2)], UP)
	# the frame: corner posts every 1.6 m, a black rail round the top, the back counter top
	var x = 0.0
	while x <= ln + 0.01:
		K.lbox(b, G, "s6_rs_black", o, r, f, min(x, ln - 0.03), 0.32, -0.03, 0.03, h - 0.32, 0.03, [])
		x += 1.6
	K.lbox(b, G, "s6_rs_black", o, r, f, 0.0, h, -0.03, ln, 0.025, 0.03, [])
	K.lbox(b, G, "s6_rs_black", o, r, f, 0.0, h, -dp, ln, 0.035, 0.22, [])
	# terminals and keyboards on the back counter, facing the clerks (-f)
	for tx in [1.1, 4.2]:
		terminal(b, S, K.L(o, r, f, tx, h + 0.035, -dp + 0.02), r, f)
	# a bag rack and a stack of black bags at the far end
	K.lbox(b, S, "s6_rs_black", o, r, f, ln - 0.7, h + 0.035, -dp + 0.02, 0.5, 0.08, 0.3, [])
	K.ob_local(b, o, r, f, -0.05, -dp - 0.05, ln + 0.05, 0.02)

## A beige CRT terminal with a keyboard and a card swiper: the screen faces -f.
static func terminal(b, S, o, r, f):
	var beige = Color("#d9d2bf")
	b.cur_color = beige
	K.lbox(b, S, "vcolor", o, r, f, -0.2, 0.0, 0.05, 0.4, 0.06, 0.34, [], true)
	K.lbox(b, S, "vcolor", o, r, f, -0.19, 0.06, 0.07, 0.38, 0.34, 0.36, [], true)
	K.lbox(b, S, "vcolor", o, r, f, -0.14, 0.1, 0.43, 0.28, 0.24, 0.12, [], true)
	K.fq(b, S, "s6_rs_screen", o, -r, -f, -0.15, 0.15, 0.1, 0.36, -0.069, 0.0, 0.0, 1.0, 1.0, true)
	# the keyboard in front of it, with its colour-keyed blocks (video 1:24)
	K.lbox(b, S, "vcolor", o, r, f, -0.24, 0.0, -0.22, 0.48, 0.035, 0.2, [], true)
	var cols = ["#e8c23a", "#5a8ad8", "#4ab85a", "#c86ac8", "#e8c23a"]
	for i in cols.size():
		b.cur_color = Color(cols[i])
		K.lbox(b, S, "vcolor", o, r, f, -0.22 + i * 0.09, 0.035, -0.2, 0.07, 0.008, 0.06, [], true)
	b.cur_color = Color("#c8c2b2")
	K.lbox(b, S, "vcolor", o, r, f, 0.28, 0.0, -0.12, 0.12, 0.06, 0.08, [], true)
	b.cur_color = Color.WHITE

## The low double-sided gondola: two shelves a side with red lips, boxed goods and electronics,
## an end panel at each end with a stack of truck boxes on the front one.
static func gondola(b, G, o, r, f, ln, rng):
	var dp = 0.38
	var hgt = 1.45
	for s in [1.0, -1.0]:
		var oo = o if s > 0 else o + r * ln
		var rr = r * s
		var ff = f * s
		K.lbox(b, G, "s6_rs_shelf", oo, rr, ff, 0.0, 0.0, 0.0, ln, 0.12, dp, ["-y"])
		for i in 3:
			var y = [0.12, 0.6, 1.05][i]
			if i > 0:
				K.lbox(b, G, "s6_rs_shelf", oo, rr, ff, 0.0, y - 0.025, 0.0, ln, 0.025, dp, [])
			K.fq(b, G, "s6_rs_red", oo, rr, ff, 0.0, ln, y - 0.03, y + 0.012, dp + 0.002)
			K.stock_row(b, G, oo, rr, ff, 0.03, ln - 0.03, y, [0.44, 0.41, 0.36][i], dp - 0.04, ["rsboxes", "rsphones", "rsparts"][i], rng)
	K.lbox(b, G, "md_white", o, r, f, 0.0, 0.12, -0.02, ln, hgt - 0.12, 0.04, [])
	for e in [0.0, ln]:
		K.lbox(b, G, "s6_rs_shelf", o + r * e - r * 0.02, r, f, 0.0, 0.0, -dp - 0.02, 0.04, hgt, (dp + 0.02) * 2.0, [])
	# a promo card on each end panel
	K.fq(b, G, "s6_rs_cards", o - r * 0.021, f, -r, -0.3, 0.3, 0.75, 1.35, 0.0, 0.0, 0.0, 0.5, 1.0)
	K.fq(b, G, "s6_rs_cards", o + r * (ln + 0.021), -f, r, -0.3, 0.3, 0.75, 1.35, 0.0, 0.5, 0.0, 1.0, 1.0)
	K.ob_local(b, o, r, f, -0.05, -dp - 0.05, ln + 0.05, dp + 0.05)

## A stack of R/C truck boxes on the floor, `count` high, along r, the box faces toward f.
static func stack(b, G, o, r, f, count, rng):
	for i in count:
		var c = o + UP * (i * 0.3)
		var jit = r * rng.randf_range(-0.03, 0.03)
		K.lbox(b, G, "s6_rs_box", c + jit, r, f, -0.28, 0.0, -0.2, 0.56, 0.3, 0.4, ["-y"] if i == 0 else [])
		var cell = rng.randi_range(0, 3)
		K.fq(b, G, "md_stock_rsboxes", c + jit, r, f, -0.27, 0.27, 0.01, 0.29, 0.201, 0.0, 0.0 + cell * 0.125, 0.45, 0.125 + cell * 0.125)
	K.ob(b, o - Vector3(0.35, 0, 0.35), o + Vector3(0.35, 0, 0.35), 0.05)

## The blue R/C monster truck on a white pedestal at the door (video 0:52).
static func truck(b, S, c, f, rng):
	var r = (-f).cross(UP)
	b.cur_color = Color("#f2f2ee")
	K.lbox(b, S, "vcolor", c, r, f, -0.4, 0.0, -0.3, 0.8, 0.55, 0.6, [], true)
	b.cur_color = Color("#2a4ab8")
	K.lbox(b, S, "vcolor", c, r, f, -0.4, 0.2, 0.301, 0.8, 0.12, 0.004, [], true)
	var top = c + UP * 0.55
	# wheels, chassis, body, cab
	b.cur_color = Color("#141416")
	for q in [Vector2(-0.17, -0.15), Vector2(0.17, -0.15), Vector2(-0.17, 0.15), Vector2(0.17, 0.15)]:
		K.lbox(b, S, "vcolor", top + r * q.y + f * q.x, r, f, -0.045, 0.0, -0.09, 0.09, 0.18, 0.18, [], true)
	b.cur_color = Color("#2238a8")
	K.lbox(b, S, "vcolor", top, r, f, -0.13, 0.12, -0.25, 0.26, 0.09, 0.5, [], true)
	K.lbox(b, S, "vcolor", top, r, f, -0.11, 0.21, -0.05, 0.22, 0.08, 0.2, [], true)
	b.cur_color = Color("#9ab4e8")
	K.lbox(b, S, "vcolor", top, r, f, -0.1, 0.22, 0.15, 0.2, 0.06, 0.004, [], true)
	b.cur_color = Color("#e8e8e4")
	K.lbox(b, S, "vcolor", top, r, f, -0.09, 0.3, -0.03, 0.18, 0.012, 0.03, [], true)
	b.cur_color = Color.WHITE
	K.ob(b, c - Vector3(0.45, 0, 0.45), c + Vector3(0.45, 0, 0.45), 0.05)

## A satellite dish display: a grey dish tilted up on a short pole, a card on the pole (0:52).
static func dish(b, S, c, f):
	f = f.normalized()
	b.cur_color = Color("#3a3a3e")
	b.cyl(S, "vcolor", c, 0.22, 0.22, 0.04, 14, true, false, true)
	b.cyl(S, "vcolor", c, 0.025, 0.025, 1.25, 8, false, false, true)
	b.cur_color = Color("#c4c6ca")
	var dc = c + UP * 1.4
	var nrm = (f + UP * 0.6).normalized()
	var u = nrm.cross(UP).normalized()
	var v = u.cross(nrm).normalized()
	var s = b.st(S, "vcolor", true)
	var seg = 16
	for i in seg:
		var a0 = TAU * i / seg
		var a1 = TAU * (i + 1) / seg
		var p0 = dc + (u * cos(a0) + v * sin(a0)) * 0.36 + nrm * 0.06
		var p1 = dc + (u * cos(a1) + v * sin(a1)) * 0.36 + nrm * 0.06
		b.tri(s, dc, p0, p1, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, nrm)
		b.tri(s, dc, p1, p0, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, -nrm)
	b.cur_color = Color("#2a2a2c")
	b.box(S, "vcolor", dc + nrm * 0.3, Vector3(0.05, 0.05, 0.05), Transform3D.IDENTITY, [], true)
	b.cur_color = Color.WHITE
	K.fq(b, S, "s6_rs_cards", c + f * 0.03 - u * 0.15, u, f, 0.0, 0.3, 0.75, 1.05, 0.0, 0.5, 0.0, 1.0, 1.0, true)
	K.ob(b, c - Vector3(0.3, 0, 0.3), c + Vector3(0.3, 0, 0.3), 0.05)

## A double-sided grey panel of wire and cable spools (video 4:24: a wall of black reels on grey
## board with white price tags), `ln` long along r from o, both faces (f and -f): five rows of
## black spools on pegs, a grey base, a header strip.
static func spools(b, G, o, r, f, ln, rng):
	var hgt = 1.9
	K.lbox(b, G, "s6_rs_shelf", o, r, f, 0.0, 0.0, -0.2, ln, 0.15, 0.4, ["-y"])
	b.cur_color = Color("#8e9094")
	K.lbox(b, G, "vcolor", o, r, f, 0.0, 0.15, -0.03, ln, hgt - 0.15, 0.06)
	for e in [0.0, ln - 0.04]:
		K.lbox(b, G, "s6_rs_shelf", o, r, f, e, 0.0, -0.2, 0.04, hgt + 0.05, 0.4, [])
	b.cur_color = Color.WHITE
	K.lbox(b, G, "s6_rs_black", o, r, f, 0.0, hgt, -0.05, ln, 0.12, 0.1, [])
	for sg in [1.0, -1.0]:
		var ff = f * sg
		var oo = o if sg > 0 else o + r * ln
		var rr = r * sg
		for row in 5:
			var y = 0.42 + row * 0.32
			var x = 0.16
			while x < ln - 0.1:
				var rad = rng.randf_range(0.07, 0.11)
				var c = K.L(oo, rr, ff, x, y, 0.03)
				disc(b, G, c, ff, rad, rng.randf_range(0.04, 0.07), Color("#141416") if rng.randf() < 0.75 else Color(["#b8202a", "#2a5ab8", "#d8a020"][rng.randi() % 3]))
				# the reel's hub and its white tag under it
				b.cur_color = Color("#3a3a3e")
				b.box(G, "vcolor", K.L(oo, rr, ff, x, y, 0.085), Vector3(0.03, 0.03, 0.03))
				b.cur_color = Color("#f2f2ee")
				K.lbox(b, G, "vcolor", oo, rr, ff, x - 0.03, y - rad - 0.05, 0.03, 0.06, 0.035, 0.004, [])
				x += 0.27
		b.cur_color = Color.WHITE
	K.ob_local(b, o, r, f, -0.05, -0.25, ln + 0.05, 0.25)
	b.cur_color = Color.WHITE

## A flat cylinder (a reel) at c, its axis along `ax`, radius `rad`, thickness `th`, colour `col`.
static func disc(b, G, c, ax, rad, th, col):
	b.cur_color = col
	var s = b.st(G, "vcolor")
	var u = ax.cross(Vector3.UP).normalized()
	var v = u.cross(ax).normalized()
	var seg = 14
	for i in seg:
		var a0 = TAU * i / seg
		var a1 = TAU * (i + 1) / seg
		var d0 = u * cos(a0) + v * sin(a0)
		var d1 = u * cos(a1) + v * sin(a1)
		var f0 = c + ax * th
		b.tri(s, f0, f0 + d0 * rad, f0 + d1 * rad, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, ax)
		b.tri(s, c + d0 * rad, c + d1 * rad, f0 + d1 * rad, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, (d0 + d1).normalized())
		b.tri(s, c + d0 * rad, f0 + d1 * rad, f0 + d0 * rad, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, (d0 + d1).normalized())
	b.cur_color = Color.WHITE

## Christmas stock at the counter's end (video 4:30-4:50): brown shipping cartons with red and white
## tape stacked on the floor, and the black podium the clerk opened the R/C box on.
static func cartons(b, G, o, r, f, rng):
	var boxes = [[0.0, 0.0, 0.0, 0.55, 0.45, 0.5], [0.6, 0.0, 0.05, 0.5, 0.4, 0.45], [0.05, 0.45, 0.02, 0.45, 0.35, 0.42], [0.65, 0.4, 0.08, 0.4, 0.3, 0.35]]
	for bx in boxes:
		var j = rng.randf_range(-0.03, 0.03)
		b.cur_color = Color("#a87c4c").lerp(Color("#8a6238"), rng.randf())
		K.lbox(b, G, "vcolor", o + f * j, r, f, bx[0], bx[1], bx[2], bx[3], bx[4], bx[5], ["-y"] if bx[1] == 0.0 else [])
		# the tape across the top and down the front: red and white
		b.cur_color = Color("#c8262c")
		K.lbox(b, G, "vcolor", o + f * j, r, f, bx[0] + bx[3] * 0.4, bx[1] + bx[4], bx[2], bx[3] * 0.2, 0.004, bx[5], [])
		b.cur_color = Color("#f2f0ea")
		K.lbox(b, G, "vcolor", o + f * j, r, f, bx[0] + bx[3] * 0.45, bx[1] + bx[4] * 0.3, bx[2] + bx[5], bx[3] * 0.1, bx[4] * 0.7, 0.004, [])
	# the black podium beside them
	b.cur_color = Color("#18181a")
	K.lbox(b, G, "vcolor", o, r, f, -0.2, 0.0, 0.75, 0.6, 0.95, 0.55, ["-y"])
	b.cur_color = Color.WHITE
	K.ob_local(b, o, r, f, -0.25, -0.05, 1.1, 1.35)

## Radio Shack's standalone items (workstream D; tools/stores/radioshack_items/, design/storefronts/
## radio-shack.md): each entry of data/items/radioshack.json is instanced from its scene at its
## place, as its own node under "Items" (named by its id), so workstream B+C can pick it up.
static func items(b):
	var J = JSON.parse_string(FileAccess.get_file_as_string("res://data/items/radioshack.json"))
	if J == null or b.mall == null:
		return
	var holder = b.mall.get_node_or_null("Items")
	if holder == null:
		holder = Node3D.new()
		holder.name = "Items"
		b.mall.add_child(holder)
		holder.owner = b.mall
	for it in J:
		if int(it.place.year) != 1995 or not ResourceLoader.exists(it.scene):
			continue
		var inst = load(it.scene).instantiate()
		inst.name = it.id
		inst.position = Vector3(it.place.pos[0], it.place.pos[1], it.place.pos[2])
		inst.rotation.y = deg_to_rad(float(it.place.yaw))
		holder.add_child(inst)
		inst.owner = b.mall
