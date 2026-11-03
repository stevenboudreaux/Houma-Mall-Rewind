## Pocket Change prop module `airhockey`: an 8 ft commercial coin-op air hockey table.
## Contract: tools/stores/pocket_change/README.md. Textures: paint_airhockey.py -> tex/pc/airhockey_*.png.
##
## Form (from Steven's reference photo, u8_airhockey.jpg, and the published specs of 1990s
## 8 ft tables, ~96 x 52 in, playfield ~31 in high): a white/silver-grey laminate cabinet
## with a royal-blue band and gold pinstripes, bowed end panels, grey corner legs tapering to
## the floor over a recessed dark base; a medium-blue perforated playfield inside flat
## aluminium rails with black rubber bumpers and goal slots at both ends; clear acrylic side
## guards; a chrome double-tube arch from the middle of each long side carrying a silver
## lamp/score unit (fluorescent lamp face underneath, red LED scores on both ends); a coin
## door on the right-hand side near the player's end; puck-return trays under both goals;
## a red puck and two mallets. Generic words only ("AIR HOCKEY").
## opts: {"number": 1|2} picks the scores, mirrors the playfield wear and moves the puck
## and mallets, so the pair does not look cloned.
##
## Preview:
##   tools/qa/preview.sh airhockey /home/claude/houma-mall-rewind/.scratch/preview/airhockey/a \
##     "0,1.6,1.3,0,-25;2.4,1.7,1.0,50,-20;3.2,1.3,-1.2,90,-10" '{"number":1}' lit

const W = 1.35      # width (player's right)
const HW = 0.675
const L = 2.45      # length (along f)
const YP = 0.80     # playfield
const YR = 0.835    # rail top
const YS = 0.78     # top of the skirt, under the rail lip
const YB = 0.30     # bottom of the skirt
const RS = 0.075    # side rail width
const RE = 0.10     # end rail width
const IW = 0.60     # half-width of the playfield (HW - RS)
const GOAL = 0.13   # half-width of the goal slot
const BOW = 0.035   # how far the middle of each end panel bulges past its corners
const ZM = 1.225    # middle of the table
const XP = 0.722    # arch posts' centre line (outside the side skirts)
const TR = 0.0165   # arch tube radius
const TG = 0.028    # half the gap between the two tubes of the arch
const YA = 2.255    # arch bar centre line
const RB = 0.17     # arch bend radius
const GUARD_H = 0.15

## Footprint (width, depth) in metres.
static func footprint(_opts = {}):
	return Vector2(W, L)

static func X(o, f):
	return Transform3D(Basis(f.cross(Vector3.UP), Vector3.UP, f), o)

## The end panel's z at x (near end; the far end is L - endz(x)): bowed in plan.
static func endz(x):
	var t = x / HW
	return BOW * t * t

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

## A box from local min to max corners.
static func bx(b, g, m, xf, lo, hi, skip = [], dyn = false):
	b.box(g, m, (lo + hi) * 0.5, hi - lo, xf, skip, dyn)

## One smooth-shaded triangle (world points, per-vertex normals).
static func stri(b, s, p, n, uv):
	var fn = (n[0] + n[1] + n[2]).normalized()
	var order = [0, 1, 2]
	if (p[1] - p[0]).cross(p[2] - p[0]).dot(fn) > 0.0:
		order = [0, 2, 1]
	for i in order:
		s.set_color(b.cur_color); s.set_normal(n[i]); s.set_uv(uv[i]); s.add_vertex(p[i])

## A solid from 8 local corners: bottom ring p[0..3], top ring p[4..7] (same order).
## Faces get flat normals pointing away from the centre; UVs are world-projected.
static func hexa(b, g, m, xf, p, dyn = false):
	var c = Vector3.ZERO
	for v in p:
		c += v
	c /= 8.0
	var faces = [[0, 1, 2, 3], [4, 5, 6, 7], [0, 1, 5, 4], [1, 2, 6, 5], [2, 3, 7, 6], [3, 0, 4, 7]]
	for fc in faces:
		var a = p[fc[0]]; var bb = p[fc[1]]; var cc = p[fc[2]]; var d = p[fc[3]]
		var n = (cc - a).cross(d - bb).normalized()
		if n.dot((a + bb + cc + d) * 0.25 - c) < 0.0:
			n = -n
		q(b, g, m, xf, [a, bb, cc, d], n, [], dyn)

## A tube swept along local points `path` lying in a plane z = const (the arch).
static func tube(b, g, m, xf, path, r, seg = 12):
	var s = b.st(g, m, true)
	var rings = []
	var nrms = []
	for i in path.size():
		var t
		if i == 0:
			t = path[1] - path[0]
		elif i == path.size() - 1:
			t = path[i] - path[i - 1]
		else:
			t = path[i + 1] - path[i - 1]
		t = t.normalized()
		var bn = Vector3(0, 0, 1)
		var nn = t.cross(bn).normalized()
		var ring = []
		var rn = []
		for k in seg:
			var a = TAU * k / seg
			var d = nn * cos(a) + bn * sin(a)
			ring.append(xf * (path[i] + d * r))
			rn.append((xf.basis * d).normalized())
		rings.append(ring)
		nrms.append(rn)
	for i in path.size() - 1:
		for k in seg:
			var k1 = (k + 1) % seg
			var uv = [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]
			stri(b, s, [rings[i][k], rings[i][k1], rings[i + 1][k1]], [nrms[i][k], nrms[i][k1], nrms[i + 1][k1]], [uv[0], uv[1], uv[2]])
			stri(b, s, [rings[i][k], rings[i + 1][k1], rings[i + 1][k]], [nrms[i][k], nrms[i + 1][k1], nrms[i + 1][k]], [uv[0], uv[2], uv[3]])

## A vertical cylinder at local base point c (world-vertical, so b.cyl works).
static func vcyl(b, g, m, xf, c, r0, r1, h, seg = 20, top = true):
	b.cyl(g, m, xf * c, r0, r1, h, seg, top, false, true)

# ---------------------------------------------------------------- build
## Builds one table. The player stands at `o` (floor, centre of one end) facing `f`.
static func build(b, g, o, f, opts = {}):
	var xf = X(o, f)
	var num = clampi(int(opts.get("number", 1)), 1, 2)
	var rng = RandomNumberGenerator.new()
	rng.seed = 8800 + num
	var R = Vector3.RIGHT; var UP = Vector3.UP; var DN = Vector3.DOWN
	var FR = Vector3(0, 0, -1); var BK = Vector3(0, 0, 1)
	var NB = 8   # segments across a bowed end

	# ---- long side skirts (laminate, blue band, AIR HOCKEY label)
	for sx in [-1, 1]:
		var x = sx * HW
		var U = func(z): return (z / L) if sx > 0 else 1.0 - z / L
		var z0 = endz(HW); var z1 = L - endz(HW)
		q(b, g, "pc_airhockey_side", xf, [Vector3(x, YB, z0), Vector3(x, YB, z1), Vector3(x, YS, z1), Vector3(x, YS, z0)], R * sx,
			[Vector2(U.call(z0), 1), Vector2(U.call(z1), 1), Vector2(U.call(z1), 0), Vector2(U.call(z0), 0)])

	# ---- bowed end skirts, smooth-shaded
	for e in [0, 1]:
		var s = b.st(g, "pc_airhockey_end", false)
		for i in NB:
			var xa = -HW + W * i / NB
			var xb = -HW + W * (i + 1) / NB
			var za = endz(xa); var zb = endz(xb)
			var na = Vector3(2.0 * BOW * xa / (HW * HW), 0, -1).normalized()
			var nb = Vector3(2.0 * BOW * xb / (HW * HW), 0, -1).normalized()
			# u runs left to right as seen from outside that end
			var ua = (xa + HW) / W; var ub = (xb + HW) / W
			if e == 1:
				za = L - za; zb = L - zb
				na = Vector3(na.x, 0, -na.z); nb = Vector3(nb.x, 0, -nb.z)
				ua = 1.0 - ua; ub = 1.0 - ub
			var p = [xf * Vector3(xa, YB, za), xf * Vector3(xb, YB, zb), xf * Vector3(xb, YS, zb), xf * Vector3(xa, YS, za)]
			var n = [(xf.basis * na).normalized(), (xf.basis * nb).normalized()]
			stri(b, s, [p[0], p[1], p[2]], [n[0], n[1], n[1]], [Vector2(ua, 1), Vector2(ub, 1), Vector2(ub, 0)])
			stri(b, s, [p[0], p[2], p[3]], [n[0], n[1], n[0]], [Vector2(ua, 1), Vector2(ub, 0), Vector2(ua, 0)])
		# underside of the overhang between the corner legs
	q(b, g, "pc_airhockey_base", xf, [Vector3(-HW, YB, endz(HW)), Vector3(HW, YB, endz(HW)), Vector3(HW, YB, L - endz(HW)), Vector3(-HW, YB, L - endz(HW))], DN)
	q(b, g, "pc_airhockey_base", xf, [Vector3(-HW, YB, 0.0), Vector3(HW, YB, 0.0), Vector3(HW, YB, endz(HW)), Vector3(-HW, YB, endz(HW))], DN)
	q(b, g, "pc_airhockey_base", xf, [Vector3(-HW, YB, L - endz(HW)), Vector3(HW, YB, L - endz(HW)), Vector3(HW, YB, L), Vector3(-HW, YB, L)], DN)

	# ---- recessed dark base (blower box) and grey corner legs tapering to the floor
	bx(b, g, "pc_airhockey_base", xf, Vector3(-0.50, 0.0, 0.34), Vector3(0.50, YB, L - 0.34), ["-y"])
	for sx in [-1, 1]:
		for e in [0, 1]:
			var zz = func(z): return z if e == 0 else L - z
			var xo = sx * (HW + 0.012)
			var xi = sx * (HW - 0.17)
			var xfo = sx * (HW - 0.035)
			var xfi = sx * (HW - 0.135)
			var p = [Vector3(xfi, 0, zz.call(0.07)), Vector3(xfo, 0, zz.call(0.07)), Vector3(xfo, 0, zz.call(0.19)), Vector3(xfi, 0, zz.call(0.19)),
				Vector3(xi, YS, zz.call(endz(HW - 0.17) - 0.012)), Vector3(xo, YS, zz.call(endz(HW) - 0.012)), Vector3(xo, YS, zz.call(0.29)), Vector3(xi, YS, zz.call(0.29))]
			hexa(b, g, "pc_airhockey_leg", xf, p)
			# levelling foot
			b.cur_color = Color("#141416")
			vcyl(b, g, "vcolor", xf, Vector3(sx * (HW - 0.085), 0.0, zz.call(0.13)), 0.032, 0.026, 0.018, 12)
			b.cur_color = Color.WHITE

	# ---- rails: aluminium boxes, painted tops, rubber bumpers on the inner faces
	var ro = 0.008
	for sx in [-1, 1]:
		var xa = sx * (HW - RS); var xb = sx * (HW + ro)
		bx(b, g, "pc_airhockey_alu", xf, Vector3(min(xa, xb), YS, -ro), Vector3(max(xa, xb), YR, L + ro), ["+y", "-y", "-x" if sx > 0 else "+x"])
		var ua = 0.0 if sx > 0 else 1.0
		var ub = 1.0 - ua
		# top: v = 0 along the outer edge
		q(b, g, "pc_airhockey_rail", xf, [Vector3(xb, YR, -ro), Vector3(xb, YR, L + ro), Vector3(xa, YR, L + ro), Vector3(xa, YR, -ro)], UP,
			[Vector2(ua, 0), Vector2(ub, 0), Vector2(ub, 1), Vector2(ua, 1)])
		q(b, g, "pc_airhockey_rubber", xf, [Vector3(xa, YP, RE), Vector3(xa, YP, L - RE), Vector3(xa, YR - 0.006, L - RE), Vector3(xa, YR - 0.006, RE)], -R * sx)
		q(b, g, "pc_airhockey_alu", xf, [Vector3(xa, YR - 0.006, RE), Vector3(xa, YR - 0.006, L - RE), Vector3(xa, YR, L - RE), Vector3(xa, YR, RE)], -R * sx)
	for e in [0, 1]:
		var za = -ro if e == 0 else L - RE
		var zb = RE if e == 0 else L + ro
		var zi = RE if e == 0 else L - RE
		var ni = BK if e == 0 else FR
		bx(b, g, "pc_airhockey_alu", xf, Vector3(-HW + RS, YS, za), Vector3(HW - RS, YR, zb), ["+y", "-y", "+x", "-x", "+z" if e == 0 else "-z"])
		var zo = -ro if e == 0 else L + ro
		q(b, g, "pc_airhockey_rail", xf, [Vector3(-HW + RS, YR, zo), Vector3(HW - RS, YR, zo), Vector3(HW - RS, YR, zi), Vector3(-HW + RS, YR, zi)], UP,
			[Vector2(0, 0), Vector2(0.53, 0), Vector2(0.53, 1), Vector2(0, 1)])
		# inner face: rubber either side of the goal slot, the slot itself, rubber over it
		for side in [-1, 1]:
			var x0 = side * IW; var x1 = side * GOAL
			q(b, g, "pc_airhockey_rubber", xf, [Vector3(min(x0, x1), YP, zi), Vector3(max(x0, x1), YP, zi), Vector3(max(x0, x1), YR - 0.006, zi), Vector3(min(x0, x1), YR - 0.006, zi)], ni)
		q(b, g, "pc_airhockey_slot", xf, [Vector3(-GOAL, YP - 0.03, zi), Vector3(GOAL, YP - 0.03, zi), Vector3(GOAL, YP + 0.019, zi), Vector3(-GOAL, YP + 0.019, zi)], ni)
		q(b, g, "pc_airhockey_rubber", xf, [Vector3(-GOAL, YP + 0.019, zi), Vector3(GOAL, YP + 0.019, zi), Vector3(GOAL, YR - 0.006, zi), Vector3(-GOAL, YR - 0.006, zi)], ni)
		q(b, g, "pc_airhockey_alu", xf, [Vector3(-IW, YR - 0.006, zi), Vector3(IW, YR - 0.006, zi), Vector3(IW, YR, zi), Vector3(-IW, YR, zi)], ni)

	# ---- playfield (mirrored for table 2 so the wear differs)
	var fu0 = 0.0 if num == 1 else 1.0
	var fu1 = 1.0 - fu0
	q(b, g, "pc_airhockey_field", xf, [Vector3(-IW, YP, RE), Vector3(IW, YP, RE), Vector3(IW, YP, L - RE), Vector3(-IW, YP, L - RE)], UP,
		[Vector2(fu0, 0), Vector2(fu0, 1), Vector2(fu1, 1), Vector2(fu1, 0)])

	# ---- acrylic side guards (dynamic, transparent) with a thin top edge
	for sx in [-1, 1]:
		var x = sx * (HW - 0.022)
		var g0 = 0.17; var g1 = L - 0.17
		q(b, g, "pc_airhockey_acrylic", xf, [Vector3(x, YR, g0), Vector3(x, YR, g1), Vector3(x, YR + GUARD_H, g1), Vector3(x, YR + GUARD_H, g0)], R * sx, ruv(), true)

	# ---- arch: two chrome tubes per post, bent over the table; brackets on the skirts
	for dz in [-TG, TG]:
		var path = []
		var z = ZM + dz
		path.append(Vector3(-XP, 0.54, z))
		path.append(Vector3(-XP, YA - RB, z))
		for k in range(1, 7):
			var a = PI * 0.5 * k / 6.0
			path.append(Vector3(-XP + RB - RB * cos(a), YA - RB + RB * sin(a), z))
		path.append(Vector3(XP - RB, YA, z))
		for k in range(1, 7):
			var a = PI * 0.5 * k / 6.0
			path.append(Vector3(XP - RB + RB * sin(a), YA - RB + RB * cos(a), z))
		path.append(Vector3(XP, 0.54, z))
		tube(b, g, "pc_airhockey_chrome", xf, path, TR)
	for sx in [-1, 1]:
		# grey mounting block on the skirt, and a clamp collar round the tubes at rail height
		bx(b, g, "pc_airhockey_bracket", xf, Vector3(min(sx * HW, sx * (XP + 0.03)), 0.50, ZM - 0.075), Vector3(max(sx * HW, sx * (XP + 0.03)), 0.66, ZM + 0.075))
		bx(b, g, "pc_airhockey_chrome", xf, Vector3(sx * XP - 0.026, 0.86, ZM - 0.058), Vector3(sx * XP + 0.026, 0.90, ZM + 0.058), [], true)

	# ---- lamp / score unit hanging from the middle of the bar
	var ux = 0.18; var uz = 0.10
	var uy0 = 2.15; var uy1 = 2.285
	bx(b, g, "pc_airhockey_housing", xf, Vector3(-ux, uy0, ZM - uz), Vector3(ux, uy1, ZM + uz), ["-z", "+z", "-y"])
	for e in [0, 1]:
		var zf = ZM - uz if e == 0 else ZM + uz
		var nn = FR if e == 0 else BK
		var xl = -ux if e == 0 else ux
		var xr = ux if e == 0 else -ux
		q(b, g, "pc_airhockey_unit", xf, [Vector3(xl, uy0, zf), Vector3(xr, uy0, zf), Vector3(xr, uy1 - 0.005, zf), Vector3(xl, uy1 - 0.005, zf)], nn, ruv())
		# LED window: this table's row, this end's column
		var lz = zf + (-0.003 if e == 0 else 0.003)
		var lxl = -0.115 if e == 0 else 0.115
		var lxr = -lxl
		var u0 = 0.5 * e; var v0 = 0.5 * (num - 1)
		q(b, g, "pc_airhockey_led", xf, [Vector3(lxl, uy0 + 0.025, lz), Vector3(lxr, uy0 + 0.025, lz), Vector3(lxr, uy0 + 0.11, lz), Vector3(lxl, uy0 + 0.11, lz)], nn,
			ruv(u0, v0 + 0.06, u0 + 0.5, v0 + 0.44))
	# hood: a flared skirt under the box, white inside, lamp face at the top of it
	var hx = 0.36; var hz = 0.22; var hy = 2.06
	var top = [Vector3(-ux, uy0, ZM - uz), Vector3(ux, uy0, ZM - uz), Vector3(ux, uy0, ZM + uz), Vector3(-ux, uy0, ZM + uz)]
	var bot = [Vector3(-hx, hy, ZM - hz), Vector3(hx, hy, ZM - hz), Vector3(hx, hy, ZM + hz), Vector3(-hx, hy, ZM + hz)]
	for i in 4:
		var j = (i + 1) % 4
		var mid = (top[i] + top[j] + bot[i] + bot[j]) * 0.25
		var out = Vector3(mid.x, 0, mid.z - ZM)
		var n = (bot[j] - top[i]).cross(bot[i] - top[j]).normalized()
		if n.dot(out) < 0.0:
			n = -n
		q(b, g, "pc_airhockey_housing", xf, [bot[i], bot[j], top[j], top[i]], n)
		q(b, g, "pc_airhockey_hoodin", xf, [bot[i], bot[j], top[j], top[i]], -n)
	q(b, g, "pc_airhockey_lamp", xf, [Vector3(-ux, uy0 - 0.002, ZM - uz), Vector3(ux, uy0 - 0.002, ZM - uz), Vector3(ux, uy0 - 0.002, ZM + uz), Vector3(-ux, uy0 - 0.002, ZM + uz)], DN, ruv())
	# rolled lip round the hood's bottom edge
	for i in 4:
		var j = (i + 1) % 4
		var a = bot[i]; var c = bot[j]
		var lo = Vector3(min(a.x, c.x) - 0.006, hy - 0.012, min(a.z, c.z) - 0.006)
		var hi = Vector3(max(a.x, c.x) + 0.006, hy, max(a.z, c.z) + 0.006)
		bx(b, g, "pc_airhockey_chrome", xf, lo, hi, [], true)

	# ---- coin door on the right-hand skirt near the player's end, lit coin entries
	var dx = HW + 0.006
	var dz0 = 0.36; var dz1 = 0.56
	var dy0 = 0.47; var dy1 = 0.72
	bx(b, g, "pc_airhockey_bezel", xf, Vector3(HW, dy0 - 0.012, dz0 - 0.012), Vector3(dx + 0.004, dy1 + 0.012, dz1 + 0.012), ["-x"])
	# seen from +x the viewer's right is +z (as with the side texture)
	q(b, g, "pc_airhockey_door", xf, [Vector3(dx + 0.0045, dy0, dz0), Vector3(dx + 0.0045, dy0, dz1), Vector3(dx + 0.0045, dy1, dz1), Vector3(dx + 0.0045, dy1, dz0)], R, ruv())
	for cz in [0.055, 0.145]:
		var zc = dz0 + cz
		var yc = dy1 - 0.025 - 0.024 * 0.96
		q(b, g, "pc_airhockey_coinlit", xf, [Vector3(dx + 0.006, yc - 0.017, zc - 0.011), Vector3(dx + 0.006, yc - 0.017, zc + 0.011), Vector3(dx + 0.006, yc + 0.017, zc + 0.011), Vector3(dx + 0.006, yc + 0.017, zc - 0.011)], R, ruv(), true)
		# reject buttons
		b.cur_color = Color("#a8a8ae")
		bx(b, g, "vcolor", xf, Vector3(dx + 0.0045, dy1 - 0.088, zc - 0.009), Vector3(dx + 0.012, dy1 - 0.070, zc + 0.009), [], true)
		b.cur_color = Color.WHITE

	# ---- puck-return trays under both goals
	for e in [0, 1]:
		var s = -1.0 if e == 0 else 1.0
		var zp = endz(0.0) if e == 0 else L - endz(0.0)
		var zo = zp + s * 0.085
		var z_in = zp - s * 0.01
		bx(b, g, "pc_airhockey_tray", xf, Vector3(-0.11, 0.565, min(zo, z_in)), Vector3(0.11, 0.58, max(zo, z_in)), [], true)
		bx(b, g, "pc_airhockey_tray", xf, Vector3(-0.11, 0.565, min(zo, zo - s * 0.008)), Vector3(0.11, 0.615, max(zo, zo - s * 0.008)), [], true)
		for sx in [-1, 1]:
			bx(b, g, "pc_airhockey_tray", xf, Vector3(sx * 0.11 - 0.004, 0.565, min(zo, z_in)), Vector3(sx * 0.11 + 0.004, 0.62, max(zo, z_in)), [], true)

	# ---- puck and mallets (dynamic)
	var spots = [[Vector3(0.18, YP, 0.98), Vector3(-0.22, YP, 0.42), Vector3(0.12, YP, 2.02)],
		[Vector3(-0.30, YP, 1.70), Vector3(0.26, YP, 0.36), Vector3(-0.05, YP, 2.10)]]
	var sp = spots[num - 1]
	b.cur_color = Color("#c81a16")
	vcyl(b, g, "vcolor", xf, sp[0], 0.0415, 0.0415, 0.0062, 20)
	b.cur_color = Color.WHITE
	for k in [1, 2]:
		var c = sp[k]
		vcyl(b, g, "pc_airhockey_mallet", xf, c, 0.048, 0.048, 0.006, 20, false)
		vcyl(b, g, "pc_airhockey_mallet", xf, c + Vector3(0, 0.006, 0), 0.048, 0.040, 0.016, 20, true)
		vcyl(b, g, "pc_airhockey_mallet", xf, c + Vector3(0, 0.022, 0), 0.016, 0.014, 0.030, 12, false)
		vcyl(b, g, "pc_airhockey_mallet", xf, c + Vector3(0, 0.052, 0), 0.020, 0.018, 0.016, 12, true)

	# walk obstacle
	var c0 = xf * Vector3(-HW, 0, 0)
	var c1 = xf * Vector3(HW, 0, L)
	b.obst(["rect", min(c0.x, c1.x), min(c0.z, c1.z), max(c0.x, c1.x), max(c0.z, c1.z)])

static func emit(m, b, path, e):
	m.emission_enabled = true
	m.emission_texture = b.tex(path)
	m.emission = Color.WHITE
	m.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY
	m.emission_energy_multiplier = e
	m.set_meta("e_day", e); m.set_meta("e_night", e)

## Material "pc_airhockey_<key>".
static func fill_mat(m, key, b):
	match key:
		"side", "end":
			m.albedo_texture = b.tex("pc/airhockey_%s.png" % key); m.roughness = 0.42
		"leg":
			m.albedo_texture = b.tex("pc/airhockey_leg.png"); m.roughness = 0.45; m.metallic = 0.2
		"field":
			# glossy laminate; it carries a faint copy of itself lit from the lamp above
			m.albedo_texture = b.tex("pc/airhockey_field.png"); m.roughness = 0.22; m.metallic_specular = 0.6
			emit(m, b, "pc/airhockey_fieldglow.png", 0.75)
		"rail":
			m.albedo_texture = b.tex("pc/airhockey_rail.png"); m.roughness = 0.32; m.metallic = 0.75
		"alu":
			m.albedo_color = Color("#b4b6ba"); m.roughness = 0.35; m.metallic = 0.75
		"rubber":
			m.albedo_color = Color("#141416"); m.roughness = 0.85
		"slot":
			m.albedo_color = Color("#050506"); m.roughness = 0.9
		"base":
			m.albedo_color = Color("#1a1a1e"); m.roughness = 0.8
		"bracket":
			m.albedo_color = Color("#8c8e94"); m.roughness = 0.45; m.metallic = 0.4
		"acrylic":
			m.albedo_texture = b.tex("pc/airhockey_acrylic.png"); m.roughness = 0.05; m.metallic_specular = 0.8
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
		"chrome":
			m.albedo_color = Color("#f2f3f6"); m.metallic = 0.7; m.roughness = 0.14
		"housing":
			m.albedo_color = Color("#c6c4bc"); m.roughness = 0.4; m.metallic = 0.35
		"unit":
			m.albedo_texture = b.tex("pc/airhockey_unit.png"); m.roughness = 0.4; m.metallic = 0.3
		"hoodin":
			# the inside of the hood catches the tubes' light
			m.albedo_color = Color("#ece9e0"); m.roughness = 0.6
			m.emission_enabled = true; m.emission = Color("#fff6e4")
			m.emission_energy_multiplier = 0.8
			m.set_meta("e_day", 0.8); m.set_meta("e_night", 0.8)
		"lamp":
			m.albedo_texture = b.tex("pc/airhockey_lamp.png"); m.roughness = 0.3
			emit(m, b, "pc/airhockey_lamp.png", 3.2)
		"led":
			m.albedo_texture = b.tex("pc/airhockey_led.png"); m.roughness = 0.15
			emit(m, b, "pc/airhockey_led.png", 1.8)
		"door":
			m.albedo_texture = b.tex("pc/airhockey_door.png"); m.roughness = 0.35; m.metallic = 0.6
		"bezel":
			m.albedo_color = Color("#1c1c20"); m.roughness = 0.4; m.metallic = 0.3
		"coinlit":
			m.albedo_color = Color("#ff5a2a"); m.roughness = 0.3
			m.emission_enabled = true; m.emission = Color("#ff5a2a")
			m.emission_energy_multiplier = 2.2
			m.set_meta("e_day", 2.2); m.set_meta("e_night", 2.2)
		"tray":
			m.albedo_color = Color("#141416"); m.roughness = 0.55
		"mallet":
			m.albedo_color = Color("#e6e2d6"); m.roughness = 0.35
		_:
			return false
	return true
