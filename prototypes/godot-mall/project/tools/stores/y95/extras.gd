## 1995 additions from Steven's Oct 28 sprint (workstream G, step 7), called from the stores'
## own builders with one line each. Notes: design/storefronts/karmelkorn.md, gadzooks.md.
##
## - popcorn_back(): KarmelKorn's back of the shop "as rich as Pocket Change's prize counter": a
##   wall of lit shelves of tins and bags over the kettles, tall glass drums of popcorn in four
##   colours, a floor pyramid of tins, bags hanging from a rail, a popper cart with corn spilling.
## - beetle(): Gadzooks' white half VW Beetle with coloured handprints, in the left window
##   (design/storefronts/refs/gadzooks-front-night-with-beetle.jpg, gadzooks-beetle-handprints.png).
## - gz_ads(): period-style poster panels on Gadzooks' walls after the store's ads (invented art:
##   checker, floral, skate, surf; no brand marks).
## Frame (the callers'): P(a, t, n, u, y, d) = a + t u - n d + y up. Materials "y95_<key>".

const K = preload("res://tools/stores/media/kit.gd")
const UP = Vector3.UP

static func P(a, t, n, u, y, d):
	return a + t * u - n * d + UP * y

# ------------------------------------------------------------------ KarmelKorn
static func popcorn_back(b, a, t, n, W, D):
	var G = "s6k_fix"
	var S = "y95_kk_small"
	var rng = RandomNumberGenerator.new()
	rng.seed = 5795
	var dB = D - 0.15
	# lit shelving over the kettles, u 1.2 .. 10.8, four shelves 1.95 .. 2.85, tins and bags
	var u0 = 1.2
	var u1 = 10.8
	b.cur_color = Color("#f6e7a8")
	b.quad(G, "vcolor_matte", [P(a, t, n, u0, 1.8, dB - 0.01), P(a, t, n, u1, 1.8, dB - 0.01), P(a, t, n, u1, 2.95, dB - 0.01), P(a, t, n, u0, 2.95, dB - 0.01)], n)
	b.cur_color = Color.WHITE
	for k in 4:
		var y = 1.85 + k * 0.28
		b.cur_color = Color("#c8141c")
		K.lbox(b, G, "vcolor", P(a, t, n, u0, 0, dB), t, n, 0.0, y - 0.02, 0.0, u1 - u0, 0.02, 0.32)
		b.cur_color = Color.WHITE
		var u = u0 + 0.08
		while u < u1 - 0.2:
			if rng.randf() < 0.65:
				tin(b, S, P(a, t, n, u + 0.09, y, dB - 0.17), rng, 0.09, 0.2)
				u += 0.21
			else:
				bag(b, S, P(a, t, n, u + 0.09, y, dB - 0.16), t, n, rng)
				u += 0.2
	var l = b.add_omni(P(a, t, n, (u0 + u1) * 0.5, 2.6, dB - 0.8), 0.45, 5.0, Color(1.0, 0.92, 0.75))
	b.tag(l, "", 0.4, 0.45)
	# tall glass drums of popcorn between and beside the kettles: caramel, cheese, plain, cherry
	var cols = ["y95_corn_caramel", "y95_corn_cheese", "y95_corn_plain", "y95_corn_red"]
	var k2 = 0
	for u in [1.6, 4.5, 7.5, 10.4]:
		var c = P(a, t, n, u, 0, dB - 0.45)
		b.cur_color = Color("#c8141c")
		b.cyl(G, "vcolor", c, 0.3, 0.3, 0.6, 16, true, false)
		b.cur_color = Color.WHITE
		b.cyl(G, cols[k2 % 4], c + UP * 0.6, 0.27, 0.27, 0.9, 16, true, false)
		b.cyl("glass", "glass", c + UP * 0.6, 0.29, 0.29, 1.0, 16, true, false, true)
		b.cur_color = Color("#d8d8dc")
		b.cyl(G, "vcolor", c + UP * 1.6, 0.31, 0.25, 0.08, 16, true, false)
		b.cur_color = Color.WHITE
		k2 += 1
	# a pyramid of tins on the floor by the west wall
	var base = P(a, t, n, 2.2, 0, D - 3.4)
	for row in 4:
		var nrow = 4 - row
		for i in nrow:
			for j in nrow:
				tin(b, S, base + t * ((i - nrow * 0.5) * 0.24) - n * ((j - nrow * 0.5) * 0.24) + UP * (row * 0.21), rng, 0.11, 0.21)
	K.ob(b, base - t * 0.6 + n * 0.6, base + t * 0.6 - n * 0.6, 0.05)
	# bags hanging from a rail along the west wall
	b.cur_color = Color("#c0c0c4")
	K.lbox(b, G, "vcolor", P(a, t, n, 0.15, 0, 3.2), -n, t, 0.0, 1.95, 0.05, D - 5.8, 0.02, 0.02)
	b.cur_color = Color.WHITE
	var dd = 3.4
	while dd < D - 2.7:
		for yy in [1.55, 1.15]:
			bag(b, S, P(a, t, n, 0.28, yy, dd), -n, t, rng)
		dd += 0.26
	# the popper cart by the counter's end: red cart, glass box overflowing with corn
	var pc = P(a, t, n, W - 3.2, 0, D - 2.4)
	b.cur_color = Color("#c8141c")
	b.box(G, "vcolor", pc + UP * 0.45, Vector3(0.9, 0.9, 0.6))
	b.cur_color = Color("#f2c81e")
	b.box(G, "vcolor", pc + UP * 0.92, Vector3(0.94, 0.04, 0.64))
	b.cur_color = Color.WHITE
	b.box(G, "y95_corn_plain", pc + UP * 1.12, Vector3(0.84, 0.36, 0.54))
	b.box("glass", "glass", pc + UP * 1.3, Vector3(0.9, 0.76, 0.6), Transform3D.IDENTITY, ["-y"], true)
	b.cur_color = Color("#d8d8dc")
	b.cyl(S, "vcolor", pc + UP * 1.5, 0.16, 0.16, 0.12, 12, true, true, true)
	b.cur_color = Color("#c8141c")
	b.box(G, "vcolor", pc + UP * 1.72, Vector3(0.94, 0.08, 0.64))
	b.cur_color = Color.WHITE
	K.ob(b, pc - Vector3(0.5, 0, 0.35), pc + Vector3(0.5, 0, 0.35), 0.05)

## A popcorn tin: a coloured drum with a band and a lid.
static func tin(b, S, c, rng, r, h):
	var cols = ["#c8141c", "#1e5a2a", "#1f3f8f", "#f2c81e", "#f4f2ec", "#7a1e5a"]
	b.cur_color = Color(cols[rng.randi_range(0, cols.size() - 1)])
	b.cyl(S, "vcolor", c, r, r, h * 0.92, 12, false, false, true)
	b.cur_color = Color(cols[rng.randi_range(0, cols.size() - 1)])
	b.cyl(S, "vcolor", c + UP * h * 0.35, r + 0.003, r + 0.003, h * 0.18, 12, false, false, true)
	b.cur_color = Color("#d8d8dc")
	b.cyl(S, "vcolor", c + UP * h * 0.9, r + 0.005, r + 0.005, h * 0.1, 12, true, false, true)
	b.cur_color = Color.WHITE

## A cellophane bag of caramel corn tied with a ribbon: a corn body, a clear top, a ribbon.
static func bag(b, S, c, r, f, rng):
	var corn = ["y95_corn_caramel", "y95_corn_cheese", "y95_corn_plain", "y95_corn_red"][rng.randi_range(0, 3)]
	var xf = Transform3D(Basis(r, UP, f.cross(UP) if f.cross(UP).dot(r) > 0 else -f.cross(UP)).orthonormalized(), c)
	b.box(S, corn, Vector3(0, 0.1, 0), Vector3(0.14, 0.2, 0.09), xf, [], true)
	b.cur_color = Color("#eef4f6")
	b.box(S, "vcolor", Vector3(0, 0.23, 0), Vector3(0.11, 0.06, 0.06), xf, [], true)
	b.cur_color = Color(["#c8141c", "#f2c81e", "#1f3f8f"][rng.randi_range(0, 2)])
	b.box(S, "vcolor", Vector3(0, 0.205, 0), Vector3(0.12, 0.015, 0.07), xf, [], true)
	b.cur_color = Color.WHITE

# ------------------------------------------------------------------ Gadzooks
## The rear half of a white VW Beetle with coloured handprints, cut square at `c` (the cut's
## centre on the floor), the car's axis `ax` pointing from the cut toward the rear. Lofted from
## body sections; rear fenders, wheels, rear window, engine lid, taillights, bumper.
static func beetle(b, g, c, ax):
	var S = g
	var side = ax.cross(UP).normalized()
	var L = 1.95
	var seg = 14
	var ring = 18
	var st = b.st(S, "y95_beetle", true)
	# body profile along x (0 at the cut, L at the rear): roof height and half-width
	var prof = func(x):
		var s = x / L
		var top = 1.48 - 0.55 * pow(max(0.0, s - 0.15) / 0.85, 1.6)
		var hw = 0.72 - 0.18 * pow(s, 3.0)
		var bot = 0.32 + 0.08 * s
		return [top, hw, bot]
	var pts = []
	for i in seg + 1:
		var x = L * i / seg
		var pr = prof.call(x)
		var row = []
		for j in ring + 1:
			var th = PI * j / ring          # 0: right sill, PI: left sill, over the top
			var yy = pr[2] + (pr[0] - pr[2]) * pow(sin(th), 0.7)
			var ww = pr[1] * cos(th)
			row.append(c + ax * x + side * ww + UP * yy)
		pts.append(row)
	for i in seg:
		for j in ring:
			var p00 = pts[i][j]; var p01 = pts[i][j + 1]; var p10 = pts[i + 1][j]; var p11 = pts[i + 1][j + 1]
			var nrm = (p10 - p00).cross(p01 - p00).normalized()
			var mid = (p00 + p11) * 0.5
			var outv = (mid - (c + ax * ((float(i) + 0.5) * L / seg) + UP * 0.8)).normalized()
			if nrm.dot(outv) < 0.0:
				nrm = -nrm
			var uv = func(ii, jj):
				return Vector2(float(jj) / ring * 2.0, float(ii) / seg * 1.5)
			b.tri(st, p00, p10, p11, uv.call(i, j), uv.call(i + 1, j), uv.call(i + 1, j + 1), nrm)
			b.tri(st, p00, p11, p01, uv.call(i, j), uv.call(i + 1, j + 1), uv.call(i, j + 1), nrm)
	# the rear end cap and the cut face (white)
	var sw = b.st(S, "y95_white", true)
	for i in [0, seg]:
		var cc = c + ax * (L * i / seg) + UP * 0.8
		var nrm2 = -ax if i == 0 else ax
		for j in ring:
			b.tri(sw, cc, pts[i][j], pts[i][j + 1], Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, nrm2)
	# the underside
	b.quad(S, "y95_dark", [pts[0][0], pts[seg][0], pts[seg][ring], pts[0][ring]], Vector3.DOWN, [], true)
	# rear fenders (bulges) and the wheels
	for s in [1.0, -1.0]:
		var fc = c + ax * 1.15 + side * s * 0.68 + UP * 0.42
		b.cur_color = Color("#f4f2ee")
		b.box(S, "y95_beetle", Vector3.ZERO, Vector3(0.95, 0.42, 0.16), Transform3D(Basis(ax, UP, side * s), fc + UP * 0.12), [], true)
		var wc = c + ax * 1.15 + side * s * 0.66 + UP * 0.33
		disc(b, S, wc, side * s, 0.33, 0.2, "#141414")
		disc(b, S, wc + side * s * 0.11, side * s, 0.17, 0.02, "#c8c8cc")
	# rear window, engine lid with vents, taillights, bumper
	var rw = c + ax * 1.35 + UP * 1.2
	b.cur_color = Color("#20242a")
	b.box(S, "vcolor", Vector3.ZERO, Vector3(0.04, 0.26, 0.7), Transform3D(Basis(ax, UP, side).rotated(side, -0.75), rw + ax * 0.08), [], true)
	b.cur_color = Color("#d8d6d0")
	for k in 5:
		b.box(S, "vcolor", c + ax * (L - 0.05) + UP * (0.95 - k * 0.04), Vector3(0.02, 0.012, 0.3), Transform3D(Basis(ax, UP, side), Vector3.ZERO), [], true)
	for s in [1.0, -1.0]:
		b.cur_color = Color("#b0141c")
		b.box(S, "vcolor", Vector3.ZERO, Vector3(0.08, 0.16, 0.1), Transform3D(Basis(ax, UP, side), c + ax * (L - 0.25) + side * s * 0.62 + UP * 0.72), [], true)
	b.cur_color = Color("#d0d0d4")
	b.box(S, "vcolor", Vector3.ZERO, Vector3(0.06, 0.08, 1.5), Transform3D(Basis(ax, UP, side), c + ax * (L + 0.04) + UP * 0.42), [], true)
	b.cur_color = Color.WHITE
	K.ob(b, c - side * 0.8, c + ax * (L + 0.1) + side * 0.8, 0.05)

## A cylinder of radius r and width w centred on c, its axis along `axis` (a wheel), in colour col.
static func disc(b, S, c, axis, r, w, col, seg = 18):
	var st = b.st(S, "vcolor", true)
	b.cur_color = Color(col)
	var u = axis.cross(UP).normalized() if abs(axis.dot(UP)) < 0.9 else axis.cross(Vector3.RIGHT).normalized()
	var v = axis.cross(u).normalized()
	for i in seg:
		var a0 = TAU * i / seg
		var a1 = TAU * (i + 1) / seg
		var d0 = u * cos(a0) + v * sin(a0)
		var d1 = u * cos(a1) + v * sin(a1)
		var p0 = c + d0 * r - axis * (w * 0.5)
		var p1 = c + d1 * r - axis * (w * 0.5)
		var q0 = p0 + axis * w
		var q1 = p1 + axis * w
		var nm = (d0 + d1).normalized()
		b.tri(st, p0, p1, q1, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, nm)
		b.tri(st, p0, q1, q0, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, nm)
		b.tri(st, c + axis * (w * 0.5), q0, q1, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, axis)
		b.tri(st, c - axis * (w * 0.5), p0, p1, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, -axis)
	b.cur_color = Color.WHITE

## Poster panels on Gadzooks' walls after its period ads (invented art), on the side walls 1.2-2.6 m.
static func gz_ads(b, a, t, n, W, D):
	var G = "a2_shell"
	for k in 6:
		var left = k % 2 == 0
		var u = 0.15 if left else W - 0.15
		var d0 = 3.0 + (k / 2) * 5.0
		var face = t if left else -t
		var p0 = P(a, t, n, u, 2.0, d0)
		var p1 = P(a, t, n, u, 2.0, d0 + 1.4)
		var ua = (k % 4) * 0.25
		var pts = [p0, p1, p1 + UP * 0.95, p0 + UP * 0.95] if left else [p1, p0, p0 + UP * 0.95, p1 + UP * 0.95]
		b.quad(G, "y95_gz_ads", pts, face, [Vector2(ua, 1), Vector2(ua + 0.25, 1), Vector2(ua + 0.25, 0), Vector2(ua, 0)])

# ------------------------------------------------------------------ materials
static func fill_mat(m, key, b):
	match key:
		"corn_caramel", "corn_cheese", "corn_plain", "corn_red":
			m.albedo_texture = b.tex("y95/%s.png" % key.substr(5)); m.roughness = 0.75
			m.uv1_triplanar = true; m.uv1_scale = Vector3(3, 3, 3)
		"beetle":
			m.albedo_texture = b.tex("y95/beetle.png"); m.roughness = 0.25; m.metallic_specular = 0.7
		"white":
			m.albedo_color = Color("#f4f2ee"); m.roughness = 0.3
		"dark":
			m.albedo_color = Color("#1a1a1a"); m.roughness = 0.8
		"gz_ads":
			m.albedo_texture = b.tex("y95/gz_ads.png"); m.roughness = 0.5
		_:
			return false
	return true
