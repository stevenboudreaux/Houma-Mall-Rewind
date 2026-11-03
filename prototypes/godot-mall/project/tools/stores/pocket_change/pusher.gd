## Pocket Change prop module `pusher`: a mid-1990s three-player coin pusher ("penny falls").
## Contract: tools/stores/pocket_change/README.md. Textures: paint_pusher.py -> tex/pc/pusher_*.png.
##
## Form (Steven's reference photos of a Crompton's-type three-player pusher, about 1.65 m wide,
## 1.1 m deep and 2.15 m tall): a black plinth; a blue lower cabinet of three doors, each with
## a black payout cup; an aluminium sill and a big glass window leaning back over the
## playfield, with small side windows let into the grey side wings; a blue coin-entry band
## with three chrome coin mechanisms; and a back-lit marquee box carried on grey angled side
## ears above a small gap. Inside, per player position: a back-lit space-art translite, a
## white zig-zag coin chute, the pusher deck (upper tier) heaped with coins, and the fixed
## lower shelf with its heap at the drop edge; steel partition fins and blue art ramps
## between the positions, perforated deflectors at the walls, a fluorescent tube in the top.
## The coin heaps are painted low mounds (a seamless coin texture on smooth heap surfaces with
## coin-stack front faces) plus a few dozen loose coin discs on the edges and in the cups.
## Invented title: COIN COMET (owner-editable sign "pc.pusher.1"). The pusher is static.
##
## opts {"double": true} (Steven, Oct 8 2026: Southland's was one machine played from both sides,
## like Crompton's Silver Skis, not two back to back): two playfields back to back in ONE cabinet,
## 1.64 m deep. Each side is built from its front to the translites (ZM); the side panels, the
## ears and the marquee box run through to meet the other side's, so the cabinet is continuous,
## with a marquee face on each side and no backs.
##
## Preview:
##   tools/qa/preview.sh pusher /home/claude/houma-mall-rewind/.scratch/preview/pusher/a \
##     "0,1.6,2.6,0,-12;2.4,1.7,1.9,45,-12;3.2,1.5,0.55,90,-6" '{}' lit

const W = 1.65      # width (player's right)
const D = 1.10      # depth (into the machine)
const H = 2.20      # top of the ears
const HW = 0.825    # outer face of the side panels
const IW = 0.79     # inner face of the side panels
const PX = [-0.527, 0.0, 0.527]   # the three player positions' centres
const PH = 0.2635   # half a position's width (partitions at x = +-0.2635)
# window glass: bottom edge (z, y) and top edge (z, y)
const G0 = Vector2(0.06, 0.78)
const G1 = Vector2(0.30, 1.48)
# playfield
const Y_SH = 0.82     # lower (fixed) shelf
const Z_DROP = 0.12   # its front (drop) edge
const Z_PUSH = 0.50   # the pusher deck's front face
const Y_PT = 0.895    # the pusher deck
const Z_BACK = 0.80   # the translites
const Y_CEIL = 1.47   # the lit top inside
# coin band and marquee box
const Z_BAND = 0.30
const Y_BAND = 1.48
const Y_TOP = 1.79
const Y_M0 = 1.83
const Y_M1 = 2.18
const Z_M = 0.29
const Z_MB = 0.48
const COIN_R = 0.0125
const COIN_T = 0.0018
const ZM = 0.82       # the double cabinet's middle (each side is built from 0 to here)

# side panel outline (z, y), the side window cut out of its upper front
const SIDE = [Vector2(0.0, 0.07), Vector2(1.10, 0.07), Vector2(1.10, 1.00), Vector2(0.82, 1.48), Vector2(0.82, 1.79),
	Vector2(0.30, 1.79), Vector2(0.30, 1.48), Vector2(0.50, 1.48), Vector2(0.50, 0.98), Vector2(0.06, 0.78), Vector2(0.0, 0.78)]
# inner face: only where it can be seen, round the playfield
const INNER = [Vector2(0.06, 0.72), Vector2(0.82, 0.72), Vector2(0.82, 1.48), Vector2(0.50, 1.48), Vector2(0.50, 0.98), Vector2(0.06, 0.78)]
# the side window
const SWIN = [Vector2(0.06, 0.78), Vector2(0.50, 0.98), Vector2(0.50, 1.48), Vector2(0.30, 1.48)]
# the grey ear beside the marquee
const EAR = [Vector2(0.27, 1.82), Vector2(0.70, 1.82), Vector2(0.49, 2.20), Vector2(0.27, 2.20)]
# the double cabinet's side of one half (runs to the middle, ZM) and its ear (meets the other's)
const SIDE_H = [Vector2(0.0, 0.07), Vector2(0.82, 0.07), Vector2(0.82, 1.79), Vector2(0.30, 1.79), Vector2(0.30, 1.48),
	Vector2(0.50, 1.48), Vector2(0.50, 0.98), Vector2(0.06, 0.78), Vector2(0.0, 0.78)]
const EAR_H = [Vector2(0.27, 1.82), Vector2(0.82, 1.82), Vector2(0.82, 2.20), Vector2(0.27, 2.20)]
# partition fin between positions
const FIN = [Vector2(0.50, 0.895), Vector2(0.80, 0.895), Vector2(0.80, 1.47), Vector2(0.71, 1.47), Vector2(0.71, 1.06), Vector2(0.50, 0.94)]

## Footprint (width, depth) in metres.
static func footprint(opts = {}):
	return Vector2(W, 2.0 * ZM) if opts.get("double", false) else Vector2(W, D)

static func X(o, f):
	return Transform3D(Basis(f.cross(Vector3.UP), Vector3.UP, f), o)

# ---------------------------------------------------------------- heap shapes
## Height of the lower shelf's coin heap above Y_SH at (x, z): a mound pushed up against the
## drop edge, a low ridge in front of the pusher, lower beside the ramps.
static func heap_lo(x, z):
	var h = 0.007 + 0.032 * exp(-pow((z - 0.18) / 0.085, 2.0)) + 0.007 * exp(-pow((z - 0.47) / 0.035, 2.0))
	h += 0.007 * sin(x * 23.0 + 1.3) * sin(z * 17.0 + 0.7) + 0.004 * sin(x * 41.0 + z * 29.0) + 0.003 * sin(x * 67.0 - z * 51.0)
	var dw = min(abs(x - PH), abs(x + PH))
	dw = min(dw, IW - abs(x))
	h *= clamp((dw - 0.03) / 0.09, 0.35, 1.0)
	return max(h, 0.003)

## Height of the pusher deck's coins above Y_PT.
static func heap_hi(x, z):
	var h = 0.006 + 0.010 * exp(-pow((z - 0.535) / 0.05, 2.0)) + 0.003 * sin(x * 31.0 + 2.0) * sin(z * 23.0) + 0.002 * sin(x * 59.0 + z * 37.0)
	return max(h, 0.003)

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

## A flat polygon in the plane x = const, outline given as (z, y); uvf maps (z, y) -> uv.
static func zpoly(b, g, m, xf, outline, x, nx, uvf, dyn = false):
	var pk = PackedVector2Array(outline)
	var idx = Geometry2D.triangulate_polygon(pk)
	if idx.is_empty():
		push_error("pusher: triangulation failed")
		return
	var s = b.st(g, m, dyn)
	var n = (xf.basis * Vector3(nx, 0, 0)).normalized()
	for i in range(0, idx.size(), 3):
		var p = []; var uv = []
		for j in 3:
			var v = outline[idx[i + j]]
			p.append(xf * Vector3(x, v.y, v.x))
			uv.append(uvf.call(v))
		b.tri(s, p[0], p[1], p[2], uv[0], uv[1], uv[2], n)

## The edge strips of a (z, y) outline between x0 and x1; mats[i] is the strip after point i.
static func zedges(b, g, mats, xf, outline, x0, x1, dyn = false):
	var area = 0.0
	var n = outline.size()
	for i in n:
		var a = outline[i]; var c = outline[(i + 1) % n]
		area += a.x * c.y - c.x * a.y
	var sgn = 1.0 if area > 0.0 else -1.0
	for i in n:
		var m = mats[i] if mats is Array else mats
		if m == "":
			continue
		var a = outline[i]; var c = outline[(i + 1) % n]
		var d = (c - a).normalized()
		# outward normal in (z, y): rotate the edge direction clockwise for a CCW outline
		var on = Vector2(d.y, -d.x) * sgn
		q(b, g, m, xf, [Vector3(x0, a.y, a.x), Vector3(x1, a.y, a.x), Vector3(x1, c.y, c.x), Vector3(x0, c.y, c.x)], Vector3(0, on.y, on.x), [], dyn)

## Smooth heap surface over x0..x1, z0..z1 at base height y0 + hf(x, z), planar coin UVs.
static func heap(b, g, xf, x0, x1, z0, z1, y0, hf, nu, nv, uoff):
	var s = b.st(g, "pc_pusher_coins", false)
	var P = func(i, j):
		var x = lerp(x0, x1, float(i) / nu)
		var z = lerp(z0, z1, float(j) / nv)
		return Vector3(x, y0 + hf.call(x, z), z)
	var N = func(i, j):
		var x = lerp(x0, x1, float(i) / nu)
		var z = lerp(z0, z1, float(j) / nv)
		var e = 0.004
		var dx = (hf.call(x + e, z) - hf.call(x - e, z)) / (2.0 * e)
		var dz = (hf.call(x, z + e) - hf.call(x, z - e)) / (2.0 * e)
		return Vector3(-dx, 1.0, -dz).normalized()
	for i in nu:
		for j in nv:
			var ids = [[i, j], [i + 1, j], [i + 1, j + 1], [i, j + 1]]
			var p = []; var nn = []; var uv = []
			for k in ids:
				var lp = P.call(k[0], k[1])
				p.append(xf * lp)
				nn.append((xf.basis * N.call(k[0], k[1])).normalized())
				uv.append(Vector2(lp.x / 0.35 + uoff, lp.z / 0.35 + uoff * 0.37))
			stri(b, s, [p[0], p[1], p[2]], [nn[0], nn[1], nn[2]], [uv[0], uv[1], uv[2]])
			stri(b, s, [p[0], p[2], p[3]], [nn[0], nn[2], nn[3]], [uv[0], uv[2], uv[3]])

## The front face of a heap (coins edge-on) at depth z, from y_bot up to y0 + hf(x, z).
static func heap_front(b, g, xf, x0, x1, z, y_bot, y0, hf, zs, nu):
	for i in nu:
		var xa = lerp(x0, x1, float(i) / nu)
		var xc = lerp(x0, x1, float(i + 1) / nu)
		var ya = y0 + hf.call(xa, zs) + 0.0005
		var yc = y0 + hf.call(xc, zs) + 0.0005
		q(b, g, "pc_pusher_edge", xf, [Vector3(xa, y_bot, z), Vector3(xc, y_bot, z), Vector3(xc, yc, z), Vector3(xa, ya, z)], Vector3(0, 0, -1),
			[Vector2(xa / 0.35, (ya - y_bot) / 0.044), Vector2(xc / 0.35, (yc - y_bot) / 0.044), Vector2(xc / 0.35, 0.0), Vector2(xa / 0.35, 0.0)])

## A static cylinder along local axis ax from local point c, length l (the fluorescent tube).
static func lcyl(b, g, m, xf, c, ax, r, l, seg = 12):
	var s = b.st(g, m, false)
	var u = Vector3.UP
	var v = ax.cross(u).normalized()
	for i in seg:
		var a0 = TAU * i / seg
		var a1 = TAU * (i + 1) / seg
		var d0 = u * cos(a0) + v * sin(a0)
		var d1 = u * cos(a1) + v * sin(a1)
		var n0 = (xf.basis * d0).normalized()
		var n1 = (xf.basis * d1).normalized()
		var p = [xf * (c + d0 * r), xf * (c + d1 * r), xf * (c + ax * l + d1 * r), xf * (c + ax * l + d0 * r)]
		var uv = [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]
		stri(b, s, [p[0], p[1], p[2]], [n0, n1, n1], [uv[0], uv[1], uv[2]])
		stri(b, s, [p[0], p[2], p[3]], [n0, n1, n0], [uv[0], uv[2], uv[3]])

## One loose coin (dynamic): centre c, face normal nrm (local), copper or silver face.
static func disc(b, g, xf, c, nrm, silver, bottom = true, seg = 8):
	var s = b.st(g, "pc_pusher_coin", true)
	var n = nrm.normalized()
	var u = n.cross(Vector3(0, 0, 1))
	if u.length() < 0.1:
		u = n.cross(Vector3.RIGHT)
	u = u.normalized()
	var v = n.cross(u).normalized()
	var ct = c + n * COIN_T * 0.5
	var cb = c - n * COIN_T * 0.5
	var uc = 0.75 if silver else 0.25
	var ue = Vector2(0.52 if silver else 0.02, 0.02)
	var wn = (xf.basis * n).normalized()
	for i in seg:
		var a0 = TAU * i / seg
		var a1 = TAU * (i + 1) / seg
		var d0 = u * cos(a0) + v * sin(a0)
		var d1 = u * cos(a1) + v * sin(a1)
		var t0 = xf * (ct + d0 * COIN_R); var t1 = xf * (ct + d1 * COIN_R)
		var b0 = xf * (cb + d0 * COIN_R); var b1 = xf * (cb + d1 * COIN_R)
		var uv0 = Vector2(uc + cos(a0) * 0.235, 0.5 + sin(a0) * 0.47)
		var uv1 = Vector2(uc + cos(a1) * 0.235, 0.5 + sin(a1) * 0.47)
		b.tri(s, xf * ct, t0, t1, Vector2(uc, 0.5), uv0, uv1, wn)
		if bottom:
			b.tri(s, xf * cb, b1, b0, Vector2(uc, 0.5), uv1, uv0, -wn)
		var n0 = (xf.basis * d0).normalized(); var n1 = (xf.basis * d1).normalized()
		stri(b, s, [b0, b1, t1], [n0, n1, n1], [ue, ue, ue])
		stri(b, s, [b0, t1, t0], [n0, n1, n0], [ue, ue, ue])

## A coin normal tilted forward (toward the player, -z) by `a` degrees, turned by `yaw`.
static func tilt(a, yaw = 0.0):
	var n = Vector3(0, cos(deg_to_rad(a)), -sin(deg_to_rad(a)))
	return n.rotated(Vector3.UP, deg_to_rad(yaw))

## A small dome (a lamp bulb, dynamic) on local point c, bulging along local axis ax.
static func dome(b, g, m, xf, c, ax, r, seg = 8):
	var s = b.st(g, m, true)
	var u = ax.cross(Vector3.UP)
	if u.length() < 0.1:
		u = Vector3.RIGHT
	u = u.normalized()
	var v = ax.cross(u).normalized()
	var rings = [[0.0, 1.0], [0.68, 0.73]]
	for j in rings.size():
		for i in seg:
			var a0 = TAU * i / seg
			var a1 = TAU * (i + 1) / seg
			var e0 = rings[j]
			var d0 = u * cos(a0) + v * sin(a0)
			var d1 = u * cos(a1) + v * sin(a1)
			var p00 = c + ax * e0[0] * r + d0 * e0[1] * r
			var p01 = c + ax * e0[0] * r + d1 * e0[1] * r
			var n00 = (ax * e0[0] + d0 * e0[1]).normalized()
			var n01 = (ax * e0[0] + d1 * e0[1]).normalized()
			if j == rings.size() - 1:
				var tp = c + ax * r
				stri(b, s, [xf * p00, xf * p01, xf * tp], [(xf.basis * n00).normalized(), (xf.basis * n01).normalized(), (xf.basis * ax).normalized()], [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])
			else:
				var e1 = rings[j + 1]
				var p10 = c + ax * e1[0] * r + d0 * e1[1] * r
				var p11 = c + ax * e1[0] * r + d1 * e1[1] * r
				var n10 = (ax * e1[0] + d0 * e1[1]).normalized()
				var n11 = (ax * e1[0] + d1 * e1[1]).normalized()
				var P = [xf * p00, xf * p01, xf * p11, xf * p10]
				var N = [(xf.basis * n00).normalized(), (xf.basis * n01).normalized(), (xf.basis * n11).normalized(), (xf.basis * n10).normalized()]
				stri(b, s, [P[0], P[1], P[2]], [N[0], N[1], N[2]], [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])
				stri(b, s, [P[0], P[2], P[3]], [N[0], N[2], N[3]], [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])

# ---------------------------------------------------------------- build
## Builds one machine. The player stands at `o` (floor, centre of the front edge) facing `f`.
static func build(b, g, o, f, opts = {}):
	if opts.get("double", false):
		half(b, g, X(o, f), true)
		half(b, g, X(o + f * (2.0 * ZM), -f), true)
	else:
		half(b, g, X(o, f), false)

## One playfield and its cabinet in the frame xf; dbl: one side of the double cabinet.
static func half(b, g, xf, dbl):
	var rng = RandomNumberGenerator.new()
	rng.seed = 1995
	var UP = Vector3.UP; var FR = Vector3(0, 0, -1); var BK = Vector3(0, 0, 1)

	# ---- plinth, lower front, sill
	if dbl:
		b.box(g, "pc_pusher_plinth", Vector3(0, 0.035, 0.04 + (ZM - 0.04) * 0.5), Vector3(1.60, 0.07, ZM - 0.04), xf, ["+z"])
	else:
		b.box(g, "pc_pusher_plinth", Vector3(0, 0.035, 0.55), Vector3(1.60, 0.07, 1.02), xf)
	q(b, g, "pc_pusher_front", xf, [Vector3(-IW, 0.07, 0), Vector3(IW, 0.07, 0), Vector3(IW, 0.70, 0), Vector3(-IW, 0.70, 0)], FR, ruv())
	b.box(g, "pc_pusher_alu", Vector3(0, 0.7425, 0.03), Vector3(2.0 * HW, 0.085, 0.09), xf)
	# payout cups: black plastic trays standing out of the doors
	for cx in PX:
		b.box(g, "pc_pusher_cup", Vector3(cx, 0.195, -0.035), Vector3(0.15, 0.012, 0.07), xf)
		for sx in [-1.0, 1.0]:
			b.box(g, "pc_pusher_cup", Vector3(cx + sx * 0.069, 0.23, -0.035), Vector3(0.012, 0.058, 0.07), xf, [], true)
		b.box(g, "pc_pusher_cup", Vector3(cx, 0.214, -0.068), Vector3(0.15, 0.036, 0.008), xf)
		b.box(g, "pc_pusher_cup", Vector3(cx, 0.274, -0.022), Vector3(0.15, 0.012, 0.044), xf)

	# ---- side panels: blue below, grey wing above (one painted face), the side windows
	var suv = func(v): return Vector2(v.x / 1.1, 1.0 - v.y / 2.2)
	var iuv = func(v): return Vector2(v.x / 0.4, -v.y / 0.4)
	var emats = ["", "pc_pusher_trim", "pc_pusher_trim", "pc_pusher_trim", "pc_pusher_trim", "pc_pusher_alu", "pc_pusher_alu", "pc_pusher_alu", "pc_pusher_alu", "pc_pusher_alu", "pc_pusher_alu"]
	var side = SIDE
	var ear = EAR
	var ear_m = ["pc_pusher_trim", "pc_pusher_trim", "pc_pusher_alu", "pc_pusher_alu"]
	if dbl:
		side = SIDE_H
		ear = EAR_H
		emats = ["", "", "pc_pusher_trim", "pc_pusher_alu", "pc_pusher_alu", "pc_pusher_alu", "pc_pusher_alu", "pc_pusher_alu", "pc_pusher_alu"]
		ear_m = ["pc_pusher_trim", "", "pc_pusher_alu", "pc_pusher_alu"]
	for sx in [-1.0, 1.0]:
		zpoly(b, g, "pc_pusher_side", xf, side, sx * HW, sx, suv)
		zpoly(b, g, "pc_pusher_inner", xf, INNER, sx * IW, -sx, iuv)
		zedges(b, g, emats, xf, side, sx * IW, sx * HW)
		# the ears beside the marquee
		zpoly(b, g, "pc_pusher_side", xf, ear, sx * HW, sx, suv)
		zpoly(b, g, "pc_pusher_side", xf, ear, sx * IW, -sx, suv)
		zedges(b, g, ear_m, xf, ear, sx * IW, sx * HW)
		# side window glass and the corner post where it meets the front glass
		var xg = sx * (HW + IW) * 0.5
		var gp = []
		for v in SWIN:
			gp.append(Vector3(xg, v.y, v.x))
		q(b, g, "pc_pusher_glass", xf, gp, Vector3(sx, 0, 0), [Vector2(0.0, 1.0), Vector2(0.7, 0.71), Vector2(0.7, 0.0), Vector2(0.38, 0.0)], true)
		obox(b, g, "pc_pusher_alu", xf, Vector3(sx * 0.803, G0.y - 0.01, G0.x), Vector3(sx * 0.803, G1.y + 0.01, G1.x), 0.046, 0.034)

	# ---- the back: plain painted panels
	if not dbl:
		q(b, g, "pc_pusher_dark", xf, [Vector3(IW, 0.07, D), Vector3(-IW, 0.07, D), Vector3(-IW, 1.00, D), Vector3(IW, 1.00, D)], BK)
		q(b, g, "pc_pusher_dark", xf, [Vector3(IW, 1.00, D), Vector3(-IW, 1.00, D), Vector3(-IW, 1.48, 0.82), Vector3(IW, 1.48, 0.82)], Vector3(0, 0.28, 0.48).normalized())
		q(b, g, "pc_pusher_dark", xf, [Vector3(IW, 1.48, 0.82), Vector3(-IW, 1.48, 0.82), Vector3(-IW, Y_TOP, 0.82), Vector3(IW, Y_TOP, 0.82)], BK)
	q(b, g, "pc_pusher_dark", xf, [Vector3(-IW, Y_TOP, Z_BAND), Vector3(IW, Y_TOP, Z_BAND), Vector3(IW, Y_TOP, 0.82), Vector3(-IW, Y_TOP, 0.82)], UP)

	# ---- window: glass leaning back, aluminium frame
	var gy = Vector3(0, G1.y - G0.y, G1.x - G0.x)
	var L = gy.length()
	gy = gy / L
	var gx = Vector3.RIGHT
	var gn = gx.cross(gy)          # into the machine
	var GP = func(x, s): return Vector3(x, G0.y, G0.x) + gy * s
	var gb = Basis(gx, gy, gn)
	b.box(g, "pc_pusher_alu", Vector3.ZERO, Vector3(1.60, 0.06, 0.02), xf * Transform3D(gb, GP.call(0.0, 0.03) - gn * 0.012))
	b.box(g, "pc_pusher_alu", Vector3.ZERO, Vector3(1.60, 0.04, 0.02), xf * Transform3D(gb, GP.call(0.0, L - 0.02) - gn * 0.012))
	for sx in [-1.0, 1.0]:
		b.box(g, "pc_pusher_alu", Vector3.ZERO, Vector3(0.04, L, 0.02), xf * Transform3D(gb, GP.call(sx * 0.77, L * 0.5) - gn * 0.012))
	q(b, g, "pc_pusher_glass", xf, [GP.call(-IW, 0.0), GP.call(IW, 0.0), GP.call(IW, L), GP.call(-IW, L)], -gn, ruv(), true)

	# ---- coin band with the three coin mechanisms
	q(b, g, "pc_pusher_band", xf, [Vector3(-IW, Y_BAND, Z_BAND), Vector3(IW, Y_BAND, Z_BAND), Vector3(IW, Y_TOP, Z_BAND), Vector3(-IW, Y_TOP, Z_BAND)], FR, ruv())
	b.box(g, "pc_pusher_chrome", Vector3(0, Y_TOP - 0.006, Z_BAND - 0.004), Vector3(2.0 * IW, 0.014, 0.012), xf)
	for cx in PX:
		b.box(g, "pc_pusher_chrome", Vector3(cx, 1.645, Z_BAND - 0.015), Vector3(0.10, 0.11, 0.03), xf, ["-z"])
		q(b, g, "pc_pusher_mech", xf, [Vector3(cx - 0.05, 1.59, Z_BAND - 0.0305), Vector3(cx + 0.05, 1.59, Z_BAND - 0.0305), Vector3(cx + 0.05, 1.70, Z_BAND - 0.0305), Vector3(cx - 0.05, 1.70, Z_BAND - 0.0305)], FR, ruv())

	# ---- marquee box on its ears, a small gap above the body
	var zmb = ZM if dbl else Z_MB
	b.box(g, "pc_pusher_dark", Vector3(0, (Y_M0 + Y_M1) * 0.5, (Z_M + zmb) * 0.5), Vector3(2.0 * IW, Y_M1 - Y_M0, zmb - Z_M), xf, ["-z", "+z"] if dbl else ["-z"])
	for sx in [-1.0, 1.0]:
		b.box(g, "pc_pusher_dark", Vector3(sx * 0.62, (Y_TOP + Y_M0) * 0.5, 0.42), Vector3(0.06, Y_M0 - Y_TOP, 0.10), xf, [], true)
	var zm = Z_M - 0.001
	q(b, g, "pc_pusher_dark", xf, [Vector3(-IW, Y_M0, zm), Vector3(IW, Y_M0, zm), Vector3(IW, Y_M1, zm), Vector3(-IW, Y_M1, zm)], FR)
	var mq = [Vector3(-0.772, Y_M0 + 0.03, zm - 0.002), Vector3(0.772, Y_M0 + 0.03, zm - 0.002), Vector3(0.772, Y_M1 - 0.03, zm - 0.002), Vector3(-0.772, Y_M1 - 0.03, zm - 0.002)]
	q(b, g, "pc_pusher_marquee", xf, mq, FR, ruv())
	b.box(g, "pc_pusher_chrome", Vector3(0, Y_M1 - 0.015, Z_M - 0.008), Vector3(2.0 * IW, 0.03, 0.014), xf)
	b.box(g, "pc_pusher_chrome", Vector3(0, Y_M0 + 0.015, Z_M - 0.008), Vector3(2.0 * IW, 0.03, 0.014), xf)
	# chaser bulbs along the top and bottom rails (lit steady; small, so dynamic)
	for yb in [Y_M0 + 0.015, Y_M1 - 0.015]:
		for i in 15:
			var xb = -0.70 + 1.40 * i / 14.0
			dome(b, g, "pc_pusher_bulb" if i % 2 == 0 else "pc_pusher_bulb2", xf, Vector3(xb, yb, Z_M - 0.015), FR, 0.0105)
	for sx in [-1.0, 1.0]:
		b.box(g, "pc_pusher_chrome", Vector3(sx * 0.781, (Y_M0 + Y_M1) * 0.5, Z_M - 0.008), Vector3(0.018, Y_M1 - Y_M0, 0.014), xf)
	if "signs" in b:
		# the name is owner-editable (scripts/signs.gd); paint_pusher.py paints the word-free copy
		var mp = []
		for v in mq:
			mp.append(xf * v)
		b.sign_add("pc.pusher.1", "pc_pusher", "COIN COMET", 0, [[mp, ruv(), (xf.basis * FR).normalized()]],
			{"tex": "res://tex/pc/pusher_marquee_blank.png", "look": {"font": "sans_italic", "fill": "#ff3a2a", "outline": "#3a0a08"}})

	# ---- inside the top: lit diffuser, the fluorescent tube behind a valance
	q(b, g, "pc_pusher_ceil", xf, [Vector3(-IW, Y_CEIL, Z_BACK), Vector3(IW, Y_CEIL, Z_BACK), Vector3(IW, Y_CEIL, Z_BAND), Vector3(-IW, Y_CEIL, Z_BAND)], Vector3.DOWN)
	lcyl(b, g, "pc_pusher_tube", xf, Vector3(-0.70, 1.437, 0.37), Vector3.RIGHT, 0.013, 1.40)
	for sx in [-1.0, 1.0]:
		b.box(g, "pc_pusher_dark", Vector3(sx * 0.72, 1.445, 0.37), Vector3(0.04, 0.05, 0.04), xf, [], true)
	b.box(g, "pc_pusher_alu", Vector3(0, 1.4325, 0.327), Vector3(2.0 * IW, 0.075, 0.006), xf)

	# ---- translites (one back-lit panel per position; the fins hide the seams)
	q(b, g, "pc_pusher_back", xf, [Vector3(-IW, Y_PT - 0.004, Z_BACK), Vector3(IW, Y_PT - 0.004, Z_BACK), Vector3(IW, Y_CEIL, Z_BACK), Vector3(-IW, Y_CEIL, Z_BACK)], FR, ruv())

	# ---- the playfield: trough, lower shelf, pusher deck
	q(b, g, "pc_pusher_dark", xf, [Vector3(-IW, 0.72, 0.065), Vector3(IW, 0.72, 0.065), Vector3(IW, 0.72, Z_DROP), Vector3(-IW, 0.72, Z_DROP)], UP)
	q(b, g, "pc_pusher_dark", xf, [Vector3(-IW, 0.72, 0.066), Vector3(IW, 0.72, 0.066), Vector3(IW, G0.y + 0.005, 0.066), Vector3(-IW, G0.y + 0.005, 0.066)], BK)
	q(b, g, "pc_pusher_dark", xf, [Vector3(-IW, 0.72, Z_DROP), Vector3(IW, 0.72, Z_DROP), Vector3(IW, Y_SH - 0.016, Z_DROP), Vector3(-IW, Y_SH - 0.016, Z_DROP)], FR)
	q(b, g, "pc_pusher_steel", xf, [Vector3(-IW, Y_SH - 0.016, Z_DROP - 0.001), Vector3(IW, Y_SH - 0.016, Z_DROP - 0.001), Vector3(IW, Y_SH - 0.003, Z_DROP - 0.001), Vector3(-IW, Y_SH - 0.003, Z_DROP - 0.001)], FR)
	q(b, g, "pc_pusher_steel", xf, [Vector3(-IW, Y_SH, Z_PUSH), Vector3(IW, Y_SH, Z_PUSH), Vector3(IW, Y_PT - 0.002, Z_PUSH), Vector3(-IW, Y_PT - 0.002, Z_PUSH)], FR)
	var hlo = func(x, z): return heap_lo(x, z)
	var hhi = func(x, z): return heap_hi(x, z)
	for k in 3:
		var cx = PX[k]
		var x0 = cx - PH; var x1 = cx + PH
		heap(b, g, xf, x0, x1, Z_DROP, Z_PUSH, Y_SH, hlo, 16, 9, 0.31 * k)
		heap_front(b, g, xf, x0, x1, Z_DROP, Y_SH - 0.004, Y_SH, hlo, Z_DROP, 16)
		heap(b, g, xf, x0, x1, Z_PUSH, Z_BACK, Y_PT, hhi, 12, 6, 0.53 * k + 0.2)
		heap_front(b, g, xf, x0, x1, Z_PUSH, Y_PT - 0.004, Y_PT, hhi, Z_PUSH, 12)

	# ---- blue art ramps between the positions, perforated deflectors at the walls
	for xr in [-PH, PH]:
		var zf = Z_DROP + 0.012
		var yr0 = Y_SH + 0.034
		var yr1 = Y_SH + 0.072
		for s in [-1.0, 1.0]:
			var p = [Vector3(xr + s * 0.056, Y_SH, zf), Vector3(xr, yr0, zf), Vector3(xr, yr1, Z_PUSH), Vector3(xr + s * 0.056, Y_SH, Z_PUSH)]
			var nn = (p[1] - p[0]).cross(p[3] - p[0]).normalized()
			if nn.y < 0.0:
				nn = -nn
			q(b, g, "pc_pusher_ramp", xf, p, nn, [Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])
		var st = b.st(g, "pc_pusher_chrome", true)
		b.tri(st, xf * Vector3(xr - 0.056, Y_SH, zf), xf * Vector3(xr + 0.056, Y_SH, zf), xf * Vector3(xr, yr0, zf), Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, (xf.basis * FR).normalized())
		obox(b, g, "pc_pusher_chrome", xf, Vector3(xr, yr0 + 0.004, zf - 0.004), Vector3(xr, yr1 + 0.004, Z_PUSH), 0.012, 0.01)
		for s in [-1.0, 1.0]:
			obox(b, g, "pc_pusher_chrome", xf, Vector3(xr + s * 0.054, Y_SH + 0.004, zf), Vector3(xr + s * 0.054, Y_SH + 0.004, Z_PUSH), 0.008, 0.008)
	for sx in [-1.0, 1.0]:
		var xw = sx * IW
		var xi = sx * (IW - 0.07)
		var p = [Vector3(xi, Y_SH, Z_DROP + 0.01), Vector3(xw, Y_SH + 0.05, Z_DROP + 0.01), Vector3(xw, Y_SH + 0.08, Z_PUSH), Vector3(xi, Y_SH, Z_PUSH)]
		var nn = (p[1] - p[0]).cross(p[3] - p[0]).normalized()
		if nn.y < 0.0:
			nn = -nn
		var sl = 0.09 / 0.064
		q(b, g, "pc_pusher_perf", xf, p, nn, [Vector2(0, Z_DROP / 0.064), Vector2(sl, Z_DROP / 0.064), Vector2(sl, Z_PUSH / 0.064), Vector2(0, Z_PUSH / 0.064)])
		obox(b, g, "pc_pusher_chrome", xf, Vector3(sx * (IW - 0.005), Y_SH + 0.052, Z_DROP + 0.006), Vector3(sx * (IW - 0.005), Y_SH + 0.082, Z_PUSH), 0.01, 0.012)

	# ---- steel partition fins between the positions (over the pusher deck, up the translites)
	var fuv = func(v): return Vector2(v.x / 0.3, -v.y / 0.3)
	for xr in [-PH, PH]:
		zpoly(b, g, "pc_pusher_steel", xf, FIN, xr - 0.005, -1.0, fuv)
		zpoly(b, g, "pc_pusher_steel", xf, FIN, xr + 0.005, 1.0, fuv)
		zedges(b, g, ["", "", "pc_pusher_chrome", "pc_pusher_chrome", "pc_pusher_chrome", "pc_pusher_chrome"], xf, FIN, xr - 0.005, xr + 0.005)

	# ---- white zig-zag coin chutes in front of each translite
	for k in 3:
		var cx = PX[k]
		var pts = [Vector2(cx + 0.01, Y_CEIL), Vector2(cx - 0.075, 1.37), Vector2(cx + 0.075, 1.25), Vector2(cx - 0.075, 1.13), Vector2(cx + 0.045, 1.01)]
		for i in pts.size() - 1:
			var a = Vector3(pts[i].x, pts[i].y, Z_BACK - 0.03)
			var c = Vector3(pts[i + 1].x, pts[i + 1].y, Z_BACK - 0.03)
			var dd = (c - a).normalized()
			obox(b, g, "pc_pusher_chute", xf, a - dd * 0.022, c + dd * 0.022, 0.016, 0.055)
		# a little bracket holding the chute's foot off the translite
		b.box(g, "pc_pusher_chrome", Vector3(cx + 0.045, 1.025, Z_BACK - 0.012), Vector3(0.03, 0.02, 0.024), xf, [], true)

	# ---- loose coins (dynamic): over the drop edge, along the pusher's lip, on the heaps,
	# in the trough and in two payout cups
	for k in 3:
		var cx = PX[k]
		for i in 6:
			var x = cx + rng.randf_range(-0.20, 0.20)
			var z = Z_DROP + rng.randf_range(-0.004, 0.006)
			var a = rng.randf_range(22.0, 58.0)
			var y = Y_SH + heap_lo(x, Z_DROP + 0.012) - 0.002 - sin(deg_to_rad(a)) * COIN_R * 0.4
			disc(b, g, xf, Vector3(x, y, z), tilt(a, rng.randf_range(-25.0, 25.0)), rng.randf() < 0.15)
		for i in 4:
			var x = cx + rng.randf_range(-0.22, 0.22)
			var a = rng.randf_range(15.0, 45.0)
			var y = Y_PT + heap_hi(x, Z_PUSH + 0.012) - 0.002 - sin(deg_to_rad(a)) * COIN_R * 0.4
			disc(b, g, xf, Vector3(x, y, Z_PUSH + rng.randf_range(0.0, 0.006)), tilt(a, rng.randf_range(-25.0, 25.0)), rng.randf() < 0.15)
		for i in 3:
			var x = cx + rng.randf_range(-0.18, 0.18)
			var z = rng.randf_range(0.22, 0.45)
			var a = rng.randf_range(0.0, 22.0)
			disc(b, g, xf, Vector3(x, Y_SH + heap_lo(x, z) + sin(deg_to_rad(a)) * COIN_R * 0.6 + 0.001, z), tilt(a, rng.randf_range(0.0, 360.0)), rng.randf() < 0.2, false)
		for i in 2:
			var x = cx + rng.randf_range(-0.2, 0.2)
			var z = rng.randf_range(0.56, 0.74)
			var a = rng.randf_range(0.0, 20.0)
			disc(b, g, xf, Vector3(x, Y_PT + heap_hi(x, z) + sin(deg_to_rad(a)) * COIN_R * 0.6 + 0.001, z), tilt(a, rng.randf_range(0.0, 360.0)), rng.randf() < 0.2, false)
		disc(b, g, xf, Vector3(cx + rng.randf_range(-0.2, 0.2), 0.72 + COIN_T * 0.5 + 0.0005, rng.randf_range(0.078, 0.108)), tilt(rng.randf_range(0, 6), 0), rng.randf() < 0.2, false)
	for k in [0, 2]:
		for i in 3:
			disc(b, g, xf, Vector3(PX[k] + rng.randf_range(-0.045, 0.045), 0.2015 + i * 0.0006, rng.randf_range(-0.055, -0.02)), tilt(rng.randf_range(0, 12), rng.randf_range(0, 360)), i == 1, false)

	# walk obstacle
	var c0 = xf * Vector3(-HW, 0, 0)
	var c1 = xf * Vector3(HW, 0, ZM if dbl else D)
	b.obst(["rect", min(c0.x, c1.x), min(c0.z, c1.z), max(c0.x, c1.x), max(c0.z, c1.z)])

## Material "pc_pusher_<key>".
static func fill_mat(m, key, b):
	match key:
		"front", "side", "band":
			m.albedo_texture = b.tex("pc/pusher_%s.png" % key)
			m.roughness = 0.35; m.metallic_specular = 0.6
		"inner":
			m.albedo_texture = b.tex("pc/pusher_inner.png"); m.roughness = 0.5
		"mech":
			m.albedo_texture = b.tex("pc/pusher_mech.png"); m.roughness = 0.25; m.metallic = 0.3
		"marquee", "back":
			var e = 1.4 if key == "marquee" else 1.3
			m.albedo_texture = b.tex("pc/pusher_%s.png" % key); m.roughness = 0.3
			m.emission_enabled = true; m.emission_texture = b.tex("pc/pusher_%s.png" % key)
			m.emission = Color.WHITE; m.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY
			m.emission_energy_multiplier = e
			m.set_meta("e_day", e); m.set_meta("e_night", e)
		"coins", "edge", "coin":
			# the playfield under its fluorescent tube: a little self light stands in for it
			m.albedo_texture = b.tex("pc/pusher_%s.png" % key)
			m.metallic = 0.55; m.roughness = 0.38
			m.emission_enabled = true; m.emission_texture = b.tex("pc/pusher_%s.png" % key)
			m.emission = Color.WHITE; m.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY
			var e = 0.75 if key == "edge" else 0.85
			m.emission_energy_multiplier = e
			m.set_meta("e_day", e); m.set_meta("e_night", e)
		"ramp":
			m.albedo_texture = b.tex("pc/pusher_ramp.png"); m.roughness = 0.3
			m.emission_enabled = true; m.emission_texture = b.tex("pc/pusher_ramp.png")
			m.emission = Color.WHITE; m.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY
			m.emission_energy_multiplier = 0.5
			m.set_meta("e_day", 0.5); m.set_meta("e_night", 0.5)
		"perf":
			m.albedo_texture = b.tex("pc/pusher_perf.png"); m.roughness = 0.35; m.metallic = 0.4
		"glass":
			m.albedo_texture = b.tex("pc/pusher_glass.png")
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.albedo_color = Color(1, 1, 1, 1)
			m.roughness = 0.04; m.metallic_specular = 0.9
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
		"alu":
			m.albedo_color = Color("#d0d4da"); m.metallic = 0.45; m.roughness = 0.32
		"chrome":
			m.albedo_color = Color("#eceef2"); m.metallic = 0.55; m.roughness = 0.18
		"steel":
			m.albedo_color = Color("#aab0b8"); m.metallic = 0.45; m.roughness = 0.32
		"trim":
			m.albedo_color = Color("#7c8894"); m.roughness = 0.5
		"dark":
			m.albedo_color = Color("#14182a"); m.roughness = 0.6
		"plinth":
			m.albedo_color = Color("#0c0c0e"); m.roughness = 0.7
		"cup":
			m.albedo_color = Color("#101012"); m.roughness = 0.45
		"chute":
			# white acrylic, glowing with the tube and the translites behind it
			m.albedo_color = Color("#f4f4f0"); m.roughness = 0.3
			m.emission_enabled = true; m.emission = Color("#fffdf6"); m.emission_energy_multiplier = 0.8
			m.set_meta("e_day", 0.8); m.set_meta("e_night", 0.8)
		"bulb", "bulb2":
			var bc = Color("#ffd88a") if key == "bulb" else Color("#fff2d8")
			m.albedo_color = bc; m.roughness = 0.2
			m.emission_enabled = true; m.emission = bc; m.emission_energy_multiplier = 3.0
			m.set_meta("e_day", 3.0); m.set_meta("e_night", 3.0)
		"ceil":
			m.albedo_color = Color("#eef2f6"); m.roughness = 0.8
			m.emission_enabled = true; m.emission = Color("#eef4ff"); m.emission_energy_multiplier = 1.0
			m.set_meta("e_day", 1.0); m.set_meta("e_night", 1.0)
		"tube":
			m.albedo_color = Color.WHITE
			m.emission_enabled = true; m.emission = Color("#f2f6ff"); m.emission_energy_multiplier = 4.0
			m.set_meta("e_day", 4.0); m.set_meta("e_night", 4.0)
		_:
			return false
	return true
