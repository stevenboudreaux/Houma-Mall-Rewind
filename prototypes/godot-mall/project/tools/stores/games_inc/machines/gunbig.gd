## games, inc. M7: the big two-player gun cabinet on the right wall (design/storefronts/games-inc-2026.md;
## f031-f033, f035). 1.8 x 1.4 x 2.6 m: a dark jungle-green body on a red base, a screen in an arched
## surround edged with a green LED arch, ARCADE on the lower front and sides, two mounted guns, a topper.
## The dinosaur franchise art and topper are generic jungle shapes and a burst (no licensed art).
## Atlas tex/gi/m_gunbig.png (paint.py gunbig()).

const K = preload("res://tools/stores/games_inc/machines/kit.gd")
const W = 1.8
const D = 1.4
const H = 2.6

static func footprint(_opts = {}):
	return Vector2(W, D)

static func build(b, g, o, f, opts = {}):
	var xf = K.X(o, f)
	var body = "gi_m_gunbig_body"
	var lit = "gi_m_gunbig_lit"
	var hw = W * 0.5
	var side = K.rg("gunbig", "side")
	K.tbox(b, g, body, xf, Vector3(0, 1.1, 0.75), Vector3(W, 2.2, 1.3), {"front": K.rg("gunbig", "front"), "left": side, "right": side, "back": side, "top": side})
	# the screen, recessed 2 cm behind the front's arched surround
	K.face(b, g, lit, xf, [Vector3(-0.6, 1.25, 0.08), Vector3(0.6, 1.25, 0.08), Vector3(0.6, 2.0, 0.08), Vector3(-0.6, 2.0, 0.08)], Vector3(0, 0, -1), K.rg("gunbig", "screen"))
	# green LED arch round the screen (three straight runs)
	K.led(b, g, xf, Vector3(-0.7, 1.15, 0.07), Vector3(-0.7, 2.05, 0.07), "#3cff6a", 0.035)
	K.led(b, g, xf, Vector3(0.7, 1.15, 0.07), Vector3(0.7, 2.05, 0.07), "#3cff6a", 0.035)
	K.led(b, g, xf, Vector3(-0.7, 2.08, 0.07), Vector3(0.7, 2.08, 0.07), "#3cff6a", 0.035)
	# the topper
	K.tbox(b, g, lit, xf, Vector3(0, 2.4, 0.9), Vector3(1.4, 0.4, 0.5), {"front": K.rg("gunbig", "top"), "left": side, "right": side, "back": side, "top": side})
	# the control shelf and two guns (dynamic)
	K.cbox(b, g, "vcolor", xf, Vector3(0, 0.95, 0.0), Vector3(W - 0.2, 0.08, 0.3), "#b8161c")
	for sx in [-1, 1]:
		K.cbox(b, g, "vcolor", xf, Vector3(sx * 0.45, 1.06, -0.05), Vector3(0.08, 0.14, 0.32), ["#ff8a1a", "#3b6bff"][(sx + 1) / 2], true)
		K.cbox(b, g, "gi_k_black", xf, Vector3(sx * 0.45, 1.0, 0.05), Vector3(0.05, 0.12, 0.06), "#ffffff", true)
	K.led(b, g, xf, Vector3(-hw, 0.02, 0.1), Vector3(hw, 0.02, 0.1), "#ff2a2a", 0.03)
	K.obst(b, xf, -hw, hw, -0.15, D, 0.12)

static func fill_mat(m, key, b):
	if key in ["body", "lit"]:
		return K.atlas_mat(m, b, "gunbig", key, 1.2, 0.4)
	return false
