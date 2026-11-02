## games, inc. M23/M24: the two air hockey tables (design/storefronts/games-inc-2026.md; g001-g003, IMG_4445).
## 1.3 x 2.4 x 0.8 m, placed lengthwise (the player stands at one goal end). opts {"style": 0 (red/orange,
## black rails, flame-print aprons, a curved orange overhead score arch, M23) | 1 (blue, yellow rail, M24)}.
## Atlas tex/gi/m_hockey.png (paint.py hockey()).

const K = preload("res://tools/stores/games_inc/machines/kit.gd")
const W = 1.3
const D = 2.4
const Y = 0.8
const RAIL = ["#141418", "#ffd21a"]
const LEG = ["#141418", "#3b6bff"]

static func footprint(_opts = {}):
	return Vector2(W, D)

static func build(b, g, o, f, opts = {}):
	var xf = K.X(o, f)
	var s = int(opts.get("style", 0)) % 2
	var body = "gi_m_hockey_body"
	var lit = "gi_m_hockey_lit"
	var hw = W * 0.5
	var ap = K.rg("hockey", "apron%d" % s)
	# the table body (apron 0.5..0.8) on four legs
	K.tbox(b, g, body, xf, Vector3(0, 0.62, D * 0.5), Vector3(W, 0.36, D), {"front": ap, "back": ap, "left": ap, "right": ap, "top": null, "bottom": K.sub(ap, 0, 0, 0.1, 0.1)})
	K.face(b, g, lit, xf, [Vector3(-hw + 0.07, Y, 0.07), Vector3(hw - 0.07, Y, 0.07), Vector3(hw - 0.07, Y, D - 0.07), Vector3(-hw + 0.07, Y, D - 0.07)], Vector3.UP, K.rg("hockey", "field%d" % s))
	# rails
	for r in [[Vector3(0, Y + 0.04, 0.035), Vector3(W, 0.08, 0.07)], [Vector3(0, Y + 0.04, D - 0.035), Vector3(W, 0.08, 0.07)],
			[Vector3(-hw + 0.035, Y + 0.04, D * 0.5), Vector3(0.07, 0.08, D)], [Vector3(hw - 0.035, Y + 0.04, D * 0.5), Vector3(0.07, 0.08, D)]]:
		K.cbox(b, g, "vcolor", xf, r[0], r[1], RAIL[s])
	for sx in [-1, 1]:
		for zz in [0.2, D - 0.2]:
			K.cbox(b, g, "vcolor", xf, Vector3(sx * (hw - 0.15), 0.22, zz), Vector3(0.12, 0.44, 0.12), LEG[s])
	# mallets and puck (dynamic)
	for zz in [0.35, D - 0.35]:
		K.vcyl(b, g, "vcolor", xf, Vector3(0, Y, zz), 0.05, 0.05, 0.03, 12, true, true, Color(["#ff3a2a", "#ff4fa8"][s]))
		K.vcyl(b, g, "vcolor", xf, Vector3(0, Y + 0.03, zz), 0.02, 0.02, 0.05, 8, true, true, Color(["#ff3a2a", "#ff4fa8"][s]))
	if s == 0:
		# the overhead score arch: two curved orange legs from the long sides, the score box at the top
		var pts = []
		for k in 9:
			var a = PI * k / 8.0
			pts.append(Vector3(cos(a) * (hw + 0.02), Y + 0.1 + sin(a) * 1.25, D * 0.5))
		for k in 8:
			var p0 = pts[k]; var p1 = pts[k + 1]
			var mid = (p0 + p1) * 0.5
			var dirv = (p1 - p0)
			var bas = Basis(Vector3(0, 0, 1).cross(dirv.normalized()), dirv.normalized(), Vector3(0, 0, 1))
			b.cur_color = Color("#f06a1a")
			b.box(g, "vcolor", Vector3.ZERO, Vector3(0.1, dirv.length() + 0.02, 0.07), xf * Transform3D(bas, mid))
			b.cur_color = Color.WHITE
		K.tbox(b, g, lit, xf, Vector3(0, Y + 1.38, D * 0.5), Vector3(0.6, 0.2, 0.3), {"all": K.rg("hockey", "score")})
	K.obst(b, xf, -hw, hw, -0.05, D + 0.05, 0.1)

static func fill_mat(m, key, b):
	if key in ["body", "lit"]:
		return K.atlas_mat(m, b, "hockey", key, 0.9, 0.35)
	return false
