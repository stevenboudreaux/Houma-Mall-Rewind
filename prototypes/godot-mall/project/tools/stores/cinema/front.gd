## Southland Cinema 4's front on the Sears hall (store n.., 24 m, facing north), after Steven's
## photos (Oct 7, 2026): a white-painted brick wall with tall round-headed arches glazed in
## bronze; the box office under the first arch (a dark wood counter, the ticket window, price
## cards and a help-wanted card), glass doors under the others; black-and-brass carriage lanterns
## on the piers; silver poster cases with a lit yellow back; the "Welcome to Southland Cinema 4"
## case (without the United Artists badge). The films are invented (paint_cinema.py). Behind the
## glass a dim lobby; the inside comes later. Not walkable.
##
## Frame: v runs along the front from the viewer's left (American Bank's side) to the right;
## P(v, y, d): d into the building.

const UP = Vector3.UP
const SPRING = 2.95      # where the arches spring
const AW = 2.7           # arch width
const TRANSOM = 2.55     # the bronze transom bar
const LOBBY = 9.0        # how deep the lobby runs behind the glass

static func build(b, g, e, a, bb, n, t, Ln, sd):
	var F = "cinf_props"
	var G = "cin_lobby"
	# viewer's left is b (the edge runs right to left as seen from the hall)
	var o = bb
	var r = -t
	var Pf = func(v, y, d): return o + r * v - n * d + UP * y
	var LH = b.LANE_H
	# the bays, left to right: arch (box office), lantern, case, lantern, arch (doors), lantern,
	# the welcome case, lantern, arch (doors), lantern, case, lantern
	var arches = [[2.4, "box"], [10.0, "doors"], [17.6, "doors"]]
	var cases = [[6.2, "poster", 0], [13.8, "welcome", 0], [21.4, "poster", 2]]
	var lanterns = [4.4, 8.0, 12.0, 15.6, 19.6, 23.1]
	# the brick wall, with the arches cut out of it (piers to the springing, spandrels above)
	var edges = [0.0]
	for ac in arches:
		edges.append(ac[0] - AW * 0.5)
		edges.append(ac[0] + AW * 0.5)
	edges.append(Ln)
	for k in range(0, edges.size(), 2):
		var v0 = edges[k]
		var v1 = edges[k + 1]
		if v1 - v0 > 0.01:
			b.quad(F, "cin_brick", [Pf.call(v0, 0, 0), Pf.call(v1, 0, 0), Pf.call(v1, SPRING, 0), Pf.call(v0, SPRING, 0)], n,
				[Vector2(v0, SPRING), Vector2(v1, SPRING), Vector2(v1, 0), Vector2(v0, 0)])
	# above the springing: the wall in strips between arches, and a spandrel over each arch
	var rad = AW * 0.5
	var prev = 0.0
	for ac in arches:
		var c = ac[0]
		_wall_strip(b, F, Pf, n, prev, c - rad, SPRING, LH)
		_spandrel(b, F, Pf, n, c, rad, LH)
		prev = c + rad
	_wall_strip(b, F, Pf, n, prev, Ln, SPRING, LH)
	# a stone base course and a cornice band along the whole front
	b.box(F, "cin_base", Pf.call(Ln * 0.5, 0.12, -0.03), b.abs_size(r, Ln, 0.24, 0.06, n), Transform3D.IDENTITY, ["-y"])
	for ac in arches:
		_arch(b, F, G, Pf, r, n, ac[0], ac[1])
	for cs in cases:
		_case(b, F, Pf, r, n, cs[0], cs[1], cs[2])
	for lv in lanterns:
		_lantern(b, F, Pf, r, n, lv)
	_lobby(b, G, Pf, r, n, Ln)

static func _wall_strip(b, F, Pf, n, v0, v1, y0, y1):
	if v1 - v0 < 0.01:
		return
	b.quad(F, "cin_brick", [Pf.call(v0, y0, 0), Pf.call(v1, y0, 0), Pf.call(v1, y1, 0), Pf.call(v0, y1, 0)], n,
		[Vector2(v0, y1), Vector2(v1, y1), Vector2(v1, y0), Vector2(v0, y0)])

## The wall over one arch: from the semicircle up to the lane ceiling, as a fan of quads.
static func _spandrel(b, F, Pf, n, c, rad, LH):
	var seg = 16
	for i in seg:
		var a0 = PI * i / seg
		var a1 = PI * (i + 1) / seg
		var x0 = c + cos(PI - a0) * rad
		var x1 = c + cos(PI - a1) * rad
		var y0 = SPRING + sin(a0) * rad
		var y1 = SPRING + sin(a1) * rad
		b.quad(F, "cin_brick", [Pf.call(x0, y0, 0), Pf.call(x1, y1, 0), Pf.call(x1, LH, 0), Pf.call(x0, LH, 0)], n,
			[Vector2(x0, LH), Vector2(x1, LH), Vector2(x1, y1), Vector2(x0, y0)])

## One arch: the reveal, the bronze frame (jambs, the transom bar, the half-round head glazed
## with radiating bars), and below the transom either the box office or a pair of glass doors.
static func _arch(b, F, G, Pf, r, n, c, kind):
	var rad = AW * 0.5
	var dep = 0.32
	var seg = 18
	# the reveal: jambs and the curved soffit, painted brick
	for s in [-1.0, 1.0]:
		var v = c + s * rad
		b.quad(F, "cin_reveal", [Pf.call(v, 0, 0), Pf.call(v, 0, dep), Pf.call(v, SPRING, dep), Pf.call(v, SPRING, 0)], r * (-s))
	for i in seg:
		var a0 = PI * i / seg
		var a1 = PI * (i + 1) / seg
		var p0 = Vector2(c + cos(PI - a0) * rad, SPRING + sin(a0) * rad)
		var p1 = Vector2(c + cos(PI - a1) * rad, SPRING + sin(a1) * rad)
		var nn = -(r * ((p0.x + p1.x) * 0.5 - c) + UP * ((p0.y + p1.y) * 0.5 - SPRING)).normalized()
		b.quad(F, "cin_reveal", [Pf.call(p0.x, p0.y, 0), Pf.call(p1.x, p1.y, 0), Pf.call(p1.x, p1.y, dep), Pf.call(p0.x, p0.y, dep)], nn)
	# a brick soldier course round the head
	for i in seg:
		var a0 = PI * i / seg
		var a1 = PI * (i + 1) / seg
		var q = []
		for pr in [[a0, rad], [a1, rad], [a1, rad + 0.16], [a0, rad + 0.16]]:
			q.append(Pf.call(c + cos(PI - pr[0]) * pr[1], SPRING + sin(pr[0]) * pr[1], -0.015))
		b.quad(F, "cin_trim", q, n)
	# the bronze frame and the glass, set at the back of the reveal
	var gd = dep - 0.04
	var fw = 0.07
	for s in [-1.0, 1.0]:
		b.box(F, "cin_bronze", Pf.call(c + s * (rad - fw * 0.5), SPRING * 0.5, gd), b.abs_size(r, fw, SPRING, 0.08, n), Transform3D.IDENTITY, ["-y"])
	b.box(F, "cin_bronze", Pf.call(c, TRANSOM, gd), b.abs_size(r, AW, 0.1, 0.09, n))
	b.box(F, "cin_bronze", Pf.call(c, SPRING, gd), b.abs_size(r, AW, 0.05, 0.07, n))
	# the head: a half-round of glass with bronze bars radiating from the middle of the springing
	var hs = b.st("glass", "glass", true)
	for i in seg:
		var a0 = PI * i / seg
		var a1 = PI * (i + 1) / seg
		var ce = Pf.call(c, SPRING, gd)
		var p0 = Pf.call(c + cos(PI - a0) * (rad - 0.04), SPRING + sin(a0) * (rad - 0.04), gd)
		var p1 = Pf.call(c + cos(PI - a1) * (rad - 0.04), SPRING + sin(a1) * (rad - 0.04), gd)
		b.tri(hs, ce, p0, p1, Vector2(0.5, 1), Vector2(0, 0), Vector2(1, 0), n)
	for k in 5:
		var ang = PI * (k + 1) / 6.0
		var tip = Vector2(c + cos(PI - ang) * (rad - 0.04), SPRING + sin(ang) * (rad - 0.04))
		var ce2 = Vector2(c, SPRING)
		var mid = (tip + ce2) * 0.5
		var ln = tip.distance_to(ce2)
		var dv = (r * (tip.x - ce2.x) + UP * (tip.y - ce2.y)).normalized()
		var xa = dv.cross(n).normalized()
		b.box(F, "cin_bronze", Vector3.ZERO, Vector3(0.035, ln, 0.04), Transform3D(Basis(xa, dv, n), Pf.call(mid.x, mid.y, gd)), [], true)
	for i in seg:
		var a0 = PI * i / seg
		var a1 = PI * (i + 1) / seg
		var p0 = Vector2(c + cos(PI - a0) * (rad - 0.035), SPRING + sin(a0) * (rad - 0.035))
		var p1 = Vector2(c + cos(PI - a1) * (rad - 0.035), SPRING + sin(a1) * (rad - 0.035))
		var dv = (r * (p1.x - p0.x) + UP * (p1.y - p0.y))
		var xa = dv.normalized().cross(n).normalized()
		b.box(F, "cin_bronze", Vector3.ZERO, Vector3(0.07, dv.length() + 0.01, 0.08), Transform3D(Basis(xa, dv.normalized(), n), Pf.call((p0.x + p1.x) * 0.5, (p0.y + p1.y) * 0.5, gd)), [], true)
	# between the transom and the springing: glass, and (over the doors) the film's title
	b.quad("glass", "glass", [Pf.call(c - rad + fw, TRANSOM + 0.05, gd), Pf.call(c + rad - fw, TRANSOM + 0.05, gd), Pf.call(c + rad - fw, SPRING, gd), Pf.call(c - rad + fw, SPRING, gd)], n,
		[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)], true)
	if kind == "box":
		_box_office(b, F, G, Pf, r, n, c, rad, gd, fw)
	else:
		# two pairs of glass doors in bronze stiles, a centre mullion
		var w = AW - 2 * fw
		for k in 5:
			var v = c - rad + fw + w * k / 4.0
			b.box(F, "cin_bronze", Pf.call(v, TRANSOM * 0.5, gd), b.abs_size(r, 0.06, TRANSOM, 0.06, n), Transform3D.IDENTITY, ["-y"])
		for k in 4:
			var v0 = c - rad + fw + w * k / 4.0
			var v1 = c - rad + fw + w * (k + 1) / 4.0
			b.quad("glass", "glass", [Pf.call(v0, 0.0, gd), Pf.call(v1, 0.0, gd), Pf.call(v1, TRANSOM, gd), Pf.call(v0, TRANSOM, gd)], n,
				[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)], true)
			b.box(F, "cin_bronze", Pf.call((v0 + v1) * 0.5, 1.0, gd - 0.03), b.abs_size(r, 0.36, 0.03, 0.03, n))   # push bars
			b.box(F, "cin_bronze", Pf.call((v0 + v1) * 0.5, 0.12, gd), b.abs_size(r, v1 - v0, 0.24, 0.07, n), Transform3D.IDENTITY, ["-y"])
		# workstream S (Nov 2 2026): the closed roll gate behind the doors, the default look (the
		# cinema is locked: scripts/cinema_gate.gd rolls it up once cinema_unlocked is set). Its own
		# dynamic mesh (dyn_cin_gate) so it can move; not in the bake.
		_roll_gate(b, Pf, r, n, c - rad + fw, c + rad - fw, gd + 0.07, TRANSOM)
	b.obst(["rect", min(Pf.call(c - rad, 0, -0.1).x, Pf.call(c + rad, 0, gd + 0.1).x), min(Pf.call(c - rad, 0, -0.1).z, Pf.call(c + rad, 0, gd + 0.1).z),
		max(Pf.call(c - rad, 0, -0.1).x, Pf.call(c + rad, 0, gd + 0.1).x), max(Pf.call(c - rad, 0, -0.1).z, Pf.call(c + rad, 0, gd + 0.1).z)])

## A closed roll gate across one opening, v0..v1, d into the building, floor to `top`: a grille
## panel and horizontal slats, in dynamic group "cin_gate" (scripts/cinema_gate.gd moves it).
static func _roll_gate(b, Pf, r, n, v0, v1, d, top):
	b.force_dyn = true
	b.quad("cin_gate", "grille", [Pf.call(v0, 0, d), Pf.call(v1, 0, d), Pf.call(v1, top, d), Pf.call(v0, top, d)], n, [], false, 1.0)
	var y = 0.0
	while y < top:
		b.box("cin_gate", "metal_dark", Pf.call((v0 + v1) * 0.5, y, d - 0.02), b.abs_size(r, v1 - v0, 0.03, 0.03, n))
		y += 0.18
	b.force_dyn = false

## The box office: a dark wood counter to 1.05 m, the ticket window above it with a speaking
## grille and a pass-through, the price cards along the top and a help-wanted card; inside, the
## booth's warm orange wall and a lamp.
static func _box_office(b, F, G, Pf, r, n, c, rad, gd, fw):
	var v0 = c - rad + fw
	var v1 = c + rad - fw
	var w = v1 - v0
	b.box(F, "cin_wood", Pf.call(c, 0.525, gd - 0.06), b.abs_size(r, w, 1.05, 0.24, n), Transform3D.IDENTITY, ["-y"])
	b.box(F, "cin_wood", Pf.call(c, 1.07, gd - 0.12), b.abs_size(r, w + 0.04, 0.05, 0.4, n))
	# the window, a frame round it, and the counter's money slot
	b.quad("glass", "glass", [Pf.call(v0, 1.1, gd), Pf.call(v1, 1.1, gd), Pf.call(v1, TRANSOM, gd), Pf.call(v0, TRANSOM, gd)], n,
		[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)], true)
	b.box(F, "cin_bronze", Pf.call(c, 1.8, gd), b.abs_size(r, 0.05, 1.4, 0.06, n))
	b.box(F, "cin_grille", Pf.call(c - 0.55, 1.45, gd - 0.01), b.abs_size(r, 0.16, 0.16, 0.01, n))
	b.box(F, "cin_grille", Pf.call(c + 0.55, 1.45, gd - 0.01), b.abs_size(r, 0.16, 0.16, 0.01, n))
	# the cards inside the glass, along its top: four price cards and the help-wanted card
	for k in 4:
		var u0 = k * 0.1875
		var cv0 = v0 + 0.08 + k * 0.42
		_card(b, Pf, r, n, cv0, cv0 + 0.38, 2.05, 2.45, gd + 0.06, u0 + 0.008, 0.06, u0 + 0.18, 0.94)
	_card(b, Pf, r, n, v0 + 0.1, v0 + 0.5, 1.2, 1.45, gd + 0.04, 0.765, 0.18, 0.995, 0.8)
	# the booth inside
	b.quad(G, "cin_booth", [Pf.call(v0, 0, gd + 1.6), Pf.call(v1, 0, gd + 1.6), Pf.call(v1, SPRING, gd + 1.6), Pf.call(v0, SPRING, gd + 1.6)], n)
	for s in [[v0, -1.0], [v1, 1.0]]:
		b.quad(G, "cin_booth", [Pf.call(s[0], 0, gd), Pf.call(s[0], 0, gd + 1.6), Pf.call(s[0], SPRING, gd + 1.6), Pf.call(s[0], SPRING, gd)], r * (-s[1]))
	b.quad(G, "cin_dark", [Pf.call(v0, SPRING, gd), Pf.call(v1, SPRING, gd), Pf.call(v1, SPRING, gd + 1.6), Pf.call(v0, SPRING, gd + 1.6)], Vector3.DOWN)
	b.box(G, "cin_wood", Pf.call(c, 0.95, gd + 0.4), b.abs_size(r, w, 0.04, 0.5, n))
	var l = b.add_omni(Pf.call(c, 2.3, gd + 0.8), 0.5, 3.5, Color(1.0, 0.82, 0.6))
	b.tag(l, "", 0.4, 0.6)

static func _card(b, Pf, r, n, v0, v1, y0, y1, d, ua, va, ub, vb):
	b.quad("cinf_sign", "cin_cards", [Pf.call(v0, y0, d), Pf.call(v1, y0, d), Pf.call(v1, y1, d), Pf.call(v0, y1, d)], n,
		[Vector2(ua, vb), Vector2(ub, vb), Vector2(ub, va), Vector2(ua, va)], true)

## A poster case: a silver frame round a lit yellow back with two one-sheets (or the welcome card).
static func _case(b, F, Pf, r, n, v, kind, idx):
	var w = 1.55 if kind == "poster" else 0.95
	var y0 = 0.7
	var y1 = 2.3
	var d = -0.07
	b.box(F, "cin_silver", Pf.call(v, (y0 + y1) * 0.5, -0.04), b.abs_size(r, w + 0.12, y1 - y0 + 0.12, 0.08, n))
	b.quad("cinf_sign", "cin_yellow", [Pf.call(v - w * 0.5, y0, d - 0.011), Pf.call(v + w * 0.5, y0, d - 0.011), Pf.call(v + w * 0.5, y1, d - 0.011), Pf.call(v - w * 0.5, y1, d - 0.011)], n,
		[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)], true)
	if kind == "poster":
		for k in 2:
			var pi = (idx + k) % 4
			var row = 0 if k == 0 else 1
			var pv0 = v - w * 0.5 + 0.06 + k * (w * 0.5)
			var pv1 = pv0 + w * 0.5 - 0.12
			var ua = pi * 0.25
			b.quad("cinf_sign", "cin_posters", [Pf.call(pv0, y0 + 0.12, d - 0.013), Pf.call(pv1, y0 + 0.12, d - 0.013), Pf.call(pv1, y1 - 0.12, d - 0.013), Pf.call(pv0, y1 - 0.12, d - 0.013)], n,
				[Vector2(ua, row * 0.5 + 0.5), Vector2(ua + 0.25, row * 0.5 + 0.5), Vector2(ua + 0.25, row * 0.5), Vector2(ua, row * 0.5)], true)
	else:
		b.quad("cinf_sign", "cin_welcome", [Pf.call(v - w * 0.5 + 0.05, y0 + 0.05, d - 0.013), Pf.call(v + w * 0.5 - 0.05, y0 + 0.05, d - 0.013), Pf.call(v + w * 0.5 - 0.05, y1 - 0.05, d - 0.013), Pf.call(v - w * 0.5 + 0.05, y1 - 0.05, d - 0.013)], n,
			[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)], true)
	b.quad("glass", "glass", [Pf.call(v - w * 0.5, y0, d - 0.02), Pf.call(v + w * 0.5, y0, d - 0.02), Pf.call(v + w * 0.5, y1, d - 0.02), Pf.call(v - w * 0.5, y1, d - 0.02)], n,
		[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)], true)

## A carriage lantern on a pier: a black-and-brass box lantern with a pointed cap, on a bracket.
static func _lantern(b, F, Pf, r, n, v):
	var y = 2.75
	var c = Pf.call(v, y, -0.3)
	b.box(F, "cin_black", Pf.call(v, y + 0.42, -0.13), b.abs_size(r, 0.05, 0.05, 0.26, n))
	b.box(F, "cin_black", Pf.call(v, y + 0.42, -0.005), b.abs_size(r, 0.12, 0.22, 0.02, n))
	b.cyl(F, "cin_black", c + UP * 0.28, 0.17, 0.02, 0.16, 4, true, false)
	b.cyl(F, "cin_brass", c + UP * 0.25, 0.15, 0.15, 0.03, 4, true, true)
	b.cyl(F, "cin_lamp", c - UP * 0.2, 0.1, 0.14, 0.45, 4, false, false)
	for k in 4:
		var ang = PI * 0.25 + PI * 0.5 * k
		var off = Vector3(cos(ang), 0, sin(ang)) * 0.13
		b.box(F, "cin_black", c + off + UP * 0.03, Vector3(0.02, 0.46, 0.02))
	b.cyl(F, "cin_black", c - UP * 0.24, 0.1, 0.1, 0.04, 4, true, true)
	b.cyl(F, "cin_black", c - UP * 0.36, 0.02, 0.07, 0.12, 8, false, true)
	var l = b.add_omni(c, 0.6, 3.5, Color(1.0, 0.82, 0.55))
	b.tag(l, "", 0.35, 0.8)

## The lobby behind the glass, dim: patterned carpet, a dark ceiling, posters on the side walls,
## the concession stand's glow at the back (the inside is built later).
static func _lobby(b, G, Pf, r, n, Ln):
	var D = LOBBY
	b.quad(G, "cin_carpet", [Pf.call(0.3, 0, 0.3), Pf.call(Ln - 0.3, 0, 0.3), Pf.call(Ln - 0.3, 0, D), Pf.call(0.3, 0, D)], UP,
		[Vector2(0, 0), Vector2(Ln / 1.5, 0), Vector2(Ln / 1.5, D / 1.5), Vector2(0, D / 1.5)])
	b.quad(G, "cin_dark", [Pf.call(0.3, 3.2, 0.3), Pf.call(Ln - 0.3, 3.2, 0.3), Pf.call(Ln - 0.3, 3.2, D), Pf.call(0.3, 3.2, D)], Vector3.DOWN)
	b.quad(G, "cin_wall", [Pf.call(Ln - 0.3, 0, D), Pf.call(0.3, 0, D), Pf.call(0.3, 3.2, D), Pf.call(Ln - 0.3, 3.2, D)], n)
	for s in [[0.3, 1.0], [Ln - 0.3, -1.0]]:
		b.quad(G, "cin_wall", [Pf.call(s[0], 0, 0.3), Pf.call(s[0], 0, D), Pf.call(s[0], 3.2, D), Pf.call(s[0], 3.2, 0.3)], r * s[1])
	# the concession stand at the back, its back-lit menu
	b.box(G, "cin_wood", Pf.call(Ln * 0.5, 0.5, D - 1.4), b.abs_size(r, 7.0, 1.0, 0.7, n), Transform3D.IDENTITY, ["-y"])
	b.quad(G, "cin_menu", [Pf.call(Ln * 0.5 - 3.4, 1.8, D - 0.01), Pf.call(Ln * 0.5 + 3.4, 1.8, D - 0.01), Pf.call(Ln * 0.5 + 3.4, 2.7, D - 0.01), Pf.call(Ln * 0.5 - 3.4, 2.7, D - 0.01)], n)
	for k in 3:
		var l = b.add_spot(Pf.call(Ln * (0.25 + 0.25 * k), 3.1, D * 0.5), Vector3.DOWN, 0.9, 5.0, 60.0, Color(1.0, 0.85, 0.65))
		b.tag(l, "", 0.6, 0.9)
	var lm = b.add_omni(Pf.call(Ln * 0.5, 2.2, D - 2.0), 0.8, 6.0, Color(1.0, 0.78, 0.5))
	b.tag(lm, "", 0.6, 1.0)

static func fill_mat(m, key, b):
	match key:
		"brick":
			m.albedo_texture = b.tex("cin/brick.png"); m.roughness = 0.85
		"reveal":
			m.albedo_texture = b.tex("cin/brick.png"); m.roughness = 0.85; m.albedo_color = Color(0.95, 0.95, 0.94)
		"trim":
			m.albedo_color = Color("#e8e6e0"); m.roughness = 0.8
		"base":
			m.albedo_color = Color("#8a8680"); m.roughness = 0.6
		"bronze":
			m.albedo_color = Color("#3a2c22"); m.metallic = 0.6; m.roughness = 0.35
		"wood":
			m.albedo_texture = b.tex("wood_dark.png"); m.albedo_color = Color(0.8, 0.62, 0.52); m.roughness = 0.45
		"grille":
			m.albedo_color = Color("#9a9894"); m.metallic = 0.7; m.roughness = 0.4
		"silver":
			m.albedo_color = Color("#c8cacc"); m.metallic = 0.8; m.roughness = 0.25
		"yellow":
			m.albedo_color = Color("#f2d86a"); m.roughness = 0.5
			m.emission_enabled = true; m.emission = Color("#ffe27a"); m.emission_energy_multiplier = 0.9
			m.set_meta("e_day", 0.6); m.set_meta("e_night", 1.0)
		"posters":
			m.albedo_texture = b.tex("cin/posters.png"); m.roughness = 0.4
			m.emission_enabled = true; m.emission_texture = m.albedo_texture; m.emission = Color.WHITE
			m.emission_energy_multiplier = 0.45
			m.set_meta("e_day", 0.3); m.set_meta("e_night", 0.55)
		"welcome":
			m.albedo_texture = b.tex("cin/welcome.png"); m.roughness = 0.4
			m.emission_enabled = true; m.emission_texture = m.albedo_texture; m.emission = Color.WHITE
			m.emission_energy_multiplier = 0.45
			m.set_meta("e_day", 0.3); m.set_meta("e_night", 0.55)
		"cards":
			m.albedo_texture = b.tex("cin/cards.png"); m.roughness = 0.5
		"booth":
			m.albedo_color = Color("#c8501e"); m.roughness = 0.7
		"dark":
			m.albedo_color = Color("#1a1412"); m.roughness = 0.9
		"black":
			m.albedo_color = Color("#141210"); m.roughness = 0.45; m.metallic = 0.3
		"brass":
			m.albedo_color = Color("#b88d3e"); m.metallic = 1.0; m.roughness = 0.3
		"lamp":
			m.albedo_color = Color("#ffe2b0")
			m.emission_enabled = true; m.emission = Color("#ffc977"); m.emission_energy_multiplier = 2.5
			m.set_meta("e_day", 1.5); m.set_meta("e_night", 3.0)
		"carpet":
			m.albedo_texture = b.tex("cin/carpet.png"); m.roughness = 0.95
		"wall":
			m.albedo_color = Color("#5a2a2e"); m.roughness = 0.9
		"menu":
			m.albedo_texture = b.tex("cin/posters.png"); m.albedo_color = Color(1.0, 0.85, 0.7); m.roughness = 0.5
			m.emission_enabled = true; m.emission_texture = m.albedo_texture; m.emission = Color("#ffd8a0")
			m.emission_energy_multiplier = 0.5
			m.set_meta("e_day", 0.4); m.set_meta("e_night", 0.6)
		_:
			return false
	return true
