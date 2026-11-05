## A B1 character body (design/godot-characters.md): one of the two base bodies in
## models/characters/, shaped by sliders, dressed in layered pieces, playing the shoppers' clips.
##
## It is an NpcBody (same clips, same NpcRig retargeting). The bodies' skeleton rest IS Ch01's
## (npc/anims.json "rest"), so NpcRig finds nothing to fix at neutral; the posture slider tilts
## the spine's rest and NpcRig then carries every clip over stooped.
##
## Shaping, from models/characters/characters.json:
##   slider x > 0 -> blend shape '<name>+' = x; x < 0 -> '<name>-' = -x; correctives = products.
##   Each blend shape also moves joints ("joints": local rest-translation offsets per bone), so
##   bones follow the flesh: new rests, and new bind poses on every Skin (body + pieces share one
##   skeleton and one set of inverse bind matrices).
## Pieces (hair, clothes) are glbs on the same 65-bone skeleton; their meshes move
## under this body's Skeleton3D, get the same blend shape weights (the names they carry), and
## hide body / lower-layer regions they cover (scripts/spatial_char_region.gdshader, region id in UV2.x).
##
## This is B1's proof loader; B2's editor builds on it. B-FIX (Nov 2): the clothed rule and the child
## rule below replace every base-layer rule.
class_name CharBody
extends NpcBody

const MANIFEST := "res://models/characters/characters.json"
static var _cm := {}

var sex := "female"
var values := {}          # slider name -> value
var weights := {}         # blend shape name -> weight
var pieces := {}          # piece id -> its manifest entry (its meshes moved under the skeleton)
var colors := {}          # "skin" / "iris" / "hair" / piece id -> Color
var sk: Skeleton3D
var _skins: Array[Skin] = []

static func cman() -> Dictionary:
	if _cm.is_empty():
		var j = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
		_cm = j if j is Dictionary else {}
	return _cm

## Load a base body ("female" / "male"); hi = the full-resolution mesh (close-ups, face passes).
func make(s: String, hi := false) -> void:
	sex = s
	pieces.clear()     # B2: remaking a body (another sex) drops the old body's pieces with its skin
	var b: Dictionary = cman().bodies[s]
	set_skin({"id": "b1_" + s, "scn": b.glb_hi if hi else b.glb, "hips": b.hips_height,
		"height_m": b.height_m, "sex": "f" if s == "female" else "m"})
	walk_clip = "walk_f" if s == "female" else "walk_m"
	sk = skin.find_child("Skeleton3D", true, false)
	_skins.clear()
	for mi in sk.find_children("*", "MeshInstance3D", true, false):
		_own_skin(mi)
	apply({})          # dresses the body in the clothed defaults (the clothed rule)

func _own_skin(mi: MeshInstance3D) -> void:
	if mi.skin:
		mi.skin = mi.skin.duplicate()
		_skins.append(mi.skin)

## Slider values -> blend shape weights (the rule above).
static func shape_weights(vals: Dictionary, s: String) -> Dictionary:
	var w := {}
	for sl in cman().sliders:
		if sl.kind != "shape" or (sl.has("sex") and sl.sex != s): continue
		var x := clampf(float(vals.get(sl.name, 0.0)), float(sl.range[0]), float(sl.range[1]))
		if x > 0.0 and sl.shapes.has(sl.name + "+"): w[sl.name + "+"] = x
		elif x < 0.0 and sl.shapes.has(sl.name + "-"): w[sl.name + "-"] = -x
	for c in cman().correctives:
		var p := 1.0
		for side in c.product_of: p *= float(w.get(side, 0.0))
		if p > 0.0: w[c.shape] = p
	return w

## Set every slider at once (missing = 0) and rebuild bones, binds and the rig. Runs the clothed
## rule and the child rule (below) on every call, so a slider that makes a body a child takes off
## anything a child may not wear.
func apply(vals: Dictionary) -> void:
	values = vals.duplicate()
	if is_child(values):
		for k in CHILD_ZERO_KEYS: values.erase(k)
	weights = shape_weights(values, sex)
	ensure_clothed(false)
	for mi in sk.find_children("*", "MeshInstance3D", true, false):
		_weigh(mi)
	_bones()
	_layers()
	CharFit.fit_hair(self)   # CHAR-EDITOR: the hair fitted to this shape (scripts/chars/char_fit.gd)

func _weigh(mi: MeshInstance3D) -> void:
	var m := mi.mesh
	if m == null: return
	for i in range(m.get_blend_shape_count()):
		var n := str(m.get_blend_shape_name(i))
		mi.set_blend_shape_value(i, float(weights.get(n, 0.0)))

## Joint offsets from the blend shapes, posture turns, then rests + bind poses + NpcRig.
func _bones() -> void:
	var b: Dictionary = cman().bodies[sex]
	var bones: Dictionary = b.bones
	var turns := {}
	for sl in cman().sliders:
		if sl.kind == "skeleton":
			var x := float(values.get(sl.name, 0.0))
			for bn in sl.bones: turns[bn] = float(turns.get(bn, 0.0)) + float(sl.bones[bn]) * x
	var bind_g := {}
	for i in range(sk.get_bone_count()):
		var n := sk.get_bone_name(i)
		if not bones.has(n): continue
		var e: Dictionary = bones[n]
		var pos := Vector3(e.pos[0], e.pos[1], e.pos[2])
		for sn in weights:
			var jd: Dictionary = b.joints.get(sn, {})
			if jd.has(n):
				var d: Array = jd[n]
				pos += Vector3(d[0], d[1], d[2]) * float(weights[sn])
		var rr := Quaternion(e.rest_rot[0], e.rest_rot[1], e.rest_rot[2], e.rest_rot[3])
		if turns.has(n) and absf(turns[n]) > 0.01:
			rr = Quaternion(Vector3.RIGHT, deg_to_rad(turns[n])) * rr
		var rest := Transform3D(Basis(rr), pos)
		sk.set_bone_rest(i, rest)
		sk.set_bone_pose(i, rest)
		var bq := Quaternion(e.bind_rot[0], e.bind_rot[1], e.bind_rot[2], e.bind_rot[3])
		var lb := Transform3D(Basis(bq), pos)
		var p := sk.get_bone_parent(i)
		bind_g[i] = (bind_g[p] as Transform3D) * lb if p >= 0 and bind_g.has(p) else lb
	for s in _skins:
		for k in range(s.get_bind_count()):
			var bi := s.get_bind_bone(k)
			if bi < 0: bi = sk.find_bone(str(s.get_bind_name(k)))
			if bind_g.has(bi): s.set_bind_pose(k, (bind_g[bi] as Transform3D).affine_inverse())
	# NpcRig: a fresh one for the new rests (posture), hips ratio from the new hips height
	if rig:
		rig.get_parent().remove_child(rig); rig.free()
	rig = NpcRig.new()
	var hips := sk.get_bone_global_rest(sk.find_bone("mixamorig_Hips")).origin.y
	rig.setup(sk, hips / float(NpcBody.meta().get("hips", 1.0)))
	sk.add_child(rig)

## Dress: wear a piece from the manifest (characters.json "pieces" entry, or its id). Its meshes
## move under this skeleton; layers are then resolved (_layers): covered regions hidden below,
## 'fit_over' turned on where it sits over another piece. A piece in the same slot is replaced.
## Refused (false): an unknown piece, a base-layer piece (none in the live game), and on a child body
## anything outside CHILD_ALLOW. The clothed rule runs after, so a body is never left undressed.
func wear(p) -> bool:
	var e: Dictionary = p if p is Dictionary else piece_entry(str(p))
	if not _may_wear(e): return false
	_clear_for(e)
	var ok := _attach_piece(e)
	ensure_clothed(false)
	_bones()
	_layers()
	CharFit.fit_hair(self)   # CHAR-EDITOR
	return ok

## Wear several pieces at once (one rebuild of bones and layers at the end), with the same rules as
## wear(); the clothed rule runs after. Returns the ids actually worn.
func wear_many(list: Array) -> Array:
	var done := []
	for p in list:
		var e: Dictionary = p if p is Dictionary else piece_entry(str(p))
		if not _may_wear(e): continue
		_clear_for(e)
		if _attach_piece(e): done.append(str(e.id))
	ensure_clothed(false)
	_bones()
	_layers()
	return done

func _may_wear(e: Dictionary) -> bool:
	if e.is_empty():
		push_warning("char_body: no such piece"); return false
	if str(e.slot).begins_with("base_"):
		push_warning("char_body: base-layer pieces are not worn in the live game: " + str(e.get("id", "")))
		return false
	if is_child(values) and not child_ok(e):
		push_warning("char_body: not a child's piece: " + str(e.get("id", "")))
		return false
	return true

## Take off what a new piece replaces (same slot, counts_as, CLASHES).
func _clear_for(e: Dictionary) -> void:
	for other in pieces.keys():
		if pieces[other].slot == e.slot or (e.get("counts_as", []) as Array).has(pieces[other].slot) \
				or (pieces[other].get("counts_as", []) as Array).has(e.slot) \
				or (CLASHES.get(e.slot, []) as Array).has(pieces[other].slot):
			_remove(other)

## Take off everything except the clothed minimum: hair, plus the full outfit, or one closed top and
## one bottom (the clothed defaults if none is worn). Never less (the clothed rule). Returns what is left.
## (The name is kept from B2; there is no base layer to strip to.)
func strip_to_base(_unused := true) -> Array:
	var keep := {}
	var top := ""; var bot := ""; var full := ""
	for k in pieces:
		var c := covers(pieces[k])
		if c == "full" and full == "": full = k
		elif c == "top" and top == "": top = k
		elif c == "bottom" and bot == "": bot = k
		if str(pieces[k].slot) == "hair": keep[k] = true
	if full != "": keep[full] = true
	else:
		if top != "": keep[top] = true
		if bot != "": keep[bot] = true
	for k in pieces.keys():
		if not keep.has(k): _remove(k)
	ensure_clothed(false)
	_bones()
	_layers()
	return pieces.keys()

## Move a piece's meshes under the skeleton (no layering yet). False when its glb is missing.
func _attach_piece(e: Dictionary) -> bool:
	var ps: PackedScene = load(str(e.glb))
	if ps == null:
		push_warning("char_body: cannot load " + str(e.glb)); return false
	var inst := ps.instantiate()
	for mi in inst.find_children("*", "MeshInstance3D", true, false):
		mi.get_parent().remove_child(mi)
		mi.owner = null
		sk.add_child(mi)
		mi.skeleton = NodePath("..")
		mi.set_meta("piece", e.id)
		_own_skin(mi)
		_weigh(mi)
	inst.free()
	pieces[e.id] = e
	return true

## The manifest entry of a piece id for this body ("top_tee" or "top_tee_female").
func piece_entry(id: String) -> Dictionary:
	for e in cman().pieces:
		if e.body == sex and (e.id == id or e.base_id == id): return e
	return {}

## Take a piece off. Refused (false) when it is the only thing covering the chest or the groin
## (the clothed rule): a closed top, a bottom or a full outfit can only be replaced by another.
func take_off(id: String) -> bool:
	var key := ""
	for k in pieces:
		if k == id or pieces[k].base_id == id: key = k
	if key == "": return false
	var rest := pieces.duplicate()
	rest.erase(key)
	var c := coverage(rest)
	if not (c.top and c.bottom):
		return false
	_remove(key)
	_layers()
	return true

func _remove(key: String) -> void:
	for mi in sk.find_children("*", "MeshInstance3D", true, false):
		if mi.get_meta("piece", "") == key:
			_skins.erase(mi.skin)
			mi.get_parent().remove_child(mi)
			mi.queue_free()
	pieces.erase(key)

## THE CLOTHED RULE (Steven, Nov 2, final; design/godot-characters.md). In the live game every
## character, adult or child, is clothed at all times: it always wears a closed top and a bottom, or a
## full outfit. Enforced here (make, apply, wear, wear_many, take_off, strip_to_base) and in
## CharPreset.normalize(), not only in an editor. There is no base layer, no flag and no option around
## it. Under the clothes the body itself is painted with an opaque base layer (scripts/
## spatial_char_region.gdshader base_mask + the albedo map) and its chest and groin are flattened, so a
## missing piece or a bug still shows no bare chest or groin.
const CLOSED_TOPS := ["top_tee", "top_polo", "top_buttondown", "top_sweatshirt", "top_tank", "top_babytee"]
const BOTTOMS := ["bot_jeans", "bot_widejeans", "bot_khakis", "bot_slacks", "bot_longshorts",
	"bot_shortshorts", "bot_skirt", "bot_overalls"]
const FULL_OUTFITS := ["full_football", "full_cheer", "full_waitress", "full_coveralls"]
## What a body missing a top / a bottom is given (the first one this pack ships).
const CLOTHED_DEFAULT := {"top": ["top_tee", "top_polo", "top_sweatshirt", "top_buttondown"],
	"bottom": ["bot_jeans", "bot_khakis", "bot_slacks", "bot_longshorts"]}
## THE CHILD RULE: a body with youth > 0 or youth_small > 0 is a child. A child wears only these
## plain pieces (and any hair); nothing else is offered, loaded or kept, whatever a preset says.
const CHILD_ALLOW := ["top_tee", "top_polo", "top_buttondown", "top_sweatshirt", "top_flannel", "top_cardigan",
	"bot_jeans", "bot_widejeans", "bot_khakis", "bot_slacks", "bot_longshorts", "bot_overalls",
	"shoe_sneakers", "shoe_boots", "shoe_dressshoes", "shoe_sandals",
	"x_cap_fwd", "x_cap_back", "x_glasses", "x_watch"]
## Adult-only shape sliders, held at 0 on a child body.
const CHILD_ZERO_KEYS := ["bust", "bust_lift"]
## The painted base layer: body regions (characters.json "regions") drawn as plain fabric, not skin.
const BASE_REGIONS := ["chest_f", "chest_b", "pelvis_f", "pelvis_b", "crotch"]
const BASE_COLOR := Color(0.74, 0.73, 0.69)   # a plain undershirt / bike-short grey
## A full outfit (football, cheer, waitress, coveralls) replaces top, bottom and underlayer, and
## each of those replaces a full outfit.
const CLASHES := {"full": ["top", "bottom", "under"], "top": ["full"], "bottom": ["full"], "under": ["full"]}

static func is_child(vals: Dictionary) -> bool:
	return float(vals.get("youth", 0.0)) > 0.0 or float(vals.get("youth_small", 0.0)) > 0.0

static func child_ok(e: Dictionary) -> bool:
	return str(e.get("slot", "")) == "hair" or CHILD_ALLOW.has(str(e.get("base_id", "")))

## What a piece covers for the clothed rule: "full", "top", "bottom" or "".
static func covers(e: Dictionary) -> String:
	var b := str(e.get("base_id", ""))
	if FULL_OUTFITS.has(b): return "full"
	if CLOSED_TOPS.has(b): return "top"
	if BOTTOMS.has(b): return "bottom"
	return ""

## Whether a set of worn pieces (id -> entry) covers the chest and the groin.
static func coverage(ps: Dictionary) -> Dictionary:
	var c := {"top": false, "bottom": false}
	for k in ps:
		match covers(ps[k]):
			"full": c.top = true; c.bottom = true
			"top": c.top = true
			"bottom": c.bottom = true
	return c

func is_clothed() -> bool:
	var c := coverage(pieces)
	return c.top and c.bottom

## The clothed rule and the child rule on the worn pieces: base-layer pieces and (on a child) pieces
## outside CHILD_ALLOW come off; a missing top or bottom gets the first default this pack ships.
func ensure_clothed(rebuild := true) -> void:
	var child := is_child(values)
	for k in pieces.keys():
		if str(pieces[k].slot).begins_with("base_") or (child and not child_ok(pieces[k])):
			_remove(k)
	var c := coverage(pieces)
	for need in ["top", "bottom"]:
		if c[need]: continue
		var ok := false
		for id in CLOTHED_DEFAULT[need]:
			var e := piece_entry(str(id))
			if e.is_empty() or (child and not child_ok(e)): continue
			if _attach_piece(e):
				ok = true; break
		if not ok:
			push_warning("char_body: this pack ships no %s; the painted base layer shows" % need)
	if rebuild:
		_bones()
		_layers()

## Layering: each surface hides the regions covered by any piece on a HIGHER layer (the body is
## below everything); a piece above the base layer gets its 'fit_over' push-out when another piece
## on its own layer or the one below (base excluded) is worn.
func _layers() -> void:
	var reg: Array = cman().regions
	for mi in sk.find_children("*", "MeshInstance3D", true, false):
		var pid: String = mi.get_meta("piece", "")
		var my_layer := -1 if pid == "" else int(pieces[pid].layer)
		var mask := 0
		var over := false
		for k in pieces:
			if k == pid: continue
			var L := int(pieces[k].layer)
			if L > my_layer:
				for r in pieces[k].get("hides", []):
					var i := reg.find(r)
					if i >= 0: mask |= 1 << i
			if pid != "" and my_layer >= 1 and (L == my_layer or L == my_layer - 1) and L >= 1:
				over = true
		_shade(mi, mask)
		if mi.mesh:
			var fi: int = mi.find_blend_shape_by_name("fit_over")
			if fi >= 0: mi.set_blend_shape_value(fi, 1.0 if over else 0.0)

## The painted base layer's region bits (BASE_REGIONS in characters.json "regions").
static func base_mask() -> int:
	var reg: Array = cman().get("regions", [])
	var m := 0
	for r in BASE_REGIONS:
		var i := reg.find(r)
		if i >= 0: m |= 1 << i
	return m

const REGION_SHADER := preload("res://scripts/spatial_char_region.gdshader")

## Surfaces become spatial_char_region materials (same look as the imported material + hiding).
func _shade(mi: MeshInstance3D, mask: int) -> void:
	if mi.mesh == null: return
	for i in range(mi.mesh.get_surface_count()):
		var cur = mi.get_surface_override_material(i)
		var sm: ShaderMaterial
		if cur is ShaderMaterial:
			sm = cur
		else:
			var m = mi.mesh.surface_get_material(i)
			if not (m is BaseMaterial3D) or m.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
				continue
			sm = ShaderMaterial.new()
			sm.shader = REGION_SHADER
			# CHAR-EDITOR: hair is drawn double-sided (the puffs' shells had see-through gaps, a curtain's
			# inside showed the background from below); Godot flips a back face's normal itself
			var hp := str(mi.get_meta("piece", ""))
			if hp != "" and pieces.has(hp) and str(pieces[hp].slot) == "hair" and CharFit.enabled():   # (off: the QA "before" grid)
				sm.shader = hair_shader()
			sm.resource_name = m.resource_name
			sm.set_shader_parameter("albedo_color", m.albedo_color * NpcBody.tint)
			if m.albedo_texture:
				sm.set_shader_parameter("albedo_tex", m.albedo_texture); sm.set_shader_parameter("has_albedo", true)
			if m.normal_enabled and m.normal_texture:
				sm.set_shader_parameter("normal_tex", m.normal_texture); sm.set_shader_parameter("has_normal", true)
				sm.set_shader_parameter("normal_strength", m.normal_scale)
			if m.roughness_texture:
				sm.set_shader_parameter("orm_tex", m.roughness_texture); sm.set_shader_parameter("has_orm", true)
			sm.set_shader_parameter("roughness", m.roughness)
			sm.set_shader_parameter("metallic", m.metallic)
			sm.set_shader_parameter("use_vertex_color", m.vertex_color_use_as_albedo)
			if str(m.resource_name).begins_with("skin_"):
				sm.set_shader_parameter("wrinkle_tex", load("res://models/characters/skin_wrinkle.png"))
				sm.set_shader_parameter("base_mask", base_mask())
				sm.set_shader_parameter("base_color", BASE_COLOR)
			if m.cull_mode == BaseMaterial3D.CULL_DISABLED:
				sm.render_priority = 0
			mi.set_surface_override_material(i, sm)
		sm.set_shader_parameter("hide_mask", mask)
		if str(sm.resource_name).begins_with("skin_"):
			sm.set_shader_parameter("wrinkle", float(values.get("age", 0.0)))

## The region shader drawn double-sided (hair), made once from REGION_SHADER's code.
static var _hair_sh: Shader = null
static func hair_shader() -> Shader:
	if _hair_sh == null:
		_hair_sh = Shader.new()
		_hair_sh.code = REGION_SHADER.code.replace("cull_back", "cull_disabled")
	return _hair_sh

## Paint (tint) every material whose name starts with mat_prefix: "skin_" = skin tone, "eye_iris",
## "lashes", "<piece id>_main" / "_trim" / "_accent" = a piece's colour regions.
func paint(mat_prefix: String, c: Color) -> void:
	for mi in sk.find_children("*", "MeshInstance3D", true, false):
		if mi.mesh == null: continue
		for i in range(mi.mesh.get_surface_count()):
			var m = mi.get_surface_override_material(i)
			if m == null: m = mi.mesh.surface_get_material(i)
			if m == null or not str(m.resource_name).begins_with(mat_prefix): continue
			if m is ShaderMaterial:
				m.set_shader_parameter("albedo_color", c * NpcBody.tint)
			elif m is BaseMaterial3D:
				var mm: BaseMaterial3D = m.duplicate()
				mm.albedo_color = c
				mi.set_surface_override_material(i, mm)
