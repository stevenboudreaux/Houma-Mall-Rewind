## Pocket Change's ticket prizes, and a screen for a closer look at them (Steven, Oct 15 2026).
## design/godot-prize-counter.md. Made by player.gd in Wing 2 (and the whole-mall scene).
##
## 1. The prize counter's generic baked prizes (trays, cards, plush, boom boxes, hanging toys) are
##    hidden at runtime by surface overrides on pc*_mach meshes, so nothing in the wing's bake,
##    stand-ins or game files changes. The black trays and card backs share a material with the
##    counter body, so those get a copy of it that cuts away only inside the cases.
## 2. The real prizes are built here from primitives and prizes/*.png, slot by slot from
##    scripts/prizes.json (also the catalogue a ticket-redemption system will read later):
##    acrylic bins with a price card each in the glass cases, and the back wall's hanging aliens
##    and giant fuzzy dice, lava lamps, boom boxes and basketballs.
## 3. Standing at either case, a prompt offers a closer look: the camera glides to an angled view
##    down through the glass at one bay (or at half the back wall); ◀ ▶ walk along the counter,
##    tapping or hovering a prize names it and its price. No redemption yet.
## 4. Every word on a prize (each price card's number, name and TICKETS band, the packaging's
##    printing) is drawn over word-free art at load time (SubViewports → textures), from
##    prizes.json "text"/"art" and the published edits in play/prize_text.json. On the owner's
##    browser the closer look has "Edit words": tap a prize, change its words, font, size and
##    colours in a form (web/shell.html mallPrizeEdit), then "Publish words" writes
##    play/prize_text.json to GitHub with the mall editor's token (mallPrizeText). No rebuild.
extends Node3D

var player: Node3D
var J: Dictionary = {}
const UP := Vector3.UP
const CNT_D := 0.6
const LY := [0.135, 0.41, 0.67]      # deck, lower shelf, upper shelf (top surfaces)
const CLEAR := [0.25, 0.24, 0.2]     # head room above each level
const D0 := 0.06                     # bins: front and back, measured into the case
const D1 := 0.47
## Frames: origin, and f, the way a customer faces it. A = f x UP is the customer's right.
const FR := {
	"A": [Vector3(-104.1, 0, 65.6), Vector3(1, 0, 0), 5.0, 4],     # the long case
	"B": [Vector3(-103.3, 0, 62.5), Vector3(0, 0, 1), 1.6, 1],     # the short case by the door
	"W": [Vector3(-102.6, 0, 65.6), Vector3(1, 0, 0), 5.0, 1],     # the prize wall
}
const HIDE := ["pc_redeem_cards", "pc_redeem_small", "pc_redeem_toys", "pc_redeem_vinyl", "pc_redeem_plush", "pc_redeem_bead"]
# inside the two cases, and the prize wall above its base cabinet (world AABBs: lo, hi)
const CASE_BOXES := [[Vector3(-104.08, 0.137, 63.11), Vector3(-103.52, 0.9, 68.09)],
	[Vector3(-104.09, 0.137, 62.51), Vector3(-102.51, 0.9, 63.09)]]
const WALL_BOXES := [[Vector3(-102.62, 0.84, 63.11), Vector3(-102.08, 2.4, 68.09)]]

var acc := {}          # multimesh key -> {mesh, mat, xf: [], col: []}
var sh_opa: Shader
var sh_tr: Shader
var mats := {}
var font: Font
var items := []        # tooltip anchors: {pos, name, tickets}
var blobs := []        # lava lamp blobs: [node, base (world), phase, speed, rise, r]
var anim_t := 0.0
var built := false

# look mode
var views := []        # {name, pos, tgt}
var looking := false
var view_i := 0
var lcam: Camera3D
var tw: Tween
var ui: CanvasLayer
var prompt: Button
var prompt_key: Label
var bar: Control
var title: Label
var hint: Label
var tip: PanelContainer
var tip_label: Label
var btn_prev: Button
var btn_next: Button
var btn_back: Button
var sel := -1
var saved_vis := []
var touch_start := Vector2.ZERO
var stick_latch := false
var input_kind := "kb"
# words (section 4)
const FONT_FILES := {"sans": "sans.otf", "sans_italic": "sans_italic.otf", "serif": "serif.ttf", "script": "script.ttf"}
const DRAFT_KEY := "southland-prizes-draft"
var pub := {}          # text id -> fields, published (play/prize_text.json)
var draft := {}        # text id -> fields, the owner's unpublished edits
var fonts := {}
var art_mats := {}     # "card:<item>", "pog_card", "candy_box" -> material whose texture carries the words
var painting := false
var paint_again := false
var web := false
var is_owner := false
var edit_on := false
var dialog_open := false
var dialog_item := ""
var publishing := false
var poll_t := 0.0
var btn_edit: Button
var btn_pub: Button
var status_l: Label

func _ready() -> void:
	var p = "res://scripts/prizes.json"
	if FileAccess.file_exists(p):
		J = JSON.parse_string(FileAccess.get_file_as_string(p))
	font = load("res://fonts/sans.otf")
	_shaders()
	_hide_generic()
	_build()
	_views()
	_build_ui()
	built = true
	web = OS.has_feature("web")
	if web:
		var o = JavaScriptBridge.eval("(function(){try{var q=new URLSearchParams(location.search).get('owner');if(q==='1')localStorage.setItem('southland-editor','1');return localStorage.getItem('southland-editor')==='1'?'1':'0'}catch(e){return '0'}})()")
		is_owner = str(o) == "1"
		if is_owner:
			var d = JavaScriptBridge.eval("(function(){try{return localStorage.getItem('" + DRAFT_KEY + "')||''}catch(e){return ''}})()")
			if d is String and d != "":
				var dj = JSON.parse_string(d)
				if dj is Dictionary:
					draft = dj
		_fetch_published()
	_owner_ui()
	paint_words()

# ------------------------------------------------------------------ frames
func W(fr: String, u: float, y: float, d: float) -> Vector3:
	var o: Vector3 = FR[fr][0]
	var f: Vector3 = FR[fr][1]
	return o + f.cross(UP) * u + UP * y + f * d

## Item basis: +x the customer's right, +y up, +z toward the customer.
func IB(fr: String) -> Basis:
	var f: Vector3 = FR[fr][1]
	return Basis(f.cross(UP), UP, -f)

## A transform at slot point (u, y, d) with a local basis (in item axes).
func XF(fr: String, u: float, y: float, d: float, b := Basis()) -> Transform3D:
	return Transform3D(IB(fr) * b, W(fr, u, y, d))

func slot_span(fr: String, bay: int, side: String) -> Vector2:
	var L: float = FR[fr][2]
	var n: int = FR[fr][3]
	var uw := L / n
	var a := -L * 0.5 + bay * uw + 0.0125 + 0.02
	var c := -L * 0.5 + (bay + 1) * uw - 0.0125 - 0.02
	var mid := (a + c) * 0.5
	match side:
		"left": return Vector2(a, mid - 0.008)
		"right": return Vector2(mid + 0.008, c)
	return Vector2(a, c)

# ------------------------------------------------------------------ materials
func _shaders() -> void:
	var lin := "vec3 lin(vec3 c){ return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), c)); }\n"
	sh_opa = Shader.new()
	sh_opa.code = "shader_type spatial;\nrender_mode cull_disabled;\n" \
		+ "uniform sampler2D tex : source_color, filter_linear_mipmap, repeat_enable, hint_default_white;\n" \
		+ "uniform vec4 tint : source_color = vec4(1.0);\nuniform float emit = 0.35;\nuniform float rough = 0.6;\n" \
		+ "uniform float metal = 0.0;\nuniform float scissor = 0.0;\n" + lin \
		+ "void fragment(){ vec4 t = texture(tex, UV); if (scissor > 0.0 && t.a < scissor) discard;\n" \
		+ " vec3 c = t.rgb * tint.rgb * lin(COLOR.rgb); ALBEDO = c; ROUGHNESS = rough; METALLIC = metal; EMISSION = c * emit; }\n"
	sh_tr = Shader.new()
	sh_tr.code = "shader_type spatial;\nrender_mode blend_mix, cull_disabled, depth_draw_never;\n" \
		+ "uniform sampler2D tex : source_color, filter_linear_mipmap, repeat_enable, hint_default_white;\n" \
		+ "uniform vec4 tint : source_color = vec4(1.0);\nuniform float emit = 0.35;\nuniform float rough = 0.1;\n" \
		+ "uniform float alpha = 0.5;\n" + lin \
		+ "void fragment(){ vec4 t = texture(tex, UV); vec3 c = t.rgb * tint.rgb * lin(COLOR.rgb);\n" \
		+ " ALBEDO = c; ROUGHNESS = rough; SPECULAR = 0.8; EMISSION = c * emit; ALPHA = t.a * alpha * COLOR.a; }\n"

## A prize material (cached by its arguments). tex: a file in prizes/, or "".
func M(tex := "", tint := Color.WHITE, emit := 0.35, rough := 0.6, metal := 0.0, alpha := 1.0) -> ShaderMaterial:
	var key := "%s|%s|%.2f|%.2f|%.2f|%.2f" % [tex, tint.to_html(), emit, rough, metal, alpha]
	if mats.has(key):
		return mats[key]
	var m := ShaderMaterial.new()
	m.shader = sh_tr if alpha < 1.0 else sh_opa
	if tex != "":
		m.set_shader_parameter("tex", load("res://prizes/%s.png" % tex))
	m.set_shader_parameter("tint", tint)
	m.set_shader_parameter("emit", emit)
	m.set_shader_parameter("rough", rough)
	if alpha < 1.0:
		m.set_shader_parameter("alpha", alpha)
	else:
		m.set_shader_parameter("metal", metal)
	mats[key] = m
	return m

## Hides the generic baked prizes (see the header).
func _hide_generic() -> void:
	var scn := get_parent()
	if scn == null:
		return
	var gone := ShaderMaterial.new()
	gone.shader = Shader.new()
	gone.shader.code = "shader_type spatial;\nrender_mode unshaded, cull_disabled;\nvoid vertex(){ POSITION = vec4(2.0, 2.0, 2.0, 1.0); }\n"
	for mi in scn.find_children("*pc*_mach", "MeshInstance3D", true, false):
		var dyn: bool = mi.name.begins_with("dyn_")
		var mesh: Mesh = mi.mesh
		if mesh == null:
			continue
		for i in mesh.get_surface_count():
			var m = mesh.surface_get_material(i)
			if m == null:
				continue
			var n: String = m.resource_name
			if n in HIDE or (dyn and n == "pc_redeem_tags"):
				mi.set_surface_override_material(i, gone)
			elif not dyn and n in ["pc_redeem_lam", "pc_redeem_desk"]:
				mi.set_surface_override_material(i, _cut(m, CASE_BOXES))
			elif dyn and (n == "pc_redeem_chrome" or n.begins_with("vcolor")):
				mi.set_surface_override_material(i, _cut(m, WALL_BOXES))

## A copy of a StandardMaterial3D that discards fragments inside the given world boxes.
func _cut(src: Material, boxes: Array) -> Material:
	if not (src is StandardMaterial3D):
		return src
	var s: StandardMaterial3D = src
	var code := "shader_type spatial;\n" \
		+ "uniform sampler2D tex : source_color, filter_linear_mipmap, repeat_enable, hint_default_white;\n" \
		+ "uniform vec4 col : source_color = vec4(1.0);\nuniform float rough = 0.5;\nuniform float metal = 0.0;\n" \
		+ "uniform vec2 uvs = vec2(1.0);\nuniform float vcol = 0.0;\n" \
		+ "uniform vec3 lo0; uniform vec3 hi0; uniform vec3 lo1; uniform vec3 hi1;\nvarying vec3 wp;\n" \
		+ "vec3 lin(vec3 c){ return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), c)); }\n" \
		+ "bool inb(vec3 p, vec3 lo, vec3 hi){ return all(greaterThan(p, lo)) && all(lessThan(p, hi)); }\n" \
		+ "void vertex(){ wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; UV = UV * uvs; }\n" \
		+ "void fragment(){ if (inb(wp, lo0, hi0) || inb(wp, lo1, hi1)) discard;\n" \
		+ " vec3 c = texture(tex, UV).rgb * col.rgb; if (vcol > 0.5) c *= lin(COLOR.rgb);\n" \
		+ " ALBEDO = c; ROUGHNESS = rough; METALLIC = metal; }\n"
	var sh := Shader.new()
	sh.code = code
	var m := ShaderMaterial.new()
	m.shader = sh
	if s.albedo_texture:
		m.set_shader_parameter("tex", s.albedo_texture)
	m.set_shader_parameter("col", s.albedo_color)
	m.set_shader_parameter("rough", s.roughness)
	m.set_shader_parameter("metal", s.metallic)
	m.set_shader_parameter("uvs", Vector2(s.uv1_scale.x, s.uv1_scale.y))
	m.set_shader_parameter("vcol", 1.0 if s.vertex_color_use_as_albedo else 0.0)
	for k in min(2, boxes.size()):
		m.set_shader_parameter("lo%d" % k, boxes[k][0])
		m.set_shader_parameter("hi%d" % k, boxes[k][1])
	if boxes.size() < 2:
		m.set_shader_parameter("lo1", Vector3(1, 1, 1))
		m.set_shader_parameter("hi1", Vector3(-1, -1, -1))
	return m

# ------------------------------------------------------------------ batching
func kind(key: String, mesh: Mesh, mat: Material) -> void:
	if not acc.has(key):
		acc[key] = {"mesh": mesh, "mat": mat, "xf": [], "col": []}

func add(key: String, xf: Transform3D, col := Color.WHITE) -> void:
	acc[key].xf.append(xf)
	acc[key].col.append(col)

func _flush() -> void:
	for key in acc:
		var a = acc[key]
		if a.xf.is_empty():
			continue
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.mesh = a.mesh
		mm.instance_count = a.xf.size()
		for i in a.xf.size():
			mm.set_instance_transform(i, a.xf[i])
			mm.set_instance_color(i, a.col[i])
		var mi := MultiMeshInstance3D.new()
		mi.name = "pz_" + key
		mi.multimesh = mm
		mi.material_override = a.mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.visibility_range_end = 40.0
		add_child(mi)

func cyl(r_top: float, r_bot: float, h: float, seg := 10, caps := true) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = r_top; c.bottom_radius = r_bot; c.height = h
	c.radial_segments = seg; c.rings = 1
	c.cap_top = caps; c.cap_bottom = caps
	return c

func box(sz: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = sz
	return b

func quad(sz: Vector2) -> QuadMesh:
	var q := QuadMesh.new()
	q.size = sz
	return q

func sphere(r: float, seg := 12, rings := 6) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r; s.height = r * 2.0
	s.radial_segments = seg; s.rings = rings
	return s

func torus(ri: float, ro: float, seg := 12, rs := 6) -> TorusMesh:
	var t := TorusMesh.new()
	t.inner_radius = ri; t.outer_radius = ro
	t.rings = seg; t.ring_segments = rs
	return t

# ------------------------------------------------------------------ building
func _build() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1995
	var bins := SurfaceTool.new()
	bins.begin(Mesh.PRIMITIVE_TRIANGLES)
	_kinds()
	var cat: Dictionary = J.get("items", {})
	var si := 0
	for s in J.get("case", []):
		var fr: String = s[0]
		var bay := int(s[1])
		var lv := int(s[2])
		var span := slot_span(fr, bay, s[3])
		var it: String = s[4]
		rng.seed = 1995 + si * 31
		si += 1
		var y: float = LY[lv]
		_bin(bins, fr, span, y)
		var tk := int(cat.get(it, {}).get("tickets", 0))
		_card(fr, (span.x + span.y) * 0.5, y, it)
		match it:
			"finger_trap": _traps(rng, fr, span, y, false)
			"jelly_trap": _traps(rng, fr, span, y, true)
			"chew": _chews(rng, fr, span, y)
			"candy_cig": _candy_boxes(rng, fr, span, y)
			"candy_neck": _necklaces(rng, fr, span, y)
			"slap": _slaps(rng, fr, span, y)
			"pogs": _pogs(rng, fr, span, y, bins)
			"spring": _springs(rng, fr, span, y, lv)
			"dice": _dice(rng, fr, span, y)
			"vpet": _vpets(rng, fr, span, y, bins)
		items.append({"pos": W(fr, (span.x + span.y) * 0.5, y + 0.05, (D0 + D1) * 0.5),
			"name": str(cat.get(it, {}).get("name", it)), "tickets": tk, "key": it})
	_wall(rng, cat)
	var bm := MeshInstance3D.new()
	bm.name = "pz_bins"
	bins.generate_normals()
	bm.mesh = bins.commit()
	bm.material_override = M("", Color(0.86, 0.94, 1.0), 0.15, 0.05, 0.0, 0.22)
	bm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	bm.visibility_range_end = 40.0
	add_child(bm)
	_flush()

func _kinds() -> void:
	kind("trap", cyl(0.008, 0.008, 0.13, 8, true), M("weave", Color.WHITE, 0.35, 0.8))
	kind("jelly", cyl(0.0085, 0.0085, 0.115, 8, true), M("", Color.WHITE, 0.6, 0.12, 0.0, 0.8))
	kind("chew", cyl(0.0075, 0.0075, 0.036, 8, true), M("chew", Color.WHITE, 0.35, 0.5))
	kind("cbox", box(Vector3(0.05, 0.075, 0.014)), M("", Color(0.97, 0.96, 0.94), 0.35, 0.6))
	kind("cface", quad(Vector2(0.05, 0.075)), _art_mat("candy_box", "candy_box", 0.35, 0.55))
	kind("neck", _necklace_mesh(), M("", Color.WHITE, 0.35, 0.35))
	for i in 4:
		kind("slap%d" % i, quad(Vector2(0.22, 0.026)), M("slap%d" % i, Color.WHITE, 0.35, 0.3, 0.2))
	kind("pogcard", quad(Vector2(0.09, 0.135)), _art_mat("pog_card", "pog_card", 0.35, 0.5))
	kind("bubble", box(Vector3(0.072, 0.086, 0.012)), M("", Color(0.92, 0.97, 1.0), 0.2, 0.05, 0.0, 0.28))
	kind("cap", cyl(0.021, 0.021, 0.003, 14, true), M("", Color.WHITE, 0.35, 0.5))
	kind("spring", _tube(0.034, 0.06, 18), M("rainbow", Color.WHITE, 0.45, 0.35, 0.3))
	kind("ring", torus(0.03, 0.036, 18, 4), M("", Color.WHITE, 0.45, 0.35, 0.3))
	kind("die", box(Vector3(0.05, 0.05, 0.05)), M("die", Color.WHITE, 0.3, 1.0))
	kind("cord", cyl(0.0018, 0.0018, 1.0, 4, false), M("", Color.WHITE, 0.3, 0.9))
	kind("egg", sphere(0.5, 16, 8), M("", Color.WHITE, 0.35, 0.28))
	kind("lcd", quad(Vector2(0.024, 0.021)), M("vpet_screen", Color.WHITE, 0.45, 0.2))
	kind("btn", sphere(0.0036, 8, 4), M("", Color.WHITE, 0.3, 0.3))
	# the wall
	kind("hook", cyl(0.003, 0.003, 1.0, 5, false), M("", Color(0.82, 0.82, 0.86), 0.1, 0.2, 0.8))
	kind("green", sphere(0.5, 16, 8), M("", Color.WHITE, 0.6, 1.0))
	kind("limb", _capsule(), M("", Color.WHITE, 0.6, 1.0))
	kind("eye", sphere(0.5, 12, 6), M("", Color(0.03, 0.03, 0.04), 0.0, 0.08))
	kind("loop", torus(0.008, 0.012, 10, 4), M("", Color(0.9, 0.9, 0.9), 0.2, 0.8))
	kind("bigdie", box(Vector3(0.14, 0.14, 0.14)), M("die", Color.WHITE, 0.5, 1.0))
	kind("lamp_metal", cyl(0.5, 0.5, 1.0, 16, true), M("", Color.WHITE, 0.35, 0.3, 0.45))
	kind("lamp_glass", cyl(0.034, 0.056, 0.22, 18, true), M("", Color.WHITE, 1.1, 0.08, 0.0, 0.62))
	kind("ubox", box(Vector3(1, 1, 1)), M("", Color.WHITE, 0.5, 0.45))
	kind("speaker", cyl(0.5, 0.5, 1.0, 16, true), M("", Color(0.08, 0.08, 0.09), 0.1, 0.9))
	kind("chrome", cyl(0.5, 0.5, 1.0, 8, true), M("", Color(0.82, 0.82, 0.86), 0.15, 0.2, 0.8))
	kind("ball", sphere(0.12, 20, 10), M("ball", Color.WHITE, 0.5, 0.75))

## An open tube, height h along y, its UV running once round (u) and once up (v).
func _tube(r: float, h: float, seg: int) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in seg:
		var a0 := TAU * k / seg
		var a1 := TAU * (k + 1) / seg
		var n0 := Vector3(cos(a0), 0, sin(a0)); var n1 := Vector3(cos(a1), 0, sin(a1))
		var q := [[n0, float(k) / seg, -0.5], [n1, float(k + 1) / seg, -0.5], [n1, float(k + 1) / seg, 0.5],
			[n0, float(k) / seg, -0.5], [n1, float(k + 1) / seg, 0.5], [n0, float(k) / seg, 0.5]]
		for v in q:
			st.set_normal(v[0]); st.set_uv(Vector2(v[1], 0.5 - v[2]))
			st.add_vertex(v[0] * r + Vector3(0, v[2] * h, 0))
	return st.commit()

func _capsule() -> CapsuleMesh:
	var c := CapsuleMesh.new()
	c.radius = 0.5; c.height = 2.0
	c.radial_segments = 10; c.rings = 4
	return c

## One candy necklace: 22 pastel beads round a 4.5 cm ring, as one mesh.
func _necklace_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var cols := [Color("#f6b4c8"), Color("#bfe6f8"), Color("#fff1a8"), Color("#c8f2c0"), Color("#e4c8f6"), Color("#ffd2a8")]
	var n := 22
	var bead := sphere(0.0068, 7, 4)
	var arr := bead.get_mesh_arrays()
	var V: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var N: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var I: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	for k in n:
		var a := TAU * k / n
		var c := Vector3(cos(a) * 0.045, 0.0068, sin(a) * 0.045)
		st.set_color(cols[k % cols.size()])
		for ii in I:
			st.set_normal(N[ii])
			st.add_vertex(V[ii] * Vector3(1, 0.8, 1) + c)
	return st.commit()

## An open acrylic bin over the slot: floor and four walls 4.5 cm high.
func _bin(st: SurfaceTool, fr: String, span: Vector2, y: float) -> void:
	var h := 0.045
	var u0 := span.x; var u1 := span.y
	var y0 := y + 0.002; var y1 := y + h
	var P := func(u, yy, d): return W(fr, u, yy, d)
	_quad(st, P.call(u0, y0, D0), P.call(u1, y0, D0), P.call(u1, y1, D0), P.call(u0, y1, D0))
	_quad(st, P.call(u0, y0, D1), P.call(u1, y0, D1), P.call(u1, y1, D1), P.call(u0, y1, D1))
	_quad(st, P.call(u0, y0, D0), P.call(u0, y0, D1), P.call(u0, y1, D1), P.call(u0, y1, D0))
	_quad(st, P.call(u1, y0, D0), P.call(u1, y0, D1), P.call(u1, y1, D1), P.call(u1, y1, D0))

func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	for v in [a, b, c, a, c, d]:
		st.set_uv(Vector2.ZERO)
		st.add_vertex(v)

## A price card standing on the bin's front lip, leaning back: the number, the prize's name,
## the TICKETS band (one picture per item, painted by paint_words).
func _card(fr: String, u: float, y: float, it: String) -> void:
	var lean := Basis(Vector3(1, 0, 0), -0.28)
	_card_at(XF(fr, u, y + 0.055, D0 - 0.006, lean), it, 1.0)

func _card_at(c: Transform3D, it: String, size: float) -> void:
	var key := "card_" + it
	if not acc.has(key):
		kind(key, quad(Vector2(0.07, 0.0558)), _art_mat("card:" + it, "tag", 0.6, 0.6))
	add(key, c * Transform3D(Basis().scaled(Vector3.ONE * size), Vector3.ZERO))

# ---- the case prizes. Each fills the bin [span] x [D0, D1] at height y.
func _rand_in(rng: RandomNumberGenerator, span: Vector2, m: float) -> Vector2:
	return Vector2(rng.randf_range(span.x + m, span.y - m), rng.randf_range(D0 + m, D1 - m))

func _traps(rng: RandomNumberGenerator, fr: String, span: Vector2, y: float, jelly: bool) -> void:
	var area := (span.y - span.x) * (D1 - D0)
	var n := int(area * 260.0)
	var cols := [Color("#ff3c96"), Color("#3cdcff"), Color("#9cff3c"), Color("#ffdc28"), Color("#b45aff"), Color("#ff7a1e")] if jelly \
		else [Color("#d8c08a"), Color("#c8343c"), Color("#2f7fd0"), Color("#3aa04a"), Color("#e8c020"), Color("#e070b0"), Color("#f2efe4")]
	for i in n:
		var p := _rand_in(rng, span, 0.07)
		var layer := float(i) / n * 2.2
		var b := Basis(UP, rng.randf() * TAU) * Basis(Vector3(0, 0, 1), PI * 0.5 + rng.randf_range(-0.25, 0.25))
		var c: Color = cols[rng.randi() % cols.size()]
		if jelly:
			c.a = 0.78
		add("jelly" if jelly else "trap", XF(fr, p.x, y + 0.01 + layer * 0.014 + rng.randf() * 0.004, p.y, b), c)

func _chews(rng: RandomNumberGenerator, fr: String, span: Vector2, y: float) -> void:
	var area := (span.y - span.x) * (D1 - D0)
	var n := int(area * 900.0)
	for i in n:
		var p := _rand_in(rng, span, 0.025)
		var layer := float(i) / n * 2.6
		var b := Basis(UP, rng.randf() * TAU) * Basis(Vector3(0, 0, 1), PI * 0.5 + rng.randf_range(-0.3, 0.3))
		add("chew", XF(fr, p.x, y + 0.009 + layer * 0.013 + rng.randf() * 0.003, p.y, b))

func _candy_boxes(rng: RandomNumberGenerator, fr: String, span: Vector2, y: float) -> void:
	var w := 0.056
	var cols := int((span.y - span.x - 0.02) / w)
	var u0 := (span.x + span.y) * 0.5 - (cols - 1) * w * 0.5
	var d := D0 + 0.05
	while d < D1 - 0.02:
		for k in cols:
			var lean := rng.randf_range(0.04, 0.14)
			var b := Basis(UP, rng.randf_range(-0.06, 0.06)) * Basis(Vector3(1, 0, 0), -lean)
			var c := XF(fr, u0 + k * w, y + 0.002, d, b) * Transform3D(Basis(), Vector3(0, 0.0375, 0))
			add("cbox", c)
			add("cface", c * Transform3D(Basis(), Vector3(0, 0, 0.0072)))
		d += 0.075

func _necklaces(rng: RandomNumberGenerator, fr: String, span: Vector2, y: float) -> void:
	var area := (span.y - span.x) * (D1 - D0)
	var n := int(area * 90.0)
	for i in n:
		var p := _rand_in(rng, span, 0.055)
		var b := Basis(UP, rng.randf() * TAU) * Basis(Vector3(1, 0, 0), rng.randf_range(-0.25, 0.25)) \
			* Basis(Vector3(0, 0, 1), rng.randf_range(-0.25, 0.25))
		add("neck", XF(fr, p.x, y + 0.004 + float(i) / n * 0.03, p.y, b.scaled(Vector3.ONE * rng.randf_range(0.9, 1.08))))

func _slaps(rng: RandomNumberGenerator, fr: String, span: Vector2, y: float) -> void:
	var w := span.y - span.x
	var rows := 14
	for i in rows:
		var t := (i + 0.5) / rows
		var d: float = lerp(D0 + 0.03, D1 - 0.03, t)
		var u: float = (span.x + span.y) * 0.5 + rng.randf_range(-0.05, 0.05) * w
		var b := Basis(UP, rng.randf_range(-0.35, 0.35)) * Basis(Vector3(1, 0, 0), -PI * 0.5)
		add("slap%d" % (rng.randi() % 4), XF(fr, u, y + 0.004 + i * 0.0018, d, b))
		if w > 0.4:
			add("slap%d" % (rng.randi() % 4), XF(fr, u + rng.randf_range(-0.12, 0.12), y + 0.006 + i * 0.0018, d + 0.01, b))

func _pogs(rng: RandomNumberGenerator, fr: String, span: Vector2, y: float, bins: SurfaceTool) -> void:
	var full := span.y - span.x > 0.8
	var rows := [0.32, 0.17] if full else [0.36]
	for ri in rows.size():
		var d: float = rows[ri]
		var rise := 0.07 if (full and ri == 0) else 0.0
		if rise > 0.0:
			# a clear riser for the back row
			var a := W(fr, span.x + 0.01, y + rise, d - 0.06)
			_quad(bins, W(fr, span.x + 0.01, y + rise, d - 0.06), W(fr, span.y - 0.01, y + rise, d - 0.06), W(fr, span.y - 0.01, y + rise, d + 0.06), W(fr, span.x + 0.01, y + rise, d + 0.06))
			_quad(bins, W(fr, span.x + 0.01, y, d - 0.06), W(fr, span.y - 0.01, y, d - 0.06), W(fr, span.y - 0.01, y + rise, d - 0.06), a)
		var n := int((span.y - span.x - 0.02) / 0.105)
		var u0 := (span.x + span.y) * 0.5 - (n - 1) * 0.105 * 0.5
		for k in n:
			var b := Basis(UP, rng.randf_range(-0.05, 0.05)) * Basis(Vector3(1, 0, 0), -0.2)
			var c := XF(fr, u0 + k * 0.105, y + rise + 0.002, d, b) * Transform3D(Basis(), Vector3(0, 0.0675, 0))
			add("pogcard", c)
			add("bubble", c * Transform3D(Basis(), Vector3(0, -0.01, 0.0065)))
	if not full:
		# loose caps and a slammer or two heaped in front
		var cols := [Color("#e63c28"), Color("#28aa46"), Color("#fac828"), Color("#8c32b4"), Color("#1e8cdc"), Color("#f2f0e6")]
		var sp := Vector2(span.x, span.y)
		for i in 46:
			var p := Vector2(rng.randf_range(sp.x + 0.03, sp.y - 0.03), rng.randf_range(D0 + 0.03, 0.26))
			var b := Basis(UP, rng.randf() * TAU) * Basis(Vector3(1, 0, 0), rng.randf_range(-0.3, 0.3))
			var c: Color = cols[rng.randi() % cols.size()] if i % 9 != 0 else Color("#4a4a52")
			add("cap", XF(fr, p.x, y + 0.004 + float(i) / 46.0 * 0.02, p.y, b), c)

func _springs(rng: RandomNumberGenerator, fr: String, span: Vector2, y: float, lv: int) -> void:
	var s := 0.077
	var cols := int((span.y - span.x - 0.01) / s)
	var rows := int((D1 - D0 - 0.01) / s)
	var u0 := (span.x + span.y) * 0.5 - (cols - 1) * s * 0.5
	var stack := 2 if lv == 0 else 1
	for r in rows:
		for k in cols:
			for h in stack:
				var b := Basis(UP, rng.randf() * TAU) * Basis(Vector3(1, 0, 0), rng.randf_range(-0.05, 0.05))
				var c := XF(fr, u0 + k * s, y + 0.002 + h * 0.061, D0 + s * 0.5 + 0.005 + r * s, b) * Transform3D(Basis(), Vector3(0, 0.03, 0))
				add("spring", c)
				add("ring", c * Transform3D(Basis(), Vector3(0, 0.029, 0)), Color("#e62828"))
				add("ring", c * Transform3D(Basis(), Vector3(0, -0.029, 0)), Color("#8232be"))

func _dice(rng: RandomNumberGenerator, fr: String, span: Vector2, y: float) -> void:
	var cols := [Color.WHITE, Color("#ffb4d2"), Color("#ff6464"), Color("#a8d8ff"), Color("#fff08a")]
	var area := (span.y - span.x) * (D1 - D0)
	var n := int(area * 42.0)
	var placed := []
	var tries := 0
	while placed.size() < n and tries < 400:
		tries += 1
		var p := _rand_in(rng, span, 0.075)
		var ok := true
		for q in placed:
			if p.distance_to(q) < 0.13:
				ok = false
		if not ok:
			continue
		placed.append(p)
		var c: Color = cols[rng.randi() % cols.size()]
		var yaw := rng.randf() * TAU
		var ax := Vector2(cos(yaw), sin(yaw)) * 0.032
		var top := []
		for sgn in [-1.0, 1.0]:
			var b := Basis(UP, yaw + rng.randf_range(-0.4, 0.4)) * Basis(Vector3(1, 0, 0), [0.0, PI * 0.5, PI][rng.randi() % 3])
			var q := XF(fr, p.x + ax.x * sgn, y + 0.027, p.y + ax.y * sgn, b)
			add("die", q, c)
			top.append(q.origin + UP * 0.026)
		var mid: Vector3 = (top[0] + top[1]) * 0.5 + UP * 0.02
		for e in [top[0], top[1]]:
			add("cord", _rod(e, mid, 1.0))

## A unit cylinder (height 1, along y) stretched from a to b, radius scaled by rs.
func _rod(a: Vector3, b: Vector3, rs: float) -> Transform3D:
	var dvec := b - a
	var L := dvec.length()
	var yv: Vector3 = dvec / maxf(L, 0.0001)
	var xv := yv.cross(Vector3(0, 0, 1))
	if xv.length() < 0.1:
		xv = yv.cross(Vector3(1, 0, 0))
	xv = xv.normalized()
	var zv := xv.cross(yv)
	return Transform3D(Basis(xv * rs, yv * L, zv * rs), (a + b) * 0.5)

func _vpets(rng: RandomNumberGenerator, fr: String, span: Vector2, y: float, bins: SurfaceTool) -> void:
	var cols := [Color("#ff8cc0"), Color("#8cd2ff"), Color("#f4f4f0"), Color("#ffe060"), Color("#b48cff"), Color("#78dc8c"), Color("#ff5a5a"), Color("#3a3a44")]
	var rows := [[0.33, 0.06], [0.16, 0.0]]
	var s := 0.088
	for row in rows:
		var d: float = row[0]
		var rise: float = row[1]
		if rise > 0.0:
			_quad(bins, W(fr, span.x + 0.01, y + rise, d - 0.06), W(fr, span.y - 0.01, y + rise, d - 0.06), W(fr, span.y - 0.01, y + rise, d + 0.06), W(fr, span.x + 0.01, y + rise, d + 0.06))
			_quad(bins, W(fr, span.x + 0.01, y, d - 0.06), W(fr, span.y - 0.01, y, d - 0.06), W(fr, span.y - 0.01, y + rise, d - 0.06), W(fr, span.x + 0.01, y + rise, d - 0.06))
		var n := int((span.y - span.x - 0.02) / s)
		var u0 := (span.x + span.y) * 0.5 - (n - 1) * s * 0.5
		for k in n:
			var b := Basis(UP, rng.randf_range(-0.12, 0.12)) * Basis(Vector3(1, 0, 0), -0.22)
			var c := XF(fr, u0 + k * s, y + rise + 0.003, d, b) * Transform3D(Basis(), Vector3(0, 0.03, 0))
			var col: Color = cols[(k + int(d * 100)) % cols.size()]
			add("egg", c * Transform3D(Basis().scaled(Vector3(0.05, 0.058, 0.024)), Vector3.ZERO), col)
			add("lcd", c * Transform3D(Basis(), Vector3(0, 0.005, 0.0122)))
			for bx in [-0.009, 0.0, 0.009]:
				add("btn", c * Transform3D(Basis(), Vector3(bx, -0.0135 - (0.003 if bx == 0.0 else 0.0), 0.0105)), Color("#d8d8d8") if col != Color("#3a3a44") else Color("#ff8cc0"))
			add("loop", c * Transform3D(Basis(Vector3(1, 0, 0), PI * 0.5), Vector3(0, 0.034, 0)), Color("#c8c8cc"))

# ---- the prize wall
func _wall(rng: RandomNumberGenerator, cat: Dictionary) -> void:
	var yh := 2.34
	# base cabinet top (y 0.83): boom boxes, basketballs, big sitting aliens
	for e in [[-2.05, "boombox"], [-1.45, "ball"], [-0.85, "alien"], [-0.2, "boombox"], [0.45, "ball"], [1.05, "alien"], [1.75, "boombox"]]:
		_wall_item(rng, cat, e[1], e[0], 0.83, 0.03, 0.43, 0.42)
	# shelf a (y 1.30, from 0.14 to 0.43 deep)
	for e in [[-2.0, "big_dice"], [-1.3, "alien"], [-0.6, "big_dice"], [0.1, "alien"], [0.8, "big_dice"], [1.5, "alien"], [2.12, "ball"]]:
		_wall_item(rng, cat, e[1], e[0], 1.30, 0.14, 0.43, 0.32)
	# shelf b (y 1.74, from 0.23 deep): lava lamps, behind the hanging things
	for u in [-1.9, -0.65, 0.65, 1.9]:
		_wall_item(rng, cat, "lava", u, 1.74, 0.23, 0.43, 0.42)
	# hooks along the top: aliens and giant fuzzy dice
	var hangs := [[-2.35, "alien"], [-1.28, "big_dice"], [0.0, "alien"], [1.28, "big_dice"], [2.35, "alien"]]
	for e in hangs:
		var u: float = e[0]
		add("hook", _rod(W("W", u, yh, 0.43), W("W", u, yh, 0.09), 1.0))
		add("hook", _rod(W("W", u, yh, 0.09), W("W", u, yh + 0.03, 0.075), 1.0))
		var hp := W("W", u, yh - 0.004, 0.1)
		var nm: String = e[1]
		if nm == "alien":
			var h := rng.randf_range(0.44, 0.5)
			add("loop", Transform3D(IB("W"), hp + Vector3(0, -0.012, 0)), Color("#e8e8e8"))
			_alien(Transform3D(IB("W"), hp + Vector3(0, -0.024 - h, 0)), h, true, rng)
			_wall_tag(Transform3D(IB("W"), W("W", u + 0.14, yh - 0.12, 0.07)), cat, "alien", hp + Vector3(0, -0.25, 0))
		else:
			var col: Color = [Color.WHITE, Color("#ffb4d2")][rng.randi() % 2]
			var p1 := hp + Vector3(0, -0.13, 0) + IB("W").x * -0.05
			var p2 := hp + Vector3(0, -0.2, 0) + IB("W").x * 0.06
			for p in [p1, p2]:
				add("cord", _rod(hp, p + Vector3(0, 0.07, 0), 1.0))
				add("bigdie", Transform3D(IB("W") * Basis(UP, rng.randf_range(-0.5, 0.5)) * Basis(Vector3(1, 0, 0), rng.randf_range(-0.2, 0.2)), p), col)
			_wall_tag(Transform3D(IB("W"), W("W", u + 0.15, yh - 0.12, 0.07)), cat, "big_dice", hp + Vector3(0, -0.17, 0))

## One wall prize standing at (u, y), between depths zf and zb, with its tag on the shelf edge.
func _wall_item(rng: RandomNumberGenerator, cat: Dictionary, it: String, u: float, y: float, zf: float, zb: float, maxh: float) -> void:
	var mid := (zf + zb) * 0.5
	var anchor := W("W", u, y + 0.15, mid)
	match it:
		"boombox":
			_boombox(XF("W", u, y, mid + 0.02, Basis(UP, rng.randf_range(-0.1, 0.1))))
			anchor = W("W", u, y + 0.13, mid)
		"ball":
			add("ball", XF("W", u, y + 0.12, zb - 0.14, Basis(UP, rng.randf() * TAU)))
			anchor = W("W", u, y + 0.12, zb - 0.14)
		"alien":
			var h := maxh * rng.randf_range(0.88, 1.0)
			_alien(XF("W", u, y, zb - 0.18, Basis(UP, rng.randf_range(-0.25, 0.25))), h, false, rng)
			anchor = W("W", u, y + h * 0.6, zb - 0.18)
		"big_dice":
			var col: Color = [Color.WHITE, Color("#ffb4d2"), Color("#ff6464")][rng.randi() % 3]
			add("bigdie", XF("W", u - 0.075, y + 0.07, mid, Basis(UP, rng.randf_range(-0.3, 0.3))), col)
			add("bigdie", XF("W", u + 0.08, y + 0.07, mid + 0.02, Basis(UP, rng.randf_range(0.3, 0.8)) * Basis(Vector3(1, 0, 0), PI * 0.5)), col)
			anchor = W("W", u, y + 0.08, mid)
		"lava":
			_lava(rng, XF("W", u, y, mid + 0.02))
			anchor = W("W", u, y + 0.22, mid)
	var tagz := zf - 0.008
	_wall_tag(XF("W", u, y - 0.036, tagz), cat, it, anchor)

func _wall_tag(c: Transform3D, cat: Dictionary, it: String, anchor: Vector3) -> void:
	var tk := int(cat.get(it, {}).get("tickets", 0))
	_card_at(c, it, 1.6)
	items.append({"pos": anchor, "name": str(cat.get(it, {}).get("name", it)), "tickets": tk, "key": it})

## A green alien plush, height h; c at its bottom centre (or, hanging, at the bottom of the
## dangling legs), +z its front.
func _alien(c: Transform3D, h: float, hanging: bool, rng: RandomNumberGenerator) -> void:
	var g := Color("#6ccf3c").lerp(Color("#9be65a"), rng.randf() * 0.4)
	var S := func(p: Vector3, s: Vector3, b: Basis) -> Transform3D:
		return c * Transform3D(b * Basis().scaled(s), p)
	# head: wide at the brow, a pointed chin
	add("green", S.call(Vector3(0, 0.74 * h, 0), Vector3(0.44, 0.36, 0.36) * h, Basis()), g)
	add("green", S.call(Vector3(0, 0.62 * h, 0.01 * h), Vector3(0.24, 0.2, 0.24) * h, Basis()), g)
	# eyes: big black almonds, tilted up and out
	for sx in [-1.0, 1.0]:
		add("eye", S.call(Vector3(sx * 0.095 * h, 0.735 * h, 0.15 * h), Vector3(0.1, 0.16, 0.05) * h,
			Basis(Vector3(0, 0, 1), sx * 0.75) * Basis(UP, sx * 0.35)))
	# body
	add("limb", S.call(Vector3(0, 0.3 * h, 0), Vector3(0.16, 0.17, 0.13) * h, Basis()), g)
	# arms: thin, hanging down by the sides
	for sx in [-1.0, 1.0]:
		add("limb", S.call(Vector3(sx * 0.12 * h, 0.3 * h, 0.01 * h), Vector3(0.036, 0.13, 0.036) * h, Basis(Vector3(0, 0, 1), sx * 0.25)), g)
	# legs: sitting, they stick out in front; hanging, they dangle
	for sx in [-1.0, 1.0]:
		if hanging:
			add("limb", S.call(Vector3(sx * 0.06 * h, 0.1 * h, 0), Vector3(0.042, 0.12, 0.042) * h, Basis(Vector3(0, 0, 1), sx * 0.08)), g)
		else:
			add("limb", S.call(Vector3(sx * 0.07 * h, 0.075 * h, 0.1 * h), Vector3(0.05, 0.12, 0.05) * h, Basis(Vector3(1, 0, 0), PI * 0.5) * Basis(Vector3(0, 0, 1), sx * 0.15)), g)

func _boombox(c: Transform3D) -> void:
	var w := 0.46; var h := 0.24; var dz := 0.12
	add("ubox", c * Transform3D(Basis().scaled(Vector3(w, h, dz)), Vector3(0, h * 0.5, 0)), Color("#45454c"))
	add("ubox", c * Transform3D(Basis().scaled(Vector3(w - 0.02, 0.035, 0.004)), Vector3(0, h - 0.03, dz * 0.5)), Color("#b8b8c0"))
	for sx in [-1.0, 1.0]:
		var sp := c * Transform3D(Basis(Vector3(1, 0, 0), PI * 0.5).scaled(Vector3(0.15, 0.012, 0.15)), Vector3(sx * 0.14, 0.1, dz * 0.5 + 0.002))
		add("speaker", sp)
		add("ring", c * Transform3D(Basis(Vector3(1, 0, 0), PI * 0.5).scaled(Vector3(2.2, 1, 2.2)), Vector3(sx * 0.14, 0.1, dz * 0.5 + 0.006)), Color("#c8c8d0"))
	add("ubox", c * Transform3D(Basis().scaled(Vector3(0.11, 0.065, 0.004)), Vector3(0, 0.11, dz * 0.5)), Color("#3c5064"))
	add("ubox", c * Transform3D(Basis().scaled(Vector3(0.1, 0.02, 0.006)), Vector3(0, 0.045, dz * 0.5)), Color("#808088"))
	# handle and an aerial
	var tl := c * Vector3(-0.15, h, 0); var tr := c * Vector3(0.15, h, 0)
	var hl := c * Vector3(-0.14, h + 0.055, 0); var hr := c * Vector3(0.14, h + 0.055, 0)
	add("chrome", _rod(tl, hl, 0.016)); add("chrome", _rod(tr, hr, 0.016)); add("chrome", _rod(hl, hr, 0.016))
	add("chrome", _rod(c * Vector3(0.2, h, -0.03), c * Vector3(0.12, h + 0.32, -0.05), 0.005))

func _lava(rng: RandomNumberGenerator, c: Transform3D) -> void:
	var sets := [[Color("#ff3020"), Color("#ffd040")], [Color("#2050ff"), Color("#f0f0ff")], [Color("#9030d0"), Color("#ff9020")], [Color("#20b050"), Color("#f8ff70")]]
	var cs: Array = sets[blobs.size() / 4 % sets.size()]
	var metal: Color = [Color("#c8a040"), Color("#c0c0c8")][rng.randi() % 2]
	add("lamp_metal", c * Transform3D(Basis().scaled(Vector3(0.115, 0.14, 0.115)) , Vector3(0, 0.07, 0)), metal)
	add("lamp_metal", c * Transform3D(Basis().scaled(Vector3(0.07, 0.012, 0.07)), Vector3(0, 0.146, 0)), metal)
	var liquid: Color = cs[0]
	liquid.a = 0.62
	add("lamp_glass", c * Transform3D(Basis(), Vector3(0, 0.26, 0)), liquid)
	add("lamp_metal", c * Transform3D(Basis().scaled(Vector3(0.05, 0.07, 0.05)), Vector3(0, 0.405, 0)), metal)
	# the wax: a few glowing blobs drifting up and down inside the glass
	var wm := StandardMaterial3D.new()
	wm.albedo_color = cs[1]
	wm.emission_enabled = true
	wm.emission = cs[1]
	wm.emission_energy_multiplier = 1.6
	wm.roughness = 0.3
	for k in 4:
		var r := rng.randf_range(0.011, 0.019)
		var mi := MeshInstance3D.new()
		mi.mesh = sphere(1.0, 10, 5)
		mi.material_override = wm
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.visibility_range_end = 30.0
		add_child(mi)
		blobs.append([mi, c.origin, rng.randf() * TAU, rng.randf_range(0.18, 0.32), r, rng.randf_range(-1, 1)])
	var pool := MeshInstance3D.new()
	pool.mesh = sphere(1.0, 10, 5)
	pool.material_override = wm
	pool.transform = Transform3D(Basis().scaled(Vector3(0.045, 0.014, 0.045)), c.origin + UP * 0.162)
	pool.visibility_range_end = 30.0
	add_child(pool)
	_blob_place(blobs.size() - 4, 0.0)

func _blob_place(from: int, t: float) -> void:
	for i in range(from, blobs.size()):
		var b = blobs[i]
		var ph: float = b[2] + t * b[3]
		var s := 0.5 - 0.5 * cos(ph)                       # 0 bottom .. 1 top
		var yy: float = 0.17 + s * 0.17
		var rad: float = lerp(0.04, 0.026, s) - b[4]          # the glass narrows toward the top
		var off := Vector3(sin(ph * 0.7 + b[5]) * rad * 0.5, 0, cos(ph * 0.5 + b[5]) * rad * 0.4)
		var st: float = b[4] * (1.0 + 0.25 * sin(ph * 2.0))
		b[0].transform = Transform3D(Basis().scaled(Vector3(st, st * 1.25, st)), b[1] + UP * yy + off)

func _process(dt: float) -> void:
	if not built or player == null:
		return
	anim_t += dt
	if not blobs.is_empty() and player.position.distance_to(blobs[0][1]) < 25.0:
		_blob_place(0, anim_t)
	if dialog_open:
		_poll_dialog()
	if publishing:
		_poll_publish(dt)
	if looking:
		return
	_update_prompt()

# ------------------------------------------------------------------ the closer look
func _views() -> void:
	views.append({"name": "Short case, by the counter gate", "fr": "B", "pos": W("B", 0, 1.04, -0.74), "tgt": W("B", 0, 0.43, 0.3)})
	var names := ["Long case, first bay", "Long case, second bay", "Long case, third bay", "Long case, fourth bay"]
	for i in 4:
		var u := -2.5 + (i + 0.5) * 1.25
		views.append({"name": names[i], "fr": "A", "pos": W("A", u, 1.04, -0.74), "tgt": W("A", u, 0.43, 0.3)})
	views.append({"name": "Prize wall, left", "fr": "W", "pos": W("W", -1.25, 1.62, -1.85), "tgt": W("W", -1.25, 1.62, 0.3)})
	views.append({"name": "Prize wall, right", "fr": "W", "pos": W("W", 1.25, 1.62, -1.85), "tgt": W("W", 1.25, 1.62, 0.3)})

func _view_xf(i: int) -> Transform3D:
	var v = views[i]
	return Transform3D(Basis.looking_at(v.tgt - v.pos, UP), v.pos)

## Where the player stands: 0 none, else a zone; picks the view they are looking toward.
func _zone_view() -> int:
	if player.vr_on or player.leaving or player.frozen:
		return -1
	var p: Vector3 = player.position
	var fwd: Vector3 = -player.cam.global_transform.basis.z
	var inside := false
	for fr in ["A", "B"]:
		var o: Vector3 = FR[fr][0]
		var f: Vector3 = FR[fr][1]
		var a := f.cross(UP)
		var d := (p - o).dot(f)
		var u := (p - o).dot(a)
		var half: float = FR[fr][2] * 0.5 + 0.25
		if d > -2.2 and d < 0.05 and abs(u) < half and Vector2(fwd.x, fwd.z).normalized().dot(Vector2(f.x, f.z)) > 0.3:
			inside = true
	if not inside:
		return -1
	var eye: Vector3 = player.cam.global_position
	var best := -1
	var bd := -2.0
	for i in views.size():
		var dd: float = fwd.dot((views[i].tgt - eye).normalized())
		if dd > bd:
			bd = dd; best = i
	return best

func _update_prompt() -> void:
	var z := _zone_view()
	prompt.visible = z >= 0
	if prompt.visible:
		prompt_key.text = {"pad": "A", "touch": "Tap"}.get(input_kind, "E")

func _build_ui() -> void:
	ui = CanvasLayer.new()
	ui.layer = 15
	add_child(ui)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.06, 0.05, 0.78)
	sb.border_color = Color(0.93, 0.85, 0.66, 0.85)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 14; sb.content_margin_right = 18
	sb.content_margin_top = 8; sb.content_margin_bottom = 8
	prompt = Button.new()
	prompt.focus_mode = Control.FOCUS_NONE
	prompt.visible = false
	for st_name in ["normal", "hover", "pressed", "focus"]:
		prompt.add_theme_stylebox_override(st_name, sb)
	prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	prompt.custom_minimum_size = Vector2(300, 58)
	prompt.offset_left = -150; prompt.offset_right = 150
	prompt.offset_top = -132; prompt.offset_bottom = -74
	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 14; row.offset_right = -14
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prompt.add_child(row)
	prompt_key = Label.new()
	prompt_key.custom_minimum_size = Vector2(38, 34)
	prompt_key.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_key.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	prompt_key.add_theme_font_size_override("font_size", 17)
	prompt_key.add_theme_color_override("font_color", Color(0.1, 0.08, 0.06))
	var kb := StyleBoxFlat.new()
	kb.bg_color = Color(0.95, 0.89, 0.74)
	kb.set_corner_radius_all(6)
	kb.content_margin_left = 6; kb.content_margin_right = 6
	prompt_key.add_theme_stylebox_override("normal", kb)
	prompt_key.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(prompt_key)
	var pt := Label.new()
	pt.text = "Redeem tickets"   # R (Nov 2): the glass opens the redemption screen
	pt.add_theme_font_size_override("font_size", 16)
	pt.add_theme_color_override("font_color", Color(1, 0.97, 0.9))
	pt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(pt)
	prompt.pressed.connect(func(): redeem())
	ui.add_child(prompt)
	# the look screen
	bar = Control.new()
	bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.visible = false
	ui.add_child(bar)
	title = Label.new()
	title.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	title.offset_left = -260; title.offset_right = 260; title.offset_top = 12
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(1, 0.97, 0.9))
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	title.add_theme_constant_override("shadow_offset_x", 1)
	title.add_theme_constant_override("shadow_offset_y", 1)
	bar.add_child(title)
	hint = Label.new()
	hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	hint.offset_left = -300; hint.offset_right = 300; hint.offset_top = 42; hint.offset_bottom = 64
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
	hint.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	hint.add_theme_constant_override("shadow_offset_x", 1)
	hint.add_theme_constant_override("shadow_offset_y", 1)
	bar.add_child(hint)
	var brow := HBoxContainer.new()
	brow.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	brow.offset_left = -170; brow.offset_right = 170; brow.offset_top = -68; brow.offset_bottom = -14
	brow.alignment = BoxContainer.ALIGNMENT_CENTER
	brow.add_theme_constant_override("separation", 14)
	bar.add_child(brow)
	btn_prev = _mk_btn("<", sb, func(): step_view(-1))
	btn_back = _mk_btn("Back", sb, func(): close_look())
	btn_next = _mk_btn(">", sb, func(): step_view(1))
	for b in [btn_prev, btn_back, btn_next]:
		brow.add_child(b)
	btn_back.custom_minimum_size = Vector2(120, 52)
	tip = PanelContainer.new()
	var ts := StyleBoxFlat.new()
	ts.bg_color = Color(0.99, 0.97, 0.9, 0.95)
	ts.border_color = Color(0.75, 0.05, 0.08)
	ts.set_border_width_all(2)
	ts.set_corner_radius_all(6)
	ts.content_margin_left = 10; ts.content_margin_right = 10; ts.content_margin_top = 5; ts.content_margin_bottom = 5
	tip.add_theme_stylebox_override("panel", ts)
	tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tip.visible = false
	tip_label = Label.new()
	tip_label.add_theme_font_size_override("font_size", 16)
	tip_label.add_theme_color_override("font_color", Color(0.12, 0.08, 0.06))
	tip.add_child(tip_label)
	bar.add_child(tip)

func _mk_btn(t: String, sb: StyleBox, cb: Callable) -> Button:
	var b := Button.new()
	b.text = t
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(64, 52)
	b.add_theme_font_size_override("font_size", 20)
	for st_name in ["normal", "hover", "pressed", "focus"]:
		b.add_theme_stylebox_override(st_name, sb)
	b.add_theme_color_override("font_color", Color(1, 0.97, 0.9))
	b.pressed.connect(cb)
	return b

func open_look(i := -1) -> void:
	if looking:
		return
	if i < 0:
		i = _zone_view()
	if i < 0:
		i = 1
	looking = true
	view_i = i
	player.frozen = true
	saved_vis = []
	for c in player.buttons + [player.jump_open_btn, player.hint, player.stick]:
		if c:
			saved_vis.append([c, c.visible])
			c.visible = false
	var sg = get_parent().get_node_or_null("Signs")
	if sg and sg.get("ui") is CanvasLayer:
		saved_vis.append([sg.ui, sg.ui.visible])
		sg.ui.visible = false
	prompt.visible = false
	if lcam == null:
		lcam = Camera3D.new()
		lcam.near = 0.03
		lcam.far = 120.0
		add_child(lcam)
	lcam.global_transform = player.cam.global_transform
	lcam.fov = player.cam.fov
	lcam.keep_aspect = player.cam.keep_aspect
	lcam.current = true
	bar.visible = true
	_go(view_i, 0.55)

## R (Nov 2; design/godot-prize-counter.md "Redemption"): the counter glass opens the redemption screen
## (scripts/redemption.gd, as mall.redemption); its "Look at the prizes" comes back here (open_look).
## Without one (an old save path, a test scene) the glass still gives the closer look.
func redeem() -> void:
	var m = player.get("mall") if player else null
	if m != null and m.get("redemption") != null:
		prompt.visible = false
		m.redemption.open()
	else:
		open_look()

func close_look() -> void:
	if not looking:
		return
	tip.visible = false
	bar.visible = false
	sel = -1
	if tw:
		tw.kill()
	tw = create_tween()
	var from := lcam.global_transform
	var to: Transform3D = player.cam.global_transform
	var f0 := lcam.fov
	tw.tween_method(func(t: float):
		lcam.global_transform = from.interpolate_with(to, t)
		lcam.fov = lerp(f0, player.cam.fov, t), 0.0, 1.0, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tw.tween_callback(func():
		player.cam.current = true
		player.frozen = false
		looking = false
		for e in saved_vis:
			if e[0] != player.hint and is_instance_valid(e[0]):
				e[0].visible = e[1])

func step_view(k: int) -> void:
	if not looking:
		return
	view_i = (view_i + k + views.size()) % views.size()
	sel = -1
	tip.visible = false
	_go(view_i, 0.45)

func _fov_for(i: int) -> Array:
	# landscape: keep the height (vertical fov); portrait: keep the width (horizontal fov)
	var vp := get_viewport().get_visible_rect().size
	var wall: bool = views[i].fr == "W"
	if vp.x >= vp.y:
		return [Camera3D.KEEP_HEIGHT, 52.0 if wall else 46.0]
	return [Camera3D.KEEP_WIDTH, 74.0 if wall else 64.0]

func _go(i: int, dur: float) -> void:
	title.text = views[i].name + "   (%d / %d)" % [i + 1, views.size()]
	hint.text = {"pad": "D-pad left / right to move along · up / down to pick a prize · B to step back",
		"touch": "Tap a prize to see its price · swipe or < > to move along"}.get(input_kind,
		"Point at a prize to see its price · A / D or < > to move along · Esc to step back")
	if tw:
		tw.kill()
	var from := lcam.global_transform
	var to := _view_xf(i)
	var fa := _fov_for(i)
	lcam.keep_aspect = fa[0]
	var f0 := lcam.fov
	tw = create_tween()
	tw.tween_method(func(t: float):
		lcam.global_transform = from.interpolate_with(to, t)
		lcam.fov = lerp(f0, float(fa[1]), t), 0.0, 1.0, dur).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

## The prizes on screen in this view, sorted top-left to bottom-right: [index, screen pos].
func _on_screen() -> Array:
	var vp := get_viewport().get_visible_rect().size
	var out := []
	for k in items.size():
		var p: Vector3 = items[k].pos
		if lcam.is_position_behind(p):
			continue
		var s := lcam.unproject_position(p)
		if s.x < 20 or s.y < 70 or s.x > vp.x - 20 or s.y > vp.y - 80:
			continue
		out.append([k, s])
	out.sort_custom(func(a, b): return round(a[1].y / 60.0) * 100000.0 + a[1].x < round(b[1].y / 60.0) * 100000.0 + b[1].x)
	return out

func _pick(at: Vector2) -> void:
	var best := -1
	var bd := 95.0
	for e in _on_screen():
		var dd: float = e[1].distance_to(at)
		if dd < bd:
			bd = dd; best = e[0]
	_show_tip(best)

func _show_tip(k: int) -> void:
	sel = k
	if k < 0:
		tip.visible = false
		return
	var it = items[k]
	var tks: String = str(tget(it.key + ".tickets").get("text", it.tickets))
	tip_label.text = "%s — %s tickets" % [str(tget(it.key + ".name").get("text", it.name)), _commas(int(tks)) if tks.is_valid_int() else tks]
	tip.visible = true
	tip.reset_size()
	var s := lcam.unproject_position(it.pos)
	var vp := get_viewport().get_visible_rect().size
	var sz := tip.get_combined_minimum_size()
	tip.position = Vector2(clamp(s.x - sz.x * 0.5, 8, vp.x - sz.x - 8), clamp(s.y - sz.y - 18, 70, vp.y - sz.y - 80))

func _commas(n: int) -> String:
	var s := str(n)
	return s if s.length() <= 3 else s.substr(0, s.length() - 3) + "," + s.substr(s.length() - 3)

func _cycle(k: int) -> void:
	var on := _on_screen()
	if on.is_empty():
		return
	var at := 0
	for j in on.size():
		if on[j][0] == sel:
			at = (j + k + on.size()) % on.size()
			break
		at = 0 if k > 0 else on.size() - 1
	_show_tip(on[at][0])

func _input(e: InputEvent) -> void:
	if e is InputEventJoypadButton or (e is InputEventJoypadMotion and abs(e.axis_value) > 0.4):
		input_kind = "pad"
	elif e is InputEventKey or e is InputEventMouseButton:
		input_kind = "kb"
	elif e is InputEventScreenTouch:
		input_kind = "touch"
	if not built or player == null:
		return
	if dialog_open:
		if e is InputEventKey or e is InputEventMouseButton or e is InputEventScreenTouch or e is InputEventJoypadButton:
			get_viewport().set_input_as_handled()
		return
	if looking and is_owner and _owner_input(e):
		get_viewport().set_input_as_handled()
		return
	if not looking:
		if prompt.visible:
			var go := false
			if e is InputEventKey and e.pressed and not e.echo and e.physical_keycode in [KEY_E, KEY_ENTER, KEY_KP_ENTER]:
				go = true
			elif e is InputEventJoypadButton and e.pressed and e.button_index == JOY_BUTTON_A:
				go = true
			elif e is InputEventScreenTouch and e.pressed and prompt.get_global_rect().has_point(e.position):
				go = true
			if go:
				get_viewport().set_input_as_handled()
				redeem()
		return
	var handled := true
	if e is InputEventKey and e.pressed:
		match e.physical_keycode:
			KEY_A, KEY_LEFT:
				if not e.echo: step_view(-1)
			KEY_D, KEY_RIGHT:
				if not e.echo: step_view(1)
			KEY_W, KEY_UP:
				_cycle(-1)
			KEY_S, KEY_DOWN, KEY_TAB:
				_cycle(1)
			KEY_ESCAPE, KEY_Q, KEY_B, KEY_BACKSPACE, KEY_E:
				if not e.echo: close_look()
			_:
				handled = false
	elif e is InputEventJoypadButton and e.pressed:
		match e.button_index:
			JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_LEFT_SHOULDER: step_view(-1)
			JOY_BUTTON_DPAD_RIGHT, JOY_BUTTON_RIGHT_SHOULDER: step_view(1)
			JOY_BUTTON_DPAD_UP: _cycle(-1)
			JOY_BUTTON_DPAD_DOWN: _cycle(1)
			JOY_BUTTON_B, JOY_BUTTON_Y: close_look()
			_: handled = false
	elif e is InputEventJoypadMotion:
		if e.axis == JOY_AXIS_LEFT_X:
			if abs(e.axis_value) > 0.6 and not stick_latch:
				stick_latch = true
				step_view(1 if e.axis_value > 0 else -1)
			elif abs(e.axis_value) < 0.3:
				stick_latch = false
	elif e is InputEventMouseMotion:
		_pick(e.position)
		handled = false
	elif e is InputEventMouseButton:
		if e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			_pick(e.position)
		handled = false          # the buttons still get their clicks
	elif e is InputEventScreenTouch:
		if e.pressed:
			touch_start = e.position
			for b in [btn_prev, btn_back, btn_next]:
				if b.get_global_rect().has_point(e.position):
					b.pressed.emit()
					get_viewport().set_input_as_handled()
					return
		else:
			var dv: Vector2 = e.position - touch_start
			if abs(dv.x) > 70 and abs(dv.y) < 80:
				step_view(-1 if dv.x > 0 else 1)
			else:
				_pick(e.position)
	elif e is InputEventScreenDrag:
		pass
	else:
		handled = false
	if handled:
		get_viewport().set_input_as_handled()

# ------------------------------------------------------------------ words (section 4)
## The text and style of one text id: prizes.json, then published edits, then the owner's
## draft. "<item>.name" and "<item>.tickets" take their style from card.name / card.number.
func tget(id: String) -> Dictionary:
	var parts := id.split(".")
	var d := {}
	var items_j: Dictionary = J.get("items", {})
	if parts.size() == 2 and parts[1] in ["name", "tickets"] and items_j.has(parts[0]):
		d = tget("card." + ("number" if parts[1] == "tickets" else "name")).duplicate()
		d["text"] = str(items_j[parts[0]].get("name", parts[0])) if parts[1] == "name" else str(int(items_j[parts[0]].get("tickets", 0)))
	else:
		d = J.get("text", {}).get(id, {}).duplicate()
	for src in [pub, draft]:
		if src.get(id) is Dictionary:
			d.merge(src[id], true)
	return d

## The same without the owner's draft (what visitors see now).
func tlive(id: String) -> Dictionary:
	var keep := draft
	draft = {}
	var d := tget(id)
	draft = keep
	return d

## The same as shipped in prizes.json (no edits at all).
func tship(id: String) -> Dictionary:
	var kp := pub
	var kd := draft
	pub = {}; draft = {}
	var d := tget(id)
	pub = kp; draft = kd
	return d

func _font(name: String) -> Font:
	if not FONT_FILES.has(name):
		name = "sans"
	if not fonts.has(name):
		fonts[name] = load("res://fonts/" + FONT_FILES[name])
	return fonts[name]

func _art_mat(key: String, bg: String, emit: float, rough: float) -> ShaderMaterial:
	if not art_mats.has(key):
		var m := ShaderMaterial.new()
		m.shader = sh_opa
		m.set_shader_parameter("tex", load("res://prizes/%s.png" % bg))
		m.set_shader_parameter("tint", Color.WHITE)
		m.set_shader_parameter("emit", emit)
		m.set_shader_parameter("rough", rough)
		art_mats[key] = m
	return art_mats[key]

## [bg, size, [[text id, rect]]] for an art key.
func _art_spec(key: String) -> Array:
	var art: Dictionary = J.get("art", {})
	var it := ""
	var name := key
	if key.begins_with("card:"):
		it = key.substr(5)
		name = "card"
	var a: Dictionary = art.get(name, {})
	var fields := []
	for f in a.get("fields", []):
		fields.append([str(f[0]).replace("{item}", it), f[1]])
	var sz: Array = a.get("size", [256, 256])
	return [str(a.get("bg", "tag")), Vector2i(int(sz[0]), int(sz[1])), fields]

## Paints every picture that carries words, each in a SubViewport, and puts the results on
## their materials. Called again after any edit.
func paint_words() -> void:
	if painting:
		paint_again = true
		return
	painting = true
	var jobs := []
	for key in art_mats:
		var sp := _art_spec(key)
		var vp := SubViewport.new()
		vp.size = sp[1]
		vp.disable_3d = true
		vp.transparent_bg = false
		vp.render_target_update_mode = SubViewport.UPDATE_ONCE
		var tr := TextureRect.new()
		tr.texture = load("res://prizes/%s.png" % sp[0])
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_SCALE
		tr.size = Vector2(sp[1])
		vp.add_child(tr)
		for f in sp[2]:
			vp.add_child(_word_label(tget(f[0]), f[1], str(f[0]).ends_with(".name")))
		add_child(vp)
		jobs.append([key, vp])
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	for j in jobs:
		var img: Image = j[1].get_texture().get_image()
		if img:
			img.generate_mipmaps()
			art_mats[j[0]].set_shader_parameter("tex", ImageTexture.create_from_image(img))
		j[1].queue_free()
	painting = false
	if paint_again:
		paint_again = false
		paint_words()

## A Label for one text field, shrunk until it fits its rect (names may wrap to two lines).
func _word_label(st: Dictionary, rect: Array, wrap: bool) -> Label:
	var l := Label.new()
	l.position = Vector2(rect[0], rect[1])
	l.size = Vector2(rect[2], rect[3])
	var txt := str(st.get("text", ""))
	l.text = txt
	var f := _font(str(st.get("font", "sans")))
	var sz := clampi(int(st.get("size", 24)), 6, 200)
	var oc := str(st.get("outline", ""))
	var has_ol := oc != ""
	var w := float(rect[2]) - 4.0
	var h := float(rect[3])
	while sz > 7:
		var osz := maxi(2, sz / 9) if has_ol else 0
		var one := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, sz)
		if one.x + osz * 2 <= w and f.get_height(sz) <= h + 6:
			break
		if wrap and f.get_multiline_string_size(txt, HORIZONTAL_ALIGNMENT_CENTER, w, sz).y <= h + 2:
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			break
		sz -= 1
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", f)
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", Color.from_string(str(st.get("fill", "#000000")), Color.BLACK))
	l.add_theme_constant_override("line_spacing", -int(sz * 0.18))
	if has_ol:
		l.add_theme_color_override("font_outline_color", Color.from_string(oc, Color.BLACK))
		l.add_theme_constant_override("outline_size", maxi(2, sz / 9) * 2)
	return l

func _fetch_published() -> void:
	var url = JavaScriptBridge.eval("new URL('prize_text.json', location.href).href")
	if not (url is String):
		return
	var h := HTTPRequest.new()
	add_child(h)
	h.request_completed.connect(func(result, code, _headers, body):
		if result == HTTPRequest.RESULT_SUCCESS and code == 200:
			var j = JSON.parse_string(body.get_string_from_utf8())
			if j is Dictionary and j.get("text") is Dictionary:
				pub = j.text
				paint_words()
		h.queue_free())
	h.request(url + "?t=" + str(Time.get_unix_time_from_system()))

# ---- the owner's editing
func _owner_ui() -> void:
	if not is_owner:
		return
	btn_edit = Button.new()
	btn_pub = Button.new()
	var y := 72
	for b in [btn_edit, btn_pub]:
		b.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
		b.offset_left = -212; b.offset_right = -12
		b.offset_top = y; b.offset_bottom = y + 42
		b.mouse_filter = Control.MOUSE_FILTER_IGNORE   # hit-tested in _owner_input (touch skips mouse emulation)
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_size_override("font_size", 17)
		bar.add_child(b)
		y += 50
	btn_edit.toggle_mode = true
	status_l = Label.new()
	status_l.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	status_l.offset_left = -330; status_l.offset_right = -12
	status_l.offset_top = y + 2; status_l.offset_bottom = y + 26
	status_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status_l.add_theme_font_size_override("font_size", 16)
	status_l.add_theme_color_override("font_color", Color.WHITE)
	status_l.add_theme_color_override("font_outline_color", Color.BLACK)
	status_l.add_theme_constant_override("outline_size", 5)
	bar.add_child(status_l)
	_owner_refresh()

func _owner_refresh() -> void:
	if btn_edit == null:
		return
	btn_edit.text = "Edit words: on" if edit_on else "Edit words"
	btn_edit.button_pressed = edit_on
	btn_pub.disabled = draft.is_empty() or publishing
	btn_pub.text = "Publish words (%d)" % draft.size() if not draft.is_empty() else "Publish words"
	if publishing:
		status_l.text = "Publishing..."
	elif edit_on:
		status_l.text = "Tap a prize to change its words"
	elif status_l.text.begins_with("Tap"):
		status_l.text = ""

## Owner buttons and, with Edit words on, a tap on a prize. True when it took the event.
func _owner_input(e: InputEvent) -> bool:
	var pos = null
	var down := false
	if e is InputEventScreenTouch:
		pos = e.position; down = e.pressed
	elif e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		pos = e.position; down = e.pressed
	if pos == null:
		return false
	if down:
		if btn_edit.get_global_rect().has_point(pos):
			edit_on = not edit_on
			_owner_refresh()
			return true
		if btn_pub.get_global_rect().has_point(pos):
			if not btn_pub.disabled:
				_publish()
			return true
		for b in [btn_prev, btn_back, btn_next]:
			if b.get_global_rect().has_point(pos):
				return false
		if edit_on:
			touch_start = pos
			return true
	elif edit_on and pos.distance_to(touch_start) < 14.0:
		var best := -1
		var bd := 95.0
		for en in _on_screen():
			var dd: float = en[1].distance_to(pos)
			if dd < bd:
				bd = dd; best = en[0]
		if best >= 0:
			_open_dialog(str(items[best].key))
		return true
	return false

## The text ids one item shows: its card's name and number, its packaging, then the styles
## every card shares.
func _ids_for(it: String) -> Array:
	var out := [[it + ".name", "Name on its card", true, false], [it + ".tickets", "Ticket number on its card", true, false]]
	for key in J.get("text", {}):
		if str(key).begins_with(it + ".") or (it == "pogs" and str(key).begins_with("pogs.")):
			out.append([key, "Packaging: " + str(key).get_slice(".", 1), true, true])
	out.append(["card.number", "Every card: the number", false, true])
	out.append(["card.name", "Every card: the name", false, true])
	out.append(["card.band", "Every card: the band", true, true])
	return out

func _open_dialog(it: String) -> void:
	var fields := []
	for e in _ids_for(it):
		var st := tget(e[0])
		fields.append({"id": e[0], "label": e[1], "text": str(st.get("text", "")) if e[2] else null, "style": e[3],
			"font": str(st.get("font", "sans")), "size": int(st.get("size", 24)),
			"fill": _hex(str(st.get("fill", "#000000"))), "outline": str(st.get("outline", ""))})
	var spec := {"title": str(tget(it + ".name").get("text", it)), "fields": fields, "fonts": FONT_FILES.keys()}
	var ok = JavaScriptBridge.eval("(function(){if(!window.mallPrizeEdit)return '0';window.mallPrizeEdit.open(" + JSON.stringify(JSON.stringify(spec)) + ");return '1'})()")
	if str(ok) != "1":
		status_l.text = "Editing isn't available on this page"
		return
	dialog_open = true
	dialog_item = it

func _hex(c: String) -> String:
	return "#" + Color.from_string(c, Color.BLACK).to_html(false)

func _poll_dialog() -> void:
	var r = JavaScriptBridge.eval("window.mallPrizeEdit ? window.mallPrizeEdit.result : '{\"cancel\":1}'")
	if not (r is String) or r == "":
		return
	dialog_open = false
	var j = JSON.parse_string(r)
	if not (j is Dictionary):
		return
	if j.get("save") is Dictionary:
		for id in j.save:
			_set_draft(id, j.save[id])
	elif j.get("reset") is Array:
		for id in j.reset:
			_set_draft(str(id), tship(str(id)))
	JavaScriptBridge.eval("(function(){try{localStorage.setItem('" + DRAFT_KEY + "'," + JSON.stringify(JSON.stringify(draft)) + ")}catch(e){}})()")
	paint_words()
	_owner_refresh()

## Keeps in the draft only the fields that differ from what visitors see now.
func _set_draft(id: String, want: Dictionary) -> void:
	var live := tlive(id)
	var diff := {}
	for k in ["text", "font", "size", "fill", "outline"]:
		if not want.has(k) or want[k] == null:
			continue
		var a = want[k]
		var b = live.get(k, "")
		if k == "size":
			a = int(a); b = int(b)
		elif k in ["fill", "outline"] and str(a) != "" and str(b) != "":
			a = _hex(str(a)); b = _hex(str(b))
		if str(a) != str(b):
			diff[k] = a
	if diff.is_empty():
		draft.erase(id)
	else:
		draft[id] = diff

func _publish() -> void:
	if draft.is_empty() or publishing:
		return
	var ok = JavaScriptBridge.eval("(function(){if(!window.mallPrizeText)return '0';window.mallPrizeText.publish(" + JSON.stringify(JSON.stringify(draft)) + ");return '1'})()")
	if str(ok) != "1":
		status_l.text = "Publishing isn't available on this page"
		return
	publishing = true
	poll_t = 0.0
	_owner_refresh()

func _poll_publish(dt: float) -> void:
	poll_t += dt
	if poll_t < 0.5:
		return
	poll_t = 0.0
	var s = JavaScriptBridge.eval("window.mallPrizeText ? window.mallPrizeText.status : 'error: no publisher'")
	if not (s is String) or s == "busy":
		return
	publishing = false
	if s == "ok":
		for id in draft:
			var cur: Dictionary = pub.get(id, {}) if pub.get(id) is Dictionary else {}
			cur.merge(draft[id], true)
			pub[id] = cur
		draft.clear()
		JavaScriptBridge.eval("(function(){try{localStorage.setItem('" + DRAFT_KEY + "','{}')}catch(e){}})()")
		status_l.text = "Published. Everyone sees it in about a minute."
	else:
		status_l.text = "Not published: " + s.trim_prefix("error:").strip_edges()
	_owner_refresh()
