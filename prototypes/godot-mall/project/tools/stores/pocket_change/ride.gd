## Pocket Change: the deluxe enclosed two-seat motion-ride cabinet that stood in the middle
## of the arcade (a dinosaur light-gun game, 1994 era). The machine TYPE only: the
## title "TALON CREEK" and all its art are original (tools/stores/pocket_change/README.md).
##
## Form factor (mid-90s deluxe motion cabins): a fibreglass capsule on a motion base,
## about 1.7 m wide, 2.6 m long, 2.4 m tall with the marquee. Riders climb a carpeted
## step at the rear (z = 0, where the player stands), pass a split black curtain and sit
## on a two-place vinyl bench facing a 50-inch projection screen at the far end
## (z = depth), with a mounted light gun and a START button each. Outside: painted side
## art, a backlit marquee over the entry, rubber bumpers, a bellows skirt over the motion
## base, a token door, a safety placard and a "2 PLAYERS" sign.
## Livery (after the Oct 5 IP review): sunset-orange gloss upper body, charcoal lower body,
## chrome trim lines and door edge, purple accents; canyon art with generic dinosaurs.
## Textures: tools/stores/pocket_change/paint_ride.py -> tex/pc/ride_*.png.
##   tools/qa/preview.sh ride /home/claude/houma-mall-rewind/.scratch/preview/ride/v "0,1.6,3.6,0,-8;-0.3,1.55,-1.0,0,-6"

const W = 1.74    # overall width with the bumpers (shell 1.64)
const D = 2.64    # overall length, step to front bumper
const BOT = 0.34  # shell bottom = top of the motion base
const FLOOR = 0.40   # cabin floor
const HW = 0.82   # shell half width
# shell stations along z: [z, half width, top, roof corner radius]
const ST = [[0.300, 0.795, 2.075, 0.275], [0.335, 0.82, 2.10, 0.30], [2.30, 0.82, 2.10, 0.30],
	[2.42, 0.812, 2.07, 0.33], [2.50, 0.79, 2.01, 0.36], [2.56, 0.75, 1.90, 0.36], [2.60, 0.68, 1.74, 0.32]]
const ART_Z0 = 0.335
const ART_Z1 = 2.30
const IN_HW = 0.77    # cabin inside
const IN_TOP = 2.05
const IN_RT = 0.25
const IN_Z0 = 0.36    # inside face of the rear wall
const IN_Z1 = 2.40    # front wall (behind the screen shroud)
const DOOR = [0.50, 1.86, 0.16]   # door half width, top, corner radius (bottom = FLOOR)
const SEGS = 12       # segments per rounded corner

## Footprint (width, depth) in metres, for the store's layout.
static func footprint(_opts = {}):
	return Vector2(W, D)

## The machine's frame: local x = player's right, y = up, z = into the machine (along f).
static func X(o, f):
	return Transform3D(Basis(f.cross(Vector3.UP), Vector3.UP, f), o)

# ------------------------------------------------------------------ helpers
## A rounded-roof cross-section, open at the bottom: right side up, right corner, roof,
## left corner, left side down. Returns [points (Vector2), outward normals (Vector2)].
static func ring(hw, top, bot, rt):
	var p = [Vector2(hw, bot)]
	var n = [Vector2(1, 0)]
	for i in SEGS + 1:
		var a = PI * 0.5 * i / SEGS
		p.append(Vector2(hw - rt, top - rt) + Vector2(cos(a), sin(a)) * rt)
		n.append(Vector2(cos(a), sin(a)))
	for i in SEGS + 1:
		var a = PI * 0.5 + PI * 0.5 * i / SEGS
		p.append(Vector2(-(hw - rt), top - rt) + Vector2(cos(a), sin(a)) * rt)
		n.append(Vector2(cos(a), sin(a)))
	p.append(Vector2(-hw, bot))
	n.append(Vector2(-1, 0))
	return [p, n]

static func arclen(p):
	var s = [0.0]
	for k in range(1, p.size()):
		s.append(s[k - 1] + p[k].distance_to(p[k - 1]))
	return s

## One triangle with per-vertex normals (world space); winding as build_mall.gd's tri().
static func _t(b, s, p, n, uv):
	var order = [0, 1, 2]
	if (p[1] - p[0]).cross(p[2] - p[0]).dot(n[0] + n[1] + n[2]) > 0.0:
		order = [0, 2, 1]
	for i in order:
		s.set_color(b.cur_color)
		s.set_normal(n[i])
		s.set_uv(uv[i])
		s.add_vertex(p[i])

## A smooth-shaded quad from local points/normals.
static func sq(b, g, m, xf, p, n, uv, dyn = false):
	var s = b.st(g, m, dyn)
	var wp = []
	var wn = []
	for i in 4:
		wp.append(xf * p[i])
		wn.append((xf.basis * n[i]).normalized())
	_t(b, s, [wp[0], wp[1], wp[2]], [wn[0], wn[1], wn[2]], [uv[0], uv[1], uv[2]])
	_t(b, s, [wp[0], wp[2], wp[3]], [wn[0], wn[2], wn[3]], [uv[0], uv[2], uv[3]])

## A flat quad from local points.
static func q(b, g, m, xf, p, n, uv = [], dyn = false):
	var wp = []
	for v in p:
		wp.append(xf * v)
	b.quad(g, m, wp, (xf.basis * n).normalized(), uv, dyn)

## A planar-UV quad in a local axis plane: UVs from local coordinates (metres * k).
static func qp(b, g, m, xf, p, n, k = 1.0, dyn = false):
	var uv = []
	for v in p:
		if absf(n.z) > 0.5:
			uv.append(Vector2(v.x * signf(-n.z), -v.y) * k)
		elif absf(n.x) > 0.5:
			uv.append(Vector2(v.z * signf(n.x), -v.y) * k)
		else:
			uv.append(Vector2(v.x, v.z) * k)
	q(b, g, m, xf, p, n, uv, dyn)

## Box with UVs at k repeats per metre (b.box is fixed at 1).
static func bx(b, g, m, c, size, xf, skip = [], dyn = false, k = 1.0):
	var h = size * 0.5
	var faces = {
		"+x": [Vector3(1, 0, 0), [Vector3(h.x, -h.y, -h.z), Vector3(h.x, h.y, -h.z), Vector3(h.x, h.y, h.z), Vector3(h.x, -h.y, h.z)]],
		"-x": [Vector3(-1, 0, 0), [Vector3(-h.x, -h.y, h.z), Vector3(-h.x, h.y, h.z), Vector3(-h.x, h.y, -h.z), Vector3(-h.x, -h.y, -h.z)]],
		"+y": [Vector3(0, 1, 0), [Vector3(-h.x, h.y, -h.z), Vector3(-h.x, h.y, h.z), Vector3(h.x, h.y, h.z), Vector3(h.x, h.y, -h.z)]],
		"-y": [Vector3(0, -1, 0), [Vector3(-h.x, -h.y, h.z), Vector3(-h.x, -h.y, -h.z), Vector3(h.x, -h.y, -h.z), Vector3(h.x, -h.y, h.z)]],
		"+z": [Vector3(0, 0, 1), [Vector3(h.x, -h.y, h.z), Vector3(h.x, h.y, h.z), Vector3(-h.x, h.y, h.z), Vector3(-h.x, -h.y, h.z)]],
		"-z": [Vector3(0, 0, -1), [Vector3(-h.x, -h.y, -h.z), Vector3(-h.x, h.y, -h.z), Vector3(h.x, h.y, -h.z), Vector3(h.x, -h.y, -h.z)]],
	}
	for key in faces:
		if key in skip:
			continue
		var uv = []
		var fq = faces[key][1]
		var nn = faces[key][0]
		for v in fq:
			var lv = c + v
			if absf(nn.x) > 0.5:
				uv.append(Vector2(lv.z * nn.x, -lv.y) * k)
			elif absf(nn.y) > 0.5:
				uv.append(Vector2(lv.x, lv.z * nn.y) * k)
			else:
				uv.append(Vector2(-lv.x * nn.z, -lv.y) * k)
		var pts = []
		for v in fq:
			pts.append(xf * (c + v))
		b.quad(g, m, pts, (xf.basis * nn).normalized(), uv, dyn)

## Strip of smooth quads between two polylines A and B (local 3D) with normals and UVs.
static func strip(b, g, m, xf, A, B, NA, NB, UA, UB, dyn = false):
	for k in A.size() - 1:
		sq(b, g, m, xf, [A[k], A[k + 1], B[k + 1], B[k]], [NA[k], NA[k + 1], NB[k + 1], NB[k]], [UA[k], UA[k + 1], UB[k + 1], UB[k]], dyn)

## A flat fan over a closed outline (convex), planar UVs u = (x - u0) * ku, v = (v0 - y) * kv.
static func fan(b, g, m, xf, pts, z, n, c, u0, ku, v0, kv):
	var s = b.st(g, m)
	var wn = (xf.basis * n).normalized()
	var cc = xf * Vector3(c.x, c.y, z)
	var cu = Vector2((c.x - u0) * ku, (v0 - c.y) * kv)
	for k in pts.size():
		var a = pts[k]
		var bb = pts[(k + 1) % pts.size()]
		b.tri(s, cc, xf * Vector3(a.x, a.y, z), xf * Vector3(bb.x, bb.y, z), cu,
			Vector2((a.x - u0) * ku, (v0 - a.y) * kv), Vector2((bb.x - u0) * ku, (v0 - bb.y) * kv), wn)

## A padded "loaf" (cushion, backrest): a rounded-top section in the frame's (z, y) plane,
## extruded along the frame's x from x0 to x1, centred on z = 0, with end caps.
static func loaf(b, g, m, fr, x0, x1, dz, bot, top, r, k = 3.0, dyn = false):
	var L = fr * Transform3D(Basis(Vector3(0, 0, 1), Vector3(0, 1, 0), Vector3(1, 0, 0)), Vector3.ZERO)
	var rr = ring(dz * 0.5, top, bot, r)
	var P = rr[0]
	var N = rr[1]
	var s = arclen(P)
	var A = []
	var B = []
	var NA = []
	var UA = []
	var UB = []
	for i in P.size():
		A.append(Vector3(P[i].x, P[i].y, x0))
		B.append(Vector3(P[i].x, P[i].y, x1))
		NA.append(Vector3(N[i].x, N[i].y, 0))
		UA.append(Vector2(s[i] * k, x0 * k))
		UB.append(Vector2(s[i] * k, x1 * k))
	strip(b, g, m, L, A, B, NA, NA, UA, UB, dyn)
	var c = Vector2(0, (bot + top) * 0.5)
	fan(b, g, m, L, P, x0, Vector3(0, 0, -1), c, 0.0, k, 0.0, k)
	fan(b, g, m, L, P, x1, Vector3(0, 0, 1), c, 0.0, k, 0.0, k)

## A cylinder along the frame's z from z0 to z1 (radius r), with end caps; small parts.
static func zcyl(b, g, m, fr, r, z0, z1, seg = 12, dyn = true):
	var s = b.st(g, m, dyn)
	for i in seg:
		var a0 = TAU * i / seg
		var a1 = TAU * (i + 1) / seg
		var d0 = Vector3(cos(a0), sin(a0), 0)
		var d1 = Vector3(cos(a1), sin(a1), 0)
		var p = [fr * (d0 * r + Vector3(0, 0, z0)), fr * (d1 * r + Vector3(0, 0, z0)), fr * (d1 * r + Vector3(0, 0, z1)), fr * (d0 * r + Vector3(0, 0, z1))]
		var n0 = (fr.basis * d0).normalized()
		var n1 = (fr.basis * d1).normalized()
		var uv = [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]
		_t(b, s, [p[0], p[1], p[2]], [n0, n1, n1], [uv[0], uv[1], uv[2]])
		_t(b, s, [p[0], p[2], p[3]], [n0, n1, n0], [uv[0], uv[2], uv[3]])
		var nz = (fr.basis * Vector3(0, 0, 1)).normalized()
		b.tri(s, fr * Vector3(0, 0, z1), p[3], p[2], Vector2(0.5, 0.5), uv[0], uv[1], nz)
		b.tri(s, fr * Vector3(0, 0, z0), p[0], p[1], Vector2(0.5, 0.5), uv[0], uv[1], -nz)

static func atlas(x0, y0, x1, y1):
	# atlas pixel rect (512 px) -> UVs for a quad listed bottom-left, bottom-right, top-right, top-left
	return [Vector2(x0, y1) / 512.0, Vector2(x1, y1) / 512.0, Vector2(x1, y0) / 512.0, Vector2(x0, y0) / 512.0]

# ------------------------------------------------------------------ build
## Builds one machine. The player stands at `o` (floor, centre of the machine's rear/entry
## edge) facing `f`; the machine fills x in [-W/2, W/2], z in [0, D].
static func build(b, g, o, f, _opts = {}):
	var xf = X(o, f)
	b.cur_color = Color.WHITE
	_shell(b, g, xf)
	_base(b, g, xf)
	_rear(b, g, xf)
	_cabin(b, g, xf)
	_marquee(b, g, xf)
	_guns(b, g, xf)
	_front(b, g, xf)
	b.cur_color = Color.WHITE
	# one small light inside the cabin: the screen's glow on the riders and out of the door
	var l = b.add_omni(xf * Vector3(0, 1.50, 1.60), 0.8, 2.3, Color(0.95, 0.78, 0.82), true)
	b.tag(l, "", 0.8, 0.8)
	var c0 = xf * Vector3(-W * 0.5, 0, 0)
	var c1 = xf * Vector3(W * 0.5, 0, D)
	b.obst(["rect", min(c0.x, c1.x), min(c0.z, c1.z), max(c0.x, c1.x), max(c0.z, c1.z)])

## The fibreglass capsule: lofted rounded-roof sections, side art on the flat sides.
static func _shell(b, g, xf):
	var R = []
	var RN = []
	var S = []
	for st in ST:
		var r = ring(st[1], st[2], BOT, st[3])
		var pts = []
		for p in r[0]:
			pts.append(Vector3(p.x, p.y, st[0]))
		R.append(pts)
		RN.append(r[1])
		S.append(arclen(r[0]))
	var ns = R[0].size()
	# smooth vertex normals from the loft's two tangents
	var N = []
	for i in R.size():
		var row = []
		for k in ns:
			var tr = R[i][min(k + 1, ns - 1)] - R[i][max(k - 1, 0)]
			var tz = R[min(i + 1, R.size() - 1)][k] - R[max(i - 1, 0)][k]
			var nn = tr.cross(tz).normalized()
			if nn.dot(Vector3(RN[i][k].x, RN[i][k].y, 0)) < 0.0:
				nn = -nn
			row.append(nn)
		N.append(row)
	for i in R.size() - 1:
		var za = ST[i][0]
		var zb = ST[i + 1][0]
		for k in ns - 1:
			var p = [R[i][k], R[i][k + 1], R[i + 1][k + 1], R[i + 1][k]]
			var n = [N[i][k], N[i][k + 1], N[i + 1][k + 1], N[i + 1][k]]
			var art = (k == 0 or k == ns - 2) and za >= ART_Z0 - 0.001 and zb <= ART_Z1 + 0.001
			if art:
				# v: 0 at y = 1.80 (top of the flat side), 1 at the shell bottom
				var uv = []
				for v in p:
					uv.append(Vector2((v.z - ART_Z0) / (ART_Z1 - ART_Z0), (1.80 - v.y) / (1.80 - BOT)))
				sq(b, g, "pc_ride_side", xf, p, n, uv)
			elif k == 0 or k == ns - 2:
				# flat sides of the bevel and the nose: the two-tone end-wall paint, by height
				var uv3 = []
				for v in p:
					uv3.append(Vector2(v.z, (2.10 - v.y) / 1.76))
				sq(b, g, "pc_ride_rear", xf, p, n, uv3)
			else:
				var uv2 = [Vector2(S[i][k], za), Vector2(S[i][k + 1], za), Vector2(S[i + 1][k + 1], zb), Vector2(S[i + 1][k], zb)]
				sq(b, g, "pc_ride_paint", xf, p, n, uv2)
	# underside of the shell (seen only from low down)
	q(b, g, "pc_ride_frame", xf, [Vector3(-0.80, BOT, 0.30), Vector3(0.80, BOT, 0.30), Vector3(0.80, BOT, 2.50), Vector3(-0.80, BOT, 2.50)], Vector3.DOWN)
	# front cap
	var F = ring(ST[-1][1], ST[-1][2], BOT, ST[-1][3])[0]
	fan(b, g, "pc_ride_rear", xf, F, ST[-1][0], Vector3(0, 0, 1), Vector2(0, 1.0), 0.0, 1.0, 2.10, 1.0 / 1.76)
	# chrome trim lines along both sides: top of the art and the orange / charcoal break
	for sx in [-1.0, 1.0]:
		for yy in [0.72, 1.80]:
			bx(b, g, "pc_ride_trim", Vector3(sx * (HW + 0.004), yy, (ART_Z0 + ART_Z1) * 0.5), Vector3(0.010, 0.020, ART_Z1 - ART_Z0), xf)
	# title decals on both sides (vinyl, alpha-scissored), read correctly from outside
	for sx in [-1.0, 1.0]:
		var x = sx * (HW + 0.004)
		var z0 = 0.62
		var z1 = 2.02
		var y0 = 1.40
		var y1 = 1.75
		var u0 = 1.0 if sx < 0 else 0.0   # the local frame is left-handed: read from outside
		var u1 = 1.0 - u0
		q(b, g, "pc_ride_title", xf, [Vector3(x, y0, z0), Vector3(x, y0, z1), Vector3(x, y1, z1), Vector3(x, y1, z0)], Vector3(sx, 0, 0),
			[Vector2(u0, 1), Vector2(u1, 1), Vector2(u1, 0), Vector2(u0, 0)])

## Motion base under the shell: steel frame, bellows skirt, rubber bumpers, the entry step.
static func _base(b, g, xf):
	bx(b, g, "pc_ride_steel", Vector3(0, 0.025, 1.43), Vector3(1.62, 0.05, 2.26), xf)
	# skirt: four bellows faces, u along the face in metres
	var y0 = 0.05
	var y1 = BOT
	var x = 0.76
	var za = 0.40
	var zb = 2.46
	q(b, g, "pc_ride_skirt", xf, [Vector3(x, y0, za), Vector3(x, y0, zb), Vector3(x, y1, zb), Vector3(x, y1, za)], Vector3.RIGHT,
		[Vector2(0, 1), Vector2(zb - za, 1), Vector2(zb - za, 0), Vector2(0, 0)])
	q(b, g, "pc_ride_skirt", xf, [Vector3(-x, y0, zb), Vector3(-x, y0, za), Vector3(-x, y1, za), Vector3(-x, y1, zb)], Vector3.LEFT,
		[Vector2(0, 1), Vector2(zb - za, 1), Vector2(zb - za, 0), Vector2(0, 0)])
	q(b, g, "pc_ride_skirt", xf, [Vector3(x, y0, zb), Vector3(-x, y0, zb), Vector3(-x, y1, zb), Vector3(x, y1, zb)], Vector3.BACK,
		[Vector2(0, 1), Vector2(2 * x, 1), Vector2(2 * x, 0), Vector2(0, 0)])
	q(b, g, "pc_ride_skirt", xf, [Vector3(-x, y0, za), Vector3(x, y0, za), Vector3(x, y1, za), Vector3(-x, y1, za)], Vector3.FORWARD,
		[Vector2(0, 1), Vector2(2 * x, 1), Vector2(2 * x, 0), Vector2(0, 0)])
	# rubber bumper rails round the shell's bottom edge
	for sx in [-1.0, 1.0]:
		bx(b, g, "pc_ride_rubber", Vector3(sx * 0.845, 0.40, 1.32), Vector3(0.05, 0.12, 2.02), xf, [], false, 2.0)
		# angled corner piece toward the nose
		var a = Vector3(sx * 0.845, 0.40, 2.33)
		var c = Vector3(sx * 0.70, 0.40, 2.615)
		var dirv = (c - a)
		var bas = Basis(Vector3.UP, atan2(dirv.x, dirv.z))
		bx(b, g, "pc_ride_rubber", Vector3.ZERO, Vector3(0.05, 0.12, dirv.length() + 0.03), xf * Transform3D(bas, (a + c) * 0.5), [], false, 2.0)
		# rear corner bumpers either side of the step
		bx(b, g, "pc_ride_rubber", Vector3(sx * 0.70, 0.40, 0.285), Vector3(0.34, 0.12, 0.05), xf, [], false, 2.0)
	bx(b, g, "pc_ride_rubber", Vector3(0, 0.40, 2.615), Vector3(1.40, 0.12, 0.05), xf, [], false, 2.0)
	# the entry step: black steel box, carpet tread, diamond-plate nosing, red rubber nosing strip
	bx(b, g, "pc_ride_frame", Vector3(0, 0.10, 0.16), Vector3(1.00, 0.20, 0.28), xf, ["+y"])
	q(b, g, "pc_ride_carpet", xf, [Vector3(-0.50, 0.20, 0.08), Vector3(0.50, 0.20, 0.08), Vector3(0.50, 0.20, 0.30), Vector3(-0.50, 0.20, 0.30)], Vector3.UP,
		[Vector2(0, 0.44), Vector2(2, 0.44), Vector2(2, 0), Vector2(0, 0)])
	q(b, g, "pc_ride_tread", xf, [Vector3(-0.50, 0.201, 0.02), Vector3(0.50, 0.201, 0.02), Vector3(0.50, 0.201, 0.08), Vector3(-0.50, 0.201, 0.08)], Vector3.UP,
		[Vector2(0, 0.24), Vector2(4, 0.24), Vector2(4, 0), Vector2(0, 0)])
	q(b, g, "pc_ride_redrub", xf, [Vector3(-0.50, 0.15, 0.018), Vector3(0.50, 0.15, 0.018), Vector3(0.50, 0.198, 0.018), Vector3(-0.50, 0.198, 0.018)], Vector3.FORWARD,
		[Vector2(0, 1), Vector2(2, 1), Vector2(2, 0), Vector2(0, 0)])

## The rear (entry) end: wall with the doorway, rubber jamb, chrome edge trim, threshold,
## token door, safety placard, "2 PLAYERS", grab handles, the curtain.
static func _rear(b, g, xf):
	var A = ring(ST[0][1], ST[0][2], BOT, ST[0][3])[0]
	var dr = ring(DOOR[0], DOOR[1], FLOOR, DOOR[2])
	var Dp = dr[0]
	var Dn = dr[1]
	var I = ring(IN_HW, IN_TOP, FLOOR, IN_RT)[0]
	var E = ring(DOOR[0] + 0.035, DOOR[1] + 0.035, FLOOR, DOOR[2] + 0.035)[0]
	var sD = arclen(Dp)
	var a3 = []
	var d3 = []
	var d3i = []
	var i3 = []
	var e3 = []
	var nb = []
	var nf = []
	var nj = []
	var ua = []
	var ud = []
	var udi = []
	var ui = []
	var uh0 = []
	var uh1 = []
	var z0 = ST[0][0]
	for k in Dp.size():
		a3.append(Vector3(A[k].x, A[k].y, z0))
		d3.append(Vector3(Dp[k].x, Dp[k].y, z0))
		d3i.append(Vector3(Dp[k].x, Dp[k].y, IN_Z0))
		i3.append(Vector3(I[k].x, I[k].y, IN_Z0))
		e3.append(Vector3(E[k].x, E[k].y, z0 - 0.003))
		nb.append(Vector3(0, 0, -1))
		nf.append(Vector3(0, 0, 1))
		nj.append(Vector3(-Dn[k].x, -Dn[k].y, 0))
		ua.append(Vector2(A[k].x, (2.10 - A[k].y) / 1.76))
		ud.append(Vector2(Dp[k].x, (2.10 - Dp[k].y) / 1.76))
		udi.append(Vector2(Dp[k].x * 2.0, -Dp[k].y * 2.0))
		ui.append(Vector2(I[k].x * 2.0, -I[k].y * 2.0))
		uh0.append(Vector2(sD[k] * 2.0, 1))
		uh1.append(Vector2(sD[k] * 2.0, 0))
	var d3h = []
	for v in d3:
		d3h.append(v - Vector3(0, 0, 0.003))
	strip(b, g, "pc_ride_rear", xf, a3, d3, nb, nb, ua, ud)
	strip(b, g, "pc_ride_rubber", xf, d3, d3i, nj, nj, uh0, uh1)
	strip(b, g, "pc_ride_wall", xf, i3, d3i, nf, nf, ui, udi)
	strip(b, g, "pc_ride_trim", xf, d3h, e3, nb, nb, uh1, uh0)
	# under the door: riser and diamond-plate threshold
	q(b, g, "pc_ride_frame", xf, [Vector3(-DOOR[0], BOT, z0), Vector3(DOOR[0], BOT, z0), Vector3(DOOR[0], FLOOR, z0), Vector3(-DOOR[0], FLOOR, z0)], Vector3.FORWARD)
	q(b, g, "pc_ride_tread", xf, [Vector3(-DOOR[0], FLOOR + 0.002, 0.28), Vector3(DOOR[0], FLOOR + 0.002, 0.28), Vector3(DOOR[0], FLOOR + 0.002, 0.44), Vector3(-DOOR[0], FLOOR + 0.002, 0.44)], Vector3.UP,
		[Vector2(0, 0.64), Vector2(4, 0.64), Vector2(4, 0), Vector2(0, 0)])
	bx(b, g, "pc_ride_frame", Vector3(0, (BOT + FLOOR) * 0.5 - 0.01, 0.29), Vector3(2 * DOOR[0], FLOOR - BOT, 0.02), xf, ["+z"])
	# token door on the right pillar: steel frame box, printed face, two lit token slots
	bx(b, g, "pc_ride_frame", Vector3(0.68, 0.93, z0 - 0.012), Vector3(0.22, 0.38, 0.024), xf, ["+z"])
	q(b, g, "pc_ride_decals", xf, [Vector3(0.57, 0.74, z0 - 0.0245), Vector3(0.79, 0.74, z0 - 0.0245), Vector3(0.79, 1.12, z0 - 0.0245), Vector3(0.57, 1.12, z0 - 0.0245)], Vector3.FORWARD,
		atlas(256, 96, 448, 448))
	for cx in [58.0, 134.0]:
		var xa = 0.57 + (cx - 20.0) / 192.0 * 0.22
		var xb = 0.57 + (cx + 20.0) / 192.0 * 0.22
		var yb = 1.12 - (104.0 - 30.0) / 352.0 * 0.38
		var yt = 1.12 - (104.0 - 52.0) / 352.0 * 0.38
		q(b, g, "pc_ride_lamp", xf, [Vector3(xa, yb, z0 - 0.026), Vector3(xb, yb, z0 - 0.026), Vector3(xb, yt, z0 - 0.026), Vector3(xa, yt, z0 - 0.026)], Vector3.FORWARD,
			[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)], true)
	# safety placard on the left pillar, "2 PLAYERS" over the door
	q(b, g, "pc_ride_decals", xf, [Vector3(-0.785, 0.90, z0 - 0.004), Vector3(-0.555, 0.90, z0 - 0.004), Vector3(-0.555, 1.245, z0 - 0.004), Vector3(-0.785, 1.245, z0 - 0.004)], Vector3.FORWARD,
		atlas(0, 0, 256, 384))
	q(b, g, "pc_ride_decals", xf, [Vector3(-0.20, 1.915, z0 - 0.004), Vector3(0.20, 1.915, z0 - 0.004), Vector3(0.20, 2.05, z0 - 0.004), Vector3(-0.20, 2.05, z0 - 0.004)], Vector3.FORWARD,
		atlas(256, 0, 512, 86))
	# chrome grab handles either side of the door
	for sx in [-1.0, 1.0]:
		bx(b, g, "pc_ride_chrome", Vector3(sx * 0.615, 1.58, z0 - 0.05), Vector3(0.026, 0.46, 0.026), xf, [], true)
		for yy in [1.38, 1.78]:
			bx(b, g, "pc_ride_chrome", Vector3(sx * 0.615, yy, z0 - 0.025), Vector3(0.022, 0.022, 0.05), xf, [], true)
	# the curtain: two black halves pulled aside, pleated, hanging just inside the door
	for sx in [-1.0, 1.0]:
		var nseg = 12
		var top = []
		var bot = []
		var nt = []
		var ut = []
		var ub = []
		for i in nseg + 1:
			var t = float(i) / nseg
			var dz = (0.022 if i % 2 == 1 else -0.012)
			top.append(Vector3(sx * lerpf(0.53, 0.30, t), 1.86, 0.40 + dz))
			bot.append(Vector3(sx * lerpf(0.53, 0.22, t), FLOOR + 0.06, 0.40 + dz * 1.4))
			ut.append(Vector2(t, 0))
			ub.append(Vector2(t, 1))
		for i in nseg + 1:
			var a = top[max(i - 1, 0)]
			var c = top[min(i + 1, nseg)]
			var tng = (c - a)
			var nn = Vector3(tng.z, 0, -tng.x).normalized()
			if nn.z > 0.0:
				nn = -nn
			nt.append(nn)
		strip(b, g, "pc_ride_curtain", xf, top, bot, nt, nt, ut, ub)
	bx(b, g, "pc_ride_chrome", Vector3(0, 1.875, 0.40), Vector3(1.12, 0.018, 0.018), xf, [], true)

## Inside: shell lining, carpet, the bench, the gun console, the screen in its shroud.
static func _cabin(b, g, xf):
	var r = ring(IN_HW, IN_TOP, FLOOR, IN_RT)
	var P = r[0]
	var Nn = r[1]
	var s = arclen(P)
	var A = []
	var B = []
	var NA = []
	var UA = []
	var UB = []
	for k in P.size():
		A.append(Vector3(P[k].x, P[k].y, IN_Z0))
		B.append(Vector3(P[k].x, P[k].y, IN_Z1))
		NA.append(Vector3(-Nn[k].x, -Nn[k].y, 0))
		UA.append(Vector2(s[k] * 2.0, IN_Z0 * 2.0))
		UB.append(Vector2(s[k] * 2.0, IN_Z1 * 2.0))
	strip(b, g, "pc_ride_wall", xf, A, B, NA, NA, UA, UB)
	# carpet floor
	q(b, g, "pc_ride_carpet", xf, [Vector3(-IN_HW, FLOOR, IN_Z0), Vector3(IN_HW, FLOOR, IN_Z0), Vector3(IN_HW, FLOOR, IN_Z1), Vector3(-IN_HW, FLOOR, IN_Z1)], Vector3.UP,
		[Vector2(0, IN_Z0 * 2), Vector2(IN_HW * 4, IN_Z0 * 2), Vector2(IN_HW * 4, IN_Z1 * 2), Vector2(0, IN_Z1 * 2)])
	# front wall around the screen shroud
	fan(b, g, "pc_ride_dash", xf, P, IN_Z1, Vector3(0, 0, -1), Vector2(0, 1.2), -IN_HW, 1.0 / (2 * IN_HW), IN_TOP, 1.0 / (IN_TOP - FLOOR))
	# bench: steel pedestal, two vinyl cushions, reclined backs in a fibreglass shell, divider
	bx(b, g, "pc_ride_frame", Vector3(0, 0.57, 1.17), Vector3(1.26, 0.34, 0.40), xf, ["+y"])
	for sx in [-1.0, 1.0]:
		var cxf = xf * Transform3D(Basis.IDENTITY, Vector3(0, 0, 1.18))
		loaf(b, g, "pc_ride_vinyl", cxf, sx * 0.36 - 0.325, sx * 0.36 + 0.325, 0.48, 0.74, 0.875, 0.05)
		var bxf = xf * Transform3D(Basis(Vector3.RIGHT, -0.20), Vector3(0, 1.114, 0.844))
		loaf(b, g, "pc_ride_vinyl", bxf, sx * 0.36 - 0.31, sx * 0.36 + 0.31, 0.11, -0.26, 0.26, 0.05)
		loaf(b, g, "pc_ride_vinyl", bxf * Transform3D(Basis.IDENTITY, Vector3(0, 0, 0.035)), sx * 0.36 - 0.22, sx * 0.36 + 0.22, 0.08, 0.13, 0.27, 0.035)   # head pad
	var sxf = xf * Transform3D(Basis(Vector3.RIGHT, -0.20), Vector3(0, 1.10, 0.768))
	bx(b, g, "pc_ride_frame", Vector3.ZERO, Vector3(1.40, 0.60, 0.05), sxf, [], false)
	loaf(b, g, "pc_ride_vinyl", xf * Transform3D(Basis.IDENTITY, Vector3(0, 0, 1.16)), -0.04, 0.04, 0.40, 0.86, 1.00, 0.04)
	# chrome grab bar across the back of the bench (riders hold it climbing in)
	bx(b, g, "pc_ride_chrome", Vector3(0, 0.35, -0.05), Vector3(1.22, 0.028, 0.028), sxf, [], true)
	for sx in [-1.0, 1.0]:
		bx(b, g, "pc_ride_chrome", Vector3(sx * 0.60, 0.315, -0.035), Vector3(0.024, 0.07, 0.024), sxf, [], true)
	# gun console: body, slanted printed panel, kick plate
	bx(b, g, "pc_ride_frame", Vector3(0, 0.685, 2.16), Vector3(2 * IN_HW, 0.57, 0.48), xf, ["+y", "+z", "+x", "-x"])
	q(b, g, "pc_ride_console", xf, [Vector3(-0.76, 0.975, 1.90), Vector3(0.76, 0.975, 1.90), Vector3(0.76, 1.035, 2.20), Vector3(-0.76, 1.035, 2.20)], Vector3(0, 0.98, -0.196),
		[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])
	q(b, g, "pc_ride_frame", xf, [Vector3(-0.76, 0.955, 1.90), Vector3(0.76, 0.955, 1.90), Vector3(0.76, 0.975, 1.90), Vector3(-0.76, 0.975, 1.90)], Vector3.FORWARD)
	q(b, g, "pc_ride_frame", xf, [Vector3(-0.76, 1.035, 2.20), Vector3(0.76, 1.035, 2.20), Vector3(0.76, 1.02, 2.26), Vector3(-0.76, 1.02, 2.26)], Vector3(0, 1, 0.25))
	q(b, g, "pc_ride_tread", xf, [Vector3(-0.76, FLOOR, 1.917), Vector3(0.76, FLOOR, 1.917), Vector3(0.76, FLOOR + 0.12, 1.917), Vector3(-0.76, FLOOR + 0.12, 1.917)], Vector3.FORWARD,
		[Vector2(0, 0.48), Vector2(6, 0.48), Vector2(6, 0), Vector2(0, 0)])
	# START buttons (lit) in black bezels
	for sx in [-1.0, 1.0]:
		var by = 0.975 + (2.02 - 1.90) / 0.30 * 0.06
		b.cur_color = Color("#101010")
		b.cyl(g, "vcolor", xf * Vector3(sx * 0.60, by - 0.004, 2.02), 0.027, 0.026, 0.012, 16, true, false, true)
		b.cur_color = Color.WHITE
		b.cyl(g, "pc_ride_start" + ("1" if sx < 0 else "2"), xf * Vector3(sx * 0.60, by, 2.02), 0.019, 0.018, 0.022, 16, true, false, true)
	# screen shroud: outer box faces, front ring, tunnel, the screen
	var ox = 0.60
	var oy0 = 1.02
	var oy1 = 1.98
	var zf = 2.26
	var hx = 0.535
	var hy0 = 1.075
	var hy1 = 1.915
	var sx2 = 0.50
	var sy0 = 1.10
	var sy1 = 1.85
	var zs = 2.385
	qp(b, g, "pc_ride_frame", xf, [Vector3(-ox, oy1, zf), Vector3(ox, oy1, zf), Vector3(ox, oy1, IN_Z1), Vector3(-ox, oy1, IN_Z1)], Vector3.UP)
	qp(b, g, "pc_ride_frame", xf, [Vector3(ox, oy0, zf), Vector3(ox, oy0, IN_Z1), Vector3(ox, oy1, IN_Z1), Vector3(ox, oy1, zf)], Vector3.RIGHT)
	qp(b, g, "pc_ride_frame", xf, [Vector3(-ox, oy0, IN_Z1), Vector3(-ox, oy0, zf), Vector3(-ox, oy1, zf), Vector3(-ox, oy1, IN_Z1)], Vector3.LEFT)
	var nfz = Vector3(0, 0, -1)
	qp(b, g, "pc_ride_frame", xf, [Vector3(-ox, hy1, zf), Vector3(ox, hy1, zf), Vector3(ox, oy1, zf), Vector3(-ox, oy1, zf)], nfz)
	qp(b, g, "pc_ride_frame", xf, [Vector3(-ox, oy0, zf), Vector3(ox, oy0, zf), Vector3(ox, hy0, zf), Vector3(-ox, hy0, zf)], nfz)
	qp(b, g, "pc_ride_frame", xf, [Vector3(-ox, hy0, zf), Vector3(-hx, hy0, zf), Vector3(-hx, hy1, zf), Vector3(-ox, hy1, zf)], nfz)
	qp(b, g, "pc_ride_frame", xf, [Vector3(hx, hy0, zf), Vector3(ox, hy0, zf), Vector3(ox, hy1, zf), Vector3(hx, hy1, zf)], nfz)
	qp(b, g, "pc_ride_bezel", xf, [Vector3(-hx, hy1, zf), Vector3(hx, hy1, zf), Vector3(sx2, sy1, zs), Vector3(-sx2, sy1, zs)], Vector3(0, -1, 0.2))
	qp(b, g, "pc_ride_bezel", xf, [Vector3(-sx2, sy0, zs), Vector3(sx2, sy0, zs), Vector3(hx, hy0, zf), Vector3(-hx, hy0, zf)], Vector3(0, 1, 0.2))
	qp(b, g, "pc_ride_bezel", xf, [Vector3(-hx, hy0, zf), Vector3(-sx2, sy0, zs), Vector3(-sx2, sy1, zs), Vector3(-hx, hy1, zf)], Vector3(1, 0, 0.2))
	qp(b, g, "pc_ride_bezel", xf, [Vector3(sx2, sy0, zs), Vector3(hx, hy0, zf), Vector3(hx, hy1, zf), Vector3(sx2, sy1, zs)], Vector3(-1, 0, 0.2))
	q(b, g, "pc_ride_screen", xf, [Vector3(-sx2, sy0, zs), Vector3(sx2, sy0, zs), Vector3(sx2, sy1, zs), Vector3(-sx2, sy1, zs)], nfz,
		[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])

## Backlit marquee lightbox on the roof over the entry; lit both ways.
static func _marquee(b, g, xf):
	var x0 = 0.60
	var y0 = 2.10
	var y1 = 2.40
	var za = 0.32
	var zb = 0.50
	bx(b, g, "pc_ride_frame", Vector3(0, 2.25, 0.41), Vector3(1.24, 0.34, 0.18), xf, ["-z", "+z"])
	bx(b, g, "pc_ride_frame", Vector3(0, 2.07, 0.41), Vector3(1.10, 0.06, 0.14), xf, ["+y"])
	q(b, g, "pc_ride_marquee", xf, [Vector3(-x0, y0, za), Vector3(x0, y0, za), Vector3(x0, y1, za), Vector3(-x0, y1, za)], Vector3.FORWARD,
		[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])
	q(b, g, "pc_ride_marquee", xf, [Vector3(x0, y0, zb), Vector3(-x0, y0, zb), Vector3(-x0, y1, zb), Vector3(x0, y1, zb)], Vector3.BACK,
		[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])
	# chrome bezels on both faces
	for z in [za - 0.004, zb + 0.004]:
		var n = Vector3.FORWARD if z < 0.41 else Vector3.BACK
		for rr in [[-0.62, 0.62, y1, y1 + 0.02], [-0.62, 0.62, y0 - 0.02, y0], [-0.62, -x0, y0, y1], [x0, 0.62, y0, y1]]:
			q(b, g, "pc_ride_chrome", xf, [Vector3(rr[0], rr[2], z), Vector3(rr[1], rr[2], z), Vector3(rr[1], rr[3], z), Vector3(rr[0], rr[3], z)], n,
				[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])

## The two mounted light guns on swivel posts (small parts: dynamic, vertex colours).
static func _guns(b, g, xf):
	var body = Color("#26272c")
	for sx in [-1.0, 1.0]:
		var px = sx * 0.34
		var accent = Color("#d8541e") if sx < 0 else Color("#2f9a46")
		var py = 0.975 + (2.02 - 1.90) / 0.30 * 0.06
		# swivel post and yoke
		b.cur_color = Color("#3a3b40")
		b.cyl(g, "vcolor", xf * Vector3(px, py - 0.005, 2.02), 0.045, 0.040, 0.015, 16, true, false, true)
		b.cyl(g, "vcolor", xf * Vector3(px, py, 2.02), 0.022, 0.022, 0.085, 12, true, false, true)
		bx(b, g, "vcolor", Vector3(px, py + 0.095, 2.02), Vector3(0.11, 0.025, 0.07), xf, [], true)
		for s2 in [-1.0, 1.0]:
			bx(b, g, "vcolor", Vector3(px + s2 * 0.048, py + 0.125, 2.02), Vector3(0.012, 0.06, 0.05), xf, [], true)
		var gx = xf * Transform3D(Basis(Vector3.RIGHT, -0.12), Vector3(px, py + 0.150, 1.99))
		b.cur_color = body
		bx(b, g, "vcolor", Vector3(0, 0.0, -0.06), Vector3(0.074, 0.092, 0.24), gx, [], true)     # receiver
		zcyl(b, g, "vcolor", gx, 0.033, 0.06, 0.20)                                               # barrel shroud
		b.cur_color = Color("#0e0e10")
		zcyl(b, g, "vcolor", gx, 0.019, 0.20, 0.245)                                              # muzzle
		bx(b, g, "vcolor", Vector3(0, 0.055, -0.15), Vector3(0.022, 0.026, 0.03), gx, [], true)   # rear sight
		bx(b, g, "vcolor", Vector3(0, 0.045, 0.18), Vector3(0.008, 0.03, 0.02), gx, [], true)     # front sight
		bx(b, g, "vcolor", Vector3(0, -0.066, -0.09), Vector3(0.012, 0.035, 0.06), gx, [], true)  # trigger guard
		b.cur_color = body
		var gp = gx * Transform3D(Basis(Vector3.RIGHT, 0.32), Vector3(0, -0.10, -0.15))
		bx(b, g, "vcolor", Vector3.ZERO, Vector3(0.046, 0.13, 0.056), gp, [], true)              # pistol grip
		bx(b, g, "vcolor", Vector3(0, -0.08, 0.075), Vector3(0.04, 0.10, 0.045), gx, [], true)   # front grip
		b.cur_color = Color("#c02018")
		bx(b, g, "vcolor", Vector3(0, -0.055, -0.08), Vector3(0.008, 0.02, 0.012), gx, [], true)  # trigger
		b.cur_color = accent
		for s2 in [-1.0, 1.0]:
			bx(b, g, "vcolor", Vector3(s2 * 0.0385, 0.012, -0.06), Vector3(0.004, 0.022, 0.20), gx, [], true)
		zcyl(b, g, "vcolor", gx, 0.0345, 0.17, 0.19)                                              # coloured band
	b.cur_color = Color.WHITE

## The screen end outside: vent louvres and stickers on the front cap.
static func _front(b, g, xf):
	var z = ST[-1][0] + 0.003
	var n = Vector3.BACK
	q(b, g, "pc_ride_decals", xf, [Vector3(0.24, 0.55, z), Vector3(-0.24, 0.55, z), Vector3(-0.24, 0.67, z), Vector3(0.24, 0.67, z)], n, atlas(256, 452, 512, 512))
	q(b, g, "pc_ride_decals", xf, [Vector3(-0.12, 1.12, z), Vector3(-0.28, 1.12, z), Vector3(-0.28, 1.19, z), Vector3(-0.12, 1.19, z)], n, atlas(0, 392, 256, 504))
	# title across the top of the screen end, so the far side of the arcade sees it too
	q(b, g, "pc_ride_title", xf, [Vector3(0.48, 1.36, z), Vector3(-0.48, 1.36, z), Vector3(-0.48, 1.60, z), Vector3(0.48, 1.60, z)], n,
		[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])
	# service door: a recessed seam (dark strips) round a panel, a key lock
	var sx0 = 0.36
	var sy0 = 0.42
	var sy1 = 1.24
	var t = 0.008
	for rr in [[-sx0, sx0, sy1, sy1 + t], [-sx0, sx0, sy0 - t, sy0], [-sx0 - t, -sx0, sy0 - t, sy1 + t], [sx0, sx0 + t, sy0 - t, sy1 + t]]:
		q(b, g, "pc_ride_bezel", xf, [Vector3(rr[1], rr[2], z), Vector3(rr[0], rr[2], z), Vector3(rr[0], rr[3], z), Vector3(rr[1], rr[3], z)], n,
			[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])
	bx(b, g, "pc_ride_chrome", Vector3(-0.30, 0.95, z + 0.006), Vector3(0.026, 0.026, 0.012), xf, [], true)

## Material "pc_ride_<key>": fill m and return true, or return false for an unknown key.
static func fill_mat(m, key, b):
	match key:
		"paint":
			m.albedo_texture = b.tex("pc/ride_paint.png"); m.roughness = 0.24; m.metallic_specular = 0.65
		"side":
			m.albedo_texture = b.tex("pc/ride_side.png"); m.roughness = 0.30; m.metallic_specular = 0.6
		"title":
			m.albedo_texture = b.tex("pc/ride_title.png"); m.roughness = 0.35
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR; m.alpha_scissor_threshold = 0.5
		"marquee":
			m.albedo_texture = b.tex("pc/ride_marquee.png"); m.roughness = 0.2
			# MULTIPLY: emission = texture x energy (the default ADD would add white to it)
			m.emission_enabled = true; m.emission_texture = m.albedo_texture; m.emission = Color.WHITE
			m.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY
			m.emission_energy_multiplier = 1.3
			m.set_meta("e_day", 1.3); m.set_meta("e_night", 1.3)
		"screen":
			m.albedo_color = Color("#050607"); m.roughness = 0.08; m.metallic_specular = 0.7
			m.emission_enabled = true; m.emission_texture = b.tex("pc/ride_screen.png"); m.emission = Color.WHITE
			m.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY
			m.emission_energy_multiplier = 1.5
			m.set_meta("e_day", 1.5); m.set_meta("e_night", 1.5)
		"start1", "start2":
			var c = Color("#ff5a1e") if key == "start1" else Color("#3ade5a")
			m.albedo_color = c; m.roughness = 0.25
			m.emission_enabled = true; m.emission = c; m.emission_energy_multiplier = 3.0
			m.set_meta("e_day", 3.0); m.set_meta("e_night", 3.0)
		"lamp":
			m.albedo_color = Color("#ff8a2a")
			m.emission_enabled = true; m.emission = Color("#ff8a2a"); m.emission_energy_multiplier = 2.5
			m.set_meta("e_day", 2.5); m.set_meta("e_night", 2.5)
		"frame":
			m.albedo_color = Color("#161618"); m.roughness = 0.55
		"bezel":
			m.albedo_color = Color("#0b0b0c"); m.roughness = 0.85
		"rubber":
			m.albedo_color = Color("#141414"); m.roughness = 0.82
		"skirt":
			m.albedo_texture = b.tex("pc/ride_skirt.png"); m.roughness = 0.8
		"steel":
			m.albedo_color = Color("#2a2b2e"); m.metallic = 0.6; m.roughness = 0.5
		"carpet":
			m.albedo_texture = b.tex("pc/ride_carpet.png"); m.roughness = 1.0
		"wall":
			m.albedo_texture = b.tex("pc/ride_felt.png"); m.roughness = 1.0
		"vinyl":
			m.albedo_texture = b.tex("pc/ride_vinyl.png"); m.roughness = 0.42; m.metallic_specular = 0.55
		"chrome":
			m.albedo_color = Color("#d4d6da"); m.metallic = 0.9; m.roughness = 0.18
		"tread":
			m.albedo_texture = b.tex("pc/ride_tread.png"); m.metallic = 0.7; m.roughness = 0.38
		"rear":
			m.albedo_texture = b.tex("pc/ride_rear.png"); m.roughness = 0.26; m.metallic_specular = 0.65
		"trim":
			# polished aluminium trim: reads bright even without a reflection probe
			m.albedo_color = Color("#c9ccd2"); m.metallic = 0.55; m.roughness = 0.28
		"redrub":
			m.albedo_color = Color("#9a1c1a"); m.roughness = 0.7
		"dash":
			m.albedo_texture = b.tex("pc/ride_dash.png"); m.roughness = 0.7
		"console":
			m.albedo_texture = b.tex("pc/ride_console.png"); m.roughness = 0.45
		"decals":
			m.albedo_texture = b.tex("pc/ride_decals.png"); m.roughness = 0.45
		"curtain":
			m.albedo_color = Color("#141218"); m.roughness = 0.95
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
		_:
			return false
	return true
