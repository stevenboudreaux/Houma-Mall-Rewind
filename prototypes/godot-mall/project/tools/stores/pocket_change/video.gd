## Pocket Change (1995): upright video arcade cabinets, eight US form factors.
## Contract: tools/stores/pocket_change/README.md. Textures: paint_video.py -> tex/pc/video_*.png.
##   tools/qa/preview.sh video /home/claude/houma-mall-rewind/.scratch/preview/video/s0 "0,1.5,2.2,0,-12" '{"style":0}'
##
## opts.style:
##   0  2-player fighting upright (black, 6 buttons a player)        THUNDER DOJO
##   1  4-player wide brawler kit (2 coin doors)                     IRON ALLEY
##   2  light-gun cabinet, two holstered guns on armoured cables     BULLSEYE PATROL
##   3  side-scrolling space shooter (landscape 25" CRT)             ORBIT RAIDER
##   4  black conversion kit, 25" monitor, side decal                FOURTH & GOAL
##   5  trackball bowling, black cabinet                             LUCKY LANES
##   6  tall dedicated racer: flared marquee, wheel, shifter, pedal  RED LINE RUSH
##   7  early-80s wood-grain cabinet kept on the floor (spinner)     PADDLE PANIC
## All titles and art are invented. Every number below is metres in the machine frame:
## z = 0 is the front of the control panel, z grows into the machine, y is up.
##
## Profile keys: W, D, H outer size; kz lower-front setback; kh kick-plate height; lo where
## the lower front meets the panel underside; cp = [panel front bottom y, panel top front y,
## panel depth z, panel top back y]; the bezel runs from (cp[2], cp[3]) to bz = [z, y];
## the speaker board from bz to mq[0..1]; the marquee from (mq[0], mq[1]) to (mq[2], mq[3]);
## then a cap to top = [z, y] and the roof back to (D, H). scr = [visible width, height,
## offset of the picture's bottom edge along the bezel]. flare > 0: a wider marquee
## housing (style 6). ctl: [kind, x, s along the panel top from its front edge, colour].
## paint_video.py reads this block as JSON: keep it JSON (double quotes, no trailing commas).
# --- STYLES ---
const STYLES = [
{"title": "THUNDER DOJO", "W": 0.66, "D": 0.86, "H": 1.88, "kz": 0.13, "kh": 0.10, "lo": 0.80,
 "cp": [0.86, 0.95, 0.30, 0.99], "bz": [0.43, 1.52], "mq": [0.31, 1.585, 0.29, 1.83], "top": [0.30, 1.88],
 "scr": [0.48, 0.36, 0.10], "vert": false, "flare": 0, "body": "#1a1a1d", "tm": "#202022", "cpc": "#141416",
 "doors": [0.0],
 "ctl": [["stick", -0.255, 0.135, "#c41a1a"],
  ["btn", -0.185, 0.170, "#c4161c"], ["btn", -0.140, 0.180, "#c4161c"], ["btn", -0.095, 0.175, "#c4161c"],
  ["btn", -0.190, 0.120, "#e8e4d8"], ["btn", -0.145, 0.130, "#e8e4d8"], ["btn", -0.100, 0.125, "#e8e4d8"],
  ["stick", 0.075, 0.135, "#1c46b0"],
  ["btn", 0.145, 0.170, "#1f4fb4"], ["btn", 0.190, 0.180, "#1f4fb4"], ["btn", 0.235, 0.175, "#1f4fb4"],
  ["btn", 0.140, 0.120, "#e8e4d8"], ["btn", 0.185, 0.130, "#e8e4d8"], ["btn", 0.230, 0.125, "#e8e4d8"],
  ["start", -0.030, 0.255, "w"], ["start", 0.030, 0.255, "w"]]},
{"title": "IRON ALLEY", "W": 1.06, "D": 0.92, "H": 1.90, "kz": 0.16, "kh": 0.11, "lo": 0.79,
 "cp": [0.85, 0.95, 0.36, 1.00], "bz": [0.48, 1.53], "mq": [0.36, 1.60, 0.34, 1.85], "top": [0.35, 1.90],
 "scr": [0.52, 0.39, 0.08], "vert": false, "flare": 0, "body": "#1a1a1d", "tm": "#d8b020", "cpc": "#18181a",
 "doors": [-0.22, 0.22],
 "ctl": [["stick", -0.455, 0.150, "#c8201c"], ["btn", -0.390, 0.165, "#c8201c"], ["btn", -0.350, 0.172, "#c8201c"], ["btn", -0.310, 0.165, "#c8201c"],
  ["stick", -0.195, 0.150, "#1f4fc0"], ["btn", -0.130, 0.165, "#1f4fc0"], ["btn", -0.090, 0.172, "#1f4fc0"], ["btn", -0.050, 0.165, "#1f4fc0"],
  ["stick", 0.065, 0.150, "#e0b818"], ["btn", 0.130, 0.165, "#e0b818"], ["btn", 0.170, 0.172, "#e0b818"], ["btn", 0.210, 0.165, "#e0b818"],
  ["stick", 0.325, 0.150, "#2a9a3a"], ["btn", 0.390, 0.165, "#2a9a3a"], ["btn", 0.430, 0.172, "#2a9a3a"], ["btn", 0.470, 0.165, "#2a9a3a"],
  ["start", -0.350, 0.285, "r"], ["start", -0.090, 0.285, "b"], ["start", 0.170, 0.285, "y"], ["start", 0.430, 0.285, "g"]]},
{"title": "BULLSEYE PATROL", "W": 0.76, "D": 0.94, "H": 1.92, "kz": 0.14, "kh": 0.10, "lo": 0.80,
 "cp": [0.86, 0.93, 0.30, 0.97], "bz": [0.44, 1.56], "mq": [0.30, 1.64, 0.27, 1.88], "top": [0.30, 1.92],
 "scr": [0.53, 0.40, 0.10], "vert": false, "flare": 0, "body": "#18181a", "tm": "#d8d8dc", "cpc": "#141418",
 "doors": [0.0],
 "ctl": [["gun", -0.275, 0.150, "#d0401c"], ["gun", 0.275, 0.150, "#2a5ad0"],
  ["start", -0.075, 0.140, "r"], ["start", 0.075, 0.140, "b"]]},
{"title": "ORBIT RAIDER", "W": 0.64, "D": 0.82, "H": 1.80, "kz": 0.12, "kh": 0.10, "lo": 0.79,
 "cp": [0.85, 0.94, 0.27, 0.98], "bz": [0.38, 1.52], "mq": [0.27, 1.57, 0.25, 1.76], "top": [0.27, 1.80],
 "scr": [0.48, 0.36, 0.09], "vert": false, "flare": 0, "body": "#18181a", "tm": "#7a3cc0", "cpc": "#141018",
 "doors": [0.0],
 "ctl": [["stick", -0.205, 0.130, "#111114"], ["btn", -0.130, 0.140, "#e8c018"], ["btn", -0.085, 0.150, "#2ea040"],
  ["stick", 0.075, 0.130, "#111114"], ["btn", 0.150, 0.140, "#e8c018"], ["btn", 0.195, 0.150, "#2ea040"],
  ["start", -0.020, 0.235, "w"], ["start", 0.025, 0.235, "w"]]},
{"title": "FOURTH & GOAL", "W": 0.66, "D": 0.84, "H": 1.86, "kz": 0.12, "kh": 0.12, "lo": 0.80,
 "cp": [0.86, 0.94, 0.29, 0.97], "bz": [0.36, 1.50], "mq": [0.22, 1.55, 0.22, 1.80], "top": [0.22, 1.86],
 "scr": [0.48, 0.36, 0.09], "vert": false, "flare": 0, "body": "#18181a", "tm": "#1c1c1e", "cpc": "#141416",
 "doors": [0.0],
 "ctl": [["stick", -0.225, 0.130, "#c4161c"], ["btn", -0.150, 0.140, "#1f4fb4"], ["btn", -0.108, 0.148, "#c4161c"], ["btn", -0.066, 0.140, "#e8c018"],
  ["stick", 0.085, 0.130, "#c4161c"], ["btn", 0.160, 0.140, "#1f4fb4"], ["btn", 0.202, 0.148, "#c4161c"], ["btn", 0.244, 0.140, "#e8c018"],
  ["start", -0.025, 0.245, "w"], ["start", 0.025, 0.245, "w"]]},
{"title": "LUCKY LANES", "W": 0.66, "D": 0.82, "H": 1.80, "kz": 0.12, "kh": 0.10, "lo": 0.78,
 "cp": [0.84, 0.93, 0.28, 0.97], "bz": [0.39, 1.50], "mq": [0.29, 1.55, 0.27, 1.76], "top": [0.29, 1.80],
 "scr": [0.48, 0.36, 0.10], "vert": false, "flare": 0, "body": "#18181a", "tm": "#c41e24", "cpc": "#1a1a1c",
 "doors": [0.0],
 "ctl": [["ball", 0.0, 0.150, "#c81e2a"],
  ["start", -0.175, 0.150, "y"], ["start", 0.175, 0.150, "y"]]},
{"title": "RED LINE RUSH", "W": 0.72, "D": 0.94, "H": 1.96, "kz": 0.18, "kh": 0.10, "lo": 0.78,
 "cp": [0.84, 0.95, 0.34, 1.00], "bz": [0.45, 1.52], "mq": [0.33, 1.58, 0.30, 1.96], "top": [0.30, 1.96],
 "scr": [0.48, 0.36, 0.09], "vert": false, "flare": 0.90, "body": "#a8141a", "tm": "#151517", "cpc": "#141416",
 "doors": [-0.10],
 "ctl": [["wheel", 0.0, 0.12, "#141414"], ["shift", 0.255, 0.150, "#141414"], ["pedal", 0.17, 0.0, "#2a2a2c"],
  ["start", -0.255, 0.215, "y"], ["btn", -0.255, 0.120, "#c4161c"]]},
{"title": "PADDLE PANIC", "W": 0.64, "D": 0.80, "H": 1.80, "kz": 0.10, "kh": 0.12, "lo": 0.82,
 "cp": [0.86, 0.93, 0.24, 0.96], "bz": [0.44, 1.42], "mq": [0.30, 1.52, 0.36, 1.74], "top": [0.40, 1.80],
 "scr": [0.40, 0.30, 0.10], "vert": false, "flare": 0, "body": "#121214", "tm": "#18181a", "cpc": "#2a2018",
 "doors": [0.0],
 "ctl": [["spin", 0.0, 0.105, "#18181a"], ["btn", -0.150, 0.105, "#d8d4c8"], ["btn", 0.150, 0.105, "#d8d4c8"],
  ["start", -0.070, 0.185, "w"], ["start", 0.070, 0.185, "w"]]}
]
# --- end STYLES ---

const T = 0.019          # side panel thickness (3/4" plywood / particle board)
const SIDE_COLS = 4      # video_sides.png: 4 x 2 cells of 256 x 512
const PANEL_COLS = 2     # video_panels.png: 2 x 4 cells of 512 x 256 (top 192 + front 64)
const BEZEL_COLS = 4     # video_bezels.png: 4 x 2 cells of 256 x 256
const MQ_COLS = 2        # video_marquees.png: 2 x 6 cells of 512 x 170
const SCR_COLS = 3       # video_screens.png (1024 x 768): 3 x 3 cells of 341 x 256

static func _st(opts):
	var i = 0
	if opts != null and opts.has("style"):
		i = int(opts["style"])
	return clampi(i, 0, STYLES.size() - 1)

## Footprint (width, depth) in metres: the widest part (flared marquee) by the full depth.
static func footprint(opts = {}):
	var s = STYLES[_st(opts)]
	return Vector2(max(s.W, s.flare), s.D)

static func X(o, f):
	return Transform3D(Basis(f.cross(Vector3.UP), Vector3.UP, f), o)

## The side profile as a chain from the lower front up over the roof and down the back.
## Each entry: [z, y, kind of the segment that starts here].
static func _chain(s):
	var c = []
	c.append([s.kz, 0.0, "kick"])
	c.append([s.kz, s.kh, "lower"])
	c.append([s.kz, s.lo, "hid"])
	c.append([s.cp[2], s.cp[3], "bezel"])
	c.append([s.bz[0], s.bz[1], "speaker"])
	if s.flare > 0:
		c.append([s.mq[0], s.mq[1], "hid"])
		c.append([s.D, s.mq[1], "back"])
	else:
		c.append([s.mq[0], s.mq[1], "marquee"])
		c.append([s.mq[2], s.mq[3], "cap"])
		c.append([s.top[0], s.top[1], "top"])
		c.append([s.D, s.H, "back"])
	c.append([s.D, 0.0, "end"])
	return c

## A frame on one chain segment: origin at A, V along A->B, N outward (toward the player
## or up); points are O + U x + V v - N w (w > 0 goes into the cabinet).
static func _frame(az, ay, bz_, by):
	var d = Vector2(bz_ - az, by - ay)
	var L = d.length()
	var e = d / L
	return {"O": Vector3(0, ay, az), "V": Vector3(0, e.y, e.x), "N": Vector3(0, e.x, -e.y), "L": L}

static func _fp(fr, u, v, w):
	return fr.O + Vector3(u, 0, 0) + fr.V * v - fr.N * w

## A quad in the machine frame: local points, local outward normal.
static func _q(b, g, m, xf, p, n, uv, dyn = false):
	b.quad(g, m, [xf * p[0], xf * p[1], xf * p[2], xf * p[3]], (xf.basis * n).normalized(), uv, dyn)

## A box in a local frame (Transform3D in machine coordinates), centre c and size sz.
static func _bx(b, g, m, xf, fr_xf, c, sz, dyn = true, skip = []):
	b.box(g, m, c, sz, xf * fr_xf, skip, dyn)

## A thin bar from a to b (machine coordinates), square section th.
static func _bar(b, g, m, xf, a, bp, th, dyn = true):
	var d = bp - a
	var L = d.length()
	if L < 0.0005:
		return
	var y = d / L
	var ref = Vector3.UP if abs(y.y) < 0.9 else Vector3.RIGHT
	var x = y.cross(ref).normalized()
	var z = x.cross(y)
	b.box(g, m, Vector3.ZERO, Vector3(th, L, th), xf * Transform3D(Basis(x, y, z), (a + bp) * 0.5), [], dyn)

static func _uv_cell(cols, rows, col, row, fu, fv, pad = 0.004):
	fu = clamp(fu, 0.0, 1.0) * (1.0 - 2.0 * pad) + pad
	fv = clamp(fv, 0.0, 1.0) * (1.0 - 2.0 * pad) + pad
	return Vector2((col + fu) / cols, (row + fv) / rows)

## Builds one cabinet. Player at `o` facing `f`; the machine fills x in [-W/2, W/2] (or the
## flare), z in [0, D].
static func build(b, g, o, f, opts = {}):
	var si = _st(opts)
	var s = STYLES[si]
	var xf = X(o, f)
	var ch = _chain(s)
	var Wi = s.W - 2.0 * T
	var lam = "pc_video_lam_%d" % si
	var sf = {}   # title-bearing faces for the owner-editable sign: name -> [points, uvs, normal] (machine frame)
	_sides(b, g, xf, s, si, ch)
	# ---- front chain faces between the side panels
	for i in ch.size() - 1:
		var A = ch[i]
		var B = ch[i + 1]
		var kind = A[2]
		var fr = _frame(A[0], A[1], B[0], B[1])
		var p = [_fp(fr, -Wi * 0.5, 0, 0), _fp(fr, Wi * 0.5, 0, 0), _fp(fr, Wi * 0.5, fr.L, 0), _fp(fr, -Wi * 0.5, fr.L, 0)]
		var uv01 = [Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)]
		match kind:
			"kick":
				_q(b, g, "pc_video_kick", xf, p, fr.N, uv01)
			"lower":
				# lower-front art panel (video_fronts.png, 4 x 2 cells of 256 x 256)
				var fc = si % 4
				var frw = si / 4
				var fuv = [_uv_cell(4, 2, fc, frw, 0, 1), _uv_cell(4, 2, fc, frw, 1, 1), _uv_cell(4, 2, fc, frw, 1, 0), _uv_cell(4, 2, fc, frw, 0, 0)]
				_q(b, g, "pc_video_front", xf, p, fr.N, fuv)
				sf["fronts"] = [p, fuv, fr.N]
			"hid":
				_q(b, g, "pc_video_cpside", xf, p, fr.N, [])
			"bezel":
				sf["bezels"] = _bezel(b, g, xf, s, si, fr, Wi)
			"speaker":
				var w = 0.004
				var ps = [_fp(fr, -Wi * 0.5, 0, w), _fp(fr, Wi * 0.5, 0, w), _fp(fr, Wi * 0.5, fr.L, w), _fp(fr, -Wi * 0.5, fr.L, w)]
				_q(b, g, "pc_video_speaker", xf, ps, fr.N, uv01)
			"marquee":
				sf["marquee"] = _marquee(b, g, xf, si, fr, Wi)
			"cap", "top", "back":
				_q(b, g, lam, xf, p, fr.N, [])
	if s.flare > 0:
		sf["marquee"] = _housing(b, g, xf, s, si)
	sf["panels"] = _panel(b, g, xf, s, si)
	_sign(b, si, xf, sf)
	_doors(b, g, xf, s)
	_controls(b, g, xf, s)
	# obstacle: the footprint
	var fw = max(s.W, s.flare) * 0.5
	var c0 = xf * Vector3(-fw, 0, 0)
	var c1 = xf * Vector3(fw, 0, s.D)
	b.obst(["rect", min(c0.x, c1.x), min(c0.z, c1.z), max(c0.x, c1.x), max(c0.z, c1.z)])

## Side panels (outer art face, inner face) and the T-molding along the profile.
static func _sides(b, g, xf, s, si, ch):
	var outline = PackedVector2Array()
	for c in ch:
		outline.append(Vector2(c[0], c[1]))
	var idx = Geometry2D.triangulate_polygon(outline)
	var col = si % SIDE_COLS
	var row = si / SIDE_COLS
	var lam = "pc_video_lam_%d" % si
	for sg in [-1.0, 1.0]:
		var xo = sg * s.W * 0.5
		var xi = sg * (s.W * 0.5 - T)
		var so = b.st(g, "pc_video_side")
		var sn = b.st(g, lam)
		var no = (xf.basis * Vector3(sg, 0, 0)).normalized()
		for k in range(0, idx.size(), 3):
			var pts = []
			var pin = []
			var uvs = []
			for j in 3:
				var q = outline[idx[k + j]]
				pts.append(xf * Vector3(xo, q.y, q.x))
				pin.append(xf * Vector3(xi, q.y, q.x))
				uvs.append(_uv_cell(SIDE_COLS, 2, col, row, q.x / s.D, 1.0 - q.y / s.H))
			b.tri(so, pts[0], pts[1], pts[2], uvs[0], uvs[1], uvs[2], no)
			b.tri(sn, pin[0], pin[1], pin[2], Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, -no)
		# T-molding: a crowned strip on every profile edge but the floor
		var tm = "pc_video_tm_%d" % si
		for i in ch.size() - 1:
			var A = ch[i]
			var B = ch[i + 1]
			if A[2] == "hid" or A[2] == "end":
				continue
			var fr = _frame(A[0], A[1], B[0], B[1])
			var L = fr.L
			var x_out = sg * (s.W * 0.5 + 0.0015)
			var x_mid_o = sg * (s.W * 0.5 - 0.004)
			var x_mid_i = sg * (s.W * 0.5 - T + 0.004)
			var x_in = sg * (s.W * 0.5 - T - 0.0015)
			var wv = -0.0025   # proud of the profile line
			var ns = (fr.N + Vector3(sg, 0, 0) * 0.8).normalized()
			var ni = (fr.N - Vector3(sg, 0, 0) * 0.8).normalized()
			var e0 = 0.0
			var e1 = L
			var vv = L * 2.0
			# crown
			_q(b, g, tm, xf, [_fp(fr, x_mid_i, e0, wv), _fp(fr, x_mid_o, e0, wv), _fp(fr, x_mid_o, e1, wv), _fp(fr, x_mid_i, e1, wv)], fr.N,
				[Vector2(0.2, vv), Vector2(0.8, vv), Vector2(0.8, 0), Vector2(0.2, 0)])
			# shoulders
			_q(b, g, tm, xf, [_fp(fr, x_mid_o, e0, wv), _fp(fr, x_out, e0, 0.0005), _fp(fr, x_out, e1, 0.0005), _fp(fr, x_mid_o, e1, wv)], ns,
				[Vector2(0.8, vv), Vector2(1, vv), Vector2(1, 0), Vector2(0.8, 0)])
			_q(b, g, tm, xf, [_fp(fr, x_in, e0, 0.0005), _fp(fr, x_mid_i, e0, wv), _fp(fr, x_mid_i, e1, wv), _fp(fr, x_in, e1, 0.0005)], ni,
				[Vector2(0, vv), Vector2(0.2, vv), Vector2(0.2, 0), Vector2(0, 0)])

## The monitor bezel with the CRT behind it, the scanline layer and the front glass.
## Returns the bezel strip above the picture [points, uvs, normal].
static func _bezel(b, g, xf, s, si, fr, Wi):
	var sw = s.scr[0]
	var sh = s.scr[1]
	var sb = s.scr[2]
	var Lb = fr.L
	var wb = 0.008     # bezel sits 8 mm behind the side edge
	var col = si % BEZEL_COLS
	var row = si / BEZEL_COLS
	var x0 = -Wi * 0.5
	var x1 = Wi * 0.5
	var hx0 = -sw * 0.5
	var hx1 = sw * 0.5
	var hs0 = sb
	var hs1 = sb + sh
	var rects = [[x0, x1, 0.0, hs0], [x0, x1, hs1, Lb], [x0, hx0, hs0, hs1], [hx1, x1, hs0, hs1]]
	var top = []
	for r in rects:
		var pts = [_fp(fr, r[0], r[2], wb), _fp(fr, r[1], r[2], wb), _fp(fr, r[1], r[3], wb), _fp(fr, r[0], r[3], wb)]
		var uv = []
		for q in [[r[0], r[2]], [r[1], r[2]], [r[1], r[3]], [r[0], r[3]]]:
			uv.append(_uv_cell(BEZEL_COLS, 2, col, row, (q[0] - x0) / Wi, 1.0 - q[1] / Lb, 0.0))
		_q(b, g, "pc_video_bezel", xf, pts, fr.N, uv)
		if r[2] == hs1:
			top = [pts, uv, fr.N]   # the strip above the picture, where the title is printed
	# recess walls from the hole back to the tube
	var wr = wb + 0.032
	var corners = [[hx0, hs0], [hx1, hs0], [hx1, hs1], [hx0, hs1]]
	for i in 4:
		var a = corners[i]
		var c = corners[(i + 1) % 4]
		var pts = [_fp(fr, a[0], a[1], wb), _fp(fr, c[0], c[1], wb), _fp(fr, c[0], c[1], wr), _fp(fr, a[0], a[1], wr)]
		var mid = (Vector2(a[0], a[1]) + Vector2(c[0], c[1])) * 0.5
		var inward = Vector2(0.0 - mid.x, (hs0 + hs1) * 0.5 - mid.y).normalized()
		var n = Vector3(inward.x, 0, 0) + fr.V * inward.y
		_q(b, g, "pc_video_recess", xf, pts, n.normalized(), [])
	# the tube face: a bowed grid (centre 12 mm behind the bezel, edges 38 mm)
	var NU = 10
	var NV = 8
	var scol = si % SCR_COLS
	var srow = si / SCR_COLS
	var crt = b.st(g, "pc_video_crt")
	var scan = b.st(g, "pc_video_scan", true)
	var grid = []
	var gscan = []
	var nrm = []
	var uvs = []
	var suv = []
	var lines = 224.0 if not s.vert else 256.0
	for j in NV + 1:
		for i in NU + 1:
			var fu = float(i) / NU
			var fv = float(j) / NV
			var uu = fu * 2.0 - 1.0
			var vv = fv * 2.0 - 1.0
			var bow = (1.0 - uu * uu * 0.85) * (1.0 - vv * vv * 0.85)
			var w = wb + 0.036 - 0.026 * bow
			var x = hx0 + fu * sw
			var sv = hs0 + fv * sh
			grid.append(_fp(fr, x, sv, w))
			gscan.append(_fp(fr, x, sv, w - 0.0015))
			# slope of w for the normal
			var dwdx = 0.026 * (2.0 * uu * 0.85 / sw * 2.0) * (1.0 - vv * vv * 0.85) * 0.5
			var dwds = 0.026 * (2.0 * vv * 0.85 / sh * 2.0) * (1.0 - uu * uu * 0.85) * 0.5
			nrm.append((fr.N - Vector3(dwdx, 0, 0) - fr.V * dwds).normalized())
			# atlas cell: 341 x 256 px, picture 336 x 251 inside it
			var cu0 = (scol * 341.0 + 2.5) / 1024.0
			var cv0 = (srow * 256.0 + 2.5) / 768.0
			var cw = 336.0 / 1024.0
			var chh = 251.0 / 768.0
			if s.vert:
				# portrait picture stored rotated a quarter turn clockwise in a landscape cell
				uvs.append(Vector2(cu0 + fv * cw, cv0 + fu * chh))
				suv.append(Vector2(fv, fu * lines))
			else:
				uvs.append(Vector2(cu0 + fu * cw, cv0 + (1.0 - fv) * chh))
				suv.append(Vector2(fu, (1.0 - fv) * lines))
	var fn = (xf.basis * fr.N).normalized()
	for j in NV:
		for i in NU:
			var a = j * (NU + 1) + i
			var q = [a, a + 1, a + NU + 2, a + NU + 1]
			var P = []
			var Pn = []
			var U = []
			var Ps = []
			var Us = []
			for k in q:
				P.append(xf * grid[k])
				Ps.append(xf * gscan[k])
				Pn.append((xf.basis * nrm[k]).normalized())
				U.append(uvs[k])
				Us.append(suv[k])
			b._tri_n(crt, [P[0], P[1], P[2]], [Pn[0], Pn[1], Pn[2]], [U[0], U[1], U[2]], fn)
			b._tri_n(crt, [P[0], P[2], P[3]], [Pn[0], Pn[2], Pn[3]], [U[0], U[2], U[3]], fn)
			b._tri_n(scan, [Ps[0], Ps[1], Ps[2]], [Pn[0], Pn[1], Pn[2]], [Us[0], Us[1], Us[2]], fn)
			b._tri_n(scan, [Ps[0], Ps[2], Ps[3]], [Pn[0], Pn[2], Pn[3]], [Us[0], Us[2], Us[3]], fn)
	# front glass: flat, over the whole bezel, fingerprints and dust in its alpha
	var wg = wb - 0.004
	var gp = [_fp(fr, x0 + 0.002, 0.004, wg), _fp(fr, x1 - 0.002, 0.004, wg), _fp(fr, x1 - 0.002, Lb - 0.004, wg), _fp(fr, x0 + 0.002, Lb - 0.004, wg)]
	_q(b, g, "pc_video_glass", xf, gp, fr.N, [Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)], true)
	return top

## The backlit marquee between two black retainer strips. Returns [points, uvs, normal].
static func _marquee(b, g, xf, si, fr, Wi):
	var col = si % MQ_COLS
	var row = si / MQ_COLS
	var L = fr.L
	var w = 0.009
	var x0 = -Wi * 0.5
	var x1 = Wi * 0.5
	var pts = [_fp(fr, x0, 0, w), _fp(fr, x1, 0, w), _fp(fr, x1, L, w), _fp(fr, x0, L, w)]
	var uv = [_mq_uv(col, row, 0, 1), _mq_uv(col, row, 1, 1), _mq_uv(col, row, 1, 0), _mq_uv(col, row, 0, 0)]
	_q(b, g, "pc_video_marquee", xf, pts, fr.N, uv)
	var fxf = Transform3D(Basis(Vector3.RIGHT, fr.V, -fr.N), fr.O)
	_bx(b, g, "pc_video_metal", xf, fxf, Vector3(0, 0.011, 0.003), Vector3(Wi, 0.022, 0.014), false)
	_bx(b, g, "pc_video_metal", xf, fxf, Vector3(0, L - 0.011, 0.003), Vector3(Wi, 0.022, 0.014), false)
	return [pts, uv, fr.N]

## Where each style's title is printed on the lower front, the panel lip and the bezel, and
## in what look: written by paint_video.py paint_titles_blank().
static var _titles = null

static func _title_info():
	if _titles == null:
		_titles = {}
		var path = "res://tools/stores/pocket_change/video_titles.json"
		if FileAccess.file_exists(path):
			var j = JSON.parse_string(FileAccess.get_file_as_string(path))
			if j is Dictionary:
				_titles = j
	return _titles

## Registers the cabinet's title as an owner-editable sign (scripts/signs.gd), numbered in
## build order. The marquee is the first face (signs.gd reads faces[0] as "the marquee"); the
## lower front, the panel's front lip and the bezel strip, which repeat the title, follow, each
## with its word-free atlas (tex/pc/video_<face>_blank.png), the title's band on that face
## and its look, so a rename changes every printed copy of the name together.
static func _sign(b, si, xf, sf):
	if not ("signs" in b) or not sf.has("marquee"):
		return
	var k = 0
	for r in b.signs:
		if r.kind == "pc_marquee":
			k += 1
	var faces = []
	var info = _title_info()
	for key in ["marquee", "fronts", "panels", "bezels"]:
		if not sf.has(key) or sf[key] == null or sf[key].is_empty():
			continue
		var P = []
		for p in sf[key][0]:
			P.append(xf * p)
		var face = [P, sf[key][1], (xf.basis * sf[key][2]).normalized()]
		if key != "marquee":
			var t = info.get(key, [])
			if si >= t.size() or t[si] == null:
				continue
			var e = t[si]
			var look = {"font": e.font, "fill": e.fill, "outline": e.outline}
			if e.has("osz"):
				look["osz"] = e.osz
			face.append({"tex": "res://tex/pc/video_%s_blank.png" % key, "band": e.band, "span": e.span, "look": look, "lit": true})
		faces.append(face)
	b.sign_add("pc.video.%02d" % (k + 1), "pc_marquee", STYLES[si].title, si, faces)

static func _mq_uv(col, row, fu, fv):
	return Vector2((col * 512.0 + 3.0 + fu * 506.0) / 1024.0, (row * 170.0 + 3.0 + fv * 164.0) / 1024.0)

## Style 6: a marquee housing wider than the cabinet, its sides flaring out toward the top.
## Returns the marquee face [points, uvs, normal].
static func _housing(b, g, xf, s, si):
	var z0 = s.mq[0]
	var y0 = s.mq[1]
	var z1 = s.mq[2]
	var y1 = s.mq[3]
	var hw0 = s.W * 0.5
	var hw1 = s.flare * 0.5
	var D = s.D
	var lam = "pc_video_lam_%d" % si
	var tm = "pc_video_tm_%d" % si
	var fl = Vector3(-hw0, y0, z0)
	var fr_ = Vector3(hw0, y0, z0)
	var tl = Vector3(-hw1, y1, z1)
	var tr = Vector3(hw1, y1, z1)
	var nfront = (fr_ - fl).cross(tl - fl).normalized()
	if nfront.z > 0:
		nfront = -nfront
	_q(b, g, "pc_video_metal", xf, [fl, fr_, tr, tl], nfront, [])
	# marquee plastic, inset by a 22 mm frame, 3 mm proud
	var col = si % MQ_COLS
	var row = si / MQ_COLS
	var m = []
	var uv = []
	for c in [[0.0, 0.0], [1.0, 0.0], [1.0, 1.0], [0.0, 1.0]]:
		var fv = lerp(0.07, 0.93, c[1])
		var hw = lerp(hw0, hw1, fv) - 0.022
		var y = lerp(y0, y1, fv)
		var z = lerp(z0, z1, fv)
		m.append(Vector3(lerp(-hw, hw, c[0]), y, z) + nfront * 0.003)
		uv.append(_mq_uv(col, row, c[0], 1.0 - c[1]))
	_q(b, g, "pc_video_marquee", xf, m, nfront, uv)
	for sg in [-1.0, 1.0]:
		var a = Vector3(sg * hw0, y0, z0)
		var c = Vector3(sg * hw1, y1, z1)
		var a2 = Vector3(sg * hw0, y0, D)
		var c2 = Vector3(sg * hw1, y1, D)
		var n = (c - a).cross(a2 - a).normalized()
		if n.x * sg < 0:
			n = -n
		_q(b, g, lam, xf, [a, a2, c2, c], n, [])
		# T-molding on the front edge of each wing
		var inx = Vector3(-sg * 0.019, 0, 0)
		_q(b, g, tm, xf, [a + nfront * 0.002, a + nfront * 0.002 + inx, c + nfront * 0.002 + inx, c + nfront * 0.002], nfront,
			[Vector2(0, 2), Vector2(1, 2), Vector2(1, 0), Vector2(0, 0)])
		var e0 = a + n * 0.0015
		var e1 = c + n * 0.0015
		_q(b, g, tm, xf, [e0 + nfront * 0.002, e0 - nfront * 0.0 + (a2 - a).normalized() * 0.02, e1 + (c2 - c).normalized() * 0.02, e1 + nfront * 0.002], n,
			[Vector2(0, 2), Vector2(1, 2), Vector2(1, 0), Vector2(0, 0)])
	# roof, back
	_q(b, g, lam, xf, [tl, tr, Vector3(hw1, y1, D), Vector3(-hw1, y1, D)], Vector3.UP, [])
	_q(b, g, lam, xf, [Vector3(-hw0, y0, D), Vector3(hw0, y0, D), Vector3(hw1, y1, D), Vector3(-hw1, y1, D)], Vector3.BACK, [])
	# top edge trim (T-molding over the front of the roof)
	_q(b, g, tm, xf, [tl + Vector3(0, 0.002, -0.002), tr + Vector3(0, 0.002, -0.002), tr + Vector3(0, 0.002, 0.018), tl + Vector3(0, 0.002, 0.018)], Vector3.UP,
		[Vector2(0, 2), Vector2(1, 2), Vector2(1, 0), Vector2(0, 0)])
	return [m, uv, nfront]

## The control panel: a steel box a little wider than the cabinet, overlay on top and front.
## Returns the front lip [points, uvs, normal], where the title is printed.
static func _panel(b, g, xf, s, si):
	var y0 = s.cp[0]
	var tf = s.cp[1]
	var d = s.cp[2] + 0.012
	var tb = s.cp[3] + 0.006
	var Wp = s.W + 0.010
	var prof = [Vector2(0, y0), Vector2(0, tf), Vector2(d, tb), Vector2(d, tb - 0.07), Vector2(s.kz - 0.004, s.lo - 0.01)]
	var col = si % PANEL_COLS
	var row = si / PANEL_COLS
	var lip = []
	for i in prof.size():
		var A = prof[i]
		var B = prof[(i + 1) % prof.size()]
		var fr = _frame(A.x, A.y, B.x, B.y)
		var p = [_fp(fr, -Wp * 0.5, 0, 0), _fp(fr, Wp * 0.5, 0, 0), _fp(fr, Wp * 0.5, fr.L, 0), _fp(fr, -Wp * 0.5, fr.L, 0)]
		if i == 0:
			var uv = [_pn_uv(col, row, 0, 192 + 64), _pn_uv(col, row, 1, 192 + 64), _pn_uv(col, row, 1, 192), _pn_uv(col, row, 0, 192)]
			_q(b, g, "pc_video_panel", xf, p, fr.N, uv)
			lip = [p, uv, fr.N]
		elif i == 1:
			var uv = [_pn_uv(col, row, 0, 192), _pn_uv(col, row, 1, 192), _pn_uv(col, row, 1, 0), _pn_uv(col, row, 0, 0)]
			_q(b, g, "pc_video_panel", xf, p, fr.N, uv)
		else:
			_q(b, g, "pc_video_cpside", xf, p, fr.N, [])
	# rounded front edge: a 45 degree bevel strip over the corner
	var be = 0.006
	_q(b, g, "pc_video_panel", xf, [Vector3(-Wp * 0.5, tf - be, -0.001), Vector3(Wp * 0.5, tf - be, -0.001), Vector3(Wp * 0.5, tf + 0.0005, be * 0.4), Vector3(-Wp * 0.5, tf + 0.0005, be * 0.4)],
		Vector3(0, 1, -1).normalized(), [_pn_uv(col, row, 0, 193), _pn_uv(col, row, 1, 193), _pn_uv(col, row, 1, 190), _pn_uv(col, row, 0, 190)])
	# panel ends
	var outline = PackedVector2Array(prof)
	var idx = Geometry2D.triangulate_polygon(outline)
	for sg in [-1.0, 1.0]:
		var stt = b.st(g, "pc_video_cpside")
		var n = (xf.basis * Vector3(sg, 0, 0)).normalized()
		for k in range(0, idx.size(), 3):
			var pts = []
			for j in 3:
				var q = outline[idx[k + j]]
				pts.append(xf * Vector3(sg * Wp * 0.5, q.y, q.x))
			b.tri(stt, pts[0], pts[1], pts[2], Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, n)
	return lip

static func _pn_uv(col, row, fu, py):
	return Vector2((col * 512.0 + 2.0 + fu * 508.0) / 1024.0, (row * 256.0 + clamp(py, 1.0, 255.0)) / 1024.0)

## A point on the panel top: x across, s metres back from the front edge, h above it.
static func _ptop(s, x, sv, h = 0.0):
	var tf = s.cp[1]
	var d = s.cp[2] + 0.012
	var tb = s.cp[3] + 0.006
	var L = Vector2(d, tb - tf).length()
	var t = sv / L
	return Vector3(x, lerp(tf, tb, t) + h, d * t)

## Coin doors: steel door (painted), two coin entries each with a lit reject button.
static func _doors(b, g, xf, s):
	var dh = 0.41
	var dw = 0.30
	var y1 = s.lo - 0.05
	var y0 = y1 - dh
	var z = s.kz - 0.006
	for dx in s.doors:
		var x0 = dx - dw * 0.5
		var x1 = dx + dw * 0.5
		_q(b, g, "pc_video_door", xf, [Vector3(x0, y0, z), Vector3(x1, y0, z), Vector3(x1, y1, z), Vector3(x0, y1, z)], Vector3.FORWARD,
			[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])
		# door edges (6 mm proud)
		_q(b, g, "pc_video_metal", xf, [Vector3(x0, y1, z), Vector3(x1, y1, z), Vector3(x1, y1, s.kz), Vector3(x0, y1, s.kz)], Vector3.UP, [])
		_q(b, g, "pc_video_metal", xf, [Vector3(x0, y0, s.kz), Vector3(x1, y0, s.kz), Vector3(x1, y0, z), Vector3(x0, y0, z)], Vector3.DOWN, [])
		_q(b, g, "pc_video_metal", xf, [Vector3(x0, y0, s.kz), Vector3(x0, y0, z), Vector3(x0, y1, z), Vector3(x0, y1, s.kz)], Vector3.LEFT, [])
		_q(b, g, "pc_video_metal", xf, [Vector3(x1, y0, z), Vector3(x1, y0, s.kz), Vector3(x1, y1, s.kz), Vector3(x1, y1, z)], Vector3.RIGHT, [])
		# coin entries: chrome plates 52 x 110 mm, 12 mm proud
		for ex in [-0.062, 0.062]:
			var cx = dx + ex
			var cy = y1 - 0.105
			var ew = 0.026
			var eh = 0.055
			var ez = z - 0.012
			_q(b, g, "pc_video_entry", xf, [Vector3(cx - ew, cy - eh, ez), Vector3(cx + ew, cy - eh, ez), Vector3(cx + ew, cy + eh, ez), Vector3(cx - ew, cy + eh, ez)], Vector3.FORWARD,
				[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)], true)
			_bx(b, g, "pc_video_chrome", xf, Transform3D(Basis(), Vector3(cx, cy, (ez + z) * 0.5)), Vector3.ZERO, Vector3(ew * 2.0, eh * 2.0, z - ez), true, ["-z", "+z"])

## Joysticks, buttons, start lamps and the special controls.
static func _controls(b, g, xf, s):
	for c in s.ctl:
		var kind = c[0]
		var x = float(c[1])
		var sv = float(c[2])
		var col = Color(c[3]) if c[3].begins_with("#") else Color.WHITE
		var p = _ptop(s, x, sv)
		var wp = xf * p
		match kind:
			"stick":
				b.cur_color = Color("#101012")
				b.cyl(g, "vcolor", wp + Vector3(0, -0.002, 0), 0.026, 0.026, 0.0035, 14, true, false, true)
				b.cyl(g, "pc_video_chrome", wp, 0.0052, 0.0052, 0.062, 8, false, false, true)
				b.cur_color = col
				_sphere(b, g, "pc_video_ball", wp + Vector3(0, 0.077, 0), 0.0175, 12, -80.0)
			"btn":
				b.cur_color = Color("#0e0e10") if col.v > 0.5 else col.darkened(0.25)
				b.cyl(g, "vcolor", wp + Vector3(0, -0.003, 0), 0.0168, 0.0162, 0.0075, 14, true, false, true)
				b.cur_color = col
				b.cyl(g, "pc_video_ball", wp + Vector3(0, -0.002, 0), 0.0128, 0.0126, 0.0115, 14, true, false, true)
			"start":
				b.cur_color = Color("#d8d8d8")
				b.cyl(g, "vcolor", wp + Vector3(0, -0.003, 0), 0.0135, 0.013, 0.006, 12, true, false, true)
				b.cyl(g, "pc_video_lamp_" + c[3], wp + Vector3(0, -0.002, 0), 0.0105, 0.0102, 0.0095, 12, true, false, true)
			"ball":
				b.cur_color = Color("#0c0c0e")
				b.cyl(g, "pc_video_chrome", wp + Vector3(0, -0.002, 0), 0.050, 0.047, 0.005, 20, true, false, true)
				b.cur_color = col
				_sphere(b, g, "pc_video_ball", wp + Vector3(0, -0.013, 0), 0.0381, 16, asin(0.016 / 0.0381) * 180.0 / PI)
			"spin":
				b.cyl(g, "pc_video_chrome", wp + Vector3(0, -0.002, 0), 0.032, 0.030, 0.006, 18, true, false, true)
				b.cur_color = col
				b.cyl(g, "vcolor", wp + Vector3(0, 0.004, 0), 0.024, 0.0235, 0.026, 18, true, false, true)
				b.cyl(g, "pc_video_chrome", wp + Vector3(0, 0.030, 0), 0.010, 0.009, 0.001, 12, true, false, true)
			"gun":
				_gun(b, g, xf, s, p, col)
			"wheel":
				_wheel(b, g, xf, s, p, col)
			"shift":
				b.cur_color = Color("#101012")
				b.cyl(g, "vcolor", wp + Vector3(0, -0.002, 0), 0.040, 0.020, 0.045, 12, true, false, true)
				var top = p + Vector3(0, 0.16, 0.02)
				_bar(b, g, "pc_video_chrome", xf, p + Vector3(0, 0.04, 0), top, 0.011)
				b.cur_color = col
				_sphere(b, g, "pc_video_ball", xf * top + Vector3(0, 0.01, 0), 0.024, 12, -80.0)
			"pedal":
				var z0 = 0.015
				var z1 = s.kz - 0.008
				b.cur_color = Color("#1e1e20")
				_bx(b, g, "vcolor", xf, Transform3D(Basis(), Vector3(x, 0.02, (z0 + z1) * 0.5)), Vector3.ZERO, Vector3(0.20, 0.04, z1 - z0), true)
				var pb = Basis(Vector3.RIGHT, deg_to_rad(28.0))
				b.cur_color = col
				_bx(b, g, "pc_video_kick", xf, Transform3D(pb, Vector3(x, 0.085, (z0 + z1) * 0.5 + 0.005)), Vector3.ZERO, Vector3(0.10, 0.012, 0.15), true)
		b.cur_color = Color.WHITE

## A sphere (dynamic, vertical rings) from latitude lat0 (degrees) to the pole.
static func _sphere(b, g, m, c, r, seg, lat0):
	var n = 6
	var a0 = deg_to_rad(lat0)
	for i in n:
		var la = lerp(a0, PI * 0.5, float(i) / n)
		var lb = lerp(a0, PI * 0.5, float(i + 1) / n)
		var y0 = c.y + r * sin(la)
		var y1 = c.y + r * sin(lb)
		b.cyl(g, m, Vector3(c.x, y0, c.z), r * cos(la), max(r * cos(lb), 0.0005), y1 - y0, seg, i == n - 1, i == 0 and lat0 < -60.0, true)

## A light gun parked barrel-down in a holster cup, its armoured cable into the panel.
static func _gun(b, g, xf, s, p, col):
	b.cur_color = Color("#141416")
	# holster cup
	_bx(b, g, "vcolor", xf, Transform3D(Basis(), p + Vector3(0, 0.040, 0.0)), Vector3.ZERO, Vector3(0.068, 0.11, 0.075), true)
	_bx(b, g, "pc_video_chrome", xf, Transform3D(Basis(), p + Vector3(0, 0.0955, 0.0)), Vector3.ZERO, Vector3(0.072, 0.004, 0.079), true)
	# gun: barrel down into the cup, tilted back 12 degrees. Gun frame: y = from muzzle to
	# the rear of the gun, z = the gun's top (toward the machine), -z = its grip side.
	var gb = Basis(Vector3.RIGHT, deg_to_rad(-12.0))
	var gxf = Transform3D(gb, p + Vector3(0, 0.02, 0.0))
	b.cur_color = col
	# barrel and receiver
	_bx(b, g, "pc_video_ball", xf, gxf, Vector3(0, 0.075, 0.010), Vector3(0.026, 0.15, 0.028), true)
	_bx(b, g, "pc_video_ball", xf, gxf, Vector3(0, 0.180, 0.000), Vector3(0.034, 0.075, 0.056), true)
	_bx(b, g, "pc_video_ball", xf, gxf, Vector3(0, 0.150, -0.004), Vector3(0.030, 0.03, 0.040), true)
	# rear sight and muzzle ring
	b.cur_color = Color("#16161a")
	_bx(b, g, "pc_video_ball", xf, gxf, Vector3(0, 0.205, 0.031), Vector3(0.012, 0.014, 0.008), true)
	# grip: down and back from the receiver, toward the player
	var gd = Vector3(0, 0.32, -1.0).normalized()
	var g0 = Vector3(0, 0.185, -0.018)
	var g1 = g0 + gd * 0.105
	var gl = gd
	var gx = Vector3.RIGHT
	var gz = gx.cross(gl)
	_bx(b, g, "pc_video_ball", xf, gxf * Transform3D(Basis(gx, gl, gz), (g0 + g1) * 0.5), Vector3.ZERO, Vector3(0.031, 0.105, 0.038), true)
	# trigger and its guard, ahead of the grip
	b.cur_color = col
	_bx(b, g, "pc_video_ball", xf, gxf, Vector3(0, 0.118, -0.050), Vector3(0.010, 0.050, 0.008), true)
	_bx(b, g, "pc_video_ball", xf, gxf, Vector3(0, 0.097, -0.036), Vector3(0.010, 0.008, 0.030), true)
	b.cur_color = Color("#16161a")
	_bx(b, g, "pc_video_ball", xf, gxf, Vector3(0, 0.140, -0.034), Vector3(0.006, 0.012, 0.020), true)
	# armoured cable: from the butt to a grommet farther out on the panel
	var butt = gxf * (g1 + gd * 0.005)
	var side = 1.0 if p.x > 0 else -1.0
	var ent = _ptop(s, p.x + side * 0.055, 0.25)
	var mid = (butt + ent) * 0.5 + Vector3(side * 0.03, 0.10, -0.03)
	b.cur_color = Color("#2a2a2e")
	var prev = butt
	for i in range(1, 11):
		var t = float(i) / 10.0
		var q = butt.lerp(mid, t).lerp(mid.lerp(ent, t), t)
		_bar(b, g, "pc_video_chrome", xf, prev, q, 0.011)
		prev = q
	b.cyl(g, "vcolor", xf * ent + Vector3(0, -0.002, 0), 0.016, 0.014, 0.012, 10, true, false, true)

## Steering wheel on a column out of the panel (style 6).
static func _wheel(b, g, xf, s, p, col):
	var c = Vector3(0, 1.10, 0.13)
	var n = Vector3(0, 0.55, -0.835).normalized()   # wheel face toward the player and up
	var v = Vector3(0, 0.835, 0.55)                  # wheel "up" in its plane
	var u = Vector3.RIGHT
	var r = 0.145
	b.cur_color = col
	var N = 20
	for i in N:
		var a0 = TAU * i / N
		var a1 = TAU * (i + 1) / N
		var p0 = c + (u * cos(a0) + v * sin(a0)) * r
		var p1 = c + (u * cos(a1) + v * sin(a1)) * r
		_bar(b, g, "pc_video_ball", xf, p0, p1 + (p1 - p0) * 0.12, 0.024)
	# spokes and hub
	for a in [0.0, PI, -PI * 0.5]:
		var e = c + (u * cos(a) + v * sin(a)) * (r - 0.01)
		_bar(b, g, "pc_video_ball", xf, c, e, 0.018)
	b.cur_color = Color("#202024")
	_bx(b, g, "pc_video_ball", xf, Transform3D(Basis(u, v, -n), c - n * 0.012), Vector3.ZERO, Vector3(0.075, 0.075, 0.03), true)
	# column into the panel console
	var foot = _ptop(s, 0.0, 0.22, -0.01)
	b.cur_color = Color("#141416")
	_bar(b, g, "vcolor", xf, c - n * 0.02, foot, 0.06)
	b.cur_color = Color.WHITE

static func _tint(h):
	var c = Color(h)
	return Color(c.r * 2.5, c.g * 2.5, c.b * 2.5, 1.0)

## Material "pc_video_<key>".
static func fill_mat(m, key, b):
	if key.begins_with("lam_"):
		var s = STYLES[int(key.substr(4))]
		m.albedo_texture = b.tex("pc/video_lam.png")
		m.albedo_color = _tint(s.body)   # the texture is ~0.4 grey: abrasion can read lighter
		m.roughness = 0.55
		return true
	if key.begins_with("tm_"):
		var s = STYLES[int(key.substr(3))]
		m.albedo_texture = b.tex("pc/video_tmold.png")
		m.albedo_color = _tint(s.tm)
		m.roughness = 0.35
		return true
	if key.begins_with("lamp_"):
		var lc = {"w": "#fff4d8", "r": "#ff3a2a", "b": "#4a8cff", "y": "#ffd23a", "g": "#4cff6a"}
		var c = Color(lc.get(key.substr(5), "#ffffff"))
		m.albedo_color = c
		m.roughness = 0.3
		m.emission_enabled = true; m.emission = c; m.emission_energy_multiplier = 3.5
		m.set_meta("e_day", 3.5); m.set_meta("e_night", 3.5)
		return true
	match key:
		"side":
			m.albedo_texture = b.tex("pc/video_sides.png"); m.roughness = 0.5
		"kick":
			m.albedo_texture = b.tex("pc/video_kick.png"); m.roughness = 0.45; m.metallic = 0.5
		"front":
			m.albedo_texture = b.tex("pc/video_fronts.png"); m.roughness = 0.5
		"door":
			m.albedo_texture = b.tex("pc/video_door.png"); m.roughness = 0.5; m.metallic = 0.35
		"entry":
			m.albedo_texture = b.tex("pc/video_entry.png"); m.roughness = 0.25; m.metallic = 0.7
			m.emission_enabled = true; m.emission_texture = b.tex("pc/video_entry_e.png")
			m.emission = Color.WHITE; m.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY; m.emission_energy_multiplier = 2.2
			m.set_meta("e_day", 2.2); m.set_meta("e_night", 2.2)
		"chrome":
			m.albedo_color = Color("#b8b8be"); m.metallic = 0.85; m.roughness = 0.25
		"metal":
			m.albedo_color = Color("#141416"); m.metallic = 0.4; m.roughness = 0.45
		"cpside":
			m.albedo_texture = b.tex("pc/video_lam.png"); m.albedo_color = _tint(STYLES[0].cpc); m.roughness = 0.5
		"panel":
			m.albedo_texture = b.tex("pc/video_panels.png"); m.roughness = 0.4
		"bezel":
			m.albedo_texture = b.tex("pc/video_bezels.png"); m.roughness = 0.6
		"recess":
			m.albedo_color = Color("#060607"); m.roughness = 0.9
		"speaker":
			m.albedo_texture = b.tex("pc/video_speaker.png"); m.roughness = 0.75
		"crt":
			var t = b.tex("pc/video_screens.png")
			m.albedo_texture = t; m.albedo_color = Color(0.10, 0.10, 0.10)
			m.roughness = 0.12; m.metallic_specular = 0.6
			m.emission_enabled = true; m.emission_texture = t
			m.emission = Color.WHITE; m.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY; m.emission_energy_multiplier = 1.6
			m.set_meta("e_day", 1.6); m.set_meta("e_night", 1.6)
		"scan":
			m.albedo_texture = b.tex("pc/video_scan.png")
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
		"glass":
			m.albedo_texture = b.tex("pc/video_glass.png")
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
			m.roughness = 0.08; m.metallic_specular = 0.9
		"marquee":
			var t = b.tex("pc/video_marquees.png")
			m.albedo_texture = t; m.albedo_color = Color(0.55, 0.55, 0.55); m.roughness = 0.3
			m.emission_enabled = true; m.emission_texture = t
			m.emission = Color.WHITE; m.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY; m.emission_energy_multiplier = 1.3
			m.set_meta("e_day", 1.3); m.set_meta("e_night", 1.3)
		"ball":
			m.vertex_color_use_as_albedo = true; m.roughness = 0.22; m.metallic_specular = 0.6
		_:
			return false
	return true
