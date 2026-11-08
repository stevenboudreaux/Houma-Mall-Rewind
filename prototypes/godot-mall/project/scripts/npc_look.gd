## An NPC looks at the camera while it is being talked to (workstream TALK, Nov 8 2026;
## design/godot-dialogue.md "The look"). Made and stopped by scripts/story/talk_camera.gd; one per
## conversation, a child of the talk camera node; it frees itself once the NPC is back to idle.
##
## Which rigs have eyes: none of them has eye bones. The UBC bodies (models/ubc, every attendant
## with "look": "preset") have a separate eye mesh skinned to the head and a fisheye iris texture, so
## the eyes are turned by sliding that texture (scripts/spatial_npc_eye.gdshader) and they blink (a
## lid-coloured wipe: the bodies have no eyelids). The Mixamo crowd skins (the Cuco's bartender, and
## any attendant before the web's character pack mounts) paint the eyes into the one body texture:
## head look-at only, no eye turn, no blink. If a rig ever has eye bones (a bone named *LeftEye /
## *RightEye), they are turned instead of the texture.
##
## Each frame: the gaze target is the camera (plus a saccade, eyes only). The head follows within
## head_yaw / head_pitch of the body's front with a slow ease (head_tau); the eyes lead with a fast
## one (eye_tau) and take the rest within eye_yaw / eye_pitch. The head turn goes through NpcRig's
## look (neck 40 %, head the rest) at a weight that blends in and out over blend_s, so the clip's own
## idle head comes back smoothly. All numbers: data/story/talk_camera.json "look", "eyes_ubc".
class_name NpcLook
extends Node

const EYE_SHADER := preload("res://scripts/spatial_npc_eye.gdshader")

var body: NpcBody
var target: Node3D
var cfg := {}
var ecfg := {}
var weight := 0.0
var stopping := false
var head := Vector2.ZERO          # degrees, body-relative (x yaw toward the body's +x, y pitch up)
var eyes := Vector2.ZERO          # degrees, head-relative
var blink := 0.0
var _sacc := Vector2.ZERO
var _sacc_t := 1.0
var _blink_t := 2.0
var _blink_age := -1.0
var _rng := RandomNumberGenerator.new()
var _sk: Skeleton3D
var _eye_mi: MeshInstance3D       # the UBC eye mesh, while its material is swapped
var _eye_surf := -1
var _eye_had: Material = null     # its surface override before the swap (null = none)
var _eye_mat: ShaderMaterial
var _eye_bind := Transform3D()    # the head's bind pose in the eye mesh's skin
var _eye_bones := []              # [bone, rest rotation] when a rig has eye bones

## Start looking at `at` (the talk camera). c: talk_camera.json's whole config.
func start(b: NpcBody, at: Node3D, c: Dictionary) -> void:
	body = b
	target = at
	cfg = c.get("look", {})
	ecfg = c.get("eyes_ubc", {})
	_rng.randomize()
	_sacc_t = _rng.randf_range(0.4, 1.0)
	_blink_t = _rng.randf_range(0.8, 2.0)
	_sk = skeleton(body)
	if _sk:
		for i in range(_sk.get_bone_count()):
			var n := _sk.get_bone_name(i)
			if n.ends_with("LeftEye") or n.ends_with("RightEye"):
				_eye_bones.append(i)
		if _eye_bones.is_empty():
			_swap_eyes()
		_sk.skeleton_updated.connect(_after_pose)
	set_process(true)

## Ease back to the idle head, then restore the eyes and free this node.
func stop() -> void:
	stopping = true

func _f(k: String, d: float) -> float:
	return float(cfg.get(k, d))

static func _ease(now, want, tau: float, dt: float):
	return now + (want - now) * (1.0 - exp(-dt / maxf(tau, 0.001)))

func _process(dt: float) -> void:
	if body == null or not is_instance_valid(body) or body.rig == null:
		_finish()
		return
	var blend := maxf(_f("blend_s", 0.35), 0.01)
	weight = clampf(weight + (dt / blend) * (-1.0 if stopping else 1.0), 0.0, 1.0)
	if stopping and weight <= 0.0:
		_finish()
		return
	# where the camera is, in the body's terms
	var want := Vector2.ZERO
	var e := eye_point(body)
	if target and is_instance_valid(target) and not stopping:
		var d := body.global_basis.orthonormalized().inverse() * (target.global_position - e)
		want = Vector2(rad_to_deg(atan2(d.x, d.z)), rad_to_deg(atan2(d.y, Vector2(d.x, d.z).length())))
	# saccades: small jumps of the eyes alone
	_sacc_t -= dt
	if _sacc_t <= 0.0:
		var r: Array = cfg.get("saccade_s", [0.6, 2.4])
		_sacc_t = _rng.randf_range(float(r[0]), float(r[1]))
		var a := _rng.randf() * TAU
		_sacc = Vector2(cos(a), sin(a) * 0.6) * _rng.randf_range(0.3, 1.0) * _f("saccade_deg", 1.6)
	var hy := _f("head_yaw", 40.0); var hp := _f("head_pitch", 22.0)
	head = _ease(head, Vector2(clampf(want.x, -hy, hy), clampf(want.y, -hp, hp)), _f("head_tau", 0.32), dt)
	var ey := _f("eye_yaw", 16.0); var ep := _f("eye_pitch", 10.0)
	var ew := want + (_sacc if not stopping else Vector2.ZERO) - head
	eyes = _ease(eyes, Vector2(clampf(ew.x, -ey, ey), clampf(ew.y, -ep, ep)), _f("eye_tau", 0.05), dt)
	# the head: through NpcRig's look, at the blend weight
	var dir := Vector3(sin(deg_to_rad(head.x)) * cos(deg_to_rad(head.y)), sin(deg_to_rad(head.y)),
		cos(deg_to_rad(head.x)) * cos(deg_to_rad(head.y)))
	body.rig.look = e + body.global_basis.orthonormalized() * dir * 3.0
	body.rig.look_weight = weight
	# blinks
	_blink_t -= dt
	if _blink_t <= 0.0 and _blink_age < 0.0:
		_blink_age = 0.0
		var br: Array = cfg.get("blink_s", [2.2, 5.5])
		_blink_t = _rng.randf_range(float(br[0]), float(br[1]))
	blink = 0.0
	if _blink_age >= 0.0:
		_blink_age += dt
		var bl := _f("blink_len", 0.16)
		blink = 1.0 - absf(_blink_age / bl * 2.0 - 1.0)
		if _blink_age >= bl:
			_blink_age = -1.0; blink = 0.0
	if _eye_mat:
		_eye_mat.set_shader_parameter("gaze", eyes * weight)
		_eye_mat.set_shader_parameter("blink", blink * weight)

## After the skeleton's final pose (NpcRig included): the eye shader's unpose, or the eye bones.
func _after_pose() -> void:
	if _sk == null or not is_instance_valid(_sk):
		return
	if not _eye_bones.is_empty():
		var q := Quaternion(Vector3.UP, deg_to_rad(eyes.x * weight)) * Quaternion(Vector3.LEFT, deg_to_rad(eyes.y * weight))
		for i in _eye_bones:
			_sk.set_bone_pose_rotation(i, (_sk.get_bone_pose_rotation(i) * q).normalized())
		return
	if _eye_mat == null or _eye_mi == null or not is_instance_valid(_eye_mi):
		return
	var h := head_bone(_sk)
	if h < 0:
		return
	# skinned (mesh space) = S · N · B · v, so v = B⁻¹ · N⁻¹ · S⁻¹ · skinned
	var S := _eye_mi.global_transform.affine_inverse() * _sk.global_transform
	var N := _sk.get_bone_global_pose(h)
	var un := (S * N * _eye_bind).affine_inverse()
	_eye_mat.set_shader_parameter("unpose", Projection(un))

## Swap the UBC eye surface for spatial_npc_eye, copying its look; _restore_eyes() undoes it.
func _swap_eyes() -> void:
	for mi in body.skin.find_children("*", "MeshInstance3D", true, false) if body.skin else []:
		if mi.mesh == null or mi.skin == null:
			continue
		for i in range(mi.mesh.get_surface_count()):
			var cur = mi.get_surface_override_material(i)
			var m = cur if cur else mi.mesh.surface_get_material(i)
			if m == null or not str(m.resource_name).begins_with("eye_iris"):
				continue
			var em := ShaderMaterial.new()
			em.shader = EYE_SHADER
			em.resource_name = "eye_iris_talk"
			if m is ShaderMaterial:
				for k in ["albedo_color", "albedo_tex", "has_albedo", "roughness", "metallic"]:
					var v = m.get_shader_parameter(k)
					if v != null: em.set_shader_parameter(k, v)
			elif m is BaseMaterial3D:
				em.set_shader_parameter("albedo_color", m.albedo_color)
				if m.albedo_texture:
					em.set_shader_parameter("albedo_tex", m.albedo_texture); em.set_shader_parameter("has_albedo", true)
				em.set_shader_parameter("roughness", m.roughness)
			for k in ["center", "dx", "dy"]:
				var a: Array = ecfg.get(k, [])
				if a.size() == 2: em.set_shader_parameter(k, Vector2(float(a[0]), float(a[1])))
			em.set_shader_parameter("lid_top", float(ecfg.get("lid_top", 0.16)))
			em.set_shader_parameter("lid_color", _lid_color(mi) * float(ecfg.get("lid_k", 0.82)))
			# the head's bind pose in this mesh's skin
			var h := head_bone(_sk)
			for k in range(mi.skin.get_bind_count()):
				var bb := mi.skin.get_bind_bone(k)
				if bb < 0: bb = _sk.find_bone(str(mi.skin.get_bind_name(k)))
				if bb == h:
					_eye_bind = mi.skin.get_bind_pose(k)
			_eye_mi = mi; _eye_surf = i; _eye_had = cur; _eye_mat = em
			mi.set_surface_override_material(i, em)
			return

## The skin tone the lid is drawn in: the body's skin material colour.
func _lid_color(eye_mi: MeshInstance3D) -> Color:
	for mi in eye_mi.get_parent().find_children("*", "MeshInstance3D", false, false):
		if mi.mesh == null: continue
		for i in range(mi.mesh.get_surface_count()):
			var m = mi.get_surface_override_material(i)
			if m == null: m = mi.mesh.surface_get_material(i)
			if m and str(m.resource_name).begins_with("skin_"):
				if m is ShaderMaterial and m.get_shader_parameter("albedo_color") is Color:
					return m.get_shader_parameter("albedo_color")
				if m is BaseMaterial3D:
					return m.albedo_color
	return Color(0.75, 0.58, 0.48)

func _restore_eyes() -> void:
	if _eye_mi and is_instance_valid(_eye_mi) and _eye_surf >= 0 \
			and _eye_mi.get_surface_override_material(_eye_surf) == _eye_mat:
		_eye_mi.set_surface_override_material(_eye_surf, _eye_had)
	_eye_mi = null; _eye_mat = null; _eye_surf = -1

func _finish() -> void:
	weight = 0.0
	if body and is_instance_valid(body) and body.rig:
		body.rig.look = Vector3.INF
		body.rig.look_weight = 1.0
	_restore_eyes()
	if _sk and is_instance_valid(_sk) and _sk.skeleton_updated.is_connected(_after_pose):
		_sk.skeleton_updated.disconnect(_after_pose)
	set_process(false)
	if not is_queued_for_deletion():
		queue_free()

## Freed early (the wing unloads, the body is rebuilt): leave nothing behind.
func _exit_tree() -> void:
	if _eye_mat != null or weight > 0.0:
		weight = 0.0
		_restore_eyes()
		if body and is_instance_valid(body) and body.rig:
			body.rig.look = Vector3.INF
			body.rig.look_weight = 1.0

# ------------------------------------------------------------------ where the eyes are
static func skeleton(b: NpcBody) -> Skeleton3D:
	if b == null or b.skin == null:
		return null
	return b.skin.find_child("Skeleton3D", true, false) as Skeleton3D

static func head_bone(sk: Skeleton3D) -> int:
	for n in ["mixamorig_Head", "mixamorig:Head", "Head"]:
		var i := sk.find_bone(n)
		if i >= 0: return i
	for i in range(sk.get_bone_count()):
		if sk.get_bone_name(i).ends_with("Head"): return i
	return -1

## The point between the eyes, in the world, as the head is posed now: from the head bone, so it is
## right for every body height and shape (npc_body.gd eye_pos() reads the skin's nominal height).
## UBC bodies: the eye mesh's centre carried by the head's bind pose. Mixamo skins (no eye mesh):
## MIXAMO_EYE in the body's frame at rest, scaled by height.
const MIXAMO_EYE := Vector2(0.095, 0.085)    # m above / in front of the head bone, for a 1.75 m skin
static func eye_point(b: NpcBody) -> Vector3:
	var sk := skeleton(b)
	if sk == null:
		return b.eye_pos() if b else Vector3.ZERO
	var h := head_bone(sk)
	if h < 0:
		return b.eye_pos()
	var key := "talk_eye_off_%d" % b.skin.get_instance_id()
	var off = b.get_meta(key, null)
	if off == null:
		off = _eye_offset(b, sk, h)
		b.set_meta(key, off)
	return sk.global_transform * sk.get_bone_global_pose(h) * (off as Vector3)

## The eyes in the head bone's own frame.
static func _eye_offset(b: NpcBody, sk: Skeleton3D, h: int) -> Vector3:
	for mi in sk.find_children("*", "MeshInstance3D", true, false):
		if mi.mesh == null or mi.skin == null: continue
		var is_eye := false
		for i in range(mi.mesh.get_surface_count()):
			var m = mi.mesh.surface_get_material(i)
			if m and str(m.resource_name).begins_with("eye_iris"): is_eye = true
		if not is_eye: continue
		var c: Vector3 = mi.get_aabb().get_center()
		for k in range(mi.skin.get_bind_count()):
			var bb := mi.skin.get_bind_bone(k)
			if bb < 0: bb = sk.find_bone(str(mi.skin.get_bind_name(k)))
			if bb == h:
				return mi.skin.get_bind_pose(k) * c
	# Mixamo: MIXAMO_EYE in the body's frame, from the head as it rests
	var k := float(b.entry.get("height_m", 1.75)) / 1.75
	var hr := sk.global_transform * sk.get_bone_global_rest(h)
	var w := hr.origin + b.global_basis.orthonormalized() * Vector3(0, MIXAMO_EYE.x * k, MIXAMO_EYE.y * k)
	return hr.affine_inverse() * w
