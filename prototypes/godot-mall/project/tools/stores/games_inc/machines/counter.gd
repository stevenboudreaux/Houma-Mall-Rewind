## games, inc. prize counter pieces, the "GALACTIC PRIZE PORTAL" (design/storefronts/games-inc-2026.md
## P1-P6; f017-f028). opts {"kind": ...}:
##  "case"      P4: a 6 ft glass showcase, 1.83 x 0.56 x 0.97 m: white base, lit glass box of small prizes,
##              LED edge light in opts "led" (pink / blue / white in the footage).
##  "counter"   P5: the black counter run, opts "length" x 0.6 x 0.97 m, with a register and a ticket eater.
##  "prizewall" P1: black slatwall shelving of small prizes, opts "length" x 0.45 x 2.2 m, a row of plush on
##              top, the GALACTIC PRIZE PORTAL panel (P2) and two TVs (P3) on the wall above it.
##  "kiosk"     P6: a card kiosk, 0.5 x 0.45 x 1.5 m: a black pedestal with a blue touch screen.
## Atlas tex/gi/m_counter.png (paint.py counter()).

const K = preload("res://tools/stores/games_inc/machines/kit.gd")

static func footprint(opts = {}):
	match str(opts.get("kind", "case")):
		"counter":
			return Vector2(float(opts.get("length", 2.8)), 0.6)
		"prizewall":
			return Vector2(float(opts.get("length", 8.0)), 0.45)
		"kiosk":
			return Vector2(0.5, 0.45)
	return Vector2(1.83, 0.56)

static func build(b, g, o, f, opts = {}):
	var xf = K.X(o, f)
	var kind = str(opts.get("kind", "case"))
	var fp = footprint(opts)
	var hw = fp.x * 0.5
	var body = "gi_m_counter_body"
	var lit = "gi_m_counter_lit"
	var blk = K.rg("counter", "black")
	match kind:
		"case":
			K.cbox(b, g, "vcolor", xf, Vector3(0, 0.2, fp.y * 0.5), Vector3(fp.x, 0.4, fp.y), "#eeeef0")
			K.face(b, g, lit, xf, [Vector3(-hw + 0.03, 0.4, fp.y - 0.06), Vector3(hw - 0.03, 0.4, fp.y - 0.06), Vector3(hw - 0.03, 0.95, fp.y - 0.06), Vector3(-hw + 0.03, 0.95, fp.y - 0.06)], Vector3(0, 0, -1), K.rg("counter", "case"))
			K.face(b, g, lit, xf, [Vector3(-hw + 0.03, 0.4, 0.06), Vector3(hw - 0.03, 0.4, 0.06), Vector3(hw - 0.03, 0.4, fp.y - 0.06), Vector3(-hw + 0.03, 0.4, fp.y - 0.06)], Vector3.UP, K.sub(K.rg("counter", "case"), 0, 0.6, 1, 1))
			K.tbox(b, g, "gi_k_glass", xf, Vector3(0, 0.685, fp.y * 0.5), Vector3(fp.x - 0.02, 0.57, fp.y - 0.02), {"all": Vector4(0, 0, 1, 1)}, true)
			var c = str(opts.get("led", "#3fd0ff"))
			for zz in [0.0, fp.y]:
				K.led(b, g, xf, Vector3(-hw, 0.97, zz), Vector3(hw, 0.97, zz), c, 0.025)
				K.led(b, g, xf, Vector3(-hw, 0.4, zz), Vector3(hw, 0.4, zz), c, 0.025)
			for sx in [-1, 1]:
				K.led(b, g, xf, Vector3(sx * hw, 0.4, 0.0), Vector3(sx * hw, 0.97, 0.0), c, 0.025)
			K.obst(b, xf, -hw, hw, 0, fp.y, 0.08)
		"counter":
			K.tbox(b, g, body, xf, Vector3(0, 0.47, fp.y * 0.5), Vector3(fp.x, 0.94, fp.y), {"all": blk})
			K.cbox(b, g, "gi_k_black", xf, Vector3(0, 0.955, fp.y * 0.5), Vector3(fp.x + 0.04, 0.03, fp.y + 0.06), "#ffffff")
			K.cbox(b, g, "gi_k_black", xf, Vector3(-hw * 0.4, 1.06, fp.y * 0.6), Vector3(0.36, 0.18, 0.3), "#ffffff", true)
			K.face(b, g, lit, xf, [Vector3(-hw * 0.4 - 0.15, 1.1, fp.y * 0.6 - 0.16), Vector3(-hw * 0.4 + 0.15, 1.1, fp.y * 0.6 - 0.16), Vector3(-hw * 0.4 + 0.15, 1.3, fp.y * 0.6 - 0.1), Vector3(-hw * 0.4 - 0.15, 1.3, fp.y * 0.6 - 0.1)], Vector3(0, 0, -1), K.rg("counter", "kiosk"), true)
			K.obst(b, xf, -hw, hw, 0, fp.y, 0.1)
		"prizewall":
			# the shelving face (repeat the prizes region every 2 m), its top plush row, the wall stuff above
			var n = max(1, int(round(fp.x / 2.0)))
			var seg = fp.x / n
			for k in n:
				var x0 = -hw + k * seg
				K.face(b, g, body, xf, [Vector3(x0, 0.1, 0.05), Vector3(x0 + seg, 0.1, 0.05), Vector3(x0 + seg, 2.0, 0.05), Vector3(x0, 2.0, 0.05)], Vector3(0, 0, -1), K.rg("counter", "prizes"))
			K.tbox(b, g, body, xf, Vector3(0, 1.05, 0.25), Vector3(fp.x, 2.1, 0.4), {"top": blk, "left": blk, "right": blk, "front": null, "back": null})
			K.cbox(b, g, "gi_k_black", xf, Vector3(0, 0.05, 0.2), Vector3(fp.x, 0.1, 0.4), "#ffffff")
			var rng = RandomNumberGenerator.new(); rng.seed = 41
			var cols = ["#f6d23a", "#5db5e8", "#79c66a", "#ff8fc8", "#8e6bd1", "#f3f1e8", "#f08a2a", "#3cc7b0", "#e94f6a"]
			var x = -hw + 0.2
			while x < hw - 0.2:
				var kk = rng.randf_range(0.55, 0.85)
				K.plush(b, g, xf * Vector3(x, 2.1, 0.22), kk, cols[rng.randi() % cols.size()], rng)
				x += 0.32 * kk + rng.randf_range(0.02, 0.08)
			# GALACTIC PRIZE PORTAL panel and the two TVs on the orange wall above the shelving
			var sx0 = float(opts.get("sign_at", -hw + 2.4))
			K.face(b, g, "gi_m_counter_sign", xf, [Vector3(sx0 - 1.0, 2.55, 0.08), Vector3(sx0 + 1.0, 2.55, 0.08), Vector3(sx0 + 1.0, 3.15, 0.08), Vector3(sx0 - 1.0, 3.15, 0.08)], Vector3(0, 0, -1), K.rg("counter", "sign"))
			for tx in opts.get("tvs", [-hw + 5.0, -hw + 6.6]):
				K.cbox(b, g, "gi_k_black", xf, Vector3(tx, 2.75, 0.1), Vector3(0.95, 0.56, 0.06), "#ffffff")
				K.face(b, g, lit, xf, [Vector3(tx - 0.44, 2.5, 0.065), Vector3(tx + 0.44, 2.5, 0.065), Vector3(tx + 0.44, 3.0, 0.065), Vector3(tx - 0.44, 3.0, 0.065)], Vector3(0, 0, -1), K.rg("counter", "tv"))
			K.obst(b, xf, -hw, hw, 0, fp.y, 0.05)
		"kiosk":
			K.tbox(b, g, body, xf, Vector3(0, 0.6, 0.25), Vector3(0.42, 1.2, 0.35), {"all": blk})
			K.tbox(b, g, body, xf, Vector3(0, 1.32, 0.22), Vector3(0.5, 0.36, 0.12), {"all": blk, "front": null})
			K.face(b, g, lit, xf, [Vector3(-0.22, 1.16, 0.15), Vector3(0.22, 1.16, 0.15), Vector3(0.22, 1.48, 0.15), Vector3(-0.22, 1.48, 0.15)], Vector3(0, 0, -1), K.rg("counter", "kiosk"))
			K.obst(b, xf, -hw, hw, 0, fp.y, 0.08)

static func fill_mat(m, key, b):
	if key in ["body", "lit"]:
		return K.atlas_mat(m, b, "counter", key, 1.2, 0.4)
	if key == "sign":
		# the neon panel glows harder than the TVs
		return K.atlas_mat(m, b, "counter", "lit", 2.2, 0.4)
	return false
