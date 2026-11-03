## Pocket Change prop module "crane": an early-1990s claw (crane) machine full of plush
## prizes, ~0.80 m wide x 0.90 m deep x 1.98 m tall. Contract: README.md in this folder.
## Lower cabinet (coin door with lit token inserts, prize door with a PUSH flap), a sloped
## control-panel ledge (joystick + lit drop button), a four-sided glass prize box on
## aluminium corner posts, a fluorescent tube and lit ceiling inside, the gantry with a
## three-prong chrome claw on its cable and coiled cord, a pile of generic plush (bears,
## dogs, bunnies, balls, pom critters) and a fluorescent-backlit header marquee.
## opts {"style": 0..2}: 0 black PRIZE CATCHER (classic bears), 1 blue LUCKY GRAB (pastels),
## 2 red SKILL CRANE (brights). All titles and art are invented.
## Textures: tools/stores/pocket_change/paint_crane.py -> tex/pc/crane_*.png
##   tools/qa/preview.sh crane /home/claude/houma-mall-rewind/.scratch/preview/crane/a "0,1.55,2.2,0,-12;1.6,1.5,1.6,45,-12" '{"style":0}' lit

const W = 0.80
const D = 0.90
const H = 1.98
const Z_CAB = 0.05      # lower cabinet front (the panel ledge overhangs it to z = 0)
const Z_PNL = 0.17      # back edge of the panel ledge = front of the glass box
const Y_PF = 0.905      # panel top at its front edge
const Y_PB = 0.93       # ... and at its back edge
const Y_DECK = 0.955    # prize-box floor
const Y_G0 = 0.96       # glass bottom
const Y_G1 = 1.60       # glass top
const Y_HD = 1.64       # header box bottom
const PX = 550.0        # cabinet atlas px per metre (paint_crane.py PXM)

## plush fabric colours (materials pc_crane_fur<i>)
const FUR = ["#b5824a", "#5a3820", "#e8e0cc", "#c21f2a", "#ea88ae", "#72a6e0", "#9e82d4",
	"#7ccfa6", "#f2cc34", "#2850c0", "#2c9c46", "#ec7420", "#743498", "#9a9aa2"]
## per style: [colour index, weight] and [type, weight]
const MIX = [
	{"col": [[0, 5], [1, 3], [2, 3], [3, 2], [13, 1], [4, 1]], "typ": [["bear", 6], ["dog", 2], ["ball", 1], ["pom", 1]]},
	{"col": [[4, 3], [5, 3], [6, 3], [7, 2], [2, 2], [8, 1]], "typ": [["bear", 3], ["bunny", 3], ["pom", 2], ["ball", 1]]},
	{"col": [[3, 2], [8, 2], [9, 2], [10, 2], [11, 2], [12, 2], [0, 1]], "typ": [["dog", 3], ["ball", 3], ["bear", 2], ["pom", 2]]},
]
const CAB_COL = ["#18181b", "#1c3890", "#961418"]
const BTN_COL = ["#ff2a1a", "#ffd21a", "#27e04a"]
## claw: [x, z, housing-top y or -1 = just above the pile]
const CLAW = [[-0.275, 0.30, 1.50], [0.06, 0.56, -1.0], [0.16, 0.44, 1.40]]

## Footprint (width, depth) in metres.
static func footprint(_opts = {}):
	return Vector2(W, D)

static func X(o, f):
	return Transform3D(Basis(f.cross(Vector3.UP), Vector3.UP, f), o)

# ------------------------------------------------------------------ geometry helpers
## A quad from local points [bl, br, tr, tl] with the texture rect r = (u0, v0, u1, v1).
static func face(b, g, m, xf, p, n, r = Vector4(0, 0, 1, 1), dyn = false):
	var w = []
	for q in p:
		w.append(xf * q)
	b.quad(g, m, w, (xf.basis * n).normalized(),
		[Vector2(r.x, r.w), Vector2(r.z, r.w), Vector2(r.z, r.y), Vector2(r.x, r.y)], dyn)

static func px(x0, y0, x1, y1, tw, th):
	return Vector4(x0 / tw, y0 / th, x1 / tw, y1 / th)

## One smooth triangle: v = [pos, normal, uv] x 3, wound to face the averaged normal.
static func tri3(b, s, a, c, d):
	var fn = a[1] + c[1] + d[1]
	if (c[0] - a[0]).cross(d[0] - a[0]).dot(fn) > 0.0:
		var t = c; c = d; d = t
	for v in [a, c, d]:
		s.set_color(Color.WHITE); s.set_normal(v[1]); s.set_uv(v[2]); s.add_vertex(v[0])

## Smooth ellipsoid (world centre c, radii rad along the world basis bs). mats: one material,
## or an array cycled per longitude segment (panelled balls).
static func ell(b, g, mats, c, rad, bs, seg, rings, dyn, uvk = Vector2(2, 1)):
	var grid = []
	for j in rings + 1:
		var t = PI * j / rings
		var row = []
		for i in seg + 1:
			var ph = TAU * i / seg
			var dd = Vector3(sin(t) * cos(ph), cos(t), sin(t) * sin(ph))
			var pos = c + bs * (dd * rad)
			var nr = (bs * Vector3(dd.x / rad.x, dd.y / rad.y, dd.z / rad.z)).normalized()
			row.append([pos, nr, Vector2(float(i) / seg * uvk.x, float(j) / rings * uvk.y)])
		grid.append(row)
	for j in rings:
		for i in seg:
			var m = mats if mats is String else mats[i % mats.size()]
			var s = b.st(g, m, dyn)
			if j > 0:
				tri3(b, s, grid[j][i], grid[j][i + 1], grid[j + 1][i + 1])
			if j < rings - 1:
				tri3(b, s, grid[j][i], grid[j + 1][i + 1], grid[j + 1][i])

## A round tube along a world polyline (parallel-transported frame, no caps).
static func pipe(b, g, m, pts, r, seg, dyn):
	var s = b.st(g, m, dyn)
	var rings = []
	var u = Vector3.ZERO
	for k in pts.size():
		var t = (pts[min(k + 1, pts.size() - 1)] - pts[max(k - 1, 0)]).normalized()
		if k == 0:
			var ref = Vector3.UP if abs(t.y) < 0.9 else Vector3.RIGHT
			u = t.cross(ref).normalized()
		else:
			u = (u - t * t.dot(u)).normalized()
		var v = t.cross(u)
		var ring = []
		for i in seg + 1:
			var a = TAU * i / seg
			var dd = u * cos(a) + v * sin(a)
			ring.append([pts[k] + dd * r, dd, Vector2(float(i) / seg, float(k))])
		rings.append(ring)
	for k in pts.size() - 1:
		for i in seg:
			tri3(b, s, rings[k][i], rings[k][i + 1], rings[k + 1][i + 1])
			tri3(b, s, rings[k][i], rings[k + 1][i + 1], rings[k + 1][i])

## A small square decal (world centre, outward normal, up hint, side length, texture rect).
static func decal(b, g, c, n, up, sz, r):
	var rt = up.cross(n).normalized()
	var u2 = n.cross(rt).normalized()
	var h = sz * 0.5
	var c2 = c + n * 0.0015
	b.quad(g, "pc_crane_face", [c2 - rt * h - u2 * h, c2 + rt * h - u2 * h, c2 + rt * h + u2 * h, c2 - rt * h + u2 * h], n,
		[Vector2(r.x, r.w), Vector2(r.z, r.w), Vector2(r.z, r.y), Vector2(r.x, r.y)], true)

# ------------------------------------------------------------------ build
## Builds one crane machine; the player stands at o facing f.
static func build(b, g, o, f, opts = {}):
	var st = clampi(int(opts.get("style", 0)), 0, 2)
	var xf = X(o, f)
	var body = "pc_crane_body%d" % st
	var cab = "pc_crane_cab%d" % st
	b.cur_color = Color.WHITE

	# ---- lower cabinet
	b.box(g, body, Vector3(0, 0.485, 0.475), Vector3(W, 0.87, 0.85), xf, ["-z", "+x", "-x", "+y"])
	b.box(g, "pc_crane_blk", Vector3(0, 0.025, 0.48), Vector3(W - 0.03, 0.05, 0.80), xf, ["+y"])
	# front, in pieces around the prize-door opening (x -0.33..-0.13, y 0.30..0.52)
	var fr = func(x0, y0, x1, y1):
		face(b, g, cab, xf, [Vector3(x0, y0, Z_CAB), Vector3(x1, y0, Z_CAB), Vector3(x1, y1, Z_CAB), Vector3(x0, y1, Z_CAB)], Vector3(0, 0, -1),
			px((x0 + 0.40) * PX, (0.84 - y1) * PX, (x1 + 0.40) * PX, (0.84 - y0) * PX, 1024.0, 512.0))
	fr.call(-0.40, 0.05, -0.33, 0.84)
	fr.call(-0.13, 0.05, 0.40, 0.84)
	fr.call(-0.33, 0.05, -0.13, 0.30)
	fr.call(-0.33, 0.52, -0.13, 0.84)
	var rz = Z_CAB + 0.03
	face(b, g, "pc_crane_hole", xf, [Vector3(-0.33, 0.30, Z_CAB), Vector3(-0.13, 0.30, Z_CAB), Vector3(-0.13, 0.30, rz), Vector3(-0.33, 0.30, rz)], Vector3.UP)
	face(b, g, "pc_crane_hole", xf, [Vector3(-0.33, 0.52, rz), Vector3(-0.13, 0.52, rz), Vector3(-0.13, 0.52, Z_CAB), Vector3(-0.33, 0.52, Z_CAB)], Vector3.DOWN)
	face(b, g, "pc_crane_hole", xf, [Vector3(-0.33, 0.30, rz), Vector3(-0.33, 0.30, Z_CAB), Vector3(-0.33, 0.52, Z_CAB), Vector3(-0.33, 0.52, rz)], Vector3.RIGHT)
	face(b, g, "pc_crane_hole", xf, [Vector3(-0.13, 0.30, Z_CAB), Vector3(-0.13, 0.30, rz), Vector3(-0.13, 0.52, rz), Vector3(-0.13, 0.52, Z_CAB)], Vector3.LEFT)
	# the PUSH flap, hung from the top of the opening and swung in a little at the bottom
	face(b, g, "pc_crane_panel", xf, [Vector3(-0.33, 0.30, rz - 0.002), Vector3(-0.13, 0.30, rz - 0.002), Vector3(-0.13, 0.52, Z_CAB + 0.012), Vector3(-0.33, 0.52, Z_CAB + 0.012)],
		Vector3(0, 0.1, -1).normalized(), px(0, 168, 80, 256, 512.0, 256.0))
	# sides (u = 0 at the edge on the viewer's left, so the decal title reads on both)
	var sr = px(448, 0, 916, 479, 1024.0, 512.0)
	face(b, g, cab, xf, [Vector3(0.40, 0.05, Z_CAB), Vector3(0.40, 0.05, D), Vector3(0.40, 0.92, D), Vector3(0.40, 0.92, Z_CAB)], Vector3.RIGHT, sr)
	face(b, g, cab, xf, [Vector3(-0.40, 0.05, D), Vector3(-0.40, 0.05, Z_CAB), Vector3(-0.40, 0.92, Z_CAB), Vector3(-0.40, 0.92, D)], Vector3.LEFT, sr)

	# ---- coin door: a plate 1 cm proud carrying the painted door, lit token inserts
	var cz = Z_CAB - 0.01
	var cr = px((0.05 + 0.40) * PX, (0.84 - 0.74) * PX, (0.31 + 0.40) * PX, (0.84 - 0.40) * PX, 1024.0, 512.0)
	face(b, g, cab, xf, [Vector3(0.05, 0.40, cz), Vector3(0.31, 0.40, cz), Vector3(0.31, 0.74, cz), Vector3(0.05, 0.74, cz)], Vector3(0, 0, -1), cr)
	b.box(g, "pc_crane_steel", Vector3(0.18, 0.57, cz + 0.005), Vector3(0.26, 0.34, 0.0098), xf, ["-z", "+z"])
	var cw = 0.26 * PX
	for k in 2:
		var lx = 0.05 + cw * (0.27 + 0.46 * k) / PX
		face(b, g, "pc_crane_lamp", xf, [Vector3(lx - 0.022, 0.643, cz - 0.0015), Vector3(lx + 0.022, 0.643, cz - 0.0015),
			Vector3(lx + 0.022, 0.704, cz - 0.0015), Vector3(lx - 0.022, 0.704, cz - 0.0015)], Vector3(0, 0, -1), px(96, 168, 144, 232, 512.0, 256.0), true)

	# ---- control panel ledge (sloped top, fascia, aluminium end caps and nosing)
	var pn = Vector3(0, Z_PNL, -(Y_PB - Y_PF)).normalized()
	face(b, g, "pc_crane_panel", xf, [Vector3(-0.40, Y_PF, 0), Vector3(0.40, Y_PF, 0), Vector3(0.40, Y_PB, Z_PNL), Vector3(-0.40, Y_PB, Z_PNL)], pn, px(0, 0, 512, 110, 512.0, 256.0))
	face(b, g, "pc_crane_panel", xf, [Vector3(-0.40, 0.84, 0), Vector3(0.40, 0.84, 0), Vector3(0.40, Y_PF, 0), Vector3(-0.40, Y_PF, 0)], Vector3(0, 0, -1), px(0, 112, 512, 164, 512.0, 256.0))
	face(b, g, "pc_crane_blk", xf, [Vector3(-0.40, 0.84, Z_CAB), Vector3(0.40, 0.84, Z_CAB), Vector3(0.40, 0.84, 0), Vector3(-0.40, 0.84, 0)], Vector3.DOWN)
	for sx in [-1.0, 1.0]:
		var ex = sx * 0.403
		face(b, g, "pc_crane_alu", xf, [Vector3(ex, 0.835, 0), Vector3(ex, 0.835, Z_PNL), Vector3(ex, Y_PB + 0.004, Z_PNL), Vector3(ex, Y_PF + 0.004, 0)], Vector3(sx, 0, 0))
		face(b, g, "pc_crane_alu", xf, [Vector3(ex - sx * 0.003, 0.835, -0.003), Vector3(ex, 0.835, -0.003), Vector3(ex, Y_PF + 0.004, -0.003), Vector3(ex - sx * 0.003, Y_PF + 0.004, -0.003)], Vector3(0, 0, -1))
	pipe(b, g, "pc_crane_alu", [xf * Vector3(-0.40, Y_PF - 0.004, 0.004), xf * Vector3(0.40, Y_PF - 0.004, 0.004)], 0.008, 8, false)

	# ---- controls (dynamic): ball-top joystick and a lit drop button
	var ypz = func(z): return Y_PF + (Y_PB - Y_PF) * z / Z_PNL
	var jz = 0.085
	var jb = xf * Vector3(-0.12, ypz.call(jz), jz)
	b.cyl(g, "pc_crane_blk", jb, 0.03, 0.026, 0.006, 16, true, false, true)
	b.cyl(g, "pc_crane_blk", jb + Vector3(0, 0.006, 0), 0.013, 0.008, 0.02, 10, false, false, true)
	b.cyl(g, "pc_crane_chrome", jb + Vector3(0, 0.02, 0), 0.0055, 0.0055, 0.055, 8, false, false, true)
	ell(b, g, "pc_crane_ball", jb + Vector3(0, 0.088, 0), Vector3(0.02, 0.02, 0.02), xf.basis, 12, 8, true)
	var bb = xf * Vector3(0.13, ypz.call(jz), jz)
	b.cyl(g, "pc_crane_chrome", bb, 0.031, 0.029, 0.007, 18, true, false, true)
	b.cyl(g, "pc_crane_btn%d" % st, bb + Vector3(0, 0.007, 0), 0.024, 0.023, 0.012, 18, true, false, true)

	# ---- glass box frame: aluminium rails and corner posts
	for yy in [[0.925, Y_G0], [Y_G1, Y_HD]]:
		var yc = (yy[0] + yy[1]) * 0.5
		var hh = yy[1] - yy[0]
		b.box(g, "pc_crane_alu", Vector3(0, yc, Z_PNL + 0.01), Vector3(W, hh, 0.02), xf)
		b.box(g, "pc_crane_alu", Vector3(0, yc, D - 0.01), Vector3(W, hh, 0.02), xf)
		for sx in [-1.0, 1.0]:
			b.box(g, "pc_crane_alu", Vector3(sx * 0.39, yc, (Z_PNL + D) * 0.5), Vector3(0.02, hh, D - Z_PNL - 0.04), xf)
	for sx in [-1.0, 1.0]:
		for zz in [Z_PNL + 0.015, D - 0.015]:
			b.box(g, "pc_crane_alu", Vector3(sx * 0.385, (Y_G0 + Y_G1) * 0.5, zz), Vector3(0.03, Y_G1 - Y_G0, 0.03), xf)
	# glass, all four sides (dynamic, transparent)
	var gz0 = Z_PNL + 0.013
	var gz1 = D - 0.013
	face(b, g, "pc_crane_glass", xf, [Vector3(-0.37, Y_G0, gz0), Vector3(0.37, Y_G0, gz0), Vector3(0.37, Y_G1, gz0), Vector3(-0.37, Y_G1, gz0)], Vector3(0, 0, -1), Vector4(0, 0, 1, 1), true)
	face(b, g, "pc_crane_glass", xf, [Vector3(0.37, Y_G0, gz1), Vector3(-0.37, Y_G0, gz1), Vector3(-0.37, Y_G1, gz1), Vector3(0.37, Y_G1, gz1)], Vector3(0, 0, 1), Vector4(0.3, 0, 1.0, 1), true)
	face(b, g, "pc_crane_glass", xf, [Vector3(0.387, Y_G0, Z_PNL + 0.03), Vector3(0.387, Y_G0, D - 0.03), Vector3(0.387, Y_G1, D - 0.03), Vector3(0.387, Y_G1, Z_PNL + 0.03)], Vector3.RIGHT, Vector4(1, 0, 0, 1), true)
	face(b, g, "pc_crane_glass", xf, [Vector3(-0.387, Y_G0, D - 0.03), Vector3(-0.387, Y_G0, Z_PNL + 0.03), Vector3(-0.387, Y_G1, Z_PNL + 0.03), Vector3(-0.387, Y_G1, D - 0.03)], Vector3.LEFT, Vector4(0, 0, 0.9, 1), true)

	# ---- prize-box floor with the chute in the front-left corner, its acrylic shield
	var hx = -0.165
	var hz = 0.405
	face(b, g, "pc_crane_deck", xf, [Vector3(hx, Y_DECK, Z_PNL), Vector3(0.39, Y_DECK, Z_PNL), Vector3(0.39, Y_DECK, D), Vector3(hx, Y_DECK, D)], Vector3.UP)
	face(b, g, "pc_crane_deck", xf, [Vector3(-0.39, Y_DECK, hz), Vector3(hx, Y_DECK, hz), Vector3(hx, Y_DECK, D), Vector3(-0.39, Y_DECK, D)], Vector3.UP)
	var yb = 0.62
	face(b, g, "pc_crane_hole", xf, [Vector3(hx, yb, Z_PNL), Vector3(hx, yb, hz), Vector3(hx, Y_DECK, hz), Vector3(hx, Y_DECK, Z_PNL)], Vector3.LEFT)
	face(b, g, "pc_crane_hole", xf, [Vector3(-0.39, yb, hz), Vector3(hx, yb, hz), Vector3(hx, Y_DECK, hz), Vector3(-0.39, Y_DECK, hz)], Vector3(0, 0, -1))
	face(b, g, "pc_crane_hole", xf, [Vector3(-0.39, yb, Z_PNL), Vector3(-0.39, yb, hz), Vector3(-0.39, Y_DECK, hz), Vector3(-0.39, Y_DECK, Z_PNL)], Vector3.RIGHT)
	face(b, g, "pc_crane_hole", xf, [Vector3(-0.39, yb, Z_PNL), Vector3(hx, yb, Z_PNL), Vector3(hx, Y_DECK, Z_PNL), Vector3(-0.39, Y_DECK, Z_PNL)], Vector3(0, 0, 1))
	face(b, g, "pc_crane_hole", xf, [Vector3(-0.39, yb, Z_PNL), Vector3(hx, yb, Z_PNL), Vector3(hx, yb, hz), Vector3(-0.39, yb, hz)], Vector3.UP)
	var sh = 1.12
	face(b, g, "pc_crane_glass", xf, [Vector3(hx, Y_DECK, Z_PNL + 0.02), Vector3(hx, Y_DECK, hz), Vector3(hx, sh, hz), Vector3(hx, sh, Z_PNL + 0.02)], Vector3.RIGHT, Vector4(0.1, 0.55, 0.4, 0.95), true)
	face(b, g, "pc_crane_glass", xf, [Vector3(-0.385, Y_DECK, hz), Vector3(hx, Y_DECK, hz), Vector3(hx, sh, hz), Vector3(-0.385, sh, hz)], Vector3(0, 0, 1), Vector4(0.5, 0.55, 0.8, 0.95), true)
	b.box(g, "pc_crane_alu", Vector3(hx, sh, (Z_PNL + 0.02 + hz) * 0.5), Vector3(0.008, 0.01, hz - Z_PNL - 0.02), xf, [], true)
	b.box(g, "pc_crane_alu", Vector3((-0.385 + hx) * 0.5, sh, hz), Vector3(hx + 0.385, 0.01, 0.008), xf, [], true)

	# ---- header box with backlit marquees and a chrome frame
	b.box(g, body, Vector3(0, (Y_HD + H) * 0.5, (0.14 + D) * 0.5), Vector3(W, H - Y_HD, D - 0.14), xf)
	var hm = "pc_crane_hdr%d" % st
	face(b, g, hm, xf, [Vector3(-0.37, 1.665, 0.138), Vector3(0.37, 1.665, 0.138), Vector3(0.37, 1.955, 0.138), Vector3(-0.37, 1.955, 0.138)], Vector3(0, 0, -1), px(0, 0, 1024, 400, 1024.0, 640.0))
	if "signs" in b:
		# the name is owner-editable (scripts/signs.gd); paint_blanks.py paints the word-free copy
		var mp = []
		for v in [Vector3(-0.37, 1.665, 0.138), Vector3(0.37, 1.665, 0.138), Vector3(0.37, 1.955, 0.138), Vector3(-0.37, 1.955, 0.138)]:
			mp.append(xf * v)
		var rr = px(0, 0, 1024, 400, 1024.0, 640.0)
		var k = 0
		for r0 in b.signs:
			if r0.kind == "pc_crane":
				k += 1
		var looks = [{"font": "sans_italic", "fill": "#fff278", "outline": "#7a0c08"}, {"font": "sans_italic", "fill": "#fff48c", "outline": "#c0207a"}, {"font": "serif", "fill": "#ff5a4a", "outline": "#ffffff"}]
		b.sign_add("pc.crane.%d" % (k + 1), "pc_crane", ["PRIZE CATCHER", "LUCKY GRAB", "SKILL CRANE"][st], st,
			[[mp, [Vector2(rr.x, rr.w), Vector2(rr.z, rr.w), Vector2(rr.z, rr.y), Vector2(rr.x, rr.y)], (xf.basis * Vector3(0, 0, -1)).normalized()]],
			{"tex": "res://tex/pc/crane_header_%d_blank.png" % st, "look": looks[st]})
	var hs = px(0, 416, 512, 640, 1024.0, 640.0)
	b.box(g, "pc_crane_chrome", Vector3(0, 1.962, 0.133), Vector3(0.768, 0.016, 0.012), xf)
	b.box(g, "pc_crane_chrome", Vector3(0, 1.658, 0.133), Vector3(0.768, 0.016, 0.012), xf)
	for sx in [-1.0, 1.0]:
		b.box(g, "pc_crane_chrome", Vector3(sx * 0.377, 1.81, 0.133), Vector3(0.016, 0.288, 0.012), xf)
		b.box(g, "pc_crane_chrome", Vector3(sx * 0.402, 1.81, 0.52), Vector3(0.006, 0.31, 0.68), xf, ["-x" if sx > 0 else "+x"])
	# the side marquees sit in the chrome frame: put them back on top of it
	face(b, g, hm, xf, [Vector3(0.406, 1.67, 0.20), Vector3(0.406, 1.67, 0.84), Vector3(0.406, 1.95, 0.84), Vector3(0.406, 1.95, 0.20)], Vector3.RIGHT, hs)
	face(b, g, hm, xf, [Vector3(-0.406, 1.67, 0.84), Vector3(-0.406, 1.67, 0.20), Vector3(-0.406, 1.95, 0.20), Vector3(-0.406, 1.95, 0.84)], Vector3.LEFT, hs)

	# ---- inside the top: lit diffuser ceiling, the fluorescent tube, gantry rails
	face(b, g, "pc_crane_ceil", xf, [Vector3(-0.39, Y_HD - 0.002, D), Vector3(0.39, Y_HD - 0.002, D), Vector3(0.39, Y_HD - 0.002, Z_PNL), Vector3(-0.39, Y_HD - 0.002, Z_PNL)], Vector3.DOWN)
	pipe(b, g, "pc_crane_tube", [xf * Vector3(-0.345, 1.588, 0.212), xf * Vector3(0.345, 1.588, 0.212)], 0.013, 10, false)
	for sx in [-1.0, 1.0]:
		b.box(g, "pc_crane_blk", Vector3(sx * 0.36, 1.598, 0.212), Vector3(0.03, 0.05, 0.04), xf)
		b.box(g, "pc_crane_steel", Vector3(sx * 0.355, 1.622, 0.55), Vector3(0.025, 0.022, 0.66), xf)
	var cl = CLAW[st]
	var cx = cl[0]
	var czz = cl[1]
	b.box(g, "pc_crane_steel", Vector3(0, 1.604, czz), Vector3(0.70, 0.02, 0.04), xf)
	b.box(g, "pc_crane_steel", Vector3(cx, 1.572, czz), Vector3(0.10, 0.044, 0.09), xf)
	b.box(g, "pc_crane_blk", Vector3(cx + 0.035, 1.575, czz - 0.055), Vector3(0.04, 0.04, 0.03), xf)

	# ---- the plush pile
	var rng = RandomNumberGenerator.new()
	rng.seed = 1995 + st * 7
	var items = []
	var step = 0.098
	var row = 0
	var zz = 0.225
	while zz < D - 0.04:
		var xx = -0.355 + (step * 0.5 if row % 2 else 0.0)
		while xx < 0.37:
			if not (xx < hx + 0.05 and zz < hz + 0.04):
				items.append(Vector2(xx + rng.randf_range(-0.02, 0.02), zz + rng.randf_range(-0.02, 0.02)))
			xx += step
		zz += step * 0.87
		row += 1
	for p in items:
		plush(b, g, xf, rng, st, Vector3(p.x, pile_y(p.x, p.y, st) - 0.045, p.y), false)
	# the top layer: whole animals resting on the pile
	var tops = []
	var tries = 0
	while tops.size() < 8 and tries < 400:
		tries += 1
		var q = Vector2(rng.randf_range(-0.30, 0.30), rng.randf_range(0.27, 0.82))
		if q.x < hx + 0.10 and q.y < hz + 0.08:
			continue
		var ok = true
		for t in tops:
			if t.distance_to(q) < 0.14:
				ok = false
		if ok:
			tops.append(q)
	for q in tops:
		plush(b, g, xf, rng, st, Vector3(q.x, pile_y(q.x, q.y, st) - 0.01, q.y), true)

	# ---- the claw (dynamic): cable, coiled cord, chrome housing and three prongs
	var ytop = cl[2]
	if ytop < 0:
		ytop = pile_y(cx, czz, st) + 0.33
	var cpos = xf * Vector3(cx, ytop, czz)
	var up = xf.basis.y
	pipe(b, g, "pc_crane_blk", [xf * Vector3(cx, 1.55, czz), cpos], 0.0018, 3, true)
	var coil = []
	var L = 1.55 - ytop - 0.01
	var turns = clampi(int(L / 0.025), 3, 8)
	var n = turns * 4
	for k in n + 1:
		var a = TAU * k / 4.0
		coil.append(xf * Vector3(cx + 0.022 + 0.007 * cos(a), 1.55 - L * k / n, czz + 0.007 * sin(a)))
	pipe(b, g, "pc_crane_blk", coil, 0.0022, 3, true)
	b.cyl(g, "pc_crane_chrome", cpos - up * 0.07, 0.032, 0.029, 0.07, 14, true, false, true)
	b.cyl(g, "pc_crane_blk", cpos - up * 0.05, 0.0335, 0.0335, 0.014, 14, false, false, true)
	b.cyl(g, "pc_crane_chrome", cpos - up * 0.095, 0.017, 0.022, 0.025, 10, false, true, true)
	var ybot = ytop - 0.095
	var open = 1.0 if st != 1 else 0.85
	var a0 = rng.randf_range(0, TAU)
	for k in 3:
		var a = a0 + TAU * k / 3.0
		var rd = Vector3(cos(a), 0, sin(a))
		var pts = []
		for pp in [[0.016, 0.004], [0.050, -0.03], [0.064, -0.075], [0.052, -0.118], [0.032, -0.136]]:
			var lp = Vector3(cx, ybot + pp[1], czz) + rd * pp[0] * (open if pp[1] < -0.05 else 1.0)
			pts.append(xf * lp)
		pipe(b, g, "pc_crane_chrome", pts, 0.0042, 5, true)

	b.cur_color = Color.WHITE
	var c0 = xf * Vector3(-W * 0.5, 0, 0)
	var c1 = xf * Vector3(W * 0.5, 0, D)
	b.obst(["rect", min(c0.x, c1.x), min(c0.z, c1.z), max(c0.x, c1.x), max(c0.z, c1.z)])

## Height of the plush pile's surface at local (x, z): a slope up toward the back, lumpy,
## lower beside the chute.
static func pile_y(x, z, st):
	var y = Y_DECK + 0.11 + 0.08 * clampf((z - 0.2) / 0.65, 0.0, 1.0)
	y += 0.025 * sin(x * 11.0 + st * 2.0) * cos(z * 8.0 + st)
	y -= 0.05 * exp(-(pow((x + 0.28) / 0.14, 2) + pow((z - 0.30) / 0.14, 2)))
	return y

static func pick(rng, lst):
	var tot = 0
	for e in lst:
		tot += e[1]
	var r = rng.randi_range(0, tot - 1)
	for e in lst:
		r -= e[1]
		if r < 0:
			return e[0]
	return lst[0][0]

static func fur(i):
	return "pc_crane_fur%d" % i

## One plush animal at local position p (its base). top = a whole animal on the pile
## (dynamic); otherwise a half-buried filler (static body, dynamic face decals).
static func plush(b, g, xf, rng, st, p, top):
	var typ = pick(rng, MIX[st].typ)
	var ci = pick(rng, MIX[st].col)
	var c2 = 2 if ci not in [2, 8] else 0       # muzzle / inner-ear colour
	if ci == 1:
		c2 = 0
	var k = rng.randf_range(0.95, 1.3) if top else rng.randf_range(0.85, 1.15)
	var yaw = rng.randf_range(-0.9, 0.9)
	var tilt = rng.randf_range(0.15, 0.6)
	if not top:
		yaw = rng.randf_range(-PI, PI)
		tilt = rng.randf_range(0.6, 1.5)        # filler lies on its back or side
	elif rng.randf() < 0.25:
		tilt = rng.randf_range(1.0, 1.4)
	var roll = rng.randf_range(-0.35, 0.35)
	var ib = Basis(Vector3.UP, yaw) * Basis(Vector3.FORWARD, roll) * Basis(Vector3.RIGHT, tilt)
	# keep the whole animal inside the glass: clamp its middle, with room for its size
	var mid = p + ib * Vector3(0, 0.1 * k, 0)
	var mx = clampf(mid.x, -0.38 + 0.1 * k, 0.38 - 0.1 * k)
	var mzc = clampf(mid.z, Z_PNL + 0.02 + 0.1 * k, D - 0.015 - 0.1 * k)
	p += Vector3(mx - mid.x, 0, mzc - mid.z)
	var wb = xf.basis * ib
	var dyn = top
	var at = func(v): return xf * (p + ib * (v * k))
	var sg = 1 if top else 0                    # detail step
	match typ:
		"ball":
			var r = 0.078 * k
			var other = (ci + 3 + rng.randi_range(0, 5)) % FUR.size()
			ell(b, g, [fur(ci), fur(other)], xf * (p + Vector3(0, r * 0.75, 0)), Vector3(r, r * 0.93, r), wb, 8 + 2 * sg, 5 + sg, dyn)
		"pom":
			var r = 0.07 * k
			ell(b, g, fur(ci), at.call(Vector3(0, 0.065, 0)), Vector3(r, r * 0.92, r), wb, 7 + sg, 4 + sg, dyn, Vector2(3, 1.5))
			var fc = at.call(Vector3(0, 0.085, -0.066))
			var fn = (wb * Vector3(0, 0.25, -1)).normalized()
			for sx in [-1.0, 1.0]:
				decal(b, g, at.call(Vector3(sx * 0.024, 0.09, -0.064)), fn, wb.y, 0.024 * k, px(3, 46, 39, 82, 256.0, 128.0))
			if top:
				for sx in [-1.0, 1.0]:
					ell(b, g, fur(c2), at.call(Vector3(sx * 0.032, 0.006, -0.035)), Vector3(0.022, 0.014, 0.03) * k, wb, 6, 3, dyn)
		_:
			# bear / dog / bunny share a body plan
			if top or rng.randf() < 0.5:
				ell(b, g, fur(ci), at.call(Vector3(0, 0.065, 0)), Vector3(0.06, 0.07, 0.052) * k, wb, 6 + sg, 4 + sg, dyn)
			var hc = Vector3(0, 0.158, -0.004)
			ell(b, g, fur(ci), at.call(hc), Vector3(0.056, 0.052, 0.05) * k, wb, 7 + sg, 4 + sg, dyn)
			var mz = Vector3(0, 0.143, -0.046)
			var mr = Vector3(0.026, 0.02, 0.019)
			if typ == "dog":
				mz = Vector3(0, 0.142, -0.056); mr = Vector3(0.027, 0.022, 0.03)
			ell(b, g, fur(c2), at.call(mz), mr * k, wb, 5 + sg, 2 + sg, dyn)
			match typ:
				"bear":
					for sx in [-1.0, 1.0]:
						ell(b, g, fur(ci), at.call(Vector3(sx * 0.041, 0.202, 0.0)), Vector3(0.021, 0.021, 0.012) * k, wb, 5, 2 + sg, dyn)
				"dog":
					var ec = 1 if ci != 1 else 13
					for sx in [-1.0, 1.0]:
						var eb = wb * Basis(Vector3.BACK, sx * 0.35)
						ell(b, g, fur(ec), at.call(Vector3(sx * 0.054, 0.15, 0.0)), Vector3(0.013, 0.042, 0.026) * k, eb, 5, 3, dyn)
				"bunny":
					for sx in [-1.0, 1.0]:
						var eb = wb * Basis(Vector3.BACK, -sx * 0.22)
						ell(b, g, fur(ci), at.call(Vector3(sx * 0.026, 0.235, 0.002)), Vector3(0.017, 0.058, 0.009) * k, eb, 5, 3, dyn)
			# eyes and nose decals on the head
			var hcen = hc
			for sx in [-1.0, 1.0]:
				var dirn = Vector3(sx * 0.42, 0.25, -0.87).normalized()
				var sp = hcen + Vector3(dirn.x * 0.056, dirn.y * 0.052, dirn.z * 0.05)
				var nw = (wb * Vector3(dirn.x / 0.056, dirn.y / 0.052, dirn.z / 0.05)).normalized()
				decal(b, g, at.call(sp), nw, wb.y, 0.017 * k, px(3, 46, 39, 82, 256.0, 128.0))
			var np = mz + Vector3(0, 0.004, -mr.z + 0.001)
			decal(b, g, at.call(np), (wb * Vector3(0, 0.25, -1)).normalized(), wb.y, 0.026 * k, px(150, 6, 238, 110, 256.0, 128.0))
			if top:
				for sx in [-1.0, 1.0]:
					ell(b, g, fur(ci), at.call(Vector3(sx * 0.058, 0.085, -0.022)), Vector3(0.02, 0.042, 0.02) * k, wb * Basis(Vector3.BACK, sx * 0.45), 5, 3, dyn)
					ell(b, g, fur(ci), at.call(Vector3(sx * 0.034, 0.02, -0.04)), Vector3(0.024, 0.022, 0.038) * k, wb, 5, 3, dyn)

# ------------------------------------------------------------------ materials
## Material "pc_crane_<key>".
static func fill_mat(m, key, b):
	if key.begins_with("fur"):
		var c = Color(FUR[int(key.substr(3))])
		m.albedo_texture = b.tex("pc/crane_fur.png")
		m.albedo_color = c
		m.roughness = 1.0
		m.rim_enabled = true; m.rim = 0.35; m.rim_tint = 0.6
		# the tube and the lit ceiling wash the pile; this keeps it glowing through the glass
		m.emission_enabled = true; m.emission_texture = m.albedo_texture; m.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY
		m.emission = c; m.emission_energy_multiplier = 0.5
		m.set_meta("e_day", 0.5); m.set_meta("e_night", 0.5)
		return true
	for s in 3:
		if key == "cab%d" % s:
			m.albedo_texture = b.tex("pc/crane_cab_%d.png" % s); m.roughness = 0.42; m.metallic_specular = 0.55
			return true
		if key == "body%d" % s:
			m.albedo_color = Color(CAB_COL[s]); m.roughness = 0.45; m.metallic_specular = 0.5
			return true
		if key == "hdr%d" % s:
			m.albedo_texture = b.tex("pc/crane_header_%d.png" % s); m.roughness = 0.25
			m.emission_enabled = true; m.emission_texture = m.albedo_texture; m.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY; m.emission = Color.WHITE
			m.emission_energy_multiplier = 1.35
			m.set_meta("e_day", 1.35); m.set_meta("e_night", 1.35)
			return true
		if key == "btn%d" % s:
			var c = Color(BTN_COL[s])
			m.albedo_color = c; m.roughness = 0.25
			m.emission_enabled = true; m.emission = c; m.emission_energy_multiplier = 2.0
			m.set_meta("e_day", 2.0); m.set_meta("e_night", 2.0)
			return true
	match key:
		"panel":
			m.albedo_texture = b.tex("pc/crane_panel.png"); m.roughness = 0.5
		"lamp":
			m.albedo_texture = b.tex("pc/crane_panel.png"); m.roughness = 0.3
			m.emission_enabled = true; m.emission_texture = m.albedo_texture; m.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY; m.emission = Color.WHITE
			m.emission_energy_multiplier = 1.8
			m.set_meta("e_day", 1.8); m.set_meta("e_night", 1.8)
		"blk":
			m.albedo_color = Color("#121214"); m.roughness = 0.5
		"hole":
			m.albedo_color = Color("#040404"); m.roughness = 1.0
		"deck":
			m.albedo_color = Color("#1e1e22"); m.roughness = 0.95
		"alu":
			m.albedo_color = Color("#c2c6cc"); m.metallic = 0.85; m.roughness = 0.32
		"chrome":
			m.albedo_color = Color("#e6e9ee"); m.metallic = 0.75; m.roughness = 0.16
		"steel":
			m.albedo_color = Color("#5a5d63"); m.metallic = 0.6; m.roughness = 0.45
		"ball":
			m.albedo_color = Color("#d01818"); m.roughness = 0.2; m.metallic_specular = 0.7
		"glass":
			m.albedo_texture = b.tex("pc/crane_glass.png")
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.albedo_color = Color(1, 1, 1, 1)
			m.roughness = 0.04; m.metallic_specular = 0.9
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
		"tube":
			m.albedo_color = Color.WHITE
			m.emission_enabled = true; m.emission = Color("#eef5ff"); m.emission_energy_multiplier = 4.0
			m.set_meta("e_day", 4.0); m.set_meta("e_night", 4.0)
		"ceil":
			m.albedo_color = Color("#e8ecf0"); m.roughness = 0.8
			m.emission_enabled = true; m.emission = Color("#e6eeff"); m.emission_energy_multiplier = 0.8
			m.set_meta("e_day", 0.8); m.set_meta("e_night", 0.8)
		"face":
			m.albedo_texture = b.tex("pc/crane_face.png")
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			m.alpha_scissor_threshold = 0.5
			m.roughness = 0.2
		_:
			return false
	return true
