## games, inc. back-wall games (design/storefronts/games-inc-2026.md). opts {"style": ...}:
##  "alley" M25 (g004): one blue alley-roller lane, 0.9 x 2.7 x 2.2 m: an orange front panel with a card
##          reader, a wood-look rolling lane with green-lit gutters, a blue target hood with a red LED score.
##  "eyes"  M27 (g005): the big-eyed drop column, 0.8 x 0.9 x 2.5 m, with 15 / 40 / 25 value windows.
##  "quik"  M28 (g005-g006): "QUIK DROP", 0.7 x 0.8 x 2.4 m, its round red marquee on top.
## Atlas tex/gi/m_alley.png (paint.py alley()).

const K = preload("res://tools/stores/games_inc/machines/kit.gd")
const SIZE = {"alley": Vector3(0.9, 2.7, 2.2), "eyes": Vector3(0.8, 0.9, 2.5), "quik": Vector3(0.7, 0.8, 2.4)}

static func footprint(opts = {}):
	var s = SIZE[str(opts.get("style", "alley"))]
	return Vector2(s.x, s.y)

static func build(b, g, o, f, opts = {}):
	var xf = K.X(o, f)
	var st = str(opts.get("style", "alley"))
	var S = SIZE[st]
	var body = "gi_m_alley_body"
	var lit = "gi_m_alley_lit"
	var hw = S.x * 0.5
	var blue = K.sub(K.rg("alley", "front"), 0.0, 0.0, 0.05, 0.05)
	if st == "alley":
		# the low lane body (0..2.0), rising from 0.75 to 1.0, then the target hood (2.0..2.7)
		K.tbox(b, g, body, xf, Vector3(0, 0.4, 1.0), Vector3(S.x, 0.8, 2.0), {"front": K.rg("alley", "front"), "all": blue, "top": null})
		K.face(b, g, body, xf, [Vector3(-hw + 0.1, 0.8, 0.0), Vector3(hw - 0.1, 0.8, 0.0), Vector3(hw - 0.1, 1.0, 2.0), Vector3(-hw + 0.1, 1.0, 2.0)], Vector3(0, 0.99, -0.1).normalized(), K.rg("alley", "lane"))
		for sx in [-1, 1]:
			K.led(b, g, xf, Vector3(sx * (hw - 0.05), 0.82, 0.0), Vector3(sx * (hw - 0.05), 1.02, 2.0), "#3cff6a", 0.04)
		K.tbox(b, g, body, xf, Vector3(0, S.z * 0.5, 2.35), Vector3(S.x, S.z, 0.7), {"all": blue, "front": null})
		K.face(b, g, lit, xf, [Vector3(-hw, 1.0, 2.0), Vector3(hw, 1.0, 2.0), Vector3(hw, S.z, 2.0), Vector3(-hw, S.z, 2.0)], Vector3(0, 0, -1), K.rg("alley", "target"))
	else:
		K.tbox(b, g, body, xf, Vector3(0, S.z * 0.5, S.y * 0.5), Vector3(S.x, S.z, S.y), {"all": blue})
		K.face(b, g, lit, xf, [Vector3(-hw, 0.0, -0.01), Vector3(hw, 0.0, -0.01), Vector3(hw, S.z, -0.01), Vector3(-hw, S.z, -0.01)], Vector3(0, 0, -1), K.rg("alley", st))
		K.led(b, g, xf, Vector3(-hw, 0.02, -0.02), Vector3(hw, 0.02, -0.02), "#3cff6a" if st == "eyes" else "#ff2a3a", 0.03)
	K.obst(b, xf, -hw, hw, 0, S.y, 0.1)

static func fill_mat(m, key, b):
	if key in ["body", "lit"]:
		return K.atlas_mat(m, b, "alley", key, 1.3, 0.4)
	return false
