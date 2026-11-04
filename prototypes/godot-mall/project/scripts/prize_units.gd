## The prizes added for the fuller counters (workstream PRIZES, Nov 3 2026; design/godot-prize-counter.md
## "PRIZES"): Pocket Change 1995 (Option B of design/research/redemption-counters.md) and games, inc. 2026.
## Static helpers on a scripts/prizes.gd instance P (its kind() / add() / M() / batching), so the counter
## (P fills its bins and shelves) and the bag (scripts/items/prize_model.gd builds one unit) draw the
## same thing.
##
##   kinds(P)                         registers every mesh kind these prizes use (once per P)
##   unit(P, base, c, k, rng)         one unit of a prize at c (bottom centre, +x the customer's right,
##                                    +y up, +z toward the customer), colour variant k
##   fill(P, rng, fr, span, y, base, bins) -> bool
##                                    fills a bin of P's case frame fr neatly: same orientation, rows and
##                                    layers on a grid, colours striped by column; false if base is unknown
##   SPEC[base]                        how a prize sits in a bin (see below)
##
## A prize's base name is its catalogue key without games, inc.'s "g_" prefix, so a prize sold in both
## years (finger trap, slap bracelet, sticky hand, ...) is drawn the same at both counters.
## All shapes are generic: no brands, characters or logos; packaging words are drawn by prizes.gd (art).
extends RefCounted

const UP := Vector3.UP

## How each prize sits in a bin. mode: "grid" (units in rows and layers: pu across, pd in depth, dy per
## layer, n layers), "row" (cards or boxes standing in rows, front to back, pd apart, the back rows on
## clear risers), "upright" (standing in rows, eyes or faces to the customer).
## cols: the colour variants, cycled by column (so a bin shows neat stripes of colour).
const SPEC := {
	"lollipop": {"mode": "upright", "pu": 0.036, "pd": 0.04},
	"candy_roll": {"mode": "grid", "pu": 0.056, "pd": 0.019, "dy": 0.0165, "n": 3},
	"taffy": {"mode": "grid", "pu": 0.092, "pd": 0.031, "dy": 0.0072, "n": 4},
	"powder_straw": {"mode": "grid", "pu": 0.0092, "pd": 0.17, "dy": 0.0078, "n": 3},
	"sour_candy": {"mode": "grid", "pu": 0.03, "pd": 0.021, "dy": 0.0165, "n": 3},
	"candy_ring": {"mode": "upright", "pu": 0.03, "pd": 0.032},
	"spider_ring": {"mode": "grid", "pu": 0.027, "pd": 0.027, "dy": 0.009, "n": 2},
	"bounce_ball": {"mode": "grid", "pu": 0.028, "pd": 0.028, "dy": 0.024, "n": 2},
	"pencil": {"mode": "grid", "pu": 0.0082, "pd": 0.2, "dy": 0.0072, "n": 3},
	"eraser": {"mode": "grid", "pu": 0.036, "pd": 0.026, "dy": 0.0155, "n": 2},
	"stickers": {"mode": "row", "pd": 0.05, "w": 0.062, "h": 0.093, "gap": 0.004},
	"sticky_hand": {"mode": "grid", "pu": 0.044, "pd": 0.06, "dy": 0.006, "n": 3},
	"jelly_bracelet": {"mode": "grid", "pu": 0.07, "pd": 0.07, "dy": 0.0045, "n": 6},
	"glow_bracelet": {"mode": "grid", "pu": 0.074, "pd": 0.074, "dy": 0.0045, "n": 5},
	"army_men": {"mode": "row", "pd": 0.04, "w": 0.075, "h": 0.105, "gap": 0.006},
	"rubber_snake": {"mode": "grid", "pu": 0.05, "pd": 0.05, "dy": 0.013, "n": 2},
	"slammer": {"mode": "grid", "pu": 0.05, "pd": 0.05, "dy": 0.0066, "n": 7},
	"troll": {"mode": "upright", "pu": 0.055, "pd": 0.07},
	"paddle_ball": {"mode": "row", "pd": 0.045, "w": 0.105, "h": 0.215, "gap": 0.008, "lean": 0.5},
	"yoyo": {"mode": "upright", "pu": 0.064, "pd": 0.045},
	"water_pistol": {"mode": "grid", "pu": 0.07, "pd": 0.12, "dy": 0.026, "n": 2},
	"sunglasses": {"mode": "grid", "pu": 0.145, "pd": 0.06, "dy": 0.016, "n": 2},
	"mood_ring": {"mode": "upright", "pu": 0.026, "pd": 0.028},
	"toy_car": {"mode": "row", "pd": 0.04, "w": 0.09, "h": 0.13, "gap": 0.008},
	"harmonica": {"mode": "grid", "pu": 0.11, "pd": 0.034, "dy": 0.021, "n": 2},
	"koosh": {"mode": "grid", "pu": 0.07, "pd": 0.07, "dy": 0.06, "n": 1},
	"lcd_game": {"mode": "row", "pd": 0.06, "w": 0.1, "h": 0.135, "gap": 0.01, "box": 0.035},
	"walkie": {"mode": "row", "pd": 0.07, "w": 0.11, "h": 0.15, "gap": 0.01, "box": 0.045},
	# games, inc. (2026)
	"popper_key": {"mode": "grid", "pu": 0.058, "pd": 0.058, "dy": 0.011, "n": 3},
	"squishy": {"mode": "grid", "pu": 0.046, "pd": 0.046, "dy": 0.03, "n": 2},
	"light_ring": {"mode": "upright", "pu": 0.03, "pd": 0.032},
	"fidget": {"mode": "grid", "pu": 0.068, "pd": 0.068, "dy": 0.0115, "n": 3},
	"blind_bag": {"mode": "row", "pd": 0.035, "w": 0.085, "h": 0.115, "gap": 0.006},
	"slime": {"mode": "grid", "pu": 0.068, "pd": 0.068, "dy": 0.047, "n": 2},
	"emoji_key": {"mode": "upright", "pu": 0.05, "pd": 0.05},
	"dough_ball": {"mode": "grid", "pu": 0.066, "pd": 0.066, "dy": 0.06, "n": 1},
	"led_wand": {"mode": "grid", "pu": 0.03, "pd": 0.32, "dy": 0.022, "n": 2},
	"popper_board": {"mode": "row", "pd": 0.045, "w": 0.16, "h": 0.16, "gap": 0.01, "lean": 0.35},
	"phone_stand": {"mode": "row", "pd": 0.08, "w": 0.11, "h": 0.15, "gap": 0.012, "box": 0.05},
	"cable": {"mode": "row", "pd": 0.05, "w": 0.09, "h": 0.14, "gap": 0.012, "box": 0.03},
	"earbuds": {"mode": "row", "pd": 0.07, "w": 0.1, "h": 0.13, "gap": 0.014, "box": 0.05},
	"speaker": {"mode": "row", "pd": 0.1, "w": 0.13, "h": 0.15, "gap": 0.014, "box": 0.08},
	"giftcard": {"mode": "row", "pd": 0.03, "w": 0.06, "h": 0.095, "gap": 0.008},
	"arcade": {"mode": "row", "pd": 0.12, "w": 0.13, "h": 0.17, "gap": 0.015, "box": 0.1},
	# the bigger prizes (walls; the bag)
	"projector": {"mode": "row", "pd": 0.2, "w": 0.18, "h": 0.18, "gap": 0.02, "box": 0.18},
	"headphones": {"mode": "row", "pd": 0.2, "w": 0.2, "h": 0.24, "gap": 0.02, "box": 0.09},
	"handheld": {"mode": "row", "pd": 0.2, "w": 0.3, "h": 0.17, "gap": 0.03, "box": 0.07},
	"console": {"mode": "row", "pd": 0.3, "w": 0.36, "h": 0.44, "gap": 0.04, "box": 0.13},
	"ledstrip": {"mode": "row", "pd": 0.1, "w": 0.2, "h": 0.2, "gap": 0.02, "box": 0.06},
	"squish": {"mode": "upright", "pu": 0.23, "pd": 0.3},
	"capybara": {"mode": "upright", "pu": 0.3, "pd": 0.32},
	"squish_big": {"mode": "upright", "pu": 0.34, "pd": 0.36},
	"play_ball": {"mode": "grid", "pu": 0.19, "pd": 0.19, "dy": 0.18, "n": 1},
	"bubbles": {"mode": "upright", "pu": 0.055, "pd": 0.07},
	"plush_bear": {"mode": "upright", "pu": 0.3, "pd": 0.3},
	"plush_bunny": {"mode": "upright", "pu": 0.3, "pd": 0.3},
	"plush_dog": {"mode": "upright", "pu": 0.3, "pd": 0.3},
}

## Plush that are tinted (their Blender fur is near-white), cycled like COLS (the claw's FUR colours).
const TINT := {"plush_bear": true, "plush_bunny": true, "plush_dog": true, "big_bear": true, "squish": true, "squish_big": true, "jumbo": true}

## Prizes with a Blender model (models/<id>/<id>.glb, the shared "items" pack): the counter shows the
## model, batched; [glb id, scale]. When the model isn't there (not built yet) the primitive stands in.
const BLENDER := {
	"troll": ["bl_pc_troll", 1.0], "yoyo": ["bl_pc_yoyo", 1.0], "koosh": ["bl_pc_koosh", 1.0],
	"blaster": ["bl_pc_blaster", 1.0], "skateboard": ["bl_pc_skateboard", 1.0], "plasma": ["bl_pc_plasma", 1.0],
	"plush_bear": ["bl_pc_plush_bear", 1.0], "plush_bunny": ["bl_pc_plush_bunny", 1.0], "plush_dog": ["bl_pc_plush_dog", 1.0],
	"big_bear": ["bl_pc_plush_bear", 2.6],
	"squish": ["bl_gi_squish", 1.0], "squish_big": ["bl_gi_squish", 1.6], "jumbo": ["bl_gi_squish", 3.6],
	"capybara": ["bl_gi_capybara", 1.0], "dough_ball": ["bl_gi_doughball", 1.0],
}

## Colour variants per prize (cycled by column, or by unit on the wall).
const COLS := {
	"lollipop": ["#e8283c", "#ffb428", "#3cb4f0", "#8c3cd2", "#3cc85a", "#ff6eb4"],
	"candy_roll": ["#ff9ec8", "#bfe6f8", "#fff1a8", "#c8f2c0", "#e4c8f6"],
	"taffy": ["#e8283c", "#3cb4f0", "#ffc828", "#8cd23c", "#b45adc"],
	"powder_straw": ["#ff4fa8", "#3c8cff", "#ffd228", "#46d264", "#ff7a1e", "#9a46e6"],
	"sour_candy": ["#9cff3c", "#ffdc28", "#ff3c3c", "#3cdcff", "#c85aff"],
	"candy_ring": ["#ff2a50", "#2a8cff", "#ffd228", "#3cdc6e", "#c84bff"],
	"spider_ring": ["#121214", "#121214", "#ff7a1e", "#9cff3c"],
	"bounce_ball": ["#ff3c96", "#3cdcff", "#9cff3c", "#ffdc28", "#b45aff", "#ff7a1e"],
	"pencil": ["#ffd228", "#ff4fa8", "#3c8cff", "#46d264", "#ff7a1e"],
	"eraser": ["#ff9ec8", "#9ee0ff", "#fff08a", "#b4f09a", "#ffffff"],
	"sticky_hand": ["#ff3c96", "#3cdcff", "#9cff3c", "#ffdc28", "#b45aff"],
	"jelly_bracelet": ["#ff3c96", "#3cdcff", "#9cff3c", "#ffdc28", "#b45aff", "#111114"],
	"glow_bracelet": ["#3cff6e", "#ff4fd2", "#3cc8ff", "#ffe63c", "#ff8a28"],
	"rubber_snake": ["#3a8c32", "#c8341e", "#e6b41e", "#3c3c46"],
	"slammer": ["#26262c", "#b8b8c0", "#c8a040", "#26262c"],
	"troll": ["#ff3c96", "#3cdcff", "#9cff3c", "#ffdc28", "#b45aff", "#ff7a1e"],
	"paddle_ball": ["#d8a868"],
	"yoyo": ["#e8283c", "#2a6cff", "#ffd228", "#2ab45a", "#111114"],
	"water_pistol": ["#3cdcff", "#ff4fa8", "#9cff3c", "#ffb428"],
	"sunglasses": ["#ff3c96", "#3cdcff", "#ffe63c", "#9cff3c", "#ff8a28"],
	"mood_ring": ["#2a3c9c", "#1e8c64", "#8c2aa0", "#3c2a20"],
	"toy_car": ["#e8283c", "#2a6cff", "#ffd228", "#2ab45a", "#e6e6ea"],
	"harmonica": ["#c8c8d0"],
	"koosh": ["#ff3c96", "#3cdcff", "#9cff3c", "#ffdc28"],
	"popper_key": ["#ff3c96", "#3cdcff", "#9cff3c", "#ffdc28", "#b45aff", "#ff7a1e"],
	"squishy": ["#ffc8dc", "#c8ecff", "#fff0b4", "#d2f5c8", "#e6d2ff", "#ffdcbe"],
	"light_ring": ["#ff2a50", "#2a8cff", "#3cff6e", "#ffd228", "#ff4fd2"],
	"fidget": ["#ff3c3c", "#2a8cff", "#ffd228", "#2ab45a", "#b45aff", "#111114"],
	"blind_bag": ["#d2b4ff", "#b4e6ff", "#ffb4dc", "#c8ffb4"],
	"slime": ["#3cff9c", "#ff4fd2", "#3cc8ff", "#ffe63c", "#b45aff"],
	"emoji_key": ["#ffd232"],
	"dough_ball": ["#ffc8dc", "#c8ecff", "#fff0b4", "#d2f5c8", "#e6d2ff"],
	"led_wand": ["#ff4fd2", "#3cc8ff", "#3cff6e", "#ffe63c"],
	"popper_board": ["#ff3c96", "#3cdcff", "#9cff3c", "#ffdc28", "#b45aff"],
	"giftcard": ["#e8283c", "#2a6cff", "#2ab45a", "#111114", "#ffb428", "#8c3cd2"],
	"plush_bear": ["#b5824a", "#5a3820", "#c21f2a", "#72a6e0"],
	"plush_bunny": ["#ea88ae", "#e8e0cc", "#9e82d4", "#f2cc34"],
	"plush_dog": ["#c8a070", "#e8e0cc", "#7ccfa6", "#5a3820"],
	"big_bear": ["#b5824a"],
	"squish": ["#ffc8dc", "#bfe6ff", "#fff0a8", "#c8f2c0", "#e4d0ff", "#ffd8b8", "#9be0d0"],
	"squish_big": ["#e4d0ff", "#ffc8dc", "#bfe6ff", "#c8f2c0"],
	"jumbo": ["#ffc8dc", "#bfe6ff", "#e4d0ff"],
}

const BOX_ART := {"lcd_game": "box_lcd", "walkie": "box_walkie", "cassette": "box_cassette", "rc_car": "box_rc",
	"earbuds": "box_earbuds", "speaker": "box_speaker", "projector": "box_projector", "headphones": "box_headphones",
	"handheld": "box_handheld", "console": "box_console", "phone_stand": "box_phonestand", "cable": "box_cable",
	"arcade": "box_arcade", "ledstrip": "box_ledstrip"}
## A box art whose picture is another's (outside a counter, where the catalogue's "art" isn't read).
const BOX_BG := {"box_cable": "box_phonestand"}
## Box sizes (w, h, depth) in metres for the boxed prizes.
const BOX_SIZE := {"lcd_game": Vector3(0.1, 0.135, 0.035), "walkie": Vector3(0.11, 0.15, 0.045),
	"cassette": Vector3(0.2, 0.15, 0.07), "rc_car": Vector3(0.34, 0.2, 0.14), "earbuds": Vector3(0.1, 0.13, 0.05),
	"speaker": Vector3(0.13, 0.15, 0.08), "projector": Vector3(0.18, 0.18, 0.18), "headphones": Vector3(0.2, 0.24, 0.09),
	"handheld": Vector3(0.3, 0.17, 0.07), "console": Vector3(0.36, 0.44, 0.13), "phone_stand": Vector3(0.11, 0.15, 0.05),
	"cable": Vector3(0.09, 0.14, 0.03), "arcade": Vector3(0.13, 0.17, 0.1), "ledstrip": Vector3(0.2, 0.2, 0.06)}

static func col(base: String, k: int) -> Color:
	var cs: Array = COLS.get(base, ["#ffffff"])
	return Color(cs[posmod(k, cs.size())])

static func base_of(it: String) -> String:
	return it.trim_prefix("g_")

# ------------------------------------------------------------------ mesh kinds
static func kinds(P) -> void:
	if P.acc.has("u_ball_s"):
		return
	P.kind("u_ball_s", P.sphere(0.5, 12, 6), P.M("swirl", Color.WHITE, 0.4, 0.35))
	P.kind("u_sph", P.sphere(0.5, 12, 6), P.M("", Color.WHITE, 0.35, 0.45))
	P.kind("u_sph_soft", P.sphere(0.5, 14, 7), P.M("", Color.WHITE, 0.4, 0.95))
	P.kind("u_sph_jelly", P.sphere(0.5, 12, 6), P.M("", Color.WHITE, 0.6, 0.12, 0.0, 0.8))
	P.kind("u_box", P.box(Vector3.ONE), P.M("", Color.WHITE, 0.35, 0.5))
	P.kind("u_box_soft", P.box(Vector3.ONE), P.M("", Color.WHITE, 0.4, 0.9))
	P.kind("u_box_metal", P.box(Vector3.ONE), P.M("", Color.WHITE, 0.25, 0.25, 0.75))
	P.kind("u_box_jelly", P.box(Vector3.ONE), P.M("", Color.WHITE, 0.6, 0.12, 0.0, 0.7))
	P.kind("u_box_clear", P.box(Vector3.ONE), P.M("", Color(0.92, 0.97, 1.0), 0.2, 0.05, 0.0, 0.28))
	P.kind("u_wrap_box", P.box(Vector3.ONE), P.M("wrapper", Color.WHITE, 0.4, 0.45))
	P.kind("u_cyl", P.cyl(0.5, 0.5, 1.0, 12, true), P.M("", Color.WHITE, 0.35, 0.5))
	P.kind("u_cyl_metal", P.cyl(0.5, 0.5, 1.0, 12, true), P.M("", Color.WHITE, 0.25, 0.25, 0.75))
	P.kind("u_cyl_jelly", P.cyl(0.5, 0.5, 1.0, 12, true), P.M("", Color.WHITE, 0.6, 0.12, 0.0, 0.7))
	P.kind("u_cyl_wrap", P.cyl(0.5, 0.5, 1.0, 10, true), P.M("wrapper", Color.WHITE, 0.4, 0.45))
	P.kind("u_cyl_stripe", P.cyl(0.5, 0.5, 1.0, 8, true), P.M("stripes", Color.WHITE, 0.4, 0.45))
	P.kind("u_hex_stripe", P.cyl(0.5, 0.5, 1.0, 6, true), P.M("stripes", Color.WHITE, 0.35, 0.55))
	P.kind("u_glow", P.cyl(0.5, 0.5, 1.0, 10, true), P.M("", Color.WHITE, 2.2, 0.2))
	P.kind("u_glow_sph", P.sphere(0.5, 10, 5), P.M("", Color.WHITE, 2.2, 0.2))
	P.kind("u_tor", P.torus(0.8, 1.0, 16, 5), P.M("", Color.WHITE, 0.35, 0.4))
	P.kind("u_tor_jelly", P.torus(0.86, 1.0, 18, 5), P.M("", Color.WHITE, 0.6, 0.12, 0.0, 0.75))
	P.kind("u_tor_glow", P.torus(0.88, 1.0, 18, 5), P.M("", Color.WHITE, 1.8, 0.2, 0.0, 0.85))
	P.kind("u_tor_metal", P.torus(0.78, 1.0, 14, 5), P.M("", Color(0.82, 0.82, 0.86), 0.2, 0.2, 0.8))
	P.kind("u_tor_soft", P.torus(0.45, 1.0, 16, 8), P.M("", Color.WHITE, 0.4, 0.8))
	P.kind("u_stick", P.cyl(0.5, 0.5, 1.0, 6, true), P.M("", Color(0.97, 0.96, 0.92), 0.3, 0.7))
	P.kind("u_dark", P.box(Vector3.ONE), P.M("", Color(0.05, 0.05, 0.06), 0.0, 0.15))
	P.kind("u_dark_q", P.quad(Vector2.ONE), P.M("", Color(0.04, 0.04, 0.05), 0.05, 0.12))
	P.kind("u_foil", P.box(Vector3.ONE), P.M("foil", Color.WHITE, 0.45, 0.3, 0.5))
	P.kind("u_stickers", P.quad(Vector2.ONE), P.M("stickers", Color.WHITE, 0.4, 0.5))
	P.kind("u_emoji", P.quad(Vector2.ONE), P.M("emoji", Color.WHITE, 0.4, 0.6))
	P.acc["u_emoji"].mat.set_shader_parameter("scissor", 0.5)     # the round face: its corners are clear
	P.kind("u_blister", P.quad(Vector2.ONE), P.M("blister", Color.WHITE, 0.4, 0.55))
	P.kind("u_bubble", P.box(Vector3.ONE), P.M("", Color(0.92, 0.97, 1.0), 0.2, 0.05, 0.0, 0.3))

## A box with an art face on its front (+z): base names in BOX_ART. Its words: prizes.json art "<box art>".
static func _box_kind(P, art: String) -> String:
	var key := "u_face_" + art
	if not P.acc.has(key):
		var a: Dictionary = P.J.get("art", {}).get(art, {})
		P.kind(key, P.quad(Vector2.ONE), P._art_mat(art, str(a.get("bg", BOX_BG.get(art, art))), 0.4, 0.5))
	return key

## A Blender model as a batched kind: its key, or "" when the model isn't in the project.
static func glb_kind(P, id: String) -> String:
	var key := "glb_" + id
	if P.acc.has(key):
		return key
	var path := "res://models/%s/%s.glb" % [id, id]
	if not ResourceLoader.exists(path):
		return ""
	var sc: Node = load(path).instantiate()
	var mis := sc.find_children("*", "MeshInstance3D", true, false)
	if mis.is_empty():
		sc.free()
		return ""
	var mi: MeshInstance3D = mis[0]
	var xf := Transform3D()
	var n: Node = mi
	while n != sc and n is Node3D:
		xf = (n as Node3D).transform * xf
		n = n.get_parent()
	# the baked material takes the instance colour (a white instance leaves it as it is), so the counter can
	# tint the plush as the claw does (their fur is baked near-white for tinting: _plush.py)
	var mesh: Mesh = mi.mesh.duplicate()
	for i in mesh.get_surface_count():
		var m = mesh.surface_get_material(i)
		if m is BaseMaterial3D and str(m.resource_name).ends_with("_baked"):
			var m2: BaseMaterial3D = m.duplicate()
			m2.vertex_color_use_as_albedo = true
			mesh.surface_set_material(i, m2)
	P.kind(key, mesh, null)
	P.acc[key]["base"] = xf
	sc.free()
	return key

static func glb_add(P, key: String, c: Transform3D, scale := 1.0, tint := Color.WHITE) -> void:
	P.add(key, c * Transform3D(Basis().scaled(Vector3.ONE * scale), Vector3.ZERO) * P.acc[key].get("base", Transform3D()), tint)

static func S(c: Transform3D, p: Vector3, s: Vector3, b := Basis()) -> Transform3D:
	return c * Transform3D(b * Basis().scaled(s), p)

# ------------------------------------------------------------------ one unit
## One unit of a prize at c (bottom centre, +z toward the customer). k picks the colour.
static func unit(P, base: String, c: Transform3D, k: int, rng: RandomNumberGenerator) -> void:
	kinds(P)
	if BLENDER.has(base):
		var gk := glb_kind(P, str(BLENDER[base][0]))
		if gk != "":
			glb_add(P, gk, c, float(BLENDER[base][1]), col(base, k) if TINT.has(base) else Color.WHITE)
			return
	var cl := col(base, k)
	var lie_x := Basis(Vector3(0, 0, 1), PI * 0.5)        # a tube lying along x
	var lie_z := Basis(Vector3(1, 0, 0), PI * 0.5)        # a tube lying along z
	var face_up := Basis(Vector3(1, 0, 0), -PI * 0.5)     # a quad lying face up
	match base:
		"lollipop":
			P.add("u_stick", S(c, Vector3(0, 0.045, 0), Vector3(0.0045, 0.09, 0.0045)))
			P.add("u_ball_s", S(c, Vector3(0, 0.104, 0), Vector3(0.034, 0.034, 0.016)), cl)
		"candy_roll":
			P.add("u_cyl_wrap", S(c, Vector3(0, 0.0085, 0), Vector3(0.017, 0.05, 0.017), lie_x), cl)
		"taffy":
			P.add("u_wrap_box", S(c, Vector3(0, 0.0035, 0), Vector3(0.085, 0.007, 0.028)), cl)
		"powder_straw":
			P.add("u_cyl_stripe", S(c, Vector3(0, 0.004, 0), Vector3(0.008, 0.16, 0.008), lie_z), cl)
		"sour_candy":
			P.add("u_sph", S(c, Vector3(0, 0.008, 0), Vector3(0.018, 0.016, 0.016)), cl)
			for sx in [-1.0, 1.0]:
				P.add("u_box_clear", S(c, Vector3(sx * 0.0125, 0.008, 0), Vector3(0.007, 0.013, 0.004)))
		"candy_ring":
			P.add("u_tor", S(c, Vector3(0, 0.011, 0), Vector3(0.011, 0.011, 0.011) , Basis(Vector3(1, 0, 0), PI * 0.5)), Color("#f0f0f2"))
			P.add("u_sph_jelly", S(c, Vector3(0, 0.026, 0), Vector3(0.017, 0.02, 0.017)), Color(cl, 0.85))
		"spider_ring":
			P.add("u_tor", S(c, Vector3(0, 0.0015, 0), Vector3(0.009, 0.009, 0.009)), cl)
			P.add("u_sph", S(c, Vector3(0, 0.005, 0), Vector3(0.012, 0.007, 0.014)), cl)
			for sx in [-1.0, 1.0]:
				for j in 4:
					var a := -0.75 + j * 0.5
					P.add("u_stick", S(c, Vector3(sx * 0.007, 0.004, sin(a) * 0.007), Vector3(0.0015, 0.013, 0.0015),
						Basis(UP, -a * sx) * Basis(Vector3(0, 0, 1), sx * PI * 0.42)), cl)
		"bounce_ball":
			P.add("u_ball_s", S(c, Vector3(0, 0.012, 0), Vector3.ONE * 0.024, Basis(UP, k * 1.3)), cl)
		"pencil":
			P.add("u_hex_stripe", S(c, Vector3(0, 0.0036, -0.008), Vector3(0.0072, 0.17, 0.0072), lie_z), cl)
			P.add("u_sph", S(c, Vector3(0, 0.006, 0.084), Vector3(0.012, 0.012, 0.014)), col("eraser", k + 1))
		"eraser":
			var e := k % 3
			if e == 0:
				P.add("u_box_soft", S(c, Vector3(0, 0.007, 0), Vector3(0.03, 0.014, 0.02)), cl)
			elif e == 1:
				P.add("u_sph_soft", S(c, Vector3(0, 0.007, 0), Vector3(0.03, 0.014, 0.022)), cl)
			else:
				P.add("u_cyl", S(c, Vector3(0, 0.007, 0), Vector3(0.024, 0.014, 0.024)), cl)
		"stickers":
			P.add("u_stickers", S(c, Vector3(0, 0.0465, 0), Vector3(0.062, 0.093, 1)))
		"sticky_hand":
			P.add("u_sph_jelly", S(c, Vector3(0, 0.003, 0.0), Vector3(0.03, 0.005, 0.034)), Color(cl, 0.8))
			for j in 5:
				var a := -0.62 + j * 0.31
				P.add("u_sph_jelly", S(c, Vector3(sin(a) * 0.024, 0.0025, -cos(a) * 0.024), Vector3(0.007, 0.004, 0.02), Basis(UP, -a)), Color(cl, 0.8))
			P.add("u_sph_jelly", S(c, Vector3(0, 0.0025, 0.028), Vector3(0.006, 0.004, 0.03)), Color(cl, 0.8))
		"jelly_bracelet":
			P.add("u_tor_jelly", S(c, Vector3(0, 0.002, 0), Vector3(0.032, 0.03, 0.032)), Color(cl, 0.75))
		"glow_bracelet":
			P.add("u_tor_glow", S(c, Vector3(0, 0.002, 0), Vector3(0.034, 0.03, 0.034)), Color(cl, 0.9))
			P.add("u_box_metal", S(c, Vector3(0.034, 0.002, 0), Vector3(0.006, 0.004, 0.004)), Color.WHITE)
		"army_men":
			P.add("u_box_clear", S(c, Vector3(0, 0.0525, 0), Vector3(0.075, 0.105, 0.012)))
			for j in 6:
				P.add("u_sph", S(c, Vector3(-0.022 + (j % 3) * 0.022, 0.025 + (j / 3) * 0.03, 0), Vector3(0.008, 0.026, 0.006), Basis(Vector3(0, 0, 1), (j - 2.5) * 0.3)), Color("#4a6a2c"))
			P.add("u_blister", S(c, Vector3(0, 0.094, 0.0065), Vector3(0.075, 0.022, 1)), Color("#d8c89a"))
		"rubber_snake":
			P.add("u_tor_soft", S(c, Vector3(0, 0.0055, 0), Vector3(0.022, 0.011, 0.022)), cl)
			P.add("u_tor_soft", S(c, Vector3(0, 0.0055, 0), Vector3(0.013, 0.008, 0.013)), cl)
			P.add("u_sph_soft", S(c, Vector3(0.0, 0.006, 0.024), Vector3(0.012, 0.009, 0.016)), cl)
		"slammer":
			P.add("u_cyl_metal", S(c, Vector3(0, 0.003, 0), Vector3(0.044, 0.006, 0.044)), cl)
		"troll":
			P.add("u_sph_soft", S(c, Vector3(0, 0.022, 0), Vector3(0.034, 0.044, 0.03)), Color("#f0c8a0"))
			P.add("u_sph_soft", S(c, Vector3(0, 0.052, 0.002), Vector3(0.03, 0.028, 0.028)), Color("#f0c8a0"))
			P.add("u_sph_soft", S(c, Vector3(0, 0.085, 0), Vector3(0.026, 0.06, 0.026)), cl)
			for sx in [-1.0, 1.0]:
				P.add("u_sph", S(c, Vector3(sx * 0.006, 0.056, 0.014), Vector3.ONE * 0.006), Color("#3a7ad0"))
		"paddle_ball":
			P.add("u_cyl", S(c, Vector3(0, 0.13, 0), Vector3(0.1, 0.006, 0.12), Basis(Vector3(1, 0, 0), PI * 0.5)), cl)
			P.add("u_box", S(c, Vector3(0, 0.035, 0), Vector3(0.024, 0.07, 0.006)), cl)
			P.add("u_sph", S(c, Vector3(0.02, 0.17, 0.012), Vector3.ONE * 0.022), Color("#e8283c"))
			P.add("u_blister", S(c, Vector3(0, 0.205, 0.004), Vector3(0.1, 0.02, 1)), Color("#ffd228"))
		"yoyo":
			for sz in [-1.0, 1.0]:
				P.add("u_cyl", S(c, Vector3(0, 0.028, sz * 0.0075), Vector3(0.056, 0.011, 0.056), Basis(Vector3(1, 0, 0), PI * 0.5)), cl)
			P.add("u_cyl", S(c, Vector3(0, 0.028, 0), Vector3(0.012, 0.006, 0.012), Basis(Vector3(1, 0, 0), PI * 0.5)), Color("#e6e6ea"))
		"water_pistol":
			P.add("u_box_jelly", S(c, Vector3(0, 0.011, 0), Vector3(0.05, 0.022, 0.11)), Color(cl, 0.8))
			P.add("u_box_jelly", S(c, Vector3(0, 0.01, 0.07), Vector3(0.022, 0.02, 0.05), Basis(Vector3(1, 0, 0), 0.25)), Color(cl, 0.8))
			P.add("u_cyl_jelly", S(c, Vector3(0, 0.011, -0.07), Vector3(0.012, 0.03, 0.012), lie_z), Color(cl, 0.8))
		"sunglasses":
			P.add("u_box", S(c, Vector3(0, 0.02, 0), Vector3(0.135, 0.04, 0.007)), cl)
			for sx in [-1.0, 1.0]:
				P.add("u_dark", S(c, Vector3(sx * 0.033, 0.02, 0.004), Vector3(0.05, 0.032, 0.002)))
				P.add("u_box", S(c, Vector3(sx * 0.06, 0.008, -0.045), Vector3(0.006, 0.006, 0.09)), cl)
		"mood_ring":
			P.add("u_tor_metal", S(c, Vector3(0, 0.011, 0), Vector3.ONE * 0.011, Basis(Vector3(1, 0, 0), PI * 0.5)))
			P.add("u_sph_jelly", S(c, Vector3(0, 0.024, 0), Vector3(0.012, 0.008, 0.015)), Color(cl, 0.95))
		"toy_car":
			P.add("u_blister", S(c, Vector3(0, 0.065, 0), Vector3(0.09, 0.13, 1)), Color("#3c78dc"))
			var cc := c * Transform3D(Basis(), Vector3(0, 0.05, 0.004))
			P.add("u_box", S(cc, Vector3(0, 0.0, 0.007), Vector3(0.06, 0.022, 0.012)), cl)
			P.add("u_box", S(cc, Vector3(0.004, 0.013, 0.007), Vector3(0.03, 0.014, 0.01)), cl)
			for sx in [-1.0, 1.0]:
				P.add("u_cyl", S(cc, Vector3(sx * 0.02, -0.012, 0.009), Vector3(0.013, 0.006, 0.013), Basis(Vector3(1, 0, 0), PI * 0.5)), Color("#111114"))
			P.add("u_bubble", S(cc, Vector3(0, 0.0, 0.012), Vector3(0.072, 0.05, 0.016)))
		"harmonica":
			P.add("u_box_metal", S(c, Vector3(0, 0.01, 0), Vector3(0.1, 0.02, 0.026)), Color("#c8c8d0"))
			P.add("u_dark", S(c, Vector3(0, 0.01, 0.0131), Vector3(0.092, 0.006, 0.001)))
		"koosh":
			P.add("u_sph_soft", S(c, Vector3(0, 0.032, 0), Vector3.ONE * 0.064), cl)
			for j in 10:
				var d := Vector3(cos(j * 2.4), 0.8 * sin(j * 1.7), sin(j * 2.4)).normalized()
				P.add("u_sph_soft", S(c, Vector3(0, 0.032, 0) + d * 0.026, Vector3.ONE * 0.018), col("koosh", k + j))
		# ---- 2026
		"popper_key":
			P.add("u_box_soft", S(c, Vector3(0, 0.004, 0), Vector3(0.05, 0.008, 0.05)), cl)
			for i in 3:
				for j in 3:
					P.add("u_sph_soft", S(c, Vector3(-0.015 + i * 0.015, 0.008, -0.015 + j * 0.015), Vector3(0.012, 0.007, 0.012)), col("popper_key", k + i + j))
			P.add("u_tor_metal", S(c, Vector3(0, 0.004, -0.032), Vector3.ONE * 0.008))
		"squishy":
			var s := k % 3
			if s == 0:
				P.add("u_sph_soft", S(c, Vector3(0, 0.014, 0), Vector3(0.042, 0.028, 0.036)), cl)
			elif s == 1:
				P.add("u_box_soft", S(c, Vector3(0, 0.012, 0), Vector3(0.04, 0.024, 0.03)), cl)
				P.add("u_sph_soft", S(c, Vector3(0, 0.024, 0), Vector3(0.04, 0.012, 0.03)), Color("#a8642c"))
			else:
				P.add("u_sph_soft", S(c, Vector3(0, 0.016, 0), Vector3(0.036, 0.032, 0.034)), cl)
				for sx in [-1.0, 1.0]:
					P.add("u_sph_soft", S(c, Vector3(sx * 0.012, 0.032, 0), Vector3(0.012, 0.014, 0.01)), cl)
		"light_ring":
			P.add("u_tor", S(c, Vector3(0, 0.011, 0), Vector3.ONE * 0.011, Basis(Vector3(1, 0, 0), PI * 0.5)), Color("#202024"))
			P.add("u_glow_sph", S(c, Vector3(0, 0.026, 0), Vector3(0.018, 0.016, 0.018)), cl)
		"fidget":
			P.add("u_cyl", S(c, Vector3(0, 0.005, 0), Vector3(0.022, 0.01, 0.022)), cl)
			for j in 3:
				var a := TAU * j / 3.0
				P.add("u_cyl", S(c, Vector3(sin(a) * 0.022, 0.005, cos(a) * 0.022), Vector3(0.022, 0.009, 0.022)), cl)
				P.add("u_cyl_metal", S(c, Vector3(sin(a) * 0.022, 0.005, cos(a) * 0.022), Vector3(0.014, 0.01, 0.014)))
		"blind_bag":
			P.add("u_foil", S(c, Vector3(0, 0.0575, 0), Vector3(0.085, 0.115, 0.014)), cl)
		"slime":
			P.add("u_cyl_jelly", S(c, Vector3(0, 0.018, 0), Vector3(0.058, 0.036, 0.058)), Color(cl, 0.85))
			P.add("u_cyl", S(c, Vector3(0, 0.04, 0), Vector3(0.062, 0.009, 0.062)), Color("#f4f4f6"))
		"emoji_key":
			P.add("u_sph_soft", S(c, Vector3(0, 0.022, 0), Vector3(0.044, 0.044, 0.018)), cl)
			P.add("u_emoji", S(c, Vector3(0, 0.022, 0.0092), Vector3(0.04, 0.04, 1)))
			P.add("u_tor_metal", S(c, Vector3(0, 0.05, 0), Vector3.ONE * 0.008, Basis(Vector3(1, 0, 0), PI * 0.5)))
		"dough_ball":
			P.add("u_sph_jelly", S(c, Vector3(0, 0.03, 0), Vector3(0.06, 0.056, 0.06)), Color(cl, 0.92))
		"led_wand":
			P.add("u_cyl", S(c, Vector3(0, 0.011, 0.11), Vector3(0.022, 0.09, 0.022), lie_z), Color("#26262c"))
			P.add("u_glow", S(c, Vector3(0, 0.011, -0.04), Vector3(0.016, 0.22, 0.016), lie_z), cl)
		"popper_board":
			P.add("u_box_soft", S(c, Vector3(0, 0.08, 0), Vector3(0.16, 0.16, 0.012)), cl)
			for i in 5:
				for j in 5:
					P.add("u_sph_soft", S(c, Vector3(-0.056 + i * 0.028, 0.024 + j * 0.028, 0.006), Vector3(0.022, 0.022, 0.012)), col("popper_board", k + i + j))
		"giftcard":
			P.add("u_box", S(c, Vector3(0, 0.0475, 0), Vector3(0.054, 0.086, 0.001)), cl)
			P.add("u_blister", S(c, Vector3(0, 0.0475, -0.002), Vector3(0.06, 0.095, 1)), Color("#f4f4f6"))
		# ---- the bigger prizes (primitive stand-ins where a Blender model isn't built)
		"squish", "squish_big", "jumbo":
			var sc: float = {"squish": 1.0, "squish_big": 1.6, "jumbo": 3.6}[base]
			var pc := col("squishy", k)
			P.add("u_sph_soft", S(c, Vector3(0, 0.1, 0) * sc, Vector3(0.22, 0.2, 0.2) * sc), pc)
			for sx in [-1.0, 1.0]:
				P.add("u_sph_soft", S(c, Vector3(sx * 0.07, 0.19, 0) * sc, Vector3(0.05, 0.05, 0.03) * sc), pc)
				P.add("u_sph", S(c, Vector3(sx * 0.04, 0.12, 0.095) * sc, Vector3(0.018, 0.022, 0.008) * sc), Color("#141416"))
		"capybara":
			P.add("u_sph_soft", S(c, Vector3(0, 0.09, -0.02), Vector3(0.2, 0.17, 0.26)), Color("#a8744a"))
			P.add("u_sph_soft", S(c, Vector3(0, 0.14, 0.1), Vector3(0.12, 0.11, 0.14)), Color("#a8744a"))
			P.add("u_box_soft", S(c, Vector3(0, 0.13, 0.17), Vector3(0.06, 0.04, 0.03)), Color("#6e4a2e"))
			for sx in [-1.0, 1.0]:
				P.add("u_sph", S(c, Vector3(sx * 0.035, 0.17, 0.15), Vector3.ONE * 0.012), Color("#141416"))
				P.add("u_sph_soft", S(c, Vector3(sx * 0.045, 0.2, 0.07), Vector3(0.03, 0.02, 0.02)), Color("#8a5c38"))
		"play_ball":
			P.add("u_ball_s", S(c, Vector3(0, 0.09, 0), Vector3.ONE * 0.18, Basis(UP, k * 0.9)), col("bounce_ball", k))
		"bubbles":
			P.add("u_cyl_jelly", S(c, Vector3(0, 0.05, 0), Vector3(0.04, 0.1, 0.04)), Color(col("bounce_ball", k), 0.7))
			P.add("u_cyl", S(c, Vector3(0, 0.11, 0), Vector3(0.03, 0.025, 0.03)), col("bounce_ball", k + 2))
			P.add("u_tor", S(c, Vector3(0, 0.15, 0), Vector3.ONE * 0.016, Basis(Vector3(1, 0, 0), PI * 0.5)), col("bounce_ball", k + 2))
		"skateboard":
			# flat on its wheels, nose toward -z (as bl_pc_skateboard)
			P.add("u_box", S(c, Vector3(0, 0.075, 0), Vector3(0.19, 0.014, 0.76)), Color("#e8283c"))
			P.add("u_dark", S(c, Vector3(0, 0.083, 0), Vector3(0.18, 0.002, 0.74)))
			for sz in [-0.19, 0.19]:
				P.add("u_box_metal", S(c, Vector3(0, 0.05, sz), Vector3(0.16, 0.022, 0.02)), Color("#c8c8cc"))
				for sx in [-1.0, 1.0]:
					P.add("u_cyl", S(c, Vector3(sx * 0.085, 0.027, sz), Vector3(0.054, 0.032, 0.054), Basis(Vector3(0, 0, 1), PI * 0.5)), Color("#f4f0e0"))
		"plasma":
			P.add("u_cyl", S(c, Vector3(0, 0.05, 0), Vector3(0.12, 0.1, 0.12)), Color("#16161a"))
			P.add("u_glow_sph", S(c, Vector3(0, 0.17, 0), Vector3.ONE * 0.05), Color("#e6a0ff"))
			P.add("u_sph_jelly", S(c, Vector3(0, 0.18, 0), Vector3.ONE * 0.18), Color(0.7, 0.55, 1.0, 0.35))
		"blaster":
			P.add("u_box_jelly", S(c, Vector3(0, 0.09, 0), Vector3(0.06, 0.08, 0.34)), Color(col("water_pistol", k), 0.85))
			P.add("u_cyl_jelly", S(c, Vector3(0, 0.15, -0.02), Vector3(0.07, 0.2, 0.07), Basis(Vector3(1, 0, 0), PI * 0.5)), Color(col("water_pistol", k + 1), 0.85))
			P.add("u_box_jelly", S(c, Vector3(0, 0.03, 0.1), Vector3(0.04, 0.09, 0.05), Basis(Vector3(1, 0, 0), 0.3)), Color(col("water_pistol", k), 0.85))
			P.add("u_box_jelly", S(c, Vector3(0, 0.07, -0.1), Vector3(0.05, 0.03, 0.1)), Color(col("water_pistol", k + 2), 0.85))
		"plush_bear", "plush_bunny", "plush_dog", "big_bear":
			var sc2 := 2.6 if base == "big_bear" else 1.0
			var pcol: Color = {"plush_bunny": Color("#f4f0f0"), "plush_dog": Color("#c8a070")}.get(base, Color("#8c5a32"))
			P.add("u_sph_soft", S(c, Vector3(0, 0.1, 0) * sc2, Vector3(0.18, 0.2, 0.15) * sc2), pcol)
			P.add("u_sph_soft", S(c, Vector3(0, 0.25, 0.01) * sc2, Vector3(0.15, 0.14, 0.13) * sc2), pcol)
		_:
			if BOX_ART.has(base):
				box_unit(P, base, c)
			else:
				push_warning("prize_units: unknown prize '%s'" % base)

## A boxed prize standing on its base, art on the front.
static func box_unit(P, base: String, c: Transform3D, scale := 1.0) -> void:
	var sz: Vector3 = BOX_SIZE.get(base, Vector3(0.1, 0.14, 0.05)) * scale
	var art: String = BOX_ART.get(base, "box_lcd")
	P.add("u_box", S(c, Vector3(0, sz.y * 0.5, 0), sz), Color(0.95, 0.95, 0.96))
	P.add(_box_kind(P, art), S(c, Vector3(0, sz.y * 0.5, sz.z * 0.5 + 0.0008), Vector3(sz.x, sz.y, 1)))

# ------------------------------------------------------------------ filling a bin
## Fills a bin of P's frame fr: span (u from, u to), depth from P.D0 to P.D1, floor at y. Neat: one
## orientation, a grid, colour by column, the layers brick-stacked.
static func fill(P, rng: RandomNumberGenerator, fr: String, span: Vector2, y: float, base: String, bins: SurfaceTool) -> bool:
	if not SPEC.has(base):
		return false
	kinds(P)
	var sp: Dictionary = SPEC[base]
	var d0: float = P.D0
	var d1: float = P.D1
	var w: float = span.y - span.x - 0.02
	match str(sp.mode):
		"grid":
			var pu: float = sp.pu
			var pd: float = sp.pd
			var nu := maxi(1, int(w / pu))
			var nd := maxi(1, int((d1 - d0 - 0.02) / pd))
			var u0: float = (span.x + span.y) * 0.5 - (nu - 1) * pu * 0.5
			var dd0: float = (d0 + d1) * 0.5 - (nd - 1) * pd * 0.5
			for L in int(sp.n):
				var off := 0.5 if L % 2 == 1 else 0.0
				var cu := nu - (1 if off > 0.0 else 0)
				for i in cu:
					for j in nd:
						var b := Basis(UP, rng.randf_range(-0.03, 0.03))
						unit(P, base, P.XF(fr, u0 + (i + off) * pu, y + 0.003 + L * float(sp.dy), dd0 + j * pd, b), i, rng)
		"upright":
			var pu2: float = sp.pu
			var pd2: float = sp.pd
			var nu2 := maxi(1, int(w / pu2))
			var nd2 := maxi(1, int((d1 - d0 - 0.03) / pd2))
			var u02: float = (span.x + span.y) * 0.5 - (nu2 - 1) * pu2 * 0.5
			for j in nd2:
				# back rows a step higher, on a clear riser, so every face shows
				var rise := (nd2 - 1 - j) * 0.012
				var dj: float = d0 + 0.02 + pd2 * 0.5 + j * pd2
				if rise > 0.0:
					P._quad(bins, P.W(fr, span.x + 0.01, y + rise, dj - pd2 * 0.5), P.W(fr, span.y - 0.01, y + rise, dj - pd2 * 0.5), P.W(fr, span.y - 0.01, y + rise, dj + pd2 * 0.5), P.W(fr, span.x + 0.01, y + rise, dj + pd2 * 0.5))
				for i in nu2:
					unit(P, base, P.XF(fr, u02 + i * pu2, y + 0.002 + rise, dj, Basis(UP, rng.randf_range(-0.04, 0.04))), i + j, rng)
		"row":
			var cw: float = float(sp.w) + float(sp.gap)
			var nu3 := maxi(1, int(w / cw))
			var u03: float = (span.x + span.y) * 0.5 - (nu3 - 1) * cw * 0.5
			var pd3: float = sp.pd
			var lean: float = sp.get("lean", 0.18)
			var nd3 := maxi(1, int((d1 - d0 - 0.03) / pd3))
			for j in nd3:
				var dj3: float = d1 - 0.03 - j * pd3        # from the back to the front
				var rise3 := 0.0
				for i in nu3:
					var b3 := Basis(UP, rng.randf_range(-0.03, 0.03)) * Basis(Vector3(1, 0, 0), -lean * (0.0 if sp.has("box") else 1.0))
					unit(P, base, P.XF(fr, u03 + i * cw, y + 0.002 + rise3, dj3, b3), i + j, rng)
	return true
