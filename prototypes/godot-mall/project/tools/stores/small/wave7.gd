## The Wave 7 shops, all from Southland facade records made from Steven's photos:
## Merry-Go-Round (s47), Champs Sports (s49), Sports Avenue (s8b) and Great American Cookie
## Co. (smuopv1vy0) on the north side; Jean Nicole (s16) on the east hall; Regis
## Hairstylists (s60), Afterthoughts (n56) and Orange Julius (s34) facing south-side halls;
## and the corner jeweller Gordon's (s29). Specs: design/storefronts/merry-go-round.md,
## champs-sports.md, sports-avenue.md, great-american-cookie.md, jean-nicole.md, regis.md,
## afterthoughts.md, orange-julius.md, gordons.md. Insides are period types on the kits;
## layouts are guessed.
##
## Frame: P(a, t, n, u, y, d) = a + t u - n d + y up, u along the frontage, d into the store.

const CH = preload("res://tools/stores/signs/channel.gd")
const K = preload("res://tools/stores/media/kit.gd")
const AK = preload("res://tools/stores/apparel/kit.gd")
const M2 = preload("res://tools/stores/apparel/more.gd")
const S1 = preload("res://tools/stores/small/store.gd")
const S2 = preload("res://tools/stores/small/store2.gd")
const SP = preload("res://tools/stores/small/sports.gd")
const UP = Vector3.UP
const SIDE = 0.12
const LET = "res://tools/stores/small/"

static func P(a, t, n, u, y, d):
	return a + t * u - n * d + Vector3(0, y, 0)

static func probe(b, a, t, n, W, D):
	var rp = ReflectionProbe.new()
	rp.position = P(a, t, n, W * 0.5, 1.6, D * 0.5)
	rp.size = (t * W + n * D).abs() + Vector3(0.1, 3.3, 0.1)
	rp.box_projection = true
	rp.interior = true
	rp.update_mode = ReflectionProbe.UPDATE_ONCE
	rp.intensity = 0.6
	b.light_root.add_child(rp)

static func build(b, g, e, a, bb, n, t, Ln, sd):
	var rng = RandomNumberGenerator.new()
	rng.seed = 700 + int(Ln * 10)
	var W = Ln
	var D = 12.0
	match sd.name:
		"MERRY-GO-ROUND":
			D = 20.0
			merry(b, a, t, n, W, D, rng)
		"JEAN NICOLE":
			D = 24.0
			jean_nicole(b, a, t, n, W, D, rng)
		"CHAMPS SPORTS":
			D = 24.0
			champs(b, a, t, n, W, D, rng)
		"SPORTS AVENUE":
			sports_avenue(b, a, t, n, W, D, rng)
		"GREAT AMERICAN COOKIE CO":
			cookie(b, a, t, n, W, D, rng)
		"REGIS HAIRSTYLISTS":
			D = 16.0
			regis(b, a, t, n, W, D, rng)
		"AFTERTHOUGHTS":
			afterthoughts(b, a, t, n, W, D, rng)
		"ORANGE JULIUS":
			D = 10.0   # moved up into line with Tee Tai's (Steven, Oct 8): 4 m wide, 10 m deep
			orange_julius(b, a, t, n, W, D, rng)
		"GORDON'S JEWELERS":
			if abs(n.x) < 0.5:
				return   # the corner's north edge: built with the west one
			D = 10.0
			gordons(b, a, t, n, W, D, rng)
	probe(b, a, t, n, W, D)

## A clothing store's inside on the apparel kit (more.gd's inside).
static func apparel(b, a, t, n, W, D, c, rng):
	M2.shell2(b, c.get("group", "w7_shell"), a, t, n, W, D, 3.2, 0.0, c.floor, 1.0, c.wall, "kb_ceiling", c.rows, c.door)
	M2.inside(b, a, t, n, W, D, c, rng)

# ------------------------------------------------------------------ Merry-Go-Round
## A gloss-black fascia with fat round tube letters, MERRY red, GO yellow, ROUND green;
## dark-framed windows either side, a bright open front: sunset stripes on the wall, rails of
## jackets and tops, a round rack of striped shirts out front, sale boards (record).
static func merry(b, a, t, n, W, D, rng):
	var F = "w7mf_props"
	var head = 2.8
	S1.upper(b, F, a, t, n, W, head, "w7_gloss_black", 0.18)
	var parts = [["mgr_merry.json", 2.151, "w7_tube_red"], ["mgr_go.json", 0.934, "w7_tube_yellow"], ["mgr_round.json", 2.3, "w7_tube_green"]]
	var total = 2.151 + 0.934 + 2.3 + 0.5
	var rv = (-n).cross(UP)
	for k in parts.size():
		var p = parts[k]
		# kit letters are centred on c along the viewer's right (rv)
		var cc = P(a, t, n, W * 0.5, head + 0.42, -0.18) + rv * (-total * 0.5 + p[1] * 0.5 + (0.0 if k == 0 else (2.151 + 0.25 if k == 1 else 2.151 + 0.934 + 0.5)))
		AK.letters(b, F, LET + p[0], cc, n, p[2], p[2], 0.02, 0.08)
	var rng2 = RandomNumberGenerator.new()
	M2.windows(b, F, a, t, n, 0.1, 2.2, head, "ap_black", "ap_black", rng2, ["#c83a3a", "#2e2e34", "#e8c040"])
	# the form in the right-hand window is the one the Rougarou takes the place of (Steven, Oct 15:
	# scripts/rougarou_ai.gd story mode), so it is its own mesh, dyn_rg_mannequin, the game hides
	M2.windows(b, F, a, t, n, W - 2.2, W - 0.1, head, "ap_black", "ap_black", rng2, ["#3a7a4a", "#e8e2d2", "#2e3a5c"], 0, "rg_mannequin")
	M2.soffit(b, F, a, t, n, W, head, "ap_black")
	var c = {"cash": "right", "seed": 47, "slat": "gb_slat_black", "door": 7.0, "fit": 2, "cols": [4.0], "cards": [9, 10, 11], "floor": "ap_wood", "wall": "ap_cream", "rows": [1.6, 5.6]}
	apparel(b, a, t, n, W, D, c, rng)
	# the sunset stripes high on the back wall
	K.fq(b, "w7_shell", "w7_sunset", P(a, t, n, W - SIDE, 0, D - SIDE - 0.01), -t, n, 0.0, W - 2 * SIDE, 2.2, 3.15, 0.0, 0.0, 0.0, 1.0, 0.6)

# ------------------------------------------------------------------ Jean Nicole
## A rust-red fascia with the name in fat white brush script and a yellow dot over the i; a
## mirrored soffit; a red shop on red carpet: round racks of pastel blouses, maroon sale cards,
## forms in pastel suits up on the fixtures (record).
static func jean_nicole(b, a, t, n, W, D, rng):
	var F = "w7jf_props"
	var head = 2.8
	S1.upper(b, F, a, t, n, W, head, "w7_rust", 0.2)
	var cc = P(a, t, n, W * 0.5, head + 0.42, -0.2)
	AK.letters(b, F, LET + "jn_letters.json", cc, n, "ap_letterwhite", "ap_letterwhite", 0.0, 0.05)
	# the yellow dot over the i (Jean Nicole: the i is the 8th glyph; placed by eye)
	var rv = (-n).cross(UP)
	b.cyl(F, "w7_dot", cc + rv * 0.62 + UP * 0.6 - n * 0.0 + n * 0.06, 0.06, 0.06, 0.04, 12, true, false, true)
	b.quad(F, "w7_mirror", [P(a, t, n, 0, head, 0), P(a, t, n, W, head, 0), P(a, t, n, W, head, 1.0), P(a, t, n, 0, head, 1.0)], Vector3.DOWN)
	b.quad("w7j_shell", "ap_cream", [P(a, t, n, SIDE, head, 1.0), P(a, t, n, W - SIDE, head, 1.0), P(a, t, n, W - SIDE, 3.2, 1.0), P(a, t, n, SIDE, 3.2, 1.0)], -n)
	var rng2 = RandomNumberGenerator.new()
	M2.windows(b, F, a, t, n, 0.1, 3.2, head, "w7_rust", "w7_rust", rng2, ["#f0c8d8", "#c8e0f0", "#f6e8b8"])
	M2.windows(b, F, a, t, n, W - 3.2, W - 0.1, head, "w7_rust", "w7_rust", rng2, ["#d8f0d8", "#f0c8d8", "#e8d8f0"])
	var c = {"group": "w7j_shell", "cash": "left", "seed": 16, "slat": "gb_slat_white", "door": 9.0, "fit": 3, "cols": [3.4, 6.6], "cards": [0, 1, 13], "floor": "s6_red_carpet", "wall": "w7_rose_wall", "rows": [1.8, 7.6]}
	apparel(b, a, t, n, W, D, c, rng)

# ------------------------------------------------------------------ Champs Sports
## A smooth white portal with the navy badge outlined in red, cream serif capitals and SPORTS
## in its lower lobe; a royal-blue soffit with downlights; the blue WE KNOW GAME panel on a
## grey block plinth; a dark ceiling, a slat-wood back wall of hung tops, a mannequin at the
## glass, a wall of trainers on the right (record).
static func champs(b, a, t, n, W, D, rng):
	var F = "w7cf_props"
	var head = 2.8
	# Steven's sign pass (Oct 7: design/storefronts/photos/champs-sports): the blue badge logo
	# (photos 03, 04) in 3D on the polished-steel framed front of photos 01, 02
	S1.upper(b, F, a, t, n, W, head, "sg_cs_fascia", 0.16)
	b.box(F, "sg_cs_steel", P(a, t, n, W * 0.5, head + 0.1, -0.2), b.abs_size(t, W, 0.2, 0.08, n))
	var bc = P(a, t, n, W * 0.5, head + 0.28, -0.3)
	CH.build(b, "w7cf_sign", "res://tools/stores/signs/cs_rim_logo.json", bc - UP * 0.06, n, "sg_cs_red", "sg_cs_red", "", 0.0, 0.1, 0.0)
	CH.build(b, "w7cf_sign", "res://tools/stores/signs/cs_badge_logo.json", bc, n, "sg_cs_blue", "sg_cs_blue", "", 0.0, 0.115, 0.0)
	CH.build(b, "w7cf_sign", "res://tools/stores/signs/cs_name_logo.json", bc, n, "sg_cs_cream", "sg_cs_red", "", 0.115, 0.03, 0.0, "sg_cs_glow")
	CH.build(b, "w7cf_sign", "res://tools/stores/signs/cs_sub_logo.json", bc, n, "sg_cs_red", "sg_cs_red", "", 0.115, 0.012, 0.0)
	for u in [W * 0.5 - 1.3, W * 0.5, W * 0.5 + 1.3]:
		b.cyl(F, "sg_cs_navy", P(a, t, n, u, head + 1.36, -0.36), 0.025, 0.025, b.LANE_H - head - 1.36, 8, false, false)
	# polished steel piers, glass in steel frames either side of the open middle
	for s in [[0.0, 0.5], [W - 0.5, W]]:
		b.box(F, "sg_cs_steel", P(a, t, n, (s[0] + s[1]) * 0.5, head * 0.5, -0.1), b.abs_size(t, s[1] - s[0], head, 0.2, n), Transform3D.IDENTITY, ["-y"])
		K.ob(b, P(a, t, n, s[0], 0, -0.2), P(a, t, n, s[1], 0, 0.0), 0.05)
	for s in [[0.5, 3.6], [W - 3.6, W - 0.5]]:
		b.quad("glass", "glass", [P(a, t, n, s[0], 0.08, -0.04), P(a, t, n, s[1], 0.08, -0.04), P(a, t, n, s[1], head, -0.04), P(a, t, n, s[0], head, -0.04)], n,
			[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)], true)
		var inner = s[1] if s[0] < 1.0 else s[0]
		b.box(F, "sg_cs_steel", P(a, t, n, inner, head * 0.5, -0.06), b.abs_size(t, 0.22, head, 0.16, n), Transform3D.IDENTITY, ["-y"])
		b.box(F, "sg_cs_steel", P(a, t, n, (s[0] + s[1]) * 0.5, 0.04, -0.04), b.abs_size(t, s[1] - s[0], 0.08, 0.08, n), Transform3D.IDENTITY, ["-y"])
		K.ob(b, P(a, t, n, s[0], 0, -0.2), P(a, t, n, s[1], 0, 0.05), 0.05)
	# the WE KNOW GAME panel on a grey block plinth, left of the doors
	b.box(F, "w7_grey_block", P(a, t, n, 1.6, 0.35, 0.3), b.abs_size(t, 2.0, 0.7, 0.4, n), Transform3D.IDENTITY, ["-y"])
	b.box(F, "w7_navy", P(a, t, n, 1.6, 1.4, 0.3), b.abs_size(t, 2.0, 1.4, 0.06, n), Transform3D.IDENTITY, [])
	K.ob(b, P(a, t, n, 0.6, 0, 0.1), P(a, t, n, 2.6, 0, 0.5), 0.05)
	AK.mannequin(b, P(a, t, n, 3.2, 0.0, 0.8), -n, "#2aa8a0", "#2e2e34")
	M2.soffit(b, F, a, t, n, W, head, "sg_cs_steel")
	# the inside: sports stock, seen through the glass; not walkable yet (Steven, Oct 7)
	M2.shell2(b, "w7c_shell", a, t, n, W, D, 3.2, 0.0, "a2_carpet_grey", 1.0, "md_wall", "kb_ceiling", [2.0, 6.0, 9.4], 11.0)
	SP.inside(b, "w7c_fix", a, t, n, W, D, 3.2, rng)

# ------------------------------------------------------------------ Sports Avenue
## The front hangs off a gold goalpost: a red padded post at the door, a goose-neck up to the
## crossbar, uprights past the sign with red flags; a gold marquee of white bulbs with SPORTS
## in red and a star at each corner; AVENUE in gold capitals on a rail against blue; behind the
## glass, jerseys pinned in a grid, forms in hoods and shorts (record).
static func sports_avenue(b, a, t, n, W, D, rng):
	var F = "w7sf_props"
	var head = 2.7
	S1.upper(b, F, a, t, n, W, head, "w7_royal", 0.12)
	var rv = (-n).cross(UP)
	# Steven's sign pass (Oct 7: design/storefronts/photos/sports-avenue): the marquee as the photos
	# show it, a scoreboard: a black grid of round lamps in a gold trapezoid frame, the red ones
	# spelling SPORTS, the rest white; white stars on the frame; AVENUE in gold on a rail below
	var mu = W * 0.5
	var mb = head + 0.25
	var fr = P(a, t, n, mu, mb, -0.3)
	CH.build(b, F, "res://tools/stores/signs/sa_frame_logo.json", fr, n, "w7_gold", "w7_gold", "", 0.0, 0.32, 0.0)
	sa_scoreboard(b, P(a, t, n, mu, mb + 0.175, -0.3) + n * 0.22, n)
	for sx in [-1.0, 1.0]:
		CH.build(b, "w7sf_sign", "res://tools/stores/signs/sa_star_logo.json", P(a, t, n, mu + sx * 1.74, mb + 0.54, -0.3) + n * 0.325, n, "sg_sa_lamp_white", "w7_gold", "", 0.0, 0.02, 0.0)
	AK.letters(b, F, LET + "avenue_letters.json", P(a, t, n, mu, mb - 0.2, -0.3), n, "w7_gold", "w7_gold", 0.0, 0.04)
	b.box(F, "w7_gold", P(a, t, n, mu, mb - 0.24, -0.25), b.abs_size(t, 2.6, 0.04, 0.05, n))
	# the goalpost, centred on the front: the crossbar right across it, an upright at each end
	# with a pennant, and the red padded post at the middle joined to the crossbar by a gooseneck
	var cy = 2.5
	var cd = -0.42
	b.box(F, "w7_gold", P(a, t, n, mu, cy, cd), b.abs_size(t, W - 0.5, 0.11, 0.11, n))
	for x in [0.25, W - 0.25]:
		var u0 = P(a, t, n, x, 0, cd)
		b.box(F, "w7_gold", u0 + UP * ((cy + b.LANE_H) * 0.5), b.abs_size(t, 0.1, b.LANE_H - cy, 0.1, n))
		var fl = u0 + UP * (b.LANE_H - 0.42)
		var rr = t if x > W * 0.5 else -t
		var sf = b.st(F, "w7_red", true)
		b.tri(sf, fl, fl + UP * 0.28, fl + UP * 0.14 + rr * 0.34, Vector2(0, 0), Vector2(0, 0), Vector2(0, 0), n)
		b.tri(sf, fl, fl + UP * 0.14 + rr * 0.34, fl + UP * 0.28, Vector2(0, 0), Vector2(0, 0), Vector2(0, 0), -n)
	# (the post stands out in the hall in front of the window; the bend carries the pipe back to the bar)
	var pb = P(a, t, n, mu, 0, -1.15)
	var tb = P(a, t, n, mu, 0, cd)
	var tw = (tb - pb).normalized()
	var r = pb.distance_to(tb)
	b.cyl(F, "w7_red", pb, 0.14, 0.14, 1.65, 18, true, false)
	b.cyl(F, "w7_gold", pb + UP * 1.65, 0.055, 0.055, cy - r - 1.65, 12, false, false)
	var c0 = pb + UP * (cy - r) + tw * r
	var prev = pb + UP * (cy - r)
	for i in range(1, 13):
		var ang = PI * 0.5 * i / 12.0
		var q = c0 - tw * (r * cos(ang)) + UP * (r * sin(ang))
		_pipe(b, F, prev, q, 0.055)
		prev = q
	K.ob(b, pb - t * 0.16 - n * 0.16, pb + t * 0.16 + n * 0.16, 0.05)
	# glass with jerseys behind it to the right of the post, the entrance to its left
	var g0 = mu + 0.3
	b.quad("glass", "glass", [P(a, t, n, g0, 0.4, -0.02), P(a, t, n, W - 0.1, 0.4, -0.02), P(a, t, n, W - 0.1, head, -0.02), P(a, t, n, g0, head, -0.02)], n,
		[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)], true)
	b.box(F, "w7_royal", P(a, t, n, (g0 + W - 0.1) * 0.5, 0.2, 0.0), b.abs_size(t, W - 0.1 - g0, 0.4, 0.1, n), Transform3D.IDENTITY, ["-y"])
	b.box(F, "w7_royal", P(a, t, n, g0, head * 0.5, -0.02), b.abs_size(t, 0.06, head, 0.08, n))
	K.ob(b, P(a, t, n, g0, 0, -0.1), P(a, t, n, W, 0, 0.1), 0.05)
	M2.shell2(b, "w7s_shell", a, t, n, W, D, 3.0, 0.0, "a2_carpet_grey", 1.0, "md_wall", "kb_ceiling", [1.6, 4.0], 5.0)
	# the inside: sports stock, seen through the glass; not walkable yet (Steven, Oct 7)
	SP.inside(b, "w7s_fix", a, t, n, W, D, 3.0, rng, {"d0": 1.2, "first": 3.0})

## A gold pipe from p to q.
static func _pipe(b, F, p, q, r):
	var d = q - p
	var L = d.length()
	if L < 0.001:
		return
	var y = d / L
	var x = y.cross(Vector3.FORWARD if abs(y.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT).normalized()
	var z = x.cross(y)
	b.box(F, "w7_gold", Vector3.ZERO, Vector3(r * 2.0, L + r, r * 2.0), Transform3D(Basis(x, y, z), (p + q) * 0.5))

## The SPORTS scoreboard: c the field's lower middle on its face, facing nn; 52 x 15 round lamps
## (tools/stores/signs/sa_dots.json) on a black board with a dark grid between them.
static func sa_scoreboard(b, c, nn):
	var J = JSON.parse_string(FileAccess.get_file_as_string("res://tools/stores/signs/sa_dots.json"))
	var cols = int(J.cols)
	var rows = int(J.rows)
	var fw = 3.1
	var fh = 0.95
	var px = fw / cols
	var py = fh / rows
	var r = (-nn).cross(UP)
	var o = c - r * (fw * 0.5)
	b.box("w7sf_sign", "sg_sa_board", o + r * (fw * 0.5) + UP * (fh * 0.5) - nn * 0.01, b.abs_size(r, fw, fh, 0.02, nn), Transform3D.IDENTITY, [], true)
	for k in cols + 1:
		b.box("w7sf_sign", "sg_sa_grid", o + r * (k * px) + UP * (fh * 0.5) + nn * 0.004, b.abs_size(r, 0.006, fh, 0.008, nn), Transform3D.IDENTITY, [], true)
	for k in rows + 1:
		b.box("w7sf_sign", "sg_sa_grid", o + r * (fw * 0.5) + UP * (k * py) + nn * 0.004, b.abs_size(r, fw, 0.006, 0.008, nn), Transform3D.IDENTITY, [], true)
	var rad = min(px, py) * 0.4
	var seg = 10
	var sw = b.st("w7sf_sign", "sg_sa_lamp_white", true)
	var sr = b.st("w7sf_sign", "sg_sa_lamp_red", true)
	for row in rows:
		var line = str(J.red[rows - 1 - row])
		for col in cols:
			var s = sr if line[col] == "1" else sw
			var cc = o + r * ((col + 0.5) * px) + UP * ((row + 0.5) * py) + nn * 0.012
			for i in seg:
				var a0 = TAU * i / seg
				var a1 = TAU * (i + 1) / seg
				var p0 = cc + (r * cos(a0) + UP * sin(a0)) * rad
				var p1 = cc + (r * cos(a1) + UP * sin(a1)) * rad
				b.tri(s, cc + nn * 0.006, p0, p1, Vector2(0.5, 0.5), Vector2(0.5, 0.5), Vector2(0.5, 0.5), nn)
				b.tri(s, p0 - nn * 0.012, p1 - nn * 0.012, p1, Vector2(0.5, 0.5), Vector2(0.5, 0.5), Vector2(0.5, 0.5), (p0 + p1 - cc * 2.0).normalized())
				b.tri(s, p0 - nn * 0.012, p1, p0, Vector2(0.5, 0.5), Vector2(0.5, 0.5), Vector2(0.5, 0.5), (p0 + p1 - cc * 2.0).normalized())

# ------------------------------------------------------------------ Great American Cookie Co.
## A cream sign box with maroon checkerboard corners, 'Great American' in yellow script on a
## maroon lobe over a black pill of white capitals; warm downlights, a row of back-lit menu
## pictures, white tile with a red check course, the glass case of cookies (record).
static func cookie(b, a, t, n, W, D, rng):
	var F = "w7kf_props"
	var G = "w7k_fix"
	var head = 2.7
	S1.upper(b, F, a, t, n, W, head, "w7_white_tile", 0.12)
	# the sign (Steven, Oct 7: his photo of a Great American Cookie Co. mall store): a black fascia
	# with red-and-white checkerboard stepping down from its top corners, "Great American" in red
	# neon script over COOKIE CO. in white lit capitals, all 3D
	var LH = b.LANE_H
	b.box(F, "sg_gac_black", P(a, t, n, W * 0.5, (head + 0.1 + LH) * 0.5, -0.2), b.abs_size(t, W, LH - head - 0.1, 0.16, n), Transform3D.IDENTITY, ["-y"])
	var rv = (-n).cross(UP)
	var sq = 0.15   # the checker squares
	for side in [0, 1]:
		for step in [[0.0, 1.5, 0], [0.0, 0.75, 1]]:
			var x0 = step[0] if side == 0 else W - step[1]
			var x1 = step[1] if side == 0 else W - step[0]
			var y1 = LH - 0.04 - step[2] * 0.3
			var y0 = y1 - 0.3
			var o = P(a, t, n, x0, 0, -0.281)
			K.fq(b, "w7kf_sign", "sg_gac_check", o, t, n, 0.0, x1 - x0, y0, y1, 0.0, 0.0, 0.0, (x1 - x0) / (sq * 8.0), 0.3 / (sq * 8.0), true)
	CH.build(b, "w7kf_sign", "res://tools/stores/signs/gac_script_logo.json", P(a, t, n, W * 0.5, head + 0.98, -0.28), n, "sg_gac_neon", "sg_gac_neon_ret", "", 0.03, 0.03, 0.0, "sg_gac_glow")
	CH.build(b, "w7kf_sign", "res://tools/stores/signs/gac_name_logo.json", P(a, t, n, W * 0.5, head + 0.3, -0.28), n, "sg_gac_white", "sg_gac_white_ret", "", 0.02, 0.07, 0.0, "sg_gac_name_glow")
	M2.shell2(b, "w7k_shell", a, t, n, W, D, 3.0, 0.0, "wl_floor", 1.22, "w7_white_tile", "kb_ceiling", [1.6, 4.0], 1.0)
	M2.soffit(b, F, a, t, n, W, head, "w7_cream")
	# the red check course round the walls at counter height
	for w in [[SIDE + 0.01, t], [W - SIDE - 0.01, -t]]:
		var p0 = P(a, t, n, w[0], 1.0, 0.8)
		var p1 = P(a, t, n, w[0], 1.0, D - 0.2)
		b.quad(G, "w7_check", [p0, p1, p1 + UP * 0.15, p0 + UP * 0.15], w[1], [Vector2(0, 0), Vector2((D - 1.0) / 0.3, 0), Vector2((D - 1.0) / 0.3, 1), Vector2(0, 1)])
	# ws/g: the glass case is Great American Cookies' own, the same in 1995 and 2026 (Steven, Oct 28;
	# tools/stores/gac/case.gd), across the shop from 2.6 m in; the register on its back ledge
	var co = P(a, t, n, 0.6, 0, 2.6)
	load("res://tools/stores/gac/case.gd").case_run(b, G, "w7k_small", co, t, -n, W - 1.2)
	K.register(b, "w7k_small", K.L(co, t, -n, W - 1.9, 1.33, 0.82), t, n)
	K.ob(b, P(a, t, n, SIDE, 0, 2.6), P(a, t, n, 0.6, 0, 3.4), 0.0)
	K.ob(b, P(a, t, n, W - 0.6, 0, 2.6), P(a, t, n, W - SIDE, 0, 3.4), 0.0)
	K.lbox(b, G, "wl_steel", P(a, t, n, W - 0.4, 0, D - SIDE), -t, n, 0.0, 0.0, 0.0, W - 0.8, 1.4, 0.7)
	for k in 3:
		K.fq(b, G, "sm_cards", P(a, t, n, W - 0.5, 0, D - SIDE), -t, n, k * 1.7, k * 1.7 + 1.5, 1.8, 2.6, 0.72, k * 0.25, 0.75, k * 0.25 + 0.25, 1.0)
	K.ob(b, P(a, t, n, SIDE, 0, 3.4), P(a, t, n, W - SIDE, 0, D - SIDE), 0.0)

# ------------------------------------------------------------------ Regis
## Honed travertine with a black cornice, triple black stripes banding the piers, a black
## plinth, the name in heavy black letters with light spilling round them; a tall window on
## a salon floor of black chairs and mirrors, the open reception with its maple desk, walls of
## bottles (record).
static func regis(b, a, t, n, W, D, rng):
	var F = "w7rf_props"
	var G = "w7r_fix"
	var head = 2.9
	S1.upper(b, F, a, t, n, W, head, "w7_travertine", 0.2)
	b.box(F, "md_black", P(a, t, n, W * 0.5, b.LANE_H - 0.12, -0.25), b.abs_size(t, W, 0.24, 0.1, n))
	b.quad(F, "w7_halo", [P(a, t, n, 1.8, head + 0.25, -0.205), P(a, t, n, W - 1.8, head + 0.25, -0.205), P(a, t, n, W - 1.8, head + 0.95, -0.205), P(a, t, n, 1.8, head + 0.95, -0.205)], n)
	AK.letters(b, F, LET + "regis_letters.json", P(a, t, n, W * 0.5, head + 0.38, -0.2), n, "md_black", "md_black", 0.06, 0.06)
	for s in [[0.0, 0.6], [W - 0.6, W]]:
		var cu = (s[0] + s[1]) * 0.5
		b.box(F, "w7_travertine", P(a, t, n, cu, head * 0.5, -0.1), b.abs_size(t, s[1] - s[0], head, 0.2, n), Transform3D.IDENTITY, ["-y"])
		for y in [1.6, 1.75, 1.9]:
			b.box(F, "md_black", P(a, t, n, cu, y, -0.205), b.abs_size(t, s[1] - s[0], 0.06, 0.01, n))
		K.ob(b, P(a, t, n, s[0], 0, -0.2), P(a, t, n, s[1], 0, 0.0), 0.05)
	b.box(F, "md_black", P(a, t, n, 2.8, 0.25, -0.05), b.abs_size(t, 4.4, 0.5, 0.12, n), Transform3D.IDENTITY, ["-y"])
	b.quad("glass", "glass", [P(a, t, n, 0.6, 0.5, -0.03), P(a, t, n, 5.0, 0.5, -0.03), P(a, t, n, 5.0, head, -0.03), P(a, t, n, 0.6, head, -0.03)], n,
		[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)], true)
	K.ob(b, P(a, t, n, 0.6, 0, -0.12), P(a, t, n, 5.0, 0, 0.1), 0.05)
	M2.shell2(b, "w7r_shell", a, t, n, W, D, 3.0, 0.0, "md_vinyl", 0.61, "md_wall", "kb_ceiling", [2.0, 5.6], 7.0)
	# the reception: a maple desk by the door, portraits behind it
	K.counter(b, G, "w7r_small", P(a, t, n, W - 0.8, 0, 1.6), -n, -t, 1.6, "w7_maple", rng, 1.0, 0.55)
	# walls of bottles on the right, black chairs and mirrors on the left
	for k in 3:
		K.bay(b, G, G, P(a, t, n, W - SIDE, 0, 3.6 + k * 1.22), -n, -t, 1.22, [0.6, 0.95, 1.3, 1.65], ["hba"], rng, 0.25)
	K.ob(b, P(a, t, n, W - SIDE, 0, 3.6), P(a, t, n, W - SIDE - 0.3, 0, 7.3), 0.05)
	for k in 4:
		var d = 1.8 + k * 1.5
		var o = P(a, t, n, SIDE, 0, d + 1.3)
		K.lbox(b, G, "md_black", o, n, t, 0.1, 0.0, 0.0, 1.1, 0.8, 0.4)
		b.quad(G, "ap_mirror", [K.L(o, n, t, 0.15, 0.95, 0.01), K.L(o, n, t, 1.15, 0.95, 0.01), K.L(o, n, t, 1.15, 2.05, 0.01), K.L(o, n, t, 0.15, 2.05, 0.01)], t)
		var cc = K.L(o, n, t, 0.65, 0.0, 1.0)
		b.cur_color = Color("#1a1a1c")
		b.cyl("w7r_small", "vcolor", cc, 0.27, 0.23, 0.06, 14, true, false)
		b.cyl("w7r_small", "vcolor", cc, 0.05, 0.05, 0.45, 8, false, false)
		b.box("w7r_small", "vcolor", cc + UP * 0.52, Vector3(0.5, 0.12, 0.5))
		b.box("w7r_small", "vcolor", cc - t * 0.22 + UP * 0.85, b.abs_size(n, 0.48, 0.6, 0.1, t))
		b.cur_color = Color.WHITE
		K.ob(b, cc - Vector3(0.3, 0, 0.3), cc + Vector3(0.3, 0, 0.3), 0.05)
	K.ob(b, P(a, t, n, SIDE, 0, 1.9), P(a, t, n, SIDE + 0.5, 0, 8.0), 0.05)

# ------------------------------------------------------------------ Afterthoughts
## Mauve mosaic tile, raised pink speed-lines, thin white lower-case letters, round and airy,
## a wide open front onto warm slatwall hung with bags, a spinner of earring cards (record).
static func afterthoughts(b, a, t, n, W, D, rng):
	var F = "w7af_props"
	var G = "w7a_fix"
	var head = 2.8
	S1.upper(b, F, a, t, n, W, head, "w7_mosaic", 0.14)
	for y in [head + 1.05, head + 1.13, head + 1.21]:
		b.box(F, "w7_pink", P(a, t, n, W * 0.5, y, -0.16), b.abs_size(t, W - 0.4, 0.03, 0.04, n))
	AK.letters(b, F, LET + "at_letters.json", P(a, t, n, W * 0.5, head + 0.4, -0.14), n, "ap_letterwhite", "ap_letterwhite", 0.0, 0.03)
	M2.shell2(b, "w7a_shell", a, t, n, W, D, 3.0, 0.0, "a2_carpet_mauve", 1.0, "w7_rose_wall", "kb_ceiling", [1.7], 1.0)
	M2.soffit(b, F, a, t, n, W, head, "w7_mosaic")
	S1.side_bays(b, G, a, t, n, W, 1.0, D - 2.0, ["acc", "gifts"], ["gifts", "acc"], rng, "w7_warm_slat", [0.5, 0.9, 1.3, 1.7], 0.3)
	# a spinner of earring cards in the middle
	var sc = P(a, t, n, W * 0.5, 0, 3.0)
	b.cyl(G, "md_chrome", sc, 0.2, 0.2, 0.03, 12, true, false)
	b.cyl(G, "md_chrome", sc, 0.02, 0.02, 1.7, 8, false, false)
	for k in 4:
		var f = Vector3(cos(k * PI * 0.5), 0, sin(k * PI * 0.5))
		var r = (-f).cross(UP)
		K.stock_row(b, G, sc - r * 0.2 + f * 0.04, r, f, 0.0, 0.4, 0.5, 0.3, 0.0, "acc", rng)
		K.stock_row(b, G, sc - r * 0.2 + f * 0.04, r, f, 0.0, 0.4, 0.85, 0.3, 0.0, "acc", rng)
		K.stock_row(b, G, sc - r * 0.2 + f * 0.04, r, f, 0.0, 0.4, 1.2, 0.3, 0.0, "acc", rng)
	K.ob(b, sc - Vector3(0.3, 0, 0.3), sc + Vector3(0.3, 0, 0.3), 0.05)
	K.counter(b, G, "w7a_small", P(a, t, n, W - 0.5, 0, D - 1.8), -t, n, W - 1.0, "md_bb_counter", rng)

# ------------------------------------------------------------------ Orange Julius
## Cream tile, a raised sign board with the name in looping orange neon, a course of red tiles
## set with black diamonds; inside, pale walls with framed prints, the tiled counter under
## black menu light-boxes with the kitchen's steel behind, a dark red floor (record).
static func orange_julius(b, a, t, n, W, D, rng):
	var F = "w7of_props"
	var G = "w7o_fix"
	var head = 2.7
	S1.upper(b, F, a, t, n, W, head, "w7_cream_tile", 0.12)
	b.box(F, "w7_cream", P(a, t, n, W * 0.5, head + 0.85, -0.18), b.abs_size(t, min(W - 0.3, max(W - 1.0, 3.5)), 1.0, 0.12, n))
	AK.neon(b, F, LET + "oj_letters.json", P(a, t, n, W * 0.5, head + 0.62, -0.24), n, "w7_neon_orange", 0.02, 0.016, 0.02)
	K.fq(b, F, "w7_diamonds", P(a, t, n, W, 0, 0), -t, n, 0.0, W, head + 0.05, head + 0.2, 0.125, 0.0, 0.0, W / 0.6, 1.0)
	M2.shell2(b, "w7o_shell", a, t, n, W, D, 3.0, 0.0, "s6_red_tile", 0.61, "w7_cream", "kb_ceiling", [1.6, 4.0], 1.0)
	M2.soffit(b, F, a, t, n, W, head, "w7_cream_tile")
	# the tiled counter across the shop, the menu light-boxes and the kitchen's steel behind
	var co = P(a, t, n, W - 0.6, 0, 2.4)
	K.lbox(b, G, "w7_cream_tile", co, -t, n, 0.0, 0.0, -0.7, W - 1.2, 1.0, 0.7, ["-y"])
	K.fq(b, G, "w7_diamonds", co, -t, n, 0.0, W - 1.2, 0.8, 0.95, 0.002, 0.0, 0.0, (W - 1.2) / 0.6, 1.0)
	K.register(b, "w7o_small", K.L(co, -t, n, 1.0, 1.0, -0.6), -t, n)
	K.ob_local(b, co, -t, n, 0.0, -0.7, W - 1.2, 0.0)
	K.ob(b, P(a, t, n, SIDE, 0, 1.7), P(a, t, n, 0.6, 0, 2.4), 0.0)
	K.ob(b, P(a, t, n, W - 0.6, 0, 1.7), P(a, t, n, W - SIDE, 0, 2.4), 0.0)
	K.lbox(b, G, "wl_steel", P(a, t, n, W - 0.4, 0, D - SIDE), -t, n, 0.0, 0.0, 0.0, W - 0.8, 1.0, 0.7)
	for k in clampi(int((W - 1.0) / 1.6), 1, 3):
		K.lbox(b, G, "md_black", P(a, t, n, W - 0.6, 0, D - SIDE), -t, n, k * 1.6, 1.8, 0.0, 1.5, 0.8, 0.08)
		K.fq(b, G, "sm_cards", P(a, t, n, W - 0.6, 0, D - SIDE), -t, n, k * 1.6 + 0.05, k * 1.6 + 1.45, 1.85, 2.55, 0.082, k * 0.25, 0.75, k * 0.25 + 0.25, 1.0)
	K.ob(b, P(a, t, n, SIDE, 0, 2.4), P(a, t, n, W - SIDE, 0, D - SIDE), 0.0)
	# framed prints on the pale side walls
	K.fq(b, G, "wl_food_photos", P(a, t, n, SIDE, 0, 1.6), n, t, 0.0, 1.2, 1.5, 1.8, 0.01, 0.0, 0.0, 0.5, 1.0)

# ------------------------------------------------------------------ Gordon's Jewelers
## A dark bronze header holding a row of back-lit frosted panels crossed by one long arch, the
## name on the centre panel; under it an open front onto a dim taupe room hung with framed
## pictures under track lights, lit glass cases on a dark mahogany base (record). A corner shop:
## open to the west hall and, at u = W, to the south.
static func gordons(b, a, t, n, W, D, rng):
	var F = "w7gf_props"
	var G = "w7g_fix"
	var head = 2.8
	S1.upper(b, F, a, t, n, W, head, "w7_bronze", 0.2)
	# Steven's sign pass (Oct 7: design/storefronts/photos/gordons): a lit white transom framed in
	# cherry with arched muntins, "Gordon's / JEWELERS" in black over it, on both faces
	gordons_sign(b, F, P(a, t, n, W * 0.5, 0, -0.2), n, W - 0.6, head)
	# the other front: the bronze header round the corner
	var e0 = P(a, t, n, W, 0, 0)
	b.box(F, "w7_bronze", e0 - n * (D * 0.5) + UP * ((head + b.LANE_H) * 0.5) + t * 0.1, b.abs_size(-n, D, b.LANE_H - head, 0.2, t))
	gordons_sign(b, F, e0 - n * (D * 0.5) + t * 0.2, t, D - 0.6, head)
	b.box(F, "w7_bronze", P(a, t, n, 0.2, head * 0.5, 0.0), b.abs_size(t, 0.4, head, 0.4, n), Transform3D.IDENTITY, ["-y"])
	b.box(F, "w7_bronze", P(a, t, n, W - 0.2, head * 0.5, D - 0.2), b.abs_size(t, 0.4, head, 0.4, n), Transform3D.IDENTITY, ["-y"])
	b.box(F, "w7_bronze", P(a, t, n, W - 0.2, head * 0.5, 0.2), b.abs_size(t, 0.4, head, 0.4, n), Transform3D.IDENTITY, ["-y"])
	K.ob(b, P(a, t, n, W - 0.4, 0, 0.0), P(a, t, n, W, 0, 0.4), 0.05)
	M2.shell2(b, "w7g_shell", a, t, n, W, D, 3.0, 0.0, "w7_taupe_carpet", 1.0, "w7_taupe", "kb_ceiling", [2.0, 5.6], 1.0, 1.0, true)
	M2.soffit(b, F, a, t, n, W, head, "w7_bronze")
	for cs in [[P(a, t, n, SIDE, 0, D - 0.6), n, t, D - 2.0], [P(a, t, n, W - 1.0, 0, D - SIDE), -t, n, W - 2.4], [P(a, t, n, 5.0, 0, 3.0), -n, t, 2.4]]:
		S2.jewel_case(b, G, cs[0], cs[1], cs[2], cs[3])
	S2.jewel_case(b, G, P(a, t, n, 4.4, 0, 5.4), n, -t, 2.4)
	# framed pictures on the dim walls under track lights
	for k in 3:
		K.fq(b, G, "wl_food_photos", P(a, t, n, SIDE, 0, 2.6 + k * 2.6), n, t, 0.0, 0.6, 1.6, 2.2, 0.62, (k % 4) * 0.25, 0.0, (k % 4) * 0.25 + 0.25, 1.0)
	var l = b.add_omni(P(a, t, n, W * 0.5, 2.6, D * 0.5), 0.3, 6.0, Color(1.0, 0.9, 0.78))
	b.tag(l, "", 0.3, 0.4)

## Gordon's transom on one face: c the foot's middle on the fascia, w wide, 1.0 m tall from head + 0.25.
static func gordons_sign(b, F, c, nn, w, head):
	var r = (-nn).cross(UP)
	var y0 = head + 0.25
	var h = 1.0
	var mid = c + UP * (y0 + h * 0.5)
	b.box(F, "sg_gor_frame", mid + nn * 0.04, b.abs_size(r, w + 0.16, h + 0.16, 0.08, nn))
	b.box(F, "sg_gor_lit", mid + nn * 0.085, b.abs_size(r, w, h, 0.01, nn))
	# the muntins: two uprights and an arch across the panel
	for x in [-w * 0.32, w * 0.32]:
		b.box(F, "sg_gor_frame", mid + r * x + nn * 0.095, b.abs_size(r, 0.05, h, 0.012, nn))
	var seg = 16
	for i in seg:
		var a0 = PI * i / seg
		var a1 = PI * (i + 1) / seg
		var q0 = mid + r * (-cos(a0) * w * 0.5) + UP * (sin(a0) * h * 0.85 - h * 0.5) + nn * 0.095
		var q1 = mid + r * (-cos(a1) * w * 0.5) + UP * (sin(a1) * h * 0.85 - h * 0.5) + nn * 0.095
		var d = q1 - q0
		var xf = Transform3D(Basis(d.normalized(), d.normalized().cross(nn).normalized() * -1.0, nn), (q0 + q1) * 0.5)
		b.box(F, "sg_gor_frame", Vector3.ZERO, Vector3(d.length() + 0.02, 0.04, 0.012), xf)
	CH.build(b, "w7gf_sign", "res://tools/stores/signs/gor_name_logo.json", c + UP * (y0 + 0.38) + nn * 0.1, nn, "sg_gor_black", "sg_gor_black", "", 0.0, 0.015, 0.0)
	CH.build(b, "w7gf_sign", "res://tools/stores/signs/gor_sub_logo.json", c + UP * (y0 + 0.18) + nn * 0.1, nn, "sg_gor_black", "sg_gor_black", "", 0.0, 0.01, 0.0)

# ------------------------------------------------------------------ materials
## "w7_<key>" (build_mall.gd's mat() calls this).
static func fill_mat(m, key, b):
	match key:
		"gloss_black":
			m.albedo_color = Color("#0e0e10"); m.roughness = 0.1; m.metallic_specular = 0.8
		"tube_red":
			m.albedo_color = Color("#ff3030"); m.roughness = 0.3
			K.emit(m, Color("#ff2020"), 1.2)
		"tube_yellow":
			m.albedo_color = Color("#ffd820"); m.roughness = 0.3
			K.emit(m, Color("#ffc810"), 1.0)
		"tube_green":
			m.albedo_color = Color("#30c050"); m.roughness = 0.3
			K.emit(m, Color("#20b040"), 1.0)
		"sunset":
			m.albedo_texture = b.tex("w7/sunset.png"); m.roughness = 0.8
		"rust":
			m.albedo_color = Color("#a8402a"); m.roughness = 0.45; m.metallic_specular = 0.4
		"dot":
			m.albedo_color = Color("#ffd820")
			K.emit(m, Color("#ffd020"), 0.6)
		"mirror":
			m.albedo_color = Color("#cfd6da"); m.metallic = 1.0; m.roughness = 0.05
		"rose_wall":
			m.albedo_color = Color("#ecd2d2"); m.roughness = 0.85
		"red":
			m.albedo_color = Color("#c8141c"); m.roughness = 0.4
		"navy":
			m.albedo_color = Color("#1a2a5c"); m.roughness = 0.4; m.metallic_specular = 0.45
		"royal":
			m.albedo_color = Color("#1e46b4"); m.roughness = 0.5
		"cream_letter":
			m.albedo_color = Color("#f2e8cc"); m.roughness = 0.4
			K.emit(m, Color("#f2e8cc"), 0.5)
		"grey_block":
			m.albedo_texture = b.tex("sm/stone.png"); m.roughness = 0.6
			m.albedo_color = Color(0.75, 0.75, 0.78)
		"gold":
			m.albedo_color = Color("#d4a838"); m.metallic = 0.6; m.roughness = 0.3
			K.emit(m, Color("#b08a2a"), 0.3)
		"marquee":
			m.albedo_texture = b.tex("w7/marquee.png"); m.roughness = 0.4
			K.emit_tex(m, 1.4)
		"white_tile":
			m.albedo_texture = b.tex("wl/floor.png"); m.roughness = 0.25; m.metallic_specular = 0.55
		"cream":
			m.albedo_color = Color("#f2ead6"); m.roughness = 0.6
		"cream_tile":
			m.albedo_texture = b.tex("wl/floor.png"); m.roughness = 0.25; m.metallic_specular = 0.55
			m.albedo_color = Color(1.0, 0.95, 0.82)
		"cookie_sign":
			m.albedo_texture = b.tex("w7/cookie_sign.png"); m.roughness = 0.4
			K.emit_tex(m, 0.9)
		"check":
			m.albedo_texture = b.tex("a2/checker.png"); m.roughness = 0.3
		"cookies":
			m.albedo_texture = b.tex("w7/cookies.png"); m.roughness = 0.6
			K.emit_tex(m, 0.35)
		"travertine":
			m.albedo_texture = b.tex("w7/travertine.png"); m.roughness = 0.45; m.metallic_specular = 0.45
		"halo":
			m.albedo_color = Color("#fff4e0")
			K.emit(m, Color("#fff0d0"), 0.9)
		"maple":
			m.albedo_texture = b.tex("wood_dark.png"); m.roughness = 0.4
			m.albedo_color = Color(2.2, 1.8, 1.3)
		"mosaic":
			m.albedo_texture = b.tex("w7/mosaic.png"); m.roughness = 0.3; m.metallic_specular = 0.5
		"pink":
			m.albedo_color = Color("#f080b0"); m.roughness = 0.4
			K.emit(m, Color("#f070a8"), 0.4)
		"warm_slat":
			m.albedo_texture = b.tex("gb/slat_white.png"); m.roughness = 0.6
			m.albedo_color = Color(1.0, 0.86, 0.72)
		"neon_orange":
			m.albedo_color = Color("#ffb060")
			m.emission_enabled = true; m.emission = Color("#ff7a10"); m.emission_energy_multiplier = 2.6
			m.set_meta("e_day", 2.2); m.set_meta("e_night", 2.6)
		"diamonds":
			m.albedo_texture = b.tex("w7/diamonds.png"); m.roughness = 0.3; m.metallic_specular = 0.5
		"bronze":
			m.albedo_color = Color("#4a3624"); m.metallic = 0.5; m.roughness = 0.35
		"gordons":
			m.albedo_texture = b.tex("w7/gordons.png"); m.roughness = 0.5
			K.emit_tex(m, 0.8)
		"taupe":
			m.albedo_color = Color("#a89a88"); m.roughness = 0.85
		"taupe_carpet":
			m.albedo_texture = b.tex("a2/carpet_grey.png"); m.roughness = 0.95
			m.albedo_color = Color(0.95, 0.85, 0.75)
		_:
			return false
	return true
