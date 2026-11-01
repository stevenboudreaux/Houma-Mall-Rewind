## The outside of the mall: wing 3, "Outside" (design/godot-exterior.md). Built by build_mall.gd
## with --wing=3 from exterior.json (tools/make_exterior.py: the building's outline from the 1995
## map, its doors, the lot's walk grid) and the Oct 23 2026 site visit (the report's shared
## exterior table: the masses, the lot panels, the palm drive, the Horton tank, the outparcels)
## with 1995-plausible skins where the 2026 ones are re-skins.
##
## Frame: metres, +x east (West Park Ave, the main entrance), +z south (Bayou Gardens Blvd),
## -z north (Armour Dr). Sears is the north box, Dillard's the south-east one, JCPenney the west one.
##
## Steven's decision (Oct 23): the Cucos neon goes on the east entrance's outside fascia (s43,
## where the gold fan is today), so it is built there, 2.2x the indoor sign.
##
## Everything here is in groups "ex_*": "ex_ground" takes a coarse lightmap texel, the rest a
## medium one (build_mall.gd). Trees, palms and the signs are dynamic (no lightmap).
const UP = Vector3.UP
const CU = preload("res://tools/stores/signs/cucos_sign.gd")
const MON = preload("res://tools/exterior/monuments.gd")
const Y26 = preload("res://tools/exterior/exterior_2026.gd")

# ---- heights (parapets, metres): the report's table
const H_DEFAULT = 6.5     # store backs, the east facade
const H_SOUTH_BACKS = 5.0 # the Concourse's south row, from the south entrance to Dillard's
const H_SEARS = 9.0
const H_CINEMA = 9.0
const H_WOOL = 9.0        # the taller red-brick block behind Woolworth
const H_JCP_FRONT = 7.5
const H_JCP_REAR = 9.5
const H_DILLARDS = 14.0
const H_CUCOS = 7.0
const H_KB = 7.0
const H_EAST_ENTRY = 7.0
const H_MAIN_ENTRY = 7.5
const H_SOUTH_PAV = 10.0
const H_UNITECH = 7.0

static var E = {}          # exterior.json
static var rng = RandomNumberGenerator.new()
static var trees = 0
static var YEAR = 1995     # --year=2026 builds the outside as filmed on Oct 23 2026 (exterior_2026.gd)
## The Bayou Gardens drive (Workstream F): the gap in the palm island in front of the south
## entrance, x0..x1, where the monument sign stands (tools/exterior/monuments.gd)
const BAYOU_DRIVE = [-150.0, -134.0]

# ------------------------------------------------------------------ materials
static func fill_mat(m, key, b):
	var tx = func(f, rough): m.albedo_texture = b.tex("ex/" + f + ".png"); m.roughness = rough
	match key:
		"brick_cream": tx.call("brick_cream", 0.85)
		"brick_salmon": tx.call("brick_salmon", 0.85)
		"brick_tan": tx.call("brick_tan", 0.9)
		"brick_red": tx.call("brick_red", 0.9)
		"brick_brown": tx.call("brick_brown", 0.9)
		"block_white": tx.call("block_white", 0.8)
		"stucco_white": tx.call("stucco_white", 0.9)
		"stucco_cream": tx.call("stucco_cream", 0.85)
		"stucco_peach": tx.call("stucco_peach", 0.85)
		"stucco_tan": tx.call("stucco_tan", 0.85)
		"aggregate": tx.call("aggregate", 0.95)
		"concrete": tx.call("concrete_panel", 0.9)
		"asphalt": tx.call("asphalt", 0.95)
		"mulch": tx.call("mulch", 1.0)
		"grass": tx.call("grass", 1.0)
		"chainlink":
			m.albedo_texture = b.tex("ex/chainlink.png"); m.roughness = 0.5; m.metallic = 0.4
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR; m.alpha_scissor_threshold = 0.5
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
		"coping": m.albedo_color = Color("#e8e4dc"); m.roughness = 0.6
		"coping_dark": m.albedo_color = Color("#4a4642"); m.roughness = 0.5; m.metallic = 0.3
		"soldier": m.albedo_color = Color("#3b2e28"); m.roughness = 0.8
		"peach_pier": m.albedo_color = Color("#e3b89a"); m.roughness = 0.8
		"cream_pier": m.albedo_color = Color("#efe6d2"); m.roughness = 0.75
		"white_wainscot": m.albedo_color = Color("#f2efe8"); m.roughness = 0.6
		"beige_door": m.albedo_color = Color("#c9bda4"); m.roughness = 0.5; m.metallic = 0.3
		"wall_pack": m.albedo_color = Color("#8a8580"); m.roughness = 0.5; m.metallic = 0.5
		"bollard_yellow": m.albedo_color = Color("#e9c21d"); m.roughness = 0.5
		"pipe_yellow": m.albedo_color = Color("#f0c419"); m.roughness = 0.4; m.metallic = 0.5
		"pipe_grey": m.albedo_color = Color("#9a9a96"); m.roughness = 0.45; m.metallic = 0.6
		"pole_white": m.albedo_color = Color("#eceae4"); m.roughness = 0.4; m.metallic = 0.3
		"pedestal": m.albedo_color = Color("#d9c23a"); m.roughness = 0.8
		"shoebox": m.albedo_color = Color("#3a3a38"); m.roughness = 0.5; m.metallic = 0.5
		"lamp":
			m.albedo_color = Color("#fff0c8"); m.emission_enabled = true; m.emission = Color("#ffc46a")
			m.emission_energy_multiplier = 3.0; m.set_meta("e_day", 0.0); m.set_meta("e_night", 3.0)
		"stripe_white": m.albedo_color = Color("#f4f2ec"); m.roughness = 0.9
		"stripe_yellow": m.albedo_color = Color("#e2c232"); m.roughness = 0.9
		"curb_yellow": m.albedo_color = Color("#e4c52c"); m.roughness = 0.8
		"curb": m.albedo_color = Color("#c8c4bc"); m.roughness = 0.9
		"tank_white": m.albedo_color = Color("#e4e3df"); m.roughness = 0.55; m.metallic = 0.4
		"tank_rust": m.albedo_color = Color("#8d6b4a"); m.roughness = 0.8; m.metallic = 0.2
		"steel": m.albedo_color = Color("#6f6f6c"); m.roughness = 0.5; m.metallic = 0.7
		"bronze": m.albedo_color = Color("#4a3a2a"); m.roughness = 0.4; m.metallic = 0.6
		"canopy_brown": m.albedo_color = Color("#3e2a1e"); m.roughness = 0.6
		"canopy_cream": m.albedo_color = Color("#f1ead8"); m.roughness = 0.75
		"soffit_white": m.albedo_color = Color("#f6f4ee"); m.roughness = 0.9
		"can":
			m.albedo_color = Color("#ffffff"); m.emission_enabled = true; m.emission = Color("#fff1d8")
			m.emission_energy_multiplier = 2.0; m.set_meta("e_day", 0.6); m.set_meta("e_night", 2.5)
		"glass":
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.albedo_color = Color(0.45, 0.55, 0.58, 0.45)
			m.roughness = 0.05; m.metallic = 0.3
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
		"glass_dark":
			m.albedo_color = Color("#2a3a40"); m.roughness = 0.08; m.metallic = 0.5
		"mullion": m.albedo_color = Color("#c4c6c2"); m.roughness = 0.35; m.metallic = 0.7
		"maroon": m.albedo_color = Color("#6b1a24"); m.roughness = 0.6
		"red_arcade": m.albedo_color = Color("#b4302e"); m.roughness = 0.75
		"coral": m.albedo_color = Color("#e07a5f"); m.roughness = 0.6
		"teal": m.albedo_color = Color("#1f7a74"); m.roughness = 0.6
		"awning_teal": m.albedo_color = Color("#1a6b66"); m.roughness = 0.85
		"planks": m.albedo_texture = b.tex("wood_dark.png"); m.roughness = 0.6; m.albedo_color = Color(1.35, 1.2, 1.0)
		"ivory": m.albedo_color = Color("#f4efe3"); m.roughness = 0.6
		"purple": m.albedo_color = Color("#5a2d7a"); m.roughness = 0.5
		"kb_tan": m.albedo_color = Color("#c9b48e"); m.roughness = 0.8
		"pebble": m.albedo_color = Color("#b9b2a4"); m.roughness = 0.95
		"trunk": m.albedo_color = Color("#6d5a3e"); m.roughness = 0.95
		"oak": m.albedo_color = Color("#3f6b2c"); m.roughness = 0.95
		"pine": m.albedo_color = Color("#2f5a2a"); m.roughness = 0.95
		"myrtle": m.albedo_color = Color("#d26b8c"); m.roughness = 0.95
		"holly": m.albedo_color = Color("#2e5a2f"); m.roughness = 0.9
		"podocarpus": m.albedo_color = Color("#3a6a3a"); m.roughness = 0.9
		"fence_wood": m.albedo_texture = b.tex("wood_dark.png"); m.roughness = 0.8; m.albedo_color = Color(1.1, 1.0, 0.9)
		"fence_black": m.albedo_color = Color("#1e1e1e"); m.roughness = 0.5; m.metallic = 0.4
		"roof_grey": m.albedo_color = Color("#8f8b84"); m.roughness = 0.95
		"roof_dark": m.albedo_color = Color("#4a4744"); m.roughness = 0.9
		"roof_rust": m.albedo_color = Color("#7a3f28"); m.roughness = 0.6; m.metallic = 0.3
		"signal": m.albedo_color = Color("#2a2a28"); m.roughness = 0.5
		"signal_red": m.albedo_color = Color("#ff2a1a"); m.emission_enabled = true; m.emission = Color("#ff3020"); m.emission_energy_multiplier = 2.0
		"cream_green_roof": m.albedo_color = Color("#2f6b45"); m.roughness = 0.6
		"water_blue": m.albedo_color = Color("#2b5ea8"); m.roughness = 0.6
		"vcolor": m.vertex_color_use_as_albedo = true; m.roughness = 0.7
		# ---- Workstream F (Nov 1 2026): sign faces, lace, lot paint, the 2026 skins
		# (tools/exterior/paint_signs.py paints the textures)
		"mon_1995", "mon_2026", "ua_head", "ua_lines", "banner_2026":
			m.albedo_texture = b.tex("ex/" + key + ".png"); m.roughness = 0.7
			m.emission_enabled = true; m.emission_texture = m.albedo_texture
			m.emission_energy_multiplier = 0.0; m.set_meta("e_day", 0.0); m.set_meta("e_night", 0.35 if key.begins_with("ua") else 0.0)
		"lace", "lace_bracket", "firelane_pink", "firelane_yellow", "ada", "tactile_mat":
			var f = {"lace": "lace_frieze", "lace_bracket": "lace_bracket", "firelane_pink": "firelane_pink",
				"firelane_yellow": "firelane_yellow", "ada": "ada_symbol", "tactile_mat": "tactile"}[key]
			m.albedo_texture = b.tex("ex/" + f + ".png"); m.roughness = 0.6 if key.begins_with("lace") else 0.9
			if key.begins_with("lace"):
				m.metallic = 0.4
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR; m.alpha_scissor_threshold = 0.5
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
		"acm_white": tx.call("acm_white", 0.35); m.metallic = 0.2
		"eifs_peach": tx.call("eifs_panel", 0.85); m.albedo_color = Color("#f2d3c4")
		"eifs_salmon": tx.call("eifs_panel", 0.85); m.albedo_color = Color("#e8b7a6")
		"eifs_tan": tx.call("eifs_panel", 0.85); m.albedo_color = Color("#d6bf98")
		"eifs_pav": tx.call("eifs_panel", 0.85); m.albedo_color = Color("#e5c8b6")
		"paint_cream": tx.call("brick_painted", 0.85); m.albedo_color = Color("#efe4cc")
		"paint_pink": tx.call("brick_painted", 0.85); m.albedo_color = Color("#ecc8bc")
		"paint_salmon": tx.call("brick_painted", 0.85); m.albedo_color = Color("#d99c84")
		"paint_white": tx.call("brick_painted", 0.85)
		"paint_black": tx.call("brick_painted", 0.8); m.albedo_color = Color("#2a2826")
		"curb_red": m.albedo_color = Color("#b8303a"); m.roughness = 0.8
		"curb_pink": m.albedo_color = Color("#d84a7c"); m.roughness = 0.8
		"ada_blue": m.albedo_color = Color("#2f6fc0"); m.roughness = 0.85
		"tile_dark": m.albedo_color = Color("#5e5650"); m.roughness = 0.4
		"tile_light": m.albedo_color = Color("#d9d2c4"); m.roughness = 0.4
		"stainless": m.albedo_color = Color("#c9cbcc"); m.roughness = 0.3; m.metallic = 0.8
		"black_steel": m.albedo_color = Color("#1c1c1e"); m.roughness = 0.5; m.metallic = 0.5
		"navy": m.albedo_color = Color("#1d2a4a"); m.roughness = 0.7
		"magenta": m.albedo_color = Color("#e20074"); m.roughness = 0.5
		"red_seal": m.albedo_color = Color("#b3202a"); m.roughness = 0.6
		"jcp_red": m.albedo_color = Color("#b0164a"); m.roughness = 0.5
		"soffit_terra": m.albedo_color = Color("#b98a62"); m.roughness = 0.9
		"gold": m.albedo_color = Color("#c9a24a"); m.roughness = 0.35; m.metallic = 0.8
		"led":
			m.albedo_color = Color("#ffffff"); m.emission_enabled = true; m.emission = Color("#f4f8ff")
			m.emission_energy_multiplier = 3.0; m.set_meta("e_day", 0.0); m.set_meta("e_night", 3.0)
		"neon_open":
			m.albedo_color = Color("#ff4060"); m.emission_enabled = true; m.emission = Color("#ff3050")
			m.emission_energy_multiplier = 2.0
		_:
			return false
	return true

# ------------------------------------------------------------------ helpers
static func V(a):
	return Vector3(a[0], 0, a[1])

## A textured wall quad from a to b (ground level up to top), facing n; the texture covers 2 m.
static func wall(b, g, mname, a, bb, n, y0, y1, scale = 0.5):
	b.quad(g, mname, [a + UP * y0, bb + UP * y0, bb + UP * y1, a + UP * y1], n, [], false, scale)

## A box along a run: from u0 to u1 along t, y0..y1 high, standing `out` proud of the wall, `deep`.
static func run_box(b, g, mname, a, t, n, u0, u1, y0, y1, out, deep, skip = []):
	var c = a + t * ((u0 + u1) * 0.5) + UP * ((y0 + y1) * 0.5) + n * (out - deep * 0.5)
	b.box(g, mname, c, b.abs_size(t, u1 - u0, y1 - y0, deep, n), Transform3D.IDENTITY, skip)

## A box turned yaw radians about its own centre (build_mall.gd's box turns about the origin).
static func rbox(b, g, mname, c, size, yaw):
	var bs = Basis(UP, yaw)
	b.box(g, mname, c, size, Transform3D(bs, c - bs * c))

static func tree_oak(b, at, size):
	trees += 1
	b.cyl("ex_props", "ex_trunk", at, 0.28, 0.2, size * 0.9, 8, false, false, true)
	b.force_dyn = true
	b.bush(at + UP * (size * 0.55), "leafy", size, 4)
	b.force_dyn = false
	b.obst(["rect", at.x - 0.5, at.z - 0.5, at.x + 0.5, at.z + 0.5])

static func tree_pine(b, at, hgt):
	trees += 1
	b.cyl("ex_props", "ex_trunk", at, 0.2, 0.12, hgt * 0.45, 6, false, false, true)
	b.cyl("ex_props", "ex_pine", at + UP * (hgt * 0.3), hgt * 0.17, 0.05, hgt * 0.7, 8, false, true, true)
	b.obst(["rect", at.x - 0.4, at.z - 0.4, at.x + 0.4, at.z + 0.4])

static func palm(b, at, hgt):
	trees += 1
	b.palm(at, hgt)
	b.obst(["rect", at.x - 0.3, at.z - 0.3, at.x + 0.3, at.z + 0.3])

static func shrub(b, at, mname, size):
	b.force_dyn = true
	b.bush(at, "leafy", size, 3)
	b.force_dyn = false

## A raised curbed island (yellow curb in the lot, grey at the roads) with mulch or lawn on top.
static func island(b, x0, z0, x1, z1, top = "ex_mulch", curb = "ex_curb_yellow"):
	var c = Vector3((x0 + x1) * 0.5, 0.08, (z0 + z1) * 0.5)
	b.box("ex_lot", curb, c, Vector3(x1 - x0, 0.16, z1 - z0), Transform3D.IDENTITY, ["-y", "+y"])
	b.quad("ex_lot", top, [Vector3(x0 + 0.15, 0.16, z0 + 0.15), Vector3(x1 - 0.15, 0.16, z0 + 0.15), Vector3(x1 - 0.15, 0.16, z1 - 0.15), Vector3(x0 + 0.15, 0.16, z1 - 0.15)], UP, [], false, 0.5)
	b.quad("ex_lot", curb, [Vector3(x0, 0.16, z0), Vector3(x1, 0.16, z0), Vector3(x1 - 0.15, 0.16, z0 + 0.15), Vector3(x0 + 0.15, 0.16, z0 + 0.15)], UP)
	b.quad("ex_lot", curb, [Vector3(x0, 0.16, z1), Vector3(x0 + 0.15, 0.16, z1 - 0.15), Vector3(x1 - 0.15, 0.16, z1 - 0.15), Vector3(x1, 0.16, z1)], UP)
	b.quad("ex_lot", curb, [Vector3(x0, 0.16, z0), Vector3(x0 + 0.15, 0.16, z0 + 0.15), Vector3(x0 + 0.15, 0.16, z1 - 0.15), Vector3(x0, 0.16, z1)], UP)
	b.quad("ex_lot", curb, [Vector3(x1, 0.16, z0), Vector3(x1, 0.16, z1), Vector3(x1 - 0.15, 0.16, z1 - 0.15), Vector3(x1 - 0.15, 0.16, z0 + 0.15)], UP)
	b.obst(["rect", x0, z0, x1, z1])

## A white stall stripe (the 1995 striping under today's yellow) painted just above the lot.
static func stripe(b, a, bb, w = 0.1, mname = ""):
	if mname == "":
		# 1995: the white grid (the ghost lines under today's paint); 2026: fresh yellow (4487 f034)
		mname = "ex_stripe_yellow" if YEAR == 2026 else "ex_stripe_white"
	var t = (bb - a).normalized()
	var s = Vector3(-t.z, 0, t.x) * (w * 0.5)
	b.quad("ex_paint", mname, [a - s + UP * 0.012, bb - s + UP * 0.012, bb + s + UP * 0.012, a + s + UP * 0.012], UP, [], true)

## A double row of stalls: the row runs from p along t for `len` metres; stalls either side,
## 2.7 m wide, 5.5 m deep (two rows back to back = 11 m).
static func stall_row(b, p, t, len):
	var s = Vector3(-t.z, 0, t.x)
	var n = int(len / 2.7)
	for i in n + 1:
		var q = p + t * (i * 2.7)
		stripe(b, q - s * 5.5, q + s * 5.5)
	stripe(b, p, p + t * (n * 2.7), 0.12)

## A lot light: a white tapered pole ~11 m on a square yellow pedestal, twin shoebox heads
## (the 2026 LED poles stand on the same pedestals; period heads here).
static func lot_pole(b, at, yaw, quad_heads = false):
	var g = "ex_props"
	if YEAR == 2026:
		led_pole(b, at, yaw, quad_heads)
		return
	b.box(g, "ex_pedestal", at + UP * 0.5, Vector3(0.8, 1.0, 0.8))
	b.cyl(g, "ex_pole_white", at + UP * 1.0, 0.16, 0.09, 10.5, 10, true)
	var d = Vector3(cos(yaw), 0, sin(yaw))
	for sd in [-1.0, 1.0]:
		var arm = at + UP * 11.2 + d * (sd * 0.9)
		rbox(b, g, "ex_pole_white", arm, Vector3(1.9, 0.12, 0.12), yaw)
		var head = at + UP * 11.1 + d * (sd * 1.9)
		rbox(b, g, "ex_shoebox", head, Vector3(0.9, 0.22, 0.5), yaw)
		b.quad(g, "ex_lamp", [head + Vector3(-0.4, -0.112, -0.2), head + Vector3(0.4, -0.112, -0.2), head + Vector3(0.4, -0.112, 0.2), head + Vector3(-0.4, -0.112, 0.2)], -UP)
		b.tag(b.add_omni(head - UP * 0.5, 5.0, 30.0, Color("#FF9F45")), "night")
	b.obst(["rect", at.x - 0.5, at.z - 0.5, at.x + 0.5, at.z + 0.5])

## The 2026 lot light (4487 f030, 4488 f004): the same white tapered pole on its yellow pedestal,
## two up-curved "Y" arms with flat rectangular LED heads at ~10.5 m; nearer the building a second
## tier (4 heads). White light at night.
static func led_pole(b, at, yaw, quad_heads):
	var g = "ex_props"
	b.box(g, "ex_pedestal", at + UP * 0.5, Vector3(0.8, 1.0, 0.8))
	b.cyl(g, "ex_pole_white", at + UP * 1.0, 0.16, 0.09, 10.2, 10, true)
	var tiers = [[yaw, 10.6]]
	if quad_heads:
		tiers.append([yaw + PI * 0.5, 9.4])
	for tr in tiers:
		var d = Vector3(cos(tr[0]), 0, sin(tr[0]))
		for sd in [-1.0, 1.0]:
			# the arm: two segments rising outward, like a shallow curve
			var p0 = at + UP * (tr[1] - 0.6)
			var p1 = p0 + d * (sd * 0.7) + UP * 0.45
			var p2 = p1 + d * (sd * 0.8) + UP * 0.15
			for seg in [[p0, p1], [p1, p2]]:
				var m = (seg[0] + seg[1]) * 0.5
				var L = seg[0].distance_to(seg[1])
				var dir = (seg[1] - seg[0]).normalized()
				var bs = Basis(dir, dir.cross(Vector3(-d.z, 0, d.x)).normalized(), Vector3(-d.z, 0, d.x)).orthonormalized()
				b.box(g, "ex_pole_white", Vector3.ZERO, Vector3(L, 0.09, 0.09), Transform3D(bs, m))
			var head = p2 + d * (sd * 0.35)
			rbox(b, g, "ex_pole_white", head, Vector3(0.75, 0.08, 0.38), tr[0])
			b.quad(g, "ex_led", [head + Vector3(-0.3, -0.042, -0.15), head + Vector3(0.3, -0.042, -0.15), head + Vector3(0.3, -0.042, 0.15), head + Vector3(-0.3, -0.042, 0.15)], -UP)
			b.tag(b.add_omni(head - UP * 0.5, 4.0, 30.0, Color("#F2F4FF")), "night")
	b.obst(["rect", at.x - 0.5, at.z - 0.5, at.x + 0.5, at.z + 0.5])

## A beige steel service door with a wall pack over it, flat on the wall at u along the run.
static func service_door(b, g, a, t, n, u, hood = false):
	run_box(b, g, "ex_beige_door", a, t, n, u - 0.5, u + 0.5, 0.0, 2.15, 0.03, 0.03)
	run_box(b, g, "ex_wall_pack", a, t, n, u - 0.18, u + 0.18, 2.6, 2.85, 0.25, 0.25)
	if hood:
		run_box(b, g, "ex_coping_dark", a, t, n, u - 0.8, u + 0.8, 2.3, 2.42, 0.6, 0.6)

static func bollard(b, at):
	b.cyl("ex_props", "ex_bollard_yellow", at, 0.1, 0.1, 1.0, 8, true)

# ------------------------------------------------------------------ the building
## What a stretch of wall looks like, by the store behind it and the side it faces.
static func skin(seg):
	var nm = seg.name
	var side = seg.side
	var st = seg.store
	if nm == "SEARS" or st == "H1a" and side == "N":
		return {"mat": "ex_block_white", "h": H_SEARS}
	if nm == "DILLARD'S":
		return {"mat": "ex_stucco_peach", "h": H_DILLARDS}
	if nm == "JCPENNEY":
		return {"mat": "ex_brick_cream", "h": H_JCP_FRONT if side == "W" else H_JCP_REAR}
	if nm == "SOUTHLAND CINEMA":
		return {"mat": "ex_brick_salmon", "h": H_CINEMA}
	if nm == "WOOLWORTH":
		return {"mat": "ex_brick_red", "h": H_WOOL}
	if nm == "CUCOS BORDER CAFE":
		# 2026: The Red Seal's white heavy skip-trowel stucco over the brick (4493 f033-044)
		return {"mat": "ex_stucco_white" if YEAR == 2026 else "ex_stucco_tan", "h": H_CUCOS}
	if nm == "K&B":
		return {"mat": "ex_kb_tan", "h": H_KB}
	# Workstream F: the north returns beside the two Sears-hall exits are the Sears box's white
	# painted walls (4406 f031-035: the east entrance "recessed between the Red Seal's black brick
	# pier and the white Sears box", a charcoal eyebrow band; 4416 f002: the cinema-side exit's left
	# return is white-painted brick)
	if side == "N" and abs(seg.a[1] + 96.0) < 0.01 and (seg.a[0] >= 30 or seg.a[0] <= -76):
		return {"mat": "ex_block_white", "h": H_DEFAULT, "eyebrow": seg.a[0] >= 30}
	if nm == "EXIT" and seg.a[0] > 30 and seg.a[1] < -80:
		return {"mat": "ex_stucco_peach", "h": H_EAST_ENTRY}
	if nm == "EXIT" and seg.a[0] < -70:
		return {"mat": "ex_brick_tan", "h": H_DEFAULT}       # the cinema-wing exit: buff brick returns
	if nm == "EXIT":
		return {"mat": "ex_stucco_cream", "h": H_SOUTH_PAV}   # the south pavilion
	if nm == "MAIN ENTRANCE":
		return {"mat": "ex_stucco_cream", "h": H_MAIN_ENTRY}
	# Workstream F's filled notches (tools/exterior/wall_fixes.py): the trash / transformer bay is
	# tan brick (4406 f011-015); the link beside the south pavilion cream stucco (4489 f035)
	if nm == "SERVICE BAY" or (st == "fix_east_facade" and in_bay(seg)):
		return {"mat": "ex_brick_brown", "h": H_DEFAULT}
	if nm == "LINK":
		return {"mat": "ex_stucco_cream" if YEAR != 2026 else "ex_eifs_pav", "h": 8.0}
	# the Concourse's south row backs: a blank 5 m wall; the Dillard's wing's rear lane too
	if side == "S" and seg.a[1] >= 96 or nm in ["WESLEY AUSTIN", "TERREBONNE GENERAL OUTREACH", "MEN", "WOMEN", "ZALES"] or st == "H7":
		return {"mat": "ex_brick_tan", "h": H_SOUTH_BACKS}
	# the east facade (x >= 30, facing the front lot): cream pilasters, tan panels, white wainscot
	if seg.a[0] >= 30 and side in ["E", "N", "S"] and seg.a[1] > -60:
		return {"mat": "ex_stucco_tan", "h": H_DEFAULT, "panels": true}
	return {"mat": "ex_brick_tan", "h": H_DEFAULT}

## The rear service lane behind the Dillard's wing: the walls round the pocket and alley between
## the Concourse's back row, the restrooms and Dillard's (x -44..-18, z 68..98), not Dillard's own.
static func rear_lane(seg):
	if seg.name == "DILLARD'S":
		return false
	var m = (V(seg.a) + V(seg.b)) * 0.5
	return m.x > -44.0 and m.x < -18.0 and m.z > 68.0 and m.z < 98.0

## A wall run inside the east facade's trash bay (exterior.json "bay").
static func in_bay(seg):
	var r = E.get("bay", [])
	if r.size() < 4:
		return false
	var m = (V(seg.a) + V(seg.b)) * 0.5
	return m.x >= r[0] - 0.01 and m.x <= r[2] + 0.01 and m.z >= r[1] - 0.01 and m.z <= r[3] + 0.01

static func shell(b):
	var g = "ex_shell"
	for seg in E.segments:
		var a = V(seg.a); var bb = V(seg.b); var n = V(seg.n)
		var t = (bb - a).normalized(); var Ln = a.distance_to(bb)
		var sk = skin(seg)
		var h = sk.h
		if YEAR == 2026 and seg.side == "S" and V(seg.a).z >= 96.0 and seg.name != "DILLARD'S" and h <= 5.5:
			# 2026: the low wing wall in two-tone EIFS, pale peach over deeper salmon split at 2.2 m,
			# thick cream coping, diamond wall-packs every ~10 m (4489 f059-f069)
			wall(b, g, "ex_eifs_salmon", a, bb, n, 0.0, 2.2)
			wall(b, g, "ex_eifs_peach", a, bb, n, 2.2, h)
			run_box(b, g, "ex_coping", a, t, n, 0.0, Ln, 2.18, 2.22, 0.02, 0.02)
			var kw = 5.0
			while kw < Ln - 1.0:
				run_box(b, g, "ex_white_wainscot", a, t, n, kw - 0.2, kw + 0.2, h - 1.0, h - 0.6, 0.18, 0.18)
				kw += 10.0
		elif rear_lane(seg):
			# the rear service lane behind the Dillard's wing (4490 f006-012): painted brick in three
			# bands, a darker salmon base, a light-pink middle, a cream top under the coping, thin
			# reveals between (the paint is today's; 1995 the same, a GUESS)
			wall(b, g, "ex_paint_salmon", a, bb, n, 0.0, 1.6)
			wall(b, g, "ex_paint_pink", a, bb, n, 1.6, 3.6)
			wall(b, g, "ex_paint_cream", a, bb, n, 3.6, h)
			run_box(b, g, "ex_coping", a, t, n, 0.0, Ln, 1.58, 1.62, 0.02, 0.02)
			run_box(b, g, "ex_coping", a, t, n, 0.0, Ln, 3.58, 3.62, 0.02, 0.02)
			var k2 = 6.0
			while k2 < Ln - 1.0:
				run_box(b, g, "ex_white_wainscot", a, t, n, k2 - 0.12, k2 + 0.12, 0.0, h - 0.3, 0.14, 0.12)
				k2 += 9.0
		else:
			wall(b, g, sk.mat, a, bb, n, 0.0, h)
		if sk.get("eyebrow", false):
			run_box(b, g, "ex_coping_dark", a, t, n, 0.0, Ln, 3.3, 3.6, 0.5, 0.5)
		# coping
		run_box(b, g, "ex_coping" if sk.mat != "ex_brick_red" else "ex_coping_dark", a, t, n, 0.0, Ln, h - 0.08, h + 0.1, 0.12, 0.6)
		if sk.has("panels"):
			east_panels(b, g, a, t, n, Ln, h)
		elif sk.mat == "ex_brick_tan" and h > 6.0:
			# store backs: dark soldier-course line at ~4.7 m, peach pilasters / downspouts every ~8 m
			run_box(b, g, "ex_soldier", a, t, n, 0.0, Ln, 4.6, 4.85, 0.015, 0.015)
			var k = 8.0
			while k < Ln - 2.0:
				run_box(b, g, "ex_peach_pier", a, t, n, k - 0.25, k + 0.25, 0.0, h - 0.3, 0.14, 0.14)
				b.cyl(g, "ex_pipe_grey", a + t * (k + 0.5) + n * 0.1, 0.06, 0.06, h - 0.4, 6, false)
				k += 8.0
	roofs(b)
	masses(b)

## The east facade's panel rhythm (main entrance to Cucos, 4486/4492): cream pilasters every
## 4 m with recessed ~4 x 4 m panels between them and a white wainscot ~1 m. 1995 wore it in
## other finishes (report: "panel rhythm likely original; finishes re-skinned").
static func east_panels(b, g, a, t, n, Ln, h):
	run_box(b, g, "ex_white_wainscot", a, t, n, 0.0, Ln, 0.0, 1.0, 0.06, 0.06)
	var cnt = max(1, int(round(Ln / 4.0)))
	var w = Ln / cnt
	for i in cnt + 1:
		var u = clamp(i * w, 0.2, Ln - 0.2)
		run_box(b, g, "ex_cream_pier", a, t, n, u - 0.2, u + 0.2, 0.0, h - 0.6, 0.2, 0.2)
	# the cream parapet band with a stepped cornice over the tan field
	run_box(b, g, "ex_cream_pier", a, t, n, 0.0, Ln, h - 0.6, h, 0.2, 0.2)
	run_box(b, g, "ex_cream_pier", a, t, n, 0.0, Ln, h - 1.1, h - 0.6, 0.1, 0.1)

## The roof: one slab per footprint rectangle at the low parapet height, grey built-up roofing.
static func roofs(b):
	for r in E.roofs:
		var y = 6.0
		b.quad("ex_roof", "ex_roof_grey", [Vector3(r[0], y, r[1]), Vector3(r[2], y, r[1]), Vector3(r[2], y, r[3]), Vector3(r[0], y, r[3])], UP, [], false, 0.1)
	for s in E.standalone:
		var r = s.rect
		var y = H_UNITECH
		# Unitech: "a separate long low white warehouse box" (4486 f010, f072)
		b.box("ex_shell", "ex_block_white", Vector3((r[0] + r[2]) * 0.5, y * 0.5, (r[1] + r[3]) * 0.5), Vector3(r[2] - r[0], y, r[3] - r[1]), Transform3D.IDENTITY, ["-y"])
		if YEAR == 2026:
			b.label("UNITECH", "sans", "#1d2a4a", Vector3((r[0] + r[2]) * 0.5, y - 1.4, r[3] + 0.08), Vector3(0, 0, 1), 10.0, 1.1)
		b.box("ex_shell", "ex_coping", Vector3((r[0] + r[2]) * 0.5, y + 0.05, (r[1] + r[3]) * 0.5), Vector3(r[2] - r[0] + 0.2, 0.12, r[3] - r[1] + 0.2))
		b.obst(["rect", r[0], r[1], r[2], r[3]])

## The taller masses stand above the low roof: Sears, Dillard's, JCPenney's rear block, the cinema
## auditorium box, the Woolworth block, the south pavilion. Their roofs and inner sides.
static func masses(b):
	var g = "ex_shell"
	var M = [
		["ex_block_white", -40.0, -134.0, 30.0, -96.0, H_SEARS],
		["ex_block_white", -76.0, -96.0, -40.0, -86.0, H_SEARS],     # the Sears hall's north wall is part of the box
		["ex_stucco_peach", -38.0, 80.0, 30.0, 118.0, H_DILLARDS],
		["ex_brick_cream", -202.0, 32.0, -154.0, 92.0, H_JCP_REAR],   # to z 92: wall_fixes F3
		["ex_brick_salmon", -70.0, -86.0, -46.0, -64.0, H_CINEMA],
		["ex_brick_red", -74.0, -14.0, -10.0, 22.0, H_WOOL],
		["ex_stucco_cream", -146.0, 88.0, -138.0, 92.0, H_SOUTH_PAV]]
	for m in M:
		var c = Vector3((m[1] + m[3]) * 0.5, (6.0 + m[5]) * 0.5, (m[2] + m[4]) * 0.5)
		b.box(g, m[0], c, Vector3(m[3] - m[1], m[5] - 6.0, m[4] - m[2]), Transform3D.IDENTITY, ["-y", "+y"])
		b.quad("ex_roof", "ex_roof_grey", [Vector3(m[1], m[5], m[2]), Vector3(m[3], m[5], m[2]), Vector3(m[3], m[5], m[4]), Vector3(m[1], m[5], m[4])], UP, [], false, 0.1)
	# rooftop units
	rng.seed = 7
	for r in E.roofs:
		if r[2] - r[0] > 20 and r[3] - r[1] > 10:
			for i in int((r[2] - r[0]) * (r[3] - r[1]) / 600.0):
				var p = Vector3(rng.randf_range(r[0] + 4, r[2] - 4), 6.0, rng.randf_range(r[1] + 4, r[3] - 4))
				b.box(g, "ex_wall_pack", p + UP * 0.6, Vector3(2.4, 1.2, 1.6))

# ------------------------------------------------------------------ the special fronts
static func fronts(b):
	east_entrance(b)
	if YEAR == 2026:
		Y26.main_entrance(b)        # today's porte-cochere, T-Mobile, Shoe Dept. (exterior_2026.gd)
	else:
		main_entrance(b)
	south_entrance(b)
	cinema_exit(b)
	cinema_box(b)
	kb_bay(b)
	cucos(b)
	jcpenney(b)
	dillards(b)
	sears_dock(b)
	store_backs(b)

## The east entrance (s43, the Sears hall's east end): peach fascia with the Cucos neon where the
## gold fan is today (Steven, Oct 23), a dark-brown curved eyebrow canopy ~8 m, a 2-tier storefront
## with 4 glass doors (4406 f038-040).
static func east_entrance(b):
	var g = "ex_entry"
	var a = Vector3(40, 0, -96); var bb = Vector3(40, 0, -86)
	var n = Vector3(1, 0, 0); var t = Vector3(0, 0, 1); var Ln = 10.0
	# the storefront: a bronze-mullioned curtain wall, doors below the transom
	for i in 5:
		run_box(b, g, "ex_bronze", a, t, n, 1.0 + i * 2.0 - 0.05, 1.0 + i * 2.0 + 0.05, 0.0, 3.4, 0.0, 0.14)
	run_box(b, g, "ex_bronze", a, t, n, 1.0, 9.0, 2.35, 2.5, 0.0, 0.14)
	run_box(b, g, "ex_bronze", a, t, n, 1.0, 9.0, 3.4, 3.55, 0.0, 0.14)
	for i in 4:
		run_box(b, g, "ex_bronze", a, t, n, 1.1 + i * 2.0, 1.1 + i * 2.0 + 0.08, 0.0, 2.35, -0.02, 0.05)
		run_box(b, g, "ex_bronze", a, t, n, 2.9 + i * 2.0 - 0.08, 2.9 + i * 2.0, 0.0, 2.35, -0.02, 0.05)
		run_box(b, g, "ex_bronze", a, t, n, 1.1 + i * 2.0, 2.9 + i * 2.0, 0.0, 0.25, -0.02, 0.05)
	b.quad("ex_glass", "ex_glass", [a + t * 1.0 + n * 0.02, a + t * 9.0 + n * 0.02, a + t * 9.0 + n * 0.02 + UP * 3.4, a + t * 1.0 + n * 0.02 + UP * 3.4], n, [], true)
	# the eyebrow canopy: dark brown, curved in section, 8 m wide, 2.2 m out
	for k in 8:
		var f0 = float(k) / 8.0; var f1 = float(k + 1) / 8.0
		var y0 = 3.7 + 0.9 * sin(f0 * PI * 0.5); var y1 = 3.7 + 0.9 * sin(f1 * PI * 0.5)
		var o0 = 2.2 * (1.0 - cos(f0 * PI * 0.5)); var o1 = 2.2 * (1.0 - cos(f1 * PI * 0.5))
		var p0 = a + t * 1.0 + n * (2.2 - o0) + UP * y0
		var p1 = a + t * 9.0 + n * (2.2 - o0) + UP * y0
		var p2 = a + t * 9.0 + n * (2.2 - o1) + UP * y1
		var p3 = a + t * 1.0 + n * (2.2 - o1) + UP * y1
		var nn = (n * (y1 - y0) + UP * (o1 - o0)).normalized()
		b.quad(g, "ex_canopy_brown", [p0, p1, p2, p3], nn)
		b.quad(g, "ex_soffit_white", [p3, p2, p1, p0], -nn)
	for k in 2:
		var u = 1.0 if k == 0 else 9.0
		var pts = PackedVector2Array()
		for i in 9:
			var f = float(i) / 8.0
			pts.append(Vector2(2.2 - 2.2 * (1.0 - cos(f * PI * 0.5)), 3.7 + 0.9 * sin(f * PI * 0.5)))
		pts.append(Vector2(0.0, 3.7))
		b.poly(g, "ex_canopy_brown", pts, a + t * u, n, UP, t * (-1.0 if k == 0 else 1.0))
	# the fascia's cream band and the neon, centred over the doors
	run_box(b, g, "ex_cream_pier", a, t, n, 0.0, Ln, H_EAST_ENTRY - 0.5, H_EAST_ENTRY, 0.12, 0.12)
	var c = a + t * 5.0 + UP * 3.95 + n * 0.02
	if YEAR == 2026:
		# today: the gold art-deco fan and two small diamonds on the peach fascia (4406 f038-040)
		Y26.fan_ornament(b, c + UP * 1.4, n, t)
	else:
		CU.build(b, "ex_cucos_neon", "res://tools/stores/signs/cu_sign.json", c, n, 2.2)
	# daylight cans in the soffit, a warm spot on the doors at night
	for i in 3:
		b.tag(b.add_spot(a + t * (2.5 + i * 2.5) + n * 1.0 + UP * 3.6, -UP, 1.5, 6.0, 60.0, Color("#FFE6C2")), "night")

## The main entrance (s39, West Park Ave): a 2000s porte-cochere today — not copied. A plain 1995
## form until Steven finds a photo: a flat canopy on square columns, a glass storefront with two
## door pairs, "SOUTHLAND MALL" on the fascia (design/godot-exterior.md: a placeholder).
static func main_entrance(b):
	var g = "ex_entry"
	var a = Vector3(44, 0, -6); var n = Vector3(1, 0, 0); var t = Vector3(0, 0, 1); var Ln = 12.0
	for i in 7:
		run_box(b, g, "ex_bronze", a, t, n, 1.0 + i * (10.0 / 6.0) - 0.05, 1.0 + i * (10.0 / 6.0) + 0.05, 0.0, 4.0, 0.0, 0.14)
	run_box(b, g, "ex_bronze", a, t, n, 1.0, 11.0, 2.4, 2.55, 0.0, 0.14)
	run_box(b, g, "ex_bronze", a, t, n, 1.0, 11.0, 4.0, 4.15, 0.0, 0.14)
	b.quad("ex_glass", "ex_glass", [a + t * 1.0 + n * 0.02, a + t * 11.0 + n * 0.02, a + t * 11.0 + n * 0.02 + UP * 4.0, a + t * 1.0 + n * 0.02 + UP * 4.0], n, [], true)
	# the canopy: a flat slab 6 m out on four square columns
	var slab = a + t * 6.0 + n * 3.0 + UP * 4.6
	b.box(g, "ex_cream_pier", slab, Vector3(6.4, 0.6, 14.0))
	b.box(g, "ex_soffit_white", slab - UP * 0.31, Vector3(6.2, 0.02, 13.8), Transform3D.IDENTITY, ["+y"])
	for p in [Vector3(49.5, 0, -5.4), Vector3(49.5, 0, 5.4)]:
		b.box(g, "ex_cream_pier", p + UP * 2.15, Vector3(0.7, 4.3, 0.7))
		b.obst(["rect", p.x - 0.4, p.z - 0.4, p.x + 0.4, p.z + 0.4])
	for i in 3:
		b.tag(b.add_spot(a + t * (3.0 + i * 3.0) + n * 3.0 + UP * 4.25, -UP, 1.5, 7.0, 60.0, Color("#FFE6C2")), "night")
	b.label("SOUTHLAND MALL", "serif", "#4a3a2a", a + t * 6.0 + UP * 6.3 + n * 0.08, n, 9.0, 0.75)
	b.label("SOUTHLAND MALL", "serif", "#f4efe3", slab + n * 3.21 + UP * 0.0, n, 5.5, 0.4)

## The south entrance (s55, Bayou Gardens): a pavilion ~10 m with a thin white flat cornice slab
## overhanging 1.2–1.5 m, cream pilasters, a deep porch with the doors turned 90 degrees inside it,
## a drop-off bulb (4489 f034, f039). EIFS today; the mass and position are original.
static func south_entrance(b):
	# Workstream F: the pavilion projects past the low wing wall with its porch (4489 f031-f040:
	# "~6 m wide x ~4 m clear x ~5-6 m deep loggia"); until Nov 1 it stood flush with the doors
	# and the drop-off bulb sat against it. Both years have the porch (the mass and position are
	# original); 2026 wears today's peach EIFS and dark tile bands, 1995 cream (a GUESS).
	var g = "ex_entry"
	var y26 = YEAR == 2026
	var wallm = "ex_eifs_pav" if y26 else "ex_stucco_cream"
	var pier = "ex_cream_pier"
	var a = Vector3(-146, 0, 92); var n = Vector3(0, 0, 1); var t = Vector3(1, 0, 0); var Ln = 8.0
	var z1 = 99.0                                   # the porch front
	var x0 = -147.2; var x1 = -136.8                # the pavilion's sides
	var top = H_SOUTH_PAV
	# the side walls of the porch, full height, and the block over it
	for xs in [[x0, x0 + 1.2], [x1 - 1.2, x1]]:
		b.box(g, wallm, Vector3((xs[0] + xs[1]) * 0.5, top * 0.5, (92.0 + z1) * 0.5), Vector3(xs[1] - xs[0], top, z1 - 92.0), Transform3D.IDENTITY, ["-y"])
		b.obst(["rect", xs[0], 92.0, xs[1], z1])
	b.box(g, wallm, Vector3((x0 + x1) * 0.5, (4.6 + top) * 0.5, (92.0 + z1) * 0.5), Vector3(x1 - x0 - 2.4, top - 4.6, z1 - 92.0), Transform3D.IDENTITY, ["-y"])
	b.quad(g, wallm, [Vector3(x0 + 1.2, 4.6, 92.0), Vector3(x1 - 1.2, 4.6, 92.0), Vector3(x1 - 1.2, 4.6, z1), Vector3(x0 + 1.2, 4.6, z1)], -UP)
	# the two big square pilasters on the front corners, banded dark at the base (3 dark tile bands
	# in 2026, 4489 f039; one dark base band in 1995)
	for px in [x0 + 0.6, x1 - 0.6]:
		var pc = Vector3(px, 0, z1 + 0.15)
		b.box(g, pier, pc + UP * ((top - 0.4) * 0.5), Vector3(1.3, top - 0.4, 0.9))
		if y26:
			for k in 3:
				b.box(g, "ex_tile_dark", pc + UP * (0.25 + k * 0.85), Vector3(1.34, 0.45, 0.94))
		else:
			b.box(g, "ex_coping_dark", pc + UP * 0.5, Vector3(1.34, 1.0, 0.94))
		# the narrow slot near the top and the white crown cap
		b.box(g, "ex_coping_dark", pc + UP * (top - 1.6) + Vector3(0, 0, 0.46), Vector3(0.18, 1.6, 0.02))
		b.box(g, "ex_white_wainscot", pc + UP * (top - 0.3), Vector3(1.45, 0.2, 1.05))
	# the thin flat white cornice slab over the whole pavilion, overhanging ~1.3 m with flared corners
	b.box(g, "ex_white_wainscot", Vector3((x0 + x1) * 0.5, top + 0.15, (88.0 + z1) * 0.5 + 0.6), Vector3(x1 - x0 + 2.6, 0.3, z1 - 88.0 + 2.6))
	b.box(g, "ex_white_wainscot", Vector3((x0 + x1) * 0.5, top - 0.45, z1 + 0.62), Vector3(x1 - x0, 0.6, 0.08))
	# the back wall: cream wainscot and a white chair rail, the doors between
	run_box(b, g, pier, a, t, n, 0.0, Ln, 0.0, 1.2, 0.05, 0.05)
	run_box(b, g, "ex_white_wainscot", a, t, n, 0.0, Ln, 1.2, 1.3, 0.07, 0.07)
	for i in 3:
		run_box(b, g, "ex_bronze", a, t, n, 1.3 + i * 2.7 - 0.05, 1.3 + i * 2.7 + 0.05, 0.0, 3.4, 0.0, 0.14)
	run_box(b, g, "ex_bronze", a, t, n, 1.3, 6.7, 2.35, 2.5, 0.0, 0.14)
	b.quad("ex_glass", "ex_glass", [a + t * 1.3 + n * 0.08, a + t * 6.7 + n * 0.08, a + t * 6.7 + n * 0.08 + UP * 3.4, a + t * 1.3 + n * 0.08 + UP * 3.4], n, [], true)
	# porch lights and the two trash cans
	for k in 2:
		b.cyl(g, "ex_can", Vector3(-142.0, 4.58, 94.0 + k * 3.0), 0.12, 0.12, 0.02, 10, false, true)
		b.tag(b.add_spot(Vector3(-142.0, 4.5, 94.0 + k * 3.0), -UP, 1.5, 7.0, 60.0, Color("#FFE6C2")), "night")
	for xx in [-144.6, -139.4]:
		b.cyl(g, "ex_stainless" if y26 else "ex_ivory", Vector3(xx, 0, 93.0), 0.3, 0.3, 0.9, 12, true)
		b.obst(["rect", xx - 0.35, 92.6, xx + 0.35, 93.4])
	if y26:
		# the east bay's black flat steel canopy hung on tie-rods, over a dark glass door (4489 f034)
		var ea = Vector3(-134.0, 0, 100.0)
		b.box(g, "ex_black_steel", ea + Vector3(0, 3.4, 1.2), Vector3(3.6, 0.12, 2.4))
		for sx in [-1.5, 1.5]:
			var p0 = ea + Vector3(sx, 3.45, 2.3); var p1 = ea + Vector3(sx, 4.6, 0.05)
			var m = (p0 + p1) * 0.5; var dir = (p1 - p0).normalized()
			b.box(g, "ex_steel", Vector3.ZERO, Vector3(0.03, p0.distance_to(p1), 0.03), Transform3D(Basis(Vector3(1, 0, 0), dir, Vector3(1, 0, 0).cross(dir)), m))
		b.box(g, "ex_glass_dark", ea + Vector3(0, 1.2, 0.03), Vector3(1.9, 2.4, 0.04))
	# the drop-off bulb: a curbed island out front, past the porch
	island(b, -150.0, 106.0, -134.0, 109.0, "ex_grass", "ex_curb")
	tree_oak(b, Vector3(-142.0, 0.16, 107.5), 4.0)

## The cinema-wing exit (s41, the Sears hall's west end): brown exposed-aggregate precast fascia
## ~1 m deep, white soffit with cans, a 2-tier clear-anodized curtain wall with 2 door pairs; buff
## brick return with a recessed poster case; the black 3-loop wave bike rack ("here since I was a
## kid"; 4416 f002/f010, 4417).
static func cinema_exit(b):
	var g = "ex_entry"
	var a = Vector3(-80, 0, -96); var n = Vector3(-1, 0, 0); var t = Vector3(0, 0, 1); var Ln = 10.0
	# the fascia and the soffit with cans
	run_box(b, g, "ex_aggregate", a, t, n, 0.0, Ln, 3.6, 4.6, 1.2, 1.2)
	b.quad(g, "ex_soffit_white", [a + n * 1.2 + UP * 3.59, a + UP * 3.59, a + t * Ln + UP * 3.59, a + t * Ln + n * 1.2 + UP * 3.59], -UP)
	for i in 3:
		var c = a + t * (2.0 + i * 3.0) + n * 0.6 + UP * 3.55
		b.cyl(g, "ex_can", c - UP * 0.02, 0.12, 0.12, 0.02, 10, false, true)
		b.tag(b.add_spot(c, -UP, 1.2, 6.0, 60.0, Color("#FFE6C2")), "night")
	# the curtain wall: clear-anodized mullions, two tiers
	for i in 6:
		run_box(b, g, "ex_mullion", a, t, n, 0.5 + i * 1.8 - 0.04, 0.5 + i * 1.8 + 0.04, 0.0, 3.6, 0.0, 0.12)
	run_box(b, g, "ex_mullion", a, t, n, 0.5, 9.5, 2.3, 2.42, 0.0, 0.12)
	b.quad("ex_glass", "ex_glass", [a + t * 0.5 + n * 0.02, a + t * 9.5 + n * 0.02, a + t * 9.5 + n * 0.02 + UP * 3.6, a + t * 0.5 + n * 0.02 + UP * 3.6], n, [], true)
	# the poster case on the buff return (the south side, z = -86)
	var ra = Vector3(-80, 0, -86); var rn = Vector3(0, 0, 1); var rt = Vector3(1, 0, 0)
	run_box(b, g, "ex_mullion", ra, rt, rn, 1.0, 2.4, 0.9, 2.5, 0.04, 0.04)
	run_box(b, g, "ex_glass_dark", ra, rt, rn, 1.08, 2.32, 0.98, 2.42, 0.05, 0.01)
	# the wave bike rack: three loops of black pipe
	var rk = Vector3(-84.5, 0, -89.0)
	for i in 3:
		var x = rk.x; var z = rk.z + i * 1.0
		for s in [-1.0, 1.0]:
			b.cyl(g, "ex_fence_black", Vector3(x, 0, z + s * 0.35), 0.025, 0.025, 0.75, 6, false)
		b.box(g, "ex_fence_black", Vector3(x, 0.78, z), Vector3(0.05, 0.05, 0.75))
	b.obst(["rect", rk.x - 0.4, rk.z - 0.5, rk.x + 0.4, rk.z + 2.5])

## The cinema box: windowless salmon-red brick, peach stucco pilasters every 8–10 m on the west
## wall, beige steel exit doors with hoods ("the side doors you left the movies out of"), a ramped
## walk with 3 steps and a pipe rail (4416, 4486 f014-037).
static func cinema_box(b):
	var g = "ex_shell"
	var a = Vector3(-70, 0, -86); var n = Vector3(-1, 0, 0); var t = Vector3(0, 0, 1); var Ln = 22.0
	for u in [0.3, 8.0, 16.0, 21.7]:
		run_box(b, g, "ex_peach_pier", a, t, n, u - 0.3, u + 0.3, 0.0, H_CINEMA - 0.2, 0.18, 0.18)
	service_door(b, g, a, t, n, 4.0, true)
	service_door(b, g, a, t, n, 12.0, true)
	service_door(b, g, a, t, n, 19.0, true)
	# the ramp and its rail along the wall
	b.box(g, "ex_peach_pier", Vector3(-71.6, 0.3, -74.0), Vector3(0.25, 0.6, 12.0))
	b.box(g, "ex_pipe_grey", Vector3(-71.6, 1.45, -74.0), Vector3(0.06, 0.06, 12.0))
	for z in [-79.5, -74.0, -68.5]:
		b.cyl(g, "ex_pipe_grey", Vector3(-71.6, 0.6, z), 0.03, 0.03, 0.85, 6, false)
	for i in 3:
		b.box(g, "ex_curb", Vector3(-71.0, 0.05 + i * 0.05, -67.0 + i * 0.35), Vector3(1.4, 0.1 + i * 0.1, 0.35))
	b.obst(["rect", -72.0, -80.5, -71.2, -66.0])

## K&B's bay (s25, the east facade): the original cream cantilevered canopy with a folded-plate
## (zig-zag) soffit, a can light in each pleat, window heads raked to follow the pleats ("that
## awning was original"; 4493 f011, f018, 4406 f004). K&B's own sign and colours in 1995: the purple
## oval logo on a cream band, where Hypervelocity's letters are today.
static func kb_bay(b):
	var g = "ex_entry"
	var a = Vector3(44, 0, -38); var n = Vector3(1, 0, 0); var t = Vector3(0, 0, 1); var Ln = 20.0
	# the folded-plate canopy: pleats 2 m wide, 0.5 m rise, 3 m out at 3.6 m
	var pleats = 10
	for i in pleats:
		var u0 = i * 2.0; var um = u0 + 1.0; var u1 = u0 + 2.0
		var lo = a + UP * 3.6; var hi = a + UP * 4.1
		var p00 = lo + t * u0; var p01 = lo + t * u0 + n * 3.0
		var pm0 = hi + t * um; var pm1 = hi + t * um + n * 3.0
		var p10 = lo + t * u1; var p11 = lo + t * u1 + n * 3.0
		var n0 = (t * -0.5 + UP * 1.0).normalized(); var n1 = (t * 0.5 + UP * 1.0).normalized()
		# underside (seen from the lot) and top
		b.quad(g, "ex_canopy_cream", [p00, p01, pm1, pm0], -n0)
		b.quad(g, "ex_canopy_cream", [pm0, pm1, p11, p10], -n1)
		b.quad(g, "ex_canopy_cream", [pm0, pm1, p01, p00], n0)
		b.quad(g, "ex_canopy_cream", [p10, p11, pm1, pm0], n1)
		var c = a + t * um + n * 1.5 + UP * 4.05
		b.cyl(g, "ex_can", c - UP * 0.02, 0.1, 0.1, 0.02, 8, false, true)
		b.tag(b.add_spot(c, -UP, 1.0, 6.0, 60.0, Color("#FFE6C2")), "night")
	# the front edge of the canopy
	var pts = PackedVector2Array()
	for i in pleats + 1:
		pts.append(Vector2(i * 2.0, 4.1 if i % 2 == 1 else 3.6))
	pts.append(Vector2(Ln, 3.4)); pts.append(Vector2(0.0, 3.4))
	b.poly(g, "ex_canopy_cream", pts, a + n * 3.0, t, UP, n)
	# the raked windows under it: white mullions, glass, heads following the pleats
	for i in pleats:
		var u0 = i * 2.0 + 0.1; var u1 = u0 + 1.8
		var ym = 3.4 if i % 2 == 1 else 3.0
		run_box(b, g, "ex_mullion", a, t, n, u0 - 0.06, u0 + 0.06, 0.9, ym, 0.0, 0.1)
		run_box(b, g, "ex_mullion", a, t, n, u1 - 0.06, u1 + 0.06, 0.9, ym, 0.0, 0.1)
		b.quad("ex_glass", "ex_glass_dark", [a + t * u0 + n * 0.02 + UP * 0.9, a + t * u1 + n * 0.02 + UP * 0.9, a + t * u1 + n * 0.02 + UP * ym, a + t * u0 + n * 0.02 + UP * ym], n)
	# the bulkheads below the windows: K&B's tan (the 2026 racing check is Hypervelocity's)
	if YEAR == 2026:
		Y26.hypervelocity(b, a, t, n, Ln)
		return
	run_box(b, g, "ex_kb_tan", a, t, n, 0.0, Ln, 0.0, 0.9, 0.05, 0.05)
	# the sign band: cream with the purple oval and K&B
	run_box(b, g, "ex_ivory", a, t, n, 2.0, 18.0, 4.6, 6.2, 0.1, 0.1)
	var s = b.st(g, "ex_purple")
	var c = a + t * 10.0 + n * 0.14 + UP * 5.4
	for i in 24:
		var a0 = TAU * i / 24; var a1 = TAU * (i + 1) / 24
		b.tri(s, c, c + t * (cos(a0) * 2.4) + UP * (sin(a0) * 0.62), c + t * (cos(a1) * 2.4) + UP * (sin(a1) * 0.62), Vector2(0, 0), Vector2(0, 0), Vector2(0, 0), n)
	b.label("K&B", "serif", "#f4efe3", c + n * 0.03, n, 3.6, 0.8)

## Cucos (s42): white heavy skip-trowel stucco over brick today with a black soldier band, black
## brick pilasters, a stepped ziggurat parapet at the sign bay, 6+ tall windows in white surrounds,
## glazed garage-style doors that lift open, red box awnings (4406 f022-026). In 1995: the same
## massing and window rhythm in Cucos's colours (warm stucco, teal trim, as its mall front).
static func cucos(b):
	var g = "ex_entry"
	var a = Vector3(44, 0, -86); var n = Vector3(1, 0, 0); var t = Vector3(0, 0, 1); var Ln = 32.0
	# 2026: The Red Seal's black (soldier band, pilasters, coping) and red (awnings) on the same massing
	var y26 = YEAR == 2026
	var trim = "ex_paint_black" if y26 else "ex_teal"
	var awn = "ex_red_seal" if y26 else "ex_awning_teal"
	run_box(b, g, trim, a, t, n, 0.0, Ln, 5.6, 5.9, 0.03, 0.03)      # the soldier band (teal in 1995)
	var k = 0.0
	while k <= Ln:
		run_box(b, g, "ex_paint_black" if y26 else "ex_planks", a, t, n, k - 0.3, k + 0.3, 0.0, H_CUCOS - 0.2 + (0.6 if y26 else 0.0), 0.2, 0.2)
		k += 8.0
	# the tall windows in white surrounds, a teal box awning over each
	for i in 6:
		var u = 1.5 + i * 5.2
		if i == 2:
			continue
		run_box(b, g, "ex_white_wainscot", a, t, n, u - 0.9, u + 0.9, 0.8, 4.4, 0.08, 0.08)
		b.quad("ex_glass", "ex_glass_dark", [a + t * (u - 0.75) + n * 0.02 + UP * 0.95, a + t * (u + 0.75) + n * 0.02 + UP * 0.95, a + t * (u + 0.75) + n * 0.02 + UP * 4.25, a + t * (u - 0.75) + n * 0.02 + UP * 4.25], n)
		run_box(b, g, awn, a, t, n, u - 1.2, u + 1.2, 4.4, 5.0, 0.8, 0.8, ["-y"])
	# the glazed garage-style doors (the ones that lift open), either side of the sign bay
	for u in [10.5, 15.0]:
		run_box(b, g, "ex_white_wainscot", a, t, n, u - 1.6, u + 1.6, 0.0, 3.2, 0.06, 0.06)
		for r in 4:
			b.quad("ex_glass", "ex_glass_dark", [a + t * (u - 1.45) + n * 0.02 + UP * (0.2 + r * 0.72), a + t * (u + 1.45) + n * 0.02 + UP * (0.2 + r * 0.72), a + t * (u + 1.45) + n * 0.02 + UP * (0.8 + r * 0.72), a + t * (u - 1.45) + n * 0.02 + UP * (0.8 + r * 0.72)], n)
	# the stepped ziggurat parapet at the sign bay and the sign
	run_box(b, g, "ex_stucco_tan", a, t, n, 8.0, 17.5, H_CUCOS, H_CUCOS + 0.8, 0.0, 0.5)
	run_box(b, g, "ex_stucco_tan", a, t, n, 10.0, 15.5, H_CUCOS + 0.8, H_CUCOS + 1.5, 0.0, 0.5)
	run_box(b, g, trim, a, t, n, 8.0, 17.5, H_CUCOS + 0.75, H_CUCOS + 0.85, 0.05, 0.55)
	run_box(b, g, trim, a, t, n, 10.0, 15.5, H_CUCOS + 1.45, H_CUCOS + 1.55, 0.05, 0.55)
	if y26:
		# THE RED (R seal) SEAL / PIZZERIA & BAR (4406 f022-026, 4493 f037-040), the big R mural
		b.label("THE RED SEAL", "sans", "#b3202a", a + t * 12.75 + UP * 6.6 + n * 0.12, n, 7.0, 0.7)
		b.label("PIZZERIA & BAR", "sans", "#1c1c1e", a + t * 12.75 + UP * 6.0 + n * 0.12, n, 3.4, 0.28)
		var mc = a + t * 28.6 + UP * 2.6 + n * 0.03
		var sr = b.st(g, "ex_red_seal")
		for i in 28:
			var a0 = TAU * i / 28; var a1 = TAU * (i + 1) / 28
			var r0 = 1.5 + (0.12 if i % 2 == 0 else 0.0); var r1 = 1.5 + (0.12 if (i + 1) % 2 == 0 else 0.0)
			b.tri(sr, mc, mc + t * (cos(a0) * r0) + UP * (sin(a0) * r0), mc + t * (cos(a1) * r1) + UP * (sin(a1) * r1), Vector2(0, 0), Vector2(0, 0), Vector2(0, 0), n)
		b.label("R", "serif", "#f4efe3", mc + n * 0.02, n, 2.0, 1.6)
	else:
		run_box(b, g, "ex_ivory", a, t, n, 9.0, 16.5, 5.95, 6.9, 0.1, 0.1)
		b.label("Cucos", "script", "#c8202c", a + t * 12.75 + UP * 6.55 + n * 0.16, n, 5.0, 0.6)
		b.label("MEXICAN CAFE", "sans", "#1f7a74", a + t * 12.75 + UP * 6.1 + n * 0.16, n, 3.0, 0.22)
	# gooseneck barn lights over the awnings
	for i in 6:
		var u = 1.5 + i * 5.2
		b.cyl(g, "ex_bronze", a + t * u + n * 0.3 + UP * 5.3, 0.14, 0.05, 0.14, 8, true, true)
		b.tag(b.add_spot(a + t * u + n * 0.3 + UP * 5.25, -UP, 0.8, 5.0, 70.0, Color("#FFD9A8")), "night")

## JCPenney: natural cream face brick with dark ironspot speckles, long thin units, no windows
## (4486 f103-113, 4487-4489). West face: the tree-side customer entrance under a flat maroon
## fascia and a grade-level roll-up receiving door; south: the customer entrance under a red
## arcade on 4 bays of square columns; north: Package Pick-up under a coral ribbed fascia, docks
## 1-2 under a red canopy. The 1995 Helvetica JCPenney mark on the W and S walls.
static func jcpenney(b):
	var g = "ex_entry"
	# west face x = -202, z 32..74
	var a = Vector3(-202, 0, 74); var n = Vector3(-1, 0, 0); var t = Vector3(0, 0, -1)
	# customer entrance under a flat maroon fascia, 6 m wide, centred
	run_box(b, g, "ex_maroon", a, t, n, 15.0, 27.0, 3.6, 4.6, 3.0, 3.0, ["+y"])
	b.quad(g, "ex_soffit_white", [a + t * 15.0 + UP * 3.59, a + t * 27.0 + UP * 3.59, a + t * 27.0 + n * 3.0 + UP * 3.59, a + t * 15.0 + n * 3.0 + UP * 3.59], -UP)
	for i in 5:
		run_box(b, g, "ex_bronze", a, t, n, 17.0 + i * 2.0 - 0.05, 17.0 + i * 2.0 + 0.05, 0.0, 3.4, 0.0, 0.14)
	b.quad("ex_glass", "ex_glass", [a + t * 17.0 + n * 0.02, a + t * 25.0 + n * 0.02, a + t * 25.0 + n * 0.02 + UP * 3.4, a + t * 17.0 + n * 0.02 + UP * 3.4], n, [], true)
	for i in 3:
		b.tag(b.add_spot(a + t * (18.0 + i * 3.0) + n * 1.5 + UP * 3.5, -UP, 1.2, 6.0, 60.0, Color("#FFE6C2")), "night")
	b.label("JCPenney", "sans", "#b0164a" if YEAR == 2026 else "#f4efe3", a + t * 21.0 + UP * 6.3 + n * 0.08, n, 10.0, 1.1)
	# roll-up receiving door at the north end
	run_box(b, g, "ex_steel", a, t, n, 36.0, 40.0, 0.0, 3.6, 0.03, 0.03)
	# podocarpus columns along the wall
	for i in 8:
		var p = a + t * (3.0 + i * 5.0) + n * 1.2
		b.cyl("ex_props", "ex_podocarpus", p, 0.6, 0.3, 3.5, 7, true, false, true)
	# south face z = 74, x -202..-154: the red arcade on square columns
	var sa = Vector3(-202, 0, 92); var sn = Vector3(0, 0, 1); var stt = Vector3(1, 0, 0)   # wall_fixes F3
	for i in 5:
		var p = sa + stt * (16.0 + i * 4.0) + sn * 3.0
		b.box(g, "ex_red_arcade", p + UP * 2.0, Vector3(0.7, 4.0, 0.7))
		b.obst(["rect", p.x - 0.4, p.z - 0.4, p.x + 0.4, p.z + 0.4])
	run_box(b, g, "ex_red_arcade", sa, stt, sn, 15.5, 32.5, 4.0, 5.0, 3.4, 3.6, ["+y"])
	for i in 4:
		run_box(b, g, "ex_bronze", sa, stt, sn, 19.0 + i * 2.0 - 0.05, 19.0 + i * 2.0 + 0.05, 0.0, 3.4, 0.0, 0.14)
	b.quad("ex_glass", "ex_glass", [sa + stt * 19.0 + sn * 0.02, sa + stt * 25.0 + sn * 0.02, sa + stt * 25.0 + sn * 0.02 + UP * 3.4, sa + stt * 19.0 + sn * 0.02 + UP * 3.4], sn, [], true)
	b.label("JCPenney", "sans", "#b0164a" if YEAR == 2026 else "#f4efe3", sa + stt * 24.0 + UP * 7.2 + sn * 0.08, sn, 10.0, 1.1)
	# north face z = 32: Package Pick-up under a coral fascia, docks under a red canopy, bollards
	var na = Vector3(-154, 0, 32); var nn = Vector3(0, 0, -1); var nt = Vector3(-1, 0, 0)
	run_box(b, g, "ex_coral", na, nt, nn, 4.0, 12.0, 3.2, 4.2, 1.5, 1.5)
	run_box(b, g, "ex_beige_door", na, nt, nn, 6.5, 9.5, 0.0, 2.6, 0.03, 0.03)
	b.label("Package Pick-up", "sans", "#f4efe3", na + nt * 8.0 + UP * 3.7 + nn * 1.52, nn, 5.0, 0.35)
	run_box(b, g, "ex_red_arcade", na, nt, nn, 28.0, 40.0, 4.0, 4.5, 2.5, 2.5)
	for u in [30.0, 36.0]:
		run_box(b, g, "ex_steel", na, nt, nn, u - 1.6, u + 1.6, 1.2, 4.0, 0.03, 0.03)
		# the dock: a raised slab with a yellow pipe rail
	run_box(b, g, "ex_curb", na, nt, nn, 27.0, 41.0, 0.0, 1.2, 2.0, 2.0, ["-y"])
	for u in [27.5, 40.5]:
		bollard(b, na + nt * u + nn * 2.6)
	b.obst(["rect", -195.0, 29.9, -181.0, 32.0])

## Dillard's: three storeys of peach EIFS scored as ashlar, two cream cornice bands, the serif
## "Dillard's"; a front gallery (the east face): a flat-roofed veranda on slender bronze columns
## with an ornate cast-iron lace frieze and brackets (New Orleans balcony look), pebble paving,
## black bollard lights; ground storey white panels with blind panelled doors under sunburst
## fanlights; a flagpole island at the corner (4490 f035-045, 4492 f104). "Extremely unique":
## Steven wants the gallery. The 1995 (D.H. Holmes-era) skin is unknown: this is the gallery as filmed.
static func dillards(b):
	var g = "ex_entry"
	var a = Vector3(30, 0, 80); var n = Vector3(1, 0, 0); var t = Vector3(0, 0, 1); var Ln = 38.0
	# ashlar scoring: faint grooves every 1.2 m, cornice bands at 9.5 and 13.4
	var y = 5.2
	while y < H_DILLARDS - 0.3:
		run_box(b, "ex_shell", "ex_coping", a, t, n, 0.0, Ln, y - 0.02, y + 0.02, 0.0, 0.03)
		y += 1.2
	run_box(b, "ex_shell", "ex_cream_pier", a, t, n, 0.0, Ln, 9.3, 9.8, 0.25, 0.25)
	run_box(b, "ex_shell", "ex_cream_pier", a, t, n, 0.0, Ln, H_DILLARDS - 0.6, H_DILLARDS, 0.3, 0.3)
	# the same bands round the south and west faces
	var sa = Vector3(-38, 0, 118); var sn = Vector3(0, 0, 1); var stt = Vector3(1, 0, 0)
	run_box(b, "ex_shell", "ex_cream_pier", sa, stt, sn, 0.0, 68.0, 9.3, 9.8, 0.25, 0.25)
	run_box(b, "ex_shell", "ex_cream_pier", sa, stt, sn, 0.0, 68.0, H_DILLARDS - 0.6, H_DILLARDS, 0.3, 0.3)
	var wa = Vector3(-38, 0, 80); var wn = Vector3(-1, 0, 0); var wt = Vector3(0, 0, 1)
	run_box(b, "ex_shell", "ex_cream_pier", wa, wt, wn, 0.0, 38.0, 9.3, 9.8, 0.25, 0.25)
	run_box(b, "ex_shell", "ex_cream_pier", wa, wt, wn, 0.0, 38.0, H_DILLARDS - 0.6, H_DILLARDS, 0.3, 0.3)
	run_box(b, "ex_shell", "ex_white_wainscot", wa, wt, wn, 0.0, 38.0, 0.0, 1.2, 0.05, 0.05)
	# the ground storey: white panels, blind panelled doors under sunburst fanlights
	run_box(b, g, "ex_white_wainscot", a, t, n, 0.0, Ln, 0.0, 4.8, 0.08, 0.08)
	for i in 6:
		var u = 4.0 + i * 5.6
		run_box(b, g, "ex_ivory", a, t, n, u - 1.0, u + 1.0, 0.0, 2.6, 0.14, 0.06)
		run_box(b, g, "ex_bronze", a, t, n, u - 0.95, u + 0.95, 0.1, 2.5, 0.15, 0.02)
		var s = b.st(g, "ex_ivory")
		var c = a + t * u + n * 0.15 + UP * 2.65
		for k in 12:
			var a0 = PI * k / 12; var a1 = PI * (k + 1) / 12
			b.tri(s, c, c + t * (cos(a0) * 1.05) + UP * (sin(a0) * 1.05), c + t * (cos(a1) * 1.05) + UP * (sin(a1) * 1.05), Vector2(0, 0), Vector2(0, 0), Vector2(0, 0), n)
			if k % 2 == 0:
				b.tri(b.st(g, "ex_bronze"), c + n * 0.01, c + n * 0.01 + t * (cos(a0) * 1.0) + UP * (sin(a0) * 1.0), c + n * 0.01 + t * (cos(a1) * 1.0) + UP * (sin(a1) * 1.0), Vector2(0, 0), Vector2(0, 0), Vector2(0, 0), n)
	# the gallery: a flat roof 3.6 m out at 4.6 m on 11 slender bronze columns. Workstream F (Nov 1):
	# the cast-iron lace as filmed (refs/new/dillards_exterior t056_021-031): a frieze of scrolled
	# roundels under the brown fascia on the front and both ends, a quarter-round scroll bracket each
	# side of every column, Corinthian-like caps and octagonal panelled bases, a terracotta soffit.
	# Until Nov 1 the lace was a dark band with white slots.
	run_box(b, g, "ex_canopy_brown", a, t, n, 0.5, Ln - 0.5, 4.6, 5.0, 3.7, 3.8, [])
	b.quad(g, "ex_soffit_terra", [a + t * 0.5 + UP * 4.59, a + t * (Ln - 0.5) + UP * 4.59, a + t * (Ln - 0.5) + n * 3.6 + UP * 4.59, a + t * 0.5 + n * 3.6 + UP * 4.59], -UP)
	var fy0 = 4.08; var fy1 = 4.58
	var L0 = 0.5; var L1 = Ln - 0.5
	var fr = a + n * 3.66
	b.quad(g, "ex_lace", [fr + t * L0 + UP * fy0, fr + t * L1 + UP * fy0, fr + t * L1 + UP * fy1, fr + t * L0 + UP * fy1], n,
		[Vector2(0, 1), Vector2(L1 - L0, 1), Vector2(L1 - L0, 0), Vector2(0, 0)])
	for ue in [L0, L1]:
		var e0 = a + t * ue
		b.quad(g, "ex_lace", [e0 + n * 0.05 + UP * fy0, e0 + n * 3.66 + UP * fy0, e0 + n * 3.66 + UP * fy1, e0 + n * 0.05 + UP * fy1], t,
			[Vector2(0, 1), Vector2(3.6, 1), Vector2(3.6, 0), Vector2(0, 0)])
	for i in 11:
		var u = 1.0 + i * 3.6
		var p = a + t * u + n * 3.4
		b.cyl(g, "ex_bronze", p + UP * 0.7, 0.085, 0.075, 3.05, 10, false)
		b.cyl(g, "ex_bronze", p + UP * 3.72, 0.08, 0.2, 0.36, 10, true)        # the flared cap
		b.box(g, "ex_bronze", p + UP * 4.12, Vector3(0.42, 0.08, 0.42))
		b.cyl(g, "ex_bronze", p, 0.2, 0.2, 0.7, 8, true)                       # the octagonal base
		b.cyl(g, "ex_bronze", p + UP * 0.7, 0.14, 0.085, 0.12, 8, false)
		# the brackets, each side of the column, in the front plane (the column on the texture's
		# right edge, the beam along its top)
		var bp = a + n * 3.4
		for sd in [-1.0, 1.0]:
			if (sd < 0 and u - 0.9 < L0) or (sd > 0 and u + 0.9 > L1):
				continue
			var q0 = bp + t * u; var q1 = bp + t * (u + sd * 0.9)
			var uv0 = 1.0; var uv1 = 0.0
			b.quad(g, "ex_lace_bracket", [q1 + UP * 3.68, q0 + UP * 3.68, q0 + UP * 4.58, q1 + UP * 4.58], n,
				[Vector2(uv1, 1), Vector2(uv0, 1), Vector2(uv0, 0), Vector2(uv1, 0)])
		b.obst(["rect", p.x - 0.25, p.z - 0.25, p.x + 0.25, p.z + 0.25])
	# pebble paving under the gallery, black bollard lights
	b.quad(g, "ex_pebble", [a + UP * 0.01, a + t * Ln + UP * 0.01, a + t * Ln + n * 4.5 + UP * 0.01, a + n * 4.5 + UP * 0.01], UP)
	for i in 4:
		var p = a + t * (4.0 + i * 10.0) + n * 5.2
		b.cyl(g, "ex_fence_black", p, 0.1, 0.1, 1.0, 8, true)
		b.cyl(g, "ex_lamp", p + UP * 0.8, 0.09, 0.09, 0.15, 8, false)
		b.tag(b.add_omni(p + UP * 0.9, 1.0, 5.0, Color("#FFD9A8")), "night")
	b.label("Dillard's", "serif", "#3b2e28", a + t * 19.0 + UP * 11.6 + n * 0.08, n, 14.0, 1.6)
	b.label("Dillard's", "serif", "#3b2e28", sa + stt * 34.0 + UP * 11.6 + sn * 0.08, sn, 14.0, 1.6)
	# the flagpole island at the corner
	island(b, 31.0, 119.0, 35.0, 123.0, "ex_grass", "ex_curb")
	b.cyl("ex_props", "ex_pole_white", Vector3(33, 0.16, 121), 0.08, 0.04, 12.0, 8, true)

## Sears loading (the north wall, Armour Dr): white block, a flat canopy on round pipe columns, a
## raised dock ~1.2 m, a truck well, yellow pipe rail ("take note of this"; 4486 f002-010).
static func sears_dock(b):
	var g = "ex_entry"
	var a = Vector3(30, 0, -134); var n = Vector3(0, 0, -1); var t = Vector3(-1, 0, 0)
	run_box(b, g, "ex_curb", a, t, n, 10.0, 34.0, 0.0, 1.2, 3.0, 3.0, ["-y"])
	run_box(b, g, "ex_coping_dark", a, t, n, 9.0, 35.0, 4.6, 4.9, 6.0, 6.0)
	for u in [10.0, 22.0, 34.0]:
		b.cyl(g, "ex_pipe_grey", a + t * u + n * 5.7, 0.12, 0.12, 4.6, 8, false)
	for u in [10.0, 34.0]:
		b.cyl(g, "ex_pipe_yellow", a + t * u + n * 3.0 + UP * 1.2, 0.03, 0.03, 1.0, 6, false)
	b.box(g, "ex_pipe_yellow", a + t * 22.0 + n * 3.0 + UP * 2.15, Vector3(24.0, 0.06, 0.06))
	for u in [14.0, 22.0, 30.0]:
		run_box(b, g, "ex_steel", a, t, n, u - 1.5, u + 1.5, 1.2, 4.2, 0.03, 0.03)
	b.obst(["rect", -4.0, -137.0, 20.0, -134.0])
	if YEAR == 2026:
		Y26.lynns(b)
	else:
		b.label("Sears", "sans", "#f4efe3", Vector3(-5.0, 7.0, -134.08), n, 12.0, 1.6)
		b.label("Sears", "sans", "#f4efe3", Vector3(30.08, 7.0, -115.0), Vector3(1, 0, 0), 12.0, 1.6)
		b.label("Sears", "sans", "#f4efe3", Vector3(-40.08, 7.0, -115.0), Vector3(-1, 0, 0), 12.0, 1.6)
	# Workstream E's door spots on Sears's east face (exterior.json "door_spots"): a glass
	# entrance is drawn there (Sears 1995 / Lynn's 2026), not yet a door the player can use
	for ds in E.get("door_spots", []):
		var da = V(ds.a); var db = V(ds.b); var dn = -V(ds.n); var dt = (db - da).normalized(); var dl = da.distance_to(db)
		run_box(b, g, "ex_mullion", da, dt, dn, 0.0, dl, 0.0, 3.0, 0.08, 0.16)
		b.quad("ex_glass", "ex_glass_dark", [da + dn * 0.1, db + dn * 0.1, db + dn * 0.1 + UP * 2.85, da + dn * 0.1 + UP * 2.85], dn)
		if YEAR == 2026:
			run_box(b, g, "ex_black_steel", da, dt, dn, -0.5, dl + 0.5, 3.1, 3.3, 1.4, 1.4)

## The east facade's trash / transformer bay (Workstream F; 4406 f011-015, 4493 f030-032): an
## open-sided roofed drive-in bay ~8 m wide, 6 m deep, tan brick, big brown louvers and louvered
## double doors ("Transformer Room 2", "Riser 3,4"), fluorescent strips in the soffit.
static func service_bay(b):
	var r = E.get("bay", [])
	if r.size() < 4:
		return
	var g = "ex_entry"
	var x0 = float(r[0]); var z0 = float(r[1]); var x1 = float(r[2]); var z1 = float(r[3])
	# the roof slab over the bay and its fascia (the facade's cream band runs across)
	b.box(g, "ex_cream_pier", Vector3((x0 + x1) * 0.5, 5.3, (z0 + z1) * 0.5), Vector3(x1 - x0, 2.4, z1 - z0), Transform3D.IDENTITY, ["-y"])
	b.quad(g, "ex_soffit_white", [Vector3(x0, 4.1, z0), Vector3(x1, 4.1, z0), Vector3(x1, 4.1, z1), Vector3(x0, 4.1, z1)], -UP)
	for k in 2:
		b.box(g, "ex_lamp", Vector3(x0 + 2.0 + k * 2.4, 4.06, (z0 + z1) * 0.5), Vector3(0.2, 0.06, 2.4))
	# louvers and the louvered doors on the back wall
	var a = Vector3(x0, 0, z1); var n = Vector3(1, 0, 0); var t = Vector3(0, 0, -1)
	run_box(b, g, "ex_canopy_brown", a, t, n, 0.6, 2.8, 1.2, 3.6, 0.05, 0.05)
	run_box(b, g, "ex_canopy_brown", a, t, n, 5.2, 7.4, 1.2, 3.6, 0.05, 0.05)
	run_box(b, g, "ex_canopy_brown", a, t, n, 3.2, 4.8, 0.0, 2.3, 0.05, 0.05)
	for k in 8:
		run_box(b, g, "ex_wall_pack", a, t, n, 0.6, 2.8, 1.4 + k * 0.28, 1.46 + k * 0.28, 0.09, 0.04)
		run_box(b, g, "ex_wall_pack", a, t, n, 5.2, 7.4, 1.4 + k * 0.28, 1.46 + k * 0.28, 0.09, 0.04)
	# the dumpster
	b.box(g, "ex_awning_teal" if YEAR != 2026 else "ex_holly", Vector3(x0 + 1.6, 0.7, (z0 + z1) * 0.5 + 1.2), Vector3(2.0, 1.4, 3.2))
	b.box(g, "ex_water_blue", Vector3(x0 + 1.6, 1.45, (z0 + z1) * 0.5 + 1.2), Vector3(2.1, 0.1, 3.3))
	b.obst(["rect", x0, (z0 + z1) * 0.5 - 0.5, x0 + 2.7, (z0 + z1) * 0.5 + 2.9])

## The store backs north of the Concourse row: beige service doors with wall packs, yellow
## bollards, a trash / compactor enclosure at the taller red-brick block (4486 f031-052); the rear
## service lane behind the Dillard's wing: tenant back doors numbered 3026–3029 on 3-step stoops
## (4490 f006-012); the Woolworth block's compactor.
static func store_backs(b):
	var g = "ex_shell"
	for seg in E.segments:
		var nm = seg.name
		if seg.side == "N" and seg.a[1] == 20.0 and nm != "":
			var a = V(seg.a); var bb = V(seg.b); var n = V(seg.n); var t = (bb - a).normalized()
			var u = a.distance_to(bb) * 0.5
			service_door(b, g, a, t, n, u)
			bollard(b, a + t * (u - 1.0) + n * 0.8)
			bollard(b, a + t * (u + 1.0) + n * 0.8)
	# the Dillard's wing's rear lane: four numbered back doors on stoops along z = 72 / 70
	var nums = ["3026", "3027", "3028", "3029"]
	var xs = [-33.0, -29.0, -25.0, -21.5]
	for i in 4:
		var a = Vector3(-36, 0, 70); var n = Vector3(0, 0, 1); var t = Vector3(1, 0, 0)
		var u = xs[i] + 36.0
		run_box(b, g, "ex_curb", a, t, n, u - 1.0, u + 1.0, 0.0, 0.5, 1.2, 1.2, ["-y"])
		run_box(b, g, "ex_beige_door", a, t, n, u - 0.5, u + 0.5, 0.5, 2.6, 0.03, 0.03)
		b.label(nums[i], "sans", "#3b2e28", a + t * u + UP * 2.85 + n * 0.05, n, 0.8, 0.18)
	# the Woolworth block's compactor enclosure on the west side
	var ca = Vector3(-74, 0, -14); var cn = Vector3(-1, 0, 0); var ct = Vector3(0, 0, 1)
	run_box(b, g, "ex_brick_red", ca, ct, cn, 20.0, 28.0, 0.0, 2.4, 4.0, 0.3)
	run_box(b, g, "ex_brick_red", ca, ct, cn, 20.0, 20.3, 0.0, 2.4, 4.0, 4.0)
	run_box(b, g, "ex_brick_red", ca, ct, cn, 27.7, 28.0, 0.0, 2.4, 4.0, 4.0)
	b.box(g, "ex_steel", Vector3(-76.5, 1.0, 10.0), Vector3(2.4, 2.0, 5.0))
	b.obst(["rect", -78.2, 6.0, -74.0, 14.0])

# ------------------------------------------------------------------ the lot
static func lot(b):
	var g = "ex_ground"
	var M = E.map
	# the ground: concrete panels 6 x 6 m over the lot (one texture per panel), out to the roads
	var x0 = M[0] - 30.0; var z0 = M[1] - 30.0; var x1 = M[2] + 30.0; var z1 = M[3] + 30.0
	b.quad(g, "ex_concrete", [Vector3(x0, 0, z0), Vector3(x1, 0, z0), Vector3(x1, 0, z1), Vector3(x0, 0, z1)], UP, [], false, 1.0 / 6.0)
	# the roads: West Park Ave (east), Bayou Gardens Blvd (south), Armour Dr (north)
	road(b, Vector3(99, 0, z0), Vector3(99, 0, z1), 11.0)
	road(b, Vector3(x0, 0, 186), Vector3(x1, 0, 186), 11.0)
	road(b, Vector3(x0, 0, -184), Vector3(x1, 0, -184), 9.0)
	# the lawns beyond the roads
	b.quad(g, "ex_grass", [Vector3(105, 0.02, z0), Vector3(x1 + 50.0, 0.02, z0), Vector3(x1 + 50.0, 0.02, z1), Vector3(105, 0.02, z1)], UP, [], false, 0.1)
	b.quad(g, "ex_grass", [Vector3(x0, 0.02, 192), Vector3(x1, 0.02, 192), Vector3(x1, 0.02, z1), Vector3(x0, 0.02, z1)], UP, [], false, 0.1)
	b.quad(g, "ex_grass", [Vector3(x0, 0.02, z0), Vector3(x1, 0.02, z0), Vector3(x1, 0.02, -189), Vector3(x0, 0.02, -189)], UP, [], false, 0.1)
	# the front lot (West Park): double rows running east-west, perpendicular to the east facade
	var z = -126.0
	while z < 160.0:
		# no rows across the entry drive or in front of the Sears hall's east entrance (z -96..-86)
		if abs(z) > 10.0 and abs(z + 91.0) > 9.0:
			for xs in [[50.0, 88.0]]:
				stall_row(b, Vector3(xs[0], 0, z), Vector3(1, 0, 0), xs[1] - xs[0])
			island(b, 47.0, z - 1.8, 50.0, z + 1.8)
			island(b, 88.0, z - 1.8, 91.0, z + 1.8)
			if int(z / 18.0) % 2 == 0:
				tree_oak(b, Vector3(48.5, 0.16, z), 3.5)
				lot_pole(b, Vector3(89.5, 0.16, z), 0.0)
			else:
				shrub(b, Vector3(89.5, 0.16, z), "leafy", 1.0)
				lot_pole(b, Vector3(48.5, 0.16, z), 0.0)
		z += 18.0
	# the back lot (Armour Dr): rows running north-south behind Sears
	var x = -70.0
	while x < 70.0:
		if x > -74.0 and x < -28.0:
			# Unitech stands here (wall_fixes.STANDALONE), its own small lot round it
			x += 18.0
			continue
		stall_row(b, Vector3(x, 0, -150), Vector3(0, 0, -1), 24.0)
		island(b, x - 1.8, -176.0, x + 1.8, -173.0)
		if int(x / 18.0) % 2 == 0:
			lot_pole(b, Vector3(x, 0.16, -174.5), PI * 0.5)
		x += 18.0
	# the south lot (Bayou Gardens): rows running north-south from the south faces to the frontage
	x = -190.0
	while x < 20.0:
		if x < -150.0 or x > -134.0:
			# rows start past the building's south faces (JCPenney's now at z 92: wall_fixes F3)
			stall_row(b, Vector3(x, 0, 108.0 if x > -150.0 and x < -60.0 else (124.0 if x > -60.0 else 100.0)), Vector3(0, 0, 1), 44.0 if x < -60.0 else 40.0)
			island(b, x - 1.8, 170.0, x + 1.8, 173.0)
			if int(x / 18.0) % 2 == 0:
				lot_pole(b, Vector3(x, 0.16, 171.5), PI * 0.5)
			else:
				tree_oak(b, Vector3(x, 0.16, 171.5), 3.5)
		x += 18.0
	# the west lot (behind JCPenney): rows running east-west; "where a lot of us learned how to skate"
	z = 36.0
	while z < 74.0:
		stall_row(b, Vector3(-280.0, 0, z), Vector3(1, 0, 0), 60.0)
		island(b, -283.0, z - 1.8, -280.0, z + 1.8)
		if int(z / 18.0) % 2 == 0:
			lot_pole(b, Vector3(-281.5, 0.16, z), 0.0)
		z += 18.0
	# the north-west notch: staff parking along the backs, the tank yard
	x = -190.0
	while x < -140.0:
		stall_row(b, Vector3(x, 0, -56.0), Vector3(0, 0, 1), 66.0)
		x += 18.0
	# the entry drive from West Park Ave: 2 lanes, double yellow centreline, 12+ sabal palms per side
	# in narrow mulch medians with yellow curbs ("that's key"; 4492 f053-066), a signal at the road
	entry_drive(b)
	ada_stalls(b)
	# the pine island and hydrant by JCPenney's north-west, the live-oak islands
	island(b, -214.0, 24.0, -206.0, 40.0, "ex_grass")
	for zz in [27.0, 32.0, 37.0]:
		tree_pine(b, Vector3(-210.0, 0.16, zz), 14.0)
	b.cyl("ex_props", "ex_red_arcade", Vector3(-205.0, 0, 42.5), 0.12, 0.12, 0.7, 8, true)
	# the lawn island with a magnolia and loblolly pines (the south lot's west end)
	island(b, -200.0, 150.0, -170.0, 160.0, "ex_grass")
	tree_oak(b, Vector3(-185.0, 0.16, 155.0), 5.0)
	tree_pine(b, Vector3(-176.0, 0.16, 153.0), 16.0)
	tree_pine(b, Vector3(-194.0, 0.16, 157.0), 15.0)
	# Bayou Gardens frontage: a long mulched island with sabal palms in a row plus live oaks
	# cut by the Bayou Gardens drive in front of the south entrance (monuments.gd)
	island(b, -200.0, 177.0, BAYOU_DRIVE[0], 181.0)
	island(b, BAYOU_DRIVE[1], 177.0, 40.0, 181.0)
	for i in 19:
		var px = -195.0 + i * 12.5
		if px > BAYOU_DRIVE[0] - 1.0 and px < BAYOU_DRIVE[1] + 1.0:
			continue
		palm(b, Vector3(px, 0.16, 179.0), 7.0 + (i % 3))
	MON.drive(b, BAYOU_DRIVE[0], BAYOU_DRIVE[1], 170.0, 181.0)
	for i in 4:
		tree_oak(b, Vector3(-182.0 + i * 60.0, 0.16, 179.0), 5.5)
	# curbs along the building: a 1.5 m sidewalk round the mall
	# (the walk is the same concrete; the kerb is the only line)
	for seg in E.segments:
		var a = V(seg.a); var bb = V(seg.b); var n = V(seg.n)
		var t = (bb - a).normalized()
		var fl = fire_lane_face(seg)
		var cm = "ex_curb"
		if fl:
			# the fire-lane curb: painted (2026 pink-red, 4416 / 4489; 1995 yellow, a GUESS from the
			# yellow curbs still on JCPenney's north side, 4487)
			cm = "ex_curb_red" if YEAR == 2026 else "ex_curb_yellow"
		run_box(b, "ex_lot", cm, a, t, n, 0.0, a.distance_to(bb), 0.0, 0.14, 1.65, 0.15)
		if fl:
			fire_lane(b, a, t, n, a.distance_to(bb))

## Which faces carry the fire lane: the customer faces round the lots (the east facade, Dillard's,
## JCPenney, the south faces, the cinema's west wall: 4416, 4486 f014-037, 4487-4489, 4492-4493),
## not the store backs on the staff lot or the service alley.
static func fire_lane_face(seg):
	var a = V(seg.a); var bb = V(seg.b)
	if seg.side == "E" and a.x >= 30.0:
		return not in_bay(seg)
	if seg.name in ["DILLARD'S", "JCPENNEY", "SOUTHLAND CINEMA", "LINK"]:
		return not (seg.name == "DILLARD'S" and seg.side == "N")
	if seg.side == "S" and a.z >= 92.0:
		return true
	return false

## The fire-lane ladder on the drive just past the curb: two rails and leaning rungs, 1.2 m wide
## (2026 pink, 1995 yellow: see above). Kept clear of the door fronts.
static func fire_lane(b, a, t, n, Ln):
	var mname = "ex_firelane_pink" if YEAR == 2026 else "ex_firelane_yellow"
	var u = 0.0
	while u < Ln - 0.5:
		var u1 = min(u + 2.0, Ln)
		var p = a + t * u + n * 1.75; var q = a + t * u1 + n * 1.75
		var y = UP * 0.018
		var near_door = false
		for d in E.doors:
			var m = Vector3(d.mid[0], 0, d.mid[1])
			if ((p + q) * 0.5).distance_to(m) < 7.0:
				near_door = true
		if not near_door:
			b.quad("ex_paint", mname, [p + y, q + y, q + n * 1.2 + y, p + n * 1.2 + y], UP,
				[Vector2(0, 0), Vector2((u1 - u) / 2.0, 0), Vector2((u1 - u) / 2.0, 1), Vector2(0, 1)], true)
		u += 2.0

## Accessible stalls by the entrances (both years: the blue wheelchair stalls are in the 2026
## footage everywhere near the doors, 4486 / 4488 / 4492; 1995 had them by the doors too, the exact
## stalls a GUESS): the symbol painted in the two stalls of each row end nearest a door.
static func ada_stalls(b):
	var spots = [
		Vector3(51.35, 0, -15.2), Vector3(54.05, 0, -15.2), Vector3(51.35, 0, 15.2), Vector3(54.05, 0, 15.2),   # main entrance
		Vector3(51.35, 0, -75.2), Vector3(54.05, 0, -75.2),                                                     # east entrance
		Vector3(-151.25, 0, 101.35), Vector3(-151.25, 0, 104.05),                                                # south entrance
		Vector3(-221.95, 0, 51.25), Vector3(-224.65, 0, 51.25)]                                                   # JCPenney west
	for p in spots:
		var c = p + UP * 0.015
		b.quad("ex_paint", "ex_ada", [c + Vector3(-0.75, 0, -0.75), c + Vector3(0.75, 0, -0.75), c + Vector3(0.75, 0, 0.75), c + Vector3(-0.75, 0, 0.75)], UP,
			[Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)], true)

static func road(b, a, bb, w):
	var t = (bb - a).normalized(); var s = Vector3(-t.z, 0, t.x) * (w * 0.5)
	b.quad("ex_ground", "ex_asphalt", [a - s + UP * 0.01, bb - s + UP * 0.01, bb + s + UP * 0.01, a + s + UP * 0.01], UP, [], false, 0.1)
	stripe(b, a + UP * 0.005, bb + UP * 0.005, 0.12, "ex_stripe_yellow")
	stripe(b, a - s * 0.5 + UP * 0.005, bb - s * 0.5 + UP * 0.005, 0.1, "ex_stripe_white")
	stripe(b, a + s * 0.5 + UP * 0.005, bb + s * 0.5 + UP * 0.005, 0.1, "ex_stripe_white")
	# a grass verge past the road edge is drawn by the caller

static func entry_drive(b):
	var g = "ex_ground"
	var x0 = 50.0; var x1 = 92.0
	b.quad(g, "ex_asphalt", [Vector3(x0, 0.015, -3.7), Vector3(x1, 0.015, -3.7), Vector3(x1, 0.015, 3.7), Vector3(x0, 0.015, 3.7)], UP, [], false, 0.1)
	stripe(b, Vector3(x0, 0.01, -0.12), Vector3(x1, 0.01, -0.12), 0.1, "ex_stripe_yellow")
	stripe(b, Vector3(x0, 0.01, 0.12), Vector3(x1, 0.01, 0.12), 0.1, "ex_stripe_yellow")
	for sd in [-1.0, 1.0]:
		island(b, x0, sd * 3.7 - (1.2 if sd < 0 else 0.0), x1, sd * 3.7 + (1.2 if sd > 0 else 0.0))
		for i in 12:
			palm(b, Vector3(x0 + 1.5 + i * 3.1, 0.16, sd * 4.3), 6.0 + (i % 3) * 0.8)
	# crape-myrtle islands by the entrance and a signal at the road
	for sd in [-1.0, 1.0]:
		island(b, 46.5, sd * 8.0 - 1.5, 49.5, sd * 8.0 + 1.5)
		b.force_dyn = true
		b.bush(Vector3(48.0, 0.16, sd * 8.0), "poinsettia", 1.6, 3)
		b.force_dyn = false
	# Workstream F: the stop bars at the mall end of the drive and the white ladder crosswalk from
	# the entrance walk across it (4492 f053-066)
	for sd in [-1.0, 1.0]:
		stripe(b, Vector3(53.0, 0.012, sd * 0.3), Vector3(53.0, 0.012, sd * 3.5), 0.45, "ex_stripe_white")
	for k in 9:
		var zz = -3.4 + k * 0.85
		stripe(b, Vector3(50.6, 0.012, zz), Vector3(52.4, 0.012, zz), 0.45, "ex_stripe_white")
	traffic_signal(b, Vector3(93.0, 0, -6.0))
	traffic_signal(b, Vector3(93.0, 0, 6.0))

static func traffic_signal(b, at):
	var g = "ex_props"
	b.cyl(g, "ex_signal", at, 0.12, 0.1, 6.0, 8, true)
	b.box(g, "ex_signal", at + UP * 5.9 + Vector3(2.5, 0, 0), Vector3(5.0, 0.14, 0.14))
	b.box(g, "ex_signal", at + UP * 5.0 + Vector3(4.5, 0, 0), Vector3(0.35, 1.1, 0.35))
	b.box(g, "ex_signal_red", at + UP * 5.35 + Vector3(4.5, 0, 0.18), Vector3(0.24, 0.24, 0.02))
	b.obst(["rect", at.x - 0.3, at.z - 0.3, at.x + 0.3, at.z + 0.3])

## The Horton Tank (1970, Chicago Bridge & Iron) behind the cinema / Woolworth backs: welded steel,
## ~11 m dia x 11 m, 4 ring courses, shallow conical roof, caged ladder, insulated riser; in a
## chain-link yard with a shrub mass, next to a peach utility building and a conduit pole on a
## yellow base (4486 f077-102).
static func tank(b):
	var g = "ex_props"
	var c = Vector3(-110.0, 0, -2.0)
	var R = 5.5
	for i in 4:
		b.cyl(g, "ex_tank_white", c + UP * (i * 2.75), R, R, 2.75, 28, false)
		b.cyl(g, "ex_tank_rust", c + UP * (i * 2.75 + 2.7), R + 0.03, R + 0.03, 0.08, 28, false)
	b.cyl(g, "ex_tank_white", c + UP * 11.0, R, 0.3, 1.4, 28, true)
	b.cyl(g, "ex_steel", c + UP * 12.4, 0.3, 0.3, 0.5, 10, true)
	# the caged ladder and the riser
	for i in 20:
		b.box(g, "ex_steel", c + Vector3(R + 0.4, 0.3 + i * 0.6, 0), Vector3(0.5, 0.03, 0.03))
	b.box(g, "ex_steel", c + Vector3(R + 0.65, 6.0, 0), Vector3(0.03, 12.0, 0.03))
	b.box(g, "ex_steel", c + Vector3(R + 0.15, 6.0, 0), Vector3(0.03, 12.0, 0.03))
	for i in 7:
		b.cyl(g, "ex_steel", c + Vector3(R + 0.4, 3.0 + i * 1.4, 0), 0.4, 0.4, 0.03, 10, false)
	b.cyl(g, "ex_tank_rust", c + Vector3(0, 0, R + 0.6), 0.2, 0.2, 10.0, 8, false)
	b.obst(["rect", c.x - R - 1.0, c.z - R - 1.0, c.x + R + 1.0, c.z + R + 1.0])
	# the chain-link yard, the utility building, the shrubs, the pole
	fence(b, "ex_chainlink", [Vector3(-124, 0, -18), Vector3(-96, 0, -18), Vector3(-96, 0, 14), Vector3(-124, 0, 14), Vector3(-124, 0, -18)], 2.2)
	b.box(g, "ex_stucco_peach", Vector3(-100.0, 1.5, 9.0), Vector3(6.0, 3.0, 5.0), Transform3D.IDENTITY, ["-y"])
	b.obst(["rect", -103.0, 6.5, -97.0, 11.5])
	shrub(b, Vector3(-119.0, 0, -12.0), "leafy", 2.5)
	shrub(b, Vector3(-116.0, 0, 8.0), "leafy", 2.0)
	b.box(g, "ex_pedestal", Vector3(-121.0, 0.4, 10.0), Vector3(0.6, 0.8, 0.6))
	b.cyl(g, "ex_trunk", Vector3(-121.0, 0.8, 10.0), 0.12, 0.1, 8.0, 7, true)
	b.obst(["rect", -124.0, -18.0, -96.0, 14.0])

static func fence(b, mname, pts, h):
	for i in pts.size() - 1:
		var a = pts[i]; var bb = pts[i + 1]
		var t = (bb - a).normalized(); var n = Vector3(-t.z, 0, t.x)
		b.quad("ex_props", mname, [a, bb, bb + UP * h, a + UP * h], n, [], false, 1.0)
		var k = 0.0
		while k <= a.distance_to(bb) + 0.01:
			b.cyl("ex_props", "ex_pipe_grey" if mname == "ex_chainlink" else "ex_fence_black", a + t * min(k, a.distance_to(bb)), 0.04, 0.04, h + 0.1, 6, true)
			k += 3.0

## The water tower (the skyline landmark in every west-lot shot): a white single-pedestal municipal
## tower with a round blue "NORTH TERREBONNE" seal, to the W/NW (4418, 4487 f002).
static func water_tower(b):
	var g = "ex_far"
	var c = Vector3(-300.0, 0, -140.0)
	b.cyl(g, "ex_tank_white", c, 3.0, 2.6, 30.0, 16, false)
	b.cyl(g, "ex_tank_white", c + UP * 30.0, 2.6, 9.0, 5.0, 24, false)
	b.cyl(g, "ex_tank_white", c + UP * 35.0, 9.0, 9.0, 7.0, 24, false)
	b.cyl(g, "ex_tank_white", c + UP * 42.0, 9.0, 0.5, 3.0, 24, true)
	var s = b.st(g, "ex_water_blue")
	var ctr = c + UP * 38.5 + Vector3(9.02, 0, 0)
	for i in 20:
		var a0 = TAU * i / 20; var a1 = TAU * (i + 1) / 20
		b.tri(s, ctr, ctr + Vector3(0, sin(a0) * 2.4, cos(a0) * 2.4), ctr + Vector3(0, sin(a1) * 2.4, cos(a1) * 2.4), Vector2(0, 0), Vector2(0, 0), Vector2(0, 0), Vector3(1, 0, 0))
	b.label("NORTH TERREBONNE", "sans", "#f4efe3", ctr + Vector3(0.05, 0, 0), Vector3(1, 0, 0), 4.2, 0.42)
	b.obst(["rect", c.x - 3.5, c.z - 3.5, c.x + 3.5, c.z + 3.5])

## The outparcels and the neighbours (4413, 4487, 4489): the drive-thru bank at the SW edge of the
## back lot with the lattice cell tower behind; the 1-storey strip centre along the south edge
## (brown brick piers, a mansard); Big Lots (Kirchmann's furniture in 1995) across West Park Ave; Ground Pat'i
## at the SW corner (a 4-sided cube pole sign, brown brick, rust standing-seam mansards: "I really
## want to capture a little bit of that"); the charcoal apartments behind a wood fence (W), the
## soccer fields behind a black picket fence (W), St. Bernadette's cream building with the green
## metal roof beyond.
static func outparcels(b):
	var g = "ex_far"
	# the drive-thru bank: a dark hip roof over 4-5 lanes
	# Workstream F: at the SW corner by Bayou Gardens (site plan "BUILDING 870 SF DRIVE-THRU";
	# 4487 f046-053 looks south / south-west to it from the back lot), not mid-west where it stood
	var bk = Vector3(-244.0, 0, 146.0)
	b.box(g, "ex_brick_brown", bk + UP * 2.0, Vector3(12.0, 4.0, 10.0), Transform3D.IDENTITY, ["-y"])
	b.cyl(g, "ex_roof_dark", bk + UP * 4.0 + Vector3(0, 0, 0), 11.0, 1.0, 3.0, 4, true)
	b.box(g, "ex_roof_dark", bk + UP * 4.3 + Vector3(12.0, 0, 0), Vector3(12.0, 0.3, 14.0))
	for i in 5:
		b.cyl(g, "ex_pipe_grey", bk + Vector3(6.5 + i * 2.8, 0, 6.5), 0.15, 0.15, 4.2, 8, false)
		b.cyl(g, "ex_pipe_grey", bk + Vector3(6.5 + i * 2.8, 0, -6.5), 0.15, 0.15, 4.2, 8, false)
	b.obst(["rect", bk.x - 6.0, bk.z - 5.0, bk.x + 18.0, bk.z + 7.0])
	# the lattice cell tower behind it
	var ct = Vector3(-262.0, 0, 164.0)
	for i in 4:
		var a = TAU * i / 4 + PI * 0.25
		b.cyl(g, "ex_steel", ct + Vector3(cos(a) * 1.8, 0, sin(a) * 1.8), 0.1, 0.06, 40.0, 6, true)
	for k in 8:
		b.box(g, "ex_steel", ct + UP * (2.5 + k * 5.0), Vector3(3.6, 0.08, 0.08))
		b.box(g, "ex_steel", ct + UP * (2.5 + k * 5.0), Vector3(0.08, 0.08, 3.6))
	b.obst(["rect", ct.x - 2.0, ct.z - 2.0, ct.x + 2.0, ct.z + 2.0])
	# the strip centre along the south edge
	strip(b, Vector3(-60.0, 0, 200.0), 70.0, 14.0, 4.2)
	# Big Lots: the strip across West Park Ave from Lynn's (4406 f031-035 "across the drive is the
	# BIG LOTS strip", 4413 f005-008). Workstream F moved it there from the north-west lot, where
	# the site plan and the directory map show parking. Tan block, white standing-seam hoods.
	# In 1995 the building was Kirchmann's, a furniture store (Steven, Nov 1 2026); its sign is
	# not in any picture, so the letters and colours are a GUESS. The building is today's shape.
	var bl = Vector3(152.0, 0, -112.0)
	b.box(g, "ex_stucco_tan", bl + UP * 3.5, Vector3(24.0, 7.0, 44.0), Transform3D.IDENTITY, ["-y"])
	b.box(g, "ex_coping_dark", bl + UP * 7.05, Vector3(24.2, 0.1, 44.2))
	for k in 3:
		b.box(g, "ex_tank_white", bl + Vector3(-12.6, 5.6, -14.0 + k * 14.0), Vector3(1.4, 2.0, 8.0))
	if YEAR == 2026:
		b.label("BIG LOTS!", "sans", "#c8202c", bl + Vector3(-13.4, 5.6, 0), Vector3(-1, 0, 0), 7.0, 1.0)
	else:
		b.label("Kirchmann's", "serif", "#4a2e1e", bl + Vector3(-13.4, 5.75, 0), Vector3(-1, 0, 0), 9.0, 1.0)
		b.label("FURNITURE", "sans", "#4a2e1e", bl + Vector3(-13.4, 4.95, 0), Vector3(-1, 0, 0), 4.0, 0.36)
	b.obst(["rect", bl.x - 12.0, bl.z - 22.0, bl.x + 12.0, bl.z + 22.0])
	# Ground Pat'i at the SW corner
	# across Bayou Gardens (4489 f071-083: "at that corner, across the road"), moved off the lot
	var gp = Vector3(-232.0, 0, 214.0)
	b.box(g, "ex_brick_brown", gp + UP * 2.2, Vector3(16.0, 4.4, 12.0), Transform3D.IDENTITY, ["-y"])
	b.box(g, "ex_roof_rust", gp + UP * 5.0, Vector3(18.0, 1.4, 14.0))
	b.box(g, "ex_roof_rust", gp + UP * 6.2, Vector3(15.0, 1.0, 11.0))
	b.obst(["rect", gp.x - 9.0, gp.z - 7.0, gp.x + 9.0, gp.z + 7.0])
	var sp = gp + Vector3(14.0, 0, 9.0)
	b.cyl(g, "ex_steel", sp, 0.2, 0.2, 7.0, 8, false)
	b.box(g, "ex_ivory", sp + UP * 8.5, Vector3(3.0, 3.0, 3.0))
	for d in [Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 0, -1)]:
		b.label("Ground Pat'i", "script", "#8a2a1a", sp + UP * 8.5 + d * 1.52, d, 2.7, 0.45)
	b.obst(["rect", sp.x - 0.4, sp.z - 0.4, sp.x + 0.4, sp.z + 0.4])
	# the apartments behind a wood fence (W), the soccer fields behind a black picket fence
	fence(b, "ex_fence_wood", [Vector3(-296.0, 0, 20.0), Vector3(-296.0, 0, 100.0)], 1.9)
	for i in 3:
		var ap = Vector3(-312.0, 0, 35.0 + i * 24.0)
		b.box(g, "ex_roof_dark", ap + UP * 3.5, Vector3(14.0, 7.0, 18.0), Transform3D.IDENTITY, ["-y"])
		b.box(g, "ex_roof_grey", ap + UP * 7.3, Vector3(15.0, 0.6, 19.0))
		b.obst(["rect", ap.x - 7.0, ap.z - 9.0, ap.x + 7.0, ap.z + 9.0])
	fence(b, "ex_fence_black", [Vector3(-296.0, 0, -60.0), Vector3(-296.0, 0, 10.0)], 1.2)
	b.quad("ex_ground", "ex_grass", [Vector3(-340.0, 0.03, -120.0), Vector3(-298.0, 0.03, -120.0), Vector3(-298.0, 0.03, 15.0), Vector3(-340.0, 0.03, 15.0)], UP, [], false, 0.1)
	# St. Bernadette's: cream building, green metal roof, beyond the fields
	var sb = Vector3(-330.0, 0, -80.0)
	b.box(g, "ex_stucco_cream", sb + UP * 3.0, Vector3(30.0, 6.0, 20.0), Transform3D.IDENTITY, ["-y"])
	b.box(g, "ex_cream_green_roof", sb + UP * 6.6, Vector3(32.0, 1.2, 22.0))
	b.obst(["rect", sb.x - 15.0, sb.z - 10.0, sb.x + 15.0, sb.z + 10.0])

static func strip(b, c, w, d, h):
	var g = "ex_far"
	b.box(g, "ex_stucco_cream", c + UP * (h * 0.5), Vector3(w, h, d), Transform3D.IDENTITY, ["-y"])
	for i in int(w / 7.0) + 1:
		b.box(g, "ex_brick_brown", c + Vector3(-w * 0.5 + i * 7.0, h * 0.5, -d * 0.5 - 0.2), Vector3(0.8, h, 0.4))
	b.box(g, "ex_roof_dark", c + UP * (h + 0.7) + Vector3(0, 0, -0.6), Vector3(w + 1.0, 1.4, d + 2.2))
	b.obst(["rect", c.x - w * 0.5, c.z - d * 0.5 - 1.0, c.x + w * 0.5, c.z + d * 0.5])

# ------------------------------------------------------------------ build
## Called by build_mall.gd for --wing=3. Returns the wing.json fields (spawn, walk, doors).
static func build(b):
	E = JSON.parse_string(FileAccess.get_file_as_string("res://exterior.json"))
	YEAR = int(b.YEAR)
	rng.seed = 1995
	trees = 0
	b.cur_color = Color.WHITE
	shell(b)
	fronts(b)
	service_bay(b)
	lot(b)
	tank(b)
	water_tower(b)
	outparcels(b)
	MON.build(b, YEAR)
	if YEAR == 2026:
		Y26.build(b, E.doors)
	# the building blocks the player: its footprint, in rectangles
	for r in E.roofs:
		b.obst(["rect", r[0], r[1], r[2], r[3]])
	print("exterior: ", E.segments.size(), " wall runs, ", E.doors.size(), " doors, ", trees, " trees")
	# the player starts on the main entrance's walk, looking at the doors
	return {"spawn": [52.0, 0.0, 90.0, 2.0], "walk": E.walk, "doors": E.doors}
