## games, inc. M8 and M30 (design/storefronts/games-inc-2026.md). opts {"kind": "twin" | "bikes"}.
## "twin" (M8, f035, f037): a twin sit-down racer, 2.2 x 1.9 x 2.0 m: a dark hood with two screens and a lit
## marquee, two red bucket seats on yellow/black bases, wheels on the dash. "bikes" (M30, g005-g006): two
## sit-on motorbike racers side by side, 2.2 x 2.3 x 1.9 m: yellow and black bikes with chrome engine
## covers in front of a dark screen cabinet. Atlas tex/gi/m_racer.png (paint.py racer()).

const K = preload("res://tools/stores/games_inc/machines/kit.gd")

static func footprint(opts = {}):
	return Vector2(2.2, 2.3) if opts.get("kind", "twin") == "bikes" else Vector2(2.2, 1.9)

static func build(b, g, o, f, opts = {}):
	var xf = K.X(o, f)
	var body = "gi_m_racer_body"
	var lit = "gi_m_racer_lit"
	var fp = footprint(opts)
	var hw = fp.x * 0.5
	var D = fp.y
	# the screen cabinet at the back (z D-0.75 .. D)
	var zc = D - 0.75
	K.tbox(b, g, body, xf, Vector3(0, 1.0, zc + 0.375), Vector3(fp.x, 2.0, 0.75), {"all": K.rg("racer", "base"), "front": null, "top": K.rg("racer", "base")})
	K.face(b, g, lit, xf, [Vector3(-hw, 0.9, zc), Vector3(hw, 0.9, zc), Vector3(hw, 1.75, zc), Vector3(-hw, 1.75, zc)], Vector3(0, 0, -1), K.rg("racer", "hood"))
	K.face(b, g, lit, xf, [Vector3(-hw, 1.75, zc), Vector3(hw, 1.75, zc), Vector3(hw, 2.0, zc), Vector3(-hw, 2.0, zc)], Vector3(0, 0, -1), K.rg("racer", "marq"))
	K.face(b, g, body, xf, [Vector3(-hw, 0.0, zc), Vector3(hw, 0.0, zc), Vector3(hw, 0.9, zc), Vector3(-hw, 0.9, zc)], Vector3(0, 0, -1), K.rg("racer", "base"))
	for k in 2:
		var x = -hw * 0.5 + k * hw
		if opts.get("kind", "twin") == "bikes":
			# a sit-on bike: yellow fairing and tank, black seat, chrome engine cover, handlebars
			K.tbox(b, g, body, xf, Vector3(x, 0.45, zc - 0.7), Vector3(0.42, 0.5, 1.3), {"all": K.rg("racer", "bike")})
			K.cbox(b, g, "vcolor", xf, Vector3(x, 0.78, zc - 0.95), Vector3(0.36, 0.14, 0.6), "#141414")
			K.cbox(b, g, "vcolor", xf, Vector3(x, 0.85, zc - 0.25), Vector3(0.46, 0.3, 0.35), "#ffd21a")
			K.cbox(b, g, "gi_k_chrome", xf, Vector3(x, 0.98, zc - 0.15), Vector3(0.62, 0.04, 0.04), "#ffffff", true)
			K.cbox(b, g, "gi_k_black", xf, Vector3(x, 0.08, zc - 0.7), Vector3(0.6, 0.16, 1.5), "#ffffff")
			K.led(b, g, xf, Vector3(x - 0.08, 0.6, zc - 1.36), Vector3(x + 0.08, 0.6, zc - 1.36), "#ff2a2a", 0.04)
		else:
			# a red bucket seat on a yellow base, a wheel on the dash
			K.tbox(b, g, body, xf, Vector3(x, 0.2, zc - 0.55), Vector3(0.8, 0.4, 1.1), {"all": K.rg("racer", "base")})
			K.tbox(b, g, body, xf, Vector3(x, 0.55, zc - 0.85), Vector3(0.55, 0.3, 0.5), {"all": K.rg("racer", "seat")})
			K.tbox(b, g, body, xf, Vector3(x, 0.95, zc - 1.05), Vector3(0.55, 0.75, 0.14), {"all": K.rg("racer", "seat")})
			K.vcyl(b, g, "gi_k_black", xf, Vector3(x, 0.9, zc - 0.15), 0.16, 0.16, 0.04, 14, true, true)
	K.obst(b, xf, -hw, hw, 0, D, 0.12)

static func fill_mat(m, key, b):
	if key in ["body", "lit"]:
		return K.atlas_mat(m, b, "racer", key, 1.2, 0.4)
	return false
