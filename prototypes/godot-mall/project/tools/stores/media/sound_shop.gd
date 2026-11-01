## Sound Shop (store s19), the record store beside Kay-Bee Toys, built to
## design/storefronts/sound-shop.md.
##
## The front and the inside follow the 1993 Hammond Square Mall commercial (YouTube
## WvaGN9lUpr0, 4.3-4.9 s): a dark grey fascia with fat red italic neon letters, a wide
## open front framed in dark grey, a bright white store behind: white wall racks of CDs
## and cassettes, white islands by the door, big posters hung high, a light vinyl floor.
## Steven: the registers were on the LEFT looking in, and behind them a concert
## box-office board (the counter sold tickets); here a generic "TICKETS" board.
##
## Frame (as Kay-Bee's next door): u runs along the 6 m frontage from the edge's start a
## (z = -64, the viewer's right, Lane Bryant's side) to z = -58 (u = 6, Kay-Bee's side).
## d runs into the store (-x); d < 0 is the hall.

const K = preload("res://tools/stores/media/kit.gd")
const UNIT = 6.0
const DEPTH = 24.0
const SIDE = 0.12
const HEAD = 2.75
const FTOP = 3.6
const PROUD = 0.22
const CEIL = 3.0
const HY = 2.3
const BAY = 1.22
const UP = Vector3.UP
## CD wall: nine rows of jewel cases face-out, a cassette row at the bottom
const CD_BOARDS = [0.36, 0.56, 0.76, 0.96, 1.16, 1.36, 1.56, 1.76, 1.96]

static func P(a, t, n, u, y, d):
	return a + t * u - n * d + Vector3(0, y, 0)

static func gm(d):
	return "ss%d_merch" % int(clamp(d / 8.0, 0, 2))

static func build(b, g, e, a, bb, n, t, Ln, sd):
	var rng = RandomNumberGenerator.new()
	rng.seed = 1993
	front(b, "ssf_props", a, t, n)
	room(b, "ss_shell", a, t, n)
	fixtures(b, a, t, n, rng)
	var rp = ReflectionProbe.new()
	rp.position = P(a, t, n, UNIT * 0.5, CEIL * 0.5, DEPTH * 0.5)
	rp.size = (t * UNIT + n * DEPTH).abs() + Vector3(0.1, CEIL + 0.1, 0.1)
	rp.box_projection = true
	rp.interior = true
	rp.update_mode = ReflectionProbe.UPDATE_ONCE
	rp.intensity = 0.6
	b.light_root.add_child(rp)

# ------------------------------------------------------------------ the front
## Rebuilt Nov 1, 2026 (design/storefronts/sound-shop.md): the photo
## refs/era_1995/stores/Sound_Shop.jpg (lit yellow-orange SOUND SHOP letters with a red rim)
## and, Steven (Nov 1), an open storefront (no glass), on the parts of the
## front that still stand at Southland (IMG_4484 f050-f055, now SOLA): the black textured
## stucco fascia band, bull-nosed and curved back to the wall at both ends, a white soffit
## under it, glossy black round pillars and a black 8-inch tile threshold.
const BAND_LO = 2.75          # fascia band bottom (the soffit)
const BAND_HI = 3.6
const BAND_OUT = 0.45         # how far the band stands out from the wall line
const END_R = 0.45            # the plan radius where the band curves back to the wall
const PIL_R = 0.2             # the black pillars (2026: about 0.4 m across)
const PIL_U = [0.62, 5.38]
const PIL_D = -0.2
const OPEN_D = 0.8            # the soffit inside the open front

## The band's face line in plan, from one end to the other: a list of [u, d] (d < 0 is out
## in the hall), straight in the middle, quarter circles back to the wall at the ends.
static func band_plan():
	var pts = []
	for i in range(0, 9):
		var a = PI + PI * 0.5 * i / 8.0
		pts.append([END_R + END_R * cos(a) + 0.08, END_R * sin(a)])
	for i in range(1, 8):
		pts.append([lerp(END_R + 0.08, UNIT - END_R - 0.08, i / 8.0), -END_R])
	for i in range(0, 9):
		var a = PI * 1.5 + PI * 0.5 * i / 8.0
		pts.append([UNIT - END_R - 0.08 + END_R * cos(a), END_R * sin(a)])
	return pts

static func front(b, G, a, t, n):
	var LH = b.LANE_H
	var o = P(a, t, n, 0, 0, 0)
	var GD = "ssf_sign"        # unbaked: the letters and their glow
	# the mall wall over the band: cream as along the rest of the lane (2026 frames)
	b.quad(G, "bulkhead", [P(a, t, n, 0, BAND_HI, 0), P(a, t, n, UNIT, BAND_HI, 0), P(a, t, n, UNIT, LH, 0), P(a, t, n, 0, LH, 0)], n)
	# -- the band: sweep a bull-nosed profile along the plan line
	var plan = band_plan()
	# profile: [inset back from the face, y]
	var prof = [[0.14, BAND_LO], [0.05, BAND_LO + 0.012], [0.012, BAND_LO + 0.05], [0.0, BAND_LO + 0.12],
		[0.0, BAND_HI - 0.12], [0.012, BAND_HI - 0.05], [0.05, BAND_HI - 0.012], [0.14, BAND_HI]]
	var pw = []   # world points of the plan line and their outward normals
	for k in plan.size():
		var k0 = plan[max(k - 1, 0)]
		var k1 = plan[min(k + 1, plan.size() - 1)]
		var tu = Vector2(k1[0] - k0[0], k1[1] - k0[1]).normalized()
		var out = Vector2(tu.y, -tu.x)    # pointing toward -d (the hall)
		if out.y > 0.0:
			out = -out
		pw.append([plan[k], out])
	var prevs = []
	for k in pw.size():
		var pu = pw[k][0][0]
		var pd = pw[k][0][1]
		var ou = pw[k][1].x
		var od = pw[k][1].y
		var ring = []
		for q in prof:
			# inset toward the wall: against the outward normal, but never behind the wall line
			var uu = pu - ou * q[0]
			var dd = min(pd - od * q[0], 0.0)
			ring.append(P(a, t, n, uu, q[1], dd))
		if k > 0:
			for j in range(prof.size() - 1):
				var p0 = prevs[j]; var p1 = ring[j]; var p2 = ring[j + 1]; var p3 = prevs[j + 1]
				var nn = (p1 - p0).cross(p3 - p0).normalized()
				var mid = (p0 + p1 + p2 + p3) * 0.25
				var face_out = P(a, t, n, pu + ou, (BAND_LO + BAND_HI) * 0.5, pd + od) - mid
				if nn.dot(face_out) < 0.0 and abs(prof[j][1] - prof[j + 1][1]) > 0.0:
					nn = -nn
				b.quad(G, "md_ss_stucco", [p0, p1, p2, p3], nn, [Vector2(0, 0), Vector2(0.3, 0), Vector2(0.3, 0.3), Vector2(0, 0.3)].map(func(v): return v + Vector2(k * 0.3, j * 0.11)))
			# the white soffit under the band and the band's top, from the inner edge back to the wall
			var s0 = prevs[0]; var s1 = ring[0]
			var w0 = s0 + n * (s0 - a).dot(n) * -1.0
			var w1 = s1 + n * (s1 - a).dot(n) * -1.0
			b.quad(G, "md_ss_soffit", [s0, s1, w1, w0], Vector3.DOWN)
			var tt0 = prevs[prof.size() - 1]; var tt1 = ring[prof.size() - 1]
			b.quad(G, "md_ss_stucco", [tt0, tt1, tt1 + n * (tt1 - a).dot(n) * -1.0, tt0 + n * (tt0 - a).dot(n) * -1.0], UP)
		prevs = ring
	# -- the letters: "SOUND SHOP" lit yellow-orange with red returns (photo), on the band's face
	var sc = 1.22
	K.letters(b, GD, "md_ss_letter", "md_ss_letter_side", "res://tools/stores/media/ss_letters.json", P(a, t, n, UNIT, 0, 0), -t, n, UNIT * 0.5, BAND_LO + 0.17, BAND_OUT, 0.07, sc)
	# the glow they throw on the band and the floor in front (the photo's orange wash)
	var l = b.add_omni(P(a, t, n, UNIT * 0.5, BAND_LO - 0.1, -1.3), 0.5, 3.5, Color(1.0, 0.62, 0.3))
	b.tag(l, "", 0.35, 0.6)
	# -- the black pillars under the band's curved ends
	for pu in PIL_U:
		b.cyl(G, "md_ss_gloss_black", P(a, t, n, pu, 0, PIL_D), PIL_R, PIL_R, BAND_LO, 24, false, false)
		K.ob(b, P(a, t, n, pu, 0, PIL_D) - Vector3(PIL_R, 0, PIL_R), P(a, t, n, pu, 0, PIL_D) + Vector3(PIL_R, 0, PIL_R), 0.08)
	# -- the end returns: dark wall from the neighbours' piers to the glass
	for s in [[0.0, 0.32], [UNIT - 0.32, UNIT]]:
		K.lbox(b, G, "md_ss_wall_dark", o, t, n, s[0], 0.0, -0.05, s[1] - s[0], BAND_LO, 0.17, ["-y"])
	# -- the opening (Steven, Nov 1: "sound shop is an open storefront"): wide open between the
	# pillars, no glass; the security grille rolled up in a slim box under the band
	b.cur_color = Color("#9a9c9e")
	K.lbox(b, G, "vcolor", o, t, n, 0.32, BAND_LO - 0.16, -0.12, UNIT - 0.64, 0.16, 0.2)
	b.cur_color = Color.WHITE
	# the grille's side tracks inside the end returns
	for gu in [0.32, UNIT - 0.36]:
		K.lbox(b, G, "md_ss_alu", o, t, n, gu, 0.0, -0.06, 0.04, BAND_LO - 0.16, 0.06, ["-y"])
	# the white soffit just inside the opening, three downlights
	b.quad(G, "md_ss_soffit", [P(a, t, n, 0.32, BAND_LO, 0.0), P(a, t, n, UNIT - 0.32, BAND_LO, 0.0), P(a, t, n, UNIT - 0.32, BAND_LO, OPEN_D), P(a, t, n, 0.32, BAND_LO, OPEN_D)], Vector3.DOWN)
	b.quad(G, "md_wall", [P(a, t, n, SIDE, BAND_LO, OPEN_D), P(a, t, n, UNIT - SIDE, BAND_LO, OPEN_D), P(a, t, n, UNIT - SIDE, CEIL, OPEN_D), P(a, t, n, SIDE, CEIL, OPEN_D)], -n)
	for u in [1.2, 3.0, 4.8]:
		b.cyl(G, "md_downlight", P(a, t, n, u, BAND_LO - 0.004, OPEN_D * 0.5), 0.08, 0.08, 0.004, 12, false, true)
	var l2 = b.add_spot(P(a, t, n, 3.0, BAND_LO - 0.1, OPEN_D * 0.5), Vector3.DOWN, 1.2, 5.0, 70.0, Color(1.0, 0.95, 0.86))
	b.tag(l2, "", 1.2, 1.2)
	# -- the black 8-inch tile threshold (Southland, 2026): from the hall to just inside the opening
	K.floor_rect(b, G, "md_ss_tile_black", P(a, t, n, 0, 0.004, 0), t, n, 0.32, UNIT - 0.32, -0.65, 0.4, 0.8)
	# the SALE $9.99 card on its chrome stand just inside
	K.sign_stand(b, G, "md_ss_cards", P(a, t, n, 2.3, 0, 0.6), -t, n, 2)

# ------------------------------------------------------------------ the room
static func room(b, G, a, t, n):
	var u0 = SIDE
	var u1 = UNIT - SIDE
	var dB = DEPTH - SIDE
	K.floor_rect(b, G, "md_vinyl", a, t, n, u0, u1, 0.0, dB, 0.61)
	K.ceiling(b, G, a, t, n, u0, u1, 0.8, dB, CEIL, [1.5, 4.5])
	K.wall(b, G, "md_wall", a, t, n, u1, dB, u1, 0.0, 0.0, CEIL, -t)
	K.wall(b, G, "md_wall", a, t, n, u0, 0.0, u0, dB, 0.0, CEIL, t)
	K.wall(b, G, "md_wall", a, t, n, u1, dB, u0, dB, 0.0, CEIL, n)
	# the stockroom door in the back wall, an exit sign over it
	var du = 1.0
	b.cur_color = Color("#d8d6d0")
	b.box(G, "vcolor", P(a, t, n, du, 1.05, dB - 0.02), b.abs_size(t, 0.95, 2.1, 0.04, n))
	b.cur_color = Color("#9a9a9a")
	b.box(G, "vcolor", P(a, t, n, du + 0.35, 1.0, dB - 0.06), b.abs_size(t, 0.12, 0.04, 0.04, n))
	b.cur_color = Color.WHITE
	b.box(G, "exit_sign", P(a, t, n, du, 2.4, dB - 0.05), b.abs_size(t, 0.36, 0.16, 0.06, n))

# ------------------------------------------------------------------ fixtures
static func fixtures(b, a, t, n, rng):
	var G = "ss_fix"
	var S = "ss_small"
	var u0 = SIDE
	var u1 = UNIT - SIDE
	var dB = DEPTH - SIDE
	var into = -n
	# -- the registers on the left (Steven), the box-office board behind them
	var bo = P(a, t, n, u1, 0, 1.3)
	b.cur_color = Color("#2a2a2e")
	K.lbox(b, G, "vcolor", bo, into, -t, 0.0, 0.9, 0.0, 3.2, 1.6, 0.03)
	b.cur_color = Color.WHITE
	K.fq(b, G, "md_tickets", bo, into, -t, 0.6, 2.6, 1.3, 2.3, 0.035)
	# a back counter under the board: cassettes behind glass
	K.lbox(b, G, "md_laminate", bo, into, -t, 0.0, 0.0, 0.0, 3.2, 0.88, 0.45, ["-y"])
	K.stock_row(b, G, bo, into, -t, 0.1, 3.1, 0.3, 0.14, 0.47, "tape", rng)
	K.stock_row(b, G, bo, into, -t, 0.1, 3.1, 0.52, 0.14, 0.47, "tape", rng)
	b.quad("glass", "glass", [K.L(bo, into, -t, 0.05, 0.15, 0.452), K.L(bo, into, -t, 3.15, 0.15, 0.452), K.L(bo, into, -t, 3.15, 0.85, 0.452), K.L(bo, into, -t, 0.05, 0.85, 0.452)], -t,
		[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)], true)
	# the counter, parallel to the wall, two registers
	var co = P(a, t, n, 4.75, 0, 1.4)
	K.counter(b, G, S, co, into, -t, 3.0, "md_ss_counter", rng)
	K.register(b, S, K.L(co, into, -t, 2.0, 0.985, 0.12), into, -t)
	K.ob_local(b, bo, into, -t, 0.0, 0.0, 3.2, 1.0)
	# -- by the door: two white islands of new releases (Hammond), a poster stand
	for s in [[1.55, 2.1, 0], [3.05, 3.0, 1]]:
		var c = P(a, t, n, s[0], 0, s[1])
		K.lbox(b, G, "md_white", c - t * 0.45 - into * 0.45, t, into, 0.0, 0.0, 0.0, 0.9, 1.0, 0.9, ["-y"])
		for f in [n, -n, t, -t]:
			var r = (-f).cross(UP)
			K.stock_row(b, G, c - r * 0.45, r, f, 0.05, 0.85, 0.55, 0.16, 0.46, "cd", rng)
			K.stock_row(b, G, c - r * 0.45, r, f, 0.05, 0.85, 0.3, 0.16, 0.46, "cd", rng)
		# the header card on its stem
		b.cur_color = Color("#d8d8d4")
		b.box(S, "vcolor", c + Vector3(0, 1.2, 0), Vector3(0.02, 0.4, 0.02))
		b.cur_color = Color.WHITE
		for sg in [1.0, -1.0]:
			K.fq(b, S, "md_ss_cards", c + n * 0.012 * sg + t * 0.25 * sg, -t * sg, n * sg, 0.0, 0.5, 1.4, 1.9, 0.0, (s[2] % 2) * 0.5, 0.0, (s[2] % 2) * 0.5 + 0.5, 0.5)
		K.ob(b, c - Vector3(0.45, 0, 0.45), c + Vector3(0.45, 0, 0.45), 0.12)
	K.sign_stand(b, G, "md_ss_cards", P(a, t, n, 2.3, 0, 0.6), -t, n, 2)
	# -- the CD walls: the left past the counter, the right the whole way back
	var heads = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 11, 10]
	var d = 5.0
	var k = 0
	while d + BAY <= dB - 0.45:
		var sheets = [["tape"]] if k >= 13 else [["tape", "cd", "cd", "cd", "cd", "cd", "cd", "cd", "cd"]]
		K.bay_run(b, G, gm(d), P(a, t, n, u1, 0, d), into, -t, BAY, 1, CD_BOARDS, sheets, [heads[(k / 2) % heads.size()] if k % 2 == 0 else -1], "md_ss_headers", HY, rng, 0.3)
		d += BAY
		k += 1
	K.end_cap(b, G, "md_white", P(a, t, n, u1, 0, 5.0), into, -t, 0.3, PI, PI * 0.5, 0.0, 2.1)
	d = dB - 0.45
	k = 0
	while d - BAY >= 0.9:
		var sheets = [["tape", "cd", "cd", "cd", "cd", "cd", "cd", "cd", "cd"]]
		K.bay_run(b, G, gm(d), P(a, t, n, u0, 0, d), n, t, BAY, 1, CD_BOARDS, sheets, [heads[(k / 2 + 6) % heads.size()] if k % 2 == 0 else -1], "md_ss_headers", HY, rng, 0.3)
		d -= BAY
		k += 1
	K.end_cap(b, G, "md_white", P(a, t, n, u0, 0, d), n, t, 0.3, 0.0, PI * 0.5, 0.0, 2.1)
	# the back wall: cassettes, left of the stockroom door
	K.bay_run(b, G, "ss2_merch", P(a, t, n, u1 - 0.4, 0, dB), -t, n, BAY, 3, CD_BOARDS, [["tape"]], [11, -1, 11], "md_ss_headers", HY, rng, 0.3)
	# -- the middle: two runs of CD browser bins down the store
	for run in [[6.2, 6], [14.0, 6]]:
		for j in run[1]:
			var dd = run[0] + j * 1.02
			K.browser(b, G if dd < 12.0 else "ss_fix2", P(a, t, n, 3.5, 0, dd), into, t, 1.0, rng)
		# a divider card standing at each run's front end
		var c = P(a, t, n, 2.95, 0, run[0] - 0.05)
		for sg in [1.0, -1.0]:
			K.fq(b, S, "md_ss_cards", c + n * 0.01 * sg - t * 0.25 * sg, t * sg, n * sg, 0.0, 0.5, 0.95, 1.35, 0.0, 0.0, 0.5, 0.5, 1.0)
	# -- posters hung high over the browser runs (Hammond: big posters near the ceiling)
	for dd in [8.0, 15.8]:
		var c = P(a, t, n, 2.95, 0, dd)
		for sg in [1.0, -1.0]:
			K.fq(b, S, "md_ss_posters", c + t * 0.01 * sg - into * 1.0 * sg, into * sg, t * sg, 0.0, 2.0, 2.05, 2.95, 0.0, 0.0, 0.0, 1.0, 0.75)
		b.cur_color = Color("#c8c8c8")
		for s2 in [-0.8, 0.8]:
			b.box(S, "vcolor", c + into * s2 + Vector3(0, 2.975, 0), Vector3(0.005, 0.05, 0.005), Transform3D.IDENTITY, [], true)
		b.cur_color = Color.WHITE
