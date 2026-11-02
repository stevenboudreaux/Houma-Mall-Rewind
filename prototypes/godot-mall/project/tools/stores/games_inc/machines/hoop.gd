## games, inc. M11: "BASKETBALL PRO" (design/storefronts/games-inc-2026.md; f038-f039). A single-player hoop
## cabinet, 0.9 x 2.4 x 2.6 m: a ball ramp at the front, side panels in blue/red with the name, a caged net
## box (netting as see-through glass), a white backboard with a red LED score and a hoop, a lit marquee
## on top. Atlas tex/gi/m_hoop.png (paint.py hoop()).

const K = preload("res://tools/stores/games_inc/machines/kit.gd")
const W = 0.9
const D = 2.4
const H = 2.6

static func footprint(_opts = {}):
	return Vector2(W, D)

static func build(b, g, o, f, opts = {}):
	var xf = K.X(o, f)
	var body = "gi_m_hoop_body"
	var lit = "gi_m_hoop_lit"
	var hw = W * 0.5
	var side = K.rg("hoop", "side")
	# the ramp body (z 0..1.5, rising 0.8 -> 1.0) and the back tower (z 1.5..2.4)
	K.tbox(b, g, body, xf, Vector3(0, 0.4, 0.75), Vector3(W, 0.8, 1.5), {"front": K.sub(side, 0.0, 0.0, 0.1, 0.4), "left": K.sub(side, 0.0, 0.6, 0.6, 1.0), "right": K.sub(side, 0.0, 0.6, 0.6, 1.0), "top": null})
	K.face(b, g, body, xf, [Vector3(-hw, 0.8, 0.0), Vector3(hw, 0.8, 0.0), Vector3(hw, 1.0, 1.5), Vector3(-hw, 1.0, 1.5)], Vector3(0, 0.99, -0.13).normalized(), K.rg("hoop", "ramp"))
	K.tbox(b, g, body, xf, Vector3(0, H * 0.5 - 0.2, 1.95), Vector3(W, H - 0.4, 0.9), {"all": side, "front": null})
	# side walls of the net box (glass) and its roof
	for sx in [-1, 1]:
		K.face(b, g, "gi_k_glass", xf, [Vector3(sx * hw, 1.0, 1.5), Vector3(sx * hw, 0.8, 0.0), Vector3(sx * hw, 2.0, 0.0), Vector3(sx * hw, 2.0, 1.5)], Vector3(sx, 0, 0), Vector4(0, 0, 1, 1), true)
		K.cbox(b, g, "vcolor", xf, Vector3(sx * hw, 1.4, 0.0), Vector3(0.05, 1.2, 0.05), "#d8202a")
	# the backboard with the score, a hoop (dynamic ring of small boxes)
	K.face(b, g, lit, xf, [Vector3(-0.38, 1.2, 1.5), Vector3(0.38, 1.2, 1.5), Vector3(0.38, 1.95, 1.5), Vector3(-0.38, 1.95, 1.5)], Vector3(0, 0, -1), K.rg("hoop", "board"))
	for k in 10:
		var a = TAU * k / 10.0
		K.cbox(b, g, "vcolor", xf, Vector3(cos(a) * 0.12, 1.3, 1.36 + sin(a) * 0.12), Vector3(0.03, 0.02, 0.03), "#ff6a1a", true)
	# the marquee on top, leaning forward
	K.face(b, g, lit, xf, [Vector3(-hw, 2.0, 1.45), Vector3(hw, 2.0, 1.45), Vector3(hw, H, 1.55), Vector3(-hw, H, 1.55)], Vector3(0, 0, -1), K.rg("hoop", "marq"))
	# a few balls in the well (dynamic)
	b.cur_color = Color("#f08a1a")
	for k in 3:
		K.ell(b, g, "vcolor", xf * Vector3(-0.2 + k * 0.2, 0.92, 0.12), Vector3(0.11, 0.11, 0.11), 8, 5)
	b.cur_color = Color.WHITE
	K.obst(b, xf, -hw, hw, 0, D, 0.1)

static func fill_mat(m, key, b):
	if key in ["body", "lit"]:
		return K.atlas_mat(m, b, "hoop", key, 1.3, 0.4)
	return false
