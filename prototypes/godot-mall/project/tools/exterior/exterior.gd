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
const FL = preload("res://tools/exterior/flora.gd")   # Workstream LOT: trees, shrubs, planters
const RACK = preload("res://tools/exterior/wave_rack.gd")   # EXT-LAYOUT: the 3-loop wave bike rack

# ---- heights (parapets, metres): the report's table
const H_DEFAULT = 6.5     # store backs, the east facade
const H_SOUTH_BACKS = 5.0 # the Concourse's south row, from the south entrance to Dillard's
const H_SEARS = 9.0
const H_CINEMA = 6.8       # EXT-LAYOUT: 6.3-6.7 m off 4486 f001, f014, f016 against the 2.1 m doors (was 9)
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
# EXT-LAYOUT (Nov 8 2026): the west faces at the cinema-wing exit (wall_fixes.py FILLS; design/godot-exterior.md
# "Nov 8 refinements"): the exit's glass at x -78 sits at the end of a channel between Lynn's SW corner and
# the cinema's north face
const SEARS_W = -84.0
const CINEMA_W = -98.0
# the Sears truck well (sunk 1.2 m) and the x where its ramp up to the lot begins
const WELL = [SEARS_W - 35.0, -118.0, SEARS_W - 3.0, -101.0]
const WELL_RAMP = SEARS_W - 23.0

static var E = {}          # exterior.json
static var rng = RandomNumberGenerator.new()
static var trees = 0
static var YEAR = 1995     # --year=2026 builds the outside as filmed on Oct 23 2026 (exterior_2026.gd)
## The Bayou Gardens drive (Workstream F): the gap in the palm island in front of the south
## entrance, x0..x1, where the monument sign stands (tools/exterior/monuments.gd)
const BAYOU_DRIVE = [-150.0, -134.0]
const TANK_UTILITY = false            # EXT-LOT: the tank yard's utility building and conduit pole (Steven: remove)                  # EXT-LOT: the curbed throat past the returns, before the stall rows start

## EXT-B (Nov 4 2026): the roads at the site plan's places (design/exterior-sequence.md §4, §5 #9).
const ROAD_WEST_PARK = 112.0     # x of West Park Ave's centreline (curb ~106)
const ROAD_BAYOU = 216.0         # z of Bayou Gardens Blvd (curb ~210)
const ROAD_ARMOUR = -252.0       # z of Armour Dr (curb ~-247.5)
const LOT_WEST = -360.0          # the west lot's edge (the parcel line is -383)
## Ground Pat'i's x across Bayou Gardens (Steven, Nov 8: directly across from the mall). Opposite Dillard's
## (x -38..44) from 4492 f105-107; Steven to confirm against the south pavilion (x ~ -140) or JCPenney (~ -184).
const GROUND_PATI = 20.0
## The apartments' land: nothing of the mall's north of z -150 west of x -120 (site plan)
# EXT-LAYOUT: the east fence moved from x -120 to -128 so Unitech's plan footprint (x -122..-82) has its drive
const APTS = [-400.0, -290.0, -128.0, -150.0]

static var KEEP = []             # rectangles the stall fields stay out of [x0, z0, x1, z1]
static var ROWS = []             # EXT-LOT: every stall row lot_field painted {p, t, n, field, row} (ada_stalls reads it)
static var FIELD = 0             # EXT-LOT: lot_field's running field number

static var b_ref = null

# ------------------------------------------------------------------ materials
static func fill_mat(m, key, b):
	var tx = func(f, rough): m.albedo_texture = b.tex("ex/" + f + ".png"); m.roughness = rough
	match key:
		"brick_cream": tx.call("brick_cream", 0.85)
		"brick_salmon":
			tx.call("brick_salmon", 0.85)
			m.albedo_color = Color(0.76, 0.8, 0.8)   # EXT-LAYOUT: the dusty rose of 4486 f016-f030, not orange
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
		"concrete_lot":
			# Steven (Nov 8): the lot is concrete in both years, as filmed (4487 f034, 4492 f060): jointed
			# exposed-aggregate panels, 6 m. paint_lot.py concrete(); the joints are thin sealed lines that
			# the mipmaps fade with distance (the old 'tile lines' were thick black joints with no mipmaps).
			m.albedo_texture = b.tex("ex/ex_concrete_alb.png")
			m.roughness_texture = b.tex("ex/ex_concrete_rgh.png"); m.roughness = 1.0; m.metallic = 0.0
			m.normal_enabled = true; m.normal_texture = b.tex("ex/ex_concrete_nrm.png"); m.normal_scale = 0.6
			m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
			m.vertex_color_use_as_albedo = true
			# 1995 younger and cleaner; 2026 weathered, a shade darker and warmer
			m.albedo_color = Color(0.74, 0.73, 0.71) if YEAR != 2026 else Color(0.66, 0.64, 0.61)
		"asphalt", "asphalt_lot":
			# Workstream LOT (Nov 8 2026): the lot is asphalt with exposed aggregate (paint_lot.py), the
			# roads the same mix a little darker; the lot's ground carries a slow vertex-colour mottle that
			# hides the 8 m repeat (lot_ground). 1995 is a younger, darker surface than today's faded grey.
			m.albedo_texture = b.tex("ex/ex_asphalt_alb.png")
			m.roughness_texture = b.tex("ex/ex_asphalt_rgh.png"); m.roughness = 1.0; m.metallic = 0.0
			m.normal_enabled = true; m.normal_texture = b.tex("ex/ex_asphalt_nrm.png"); m.normal_scale = 0.7
			m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
			var lum = (0.64 if YEAR == 2026 else 0.50) * (0.82 if key == "asphalt" else 1.0)
			m.albedo_color = Color(lum, lum, lum * 1.01)
			if key == "asphalt_lot":
				m.vertex_color_use_as_albedo = true
		"stripe_white", "stripe_yellow", "stripe_ghost", "lot_ada_blue":
			# worn stall paint (paint_lot.py ex_paint_worn: alpha = paint left, the stones show through);
			# the stripe's vertex alpha fades each line a little differently
			m.albedo_texture = b.tex("ex/ex_paint_worn.png")
			m.albedo_color = {"stripe_white": Color("#ecebe4"), "stripe_yellow": Color("#e0b92c"), "stripe_ghost": Color(0.92, 0.92, 0.9, 0.22),
				"lot_ada_blue": Color("#2f6fc0")}[key]   # EXT-LOT: the access aisles' hatching
			m.vertex_color_use_as_albedo = true
			m.roughness = 0.85; m.metallic = 0.0
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		"lot_decal":
			m.albedo_texture = b.tex("ex/ex_lot_decals.png"); m.roughness = 0.8; m.metallic = 0.0
			# tinted a little with the year's weathering (cracks and oil read dark on the concrete)
			var dl = 0.85 if YEAR == 2026 else 0.95
			m.albedo_color = Color(dl, dl, dl * 0.98)
			m.vertex_color_use_as_albedo = true
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		"walk":
			# the sidewalks round the building: broom-finished concrete in ~1.65 m panels (concrete_panel's
			# joints at walk scale)
			tx.call("concrete_panel", 0.9); m.albedo_color = Color(1.04, 1.03, 1.0)
		"mulch": tx.call("mulch", 1.0)
		"grass": tx.call("grass", 1.0)
		"chainlink":
			m.albedo_texture = b.tex("ex/chainlink.png"); m.roughness = 0.7; m.metallic = 0.0
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR; m.alpha_scissor_threshold = 0.5
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
		"coping": m.albedo_color = Color("#e8e4dc"); m.roughness = 0.6
		"coping_dark": m.albedo_color = Color("#4a4642"); m.roughness = 0.7
		"soldier": m.albedo_color = Color("#3b2e28"); m.roughness = 0.8
		"peach_pier": m.albedo_color = Color("#e3b89a"); m.roughness = 0.88
		"cream_pier": m.albedo_color = Color("#efe6d2"); m.roughness = 0.85
		"white_wainscot": m.albedo_color = Color("#f2efe8"); m.roughness = 0.85
		"beige_door": m.albedo_color = Color("#c9bda4"); m.roughness = 0.6
		"wall_pack": m.albedo_color = Color("#8a8580"); m.roughness = 0.6
		"bollard_yellow": m.albedo_color = Color("#e9c21d"); m.roughness = 0.5
		"pipe_yellow": m.albedo_color = Color("#f0c419"); m.roughness = 0.6
		"pipe_grey": m.albedo_color = Color("#9a9a96"); m.roughness = 0.65
		"pole_white": m.albedo_color = Color("#eceae4"); m.roughness = 0.55
		"pedestal": m.albedo_color = Color("#d9c23a"); m.roughness = 0.8
		"shoebox": m.albedo_color = Color("#3a3a38"); m.roughness = 0.6
		"lamp":
			m.albedo_color = Color("#fff0c8"); m.emission_enabled = true; m.emission = Color("#ffc46a")
			m.emission_energy_multiplier = 3.0; m.set_meta("e_day", 0.0); m.set_meta("e_night", 3.0)
		"curb_yellow": m.albedo_color = Color("#e4c52c"); m.roughness = 0.8
		"curb": m.albedo_color = Color("#9e9a91"); m.roughness = 0.92
		"tank_white": m.albedo_color = Color("#e4e3df"); m.roughness = 0.7
		"tank_rust": m.albedo_color = Color("#8d6b4a"); m.roughness = 0.9
		"steel": m.albedo_color = Color("#6f6f6c"); m.roughness = 0.6
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
		"fence_black": m.albedo_color = Color("#1e1e1e"); m.roughness = 0.6
		"roof_grey": m.albedo_color = Color("#8f8b84"); m.roughness = 0.95
		"roof_dark": m.albedo_color = Color("#4a4744"); m.roughness = 0.9
		"roof_rust": m.albedo_color = Color("#7a3f28"); m.roughness = 0.75
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
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR; m.alpha_scissor_threshold = 0.5
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
		"acm_white": tx.call("acm_white", 0.45)
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
		"black_steel": m.albedo_color = Color("#1c1c1e"); m.roughness = 0.6
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
		"rack": return RACK.fill_mat(m, key, b)     # EXT-LAYOUT: the wave bike rack's chipped paint
		_:
			return FL.fill_mat(m, key, b)
	return true

# ------------------------------------------------------------------ helpers
static func V(a):
	return Vector3(a[0], 0, a[1])

## A textured wall quad from a to b (ground level up to top), facing n; the texture covers 2 m.
## Workstream LOT (Nov 8 2026): while DEFER is on (build()), walls are held back and drawn at the end by
## flush_walls(), which leaves out the strips hidden behind the wainscots, base bands and doors laid flat
## on them (COVERS). A wall face behind such a box has every lightmap texel inside geometry; the bake
## marks them invalid and the denoiser smeared their black up the visible wall: the dark band Steven saw
## along the foot of Dillard's and JCPenney.
static func wall(b, g, mname, a, bb, n, y0, y1, scale = 0.5):
	if DEFER:
		PENDING.append([g, mname, a, bb, n, y0, y1, scale])
		return
	b.quad(g, mname, [a + UP * y0, bb + UP * y0, bb + UP * y1, a + UP * y1], n, [], false, scale)

## A box along a run: from u0 to u1 along t, y0..y1 high, standing `out` proud of the wall, `deep`.
## A box laid flat on the wall (out == deep) from the ground up is remembered as a cover (flush_walls).
## dyn: unbaked (probe-lit) geometry that does not take part in the bake (thin scoring lines).
static func run_box(b, g, mname, a, t, n, u0, u1, y0, y1, out, deep, skip = [], dyn = false):
	var c = a + t * ((u0 + u1) * 0.5) + UP * ((y0 + y1) * 0.5) + n * (out - deep * 0.5)
	b.box(g, mname, c, b.abs_size(t, u1 - u0, y1 - y0, deep, n), Transform3D.IDENTITY, skip, dyn)
	if not dyn and abs(out - deep) < 0.005 and y0 <= 0.01 and y1 > 0.3:
		COVERS.append([a + t * u0, a + t * u1, n, y1])

static var DEFER = false
static var PENDING = []
static var COVERS = []

## Draws the held-back walls, each cut where covers stand flat on it from the ground: per stretch of the
## wall the visible quad starts at the highest cover's top. Stretches with no cover are drawn whole.
static func flush_walls(b):
	DEFER = false
	var cut = 0
	for w in PENDING:
		var a = w[2]; var bb = w[3]; var n = w[4]; var y0 = w[5]; var y1 = w[6]
		var L = a.distance_to(bb)
		if L < 0.01:
			continue
		var t = (bb - a) / L
		var iv = []
		for cv in COVERS:
			if cv[2].dot(n) < 0.99 or abs(n.dot(cv[0] - a)) > 0.03 or cv[3] <= y0 + 0.01:
				continue
			var s0 = t.dot(cv[0] - a); var s1 = t.dot(cv[1] - a)
			if s0 > s1:
				var tmp = s0; s0 = s1; s1 = tmp
			s0 = max(s0, 0.0); s1 = min(s1, L)
			if s1 - s0 > 0.05:
				iv.append([s0, s1, min(cv[3], y1)])
		if iv.is_empty():
			b.quad(w[0], w[1], [a + UP * y0, bb + UP * y0, bb + UP * y1, a + UP * y1], n, [], false, w[7])
			continue
		var bp = [0.0, L]
		for v in iv:
			bp.append(v[0]); bp.append(v[1])
		bp.sort()
		var runs = []    # [s0, s1, ybottom], merged
		for k in bp.size() - 1:
			var sa = bp[k]; var sb = bp[k + 1]
			if sb - sa < 0.001:
				continue
			var m = (sa + sb) * 0.5
			var yb = y0
			for v in iv:
				if m > v[0] and m < v[1]:
					yb = max(yb, v[2])
			if not runs.is_empty() and abs(runs[-1][2] - yb) < 0.001 and abs(runs[-1][1] - sa) < 0.001:
				runs[-1][1] = sb
			else:
				runs.append([sa, sb, yb])
		for r in runs:
			if r[2] >= y1 - 0.001:
				cut += 1
				continue
			var pa = a + t * r[0]; var pb = a + t * r[1]
			b.quad(w[0], w[1], [pa + UP * r[2], pb + UP * r[2], pb + UP * y1, pa + UP * y1], n, [], false, w[7])
			if r[2] > y0:
				cut += 1
	print("exterior: walls drawn ", PENDING.size(), ", stretches cut behind base boxes ", cut)
	PENDING = []
	COVERS = []

## A box turned yaw radians about its own centre (build_mall.gd's box turns about the origin).
static func rbox(b, g, mname, c, size, yaw):
	var bs = Basis(UP, yaw)
	b.box(g, mname, c, size, Transform3D(bs, c - bs * c))

## Workstream LOT (Nov 8 2026): the trees and shrubs are flora.gd's (live oak, sabal, pine, shrub);
## the old ones borrowed the interior's potted palm (a 7 cm trunk) and the card bush with its flat top.
static func tree_oak(b, at, size):
	trees += 1
	FL.live_oak(b, at, size)

static func tree_pine(b, at, hgt):
	trees += 1
	FL.pine(b, at, hgt)

static func palm(b, at, hgt):
	trees += 1
	FL.sabal(b, at, hgt)

static func shrub(b, at, mname, size):
	FL.shrub(b, at, size * 0.65)

## A curbed island. Workstream LOT (Nov 8 2026): a landscaped planter (flora.gd planter: a low, wide
## 10 cm concrete curb, mulch, 3-5 shrubs / grass clumps with variation when `plants`, a sabal in the
## big ones when `palm`) instead of the tall single-shrub box. The lot's curbs are grey in 1995 (a GUESS:
## no period photo) and painted yellow in 2026, as filmed (4492 f060-066, 4487); callers that ask for
## "ex_curb" (the roads' islands) stay grey in both years.
static func island(b, x0, z0, x1, z1, top = "ex_mulch", curb = "ex_curb_yellow", plants = false, palm = false):
	if curb == "ex_curb_yellow" and YEAR != 2026:
		curb = "ex_curb"
	FL.planter(b, x0, z0, x1, z1, curb, top, palm, plants)

## A painted line just above the lot. Workstream LOT (Nov 8 2026): worn paint (paint_lot.py), each line
## faded a little differently (vertex alpha) and laid with a hand's error (a centimetre or two), so the
## stalls stop reading as a perfect grid. Stall paint: yellow in both years (Steven: the 1990s lot was
## yellow; 2026 fresh yellow over a ghost white grid, 4487 f034, notes_D).
static func stripe(b, a, bb, w = 0.1, mname = "", fade = -1.0):
	if mname == "":
		mname = "ex_stripe_yellow"
	if fade < 0.0:
		fade = rng.randf_range(0.70, 0.95) if YEAR == 2026 else rng.randf_range(0.55, 0.85)
	var t = (bb - a).normalized()
	var s = Vector3(-t.z, 0, t.x) * (w * 0.5)
	var j = Vector3(-t.z, 0, t.x) * rng.randf_range(-0.015, 0.015)
	var L = a.distance_to(bb)
	var v0 = rng.randf() * 8.0
	var y = UP * (0.012 if mname != "ex_stripe_ghost" else 0.010)
	b.cur_color = Color(1, 1, 1, fade)
	b.quad("ex_paint", mname, [a - s + y, bb - s + y + j, bb + s + y + j, a + s + y], UP,
		[Vector2(0, v0 / 8.0), Vector2(0, (v0 + L) / 8.0), Vector2(1, (v0 + L) / 8.0), Vector2(1, v0 / 8.0)], true)
	b.cur_color = Color.WHITE

## A double row of stalls: the row runs from p along t for `len` metres; stalls either side,
## 2.7 m wide, 5.5 m deep (two rows back to back = 11 m). 2026 also shows the faint white grid the
## yellow was painted over (4487 f034), half a stall off. An oil stain in about one stall in four.
static func stall_row(b, p, t, len):
	var s = Vector3(-t.z, 0, t.x)
	var n = int(len / 2.7)
	for i in n + 1:
		var q = p + t * (i * 2.7)
		stripe(b, q - s * 5.5, q + s * 5.5)
		if YEAR == 2026 and i < n:
			var g = q + t * 1.2
			stripe(b, g - s * 5.3, g + s * 5.3, 0.1, "ex_stripe_ghost", rng.randf_range(0.5, 1.0))
	stripe(b, p, p + t * (n * 2.7), 0.12)
	for i in n:
		for side in [-1.0, 1.0]:
			if rng.randf() < 0.28:
				var c = p + t * (i * 2.7 + 1.35) + s * (side * rng.randf_range(2.2, 3.4))
				lot_decal(b, c, t, 3, rng.randf_range(0.9, 1.5), rng.randf_range(0.35, 0.8))

## A wear decal on the asphalt (paint_lot.py ex_lot_decals cells: 0 sealed crack, 1 alligator cracks,
## 2 a patch, 3 an oil stain), `size` metres across, turned to t, faded by `fade`.
static func lot_decal(b, c, t, cell, size, fade = 1.0):
	var u0 = 0.5 * (cell % 2); var v0 = 0.5 * int(cell / 2)
	var s = Vector3(-t.z, 0, t.x)
	var h = size * 0.5
	var y = UP * 0.007
	b.cur_color = Color(1, 1, 1, fade)
	b.quad("ex_paint", "ex_lot_decal", [c - t * h - s * h + y, c + t * h - s * h + y, c + t * h + s * h + y, c - t * h + s * h + y], UP,
		[Vector2(u0, v0 + 0.5), Vector2(u0 + 0.5, v0 + 0.5), Vector2(u0 + 0.5, v0), Vector2(u0, v0)], true)
	b.cur_color = Color.WHITE

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
		# EXT-B: the box's south return in the east entrance's recess wears the charcoal eyebrow band
		# (4406 f031-035)
		return {"mat": "ex_block_white", "h": H_SEARS, "eyebrow": side == "S" and seg.a[0] >= 30}
	if nm == "SEARS RETURN":
		# EXT-B: the white painted-brick return north of the cinema-side exit, the bike rack's wall.
		# EXT-LAYOUT: a low block at Lynn's SW corner, painted brick (4416 f009), ~4.2 m (4486 f002, f014)
		return {"mat": "ex_paint_white", "h": 4.2}
	if nm == "PAVILION":
		return {"mat": "ex_eifs_pav" if YEAR == 2026 else "ex_stucco_cream", "h": H_SOUTH_PAV}
	if nm == "DILLARD'S":
		return {"mat": "ex_stucco_peach", "h": H_DILLARDS}
	if nm == "JCPENNEY":
		# EXT-B: the customer faces (west at x -214, south) 7.5 m; the rear block and the north face 9.5 m
		var front = (side == "W" and seg.a[0] > -220.0 and seg.a[1] >= 32.0) or side == "S" and seg.a[1] > 100.0
		return {"mat": "ex_brick_cream", "h": H_JCP_FRONT if front else H_JCP_REAR}
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
	# EXT-B: the east facade between the Shoe Dept box and Dillard's: today the blank white ACM wall
	# with the loading lane in front (4492 f081-108); 1995 the facade's panels
	if YEAR == 2026 and side == "E" and seg.a[0] >= 44.0 and seg.a[1] >= 50.0 and seg.a[1] < 80.0:
		return {"mat": "ex_acm_white", "h": 8.2}
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
	return m.x > -44.0 and m.x < -18.0 and m.z > 68.0 and m.z < 118.5

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
		if seg.store == "s41":
			continue    # EXT-LAYOUT: the cinema-wing exit's recess, fascia and soffit are cinema_exit()'s
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
		# LOT: 0.16 deep (was 0.6, which ran through the taller masses' faces 5 cm behind the wall)
		run_box(b, g, "ex_coping" if sk.mat != "ex_brick_red" else "ex_coping_dark", a, t, n, 0.0, Ln, h - 0.08, h + 0.1, 0.12, 0.16)
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
		if s.has("entrance"):
			unitech_box(b, r, y, s.entrance)   # EXT-LOT: the box with its recessed entrance
		else:
			b.box("ex_shell", "ex_block_white", Vector3((r[0] + r[2]) * 0.5, y * 0.5, (r[1] + r[3]) * 0.5), Vector3(r[2] - r[0], y, r[3] - r[1]), Transform3D.IDENTITY, ["-y"])
		# EXT-LAYOUT (Nov 8 2026, Steven): unsigned in both years ("Old Sears Hardware" on his plan; a historian
		# pass will settle what it read in the 1990s). It carried "UNITECH" in 2026 before.
		b.box("ex_shell", "ex_coping", Vector3((r[0] + r[2]) * 0.5, y + 0.05, (r[1] + r[3]) * 0.5), Vector3(r[2] - r[0] + 0.2, 0.12, r[3] - r[1] + 0.2))
		b.obst(["rect", r[0], r[1], r[2], r[3]])

## EXT-LOT (Nov 9 2026, Steven, Demo 53: "Sears Hardware in 1995, Unitech(?) today"; the arch he drew at the centre
## of the long lot-facing face): the white box with a modest recessed vestibule there, both years. exterior.json
## `standalone[].entrance` (make_exterior.py) gives the face (S, z = r[3]), the doorway's centre, width, recess depth,
## door head and soffit; EXT-SIGNS reads the same record for the sign above. The box is built as the back block plus
## two piers and a lintel round the recess. Period storefront (both years, 1970s-90s commercial): clear-anodized
## aluminium frame, two pairs of full-glass doors with push bars, a sidelight each side, a transom to the soffit,
## a white soffit with two cans, a concrete floor a step proud of the lot. VISUAL ONLY: the box has no inside, so
## the doors are not in `doors` and the recess is not on the walk grid (the box's obstacle covers it).
static func unitech_box(b, r, y, en):
	var g = "ex_shell"
	var W = float(en.width); var D = float(en.recess); var so = float(en.soffit)
	var xm = float(en.mid[0]); var zf = r[3]
	var zb = zf - D                 # the recess's back wall (the storefront)
	var xa = xm - W * 0.5; var xb = xm + W * 0.5
	# the back block (all but the front D metres), the two piers either side of the recess, the lintel over it
	b.box(g, "ex_block_white", Vector3((r[0] + r[2]) * 0.5, y * 0.5, (r[1] + zb) * 0.5), Vector3(r[2] - r[0], y, zb - r[1]), Transform3D.IDENTITY, ["-y", "+z"])
	b.box(g, "ex_block_white", Vector3((r[0] + xa) * 0.5, y * 0.5, (zb + zf) * 0.5), Vector3(xa - r[0], y, D), Transform3D.IDENTITY, ["-y", "-z"])
	b.box(g, "ex_block_white", Vector3((xb + r[2]) * 0.5, y * 0.5, (zb + zf) * 0.5), Vector3(r[2] - xb, y, D), Transform3D.IDENTITY, ["-y", "-z"])
	b.box(g, "ex_block_white", Vector3(xm, (so + y) * 0.5, (zb + zf) * 0.5), Vector3(W, y - so, D), Transform3D.IDENTITY, ["-z", "+x", "-x", "-y"])
	# the soffit (white, two cans) and the vestibule's floor, a 0.1 m step
	b.quad(g, "ex_soffit_white", [Vector3(xa, so - 0.01, zb), Vector3(xb, so - 0.01, zb), Vector3(xb, so - 0.01, zf), Vector3(xa, so - 0.01, zf)], -UP)
	for k in 2:
		b.cyl(g, "ex_can", Vector3(xm - 1.6 + k * 3.2, so - 0.03, (zb + zf) * 0.5), 0.12, 0.12, 0.02, 10, false, true)
	b.box("ex_lot", "ex_curb", Vector3(xm, 0.05, (zb + zf) * 0.5 + 0.15), Vector3(W, 0.1, D + 0.3), Transform3D.IDENTITY, ["-y"])
	# the storefront on the back wall (the back block's +z face is not drawn: the piers cover it either side, the
	# dark glass and the frame close the recess)
	var gz = zb + 0.02
	b.quad(g, "ex_glass_dark", [Vector3(xa, 0.0, gz), Vector3(xb, 0.0, gz), Vector3(xb, so, gz), Vector3(xa, so, gz)], Vector3(0, 0, 1))
	var dh = float(en.h)
	var posts = [xa + 0.05, xa + 1.0, xm - 1.8, xm, xm + 1.8, xb - 1.0, xb - 0.05]   # sidelight | pair | pair | sidelight
	for px in posts:
		b.box(g, "ex_mullion", Vector3(px, (so + 0.1) * 0.5, zb + 0.06), Vector3(0.1, so - 0.1, 0.12))
	b.box(g, "ex_mullion", Vector3(xm, dh + 0.05, zb + 0.06), Vector3(W, 0.12, 0.12))      # the transom bar at the door head
	b.box(g, "ex_mullion", Vector3(xm, 0.15, zb + 0.06), Vector3(W, 0.1, 0.12))            # the sill
	b.box(g, "ex_mullion", Vector3(xm, so - 0.05, zb + 0.06), Vector3(W, 0.1, 0.12))       # the head
	for k in 4:
		# each leaf: a 0.12 m stile frame (bottom rail 0.25), a push bar at 1.0 m
		var x0 = xm - 1.8 + k * 0.9
		b.box(g, "ex_mullion", Vector3(x0 + 0.45, 0.25, zb + 0.08), Vector3(0.9, 0.25, 0.06))
		b.box(g, "ex_mullion", Vector3(x0 + 0.06, (0.1 + dh) * 0.5, zb + 0.08), Vector3(0.08, dh - 0.1, 0.06))
		b.box(g, "ex_mullion", Vector3(x0 + 0.84, (0.1 + dh) * 0.5, zb + 0.08), Vector3(0.08, dh - 0.1, 0.06))
		b.box(g, "ex_stainless", Vector3(x0 + 0.45, 1.0, zb + 0.13), Vector3(0.7, 0.05, 0.05))
	b.tag(b.add_spot(Vector3(xm, so - 0.1, (zb + zf) * 0.5), -UP, 1.5, 8.0, 50.0, Color("#FFE6C2")), "night")

## The taller masses stand above the low roof: Sears, Dillard's, JCPenney's rear block, the cinema
## auditorium box, the Woolworth block, the south pavilion. Their roofs and inner sides.
static func masses(b):
	var g = "ex_shell"
	var M = [
		# EXT-B: the real footprint (design/exterior-sequence.md §5); each mass 5 cm inside its walls
		["ex_block_white", SEARS_W, -146.0, 44.0, -96.0, H_SEARS],     # EXT-LAYOUT: west face x -84
		["ex_stucco_peach", -38.0, 80.0, 44.0, 138.0, H_DILLARDS],
		["ex_brick_cream", -212.0, -14.0, -154.0, 106.0, H_JCP_REAR],
		["ex_brick_cream", -228.0, -6.0, -214.0, 32.0, H_JCP_REAR],
		["ex_brick_salmon", CINEMA_W, -86.0, -52.0, -42.0, H_CINEMA],  # EXT-LAYOUT: west face x -98
		["ex_brick_red", -74.0, -14.0, -10.0, 22.0, H_WOOL],
		["ex_eifs_pav" if YEAR == 2026 else "ex_stucco_cream", -146.0, 92.0, -134.0, 112.0, H_SOUTH_PAV]]
	for m in M:
		var e = 0.05
		var c = Vector3((m[1] + m[3]) * 0.5, (6.0 + m[5]) * 0.5, (m[2] + m[4]) * 0.5)
		b.box(g, m[0], c, Vector3(m[3] - m[1] - e * 2.0, m[5] - 6.0, m[4] - m[2] - e * 2.0), Transform3D.IDENTITY, ["-y", "+y"])
		# LOT: inset like the box; the 5 cm overhang over the box's faces put their top texels under a
		# backface (the black band on JCPenney's taller block in the Demo 52 bake)
		b.quad("ex_roof", "ex_roof_grey", [Vector3(m[1] + e, m[5], m[2] + e), Vector3(m[3] - e, m[5], m[2] + e), Vector3(m[3] - e, m[5], m[4] - e), Vector3(m[1] + e, m[5], m[4] - e)], UP, [], false, 0.1)
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
	# SMALLFIX (Nov 8 2026): one sign, on the canopy's fascia. Until now a second, bigger
	# "SOUTHLAND MALL" stood on the wall at 6.3 m behind the canopy, which cut it from the lot
	# (d52-w3-1995-entrance-sign-doubled-baked.jpg). The kept one takes that one's dark bronze so it
	# reads on the cream fascia (it was cream on cream).
	b.label("SOUTHLAND MALL", "serif", "#4a3a2a", slab + n * 3.21 + UP * 0.0, n, 12.0, 0.45)

## The south entrance (s55, Bayou Gardens): a pavilion ~12 m wide in line with the wing wall's
## front (z 118), a deep loggia with the doors at its back (z 112), big square pilasters on the front
## corners, a thin flat white cornice slab overhanging ~1.3 m, the set-back link to JCPenney's brick,
## the drop-off bulb with its live oak (4489 f031-058). EXT-B (Nov 4 2026): moved out from z 92-99 to
## the site plan's line (Steven, Nov 3: the wall runs from the pavilion to the Dillard's side). The
## mass and position are original; 2026 wears today's peach EIFS and dark tile bands, 1995 cream (a GUESS).
static func south_entrance(b):
	var g = "ex_entry"
	var y26 = YEAR == 2026
	var wallm = "ex_eifs_pav" if y26 else "ex_stucco_cream"
	var pier = "ex_cream_pier"
	var zb = 112.0; var z1 = 118.0                  # the loggia's back (the doors) and front
	var x0 = -146.0; var x1 = -134.0
	var top = H_SOUTH_PAV
	# the loggia's side walls, full height, and the block over it
	for xs in [[x0 - 0.03, x0 + 1.2], [x1 - 1.2, x1 + 0.03]]:
		b.box(g, wallm, Vector3((xs[0] + xs[1]) * 0.5, top * 0.5, (zb + z1) * 0.5), Vector3(xs[1] - xs[0], top, z1 - zb), Transform3D.IDENTITY, ["-y"])
		b.obst(["rect", xs[0], zb, xs[1], z1])
	b.box(g, wallm, Vector3((x0 + x1) * 0.5, (4.6 + top) * 0.5, (zb + z1) * 0.5), Vector3(x1 - x0 - 2.4, top - 4.6, z1 - zb), Transform3D.IDENTITY, ["-y"])
	b.quad(g, "ex_soffit_white" if not y26 else wallm, [Vector3(x0 + 1.2, 4.6, zb), Vector3(x1 - 1.2, 4.6, zb), Vector3(x1 - 1.2, 4.6, z1), Vector3(x0 + 1.2, 4.6, z1)], -UP)
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
		b.box(g, "ex_coping_dark", pc + UP * (top - 1.6) + Vector3(0, 0, 0.46), Vector3(0.18, 1.6, 0.02))
		b.box(g, "ex_white_wainscot", pc + UP * (top - 0.3), Vector3(1.45, 0.2, 1.05))
		b.obst(["rect", px - 0.7, z1 - 0.3, px + 0.7, z1 + 0.6])
	# the thin flat white cornice slab over the whole pavilion, overhanging ~1.3 m
	b.box(g, "ex_white_wainscot", Vector3((x0 + x1) * 0.5, top + 0.15, (92.0 + z1) * 0.5 + 0.6), Vector3(x1 - x0 + 2.6, 0.3, z1 - 92.0 + 2.6))
	b.box(g, "ex_white_wainscot", Vector3((x0 + x1) * 0.5, top - 0.45, z1 + 0.62), Vector3(x1 - x0, 0.6, 0.08))
	# the back wall: cream wainscot and a white chair rail, the doors between
	var a = Vector3(x0 + 1.2, 0, zb); var n = Vector3(0, 0, 1); var t = Vector3(1, 0, 0); var Ln = x1 - x0 - 2.4
	run_box(b, g, pier, a, t, n, 0.0, Ln, 0.0, 1.2, 0.05, 0.05)
	run_box(b, g, "ex_white_wainscot", a, t, n, 0.0, Ln, 1.2, 1.3, 0.07, 0.07)
	for i in 4:
		run_box(b, g, "ex_bronze", a, t, n, 0.6 + i * 2.6 - 0.05, 0.6 + i * 2.6 + 0.05, 0.0, 3.4, 0.0, 0.14)
	run_box(b, g, "ex_bronze", a, t, n, 0.6, 8.4, 2.35, 2.5, 0.0, 0.14)
	b.quad("ex_glass", "ex_glass", [a + t * 0.6 + n * 0.08, a + t * 8.4 + n * 0.08, a + t * 8.4 + n * 0.08 + UP * 3.4, a + t * 0.6 + n * 0.08 + UP * 3.4], n, [], true)
	for k in 2:
		var cz = zb + 1.6 + k * 2.8
		b.cyl(g, "ex_can", Vector3(-140.0, 4.58, cz), 0.12, 0.12, 0.02, 10, false, true)
		b.tag(b.add_spot(Vector3(-140.0, 4.5, cz), -UP, 1.5, 7.0, 60.0, Color("#FFE6C2")), "night")
	for xx in [-143.6, -136.4]:
		trash_can(b, Vector3(xx, 0, zb + 1.0))
	# the bike rack on JCPenney's brick beside the link (4489 f041-046)
	wave_rack(b, Vector3(-151.0, 0, 110.9), Vector3(1, 0, 0))
	if y26:
		# the east bay's black flat steel canopy hung on tie-rods, over a dark glass door (4489 f034)
		var ea = Vector3(-129.0, 0, z1)
		b.box(g, "ex_black_steel", ea + Vector3(0, 3.4, 1.2), Vector3(3.6, 0.12, 2.4))
		for sx in [-1.5, 1.5]:
			var p0 = ea + Vector3(sx, 3.45, 2.3); var p1 = ea + Vector3(sx, 4.6, 0.05)
			var m = (p0 + p1) * 0.5; var dir = (p1 - p0).normalized()
			b.box(g, "ex_steel", Vector3.ZERO, Vector3(0.03, p0.distance_to(p1), 0.03), Transform3D(Basis(Vector3(1, 0, 0), dir, Vector3(1, 0, 0).cross(dir)), m))
		b.box(g, "ex_glass_dark", ea + Vector3(0, 1.2, 0.03), Vector3(1.9, 2.4, 0.04))
	# the drop-off bulb: a curbed island out front, past the drive lane
	island(b, -150.0, 127.0, -130.0, 131.0, "ex_grass", "ex_curb")
	tree_oak(b, Vector3(-140.0, 0.08, 129.0), 4.5)
	for xx in [-147.0, -133.0]:
		shrub(b, Vector3(xx, 0.08, 129.0), "leafy", 1.1)

## The cinema-wing exit (s41, the Sears hall's west end): brown exposed-aggregate precast fascia
## ~1 m deep, white soffit with cans, a 2-tier clear-anodized curtain wall with 2 door pairs; the
## white painted-brick return north of it with the 3-loop bike rack along it, the poster case on the
## cinema's buff wall south of it (4416 f002/f010, 4417, 4486 f002-003). EXT-B: the cinema box and
## the white return are now flush with the doors (§5 #1, #2), as filmed.
## The cinema-wing exit (s41, "Southland Cinema Mall Entrance" on Steven's plan). EXT-LAYOUT (Nov 8 2026),
## measured off 4416 f002-f005 against the 2.1 m doors (design/godot-exterior.md "Nov 8 refinements"):
## a brown exposed-aggregate precast fascia 1.3 m deep (4.4..5.7 m) on the outer plane (x -80) with a
## white metal cap; a real white soffit 2 m deep with recessed cans; the clear-anodized storefront set
## back under it at x -78 (3 fixed bays, two door pairs with push bars and panic plates, two sidelights
## with mid rails, transom glass to the soffit); the recess's north side the white painted brick of the
## Sears return, its south side buff brick with the poster case (4417) and a rusty pipe post at the
## corner (4416 f004); past a 0.9 m buff pier the salmon cinema brick runs south. The 3-loop wave rack
## stands along the channel's north wall (the low white block's south face, z -96), 0.5 m off it, on the
## left as you face the doors (Steven, Nov 8; 4416 f009-f011, 4486 f002-f003). The exit is the end of a 10 m wide, 20 m deep channel between
## Lynn's SW corner and the cinema's north face (4486 f014; cinema_box()).
const EXIT_X = -80.0      # the outer plane (the fascia, the returns, the cinema's west wall)
const EXIT_GLASS = -78.0  # the storefront
const EXIT_SOFFIT = 4.4
const EXIT_FASCIA = 1.3
static func cinema_exit(b):
	var g = "ex_entry"
	var z0 = -96.0; var z1 = -86.0
	var a = Vector3(EXIT_X, 0, z0); var n = Vector3(-1, 0, 0); var t = Vector3(0, 0, 1); var Ln = z1 - z0
	var dep = EXIT_X - EXIT_GLASS          # -2: the recess runs +x from the outer plane
	var ys = EXIT_SOFFIT; var yf = EXIT_SOFFIT + EXIT_FASCIA
	# the fascia: 0.6 m thick, 0.2 m proud of the walls, its ends into the returns; the white cap
	run_box(b, g, "ex_aggregate", a, t, n, 0.0, Ln, ys, yf, 0.2, 0.6)
	run_box(b, g, "ex_coping", a, t, n, 0.0, Ln, yf, yf + 0.08, 0.25, 0.7)
	run_box(b, g, "ex_coping", a, t, n, 0.0, Ln, yf - 0.06, yf, 0.26, 0.04)
	# the soffit from the fascia's back to the glass, the vestibule roof and the step up to the hall's
	var xa = EXIT_X + 0.4; var xg = EXIT_GLASS
	b.quad(g, "ex_soffit_white", [Vector3(xa, ys, z0), Vector3(xg, ys, z0), Vector3(xg, ys, z1), Vector3(xa, ys, z1)], -UP)
	b.quad("ex_roof", "ex_roof_grey", [Vector3(EXIT_X - 0.2, yf + 0.08, z0), Vector3(xg, yf + 0.08, z0), Vector3(xg, yf + 0.08, z1), Vector3(EXIT_X - 0.2, yf + 0.08, z1)], UP, [], false, 0.1)
	wall(b, "ex_shell", "ex_brick_tan", Vector3(xg, 0, z0), Vector3(xg, 0, z1), n, yf + 0.08, 6.5)
	b.box("ex_shell", "ex_coping", Vector3(xg - 0.06, 6.55, (z0 + z1) * 0.5), Vector3(0.16, 0.18, Ln))
	for row in [EXIT_X + 0.9, EXIT_X + 1.6]:
		for i in 4:
			var c = Vector3(row, ys - 0.01, z0 + 1.25 + i * 2.5)
			b.cyl(g, "ex_can", c, 0.09, 0.09, 0.01, 10, false, true)
			if row > EXIT_X + 1.0:
				b.tag(b.add_spot(c - UP * 0.05, -UP, 1.2, 6.0, 60.0, Color("#FFE6C2")), "night")
	# the recess's sides: white painted brick north (the Sears return), buff brick south
	wall(b, g, "ex_block_white", Vector3(EXIT_X, 0, z0), Vector3(xg, 0, z0), Vector3(0, 0, 1), 0.0, ys)
	wall(b, g, "ex_brick_tan", Vector3(xg, 0, z1), Vector3(EXIT_X, 0, z1), Vector3(0, 0, -1), 0.0, ys)
	# the poster case on the buff side (4417): aluminium frame, dark glass, a key lock
	var pa = Vector3(EXIT_X, 0, z1); var pt = Vector3(1, 0, 0); var pn = Vector3(0, 0, -1)
	run_box(b, g, "ex_mullion", pa, pt, pn, 0.45, 1.65, 1.0, 1.9, 0.07, 0.07)
	run_box(b, g, "ex_glass_dark", pa, pt, pn, 0.52, 1.58, 1.07, 1.83, 0.075, 0.02)
	# the 0.9 m buff pier past the recess on the cinema's north face, up past the fascia to the buff
	# block's coping, then the salmon brick runs west (4416 f005); the rusty pipe post under the
	# fascia's south corner (4416 f002, f004)
	var na = Vector3(EXIT_X, 0, z1); var nt = Vector3(-1, 0, 0); var nn = Vector3(0, 0, -1)
	run_box(b, "ex_shell", "ex_brick_tan", na, nt, nn, 0.0, 0.9, 0.0, 7.0, 0.04, 0.04)
	run_box(b, "ex_shell", "ex_brick_tan", Vector3(EXIT_X, 0, z1), Vector3(0, 0, 1), n, 0.0, 0.9, yf + 0.08, 7.0, 0.0, 0.9)
	run_box(b, "ex_shell", "ex_coping", na, nt, nn, -2.0, 0.95, 7.0, 7.12, 0.08, 0.95)
	b.cyl(g, "ex_tank_rust", Vector3(EXIT_X + 0.25, 0, z1 - 0.2), 0.05, 0.05, ys, 8, false)
	b.obst(["rect", EXIT_X + 0.15, z1 - 0.3, EXIT_X + 0.35, z1 - 0.1])
	# the storefront at x -78, north to south: 3 fixed bays, door pair A, door pair B, 2 sidelights
	var ga = Vector3(xg, 0, z0)
	var cuts = [0.0, 1.4, 2.8, 4.2, 6.0, 7.8, 8.9, 10.0]
	for u in cuts:
		var hw = 0.05 if u > 0.01 and u < Ln - 0.01 else 0.08
		run_box(b, g, "ex_mullion", ga, t, n, u - hw if u > 0.01 else 0.0, u + hw if u < Ln - 0.01 else Ln, 0.0, ys, 0.07, 0.14)
	run_box(b, g, "ex_mullion", ga, t, n, 0.0, Ln, 2.18, 2.3, 0.07, 0.14)       # the transom bar
	run_box(b, g, "ex_mullion", ga, t, n, 0.0, Ln, 0.0, 0.12, 0.07, 0.14)        # the sill
	run_box(b, g, "ex_mullion", ga, t, n, 0.0, 4.2, 0.7, 0.78, 0.05, 0.1)        # the fixed bays' rail
	for u in [7.8, 8.9]:
		run_box(b, g, "ex_mullion", ga, t, n, u + 0.05, u + 1.05, 0.88, 0.94, 0.05, 0.1)
		run_box(b, g, "ex_mullion", ga, t, n, u + 0.05, u + 1.05, 1.24, 1.3, 0.05, 0.1)
	for p in [[4.2, 6.0], [6.0, 7.8]]:
		var m = (p[0] + p[1]) * 0.5
		# each leaf: wide stiles and rails, a push bar across at 1.0 m, a panic plate at the meeting stile
		for leaf in [[p[0], m], [m, p[1]]]:
			run_box(b, g, "ex_mullion", ga, t, n, leaf[0] + 0.05, leaf[0] + 0.15, 0.12, 2.18, 0.04, 0.08)
			run_box(b, g, "ex_mullion", ga, t, n, leaf[1] - 0.15, leaf[1] - 0.02, 0.12, 2.18, 0.04, 0.08)
			run_box(b, g, "ex_mullion", ga, t, n, leaf[0] + 0.05, leaf[1] - 0.02, 2.06, 2.18, 0.04, 0.08)
			run_box(b, g, "ex_mullion", ga, t, n, leaf[0] + 0.05, leaf[1] - 0.02, 0.12, 0.3, 0.04, 0.08)
			run_box(b, g, "ex_stainless", ga, t, n, leaf[0] + 0.2, leaf[1] - 0.2, 0.98, 1.04, -0.05, 0.04)   # push bar, inside
		run_box(b, g, "ex_stainless", ga, t, n, m - 0.22, m - 0.04, 0.9, 1.25, 0.07, 0.03)
		run_box(b, g, "ex_stainless", ga, t, n, m + 0.04, m + 0.22, 0.9, 1.25, 0.07, 0.03)
		# the red EXIT sign inside over each pair
		b.box(g, "ex_red_arcade", Vector3(xg + 0.6, 3.15, z0 + m), Vector3(0.08, 0.2, 0.36))
	b.quad("ex_glass", "ex_glass", [ga, ga + t * Ln, ga + t * Ln + UP * ys, ga + UP * ys], n, [], true)
	# the recess's floor: the dark sealed apron flush with the channel (4416 f002)
	b.quad("ex_walks", "ex_walk", [Vector3(EXIT_X - 1.0, 0.006, z0), Vector3(xg, 0.006, z0), Vector3(xg, 0.006, z1), Vector3(EXIT_X - 1.0, 0.006, z1)], UP, [], false, 1.0 / 1.65)
	# behind the glass: the vestibule (wing 3 has no inside): a dark tile floor, a white lay-in ceiling
	# at 3.2 m with the transom's dark band above it, white side walls, the inner doors' dark glass at
	# x -73 (4416 f002: the tiles and the inner pairs through the glass, 4418)
	var vx = EXIT_GLASS + 5.0
	b.quad(g, "ex_tile_dark", [Vector3(xg + 0.1, 0.01, z0), Vector3(vx, 0.01, z0), Vector3(vx, 0.01, z1), Vector3(xg + 0.1, 0.01, z1)], UP)
	b.quad(g, "ex_soffit_white", [Vector3(xg + 0.1, 3.2, z0), Vector3(vx, 3.2, z0), Vector3(vx, 3.2, z1), Vector3(xg + 0.1, 3.2, z1)], -UP)
	b.quad(g, "ex_coping_dark", [Vector3(xg + 0.12, 3.2, z0), Vector3(xg + 0.12, 3.2, z1), Vector3(xg + 0.12, ys, z1), Vector3(xg + 0.12, ys, z0)], n)
	b.quad(g, "ex_white_wainscot", [Vector3(xg, 0, z0 + 0.05), Vector3(vx, 0, z0 + 0.05), Vector3(vx, 3.2, z0 + 0.05), Vector3(xg, 3.2, z0 + 0.05)], Vector3(0, 0, 1))
	b.quad(g, "ex_white_wainscot", [Vector3(xg, 0, z1 - 0.05), Vector3(vx, 0, z1 - 0.05), Vector3(vx, 3.2, z1 - 0.05), Vector3(xg, 3.2, z1 - 0.05)], Vector3(0, 0, -1))
	b.quad(g, "ex_glass_dark", [Vector3(vx, 0, z0), Vector3(vx, 0, z1), Vector3(vx, 3.2, z1), Vector3(vx, 3.2, z0)], n)
	for i in 3:
		b.cyl(g, "ex_can", Vector3(xg + 2.5, 3.19, z0 + 2.5 + i * 2.5), 0.09, 0.09, 0.01, 10, false, true)
	# the wave bike rack on the white return's west face (z -100..-96), lengthwise, 0.5 m off the wall
	# Steven (Nov 8): on the white wall to the LEFT of the entrance (the channel's north side, facing
	# south), along it, not on the west face parallel to the doors; 0.5 m off the rack block's south face
	RACK.build(b, Vector3(SEARS_W - 2.3, 0, z0 + 0.5), Vector3(1, 0, 0))
	trash_can(b, Vector3(EXIT_X - 0.9, 0, z0 + 0.8))

## The cinema box: windowless salmon brick (EXT-LAYOUT, Nov 8 2026; 4486 f001-f040, 4416 f005-f007,
## design/godot-exterior.md "Nov 8 refinements"). The north face is the south side of the exit's channel
## (x -98..-80): a cream flush double door ~10 m out from the glass (4486 f001) and a single one by the
## NW corner (f016), wall packs over them. The west face (x -98) runs 44 m south in one flush run:
## shallow peach-painted brick pilasters with peach caps every 8 m, a light base course, the brass
## fire department connection on its pipes by a pilaster (f022-f024), and the raised walk along the
## wall: three steps up at its north end, the peach knee wall at the curb with a galvanized two-rail pipe
## rail, a cream single door on it (f025-f030), the ramp down at its south end, i.e. rising toward the
## exit (f031-f037); a second door at grade past the ramp (f037, far: a GUESS). Red curb along the base
## both years (fire lane hatching 2026 only: walks loop, fire_lane_face()).
static func cinema_box(b):
	var g = "ex_shell"
	var x0 = CINEMA_W
	# the north face, the channel's south side
	var na = Vector3(x0, 0, -86); var nt = Vector3(1, 0, 0); var nn = Vector3(0, 0, -1)
	run_box(b, g, "ex_peach_pier", na, nt, nn, 0.0, -80.9 - x0, 0.0, 0.45, 0.03, 0.03)
	cinema_door(b, g, na, nt, nn, (-80.0 - 10.5) - x0, 2)      # the double door (4486 f001)
	cinema_door(b, g, na, nt, nn, 1.6, 1)                      # the single by the NW corner (f016)
	# the west face
	var a = Vector3(x0, 0, -86); var n = Vector3(-1, 0, 0); var t = Vector3(0, 0, 1); var Ln = 44.0
	run_box(b, g, "ex_peach_pier", a, t, n, 0.0, Ln, 0.0, 0.45, 0.03, 0.03)
	for u in [6.0, 14.0, 22.0, 30.0, 38.0]:
		run_box(b, g, "ex_peach_pier", a, t, n, u - 0.3, u + 0.3, 0.45, H_CINEMA - 0.25, 0.1, 0.1)
		run_box(b, g, "ex_peach_pier", a, t, n, u - 0.36, u + 0.36, H_CINEMA - 0.25, H_CINEMA + 0.12, 0.16, 0.16)
	# the fire department connection: a brass siamese on a pipe off the wall left of the 14 m pilaster
	var fdc = a + t * 12.6 + n * 0.32 + UP * 0.9
	b.box(g, "ex_gold", fdc, Vector3(0.12, 0.22, 0.42))
	for sd in [-1.0, 1.0]:
		b.cyl(g, "ex_gold", fdc + t * (sd * 0.13) - UP * 0.25, 0.05, 0.05, 0.16, 8, true)
	b.box(g, "ex_pipe_grey", a + t * 13.2 + n * 0.2 + UP * 0.9, b.abs_size(t, 1.2, 0.08, 0.08, n))
	b.cyl(g, "ex_pipe_grey", a + t * 13.8 + n * 0.12, 0.05, 0.05, 1.0, 8, true)
	# the raised walk: 0.45 m up, 1.45 m wide, steps at u 15..16.05 just past the FDC pilaster (f022), level to
	# u 33, a 1:12 ramp to u 38.4
	var hp = 0.45; var w = 1.45
	var u0 = 16.05; var u1 = 33.0; var u2 = u1 + hp * 12.0
	for i in 3:
		run_box(b, g, "ex_walk", a, t, n, 15.0 + i * 0.35, u0, 0.0, (i + 1) * 0.15, w, w)
	run_box(b, g, "ex_walk", a, t, n, u0, u1, 0.0, hp, w, w)
	var r0 = a + t * u1; var r1 = a + t * u2
	b.quad(g, "ex_walk", [r0 + UP * hp, r0 + n * w + UP * hp, r1 + n * w + UP * 0.02, r1 + UP * 0.02], (UP * 12.0 + t).normalized())
	b.quad(g, "ex_walk", [r0 + n * w, r0 + n * w + UP * hp, r1 + n * w + UP * 0.02, r1 + n * w], n)
	# the knee wall at the curb (0.25 thick, 0.95 over the lot) from the steps to the ramp's foot, and
	# the galvanized two-rail pipe rail on it; the rail carries on down the ramp
	run_box(b, g, "ex_peach_pier", a, t, n, 15.0, u1, 0.0, 0.95, w + 0.25, 0.25)
	var kw0 = a + t * u1 + n * (w + 0.125); var kw1 = a + t * u2 + n * (w + 0.125)
	b.quad(g, "ex_peach_pier", [kw0 + n * 0.125, kw1 + n * 0.125, kw1 + n * 0.125 + UP * 0.4, kw0 + n * 0.125 + UP * 0.95], n)
	b.quad(g, "ex_peach_pier", [kw0 - n * 0.125 + UP * hp, kw1 - n * 0.125 + UP * 0.02, kw1 - n * 0.125 + UP * 0.4, kw0 - n * 0.125 + UP * 0.95], -n)
	b.quad(g, "ex_peach_pier", [kw0 - n * 0.125 + UP * 0.95, kw0 + n * 0.125 + UP * 0.95, kw1 + n * 0.125 + UP * 0.4, kw1 - n * 0.125 + UP * 0.4], UP)
	b.quad(g, "ex_peach_pier", [kw1 - n * 0.125, kw1 + n * 0.125, kw1 + n * 0.125 + UP * 0.4, kw1 - n * 0.125 + UP * 0.4], t)
	var rl = n * (w - 0.05)
	for y in [hp + 1.05, hp + 0.55]:
		b.box(g, "ex_pipe_grey", a + t * ((15.6 + u1) * 0.5) + rl + UP * y, b.abs_size(t, u1 - 15.6, 0.045, 0.045, n))
		var p0 = a + t * u1 + rl + UP * y; var p1 = a + t * u2 + rl + UP * (y - hp + 0.02)
		b.box(g, "ex_pipe_grey", Vector3.ZERO, Vector3(0.045, 0.045, p0.distance_to(p1)), Transform3D(Basis.looking_at(p1 - p0, UP), (p0 + p1) * 0.5))
	var posts = []
	var pu = 15.6
	while pu < u1 - 0.5:
		posts.append(pu); pu += 2.0
	posts += [u1, u1 + (u2 - u1) * 0.5, u2]
	for q in posts:
		var yb = hp if q <= u1 else hp - (q - u1) / 12.0
		b.cyl(g, "ex_pipe_grey", a + t * q + rl + UP * yb, 0.024, 0.024, 1.07, 6, false)
	cinema_door(b, g, a, t, n, 26.0, 1, hp)                        # on the raised walk (f028-f030)
	cinema_door(b, g, a, t, n, 41.5, 1)                            # past the ramp (f037, a GUESS)
	b.obst(["rect", x0 - w - 0.3, -86.0 + 15.0, x0, -86.0 + u2])

## A cream flush steel exit door (single or double) on the cinema box, set on its sill `y0` up, a wall
## pack over it and a small drip cap (4486 f001, f016, f028).
static func cinema_door(b, g, a, t, n, u, leaves, y0 = 0.0):
	var hw = 0.48 * leaves
	run_box(b, g, "ex_coping", a, t, n, u - hw - 0.06, u + hw + 0.06, y0, y0 + 2.2, 0.04, 0.04)
	run_box(b, g, "ex_beige_door", a, t, n, u - hw, u + hw, y0, y0 + 2.12, 0.05, 0.03)
	if leaves == 2:
		run_box(b, g, "ex_coping_dark", a, t, n, u - 0.01, u + 0.01, y0, y0 + 2.12, 0.055, 0.01)
	run_box(b, g, "ex_coping", a, t, n, u - hw - 0.12, u + hw + 0.12, y0 + 2.2, y0 + 2.26, 0.12, 0.12)
	run_box(b, g, "ex_wall_pack", a, t, n, u - 0.16, u + 0.16, y0 + 2.55, y0 + 2.8, 0.2, 0.2)

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

## JCPenney (EXT-B, §5 #5: 60 x 120 m to z -14, the rear block on the west): natural cream face brick
## with dark ironspot speckles, long thin units, no windows (4486 f103-113, 4487-4489). North face
## (the staff lot): docks 1-2 under a red canopy with the compactor, then the Package Pick-up recess
## under the coral ribbed fascia. West face: the roll-up receiving door on the tall rear block, the
## "tree-side" customer entrance under a flat maroon fascia, the wordmark wall with the podocarpus.
## South face: the customer entrance under the red arcade near the SW corner, the dead hedge. The
## arcade, maroon and coral fascias are today's (2012-era) treatment and stand in 1995 too (a GUESS).
static func jcpenney(b):
	var g = "ex_entry"
	var word = "#b0164a" if YEAR == 2026 else "#f4efe3"
	# ---- west face x = -214, z 32..106 (u runs north from z 106)
	var a = Vector3(-214, 0, 106); var n = Vector3(-1, 0, 0); var t = Vector3(0, 0, -1)
	run_box(b, g, "ex_maroon", a, t, n, 54.0, 66.0, 3.6, 4.6, 3.0, 3.0, ["+y"])
	b.quad(g, "ex_soffit_white", [a + t * 54.0 + UP * 3.59, a + t * 66.0 + UP * 3.59, a + t * 66.0 + n * 3.0 + UP * 3.59, a + t * 54.0 + n * 3.0 + UP * 3.59], -UP)
	for i in 5:
		run_box(b, g, "ex_bronze", a, t, n, 56.0 + i * 2.0 - 0.05, 56.0 + i * 2.0 + 0.05, 0.0, 3.4, 0.0, 0.14)
	b.quad("ex_glass", "ex_glass", [a + t * 56.0 + n * 0.02, a + t * 64.0 + n * 0.02, a + t * 64.0 + n * 0.02 + UP * 3.4, a + t * 56.0 + n * 0.02 + UP * 3.4], n, [], true)
	for i in 3:
		b.tag(b.add_spot(a + t * (57.0 + i * 3.0) + n * 1.5 + UP * 3.5, -UP, 1.2, 6.0, 60.0, Color("#FFE6C2")), "night")
	trash_can(b, a + t * 53.0 + n * 1.0)
	b.label("JCPenney", "sans", word, a + t * 30.0 + UP * 5.4 + n * 0.08, n, 10.0, 1.1)
	for i in 9:
		var u = 4.0 + i * 5.5
		if u > 52.0:
			break
		FL.column(b, a + t * u + n * 1.2, 0.55, 1.6)   # clipped podocarpus columns, ~1.6 m (4488 f020)
		b.obst(["rect", a.x - 1.8, a.z - u - 0.6, a.x - 0.6, a.z - u + 0.6])
	# the rear block's roll-up receiving door (x -228, z ~28)
	var ra = Vector3(-228, 0, 32)
	run_box(b, g, "ex_steel", ra, t, n, 2.0, 6.0, 0.0, 3.8, 0.03, 0.03)
	for k in 12:
		run_box(b, g, "ex_wall_pack", ra, t, n, 2.0, 6.0, 0.3 + k * 0.3, 0.33 + k * 0.3, 0.05, 0.02)
	bollard(b, ra + t * 1.6 + n * 0.6)
	bollard(b, ra + t * 6.4 + n * 0.6)
	# ---- south face z = 106, x -214..-154: the red arcade near the SW corner
	var sa = Vector3(-214, 0, 106); var sn = Vector3(0, 0, 1); var stt = Vector3(1, 0, 0)
	for i in 5:
		var p = sa + stt * (8.0 + i * 3.5) + sn * 3.0
		b.box(g, "ex_red_arcade", p + UP * 2.0, Vector3(0.7, 4.0, 0.7))
		b.obst(["rect", p.x - 0.4, p.z - 0.4, p.x + 0.4, p.z + 0.4])
	run_box(b, g, "ex_red_arcade", sa, stt, sn, 7.5, 22.5, 4.0, 5.0, 3.4, 3.6, ["+y"])
	b.quad(g, "ex_soffit_white", [sa + stt * 7.5 + UP * 3.99, sa + stt * 22.5 + UP * 3.99, sa + stt * 22.5 + sn * 3.4 + UP * 3.99, sa + stt * 7.5 + sn * 3.4 + UP * 3.99], -UP)
	for i in 5:
		run_box(b, g, "ex_bronze", sa, stt, sn, 11.0 + i * 2.0 - 0.05, 11.0 + i * 2.0 + 0.05, 0.0, 3.4, 0.0, 0.14)
	b.quad("ex_glass", "ex_glass", [sa + stt * 11.0 + sn * 0.02, sa + stt * 19.0 + sn * 0.02, sa + stt * 19.0 + sn * 0.02 + UP * 3.4, sa + stt * 11.0 + sn * 0.02 + UP * 3.4], sn, [], true)
	trash_can(b, sa + stt * 23.5 + sn * 1.0)
	b.label("JCPenney", "sans", word, sa + stt * 38.0 + UP * 5.4 + sn * 0.08, sn, 10.0, 1.1)
	# the hedge along the south wall (dead brown today, 4489 f010-020)
	for i in 14:
		var hp = sa + stt * (25.0 + i * 2.4) + sn * 1.0
		FL.shrub(b, hp, 0.75, Color(0.75, 0.62, 0.45) if YEAR == 2026 else Color(0.85, 1.0, 0.85))
	b.obst(["rect", sa.x + 24.0, sa.z + 0.3, sa.x + 58.0, sa.z + 1.7])
	# ---- north face z = -14, x -214..-154 (u runs west from x -154): docks 1-2 under the red canopy,
	# the compactor, the Package Pick-up recess under the coral ribbed fascia
	var na = Vector3(-154, 0, -14); var nn = Vector3(0, 0, -1); var nt = Vector3(-1, 0, 0)
	run_box(b, g, "ex_red_arcade", na, nt, nn, 4.0, 18.0, 4.0, 4.5, 3.5, 3.5)
	for u in [8.0, 14.0]:
		run_box(b, g, "ex_steel", na, nt, nn, u - 1.6, u + 1.6, 1.2, 4.0, 0.03, 0.03)
		run_box(b, g, "ex_canopy_brown", na, nt, nn, u - 1.9, u + 1.9, 1.1, 4.2, 0.25, 0.25)   # the dock seals
		b.label("1" if u < 10.0 else "2", "sans", "#f4efe3", na + nt * u + UP * 4.25 + nn * 0.05, nn, 0.5, 0.4)
	run_box(b, g, "ex_curb", na, nt, nn, 4.5, 17.5, 0.0, 1.2, 2.0, 2.0, ["-y"])
	for u in [4.8, 17.2]:
		b.cyl(g, "ex_pipe_yellow", na + nt * u + nn * 1.9 + UP * 1.2, 0.03, 0.03, 1.0, 6, false)
	b.box(g, "ex_pipe_yellow", na + nt * 11.0 + nn * 1.9 + UP * 2.15, Vector3(12.4, 0.06, 0.06))
	b.obst(["rect", -172.0, -16.0, -158.0, -14.0])
	# the compactor west of the docks
	b.box(g, "ex_awning_teal" if YEAR != 2026 else "ex_holly", Vector3(-176.0, 1.2, -17.0), Vector3(3.0, 2.4, 6.0))
	b.obst(["rect", -177.6, -20.0, -174.4, -14.0])
	run_box(b, g, "ex_coral", na, nt, nn, 33.0, 45.0, 3.2, 4.4, 1.6, 1.6)
	for k in 8:
		run_box(b, g, "ex_maroon", na, nt, nn, 33.6 + k * 1.5, 33.9 + k * 1.5, 3.2, 4.4, 1.64, 0.05)
	run_box(b, g, "ex_beige_door", na, nt, nn, 37.0, 41.0, 0.0, 2.6, 0.03, 0.03)
	b.label("Package Pick-up", "sans", "#f4efe3", na + nt * 39.0 + UP * 3.8 + nn * 1.62, nn, 5.0, 0.35)
	b.label("JCPenney", "sans", word, na + nt * 25.0 + UP * 7.6 + nn * 0.08, nn, 9.0, 1.0)
	for u in [36.0, 42.0]:
		bollard(b, na + nt * u + nn * 2.0)
	# the pine island with the hydrant at the NW corner (4487 f011-020)
	island(b, -226.0, -30.0, -214.0, -20.0, "ex_grass")
	for p in [Vector3(-223.0, 0.16, -27.0), Vector3(-218.0, 0.16, -25.5), Vector3(-221.0, 0.16, -22.5)]:
		tree_pine(b, p, 14.0 + p.x * 0.0)
	hydrant(b, Vector3(-212.5, 0, -21.0))

## Dillard's (EXT-B, §5 #7: 87 x 58 m, flush with the facade, the portal on the Bayou Gardens face):
## three storeys of peach EIFS scored as ashlar, two cream cornice bands, the serif "Dillard's"; the
## cast-iron lace gallery on the east (West Park) and south (Bayou Gardens) faces on slender bronze
## columns (Steven, Nov 3: "yes, with the gallery on the south and West Park faces"); ground storey
## white panels with blind panelled doors under sunburst fanlights; the entrance portal with 4 door
## pairs on the south face (s2s), the gallery doors on the east face (s2e); the flagpole island at
## the SW corner; the covered loading dock and the service lane on the west side (4490 f013-056,
## 4492 f100-108). The 1995 (D.H. Holmes-era) skin is unknown: this is the gallery as filmed.
static func dillards(b):
	var g = "ex_entry"
	var ea = Vector3(44, 0, 80); var en = Vector3(1, 0, 0); var et = Vector3(0, 0, 1)
	var sa = Vector3(-38, 0, 138); var sn = Vector3(0, 0, 1); var stt = Vector3(1, 0, 0)
	var wa = Vector3(-38, 0, 80); var wn = Vector3(-1, 0, 0); var wt = Vector3(0, 0, 1)
	for f in [[ea, et, en, 58.0], [sa, stt, sn, 82.0], [wa, wt, wn, 58.0]]:
		var y = 5.2
		while y < H_DILLARDS - 0.3:
			# the ashlar scoring: a thin line 1 cm proud, unbaked (it was a box sunk flush into the face,
			# coplanar with it: z-fighting, and invalid lightmap texels in strips all up the wall)
			run_box(b, "ex_shell", "ex_coping", f[0], f[1], f[2], 0.0, f[3], y - 0.02, y + 0.02, 0.01, 0.01, [], true)
			y += 1.2
		run_box(b, "ex_shell", "ex_cream_pier", f[0], f[1], f[2], 0.0, f[3], 9.3, 9.8, 0.25, 0.25)
		run_box(b, "ex_shell", "ex_cream_pier", f[0], f[1], f[2], 0.0, f[3], H_DILLARDS - 0.6, H_DILLARDS, 0.3, 0.3)
	run_box(b, "ex_shell", "ex_white_wainscot", wa, wt, wn, 0.0, 58.0, 0.0, 1.2, 0.05, 0.05)
	# the east face: white ground storey, blind doors, the s2e gallery doors (z 95..101.4)
	run_box(b, g, "ex_white_wainscot", ea, et, en, 0.0, 58.0, 0.0, 4.8, 0.08, 0.08)
	for u in [4.0, 9.6, 26.8, 32.4, 38.0, 43.6, 49.2, 54.4]:
		blind_door(b, ea, et, en, u)
	entry_doors(b, ea, et, en, 14.6, 21.8, 2)
	gallery(b, ea, et, en, 0.5, 57.5)
	b.label("Dillard's", "serif", "#3b2e28", ea + et * 29.0 + UP * 11.6 + en * 0.08, en, 14.0, 1.6)
	# the south face: the gallery either side of the portal (x -15)
	run_box(b, g, "ex_white_wainscot", sa, stt, sn, 0.0, 82.0, 0.0, 4.8, 0.08, 0.08)
	for u in [4.0, 9.6, 15.2, 30.8, 36.4, 42.0, 47.6, 53.2, 58.8, 64.4, 70.0, 75.6]:
		blind_door(b, sa, stt, sn, u)
	gallery(b, sa, stt, sn, 0.5, 16.8)
	gallery(b, sa, stt, sn, 29.2, 81.5)
	portal(b, sa, stt, sn, 23.0)
	b.label("Dillard's", "serif", "#3b2e28", sa + stt * 55.0 + UP * 11.6 + sn * 0.08, sn, 14.0, 1.6)
	# the flagpole island at the SW corner (4490 f029-034)
	island(b, -50.0, 141.0, -43.0, 147.0, "ex_grass", "ex_curb")
	for k in 3:
		b.cyl("ex_props", "ex_pole_white", Vector3(-48.5 + k * 2.0, 0.16, 144.0), 0.08, 0.04, 11.0 + (1.0 if k == 1 else 0.0), 8, true)
	# the covered loading dock on the west side (4490 f024-028): a raised dock, a canopy, a trailer
	b.box(g, "ex_curb", Vector3(-41.0, 0.6, 127.0), Vector3(6.0, 1.2, 12.0), Transform3D.IDENTITY, ["-y"])
	b.box(g, "ex_coping_dark", Vector3(-42.0, 4.75, 127.0), Vector3(8.0, 0.3, 14.0))
	for z in [121.0, 133.0]:
		b.cyl(g, "ex_pipe_grey", Vector3(-45.6, 0, z), 0.12, 0.12, 4.6, 8, false)
	for z in [123.5, 130.5]:
		b.box(g, "ex_steel", Vector3(-38.03, 2.7, z), Vector3(0.04, 3.0, 3.2))
	b.obst(["rect", -46.0, 120.0, -38.0, 134.0])
	trailer(b, Vector3(-51.5, 0, 125.0), Vector3(1, 0, 0), 13.0)
	# the roll-off container by the lane's mouth
	b.box(g, "ex_awning_teal", Vector3(-58.0, 0.8, 132.0), Vector3(2.4, 1.6, 6.5))
	b.obst(["rect", -59.3, 128.7, -56.7, 135.3])

## The Sears / Lynn's box (EXT-B, §5 #1: 115 x 50 m, flush with the facade): the loading dock on the
## WEST face just north of the cinema-side exit, under a flat white canopy on pipe columns, a raised
## dock 1.2 m, the truck well in front with the yellow pipe rail on its red curb, the box truck in it
## ("take note of this"; 4486 f002-010, 4416 f012-017). The anchors' own doors: the customer
## entrance on the east face (s1e, 4406 f031-035), the side exit with its roll shutter on the north
## face toward Armour Dr (s1x, 4413 f001-008). "Sears" on the west, east and north faces in 1995 (the
## north one is a GUESS: that face is not filmed); Lynn's in 2026.
static func sears_dock(b):
	var g = "ex_entry"
	var a = Vector3(SEARS_W, 0, -100); var n = Vector3(-1, 0, 0); var t = Vector3(0, 0, -1)
	run_box(b, g, "ex_walk", a, t, n, 1.0, 26.0, 0.0, 0.02, 3.0, 3.0, ["-y"])   # EXT-LAYOUT: the dock floor at grade
	run_box(b, g, "ex_coping", a, t, n, 0.0, 27.0, 4.6, 4.9, 8.0, 8.0)
	b.quad(g, "ex_soffit_white", [a + UP * 4.59, a + t * 27.0 + UP * 4.59, a + t * 27.0 + n * 8.0 + UP * 4.59, a + n * 8.0 + UP * 4.59], -UP)
	# EXT-LAYOUT: thin white pipe columns at the dock's edge, the canopy overhanging the well (4486 f008)
	for u in [1.0, 9.5, 18.0, 26.0]:
		b.cyl(g, "ex_coping", a + t * u + n * 2.9, 0.08, 0.08, 4.6, 8, false)
		b.obst(["rect", a.x - 3.05, a.z - u - 0.15, a.x - 2.75, a.z - u + 0.15])
	for u in [5.0, 11.0, 17.0, 23.0]:
		run_box(b, g, "ex_white_wainscot", a, t, n, u - 1.5, u + 1.5, 0.0, 3.0, 0.03, 0.03)   # white roll-up doors at the floor (4486 f008)
		run_box(b, g, "ex_canopy_brown", a, t, n, u - 1.8, u + 1.8, 2.9, 3.2, 0.22, 0.22)
		b.tag(b.add_spot(a + t * u + n * 3.0 + UP * 4.5, -UP, 1.0, 7.0, 60.0, Color("#FFD9A8")), "night")
	b.obst(["rect", SEARS_W - 3.0, -126.0, SEARS_W, -101.0])
	# EXT-LAYOUT (Nov 8 2026; 4486 f004-f010, 4416 f012-f017): the truck well is SUNK, not painted: the dock
	# floor under the canopy is the building's grade and the trucks stand 1.2 m lower, their beds at the
	# dock's edge (x SEARS_W - 3). The well runs 20 m out, then a ramp climbs 12 m west to the lot (the lot
	# beyond is lower in the frames; here it comes back up to grade, the lot being flat). Concrete retaining
	# walls each side, the yellow 2-rail on the red curb along both tops, the full length of the drop.
	var wx0 = WELL[0]; var wz0 = WELL[1]; var wx1 = WELL[2]; var wz1 = WELL[3]; var wr = WELL_RAMP
	var dp = -1.2
	b.quad("ex_walks", "ex_asphalt", [Vector3(wr, dp, wz0), Vector3(wx1, dp, wz0), Vector3(wx1, dp, wz1), Vector3(wr, dp, wz1)], UP, [], false, 0.25)
	b.quad("ex_walks", "ex_asphalt", [Vector3(wx0, 0.0, wz0), Vector3(wr, dp, wz0), Vector3(wr, dp, wz1), Vector3(wx0, 0.0, wz1)], Vector3(-dp, wr - wx0, 0).normalized(), [], false, 0.25)
	for side in [[wz1, Vector3(0, 0, -1)], [wz0, Vector3(0, 0, 1)]]:
		var z = side[0]; var nw = side[1]
		b.quad(g, "ex_curb", [Vector3(wx0, 0.0, z), Vector3(wr, dp, z), Vector3(wx1, dp, z), Vector3(wx1, 0.0, z)], nw)
		var zc = z - nw.z * 0.2
		b.box(g, "ex_curb_red", Vector3((wx0 + wx1) * 0.5, 0.15, zc), Vector3(wx1 - wx0, 0.3, 0.4))
		var px = wx0 + 1.5
		while px < wx1:
			b.cyl(g, "ex_pipe_yellow", Vector3(px, 0.3, zc), 0.04, 0.04, 0.85, 6, false)
			px += 4.0
		b.cyl(g, "ex_pipe_yellow", Vector3(wx1 - 0.3, 0.3, zc), 0.04, 0.04, 0.85, 6, false)
		for y in [1.12, 0.7]:
			b.box(g, "ex_pipe_yellow", Vector3((wx0 + wx1) * 0.5, y, zc), Vector3(wx1 - wx0 - 0.4, 0.07, 0.07))
	# the dock's face down to the well, black rubber bumpers under each door
	b.quad(g, "ex_curb", [Vector3(wx1, dp, wz0), Vector3(wx1, dp, wz1), Vector3(wx1, 0.0, wz1), Vector3(wx1, 0.0, wz0)], Vector3(-1, 0, 0))
	for u in [5.0, 11.0, 17.0]:
		for sd in [-1.0, 1.0]:
			b.box(g, "ex_fence_black", Vector3(wx1 - 0.08, -0.35, -100.0 - u + sd * 1.3), Vector3(0.16, 0.5, 0.3))
	# you cannot walk into the well (the lot is flat for the player)
	b.obst(["rect", wx0 + 2.0, wz0, wx1, wz1])
	# the low white block's door on its west face, by the well (4486 f006-f008)
	run_box(b, g, "ex_beige_door", Vector3(SEARS_W - 4.0, 0, -100.0), Vector3(0, 0, 1), Vector3(-1, 0, 0), 0.5, 1.5, 0.0, 2.1, 0.03, 0.03)
	if YEAR == 2026:
		box_truck(b, Vector3(wx1 - 0.2, dp, -111.0), Vector3(1, 0, 0), true)       # the Lynn's truck in the well
	else:
		trailer(b, Vector3(wx1 - 0.2, dp, -107.0), Vector3(1, 0, 0), 13.5)          # a plain white trailer
	# the anchors' doors
	for d in E.doors:
		if d.store == "s1e":
			var da = V(d.a); var db = V(d.b); var dn = -V(d.n); var dt = (db - da).normalized(); var dl = da.distance_to(db)
			entry_doors(b, da, dt, dn, 0.0, dl, 2)
			run_box(b, g, "ex_mullion", da, dt, dn, -1.0, dl + 1.0, 0.0, 3.6, 0.04, 0.04)
			run_box(b, g, "ex_black_steel" if YEAR == 2026 else "ex_coping_dark", da, dt, dn, -0.6, dl + 0.6, 3.4, 3.65, 1.6, 1.6)
			trash_can(b, da + dt * (dl + 1.6) + dn * 1.2)
		elif d.store == "s1n":
			sears_north_entrance(b, d)
		elif d.store == "s1x":
			var da = V(d.a); var db = V(d.b); var dn = -V(d.n); var dt = (db - da).normalized(); var dl = da.distance_to(db)
			run_box(b, g, "ex_beige_door", da, dt, dn, -0.3, dl + 0.3, 0.0, 2.4, 0.05, 0.05)
			run_box(b, g, "ex_glass_dark", da, dt, dn, 0.2, dl - 0.2, 1.2, 2.1, 0.06, 0.02)
			run_box(b, g, "ex_steel", da, dt, dn, -0.5, dl + 0.5, 2.5, 3.0, 0.45, 0.45)    # the roll shutter's hood
			run_box(b, g, "ex_wall_pack", da, dt, dn, dl * 0.5 - 0.2, dl * 0.5 + 0.2, 3.3, 3.55, 0.25, 0.25)
			for sd in [-1.2, dl + 1.2]:
				bollard(b, da + dt * sd + dn * 1.0)
			if YEAR == 2026:
				# the zebra crosswalk out to the lot (4413 f001-008)
				for k in 8:
					var c = da + dt * (dl * 0.5) + dn * 3.0
					stripe(b, c + dt * (-2.5 + k * 0.7) + UP * 0.002, c + dt * (-2.5 + k * 0.7) + dn * 6.0 + UP * 0.002, 0.4, "ex_stripe_white")
	if YEAR == 2026:
		Y26.lynns(b)
	else:
		b.label("Sears", "sans", "#1c2a4a", Vector3(SEARS_W - 0.08, 6.6, -134.0), n, 12.0, 1.6)
		b.label("Sears", "sans", "#1c2a4a", Vector3(44.08, 6.6, -134.0), Vector3(1, 0, 0), 12.0, 1.6)
		b.label("Sears", "sans", "#1c2a4a", Vector3(-24.0, 6.6, -146.08), Vector3(0, 0, -1), 12.0, 1.6)   # over the north entrance

## The Sears north entrance (s1n; EXT-LAYOUT, Nov 8 2026; Steven's annotated plan "Sears Entrance", design/
## godot-sears.md): a period Sears department-store entrance: a dark bronze storefront of three door
## pairs under a transom, bronze-framed sidelights, set under a flat dark canopy 3 m deep on the wall with
## a white soffit and cans; the wordmark over it is the face's "Sears" (1995) / "Lynn's" (2026) sign.
## Not filmed (the north face is a gap in the footage): the form is a GUESS after 1970s-80s Sears stores.
static func sears_north_entrance(b, d):
	var g = "ex_entry"
	var da = V(d.a); var db = V(d.b); var dn = -V(d.n); var dt = (db - da).normalized(); var dl = da.distance_to(db)
	# a 1 m bronze sidelight each side of the three pairs
	entry_doors(b, da, dt, dn, 1.0, dl - 1.0, 3)
	for u in [[0.0, 1.0], [dl - 1.0, dl]]:
		run_box(b, g, "ex_bronze", da, dt, dn, u[0], u[0] + 0.08, 0.0, 3.34, 0.16, 0.16)
		run_box(b, g, "ex_bronze", da, dt, dn, u[1] - 0.08, u[1], 0.0, 3.34, 0.16, 0.16)
		run_box(b, g, "ex_glass_dark", da, dt, dn, u[0] + 0.08, u[1] - 0.08, 0.1, 3.2, 0.1, 0.02)
	# the flat canopy: dark fascia 0.7 m, 3 m out, 1 m past the storefront each side, white soffit, cans
	var c0 = -1.0; var c1 = dl + 1.0; var dep = 3.0; var yb = 3.6
	run_box(b, g, "ex_coping_dark" if YEAR != 2026 else "ex_black_steel", da, dt, dn, c0, c1, yb, yb + 0.7, dep, 0.25)
	for u in [c0, c1 - 0.25]:
		run_box(b, g, "ex_coping_dark" if YEAR != 2026 else "ex_black_steel", da, dt, dn, u, u + 0.25, yb, yb + 0.7, dep, dep)
	b.quad(g, "ex_soffit_white", [da + dt * c0 + UP * (yb + 0.01), da + dt * c1 + UP * (yb + 0.01), da + dt * c1 + dn * dep + UP * (yb + 0.01), da + dt * c0 + dn * dep + UP * (yb + 0.01)], -UP)
	for k in 4:
		var c = da + dt * (dl * (k + 0.5) / 4.0) + dn * 1.8 + UP * yb
		b.cyl(g, "ex_can", c, 0.1, 0.1, 0.01, 10, false, true)
		b.tag(b.add_spot(c - UP * 0.05, -UP, 1.2, 6.0, 60.0, Color("#FFE6C2")), "night")
	for sd in [-1.6, dl + 1.6]:
		trash_can(b, da + dt * sd + dn * 1.2)

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

## A black steel trash receptacle with a domed lid (by every entrance; both years).
static func trash_can(b, at):
	b.cyl("ex_props", "ex_fence_black", at, 0.32, 0.3, 0.85, 12, false)
	b.cyl("ex_props", "ex_fence_black", at + UP * 0.85, 0.34, 0.12, 0.2, 12, true)
	b.obst(["rect", at.x - 0.35, at.z - 0.35, at.x + 0.35, at.z + 0.35])

## The black 3-loop wave bike rack ("here since I was a kid"; 4416 f010): loops along t.
static func wave_rack(b, at, t):
	RACK.build(b, at, t)   # EXT-LAYOUT: the bent-pipe model (wave_rack.gd)

## A red fire hydrant on its pad.
static func hydrant(b, at):
	b.cyl("ex_props", "ex_red_arcade", at, 0.14, 0.14, 0.6, 8, false)
	b.cyl("ex_props", "ex_red_arcade", at + UP * 0.6, 0.15, 0.06, 0.18, 8, true)
	b.box("ex_props", "ex_red_arcade", at + UP * 0.4, Vector3(0.44, 0.1, 0.1))
	b.obst(["rect", at.x - 0.3, at.z - 0.3, at.x + 0.3, at.z + 0.3])

## A blind panelled door under a sunburst fanlight (Dillard's ground storey), centred at u.
static func blind_door(b, a, t, n, u):
	var g = "ex_entry"
	run_box(b, g, "ex_ivory", a, t, n, u - 1.0, u + 1.0, 0.0, 2.6, 0.14, 0.06)
	run_box(b, g, "ex_bronze", a, t, n, u - 0.95, u + 0.95, 0.1, 2.5, 0.15, 0.02)
	var s = b.st(g, "ex_ivory")
	var sb = b.st(g, "ex_bronze")
	var c = a + t * u + n * 0.15 + UP * 2.65
	for k in 12:
		var a0 = PI * k / 12; var a1 = PI * (k + 1) / 12
		b.tri(s, c, c + t * (cos(a0) * 1.05) + UP * (sin(a0) * 1.05), c + t * (cos(a1) * 1.05) + UP * (sin(a1) * 1.05), Vector2(0, 0), Vector2(0, 0), Vector2(0, 0), n)
		if k % 2 == 0:
			b.tri(sb, c + n * 0.01, c + n * 0.01 + t * (cos(a0) * 1.0) + UP * (sin(a0) * 1.0), c + n * 0.01 + t * (cos(a1) * 1.0) + UP * (sin(a1) * 1.0), Vector2(0, 0), Vector2(0, 0), Vector2(0, 0), n)

## Glass entrance doors in bronze frames, `pairs` pairs between u0 and u1, with a transom.
static func entry_doors(b, a, t, n, u0, u1, pairs):
	var g = "ex_entry"
	var w = (u1 - u0) / pairs
	for i in pairs + 1:
		run_box(b, g, "ex_bronze", a, t, n, u0 + i * w - 0.06, u0 + i * w + 0.06, 0.0, 3.2, 0.16, 0.16)
	for i in pairs:
		run_box(b, g, "ex_bronze", a, t, n, u0 + i * w + w * 0.5 - 0.03, u0 + i * w + w * 0.5 + 0.03, 0.0, 2.4, 0.16, 0.16)
	run_box(b, g, "ex_bronze", a, t, n, u0, u1, 2.4, 2.52, 0.16, 0.16)
	run_box(b, g, "ex_bronze", a, t, n, u0, u1, 3.2, 3.34, 0.16, 0.16)
	b.quad("ex_glass", "ex_glass", [a + t * u0 + n * 0.1, a + t * u1 + n * 0.1, a + t * u1 + n * 0.1 + UP * 3.2, a + t * u0 + n * 0.1 + UP * 3.2], n, [], true)

## The Dillard's gallery along a face from u L0 to L1: a flat roof 3.7 m out at 4.6 m on slender
## bronze columns every 3.6 m, the cast-iron lace frieze of scrolled roundels under the brown fascia,
## a quarter-round scroll bracket each side of every column, flared caps and octagonal bases, a
## terracotta soffit, pebble paving, black bollard lights (refs/new/dillards_exterior t056_021-031).
static func gallery(b, a, t, n, L0, L1):
	var g = "ex_entry"
	run_box(b, g, "ex_canopy_brown", a, t, n, L0, L1, 4.6, 5.0, 3.7, 3.8, [])
	b.quad(g, "ex_soffit_terra", [a + t * L0 + UP * 4.59, a + t * L1 + UP * 4.59, a + t * L1 + n * 3.6 + UP * 4.59, a + t * L0 + n * 3.6 + UP * 4.59], -UP)
	var fy0 = 4.08; var fy1 = 4.58
	var fr = a + n * 3.66
	b.quad(g, "ex_lace", [fr + t * L0 + UP * fy0, fr + t * L1 + UP * fy0, fr + t * L1 + UP * fy1, fr + t * L0 + UP * fy1], n,
		[Vector2(0, 1), Vector2(L1 - L0, 1), Vector2(L1 - L0, 0), Vector2(0, 0)])
	for ue in [L0, L1]:
		var e0 = a + t * ue
		b.quad(g, "ex_lace", [e0 + n * 0.05 + UP * fy0, e0 + n * 3.66 + UP * fy0, e0 + n * 3.66 + UP * fy1, e0 + n * 0.05 + UP * fy1], t,
			[Vector2(0, 1), Vector2(3.6, 1), Vector2(3.6, 0), Vector2(0, 0)])
	var cnt = int((L1 - L0 - 0.4) / 3.6)
	var step = (L1 - L0 - 1.0) / max(1, cnt)
	for i in cnt + 1:
		var u = L0 + 0.5 + i * step
		var p = a + t * u + n * 3.4
		b.cyl(g, "ex_bronze", p + UP * 0.7, 0.085, 0.075, 3.05, 10, false)
		b.cyl(g, "ex_bronze", p + UP * 3.72, 0.08, 0.2, 0.36, 10, true)
		b.box(g, "ex_bronze", p + UP * 4.12, Vector3(0.42, 0.08, 0.42))
		b.cyl(g, "ex_bronze", p, 0.2, 0.2, 0.7, 8, true)
		b.cyl(g, "ex_bronze", p + UP * 0.7, 0.14, 0.085, 0.12, 8, false)
		var bp = a + n * 3.4
		for sd in [-1.0, 1.0]:
			if (sd < 0 and u - 0.9 < L0) or (sd > 0 and u + 0.9 > L1):
				continue
			var q0 = bp + t * u; var q1 = bp + t * (u + sd * 0.9)
			b.quad(g, "ex_lace_bracket", [q1 + UP * 3.68, q0 + UP * 3.68, q0 + UP * 4.58, q1 + UP * 4.58], n,
				[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])
		b.obst(["rect", p.x - 0.25, p.z - 0.25, p.x + 0.25, p.z + 0.25])
	b.quad(g, "ex_pebble", [a + t * L0 + UP * 0.01, a + t * L1 + UP * 0.01, a + t * L1 + n * 4.5 + UP * 0.01, a + t * L0 + n * 4.5 + UP * 0.01], UP)
	var k = L0 + 4.0
	while k < L1 - 2.0:
		var p = a + t * k + n * 5.2
		b.cyl(g, "ex_fence_black", p, 0.1, 0.1, 1.0, 8, true)
		b.cyl(g, "ex_lamp", p + UP * 0.8, 0.09, 0.09, 0.15, 8, false)
		b.tag(b.add_omni(p + UP * 0.9, 1.0, 5.0, Color("#FFD9A8")), "night")
		b.obst(["rect", p.x - 0.15, p.z - 0.15, p.x + 0.15, p.z + 0.15])
		k += 10.0

## Dillard's entrance portal on the Bayou Gardens face (s2s, 4490 f046-056): two big peach piers
## standing out past the gallery, a cream entablature with the "Dillard's" letters, a bronze-framed
## glass front of 4 door pairs under a transom, cans in a white soffit. The detail is a GUESS from
## the 1 fps frames.
static func portal(b, a, t, n, u):
	var g = "ex_entry"
	var W = 12.0; var D = 4.6; var H = 8.2
	for sd in [-1.0, 1.0]:
		var pc = a + t * (u + sd * (W * 0.5 - 0.7)) + n * (D * 0.5) + UP * (H * 0.5)
		b.box(g, "ex_eifs_peach", pc, b.abs_size(t, 1.4, H, D, n))
		b.box(g, "ex_cream_pier", pc - UP * (H * 0.5 - 0.5), b.abs_size(t, 1.5, 1.0, D + 0.1, n))
		var po = a + t * (u + sd * (W * 0.5 - 0.7)) + n * (D * 0.5)
		b.obst(["rect", min(po.x, po.x) - 0.75, po.z - D * 0.5, po.x + 0.75, po.z + D * 0.5])
	# the entablature over the opening, the soffit and its cans
	b.box(g, "ex_cream_pier", a + t * u + n * (D * 0.5) + UP * (H - 0.9), b.abs_size(t, W, 1.8, D, n))
	b.box(g, "ex_cream_pier", a + t * u + n * (D * 0.5 + 0.1) + UP * (H + 0.15), b.abs_size(t, W + 0.6, 0.3, D + 0.4, n))
	b.quad(g, "ex_soffit_white", [a + t * (u - W * 0.5 + 1.4) + UP * (H - 1.81), a + t * (u + W * 0.5 - 1.4) + UP * (H - 1.81), a + t * (u + W * 0.5 - 1.4) + n * D + UP * (H - 1.81), a + t * (u - W * 0.5 + 1.4) + n * D + UP * (H - 1.81)], -UP)
	for i in 3:
		var c = a + t * (u - 3.0 + i * 3.0) + n * (D * 0.5) + UP * (H - 1.85)
		b.cyl(g, "ex_can", c, 0.12, 0.12, 0.02, 10, false, true)
		b.tag(b.add_spot(c, -UP, 1.5, 8.0, 60.0, Color("#FFE6C2")), "night")
	b.label("Dillard's", "serif", "#3b2e28", a + t * u + n * (D + 0.06) + UP * (H - 0.9), n, 7.0, 1.1)
	# the glass front: 4 door pairs, a transom, a fanlight band
	entry_doors(b, a, t, n, u - W * 0.5 + 1.5, u + W * 0.5 - 1.5, 4)
	b.quad(g, "ex_pebble", [a + t * (u - W * 0.5) + UP * 0.012, a + t * (u + W * 0.5) + UP * 0.012, a + t * (u + W * 0.5) + n * (D + 1.0) + UP * 0.012, a + t * (u - W * 0.5) + n * (D + 1.0) + UP * 0.012], UP)
	trash_can(b, a + t * (u - W * 0.5 - 0.8) + n * 1.2)

## A semi trailer (white box, dark chassis, wheels) parked with its back at `at`, running `len` along d.
static func trailer(b, at, d, len):
	var g = "ex_props"
	var bs = Basis(d, UP, d.cross(UP))
	var c = at - d * (len * 0.5)
	b.box(g, "ex_tank_white", Vector3.ZERO, Vector3(len, 2.7, 2.5), Transform3D(bs, c + UP * 2.6))
	b.box(g, "ex_signal", Vector3.ZERO, Vector3(len, 0.3, 2.2), Transform3D(bs, c + UP * 1.1))
	for k in 2:
		var wc = at - d * (1.6 + k * 1.3)
		for sd in [-1.0, 1.0]:
			b.cyl(g, "ex_signal", wc + d.cross(UP) * (sd * 1.0) + UP * 0.5, 0.5, 0.5, 0.3, 10, true)
	var p1 = at - d * len
	b.obst(["rect", min(at.x, p1.x) - 1.3, min(at.z, p1.z) - 1.3, max(at.x, p1.x) + 1.3, max(at.z, p1.z) + 1.3])

## A box truck (white box, cab) backed onto a dock at `at`; d points from the truck to the dock.
static func box_truck(b, at, d, lynns):
	var g = "ex_props"
	var bs = Basis(d, UP, d.cross(UP))
	b.box(g, "ex_tank_white", Vector3.ZERO, Vector3(7.0, 2.6, 2.5), Transform3D(bs, at - d * 3.5 + UP * 2.2))
	b.box(g, "ex_tank_white", Vector3.ZERO, Vector3(2.2, 1.9, 2.4), Transform3D(bs, at - d * 8.2 + UP * 1.55))
	b.box(g, "ex_glass_dark", Vector3.ZERO, Vector3(0.05, 0.8, 2.0), Transform3D(bs, at - d * 9.31 + UP * 2.0))
	for x in [1.2, 5.6, 8.3]:
		for sd in [-1.0, 1.0]:
			b.cyl(g, "ex_signal", at - d * x + d.cross(UP) * (sd * 1.05) + UP * 0.45, 0.45, 0.45, 0.28, 10, true)
	if lynns:
		b.label("Lynn's", "script", "#1c1c1e", at - d * 3.5 + UP * 2.4 + d.cross(UP) * 1.27, d.cross(UP), 3.0, 0.9)
	var p1 = at - d * 9.4
	b.obst(["rect", min(at.x, p1.x) - 1.3, min(at.z, p1.z) - 1.3, max(at.x, p1.x) + 1.3, max(at.z, p1.z) + 1.3])

# ------------------------------------------------------------------ the lot
static func lot(b):
	b_ref = b
	var g = "ex_ground"
	var M = E.map
	# the ground: jointed concrete panels out past the roads (Workstream LOT, Nov 8 2026: Steven, concrete in
	# both years; the "tile lines" were the old texture's thick black joints aliasing without mipmaps)
	var x0 = M[0] - 30.0; var z0 = M[1] - 30.0; var x1 = M[2] + 30.0; var z1 = M[3] + 30.0
	lot_ground(b, LOT_WEST - 4.0, z0, x1, z1)
	# the roads: West Park Ave (east, 4 lanes), Bayou Gardens Blvd (south), Armour Dr (north)
	road(b, Vector3(ROAD_WEST_PARK, 0, z0 - 80.0), Vector3(ROAD_WEST_PARK, 0, z1 + 80.0), 13.0)
	road(b, Vector3(x0 - 140.0, 0, ROAD_BAYOU), Vector3(ROAD_WEST_PARK - 6.5, 0, ROAD_BAYOU), 11.0)
	road(b, Vector3(ROAD_WEST_PARK + 6.5, 0, ROAD_BAYOU), Vector3(x1 + 200.0, 0, ROAD_BAYOU), 11.0)
	road(b, Vector3(x0 - 140.0, 0, ROAD_ARMOUR), Vector3(ROAD_WEST_PARK - 6.5, 0, ROAD_ARMOUR), 9.0)
	road(b, Vector3(ROAD_WEST_PARK + 6.5, 0, ROAD_ARMOUR), Vector3(x1 + 200.0, 0, ROAD_ARMOUR), 9.0)
	# the lawns: the verges beyond the roads, the west edge, the apartments' land
	var gw = ROAD_WEST_PARK + 6.5
	b.quad(g, "ex_grass", [Vector3(gw, 0.02, z0 - 80.0), Vector3(x1 + 200.0, 0.02, z0 - 80.0), Vector3(x1 + 200.0, 0.02, z1 + 80.0), Vector3(gw, 0.02, z1 + 80.0)], UP, [], false, 0.1)
	b.quad(g, "ex_grass", [Vector3(x0 - 140.0, 0.02, ROAD_BAYOU + 5.5), Vector3(gw - 13.0, 0.02, ROAD_BAYOU + 5.5), Vector3(gw - 13.0, 0.02, z1 + 80.0), Vector3(x0 - 140.0, 0.02, z1 + 80.0)], UP, [], false, 0.1)
	b.quad(g, "ex_grass", [Vector3(x0 - 140.0, 0.02, z0 - 80.0), Vector3(gw - 13.0, 0.02, z0 - 80.0), Vector3(gw - 13.0, 0.02, ROAD_ARMOUR - 4.5), Vector3(x0 - 140.0, 0.02, ROAD_ARMOUR - 4.5)], UP, [], false, 0.1)
	b.quad(g, "ex_grass", [Vector3(x0 - 140.0, 0.02, ROAD_ARMOUR + 4.5), Vector3(LOT_WEST - 2.0, 0.02, ROAD_ARMOUR + 4.5), Vector3(LOT_WEST - 2.0, 0.02, ROAD_BAYOU - 5.5), Vector3(x0 - 140.0, 0.02, ROAD_BAYOU - 5.5)], UP, [], false, 0.1)
	b.quad(g, "ex_grass", [Vector3(LOT_WEST - 2.0, 0.025, ROAD_ARMOUR + 4.5), Vector3(APTS[2], 0.025, ROAD_ARMOUR + 4.5), Vector3(APTS[2], 0.025, APTS[3]), Vector3(LOT_WEST - 2.0, 0.025, APTS[3])], UP, [], false, 0.1)
	b.obst(["rect", LOT_WEST - 40.0, ROAD_ARMOUR + 4.5, APTS[2], APTS[3]])
	b.obst(["rect", M[0] - 10.0, ROAD_ARMOUR + 4.5, LOT_WEST - 2.0, ROAD_BAYOU - 5.5])
	# the curb along the lot's edges (a grey road curb on the verge's line)
	for e in [[Vector3(APTS[2], 0, ROAD_ARMOUR + 4.5), Vector3(ROAD_WEST_PARK - 6.5, 0, ROAD_ARMOUR + 4.5)],
			[Vector3(LOT_WEST - 2.0, 0, ROAD_BAYOU - 5.5), Vector3(ROAD_WEST_PARK - 6.5, 0, ROAD_BAYOU - 5.5)]]:
		var c = (e[0] + e[1]) * 0.5
		b.box("ex_lot", "ex_curb", c + UP * 0.07, Vector3(e[0].distance_to(e[1]), 0.14, 0.3), Transform3D.IDENTITY, ["-y"])
	lot_keepouts()
	ROWS = []; FIELD = 0   # EXT-LOT
	# the stall fields: the front lot (West Park), the back lot (Armour Dr), the staff lot, the west
	# lot behind JCPenney ("where a lot of us learned how to skate"), the south lot (Bayou Gardens)
	lot_field(52.0, -240.0, 104.0, 200.0, true, 0)
	lot_field(-120.0, -244.0, 52.0, -156.0, false, 1)
	lot_field(-150.0, -144.0, -86.0, -38.0, false, 0)
	lot_field(-356.0, -146.0, -236.0, 200.0, true, 1)
	lot_field(-236.0, 116.0, 52.0, 200.0, false, 0)
	lot_field(-236.0, -146.0, -150.0, -36.0, true, 0)
	entry_drive(b)
	ada_stalls(b)
	# Bayou Gardens frontage: a long mulched island with sabal palms in a row plus live oaks, cut by
	# the Bayou Gardens drive in front of the south entrance (monuments.gd)
	var fz = ROAD_BAYOU - 10.0
	island(b, -236.0, fz - 2.0, BAYOU_DRIVE[0], fz + 2.0)
	island(b, BAYOU_DRIVE[1], fz - 2.0, 60.0, fz + 2.0)
	for i in 24:
		var px = -231.0 + i * 12.5
		if px > BAYOU_DRIVE[0] - 1.0 and px < BAYOU_DRIVE[1] + 1.0:
			continue
		palm(b, Vector3(px, 0.08, fz), 7.0 + (i % 3))
	for i in 5:
		var ox = -218.0 + i * 60.0
		if ox > BAYOU_DRIVE[0] - 3.0 and ox < BAYOU_DRIVE[1] + 3.0:
			ox += 10.0
		tree_oak(b, Vector3(ox, 0.08, fz), 5.5)
	MON.drive(b, BAYOU_DRIVE[0], BAYOU_DRIVE[1], fz - 2.0, ROAD_BAYOU - 5.5)
	stop_sign(b, Vector3(BAYOU_DRIVE[1] + 1.0, 0, fz - 3.0), Vector3(0, 0, -1))
	# the Armour Dr drive into the back lot (monuments.gd puts its sign by it)
	MON.drive(b, -26.0, -14.0, ROAD_ARMOUR + 4.5, -238.0)
	stop_sign(b, Vector3(-13.0, 0, -238.5), Vector3(0, 0, 1))
	# the lawn island with a magnolia and loblolly pines (the south lot's west end)
	island(b, -234.0, 150.0, -206.0, 160.0, "ex_grass")
	tree_oak(b, Vector3(-220.0, 0.08, 155.0), 5.0)
	tree_pine(b, Vector3(-211.0, 0.08, 153.0), 16.0)
	tree_pine(b, Vector3(-229.0, 0.08, 157.0), 15.0)
	# curbs along the building: a 1.65 m concrete sidewalk round the mall between the wall and the curb
	# (Workstream LOT: the lot is asphalt now, so the walk is its own surface), carried round the
	# outside corners; the fire lane past it on the customer faces
	for seg in E.segments:
		var a = V(seg.a); var bb = V(seg.b); var n = V(seg.n)
		var t = (bb - a).normalized()
		var L = a.distance_to(bb)
		if seg.store == "s41":
			continue    # EXT-LAYOUT: no walk or curb across the exit's recess: a flush apron (4416 f002, f005)
		var fl = fire_lane_face(seg)
		var cm = "ex_curb"
		if fl:
			cm = "ex_curb_red" if YEAR == 2026 else "ex_curb_yellow"
		if seg.name == "SOUTHLAND CINEMA":
			# EXT-LAYOUT (Nov 8 2026): the cinema's base has a red curb in both years (4486 f001, f014-f037);
			# the pink fire-lane ladder is today's, on the west face only
			cm = "ex_curb_red"
			fl = YEAR == 2026 and seg.side == "W"
		var e0 = 1.8 if outside_corner(a, n, -t) else 0.0
		var e1 = 1.8 if outside_corner(bb, n, t) else 0.0
		var w0 = a - t * min(e0, 1.65); var w1 = bb + t * min(e1, 1.65)
		b.quad("ex_walks", "ex_walk", [w0 + UP * 0.004, w1 + UP * 0.004, w1 + n * 1.65 + UP * 0.004, w0 + n * 1.65 + UP * 0.004], UP, [], false, 1.0 / 1.65)
		run_box(b, "ex_lot", cm, a, t, n, -e0, L + e1, 0.0, 0.14, 1.8, 0.15)
		# wear near the building: a sealed crack or a patch every 10-25 m along the face, out in the lane
		var u = rng.randf_range(4.0, 12.0)
		while u < L - 2.0:
			var cell = [0, 0, 1][rng.randi() % 3]
			var at = a + t * u + n * rng.randf_range(3.0, 14.0)
			if not kept(at.x - 0.1, at.z - 0.1, at.x + 0.1, at.z + 0.1) or rng.randf() < 0.5:
				lot_decal(b, at, t.rotated(UP, rng.randf_range(-0.6, 0.6)), cell, rng.randf_range(1.6, 3.4) if cell != 2 else rng.randf_range(1.8, 3.0), rng.randf_range(0.6, 1.0) if YEAR == 2026 else rng.randf_range(0.3, 0.6))
			u += rng.randf_range(8.0, 22.0)
		if fl:
			fire_lane(b, a, t, n, a.distance_to(bb))
	# the loading lane in front of the facade between the Shoe Dept box and Dillard's (4492 f096-099):
	# yellow hatching, the box truck's place
	for k in 10:
		var zz = 70.0 + k * 1.0
		stripe(b, Vector3(46.0, 0.013, zz), Vector3(50.0, 0.013, zz + 1.6), 0.18, "ex_stripe_yellow")
	bank_pad(b)

## The lot's ground: 6 m concrete panels (Steven, Nov 8: concrete, both years), one per cell, each turned
## a random quarter turn (the texture has half a joint on every edge, so neighbours always complete the
## joint) and tinted on its own: a slow two-octave mottle (~50 m, ~14 m) times a per-panel shade, with
## about one panel in twelve a lighter replacement (4487: "lighter replacement panels").
static func lot_ground(b, x0, z0, x1, z1):
	var nz = FastNoiseLite.new(); nz.seed = 1969; nz.frequency = 1.0 / 50.0
	var nz2 = FastNoiseLite.new(); nz2.seed = 2026; nz2.frequency = 1.0 / 14.0
	var pr = RandomNumberGenerator.new(); pr.seed = 6
	var s = b.st("ex_ground", "ex_concrete_lot")
	var C = 6.0
	var nx = int(ceil((x1 - x0) / C)); var nzc = int(ceil((z1 - z0) / C))
	var col = func(x, z, k):
		var v = (1.0 + 0.06 * nz.get_noise_2d(x, z) + 0.03 * nz2.get_noise_2d(x, z)) * k
		var w = 0.015 * nz.get_noise_2d(z + 500.0, x)   # a little warmer / cooler
		return Color(v * (1.0 + w), v, v * (1.0 - w))
	for i in nx:
		for j in nzc:
			var xa = x0 + i * C; var xb = min(x1, xa + C)
			var za = z0 + j * C; var zb = min(z1, za + C)
			var k = pr.randf_range(0.94, 1.04)
			if pr.randf() < 0.08:
				k = pr.randf_range(1.08, 1.14)
			var rot = pr.randi() % 4
			# no ground under the building (its texels would be dark and bleed out at 1.6 m a texel)
			var inside = false
			for r in E.roofs:
				if xa >= r[0] and xb <= r[2] and za >= r[1] and zb <= r[3]:
					inside = true
			if inside:
				continue
			# EXT-LAYOUT: cells over the Sears truck well are cut round it (the well is sunk, sears_dock)
			for rc in ground_minus_well(xa, za, xb, zb):
				var p = [Vector3(rc[0], 0, rc[1]), Vector3(rc[2], 0, rc[1]), Vector3(rc[2], 0, rc[3]), Vector3(rc[0], 0, rc[3])]
				var uv = []
				var cs = []
				for q in p:
					cs.append(col.call(q.x, q.z, k))
					var u = (q.x - (x0 + i * C)) / C; var v = (q.z - (z0 + j * C)) / C
					for _r in rot:
						var t = u; u = 1.0 - v; v = t
					uv.append(Vector2(u, v))
				for tri in [[0, 1, 2], [0, 2, 3]]:
					for kk in tri:
						s.set_color(cs[kk]); s.set_normal(UP); s.set_uv(uv[kk]); s.add_vertex(p[kk])

## EXT-LAYOUT: a ground cell [xa, za, xb, zb] less the sunk truck well (WELL), as up to four rectangles.
static func ground_minus_well(xa, za, xb, zb):
	var h = WELL
	if xb <= h[0] or xa >= h[2] or zb <= h[1] or za >= h[3]:
		return [[xa, za, xb, zb]]
	var out = []
	if za < h[1]: out.append([xa, za, xb, h[1]])
	if zb > h[3]: out.append([xa, h[3], xb, zb])
	var zc0 = max(za, h[1]); var zc1 = min(zb, h[3])
	if xa < h[0]: out.append([xa, zc0, h[0], zc1])
	if xb > h[2]: out.append([h[2], zc0, xb, zc1])
	return out

## True when the corner at p (a wall run's end, the run's outward normal n, `along` pointing off the
## run's end) is an outside corner: the square diagonally out from it is clear of every footprint.
static func outside_corner(p, n, along):
	var q = p + n * 0.8 + along * 0.8
	for r in E.roofs:
		if q.x > r[0] and q.x < r[2] and q.z > r[1] and q.z < r[3]:
			return false
	# a neighbouring run that carries on in the same line is not a corner
	var q2 = p + along * 0.8 - n * 0.8
	for r in E.roofs:
		if q2.x > r[0] and q2.x < r[2] and q2.z > r[1] and q2.z < r[3]:
			return false
	return true

## Which faces carry the fire lane: the customer faces round the lots (the east facade, Dillard's
## east and south, JCPenney, the south faces, the cinema's west wall: 4416, 4486 f014-037,
## 4487-4489, 4492-4493), not the store backs on the staff lot, the docks or the service lane.
static func fire_lane_face(seg):
	var a = V(seg.a); var bb = V(seg.b)
	if seg.side == "E" and a.x >= 30.0:
		return not in_bay(seg)
	if seg.name in ["DILLARD'S", "JCPENNEY", "SOUTHLAND CINEMA", "LINK", "PAVILION"]:
		if seg.name == "DILLARD'S" and seg.side in ["N", "W"]:
			return false
		if seg.name == "JCPENNEY" and seg.side == "N":
			return false
		return true
	if seg.side == "S" and a.z >= 92.0 and a.x < -42.0:
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

## Accessible stalls by the entrances. EXT-LOT (Nov 9 2026, Steven, Demo 53: the old symbols "make zero sense on
## the outside concrete": they sat on a 2 m search grid, off the stall lines and out in the aisles). Now, for each
## customer door, the stall rows whose end nearest the building lies within 40 m of the door; of those, the
## nearest row and every other row of the same field after it (rows 0, 2, ...; at most two a door, never every
## row). In each chosen row, on the side facing the door, the first two stalls from the building end carry the
## wheelchair symbol, centred and wholly inside the stall lines (the symbol keeps its 1.5 m size), turned to read
## from the drive aisle; the third stall is the striped access aisle beside the pair (blue hatching in a blue
## frame, as filmed at JCPenney's west side, 4488 f005, f009). Both years; 1995's aisle colour is a GUESS (blue,
## as the 1991 ADA standard's symbol). The stall lines stay the lot's yellow.
static func ada_stalls(b):
	var spots = []
	for d in E.doors:
		if d.store in ["s41", "s1x"]:
			continue
		spots.append(Vector3(d.out[0], 0, d.out[1]))
	spots.append(Vector3(-214.0 - 2.0, 0, 46.0))      # JCPenney's tree-side entrance
	spots.append(Vector3(-200.0, 0, 108.0))           # JCPenney's arcade
	var used_rows = {}
	var pairs = 0
	for p in spots:
		# the run of each (field, row) whose end is nearest this door
		var best = {}
		for ri in ROWS.size():
			var r = ROWS[ri]
			if r.n < 3:
				continue
			var e0 = r.p; var e1 = r.p + r.t * (r.n * 2.7)
			var near0 = e0.distance_to(p) <= e1.distance_to(p)
			var d = min(e0.distance_to(p), e1.distance_to(p))
			if d > 40.0:
				continue
			var key = "%d:%d" % [r.field, r.row]
			if not best.has(key) or d < best[key][0]:
				best[key] = [d, ri, near0]
		var cands = best.values()
		if cands.is_empty():
			continue
		cands.sort_custom(func(u, v): return u[0] < v[0])
		var r0 = ROWS[cands[0][1]]
		var taken = 0
		for cnd in cands:
			var r = ROWS[cnd[1]]
			if r.field != r0.field or abs(r.row - r0.row) % 2 != 0:
				continue    # every other row, not every row
			var key = "%d:%d" % [r.field, r.row]
			if used_rows.has(key) or taken >= 2:
				continue
			used_rows[key] = true
			taken += 1
			pairs += 1
			ada_pair(b, r, cnd[2], p)
	print("exterior: accessible stalls, ", pairs, " pairs")

## One accessible pair in row r: stalls 0 and 1 from the building end (near0: the run's start), on the side
## nearer `door`, and the hatched access aisle in stall 2.
static func ada_pair(b, r, near0, door):
	var t = r.t if near0 else -r.t
	var e = r.p if near0 else r.p + r.t * (r.n * 2.7)
	var s = Vector3(-t.z, 0, t.x)
	var side = 1.0
	var q0 = e + t * 1.35
	if (q0 - s * 2.75).distance_to(door) < (q0 + s * 2.75).distance_to(door):
		side = -1.0
	var into = -s * side        # from the stall's aisle end toward the row's centre line
	var at0 = e + t * 1.35 + s * (side * 2.75)
	print("  accessible pair at (%.1f, %.1f), into (%.0f, %.0f)" % [at0.x, at0.z, into.x, into.z])
	for k in 2:
		var c = e + t * (k * 2.7 + 1.35) + s * (side * 2.75) + UP * 0.015
		var right = into.cross(UP)  # the symbol's right as you look at it walking in from the aisle
		var h = 0.75
		b.quad("ex_paint", "ex_ada", [c - right * h - into * h, c + right * h - into * h, c + right * h + into * h, c - right * h + into * h], UP,
			[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)], true)
	# the access aisle: stall 2, a blue frame 0.15 m inside the yellow lines, 45-degree hatching at 0.6 m
	var a0 = e + t * (2.0 * 2.7) + s * (side * 0.0)
	var W = 2.7; var D = 5.5; var m = 0.15
	var P = func(u, v): return a0 + t * u + s * (side * v)
	var corners = [P.call(m, m), P.call(W - m, m), P.call(W - m, D - m), P.call(m, D - m), P.call(m, m)]
	for k in 4:
		stripe(b, corners[k], corners[k + 1], 0.1, "ex_lot_ada_blue")
	var u0 = m; var u1 = W - m; var v0 = m; var v1 = D - m
	var c0 = -(v1 - v0) + 0.3
	while c0 < (u1 - u0):
		# the line u - u0 = (v - v0) + c0, clipped to the box
		var va = max(v0, v0 - c0); var vb = min(v1, v0 + (u1 - u0) - c0)
		if vb - va > 0.2:
			stripe(b, P.call(u0 + (va - v0) + c0, va), P.call(u0 + (vb - v0) + c0, vb), 0.1, "ex_lot_ada_blue")
		c0 += 0.6

static func road(b, a, bb, w):
	var t = (bb - a).normalized(); var s = Vector3(-t.z, 0, t.x) * (w * 0.5)
	b.quad("ex_ground", "ex_asphalt", [a - s + UP * 0.01, bb - s + UP * 0.01, bb + s + UP * 0.01, a + s + UP * 0.01], UP, [], false, 0.1)
	stripe(b, a + UP * 0.005, bb + UP * 0.005, 0.12, "ex_stripe_yellow")
	stripe(b, a - s * 0.5 + UP * 0.005, bb - s * 0.5 + UP * 0.005, 0.1, "ex_stripe_white")
	stripe(b, a + s * 0.5 + UP * 0.005, bb + s * 0.5 + UP * 0.005, 0.1, "ex_stripe_white")
	# a grass verge past the road edge is drawn by the caller

## The entry drive from West Park Ave: 2 lanes, double yellow centreline, 12 sabal palms per side in
## narrow mulch medians with yellow curbs ("that's key"; 4492 f053-066), crape-myrtle islands by
## the entrance, the stop bars and the ladder crosswalk, a signal at the road. EXT-B: to the road at
## x 106 (was 92).
static func entry_drive(b):
	var g = "ex_ground"
	var x0 = 50.0; var x1 = ROAD_WEST_PARK - 6.5
	# the drive itself is the lot's concrete (4492 f060: jointed panels between the palms; LOT, Nov 8)
	stripe(b, Vector3(x0, 0.01, -0.12), Vector3(x1, 0.01, -0.12), 0.1, "ex_stripe_yellow")
	stripe(b, Vector3(x0, 0.01, 0.12), Vector3(x1, 0.01, 0.12), 0.1, "ex_stripe_yellow")
	for sd in [-1.0, 1.0]:
		island(b, x0 + 4.0, sd * 3.7 - (1.2 if sd < 0 else 0.0), x1 - 2.0, sd * 3.7 + (1.2 if sd > 0 else 0.0))
		for i in 12:
			palm(b, Vector3(x0 + 6.0 + i * ((x1 - x0 - 10.0) / 11.0), 0.08, sd * 4.3), 6.0 + (i % 3) * 0.8)
	for sd in [-1.0, 1.0]:
		island(b, 46.5, sd * 8.0 - 1.5, 49.5, sd * 8.0 + 1.5)
		for k in 3:
			FL.shrub(b, Vector3(47.2 + k * 0.8, 0.08, sd * 8.0 + (k - 1) * 0.7), 0.6)
	for sd in [-1.0, 1.0]:
		stripe(b, Vector3(53.0, 0.012, sd * 0.3), Vector3(53.0, 0.012, sd * 3.5), 0.45, "ex_stripe_white")
		stripe(b, Vector3(x1 - 3.0, 0.012, sd * 0.3), Vector3(x1 - 3.0, 0.012, sd * 3.5), 0.45, "ex_stripe_white")
	for k in 9:
		var zz = -3.4 + k * 0.85
		stripe(b, Vector3(50.6, 0.012, zz), Vector3(52.4, 0.012, zz), 0.45, "ex_stripe_white")
	traffic_signal(b, Vector3(x1 + 1.0, 0, -6.0))
	traffic_signal(b, Vector3(x1 + 1.0, 0, 6.0))

static func traffic_signal(b, at):
	var g = "ex_props"
	b.cyl(g, "ex_signal", at, 0.12, 0.1, 6.0, 8, true)
	b.box(g, "ex_signal", at + UP * 5.9 + Vector3(2.5, 0, 0), Vector3(5.0, 0.14, 0.14))
	b.box(g, "ex_signal", at + UP * 5.0 + Vector3(4.5, 0, 0), Vector3(0.35, 1.1, 0.35))
	b.box(g, "ex_signal_red", at + UP * 5.35 + Vector3(4.5, 0, 0.18), Vector3(0.24, 0.24, 0.02))
	b.obst(["rect", at.x - 0.3, at.z - 0.3, at.x + 0.3, at.z + 0.3])

## The Horton Tank (1970, Chicago Bridge & Iron) at JCPenney's NE corner (EXT-B, §5 #6: yard x
## -141..-121, z -32..-9): welded steel, ~11 m dia x 11 m, 4 ring courses, shallow conical roof, caged
## ladder, insulated riser; in a chain-link yard with a shrub mass, next to a peach utility building
## and a conduit pole on a yellow base (4486 f077-102).
static func tank(b):
	var g = "ex_props"
	var c = Vector3(-132.0, 0, -21.0)
	var R = 5.5
	for i in 4:
		b.cyl(g, "ex_tank_white", c + UP * (i * 2.75), R, R, 2.75, 28, false)
		b.cyl(g, "ex_tank_rust", c + UP * (i * 2.75 + 2.7), R + 0.03, R + 0.03, 0.08, 28, false)
	b.cyl(g, "ex_tank_white", c + UP * 11.0, R, 0.3, 1.4, 28, true)
	b.cyl(g, "ex_steel", c + UP * 12.4, 0.3, 0.3, 0.5, 10, true)
	for i in 20:
		b.box(g, "ex_steel", c + Vector3(R + 0.4, 0.3 + i * 0.6, 0), Vector3(0.5, 0.03, 0.03))
	b.box(g, "ex_steel", c + Vector3(R + 0.65, 6.0, 0), Vector3(0.03, 12.0, 0.03))
	b.box(g, "ex_steel", c + Vector3(R + 0.15, 6.0, 0), Vector3(0.03, 12.0, 0.03))
	for i in 7:
		b.cyl(g, "ex_steel", c + Vector3(R + 0.4, 3.0 + i * 1.4, 0), 0.4, 0.4, 0.03, 10, false)
	b.cyl(g, "ex_tank_rust", c + Vector3(0, 0, R + 0.6), 0.2, 0.2, 10.0, 8, false)
	fence(b, "ex_chainlink", [Vector3(-141, 0, -32), Vector3(-121, 0, -32), Vector3(-121, 0, -9), Vector3(-141, 0, -9), Vector3(-141, 0, -32)], 2.2)
	b.box(g, "ex_stucco_peach", Vector3(-125.0, 1.5, -13.0), Vector3(5.0, 3.0, 5.0), Transform3D.IDENTITY, ["-y"])
	shrub(b, Vector3(-138.0, 0, -29.0), "leafy", 2.5)
	shrub(b, Vector3(-138.5, 0, -12.0), "leafy", 2.0)
	b.box(g, "ex_pedestal", Vector3(-119.0, 0.4, -8.0), Vector3(0.6, 0.8, 0.6))
	b.cyl(g, "ex_trunk", Vector3(-119.0, 0.8, -8.0), 0.12, 0.1, 8.0, 7, true)
	b.obst(["rect", -119.3, -8.3, -118.7, -7.7])
	b.obst(["rect", -141.0, -32.0, -121.0, -9.0])
	# the pink-lane sidewalk from the yard west to the docks (4486 f100-110)
	b.quad("ex_paint", "ex_concrete", [Vector3(-154.0, 0.02, -36.0), Vector3(-141.0, 0.02, -36.0), Vector3(-141.0, 0.02, -34.0), Vector3(-154.0, 0.02, -34.0)], UP, [], true, 1.0 / 6.0)

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
## tower with a round blue "NORTH TERREBONNE" seal, far to the W / SW (EXT-B, §5 #14; 4486 f066-086,
## 4487 f002). Only its bearing matters.
static func water_tower(b):
	var g = "ex_far"
	var c = Vector3(-440.0, 0, 60.0)
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

## The outparcels and the neighbours (EXT-B: at the site plan's places, §4 / §5 #3, #4, #9, #10):
## the 870 SF drive-thru bank with the lattice cell tower and the 1-storey strip centre at the far
## SW; Kirschman's (1995, Steven: "Kirschman's", the strip already there) / Big Lots (2026) across
## Armour Dr straight out of Lynn's side exit (4413 f005-007: gable sign, 3-arch loggia, standing-
## seam hoods); Ground Pat'i on Bayou Gardens Blvd directly across from the mall, opposite Dillard's
## (GROUND_PATI; Steven, Nov 8: "directly across the street from the mall, not across West Park at the
## intersection corner"; 4492 f105-107, walking south down the east facade, show it just past Dillard's
## corner across the road; 4489 f078-082 zoom on it from Dillard's west end; the 4-sided cube pole sign,
## brown brick, rust standing-seam mansards);
## the charcoal apartments behind a wood fence on their land north-west of the lot; the soccer
## fields behind a black picket fence and St. Bernadette's cream building with the green roof to the
## west.
static func outparcels(b):
	var g = "ex_far"
	# the drive-thru bank (x -359..-323, z 141..191) and its cell tower
	var bk = Vector3(-346.0, 0, 166.0)
	b.box(g, "ex_brick_brown", bk + UP * 2.0, Vector3(10.0, 4.0, 10.0), Transform3D.IDENTITY, ["-y"])
	b.cyl(g, "ex_roof_dark", bk + UP * 4.0, 9.0, 1.0, 3.0, 4, true)
	b.box(g, "ex_roof_dark", bk + UP * 4.3 + Vector3(11.0, 0, 0), Vector3(12.0, 0.3, 14.0))
	for i in 4:
		b.cyl(g, "ex_pipe_grey", bk + Vector3(6.5 + i * 3.0, 0, 6.5), 0.15, 0.15, 4.2, 8, false)
		b.cyl(g, "ex_pipe_grey", bk + Vector3(6.5 + i * 3.0, 0, -6.5), 0.15, 0.15, 4.2, 8, false)
	b.obst(["rect", bk.x - 5.0, bk.z - 5.0, bk.x + 17.0, bk.z + 7.0])
	var ct = Vector3(-354.0, 0, 184.0)
	for i in 4:
		var a = TAU * i / 4 + PI * 0.25
		b.cyl(g, "ex_steel", ct + Vector3(cos(a) * 1.8, 0, sin(a) * 1.8), 0.1, 0.06, 40.0, 6, true)
	for k in 8:
		b.box(g, "ex_steel", ct + UP * (2.5 + k * 5.0), Vector3(3.6, 0.08, 0.08))
		b.box(g, "ex_steel", ct + UP * (2.5 + k * 5.0), Vector3(0.08, 0.08, 3.6))
	b.obst(["rect", ct.x - 2.0, ct.z - 2.0, ct.x + 2.0, ct.z + 2.0])
	# the strip centre (x -323..-283, z 100..155), its storefront facing east to the lot; no names
	strip(b, Vector3(-312.0, 0, 127.5), 55.0, 18.0, 4.6, Vector3(1, 0, 0))
	# Kirschman's / Big Lots across Armour Dr, its gable sign on the side exit's axis
	var bl = Vector3(-20.0, 0, -288.0)
	b.box(g, "ex_stucco_tan", bl + UP * 3.5, Vector3(60.0, 7.0, 28.0), Transform3D.IDENTITY, ["-y"])
	b.box(g, "ex_coping_dark", bl + UP * 7.05, Vector3(60.2, 0.1, 28.2))
	# the gabled sign parapet and the 3-arch loggia in the middle of the front (facing +z, the mall)
	var fz = bl.z + 14.0
	var sg = b.st(g, "ex_stucco_tan")
	var gc = Vector3(bl.x, 7.0, fz + 0.3)
	b.tri(sg, gc + Vector3(-9.0, 0, 0), gc + Vector3(9.0, 0, 0), gc + Vector3(0, 3.6, 0), Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector3(0, 0, 1))
	b.box(g, "ex_stucco_tan", Vector3(bl.x, 3.5, fz + 0.15), Vector3(18.0, 7.0, 0.3))
	for k in 3:
		var ax = bl.x - 6.0 + k * 6.0
		b.box(g, "ex_glass_dark", Vector3(ax, 1.6, fz + 0.32), Vector3(4.2, 3.2, 0.04))
		var sa = b.st(g, "ex_coping")
		var ac = Vector3(ax, 3.2, fz + 0.33)
		for i in 10:
			var a0 = PI * i / 10.0; var a1 = PI * (i + 1) / 10.0
			b.tri(sa, ac + Vector3(cos(a0) * 2.1, sin(a0) * 1.2, 0), ac + Vector3(cos(a1) * 2.1, sin(a1) * 1.2, 0), ac + Vector3(cos(a0) * 2.4, sin(a0) * 1.4, 0), Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector3(0, 0, 1))
	for k in 4:
		b.box(g, "ex_tank_white", Vector3(bl.x - 27.0 + k * 6.0 + (36.0 if k > 1 else 0.0), 5.6, fz + 0.7), Vector3(5.0, 1.6, 1.4))
	if YEAR == 2026:
		b.label("BIG LOTS!", "sans", "#c8202c", Vector3(bl.x, 8.0, fz + 0.35), Vector3(0, 0, 1), 7.0, 1.0)
	else:
		# Steven's spelling (Nov 3); the sign's letters and colours are not in any picture: a GUESS
		b.label("Kirschman's", "serif", "#4a2e1e", Vector3(bl.x, 8.2, fz + 0.35), Vector3(0, 0, 1), 9.0, 1.0)
		b.label("FURNITURE", "sans", "#4a2e1e", Vector3(bl.x, 7.3, fz + 0.35), Vector3(0, 0, 1), 4.0, 0.36)
	b.quad("ex_ground", "ex_asphalt", [Vector3(bl.x - 40.0, 0.03, fz), Vector3(bl.x + 40.0, 0.03, fz), Vector3(bl.x + 40.0, 0.03, ROAD_ARMOUR - 4.5), Vector3(bl.x - 40.0, 0.03, ROAD_ARMOUR - 4.5)], UP, [], false, 0.1)
	# Ground Pat'i across Bayou Gardens, facing the mall (north, -z): the restaurant set back behind its own
	# small lot, the cube pole sign at the road's edge, the low yellow monument with the grinder beside it
	var gp = Vector3(GROUND_PATI, 0, ROAD_BAYOU + 26.0)
	b.box(g, "ex_brick_brown", gp + UP * 2.2, Vector3(18.0, 4.4, 12.0), Transform3D.IDENTITY, ["-y"])
	b.box(g, "ex_roof_rust", gp + UP * 5.0, Vector3(20.0, 1.4, 14.0))
	b.box(g, "ex_roof_rust", gp + UP * 6.2, Vector3(16.0, 1.0, 10.0))
	for k in 3:
		b.box(g, "ex_glass_dark", gp + Vector3(-5.0 + k * 5.0, 1.5, -6.03), Vector3(2.6, 1.8, 0.05))
	b.quad("ex_ground", "ex_asphalt", [Vector3(gp.x - 20.0, 0.03, ROAD_BAYOU + 5.5), Vector3(gp.x + 20.0, 0.03, ROAD_BAYOU + 5.5), Vector3(gp.x + 20.0, 0.03, gp.z - 6.0), Vector3(gp.x - 20.0, 0.03, gp.z - 6.0)], UP, [], false, 0.1)
	var sp = Vector3(gp.x - 14.0, 0, ROAD_BAYOU + 7.5)
	b.cyl(g, "ex_steel", sp, 0.2, 0.2, 7.0, 8, false)
	b.box(g, "ex_ivory", sp + UP * 8.5, Vector3(3.0, 3.0, 3.0))
	for d in [Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 0, -1)]:
		b.label("Ground Pat'i", "script", "#8a2a1a", sp + UP * 8.5 + d * 1.52, d, 2.7, 0.45)
	var ms = Vector3(gp.x + 12.0, 0, ROAD_BAYOU + 7.5)
	b.box(g, "ex_pipe_yellow", ms + UP * 0.9, Vector3(2.6, 1.4, 0.4))
	b.label("Ground Pat'i", "script", "#8a2a1a", ms + UP * 0.9 + Vector3(0, 0, -0.21), Vector3(0, 0, -1), 2.2, 0.32)
	# the apartments on their land north-west of the lot, behind a wood fence
	fence(b, "ex_fence_wood", [Vector3(LOT_WEST, 0, APTS[3]), Vector3(APTS[2], 0, APTS[3]), Vector3(APTS[2], 0, ROAD_ARMOUR + 5.0)], 1.9)
	for i in 6:
		var ap = Vector3(-330.0 + (i % 3) * 70.0, 0, -205.0 + (i / 3) * 34.0)
		b.box(g, "ex_roof_dark", ap + UP * 3.5, Vector3(36.0, 7.0, 14.0), Transform3D.IDENTITY, ["-y"])
		b.box(g, "ex_roof_grey", ap + UP * 7.3, Vector3(37.0, 0.6, 15.0))
	# the soccer fields behind a black picket fence (west), St. Bernadette's beyond
	fence(b, "ex_fence_black", [Vector3(LOT_WEST - 2.0, 0, -140.0), Vector3(LOT_WEST - 2.0, 0, 40.0)], 1.2)
	b.quad("ex_ground", "ex_grass", [Vector3(-470.0, 0.03, -130.0), Vector3(LOT_WEST - 4.0, 0.03, -130.0), Vector3(LOT_WEST - 4.0, 0.03, 30.0), Vector3(-470.0, 0.03, 30.0)], UP, [], false, 0.1)
	for k in 2:
		var fz2 = -100.0 + k * 75.0
		for gx in [-450.0, -380.0]:
			for sd in [-1.0, 1.0]:
				b.cyl(g, "ex_pole_white", Vector3(gx, 0, fz2 + sd * 3.6), 0.06, 0.06, 2.4, 6, false)
			b.box(g, "ex_pole_white", Vector3(gx, 2.4, fz2), Vector3(0.12, 0.12, 7.3))
	var sb = Vector3(-500.0, 0, -60.0)
	b.box(g, "ex_stucco_cream", sb + UP * 3.0, Vector3(30.0, 6.0, 20.0), Transform3D.IDENTITY, ["-y"])
	b.box(g, "ex_cream_green_roof", sb + UP * 6.6, Vector3(32.0, 1.2, 22.0))

## A one-storey strip centre: cream stucco, brown brick piers along the front, a dark mansard; the
## front faces f. No tenant names (none are legible in the footage).
static func strip(b, c, w, d, h, f = Vector3(0, 0, -1)):
	var g = "ex_far"
	var along = Vector3(-f.z, 0, f.x)
	var bs = Basis(along, UP, f)
	b.box(g, "ex_stucco_cream", Vector3.ZERO, Vector3(w, h, d), Transform3D(bs, c + UP * (h * 0.5)), ["-y"])
	for i in int(w / 7.0) + 1:
		var p = c + along * (-w * 0.5 + i * 7.0) + f * (d * 0.5 + 0.2) + UP * (h * 0.5)
		b.box(g, "ex_brick_brown", Vector3.ZERO, Vector3(0.8, h, 0.4), Transform3D(bs, p))
		if i < int(w / 7.0):
			b.box(g, "ex_glass_dark", Vector3.ZERO, Vector3(5.6, 2.8, 0.05), Transform3D(bs, c + along * (-w * 0.5 + i * 7.0 + 3.5) + f * (d * 0.5 + 0.03) + UP * 1.5))
	b.box(g, "ex_roof_dark", Vector3.ZERO, Vector3(w + 1.0, 1.4, d + 2.2), Transform3D(bs, c + UP * (h + 0.7) + f * 0.6))
	var hw = abs(along.x) * w * 0.5 + abs(f.x) * d * 0.5
	var hd = abs(along.z) * w * 0.5 + abs(f.z) * d * 0.5
	b.obst(["rect", c.x - hw - 1.0, c.z - hd - 1.0, c.x + hw + 1.0, c.z + hd + 1.0])

static func keep_out(r, pad = 0.0):
	KEEP.append([r[0] - pad, r[1] - pad, r[2] + pad, r[3] + pad])

static func kept(x0, z0, x1, z1):
	for r in KEEP:
		if x1 > r[0] and x0 < r[2] and z1 > r[1] and z0 < r[3]:
			return true
	return false

## Where the stalls may not go: the building with its curb, fire lane and drive aisle, the yards,
## the drives, the pads.
static func lot_keepouts():
	KEEP = []
	for r in E.roofs:
		keep_out(r, 8.0)
	for s in E.standalone:
		keep_out(s.rect, 8.0)
	keep_out([-141.0, -32.0, -121.0, -9.0], 4.0)          # the Horton tank's yard
	keep_out([44.0, -10.0, ROAD_WEST_PARK, 10.0])           # the palm drive and its islands
	keep_out([44.0, -100.0, 64.0, -82.0])                   # the east entrance's walk
	keep_out(BANK, 3.0)                                     # the bank pad (§5 #11; LOT: 7,758 SF)
	keep_out([SEARS_W - 40.0, -128.0, SEARS_W, -92.0])      # the Sears dock, truck well and its ramp (EXT-LAYOUT: x -84)
	keep_out([-68.0, 114.0, -36.0, 152.0])                  # Dillard's dock, roll-off, flag island
	keep_out([-160.0, 110.0, -122.0, 136.0])                # the south entrance's drop-off bulb
	keep_out([-27.0, 136.0, -3.0, 156.0])                   # Dillard's portal walk
	keep_out([-152.0, 180.0, -132.0, ROAD_BAYOU])           # the Bayou Gardens drive
	keep_out([-28.0, ROAD_ARMOUR, -12.0, -230.0])           # the Armour Dr drive
	keep_out([-12.0, -170.0, 4.0, -146.0])                  # the side exit's crosswalk (s1x)
	keep_out([-32.0, -162.0, -16.0, -146.0])                # EXT-LAYOUT: the north entrance's walk (s1n)
	keep_out(APTS, 6.0)
	keep_out([-232.0, -36.0, -208.0, -14.0])                # JCPenney's pine island and hydrant
	keep_out([-182.0, -24.0, -150.0, -14.0])                # JCPenney's docks and compactor

## A field of double stall rows inside [x0, z0, x1, z1]. along_x: the rows run east-west (spaced in
## z), else north-south (spaced in x). Each row is cut where it meets a keep-out; every run gets a
## yellow-curbed island at each end, a lot pole on every other row's islands (an oak or a shrub on
## the others), a storm grate in the aisle.
static func lot_field(x0, z0, x1, z1, along_x, seed_ = 0):
	var s0 = z0 if along_x else x0
	var s1 = z1 if along_x else x1
	var a0 = x0 if along_x else z0
	var a1 = x1 if along_x else z1
	var row = 0
	var c = s0 + 5.5
	while c <= s1 - 5.5:
		var runs = []
		var u = a0
		var start = 0.0
		var open_ = false
		while u + 2.7 <= a1:
			var bx = [u, c - 5.5, u + 2.7, c + 5.5] if along_x else [c - 5.5, u, c + 5.5, u + 2.7]
			var free = not kept(bx[0], bx[1], bx[2], bx[3])
			if free and not open_:
				start = u; open_ = true
			if not free and open_:
				runs.append([start, u]); open_ = false
			u += 2.7
		if open_:
			runs.append([start, u])
		for r in runs:
			if r[1] - r[0] < 8.0:
				continue
			# the islands take the run's first and last 3 m
			var i0 = r[0]; var i1 = r[1]
			var p = Vector3(i0 + 3.0, 0, c) if along_x else Vector3(c, 0, i0 + 3.0)
			var t = Vector3(1, 0, 0) if along_x else Vector3(0, 0, 1)
			stall_row(b_ref, p, t, i1 - i0 - 6.0)
			ROWS.append({"p": p, "t": t, "n": int((i1 - i0 - 6.0) / 2.7), "field": FIELD, "row": row})   # EXT-LOT
			for e in [[i0, i0 + 3.0], [i1 - 3.0, i1]]:
				var ic = (e[0] + e[1]) * 0.5
				var at = Vector3(ic, 0.08, c) if along_x else Vector3(c, 0.08, ic)
				var ib = [e[0], c - 1.8, e[1], c + 1.8] if along_x else [c - 1.8, e[0], c + 1.8, e[1]]
				var pole = (row + seed_) % 2 == 0 and (e[0] == i0 or (i1 - i0) > 60.0)
				var kind = (row + int(ic)) % 3
				island(b_ref, ib[0], ib[1], ib[2], ib[3], "ex_mulch", "ex_curb_yellow", not pole and kind == 2, not pole and kind == 1 and (i1 - i0) > 40.0)
				if pole:
					lot_pole(b_ref, at, 0.0 if along_x else PI * 0.5, false)
					for sd in [-1.0, 1.0]:
						var gp = at + (Vector3(0, 0, sd * 1.05) if along_x else Vector3(sd * 1.05, 0, 0))
						FL.grass(b_ref, gp, 0.4)
				elif kind == 0:
					tree_oak(b_ref, at, 3.5)
					for sd in [-1.0, 1.0]:
						var sp = at + (Vector3(0, 0, sd * 1.15) if along_x else Vector3(sd * 1.15, 0, 0))
						FL.shrub(b_ref, sp, 0.5)
						FL.grass(b_ref, sp + (Vector3(0.75, 0, 0) if along_x else Vector3(0, 0, 0.75)), 0.6)
				elif kind == 1 and (i1 - i0) <= 40.0:
					for sd in [-1.0, 0.0, 1.0]:
						var sp = at + (Vector3(0, 0, sd * 1.05) if along_x else Vector3(sd * 1.05, 0, 0))
						FL.shrub(b_ref, sp, 0.45) if sd != 0.0 else FL.grass(b_ref, sp, 0.6)
			# a storm grate in the aisle beyond the row, every ~30 m
			var k = i0 + 15.0
			while k < i1 - 5.0:
				var gp = Vector3(k, 0.012, c + 9.0) if along_x else Vector3(c + 9.0, 0.012, k)
				b_ref.quad("ex_paint", "ex_signal", [gp + Vector3(-0.45, 0, -0.45), gp + Vector3(0.45, 0, -0.45), gp + Vector3(0.45, 0, 0.45), gp + Vector3(-0.45, 0, 0.45)], UP, [], true)
				k += 30.0
		row += 1
		c += 18.0
	FIELD += 1   # EXT-LOT

## A stop sign on a post facing n (the drives' mouths).
static func stop_sign(b, at, n):
	b.cyl("ex_props", "ex_pipe_grey", at, 0.04, 0.04, 2.2, 6, false)
	var s = b.st("ex_props", "ex_red_arcade")
	var c = at + UP * 2.45 + n * 0.05
	var t = Vector3(-n.z, 0, n.x)
	for i in 8:
		var a0 = TAU * (i + 0.5) / 8.0; var a1 = TAU * (i + 1.5) / 8.0
		b.tri(s, c, c + t * (cos(a0) * 0.38) + UP * (sin(a0) * 0.38), c + t * (cos(a1) * 0.38) + UP * (sin(a1) * 0.38), Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, n)
	b.label("STOP", "sans", "#f4efe3", c + n * 0.01, n, 0.5, 0.18)
	b.obst(["rect", at.x - 0.15, at.z - 0.15, at.x + 0.15, at.z + 0.15])

## The bank pad on West Park opposite K&B / Cucos (Steven, Nov 3: "a bank in 1995, not Chase"; the
## Morguard site plan's "#3000 CHASE BANK ... NOT A PART" pad). Workstream LOT (Nov 8 2026), Steven: keep
## it (he had first asked for it to go), shrink it to the pad's 7,758 SF, one storey, brick and nameless in
## both years, the drive-thru canopy on the lot side. Read as: everything (building, canopy, drive lanes,
## lawn) inside a 28.0 x 25.75 m pad (= 721 m2 = 7,758 SF); the building 14 x 14 m, one storey (4.2 m, a
## thin coping); a flat canopy over three drive-thru lanes on its west side, facing the mall's lot. Was a
## 34 x 28 m pad with a 16 x 18 m building, a roof box to 6.4 m and the canopy on the road side.
const BANK = [67.0, -76.875, 95.0, -51.125]       # the pad, x0 z0 x1 z1 (28.0 x 25.75 m)

static func bank_pad(b):
	var g = "ex_far"
	var x0 = BANK[0]; var z0 = BANK[1]; var x1 = BANK[2]; var z1 = BANK[3]
	var zc = (z0 + z1) * 0.5
	# the lawn round the building (east of the lanes), a grey curb
	island(b, 79.0, z0, x1, z1, "ex_grass", "ex_curb")
	# the building: one storey of brick, a thin coping, dark windows to the lot and to the road
	var c = Vector3(87.0, 0.08, zc)
	b.box(g, "ex_brick_brown", c + UP * 2.1, Vector3(14.0, 4.2, 14.0), Transform3D.IDENTITY, ["-y"])
	b.box(g, "ex_coping", c + UP * 4.3, Vector3(14.4, 0.25, 14.4))
	for k in 3:
		b.box(g, "ex_glass_dark", c + Vector3(-7.03, 1.5, -4.5 + k * 4.5), Vector3(0.05, 1.8, 2.4))
	for k in 2:
		b.box(g, "ex_glass_dark", c + Vector3(7.03, 1.5, -3.0 + k * 6.0), Vector3(0.05, 1.8, 2.4))
	b.box(g, "ex_glass_dark", c + Vector3(0, 1.3, 7.03), Vector3(2.0, 2.4, 0.05))   # the door, south face
	# the drive-thru on the lot side: a flat white canopy on square piers over three north-south lanes,
	# the two islands between them with a tube kiosk each
	var dc = Vector3(73.5, 0.0, zc)
	b.box(g, "ex_cream_pier", dc + UP * 4.15, Vector3(10.0, 0.5, 11.0))
	b.quad(g, "ex_soffit_white", [dc + Vector3(-5.0, 3.89, -5.5), dc + Vector3(5.0, 3.89, -5.5), dc + Vector3(5.0, 3.89, 5.5), dc + Vector3(-5.0, 3.89, 5.5)], -UP)
	for k in 2:
		var px = dc.x - 1.5 + k * 3.0
		b.box(g, "ex_curb", Vector3(px, 0.08, zc), Vector3(0.9, 0.16, 7.0))
		for e in [-3.2, 3.2]:
			b.box(g, "ex_cream_pier", Vector3(px, 2.0, zc + e), Vector3(0.6, 4.0, 0.6))
		b.box(g, "ex_steel", Vector3(px, 0.75, zc), Vector3(0.6, 1.2, 0.5))
		b.obst(["rect", px - 0.45, zc - 3.5, px + 0.45, zc + 3.5])
	for e in [-3.2, 3.2]:
		b.box(g, "ex_cream_pier", Vector3(dc.x + 4.7, 2.0, zc + e), Vector3(0.6, 4.0, 0.6))
	# the lanes' dividing lines out to the pad's ends
	for k in 2:
		var lx = dc.x - 1.5 + k * 3.0
		stripe(b, Vector3(lx, 0.0, z0 + 0.5), Vector3(lx, 0.0, zc - 3.6), 0.1, "ex_stripe_white")
		stripe(b, Vector3(lx, 0.0, zc + 3.6), Vector3(lx, 0.0, z1 - 0.5), 0.1, "ex_stripe_white")
	b.obst(["rect", c.x - 7.0, c.z - 7.0, c.x + 7.0, c.z + 7.0])

# ------------------------------------------------------------------ build
## Called by build_mall.gd for --wing=3. Returns the wing.json fields (spawn, walk, doors).
static func build(b):
	E = JSON.parse_string(FileAccess.get_file_as_string("res://exterior.json"))
	YEAR = int(b.YEAR)
	rng.seed = 1995
	trees = 0
	FL.reset()
	DEFER = true
	PENDING = []
	COVERS = []
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
	flush_walls(b)
	# the building blocks the player: its footprint, in rectangles
	for r in E.roofs:
		b.obst(["rect", r[0], r[1], r[2], r[3]])
	print("exterior: ", E.segments.size(), " wall runs, ", E.doors.size(), " doors, ", trees, " trees, flora ", FL.count)
	# the player starts on the main entrance's walk, looking at the doors
	return {"spawn": [52.0, 0.0, 90.0, 2.0], "walk": E.walk, "doors": E.doors, "origin": E.get("origin", [148, 100])}
