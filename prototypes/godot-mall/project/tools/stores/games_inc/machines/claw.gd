## games, inc. M1/M3: the LED claw (design/storefronts/games-inc-2026.md; frames f041-f046, f055-f058,
## g002, IMG_4445). A white cabinet 0.82 x 0.86 x 2.05 m: a translucent lower body lit in the cabinet's
## colour with a big white rounded prize door and a card reader, a black control ledge, a glass prize box
## with LED-studded front posts and a prize pile inside, a white header with a lit "pill" marquee rimmed in
## the cabinet colour. opts {"color": 0..5} = green, pink, blue, red, violet, white (paint.py CLAW_COLS).
## Atlas tex/gi/m_claw.png (paint.py claw()); kit: machines/kit.gd.

const K = preload("res://tools/stores/games_inc/machines/kit.gd")
const W = 0.82
const D = 0.86
const H = 2.05
const NAMES = ["green", "pink", "blue", "red", "violet", "white"]
const LEDC = ["#3cff4a", "#ff4fa8", "#3b6bff", "#ff2a3a", "#a259ff", "#7fe6ff"]
const Y_LOW = 0.95     # top of the lower body
const Y_G1 = 1.72      # top of the glass
const Y_HD = 2.05

static func footprint(_opts = {}):
	return Vector2(W, D)

static func build(b, g, o, f, opts = {}):
	var xf = K.X(o, f)
	var ci = int(opts.get("color", 0)) % NAMES.size()
	var nm = NAMES[ci]
	var body = "gi_m_claw_body"
	var lit = "gi_m_claw_lit"
	var hw = W * 0.5
	# lower body: front and sides lit in the cabinet colour, back white
	K.tbox(b, g, lit, xf, Vector3(0, Y_LOW * 0.5, D * 0.5 + 0.02), Vector3(W, Y_LOW, D - 0.04),
		{"front": K.rg("claw", "lower_" + nm), "left": K.rg("claw", "side_" + nm), "right": K.rg("claw", "side_" + nm),
		 "back": K.rg("claw", "cab"), "top": null})
	# the control ledge: a black deck over the lower body's front
	K.tbox(b, g, body, xf, Vector3(0, Y_LOW + 0.03, 0.12), Vector3(W, 0.06, 0.24),
		{"top": K.rg("claw", "deck"), "front": K.rg("claw", "deck"), "left": K.rg("claw", "deck"), "right": K.rg("claw", "deck")})
	# joystick (dynamic, small)
	K.vcyl(b, g, "gi_k_chrome", xf, Vector3(-0.12, Y_LOW + 0.06, 0.12), 0.01, 0.01, 0.1, 8, false, true)
	b.cur_color = Color("#d01818")
	K.ell(b, g, "vcolor", xf * Vector3(-0.12, Y_LOW + 0.17, 0.12), Vector3(0.025, 0.025, 0.025), 8, 4)
	b.cur_color = Color.WHITE
	# the prize box: back panel with the pile, a sloped pile floor, four glass walls
	var zb = D - 0.04
	K.face(b, g, body, xf, [Vector3(-hw + 0.04, Y_LOW + 0.06, zb), Vector3(hw - 0.04, Y_LOW + 0.06, zb), Vector3(hw - 0.04, Y_G1, zb), Vector3(-hw + 0.04, Y_G1, zb)],
		Vector3(0, 0, -1), K.rg("claw", "pile"))
	K.face(b, g, body, xf, [Vector3(-hw + 0.04, Y_LOW + 0.06, 0.26), Vector3(hw - 0.04, Y_LOW + 0.06, 0.26), Vector3(hw - 0.04, Y_LOW + 0.34, zb), Vector3(-hw + 0.04, Y_LOW + 0.34, zb)],
		Vector3(0, 0.8, -0.6).normalized(), K.sub(K.rg("claw", "pile"), 0.0, 0.3, 0.6, 1.0))
	for q in [[Vector3(-hw + 0.03, Y_LOW + 0.06, 0.24), Vector3(hw - 0.03, Y_LOW + 0.06, 0.24), Vector3(0, 0, -1)],
			[Vector3(-hw + 0.03, Y_LOW + 0.06, zb), Vector3(-hw + 0.03, Y_LOW + 0.06, 0.24), Vector3(-1, 0, 0)],
			[Vector3(hw - 0.03, Y_LOW + 0.06, 0.24), Vector3(hw - 0.03, Y_LOW + 0.06, zb), Vector3(1, 0, 0)]]:
		K.face(b, g, "gi_k_glass", xf, [q[0], q[1], q[1] + Vector3(0, Y_G1 - Y_LOW - 0.06, 0), q[0] + Vector3(0, Y_G1 - Y_LOW - 0.06, 0)], q[2], Vector4(0, 0, 1, 1), true)
	# white corner posts, the front two studded with LEDs in the cabinet colour
	for sx in [-1, 1]:
		for zz in [0.24, zb]:
			K.tbox(b, g, body, xf, Vector3(sx * (hw - 0.025), (Y_LOW + Y_G1) * 0.5, zz), Vector3(0.05, Y_G1 - Y_LOW, 0.05), {"all": K.rg("claw", "post")})
		K.led(b, g, xf, Vector3(sx * (hw - 0.025), Y_LOW + 0.04, 0.21), Vector3(sx * (hw - 0.025), Y_G1 - 0.02, 0.21), LEDC[ci], 0.018)
	# the claw on its gantry (dynamic, small)
	K.cbox(b, g, "gi_k_chrome", xf, Vector3(0.05, Y_G1 - 0.04, 0.5), Vector3(W - 0.1, 0.03, 0.03), "#ffffff", true)
	K.vcyl(b, g, "gi_k_chrome", xf, Vector3(0.12, Y_G1 - 0.32, 0.5), 0.004, 0.004, 0.28, 4, false, true)
	K.vcyl(b, g, "gi_k_chrome", xf, Vector3(0.12, Y_G1 - 0.42, 0.5), 0.05, 0.02, 0.1, 6, true, true)
	# header box (white) and the lit pill marquee on its front, 1 cm proud
	K.tbox(b, g, body, xf, Vector3(0, (Y_G1 + Y_HD) * 0.5, D * 0.5), Vector3(W, Y_HD - Y_G1, D), {"all": K.rg("claw", "cab"), "bottom": K.rg("claw", "cab")})
	K.face(b, g, lit, xf, [Vector3(-hw + 0.03, Y_G1 + 0.03, -0.01), Vector3(hw - 0.03, Y_G1 + 0.03, -0.01), Vector3(hw - 0.03, Y_HD - 0.03, -0.01), Vector3(-hw + 0.03, Y_HD - 0.03, -0.01)],
		Vector3(0, 0, -1), K.rg("claw", "pill_" + nm))
	# the LED strip round the header's front edge
	K.led(b, g, xf, Vector3(-hw, Y_HD - 0.01, -0.005), Vector3(hw, Y_HD - 0.01, -0.005), LEDC[ci], 0.02)
	K.obst(b, xf, -hw, hw, 0, D, 0.12)

static func fill_mat(m, key, b):
	if key in ["body", "lit"]:
		return K.atlas_mat(m, b, "claw", key, 1.3, 0.35)
	return false
