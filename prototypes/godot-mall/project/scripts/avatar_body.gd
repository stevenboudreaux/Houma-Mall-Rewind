## Workstream V (design/godot-avatar.md): the avatar's body. An NpcBody (scripts/npc_body.gd, the
## shoppers' body, its clip library and NpcRig retargeting, unchanged) dressed in the player's look:
##   - the body's mesh copied once with each vertex's body part in COLOR.r, drawn with
##     scripts/avatar_recolor.gdshader (skin, hair, top and bottom colours over the body's texture);
##   - the shirt words as a Label3D on the chest, riding the Spine2 bone;
##   - a right-hand holder (BoneAttachment3D on RightHand) for a held item in third person.
## Used by scripts/avatar.gd (in the mall) and scripts/avatar_creator.gd (the preview).
extends NpcBody

const Look = preload("res://scripts/avatar_look.gd")
const SHADER = preload("res://scripts/avatar_recolor.gdshader")
const WORDS_FONT := "res://fonts/forza.ttf"   # the same face as Ch02's HOUMA (scripts/npc_shirt.json)

var info := {}             # this body's avatar_bodies.json entry
var mats: Array = []       # the recolour ShaderMaterials
var words: Label3D
var hand: Node3D           # the right-hand holder (third person's held item)
var sk: Skeleton3D

static var _mesh_cache := {}   # body id -> {mesh path -> recoloured ArrayMesh}

## Build (or rebuild for another body) and dress in look L for `year`.
func wear(L: Dictionary, year: int) -> void:
	var bid := str(L.get("body", Look.DEFAULT_BODY))
	if str(info.get("id", "")) != bid or skin == null:
		_build(bid)
	_colour(L, year)

func _build(bid: String) -> void:
	info = Look.body(bid)
	var e := {}
	for s in NpcBody.manifest().get("skins", []):
		if str(s.id) == bid: e = s
	if e.is_empty():
		push_warning("avatar_body: no skin " + bid); return
	words = null; hand = null; mats = []
	# a new skin brings a new AnimationPlayer: forget the old one's clip, or NpcBody.play("idle")
	# (which skips the clip already playing) would leave the new body in its T-pose
	clip = ""
	base = "idle"
	set_skin(e)
	if skin == null:
		return
	sk = skin.find_child("Skeleton3D", true, false)
	var k := 0
	var cache: Dictionary = _mesh_cache.get(bid, {})
	for mi in skin.find_children("*", "MeshInstance3D", true, false):
		var src: Mesh = mi.mesh
		var key := src.resource_path + "#" + str(k)
		if not cache.has(key):
			cache[key] = _part_mesh(src, k)
		var m: ArrayMesh = cache[key]
		mi.mesh = m
		for s in m.get_surface_count():
			var sm := ShaderMaterial.new()
			sm.shader = SHADER
			var tp := ""
			var tl: Array = info.get("tex", [])
			if k < tl.size(): tp = str(tl[k])
			var tex: Texture2D = load(tp) if tp != "" and ResourceLoader.exists(tp) else null
			if tex == null:
				var om = src.surface_get_material(s)
				if om is StandardMaterial3D: tex = om.albedo_texture
			sm.set_shader_parameter("albedo_tex", tex)
			sm.set_shader_parameter("tint", NpcBody.tint)
			mi.set_surface_override_material(s, sm)
			mats.append(sm)
			k += 1
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_mesh_cache[bid] = cache
	_attach()

## A copy of the mesh with, per vertex, its island's mean colour (linear) in COLOR.rgb and class in
## COLOR.a (scripts/avatar_bodies.json "islands" and "verts", by surface in build order).
func _part_mesh(src: Mesh, surf0: int) -> ArrayMesh:
	var am := ArrayMesh.new()
	var isl: Array = info.get("islands", [])
	var vl: Array = info.get("verts", [])
	for s in src.get_surface_count():
		var a := src.surface_get_arrays(s)
		var V: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
		var col := PackedColorArray(); col.resize(V.size())
		var raw := PackedByteArray()
		if surf0 + s < vl.size():
			raw = Marshalls.base64_to_raw(str(vl[surf0 + s]))
		for v in V.size():
			var c := Color(0.5, 0.5, 0.5, 0.0)
			if raw.size() >= (v + 1) * 2:
				var i := raw.decode_u16(v * 2)
				if i < isl.size():
					c = Color.from_string(str(isl[i][1]), Color.GRAY).srgb_to_linear()
					c.a = float(isl[i][0]) / 4.0
			col[v] = c
		a[Mesh.ARRAY_COLOR] = col
		var B = a[Mesh.ARRAY_BONES]
		var flags := 0
		if B != null and V.size() > 0 and B.size() / V.size() == 8: flags |= Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, a, [], {}, flags)
	return am

## The chest words and the hand holder, on bone attachments.
func _attach() -> void:
	if sk == null:
		return
	var sp := _find_bone("Spine2")
	if sp >= 0:
		var ba := BoneAttachment3D.new()
		ba.bone_idx = sp
		sk.add_child(ba)
		words = Label3D.new()
		words.font = load(WORDS_FONT)
		words.font_size = 96
		words.outline_size = 0
		words.shaded = true
		words.double_sided = false
		words.alpha_cut = Label3D.ALPHA_CUT_DISCARD
		words.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		words.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		ba.add_child(words)
		# the chest point is in body space at rest; the label sits there, facing the body's front
		var c: Array = info.get("chest", [0, 1.25, 0.12])
		var body_pt := Vector3(float(c[0]), float(c[1]), float(c[2]) + 0.012)
		var to_sk := (skin.transform * _chain(skin, sk))   # body space -> skeleton space
		var rest := sk.get_bone_global_rest(sp)
		var local := (to_sk * rest).affine_inverse()
		words.transform = local * Transform3D(Basis(), body_pt)
		# (local already undoes the skeleton's scale, so a font pixel is 1.6 mm in the world)
		words.pixel_size = 0.0016
		words.set_meta("chest_w", float(info.get("chest_w", 0.24)))
		words.set_meta("px", words.pixel_size)
	var rh := _find_bone("RightHand")
	if rh >= 0:
		var hb := BoneAttachment3D.new()
		hb.bone_idx = rh
		sk.add_child(hb)
		hand = Node3D.new()
		hand.name = "Hand"
		hb.add_child(hand)
		# undo the skeleton's scale so an item keeps its own size in the hand
		var s := (skin.transform * _chain(skin, sk)).basis.get_scale().x * sk.get_bone_global_rest(rh).basis.get_scale().x
		hand.scale = Vector3.ONE / maxf(s, 0.001)

func _chain(top: Node, n: Node3D) -> Transform3D:
	var t := Transform3D()
	var c: Node = n
	while c and c != top:
		if c is Node3D: t = (c as Node3D).transform * t
		c = c.get_parent()
	return t

func _find_bone(suffix: String) -> int:
	for i in sk.get_bone_count():
		if sk.get_bone_name(i).ends_with("_" + suffix) or sk.get_bone_name(i).ends_with(":" + suffix):
			return i
	return -1

func _colour(L: Dictionary, year: int) -> void:
	var yk := Look.year_key(year)
	var cl: Dictionary = L.get(yk, {})
	var pairs := [["skin", str(L.get("skin", ""))], ["hair", str(L.get("hair", ""))],
		["top", str(cl.get("top", ""))], ["bottom", str(cl.get("bottom", ""))]]
	var on := Vector4.ZERO
	for i in pairs.size():
		var nm: String = pairs[i][0]
		var want: String = pairs[i][1]
		on[i] = 1.0 if want != "" and str(info.get(nm, "")) != "" else 0.0
		for m in mats:
			m.set_shader_parameter("new_" + nm, _lin(want if want != "" else "#808080"))
	for m in mats:
		m.set_shader_parameter("on", on)
		m.set_shader_parameter("tint", NpcBody.tint)
	if words:
		var t := Look.clean_words(str(cl.get("words", "")))
		words.text = t
		words.visible = t != ""
		# shrink long words to the chest's width; dark ink on a light top, light ink on a dark one
		var w: float = words.get_meta("chest_w", 0.24)
		var font: Font = words.font
		# pixel_size "px" is 1.6 mm per font pixel in the world (the skeleton's scale is undone)
		var world_w := font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, words.font_size).x * 0.0016
		var sc := minf(1.0, w / maxf(world_w, 0.001)) if world_w > 0.0 else 1.0
		words.pixel_size = float(words.get_meta("px")) * sc
		var top_c := Color.from_string(str(cl.get("top", "")) if str(cl.get("top", "")) != "" else str(info.get("top", "#808080")), Color.GRAY)
		words.modulate = Color("#1a1a1a") if top_c.get_luminance() > 0.55 else Color("#f4efe2")

static func _lin(hex: String) -> Color:
	return Color.from_string(hex, Color.BLACK).srgb_to_linear()

## Hide or show the body's meshes (the words and a held item follow).
func show_body(on: bool) -> void:
	visible = on
