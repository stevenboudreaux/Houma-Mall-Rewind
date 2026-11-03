## Pocket Change prop module `cyclone`: the 1995 round light-chase ticket game, the
## arcade's feature piece dead centre inside the entrance. Contract:
## tools/stores/pocket_change/README.md. Textures: paint_cyclone.py -> tex/pc/cyclone_*.png.
## Animated lamps and neon: scripts/cyclone_lights.gd (built at run time, see build()).
##
## Form (from Steven's 1995 video and a later unit's photo): a square cabinet about
## 1.26 m x 1.30 m with rounded yellow corner posts; grey brushed-stainless sides and back,
## each with a big die-cut swoosh decal; a hot-pink front door (coin mech, 25c sticker,
## ticket slot) under a slanted art console (instructions card, big STOP! button, red LED
## TICKETS OWED window); a pink top deck with a chrome edge; a clear acrylic dome over a
## yellow playfield: two staggered rows of pink numbered squares on a blue lane, a ring of
## 64 lamps, an inner band with BONUS INCREASES / EVERY GAME plates, a recessed chrome
## dish, a BONUS readout on a pink post, and two tilted lamp towers at the back.
## Invented title: WHIRLWIND (owner-editable side decals). No real name, logo or art.
##
## Preview:
##   tools/qa/preview.sh cyclone /home/claude/houma-mall-rewind/.scratch/preview/cyclone/final-lit \
##     "0,1.6,1.9,0,-17;1.9,1.6,1.3,52,-17;2.5,1.2,-0.65,90,-6;0,1.75,0.15,0,-50" '{}' lit|dark
## Preview frames land at t = 2, 4, 6, 8 ... s, so repeating one camera shows the lights
## stepping (t = 6 falls in the whole-ring flash).

const W = 1.26     # width (player's right)
const D = 1.30     # depth (into the machine)
const HW = 0.63
const RC = 0.10    # corner post radius
const Y0 = 0.035   # top of the black plinth
const YT = 0.935   # top of the side panels
const DECK = 0.96  # top of the pink deck
const OVH = 0.012  # deck overhang past the panels
const C = Vector3(0, 0.95, 0.70)   # playfield centre (the dome's axis), local
const FY = 0.95    # playfield height
const DOME_Y = 0.975
const DOME_R = 0.535
const FL_R0 = 0.53     # flange inner radius (= playfield rim)
const FL_R1 = 0.565    # flange outer radius
const R_BAND_IN = 0.255
const R_DISH = 0.25
const DISH_Y = 0.90    # dish floor at the wall
const FIELD_M = 1.06   # cyclone_field.png spans +-0.53 m round the centre
# console (slanted art panel): bottom edge (y, z) and top edge (y, z)
const CON_A = Vector2(0.70, -0.015)
const CON_B = Vector2(0.975, 0.125)
const CON_BACK = 0.145
const CX = 0.53        # half width between the corner posts
# lamp towers: angle from the front (+ = player's left), radius, height above the field
const TOWER_TH = 122.0
const TOWER_R = 0.30
const TOWER_H = 0.21
const TOWER_S = 0.10
const TOWER_TILT = 35.0
# BONUS readout
const BOX_Z = 0.62
const BOX_Y = 0.155    # centre height above the field
const BOX_W = 0.24
const BOX_H = 0.165
const BOX_D = 0.045
const BOX_TILT = 12.0

## Footprint (width, depth) in metres.
static func footprint(_opts = {}):
	return Vector2(W, D)

static func X(o, f):
	return Transform3D(Basis(f.cross(Vector3.UP), Vector3.UP, f), o)

## Local point on the playfield at angle th (degrees from the front, + = player's left),
## radius r, height y.
static func P(th, r, y = FY):
	var t = deg_to_rad(th)
	return Vector3(C.x - sin(t) * r, y, C.z - cos(t) * r)

## Field texture UV of a local point (top of image = back of the machine).
static func fuv(p):
	return Vector2(0.5 + (p.x - C.x) / FIELD_M, 0.5 - (p.z - C.z) / FIELD_M)

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

## One smooth-shaded triangle (world points, per-vertex normals).
static func stri(b, s, p, n, uv):
	var fn = (n[0] + n[1] + n[2]).normalized()
	var order = [0, 1, 2]
	if (p[1] - p[0]).cross(p[2] - p[0]).dot(fn) > 0.0:
		order = [0, 2, 1]
	for i in order:
		s.set_color(b.cur_color); s.set_normal(n[i]); s.set_uv(uv[i]); s.add_vertex(p[i])

## A smooth quad strip piece: local points a0, a1 (one edge) and b0, b1, local normals.
static func squad(b, s, xf, p, n, uv):
	var wp = []; var wn = []
	for k in 4:
		wp.append(xf * p[k]); wn.append((xf.basis * n[k]).normalized())
	stri(b, s, [wp[0], wp[1], wp[2]], [wn[0], wn[1], wn[2]], [uv[0], uv[1], uv[2]])
	stri(b, s, [wp[0], wp[2], wp[3]], [wn[0], wn[2], wn[3]], [uv[0], uv[2], uv[3]])

## A short cylinder on local axis ax from base c, capped at the far end (disc UVs on the cap).
static func ocyl(b, g, m, xf, c, ax, r, l, seg = 16, dyn = true):
	var s = b.st(g, m, dyn)
	var u = ax.cross(Vector3.UP)
	if u.length() < 0.01:
		u = Vector3.RIGHT
	u = u.normalized()
	var v = ax.cross(u).normalized()
	var top = c + ax * l
	var an = (xf.basis * ax).normalized()
	for i in seg:
		var a0 = TAU * i / seg
		var a1 = TAU * (i + 1) / seg
		var d0 = u * cos(a0) + v * sin(a0)
		var d1 = u * cos(a1) + v * sin(a1)
		var n0 = (xf.basis * d0).normalized()
		var n1 = (xf.basis * d1).normalized()
		var p = [xf * (c + d0 * r), xf * (c + d1 * r), xf * (top + d1 * r), xf * (top + d0 * r)]
		var uv = [Vector2(0.5, 0.98), Vector2(0.5, 0.98), Vector2(0.5, 0.98), Vector2(0.5, 0.98)]
		stri(b, s, [p[0], p[1], p[2]], [n0, n1, n1], [uv[0], uv[1], uv[2]])
		stri(b, s, [p[0], p[2], p[3]], [n0, n1, n0], [uv[0], uv[2], uv[3]])
		# cap: the texture's disc, upright when the axis faces the player (v points down)
		var c0 = Vector2(0.5 + cos(a0) * 0.5, 0.5 + sin(a0) * 0.5)
		var c1 = Vector2(0.5 + cos(a1) * 0.5, 0.5 + sin(a1) * 0.5)
		stri(b, s, [xf * top, p[3], p[2]], [an, an, an], [Vector2(0.5, 0.5), c0, c1])

## A tube through local points pts (radius r, sides seg), smooth, open ends.
static func pipe(b, g, m, xf, pts, r, seg = 8, dyn = true):
	var s = b.st(g, m, dyn)
	var rings = []
	var nrm = []
	var prev_u = Vector3.ZERO
	for i in pts.size():
		var t = (pts[min(i + 1, pts.size() - 1)] - pts[max(i - 1, 0)]).normalized()
		var u = prev_u
		if u == Vector3.ZERO or abs(u.dot(t)) > 0.95:
			u = t.cross(Vector3.UP if abs(t.y) < 0.9 else Vector3.RIGHT).normalized()
		u = (u - t * u.dot(t)).normalized()
		prev_u = u
		var v = t.cross(u).normalized()
		var ring = []; var rn = []
		for k in seg + 1:
			var a = TAU * k / seg
			var d = u * cos(a) + v * sin(a)
			ring.append(pts[i] + d * r); rn.append(d)
		rings.append(ring); nrm.append(rn)
	for i in pts.size() - 1:
		for k in seg:
			squad(b, s, xf, [rings[i][k], rings[i][k + 1], rings[i + 1][k + 1], rings[i + 1][k]],
				[nrm[i][k], nrm[i][k + 1], nrm[i + 1][k + 1], nrm[i + 1][k]],
				[Vector2(float(k) / seg, 0), Vector2(float(k + 1) / seg, 0), Vector2(float(k + 1) / seg, 1), Vector2(float(k) / seg, 1)])

## A box on an arbitrary local basis bs (columns = the box's x, y, z; -z faces the player).
## Every face is mapped to the UV rect uvr (Rect2) and material m, except the faces named in
## `skin` (face key -> [material, Rect2]).
static func cube(b, g, m, xf, c, bs, size, uvr = Rect2(0, 0, 1, 1), skin = {}, dyn = false):
	var ex = bs.x; var ey = bs.y; var ez = bs.z
	var hx = size.x * 0.5; var hy = size.y * 0.5; var hz = size.z * 0.5
	# key: [normal, right, up, half along normal, half right, half up]
	var faces = {
		"-z": [-ez, ex, ey, hz, hx, hy], "+z": [ez, -ex, ey, hz, hx, hy],
		"+x": [ex, ez, ey, hx, hz, hy], "-x": [-ex, -ez, ey, hx, hz, hy],
		"+y": [ey, ex, ez, hy, hx, hz], "-y": [-ey, ex, -ez, hy, hx, hz]}
	for k in faces:
		var fc = faces[k]
		var o = c + fc[0] * fc[3]
		var rt = fc[1] * fc[4]; var up = fc[2] * fc[5]
		var mm = m; var rr = uvr
		if skin.has(k):
			mm = skin[k][0]; rr = skin[k][1]
		q(b, g, mm, xf, [o - rt - up, o + rt - up, o + rt + up, o - rt + up], fc[0], ruv(rr.position.x, rr.position.y, rr.end.x, rr.end.y), dyn)

## The cabinet outline (local x, z): a rounded rectangle grown by `off`, starting at the
## front centre and running round toward +x. Straight runs are split so the deck can be
## fanned to the dome flange.
static func outline(off, nstraight = 10, ncorner = 8):
	var r = RC + off
	var cs = [[Vector2(HW - RC, RC), -90.0], [Vector2(HW - RC, D - RC), 0.0], [Vector2(-(HW - RC), D - RC), 90.0], [Vector2(-(HW - RC), RC), 180.0]]
	var dirv = func(a): return Vector2(cos(deg_to_rad(a)), sin(deg_to_rad(a)))
	var start = Vector2(0, -off)
	var pts = []
	var nh = nstraight / 2
	var first = cs[0][0] + dirv.call(cs[0][1]) * r
	for k in nh:
		pts.append(start.lerp(first, float(k) / nh))
	for ci in 4:
		var cc = cs[ci][0]; var a0 = cs[ci][1]
		for k in ncorner + 1:
			pts.append(cc + dirv.call(a0 + 90.0 * k / ncorner) * r)
		var e0 = cc + dirv.call(a0 + 90.0) * r
		if ci < 3:
			var e1 = cs[ci + 1][0] + dirv.call(cs[ci + 1][1]) * r
			for k in range(1, nstraight):
				pts.append(e0.lerp(e1, float(k) / nstraight))
		else:
			for k in range(1, nh):
				pts.append(e0.lerp(start, float(k) / nh))
	return pts

# ---------------------------------------------------------------- build
## Builds one machine. The player stands at `o` (floor, centre of the front edge) facing `f`.
static func build(b, g, o, f, opts = {}):
	var xf = X(o, f)
	var UP = Vector3.UP; var FR = Vector3(0, 0, -1); var BK = Vector3(0, 0, 1)
	var L = Vector3.LEFT; var R = Vector3.RIGHT

	# ---- plinth (black, set in 2 cm)
	var pl = outline(-0.02, 6, 4)
	for i in pl.size():
		var a = pl[i]; var c = pl[(i + 1) % pl.size()]
		var n = Vector3(c.y - a.y, 0, -(c.x - a.x)).normalized()
		if n.dot(Vector3(a.x, 0, a.y - D * 0.5)) < 0:
			n = -n
		q(b, g, "pc_cyclone_plinth", xf, [Vector3(a.x, 0, a.y), Vector3(c.x, 0, c.y), Vector3(c.x, Y0, c.y), Vector3(a.x, Y0, a.y)], n)

	# ---- side panels: brushed stainless (one texture, the viewer's right is u)
	var span = D - 2 * RC
	q(b, g, "pc_cyclone_side", xf, [Vector3(-HW, Y0, D - RC), Vector3(-HW, Y0, RC), Vector3(-HW, YT, RC), Vector3(-HW, YT, D - RC)], L, ruv())
	q(b, g, "pc_cyclone_side", xf, [Vector3(HW, Y0, RC), Vector3(HW, Y0, D - RC), Vector3(HW, YT, D - RC), Vector3(HW, YT, RC)], R, ruv())
	q(b, g, "pc_cyclone_side", xf, [Vector3(HW - RC, Y0, D), Vector3(-(HW - RC), Y0, D), Vector3(-(HW - RC), YT, D), Vector3(HW - RC, YT, D)], BK, ruv(0.02, 0, 0.98, 1))
	# chrome joint strips where the sides meet the front corner posts
	for sx in [-1.0, 1.0]:
		b.box(g, "pc_cyclone_chrome", Vector3(sx * (HW + 0.002), (Y0 + YT) * 0.5, RC + 0.006), Vector3(0.008, YT - Y0, 0.014), xf)

	# ---- decals: left, right, back (static, alpha-cut), owner-editable title band
	var DW = 0.86; var DH = 0.54; var DYC = 0.50
	var decals = [
		[Vector3(-HW - 0.004, DYC, D * 0.5), Vector3(0, 0, -1), L],   # left: reading toward the front
		[Vector3(HW + 0.004, DYC, D * 0.5), Vector3(0, 0, 1), R],     # right: reading toward the back
		[Vector3(0, DYC, D + 0.004), Vector3(-1, 0, 0), BK],          # back: reading toward -x
	]
	var sign_faces = []
	for dc in decals:
		var cc = dc[0]; var ud = dc[1]; var n = dc[2]
		var p0 = cc - ud * DW * 0.5 - UP * DH * 0.5
		q(b, g, "pc_cyclone_decal", xf, [p0, p0 + ud * DW, p0 + ud * DW + UP * DH, p0 + UP * DH], n, ruv())
		# the sign face: the title band (u 0.06-0.94, v 0.31-0.72), opaque in the blank copy
		var s0 = p0 + ud * DW * 0.06 + UP * DH * (1.0 - 0.72)
		var s1 = p0 + ud * DW * 0.94 + UP * DH * (1.0 - 0.72)
		var s2 = p0 + ud * DW * 0.94 + UP * DH * (1.0 - 0.31)
		var s3 = p0 + ud * DW * 0.06 + UP * DH * (1.0 - 0.31)
		sign_faces.append([[xf * s0, xf * s1, xf * s2, xf * s3], [Vector2(0.06, 0.72), Vector2(0.94, 0.72), Vector2(0.94, 0.31), Vector2(0.06, 0.31)], (xf.basis * n).normalized()])
	if "signs" in b:
		# the name is owner-editable (scripts/signs.gd); paint_cyclone.py paints the word-free copy
		var k = 0
		for r0 in b.signs:
			if r0.kind == "pc_cyclone":
				k += 1
		b.sign_add("pc.cyclone.%d" % (k + 1), "pc_cyclone", "WHIRLWIND", 0, sign_faces,
			{"tex": "res://tex/pc/cyclone_decal_blank.png", "look": {"font": "sans_italic", "fill": "#ffe23c", "outline": "#3a2a90"}})

	# ---- corner posts: rounded, yellow
	var cs = [[Vector2(HW - RC, RC), -90.0], [Vector2(HW - RC, D - RC), 0.0], [Vector2(-(HW - RC), D - RC), 90.0], [Vector2(-(HW - RC), RC), 180.0]]
	var ys = b.st(g, "pc_cyclone_yellow", false)
	for ci in 4:
		var cc = cs[ci][0]
		var nseg = 7
		for k in nseg:
			var a0 = deg_to_rad(cs[ci][1] + 90.0 * k / nseg)
			var a1 = deg_to_rad(cs[ci][1] + 90.0 * (k + 1) / nseg)
			var d0 = Vector3(cos(a0), 0, sin(a0)); var d1 = Vector3(cos(a1), 0, sin(a1))
			var b0 = Vector3(cc.x, 0, cc.y)
			var u0 = (ci * 0.157 + RC * PI * 0.5 * k / nseg) / 0.3
			var u1 = (ci * 0.157 + RC * PI * 0.5 * (k + 1) / nseg) / 0.3
			squad(b, ys, xf, [b0 + d0 * RC + UP * Y0, b0 + d1 * RC + UP * Y0, b0 + d1 * RC + UP * YT, b0 + d0 * RC + UP * YT], [d0, d1, d1, d0],
				[Vector2(u0, 3.0), Vector2(u1, 3.0), Vector2(u1, 0), Vector2(u0, 0)])

	# ---- front face (door) and the slanted console above it
	q(b, g, "pc_cyclone_front", xf, [Vector3(-CX, Y0, 0), Vector3(CX, Y0, 0), Vector3(CX, CON_A.x, 0), Vector3(-CX, CON_A.x, 0)], FR, ruv())
	var ca = Vector3(0, CON_A.x, CON_A.y); var cb = Vector3(0, CON_B.x, CON_B.y)
	var cn = Vector3(0, CON_B.y - CON_A.y, -(CON_B.x - CON_A.x)).normalized()
	q(b, g, "pc_cyclone_console", xf, [Vector3(-CX, ca.y, ca.z), Vector3(CX, ca.y, ca.z), Vector3(CX, cb.y, cb.z), Vector3(-CX, cb.y, cb.z)], cn, ruv())
	# rolled top, back lip, overhang underside, end caps
	q(b, g, "pc_cyclone_yellow", xf, [Vector3(-CX, cb.y, cb.z), Vector3(CX, cb.y, cb.z), Vector3(CX, cb.y, CON_BACK), Vector3(-CX, cb.y, CON_BACK)], UP)
	q(b, g, "pc_cyclone_yellow", xf, [Vector3(CX, DECK, CON_BACK), Vector3(-CX, DECK, CON_BACK), Vector3(-CX, cb.y, CON_BACK), Vector3(CX, cb.y, CON_BACK)], BK)
	q(b, g, "pc_cyclone_plinth", xf, [Vector3(-CX, ca.y, ca.z), Vector3(CX, ca.y, ca.z), Vector3(CX, ca.y, 0.0), Vector3(-CX, ca.y, 0.0)], Vector3.DOWN)
	for sx in [-1.0, 1.0]:
		var xx = sx * CX
		var st = b.st(g, "pc_cyclone_yellow", false)
		var nn = (xf.basis * Vector3(sx, 0, 0)).normalized()
		var ep = [Vector3(xx, ca.y, ca.z), Vector3(xx, cb.y, cb.z), Vector3(xx, cb.y, CON_BACK), Vector3(xx, ca.y, CON_BACK)]
		b.tri(st, xf * ep[0], xf * ep[1], xf * ep[2], Vector2(0, 0), Vector2(0, 0.3), Vector2(0.05, 0.3), nn)
		b.tri(st, xf * ep[0], xf * ep[2], xf * ep[3], Vector2(0, 0), Vector2(0.05, 0.3), Vector2(0.05, 0), nn)
		# chrome edge trim along the console's slanted ends
		var t0 = Vector3(xx + sx * 0.004, ca.y, ca.z); var t1 = Vector3(xx + sx * 0.004, cb.y, cb.z)
		var zz = (t1 - t0).normalized()
		var bx = Vector3(1, 0, 0); var by = zz.cross(bx).normalized()
		b.box(g, "pc_cyclone_chrome", Vector3.ZERO, Vector3(0.010, 0.016, (t1 - t0).length()), xf * Transform3D(Basis(bx, by, zz), (t0 + t1) * 0.5))
	# TICKETS OWED LED window (texture px 822-978 x 82-146 of 1024 x 288)
	var cpt = func(u, v):   # console texture uv -> local point, 2 mm proud
		var e = ca.lerp(cb, 1.0 - v)
		return Vector3(-CX + u * 2.0 * CX, e.y, e.z) + cn * 0.002
	q(b, g, "pc_cyclone_led", xf, [cpt.call(822.0 / 1024, 146.0 / 288), cpt.call(978.0 / 1024, 146.0 / 288), cpt.call(978.0 / 1024, 82.0 / 288), cpt.call(822.0 / 1024, 82.0 / 288)], cn,
		ruv(0.30, 0.52, 1.0, 0.98))

	# ---- deck: pink top fanned to the dome flange, chrome edge band, dark underside lip.
	# Its outline is notched behind the console, which stands proud in front of it.
	var od = []
	for pt in outline(OVH):
		if abs(pt.x) < CX - 0.001 and pt.y < 0.0:
			continue
		od.append(pt)
	# od now runs from the front-right corner round to the front-left corner: close it
	# along the console's back edge
	var notch = [Vector2(-CX, -OVH)]
	for k in 7:
		notch.append(Vector2(lerp(-CX, CX, k / 6.0), CON_BACK))
	notch.append(Vector2(CX, -OVH))
	# rotate so the list starts at the front-right corner, then append the notch path
	var i0 = 0
	for i in od.size():
		if od[i].x > 0 and od[i].y < RC and is_equal_approx(od[i].x, CX) and is_equal_approx(od[i].y, -OVH):
			i0 = i
	od = od.slice(i0) + od.slice(0, i0)
	for k in range(1, notch.size() - 1):
		od.append(notch[k])
	var cxz = Vector2(C.x, C.z)
	var dk = b.st(g, "pc_cyclone_deck", false)
	var duv = func(p): return Vector2((p.x + 0.66) / 1.32, 1.0 - (p.z + 0.02) / 1.361)
	for i in od.size():
		var a = od[i]; var c = od[(i + 1) % od.size()]
		var ia = cxz + (a - cxz).normalized() * FL_R1
		var ic = cxz + (c - cxz).normalized() * FL_R1
		var P0 = Vector3(a.x, DECK, a.y); var P1 = Vector3(c.x, DECK, c.y)
		var P2 = Vector3(ic.x, DECK, ic.y); var P3 = Vector3(ia.x, DECK, ia.y)
		var wn = (xf.basis * UP).normalized()
		b.tri(dk, xf * P0, xf * P1, xf * P2, duv.call(P0), duv.call(P1), duv.call(P2), wn)
		b.tri(dk, xf * P0, xf * P2, xf * P3, duv.call(P0), duv.call(P2), duv.call(P3), wn)
		if a.y >= CON_BACK - 0.001 and c.y >= CON_BACK - 0.001 and abs(a.x) <= CX + 0.001 and abs(c.x) <= CX + 0.001:
			continue   # behind the console: hidden
		var n = Vector3(c.y - a.y, 0, -(c.x - a.x)).normalized()
		if n.dot(Vector3(a.x - cxz.x, 0, a.y - cxz.y)) < 0:
			n = -n
		var sl = (c - a).length()
		q(b, g, "pc_cyclone_chrome", xf, [Vector3(a.x, YT, a.y), Vector3(c.x, YT, c.y), Vector3(c.x, DECK, c.y), Vector3(a.x, DECK, a.y)], n,
			[Vector2(0, 0.025), Vector2(sl, 0.025), Vector2(sl, 0), Vector2(0, 0)])
		var ai = a - Vector2(n.x, n.z) * OVH; var ci2 = c - Vector2(n.x, n.z) * OVH
		q(b, g, "pc_cyclone_plinth", xf, [Vector3(ai.x, YT, ai.y), Vector3(ci2.x, YT, ci2.y), Vector3(c.x, YT, c.y), Vector3(a.x, YT, a.y)], Vector3.DOWN)

	# ---- dome flange (yellow ring the dome sits in)
	var NF = 96
	var fs = b.st(g, "pc_cyclone_yellow", false)
	for i in NF:
		var t0 = TAU * i / NF; var t1 = TAU * (i + 1) / NF
		var d0 = Vector3(sin(t0), 0, cos(t0)); var d1 = Vector3(sin(t1), 0, cos(t1))
		var cc = Vector3(C.x, 0, C.z)
		var u0 = t0 * FL_R1 / 0.3; var u1 = t1 * FL_R1 / 0.3
		squad(b, fs, xf, [cc + d0 * FL_R0 + UP * DOME_Y, cc + d1 * FL_R0 + UP * DOME_Y, cc + d1 * FL_R1 + UP * DOME_Y, cc + d0 * FL_R1 + UP * DOME_Y], [UP, UP, UP, UP],
			[Vector2(u0, 0), Vector2(u1, 0), Vector2(u1, 0.12), Vector2(u0, 0.12)])
		squad(b, fs, xf, [cc + d0 * FL_R1 + UP * DECK, cc + d1 * FL_R1 + UP * DECK, cc + d1 * FL_R1 + UP * DOME_Y, cc + d0 * FL_R1 + UP * DOME_Y], [d0, d1, d1, d0],
			[Vector2(u0, 0.2), Vector2(u1, 0.2), Vector2(u1, 0.15), Vector2(u0, 0.15)])
		squad(b, fs, xf, [cc + d0 * FL_R0 + UP * FY, cc + d1 * FL_R0 + UP * FY, cc + d1 * FL_R0 + UP * DOME_Y, cc + d0 * FL_R0 + UP * DOME_Y], [-d0, -d1, -d1, -d0],
			[Vector2(u0, 0.3), Vector2(u1, 0.3), Vector2(u1, 0.22), Vector2(u0, 0.22)])

	# ---- playfield: the ring annulus, the dish wall and the dish
	var fd = b.st(g, "pc_cyclone_field", false)
	var radii = [FL_R0, 0.40, R_DISH]
	var NP = 96
	for i in NP:
		var t0 = 360.0 * i / NP; var t1 = 360.0 * (i + 1) / NP
		for k in 2:
			var p = [P(t0, radii[k]), P(t1, radii[k]), P(t1, radii[k + 1]), P(t0, radii[k + 1])]
			squad(b, fd, xf, p, [UP, UP, UP, UP], [fuv(p[0]), fuv(p[1]), fuv(p[2]), fuv(p[3])])
		# dish wall (faces the centre) and the shallow dish floor
		var w = [P(t0, R_DISH, DISH_Y), P(t1, R_DISH, DISH_Y), P(t1, R_DISH, FY), P(t0, R_DISH, FY)]
		var n0 = (Vector3(C.x, 0, C.z) - Vector3(w[0].x, 0, w[0].z)).normalized()
		var n1 = (Vector3(C.x, 0, C.z) - Vector3(w[1].x, 0, w[1].z)).normalized()
		squad(b, b.st(g, "pc_cyclone_dishwall", false), xf, w, [n0, n1, n1, n0],
			[Vector2(t0 / 30.0, 1), Vector2(t1 / 30.0, 1), Vector2(t1 / 30.0, 0), Vector2(t0 / 30.0, 0)])
		var cen = Vector3(C.x, DISH_Y - 0.015, C.z)
		var a0 = P(t0, R_DISH, DISH_Y); var a1 = P(t1, R_DISH, DISH_Y)
		var mid0 = P(t0, R_DISH * 0.5, DISH_Y - 0.010); var mid1 = P(t1, R_DISH * 0.5, DISH_Y - 0.010)
		squad(b, fd, xf, [a0, a1, mid1, mid0], [UP, UP, UP, UP], [fuv(a0), fuv(a1), fuv(mid1), fuv(mid0)])
		var wn = (xf.basis * UP).normalized()
		b.tri(fd, xf * mid0, xf * mid1, xf * cen, fuv(mid0), fuv(mid1), fuv(cen), wn)

	# ---- the BONUS readout on its pink post
	var bt = deg_to_rad(BOX_TILT)
	var bb = Basis(Vector3(1, 0, 0), Vector3(0, cos(bt), sin(bt)), Vector3(0, -sin(bt), cos(bt)))   # top leans back
	var bc = Vector3(0, FY + BOX_Y, BOX_Z)
	cube(b, g, "pc_cyclone_box", xf, bc, bb, Vector3(BOX_W, BOX_H, BOX_D), Rect2(0, 0, 0.05, 0.05), {"-z": ["pc_cyclone_bonus", Rect2(0, 0, 1, 1)]})
	# its face texture is mapped whole; the LED window (px 24-232 x 60-136 of 256 x 176)
	var fz = -BOX_D * 0.5 - 0.0015
	var lp = func(px, py): return bc + bb * Vector3(-BOX_W * 0.5 + px / 256.0 * BOX_W, BOX_H * 0.5 - py / 176.0 * BOX_H, fz)
	q(b, g, "pc_cyclone_led", xf, [lp.call(24.0, 136.0), lp.call(232.0, 136.0), lp.call(232.0, 60.0), lp.call(24.0, 60.0)], bb * FR, ruv(0.04, 0.02, 0.96, 0.48))
	var post_top = bc + bb * Vector3(0, -BOX_H * 0.5, 0)
	b.box(g, "pc_cyclone_post", Vector3(0, (DISH_Y - 0.01 + post_top.y) * 0.5, BOX_Z + 0.01), Vector3(0.026, post_top.y - DISH_Y + 0.01, 0.026), xf, ["-y"], true)

	# ---- lamp towers at the back: tilted boxes on curved necks (lamp domes are run time)
	var lamps = []
	for side in [1.0, -1.0]:
		var th = TOWER_TH * side
		var tr = deg_to_rad(th)
		var inn = Vector3(sin(tr), 0, cos(tr))      # toward the centre
		var tan = Vector3(cos(tr), 0, -sin(tr))
		var ti = deg_to_rad(TOWER_TILT)
		var tup = (Vector3.UP * cos(ti) + inn * sin(ti)).normalized()
		var tb = Basis(tan, tup, tan.cross(tup).normalized())
		var tc = P(th, TOWER_R, FY + TOWER_H)
		var half = 0.0 if side > 0 else 0.5
		cube(b, g, "pc_cyclone_tower", xf, tc, tb, Vector3(TOWER_S, TOWER_S, TOWER_S), Rect2(half, 0, 0.5, 1))
		# copper lamp bezel ring on the top face
		ocyl(b, g, "pc_cyclone_copper", xf, tc + tup * (TOWER_S * 0.5), tup, 0.036, 0.008, 16, true)
		lamps.append({"pos": tc + tup * (TOWER_S * 0.5 + 0.008), "n": tup, "role": "tower_l" if side > 0 else "tower_r"})
		# neck: from the inner band up into the box's underside, bowing outward
		var base = P(th + side * 6.0, 0.33)
		var bot = tc - tup * (TOWER_S * 0.5)
		var p1 = base + Vector3.UP * 0.11
		var p2 = bot - tup * 0.07 - inn * 0.03
		var pts = []
		for k in 13:
			var t = float(k) / 12
			var mt = 1.0 - t
			pts.append(base * mt * mt * mt + p1 * 3 * mt * mt * t + p2 * 3 * mt * t * t + bot * t * t * t)
		pipe(b, g, "pc_cyclone_neck_l" if side > 0 else "pc_cyclone_neck_r", xf, pts, 0.012, 8, true)
		ocyl(b, g, "pc_cyclone_collar", xf, base - Vector3.UP * 0.002, Vector3.UP, 0.019, 0.016, 12, true)
	lamps.append({"pos": bc + bb * Vector3(0, BOX_H * 0.5, 0), "n": bb * Vector3.UP, "role": "bonus"})

	# ---- the BONUS slot housing at the front of the ring, its lamp is lamp 0 of the ring
	var sh_c = P(0.0, 0.435, FY + 0.009)
	b.box(g, "pc_cyclone_slotbox", sh_c, Vector3(0.054, 0.018, 0.07), xf, ["-z", "-y", "+y"], true)
	q(b, g, "pc_cyclone_slot", xf, [sh_c + Vector3(-0.027, -0.009, -0.035), sh_c + Vector3(0.027, -0.009, -0.035), sh_c + Vector3(0.027, 0.009, -0.035), sh_c + Vector3(-0.027, 0.009, -0.035)], FR, ruv(0.0, 0.62, 1.0, 1.0), true)
	q(b, g, "pc_cyclone_slot", xf, [sh_c + Vector3(-0.027, 0.009, -0.035), sh_c + Vector3(0.027, 0.009, -0.035), sh_c + Vector3(0.027, 0.009, 0.035), sh_c + Vector3(-0.027, 0.009, 0.035)], UP, ruv(0.0, 0.0, 1.0, 1.0), true)

	# ---- clear inner rim round the dish, and the dome (dynamic, transparent)
	var rs = b.st(g, "pc_cyclone_glass", true)
	var NR = 48; var NV = 6
	for i in NR:
		for j in NV:
			var pp = []; var nn2 = []; var uu = []
			for kk in [[i, j], [i + 1, j], [i + 1, j + 1], [i, j + 1]]:
				var th2 = TAU * kk[0] / NR; var ph = TAU * kk[1] / NV
				var dd = Vector3(sin(th2), 0, cos(th2))
				var nrm = dd * cos(ph) + Vector3.UP * sin(ph)
				pp.append(Vector3(C.x, FY + 0.006, C.z) + dd * (R_DISH + 0.004) + nrm * 0.008)
				nn2.append(nrm); uu.append(Vector2(float(kk[0]) / NR, float(kk[1]) / NV))
			squad(b, rs, xf, pp, nn2, uu)
	var ds = b.st(g, "pc_cyclone_dome", true)
	var NL = 40; var NA = 12
	for i in NL:
		for j in NA:
			var pp = []; var nn2 = []; var uu = []
			for kk in [[i, j], [i + 1, j], [i + 1, j + 1], [i, j + 1]]:
				var lon = TAU * kk[0] / NL; var lat = PI * 0.5 * kk[1] / NA
				var nrm = Vector3(sin(lon) * cos(lat), sin(lat), cos(lon) * cos(lat))
				pp.append(Vector3(C.x, DOME_Y, C.z) + nrm * DOME_R)
				nn2.append(nrm); uu.append(Vector2(2.0 * kk[0] / NL, 1.0 - float(kk[1]) / NA))
			squad(b, ds, xf, pp, nn2, uu)

	# ---- STOP! button on the console (texture px 548, 112)
	var bpos = Vector3(-CX + 548.0 / 1024 * 2.0 * CX, 0, 0)
	var be = ca.lerp(cb, 1.0 - 112.0 / 288)
	bpos.y = be.y; bpos.z = be.z
	ocyl(b, g, "pc_cyclone_bezel", xf, bpos, cn, 0.050, 0.010, 24, true)
	ocyl(b, g, "pc_cyclone_button", xf, bpos + cn * 0.002, cn, 0.040, 0.022, 24, true)

	# ---- coin mech, lock, ticket dispenser and its strip of tickets
	b.box(g, "pc_cyclone_bezel", Vector3(0.195, 0.455, -0.009), Vector3(0.075, 0.095, 0.018), xf, ["-z", "+z"], true)
	q(b, g, "pc_cyclone_coin", xf, [Vector3(0.1575, 0.4075, -0.018), Vector3(0.2325, 0.4075, -0.018), Vector3(0.2325, 0.5025, -0.018), Vector3(0.1575, 0.5025, -0.018)], FR, ruv(), true)
	ocyl(b, g, "pc_cyclone_chrome", xf, Vector3(0.355, 0.43, 0.0), FR, 0.013, 0.006, 14, true)
	ocyl(b, g, "pc_cyclone_bezel", xf, Vector3(0.355, 0.43, -0.006), FR, 0.004, 0.002, 6, true)
	b.box(g, "pc_cyclone_chrome", Vector3(0.175, 0.275, -0.008), Vector3(0.085, 0.052, 0.016), xf, ["+z"], true)
	q(b, g, "pc_cyclone_bezel", xf, [Vector3(0.15, 0.268, -0.0165), Vector3(0.20, 0.268, -0.0165), Vector3(0.20, 0.276, -0.0165), Vector3(0.15, 0.276, -0.0165)], FR, [], true)
	var rng = RandomNumberGenerator.new()
	rng.seed = 1995
	var tp = []
	var p = Vector3(0.175, 0.272, -0.017)
	var dir = Vector3(0, -0.2, -1).normalized()
	for i in 8:
		tp.append(p)
		dir = dir.lerp(Vector3(rng.randf_range(-0.05, 0.05), -1, -0.1 + 0.03 * i), 0.4).normalized()
		p = p + dir * 0.02
		p.z = min(p.z, -0.019)
	tp.append(p)
	var tw = 0.013
	for i in tp.size() - 1:
		var a = tp[i]; var c = tp[i + 1]
		var nn3 = (c - a).normalized().cross(Vector3.RIGHT).normalized()
		var va = i * 0.02 / 0.04; var vc = (i + 1) * 0.02 / 0.04
		q(b, g, "pc_cyclone_ticket", xf, [a + Vector3(-tw, 0, 0), a + Vector3(tw, 0, 0), c + Vector3(tw, 0, 0), c + Vector3(-tw, 0, 0)], nn3,
			[Vector2(0, va), Vector2(1, va), Vector2(1, vc), Vector2(0, vc)], true)

	# ---- the animated lamps and neon: a run-time node (scripts/cyclone_lights.gd).
	# Its frame is the machine frame without the mirror: node-local (x, y, -z) = machine (x, y, z).
	var ln = Node3D.new()
	ln.name = "CycloneLights"
	ln.set_script(load("res://scripts/cyclone_lights.gd"))
	var mz = func(v): return Vector3(v.x, v.y, -v.z)
	var lam = []
	for l in lamps:
		lam.append({"pos": mz.call(l.pos), "n": mz.call(l.n), "role": l.role})
	ln.set_meta("layout", {"centre": mz.call(C), "field_y": FY, "dish_y": DISH_Y, "post": mz.call(Vector3(0, DISH_Y, BOX_Z + 0.01)), "lamps": lam})
	ln.transform = Transform3D(Basis(f.cross(Vector3.UP), Vector3.UP, -f), o)
	b.light_root.add_child(ln)

	# walk obstacle
	var c0 = xf * Vector3(-HW, 0, 0)
	var c1 = xf * Vector3(HW, 0, D)
	b.obst(["rect", min(c0.x, c1.x), min(c0.z, c1.z), max(c0.x, c1.x), max(c0.z, c1.z)])

## Material "pc_cyclone_<key>".
static func fill_mat(m, key, b):
	match key:
		"side":
			m.albedo_texture = b.tex("pc/cyclone_side.png"); m.metallic = 0.55; m.roughness = 0.38
		"decal":
			m.albedo_texture = b.tex("pc/cyclone_decal.png"); m.roughness = 0.35
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR; m.alpha_scissor_threshold = 0.5
		"front":
			m.albedo_texture = b.tex("pc/cyclone_front.png"); m.roughness = 0.42
		"console":
			m.albedo_texture = b.tex("pc/cyclone_console.png"); m.roughness = 0.3
		"deck":
			m.albedo_texture = b.tex("pc/cyclone_deck.png"); m.roughness = 0.4
		"field":
			# a little self light: the neon and lamps spill on the playfield all the time,
			# but they are run-time parts the lightmap bake never sees
			m.albedo_texture = b.tex("pc/cyclone_field.png"); m.roughness = 0.35
			m.emission_enabled = true; m.emission_texture = b.tex("pc/cyclone_field.png")
			m.emission = Color(1.0, 0.92, 0.95); m.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY
			m.emission_energy_multiplier = 0.3
			m.set_meta("e_day", 0.3); m.set_meta("e_night", 0.3)
		"yellow":
			m.albedo_texture = b.tex("pc/cyclone_yellow.png"); m.roughness = 0.4
		"chrome":
			m.albedo_color = Color("#c8c8cc"); m.metallic = 0.85; m.roughness = 0.22
		"plinth":
			m.albedo_color = Color("#141416"); m.roughness = 0.7
		"dishwall":
			m.albedo_color = Color("#9a9ca4"); m.metallic = 0.6; m.roughness = 0.25
			m.emission_enabled = true; m.emission = Color("#8a7a9a"); m.emission_energy_multiplier = 0.25
			m.set_meta("e_day", 0.25); m.set_meta("e_night", 0.25)
		"bonus":
			m.albedo_texture = b.tex("pc/cyclone_bonus.png"); m.roughness = 0.4
			# the readout's face is lit from within a little
			m.emission_enabled = true; m.emission_texture = b.tex("pc/cyclone_bonus.png")
			m.emission = Color.WHITE; m.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY
			m.emission_energy_multiplier = 0.35
			m.set_meta("e_day", 0.35); m.set_meta("e_night", 0.35)
		"box":
			m.albedo_color = Color("#8e1430"); m.roughness = 0.45
		"led":
			m.albedo_texture = b.tex("pc/cyclone_led.png"); m.roughness = 0.15
			m.emission_enabled = true; m.emission_texture = b.tex("pc/cyclone_led.png")
			m.emission = Color.WHITE; m.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY
			m.emission_energy_multiplier = 1.8
			m.set_meta("e_day", 1.8); m.set_meta("e_night", 1.8)
		"tower":
			m.albedo_texture = b.tex("pc/cyclone_tower.png"); m.roughness = 0.45
		"copper":
			m.albedo_color = Color("#b8642a"); m.metallic = 0.7; m.roughness = 0.35
		"neck_l":
			m.albedo_color = Color("#145a48"); m.roughness = 0.3
		"neck_r":
			m.albedo_color = Color("#1a3a8a"); m.roughness = 0.3
		"collar":
			m.albedo_color = Color("#eae6dc"); m.roughness = 0.35
		"post":
			m.albedo_color = Color("#e04a96"); m.roughness = 0.35
		"slotbox":
			m.albedo_color = Color("#34307e"); m.roughness = 0.4
		"slot":
			m.albedo_texture = b.tex("pc/cyclone_slot.png"); m.roughness = 0.4
		"button":
			m.albedo_texture = b.tex("pc/cyclone_button.png"); m.roughness = 0.25
			m.emission_enabled = true; m.emission_texture = b.tex("pc/cyclone_button.png")
			m.emission = Color.WHITE; m.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY
			m.emission_energy_multiplier = 1.2
			m.set_meta("e_day", 1.2); m.set_meta("e_night", 1.2)
		"bezel":
			m.albedo_color = Color("#141418"); m.roughness = 0.4
		"coin":
			m.albedo_texture = b.tex("pc/cyclone_coin.png"); m.roughness = 0.45; m.metallic = 0.2
		"ticket":
			m.albedo_texture = b.tex("pc/cyclone_ticket.png"); m.roughness = 0.8
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR; m.alpha_scissor_threshold = 0.5
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
		"glass":
			m.albedo_color = Color(0.92, 0.96, 1.0, 0.35); m.roughness = 0.08; m.metallic_specular = 0.8
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
		"dome":
			m.albedo_texture = b.tex("pc/cyclone_dome.png"); m.roughness = 0.05; m.metallic_specular = 0.9
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
			# The dome is probe-lit (dynamic, transparent), and in the dark arcade the probes see
			# almost nothing, so it vanished at night (Steven, Oct 6). The ring lamps' glow on the
			# acrylic stands in: the texture's streaks and lip glow faintly, more at night.
			m.emission_enabled = true; m.emission = Color(0.82, 0.9, 1.0)
			m.emission_texture = b.tex("pc/cyclone_dome.png")
			m.emission_energy_multiplier = 0.9
			m.set_meta("e_day", 0.6); m.set_meta("e_night", 0.9)
		_:
			return false
	return true
