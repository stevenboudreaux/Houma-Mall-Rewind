## Auntie Anne's (2026 map, store n56: the 4 m stall west of Cell Xpert on the Concourse's south side, the
## 1995 Afterthoughts unit; wing 2). ws/interiors, Nov 4 2026. design/storefronts/auntie-annes.md.
##
## Built from Steven's Oct 23 2026 walkthrough of Southland (IMG_4439 f024-f025: the navy fascia over an
## open counter front, digital menu screens across the top of the opening, white subway tile under a
## band of big orange / navy / cream / violet shapes, a wood-look counter with a white top, the pretzel
## warmer on its left third over a royal-blue front with the pretzel mark, the rolling counter at the
## back, light wood slats on the right wall) and the clip refs/new/auntie_annes (the warmer: steel
## tiers, leaning rows of pretzels, cups of bites in front; Steven: "that's exactly what the pretzels
## look like in the little things"). The warmer is the Blender fixture bl_aa_warmer.
##
## Called from tools/stores/fronts26/store.gd auntie(), whose frame it uses (x 0..LN left to right as
## seen from the hall, d into the store, y up; F.P, F.cbx ...). Not walk-in: a counter stall.
## Materials "in_aa_<key>" (fill_mat), textures tex/aa/ (paint.py).

const K = preload("res://tools/stores/media/kit.gd")
const UP = Vector3.UP
const WARMER = "res://models/bl_aa_warmer/bl_aa_warmer.glb"
const D = 4.6           # the room as far as it shows (the back wall; the rest of the 12 m unit is stock)
const CY = 3.0          # the ceiling, under the fascia
const CT = 1.0          # the counter top

static func build(F, sd):
	var b = F.bb
	var LN = F.LN
	var G = F.G
	var GS = F.GS
	var rx = F.P(1, 0, 0) - F.P(0, 0, 0)
	# ---------------------------------------------------------------- the room
	F.col("#b9b2a6")
	b.quad(G, "vcolor", [F.P(0, 0.003, 0), F.P(LN, 0.003, 0), F.P(LN, 0.003, D), F.P(0, 0.003, D)], UP)
	b.cur_color = Color.WHITE
	var cp = [F.P(0, CY, 0.0), F.P(LN, CY, 0.0), F.P(LN, CY, D), F.P(0, CY, D)]
	var cuv = []
	for p in cp:
		cuv.append(Vector2(p.x / 0.61, p.z / 1.22))
	b.quad(G, "kb_ceiling", cp, Vector3.DOWN, cuv)
	# the back wall and the left wall: subway tile to 2.2 m, the band of shapes over it
	F.front_q(G, "in_aa_subway", 0.0, LN, 0.0, 2.2, D - 0.02, 0.0, -2.2 / 0.6, LN / 0.6, 0.0)
	F.front_q(G, "in_aa_geo", 0.0, LN, 2.2, CY, D - 0.02, 0.0, 0.0, LN / 2.4, 1.0)
	F.side_q(G, "in_aa_subway", 0.03, 0.0, D, 0.0, 2.2, 1.0, 0.0, -2.2 / 0.6, D / 0.6, 0.0)
	F.side_q(G, "in_aa_geo", 0.03, 0.0, D, 2.2, CY, 1.0, 0.3, 0.0, 0.3 + D / 2.4, 1.0)
	# the right wall: light wood slats (f025, the right edge)
	F.col("#e8e2d4")
	F.side_q(G, "vcolor_matte", LN - 0.03, 0.0, D, 0.0, CY, -1.0)
	b.cur_color = Color.WHITE
	var s = 0.15
	while s < D - 0.1:
		F.cbx("#c8a070", LN - 0.07, 0.15, s, 0.04, CY - 0.3, 0.07, GS, "in_aa_oak")
		s += 0.12
	# ---------------------------------------------------------------- the front
	F.band(sd, "#1f2c6a", 3.0, 0.16)
	F.cbx("#1f2c6a", 0.0, 0.0, -0.16, 0.2, 3.0, 0.16)
	F.cbx("#1f2c6a", LN - 0.2, 0.0, -0.16, 0.2, 3.0, 0.16)
	# the header under the fascia: a white strip and the three menu screens across the opening
	F.cbx("#f4f2ee", 0.2, 2.42, -0.02, LN - 0.4, 0.58, 0.32)
	for k in 3:
		var x0 = 0.3 + k * 0.92
		F.cbx("#141416", x0 - 0.02, 2.47, -0.035, 0.88, 0.48, 0.02, GS)
		F.front_q(GS, "in_aa_screens", x0, x0 + 0.84, 2.49, 2.93, -0.036, k / 3.0, 0.0, (k + 1) / 3.0, 1.0, true)
	# the small FRESH ROLLED sign hanging in the opening's right end
	F.cbx("#141416", LN - 0.95, 2.32, 0.1, 0.008, 0.1, 0.008, GS)
	F.front_q(GS, "in_aa_rolling", LN - 1.2, LN - 0.3, 2.12, 2.3, 0.1, 0.0, 0.0, 1.0, 1.0, true)
	# ---------------------------------------------------------------- the counter
	# the right two thirds: wood-look front, white top; the left third: the warmer's royal-blue base
	var wx0 = 0.25
	var wx1 = 1.75
	F.cbx("#f4f2ee", wx0, 0.0, 0.2, LN - 0.45, 0.08, 0.66)
	F.bx(G, "in_aa_oak", wx1, 0.08, 0.2, LN - 0.2 - wx1, CT - 0.12, 0.62)
	F.cbx("#f6f4ee", 0.2, CT - 0.04, 0.12, LN - 0.4, 0.05, 0.76)
	F.cbx("#1f3cbe", wx0, 0.08, 0.2, wx1 - wx0, CT - 0.12, 0.62)
	F.front_q(G, "in_aa_front", wx0 + 0.02, wx1 - 0.02, 0.1, CT - 0.06, 0.195)
	# the warmer on the left third (Blender), the register and a napkin box on the right
	place_glb(b, WARMER, F.P((wx0 + wx1) * 0.5, CT + 0.01, 0.52), rx, F.nn)
	K.register(b, GS, F.P(LN - 0.75, CT + 0.01, 0.75), -rx, F.nn)
	F.cbx("#e8e6e0", LN - 1.55, CT + 0.01, 0.4, 0.22, 0.14, 0.14, GS)
	F.cbx("#1f2c6a", 2.0, CT + 0.01, 0.3, 0.3, 0.22, 0.04, GS)
	# ---------------------------------------------------------------- behind the counter
	# the rolling counter along the back wall: a white top on a steel base, dough on it
	F.cbx("#f2f0ea", 0.15, 0.0, D - 0.75, LN - 1.35, 0.9, 0.7, "", "wl_steel")
	F.cbx("#f4f2ee", 0.12, 0.9, D - 0.78, LN - 1.3, 0.04, 0.74)
	var p0 = F.P(0.2, 0.945, D - 0.73)
	var p1 = F.P(LN - 1.25, 0.945, D - 0.73)
	b.quad(GS, "in_aa_rolltop", [p0, p1, p1 + (F.P(0, 0, 1) - F.P(0, 0, 0)) * 0.6, p0 + (F.P(0, 0, 1) - F.P(0, 0, 0)) * 0.6], UP,
		[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)], true)
	# the pretzel oven on the right at the back (a stainless two-deck oven on a stand)
	F.cbx("#b8babc", LN - 1.15, 0.0, D - 0.95, 0.95, 0.5, 0.9, "", "wl_steel")
	for k in 2:
		var y = 0.5 + k * 0.55
		F.cbx("#b8babc", LN - 1.15, y, D - 0.95, 0.95, 0.53, 0.9, "", "wl_steel")
		F.cbx("#1c1c20", LN - 1.08, y + 0.1, D - 0.96, 0.62, 0.3, 0.01, GS)
		F.cbx("#c8cacc", LN - 1.05, y + 0.44, D - 0.99, 0.56, 0.025, 0.03, GS)
	# a butter-dip station and the lemonade dispenser on the left behind the warmer
	F.cbx("#f2f0ea", 0.15, 0.0, 1.55, 0.9, 0.9, 0.55, "", "wl_steel")
	F.cbx("#f4f2ee", 0.12, 0.9, 1.53, 0.96, 0.04, 0.59)
	# two lemonade dispensers: a white base, a tinted tank, a black tap (Nov 4: were bare blocks)
	for dz in [[0.25, "#e8d050"], [0.6, "#e86a8a"]]:
		F.cbx("#f4f2ee", dz[0], 0.94, 1.65, 0.28, 0.14, 0.28, GS)
		F.cbx(dz[1], dz[0] + 0.02, 1.08, 1.67, 0.24, 0.3, 0.24, GS)
		F.cbx("#f4f2ee", dz[0], 1.38, 1.65, 0.28, 0.04, 0.28, GS)
		F.cbx("#1c1c20", dz[0] + 0.11, 1.0, 1.6, 0.06, 0.07, 0.05, GS)
	F.cbx("#2a2a2c", 0.22, 0.94, 1.62, 0.7, 0.06, 0.34, GS)
	# lights: the opening's downlights and the room
	for x in [0.8, 2.0, 3.2]:
		var l = b.add_spot(F.P(x, 2.38, 0.3), Vector3.DOWN, 0.5, 3.0, 55.0, Color(1.0, 0.95, 0.86))
		b.tag(l, "", 0.45, 0.5)
	var lo = b.add_omni(F.P(LN * 0.5, 2.6, 2.6), 0.5, 4.5, Color(1.0, 0.97, 0.92))
	b.tag(lo, "", 0.45, 0.5)
	F.ob_room(D)

## A Blender fixture (.glb) instanced at c (on its base), its front facing `face` (+Z of the model),
## r its +X; under the mall's BlenderProps node (as wave9.gd's lion).
static func place_glb(b, path, c, r, face):
	if b.mall == null or not ResourceLoader.exists(path):
		return
	var holder = b.mall.get_node_or_null("BlenderProps")
	if holder == null:
		holder = Node3D.new()
		holder.name = "BlenderProps"
		b.mall.add_child(holder)
		holder.owner = b.mall
	var inst = load(path).instantiate()
	inst.name = "%s_%d" % [path.get_file().get_basename(), holder.get_child_count()]
	var z = face.normalized()
	var x = UP.cross(z).normalized()
	inst.transform = Transform3D(Basis(x, UP, z), c)
	holder.add_child(inst)
	inst.owner = b.mall

static func fill_mat(m, key, b):
	match key:
		"subway", "geo", "oak":
			m.albedo_texture = b.tex("aa/%s.png" % key); m.roughness = 0.3 if key == "subway" else 0.6
		"front", "rolltop":
			m.albedo_texture = b.tex("aa/%s.png" % key); m.roughness = 0.45
		"screens", "rolling":
			m.albedo_texture = b.tex("aa/%s.png" % ("screens" if key == "screens" else "sign_rolling"))
			K.emit_tex(m, 0.85 if key == "screens" else 0.3)
		_:
			return false
	return true
