## The cast (design/godot-cast.md): fixed people built by tools/blender/cast/build.py, one file per
## person (res://cast/<id>.glb + its textures + res://cast/<id>.json). Cast.body(id) is the ONLY way any
## view (world, menu portrait, talk camera, attendants) makes a cast person: same id, same file, same
## class (NpcBody), so a view can never pick a body of its own.
##
## No fallback: an unknown or missing id returns null and logs an error; nothing stands in and swaps
## later. Preloading the files behind the loading card is the caller's job (npc_warmup.gd style).
##
## Each .glb holds one skeleton (Mixamo names, Ch01's rest: npc/anims.res plays unchanged, plus eye.L,
## eye.R and jaw under mixamorig_Head) and the skinned meshes of two LODs: <id>_lod0 (and, for Rocketbox
## people, <id>_lod0_face: the head and hair surfaces carrying the morphs, so the body's vertices carry
## none) and <id>_lod1 (crowd density, no morphs). LOD0 shows up to `lod_switch_m`, LOD1 beyond.
class_name CastGlb
extends RefCounted

const DIR := "res://cast/"
static var _meta := {}

## The person's build record (cast/<id>.json): hips, height_m, morphs, jaw_open_deg, lod_switch_m ...
static func meta(id: String) -> Dictionary:
	if not _meta.has(id):
		var p := DIR + id + ".json"
		var j = JSON.parse_string(FileAccess.get_file_as_string(p)) if FileAccess.file_exists(p) else null
		_meta[id] = j if j is Dictionary else {}
	return _meta[id]

static func exists(id: String) -> bool:
	return not meta(id).is_empty() and ResourceLoader.exists(DIR + id + ".glb")

## Every built cast id (from res://cast/*.json).
static func ids() -> PackedStringArray:
	var out := PackedStringArray()
	for f in DirAccess.get_files_at(DIR):
		if f.ends_with(".json"): out.append(f.get_basename())
	out.sort()
	return out

## Make the person. The caller adds it to the tree, places and faces it (NpcBody.face / play / set_speed).
static func body(id: String) -> NpcBody:
	if not exists(id):
		push_error("Cast.body: no cast member '%s' (res://cast/%s.glb)" % [id, id])
		return null
	var m := meta(id)
	var nb := NpcBody.new()
	nb.name = "Cast_" + id
	nb.set_meta("cast", id)
	nb.set_skin({"id": id, "scn": DIR + id + ".glb", "hips": float(m.get("hips", 1.0)),
		"height_m": float(m.get("height_m", 1.7)), "cast": id})
	var sw := float(m.get("lod_switch_m", 9.0))
	if not lod_meshes(nb, 0).is_empty() and not lod_meshes(nb, 1).is_empty():
		for mi in lod_meshes(nb, 0):
			mi.visibility_range_end = sw
			mi.visibility_range_end_margin = 0.5
		for mi in lod_meshes(nb, 1):
			mi.visibility_range_begin = sw
			mi.visibility_range_begin_margin = 0.5
	return nb

static func id_of(nb: Node) -> String:
	return str(nb.get_meta("cast", "")) if nb else ""

## Every mesh of one LOD (<id>_lod0, <id>_lod0_face ...).
static func lod_meshes(nb: NpcBody, lod: int) -> Array:
	var out := []
	if nb == null or nb.skin == null: return out
	for mi in nb.skin.find_children("*", "MeshInstance3D", true, false):
		var n := str(mi.name)
		if n.contains("_lod%d" % lod): out.append(mi)
	return out

## The LOD's mesh that carries the face morphs (the only one, on the MakeHuman path).
static func lod_mesh(nb: NpcBody, lod: int) -> MeshInstance3D:
	var all := lod_meshes(nb, lod)
	for mi in all:
		if mi.mesh and mi.mesh.get_blend_shape_count() > 0: return mi
	return all[0] if not all.is_empty() else null

static func skeleton(nb: NpcBody) -> Skeleton3D:
	return nb.skin.find_child("Skeleton3D", true, false) as Skeleton3D if nb and nb.skin else null

## A face morph (blink_L, smile, jaw_open, brow_up ... the list is meta(id).morphs), 0..1.
static func set_morph(nb: NpcBody, morph: String, v: float) -> bool:
	var mi := lod_mesh(nb, 0)
	if mi == null: return false
	var i := mi.find_blend_shape_by_name(morph)
	if i < 0: return false
	mi.set_blend_shape_value(i, v)
	return true

static func get_morph(nb: NpcBody, morph: String) -> float:
	var mi := lod_mesh(nb, 0)
	if mi == null: return 0.0
	var i := mi.find_blend_shape_by_name(morph)
	return mi.get_blend_shape_value(i) if i >= 0 else 0.0

## Open the mouth 0..1: the jaw_open morph (lips, chin, cheeks) and the jaw bone (lower teeth and
## tongue) by the angle the build matched to the morph, so they always agree.
static func set_mouth(nb: NpcBody, v: float) -> void:
	set_morph(nb, "jaw_open", v)
	var sk := skeleton(nb)
	if sk == null: return
	var j := sk.find_bone("jaw")
	if j < 0: return
	var deg := float(meta(id_of(nb)).get("jaw_open_deg", 12.0))
	sk.set_bone_pose_rotation(j, _model_axis_rot(sk, j, Vector3.RIGHT, deg_to_rad(deg * v)))

## Turn both eyes toward a world point (each clamped to `max_deg` off the head's forward), or back to
## rest with Vector3.INF. Eye bones are not animated by the clips, so this stays until changed.
static func aim_eyes(nb: NpcBody, world: Vector3, max_deg := 25.0) -> void:
	var sk := skeleton(nb)
	if sk == null: return
	for n in ["eye.L", "eye.R"]:
		var b := sk.find_bone(n)
		if b < 0: continue
		var rest_l := sk.get_bone_rest(b).basis.get_rotation_quaternion()
		if world == Vector3.INF:
			sk.set_bone_pose_rotation(b, rest_l); continue
		var head := sk.get_bone_parent(b)
		var hg := sk.global_transform * sk.get_bone_global_pose(head)
		var eye_w := hg * sk.get_bone_rest(b).origin
		# the head's forward in world space: the model's +Z at rest carried by the head's pose
		var rest_q := sk.get_bone_global_rest(head).basis.get_rotation_quaternion()
		var fwd_w := hg.basis.get_rotation_quaternion() * rest_q.inverse() * Vector3.BACK
		var want := (world - eye_w).normalized()
		var ang := fwd_w.angle_to(want)
		if ang > deg_to_rad(max_deg):
			want = fwd_w.slerp(want, deg_to_rad(max_deg) / ang).normalized()
		var dq := Quaternion(fwd_w.normalized(), want)
		# world delta on top of the eye's rest, in its parent's (the head's) frame
		var hq := hg.basis.get_rotation_quaternion()
		sk.set_bone_pose_rotation(b, (hq.inverse() * dq * hq * rest_l).normalized())

## Where an eye looks now (world direction): the model's +Z carried by the eye's pose.
static func eye_dir(nb: NpcBody, bone := "eye.L") -> Vector3:
	var sk := skeleton(nb)
	var b := sk.find_bone(bone) if sk else -1
	if b < 0: return Vector3.ZERO
	var g := sk.global_transform.basis.get_rotation_quaternion() * sk.get_bone_global_pose(b).basis.get_rotation_quaternion()
	return g * sk.get_bone_global_rest(b).basis.get_rotation_quaternion().inverse() * Vector3.BACK

## The bone's local pose turned by `ang` about a MODEL-space axis (as it lies at rest).
static func _model_axis_rot(sk: Skeleton3D, b: int, axis_model: Vector3, ang: float) -> Quaternion:
	var rq := sk.get_bone_global_rest(b).basis.get_rotation_quaternion()
	var rl := sk.get_bone_rest(b).basis.get_rotation_quaternion()
	return (rl * Quaternion((rq.inverse() * axis_model).normalized(), ang)).normalized()
