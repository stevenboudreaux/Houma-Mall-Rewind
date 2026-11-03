## games, inc. M4/M6: the two-player coin pushers on the right wall (design/storefronts/games-inc-2026.md;
## M4 f012, f021-f024; M6 f029-f034). 1.95 x 1.25 x 2.4 m: a lower cabinet with two stations (tray,
## card reader, red button, ticket mouth), two lit playfield windows under a sloped glass hood, red LED
## strips up the front corners, a big topper translite (the footage's licensed character art becomes a
## generic burst), two chrome stools. opts {"style": 0 (royal blue, M4) | 1 (white/purple, M6)}.
## Atlas tex/gi/m_pusher.png (paint.py pusher()).

const K = preload("res://tools/stores/games_inc/machines/kit.gd")
const W = 1.95
const D = 1.25
const H = 2.4
const Y_LOW = 0.86
const Y_HOOD = 1.62
const BODY = ["#1f3aa8", "#f2f0f4"]
const LEDC = ["#ff2a3a", "#a259ff"]
const SEAT = ["#2a4fb8", "#2a4fb8"]

static func footprint(_opts = {}):
	return Vector2(W, D)

static func build(b, g, o, f, opts = {}):
	var xf = K.X(o, f)
	var s = int(opts.get("style", 0)) % 2
	var body = "gi_m_pusher_body"
	var lit = "gi_m_pusher_lit"
	var hw = W * 0.5
	var side = K.rg("pusher", "side%d" % s)
	K.tbox(b, g, body, xf, Vector3(0, Y_LOW * 0.5, D * 0.5 + 0.05), Vector3(W, Y_LOW, D - 0.1),
		{"front": K.rg("pusher", "lower%d" % s), "left": side, "right": side, "back": side, "top": null})
	# the coin ledge
	K.cbox(b, g, "vcolor", xf, Vector3(0, Y_LOW + 0.02, 0.18), Vector3(W, 0.04, 0.36), "#c7ccd6")
	# the two playfield windows (lit) on a slope, glass over them
	for k in 2:
		var x0 = -hw + 0.08 + k * (W * 0.5)
		var x1 = x0 + W * 0.5 - 0.16
		K.face(b, g, lit, xf, [Vector3(x0, Y_LOW + 0.05, 0.4), Vector3(x1, Y_LOW + 0.05, 0.4), Vector3(x1, Y_HOOD - 0.05, 0.75), Vector3(x0, Y_HOOD - 0.05, 0.75)],
			Vector3(0, 0.4, -0.9).normalized(), K.rg("pusher", "field%d" % s))
		K.face(b, g, "gi_k_glass", xf, [Vector3(x0, Y_LOW + 0.05, 0.36), Vector3(x1, Y_LOW + 0.05, 0.36), Vector3(x1, Y_HOOD, 0.7), Vector3(x0, Y_HOOD, 0.7)],
			Vector3(0, 0.4, -0.9).normalized(), Vector4(0, 0, 1, 1), true)
	# the hood body behind and around the windows
	K.tbox(b, g, body, xf, Vector3(0, (Y_LOW + Y_HOOD) * 0.5, 0.95), Vector3(W, Y_HOOD - Y_LOW, 0.5), {"left": side, "right": side, "back": side, "top": side, "front": null})
	for x in [-hw + 0.04, 0.0, hw - 0.04]:
		K.cbox(b, g, "vcolor", xf, Vector3(x, (Y_LOW + Y_HOOD) * 0.5, 0.55), Vector3(0.08, Y_HOOD - Y_LOW, 0.4), BODY[s])
	# the topper: a lit translite on a box across the top
	K.tbox(b, g, body, xf, Vector3(0, (Y_HOOD + H) * 0.5, 0.95), Vector3(W, H - Y_HOOD, 0.4), {"left": side, "right": side, "back": side, "top": side})
	K.face(b, g, lit, xf, [Vector3(-hw + 0.02, Y_HOOD + 0.02, 0.74), Vector3(hw - 0.02, Y_HOOD + 0.02, 0.74), Vector3(hw - 0.02, H - 0.02, 0.74), Vector3(-hw + 0.02, H - 0.02, 0.74)],
		Vector3(0, 0, -1), K.rg("pusher", "top%d" % s))
	# red (or violet) LED strips up the front corners and along the topper's edge
	for sx in [-1, 1]:
		K.led(b, g, xf, Vector3(sx * hw, 0.05, 0.1), Vector3(sx * hw, Y_HOOD, 0.1), LEDC[s], 0.03)
	K.led(b, g, xf, Vector3(-hw, H, 0.74), Vector3(hw, H, 0.74), LEDC[s], 0.03)
	K.led(b, g, xf, Vector3(-hw, Y_HOOD, 0.74), Vector3(hw, Y_HOOD, 0.74), LEDC[s], 0.03)
	# two stools
	for k in 2:
		K.stool(b, g, xf, Vector3(-hw * 0.5 + k * hw, 0, -0.35), SEAT[s])
	K.obst(b, xf, -hw, hw, 0, D, 0.12)

static func fill_mat(m, key, b):
	if key in ["body", "lit"]:
		return K.atlas_mat(m, b, "pusher", key, 1.3, 0.35)
	return false
