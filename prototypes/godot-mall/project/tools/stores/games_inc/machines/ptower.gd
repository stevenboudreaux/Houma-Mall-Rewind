## games, inc. prize towers (design/storefronts/games-inc-2026.md). opts {"style": 0 | 1}:
##  0  M13 "DIZZY CHICKEN" (f052): 1.0 x 1.0 x 2.5 m: an orange/yellow cartoon-print base with the name, a
##     round acrylic tower with a lit blue spiral of prizes inside, a red cap and a cartoon chicken head on top.
##  1  M12 (f039, f052): the same format with a yellow base and an orange cap (name not legible: no word).
## Atlas tex/gi/m_ptower.png (paint.py ptower()).

const K = preload("res://tools/stores/games_inc/machines/kit.gd")
const W = 1.0
const D = 1.0
const H = 2.5
const SEG = 12

static func footprint(_opts = {}):
	return Vector2(W, D)

## A vertical prism of SEG sides (local centre c at floor y0..y1, radius r), texture rect tr wrapped once.
static func prism(b, g, m, xf, c, r, y0, y1, tr, dyn = false, inward = false):
	for k in SEG:
		var a0 = TAU * k / SEG; var a1 = TAU * (k + 1) / SEG
		var p0 = c + Vector3(cos(a0) * r, 0, sin(a0) * r); var p1 = c + Vector3(cos(a1) * r, 0, sin(a1) * r)
		var n = Vector3(cos((a0 + a1) * 0.5), 0, sin((a0 + a1) * 0.5))
		var u0 = lerp(tr.x, tr.z, float(k) / SEG); var u1 = lerp(tr.x, tr.z, float(k + 1) / SEG)
		var q = [p1 + Vector3(0, y0, 0), p0 + Vector3(0, y0, 0), p0 + Vector3(0, y1, 0), p1 + Vector3(0, y1, 0)]
		K.face(b, g, m, xf, q, -n if inward else n, Vector4(u1, tr.y, u0, tr.w), dyn)

static func build(b, g, o, f, opts = {}):
	var xf = K.X(o, f)
	var s = int(opts.get("style", 0)) % 2
	var body = "gi_m_ptower_body"
	var lit = "gi_m_ptower_lit"
	var c = Vector3(0, 0, 0.5)
	K.tbox(b, g, body, xf, Vector3(0, 0.45, 0.5), Vector3(0.9, 0.9, 0.9), {"all": K.rg("ptower", "base%d" % s), "top": K.rg("ptower", "cap")})
	# the lit prize spiral inside, the acrylic outside (dynamic), the blue LED ring at its foot
	prism(b, g, lit, xf, c, 0.36, 0.9, 2.05, K.rg("ptower", "inner%d" % s))
	prism(b, g, "gi_k_dome", xf, c, 0.44, 0.9, 2.1, Vector4(0, 0, 1, 1), true)
	for k in SEG:
		var a0 = TAU * k / SEG; var a1 = TAU * (k + 1) / SEG
		K.led(b, g, xf, c + Vector3(cos(a0) * 0.43, 0.93, sin(a0) * 0.43), c + Vector3(cos(a0) * 0.43, 0.93, sin(a0) * 0.43) + Vector3(0.001, 0, 0), ["#3b6bff", "#ff4fa8"][k % 2], 0.05, true)
	# the cap and the topper
	K.vcyl(b, g, "vcolor", xf, c + Vector3(0, 2.1, 0), 0.46, 0.4, 0.14, 16, true, false, Color(["#e8282a", "#ff8a1a"][s]))
	if s == 0:
		b.cur_color = Color("#e8282a")
		K.ell(b, g, "vcolor", xf * (c + Vector3(0, 2.33, 0)), Vector3(0.24, 0.2, 0.22), 10, 6, false)
		b.cur_color = Color.WHITE
		K.face(b, g, lit, xf, [Vector3(-0.2, 2.18, 0.26), Vector3(0.2, 2.18, 0.26), Vector3(0.2, 2.5, 0.26), Vector3(-0.2, 2.5, 0.26)], Vector3(0, 0, -1), K.rg("ptower", "head"))
	else:
		K.tbox(b, g, lit, xf, Vector3(0, 2.36, 0.5), Vector3(0.7, 0.26, 0.12), {"all": K.rg("ptower", "cap")})
	K.obst(b, xf, -W * 0.5, W * 0.5, 0, D, 0.1)

static func fill_mat(m, key, b):
	if key in ["body", "lit"]:
		return K.atlas_mat(m, b, "ptower", key, 1.3, 0.4)
	return false
