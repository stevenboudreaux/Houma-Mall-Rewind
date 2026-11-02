## Builds one wing of the mall (1995 map) from layout_mall.json: res://wing1.tscn or res://wing2.tscn.
## Run: godot --headless --path . --script res://tools/build_mall.gd -- --wing=1   (and --wing=2)
## Units are metres. +x east, +z south, +y up. Map tile (148, 100) is the origin.
##
## The wings (Steven, Oct 7: design/godot-wings.md): the game ships as two files so each stays
## well under GitHub's 100 MB file limit. Wing 1 is Sears down the east halls to the floor change
## at z = 48 where the east hall meets the Dillard's court, with Gumballs; Wing 2 is the Dillard's
## court, the Concourse and JCPenney. Each wing is built for real; the other wing is a stand-in:
## its halls and courts built as usual (coarser lightmap), every storefront a picture captured
## from the other wing's own baked build (tools/capture_standin.gd -> tex/standin/), so looking
## across the seam shows the mall as it is. --wing=0 builds the whole mall into res://main.tscn.
extends SceneTree

const LANE_H = 4.6         # flat ceiling over the store lanes
const VAULT_SPRING = 4.9   # hall vault springing
const COURT_SPRING = 6.6
const RIB_STEP = 1.8
## Halls with a low lay-in ceiling instead of the barrel vault (Steven, Oct 20: "on the side hallway
## running from cucos to the movie theater it wasnt the high ceiling it was a lower drop ceiling with
## standard white/cream ceiling tiles"): the two Sears halls. Their vault notches in the court walls
## are closed.
const DROP_HALLS = ["H1a", "H1b"]
const OPEN_H = 3.2         # storefront opening height
const ANCHOR_FRONT = 24.0  # width of an anchor store's mall entrance (JCPenney's)
## Store looks that differ from the map data (from Steven's photos and memory).
const OVERRIDES = {"CORN DOG 7": {"awningColor": "#f2cf1d", "awningStripe": "#1f2d6e"}}
var TEXEL = 0.16           # lightmap texel size (metres); fast bake for demos

var mall: Node3D
var light_root: Node3D
var mats = {}
var acc = {}               # group -> {material -> SurfaceTool}
var dyn_acc = {}
var L: Dictionary          # layout
var zones = {}             # id -> zone dict
var obstacles = []
var fx_obstacles = []     # fixtures (benches, planters, trash cans): only block when shown
var signs = []             # owner-editable signs (scripts/signs.gd), written to gen/signs.json
var mannequins = []        # window spots for the NPC mannequins (scripts/npcs.gd), gen/mannequins.json
var machines = []          # Pocket Change's machines: stand spot and facing (scripts/npcs.gd), gen/machines.json
var fx = false            # while true, geometry goes to the switchable "fixtures" mesh
var force_dyn = false     # while true, geometry goes to dynamic (unbaked, probe-lit) meshes
var cur_color = Color.WHITE
var atlas_index = {}       # store id -> atlas cell
var fronts = {}            # "x,z|x,z" of a store edge -> captured front (fronts.json)
## The live game's flat storefront paintings on the Godot fronts (Phase 4a) are off: Steven
## (Oct 5, 18:51) prefers the plain storefronts with the vendor's sign until each store is
## built in full 3D from its photos, as Corn Dog 7 is.
const USE_FRONT_ART = false
## Signs taken from the 8-bit game as placeholders (Steven, Oct 7): material, width / height.
const PLACEHOLDER_SIGNS = {"FELGER'S FOOTWEAR": ["sg_ph_felgers", 110.0 / 52.0], "TERREBONNE GENERAL OUTREACH": ["sg_ph_tgmc", 210.0 / 72.0]}
## Stores built in full 3D: their footprint (x0, z0, x1, z1 in metres) is kept clear of the
## generic interiors of neighbouring stores, which would otherwise run through them.
const BUILT_RECTS = {"CORN DOG 7": [-138.0, 68.0, -126.0, 80.0], "POCKET CHANGE": [-110.0, 60.0, -102.0, 100.0],
	"KAY-BEE TOYS": [-34.0, -58.0, -10.0, -52.0], "GUMBALLS": [-20.0, 36.0, -10.0, 48.0],
	"JW": [-80.0, 20.0, -74.0, 48.0], "5-7-9": [-74.0, 20.0, -68.0, 48.0], "COUNTY SEAT": [-94.0, 60.0, -86.0, 100.0],
	"BABBAGE'S": [-130.0, 60.0, -124.0, 68.0], "GOLD 'N' GIFTS UNLIMITED": [-136.0, 60.0, -130.0, 68.0], "SOUND SHOP": [-34.0, -64.0, -10.0, -58.0],
	"WOOLWORTH": [-46.0, -14.0, -10.0, 22.0], "LERNER SHOP": [-38.0, 22.0, -10.0, 36.0],
	"LANE BRYANT": [-34.0, -72.0, -10.0, -64.0], "MILLER'S OUTPOST": [-38.0, -52.0, -10.0, -40.0],
	"GADZOOKS": [-62.0, 24.0, -50.0, 48.0], "THE LIMITED": [-132.0, 20.0, -122.0, 48.0],
	"COACH HOUSE GIFTS": [2.0, 16.0, 26.0, 26.0], "GENERAL NUTRITION CENTER": [2.0, 34.0, 16.0, 38.0],
	"MASTERCUTS": [2.0, -48.0, 16.0, -44.0], "WICKS 'N' STICKS": [-37.0, 36.0, -32.0, 48.0],
	"CHICK-FIL-A": [-102.0, 60.0, -94.0, 86.0], "RADIO SHACK": [2.0, 26.0, 18.0, 32.4],
	"B. DALTON BOOKSELLER": [-110.0, 28.0, -102.0, 48.0], "KARMELKORN": [-36.0, 60.0, -20.0, 70.0],
	"ZALES": [-154.0, 68.0, -146.0, 78.0], "MERRY-GO-ROUND": [-102.0, 28.0, -94.0, 48.0],
	"JEAN NICOLE": [-34.0, -40.0, -10.0, -30.0], "CHAMPS SPORTS": [-122.0, 24.0, -110.0, 48.0],
	"SPORTS AVENUE": [-26.0, 36.0, -20.0, 48.0], "GREAT AMERICAN COOKIE CO": [-32.0, 36.0, -26.0, 48.0],
	"REGIS HAIRSTYLISTS": [-58.0, 60.0, -50.0, 76.0], "AFTERTHOUGHTS": [-40.0, 60.0, -36.0, 72.0],
	"ORANGE JULIUS": [12.0, 6.0, 16.0, 16.0], "GORDON'S JEWELERS": [2.0, -18.0, 12.0, -10.0],
	"CUCOS BORDER CAFE": [22.0, -86.0, 36.0, -70.0], "CLAIRE'S BOUTIQUES": [12.0, -16.0, 20.0, -6.0],
	"MITCHELL'S FORMAL WEAR": [20.0, -18.0, 24.0, -6.0], "TEE TAI'S": [16.0, 6.0, 22.0, 14.0],
	"OPTICAL OUTLET": [22.0, 6.0, 30.0, 16.0], "SAADI'S": [2.0, 66.0, 16.0, 74.0], "GOLDEN CHAIN GANG": [-74.0, 60.0, -68.0, 68.0],
	"SOLARIUM": [-18.0, -86.0, -10.0, -80.0], "RAVE": [-22.0, -80.0, -10.0, -72.0], "CONCEPTS": [-68.0, 60.0, -58.0, 74.0],
	"COUNTRY FAIR": [-124.0, 60.0, -118.0, 70.0], "LION'S SHARE RESTAURANT": [-50.0, 36.0, -40.7, 48.0], "AMERICAN BANK": [-46.0, -86.0, -36.0, -78.0],
	"SOUTHLAND CINEMA": [-70.0, -86.0, -46.0, -76.0]}
var fronts_px = 64.0       # atlas pixels per 2 m tile
# ------------------------------------------------------------------ wings
var WING = 0               # 1 or 2: the wing being built (0: the whole mall, previews)
## The year the build shows (--year= / MALL_YEAR): 1995, or 2026, the mall as Steven filmed it on
## Oct 23 2026 (same building, layout_2026.json's tenants: tools/make_layout_2026.py). A 2026 wing
## is its own scene (wing<n>_2026.tscn), meshes (gen/w<n>y26/), lightmap and stand-in pictures.
var YEAR = 1995
var GEN = "res://gen/"     # where this build's meshes and data go (res://gen/w1/, res://gen/w2/)
## The zones of Wing 2; every other zone is Wing 1.
const WING2_ZONES = ["C3", "H8", "H5", "C4", "H6", "H7"]
## Stores whose wing is not the zone their front faces: Gumballs opens on both the east hall
## (Wing 1) and the Dillard's court, and belongs to Wing 1 (Steven, Oct 7).
const STORE_WING = {"GUMBALLS": 1}
## The seam between the wings: a line on the floor (x0, z, x1) at the east hall's floor change,
## running on across Gumballs' door onto the Dillard's court. Wing 2 is the +z side.
const SEAM = [-20.0, 48.0, 2.0]
## Stand-in storefront pictures: pixels per metre in the capture atlas (fitted at build time)
const STANDIN_ATLAS = Vector2i(4096, 2048)
const STANDIN_OUT = 1.25   # the capture camera stands this far out from the front, in the hall
var zone_wing = {}
var outside = {}           # wing 3: what tools/exterior/exterior.gd returns (spawn, walk, doors)
var standin_slots = []     # [{key, a, t, n, s0, s1, rect}], written to GEN/standin.json
var standin_pxm = 0.0
var facade_levels = {}     # store id -> accuracy level 0..4 (facade_records.json)
const LEVEL_COLORS = ["#8a8a8a", "#b07a3c", "#c9c9c9", "#e2b43a", "#3fae6a"]   # grey, bronze, silver, gold, green
const ATLAS_COLS = 8
const ATLAS_ROWS = 12

# ------------------------------------------------------------------ materials
func obst(o):
	if fx:
		fx_obstacles.append(o)
	else:
		obstacles.append(o)

var raw_tex = false        # previews (tools/qa/preview.gd) read the PNGs directly, no import step

func tex(p):
	if raw_tex:
		var im = Image.load_from_file(ProjectSettings.globalize_path("res://tex/" + p))
		if im == null:
			push_error("missing texture " + p)
			return null
		im.generate_mipmaps()
		return ImageTexture.create_from_image(im)
	return load("res://tex/" + p)

func mat(name):
	if mats.has(name):
		return mats[name]
	var m = StandardMaterial3D.new()
	m.resource_name = name
	match name:
		"plaster":
			m.albedo_texture = tex("plaster.png"); m.roughness = 0.92
		"plaster_white":
			m.albedo_texture = tex("plaster.png"); m.roughness = 0.9
			m.albedo_color = Color(1.25, 1.27, 1.32)
		"drop_tile":
			m.albedo_texture = tex("kb/ceiling.png"); m.roughness = 0.95
			m.albedo_color = Color(1.0, 0.975, 0.92)
		"pink_stripe":
			m.albedo_color = Color("#e48aa0"); m.roughness = 0.6
		"elev_door":
			m.albedo_color = Color("#cbbfa6"); m.metallic = 0.6; m.roughness = 0.35
		"navy_stripe":
			m.albedo_color = Color("#22336b"); m.roughness = 0.6
		"terracotta":
			m.albedo_color = Color("#b4583a"); m.roughness = 0.75
		"crystal":
			m.albedo_color = Color("#f4f8ff"); m.metallic = 0.3; m.roughness = 0.05
			m.emission_enabled = true; m.emission = Color("#fff6e8"); m.emission_energy_multiplier = 2.5
		"cove":
			m.albedo_color = Color.WHITE
			m.emission_enabled = true; m.emission = Color("#ffc98a"); m.emission_energy_multiplier = 5.0
		"ring_glow":
			m.albedo_color = Color.WHITE
			m.emission_enabled = true; m.emission = Color("#fff2dc"); m.emission_energy_multiplier = 1.5
		"black":
			m.albedo_color = Color("#151313"); m.roughness = 0.35
		"velvet":
			m.albedo_color = Color("#2a1a24"); m.roughness = 1.0
		"bulbs":
			m.albedo_color = Color("#fff3c4")
			m.emission_enabled = true; m.emission = Color("#ffe39a"); m.emission_energy_multiplier = 4.0
		"poster":
			m.vertex_color_use_as_albedo = true
			m.emission_enabled = true; m.emission = Color("#ffffff"); m.emission_energy_multiplier = 0.6
		"trim_tan":
			m.albedo_color = Color("#a98a62"); m.roughness = 0.8
		"cream":
			m.albedo_color = Color("#ece2cf"); m.roughness = 0.85
		"bulkhead":
			m.albedo_color = Color("#efe6d3"); m.roughness = 0.8
		"lane_ceiling":
			m.albedo_color = Color("#f0e9da"); m.roughness = 0.9
		"rib":
			m.albedo_color = Color("#fbf8f2"); m.roughness = 0.6
		"vault_glow":
			m.albedo_color = Color("#f3ead8"); m.roughness = 0.9
			m.emission_enabled = true; m.emission = Color("#fff1d6"); m.emission_energy_multiplier = 1.0
			m.set_meta("e_day", 0.45); m.set_meta("e_night", 0.22)   # Oct 7: day a touch dimmer, night brighter (Steven)
		"downlight":
			m.albedo_color = Color.WHITE
			m.emission_enabled = true; m.emission = Color("#fff3df"); m.emission_energy_multiplier = 8.0
			# Godot 4.7 lights the halls mostly from these discs: dim them at night (moodier night, Steven Oct 5)
			m.set_meta("e_day", 6.8); m.set_meta("e_night", 3.4)   # Oct 7: day a touch dimmer, night brighter (Steven)
		"stone":
			m.albedo_texture = tex("stone.png"); m.roughness = 0.55
		"bronze":
			m.albedo_color = Color("#3a2f27"); m.metallic = 0.6; m.roughness = 0.4
		"int_wall":
			m.albedo_color = Color("#ece6da"); m.roughness = 0.9
		"int_floor":
			m.vertex_color_use_as_albedo = true; m.roughness = 0.6
		"int_back":
			m.albedo_texture = tex("int_atlas.png")
			m.emission_enabled = true; m.emission_texture = m.albedo_texture
			m.emission = Color.WHITE; m.emission_energy_multiplier = 0.3
			m.set_meta("e_day", 0.3); m.set_meta("e_night", 0.55)
			m.roughness = 0.8
		"front_art":
			# the live game's storefront paintings (tools/capture_fronts.py), lit
			# a little from within so the signs read at night
			m.albedo_texture = tex("fronts_atlas.png")
			# nearest keeps the live game's pixel look up close; anisotropic mipmaps keep a
			# long frontage seen down the hall from smearing
			m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS_ANISOTROPIC
			m.emission_enabled = true; m.emission_texture = m.albedo_texture
			m.emission = Color.WHITE; m.emission_energy_multiplier = 0.45
			m.set_meta("e_day", 0.15); m.set_meta("e_night", 0.45)
			m.roughness = 0.85
		"int_panel":
			m.albedo_color = Color.WHITE
			m.emission_enabled = true; m.emission = Color("#fffaf2"); m.emission_energy_multiplier = 2.2
			m.set_meta("e_day", 2.2); m.set_meta("e_night", 2.4)
		"vcolor":
			m.vertex_color_use_as_albedo = true; m.roughness = 0.5
		"vcolor_matte":
			m.vertex_color_use_as_albedo = true; m.roughness = 0.85
		"pink":
			m.albedo_color = Color("#dba9a0"); m.roughness = 0.8
		"plum":
			m.albedo_color = Color("#5a2340"); m.roughness = 0.6
		"white_pilaster":
			m.albedo_color = Color("#f5f0e8"); m.roughness = 0.7
		"column":
			m.albedo_color = Color("#f6f2ea"); m.roughness = 0.45
		"wood":
			m.albedo_texture = tex("wood_dark.png"); m.roughness = 0.45
		"door_wood":
			m.albedo_texture = tex("wood_dark.png"); m.roughness = 0.5
			m.albedo_color = Color(1.4, 1.2, 1.0)
		"metal_dark":
			m.albedo_color = Color("#262220"); m.metallic = 0.5; m.roughness = 0.45
		"grille":
			m.albedo_color = Color("#8d8a84"); m.metallic = 0.7; m.roughness = 0.5
		"planter":
			m.albedo_color = Color("#efe8da"); m.roughness = 0.35
		"soil":
			m.albedo_color = Color("#3a2a1f"); m.roughness = 1.0
		"bed_wood":
			m.albedo_texture = tex("wood_dark.png"); m.roughness = 0.6
			m.albedo_color = Color(1.25, 1.1, 1.0)
		"brass":
			m.albedo_color = Color("#b88d3e"); m.metallic = 1.0; m.roughness = 0.3
		"lantern_glass":
			m.albedo_color = Color("#ffe2b0")
			m.emission_enabled = true; m.emission = Color("#ffc977"); m.emission_energy_multiplier = 3.0
		"glass":
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.albedo_color = Color(0.78, 0.86, 0.86, 0.10)
			m.roughness = 0.04; m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
		"palm", "poinsettia", "leafy":
			m.albedo_texture = tex({"palm": "palm_frond.png", "poinsettia": "poinsettia.png", "leafy": "leafy.png"}[name])
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			m.alpha_scissor_threshold = 0.5
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
			m.roughness = 0.7
		"trunk":
			m.albedo_color = Color("#6d5a3e"); m.roughness = 0.95
		"cove_amber", "cove_cool", "cove_warm":
			m.albedo_color = Color.WHITE
			m.emission_enabled = true
			m.emission = {"cove_amber": Color("#FFC98A"), "cove_cool": Color("#DCE6FF"), "cove_warm": Color("#FFD9A8")}[name]
			m.emission_energy_multiplier = 3.0
			m.set_meta("e_day", 0.0); m.set_meta("e_night", 3.0)
		"buff_tile":
			m.albedo_texture = tex("buff_tile.png"); m.roughness = 0.35
		"grey_tile":
			m.albedo_texture = tex("grey_tile.png"); m.roughness = 0.35
		"wood_diag":
			m.albedo_texture = tex("wood_diag.png"); m.roughness = 0.6
		"brown_stone":
			m.albedo_texture = tex("brown_stone.png"); m.roughness = 0.12; m.metallic_specular = 0.7
		"halo":
			m.albedo_color = Color.WHITE
			m.emission_enabled = true; m.emission = Color("#ffffff"); m.emission_energy_multiplier = 1.6
			m.set_meta("e_day", 1.6); m.set_meta("e_night", 1.0)
		"outside_ground":
			m.albedo_color = Color("#7c7a74"); m.roughness = 0.95
		"exit_sign":
			m.albedo_color = Color("#2e7d4f")
			m.emission_enabled = true; m.emission = Color("#3fae6a"); m.emission_energy_multiplier = 0.8
		_:
			if name.begins_with("cd7_"):
				# Corn Dog 7's painted textures (tools/stores/paint_corn_dog_7.py)
				var key = name.substr(4)
				if key == "soffit":
					m.albedo_color = Color("#f4f2ec"); m.roughness = 0.9
				elif key == "glass":
					# clear interior glass (food cases, the kitchen partition): barely there, a faint sheen
					m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
					m.albedo_color = Color(0.9, 0.95, 0.95, 0.06)
					m.roughness = 0.35; m.metallic_specular = 0.1
					m.cull_mode = BaseMaterial3D.CULL_DISABLED
				elif key != "glass":
					m.albedo_texture = tex("cd7/" + key + ".png")
					m.roughness = 0.8
				if key in ["tile_navy", "counter_front", "wall_yellow"]:
					# glazed tile: a soft sheen, not a mirror (the store has its own probe)
					m.roughness = 0.45; m.metallic_specular = 0.5
				elif key == "awning":
					m.roughness = 0.3; m.metallic_specular = 0.7
					m.emission_enabled = true; m.emission_texture = m.albedo_texture
					m.emission = Color.WHITE; m.emission_energy_multiplier = 0.35
					# multiply: the sign glows its own yellow (add would wash it toward white)
					m.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY
					m.set_meta("e_day", 0.12); m.set_meta("e_night", 0.35)
				elif key == "steel":
					# brushed stainless: mostly what the baked light gives it, a little reflection
					m.metallic = 0.4; m.roughness = 0.3; m.albedo_color = Color(1.1, 1.1, 1.12)
				elif key == "troffer":
					m.emission_enabled = true; m.emission_texture = m.albedo_texture
					m.emission = Color.WHITE; m.emission_energy_multiplier = 1.4
					m.set_meta("e_day", 1.4); m.set_meta("e_night", 1.5)
				elif key == "menu":
					# a lit screen shows its picture as is
					m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
				elif key == "floor":
					m.roughness = 0.55; m.metallic_specular = 0.45
			elif name.begins_with("pc_"):
				# Pocket Change: "pc_<module>_<key>" is filled in by
				# tools/stores/pocket_change/<module>.gd's fill_mat(m, key, b)
				var parts = name.substr(3).split("_", true, 1)
				var mp = "res://tools/stores/pocket_change/%s.gd" % parts[0]
				if parts.size() < 2 or not ResourceLoader.exists(mp) or not load(mp).fill_mat(m, parts[1], self):
					push_error("unknown material " + name)
			elif name.begins_with("ap_"):
				# the clothing stores (JW, 5-7-9, County Seat): tools/stores/apparel/kit.gd's fill_mat
				if not load("res://tools/stores/apparel/kit.gd").fill_mat(m, name.substr(3), self):
					push_error("unknown material " + name)
			elif name.begins_with("sr_") or name.begins_with("dl_"):
				# workstream E: the old Sears box (tools/stores/sears/store.gd) and Dillard's level 1
				# (tools/stores/dillards/store.gd), each with its own fill_mat(m, key, b)
				var mod_e = "sears" if name.begins_with("sr_") else "dillards"
				if not load("res://tools/stores/%s/store.gd" % mod_e).fill_mat(m, name.substr(3), self):
					push_error("unknown material " + name)
			elif name.begins_with("gi_"):
				# games, inc. (2026 arcade): tools/stores/games_inc/store.gd's fill_mat(m, key, b)
				if not load("res://tools/stores/games_inc/store.gd").fill_mat(m, name.substr(3), self):
					push_error("unknown material " + name)
			elif name.begins_with("gb_"):
				# Gumballs: tools/stores/gumballs/store.gd's fill_mat(m, key, b)
				if not load("res://tools/stores/gumballs/store.gd").fill_mat(m, name.substr(3), self):
					push_error("unknown material " + name)
			elif name.begins_with("sg_"):
				# the traced channel-letter signs: tools/stores/signs/channel.gd's fill_mat
				if not load("res://tools/stores/signs/channel.gd").fill_mat(m, name.substr(3), self):
					push_error("unknown material " + name)
			elif name.begins_with("ww_"):
				# ws/g: Wicked Wingz (2026, the old Chick-fil-A unit): tools/stores/wingz/store.gd's fill_mat
				if not load("res://tools/stores/wingz/store.gd").fill_mat(m, name.substr(3), self):
					push_error("unknown material " + name)
			elif name.begins_with("y95_"):
				# ws/g: the 1995 additions (KarmelKorn's popcorn, Gadzooks' Beetle): tools/stores/y95/extras.gd
				if not load("res://tools/stores/y95/extras.gd").fill_mat(m, name.substr(4), self):
					push_error("unknown material " + name)
			elif name.begins_with("f26_"):
				# ws/g: the 2026 "through the glass" fronts: tools/stores/fronts26/store.gd's fill_mat
				if not load("res://tools/stores/fronts26/store.gd").fill_mat(m, name.substr(4), self):
					push_error("unknown material " + name)
			elif name.begins_with("gac_"):
				# ws/g: Great American Cookies' case (both years): tools/stores/gac/case.gd's fill_mat
				if not load("res://tools/stores/gac/case.gd").fill_mat(m, name.substr(4), self):
					push_error("unknown material " + name)
			elif name.begins_with("cm_"):
				# ws/g: Cinnamonster (2026, KarmelKorn's corner): tools/stores/cinnamonster/store.gd's fill_mat
				if not load("res://tools/stores/cinnamonster/store.gd").fill_mat(m, name.substr(3), self):
					push_error("unknown material " + name)
			elif name.begins_with("cf_") and YEAR == 2026 and load("res://tools/stores/wingz/store.gd").fill_cf(m, name.substr(3), self):
				# ws/g: in 2026 the Chick-fil-A stall is Wicked Wingz, re-skinned (tools/stores/wingz/store.gd)
				pass
			elif name.begins_with("cf_"):
				# Chick-fil-A, rebuilt from Steven's video: tools/stores/cfa/store.gd's fill_mat
				if not load("res://tools/stores/cfa/store.gd").fill_mat(m, name.substr(3), self):
					push_error("unknown material " + name)
			elif name.begins_with("w9_"):
				# the Wave 9 shops: tools/stores/small/wave9.gd's fill_mat
				if not load("res://tools/stores/small/wave9.gd").fill_mat(m, name.substr(3), self):
					push_error("unknown material " + name)
			elif name.begins_with("w8_"):
				# the Wave 8 shops: tools/stores/small/wave8.gd's fill_mat
				if not load("res://tools/stores/small/wave8.gd").fill_mat(m, name.substr(3), self):
					push_error("unknown material " + name)
			elif name.begins_with("w7_"):
				# the Wave 7 shops: tools/stores/small/wave7.gd's fill_mat
				if not load("res://tools/stores/small/wave7.gd").fill_mat(m, name.substr(3), self):
					push_error("unknown material " + name)
			elif name.begins_with("s6_"):
				# the Wave 6 shops: tools/stores/small/store2.gd's fill_mat
				if not load("res://tools/stores/small/store2.gd").fill_mat(m, name.substr(3), self):
					push_error("unknown material " + name)
			elif name.begins_with("sm_"):
				# the Wave 5 small shops: tools/stores/small/store.gd's fill_mat
				if not load("res://tools/stores/small/store.gd").fill_mat(m, name.substr(3), self):
					push_error("unknown material " + name)
			elif name.begins_with("a2_"):
				# the Wave 4 clothing stores: tools/stores/apparel/more.gd's fill_mat
				if not load("res://tools/stores/apparel/more.gd").fill_mat(m, name.substr(3), self):
					push_error("unknown material " + name)
			elif name.begins_with("wl_"):
				# Woolworth: tools/stores/woolworth/store.gd's fill_mat
				if not load("res://tools/stores/woolworth/store.gd").fill_mat(m, name.substr(3), self):
					push_error("unknown material " + name)
			elif name.begins_with("md_"):
				# the media kit (Babbage's, Sound Shop): tools/stores/media/kit.gd's fill_mat
				if not load("res://tools/stores/media/kit.gd").fill_mat(m, name.substr(3), self):
					push_error("unknown material " + name)
			elif name.begins_with("kb_"):
				# Kay-Bee Toys: tools/stores/kay_bee/store.gd's fill_mat(m, key, b)
				if not load("res://tools/stores/kay_bee/store.gd").fill_mat(m, name.substr(3), self):
					push_error("unknown material " + name)
			elif name.begins_with("cin_"):
				# Southland Cinema's front: tools/stores/cinema/front.gd's fill_mat
				if not load("res://tools/stores/cinema/front.gd").fill_mat(m, name.substr(4), self):
					push_error("unknown material " + name)
			elif name.begins_with("sp_"):
				# the sports stores' stock: tools/stores/small/sports.gd's fill_mat
				if not load("res://tools/stores/small/sports.gd").fill_mat(m, name.substr(3), self):
					push_error("unknown material " + name)
			elif name.begins_with("dir_"):
				# the mall directory kiosks: tools/stores/directory/kiosk.gd's fill_mat (design/godot-directory.md)
				if not load("res://tools/stores/directory/kiosk.gd").fill_mat(m, name.substr(4), self):
					push_error("unknown material " + name)
			elif name.begins_with("standin_w"):
				m = standin_mat(name)
			elif name.begins_with("doorpic_w"):
				# Workstream F: the lot seen out through the exits (tools/exterior/door_view.gd)
				m = load("res://tools/exterior/door_view.gd").mat(self, name)
			elif name.begins_with("ad_"):
				# a framed newspaper ad on a wall (tools/stores/posters/posters.gd): matte newsprint.
				# Dynamic meshes get no lightmap, so the print carries a little of its own light,
				# as if the downlights fell on it (less by day, when the halls are bright)
				var at = tex("ads/" + name.substr(3) + ".png")
				m.albedo_texture = at; m.roughness = 0.9
				m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
				m.emission_enabled = true; m.emission_texture = at; m.emission = Color.WHITE
				m.emission_energy_multiplier = 0.55
				m.set_meta("e_day", 0.35); m.set_meta("e_night", 0.55)
			elif name == "poster_mat":
				m.albedo_color = Color("#f4efe4"); m.roughness = 0.9
				m.emission_enabled = true; m.emission = Color("#f4efe4"); m.emission_energy_multiplier = 0.4
				m.set_meta("e_day", 0.25); m.set_meta("e_night", 0.4)
			elif name.begins_with("floorz_"):
				# bake-time stand-in; the runtime swaps in the procedural floor shader
				m.albedo_color = Color("#d4c4aa"); m.roughness = 0.14; m.metallic_specular = 0.6
			elif name.begins_with("ex_"):
				# the outside (wing 3, tools/exterior/exterior.gd): brick, concrete, stucco, the lot
				if not load("res://tools/exterior/exterior.gd").fill_mat(m, name.substr(3), self):
					push_error("unknown material " + name)
			else:
				push_error("unknown material " + name)
	mats[name] = m
	return m

# ------------------------------------------------------------- mesh helpers
func st(group, mname, dynamic = false):
	if fx:
		group = "fixtures"
		dynamic = true
	if force_dyn:
		dynamic = true
	var A = dyn_acc if dynamic else acc
	if not A.has(group):
		A[group] = {}
	if not A[group].has(mname):
		var s = SurfaceTool.new()
		s.begin(Mesh.PRIMITIVE_TRIANGLES)
		A[group][mname] = s
	return A[group][mname]

func tri(s, a, b, c, ua, ub, uc, n):
	if (b - a).cross(c - a).dot(n) > 0.0:
		var t = b; b = c; c = t
		var tu = ub; ub = uc; uc = tu
	for p in [[a, ua], [b, ub], [c, uc]]:
		s.set_color(cur_color)
		s.set_normal(n)
		s.set_uv(p[1])
		s.add_vertex(p[0])

func quad(group, mname, p, n, uvs = [], dynamic = false, uvscale = 1.0):
	var s = st(group, mname, dynamic)
	if uvs.is_empty():
		for v in p:
			uvs.append(proj_uv(v, n) * uvscale)
	tri(s, p[0], p[1], p[2], uvs[0], uvs[1], uvs[2], n)
	tri(s, p[0], p[2], p[3], uvs[0], uvs[2], uvs[3], n)

func proj_uv(v, n):
	var an = n.abs()
	if an.y >= an.x and an.y >= an.z:
		return Vector2(v.x, v.z)
	elif an.x >= an.z:
		return Vector2(v.z, -v.y)
	return Vector2(v.x, -v.y)

func box(group, mname, c, size, xf = Transform3D.IDENTITY, skip = [], dynamic = false):
	var h = size * 0.5
	var faces = {
		"+x": [Vector3(1, 0, 0), [Vector3(h.x, -h.y, -h.z), Vector3(h.x, h.y, -h.z), Vector3(h.x, h.y, h.z), Vector3(h.x, -h.y, h.z)]],
		"-x": [Vector3(-1, 0, 0), [Vector3(-h.x, -h.y, h.z), Vector3(-h.x, h.y, h.z), Vector3(-h.x, h.y, -h.z), Vector3(-h.x, -h.y, -h.z)]],
		"+y": [Vector3(0, 1, 0), [Vector3(-h.x, h.y, -h.z), Vector3(-h.x, h.y, h.z), Vector3(h.x, h.y, h.z), Vector3(h.x, h.y, -h.z)]],
		"-y": [Vector3(0, -1, 0), [Vector3(-h.x, -h.y, h.z), Vector3(-h.x, -h.y, -h.z), Vector3(h.x, -h.y, -h.z), Vector3(h.x, -h.y, h.z)]],
		"+z": [Vector3(0, 0, 1), [Vector3(h.x, -h.y, h.z), Vector3(h.x, h.y, h.z), Vector3(-h.x, h.y, h.z), Vector3(-h.x, -h.y, h.z)]],
		"-z": [Vector3(0, 0, -1), [Vector3(-h.x, -h.y, -h.z), Vector3(-h.x, h.y, -h.z), Vector3(h.x, h.y, -h.z), Vector3(h.x, -h.y, -h.z)]],
	}
	for k in faces:
		if k in skip:
			continue
		var n = (xf.basis * faces[k][0]).normalized()
		var pts = []
		for q in faces[k][1]:
			pts.append(xf * (c + q))
		quad(group, mname, pts, n, [], dynamic)

func cyl(group, mname, base, r0, r1, hgt, seg = 20, top = true, bottom = false, dynamic = false):
	var s = st(group, mname, dynamic)
	for i in seg:
		var a0 = TAU * i / seg
		var a1 = TAU * (i + 1) / seg
		var d0 = Vector3(cos(a0), 0, sin(a0))
		var d1 = Vector3(cos(a1), 0, sin(a1))
		var p0 = base + d0 * r0
		var p1 = base + d1 * r0
		var p2 = base + d1 * r1 + Vector3(0, hgt, 0)
		var p3 = base + d0 * r1 + Vector3(0, hgt, 0)
		var slope = (r0 - r1) / max(hgt, 0.001)
		var n0 = (d0 + Vector3(0, slope, 0)).normalized()
		var n1 = (d1 + Vector3(0, slope, 0)).normalized()
		var u0 = float(i) / seg * 2.0
		var u1 = float(i + 1) / seg * 2.0
		_tri_n(s, [p0, p1, p2], [n0, n1, n1], [Vector2(u0, 1), Vector2(u1, 1), Vector2(u1, 0)], (n0 + n1).normalized())
		_tri_n(s, [p0, p2, p3], [n0, n1, n0], [Vector2(u0, 1), Vector2(u1, 0), Vector2(u0, 0)], (n0 + n1).normalized())
		if top:
			var c = base + Vector3(0, hgt, 0)
			tri(s, c, p3, p2, Vector2(0.5, 0.5), Vector2(0.5 + d0.x * 0.5, 0.5 + d0.z * 0.5), Vector2(0.5 + d1.x * 0.5, 0.5 + d1.z * 0.5), Vector3.UP)
		if bottom:
			tri(s, base, p0, p1, Vector2(0.5, 0.5), Vector2(0.5, 0.5), Vector2(0.5, 0.5), Vector3.DOWN)

func _tri_n(s, p, n, uv, face_n):
	var order = [0, 1, 2]
	if (p[1] - p[0]).cross(p[2] - p[0]).dot(face_n) > 0.0:
		order = [0, 2, 1]
	for i in order:
		s.set_color(cur_color); s.set_normal(n[i]); s.set_uv(uv[i]); s.add_vertex(p[i])

func poly(group, mname, outline, o, ax, ay, n):
	var idx = Geometry2D.triangulate_polygon(outline)
	if idx.is_empty():
		push_error("triangulation failed in " + group)
		return
	var s = st(group, mname)
	for i in range(0, idx.size(), 3):
		var pts = []
		var uvs = []
		for j in 3:
			var q = outline[idx[i + j]]
			pts.append(o + ax * q.x + ay * q.y)
			uvs.append(Vector2(q.x, -q.y) * 0.25)
		tri(s, pts[0], pts[1], pts[2], uvs[0], uvs[1], uvs[2], n)

func abs_size(t, along, hgt, depth, n):
	var v = t.abs() * along + n.abs() * depth
	return Vector3(max(v.x, 0.001), hgt, max(v.z, 0.001))

# --------------------------------------------------------------- arch math
func arch_R(half, rise):
	return (half * half + rise * rise) / (2.0 * rise)

func arch_pts(half, spring, rise, seg):
	var R = arch_R(half, rise)
	var cy = spring + rise - R
	var th = asin(half / R)
	var out = []
	for i in seg + 1:
		var a = -th + 2.0 * th * i / seg
		out.append(Vector2(R * sin(a), cy + R * cos(a)))
	return out

func arch_y(u, half, spring, rise):
	var R = arch_R(half, rise)
	var cy = spring + rise - R
	return cy + sqrt(max(R * R - u * u, 0.0))

func hall_rise(vh):
	return vh * 0.47   # 3 m half-span -> 1.4 m rise, as in the proof

# --------------------------------------------------------------- zones
func rect_of(z):
	return z.rect   # [x0, z0, x1, z1]

## Hall geometry: frame helpers map (u across from centre, y, s along) to world.
func hall_P(z, u, y, s):
	var r = z.rect
	if z.axis == "z":
		return Vector3((r[0] + r[2]) * 0.5 + u, y, s)
	return Vector3(s, y, (r[1] + r[3]) * 0.5 + u)

func hall_span(z):
	var r = z.rect
	if z.axis == "z":
		return [r[1], r[3], (r[2] - r[0]) * 0.5]
	return [r[0], r[2], (r[3] - r[1]) * 0.5]

func build_hall(z):
	var g = z.id
	var sp = hall_span(z)
	var lo = sp[0]
	var hi = sp[1]
	var hw = sp[2]
	var vh = float(z.vault_half)
	var ax = (hall_P(z, 0, 0, 1) - hall_P(z, 0, 0, 0))
	if is_drop(z):
		drop_hall(z, lo, hi, hw)
		return
	if vh <= 0.0:
		# narrow corridor: flat ceiling, a line of downlights
		quad(g, "lane_ceiling", [hall_P(z, -hw, LANE_H, lo), hall_P(z, hw, LANE_H, lo), hall_P(z, hw, LANE_H, hi), hall_P(z, -hw, LANE_H, hi)], Vector3.DOWN)
		var s0 = lo + 2.0
		while s0 < hi - 1.0:
			var c = hall_P(z, 0, LANE_H - 0.01, s0)
			disc_down(g, c, 0.16)
			add_downlight(c)
			s0 += 4.0
		return
	var rise = hall_rise(vh)
	for side in [-1.0, 1.0]:
		var a = side * vh
		var b = side * hw
		quad(g, "lane_ceiling", [hall_P(z, a, LANE_H, lo), hall_P(z, b, LANE_H, lo), hall_P(z, b, LANE_H, hi), hall_P(z, a, LANE_H, hi)], Vector3.DOWN)
		var nf = (hall_P(z, -side, 0, 0) - hall_P(z, 0, 0, 0)).normalized()
		quad(g, "bulkhead", [hall_P(z, a, LANE_H, lo), hall_P(z, a, VAULT_SPRING, lo), hall_P(z, a, VAULT_SPRING, hi), hall_P(z, a, LANE_H, hi)], nf)
		if hw - vh >= 1.4:
			var s1 = lo + 2.25
			while s1 < hi - 0.8:
				var c2 = hall_P(z, side * (vh + hw) * 0.5, LANE_H - 0.01, s1)
				disc_down(g, c2, 0.17)
				add_downlight(c2)
				s1 += 4.5
	var pts = arch_pts(vh, VAULT_SPRING, rise, 16)
	var R = arch_R(vh, rise)
	var cy = VAULT_SPRING + rise - R
	var skies = []
	for sk in L.get("skylights", []):
		if sk.zone == z.id:
			skies.append(float(sk.at))
	var sku = vh * 0.55
	var skl = 1.3
	for i in pts.size() - 1:
		var a2 = pts[i]
		var b2 = pts[i + 1]
		var mid = (a2 + b2) * 0.5
		var nn = (hall_P(z, 0, cy, 0) - hall_P(z, mid.x, mid.y, 0)).normalized()
		var spans = [[lo, hi]]
		if abs(mid.x) < sku:
			spans = []
			var cur = lo
			var sorted_sk = skies.duplicate()
			sorted_sk.sort()
			for at in sorted_sk:
				spans.append([cur, at - skl])
				cur = at + skl
			spans.append([cur, hi])
		for sp2 in spans:
			var q0 = sp2[0]
			var q1 = sp2[1]
			if q1 - q0 < 0.01:
				continue
			quad(g, "vault_glow", [hall_P(z, a2.x, a2.y, q0), hall_P(z, b2.x, b2.y, q0), hall_P(z, b2.x, b2.y, q1), hall_P(z, a2.x, a2.y, q1)], nn, [Vector2(a2.x, q0), Vector2(b2.x, q0), Vector2(b2.x, q1), Vector2(a2.x, q1)])
	for at in skies:
		hall_skylight(z, at, sku, skl, vh, rise)
	var r = lo + RIB_STEP * 0.5
	while r < hi:
		rib(z, r, pts, vh, rise, ax)
		r += RIB_STEP
	for he in L.hall_ends:
		if he.zone == z.id and he.closed:
			hall_end(z, lo if he.end == "lo" else hi, 1.0 if he.end == "lo" else -1.0, vh, rise)

## A drop ceiling across the whole hall at the lane-ceiling height: cream 2 x 4 ft lay-in tiles
## (kb/ceiling.png, its grid running along the hall), two rows of 2 x 4 troffers a third of the way
## in from each side, a baked downlight under every other one.
func drop_hall(z, lo, hi, hw):
	var g = z.id
	var y = LANE_H
	var wells = drop_wells(z)
	# the ceiling as rectangles around the wells: full-width spans between them, side strips beside
	var rects = []
	var cur = lo
	for w in wells:
		var w0 = w[0] - w[1]; var w1 = w[0] + w[1]
		if w0 > cur:
			rects.append([-hw, hw, cur, w0])
		rects.append([-hw, -w[2], w0, w1])
		rects.append([w[2], hw, w0, w1])
		cur = w1
	rects.append([-hw, hw, cur, hi])
	for rc in rects:
		if rc[3] - rc[2] < 0.005 or rc[1] - rc[0] < 0.005:
			continue
		var pts = [hall_P(z, rc[0], y, rc[2]), hall_P(z, rc[1], y, rc[2]), hall_P(z, rc[1], y, rc[3]), hall_P(z, rc[0], y, rc[3])]
		var uvs = [Vector2(rc[0] / 0.61, rc[2] / 1.22), Vector2(rc[1] / 0.61, rc[2] / 1.22), Vector2(rc[1] / 0.61, rc[3] / 1.22), Vector2(rc[0] / 0.61, rc[3] / 1.22)]
		quad(g, "drop_tile", pts, Vector3.DOWN, uvs)
	for w in wells:
		drop_well(z, w)
	var rows = [-hw * 0.42, hw * 0.42]
	var k = 0
	var s0 = lo + 1.83
	while s0 + 1.22 < hi - 0.6:
		var in_well = false
		for w in wells:
			if s0 + 1.22 > w[0] - w[1] - 0.3 and s0 < w[0] + w[1] + 0.3:
				in_well = true
		if in_well:
			s0 += 3.66
			k += 1
			continue
		for u in rows:
			var u0 = snapped(u, 0.61) - 0.305
			var q = [hall_P(z, u0, y - 0.006, s0), hall_P(z, u0 + 0.61, y - 0.006, s0), hall_P(z, u0 + 0.61, y - 0.006, s0 + 1.22), hall_P(z, u0, y - 0.006, s0 + 1.22)]
			quad(g, "md_troffer", q, Vector3.DOWN, [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)])
			if k % 2 == 0:
				add_downlight(hall_P(z, u0 + 0.305, y - 0.02, s0 + 0.61))
		s0 += 3.66
		k += 1

## The vault half-width a court wall notches for: none for the drop-ceiling halls.
func notch_half(hz):
	return 0.0 if is_drop(hz) else float(hz.vault_half)

## Demo 42 (Steven, Oct 23 2026, after the site visit): every hall has the flat drop ceiling in
## 1995 too; only the four courts keep their vaults. ALL_HALLS_DROP false brings back the
## pre-Demo 42 look (vaults everywhere but the Sears halls).
const ALL_HALLS_DROP = true
func is_drop(z):
	if z.type != "hall" or float(z.get("vault_half", 0)) <= 0.0:
		return false
	return ALL_HALLS_DROP or (z.id in DROP_HALLS and WING != 2)

## Skylight wells cut into a drop hall's ceiling: [s_centre, s_half, u_half].
## The map's hall skylights (props) become square wells; the Sears halls get the three crosswise
## wells the 2026 footage shows (IMG_4414 f008, IMG_4485 f001): H1a's at the court end, H1b's
## about 15 m in from the east doors.
const SEARS_WELLS = {"H1a": [-19.2, -21.8, -24.4], "H1b": [18.4, 21.0, 23.6]}
func drop_wells(z):
	var out = []
	for at in SEARS_WELLS.get(z.id, []):
		out.append([float(at), 0.7, 1.9])
	for sk in L.get("skylights", []):
		if sk.zone == z.id:
			out.append([float(sk.at), 1.3, 1.6])
	out.sort_custom(func(p, q): return p[0] < q[0])
	return out

## One skylight well over a drop ceiling: splayed white sides 1.1 m up to a framed opening (real,
## so the bake gets daylight). Crosswise wells (the Sears halls) carry a low barrel-arched top.
func drop_well(z, w):
	var g = z.id
	var s = w[0]; var sh = w[1]; var uh = w[2]
	var y0 = LANE_H
	var y1 = LANE_H + 1.1
	var sp = 0.25   # splay: the opening is this much smaller each side than the ceiling hole
	var c = [[-uh, -sh], [uh, -sh], [uh, sh], [-uh, sh]]
	for i in 4:
		var p = c[i]; var q = c[(i + 1) % 4]
		var pin = Vector2(p[0], p[1]) * Vector2(1.0 - sp / uh, 1.0 - sp / sh)
		var qin = Vector2(q[0], q[1]) * Vector2(1.0 - sp / uh, 1.0 - sp / sh)
		var a0 = hall_P(z, p[0], y0, s + p[1]); var b0 = hall_P(z, q[0], y0, s + q[1])
		var a1 = hall_P(z, pin.x, y1, s + pin.y); var b1 = hall_P(z, qin.x, y1, s + qin.y)
		var mid_in = hall_P(z, 0, y0, s)
		var nn = (mid_in - (a0 + b0) * 0.5)
		nn.y = 0.0
		quad(g, "rib", [a0, b0, b1, a1], (nn.normalized() + Vector3.DOWN * 0.3).normalized())
	var iu = uh - sp; var ish = sh - sp
	var axs = hall_P(z, 0, 0, 1) - hall_P(z, 0, 0, 0)
	var axu = hall_P(z, 1, 0, 0) - hall_P(z, 0, 0, 0)
	box("glass_frames", "metal_dark", hall_P(z, 0, y1 + 0.02, s), abs_size(axs, ish * 2, 0.06, 0.05, axu), Transform3D.IDENTITY, [], true)
	box("glass_frames", "metal_dark", hall_P(z, 0, y1 + 0.02, s), abs_size(axu, iu * 2, 0.06, 0.05, axs), Transform3D.IDENTITY, [], true)
	if uh > sh * 1.5:
		# the small barrel-arched acrylic top: ribs over the opening, running across the hall
		for k in 5:
			var ss = s - ish + ish * 2.0 * k / 4.0
			var pts = arch_pts(iu, y1, 0.45, 8)
			for j in pts.size() - 1:
				var p2 = pts[j]; var q2 = pts[j + 1]
				box("glass_frames", "metal_dark", (hall_P(z, p2.x, p2.y, ss) + hall_P(z, q2.x, q2.y, ss)) * 0.5,
					abs_size(axu, abs(q2.x - p2.x) + 0.04, abs(q2.y - p2.y) + 0.04, 0.04, axs), Transform3D.IDENTITY, [], true)

## The white segmental-arch soffit where a hall meets a court (2026 footage: every hall/court
## junction, ~0.8 m deep; IMG_4484 f003, IMG_4408). Hangs below the drop ceiling at the hall's mouth.
const MOUTH_DEPTH = 0.8
const MOUTH_SPRING = 3.75
func hall_mouth(z, at, into):
	var g = z.id
	var hw = hall_span(z)[2]
	var rise = LANE_H - 0.12 - MOUTH_SPRING
	var pts = arch_pts(hw, MOUTH_SPRING, rise, 20)
	var axu = hall_P(z, 1, 0, 0) - hall_P(z, 0, 0, 0)
	var axs = hall_P(z, 0, 0, 1) - hall_P(z, 0, 0, 0)
	for face in [0.0, 1.0]:
		var s = at + into * MOUTH_DEPTH * face
		var o = PackedVector2Array()
		o.append(Vector2(-hw, LANE_H))
		for p in pts:
			o.append(Vector2(p.x, p.y))
		o.append(Vector2(hw, LANE_H))
		var n = axs * (-into if face == 0.0 else into)
		poly(g, "rib", o, hall_P(z, 0, 0, s), axu, Vector3.UP, n)
	var R = arch_R(hw, rise)
	var cy = MOUTH_SPRING + rise - R
	for i in pts.size() - 1:
		var a = pts[i]; var b = pts[i + 1]
		var mid = (a + b) * 0.5
		var nn = (hall_P(z, 0, cy, 0) - hall_P(z, mid.x, mid.y, 0)).normalized()
		var s1 = at + into * MOUTH_DEPTH
		quad(g, "rib", [hall_P(z, a.x, a.y, at), hall_P(z, b.x, b.y, at), hall_P(z, b.x, b.y, s1), hall_P(z, a.x, a.y, s1)], nn)

## Every open hall end that meets a court gets its arch.
func hall_mouths():
	for cw in L.court_walls:
		var cz = zones[cw.zone]
		var cr = cz.rect
		for hid in cw.halls:
			var hz = zones[hid]
			if not is_drop(hz):
				continue
			var sp = hall_span(hz)
			var at = 0.0
			var into = 1.0
			match cw.side:
				"n": at = cr[1]; into = -1.0
				"s": at = cr[3]; into = 1.0
				"w": at = cr[0]; into = -1.0
				"e": at = cr[2]; into = 1.0
			if abs(at - sp[0]) > 0.5 and abs(at - sp[1]) > 0.5:
				continue
			hall_mouth(hz, at, into)

## A skylight in the hall vault crown between two ribs: a short light well
## with a muntin frame; the opening is real, so the bake gets daylight.
func hall_skylight(z, at, sku, skl, vh, rise):
	var g = z.id
	var crown = VAULT_SPRING + rise
	var top = crown + 0.7
	# side walls (u = +/- sku), bottom edge on the vault surface
	for sgn in [-1.0, 1.0]:
		var yb = arch_y(sku, vh, VAULT_SPRING, rise) - 0.03
		var nrm = (hall_P(z, -sgn, 0, 0) - hall_P(z, 0, 0, 0)).normalized()
		quad(g, "lane_ceiling", [hall_P(z, sgn * sku, yb, at - skl), hall_P(z, sgn * sku, yb, at + skl), hall_P(z, sgn * sku, top, at + skl), hall_P(z, sgn * sku, top, at - skl)], nrm)
	for sgn in [-1.0, 1.0]:
		var o = PackedVector2Array()
		for i in 7:
			var u = -sku + 2.0 * sku * i / 6
			o.append(Vector2(u, arch_y(u, vh, VAULT_SPRING, rise) - 0.03))
		o.append(Vector2(sku, top)); o.append(Vector2(-sku, top))
		var org = hall_P(z, 0, 0, at + sgn * skl)
		var axu = hall_P(z, 1, 0, 0) - hall_P(z, 0, 0, 0)
		var nrm2 = (hall_P(z, 0, 0, -sgn) - hall_P(z, 0, 0, 0)).normalized()
		poly(g, "lane_ceiling", o, org, axu, Vector3.UP, nrm2)
	var axs = hall_P(z, 0, 0, 1) - hall_P(z, 0, 0, 0)
	var axu2 = hall_P(z, 1, 0, 0) - hall_P(z, 0, 0, 0)
	for k in 4:
		var u = -sku + k * sku * 2.0 / 3.0
		box("glass_frames", "metal_dark", hall_P(z, u, top - 0.05, at), abs_size(axs, skl * 2, 0.08, 0.05, axu2), Transform3D.IDENTITY, [], true)
	for k in 3:
		var s2 = at - skl + k * skl
		box("glass_frames", "metal_dark", hall_P(z, 0, top - 0.05, s2), abs_size(axu2, sku * 2, 0.08, 0.05, axs), Transform3D.IDENTITY, [], true)

func rib(z, at, pts, vh, rise, ax):
	var g = z.id
	var w = 0.07
	var depth = 0.22
	var R = arch_R(vh, rise)
	var cy = VAULT_SPRING + rise - R
	for i in pts.size() - 1:
		var a = pts[i]
		var b = pts[i + 1]
		var ia = a + (Vector2(0, cy) - a).normalized() * depth
		var ib = b + (Vector2(0, cy) - b).normalized() * depth
		var mid = (ia + ib) * 0.5
		var nn = (hall_P(z, 0, cy, 0) - hall_P(z, mid.x, mid.y, 0)).normalized()
		quad(g, "rib", [hall_P(z, ia.x, ia.y, at - w), hall_P(z, ib.x, ib.y, at - w), hall_P(z, ib.x, ib.y, at + w), hall_P(z, ia.x, ia.y, at + w)], nn)
		for sg in [-1.0, 1.0]:
			quad(g, "rib", [hall_P(z, a.x, a.y, at + sg * w), hall_P(z, b.x, b.y, at + sg * w), hall_P(z, ib.x, ib.y, at + sg * w), hall_P(z, ia.x, ia.y, at + sg * w)], ax * sg)

## Closed end of a hall: arched wall above the lane ceiling, plus a white arch trim.
func hall_end(z, at, facing, vh, rise):
	var g = z.id
	var o = PackedVector2Array()
	o.append(Vector2(-vh, LANE_H))
	for p in arch_pts(vh, VAULT_SPRING, rise, 16):
		o.append(p)
	o.append(Vector2(vh, LANE_H))
	var origin = hall_P(z, 0, 0, at)
	var ax = (hall_P(z, 1, 0, 0) - hall_P(z, 0, 0, 0))
	var n = (hall_P(z, 0, 0, 1) - hall_P(z, 0, 0, 0)) * facing
	poly(g, "cream", o, origin, ax, Vector3.UP, n)
	var pts = arch_pts(vh, VAULT_SPRING, rise, 16)
	var R = arch_R(vh, rise)
	var cy = VAULT_SPRING + rise - R
	for i in pts.size() - 1:
		var a = pts[i]
		var b = pts[i + 1]
		var off = n * 0.12
		var ia = a + (Vector2(0, cy) - a).normalized() * 0.3
		var ib = b + (Vector2(0, cy) - b).normalized() * 0.3
		quad(g, "rib", [origin + ax * a.x + Vector3.UP * a.y + off, origin + ax * b.x + Vector3.UP * b.y + off, origin + ax * ib.x + Vector3.UP * ib.y + off, origin + ax * ia.x + Vector3.UP * ia.y + off], n)

# --------------------------------------------------------------- courts
## A court: segmental plaster vault over the shorter span, walls from lane
## height up to the springing with notches where hall vaults come in, a
## square skylight, and a clerestory on long sides no hall enters.
## Demo 42: Dillard's court is vaulted (2026 footage: cream barrel vault, square skylight, white
## arch beams with a navy stripe). DILLARDS_FLAT true brings back the flat ceiling from 2018's 3:34.
const DILLARDS_FLAT = false
func build_court(z):
	if z.style == "dillards" and DILLARDS_FLAT:
		build_court_flat(z)
		return
	var g = z.id
	var vmat = "plaster_white" if z.style == "sears" else "plaster"
	var r = z.rect
	var sx = r[2] - r[0]
	var sz = r[3] - r[1]
	var cx = (r[0] + r[2]) * 0.5
	var cz = (r[1] + r[3]) * 0.5
	var axis = "z" if sz >= sx else "x"   # vault runs along the longer side
	if z.style == "shoe" or z.style == "sears":
		# Sears court (2026 footage, IMG_4408 f036, IMG_4484 f068): the vault runs north-south, the
		# pink-striped arch over the Sears entrance is its north end, clerestories run east and west
		axis = "z"
	var half = (sx if axis == "z" else sz) * 0.5
	var length = sz if axis == "z" else sx
	var rise = clamp(half * 2.0 * 0.19, 1.6, 4.2)
	var R = arch_R(half, rise)
	var cy = COURT_SPRING + rise - R
	var sky = clamp(min(half, length * 0.5) * 0.28, 1.2, 2.2)
	# skylight half-sizes across (u) and along (s) the vault: square, except the Sears court's long
	# lantern down the crown (2.5 m wide in the footage, as long as the court allows)
	var sky_u = sky
	var sky_s = sky
	if z.style == "sears":
		sky_u = 1.3
		sky_s = min(length * 0.5 - 1.0, 7.5)
	# frame: u across the span (from centre), s along the vault (from centre)
	var P = func(u, y, s):
		return Vector3(cx + u, y, cz + s) if axis == "z" else Vector3(cx + s, y, cz + u)
	var pts = arch_pts(half, COURT_SPRING, rise, 40)
	var steps = int(ceil(length / 1.0))
	for i in pts.size() - 1:
		var a = pts[i]
		var b = pts[i + 1]
		var mid = (a + b) * 0.5
		var nn = (P.call(0, cy, 0) - P.call(mid.x, mid.y, 0)).normalized()
		var arc_a = R * asin(a.x / R)
		var arc_b = R * asin(b.x / R)
		for k in steps:
			var s0 = -length * 0.5 + length * k / steps
			var s1 = -length * 0.5 + length * (k + 1) / steps
			if abs(mid.x) < sky_u and abs((s0 + s1) * 0.5) < sky_s:
				continue
			quad(g, vmat, [P.call(a.x, a.y, s0), P.call(b.x, b.y, s0), P.call(b.x, b.y, s1), P.call(a.x, a.y, s1)], nn,
				[Vector2(arc_a, s0) * 0.22, Vector2(arc_b, s0) * 0.22, Vector2(arc_b, s1) * 0.22, Vector2(arc_a, s1) * 0.22])
	# skylight well
	var top = COURT_SPRING + rise + 0.9
	var ys = arch_y(sky_u, half, COURT_SPRING, rise)
	for sgn in [-1.0, 1.0]:
		quad(g, "lane_ceiling", [P.call(sgn * sky_u, ys - 0.05, -sky_s), P.call(sgn * sky_u, ys - 0.05, sky_s), P.call(sgn * sky_u, top, sky_s), P.call(sgn * sky_u, top, -sky_s)], (P.call(-sgn, 0, 0) - P.call(0, 0, 0)).normalized())
		var o = PackedVector2Array()
		for i in 9:
			var u = -sky_u + 2.0 * sky_u * i / 8
			o.append(Vector2(u, arch_y(u, half, COURT_SPRING, rise) - 0.05))
		o.append(Vector2(sky_u, top)); o.append(Vector2(-sky_u, top))
		var org = P.call(0, 0, sgn * sky_s)
		var axu = P.call(1, 0, 0) - P.call(0, 0, 0)
		poly(g, "lane_ceiling", o, org, axu, Vector3.UP, (P.call(0, 0, -sgn) - P.call(0, 0, 0)).normalized())
	var ax_s = P.call(0, 0, 1) - P.call(0, 0, 0)
	var ax_u = P.call(1, 0, 0) - P.call(0, 0, 0)
	if z.style == "sears":
		# the lantern: white crosswise baffles about every 0.75 m down the well, glazed above
		var nb = int(round(sky_s * 2.0 / 0.75))
		for i in nb + 1:
			var s2 = -sky_s + sky_s * 2.0 * i / nb
			box(g, "rib", P.call(0, top - 0.45, s2), abs_size(ax_u, sky_u * 2.0, 0.8, 0.08, ax_s))
		for u in [-sky_u * 0.33, sky_u * 0.33]:
			box("glass_frames", "metal_dark", P.call(u, top - 0.04, 0), abs_size(ax_s, sky_s * 2, 0.08, 0.05, ax_u), Transform3D.IDENTITY, [], true)
	else:
		for i in 5:
			var u = -sky + i * sky * 0.5
			var c1 = P.call(u, top - 0.05, 0)
			var c2 = P.call(0, top - 0.05, u)
			box("glass_frames", "metal_dark", c1, abs_size(ax_s, sky * 2, 0.1, 0.05, ax_u), Transform3D.IDENTITY, [], true)
			box("glass_frames", "metal_dark", c2, abs_size(ax_u, sky * 2, 0.1, 0.05, ax_s), Transform3D.IDENTITY, [], true)
	tag(add_omni(P.call(0, COURT_SPRING, 0), 1.0, half * 2.5, Color(1.0, 0.95, 0.88)), "day")
	# night: four key spots at the springing line, aimed down, so the floor
	# gets broad overlapping pools instead of one hot centre
	for qu in [-0.45, 0.45]:
		for qs in [-0.33, 0.0, 0.33]:
			tag(add_spot(P.call(qu * half, COURT_SPRING - 0.2, qs * length), Vector3.DOWN, 3.2, 12.0, 70.0, Color("#FFE9C8")), "night")
	var cove_col = {"shoe": Color("#FFC98A"), "sears": Color("#DCE6FF")}.get(z.style, Color("#FFD9A8"))
	var cove_mat = {"shoe": "cove_amber", "sears": "cove_cool"}.get(z.style, "cove_warm")
	# walls
	var sides = {}
	for cw in L.court_walls:
		if cw.zone == z.id:
			sides[cw.side] = cw.halls
	for side in ["n", "s", "w", "e"]:
		var halls = sides.get(side, [])
		var horiz = side in ["n", "s"]   # wall runs along x
		var along_vault = (horiz and axis == "x") or (not horiz and axis == "z")
		# wall line and inward normal
		var o2 = Vector3.ZERO
		var axw = Vector3.ZERO
		var nrm = Vector3.ZERO
		var u0 = 0.0
		var u1 = 0.0
		if horiz:
			o2 = Vector3(cx, 0, r[1] if side == "n" else r[3])
			axw = Vector3(1, 0, 0); u0 = r[0] - cx; u1 = r[2] - cx
			nrm = Vector3(0, 0, 1 if side == "n" else -1)
		else:
			o2 = Vector3(r[0] if side == "w" else r[2], 0, cz)
			axw = Vector3(0, 0, 1); u0 = r[1] - cz; u1 = r[3] - cz
			nrm = Vector3(1 if side == "w" else -1, 0, 0)
		var notches = []
		for hid in halls:
			var hz = zones[hid]
			var hr = hz.rect
			var hc = ((hr[0] + hr[2]) * 0.5 - cx) if horiz else ((hr[1] + hr[3]) * 0.5 - cz)
			notches.append([hc, notch_half(hz)])
		notches.sort_custom(func(p, q): return p[0] > q[0])
		# with drop-ceiling halls (no notches) the Sears court keeps its clerestories over the
		# east and west hall mouths, as in the footage
		var clerestory = along_vault and (halls.is_empty() or (z.style == "sears" and notches.all(func(nt): return nt[1] <= 0.0)))
		var bottom = LANE_H
		if clerestory:
			bottom = 6.25
			# band below the windows, the reveal, mullions and glass
			quad(g, "plaster", [o2 + axw * u0 + Vector3.UP * LANE_H, o2 + axw * u1 + Vector3.UP * LANE_H, o2 + axw * u1 + Vector3.UP * 5.0, o2 + axw * u0 + Vector3.UP * 5.0], nrm, [], false, 0.25)
			quad(g, "trim_tan", [o2 + axw * u0 + Vector3.UP * 5.0, o2 + axw * u1 + Vector3.UP * 5.0, o2 + axw * u1 + Vector3.UP * 5.0 - nrm * 0.3, o2 + axw * u0 + Vector3.UP * 5.0 - nrm * 0.3], Vector3.UP)
			quad(g, "trim_tan", [o2 + axw * u0 + Vector3.UP * 6.25, o2 + axw * u1 + Vector3.UP * 6.25, o2 + axw * u1 + Vector3.UP * 6.25 - nrm * 0.3, o2 + axw * u0 + Vector3.UP * 6.25 - nrm * 0.3], Vector3.DOWN)
			var u = u0
			while u <= u1 + 0.01:
				box(g, "trim_tan", o2 + axw * u + Vector3.UP * 5.62 - nrm * 0.15, abs_size(axw, 0.14, 1.25, 0.3, nrm))
				u += 2.0
			quad("glass", "glass", [o2 + axw * u0 + Vector3.UP * 5.0 - nrm * 0.3, o2 + axw * u1 + Vector3.UP * 5.0 - nrm * 0.3, o2 + axw * u1 + Vector3.UP * 6.25 - nrm * 0.3, o2 + axw * u0 + Vector3.UP * 6.25 - nrm * 0.3], nrm, [], true)
		var o = PackedVector2Array()
		o.append(Vector2(u0, bottom))
		if along_vault:
			o.append(Vector2(u0, COURT_SPRING)); o.append(Vector2(u1, COURT_SPRING))
		else:
			for p in pts:
				o.append(Vector2(p.x, p.y))
		o.append(Vector2(u1, bottom))
		if not clerestory:
			for nt in notches:
				var c = nt[0]
				var vh = nt[1]
				if vh <= 0.0:
					continue
				var hrise = hall_rise(vh)
				o.append(Vector2(c + vh, LANE_H))
				var ap = arch_pts(vh, VAULT_SPRING, hrise, 16)
				ap.reverse()
				for p in ap:
					o.append(Vector2(c + p.x, p.y))
				o.append(Vector2(c - vh, LANE_H))
		poly(g, vmat, o, o2, axw, Vector3.UP, nrm)
		# trim: cornice at the springing on long sides, arch band on the ends
		if along_vault:
			box(g, "trim_tan", o2 + Vector3.UP * 6.28 + nrm * 0.12, abs_size(axw, u1 - u0, 0.12, 0.24, nrm))
			# hidden cove on top of the cornice: an emissive strip (night only)
			# and three up-lights washing the vault
			quad(g, cove_mat, [o2 + axw * u0 + Vector3.UP * 6.35 + nrm * 0.03, o2 + axw * u1 + Vector3.UP * 6.35 + nrm * 0.03, o2 + axw * u1 + Vector3.UP * 6.35 + nrm * 0.2, o2 + axw * u0 + Vector3.UP * 6.35 + nrm * 0.2], Vector3.UP)
			for f in [0.2, 0.5, 0.8]:
				var up = o2 + axw * lerp(u0, u1, f) + Vector3.UP * 6.45 + nrm * 0.15
				tag(add_spot(up, (Vector3.UP * 1.0 + nrm * 0.55), 3.0, 14.0, 70.0, cove_col), "night")
		else:
			for i in pts.size() - 1:
				var a = pts[i]
				var b = pts[i + 1]
				var ia = a + (Vector2(0, cy) - a).normalized() * 0.55
				var ib = b + (Vector2(0, cy) - b).normalized() * 0.55
				var off = nrm * 0.1
				var bmat = "rib" if z.style == "sears" else "trim_tan"
				quad(g, bmat, [o2 + axw * a.x + Vector3.UP * a.y + off, o2 + axw * b.x + Vector3.UP * b.y + off, o2 + axw * ib.x + Vector3.UP * ib.y + off, o2 + axw * ia.x + Vector3.UP * ia.y + off], nrm)
				if z.style == "sears":
					# the salmon stripe that follows the end arch (north arch over the Sears entrance,
					# IMG_4408 f036; confirms the 2018 "pink stripe")
					var ja = a + (ia - a) * 0.45
					var jb = b + (ib - b) * 0.45
					var ka = a + (ia - a) * 0.7
					var kb = b + (ib - b) * 0.7
					var off2 = nrm * 0.11
					quad(g, "pink_stripe", [o2 + axw * ja.x + Vector3.UP * ja.y + off2, o2 + axw * jb.x + Vector3.UP * jb.y + off2, o2 + axw * kb.x + Vector3.UP * kb.y + off2, o2 + axw * ka.x + Vector3.UP * ka.y + off2], nrm)
	# columns at the inner corners
	var inset = 1.3
	for qx in [r[0] + inset, r[2] - inset]:
		for qz in [r[1] + inset, r[3] - inset]:
			if no_column(qx, qz):
				continue
			cyl(g, "column", Vector3(qx, 0.35, qz), 0.3, 0.3, COURT_SPRING - 0.6, 24, false)
			cyl(g, "stone", Vector3(qx, 0, qz), 0.4, 0.4, 0.35, 24, true)
			cyl(g, "column", Vector3(qx, COURT_SPRING - 0.25, qz), 0.3, 0.42, 0.25, 24, true, true)
			obst([qx, qz, 0.55])
	if z.style == "sears" or z.style == "dillards":
		# Dillard's court (2026 footage, IMG_4438 f001, IMG_4474): white arch beams across the vault
		# with a navy stripe on their faces. (Sears court: Demo 42 drops its two cross beams and the
		# crystal pendant; the footage shows the long lantern instead and the pink stripe on the end arch.)
		var axs = P.call(0, 0, 1) - P.call(0, 0, 0)
		var beams = [-length * 0.25, length * 0.25] if z.style == "dillards" else []
		for sbeam in beams:
			for i in pts.size() - 1:
				var a = pts[i]
				var b = pts[i + 1]
				if abs(a.x) > half - 0.05 and abs(b.x) > half - 0.05:
					continue
				if abs(a.x) < sky_u and abs(b.x) < sky_u and abs(sbeam) < sky_s + 0.4:
					continue
				var ia = a + (Vector2(0, cy) - a).normalized() * 0.45
				var ib = b + (Vector2(0, cy) - b).normalized() * 0.45
				var mid2 = (ia + ib) * 0.5
				var nn2 = (P.call(0, cy, 0) - P.call(mid2.x, mid2.y, 0)).normalized()
				quad(g, "rib", [P.call(ia.x, ia.y, sbeam - 0.35), P.call(ib.x, ib.y, sbeam - 0.35), P.call(ib.x, ib.y, sbeam + 0.35), P.call(ia.x, ia.y, sbeam + 0.35)], nn2)
				for sg in [-1.0, 1.0]:
					quad(g, "rib", [P.call(a.x, a.y, sbeam + sg * 0.35), P.call(b.x, b.y, sbeam + sg * 0.35), P.call(ib.x, ib.y, sbeam + sg * 0.35), P.call(ia.x, ia.y, sbeam + sg * 0.35)], axs * sg)
					var ja = ia + (a - ia) * 0.12
					var jb = ib + (b - ib) * 0.12
					var ka = ia + (a - ia) * 0.3
					var kb = ib + (b - ib) * 0.3
					quad(g, "navy_stripe", [P.call(ja.x, ja.y, sbeam + sg * 0.36), P.call(jb.x, jb.y, sbeam + sg * 0.36), P.call(kb.x, kb.y, sbeam + sg * 0.36), P.call(ka.x, ka.y, sbeam + sg * 0.36)], axs * sg)
		add_omni(P.call(0, 5.5, 0), 1.0, 7.0, Color(1.0, 0.95, 0.85))
	if z.style == "shoe":
		fx = true
		palm_bed(g + "_props", Vector3(cx, 0, cz), 2.4, 5.0)
		for b in [[-1.75, -1.2, PI * 0.5], [-1.75, 1.2, PI * 0.5], [1.75, -1.2, -PI * 0.5], [1.75, 1.2, -PI * 0.5]]:
			bench(g + "_props", Vector3(cx + b[0], 0, cz + b[1]), b[2])
		fx = false
		for p in [Vector3(-3.8, 4.3, -4.2), Vector3(3.8, 4.3, -4.2), Vector3(-3.8, 4.3, 4.2), Vector3(3.8, 4.3, 4.2)]:
			var lp = Vector3(cx, 0, cz) + p
			lantern(lp, arch_y(p.x, half, COURT_SPRING, rise))

## Dillard's court (3:34): a higher flat ceiling ringed by a soffit whose
## hidden cove glows warm onto it, with a rectangular skylight well.
func build_court_flat(z):
	var g = z.id
	var r = z.rect
	var cx = (r[0] + r[2]) * 0.5
	var cz = (r[1] + r[3]) * 0.5
	var CH = 7.6
	var SOF = 6.9
	var ring = 1.4
	# soffit ring (underside), its inner face, and the cove strip on top
	var inner = [r[0] + ring, r[1] + ring, r[2] - ring, r[3] - ring]
	var outer_pts = [Vector3(r[0], SOF, r[1]), Vector3(r[2], SOF, r[1]), Vector3(r[2], SOF, r[3]), Vector3(r[0], SOF, r[3])]
	var inner_pts = [Vector3(inner[0], SOF, inner[1]), Vector3(inner[2], SOF, inner[1]), Vector3(inner[2], SOF, inner[3]), Vector3(inner[0], SOF, inner[3])]
	for i in 4:
		var j = (i + 1) % 4
		quad(g, "lane_ceiling", [outer_pts[i], outer_pts[j], inner_pts[j], inner_pts[i]], Vector3.DOWN)
		var lip = Vector3(0, 0.35, 0)
		var inward = (Vector3(cx, SOF, cz) - (inner_pts[i] + inner_pts[j]) * 0.5)
		inward = Vector3(sign(inward.x) if abs(inward.x) > abs(inward.z) else 0, 0, sign(inward.z) if abs(inward.z) >= abs(inward.x) else 0)
		quad(g, "bulkhead", [inner_pts[i], inner_pts[j], inner_pts[j] + lip, inner_pts[i] + lip], inward)
		quad(g, "bulkhead", [inner_pts[i] + lip, inner_pts[j] + lip, inner_pts[j] + lip - inward * 0.08, inner_pts[i] + lip - inward * 0.08], Vector3.UP)
		var cv0 = inner_pts[i] - inward * 0.3 + Vector3(0, 0.02, 0)
		var cv1 = inner_pts[j] - inward * 0.3 + Vector3(0, 0.02, 0)
		quad(g, "cove", [cv0, cv1, cv1 - inward * 0.25, cv0 - inward * 0.25], Vector3.UP)
	# upper ceiling with a rectangular skylight well
	var swx = min(6.0, (r[2] - r[0]) * 0.3)
	var swz = min(4.0, (r[3] - r[1]) * 0.2)
	var hx0 = cx - swx * 0.5
	var hx1 = cx + swx * 0.5
	var hz0 = cz - swz * 0.5
	var hz1 = cz + swz * 0.5
	for rr in [[r[0], r[1], r[2], hz0], [r[0], hz1, r[2], r[3]], [r[0], hz0, hx0, hz1], [hx1, hz0, r[2], hz1]]:
		quad(g, "lane_ceiling", [Vector3(rr[0], CH, rr[1]), Vector3(rr[2], CH, rr[1]), Vector3(rr[2], CH, rr[3]), Vector3(rr[0], CH, rr[3])], Vector3.DOWN)
	var top = CH + 1.2
	for wall in [[Vector3(hx0, CH, hz0), Vector3(hx1, CH, hz0), Vector3(0, 0, 1)], [Vector3(hx1, CH, hz1), Vector3(hx0, CH, hz1), Vector3(0, 0, -1)], [Vector3(hx0, CH, hz1), Vector3(hx0, CH, hz0), Vector3(1, 0, 0)], [Vector3(hx1, CH, hz0), Vector3(hx1, CH, hz1), Vector3(-1, 0, 0)]]:
		quad(g, "lane_ceiling", [wall[0], wall[1], wall[1] + Vector3(0, top - CH, 0), wall[0] + Vector3(0, top - CH, 0)], wall[2])
	for k in 5:
		var u = hx0 + (hx1 - hx0) * k / 4.0
		box("glass_frames", "metal_dark", Vector3(u, top - 0.05, cz), Vector3(0.05, 0.1, swz), Transform3D.IDENTITY, [], true)
	add_omni(Vector3(cx, 6.0, cz), 1.2, 16.0, Color(1.0, 0.88, 0.72))
	# perimeter walls from the lane ceiling up to the soffit, notched for hall vaults
	var sides = {}
	for cw in L.court_walls:
		if cw.zone == z.id:
			sides[cw.side] = cw.halls
	for side in ["n", "s", "w", "e"]:
		var horiz = side in ["n", "s"]
		var o2 = Vector3(cx, 0, r[1] if side == "n" else r[3]) if horiz else Vector3(r[0] if side == "w" else r[2], 0, cz)
		var axw = Vector3(1, 0, 0) if horiz else Vector3(0, 0, 1)
		var nrm = Vector3(0, 0, 1 if side == "n" else -1) if horiz else Vector3(1 if side == "w" else -1, 0, 0)
		var u0 = (r[0] - cx) if horiz else (r[1] - cz)
		var u1 = (r[2] - cx) if horiz else (r[3] - cz)
		var o = PackedVector2Array([Vector2(u0, LANE_H), Vector2(u0, SOF), Vector2(u1, SOF), Vector2(u1, LANE_H)])
		var notches = []
		for hid in sides.get(side, []):
			var hz = zones[hid]
			var hr = hz.rect
			notches.append([((hr[0] + hr[2]) * 0.5 - cx) if horiz else ((hr[1] + hr[3]) * 0.5 - cz), notch_half(hz)])
		notches.sort_custom(func(p, q): return p[0] > q[0])
		for nt in notches:
			if nt[1] <= 0.0:
				continue
			var hrise = hall_rise(nt[1])
			o.append(Vector2(nt[0] + nt[1], LANE_H))
			var ap = arch_pts(nt[1], VAULT_SPRING, hrise, 16)
			ap.reverse()
			for p in ap:
				o.append(Vector2(nt[0] + p.x, p.y))
			o.append(Vector2(nt[0] - nt[1], LANE_H))
		poly(g, "cream", o, o2, axw, Vector3.UP, nrm)
		# wall between soffit and upper ceiling, behind the cove
		quad(g, "cream", [o2 + axw * u0 + Vector3.UP * SOF, o2 + axw * u1 + Vector3.UP * SOF, o2 + axw * u1 + Vector3.UP * CH, o2 + axw * u0 + Vector3.UP * CH], nrm)
		box(g, "trim_tan", o2 + Vector3.UP * (LANE_H + 0.06) + nrm * 0.1, abs_size(axw, u1 - u0, 0.12, 0.2, nrm))
	var inset = 1.3
	for qx in [r[0] + inset, r[2] - inset]:
		for qz in [r[1] + inset, r[3] - inset]:
			if no_column(qx, qz):
				continue
			cyl(g, "column", Vector3(qx, 0.35, qz), 0.3, 0.3, SOF - 0.35, 24, false)
			cyl(g, "stone", Vector3(qx, 0, qz), 0.4, 0.4, 0.35, 24, true)
			obst([qx, qz, 0.55])

## Court columns left out: the one standing in front of the Woolworth restaurant's door
## (Shoe Dept. court, north-west corner; Steven, Oct 8).
const NO_COLUMNS = [Vector2(-8.7, -8.7)]
func no_column(qx, qz):
	for c in NO_COLUMNS:
		if abs(c.x - qx) < 0.2 and abs(c.y - qz) < 0.2:
			return true
	return false

# ------------------------------------------------------------------ lights
## Since Godot 4.7 the lightmapper lights the mall mostly from glowing surfaces
## (downlight discs at emission 8, the vault glow strip, store panels); a bake
## with emission off drops the Sears hall from luma 189 to 94, while spot/omni/
## sun/sky changes move it by 1-2 points. The Sears hall is the narrowest hall
## (10 m) and came out washed out at Ultra (Steven, Oct 5), so its meshes get
## their glow scaled down, in both the day and the night setup.
const HALL_GLOW = {"H1a": 0.7, "H1b": 0.7}

## mat(mname), with its emission (and the per-setup e_day / e_night metadata
## read by scripts/time_of_day.gd) scaled by HALL_GLOW for the halls listed there.
func glow_mat(gname, mname):
	var m = mat(mname)
	if not HALL_GLOW.has(gname) or not m.emission_enabled:
		return m
	var k = HALL_GLOW[gname]
	m = m.duplicate()
	m.emission_energy_multiplier *= k
	for key in ["e_day", "e_night"]:
		if m.has_meta(key):
			m.set_meta(key, m.get_meta(key) * k)
	return m

func disc_down(group, c, rad):
	var s = st(group, "downlight")
	var seg = 12
	for i in seg:
		var a0 = TAU * i / seg
		var a1 = TAU * (i + 1) / seg
		tri(s, c, c + Vector3(cos(a0), 0, sin(a0)) * rad, c + Vector3(cos(a1), 0, sin(a1)) * rad, Vector2(0.5, 0.5), Vector2(0, 0), Vector2(1, 0), Vector3.DOWN)

func add_downlight(c):
	var l = SpotLight3D.new()
	l.position = c + Vector3(0, -0.05, 0)
	l.rotation = Vector3(-PI / 2, 0, 0)
	l.spot_angle = 58.0
	l.spot_attenuation = 0.8
	l.spot_range = 7.0
	l.light_energy = 1.5
	l.light_color = Color(1.0, 0.92, 0.80)
	l.light_bake_mode = Light3D.BAKE_STATIC
	light_root.add_child(l)
	tag(l, "", 1.5, 1.4)

func add_omni(p, energy, rng, col, shadow = false):
	var l = OmniLight3D.new()
	l.position = p
	l.omni_range = rng
	l.light_energy = energy
	l.light_color = col
	l.light_bake_mode = Light3D.BAKE_STATIC
	l.shadow_enabled = shadow
	light_root.add_child(l)
	return l

## Time-of-day tags read by scripts/time_of_day.gd: "only" = "day"/"night"
## (the light exists in that bake only); e_day / e_night = energy per bake.
func tag(l, only = "", e_day = null, e_night = null):
	if only != "":
		l.set_meta("only", only)
	if e_day != null:
		l.set_meta("e_day", e_day)
	if e_night != null:
		l.set_meta("e_night", e_night)
	return l

func add_spot(p, dir, energy, rng, angle, col):
	var l = SpotLight3D.new()
	l.position = p
	l.light_energy = energy
	l.light_color = col
	l.spot_range = rng
	l.spot_angle = angle
	l.spot_attenuation = 0.9
	l.light_bake_mode = Light3D.BAKE_STATIC
	light_root.add_child(l)
	l.transform = Transform3D(Basis.looking_at(dir.normalized(), Vector3.UP if abs(dir.normalized().y) < 0.99 else Vector3.FORWARD), p)
	return l

# ------------------------------------------------------------------ edges
func zone_at(x, z):
	for zid in zones:
		var r = zones[zid].rect
		if x >= r[0] and x <= r[2] and z >= r[1] and z <= r[3]:
			return zid
	return "misc"

# ------------------------------------------------------------------ wings
func wing_of_zone(zid):
	return 2 if zid in WING2_ZONES else 1

## The wing a frontage belongs to: the zone it faces, unless its store is listed in STORE_WING.
func edge_wing(e):
	if e.has("store") and e.store != null and L.stores.has(e.store) and STORE_WING.has(L.stores[e.store].name):
		return STORE_WING[L.stores[e.store].name]
	var eb = edge_basics(e)
	var mid = (eb[0] + eb[1]) * 0.5
	var zid = zone_at(mid.x + eb[2].x * 1.0, mid.z + eb[2].z * 1.0)
	if zid == "misc":
		return 2 if (mid.z > SEAM[1] or mid.x < SEAM[0]) else 1
	return wing_of_zone(zid)

## True when this build makes the thing in wing w for real (else it is the stand-in, or left out).
func in_wing(w):
	return WING == 0 or w == WING

## The wing of a store by name (the wing of its first frontage).
var _store_wing_cache = {}
func store_name_wing(nm):
	if _store_wing_cache.has(nm):
		return _store_wing_cache[nm]
	var w = 0
	if STORE_WING.has(nm):
		w = STORE_WING[nm]
	else:
		for e in L.edges:
			if e.has("store") and e.store != null and L.stores.has(e.store) and L.stores[e.store].name == nm:
				w = edge_wing(e)
				break
	_store_wing_cache[nm] = w
	return w

## The wing of one walkable map tile: its zone, a leftover's side of the seam, or the store built
## over it (BUILT_RECTS), else the side of the seam.
func tile_wing(tx, ty):
	var x = (tx - float(L.origin[0]) + 0.5) * float(L.scale)
	var z = (ty - float(L.origin[1]) + 0.5) * float(L.scale)
	for zid in zones:
		var r = zones[zid].rect
		if x >= r[0] and x <= r[2] and z >= r[1] and z <= r[3]:
			return wing_of_zone(zid)
	for nm in BUILT_RECTS:
		var r = BUILT_RECTS[nm]
		if x >= r[0] and x <= r[2] and z >= r[1] and z <= r[3]:
			var w = store_name_wing(nm)
			if w != 0:
				return w
	return 2 if (z > SEAM[1] or x < SEAM[0]) else 1

## The player's walk grid for this wing: the layout's grid with the other wing's tiles closed.
func wing_walk():
	var out = []
	for ty in L.walk.size():
		var row = L.walk[ty]
		var s = ""
		for tx in row.length():
			if row[tx] == "1" and tile_wing(tx, ty) == WING:
				s += "1"
			else:
				s += "0"
		out.append(s)
	return out

## A storefront of the other wing, as the stand-in: the frontage cut into slots of the capture
## atlas (tools/capture_standin.gd fills them from that wing's baked build), each a picture on the
## frontage plane, unshaded; plus the light a lit shop throws into the hall, for this wing's bake.
func standin_edge(e):
	var eb = edge_basics(e)
	var a = eb[0]; var b2 = eb[1]; var n = eb[2]; var t = eb[3]; var Ln = eb[4]
	if e.kind != "store":
		build_edge(e)
		return
	var sd = L.stores[e.store]
	var maxlen = 30.0   # long anchor frontages go in several slots
	var parts = max(1, int(ceil(Ln / maxlen)))
	for k in parts:
		var s0 = Ln * k / parts
		var s1 = Ln * (k + 1) / parts
		var slot = {"key": edge_key(e.a, e.b) + "#%d" % k, "a": [a.x, a.z], "t": [t.x, t.z], "n": [n.x, n.z], "s0": s0, "s1": s1, "store": sd.name}
		standin_slots.append(slot)
	if not sd.vacant:
		var sl = add_omni(a + t * Ln * 0.5 - n * 1.2 + Vector3(0, OPEN_H - 0.4, 0), 0.45, 6.0, Color(1.0, 0.96, 0.9))
		tag(sl, "", 0.45, 1.2)
		if Ln >= 2.0:
			tag(add_spot(a + t * Ln * 0.5 - n * 0.4 + Vector3(0, OPEN_H - 0.15, 0), n * 0.9 + Vector3.DOWN * 1.0, 1.6, 7.0, 55.0, Color("#FFF1DC")), "night")

## Packs the stand-in slots into the atlas: rows of equal height (the lane height), the largest
## pixels-per-metre that fits. Deterministic from the layout, so the stand-in's UVs never depend on
## the pictures: a new capture only replaces the atlas images.
func pack_standin():
	var pxm = 96.0
	while pxm > 8.0:
		var ok = _try_pack(pxm)
		if ok:
			break
		pxm -= 2.0
	standin_pxm = pxm
	return pxm

func _try_pack(pxm):
	var h = int(ceil(LANE_H * pxm)) + 4
	var x = 0
	var y = 0
	for s in standin_slots:
		var w = int(ceil((s.s1 - s.s0) * pxm)) + 4
		if w > STANDIN_ATLAS.x:
			return false
		if x + w > STANDIN_ATLAS.x:
			x = 0
			y += h
		if y + h > STANDIN_ATLAS.y:
			return false
		s.rect = [x + 2, y + 2, w - 4, h - 4]
		x += w
	return true

func standin_quads():
	var other = 3 - WING
	var mname = "standin_w%d" % other
	for s in standin_slots:
		var a = Vector3(s.a[0], 0, s.a[1])
		var t = Vector3(s.t[0], 0, s.t[1])
		var n = Vector3(s.n[0], 0, s.n[1])
		var r = s.rect
		var u0 = float(r[0]) / STANDIN_ATLAS.x
		var u1 = float(r[0] + r[2]) / STANDIN_ATLAS.x
		var v0 = float(r[1]) / STANDIN_ATLAS.y
		var v1 = float(r[1] + r[3]) / STANDIN_ATLAS.y
		# the capture's left edge is the camera's left, looking at the front from the hall
		if t.dot((-n).cross(Vector3.UP)) < 0.0:
			var tmp = u0; u0 = u1; u1 = tmp
		var p0 = a + t * s.s0 + n * 0.005
		var p1 = a + t * s.s1 + n * 0.005
		quad("standin", mname, [p0, p1, p1 + Vector3(0, LANE_H, 0), p0 + Vector3(0, LANE_H, 0)], n,
			[Vector2(u0, v1), Vector2(u1, v1), Vector2(u1, v0), Vector2(u0, v0)], true)

## The stand-in pictures: captured with a linear tone curve at half exposure (capture_standin.gd),
## shown unshaded at twice the brightness so the game's own tone mapping and glow apply once, as
## they do to the real shops. The day pictures swap in with the day lighting (time_of_day.gd).
func standin_mat(name):
	var other = name.substr(9).to_int()
	var m = StandardMaterial3D.new()
	m.resource_name = name
	var night = "res://tex/standin/%s%d_night.png" % [standin_prefix(), other]
	var day = "res://tex/standin/%s%d_day.png" % [standin_prefix(), other]
	if FileAccess.file_exists(night):
		m.albedo_texture = tex("standin/%s%d_night.png" % [standin_prefix(), other])
	else:
		# not captured yet: a dim grey until tools/capture_standin.gd has run (the game loads the
		# pictures by path at start, time_of_day.gd, so no rebuild is needed after a capture)
		var im = Image.create(4, 4, false, Image.FORMAT_RGB8)
		im.fill(Color(0.12, 0.11, 0.1))
		m.albedo_texture = ImageTexture.create_from_image(im)
	m.set_meta("tex_night", night)
	m.set_meta("tex_day", day)
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(1.353, 1.353, 1.353)   # sRGB 1.353 = linear 2.0
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return m

## An owner-editable sign (scripts/signs.gd draws its text live over a blank copy of the
## art). `faces`: [[p0, p1, p2, p3], [uv0..uv3], normal] per face, p0->p1 along the text,
## p0->p3 up, with an optional 4th element: a dict of per-face overrides copied into the
## face record (tex, band, span, look, lit; see signs.gd); `style` picks the look (font,
## colours) in signs.gd.
func sign_add(id, kind, title, style, faces, extra = {}):
	var F = []
	for f in faces:
		var pts = []
		var uvs = []
		for p in f[0]:
			pts.append([snappedf(p.x, 0.0001), snappedf(p.y, 0.0001), snappedf(p.z, 0.0001)])
		for q in f[1]:
			uvs.append([snappedf(q.x, 0.00001), snappedf(q.y, 0.00001)])
		var rec_f = {"p": pts, "uv": uvs, "n": [snappedf(f[2].x, 0.0001), snappedf(f[2].y, 0.0001), snappedf(f[2].z, 0.0001)]}
		# optional per-face overrides: "tex" (word-free art for this face), "band" [top, bottom]
		# and "span" [left, right] (where the words go, as fractions of the face), "look", "lit"
		if f.size() > 3 and f[3] is Dictionary:
			rec_f.merge(f[3])
		F.append(rec_f)
	var rec = {"id": id, "kind": kind, "title": title, "style": style, "faces": F}
	rec.merge(extra)
	signs.append(rec)

func label(text, fontname, fg, pos, n, max_w, cap_h = 0.56):
	var lab = Label3D.new()
	lab.text = text
	var fnt = load("res://fonts/" + {"sans": "sans.otf", "serif": "serif.ttf", "script": "script.ttf", "sans_italic": "sans_italic.otf"}[fontname])
	lab.font = fnt
	lab.font_size = 128
	lab.modulate = Color(fg)
	var est = text.length() * 128 * (0.6 if fontname == "serif" else 0.5)
	var txt_w = max(fnt.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 128).x, est)
	var px = cap_h / 128.0
	if txt_w * px > max_w:
		px = max_w / txt_w
	lab.pixel_size = px
	lab.shaded = false
	lab.double_sided = false
	lab.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	lab.position = pos
	lab.basis = Basis.looking_at(-n, Vector3.UP)
	mall.add_child(lab)
	return lab

func edge_basics(e):
	var a = Vector3(e.a[0], 0, e.a[1])
	var b = Vector3(e.b[0], 0, e.b[1])
	var n = Vector3(e.n[0], 0, e.n[1])
	return [a, b, n, (b - a).normalized(), a.distance_to(b)]

func plain_wall(g, a, b, n, top = LANE_H, wm = "cream"):
	var t = (b - a).normalized()
	quad(g, wm, [a, b, b + Vector3(0, top, 0), a + Vector3(0, top, 0)], n)
	box(g, "stone", (a + b) * 0.5 + Vector3(0, 0.3, 0) + n * 0.03, abs_size(t, a.distance_to(b), 0.6, 0.06, n))

## The terracotta 8-point star on the pilaster between two stores (2026 footage: every demising
## pier in the halls and courts, ~25 cm, two overlapping squares; IMG_4484 f016, IMG_4433). Placed
## where two storefront edges of this wing meet in line, on the bulkhead band above the openings.
const STAR_Y = 3.85
func star_medallions():
	var ends = {}
	for e in L.edges:
		if e.kind != "store" or not in_wing(edge_wing(e)):
			continue
		var sd = L.stores[e.store]
		if sd.anchor:
			continue
		for p in [e.a, e.b]:
			var key = "%d,%d|%d,%d" % [round(p[0] * 10), round(p[1] * 10), e.n[0], e.n[1]]
			ends[key] = ends.get(key, 0) + 1
	var cnt = 0
	for key in ends:
		if ends[key] < 2:
			continue
		var parts = key.split("|")
		var pp = parts[0].split(","); var nn = parts[1].split(",")
		var p = Vector3(float(pp[0]) / 10.0, 0, float(pp[1]) / 10.0)
		var n = Vector3(float(nn[0]), 0, float(nn[1]))
		var g = zone_at(p.x + n.x * 1.5, p.z + n.z * 1.5)
		if g == "" or g == null:
			g = "misc"
		var c = p + n * 0.27 + Vector3(0, STAR_Y, 0)
		var bas = Basis.looking_at(-n, Vector3.UP)
		box(g, "bulkhead", Vector3.ZERO, Vector3(0.36, 0.36, 0.04), Transform3D(bas, c - n * 0.03))
		for rot in [0.0, PI * 0.25]:
			box(g, "terracotta", Vector3.ZERO, Vector3(0.2, 0.2, 0.03), Transform3D(bas * Basis(Vector3(0, 0, 1), rot), c))
		cnt += 1
	print("star medallions: ", cnt)

## The elevator on the south side of the concourse (H5) between Special Tees and Naturalizer
## (Steven, Oct 23 2026: "the elevator was always right there"; IMG_4439 f028): a recessed alcove
## ELEV_W wide taken half from each store's frontage.
const ELEV_X = -44.0
const ELEV_W = 2.4
const ELEV_STORES = {"SPECIAL TEES": "b", "NATURALIZER": "a", "BOOST MOBILE": "b", "CELL XPERT": "a"}
func elevator(g, z0):
	var x0 = ELEV_X - ELEV_W * 0.5
	var x1 = ELEV_X + ELEV_W * 0.5
	var dep = 1.5
	var n = Vector3(0, 0, -1)
	# side walls, back wall, the soffit and the beige doors
	for x in [x0, x1]:
		var nn = Vector3(1, 0, 0) if x == x0 else Vector3(-1, 0, 0)
		quad(g, "cream", [Vector3(x, 0, z0), Vector3(x, 0, z0 + dep), Vector3(x, LANE_H, z0 + dep), Vector3(x, LANE_H, z0)], nn)
		box(g, "stone", Vector3(x, 0.3, z0 + dep * 0.5) + nn * 0.03, Vector3(0.06, 0.6, dep))
	quad(g, "cream", [Vector3(x0, 0, z0 + dep), Vector3(x1, 0, z0 + dep), Vector3(x1, LANE_H, z0 + dep), Vector3(x0, LANE_H, z0 + dep)], n)
	quad(g, "lane_ceiling", [Vector3(x0, 3.0, z0), Vector3(x1, 3.0, z0), Vector3(x1, 3.0, z0 + dep), Vector3(x0, 3.0, z0 + dep)], Vector3.DOWN)
	quad(g, "cream", [Vector3(x0, 3.0, z0), Vector3(x1, 3.0, z0), Vector3(x1, LANE_H, z0), Vector3(x0, LANE_H, z0)], n)
	quad("misc", "floorz_left", [Vector3(x0, 0.002, z0), Vector3(x1, 0.002, z0), Vector3(x1, 0.002, z0 + dep), Vector3(x0, 0.002, z0 + dep)], Vector3.UP)
	box(g, "elev_door", Vector3(ELEV_X, 1.06, z0 + dep - 0.03), Vector3(1.2, 2.12, 0.04))
	box(g, "bronze", Vector3(ELEV_X, 1.06, z0 + dep - 0.06), Vector3(0.012, 2.12, 0.02))
	box(g, "elev_door", Vector3(ELEV_X, 2.17, z0 + dep - 0.04), Vector3(1.36, 0.1, 0.06))
	for sx in [-1.0, 1.0]:
		box(g, "elev_door", Vector3(ELEV_X + sx * 0.66, 1.08, z0 + dep - 0.04), Vector3(0.08, 2.16, 0.06))
	# call buttons and the floor indicator
	box(g, "brass", Vector3(ELEV_X + 0.9, 1.1, z0 + dep - 0.02), Vector3(0.12, 0.22, 0.02))
	box(g, "black", Vector3(ELEV_X, 2.42, z0 + dep - 0.02), Vector3(0.5, 0.14, 0.02))
	add_downlight(Vector3(ELEV_X, 2.98, z0 + dep * 0.5))
	disc_down(g, Vector3(ELEV_X, 2.99, z0 + dep * 0.5), 0.14)
	obst([ELEV_X, z0 + 0.8, 1.0])

func build_edge(e):
	var eb = edge_basics(e)
	var a = eb[0]
	var b = eb[1]
	var n = eb[2]
	var t = eb[3]
	var Ln = eb[4]
	if e.kind == "store" and ELEV_STORES.has(L.stores[e.store].name) and abs(a.z - 60.0) < 0.01:
		var side = ELEV_STORES[L.stores[e.store].name]
		var gz = zone_at((a.x + b.x) * 0.5, a.z - 1.0)
		if side == "b":
			b = Vector3(ELEV_X - ELEV_W * 0.5, 0, b.z)
			elevator(gz, a.z)
		else:
			a = Vector3(ELEV_X + ELEV_W * 0.5, 0, a.z)
		Ln = a.distance_to(b)
		e = e.duplicate()
		e.a = [a.x, a.z]; e.b = [b.x, b.z]
	var mid = (a + b) * 0.5
	var g = zone_at(mid.x + n.x * 1.0, mid.z + n.z * 1.0)
	match e.kind:
		"wall":
			plain_wall(g, a, b, n)
		"store":
			var sd0 = L.stores[e.store]
			if sd0.anchor and Ln > ANCHOR_FRONT + 1.0:
				# An anchor's mall entrance is one storefront about as wide as
				# JCPenney's (Steven, Oct 5), centred where the mall approaches
				# it; the rest of its frontage is solid wall.
				var c = Ln * 0.5
				var zid = zone_at(mid.x + n.x * 2.0, mid.z + n.z * 2.0)
				for zz in L.zones:
					if zz.type == "court":
						var r = zz.rect
						var cc = Vector3((r[0] + r[2]) * 0.5, 0, (r[1] + r[3]) * 0.5)
						var along = (cc - a).dot(t)
						var dist = abs((cc - a).dot(n))
						if along > 0 and along < Ln and dist < 20.0:
							c = along
				var s0 = clamp(c - ANCHOR_FRONT * 0.5, 0.0, Ln - ANCHOR_FRONT)
				var s1 = s0 + ANCHOR_FRONT
				var wm = ANCHOR_LOOK.get(sd0.name, {}).get("wall", "cream")
				if s0 > 0.01:
					plain_wall(g, a, a + t * s0, n, LANE_H, wm)
				storefront(g, e, a + t * s0, a + t * s1, n, t, ANCHOR_FRONT)
				if s1 < Ln - 0.01:
					plain_wall(g, a + t * s1, b, n, LANE_H, wm)
			else:
				storefront(g, e, a, b, n, t, Ln)
		"exit", "entrance":
			doors_out(g, e, a, b, n, t, Ln)
		"restroom":
			plain_wall(g, a, b, n)
			var sd = L.stores[e.store]
			var dp = a + t * min(1.6, Ln * 0.3)
			box(g, "door_wood", dp + Vector3(0, 1.05, 0) + n * 0.03, abs_size(t, 0.95, 2.1, 0.06, n))
			box(g, "bronze", dp + Vector3(0, 2.15, 0) + n * 0.03, abs_size(t, 1.1, 0.1, 0.08, n))
			label(sd.name.capitalize(), "sans", "#ffffff", dp + Vector3(0, 2.55, 0) + n * 0.06, n, 1.2, 0.22)
			cur_color = Color("#2b4a8a")
			box(g, "vcolor", dp + Vector3(0, 2.55, 0) + n * 0.03, abs_size(t, 1.3, 0.34, 0.04, n))
			cur_color = Color.WHITE
			if YEAR == 2026 and sd.name == "MEN":
				# Demo 43: the deco fan and RESTROOMS lettering over the restroom hall (IMG_4439 f030)
				var S26 = load("res://tools/stores/signs/sign_2026.gd")
				if S26.for_store("MEN") != null:
					S26.build(self, g + "_sg26", "MEN", a + t * (Ln * 0.5) + Vector3(0, 2.8, 0) + n * 0.03, n, min(Ln - 0.4, 2.6), 1.0)

## A storefront along one frontage: pilasters with a stone base, bulkhead with
## the sign, bronze-framed glass (or an open front), the lit interior behind.
func storefront(g, e, a, b, n, t, Ln, inner_call = false):
	var sd = L.stores[e.store]
	if YEAR == 2026 and not inner_call:
		# 2026: the anchors' current fronts, Corn Dog 7 (the same shop, unchanged), and the generic
		# front with each tenant's sign for everyone else, until they are built from the footage
		if sd.anchor and ANCHOR_LOOK_2026.has(sd.name):
			anchor_front(g, e, a, b, n, t, Ln, sd, ANCHOR_LOOK_2026[sd.name])
			return
		if sd.name == "GAMES, INC. (POCKET CHANGE)":
			# Demo 46 (Oct 28): the arcade in the old Blockbuster Music box, built from the Oct 23
			# footage with Pocket Change's machine modules (tools/stores/games_inc/store.gd)
			load("res://tools/stores/games_inc/store.gd").build(self, g, e, a, b, n, t, Ln, sd)
			return
		if sd.name == "WICKED WINGZ":
			# ws/g (Oct 28 sprint): the old Chick-fil-A unit, built from IMG_4441/IMG_4461
			# (tools/stores/wingz/store.gd, design/storefronts/wicked-wingz-2026.md)
			load("res://tools/stores/wingz/store.gd").build(self, g, e, a, b, n, t, Ln, sd)
			return
		if load("res://tools/stores/fronts26/store.gd").has(sd.name):
			# ws/g (Oct 28 sprint, step 4): the front and the first metres inside as filmed
			# (tools/stores/fronts26/store.gd, design/storefronts/fronts-2026.md)
			load("res://tools/stores/fronts26/store.gd").build(self, g, e, a, b, n, t, Ln, sd)
			return
		if sd.name == "CINNAMONSTER":
			# ws/g (Oct 28 sprint): KarmelKorn's corner stall from IMG_4464-4468, both faces built from
			# the north edge's call (tools/stores/cinnamonster/store.gd, design/storefronts/cinnamonster-2026.md)
			if n.z < -0.5:
				load("res://tools/stores/cinnamonster/store.gd").build(self, g, e, a, b, n, t, Ln, sd)
			return
		if sd.name != "CORN DOG 7":
			storefront(g, e, a, b, n, t, Ln, true)
			return
	if sd.name == "K&B" and not inner_call:
		# Steven (Oct 7): the front of the K&B at Prien Lake Mall (same owners), with the logo
		# from his photos (tools/stores/signs/fronts.gd); replaces decision 6's pink wall
		load("res://tools/stores/signs/fronts.gd").build(self, g, e, a, b, n, t, Ln, sd)
		return
	if sd.name == "K&B" and not inner_call and Ln > 12.0:
		# K&B's frontage was a pink wall with plum stripes (decision 6), with
		# the store entrance in the middle
		var ew = 8.0
		var m0 = Ln * 0.5 - ew * 0.5
		kb_wall(g, a, a + t * m0, n, t)
		kb_wall(g, a + t * (m0 + ew), b, n, t)
		storefront(g, e, a + t * m0, a + t * (m0 + ew), n, t, ew, true)
		return
	if sd.anchor and ANCHOR_LOOK.has(sd.name) and YEAR != 2026:
		anchor_front(g, e, a, b, n, t, Ln, sd, ANCHOR_LOOK[sd.name])
		return
	if sd.name == "POCKET CHANGE" and not inner_call:
		# built in full 3D from Steven's 2009 photo of the unchanged front, with a walkable arcade (Phase 4b)
		load("res://tools/stores/pocket_change/store.gd").build(self, g, e, a, b, n, t, Ln, sd)
		return
	if sd.name == "KAY-BEE TOYS" and not inner_call:
		# built in full 3D: the front from Steven's photo of the Southland store, the inside from
		# the 1993 Kay-Bee home video he chose (design/storefronts/kay-bee-toys.md)
		load("res://tools/stores/kay_bee/store.gd").build(self, g, e, a, b, n, t, Ln, sd)
		return
	if sd.name in ["JW", "5-7-9", "COUNTY SEAT"] and not inner_call:
		# built in full 3D after the 1995 North East Mall video Steven chose: the signs and the
		# stock from the video, the layouts guessed (design/storefronts/jw.md, 579.md, county-seat.md)
		var mod = {"JW": "jw", "5-7-9": "s579", "COUNTY SEAT": "county_seat"}[sd.name]
		load("res://tools/stores/apparel/%s.gd" % mod).build(self, g, e, a, b, n, t, Ln, sd)
		return
	if sd.name in ["SOLARIUM", "RAVE", "CONCEPTS", "COUNTRY FAIR", "LION'S SHARE RESTAURANT", "AMERICAN BANK"] and not inner_call:
		# built in full 3D from the Southland facade records and the game's flat fronts; insides
		# guessed (design/storefronts/: solarium, rave, concepts, country-fair, lions-share,
		# american-bank)
		load("res://tools/stores/small/wave9.gd").build(self, g, e, a, b, n, t, Ln, sd)
		return
	if sd.name in ["CUCOS BORDER CAFE", "CLAIRE'S BOUTIQUES", "MITCHELL'S FORMAL WEAR", "TEE TAI'S", "OPTICAL OUTLET",
			"SAADI'S", "GOLDEN CHAIN GANG"] and not inner_call:
		# built in full 3D from the Southland facade records and the game's flat fronts; insides
		# guessed (design/storefronts/: cucos, claires, mitchells, tee-tais, optical-outlet,
		# saadis, golden-chain-gang)
		load("res://tools/stores/small/wave8.gd").build(self, g, e, a, b, n, t, Ln, sd)
		return
	if sd.name in ["MERRY-GO-ROUND", "JEAN NICOLE", "CHAMPS SPORTS", "SPORTS AVENUE", "GREAT AMERICAN COOKIE CO",
			"REGIS HAIRSTYLISTS", "AFTERTHOUGHTS", "ORANGE JULIUS", "GORDON'S JEWELERS"] and not inner_call:
		# built in full 3D from the Southland facade records (Steven's photos); insides guessed
		# (design/storefronts/: merry-go-round, jean-nicole, champs-sports, sports-avenue,
		# great-american-cookie, regis, afterthoughts, orange-julius, gordons)
		load("res://tools/stores/small/wave7.gd").build(self, g, e, a, b, n, t, Ln, sd)
		return
	if sd.name in ["RADIO SHACK", "B. DALTON BOOKSELLER", "KARMELKORN", "ZALES"] and not inner_call:
		# built in full 3D from the facade records and the Hammond 1993 commercial, insides
		# guessed (design/storefronts/radio-shack.md, b-dalton.md, karmelkorn.md, zales.md)
		load("res://tools/stores/small/store2.gd").build(self, g, e, a, b, n, t, Ln, sd)
		return
	if sd.name == "DUNCAN SPORTS" and not inner_call:
		# the generic front with the script from the store's Courier ad, in blue over the
		# bulkhead (Steven, Oct 8: tools/stores/signs/make_duncan.py)
		storefront(g, e, a, b, n, t, Ln, true)
		var cdu = a + t * (Ln * 0.5) + n * 0.16 + Vector3(0, OPEN_H + 0.53, 0)
		load("res://tools/stores/signs/channel.gd").build(self, "duf_sign", "res://tools/stores/signs/du_name_logo.json", cdu, n,
			"sg_du_face", "sg_du_return", "", 0.02, 0.05, 0.0, "sg_du_glow")
		return
	if sd.name == "FRANKS" and not inner_call:
		# the generic front with the logo as bare red neon on the storefront
		# (Steven, Oct 8: tools/stores/franks/franks.gd)
		load("res://tools/stores/franks/franks.gd").build(self, g, e, a, b, n, t, Ln, sd)
		return
	if sd.name == "CHICK-FIL-A" and not inner_call:
		# rebuilt Oct 8, 2026 from Steven's video of the Southland unit
		# (design/storefronts/chick-fil-a.md)
		load("res://tools/stores/cfa/store.gd").build(self, g, e, a, b, n, t, Ln, sd)
		return
	if sd.name in ["COACH HOUSE GIFTS", "GENERAL NUTRITION CENTER", "MASTERCUTS", "WICKS 'N' STICKS"] and not inner_call:
		# built in full 3D from the facade records and the Hammond 1993 commercial, insides
		# guessed (design/storefronts/coach-house.md, gnc.md, mastercuts.md, wicks-n-sticks.md,
		# chick-fil-a.md)
		load("res://tools/stores/small/store.gd").build(self, g, e, a, b, n, t, Ln, sd)
		return
	if sd.name in ["LERNER SHOP", "LANE BRYANT", "MILLER'S OUTPOST", "GADZOOKS", "THE LIMITED"] and not inner_call:
		# built in full 3D on the apparel kit from the regional videos Steven sent (Hammond
		# 1993, Pecanland 1992, the Gadzooks slideshow); layouts guessed (design/storefronts/
		# lerner.md, lane-bryant.md, millers-outpost.md, gadzooks.md, limited.md)
		load("res://tools/stores/apparel/more.gd").build(self, g, e, a, b, n, t, Ln, sd)
		return
	if sd.name == "WOOLWORTH" and not inner_call:
		# built in full 3D: the front from the facade record, the inside from the 1991
		# Statesville video Steven chose, the restaurant on the right with its own mall door
		# (design/storefronts/woolworth.md)
		load("res://tools/stores/woolworth/store.gd").build(self, g, e, a, b, n, t, Ln, sd)
		return
	if sd.name in ["BABBAGE'S", "SOUND SHOP"] and not inner_call:
		# built in full 3D with the media kit: Babbage's from the 1997 Killeen Mall video, Sound
		# Shop from the 1993 Hammond Square commercial, both laid out to Steven's memory
		# (design/storefronts/babbages.md, sound-shop.md); Babbage's jog edge comes here too
		var mod = {"BABBAGE'S": "babbages", "SOUND SHOP": "sound_shop"}[sd.name]
		load("res://tools/stores/media/%s.gd" % mod).build(self, g, e, a, b, n, t, Ln, sd)
		return
	if sd.name == "GUMBALLS" and not inner_call:
		# built in full 3D on the court corner: the sign and the inside from the 1995 North East
		# Mall video Steven chose (design/storefronts/gumballs.md); both frontage edges come here
		load("res://tools/stores/gumballs/store.gd").build(self, g, e, a, b, n, t, Ln, sd)
		return
	if sd.name == "CORN DOG 7" and not inner_call:
		# built in full 3D from the photographs of the unchanged shop (Phase 4b)
		preload("res://tools/stores/corn_dog_7.gd").build(self, g, e, a, b, n, t, Ln, sd)
		return
	if sd.name in ["FOOT LOCKER", "ATHLETE'S FOOT", "BLOCKBUSTER MUSIC", "THE SHOE DEPT", "PAYLESS SHOES", "LADY FOOT LOCKER", "FOOTACTION USA"] and not inner_call:
		# the facade and sign in 3D from Steven's photos (sign pass, Oct 7); the generic
		# interior behind until the store is built (tools/stores/signs/fronts.gd)
		load("res://tools/stores/signs/fronts.gd").build(self, g, e, a, b, n, t, Ln, sd)
		return
	if sd.name == "SOUTHLAND CINEMA" and not inner_call:
		# the front from Steven's photos (Oct 7): white brick, bronze arches, the box office, lanterns,
		# poster cases; a dim lobby behind for now (tools/stores/cinema/front.gd)
		load("res://tools/stores/cinema/front.gd").build(self, g, e, a, b, n, t, Ln, sd)
		return
	if sd.name == "COMING SOON":
		coming_soon(g, a, b, n, t, Ln)
		return
	if sd.name == "GOLD 'N' GIFTS UNLIMITED" and not inner_call:
		# on the corner's diagonal by Babbage's (Steven, Oct 8: tools/layout_oct8.py)
		load("res://tools/stores/gold_gifts/store.gd").build(self, g, e, a, b, n, t, Ln, sd)
		return
	var fa = fronts.get(edge_key(e.a, e.b))
	if fa != null and not inner_call:
		front_art(g, e, a, b, n, t, Ln, sd, fa)
		return
	var pil = 0.4 if Ln > 2.5 else 0.25
	var anchor = sd.anchor
	var deep = clip_deep(a, b, n, clamp(float(e.depth), 3.0, 14.0 if anchor else 9.0))
	for ee in [0.0, Ln - pil]:
		var c0 = a + t * (ee + pil * 0.5)
		box(g, "stone", c0 + Vector3(0, 0.45, 0) + n * 0.06, abs_size(t, pil, 0.9, 0.12, n))
		box(g, "cream", c0 + Vector3(0, (OPEN_H + 0.9) * 0.5, 0) + n * 0.03, abs_size(t, pil, OPEN_H - 0.9, 0.06, n))
	var mid = a + t * Ln * 0.5
	var s26 = load("res://tools/stores/signs/sign_2026.gd").for_store(sd.name) if YEAR == 2026 else null
	if s26 != null and s26.has("fascia_color"):
		# Demo 43: the bulkhead itself painted as filmed (one box, so the bake is as before)
		cur_color = Color(s26.fascia_color)
		box(g, "vcolor_matte", mid + Vector3(0, (OPEN_H + LANE_H) * 0.5, 0) + n * 0.08, abs_size(t, Ln, LANE_H - OPEN_H, 0.16, n))
		cur_color = Color.WHITE
	else:
		box(g, "bulkhead", mid + Vector3(0, (OPEN_H + LANE_H) * 0.5, 0) + n * 0.08, abs_size(t, Ln, LANE_H - OPEN_H, 0.16, n))
	# sign
	var text = sd.sign
	if sd.vacant:
		text = "For Lease" + ((" · Space %d" % int(sd.unit)) if sd.unit != null else "")
	if PLACEHOLDER_SIGNS.has(sd.name):
		# Steven (Oct 7): the 8-bit game's hand-drawn sign as a placeholder (tools/stores/signs, sg_ph_*)
		var ph = PLACEHOLDER_SIGNS[sd.name]
		var sh2 = 1.3
		var sw2 = sh2 * ph[1]
		var sc2 = mid + Vector3(0, OPEN_H + (LANE_H - OPEN_H) * 0.5, 0) + n * 0.2
		box(g, "black", sc2, abs_size(t, sw2 + 0.06, sh2 + 0.06, 0.08, n))
		var rv2 = (-n).cross(Vector3.UP)
		var c2 = sc2 + n * 0.041
		quad(g, ph[0], [c2 - rv2 * (sw2 * 0.5) - Vector3.UP * (sh2 * 0.5), c2 + rv2 * (sw2 * 0.5) - Vector3.UP * (sh2 * 0.5), c2 + rv2 * (sw2 * 0.5) + Vector3.UP * (sh2 * 0.5), c2 - rv2 * (sw2 * 0.5) + Vector3.UP * (sh2 * 0.5)], n,
			[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])
		text = ""
	if YEAR == 2026 and not sd.noSign and Ln >= 1.5:
		# Demo 43: the store's own sign as filmed on Oct 23 2026, in 3D (tools/stores/signs/sign_2026.gd,
		# y26/parts/<id>.json). Vacant units have no fascia sign in the footage, only the leasing card
		# in the window (for_lease_card); a tenant with no sign in the spec keeps the old panel.
		if sd.vacant:
			text = ""
		elif sign_2026(g, sd.name, mid, n, t, Ln):
			text = ""
	if text != "" and not sd.noSign and Ln >= 1.5:
		var sw = min(Ln - 0.8, max(1.6, min(Ln * 0.72, 9.0 if anchor else 6.5)))
		var sh = 0.95 if anchor else 0.78
		var sc = mid + Vector3(0, OPEN_H + (LANE_H - OPEN_H) * 0.5, 0) + n * 0.2
		cur_color = Color("#3a3a3a") if sd.vacant else Color(sd.bg)
		box(g, "vcolor", sc, abs_size(t, sw, sh, 0.08, n))
		cur_color = Color.WHITE
		label(text, "sans" if sd.vacant else sd.font, "#f2efe6" if sd.vacant else sd.fg, sc + n * 0.05, n, sw * 0.88, 0.62 if anchor else 0.56)
	var inner0 = pil
	var inner1 = Ln - pil
	var p0 = a + t * inner0
	var p1 = a + t * inner1
	var width = inner1 - inner0
	if sd.vacant:
		# closed grille in front of a dark space
		quad(g, "grille", [p0, p1, p1 + Vector3(0, OPEN_H, 0), p0 + Vector3(0, OPEN_H, 0)], n, [], false, 1.0)
		var k = 0.0
		while k < OPEN_H:
			box(g, "metal_dark", (p0 + p1) * 0.5 + Vector3(0, k, 0) + n * 0.02, abs_size(t, width, 0.03, 0.03, n))
			k += 0.18
		if YEAR == 2026 and Ln >= 3.0:
			for_lease_card(g, a, n, t, Ln)
		return
	var ov = OVERRIDES.get(sd.name, {})
	if sd.awning and (sd.awningColor != null or ov.has("awningColor")):
		cur_color = Color(ov.get("awningColor", sd.awningColor))
		var aw0 = a + t * Ln * 0.5 + Vector3(0, OPEN_H + 0.05, 0)
		var xf = Transform3D(Basis.looking_at(-n, Vector3.UP) * Basis(Vector3.RIGHT, 0.45), aw0 + n * 0.45)
		box(g, "vcolor_matte", Vector3.ZERO, Vector3(Ln - 0.2, 0.06, 1.0), xf)
		box(g, "vcolor_matte", aw0 + n * 0.9 + Vector3(0, -0.32, 0), abs_size(t, Ln - 0.2, 0.25, 0.04, n))
		if ov.has("awningStripe"):
			cur_color = Color(ov.awningStripe)
			box(g, "vcolor_matte", aw0 + n * 0.925 + Vector3(0, -0.26, 0), abs_size(t, Ln - 0.2, 0.06, 0.02, n))
		cur_color = Color.WHITE
	var door_w = width if sd.open else min(3.0 if not anchor else 8.0, width * 0.45)
	if sd.entry != null:
		door_w = min(width, float(sd.entry) * 2.0)
	var d0 = Ln * 0.5 - door_w * 0.5
	var d1 = Ln * 0.5 + door_w * 0.5
	if not sd.open:
		for seg in [[inner0, d0], [d1, inner1]]:
			var s0 = seg[0]
			var s1 = seg[1]
			if s1 - s0 < 0.1:
				continue
			var cc = a + t * (s0 + s1) * 0.5
			box(g, "stone", cc + Vector3(0, 0.2, 0), abs_size(t, s1 - s0, 0.4, 0.2, n))
			quad("glass", "glass", [a + t * s0 + Vector3(0, 0.4, 0), a + t * s1 + Vector3(0, 0.4, 0), a + t * s1 + Vector3(0, OPEN_H, 0), a + t * s0 + Vector3(0, OPEN_H, 0)], n, [Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)], true)
			var cnt = max(1, int(round((s1 - s0) / 1.5)))
			for k in cnt + 1:
				var mp = a + t * (s0 + (s1 - s0) * k / cnt)
				box(g, "bronze", mp + Vector3(0, (OPEN_H + 0.4) * 0.5, 0), abs_size(t, 0.06, OPEN_H - 0.4, 0.1, n))
	box(g, "bronze", mid + Vector3(0, OPEN_H - 0.04, 0), abs_size(t, width, 0.08, 0.12, n))
	interior(g, e, a, n, t, Ln, sd, p0, p1, width, deep)
	if sd.name.contains("CINEMA"):
		cinema_front(g, a, n, t, Ln)

## Demo 43: the 2026 sign of store `name` on the generic front's bulkhead (front face at n * 0.16),
## centred on the band between the opening and the ceiling. False when the spec has no sign for it.
func sign_2026(g, name, mid, n, t, Ln):
	var S = load("res://tools/stores/signs/sign_2026.gd")
	var s = S.for_store(name)
	if s == null:
		return false
	var band = LANE_H - OPEN_H
	# (the spec's "fascia_color" paints the bulkhead itself: storefront())
	if s.get("mount", "fascia") == "glass":
		# lettering on the storefront glass (Wax Utopia, SOLA): just proud of the glass, about
		# head height, within the glazing
		var cg = mid + Vector3(0, 1.9 + float(s.get("glass_y", 0.0)), 0) + n * 0.012
		return S.build(self, g + "_sg26", name, cg, n, max(1.0, Ln - 1.4), OPEN_H - 1.0, s)
	var c = mid + Vector3(0, OPEN_H + band * 0.5 + float(s.get("mount_y", 0.0)), 0) + n * 0.17
	# ws/g: "drop" lets a sign hang below the band (Journeys' oval over the opening head)
	return S.build(self, g + "_sg26", name, c, n, max(1.0, Ln - 0.9), band - 0.12 + float(s.get("drop", 0.0)), s)

## Demo 43: the leasing card in a 2026 vacant unit's window (IMG_4440 f013: white, the green
## FOR LEASE, the agent's blue lines; the agent's name and number are left off), behind the grille.
func for_lease_card(g, a, n, t, Ln):
	var c = a + t * (Ln * 0.5 + min(1.2, Ln * 0.25)) + Vector3(0, 1.45, 0) - n * 0.08
	var rv = (-n).cross(Vector3.UP)
	var w = 0.56
	var h = 1.0
	quad(g + "_lease", "sg_y26_lease_card", [c - rv * (w * 0.5) - Vector3.UP * (h * 0.5), c + rv * (w * 0.5) - Vector3.UP * (h * 0.5), c + rv * (w * 0.5) + Vector3.UP * (h * 0.5), c - rv * (w * 0.5) + Vector3.UP * (h * 0.5)], n,
		[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)], true)

## How deep a store's generic interior may run before it would enter a store built in full 3D.
func clip_deep(a, b, n, deep):
	var into = -n
	for nm in BUILT_RECTS:
		if YEAR == 2026 and nm != "CORN DOG 7":
			continue
		var r = BUILT_RECTS[nm]
		# the strip from the frontage a..b running `deep` metres along `into`
		var lo_x = min(a.x, b.x); var hi_x = max(a.x, b.x)
		var lo_z = min(a.z, b.z); var hi_z = max(a.z, b.z)
		if abs(into.z) > 0.5:
			if hi_x <= r[0] + 0.01 or lo_x >= r[2] - 0.01:
				continue
			var gap = (r[1] - a.z) if into.z > 0 else (a.z - r[3])
			if gap >= -0.01:
				deep = min(deep, max(gap - 0.05, 0.5))
		else:
			if hi_z <= r[1] + 0.01 or lo_z >= r[3] - 0.01:
				continue
			var gap2 = (r[0] - a.x) if into.x > 0 else (a.x - r[2])
			if gap2 >= -0.01:
				deep = min(deep, max(gap2 - 0.05, 0.5))
	return deep

func edge_key(pa, pb):
	return "%.1f,%.1f|%.1f,%.1f" % [pa[0], pa[1], pb[0], pb[1]]

## The store behind a frontage: back wall and side walls from the interior
## atlas, floor, ceiling with lit panels, merchandise blocks, and its lights.
func interior(g, e, a, n, t, Ln, sd, p0, p1, width, deep):
	if YEAR != 2026 and load("res://tools/stores/fronts26/store.gd").has_inside_1995(sd.name):
		# ws/g (Oct 28 sprint, step 7): Foot Locker (= its 2026 inside), Payless, Blockbuster Music
		load("res://tools/stores/fronts26/store.gd").inside_1995(self, g, a, n, t, Ln, sd)
		return
	var back = -n * deep
	var cell = atlas_index.get(e.store, 0)
	var cu = float(cell % ATLAS_COLS) / ATLAS_COLS
	var cv = float(cell / ATLAS_COLS) / ATLAS_ROWS
	var du = 1.0 / ATLAS_COLS
	var dv = 1.0 / ATLAS_ROWS
	var reps = max(1, int(round(width / 6.0)))
	for k in reps:
		var q0 = p0 + t * (width * k / reps)
		var q1 = p0 + t * (width * (k + 1) / reps)
		quad(g, "int_back", [q0 + back, q1 + back, q1 + back + Vector3(0, OPEN_H, 0), q0 + back + Vector3(0, OPEN_H, 0)], n,
			[Vector2(cu, cv + dv), Vector2(cu + du, cv + dv), Vector2(cu + du, cv), Vector2(cu, cv)])
	# side walls carry the same store picture, so the glass shows the right kind of store at an angle
	var su = du * clamp(deep / 6.0, 0.3, 1.0)
	quad(g, "int_back", [p0, p0 + back, p0 + back + Vector3(0, OPEN_H, 0), p0 + Vector3(0, OPEN_H, 0)], t,
		[Vector2(cu, cv + dv), Vector2(cu + su, cv + dv), Vector2(cu + su, cv), Vector2(cu, cv)])
	quad(g, "int_back", [p1 + back, p1, p1 + Vector3(0, OPEN_H, 0), p1 + back + Vector3(0, OPEN_H, 0)], -t,
		[Vector2(cu + du - su, cv + dv), Vector2(cu + du, cv + dv), Vector2(cu + du, cv), Vector2(cu + du - su, cv)])
	cur_color = Color(sd.carpet) if sd.carpet != null else Color("#d8d2c6")
	quad(g, "int_floor", [p0, p1, p1 + back, p0 + back], Vector3.UP)
	cur_color = Color.WHITE
	quad(g, "int_wall", [p0 + Vector3(0, OPEN_H, 0), p0 + back + Vector3(0, OPEN_H, 0), p1 + back + Vector3(0, OPEN_H, 0), p1 + Vector3(0, OPEN_H, 0)], Vector3.DOWN)
	var rows = max(1, int(deep / 3.0))
	var cols = max(1, int(width / 3.0))
	for ri in rows:
		for ci in cols:
			var pc = p0 + t * (width * (ci + 0.5) / cols) - n * (deep * (ri + 0.5) / rows) + Vector3(0, OPEN_H - 0.01, 0)
			quad(g, "int_panel", [pc - t * 0.5 - n * 0.3, pc + t * 0.5 - n * 0.3, pc + t * 0.5 + n * 0.3, pc - t * 0.5 + n * 0.3], Vector3.DOWN)
	if sd.name in ["FOOTQUARTERS", "FELGER'S FOOTWEAR"]:
		# shoe walls, benches and a table seen through the glass (Steven, Oct 20; tools/stores/small/shoes.gd)
		load("res://tools/stores/small/shoes.gd").inside(self, g, p0, t, -n, width, deep, sd.name)
	var mc = sd.merch if not sd.name in ["FOOTQUARTERS", "FELGER'S FOOTWEAR"] else []
	var k2 = 0
	var pos = 1.4
	while pos < width - 0.8 and not mc.is_empty():
		cur_color = Color(mc[k2 % mc.size()])
		box(g, "vcolor", p0 + t * pos - n * (deep * 0.45) + Vector3(0, 0.45, 0), abs_size(t, 1.2, 0.9, 0.8, n))
		pos += 2.8
		k2 += 1
	cur_color = Color.WHITE
	var sl = add_omni(a + t * Ln * 0.5 - n * min(1.5, deep * 0.4) + Vector3(0, OPEN_H - 0.4, 0), 0.45, max(deep + 1.0, 6.0), Color(1.0, 0.96, 0.9))
	tag(sl, "", 0.45, 1.2)
	if Ln >= 2.0:
		var spill_at = a + t * Ln * 0.5 - n * 0.4 + Vector3(0, OPEN_H - 0.15, 0)
		tag(add_spot(spill_at, n * 0.9 + Vector3.DOWN * 1.0, 1.6, 7.0, 55.0, Color("#FFF1DC")), "night")

## A storefront painted by the live game (Phase 4, tools/capture_fronts.py):
## the painting covers the frontage floor to lane ceiling; its fascia band
## (rows 17..56 of 150 in the live game's drawing) stands 12 cm proud with
## returns; the end piers are real; door tiles are open onto the 3D interior
## with reveals, and an open front shows the whole interior under the fascia.
## Anchors keep their own 3D fronts. The picture is drawn as seen from the
## hall, so on an edge that runs right-to-left for that viewer it is mirrored.
const FRONT_ROWS = 150.0
const FASCIA_TOP_PX = 17.0
const FASCIA_BOT_PX = 56.0
func front_art(g, e, a, b, n, t, Ln, sd, fa):
	var uv = fa.uv
	var tiles = int(fa.tiles)
	var flip = bool(fa.flip)
	var H = LANE_H
	var y_top = H * (1.0 - FASCIA_TOP_PX / FRONT_ROWS)
	var y_bot = H * (1.0 - FASCIA_BOT_PX / FRONT_ROWS)
	var tu = func(f):   # fraction along the edge -> atlas u
		return uv[0] + (uv[2] - uv[0]) * ((1.0 - f) if flip else f)
	var tv = func(y):   # height -> atlas v
		return uv[1] + (uv[3] - uv[1]) * (1.0 - y / H)
	var strip = func(off, f0, f1, y0, y1):
		var q0 = a + t * (f0 * Ln) + off
		var q1 = a + t * (f1 * Ln) + off
		quad(g, "front_art", [q0 + Vector3(0, y0, 0), q1 + Vector3(0, y0, 0), q1 + Vector3(0, y1, 0), q0 + Vector3(0, y1, 0)], n,
			[Vector2(tu.call(f0), tv.call(y0)), Vector2(tu.call(f1), tv.call(y0)), Vector2(tu.call(f1), tv.call(y1)), Vector2(tu.call(f0), tv.call(y1))])
	var doors = []
	for d in fa.doors:
		doors.append(int(d))
	var open_all = bool(fa.open) or (bool(sd.open) and doors.is_empty())
	# wall picture tile by tile: door tiles (or an open front) are open up to the fascia
	for k in tiles:
		var f0 = float(k) / tiles
		var f1 = float(k + 1) / tiles
		if open_all or k in doors:
			strip.call(Vector3.ZERO, f0, f1, y_bot, H)
		else:
			strip.call(Vector3.ZERO, f0, f1, 0.0, H)
	# the fascia band stands proud, with returns
	var fd = 0.12
	strip.call(n * fd, 0.0, 1.0, y_bot, y_top)
	var fb = a + Vector3(0, y_bot, 0)
	var ft = a + Vector3(0, y_top, 0)
	var fh = Vector3(0, y_top - y_bot, 0)
	quad(g, "bulkhead", [fb, fb + n * fd, fb + t * Ln + n * fd, fb + t * Ln], Vector3.DOWN)
	quad(g, "bulkhead", [ft + t * Ln, ft + t * Ln + n * fd, ft + n * fd, ft], Vector3.UP)
	quad(g, "bulkhead", [fb, fb + fh, fb + fh + n * fd, fb + n * fd], -t)
	quad(g, "bulkhead", [fb + t * Ln + n * fd, fb + t * Ln + fh + n * fd, fb + t * Ln + fh, fb + t * Ln], t)
	# end piers over the picture's own (8 px = half a metre at the live scale)
	var pw = min(0.5, Ln * 0.2)
	for ee in [pw * 0.5, Ln - pw * 0.5]:
		var c0 = a + t * ee
		box(g, "white_pilaster", c0 + Vector3(0, y_bot * 0.5, 0) + n * 0.05, abs_size(t, pw, y_bot, 0.10, n))
		box(g, "stone", c0 + Vector3(0, 0.3, 0) + n * 0.08, abs_size(t, pw + 0.04, 0.6, 0.16, n))
	# the accuracy meter's badge (STOREFRONT-FIDELITY.md): a small plaque on the
	# viewer's-left pier in the level's colour, so a walk shows what is sourced
	if facade_levels.has(e.store):
		var lv = clamp(facade_levels[e.store], 0, 4)
		var pier_at = a + t * (Ln - pw * 0.5) if flip else a + t * (pw * 0.5)
		cur_color = Color(LEVEL_COLORS[lv])
		box(g, "vcolor", pier_at + Vector3(0, 1.45, 0) + n * 0.11, abs_size(t, 0.16, 0.16, 0.02, n))
		cur_color = Color.WHITE
	# reveals where a painted wall meets an opening
	var tile_m = Ln / tiles
	if not open_all:
		for k in doors:
			for side in [[k, 1.0], [k + 1, -1.0]]:
				var kk = side[0]
				var neighbour_open = kk - 1 in doors if side[1] > 0 else kk in doors
				if kk <= 0 or kk >= tiles or neighbour_open:
					continue
				var cc = a + t * (kk * tile_m) - n * 0.2 + Vector3(0, y_bot * 0.5, 0)
				box(g, "cream", cc, abs_size(t, 0.06, y_bot, 0.4, n))
	# the interior behind the opening
	if sd.vacant:
		return
	var deep = clamp(float(e.depth), 3.0, 9.0)
	var in0 = pw
	var in1 = Ln - pw
	interior(g, e, a, n, t, Ln, sd, a + t * in0, a + t * in1, in1 - in0, deep)

## A closed stall (narrow_stores.py, Oct 7): the room freed when stores were narrowed, behind a
## painted barricade as malls put up while a space is fitted out: the hall's bulkhead and piers,
## a cream panel floor to bulkhead with a maroon band, "Coming Soon" in the mall's serif.
func coming_soon(g, a, b, n, t, Ln):
	var mid = a + t * Ln * 0.5
	var pil = 0.3
	for ee in [0.0, Ln - pil]:
		var c0 = a + t * (ee + pil * 0.5)
		box(g, "stone", c0 + Vector3(0, 0.45, 0) + n * 0.06, abs_size(t, pil, 0.9, 0.12, n))
		box(g, "cream", c0 + Vector3(0, (OPEN_H + 0.9) * 0.5, 0) + n * 0.03, abs_size(t, pil, OPEN_H - 0.9, 0.06, n))
	box(g, "bulkhead", mid + Vector3(0, (OPEN_H + LANE_H) * 0.5, 0) + n * 0.08, abs_size(t, Ln, LANE_H - OPEN_H, 0.16, n))
	var w = Ln - 2.0 * pil
	box(g, "bulkhead", mid + Vector3(0, OPEN_H * 0.5, 0) - n * 0.02, abs_size(t, w, OPEN_H, 0.06, n))
	cur_color = Color("#5b2a3a")
	for y in [0.45, 2.55]:
		box(g, "vcolor_matte", mid + Vector3(0, y, 0) + n * 0.015, abs_size(t, w, 0.08, 0.02, n))
	cur_color = Color("#a98a62")
	box(g, "vcolor_matte", mid + Vector3(0, 0.08, 0) + n * 0.02, abs_size(t, w, 0.16, 0.04, n))
	cur_color = Color.WHITE
	label("Coming Soon", "serif", "#5b2a3a", mid + Vector3(0, 1.55, 0) + n * 0.03, n, w * 0.85, 0.5)

func kb_wall(g, a, b, n, t):
	var Lw = a.distance_to(b)
	quad(g, "pink", [a, b, b + Vector3(0, LANE_H, 0), a + Vector3(0, LANE_H, 0)], n)
	for y in [1.0, 2.35]:
		box(g, "plum", (a + b) * 0.5 + Vector3(0, y, 0) + n * 0.015, abs_size(t, Lw, 0.16, 0.03, n))
	var k = 0.3
	while k < Lw:
		var c = a + t * k
		box(g, "white_pilaster", c + Vector3(0, LANE_H * 0.5, 0) + n * 0.15, abs_size(t, 0.6, LANE_H, 0.3, n))
		for y in [1.0, 2.35]:
			box(g, "plum", c + Vector3(0, y, 0) + n * 0.31, abs_size(t, 0.62, 0.16, 0.02, n))
		k += 4.0

## Southland Cinema: a marquee with bulbs over the entrance and lit poster cases.
func cinema_front(g, a, n, t, Ln):
	var mid = a + t * Ln * 0.5
	var mw = min(Ln * 0.7, 10.0)
	var mc = mid + Vector3(0, 3.75, 0) + n * 0.9
	cur_color = Color("#1d1a2e")
	box(g, "vcolor", mc, abs_size(t, mw, 0.95, 1.6, n))
	cur_color = Color.WHITE
	box(g, "bulbs", mc + Vector3(0, -0.49, 0), abs_size(t, mw - 0.2, 0.03, 1.4, n))
	box(g, "bulbs", mc + Vector3(0, 0.43, 0) + n * 0.81, abs_size(t, mw, 0.06, 0.02, n))
	box(g, "bulbs", mc + Vector3(0, -0.43, 0) + n * 0.81, abs_size(t, mw, 0.06, 0.02, n))
	cur_color = Color("#f4f0e2")
	box(g, "poster", mc + n * 0.81, abs_size(t, mw - 0.4, 0.6, 0.02, n))
	cur_color = Color.WHITE
	label("Southland Cinema", "serif", "#1d1a2e", mc + n * 0.84, n, mw * 0.8, 0.42)
	for side in [-1.0, 1.0]:
		var pc = mid + t * side * (Ln * 0.5 - 1.6) + Vector3(0, 1.6, 0) + n * 0.12
		cur_color = Color("#c8202c") if side < 0 else Color("#2451c4")
		box(g, "poster", pc, abs_size(t, 1.0, 1.45, 0.06, n))
		cur_color = Color.WHITE
		box(g, "brass", pc + n * 0.035, abs_size(t, 1.1, 1.55, 0.02, n))
	add_omni(mc + Vector3(0, -0.8, 0) + n * 0.6, 0.8, 6.0, Color(1.0, 0.9, 0.7))

## The Concourse's island under its lit ring (decision 7). Until Oct 16 2026 it was the Mr. Silverman
## jewelry island; Steven: "what was actually right here was the information desk ... we don't need
## those glass cases up top, and it actually extended a little bit" (east, toward the cookie shop).
## Steven, Nov 2: there was no jewelry island here or anywhere in the concourse, under either name
## (Mr. Silverman / Mr. Goldman): gold_kiosk() and island_kiosk() are gone (design/godot-directory.md).
## Built dynamic (dyn_info, lit by the bake's probes) so the change needs no rebake.
func kiosks():
	var centers = []
	var ms = Vector3(-52.0, 0, 54.0)
	force_dyn = true
	info_desk("info", ms + Vector3(1.2, 0, 0), ms)
	lit_ring("info", ms)
	force_dyn = false
	centers.append(ms)
	return centers

## The mall's Information desk: a long counter, no glass, a dark top under a brass rail, an
## "Information" plaque on the fascia of each long side and a two-sided board hung under the ring.
func info_desk(g, c, rc):
	var sx = 5.8
	var sz = 1.8
	var h = 1.05
	# the counter: solid body, a kick plate, a brass rail and a dark top with a lip
	box(g, "column", c + Vector3(0, h * 0.5, 0), Vector3(sx, h, sz))
	box(g, "black", c + Vector3(0, 0.06, 0), Vector3(sx + 0.04, 0.12, sz + 0.04))
	box(g, "brass", c + Vector3(0, h - 0.07, 0), Vector3(sx + 0.03, 0.04, sz + 0.03))
	box(g, "black", c + Vector3(0, h + 0.02, 0), Vector3(sx + 0.16, 0.04, sz + 0.16))
	# a lower work surface inside for the staff (seen over the top)
	box(g, "velvet", c + Vector3(0, h + 0.045, 0), Vector3(sx - 0.6, 0.01, sz - 0.5))
	for side in [-1.0, 1.0]:
		var f = Vector3(0, 0, side)
		var face = c + f * (sz * 0.5 + 0.01)
		# the plaque: a dark panel framed in brass, "Information" in cream
		cur_color = Color("#20242e")
		box(g, "vcolor", face + Vector3(0, 0.62, 0) + f * 0.012, Vector3(2.3, 0.36, 0.02))
		cur_color = Color.WHITE
		box(g, "brass", face + Vector3(0, 0.62, 0) + f * 0.004, Vector3(2.38, 0.44, 0.012))
		label("Information", "serif", "#efe2c2", face + Vector3(0, 0.62, 0) + f * 0.025, f, 2.0, 0.22)
	# the board under the ring: dark, brass-edged, on two cables
	var by = 3.05
	cur_color = Color("#20242e")
	box(g, "vcolor", rc + Vector3(0, by, 0), Vector3(2.6, 0.5, 0.08))
	cur_color = Color.WHITE
	box(g, "brass", rc + Vector3(0, by, 0), Vector3(2.68, 0.58, 0.05))
	for sd in [-1.0, 1.0]:
		cyl(g, "metal_dark", rc + Vector3(sd * 1.1, by + 0.29, 0), 0.006, 0.006, 6.5 - by - 0.29, 4, false)
		label("Information", "serif", "#efe2c2", rc + Vector3(0, by, sd * 0.045), Vector3(0, 0, sd), 2.2, 0.26)
	obst(["rect", c.x - sx * 0.5 - 0.5, c.z - sz * 0.5 - 0.5, c.x + sx * 0.5 + 0.5, c.z + sz * 0.5 + 0.5])

## A floating white ring lit from inside, hung on cables, with small spots.
func lit_ring(g, c):
	var R = 2.6
	var y = 4.25
	var seg = 32
	for i in seg:
		var a0 = TAU * i / seg
		var a1 = TAU * (i + 1) / seg
		var o0 = Vector3(cos(a0), 0, sin(a0))
		var o1 = Vector3(cos(a1), 0, sin(a1))
		var top = Vector3(0, y + 0.14, 0)
		var bot = Vector3(0, y - 0.14, 0)
		var ro = R + 0.12
		var ri = R - 0.12
		quad(g, "rib", [c + o0 * ro + bot, c + o1 * ro + bot, c + o1 * ro + top, c + o0 * ro + top], (o0 + o1).normalized())
		quad(g, "ring_glow", [c + o0 * ri + bot, c + o1 * ri + bot, c + o1 * ri + top, c + o0 * ri + top], -(o0 + o1).normalized())
		quad(g, "rib", [c + o0 * ri + bot, c + o1 * ri + bot, c + o1 * ro + bot, c + o0 * ro + bot], Vector3.DOWN)
		quad(g, "rib", [c + o0 * ri + top, c + o1 * ri + top, c + o1 * ro + top, c + o0 * ro + top], Vector3.UP)
	for k in 3:
		var a = TAU * k / 3.0
		var p = c + Vector3(cos(a), 0, sin(a)) * R + Vector3(0, y + 0.14, 0)
		cyl(g, "metal_dark", p, 0.008, 0.008, LANE_H - p.y, 4, false)
	for k in 6:
		var a = TAU * k / 6.0 + 0.3
		box(g, "black", c + Vector3(cos(a), 0, sin(a)) * R + Vector3(0, y - 0.22, 0), Vector3(0.12, 0.16, 0.12))
	add_omni(c + Vector3(0, y - 0.3, 0), 0.9, 6.0, Color(1.0, 0.95, 0.88))

## Anchor fronts, as the current game draws them from Steven's photos:
## a wide open mouth onto the sales floor under a store-specific fascia.
## The anchors' mall fronts in 2026 (IMG_4408, IMG_4438, IMG_4457): Lynn's Interiors in the Sears
## box (white tile portal, black script), Dillard's (white serif on light oak), JCPenney (red
## letters on rosso marble).
const ANCHOR_LOOK_2026 = {
	"LYNN'S INTERIORS": {"wall": "cream", "fascia": "rib", "frame": "", "cols": "", "text": "Lynn's Interiors", "font": "script", "fg": "#151515", "halo": false, "soffit": "lane_ceiling"},
	"JCPENNEY": {"wall": "cream", "fascia": "brown_stone", "frame": "", "cols": "metal_dark", "text": "JCPenney", "font": "sans", "fg": "#d0102e", "halo": false, "soffit": "lane_ceiling", "lit": true},
	"DILLARD'S": {"wall": "cream", "fascia": "wood_diag", "frame": "", "cols": "", "text": "Dillard's", "font": "serif", "fg": "#ffffff", "halo": false, "soffit": "cream", "lit": true},
}
const ANCHOR_LOOK = {
	"SEARS": {"wall": "buff_tile", "fascia": "buff_tile", "frame": "grey_tile", "cols": "", "text": "SEARS", "font": "sans_italic", "fg": "#1f3f8f", "halo": true, "soffit": "lane_ceiling"},
	"JCPENNEY": {"wall": "cream", "fascia": "wood_diag", "frame": "", "cols": "metal_dark", "text": "JCPenney", "font": "sans", "fg": "#ffffff", "halo": false, "soffit": "lane_ceiling"},
	"DILLARD'S": {"wall": "cream", "fascia": "brown_stone", "frame": "", "cols": "", "text": "Dillard's", "font": "serif", "fg": "#ffffff", "halo": false, "soffit": "cream", "lit": true},
}

func anchor_front(g, e, a, b, n, t, Ln, sd, lk):
	var mid = a + t * Ln * 0.5
	var top = LANE_H
	var mouth_h = OPEN_H + 0.2
	var deep = clamp(float(e.depth), 6.0, 16.0)
	# fascia across the full width, standing proud of the wall line
	box(g, lk.fascia, mid + Vector3(0, (mouth_h + top) * 0.5, 0) + n * 0.15, abs_size(t, Ln, top - mouth_h, 0.3, n))
	# soffit under the fascia
	quad(g, lk.soffit, [a + Vector3(0, mouth_h, 0) + n * 0.3, b + Vector3(0, mouth_h, 0) + n * 0.3, b + Vector3(0, mouth_h, 0) - n * 0.6, a + Vector3(0, mouth_h, 0) - n * 0.6], Vector3.DOWN)
	# end piers
	for ee in [0.0, Ln - 0.6]:
		var c0 = a + t * (ee + 0.3)
		box(g, lk.fascia if lk.cols == "" else lk.cols, c0 + Vector3(0, mouth_h * 0.5, 0) + n * 0.15, abs_size(t, 0.6, mouth_h, 0.3, n))
	if lk.frame != "":
		# a darker tile band framing the mouth (Sears)
		box(g, lk.frame, mid + Vector3(0, mouth_h + 0.2, 0) + n * 0.31, abs_size(t, Ln - 1.2, 0.4, 0.02, n))
		for ee in [0.6, Ln - 0.6]:
			box(g, lk.frame, a + t * ee + Vector3(0, mouth_h * 0.5, 0) + n * 0.31, abs_size(t, 0.4, mouth_h, 0.02, n))
	if lk.cols != "":
		# dark columns across the open front (JCPenney)
		var k = 6.0
		while k < Ln - 3.0:
			box(g, lk.cols, a + t * k + Vector3(0, mouth_h * 0.5, 0) - n * 0.4, abs_size(t, 0.45, mouth_h, 0.45, n))
			k += 6.0
	# letters
	var sc = mid + Vector3(0, (mouth_h + top) * 0.5, 0) + n * 0.31
	var S26 = load("res://tools/stores/signs/sign_2026.gd")
	if YEAR == 2026 and S26.for_store(sd.name) != null:
		# Demo 43: the anchor's sign as filmed, in 3D (tools/stores/signs/sign_2026.gd)
		var s26 = S26.for_store(sd.name)
		S26.build(self, g + "_sg26", sd.name, sc + Vector3(0, float(s26.get("mount_y", 0.0)), 0), n, min(Ln * 0.7, 14.0), top - mouth_h - 0.1, s26)
	elif lk.halo:
		box(g, "halo", sc - n * 0.005, abs_size(t, min(Ln * 0.42, 9.0), 1.15, 0.01, n))
	var lab = null
	if not (YEAR == 2026 and S26.for_store(sd.name) != null):
		lab = label(lk.text, lk.font, lk.fg, sc + n * 0.02, n, min(Ln * 0.38, 8.0), 1.2)
	if lab != null and lk.get("lit", false):
		var lc = Color(lk.fg)
		lab.modulate = Color(lc.r * 1.3, lc.g * 1.3, lc.b * 1.3)
	# workstream E (Nov 1): the old Sears box (Lynn's in 2026) and Dillard's level 1 are built and
	# walkable (tools/stores/sears/, tools/stores/dillards/; design/godot-sears.md, godot-dillards.md)
	var E_MOD = {"SEARS": "sears", "LYNN'S INTERIORS": "sears", "DILLARD'S": "dillards"}
	if E_MOD.has(sd.name):
		load("res://tools/stores/%s/store.gd" % E_MOD[sd.name]).build(self, g, e, a, b, n, t, Ln, sd)
		return
	# the sales floor behind the open mouth
	var p0 = a + t * 0.6
	var p1 = b - t * 0.6
	var back = -n * deep
	var cell = atlas_index.get(e.store, 0)
	var cu = float(cell % ATLAS_COLS) / ATLAS_COLS
	var cv = float(cell / ATLAS_COLS) / ATLAS_ROWS
	var du = 1.0 / ATLAS_COLS
	var dv = 1.0 / ATLAS_ROWS
	var reps = max(1, int(round((Ln - 1.2) / 6.0)))
	for k2 in reps:
		var q0 = p0 + t * ((Ln - 1.2) * k2 / reps)
		var q1 = p0 + t * ((Ln - 1.2) * (k2 + 1) / reps)
		quad(g, "int_back", [q0 + back, q1 + back, q1 + back + Vector3(0, mouth_h, 0), q0 + back + Vector3(0, mouth_h, 0)], n,
			[Vector2(cu, cv + dv), Vector2(cu + du, cv + dv), Vector2(cu + du, cv), Vector2(cu, cv)])
	quad(g, "int_back", [p0, p0 + back, p0 + back + Vector3(0, mouth_h, 0), p0 + Vector3(0, mouth_h, 0)], t,
		[Vector2(cu, cv + dv), Vector2(cu + du, cv + dv), Vector2(cu + du, cv), Vector2(cu, cv)])
	quad(g, "int_back", [p1 + back, p1, p1 + Vector3(0, mouth_h, 0), p1 + back + Vector3(0, mouth_h, 0)], -t,
		[Vector2(cu, cv + dv), Vector2(cu + du, cv + dv), Vector2(cu + du, cv), Vector2(cu, cv)])
	cur_color = Color(sd.carpet) if sd.carpet != null else Color("#d6cdbd")
	quad(g, "int_floor", [p0, p1, p1 + back, p0 + back], Vector3.UP)
	cur_color = Color.WHITE
	quad(g, "int_wall", [p0 + Vector3(0, mouth_h, 0), p0 + back + Vector3(0, mouth_h, 0), p1 + back + Vector3(0, mouth_h, 0), p1 + Vector3(0, mouth_h, 0)], Vector3.DOWN)
	var wd = Ln - 1.2
	for ri in max(1, int(deep / 3.0)):
		for ci in max(1, int(wd / 3.0)):
			var pc = p0 + t * (wd * (ci + 0.5) / max(1, int(wd / 3.0))) - n * (deep * (ri + 0.5) / max(1, int(deep / 3.0))) + Vector3(0, mouth_h - 0.01, 0)
			quad(g, "int_panel", [pc - t * 0.5 - n * 0.3, pc + t * 0.5 - n * 0.3, pc + t * 0.5 + n * 0.3, pc - t * 0.5 + n * 0.3], Vector3.DOWN)
	# racks and tables in the store's colours, in rows
	var mc = sd.merch
	var k3 = 0
	for row in [0.3, 0.55, 0.8]:
		var pos = 1.5
		while pos < wd - 1.0:
			cur_color = Color(mc[k3 % mc.size()])
			box(g, "vcolor", p0 + t * pos - n * (deep * row) + Vector3(0, 0.6, 0), abs_size(t, 1.6, 1.2, 0.6, n))
			pos += 3.2
			k3 += 1
	cur_color = Color.WHITE
	for k4 in 3:
		tag(add_omni(p0 + t * (wd * (k4 + 0.5) / 3.0) - n * deep * 0.45 + Vector3(0, mouth_h - 0.4, 0), 0.9, deep + 2.0, Color(1.0, 0.97, 0.9)), "", 0.9, 1.4)

## Glass doors to the outside (exits and the main entrance), with daylight beyond.
func doors_out(g, e, a, b, n, t, Ln):
	var sd = L.stores.get(e.store, {})
	var dh = 3.0
	var mid = a + t * Ln * 0.5
	var dw = min(Ln - 1.0, 9.0)
	var s0 = Ln * 0.5 - dw * 0.5
	var s1 = Ln * 0.5 + dw * 0.5
	var o = PackedVector2Array([Vector2(0, 0), Vector2(0, LANE_H), Vector2(Ln, LANE_H), Vector2(Ln, 0), Vector2(s1, 0), Vector2(s1, dh), Vector2(s0, dh), Vector2(s0, 0)])
	poly(g, "cream", o, a, t, Vector3.UP, n)
	box(g, "bronze", mid + Vector3(0, dh, 0), abs_size(t, dw + 0.2, 0.15, 0.2, n))
	var k = 0
	var cnt = max(2, int(round(dw / 1.6)))
	for i in cnt + 1:
		box(g, "bronze", a + t * (s0 + dw * i / cnt) + Vector3(0, dh * 0.5, 0), abs_size(t, 0.08, dh, 0.18, n))
	quad("glass", "glass", [a + t * s0, a + t * s1, a + t * s1 + Vector3(0, dh, 0), a + t * s0 + Vector3(0, dh, 0)], n, [], true)
	# a vestibule floor and canopy outside so the daylight has something to bounce off
	var out = -n
	var og = "outside"
	cur_color = Color.WHITE
	quad(og, "outside_ground", [a, b, b + out * 12.0, a + out * 12.0], Vector3.UP, [], false, 0.25)
	quad(og, "cream", [a + Vector3(0, dh + 0.3, 0), b + Vector3(0, dh + 0.3, 0), b + out * 4.0 + Vector3(0, dh + 0.3, 0), a + out * 4.0 + Vector3(0, dh + 0.3, 0)], Vector3.DOWN)
	# night: sodium lot lights outside and a warm spot in the vestibule
	for k5 in [-1.0, 0.0, 1.0]:
		tag(add_omni(mid + out * 14.0 + t * k5 * 10.0 + Vector3(0, 9.0, 0), 4.0, 25.0, Color("#FF9F45")), "night")
	tag(add_spot(mid + out * 2.0 + Vector3(0, dh + 0.2, 0), Vector3.DOWN, 1.5, 6.0, 60.0, Color("#FFE6C2")), "night")
	if e.kind == "exit":
		box(g, "exit_sign", mid + Vector3(0, dh + 0.55, 0) + n * 0.05, abs_size(t, 1.2, 0.36, 0.08, n))
		label("EXIT", "sans", "#ffffff", mid + Vector3(0, dh + 0.55, 0) + n * 0.1, n, 1.0, 0.24)
	else:
		label("Main Entrance", "serif", "#5b4030", mid + Vector3(0, dh + 0.75, 0) + n * 0.05, n, dw * 0.6, 0.42)
	# Workstream F (Nov 1 2026): past the vestibule floor, pictures of the real lot from this door,
	# captured from the outside (wing 3); they replace the empty sky past the 12 m stand-in
	# (tools/exterior/door_view.gd, design/godot-exterior.md "Looking out")
	load("res://tools/exterior/door_view.gd").build(self, e, a, b, n)

# ------------------------------------------------------------------ props
func bench(group, at, yaw):
	var xf = Transform3D(Basis(Vector3.UP, yaw), at)
	var Lb = 1.7
	for i in 5:
		box(group, "wood", Vector3(0, 0.44, -0.2 + i * 0.105), Vector3(Lb, 0.035, 0.085), xf)
	for i in 4:
		var c = Vector3(0, 0.62 + i * 0.105, 0.29 + i * 0.012)
		var bx = xf * Transform3D(Basis(Vector3.RIGHT, -0.25 - i * 0.06), c)
		box(group, "wood", Vector3.ZERO, Vector3(Lb, 0.085, 0.03), bx)
	for ee in [-Lb * 0.5 + 0.08, Lb * 0.5 - 0.08]:
		box(group, "metal_dark", Vector3(ee, 0.22, -0.1), Vector3(0.05, 0.44, 0.05), xf)
		box(group, "metal_dark", Vector3(ee, 0.4, 0.3), Vector3(0.05, 0.8, 0.05), xf)
		box(group, "metal_dark", Vector3(ee, 0.62, 0.0), Vector3(0.06, 0.04, 0.5), xf)
		box(group, "metal_dark", Vector3(ee, 0.05, 0.1), Vector3(0.06, 0.04, 0.55), xf)
	obst([at.x, at.z, 0.85])

func planter(at, kind):
	cyl("fixtures", "planter", at, 0.42, 0.46, 0.62, 24, false)
	cyl("fixtures", "soil", at + Vector3(0, 0.56, 0), 0.4, 0.4, 0.001, 18, true)
	if kind == "palm":
		palm(at + Vector3(0, 0.56, 0), 1.6)
	else:
		bush(at + Vector3(0, 0.56, 0), "leafy", 0.75, 5)
	obst([at.x, at.z, 0.6])

func trash(at):
	cyl("fixtures", "planter", at, 0.24, 0.28, 0.82, 20, false)
	cyl("fixtures", "planter", at + Vector3(0, 0.82, 0), 0.29, 0.29, 0.05, 20, false)
	cyl("fixtures", "planter", at + Vector3(0, 0.87, 0), 0.29, 0.12, 0.12, 20, true)
	obst([at.x, at.z, 0.45])

## Benches, planters and trash cans in the groupings seen in the 2018 walkthrough:
## a pair of benches facing each other across a round planter on the hall's
## centre line every ~22 m, a trash can one lane out, and planters by court
## columns. All of it goes in one mesh the player can switch on or off.
func place_fixtures(avoid):
	fx = true
	var count = 0
	for z in L.zones:
		if not in_wing(wing_of_zone(z.id)):
			continue
		if z.type == "hall" and float(z.vault_half) > 0.0:
			var sp = hall_span(z)
			var lo = sp[0]
			var hi = sp[1]
			if hi - lo < 14.0:
				continue
			var yaw0 = 0.0 if z.axis == "z" else PI * 0.5
			var k = 0
			var s0 = lo + 7.0
			while s0 < hi - 6.0:
				var c = hall_P(z, 0, 0, s0)
				var clear = true
				for a in avoid:
					if Vector2(c.x - a.x, c.z - a.z).length() < 7.5:
						clear = false
				if clear:
					planter(c, "palm" if k % 2 == 0 else "leafy")
					bench("fixtures", hall_P(z, 0, 0, s0 - 1.6), yaw0 + PI)
					bench("fixtures", hall_P(z, 0, 0, s0 + 1.6), yaw0)
					trash(hall_P(z, sp[2] * 0.45 * (1 if k % 2 == 0 else -1), 0, s0 + 4.5))
					count += 1
					k += 1
				s0 += 22.0
		elif z.type == "court" and z.style != "shoe":
			var r = z.rect
			planter(Vector3(r[0] + 2.3, 0, r[1] + 2.3), "palm")
			planter(Vector3(r[2] - 2.3, 0, r[3] - 2.3), "palm")
			trash(Vector3(r[2] - 2.3, 0, r[1] + 2.3))
	fx = false
	print("fixture groups: ", count)

func palm(base, hgt):
	cyl("foliage", "trunk", base, 0.07, 0.05, hgt, 8, false, false, true)
	var top = base + Vector3(0, hgt, 0)
	for i in 14:
		frond(top, TAU * i / 14 + randf() * 0.3, 1.5 + randf() * 0.6, deg_to_rad(35 + randf() * 25))

func frond(top, yaw, Lf, up):
	var s = st("foliage", "palm", true)
	var dir = Vector3(cos(yaw), 0, sin(yaw))
	var side = Vector3(-dir.z, 0, dir.x)
	var segs = 6
	var prev_l = Vector3.ZERO
	var prev_r = Vector3.ZERO
	var prev_c = top
	for i in segs + 1:
		var f = float(i) / segs
		var ang = up - f * 1.6 * up - f * f * 0.9
		var c = top
		if i > 0:
			c = prev_c + (dir * cos(ang) + Vector3.UP * sin(ang)) * (Lf / segs)
		var w = 0.46 * sin(PI * (0.15 + 0.85 * f)) + 0.05
		var lft = c + side * w + Vector3(0, -w * 0.35, 0)
		var rgt = c - side * w + Vector3(0, -w * 0.35, 0)
		if i > 0:
			var nn = (dir * -sin(ang) + Vector3.UP * cos(ang)).normalized()
			var v0 = float(i - 1) / segs
			tri(s, prev_l, prev_r, rgt, Vector2(0, v0), Vector2(1, v0), Vector2(1, f), nn)
			tri(s, prev_l, rgt, lft, Vector2(0, v0), Vector2(1, f), Vector2(0, f), nn)
		prev_l = lft; prev_r = rgt; prev_c = c

func bush(base, mname, size, cards):
	var s = st("foliage", mname, true)
	for i in cards:
		var yaw = PI * i / cards
		var d = Vector3(cos(yaw), 0, sin(yaw)) * size
		var tilt = Vector3(0, size * 0.9, 0)
		var p0 = base - d + Vector3(0, 0.02, 0)
		var p1 = base + d + Vector3(0, 0.02, 0)
		var nn = Vector3(-d.z, 0.3, d.x).normalized()
		tri(s, p0, p1, p1 + tilt, Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), nn)
		tri(s, p0, p1 + tilt, p0 + tilt, Vector2(0, 1), Vector2(1, 0), Vector2(0, 0), nn)
	var c = base + Vector3(0, size * 0.75, 0)
	tri(s, c + Vector3(-size, 0, -size), c + Vector3(size, 0, -size), c + Vector3(size, 0, size), Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector3.UP)
	tri(s, c + Vector3(-size, 0, -size), c + Vector3(size, 0, size), c + Vector3(-size, 0, size), Vector2(0, 0), Vector2(1, 1), Vector2(0, 1), Vector3.UP)

func palm_bed(group, at, sx, sz):
	var h = 0.42
	box(group, "bed_wood", at + Vector3(0, h * 0.5, 0), Vector3(sx, h, sz), Transform3D.IDENTITY, ["-y"])
	box(group, "soil", at + Vector3(0, h + 0.005, 0), Vector3(sx - 0.1, 0.01, sz - 0.1), Transform3D.IDENTITY, ["-y"])
	var nx = int(sx / 0.6)
	var nz = int(sz / 0.6)
	for i in nx:
		for j in nz:
			var p = at + Vector3(-sx * 0.5 + 0.3 + i * (sx - 0.6) / max(1, nx - 1), h, -sz * 0.5 + 0.3 + j * (sz - 0.6) / max(1, nz - 1))
			if abs(p.x - at.x) < 0.6 and abs(p.z - at.z) < sz * 0.3:
				continue
			bush(p, "poinsettia", 0.28, 3)
	palm(at + Vector3(0, h, -sz * 0.22), 2.4)
	palm(at + Vector3(0, h, sz * 0.22), 1.9)
	obst(["rect", at.x - sx * 0.5 - 0.3, at.z - sz * 0.5 - 0.3, at.x + sx * 0.5 + 0.3, at.z + sz * 0.5 + 0.3])

func lantern(at, top_y):
	var g = "lanterns"
	cyl(g, "brass", Vector3(at.x, at.y + 0.55, at.z), 0.015, 0.015, top_y - at.y - 0.55, 6, false)
	cyl(g, "lantern_glass", at + Vector3(0, -0.2, 0), 0.2, 0.24, 0.6, 8, false, false)
	for i in 8:
		var a = TAU * i / 8
		box(g, "brass", at + Vector3(cos(a) * 0.245, 0.1, sin(a) * 0.245), Vector3(0.025, 0.66, 0.025))
	cyl(g, "brass", at + Vector3(0, 0.4, 0), 0.27, 0.05, 0.18, 8, true)
	cyl(g, "brass", at + Vector3(0, -0.24, 0), 0.24, 0.26, 0.05, 8, true, true)
	cyl(g, "brass", at + Vector3(0, -0.36, 0), 0.02, 0.09, 0.12, 8, false, true)
	add_omni(at + Vector3(0, -0.05, 0), 1.0, 4.0, Color(1.0, 0.85, 0.63))

# ------------------------------------------------------------------ floors
## Floor quads per zone; each zone gets its own material carrying the pattern
## parameters as metadata, read by the runtime floor shader.
func floor_zone(z):
	var r = z.rect
	var mname = "floorz_" + z.id
	var m = mat(mname)
	var meta = {}
	if z.type == "hall":
		var sp = hall_span(z)
		meta = {"pattern": 1, "axis": 0 if z.axis == "x" else 1, "center": ((r[1] + r[3]) * 0.5) if z.axis == "x" else ((r[0] + r[2]) * 0.5), "half": sp[2], "medallions": 1 if z.id == "H3" else 0}
		if sp[2] < 2.5:
			meta = {"pattern": 0}
	else:
		meta = {"pattern": 2, "cx": (r[0] + r[2]) * 0.5, "cz": (r[1] + r[3]) * 0.5, "hx": (r[2] - r[0]) * 0.5, "hz": (r[3] - r[1]) * 0.5,
			# Demo 42, from the 2026 footage: Dillard's court blue-grey (Steven, Oct 23: "it's blue"),
			# Sears court terracotta and white, Shoe Dept. court sage green, JCPenney court a straight
			# terracotta-and-white checker
			"palette": {"dillards": 1, "sears": 2, "shoe": 3, "penney": 4}.get(z.style, 0)}
	m.set_meta("floor", meta)
	quad(z.id, mname, [Vector3(r[0], 0, r[1]), Vector3(r[2], 0, r[1]), Vector3(r[2], 0, r[3]), Vector3(r[0], 0, r[3])], Vector3.UP)

# ------------------------------------------------------------- environments
## Day: soft high sun, bright sky through skylights and clerestories.
## Night (the default): navy-black sky, the interior lit by its own lights.
func make_env(mode):
	var env = Environment.new()
	var sky = Sky.new()
	var psky = ProceduralSkyMaterial.new()
	if mode == "day":
		psky.sky_top_color = Color("#6FA3D8")
		psky.sky_horizon_color = Color("#CFE0EE")
		psky.ground_horizon_color = Color("#c9c3b5")
		psky.ground_bottom_color = Color("#7b766c")
		psky.sky_energy_multiplier = 1.3
	else:
		psky.sky_top_color = Color("#0B1530")
		psky.sky_horizon_color = Color("#1B2747")
		psky.ground_horizon_color = Color("#1B2747")
		psky.ground_bottom_color = Color("#0A0A0C")
		psky.sky_energy_multiplier = 0.6
		psky.sun_angle_max = 0.0
	sky.sky_material = psky
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY if mode == "day" else Environment.AMBIENT_SOURCE_COLOR
	# Oct 7 (Steven): night was too dark: cream fixtures read black. Ambient only reaches the
	# unbaked (dynamic) things, so it lifts fixtures and props without touching the baked rooms.
	env.ambient_light_color = Color("#2A2620") if mode == "day" else Color("#4a4236")
	env.ambient_light_energy = 0.3 if mode == "day" else 0.35
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 0.95 if mode == "day" else 0.7
	env.tonemap_white = 6.0 if mode == "day" else 4.0
	env.glow_enabled = true
	env.glow_intensity = 0.35
	env.glow_bloom = 0.04 if mode == "day" else 0.0
	env.glow_hdr_threshold = 1.2 if mode == "day" else 1.0
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.08 if mode == "day" else 1.05
	env.adjustment_contrast = 1.04 if mode == "day" else 1.05
	return env

# ------------------------------------------------------------------ build
func _parse_wing():
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--wing="):
			WING = int(a.substr(7))
		if a.begins_with("--year="):
			YEAR = int(a.substr(7))
	if OS.get_environment("MALL_WING") != "":
		WING = int(OS.get_environment("MALL_WING"))
	if OS.get_environment("MALL_YEAR") != "":
		YEAR = int(OS.get_environment("MALL_YEAR"))
	if WING != 0:
		GEN = "res://gen/w%d/" % WING
		if YEAR == 2026:
			GEN = "res://gen/w%dy26/" % WING

## The layout file, the scene and the stand-in picture prefix for this build's year.
func layout_path():
	return "res://layout_2026.json" if YEAR == 2026 else "res://layout_mall.json"
func scene_path():
	if WING == 0:
		return "res://main.tscn"
	return ("res://wing%d_2026.tscn" if YEAR == 2026 else "res://wing%d.tscn") % WING
func standin_prefix():
	return "y26_from_w" if YEAR == 2026 else "from_w"

func build():
	seed(1995)
	_parse_wing()
	print("building wing ", WING, " year ", YEAR, " into ", GEN)
	L = JSON.parse_string(FileAccess.get_file_as_string(layout_path()))
	if USE_FRONT_ART and FileAccess.file_exists("res://fronts.json"):
		var fj = JSON.parse_string(FileAccess.get_file_as_string("res://fronts.json"))
		fronts_px = float(fj.atlas.px_per_tile)
		for key in fj.fronts:
			var f = fj.fronts[key]
			if f.has("uv"):
				fronts[edge_key(f.a, f.b)] = f
	if FileAccess.file_exists("res://facade_records.json"):
		var fr = JSON.parse_string(FileAccess.get_file_as_string("res://facade_records.json"))
		for sid in fr.stores:
			facade_levels[sid] = int(fr.stores[sid].level)
	for z in L.zones:
		zones[z.id] = z
		zone_wing[z.id] = wing_of_zone(z.id)
	var ids = L.stores.keys()
	ids.sort()
	var ci = 0
	for sid in ids:
		atlas_index[sid] = ci
		ci += 1
	mall = Node3D.new(); mall.name = "Mall"
	light_root = Node3D.new(); light_root.name = "Lights"
	mall.add_child(light_root); light_root.owner = mall

	if WING == 3:
		# the outside (design/godot-exterior.md): the lot and the building's shell, from exterior.json
		outside = load("res://tools/exterior/exterior.gd").build(self)
		finish()
		return
	for z in L.zones:
		floor_zone(z)
		if z.type == "hall":
			build_hall(z)
		else:
			build_court(z)
	var lm = mat("floorz_left")
	lm.set_meta("floor", {"pattern": 0})
	for r in L.leftovers:
		quad("misc", "floorz_left", [Vector3(r[0], 0, r[1]), Vector3(r[2], 0, r[1]), Vector3(r[2], 0, r[3]), Vector3(r[0], 0, r[3])], Vector3.UP)
		quad("misc", "lane_ceiling", [Vector3(r[0], LANE_H, r[1]), Vector3(r[2], LANE_H, r[1]), Vector3(r[2], LANE_H, r[3]), Vector3(r[0], LANE_H, r[3])], Vector3.DOWN)
	# triangular patches (the diagonal corner by Babbage's, Oct 8: tools/layout_oct8.py)
	for tr3 in L.get("leftover_tris", []):
		var fl = []
		for q in tr3:
			fl.append(Vector3(q[0], 0, q[1]))
		var up3 = Vector3(0, LANE_H, 0)
		tri(st("misc", "floorz_left"), fl[0], fl[1], fl[2], proj_uv(fl[0], Vector3.UP), proj_uv(fl[1], Vector3.UP), proj_uv(fl[2], Vector3.UP), Vector3.UP)
		tri(st("misc", "lane_ceiling"), fl[0] + up3, fl[1] + up3, fl[2] + up3, proj_uv(fl[0], Vector3.DOWN), proj_uv(fl[1], Vector3.DOWN), proj_uv(fl[2], Vector3.DOWN), Vector3.DOWN)
	for e in L.edges:
		if in_wing(edge_wing(e)):
			build_edge(e)
		else:
			standin_edge(e)
	hall_mouths()
	star_medallions()
	if WING != 0:
		print("stand-in: ", standin_slots.size(), " storefront slots at ", pack_standin(), " px/m")
		standin_quads()
	var avoid = kiosks() if YEAR != 2026 else []
	# the mall directory kiosks (both years); also
	# writes GEN/directory.json for the map (tools/stores/directory/kiosk.gd, design/godot-directory.md)
	avoid += load("res://tools/stores/directory/kiosk.gd").place(self)
	place_fixtures(avoid)
	# framed Courier ads on the bare walls (Steven, Oct 14: tools/stores/posters/posters.gd); 1990s ads,
	# so not in 2026
	if YEAR != 2026:
		load("res://tools/stores/posters/posters.gd").build(self)
	# K&B's mall-facing wall: pink with plum stripes instead of a full storefront
	# is a per-store look we add in Phase 2 (decision 6); its storefront is generic for now.
	finish()

## The part of the build every wing shares: the sun, the environments, the meshes and their
## lightmap unwrap, the probes, the LightmapGI, the data files, the player and the scene file.
func finish():
	var sun = DirectionalLight3D.new()
	sun.name = "Sun"
	sun.light_bake_mode = Light3D.BAKE_STATIC
	sun.shadow_enabled = true
	sun.light_energy = 1.1
	sun.light_color = Color(1.0, 0.95, 0.86)
	sun.light_angular_distance = 3.5    # soft shadow edges, no hard bands
	sun.set_meta("only", "day")
	mall.add_child(sun); sun.owner = mall
	# high sun (about 65 degrees) so window patches land short and close to the walls
	sun.transform = Transform3D(Basis.looking_at(Vector3(0.30, -0.906, 0.30), Vector3.UP), Vector3.ZERO)

	DirAccess.make_dir_recursive_absolute("res://gen")
	ResourceSaver.save(make_env("day"), "res://gen/env_day.tres")
	ResourceSaver.save(make_env("night"), "res://gen/env_night.tres")
	var we = WorldEnvironment.new()
	we.name = "Env"; we.environment = load("res://gen/env_night.tres")
	mall.add_child(we); we.owner = mall

	var static_root = Node3D.new(); static_root.name = "Static"
	mall.add_child(static_root); static_root.owner = mall
	DirAccess.make_dir_recursive_absolute(GEN)
	for gname in acc:
		var am = ArrayMesh.new()
		for mname in acc[gname]:
			var s = acc[gname][mname]
			s.index()
			s.commit(am)
			am.surface_set_material(am.get_surface_count() - 1, glow_mat(gname, mname))
		var texel = TEXEL
		if gname.ends_with("_mach"):
			# arcade machines: mostly lit by their own glow; a coarse texel keeps the
			# lightmap atlas to one layer (a fine one doubled the download)
			texel = TEXEL * 1.5
		elif gname.begins_with("sr_") or gname.begins_with("dl_"):
			# workstream E's big rooms (Sears 70 x 50 m, Dillard's 68 x 38 m): ceilings are plain lay-in,
			# so a coarse texel there; floors and walls a little coarser than the halls
			texel = TEXEL * (2.0 if gname.contains("ceil") else 1.25)
		elif gname.ends_with("props") or gname == "lanterns":
			texel = TEXEL * 0.6
		elif gname == "outside":
			texel = TEXEL * 4.0
		elif gname == "ex_ground":
			# the lot: 400 m across; a coarse texel keeps its lightmap to one layer
			texel = TEXEL * 10.0
		elif gname == "ex_far":
			texel = TEXEL * 6.0
		elif gname.begins_with("ex_"):
			texel = TEXEL * 2.5
		elif zones.has(gname) and not in_wing(zone_wing[gname]):
			# the other wing's halls and courts (the stand-in): seen from across the seam only
			texel = TEXEL * 2.5
		if am.lightmap_unwrap(Transform3D.IDENTITY, texel) != OK:
			push_error("unwrap failed " + gname)
		ResourceSaver.save(am, GEN + gname + ".res")
		var mi = MeshInstance3D.new()
		mi.name = gname
		mi.mesh = load(GEN + gname + ".res")
		mi.gi_mode = GeometryInstance3D.GI_MODE_STATIC
		static_root.add_child(mi); mi.owner = mall
	var dyn_root = Node3D.new(); dyn_root.name = "Dynamic"
	mall.add_child(dyn_root); dyn_root.owner = mall
	for gname in dyn_acc:
		var am = ArrayMesh.new()
		for mname in dyn_acc[gname]:
			var s = dyn_acc[gname][mname]
			s.index()
			# the arcade's many small machine parts: compressed vertex attributes halve the download
			# the traced sign letters too (Oct 7): dense outlines, the download crossed 100 MB without it
			s.commit(am, Mesh.ARRAY_FLAG_COMPRESS_ATTRIBUTES if gname.begins_with("pc") or gname.contains("_sign") else 0)
			am.surface_set_material(am.get_surface_count() - 1, mat(mname))
		ResourceSaver.save(am, GEN + "dyn_" + gname + ".res")
		var mi = MeshInstance3D.new()
		mi.name = "dyn_" + gname
		mi.mesh = load(GEN + "dyn_" + gname + ".res")
		mi.gi_mode = GeometryInstance3D.GI_MODE_DYNAMIC
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		dyn_root.add_child(mi); mi.owner = mall

	for z in (L.zones if WING != 3 else []):
		var r = z.rect
		var rp = ReflectionProbe.new()
		var hgt = 10.0 if z.type == "court" else 6.6
		rp.position = Vector3((r[0] + r[2]) * 0.5, hgt * 0.5, (r[1] + r[3]) * 0.5)
		rp.size = Vector3(r[2] - r[0] + 0.5, hgt, r[3] - r[1] + 0.5)
		rp.box_projection = true
		rp.interior = true
		rp.update_mode = ReflectionProbe.UPDATE_ONCE
		rp.intensity = 0.9
		mall.add_child(rp); rp.owner = mall

	var lmg = LightmapGI.new()
	lmg.name = "LightmapGI"
	# Godot 4.7: Medium leaves blotchy low-frequency noise on the hall walls and
	# vaults (the light comes from many small emissive discs); Ultra on Steven's
	# Mac takes ~12 min per setup, and the denoiser needs more than its 0.1 default.
	lmg.quality = LightmapGI.BAKE_QUALITY_ULTRA
	lmg.bounces = 3
	lmg.use_denoiser = true
	lmg.denoiser_strength = 0.25
	lmg.environment_mode = LightmapGI.ENVIRONMENT_MODE_SCENE
	lmg.max_texture_size = 4096
	lmg.generate_probes_subdiv = LightmapGI.GENERATE_PROBES_SUBDIV_4
	mall.add_child(lmg); lmg.owner = mall

	for c in light_root.get_children():
		c.owner = mall
	for c in mall.get_children():
		if c is Label3D:
			c.owner = mall

	var sf = FileAccess.open(GEN + "signs.json", FileAccess.WRITE)
	sf.store_string(JSON.stringify({"signs": signs}))
	sf.close()
	var mf = FileAccess.open(GEN + "mannequins.json", FileAccess.WRITE)
	mf.store_string(JSON.stringify({"mannequins": mannequins}))
	mf.close()
	var mc = FileAccess.open(GEN + "machines.json", FileAccess.WRITE)
	mc.store_string(JSON.stringify({"machines": machines}))
	mc.close()
	var cf = FileAccess.open(GEN + "collide.json", FileAccess.WRITE)
	cf.store_string(JSON.stringify({"static": obstacles, "fixtures": fx_obstacles}))
	cf.close()
	mall.set_meta("wing", WING)
	mall.set_meta("year", YEAR)
	mall.set_meta("gen", GEN)
	if WING == 3:
		# the outside: its walk grid is the lot (exterior.json), its doors lead into wings 1 and 2
		var wf = FileAccess.open(GEN + "wing.json", FileAccess.WRITE)
		wf.store_string(JSON.stringify({"wing": WING, "seam": [], "spawn": outside.spawn, "walk": outside.walk, "doors": outside.doors}))
		wf.close()
	elif WING != 0:
		# the wing's walk grid, its seam and where a fresh start stands (scripts/player.gd). The
		# exterior doors (they lead outside, wing 3) come from exterior.json itself, so adding the
		# outside changed nothing in gen/w1 and gen/w2 (the stand-in stamps stay valid)
		var wf = FileAccess.open(GEN + "wing.json", FileAccess.WRITE)
		wf.store_string(JSON.stringify({"wing": WING, "seam": SEAM, "other_side": 1.0 if WING == 1 else -1.0,
			"spawn": [33.0, 0.0, 90.0, 3.0] if WING == 1 else [-9.0, 61.0, 90.0, 3.0], "walk": wing_walk()}))
		wf.close()
		# the stand-in's atlas slots, for tools/capture_standin.gd (it fills the other wing's pictures)
		var jf = FileAccess.open(GEN + "standin.json", FileAccess.WRITE)
		jf.store_string(JSON.stringify({"wing": WING, "from": 3 - WING, "atlas": [STANDIN_ATLAS.x, STANDIN_ATLAS.y], "pxm": standin_pxm,
			"lane_h": LANE_H, "out": STANDIN_OUT, "slots": standin_slots}, " "))
		jf.close()
	var player = load("res://scripts/player.gd").new()
	player.name = "Player"
	player.set("obstacles", obstacles)
	player.set("map_origin", Vector2(L.origin[0], L.origin[1]))
	player.set("map_scale", L.scale)
	mall.add_child(player); player.owner = mall
	var rt = Node.new()
	rt.set_script(load("res://scripts/mall_runtime.gd"))
	rt.name = "Runtime"
	mall.add_child(rt); rt.owner = mall
	# owner-editable sign text (gen/signs.json); after the player so its taps come first
	var sg = Node.new()
	sg.set_script(load("res://scripts/signs.gd"))
	sg.name = "Signs"
	mall.add_child(sg); sg.owner = mall

	var ps = PackedScene.new()
	ps.pack(mall)
	var sp_out = scene_path()
	ResourceSaver.save(ps, sp_out)
	print("saved ", sp_out)
	var lights = light_root.get_child_count()
	print("BUILD OK static groups=", acc.size(), " dynamic=", dyn_acc.size(), " lights=", lights, " labels=", mall.get_children().filter(func(c): return c is Label3D).size())

func _initialize():
	build()
	quit()
