## Pocket Change prop module `hoops`: a 1990s ticket-redemption basketball cage game.
## Contract: tools/stores/pocket_change/README.md. Textures: paint_hoops.py -> tex/pc/hoops_*.png.
##
## Form (from Steven's reference photo and the 1990s cage games' published specs, ~30-42 in
## wide, ~10 ft long, ~8.5 ft tall): a black laminate lower cabinet with coin door, ticket
## dispenser and START button; a ball tray at waist height; a score panel (red LED SCORE and
## TIME) the balls roll under; an inclined ball floor rising to the back; a red steel cage with
## red welded-wire mesh on the sides and roof; a white backboard with an orange ring and white
## net; a fluorescent-lit header across the front top. Invented title: BAYOU BUCKETS.
## opts: {"number": 1..4} picks the number plate, the LED readout, the balls left in the tray
## and the length of the ticket strip, so a row of four does not look cloned.
##
## Preview:
##   tools/qa/preview.sh hoops /home/claude/houma-mall-rewind/.scratch/preview/hoops/a \
##     "0,1.6,2.6,0,-12;2.2,1.7,1.4,40,-12;3.6,1.6,-1.45,90,-6" '{"number":1}' lit

const W = 1.02    # width (player's right)
const D = 2.90    # depth (into the machine)
const H = 2.68    # top of the header
const HW = 0.51
const IN = 0.49   # inner face of the side walls
const BALL_R = 0.09
# ball floor: (z, y) points, tray at the front, ramp rising to the back
const FL = [Vector2(0.06, 0.80), Vector2(0.56, 0.85), Vector2(2.86, 1.13)]
const PANEL_Z = 0.44
const PANEL_Y0 = 1.05
const PANEL_Y1 = 1.42
const ROOF_Y = 2.60
const MQ_Y0 = 2.30
const RIM_C = Vector3(0, 1.95, 2.59)
const RIM_R = 0.19

## Footprint (width, depth) in metres: four abut side by side.
static func footprint(_opts = {}):
	return Vector2(W, D)

static func X(o, f):
	return Transform3D(Basis(f.cross(Vector3.UP), Vector3.UP, f), o)

## Top of the solid side wall at depth z.
static func side_top(z):
	if z <= PANEL_Z:
		return 0.90
	return lerp(1.15, 1.42, clamp((z - 0.56) / (D - 0.56), 0.0, 1.0))

## Ball-floor height at depth z.
static func floor_y(z):
	if z <= FL[1].x:
		return lerp(FL[0].y, FL[1].y, (z - FL[0].x) / (FL[1].x - FL[0].x))
	return lerp(FL[1].y, FL[2].y, (z - FL[1].x) / (FL[2].x - FL[1].x))

# ---------------------------------------------------------------- helpers
## A quad from local points with a local normal.
static func q(b, g, m, xf, p, n, uvs = [], dyn = false):
	var w = []
	for v in p:
		w.append(xf * v)
	b.quad(g, m, w, (xf.basis * n).normalized(), uvs, dyn)

## Rect UVs (0,0) top-left for a quad given bottom-left, bottom-right, top-right, top-left.
static func ruv(u0 = 0.0, v0 = 0.0, u1 = 1.0, v1 = 1.0):
	return [Vector2(u0, v1), Vector2(u1, v1), Vector2(u1, v0), Vector2(u0, v0)]

## A box whose long axis runs from local point a to local point c (a tube or rail).
static func obox(b, g, m, xf, a, c, w, h, dyn = false):
	var z = (c - a).normalized()
	var x = Vector3.UP.cross(z)
	if x.length() < 0.01:
		x = Vector3.RIGHT
	x = x.normalized()
	var y = z.cross(x).normalized()
	var t = Transform3D(Basis(x, y, z), (a + c) * 0.5)
	b.box(g, m, Vector3.ZERO, Vector3(w, h, (c - a).length()), xf * t, [], dyn)

## One smooth-shaded triangle (world points, per-vertex normals).
static func stri(b, s, p, n, uv):
	var fn = (n[0] + n[1] + n[2]).normalized()
	var order = [0, 1, 2]
	if (p[1] - p[0]).cross(p[2] - p[0]).dot(fn) > 0.0:
		order = [0, 2, 1]
	for i in order:
		s.set_color(b.cur_color); s.set_normal(n[i]); s.set_uv(uv[i]); s.add_vertex(p[i])

## Smooth grid surface: P(i, j) / N(i, j) callables over (nu+1) x (nv+1) vertices.
static func grid(b, s, xf, nu, nv, P, N, uvs):
	for i in nu:
		for j in nv:
			var ids = [[i, j], [i + 1, j], [i + 1, j + 1], [i, j + 1]]
			var p = []; var n = []; var uv = []
			for k in ids:
				p.append(xf * P.call(k[0], k[1]))
				n.append((xf.basis * N.call(k[0], k[1])).normalized())
				uv.append(uvs.call(k[0], k[1]))
			stri(b, s, [p[0], p[1], p[2]], [n[0], n[1], n[2]], [uv[0], uv[1], uv[2]])
			stri(b, s, [p[0], p[2], p[3]], [n[0], n[2], n[3]], [uv[0], uv[2], uv[3]])

## A sphere (dynamic): centre c (local), radius r, spun by basis rb.
static func sphere(b, g, m, xf, c, r, rb, nu = 12, nv = 8):
	var s = b.st(g, m, true)
	var N = func(i, j):
		var lon = TAU * i / nu
		var lat = PI * (0.5 - float(j) / nv)
		return rb * Vector3(cos(lat) * cos(lon), sin(lat), cos(lat) * sin(lon))
	var P = func(i, j): return c + N.call(i, j) * r
	var U = func(i, j): return Vector2(float(i) / nu, float(j) / nv)
	grid(b, s, xf, nu, nv, P, N, U)

## A horizontal ring (torus) round local centre c.
static func torus(b, g, m, xf, c, R, r, nu = 24, nv = 8):
	var s = b.st(g, m, true)
	var N = func(i, j):
		var th = TAU * i / nu
		var ph = TAU * j / nv
		return Vector3(cos(ph) * cos(th), sin(ph), cos(ph) * sin(th))
	var P = func(i, j):
		var th = TAU * i / nu
		return c + Vector3(cos(th), 0, sin(th)) * R + N.call(i, j) * r
	var U = func(i, j): return Vector2(float(i) / nu, float(j) / nv)
	grid(b, s, xf, nu, nv, P, N, U)

## A short cylinder (button, bezel) on the local axis ax from base c, capped at the far end.
static func ocyl(b, g, m, xf, c, ax, r, l, seg = 16):
	var s = b.st(g, m, true)
	var u = ax.cross(Vector3.UP)
	if u.length() < 0.01:
		u = Vector3.RIGHT
	u = u.normalized()
	var v = ax.cross(u).normalized()
	var top = c + ax * l
	for i in seg:
		var a0 = TAU * i / seg
		var a1 = TAU * (i + 1) / seg
		var d0 = u * cos(a0) + v * sin(a0)
		var d1 = u * cos(a1) + v * sin(a1)
		var n0 = (xf.basis * d0).normalized()
		var n1 = (xf.basis * d1).normalized()
		var p = [xf * (c + d0 * r), xf * (c + d1 * r), xf * (top + d1 * r), xf * (top + d0 * r)]
		var uv = [Vector2(0.5, 0.9), Vector2(0.5, 0.9), Vector2(0.5, 0.6), Vector2(0.5, 0.6)]
		stri(b, s, [p[0], p[1], p[2]], [n0, n1, n1], [uv[0], uv[1], uv[2]])
		stri(b, s, [p[0], p[2], p[3]], [n0, n1, n0], [uv[0], uv[2], uv[3]])
		var an = (xf.basis * ax).normalized()
		stri(b, s, [xf * top, p[3], p[2]], [an, an, an], [Vector2(0.5, 0.5), Vector2(0.5 + cos(a0) * 0.5, 0.5 + sin(a0) * 0.5), Vector2(0.5 + cos(a1) * 0.5, 0.5 + sin(a1) * 0.5)])

# ---------------------------------------------------------------- build
## Builds one machine. The player stands at `o` (floor, centre of the front edge) facing `f`.
static func build(b, g, o, f, opts = {}):
	var xf = X(o, f)
	var num = clampi(int(opts.get("number", 1)), 1, 4)
	var rng = RandomNumberGenerator.new()
	rng.seed = 7700 + num
	var L = Vector3.LEFT; var R = Vector3.RIGHT; var UP = Vector3.UP
	var FR = Vector3(0, 0, -1); var BK = Vector3(0, 0, 1)

	# ---- lower front cabinet: painted face, red rim on top
	q(b, g, "pc_hoops_front", xf, [Vector3(-HW, 0, 0), Vector3(HW, 0, 0), Vector3(HW, 0.90, 0), Vector3(-HW, 0.90, 0)], FR, ruv())
	b.box(g, "pc_hoops_paint", Vector3(0, 0.89, 0.03), Vector3(W, 0.03, 0.06), xf)
	# front corner T-molding
	for sx in [-1, 1]:
		b.box(g, "pc_hoops_bezel", Vector3(sx * (HW - 0.006), 0.45, 0.006), Vector3(0.016, 0.90, 0.016), xf)
	# lip inside the tray
	q(b, g, "pc_hoops_lam", xf, [Vector3(IN, 0.79, 0.06), Vector3(-IN, 0.79, 0.06), Vector3(-IN, 0.875, 0.06), Vector3(IN, 0.875, 0.06)], BK)

	# ---- ball floor: tray + ramp (one texture, v = 0 at the back)
	var vlen = FL[2].x - FL[0].x
	for k in 2:
		var a = FL[k]; var c = FL[k + 1]
		var va = (FL[2].x - a.x) / vlen; var vc = (FL[2].x - c.x) / vlen
		var n = Vector3(0, c.x - a.x, -(c.y - a.y)).normalized()
		q(b, g, "pc_hoops_ramp", xf, [Vector3(-IN, a.y, a.x), Vector3(IN, a.y, a.x), Vector3(IN, c.y, c.x), Vector3(-IN, c.y, c.x)], n,
			[Vector2(0, va), Vector2(1, va), Vector2(1, vc), Vector2(0, vc)])

	# ---- side walls: outer painted faces and inner laminate
	for sx in [-1, 1]:
		var xo = sx * HW
		var xi = sx * IN
		var no = R * sx
		# outer UV: the viewer's right is the machine front on the right side, its back on the left
		var U = func(z): return (z / D) if sx > 0 else 1.0 - z / D
		var V = func(y): return 1.0 - y / 1.45
		var segs = [[0.0, PANEL_Z, 0.0, 0.0, 0.90, 0.90], [PANEL_Z, 0.56, 0.0, 0.0, 1.45, 1.45], [0.56, D, 0.0, 0.0, 1.15, 1.42]]
		for sg in segs:
			var z0 = sg[0]; var z1 = sg[1]
			q(b, g, "pc_hoops_side", xf, [Vector3(xo, sg[2], z0), Vector3(xo, sg[3], z1), Vector3(xo, sg[5], z1), Vector3(xo, sg[4], z0)], no,
				[Vector2(U.call(z0), V.call(sg[2])), Vector2(U.call(z1), V.call(sg[3])), Vector2(U.call(z1), V.call(sg[5])), Vector2(U.call(z0), V.call(sg[4]))])
		# inner faces above the ball floor
		var ni = -no
		q(b, g, "pc_hoops_lam", xf, [Vector3(xi, 0.79, 0.06), Vector3(xi, 0.85, PANEL_Z), Vector3(xi, 0.90, PANEL_Z), Vector3(xi, 0.90, 0.06)], ni)
		q(b, g, "pc_hoops_lam", xf, [Vector3(xi, 0.84, PANEL_Z), Vector3(xi, 0.85, 0.56), Vector3(xi, 1.45, 0.56), Vector3(xi, 1.45, PANEL_Z)], ni)
		q(b, g, "pc_hoops_lam", xf, [Vector3(xi, floor_y(0.56), 0.56), Vector3(xi, floor_y(2.86), 2.86), Vector3(xi, side_top(2.86), 2.86), Vector3(xi, side_top(0.56), 0.56)], ni)
		# top rails: over the tray wall, and the sloped one along the ramp
		var xr = sx * (HW - 0.022)
		obox(b, g, "pc_hoops_paint", xf, Vector3(xr, 0.905, 0.0), Vector3(xr, 0.905, PANEL_Z), 0.044, 0.03)
		obox(b, g, "pc_hoops_paint", xf, Vector3(xr, side_top(0.56) + 0.02, 0.56), Vector3(xr, side_top(D) + 0.02, D), 0.044, 0.04)
		# cage: front post, mid post, back post, roof rail, mid rail
		b.box(g, "pc_hoops_paint", Vector3(xr, (1.46 + MQ_Y0) * 0.5, 0.48), Vector3(0.044, MQ_Y0 - 1.46, 0.04), xf)
		b.box(g, "pc_hoops_paint", Vector3(xr, (side_top(1.72) + ROOF_Y) * 0.5, 1.72), Vector3(0.044, ROOF_Y - side_top(1.72), 0.04), xf)
		b.box(g, "pc_hoops_paint", Vector3(xr, (side_top(D) + ROOF_Y) * 0.5, 2.86), Vector3(0.044, ROOF_Y - side_top(D), 0.04), xf)
		obox(b, g, "pc_hoops_paint", xf, Vector3(xr, ROOF_Y, 0.62), Vector3(xr, ROOF_Y, D - 0.02), 0.044, 0.04)
		obox(b, g, "pc_hoops_paint", xf, Vector3(xr, 1.95, 0.50), Vector3(xr, 1.95, 2.84), 0.03, 0.025)
		# wire mesh (dynamic, alpha): above the panel housing, then over the ramp wall
		var xm = sx * (HW - 0.024)
		var muv = func(z, y): return Vector2(z / 0.2, (2.7 - y) / 0.2)
		q(b, g, "pc_hoops_mesh", xf, [Vector3(xm, 1.46, 0.50), Vector3(xm, 1.46, 0.56), Vector3(xm, ROOF_Y, 0.56), Vector3(xm, ROOF_Y, 0.50)], no,
			[muv.call(0.50, 1.46), muv.call(0.56, 1.46), muv.call(0.56, ROOF_Y), muv.call(0.50, ROOF_Y)], true)
		var y0 = side_top(0.56) + 0.04; var y1 = side_top(2.86) + 0.04
		q(b, g, "pc_hoops_mesh", xf, [Vector3(xm, y0, 0.56), Vector3(xm, y1, 2.86), Vector3(xm, ROOF_Y, 2.86), Vector3(xm, ROOF_Y, 0.56)], no,
			[muv.call(0.56, y0), muv.call(2.86, y1), muv.call(2.86, ROOF_Y), muv.call(0.56, ROOF_Y)], true)
	# roof rails across, and the roof mesh
	for z in [1.72, 2.86]:
		obox(b, g, "pc_hoops_paint", xf, Vector3(-HW + 0.044, ROOF_Y, z), Vector3(HW - 0.044, ROOF_Y, z), 0.04, 0.04)
	q(b, g, "pc_hoops_mesh", xf, [Vector3(-IN, ROOF_Y + 0.01, 0.64), Vector3(IN, ROOF_Y + 0.01, 0.64), Vector3(IN, ROOF_Y + 0.01, 2.86), Vector3(-IN, ROOF_Y + 0.01, 2.86)], UP,
		[Vector2(-IN / 0.2, 0.64 / 0.2), Vector2(IN / 0.2, 0.64 / 0.2), Vector2(IN / 0.2, 2.86 / 0.2), Vector2(-IN / 0.2, 2.86 / 0.2)], true)

	# ---- score panel housing: the balls roll under it into the tray
	b.box(g, "pc_hoops_lam", Vector3(0, (PANEL_Y0 + 1.45) * 0.5, (PANEL_Z + 0.56) * 0.5), Vector3(W - 0.004, 1.45 - PANEL_Y0, 0.56 - PANEL_Z), xf, ["+x", "-x", "-z"])
	q(b, g, "pc_hoops_panel", xf, [Vector3(-HW, PANEL_Y0, PANEL_Z), Vector3(HW, PANEL_Y0, PANEL_Z), Vector3(HW, PANEL_Y1, PANEL_Z), Vector3(-HW, PANEL_Y1, PANEL_Z)], FR, ruv())
	b.box(g, "pc_hoops_paint", Vector3(0, 1.44, (PANEL_Z + 0.56) * 0.5), Vector3(W, 0.04, 0.56 - PANEL_Z + 0.02), xf)
	b.box(g, "pc_hoops_paint", Vector3(0, PANEL_Y0 + 0.012, PANEL_Z + 0.01), Vector3(W - 0.004, 0.024, 0.03), xf)
	# LED windows: this machine's row of the readout texture
	var rv0 = (num - 1) * 0.25
	var zl = PANEL_Z - 0.004
	q(b, g, "pc_hoops_led", xf, [Vector3(-0.36, 1.205, zl), Vector3(-0.035, 1.205, zl), Vector3(-0.035, 1.335, zl), Vector3(-0.36, 1.335, zl)], FR, ruv(0.0, rv0, 0.625, rv0 + 0.25))
	q(b, g, "pc_hoops_led", xf, [Vector3(0.065, 1.205, zl), Vector3(0.26, 1.205, zl), Vector3(0.26, 1.335, zl), Vector3(0.065, 1.335, zl)], FR, ruv(0.6406, rv0, 1.0, rv0 + 0.25))

	# ---- back: back wall, backboard, lamp hood
	q(b, g, "pc_hoops_lam", xf, [Vector3(HW, 0, D), Vector3(-HW, 0, D), Vector3(-HW, ROOF_Y + 0.02, D), Vector3(HW, ROOF_Y + 0.02, D)], BK)
	q(b, g, "pc_hoops_lam", xf, [Vector3(-IN, floor_y(2.86), 2.86), Vector3(IN, floor_y(2.86), 2.86), Vector3(IN, ROOF_Y, 2.86), Vector3(-IN, ROOF_Y, 2.86)], FR)
	b.box(g, "pc_hoops_paint", Vector3(0, ROOF_Y + 0.01, D - 0.02), Vector3(W, 0.04, 0.04), xf)
	b.box(g, "pc_hoops_lam", Vector3(0, 2.18, 2.835), Vector3(0.90, 0.60, 0.025), xf, ["-z"])
	q(b, g, "pc_hoops_board", xf, [Vector3(-0.45, 1.88, 2.8225), Vector3(0.45, 1.88, 2.8225), Vector3(0.45, 2.48, 2.8225), Vector3(-0.45, 2.48, 2.8225)], FR, ruv())
	b.box(g, "pc_hoops_paint", Vector3(0, 2.545, 2.79), Vector3(0.80, 0.05, 0.14), xf, ["-y"])
	q(b, g, "pc_hoops_lamp", xf, [Vector3(-0.38, 2.52, 2.73), Vector3(0.38, 2.52, 2.73), Vector3(0.38, 2.52, 2.85), Vector3(-0.38, 2.52, 2.85)], Vector3.DOWN, ruv())

	# ---- header (marquee): red box, backlit face
	b.box(g, "pc_hoops_paint", Vector3(0, (MQ_Y0 + H) * 0.5, 0.53), Vector3(W, H - MQ_Y0, 0.22), xf, ["-z"])
	var zf = 0.42
	q(b, g, "pc_hoops_paint", xf, [Vector3(-HW, MQ_Y0, zf), Vector3(HW, MQ_Y0, zf), Vector3(HW, MQ_Y0 + 0.02, zf), Vector3(-HW, MQ_Y0 + 0.02, zf)], FR)
	q(b, g, "pc_hoops_paint", xf, [Vector3(-HW, H - 0.02, zf), Vector3(HW, H - 0.02, zf), Vector3(HW, H, zf), Vector3(-HW, H, zf)], FR)
	q(b, g, "pc_hoops_paint", xf, [Vector3(-HW, MQ_Y0 + 0.02, zf), Vector3(-0.49, MQ_Y0 + 0.02, zf), Vector3(-0.49, H - 0.02, zf), Vector3(-HW, H - 0.02, zf)], FR)
	q(b, g, "pc_hoops_paint", xf, [Vector3(0.49, MQ_Y0 + 0.02, zf), Vector3(HW, MQ_Y0 + 0.02, zf), Vector3(HW, H - 0.02, zf), Vector3(0.49, H - 0.02, zf)], FR)
	q(b, g, "pc_hoops_marquee", xf, [Vector3(-0.49, MQ_Y0 + 0.02, zf + 0.004), Vector3(0.49, MQ_Y0 + 0.02, zf + 0.004), Vector3(0.49, H - 0.02, zf + 0.004), Vector3(-0.49, H - 0.02, zf + 0.004)], FR, ruv())
	if "signs" in b:
		# the name is owner-editable (scripts/signs.gd); paint_blanks.py paints the word-free copy
		var mp = []
		for v in [Vector3(-0.49, MQ_Y0 + 0.02, zf + 0.004), Vector3(0.49, MQ_Y0 + 0.02, zf + 0.004), Vector3(0.49, H - 0.02, zf + 0.004), Vector3(-0.49, H - 0.02, zf + 0.004)]:
			mp.append(xf * v)
		b.sign_add("pc.hoops.%d" % num, "pc_hoops", "BAYOU BUCKETS", 0, [[mp, ruv(), (xf.basis * FR).normalized()]],
			{"tex": "res://tex/pc/hoops_marquee_blank.png", "look": {"font": "sans_italic", "fill": "#ffe878", "outline": "#c81c22"}})

	# ---- coin door (static plate) and machine number plate
	var dz = -0.012
	b.box(g, "pc_hoops_bezel", Vector3(0.02, 0.41, -0.006), Vector3(0.30, 0.44, 0.012), xf, ["+z", "-z"])
	q(b, g, "pc_hoops_door", xf, [Vector3(-0.13, 0.19, dz), Vector3(0.17, 0.19, dz), Vector3(0.17, 0.63, dz), Vector3(-0.13, 0.63, dz)], FR, ruv())
	var pu = (num - 1) * 0.25
	q(b, g, "pc_hoops_plate", xf, [Vector3(-0.45, 0.775, -0.003), Vector3(-0.38, 0.775, -0.003), Vector3(-0.38, 0.845, -0.003), Vector3(-0.45, 0.845, -0.003)], FR, ruv(pu, 0.0, pu + 0.25, 1.0))

	# ---- small dynamic parts: buttons, ticket dispenser, hoop, net, balls
	for rx in [-0.045, 0.085]:
		ocyl(b, g, "pc_hoops_bezel", xf, Vector3(rx, 0.492, dz), FR, 0.016, 0.004)
		ocyl(b, g, "pc_hoops_rej", xf, Vector3(rx, 0.492, dz - 0.004), FR, 0.012, 0.008)
	ocyl(b, g, "pc_hoops_bezel", xf, Vector3(0.355, 0.79, 0.0), FR, 0.038, 0.012, 20)
	ocyl(b, g, "pc_hoops_btn", xf, Vector3(0.355, 0.79, -0.012), FR, 0.029, 0.014, 20)
	# ticket dispenser bezel and the strip of tickets hanging out
	b.box(g, "pc_hoops_chrome", Vector3(0.355, 0.585, -0.01), Vector3(0.09, 0.055, 0.02), xf, ["+z"], true)
	q(b, g, "pc_hoops_bezel", xf, [Vector3(0.335, 0.578, -0.0205), Vector3(0.375, 0.578, -0.0205), Vector3(0.375, 0.584, -0.0205), Vector3(0.335, 0.584, -0.0205)], FR, [], true)
	var tl = 0.12 + 0.06 * num + rng.randf_range(0.0, 0.04)
	var pts = []
	var p = Vector3(0, 0.581, -0.021)
	var dir = Vector3(0, -0.15, -1).normalized()
	var stepl = 0.02
	var nseg = int(tl / stepl)
	pts.append(p)
	for i in nseg:
		var t = float(i) / nseg
		var target = Vector3(0, -1, -0.12 + 0.5 * t * t).normalized()
		dir = dir.lerp(target, 0.35).normalized()
		p = p + dir * stepl
		p.z = min(p.z, -0.024)
		pts.append(p)
	var tw = 0.0145
	var twist = rng.randf_range(-0.1, 0.1)
	for i in pts.size() - 1:
		var a = pts[i]; var c = pts[i + 1]
		var sd = (c - a).normalized()
		var nn = sd.cross(Vector3.RIGHT).normalized()
		var off_a = Vector3(0.355 + twist * a.y * 0.0, 0, 0)
		var va = i * stepl / 0.102; var vc = (i + 1) * stepl / 0.102
		var ox = twist * (0.581 - a.y)
		var oxc = twist * (0.581 - c.y)
		q(b, g, "pc_hoops_ticket", xf, [a + off_a + Vector3(-tw + ox, 0, 0), a + off_a + Vector3(tw + ox, 0, 0), c + off_a + Vector3(tw + oxc, 0, 0), c + off_a + Vector3(-tw + oxc, 0, 0)], nn,
			[Vector2(0, va), Vector2(1, va), Vector2(1, vc), Vector2(0, vc)], true)
	# hoop: orange ring on a bracket, white net
	torus(b, g, "pc_hoops_rim", xf, RIM_C, RIM_R, 0.0095)
	b.box(g, "pc_hoops_rim", Vector3(0, RIM_C.y, (RIM_C.z + RIM_R + 2.8225) * 0.5), Vector3(0.10, 0.03, 2.8225 - RIM_C.z - RIM_R + 0.01), xf, [], true)
	b.box(g, "pc_hoops_rim", Vector3(0, RIM_C.y + 0.02, 2.818), Vector3(0.16, 0.11, 0.01), xf, ["+z"], true)
	var ns = 16
	var nt = b.st(g, "pc_hoops_net", true)
	var ytop = RIM_C.y - 0.005; var ybot = RIM_C.y - 0.33
	var rtop = RIM_R - 0.005; var rbot = 0.115
	for i in ns:
		var a0 = TAU * i / ns; var a1 = TAU * (i + 1) / ns
		var sway = 0.012 * sin(a0 * 3.0 + num)
		var p0 = RIM_C + Vector3(cos(a0) * rtop, ytop - RIM_C.y, sin(a0) * rtop)
		var p1 = RIM_C + Vector3(cos(a1) * rtop, ytop - RIM_C.y, sin(a1) * rtop)
		var p2 = RIM_C + Vector3(cos(a1) * rbot + sway, ybot - RIM_C.y, sin(a1) * rbot)
		var p3 = RIM_C + Vector3(cos(a0) * rbot + sway, ybot - RIM_C.y, sin(a0) * rbot)
		var n0 = (xf.basis * Vector3(cos(a0), 0.2, sin(a0))).normalized()
		var n1 = (xf.basis * Vector3(cos(a1), 0.2, sin(a1))).normalized()
		var u0 = 2.0 * i / ns; var u1 = 2.0 * (i + 1) / ns
		stri(b, nt, [xf * p0, xf * p1, xf * p2], [n0, n1, n1], [Vector2(u0, 0), Vector2(u1, 0), Vector2(u1, 1)])
		stri(b, nt, [xf * p0, xf * p2, xf * p3], [n0, n1, n0], [Vector2(u0, 0), Vector2(u1, 1), Vector2(u0, 1)])
	# balls: some in the tray, one under the panel, maybe one rolling down the ramp
	var spots = []
	for x in [-0.38, -0.19, 0.0, 0.19, 0.38]:
		spots.append(Vector3(x, 0.0, FL[0].x + BALL_R + 0.003))
	for x in [-0.285, -0.095, 0.095, 0.285]:
		spots.append(Vector3(x, 0.0, 0.33))
	var chosen = []
	for i in 5:
		if rng.randf() < 0.75:
			chosen.append(spots[i] + Vector3(rng.randf_range(-0.012, 0.012), 0, 0))
	for i in range(5, 9):
		if rng.randf() < 0.3:
			chosen.append(spots[i])
	if rng.randf() < 0.6:
		chosen.append(Vector3(rng.randf_range(-0.3, 0.3), 0, 0.50))
	if rng.randf() < 0.5:
		chosen.append(Vector3(rng.randf_range(-0.3, 0.3), 0, rng.randf_range(1.0, 2.2)))
	for c in chosen:
		var cc = Vector3(c.x, floor_y(c.z) + BALL_R, c.z)
		var rb = Basis.from_euler(Vector3(rng.randf_range(0, TAU), rng.randf_range(0, TAU), rng.randf_range(0, TAU)))
		sphere(b, g, "pc_hoops_ball", xf, cc, BALL_R, rb)
	b.cur_color = Color.WHITE

	# walk obstacle
	var c0 = xf * Vector3(-HW, 0, 0)
	var c1 = xf * Vector3(HW, 0, D)
	b.obst(["rect", min(c0.x, c1.x), min(c0.z, c1.z), max(c0.x, c1.x), max(c0.z, c1.z)])

## Material "pc_hoops_<key>".
static func fill_mat(m, key, b):
	match key:
		"front", "side", "panel", "ramp", "lam":
			m.albedo_texture = b.tex("pc/hoops_%s.png" % key)
			m.roughness = 0.55 if key != "ramp" else 0.45
		"paint":
			m.albedo_texture = b.tex("pc/hoops_paint.png"); m.roughness = 0.45; m.metallic = 0.15
		"door":
			m.albedo_texture = b.tex("pc/hoops_door.png"); m.roughness = 0.35; m.metallic = 0.7
		"board":
			# white backboard under its lamp hood: a little self light stands in for the lamp
			m.albedo_texture = b.tex("pc/hoops_board.png"); m.roughness = 0.4
			m.emission_enabled = true; m.emission_texture = b.tex("pc/hoops_board.png")
			m.emission = Color(1, 0.97, 0.9); m.emission_energy_multiplier = 0.22
			m.set_meta("e_day", 0.22); m.set_meta("e_night", 0.22)
		"plate":
			m.albedo_texture = b.tex("pc/hoops_plate.png"); m.roughness = 0.4
		"marquee":
			m.albedo_texture = b.tex("pc/hoops_marquee.png"); m.roughness = 0.3
			m.emission_enabled = true; m.emission_texture = b.tex("pc/hoops_marquee.png")
			m.emission_energy_multiplier = 1.4
			m.set_meta("e_day", 1.4); m.set_meta("e_night", 1.4)
		"led":
			m.albedo_texture = b.tex("pc/hoops_led.png"); m.roughness = 0.15
			m.emission_enabled = true; m.emission_texture = b.tex("pc/hoops_led.png")
			m.emission_energy_multiplier = 1.8
			m.set_meta("e_day", 1.8); m.set_meta("e_night", 1.8)
		"lamp":
			m.albedo_color = Color("#fff8ec")
			m.emission_enabled = true; m.emission = Color("#fff4e0"); m.emission_energy_multiplier = 3.0
			m.set_meta("e_day", 3.0); m.set_meta("e_night", 3.0)
		"btn":
			m.albedo_color = Color("#ffd23a"); m.roughness = 0.25
			m.emission_enabled = true; m.emission = Color("#ffc21a"); m.emission_energy_multiplier = 2.5
			m.set_meta("e_day", 2.5); m.set_meta("e_night", 2.5)
		"rej":
			m.albedo_color = Color("#e02a1a"); m.roughness = 0.25
			m.emission_enabled = true; m.emission = Color("#ff3018"); m.emission_energy_multiplier = 2.5
			m.set_meta("e_day", 2.5); m.set_meta("e_night", 2.5)
		"bezel":
			m.albedo_color = Color("#16161a"); m.roughness = 0.4
		"chrome":
			m.albedo_color = Color("#b8b8bc"); m.metallic = 0.85; m.roughness = 0.25
		"rim":
			m.albedo_color = Color("#e0501a"); m.metallic = 0.3; m.roughness = 0.4
		"ball":
			m.albedo_texture = b.tex("pc/hoops_ball.png"); m.roughness = 0.7
		"ticket":
			m.albedo_texture = b.tex("pc/hoops_ticket.png"); m.roughness = 0.8
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR; m.alpha_scissor_threshold = 0.5
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
		"mesh":
			m.albedo_texture = b.tex("pc/hoops_mesh.png"); m.roughness = 0.5; m.metallic = 0.2
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
		"net":
			m.albedo_texture = b.tex("pc/hoops_net.png"); m.roughness = 0.9
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
		_:
			return false
	return true
