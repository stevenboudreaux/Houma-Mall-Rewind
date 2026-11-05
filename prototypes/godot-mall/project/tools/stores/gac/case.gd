## Great American Cookies' glass case, the same in 1995 and 2026 (Steven, Oct 28: "really focus on
## this, get it perfect ... both years, only the sign style changes"). From Steven's 1990s photo of
## a Great American Cookie Co. (design/storefronts/refs/great-american-cookie-case.jpg) and the Oct
## 23 2026 footage of the Southland store (IMG_4439 f013 and its sharp crop
## refs/derived/signs/gac_IMG_4439_f013.jpg). design/storefronts/great-american-cookie.md.
##
## The case, as both pictures show it: a white base on a recessed kick; a sloped lower window,
## leaning back, with the big decorated cookie cakes standing in it on a maroon back; a deck
## with three stepped tiers of cookie trays under a quarter-round curved front glass that rises
## from the deck's front edge to a flat glass top; white end panels cut to the same profile; a
## lit strip under the top; price cards on the tier edges; sliding doors on the staff side. The
## run is in sections about 1.4 m long split by white frames.
##
## Also the 2026 store around it (build_2026, called by tools/stores/fronts26/store.gd): the red
## soffit with downlights, the LED colour box at the left corner, the white wave wall with "Share
## the Fun of Cookies" in blue script, the register pedestal and the ice-cream dipping cabinet
## (painted with invented generic cones, no brand), the red back counter with drink and slush
## machines under three menu screens.

const K = preload("res://tools/stores/media/kit.gd")
const UP = Vector3.UP
const DEPTH = 0.95        # customer face to the staff-side doors
const TOP_Y = 1.32
const DECK_Y = 0.66
const R_F = 0.53          # the curved glass: a quarter ellipse from (f 0.22, deck) to (f 0.75, top)
const R_Y = TOP_Y - DECK_Y
const F0 = 0.22
const SEC = 1.4

static func L(o, r, f, x, y, z):
	return o + r * x + UP * y + f * z

static func box(b, g, m, o, r, f, x, y, z, w, h, d, skip = [], dyn = false):
	K.lbox(b, g, m, o, r, f, x, y, z, w, h, d, skip, dyn)

## The profile of the curved glass at angle i/seg (0: the deck's front edge, 1: the top).
static func curve(i, seg):
	var th = PI * 0.5 * i / seg
	return Vector2(F0 + R_F - R_F * cos(th), DECK_Y + R_Y * sin(th))

## A run of case `w` long: o = the customer-side bottom corner at the run's start, r along the run,
## f into the store (the staff side). g: baked group; gs: small (dynamic) group.
static func case_run(b, g, gs, o, r, f, w):
	var nrm_front = -f
	# kick, base and the sloped lower window with the cookie cakes on a maroon back
	b.cur_color = Color("#2a2a2c")
	box(b, g, "vcolor", o, r, f, 0.0, 0.0, 0.08, w, 0.12, DEPTH - 0.1, ["-y"])
	b.cur_color = Color("#f4f2ee")
	box(b, g, "vcolor", o, r, f, 0.0, 0.12, 0.2, w, DECK_Y - 0.12, DEPTH - 0.2)
	box(b, g, "vcolor", o, r, f, 0.0, 0.12, 0.02, w, 0.06, 0.2)
	box(b, g, "vcolor", o, r, f, 0.0, DECK_Y - 0.05, 0.0, w, 0.05, 0.24)
	b.cur_color = Color.WHITE
	# the cookie cakes: a leaning textured plane (4 cakes per 1.4 m), the window glass in front
	var lo = 0.18
	var hi = DECK_Y - 0.06
	var cake_back0 = L(o, r, f, 0.0, lo, 0.1)
	var cake_back1 = L(o, r, f, 0.0, hi, 0.19)
	var n_cake = (f * 0.09 + UP * (hi - lo)).normalized().cross(r).normalized()
	if n_cake.dot(nrm_front) < 0.0:
		n_cake = -n_cake
	var reps = w / SEC
	b.quad(g, "gac_cakes", [cake_back0, cake_back0 + r * w, cake_back1 + r * w, cake_back1], n_cake,
		[Vector2(0, 1), Vector2(reps, 1), Vector2(reps, 0), Vector2(0, 0)])
	b.quad("glass", "glass", [L(o, r, f, 0.0, lo, 0.03), L(o, r, f, w, lo, 0.03), L(o, r, f, w, hi, 0.12), L(o, r, f, 0.0, hi, 0.12)], n_cake, [], true)
	var ll = b.add_omni(L(o, r, f, w * 0.5, hi - 0.05, 0.12), 0.08, 0.9, Color(1.0, 0.95, 0.85))
	b.tag(ll, "", 0.06, 0.08)
	# the deck and the three stepped tiers of trays (front to back), price cards on their edges
	var tiers = [[DECK_Y + 0.005, F0 + 0.04, 0.9], [DECK_Y + 0.21, 0.42, 0.9], [DECK_Y + 0.41, 0.58, 0.9]]
	for ti in tiers.size():
		var T = tiers[ti]
		var y = T[0]
		if ti > 0:
			b.cur_color = Color("#d8d8dc")
			box(b, gs, "vcolor", o, r, f, 0.03, y - 0.012, T[1], w - 0.06, 0.012, T[2] - T[1], [], true)
			b.cur_color = Color("#c0c0c4")
			for k in int(w / 0.7) + 1:
				box(b, gs, "vcolor", o, r, f, min(0.05 + k * 0.7, w - 0.07), DECK_Y, T[2] - 0.04, 0.012, y - DECK_Y, 0.012, [], true)
		b.cur_color = Color.WHITE
		var p0 = L(o, r, f, 0.05, y + 0.004, T[1])
		var dd = T[2] - T[1]
		var ux = (w - 0.1) / (SEC * 0.5)
		b.quad(gs, "gac_cookies", [p0, p0 + r * (w - 0.1), p0 + r * (w - 0.1) + f * dd, p0 + f * dd], UP,
			[Vector2(ti * 0.25, 0.0), Vector2(ti * 0.25 + ux * 0.25, 0.0), Vector2(ti * 0.25 + ux * 0.25, 0.5), Vector2(ti * 0.25, 0.5)], true)
		# a second tray row: the lower half of the sheet, offset so the kinds alternate
		b.cur_color = Color("#fbfbf8")
		var x = 0.12
		while x < w - 0.1:
			box(b, gs, "vcolor", o, r, f, x, y + 0.002, T[1] - 0.008, 0.07, 0.04, 0.004, [], true)
			x += 0.35
		b.cur_color = Color.WHITE
	# the curved front glass, the flat top, the lit strip under it
	var seg = 10
	for i in seg:
		var c0 = curve(i, seg)
		var c1 = curve(i + 1, seg)
		var q = [L(o, r, f, 0.0, c0.y, c0.x), L(o, r, f, w, c0.y, c0.x), L(o, r, f, w, c1.y, c1.x), L(o, r, f, 0.0, c1.y, c1.x)]
		var mid = (c0 + c1) * 0.5
		var nn = (-f * (cos(PI * 0.5 * (i + 0.5) / seg)) + UP * sin(PI * 0.5 * (i + 0.5) / seg)).normalized()
		b.quad("glass", "glass", q, nn, [], true)
	b.quad("glass", "glass", [L(o, r, f, 0.0, TOP_Y, F0 + R_F), L(o, r, f, w, TOP_Y, F0 + R_F), L(o, r, f, w, TOP_Y, DEPTH - 0.02), L(o, r, f, 0.0, TOP_Y, DEPTH - 0.02)], UP, [], true)
	b.cur_color = Color("#f4f2ee")
	box(b, g, "vcolor", o, r, f, 0.0, TOP_Y - 0.03, DEPTH - 0.2, w, 0.05, 0.2)
	b.cur_color = Color("#fff8ea")
	box(b, gs, "gac_led", o, r, f, 0.04, TOP_Y - 0.05, DEPTH - 0.18, w - 0.08, 0.015, 0.03, [], true)
	b.cur_color = Color.WHITE
	var l = b.add_omni(L(o, r, f, w * 0.5, TOP_Y - 0.12, 0.6), 0.22, 1.6, Color(1.0, 0.95, 0.86))
	b.tag(l, "", 0.18, 0.22)
	# the staff side: sliding doors (tinted glass in white frames)
	b.quad("glass", "glass", [L(o, r, f, 0.0, DECK_Y, DEPTH), L(o, r, f, w, DECK_Y, DEPTH), L(o, r, f, w, TOP_Y - 0.03, DEPTH), L(o, r, f, 0.0, TOP_Y - 0.03, DEPTH)], f, [], true)
	# the white end and section frames, cut to the profile
	var ns = max(1, int(round(w / SEC)))
	for k in ns + 1:
		var x = w * k / ns
		frame(b, g, o, r, f, clamp(x - 0.02, 0.0, w - 0.04), 0.04 if (k == 0 or k == ns) else 0.03)
	K.ob(b, L(o, r, f, 0, 0, 0), L(o, r, f, w, 0, DEPTH), 0.05)

## A profile frame at x (thickness th along r): the curve's outline as a strip from the deck to the
## top, and the back post.
static func frame(b, g, o, r, f, x, th):
	b.cur_color = Color("#f6f4f0")
	var seg = 10
	for i in seg:
		var c0 = curve(i, seg)
		var c1 = curve(i + 1, seg)
		var m = (c0 + c1) * 0.5
		var ln = (c1 - c0).length()
		var ang = atan2(c1.y - c0.y, c1.x - c0.x)
		# a short bar along the segment, 4 cm wide
		var ctr = L(o, r, f, x + th * 0.5, m.y, m.x)
		var along = (f * cos(ang) + UP * sin(ang)).normalized()
		var outv = along.cross(r).normalized()
		var bas = Basis(r, along, r.cross(along))
		b.box(g, "vcolor", Vector3.ZERO, Vector3(th, ln + 0.01, 0.04), Transform3D(bas, ctr - outv * 0.0))
	box(b, g, "vcolor", o, r, f, x, DECK_Y - 0.02, DEPTH - 0.22, th, TOP_Y - DECK_Y + 0.05, 0.22)
	box(b, g, "vcolor", o, r, f, x, 0.12, 0.0, th, DECK_Y - 0.12, DEPTH)
	b.cur_color = Color.WHITE

# ------------------------------------------------------------------ the 2026 store
static var a0: Vector3
static var tt: Vector3
static var nn: Vector3
static var LN = 6.0
static var FLIP = false

static func U(x):
	return LN - x if FLIP else x

static func P(x, y, d):
	return a0 + tt * U(x) - nn * d + UP * y

static func RX():
	return (P(1, 0, 0) - P(0, 0, 0))

static func cb(b, g, c, x0, y, d, w, h, dd, m = "vcolor", dyn = false):
	b.cur_color = Color(c)
	var u0 = min(U(x0), U(x0 + w))
	K.lbox(b, g, m, a0, tt, -nn, u0, y, d, w, h, dd, [], dyn)
	b.cur_color = Color.WHITE

## The 2026 store, x left to right as seen from the hall (fronts26's frame), 6 m deep.
static func build_2026(b, G, a, t, n, Ln, flip):
	a0 = a; tt = t; nn = n; LN = Ln; FLIP = flip
	var GS = G + "_gacs"
	var D = 6.0
	var CY = 3.0
	# floor, ceiling, walls
	b.cur_color = Color("#ece8e0")
	b.quad(G, "vcolor", [P(0, 0.003, 0), P(LN, 0.003, 0), P(LN, 0.003, D), P(0, 0.003, D)], UP)
	b.cur_color = Color.WHITE
	var cp = [P(0, CY, 0.8), P(LN, CY, 0.8), P(LN, CY, D), P(0, CY, D)]
	var cuv = []
	for p in cp:
		cuv.append(Vector2(p.x / 0.61, p.z / 1.22))
	b.quad(G, "kb_ceiling", cp, Vector3.DOWN, cuv)
	for tr in [[1.2, 2.0], [3.6, 2.0], [1.2, 4.2], [3.6, 4.2]]:
		b.quad(G, "gb_troffer", [P(tr[0], CY - 0.006, tr[1]), P(tr[0] + 1.22, CY - 0.006, tr[1]), P(tr[0] + 1.22, CY - 0.006, tr[1] + 0.61), P(tr[0], CY - 0.006, tr[1] + 0.61)], Vector3.DOWN,
			[Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)])
	# left: the white wave wall with the blue script; right: plain white; back: white over red
	var rx = RX()
	b.quad(G, "gac_wave", [P(0.02, 0, 0), P(0.02, 0, D), P(0.02, CY, D), P(0.02, CY, 0)], rx,
		[Vector2(0, CY / 1.2), Vector2(D / 1.2, CY / 1.2), Vector2(D / 1.2, 0), Vector2(0, 0)])
	b.label("Share the Fun of Cookies", "script", "#2a3a8a", P(0.05, 1.75, 2.6), rx, 2.8, 0.34)
	b.cur_color = Color("#f6f6f4")
	b.quad(G, "vcolor_matte", [P(LN - 0.02, 0, D), P(LN - 0.02, 0, 0), P(LN - 0.02, CY, 0), P(LN - 0.02, CY, D)], -rx)
	b.quad(G, "vcolor_matte", [P(LN, 1.0, D - 0.02), P(0, 1.0, D - 0.02), P(0, CY, D - 0.02), P(LN, CY, D - 0.02)], n)
	b.cur_color = Color("#c8202c")
	b.quad(G, "vcolor_matte", [P(LN, 0, D - 0.02), P(0, 0, D - 0.02), P(0, 1.0, D - 0.02), P(LN, 1.0, D - 0.02)], n)
	b.cur_color = Color.WHITE
	# the red soffit band over the open front, downlights in its underside; the LED box
	cb(b, G, "#c8202c", 0.0, 2.85, -0.16, LN, 0.35, 0.96)
	for x in [0.7, 1.9, 3.1, 4.3, 5.4]:
		b.cur_color = Color("#fff4dc")
		b.cyl(GS, "gac_led", P(x, 2.845, 0.35), 0.07, 0.07, 0.005, 12, false, true, true)
		var l = b.add_spot(P(x, 2.8, 0.35), Vector3.DOWN, 0.6, 3.5, 55.0, Color(1.0, 0.95, 0.85))
		b.tag(l, "", 0.5, 0.6)
	b.cur_color = Color.WHITE
	cb(b, G, "#ffffff", 0.0, 3.2, -0.3, 1.25, 0.42, 0.14, "gac_rgb", true)
	# the case along the front from the wave wall, the register pedestal, the dipping cabinet
	var cw = 2.8
	case_run(b, G, GS, P(0.15, 0, 0.35), rx, -n, cw)
	cb(b, G, "#f4f2ee", 0.15 + cw, 0.0, 0.35, 0.6, 1.0, 0.75)
	cb(b, G, "#e8e2d6", 0.12 + cw, 1.0, 0.33, 0.66, 0.04, 0.79)
	K.register(b, GS, P(0.45 + cw, 1.04, 0.75), -rx, n)
	var x1 = 0.15 + cw + 0.6
	var cwid = LN - 0.2 - x1
	cb(b, G, "#f8f6f2", x1, 0.0, 0.35, cwid, 0.95, 0.75)
	b.quad(G, "gac_dip", [P(x1, 0.08, 0.345), P(x1 + cwid, 0.08, 0.345), P(x1 + cwid, 0.92, 0.345), P(x1, 0.92, 0.345)], n,
		[Vector2(0, 1), Vector2(cwid / 1.2, 1), Vector2(cwid / 1.2, 0), Vector2(0, 0)])
	b.quad("glass", "glass", [P(x1, 0.95, 0.38), P(x1 + cwid, 0.95, 0.38), P(x1 + cwid, 1.18, 0.9), P(x1, 1.18, 0.9)], (n + UP).normalized(), [], true)
	for k in int(cwid / 0.45):
		b.cur_color = [Color("#f2e6c8"), Color("#e8a0b0"), Color("#5a3a28"), Color("#c8e0a0")][k % 4]
		b.box(GS, "vcolor", P(x1 + 0.25 + k * 0.45, 0.93, 0.7), Vector3(0.36, 0.04, 0.5), Transform3D.IDENTITY, [], true)
	b.cur_color = Color.WHITE
	K.ob(b, P(0.15, 0, 0.3), P(LN - 0.2, 0, 1.15), 0.05)
	# the back counter: red, the drink and slush machines, cups; three menu screens over it
	cb(b, G, "#c8202c", 0.4, 0.0, D - 0.7, LN - 0.8, 0.95, 0.68)
	cb(b, G, "#e8e6e0", 0.38, 0.95, D - 0.72, LN - 0.76, 0.04, 0.7)
	for k in 2:
		cb(b, G, "#b81c24", 1.0 + k * 0.62, 0.99, D - 0.6, 0.55, 0.55, 0.5)
		b.quad(GS, "gac_slush", [P(1.03 + k * 0.62, 1.25, D - 0.605), P(1.52 + k * 0.62, 1.25, D - 0.605), P(1.52 + k * 0.62, 1.52, D - 0.605), P(1.03 + k * 0.62, 1.52, D - 0.605)], n,
			[Vector2(k * 0.5, 1), Vector2(k * 0.5 + 0.5, 1), Vector2(k * 0.5 + 0.5, 0), Vector2(k * 0.5, 0)], true)
	cb(b, G, "#1a1a1c", 3.0, 0.99, D - 0.62, 1.1, 0.6, 0.55)
	for k in 6:
		b.cur_color = [Color("#202022"), Color("#c8202c"), Color("#1f3f8f"), Color("#f2c81e")][k % 4]
		b.box(GS, "vcolor", P(3.1 + k * 0.17, 1.15, D - 0.66), Vector3(0.06, 0.12, 0.05), Transform3D.IDENTITY, [], true)
	b.cur_color = Color("#f6f4ee")
	for k in 3:
		b.cyl(GS, "vcolor", P(4.5 + k * 0.14, 0.99, D - 0.4), 0.045, 0.05, 0.42, 10, true, false, true)
	b.cur_color = Color.WHITE
	for k in 3:
		var x = 0.5 + k * 1.75
		cb(b, G, "#141414", x - 0.03, 1.85, D - 0.06, 1.56, 0.9, 0.04)
		b.quad(GS, "gac_menu", [P(x, 1.88, D - 0.065), P(x + 1.5, 1.88, D - 0.065), P(x + 1.5, 2.72, D - 0.065), P(x, 2.72, D - 0.065)], n,
			[Vector2(k / 3.0, 1), Vector2((k + 1) / 3.0, 1), Vector2((k + 1) / 3.0, 0), Vector2(k / 3.0, 0)], true)
	# ws/interiors: the video's work area between the case and the back counter (gac/kitchen.gd)
	load("res://tools/stores/gac/kitchen.gd").build_2026(b, G, GS, a0, tt, nn, LN, FLIP)
	var lo = b.add_omni(P(LN * 0.5, 2.5, 3.5), 0.55, 6.0, Color(1.0, 0.97, 0.92))
	b.tag(lo, "", 0.45, 0.55)

# ------------------------------------------------------------------ materials
## "gac_<key>" (build_mall.gd's mat() calls this).
static func fill_mat(m, key, b):
	match key:
		"cookies":
			m.albedo_texture = b.tex("gac/cookies.png"); m.roughness = 0.7
		"cakes":
			m.albedo_texture = b.tex("gac/cookie_cakes.png"); m.roughness = 0.6
			K.emit_tex(m, 0.25)
		"wave":
			m.albedo_texture = b.tex("gac/wave.png"); m.roughness = 0.6
		"dip":
			m.albedo_texture = b.tex("gac/dip.png"); m.roughness = 0.5
		"slush":
			m.albedo_texture = b.tex("gac/slush.png")
			K.emit_tex(m, 0.8)
		"menu":
			m.albedo_texture = b.tex("gac/menu.png")
			K.emit_tex(m, 0.85)
		"rgb":
			m.albedo_texture = b.tex("gac/rgb.png")
			K.emit_tex(m, 1.2)
		"led":
			m.albedo_color = Color("#fff8ea")
			K.emit(m, Color("#fff4dc"), 2.0)
		_:
			# ws/interiors: the work-area kit's materials (tile, pictures, cake, fountain)
			return load("res://tools/stores/gac/kitchen.gd").fill_mat(m, key, b)
	return true
