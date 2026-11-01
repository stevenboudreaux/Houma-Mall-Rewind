## Chick-fil-A (s64), rebuilt Oct 8, 2026 from Steven's video of the Southland unit
## (design/storefronts/chick-fil-a.md has the frame-by-frame reading and what is guessed).
##
## Front (0-8 s): a light grey fascia whose sign panel drops over the open entry, the script
## name in white lit letters; a dark maroon beam to its left; to its right a recessed box with
## a pink fish-scale awning under a cove light, in one bay (no pilaster: Steven, Oct 8), over the
## counter's takeout end.
## Inside: the counter down the right (cream top, chocolate front, registers), a backlit menu
## band over it, the kitchen behind (maroon wall, hood, pressure fryers, bun toaster, holding
## cabinet, prep table, gold heat lamps); on the left a long dining room: red quarry pavers,
## cream striped paper over a dark wainscot, tufted booths, dark tables, white spindle chairs,
## brass sconces with white globes, framed prints, planters, a condiment island, ceiling fans,
## a lay-in ceiling with a dark trim band, a wood back door under an EXIT sign.
##
## Frame: P(u, y, d) = a + t u - n d + y up; u along the frontage from its start (x -102, the
## right hand of someone facing the store), d into the store.

const K = preload("res://tools/stores/media/kit.gd")
const UP = Vector3.UP
const W = 8.0
const D = 26.0
const SIDE = 0.12
const CEIL = 2.9
const HEAD = 2.7          # bottom of the sign panel and the entry soffit
const FASCIA_Y = 3.35     # bottom of the fascia over the awning and the maroon beam
const G = "cfa_fix"       # baked: counter, booths, furniture
const GS = "cfa_shell"    # baked: floor, walls, ceiling, front
const GK = "cfa_kitchen"  # baked: the kitchen line
const SM = "cfa_small"    # baked: small things
const DY = "cfaf_sign"    # unbaked: letters, awning scales, glow

static var a0: Vector3
static var tt: Vector3
static var nn: Vector3
static var bb

static func P(u, y, d):
	return a0 + tt * u - nn * d + UP * y

## An axis-aligned box in the store frame: u..u+wu, y..y+h, d..d+dd.
static func bx(g, m, u, y, d, wu, h, dd, skip = [], dyn = false):
	K.lbox(bb, g, m, a0, tt, -nn, u, y, d, wu, h, dd, skip, dyn)

static func col(c):
	bb.cur_color = Color(c)

## A textured wall quad on the plane u = const (facing +u if `f` > 0) or d = const.
static func wall_u(g, m, u, d0, d1, y0, y1, f, tile_w, tile_h):
	var nrm = tt * f
	var pts = [P(u, y0, d0), P(u, y0, d1), P(u, y1, d1), P(u, y1, d0)]
	var uvs = [Vector2(d0 / tile_w, -y0 / tile_h), Vector2(d1 / tile_w, -y0 / tile_h), Vector2(d1 / tile_w, -y1 / tile_h), Vector2(d0 / tile_w, -y1 / tile_h)]
	bb.quad(g, m, pts, nrm, uvs)

static func wall_d(g, m, d, u0, u1, y0, y1, f, tile_w, tile_h):
	var nrm = -nn * f
	var pts = [P(u0, y0, d), P(u1, y0, d), P(u1, y1, d), P(u0, y1, d)]
	var uvs = [Vector2(u0 / tile_w, -y0 / tile_h), Vector2(u1 / tile_w, -y0 / tile_h), Vector2(u1 / tile_w, -y1 / tile_h), Vector2(u0 / tile_w, -y1 / tile_h)]
	bb.quad(g, m, pts, nrm, uvs)

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
	rp.position = P(W * 0.5, 1.5, D * 0.5)
	rp.size = (t * W + n * D).abs() + Vector3(0.1, 3.1, 0.1)
	rp.box_projection = true
	rp.interior = true
	rp.update_mode = ReflectionProbe.UPDATE_ONCE
	rp.intensity = 0.6
	b.light_root.add_child(rp)

# ------------------------------------------------------------------ the front
static func front():
	var fz = -0.14   # the fascia's face
	# the grey fascia over the whole front, down to the awning box and the beam
	bx(GS, "cf_fascia", 0.0, FASCIA_Y, fz, W, bb.LANE_H - FASCIA_Y, 0.14)
	# the sign panel dropping over the entry
	bx(GS, "cf_fascia", 3.25, HEAD, fz, 4.1, FASCIA_Y - HEAD, 0.14 + 1.0, ["+y"])
	# end piers
	bx(GS, "cf_fascia", 0.0, 0.0, fz, SIDE, FASCIA_Y, 0.14 + SIDE, ["-y"])
	bx(GS, "cf_fascia", W - SIDE, 0.0, fz, SIDE, FASCIA_Y, 0.14 + SIDE, ["-y"])
	# the soffit under the sign panel, stepping up to the ceiling at d 1
	bx(GS, "cf_brown", 3.25, HEAD - 0.02, fz, 4.1, 0.02, 1.14 + 0.14, ["+y"])
	for u in [4.0, 5.3, 6.6]:
		bb.box(SM, "gb_can", P(u, HEAD - 0.025, 0.4), bb.abs_size(tt, 0.2, 0.01, 0.2, nn), Transform3D.IDENTITY, ["+y"])
	# left of the sign: the dark maroon beam over the dining entry, set back
	bx(GS, "cf_maroon", 7.35, HEAD, 0.25, W - SIDE - 7.35, FASCIA_Y - HEAD, 0.9)
	bx(GS, "cf_brown", 7.35, HEAD - 0.08, 0.2, W - SIDE - 7.35, 0.08, 1.0, ["+y"])
	letters()
	awning()

## The script name as white lit letter faces with dark returns (cfa_letters.json, an open
## script face standing in for the chain's lettering). Nov 1, 2026 (Steven: "as close as possible
## to the real 1995 mark ... with discretion"): the C carries the mark's comb (red, lit) and beak
## (white), drawn onto the script C by tools/stores/cfa/make_comb.py -> cfa_comb.json.
static func letters():
	var J = JSON.parse_string(FileAccess.get_file_as_string("res://tools/stores/small/cfa_letters.json"))
	var s = 1.02
	var wv = float(J.width) * s
	var ymin = 1e9
	var ymax = -1e9
	for Lt in J.letters:
		for q in Lt.tris:
			ymin = min(ymin, float(q[1])); ymax = max(ymax, float(q[1]))
	var uc = 5.3
	var ybase = 2.8
	var face_d = -0.14 - 0.075
	var back_d = -0.14
	var to_w = func(q, d):
		return P(uc + wv * 0.5 - float(q[0]) * s, ybase + (float(q[1]) - ymin) * s, d)
	var nf = nn
	var K = JSON.parse_string(FileAccess.get_file_as_string("res://tools/stores/cfa/cfa_comb.json"))
	var parts = []
	for Lt in J.letters:
		parts.append([Lt, "cf_letter"])
	parts.append([K.beak, "cf_letter"])
	parts.append([K.comb, "cf_comb"])
	for pr in parts:
		var Lt = pr[0]
		var sf = bb.st(DY, pr[1], true)
		var tr = Lt.tris
		var i = 0
		# the comb and beak stand 4 mm proud of the C they overlap, so the faces never fight
		var fd = face_d - (0.004 if Lt == K.comb or Lt == K.beak else 0.0)
		while i + 2 < tr.size():
			bb.tri(sf, to_w.call(tr[i], fd), to_w.call(tr[i + 1], fd), to_w.call(tr[i + 2], fd), Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, nf)
			i += 3
		if Lt.has("loops"):
			var sr = bb.st(DY, "cf_letter_ret", true)
			for lp in Lt.loops:
				for k in lp.size():
					var p0 = lp[k]
					var p1 = lp[(k + 1) % lp.size()]
					var w0 = to_w.call(p0, face_d)
					var w1 = to_w.call(p1, face_d)
					var dv = w1 - w0
					if dv.length() < 0.002:
						continue
					var side = dv.normalized().cross(nn)
					var b0 = to_w.call(p0, back_d)
					var b1 = to_w.call(p1, back_d)
					bb.tri(sr, w0, w1, b1, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, side)
					bb.tri(sr, w0, b1, b0, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, side)
					bb.tri(sr, w0, b1, w1, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, -side)
					bb.tri(sr, w0, b0, b1, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, -side)
	# the letters' light on the fascia, and a little throw onto the hall floor
	var l = bb.add_omni(P(uc, 3.1, -0.9), 0.5, 3.0, Color(1.0, 0.96, 0.9))
	bb.tag(l, "", 0.3, 0.6)

## The awning box: dark brown frame, cove light at the top, pink fish-scale shingles on a
## slope, one bay (the video's white pilaster between two bays was removed, Steven, Oct 8).
static func awning():
	var u0 = SIDE
	var u1 = 3.25
	var yb = 2.55
	var fz = -0.14
	# frame: top under the fascia, valance at the bottom, sides, dark back
	bx(GS, "cf_brown", u0, FASCIA_Y - 0.06, fz, u1 - u0, 0.06, 0.45, ["+y"])
	bx(GS, "cf_brown", u0, yb, fz - 0.02, u1 - u0, 0.08, 0.06)
	bx(GS, "cf_brown", u0, yb - 0.02, fz, u1 - u0, 0.02, 1.0, ["+y"])
	bx(GS, "cf_brown", u0, yb, 0.26, u1 - u0, FASCIA_Y - yb, 0.04)
	bx(GS, "cf_brown", u1 - 0.06, yb, fz - 0.02, 0.06, FASCIA_Y - yb, 0.44)
	# the cove light along the top
	bx(DY, "cf_cove", u0, FASCIA_Y - 0.11, 0.08, u1 - u0, 0.03, 0.14, [], true)
	var l = bb.add_omni(P((u0 + u1) * 0.5, FASCIA_Y - 0.2, 0.0), 0.35, 1.6, Color(1.0, 0.85, 0.85))
	bb.tag(l, "", 0.3, 0.45)
	# no pilaster: Steven (Oct 8) had the white pillar in front of the counter removed, so the
	# shingles run as one bay
	# shingles: a slope from the top back (y 3.17, d 0.22) to the bottom front (y 2.66, d -0.12)
	var T = Vector2(FASCIA_Y - 0.17, 0.22)
	var B = Vector2(yb + 0.11, -0.12)
	var dir_w = (P(0, B.x, B.y) - P(0, T.x, T.y))
	var slope_len = dir_w.length()
	var down = dir_w / slope_len
	var nrm = tt.cross(down).normalized()
	if nrm.dot(nn) < 0.0:
		nrm = -nrm
	var r = 0.07
	var rows = int(slope_len / (r * 1.05))
	var sp = bb.st(DY, "cf_awning", true)
	var se = bb.st(DY, "cf_awning_edge", true)
	for bay in [[u0 + 0.02, u1 - 0.07]]:
		for k in rows:
			var f = (k + 0.7) * slope_len / (rows + 0.4)
			var stagger = r if k % 2 == 1 else 0.0
			var cu = bay[0] + stagger
			while cu < bay[1] + 0.001:
				var c = P(cu, T.x, T.y) + down * f + nrm * (0.004 * (rows - k) + 0.006)
				_scale(sp, se, c, tt, down, nrm, r, bay[0], bay[1])
				cu += 2.0 * r

## One shingle: a half disc hanging from its top edge (`down` along the slope), clipped to
## the bay, with a dark rim just behind it.
static func _scale(sp, se, c, ax, down, nrm, r, lo, hi):
	var seg = 10
	for pass_i in 2:
		var rr = r * (1.0 if pass_i == 0 else 1.1)
		var s = sp if pass_i == 0 else se
		var cc = c - nrm * (0.0 if pass_i == 0 else 0.002)
		var pts = [cc - down * (r * 0.9) + ax * rr, cc + ax * rr]
		for i in range(seg + 1):
			var ang = PI * i / seg
			pts.append(cc + ax * (rr * cos(ang)) + down * (rr * sin(ang)))
		pts.append(cc - down * (r * 0.9) - ax * rr)
		# clip to the bay along u
		var a_u = ax.dot(a0)
		for i in pts.size():
			var uu = ax.dot(pts[i]) - a_u
			if uu < lo:
				pts[i] += ax * (lo - uu)
			elif uu > hi:
				pts[i] -= ax * (uu - hi)
		var top = cc - down * (r * 0.9)
		for i in range(pts.size()):
			var p0 = pts[i]
			var p1 = pts[(i + 1) % pts.size()]
			if (p1 - p0).length() < 0.0005:
				continue
			bb.tri(s, top, p0, p1, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, nrm)

# ------------------------------------------------------------------ the room
static func shell():
	var u0 = SIDE
	var u1 = W - SIDE
	var dB = D - SIDE
	# quarry floor
	var fp = [P(u0, 0, 0.0), P(u1, 0, 0.0), P(u1, 0, dB), P(u0, 0, dB)]
	var fuv = []
	for p in fp:
		fuv.append(Vector2(p.x / 0.8, p.z / 0.8))
	bb.quad(GS, "cf_quarry", fp, UP, fuv)
	# lay-in ceiling with 2 x 4 troffers and a dark trim band round the room
	var cp = [P(u0, CEIL, 1.0), P(u1, CEIL, 1.0), P(u1, CEIL, dB), P(u0, CEIL, dB)]
	var cuv = []
	for p in cp:
		cuv.append(Vector2(p.x / 0.61, p.z / 1.22))
	bb.quad(GS, "kb_ceiling", cp, Vector3.DOWN, cuv)
	var j = 0
	var dd = 2.0
	while dd + 1.22 < dB - 0.4:
		var rowsu = [0.65] if dd < 9.4 else []
		rowsu += [3.3, 5.6] if dd < 9.4 else [2.0, 4.0, 5.9]
		for uu in rowsu:
			var tq = [P(uu, CEIL - 0.006, dd), P(uu + 0.61, CEIL - 0.006, dd), P(uu + 0.61, CEIL - 0.006, dd + 1.22), P(uu, CEIL - 0.006, dd + 1.22)]
			bb.quad(GS, "gb_troffer", tq, Vector3.DOWN, [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)])
			if (j + int(uu)) % 2 == 0:
				var l = bb.add_spot(P(uu + 0.3, CEIL - 0.08, dd + 0.61), Vector3.DOWN, 1.1, 5.0, 62.0, Color(1.0, 0.97, 0.9))
				bb.tag(l, "", 1.1, 1.1)
		dd += 2.4
		j += 1
	# the step up from the entry soffit, and the trim band
	bx(GS, "cf_brown", u0, 2.53, 1.0, u1 - u0, CEIL - 2.53, 0.08)
	for s in [[u0, 0.0, u0 + 0.03, dB], [u1 - 0.03, 0.0, u1, dB]]:
		bx(G, "cf_brown", s[0], CEIL - 0.14, s[1] + 1.0, s[2] - s[0], 0.14, s[3] - s[1] - 1.0)
	bx(G, "cf_brown", u0, CEIL - 0.14, dB - 0.03, u1 - u0, 0.14, 0.03)
	# walls: the left wall papered over a wainscot the whole way; the right wall maroon in
	# the kitchen (d < 9.6), papered beyond; the back wall papered
	var WP = 0.52
	wall_u(GS, "cf_wallpaper", u1, dB, 1.0, 0.95, CEIL, -1.0, WP, WP)
	wall_u(GS, "cf_wainscot", u1, dB, 0.0, 0.0, 0.95, -1.0, 1.2, 0.95)
	wall_u(GS, "cf_wallpaper", u1, 1.0, 0.0, 0.95, HEAD, -1.0, WP, WP)
	wall_u(GS, "cf_maroon_wall", u0, 0.0, 9.46, 0.0, CEIL, 1.0, 1.0, 1.0)
	wall_u(GS, "cf_wallpaper", u0, 9.46, dB, 0.95, CEIL, 1.0, WP, WP)
	wall_u(GS, "cf_wainscot", u0, 9.46, dB, 0.0, 0.95, 1.0, 1.2, 0.95)
	wall_d(GS, "cf_wallpaper", dB, u1, u0, 0.95, CEIL, -1.0, WP, WP)
	wall_d(GS, "cf_wainscot", dB, u1, u0, 0.0, 0.95, -1.0, 1.2, 0.95)
	# chair rails
	for s in [[u1 - 0.035, 0.0, dB], [u0, 9.46, dB]]:
		bx(G, "cf_brown", s[0], 0.93, s[1], 0.035, 0.05, s[2] - s[1])
	bx(G, "cf_brown", u0, 0.93, dB - 0.035, u1 - u0, 0.05, 0.035)
	# the back door under its EXIT sign
	var du = 5.0
	bx(G, "cf_wood", du - 0.5, 0.0, dB - 0.05, 1.0, 2.15, 0.05)
	bx(G, "cf_brown", du - 0.56, 0.0, dB - 0.07, 0.06, 2.21, 0.07)
	bx(G, "cf_brown", du + 0.5, 0.0, dB - 0.07, 0.06, 2.21, 0.07)
	bx(G, "cf_brown", du - 0.56, 2.15, dB - 0.07, 1.12, 0.06, 0.07)
	col("#c8a040")
	bx(SM, "vcolor", du + 0.32, 1.0, dB - 0.1, 0.12, 0.04, 0.06)
	col("#ffffff")
	bb.box(SM, "exit_sign", P(du, 2.45, dB - 0.05), bb.abs_size(tt, 0.36, 0.16, 0.06, nn))

# ------------------------------------------------------------------ the counter
static func counter():
	var top_y = 1.02
	# the takeout leg along the front, under the awning, and the long leg down the right
	for c in [[SIDE, 0.25, 2.45 - SIDE, 0.62], [1.8, 0.87, 0.65, 8.5]]:
		bx(G, "cf_counter", c[0], 0.0, c[1], c[2], top_y, c[3], ["-y"])
		bx(G, "cf_top", c[0] - 0.03, top_y, c[1] - 0.03, c[2] + 0.06, 0.04, c[3] + 0.06)
		col("#1c120c")
		bx(G, "vcolor", c[0] + 0.04, 0.0, c[1] + 0.04, c[2] - 0.08, 0.1, c[3] - 0.08, ["-y"])
		col("#ffffff")
	# panel reveals on the customer faces
	col("#24170f")
	var dd = 1.3
	while dd < 9.3:
		bx(SM, "vcolor", 2.45, 0.14, dd, 0.006, 0.8, 0.02)
		dd += 0.75
	var uu = 0.6
	while uu < 2.4:
		bx(SM, "vcolor", uu, 0.14, 0.244, 0.02, 0.8, 0.006)
		uu += 0.75
	col("#ffffff")
	# registers facing the customers, and a takeout register facing the hall
	for d in [2.2, 4.4, 6.6]:
		K.register(bb, SM, P(1.95, top_y + 0.04, d + 0.45), nn, tt)
	K.register(bb, SM, P(1.6, top_y + 0.04, 0.72), -tt, nn)
	# napkins, cups and a straw jar on the counter
	for d in [1.3, 5.5, 8.6]:
		col("#f2f0ea")
		bb.cyl(SM, "vcolor", P(2.1, top_y + 0.04, d), 0.045, 0.05, 0.32, 10, true, false)
		col("#9a9ea2")
		bx(SM, "vcolor", 2.0, top_y + 0.04, d + 0.18, 0.14, 0.16, 0.1)
	col("#ffffff")
	# the backlit menu band over the counter (15.5 s): a dark bulkhead with four panels
	bx(G, "cf_brown", 1.78, 2.18, 0.9, 0.2, CEIL - 2.18, 8.5)
	K.fq(bb, G, "cf_menu", P(1.985, 0, 2.6), -nn, tt, 0.0, 4.8, 2.24, 2.84, 0.0)
	col("#1a100a")
	for k in 5:
		bx(SM, "vcolor", 1.98, 2.22, 2.6 + k * 1.2 - 0.02, 0.012, 0.66, 0.04)
	col("#ffffff")
	var lm = bb.add_omni(P(2.6, 2.4, 5.0), 0.35, 3.0, Color(1.0, 0.95, 0.88))
	bb.tag(lm, "", 0.3, 0.35)
	ob(0.0, -0.1, 2.5, 9.7, 0.08)

# ------------------------------------------------------------------ the kitchen
static func kitchen():
	var u0 = SIDE
	var bd = 0.72   # depth of the back line from the wall
	# the end wall closing the kitchen, with a swing door
	bx(GS, "cf_maroon", u0, 0.0, 9.4, 2.45 - u0, CEIL, 0.06)
	wall_d(GS, "cf_wallpaper", 9.46, u0, 2.45, 0.95, CEIL, 1.0, 0.52, 0.52)
	wall_d(GS, "cf_wainscot", 9.46, u0, 2.45, 0.0, 0.95, 1.0, 1.2, 0.95)
	bx(G, "cf_wood", 1.0, 0.0, 9.455, 0.75, 2.05, 0.02)
	col("#9a9ea2")
	bx(SM, "vcolor", 1.25, 1.35, 9.47, 0.25, 0.3, 0.01)
	col("#ffffff")
	# the back line along the maroon wall
	bx(GK, "wl_steel", u0, 0.0, 0.9, bd, 0.9, 2.75, ["-y"])
	bx(GK, "wl_steel", u0, 0.0, 4.95, bd, 0.9, 4.4, ["-y"])
	# drinks and lemonade at the front end
	for k in 2:
		var d = 1.15 + k * 0.42
		bb.cyl(SM, "cf_lemonade", P(u0 + 0.35, 0.9, d), 0.14, 0.14, 0.42, 14, true, false)
		col("#d8d8d4")
		bb.cyl(SM, "vcolor", P(u0 + 0.35, 1.32, d), 0.15, 0.15, 0.03, 14, true, false)
	col("#e8e6e0")
	bx(SM, "vcolor", u0 + 0.05, 0.9, 2.05, 0.55, 0.62, 0.55)
	col("#2a2a2c")
	for k in 4:
		bx(SM, "vcolor", u0 + 0.6, 1.0, 2.1 + k * 0.13, 0.01, 0.12, 0.08)
	col("#f2f0ea")
	for k in 3:
		bb.cyl(SM, "vcolor", P(u0 + 0.4, 1.52, 2.15 + k * 0.15), 0.04, 0.045, 0.3, 10, true, false)
	col("#ffffff")
	# the holding cabinet, tall, with small glass doors
	bx(GK, "wl_steel", u0, 0.9, 2.75, 0.62, 1.1, 0.7)
	col("#2c2422")
	for r in 3:
		for c in 2:
			bx(SM, "vcolor", u0 + 0.62, 1.0 + r * 0.33, 2.8 + c * 0.32, 0.01, 0.26, 0.28)
	col("#ffffff")
	# two pressure fryers under the hood (49-66 s): lid with a crank, a control panel
	for k in 2:
		var d = 3.7 + k * 0.62
		bx(GK, "wl_steel", u0, 0.0, d, bd, 1.0, 0.56, ["-y"])
		col("#1e1e20")
		bx(SM, "vcolor", u0 + bd, 0.62, d + 0.05, 0.01, 0.22, 0.46)
		col("#c8c8c8")
		for kk in 2:
			bb.cyl(SM, "vcolor", P(u0 + bd + 0.01, 0.68, d + 0.14 + kk * 0.26), 0.03, 0.03, 0.08, 8, true, false)
		col("#ffffff")
		if k == 0:
			bx(GK, "wl_steel", u0 + 0.05, 1.0, d + 0.04, 0.6, 0.14, 0.48)
			col("#2a2a2c")
			bx(SM, "vcolor", u0 + 0.33, 1.14, d + 0.26, 0.04, 0.12, 0.04)
			bx(SM, "vcolor", u0 + 0.15, 1.26, d + 0.27, 0.42, 0.03, 0.03)
			col("#ffffff")
		else:
			# the lid swung open against the wall
			var xf = Transform3D(Basis(Vector3(0, 0, 1), deg_to_rad(18.0)), P(u0 + 0.12, 1.0, d + 0.28))
			bb.box(GK, "wl_steel", Vector3(0.0, 0.3, 0.0), Vector3(0.06, 0.6, 0.48), xf)
	# the hood
	bx(GK, "wl_steel", u0, 1.95, 3.5, 1.05, 0.55, 2.7, [])
	col("#3a3a3c")
	bx(SM, "vcolor", u0 + 0.2, 1.949, 3.6, 0.7, 0.01, 2.5)
	col("#ffffff")
	# the prep table: bun toaster, cartons, buns and pickles, heat lamps over it
	bx(GK, "wl_steel", u0 + 0.05, 0.9, 5.3, 0.55, 0.42, 0.6)
	col("#202022")
	bx(SM, "vcolor", u0 + 0.6, 1.0, 5.36, 0.01, 0.12, 0.48)
	col("#e8c22a")
	bx(SM, "vcolor", u0 + 0.08, 1.32, 5.36, 0.3, 0.1, 0.22)
	col("#c8202a")
	bx(SM, "vcolor", u0 + 0.08, 1.33, 5.6, 0.3, 0.1, 0.22)
	col("#ffffff")
	var rng = RandomNumberGenerator.new()
	rng.seed = 64
	for k in 10:
		var c = P(u0 + 0.3 + (k % 2) * 0.2, 0.9, 6.1 + (k / 2) * 0.22)
		col("#d49a52")
		bb.cyl(SM, "vcolor", c, 0.075, 0.07, 0.05, 10, true, false)
	col("#6a8a3a")
	for k in 6:
		bb.cyl(SM, "vcolor", P(u0 + 0.25 + rng.randf() * 0.3, 0.905, 7.4 + rng.randf() * 0.5), 0.025, 0.025, 0.006, 8, true, false)
	col("#ffffff")
	for k in 3:
		var c = P(u0 + 0.45, 1.55, 6.2 + k * 0.5)
		bb.cyl(SM, "cf_gold", c, 0.11, 0.04, 0.28, 12, true, false)
		col("#3a3a3c")
		bb.cyl(SM, "vcolor", c + UP * 0.28, 0.006, 0.006, CEIL - 1.83, 4, false, false)
		col("#ffffff")
		bb.cyl(SM, "cf_heatglow", c + UP * 0.01, 0.09, 0.09, 0.005, 12, false, true)
	# outlets along the maroon wall
	col("#e8e4da")
	for d in [5.4, 6.0, 6.6, 7.6]:
		bx(SM, "vcolor", u0, 1.2, d, 0.01, 0.12, 0.07)
	col("#ffffff")
	var l = bb.add_omni(P(1.0, 2.2, 5.0), 0.6, 4.5, Color(1.0, 0.9, 0.78))
	bb.tag(l, "", 0.5, 0.6)

# ------------------------------------------------------------------ the dining room
static func dining():
	# booths down the left wall the whole way, down the right wall past the kitchen
	var d = 1.3
	while d + 1.75 <= 9.35:
		booth(W - SIDE, -1.0, d)
		d += 1.75
	d = 9.8
	while d + 1.75 <= D - 0.4:
		booth(W - SIDE, -1.0, d)
		booth(SIDE, 1.0, d)
		d += 1.75
	# front room: a planter along the queue line; the aisle down the middle stays open (14.5 s)
	planter(3.65, 2.6, 0.45, 4.6)
	# the condiment island at the end of the counter (12.5 s)
	island(3.25, 10.2)
	# back room: a planter down the middle, two-tops either side
	planter(3.8, 13.2, 0.45, 8.6)
	for dd in [13.6, 16.0, 18.4, 20.8]:
		two_top(2.85, dd)
		two_top(5.2, dd)
	# fans
	for f in [[4.8, 5.0], [4.0, 13.0], [4.0, 21.0]]:
		fan(f[0], f[1])
	var l = bb.add_omni(P(W * 0.5, 2.3, D * 0.6), 0.5, 10.0, Color(1.0, 0.86, 0.66))
	bb.tag(l, "", 0.4, 0.55)

## A booth bay against the wall at u = `uw`, reaching into the room along `s`, from d0 to
## d0 + 1.75: two tufted benches facing a table fixed to the wall; a sconce on the
## wainscot-top line between bays, a framed print over the table.
static func booth(uw, s, d0):
	var reach = 1.42
	var ua = uw if s > 0 else uw - reach
	for k in 2:
		var bd = d0 if k == 0 else d0 + 1.25
		var facing = 1.0 if k == 0 else -1.0
		var back_d = bd if k == 0 else bd + 0.45
		# base, seat, back (vinyl face, wood frame and cap)
		bx(G, "cf_wood", ua, 0.0, bd, reach, 0.4, 0.5, ["-y"])
		bx(G, "cf_vinyl", ua + 0.02, 0.4, bd + (0.08 if k == 0 else 0.0), reach - 0.04, 0.08, 0.42)
		bx(G, "cf_wood", ua, 0.0, back_d, reach, 1.1, 0.05, ["-y"])
		bx(G, "cf_vinyl", ua + 0.03, 0.5, back_d + (0.05 if k == 0 else -0.06), reach - 0.06, 0.55, 0.06)
		bx(G, "cf_brown", ua - 0.01, 1.1, back_d - 0.01, reach + 0.02, 0.04, 0.07)
		# the open end of the bench
		var ue = uw + s * reach
		bx(G, "cf_wood", ue - (0.04 if s > 0 else 0.0), 0.0, bd, 0.04, 0.62, 0.5)
	# the table
	var tc = P(uw + s * 0.68, 0, d0 + 0.875)
	col("#1c1c1e")
	bb.cyl(SM, "vcolor", tc, 0.2, 0.2, 0.03, 10, true, false)
	bb.cyl(SM, "vcolor", tc, 0.035, 0.035, 0.72, 8, false, false)
	col("#ffffff")
	bx(G, "cf_table", ua + (0.0 if s > 0 else 0.1), 0.72, d0 + 0.53, reach - 0.1, 0.035, 0.7)
	tabletop(tc + UP * 0.755, d0)
	# sconce between bays, framed print over the table
	var su = uw + s * 0.02
	sconce(su, s, d0)
	var pk = int(d0 * 7.0) % 4
	K.fq(bb, SM, "cf_prints", P(uw + s * 0.012, 0, d0 + 0.875 - 0.26), -nn, tt * s, 0.0, 0.52, 1.35, 2.0, 0.0, pk * 0.25, 0.0, pk * 0.25 + 0.25, 1.0)
	ob(min(uw, uw + s * reach), d0, max(uw, uw + s * reach), d0 + 1.75, 0.08)

## What sits on a table: a glass ashtray, a cup, a sandwich bag (24-41 s).
static func tabletop(c, seed_d):
	var rng = RandomNumberGenerator.new()
	rng.seed = int(seed_d * 100.0)
	if rng.randf() < 0.7:
		col("#c8d4d8")
		bb.cyl(SM, "vcolor", c + Vector3(rng.randf_range(-0.15, 0.15), 0, rng.randf_range(-0.15, 0.15)), 0.06, 0.06, 0.02, 10, true, false)
	if rng.randf() < 0.5:
		col("#f4f2ec")
		bb.cyl(SM, "vcolor", c + Vector3(rng.randf_range(-0.2, 0.2), 0, rng.randf_range(-0.2, 0.2)), 0.035, 0.045, 0.15, 10, true, false)
	col("#ffffff")

static func sconce(u, s, d):
	var c = P(u, 1.72, d)
	col("#3a2418")
	bb.box(SM, "vcolor", c + tt * s * 0.012, bb.abs_size(tt, 0.024, 0.26, 0.12, nn))
	col("#b88d3e")
	bb.box(SM, "vcolor", c + tt * s * 0.07 + UP * 0.02, bb.abs_size(tt, 0.12, 0.03, 0.03, nn))
	col("#ffffff")
	var g = c + tt * s * 0.15 + UP * 0.02
	var prof = [[0.0, 0.05], [0.04, 0.1], [0.09, 0.125], [0.15, 0.12], [0.2, 0.09], [0.23, 0.04]]
	for i in prof.size() - 1:
		bb.cyl(SM, "wl_globe", g + UP * prof[i][0], prof[i][1], prof[i + 1][1], prof[i + 1][0] - prof[i][0], 12, i == prof.size() - 2, i == 0)
	var l = bb.add_omni(g + UP * 0.12 + tt * s * 0.05, 0.22, 1.8, Color(1.0, 0.86, 0.62))
	bb.tag(l, "", 0.15, 0.25)

## A two-top: dark wood top on a black pedestal, a white spindle-back chair each side.
static func two_top(u, d):
	var c = P(u, 0, d)
	col("#1c1c1e")
	bb.cyl(SM, "vcolor", c, 0.2, 0.2, 0.03, 10, true, false)
	bb.cyl(SM, "vcolor", c, 0.035, 0.035, 0.72, 8, false, false)
	col("#ffffff")
	bx(G, "cf_table", u - 0.36, 0.72, d - 0.32, 0.72, 0.035, 0.64)
	tabletop(c + UP * 0.755, d + u)
	chair(u, d - 0.62, 1.0)
	chair(u, d + 0.62, -1.0)
	ob(u - 0.4, d - 0.85, u + 0.4, d + 0.85, 0.05)

## A white painted chair facing +d (f = 1) or -d: legs, seat, an arched top rail on spindles.
static func chair(u, d, f):
	var fw = -nn * f
	var r = tt
	var c = P(u, 0, d)
	col("#ece8de")
	for q in [Vector2(-0.18, -0.17), Vector2(0.18, -0.17), Vector2(-0.18, 0.17), Vector2(0.18, 0.17)]:
		bb.box(SM, "vcolor", c + r * q.x + fw * q.y + UP * 0.225, Vector3(0.03, 0.45, 0.03))
	bb.box(G, "cf_white", c + UP * 0.47, bb.abs_size(r, 0.42, 0.04, 0.4, nn))
	var bk = c - fw * 0.19
	for k in 5:
		bb.box(SM, "vcolor", bk + r * (-0.16 + k * 0.08) + UP * 0.66, Vector3(0.018, 0.36, 0.018))
	for x in [-0.19, 0.19]:
		bb.box(SM, "vcolor", bk + r * x + UP * 0.7, Vector3(0.03, 0.46, 0.03))
	bb.box(G, "cf_white", bk + UP * 0.9, bb.abs_size(r, 0.44, 0.08, 0.035, nn))
	bb.box(G, "cf_white", bk + UP * 0.96, bb.abs_size(r, 0.26, 0.05, 0.035, nn))
	col("#ffffff")

static func planter(u, d, wu, dd):
	bx(G, "cf_wood", u, 0.0, d, wu, 0.62, dd, ["-y"])
	bx(G, "cf_brown", u - 0.02, 0.62, d - 0.02, wu + 0.04, 0.04, dd + 0.04)
	bb.box(SM, "soil", P(u + wu * 0.5, 0.645, d + dd * 0.5), bb.abs_size(tt, wu - 0.06, 0.01, dd - 0.06, nn), Transform3D.IDENTITY, ["-y"])
	var k = 0
	var x = d + 0.35
	while x < d + dd - 0.2:
		bb.bush(P(u + wu * 0.5, 0.64, x), "leafy", 0.32 + 0.06 * (k % 2), 5)
		x += 0.55
		k += 1
	ob(u, d, u + wu, d + dd, 0.08)

## Two dark wood cabinets with steel tops and label plates: napkins, straws, sauces.
static func island(u, d):
	for k in 2:
		var cu = u + k * 0.82
		bx(G, "cf_wood", cu, 0.0, d, 0.8, 0.92, 0.6, ["-y"])
		bx(G, "wl_steel", cu - 0.01, 0.92, d - 0.01, 0.82, 0.03, 0.62)
		K.fq(bb, SM, "cf_labels", P(cu + 0.4 - 0.13, 0, d), tt, nn, 0.0, 0.26, 0.6, 0.86, 0.004, k * 0.25, 0.0, k * 0.25 + 0.25, 1.0)
		K.fq(bb, SM, "cf_labels", P(cu + 0.4 + 0.13, 0, d + 0.6), -tt, -nn, 0.0, 0.26, 0.6, 0.86, 0.004, 0.5 + k * 0.25, 0.0, 0.75 + k * 0.25, 1.0)
		col("#a8acb0")
		bx(SM, "vcolor", cu + 0.15, 0.95, d + 0.2, 0.2, 0.22, 0.16)
		col("#f2f0ea")
		bb.cyl(SM, "vcolor", P(cu + 0.6, 0.95, d + 0.3), 0.05, 0.05, 0.24, 10, true, false)
	col("#ffffff")
	ob(u, d, u + 1.64, d + 0.6, 0.1)

## A dark brown four-blade ceiling fan on a short down-rod.
static func fan(u, d):
	var c = P(u, CEIL - 0.42, d)
	col("#2c1d14")
	bb.cyl(SM, "vcolor", c + UP * 0.12, 0.012, 0.012, 0.3, 6, false, false)
	bb.cyl(SM, "vcolor", c, 0.1, 0.08, 0.14, 14, true, true)
	for k in 4:
		var ang = PI * 0.5 * k + 0.4
		var dir = Vector3(cos(ang), 0, sin(ang))
		var xf = Transform3D(Basis(dir, UP, dir.cross(UP)), c + dir * 0.45 + UP * 0.03)
		bb.box(SM, "vcolor", Vector3.ZERO, Vector3(0.62, 0.012, 0.13), xf)
	col("#ffffff")

# ------------------------------------------------------------------ materials
## "cf_<key>" (build_mall.gd's mat() calls this).
static func fill_mat(m, key, b):
	match key:
		"fascia":
			m.albedo_color = Color("#c6c8c6"); m.roughness = 0.7
		"maroon":
			m.albedo_color = Color("#4e161a"); m.roughness = 0.6
		"maroon_wall":
			m.albedo_color = Color("#5a181c"); m.roughness = 0.75
		"brown":
			m.albedo_color = Color("#34211a"); m.roughness = 0.55
		"white":
			m.albedo_color = Color("#ece8de"); m.roughness = 0.5
		"wood":
			m.albedo_color = Color("#3c2418"); m.roughness = 0.4; m.metallic_specular = 0.5
		"counter":
			m.albedo_color = Color("#2e1c14"); m.roughness = 0.35; m.metallic_specular = 0.5
		"wainscot":
			m.albedo_color = Color("#3a2318"); m.roughness = 0.45
		"table":
			m.albedo_texture = b.tex("wood_dark.png"); m.roughness = 0.3; m.metallic_specular = 0.6
			m.albedo_color = Color(0.75, 0.6, 0.5)
			m.uv1_triplanar = true; m.uv1_scale = Vector3(1.6, 1.6, 1.6)
		"top":
			m.albedo_color = Color("#e4dccb"); m.roughness = 0.35; m.metallic_specular = 0.5
		"quarry":
			m.albedo_texture = b.tex("cfa/quarry.png"); m.roughness = 0.35; m.metallic_specular = 0.55
		"wallpaper":
			m.albedo_texture = b.tex("cfa/wallpaper.png"); m.roughness = 0.85
		"vinyl":
			m.albedo_texture = b.tex("cfa/vinyl.png"); m.roughness = 0.4; m.metallic_specular = 0.55
			m.uv1_triplanar = true; m.uv1_scale = Vector3(2.5, 2.5, 2.5)
		"prints":
			m.albedo_texture = b.tex("cfa/prints.png"); m.roughness = 0.3; m.metallic_specular = 0.6
		"labels":
			m.albedo_texture = b.tex("cfa/labels.png"); m.roughness = 0.5
		"menu":
			m.albedo_texture = b.tex("cfa/menu.png"); m.roughness = 0.4
			K.emit_tex(m, 0.9)
		"letter":
			m.albedo_color = Color("#fffaf2")
			m.emission_enabled = true; m.emission = Color("#fff4e6"); m.emission_energy_multiplier = 1.4
			m.set_meta("e_day", 1.0); m.set_meta("e_night", 1.4)
		"comb":
			# the C's comb (Nov 1): the chain's red, lit like the letters
			m.albedo_color = Color("#e8202e")
			m.emission_enabled = true; m.emission = Color("#e01828"); m.emission_energy_multiplier = 1.3
			m.set_meta("e_day", 1.0); m.set_meta("e_night", 1.3)
		"letter_ret":
			m.albedo_color = Color("#2a2a2e"); m.roughness = 0.4; m.metallic = 0.3
		"awning":
			m.albedo_color = Color("#d0788c"); m.roughness = 0.55
			m.emission_enabled = true; m.emission = Color("#c06a80"); m.emission_energy_multiplier = 0.35
			m.set_meta("e_day", 0.25); m.set_meta("e_night", 0.35)
		"awning_edge":
			m.albedo_color = Color("#5e1e2c"); m.roughness = 0.6
		"cove":
			m.albedo_color = Color("#fff6ea")
			K.emit(m, Color("#fff0e0"), 2.2)
		"gold":
			m.albedo_color = Color("#c09a3c"); m.metallic = 0.7; m.roughness = 0.3
		"heatglow":
			m.albedo_color = Color("#ffb070")
			K.emit(m, Color("#ff8a40"), 1.6)
		"lemonade":
			m.albedo_color = Color(0.98, 0.92, 0.5, 0.8); m.roughness = 0.1
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_:
			return false
	return true
