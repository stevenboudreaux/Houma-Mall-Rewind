## games, inc. M10: "DEAL OR NO DEAL" (design/storefronts/games-inc-2026.md; f036-f039). 1.5 x 2.3 x 2.6 m:
## a tall black cabinet with a screen of case values and the yellow DEAL marquee, a sloped keypad console
## of lit case buttons, a yellow-lit hexagonal floor platform with a chrome stool in front.
## Atlas tex/gi/m_deal.png (paint.py deal()).

const K = preload("res://tools/stores/games_inc/machines/kit.gd")
const W = 1.5
const D = 2.3
const H = 2.6

static func footprint(_opts = {}):
	return Vector2(W, D)

static func build(b, g, o, f, opts = {}):
	var xf = K.X(o, f)
	var body = "gi_m_deal_body"
	var lit = "gi_m_deal_lit"
	var hw = W * 0.5
	var bk = K.rg("deal", "body")
	# the tower at the back (z 1.6 .. 2.3)
	K.tbox(b, g, body, xf, Vector3(0, H * 0.5, 1.95), Vector3(1.1, H, 0.7), {"all": bk, "front": null})
	K.face(b, g, lit, xf, [Vector3(-0.5, 0.95, 1.6), Vector3(0.5, 0.95, 1.6), Vector3(0.5, 2.1, 1.6), Vector3(-0.5, 2.1, 1.6)], Vector3(0, 0, -1), K.rg("deal", "screen"))
	K.face(b, g, lit, xf, [Vector3(-0.55, 2.15, 1.58), Vector3(0.55, 2.15, 1.58), Vector3(0.55, 2.6, 1.58), Vector3(-0.55, 2.6, 1.58)], Vector3(0, 0, -1), K.rg("deal", "marq"))
	K.face(b, g, body, xf, [Vector3(-0.55, 0, 1.6), Vector3(0.55, 0, 1.6), Vector3(0.55, 0.95, 1.6), Vector3(-0.55, 0.95, 1.6)], Vector3(0, 0, -1), bk)
	# the keypad console (z 1.0 .. 1.55), sloped lit top
	K.tbox(b, g, body, xf, Vector3(0, 0.45, 1.3), Vector3(0.9, 0.9, 0.5), {"all": bk, "top": null})
	K.face(b, g, lit, xf, [Vector3(-0.45, 0.9, 1.05), Vector3(0.45, 0.9, 1.05), Vector3(0.45, 1.02, 1.55), Vector3(-0.45, 1.02, 1.55)], Vector3(0, 0.97, -0.23).normalized(), K.rg("deal", "keypad"))
	# the hexagonal lit platform (z 0 .. 1.0) and the stool on it
	var hp = []
	for k in 6:
		var a = TAU * k / 6.0
		hp.append(Vector3(cos(a) * 0.62, 0.0, 0.5 + sin(a) * 0.5))
	var c = Vector3(0, 0.09, 0.5)
	var hr = K.rg("deal", "hex")
	var huv = func(p): return Vector2(lerp(hr.x, hr.z, 0.5 + p.x / 1.24), lerp(hr.y, hr.w, 0.5 + (p.z - 0.5) / 1.0))
	for k in 6:
		var p0 = hp[k] + Vector3(0, 0.09, 0); var p1 = hp[(k + 1) % 6] + Vector3(0, 0.09, 0)
		b.quad(g, lit, [xf * c, xf * p0, xf * p1, xf * c], (xf.basis * Vector3.UP).normalized(), [huv.call(c), huv.call(p0), huv.call(p1), huv.call(c)])
		K.face(b, g, "gi_k_black", xf, [hp[(k + 1) % 6], hp[k], p0, p1], ((hp[k] + hp[(k + 1) % 6]) * 0.5 - Vector3(0, 0, 0.5)).normalized())
	K.stool(b, g, xf, Vector3(0, 0.09, 0.55), "#18181c", 0.7)
	K.obst(b, xf, -hw, hw, 0, D, 0.1)

static func fill_mat(m, key, b):
	if key in ["body", "lit"]:
		return K.atlas_mat(m, b, "deal", key, 1.4, 0.4)
	return false
