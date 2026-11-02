## games, inc. M21: the tall wheel ticket game (design/storefronts/games-inc-2026.md; f046-f051, IMG_4445).
## 1.1 x 0.9 x 2.6 m: a royal-blue cabinet with "QUEST" on its base (only "...QUEST" is legible), a big
## multicolour value wheel (40 / 30 / 20 ...) standing on it in a chrome rim, a pointer at the top.
## Atlas tex/gi/m_wheel.png (paint.py wheel()).

const K = preload("res://tools/stores/games_inc/machines/kit.gd")
const W = 1.1
const D = 0.9
const H = 2.6
const SEG = 20

static func footprint(_opts = {}):
	return Vector2(W, D)

static func build(b, g, o, f, opts = {}):
	var xf = K.X(o, f)
	var body = "gi_m_wheel_body"
	var lit = "gi_m_wheel_lit"
	var side = K.rg("wheel", "side")
	K.tbox(b, g, body, xf, Vector3(0, 0.55, 0.45), Vector3(0.9, 1.1, 0.9), {"front": K.rg("wheel", "base"), "all": side})
	# the wheel's back housing (a blue disc box) and the lit wheel face as a 20-gon
	K.tbox(b, g, body, xf, Vector3(0, 1.75, 0.62), Vector3(1.1, 1.3, 0.3), {"all": side, "front": null})
	var wr = K.rg("wheel", "wheel")
	var c = Vector3(0, 1.85, 0.46)
	var Rw = 0.53
	for k in SEG:
		var a0 = TAU * k / SEG; var a1 = TAU * (k + 1) / SEG
		var p0 = c + Vector3(cos(a0) * Rw, sin(a0) * Rw, 0); var p1 = c + Vector3(cos(a1) * Rw, sin(a1) * Rw, 0)
		var uv = func(p): return Vector2(lerp(wr.x, wr.z, 0.5 + (p.x - c.x) / (2.0 * Rw)), lerp(wr.y, wr.w, 0.5 - (p.y - c.y) / (2.0 * Rw)))
		b.quad(g, lit, [xf * c, xf * p0, xf * p1, xf * c], (xf.basis * Vector3(0, 0, -1)).normalized(), [uv.call(c), uv.call(p0), uv.call(p1), uv.call(c)])
		K.cbox(b, g, "gi_k_chrome", xf, (p0 + p1) * 0.5 - Vector3(0, 0, 0.03), Vector3(0.17, 0.04, 0.06), "#ffffff")
	# the pointer
	K.cbox(b, g, "vcolor", xf, c + Vector3(0, Rw + 0.06, -0.04), Vector3(0.08, 0.14, 0.04), "#ff2a2a", true)
	K.led(b, g, xf, Vector3(-0.45, 1.12, 0.0), Vector3(0.45, 1.12, 0.0), "#ffd21a", 0.03)
	K.obst(b, xf, -W * 0.5, W * 0.5, 0, D, 0.12)

static func fill_mat(m, key, b):
	if key in ["body", "lit"]:
		return K.atlas_mat(m, b, "wheel", key, 1.3, 0.4)
	return false
