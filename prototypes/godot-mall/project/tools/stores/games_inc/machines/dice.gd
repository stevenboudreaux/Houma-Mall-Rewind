## games, inc. M5: the "MONOPOLY ROLL-N-GO"-type dice tower in the middle of the room
## (design/storefronts/games-inc-2026.md; f020, f024, f028-f031). 0.9 x 0.9 x 2.6 m: a lit front column
## (red header, BONUS 1000 TICKETS window, the 10 window, SWIPE CARD), black side pillars with readers,
## a big blue lit die in an open bay low down, a cyan-lit base. Atlas tex/gi/m_dice.png (paint.py dice()).

const K = preload("res://tools/stores/games_inc/machines/kit.gd")
const W = 0.9
const D = 0.9
const H = 2.6

static func footprint(_opts = {}):
	return Vector2(W, D)

static func build(b, g, o, f, opts = {}):
	var xf = K.X(o, f)
	var body = "gi_m_dice_body"
	var lit = "gi_m_dice_lit"
	var hw = 0.34
	# the column (0.68 wide) with its lit front
	K.tbox(b, g, body, xf, Vector3(0, H * 0.5 + 0.06, 0.5), Vector3(0.68, H - 0.12, 0.7), {"left": K.rg("dice", "side"), "right": K.rg("dice", "side"), "back": K.rg("dice", "side"), "top": K.rg("dice", "side"), "front": null})
	K.face(b, g, lit, xf, [Vector3(-hw, 0.12, 0.15), Vector3(hw, 0.12, 0.15), Vector3(hw, H, 0.15), Vector3(-hw, H, 0.15)], Vector3(0, 0, -1), K.rg("dice", "front"))
	# side pillars with the card readers
	for sx in [-1, 1]:
		K.tbox(b, g, body, xf, Vector3(sx * 0.4, 0.75, 0.35), Vector3(0.1, 1.5, 0.4), {"all": K.rg("dice", "pillar")})
	# the die in its bay (a glossy lit cube, turned)
	var dxf = xf * Transform3D(Basis(Vector3.UP, 0.5) * Basis(Vector3.RIGHT, 0.4), Vector3(0, 0.58, -0.08))
	K.tbox(b, g, lit, dxf, Vector3.ZERO, Vector3(0.36, 0.36, 0.36), {"all": K.rg("dice", "die"), "bottom": K.rg("dice", "die")})
	# base plinth with a cyan glow strip
	K.cbox(b, g, "gi_k_black", xf, Vector3(0, 0.06, 0.45), Vector3(W, 0.12, D), "#ffffff")
	K.led(b, g, xf, Vector3(-W * 0.5, 0.02, 0.0), Vector3(W * 0.5, 0.02, 0.0), "#2fe8ff", 0.03)
	K.obst(b, xf, -W * 0.5, W * 0.5, -0.3, D, 0.15)

static func fill_mat(m, key, b):
	if key in ["body", "lit"]:
		return K.atlas_mat(m, b, "dice", key, 1.3, 0.35)
	return false
