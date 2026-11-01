## The media kit: fixtures shared by the game and music shops (Babbage's, Sound Shop),
## built to design/storefronts/babbages.md and sound-shop.md.
##
## White wall bays of face-out stock with radiused end caps and a lit header box over
## each bay, low gondolas, CD browser bins, a cash wrap with a register, a lay-in ceiling
## with troffers, round columns. Textures: tools/stores/media/paint.py -> tex/md/.
## Materials are "md_<key>" (build_mall.gd's mat() calls fill_mat).
##
## Everything works in a local frame: `o` a point on the floor, `r` along the fixture's
## width, `f` out toward the shopper, y up.

const UP = Vector3.UP
const SHEET_W = 1.22            # a stock sheet's width in metres
## stock sheet -> [rows, row height m] (paint.py ROWS)
const ROWS = {"games": [8, 0.305], "pc": [8, 0.305], "books": [8, 0.305], "acc": [8, 0.305], "cd": [16, 0.1525], "tape": [16, 0.1525],
	# Woolworth's sheets (tools/stores/woolworth/paint.py)
	"boxes": [8, 0.305], "hba": [8, 0.305], "linens": [8, 0.305], "candy": [8, 0.305], "gcards": [8, 0.305], "party": [8, 0.305],
	# the Wave 5 small shops' sheets (tools/stores/small/paint.py)
	"gifts": [8, 0.305], "candles": [8, 0.305],
	# Radio Shack's sheets (tools/stores/small/paint_rs.py)
	"rsphones": [8, 0.305], "rsboxes": [8, 0.305], "rsparts": [8, 0.305], "rsbatt": [8, 0.305],
	# Kay-Bee's toy sheets (kb_merch_<cat>.png: 7 rows of 146 px for 0.35 m, kay_bee/paint_store.py)
	"kb_dolls": [7, 0.35, 0.142578], "kb_action": [7, 0.35, 0.142578], "kb_vehicles": [7, 0.35, 0.142578], "kb_games": [7, 0.35, 0.142578],
	"kb_preschool": [7, 0.35, 0.142578], "kb_sports": [7, 0.35, 0.142578]}

static func L(o, r, f, x, y, z):
	return o + r * x + UP * y + f * z

static func fq(b, g, m, o, r, f, x0, x1, y0, y1, z, ua = 0.0, va = 0.0, ub = 1.0, vb = 1.0, dyn = false):
	if r.dot((-f).cross(UP)) < 0.0:
		var tmp = ua; ua = ub; ub = tmp
	b.quad(g, m, [L(o, r, f, x0, y0, z), L(o, r, f, x1, y0, z), L(o, r, f, x1, y1, z), L(o, r, f, x0, y1, z)], f,
		[Vector2(ua, vb), Vector2(ub, vb), Vector2(ub, va), Vector2(ua, va)], dyn)

static func lbox(b, g, m, o, r, f, x, y, z, w, h, dp, skip = [], dyn = false):
	var xf = Transform3D(Basis(r, UP, f), o)
	b.box(g, m, Vector3(x + w * 0.5, y + h * 0.5, z + dp * 0.5), Vector3(w, h, dp), xf, skip, dyn)

static func hq(b, g, m, o, r, f, x0, x1, z0, z1, y, up = true, dyn = false):
	b.quad(g, m, [L(o, r, f, x0, y, z0), L(o, r, f, x1, y, z0), L(o, r, f, x1, y, z1), L(o, r, f, x0, y, z1)], UP if up else Vector3.DOWN, [], dyn)

static func sq(b, g, m, o, r, f, x, z0, z1, y0, y1, sign, dyn = false):
	b.quad(g, m, [L(o, r, f, x, y0, z0), L(o, r, f, x, y0, z1), L(o, r, f, x, y1, z1), L(o, r, f, x, y1, z0)], r * sign, [], dyn)

static func ob(b, p0, p1, pad = 0.12):
	b.obst(["rect", min(p0.x, p1.x) - pad, min(p0.z, p1.z) - pad, max(p0.x, p1.x) + pad, max(p0.z, p1.z) + pad])

## A world-space floor rectangle as an obstacle, from local corners.
static func ob_local(b, o, r, f, x0, z0, x1, z1, pad = 0.12):
	ob(b, L(o, r, f, x0, 0, z0), L(o, r, f, x1, 0, z1), pad)

# ------------------------------------------------------------------ the room
## A lay-in ceiling (2 x 4 ft, kb/ceiling.png) over the rectangle (u0..u1, d0..d1) of the
## store frame P(u, y, d) = a + t u + n(-d), with troffers every `step` metres along d in
## rows at `rows_u`, and a baked spot under every other one.
static func ceiling(b, G, a, t, n, u0, u1, d0, d1, y, rows_u, step = 2.44, lit = true):
	var P = func(u, yy, d): return a + t * u - n * d + Vector3(0, yy, 0)
	var cp = []
	var cuv = []
	for q in [[u0, d0], [u0, d1], [u1, d1], [u1, d0]]:
		cp.append(P.call(q[0], y, q[1]))
		cuv.append(Vector2(q[0] / 0.61, q[1] / 1.22))
	b.quad(G, "md_ceiling", cp, Vector3.DOWN, cuv)
	var j = 0
	var dd = d0 + step * 0.5 - 0.61
	while dd + 1.22 <= d1 - 0.2:
		for uu in rows_u:
			var tq = [P.call(uu - 0.305, y - 0.006, dd), P.call(uu + 0.305, y - 0.006, dd), P.call(uu + 0.305, y - 0.006, dd + 1.22), P.call(uu - 0.305, y - 0.006, dd + 1.22)]
			b.quad(G, "md_troffer", tq, Vector3.DOWN, [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)])
			if lit and j % 2 == 0:
				var l = b.add_spot(P.call(uu, y - 0.08, dd + 0.61), Vector3.DOWN, 1.3, 6.0, 62.0, Color(1.0, 0.98, 0.93))
				b.tag(l, "", 1.3, 1.3)
		dd += step
		j += 1

## A flat floor rectangle in the store frame, tiled every `tile` metres.
static func floor_rect(b, G, m, a, t, n, u0, u1, d0, d1, tile = 1.0):
	var P = func(u, d): return a + t * u - n * d
	var pts = [P.call(u0, d0), P.call(u1, d0), P.call(u1, d1), P.call(u0, d1)]
	var uvs = [Vector2(u0 / tile, d0 / tile), Vector2(u1 / tile, d0 / tile), Vector2(u1 / tile, d1 / tile), Vector2(u0 / tile, d1 / tile)]
	b.quad(G, m, pts, UP, uvs)

## A wall in the store frame from (u0, d0) to (u1, d1), facing `nn`, floor to y.
static func wall(b, G, m, a, t, n, u0, d0, u1, d1, y0, y1, nn):
	var P = func(u, yy, d): return a + t * u - n * d + Vector3(0, yy, 0)
	b.quad(G, m, [P.call(u0, y0, d0), P.call(u1, y0, d1), P.call(u1, y1, d1), P.call(u0, y1, d0)], nn)

# ------------------------------------------------------------------ stock
## One row of face-out stock on a shelf (x0..x1 at height y, clear `space` above), from
## stock sheet `sheet`, set back a little from the shelf lip at `depth`.
static func stock_row(b, gm, o, r, f, x0, x1, y, space, depth, sheet, rng):
	var R = ROWS[sheet]
	var nrows = int(R[0])
	var rh = float(R[1])
	var rv = float(R[2]) if R.size() > 2 else 1.0 / nrows
	var mname = ("kb_merch_" + sheet.substr(3)) if sheet.begins_with("kb_") else ("md_stock_" + sheet)
	var x = x0
	while x < x1 - 0.05:
		var seg = min(x1 - x, rng.randf_range(0.5, 1.1))
		var hgt = min(space, rh)
		var row = rng.randi_range(0, nrows - 1)
		var vb = float(row + 1) * rv
		var va = vb - hgt / rh * rv
		var ua = rng.randf() * (1.0 - seg / SHEET_W)
		var z = depth - rng.randf_range(0.02, 0.06)
		fq(b, gm, mname, o, r, f, x + 0.006, x + seg - 0.006, y, y + hgt, z, ua, va, ua + seg / SHEET_W, vb)
		x += seg

## A white wall bay: back panel, kick base, shelf boards with stock, uprights.
## `boards`: the shelf heights; `sheets`: the stock sheet for each level (cycled).
static func bay(b, G, gm, o, r, f, w, boards, sheets, rng, depth = 0.36, back_mat = "md_white", frame_mat = "md_white"):
	var top = boards[boards.size() - 1]
	b.quad(G, back_mat, [L(o, r, f, 0, 0.12, 0.01), L(o, r, f, w, 0.12, 0.01), L(o, r, f, w, top + 0.3, 0.01), L(o, r, f, 0, top + 0.3, 0.01)], f,
		[Vector2(0, 0), Vector2(w / 0.6, 0), Vector2(w / 0.6, (top + 0.18) / 0.6), Vector2(0, (top + 0.18) / 0.6)])
	lbox(b, G, frame_mat, o, r, f, 0.0, 0.0, 0.0, w, 0.12, depth + 0.03, ["-y", "-z"])
	for x in [0.0, w - 0.025]:
		lbox(b, G, frame_mat, o, r, f, x, 0.12, 0.01, 0.025, top + 0.18 - 0.12, depth, ["-y", "-z"])
	var levels = [0.12]
	for yb in boards:
		lbox(b, G, frame_mat, o, r, f, 0.025, yb - 0.022, 0.01, w - 0.05, 0.022, depth - 0.01, ["-z"])
		levels.append(yb)
	for i in levels.size() - 1:
		var y = levels[i]
		stock_row(b, gm, o, r, f, 0.03, w - 0.03, y, levels[i + 1] - 0.022 - y - 0.015, depth, sheets[i % sheets.size()], rng)
	# the top board carries a row standing in the open
	stock_row(b, gm, o, r, f, 0.03, w - 0.03, top, 0.3, depth, sheets[(levels.size() - 1) % sheets.size()], rng)

## A run of wall bays along local r from o, each `w` wide, with a header box over each.
## `heads`: header row index per bay (-1 for none), `hmat` the header sheet material.
static func bay_run(b, G, gm, o, r, f, w, count, boards, sheets_per_bay, heads, hmat, hy, rng, depth = 0.36):
	for k in count:
		var ok = o + r * (w * k)
		bay(b, G, gm, ok, r, f, w, boards, sheets_per_bay[k % sheets_per_bay.size()], rng, depth)
		var hi = heads[k % heads.size()]
		if hi >= 0:
			header(b, G, ok, r, f, w, hy, hmat, hi)
	ob_local(b, o, r, f, 0.0, 0.0, w * count, depth + 0.05)

## A lit header box over a bay: a white box 0.30 m tall standing 0.40 m out from the wall,
## the category on its face (sheet row `idx` of 12), a light strip under it washing the bay.
static func header(b, G, o, r, f, w, y0, hmat, idx):
	var hgt = 0.30
	var dp = 0.40
	lbox(b, G, "md_white", o, r, f, 0.0, y0, 0.0, w, hgt, dp, ["-z", "+z"])
	fq(b, G, hmat, o, r, f, 0.0, w, y0, y0 + hgt, dp, 0.0, idx / 12.0, 1.0, (idx + 1) / 12.0)
	# the strip light under the box's lip
	b.quad(G, "md_glowstrip", [L(o, r, f, 0.04, y0 - 0.002, dp - 0.12), L(o, r, f, w - 0.04, y0 - 0.002, dp - 0.12), L(o, r, f, w - 0.04, y0 - 0.002, dp - 0.04), L(o, r, f, 0.04, y0 - 0.002, dp - 0.04)], Vector3.DOWN)

## A radiused end cap: a white quarter- or half-round shell of radius `rad`, centred on c,
## sweeping from angle a0 to a1 (radians, 0 = +x in the (r, f) plane), y0..y1.
static func end_cap(b, G, m, c, r, f, rad, a0, a1, y0, y1, seg = 8):
	for i in seg:
		var t0 = a0 + (a1 - a0) * i / seg
		var t1 = a0 + (a1 - a0) * (i + 1) / seg
		var d0 = r * cos(t0) + f * sin(t0)
		var d1 = r * cos(t1) + f * sin(t1)
		var nn = (d0 + d1).normalized()
		b.quad(G, m, [c + d0 * rad + UP * y0, c + d1 * rad + UP * y0, c + d1 * rad + UP * y1, c + d0 * rad + UP * y1], nn)
		b.tri(b.st(G, m), c + UP * y1, c + d0 * rad + UP * y1, c + d1 * rad + UP * y1, Vector2(0, 0), Vector2(0, 0), Vector2(0, 0), UP)

## A round column cover from the floor to y.
static func column(b, G, m, c, rad, y, seg = 16):
	b.cyl(G, m, c, rad, rad, y, seg, false, false)

## A low double-sided gondola (books, accessories) of `bays` bays along r, centred on its
## spine line through o, both faces stocked, an end panel at each end.
static func gondola(b, G, gm, o, r, f, w, bays, boards, sheets, rng, depth = 0.32):
	for k in bays:
		var ok = o + r * (w * k)
		bay(b, G, gm, ok, r, f, w, boards, sheets, rng, depth)
		bay(b, G, gm, ok + r * w, -r, -f, w, boards, sheets, rng, depth)
	var top = boards[boards.size() - 1] + 0.32
	for e in [0.0, w * bays]:
		lbox(b, G, "md_white", o + r * e - r * 0.02, r, f, 0.0, 0.0, -depth - 0.03, 0.04, top, (depth + 0.03) * 2.0, [])
	ob_local(b, o, r, f, -0.02, -depth - 0.03, w * bays + 0.02, depth + 0.03)

## A CD browser bin: a white waist-high cabinet with a sloped tray of CDs filed upright
## (bin_tops.png), divider cards, a cassette shelf in the kick. `w` along r, both sides.
static func browser(b, G, o, r, f, w, rng, two_sided = true):
	var dp = 0.55 if two_sided else 0.32
	var h = 0.82
	lbox(b, G, "md_white", o, r, f, 0.0, 0.0, -dp, w, h, dp * 2.0 if two_sided else dp, ["-y"] if two_sided else ["-y", "-z"])
	var sides = [1.0, -1.0] if two_sided else [1.0]
	for s in sides:
		var ff = f * s
		var oo = o if s > 0 else o + r * w
		var rr = r * s
		# the tilted tray of CD tops, rising away from the shopper
		var p0 = L(oo, rr, ff, 0.03, h + 0.02, 0.42 if two_sided else 0.28)
		var p1 = L(oo, rr, ff, w - 0.03, h + 0.02, 0.42 if two_sided else 0.28)
		var p2 = L(oo, rr, ff, w - 0.03, h + 0.16, 0.04)
		var p3 = L(oo, rr, ff, 0.03, h + 0.16, 0.04)
		var nn = (p1 - p0).cross(p3 - p0).normalized()
		if nn.y < 0:
			nn = -nn
		var u0 = rng.randf() * 0.4
		b.quad(G, "md_bin_tops", [p0, p1, p2, p3], nn, [Vector2(u0, 1), Vector2(u0 + w / 1.0 * 0.5, 1), Vector2(u0 + w / 1.0 * 0.5, 0), Vector2(u0, 0)])
		# the bin's front lip
		lbox(b, G, "md_white", oo, rr, ff, 0.0, h, (0.42 if two_sided else 0.28), w, 0.07, 0.03, ["-y"])
		# cassettes in the kick shelf
		stock_row(b, G, oo, rr, ff, 0.05, w - 0.05, 0.12, 0.14, (0.5 if two_sided else 0.3), "tape", rng)
	ob_local(b, o, r, f, 0.0, -dp, w, dp if two_sided else 0.32)

## A cash wrap counter, its front toward f, with a register on top toward the staff side.
static func counter(b, G, S, o, r, f, w, front_mat, rng, h = 0.95, dp = 0.62):
	lbox(b, G, "md_laminate", o, r, f, 0.0, 0.0, 0.0, w, h, dp, ["-y"])
	fq(b, G, front_mat, o, r, f, 0.0, w, 0.0, h, dp + 0.002)
	lbox(b, G, "md_black", o, r, f, -0.02, h, -0.02, w + 0.04, 0.035, dp + 0.05, ["-y"])
	register(b, S, L(o, r, f, w * 0.25, h + 0.035, 0.12), r, f)
	ob_local(b, o, r, f, 0.0, 0.0, w, dp)

## A beige register: base, pole display, keyboard; the screen faces the staff (-f).
static func register(b, S, o, r, f):
	b.cur_color = Color("#d9d2bf")
	lbox(b, S, "vcolor", o, r, f, 0.0, 0.0, 0.0, 0.42, 0.11, 0.4, ["-y"])
	lbox(b, S, "vcolor", o, r, f, 0.08, 0.11, 0.06, 0.26, 0.24, 0.26, ["-y"])
	b.cur_color = Color("#bdb6a4")
	lbox(b, S, "vcolor", o, r, f, 0.48, 0.0, 0.1, 0.42, 0.03, 0.2, ["-y"])
	b.cur_color = Color("#3a3a3c")
	lbox(b, S, "vcolor", o, r, f, 0.0, 0.0, 0.42, 0.12, 0.3, 0.06, ["-y"])
	b.cur_color = Color.WHITE
	fq(b, S, "md_screens", o + f * 0.06 + r * 0.34, -r, -f, 0.0, 0.26, 0.15, 0.32, 0.0, 0.5, 0.0, 1.0, 1.0)

## A hanging card (two-sided) on wires: `cell` in a 2 x 2 card sheet.
static func hang_card(b, G, m, c, r, f, w, h, y0, cell, ceil_y):
	for s in [1.0, -1.0]:
		fq(b, G, m, c + f * 0.006 * s - r * w * 0.5 * s, r * s, f * s, 0.0, w, y0, y0 + h, 0.0, (cell % 2) * 0.5, (cell / 2) * 0.5, (cell % 2) * 0.5 + 0.5, (cell / 2) * 0.5 + 0.5)
	b.cur_color = Color("#c8c8c8")
	for s in [-0.4, 0.4]:
		b.box(G, "vcolor", c + r * w * s + Vector3(0, (y0 + h + ceil_y) * 0.5, 0), Vector3(0.005, ceil_y - y0 - h, 0.005), Transform3D.IDENTITY, [], true)
	b.cur_color = Color.WHITE

## A chrome sign stand with a poster (two-sided) at the door: `cell` in a 2 x 2 sheet.
static func sign_stand(b, G, m, c, r, f, cell):
	b.cyl(G, "md_chrome", c, 0.2, 0.2, 0.02, 16, true, false)
	b.cyl(G, "md_chrome", c, 0.015, 0.015, 1.2, 8, false, false)
	var w = 0.56
	var h = 0.72
	lbox(b, G, "md_chrome", c - r * (w * 0.5 + 0.015), r, f, 0.0, 1.0, -0.012, w + 0.03, h + 0.03, 0.024)
	for s in [1.0, -1.0]:
		fq(b, G, m, c + f * 0.0135 * s - r * w * 0.5 * s, r * s, f * s, 0.0, w, 1.015, 1.015 + h, 0.0, (cell % 2) * 0.5, (cell / 2) * 0.5, (cell % 2) * 0.5 + 0.5, (cell / 2) * 0.5 + 0.5)
	ob(b, c - Vector3(0.25, 0, 0.25), c + Vector3(0.25, 0, 0.25), 0.05)

## Raised channel letters from a letters.json (make_letters.py), standing `d_back` metres in
## front of the plane through `o` (facing f), text centred on local x = cx, baseline at y.
static func letters(b, G, face_m, side_m, path, o, r, f, cx, y, d_back, depth, scale = 1.0):
	var J = JSON.parse_string(FileAccess.get_file_as_string(path))
	var x0 = cx - float(J.width) * scale * 0.5
	var d_face = d_back + depth
	var X = func(p, d): return L(o, r, f, x0 + float(p[0]) * scale, y + float(p[1]) * scale, d)
	for Lt in J.letters:
		var tr = Lt.tris
		var s = b.st(G, face_m, true)
		for i in range(0, tr.size(), 3):
			b.tri(s, X.call(tr[i], d_face), X.call(tr[i + 1], d_face), X.call(tr[i + 2], d_face), Vector2(0, 0), Vector2(0, 0), Vector2(0, 0), f)
		for lp in Lt.loops:
			for i in lp.size():
				var q0 = lp[i]
				var q1 = lp[(i + 1) % lp.size()]
				var dx = float(q1[0]) - float(q0[0])
				var dy = float(q1[1]) - float(q0[1])
				var ln = sqrt(dx * dx + dy * dy)
				if ln < 1e-5:
					continue
				var nn = (r * (dy / ln) - UP * (dx / ln)).normalized()
				b.quad(G, side_m, [X.call(q0, d_back), X.call(q1, d_back), X.call(q1, d_face), X.call(q0, d_face)], nn,
					[Vector2(0, 0), Vector2(0, 0), Vector2(0, 0), Vector2(0, 0)], true)

# ------------------------------------------------------------------ materials
static func emit(m, col, e):
	m.emission_enabled = true; m.emission = col; m.emission_energy_multiplier = e
	m.set_meta("e_day", e); m.set_meta("e_night", e)

static func emit_tex(m, e):
	m.emission_enabled = true; m.emission_texture = m.albedo_texture
	m.emission = Color.WHITE; m.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY
	m.emission_energy_multiplier = e
	m.set_meta("e_day", e); m.set_meta("e_night", e)

## "md_<key>" (build_mall.gd's mat() calls this).
static func fill_mat(m, key, b):
	if key.begins_with("stock_"):
		m.albedo_texture = b.tex("md/" + key + ".png"); m.roughness = 0.45; m.metallic_specular = 0.4
		return true
	match key:
		"carpet_grey":
			m.albedo_texture = b.tex("md/carpet_grey.png"); m.roughness = 0.95; m.metallic_specular = 0.1
		"vinyl":
			m.albedo_texture = b.tex("md/vinyl.png"); m.roughness = 0.3; m.metallic_specular = 0.5
		"ceiling":
			m.albedo_texture = b.tex("kb/ceiling.png"); m.roughness = 0.95
		"troffer":
			m.albedo_texture = b.tex("kb/troffer.png")
			emit_tex(m, 1.5)
		"wall":
			m.albedo_color = Color("#ecebe6"); m.roughness = 0.9
		"white":
			m.albedo_color = Color("#f0efea"); m.roughness = 0.4; m.metallic_specular = 0.4
		"laminate":
			m.albedo_color = Color("#ecebe6"); m.roughness = 0.3; m.metallic_specular = 0.5
		"slatwall":
			m.albedo_texture = b.tex("md/slatwall.png"); m.roughness = 0.5
		"black":
			m.albedo_color = Color("#1e1e20"); m.roughness = 0.4
		"chrome":
			m.albedo_color = Color("#d8dadf"); m.metallic = 0.8; m.roughness = 0.2
			# probe-lit metal goes dark at night: a faint glow of its own (Demo 9b)
			emit(m, Color("#9a9ca0"), 0.25)
		"maroon":
			m.albedo_color = Color("#6e1a22"); m.roughness = 0.35; m.metallic_specular = 0.5
		"glowstrip":
			m.albedo_color = Color.WHITE
			emit(m, Color("#fff6e6"), 2.0)
		"bb_headers", "ss_headers":
			m.albedo_texture = b.tex("md/" + key + ".png"); m.roughness = 0.5
			emit_tex(m, 0.45)
		"bb_counter", "ss_counter":
			m.albedo_texture = b.tex("md/" + key + ".png"); m.roughness = 0.35; m.metallic_specular = 0.45
		"release", "tickets":
			m.albedo_texture = b.tex("md/" + key + ".png"); m.roughness = 0.6
			emit_tex(m, 0.3 if key == "release" else 0.5)
		"bb_cards", "ss_cards", "ss_posters":
			m.albedo_texture = b.tex("md/" + key + ".png"); m.roughness = 0.6
			emit_tex(m, 0.2)
		"bin_tops":
			m.albedo_texture = b.tex("md/bin_tops.png"); m.roughness = 0.4; m.metallic_specular = 0.4
		"screens":
			m.albedo_texture = b.tex("md/screens.png")
			emit_tex(m, 1.5)
		"fascia_white":
			m.albedo_color = Color("#eceae4"); m.roughness = 0.5; m.metallic_specular = 0.4
		"fascia_grey":
			m.albedo_color = Color("#4a4a4e"); m.roughness = 0.5; m.metallic_specular = 0.35
		"downlight":
			m.albedo_color = Color.WHITE
			emit(m, Color("#fff3df"), 4.0)
		"neon_pink":
			# Babbage's: fat rounded pink-red neon letters (video 19:50-20:26)
			m.albedo_color = Color("#ff3a5c"); m.roughness = 0.35
			emit(m, Color("#ff3050"), 1.6)
		"neon_pink_side":
			m.albedo_color = Color("#b8204c"); m.roughness = 0.4
			emit(m, Color("#c02050"), 0.5)
		"neon_red":
			# Sound Shop: rose-red italic letters on the dark fascia (Hammond 1993)
			m.albedo_color = Color("#ff5a74"); m.roughness = 0.35
			emit(m, Color("#ff4a66"), 1.6)
		# Sound Shop's rebuilt front (Nov 1, 2026): the photo refs/era_1995/stores/Sound_Shop.jpg
		# (yellow-orange lit letters with a red rim) on Southland's surviving black curved
		# stucco fascia, black round pillars and black tile threshold (IMG_4484 f050-f055)
		"ss_letter":
			m.albedo_color = Color("#ffa82a"); m.roughness = 0.35
			emit(m, Color("#ff9418"), 2.0)
		"ss_letter_side":
			m.albedo_color = Color("#e0401c"); m.roughness = 0.4
			emit(m, Color("#e83a14"), 1.1)
		"ss_stucco":
			m.albedo_texture = b.tex("md/ss_stucco.png"); m.roughness = 0.95
		"ss_soffit":
			m.albedo_color = Color("#f2f0ea"); m.roughness = 0.85
		"ss_gloss_black":
			m.albedo_color = Color("#0c0c0e"); m.roughness = 0.08; m.metallic_specular = 0.9
		"ss_tile_black":
			m.albedo_texture = b.tex("md/ss_tile_black.png"); m.roughness = 0.25; m.metallic_specular = 0.6
		"ss_alu":
			m.albedo_color = Color("#b9bcc0"); m.metallic = 0.7; m.roughness = 0.35
			emit(m, Color("#8a8c90"), 0.15)
		"ss_wall_dark":
			m.albedo_color = Color("#3a3a3c"); m.roughness = 0.8
		"neon_red_side":
			m.albedo_color = Color("#8a1a1a"); m.roughness = 0.4
			emit(m, Color("#a02020"), 0.4)
		_:
			return false
	return true
