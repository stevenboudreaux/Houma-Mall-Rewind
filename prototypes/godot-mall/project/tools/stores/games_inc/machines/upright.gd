## games, inc. uprights (design/storefronts/games-inc-2026.md). opts {"style": ...}:
##  "nerf"   M9 (f036-f038): a red gun upright, 0.9 x 1.1 x 2.1 m, blue NERF marquee, a mounted gun.
##  "mascot" M18 (f036-f037): a tall black cabinet, 0.8 x 0.9 x 2.5 m, with a cut-out panel beside it (the
##           cartoon mascot in the footage: here a plain black panel with a red edge, no character).
##  "music"  M29 (g005-g006): a black music cabinet, 0.9 x 1.0 x 2.3 m, with two guitar controllers on hooks
##           and a plush figure on top.
##  "crossy" M17 (f036-f037, f042-f044, IMG_4445): "CROSSY ROAD" arcade, 1.25 x 1.2 x 2.5 m: a tall screen
##           framed in RGB LED studs under a lime marquee, a wide lime/black control deck with two big
##           buttons, blocky side art (plain blocks; no character).
## Atlas tex/gi/m_upright.png (paint.py upright()).

const K = preload("res://tools/stores/games_inc/machines/kit.gd")
const SIZE = {"nerf": Vector3(0.9, 1.1, 2.1), "mascot": Vector3(0.8, 0.9, 2.5), "music": Vector3(0.9, 1.0, 2.3), "crossy": Vector3(1.25, 1.2, 2.5)}
const LEDC = {"nerf": "#ff8a1a", "mascot": "#ff2a3a", "music": "#ff2a3a", "crossy": "#b9ff3a"}

static func footprint(opts = {}):
	var s = SIZE[str(opts.get("style", "nerf"))]
	return Vector2(s.x, s.y)

static func build(b, g, o, f, opts = {}):
	var xf = K.X(o, f)
	var st = str(opts.get("style", "nerf"))
	var S = SIZE[st]
	var body = "gi_m_upright_body"
	var lit = "gi_m_upright_lit"
	var hw = S.x * 0.5
	var side = K.rg("upright", "side_" + st)
	var front = K.rg("upright", "front_" + st)
	if st == "crossy":
		# deck (0..0.55 deep, 0.95 tall, sloped top), then the tall screen tower behind it
		K.tbox(b, g, body, xf, Vector3(0, 0.45, 0.35), Vector3(S.x, 0.9, 0.7), {"front": front, "left": side, "right": side, "top": null})
		K.face(b, g, body, xf, [Vector3(-hw, 0.9, 0.0), Vector3(hw, 0.9, 0.0), Vector3(hw, 1.0, 0.7), Vector3(-hw, 1.0, 0.7)], Vector3(0, 0.99, -0.14).normalized(), K.rg("upright", "deck_crossy"))
		K.tbox(b, g, body, xf, Vector3(0, 1.25, 0.95), Vector3(S.x - 0.1, 2.5, 0.5), {"all": side, "front": null})
		K.face(b, g, lit, xf, [Vector3(-0.5, 1.05, 0.7), Vector3(0.5, 1.05, 0.7), Vector3(0.5, 2.2, 0.7), Vector3(-0.5, 2.2, 0.7)], Vector3(0, 0, -1), K.rg("upright", "screen_crossy"))
		K.face(b, g, lit, xf, [Vector3(-0.58, 2.22, 0.68), Vector3(0.58, 2.22, 0.68), Vector3(0.58, 2.5, 0.68), Vector3(-0.58, 2.5, 0.68)], Vector3(0, 0, -1), K.rg("upright", "marq_crossy"))
		# the RGB LED frame round the screen: alternating colour runs
		var cols = ["#ff2a3a", "#ffd21a", "#3cff4a", "#3b6bff", "#a259ff"]
		for k in 5:
			var y0 = 1.02 + k * 0.24
			K.led(b, g, xf, Vector3(-0.54, y0, 0.69), Vector3(-0.54, y0 + 0.22, 0.69), cols[k], 0.035)
			K.led(b, g, xf, Vector3(0.54, y0, 0.69), Vector3(0.54, y0 + 0.22, 0.69), cols[(k + 2) % 5], 0.035)
		K.obst(b, xf, -hw, hw, 0, S.y, 0.15)
		return
	# a plain upright: lower front, screen in a recess, marquee
	K.tbox(b, g, body, xf, Vector3(0, S.z * 0.5, S.y * 0.5 + 0.1), Vector3(S.x, S.z, S.y - 0.2), {"front": null, "left": side, "right": side, "back": side, "top": side})
	K.face(b, g, body, xf, [Vector3(-hw, 0, 0.1), Vector3(hw, 0, 0.1), Vector3(hw, 1.0, 0.1), Vector3(-hw, 1.0, 0.1)], Vector3(0, 0, -1), front)
	K.cbox(b, g, "vcolor", xf, Vector3(0, 1.02, 0.0), Vector3(S.x, 0.06, 0.3), "#18181c")
	K.face(b, g, lit, xf, [Vector3(-hw + 0.06, 1.12, 0.3), Vector3(hw - 0.06, 1.12, 0.3), Vector3(hw - 0.06, S.z - 0.42, 0.3), Vector3(-hw + 0.06, S.z - 0.42, 0.3)], Vector3(0, 0, -1), K.rg("upright", "screen_" + st))
	K.face(b, g, body, xf, [Vector3(-hw, 1.05, 0.1), Vector3(-hw + 0.06, 1.05, 0.3), Vector3(-hw + 0.06, S.z - 0.4, 0.3), Vector3(-hw, S.z - 0.4, 0.1)], Vector3(1, 0, 0), side)
	K.face(b, g, body, xf, [Vector3(hw - 0.06, 1.05, 0.3), Vector3(hw, 1.05, 0.1), Vector3(hw, S.z - 0.4, 0.1), Vector3(hw - 0.06, S.z - 0.4, 0.3)], Vector3(-1, 0, 0), side)
	K.face(b, g, lit, xf, [Vector3(-hw, S.z - 0.4, 0.08), Vector3(hw, S.z - 0.4, 0.08), Vector3(hw, S.z, 0.08), Vector3(-hw, S.z, 0.08)], Vector3(0, 0, -1), K.rg("upright", "marq_" + st))
	K.led(b, g, xf, Vector3(-hw, 0.03, 0.08), Vector3(hw, 0.03, 0.08), LEDC[st], 0.03)
	if st == "nerf":
		K.cbox(b, g, "vcolor", xf, Vector3(0, 1.12, -0.08), Vector3(0.1, 0.16, 0.38), "#ff8a1a", true)
	elif st == "mascot":
		# the cut-out panel standing proud of the left side (a plain black board with a red edge)
		K.cbox(b, g, "gi_k_black", xf, Vector3(-hw - 0.03, 1.1, 0.08), Vector3(0.04, 2.0, 0.55), "#ffffff")
		K.led(b, g, xf, Vector3(-hw - 0.03, 0.15, -0.2), Vector3(-hw - 0.03, 2.1, -0.2), "#ff2a3a", 0.02)
	elif st == "music":
		for sx in [-1, 1]:
			K.cbox(b, g, "vcolor", xf, Vector3(sx * 0.28, 1.1, -0.04), Vector3(0.12, 0.42, 0.05), ["#d8202a", "#2a5bff"][(sx + 1) / 2], true)
		var rng = RandomNumberGenerator.new(); rng.seed = 3
		K.plush(b, g, xf * Vector3(0, S.z, S.y * 0.5), 1.6, "#4a6a8a", rng)
	K.obst(b, xf, -hw, hw, 0, S.y, 0.15)

static func fill_mat(m, key, b):
	if key in ["body", "lit"]:
		return K.atlas_mat(m, b, "upright", key, 1.3, 0.4)
	return false
