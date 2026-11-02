## games, inc. prize merchandisers: M2, M14 "PUSH", M15 (white, one "SUPER STAR"), M16 (yellow, red ring),
## M26 (purple) (design/storefronts/games-inc-2026.md; frames f028, f052-f053, g004, IMG_4445).
## 0.85 x 0.9 x 2.0 m: a lower door panel with a card reader, a lit window of boxed prizes on glass shelves,
## a header (lit marquee). opts {"style": "white" | "plain" | "yellow" | "push" | "purple", "plush": col}
## ("plush": a plush figure sitting on top, as on the white one by the party corner and the music cab).
## Atlas tex/gi/m_merch.png (paint.py merch()).

const K = preload("res://tools/stores/games_inc/machines/kit.gd")
const W = 0.85
const D = 0.9
const H = 2.0
const Y_LOW = 0.9
const Y_WIN = 1.72
const LEDC = {"white": "#7fb0ff", "plain": "#e8f0ff", "yellow": "#ffd23a", "push": "#3b6bff", "purple": "#ff4fb8"}

static func footprint(_opts = {}):
	return Vector2(W, D)

static func build(b, g, o, f, opts = {}):
	var xf = K.X(o, f)
	var st = str(opts.get("style", "plain"))
	var body = "gi_m_merch_body"
	var lit = "gi_m_merch_lit"
	var hw = W * 0.5
	var side = K.rg("merch", "side_" + st)
	K.tbox(b, g, body, xf, Vector3(0, Y_LOW * 0.5, D * 0.5), Vector3(W, Y_LOW, D),
		{"front": K.rg("merch", "lower_" + st), "left": side, "right": side, "back": side, "top": null})
	# the window: a lit back panel of shelves, side walls in the body colour, glass front
	K.tbox(b, g, body, xf, Vector3(0, (Y_LOW + Y_WIN) * 0.5, D * 0.5), Vector3(W, Y_WIN - Y_LOW, D),
		{"left": side, "right": side, "back": side, "front": null, "top": null})
	K.face(b, g, lit, xf, [Vector3(-hw + 0.05, Y_LOW, D - 0.1), Vector3(hw - 0.05, Y_LOW, D - 0.1), Vector3(hw - 0.05, Y_WIN, D - 0.1), Vector3(-hw + 0.05, Y_WIN, D - 0.1)],
		Vector3(0, 0, -1), K.rg("merch", "window"))
	K.face(b, g, "gi_k_glass", xf, [Vector3(-hw + 0.03, Y_LOW, 0.02), Vector3(hw - 0.03, Y_LOW, 0.02), Vector3(hw - 0.03, Y_WIN, 0.02), Vector3(-hw + 0.03, Y_WIN, 0.02)],
		Vector3(0, 0, -1), Vector4(0, 0, 1, 1), true)
	# front frame round the glass in the body colour
	for sx in [-1, 1]:
		K.tbox(b, g, body, xf, Vector3(sx * (hw - 0.03), (Y_LOW + Y_WIN) * 0.5, 0.03), Vector3(0.06, Y_WIN - Y_LOW, 0.06), {"all": side})
	K.led(b, g, xf, Vector3(-hw + 0.06, Y_WIN - 0.03, 0.06), Vector3(hw - 0.06, Y_WIN - 0.03, 0.06), "#f4f8ff", 0.02)
	# header and its lit marquee
	K.tbox(b, g, body, xf, Vector3(0, (Y_WIN + H) * 0.5, D * 0.5), Vector3(W, H - Y_WIN, D), {"all": side})
	K.face(b, g, lit, xf, [Vector3(-hw + 0.02, Y_WIN + 0.03, -0.01), Vector3(hw - 0.02, Y_WIN + 0.03, -0.01), Vector3(hw - 0.02, H - 0.03, -0.01), Vector3(-hw + 0.02, H - 0.03, -0.01)],
		Vector3(0, 0, -1), K.rg("merch", "head_" + st))
	K.led(b, g, xf, Vector3(-hw, Y_LOW, 0.0), Vector3(-hw, H, 0.0), LEDC.get(st, "#ffffff"), 0.02)
	K.led(b, g, xf, Vector3(hw, Y_LOW, 0.0), Vector3(hw, H, 0.0), LEDC.get(st, "#ffffff"), 0.02)
	if opts.has("plush"):
		var rng = RandomNumberGenerator.new(); rng.seed = 5
		K.plush(b, g, xf * Vector3(0, H, D * 0.5), 1.4, opts["plush"], rng)
	K.obst(b, xf, -hw, hw, 0, D, 0.12)

static func fill_mat(m, key, b):
	if key in ["body", "lit"]:
		return K.atlas_mat(m, b, "merch", key, 1.2, 0.35)
	return false
