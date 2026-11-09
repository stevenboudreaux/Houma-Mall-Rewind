## Per-skin pose fix-up for NPC bodies (scripts/npc_body.gd), run by the skeleton every frame
## after the AnimationPlayer has written the clip's pose (Skeleton3D restores the clip's pose
## before the next frame, so nothing here accumulates).
##
## 1. Retarget. The clips were authored on Ch01's skeleton (tools/npc/bake_clips.gd records its
##    global rest rotations in npc/anims.json). For each animated bone b with parent p:
##      L_skin = Gt(p)⁻¹ · Gs(p) · L_clip · Gs(b)⁻¹ · Gt(b)
##    (G = global rest rotation, s = clip skeleton, t = this skin): the same motion relative to
##    each skeleton's own T-pose. The hips' position is scaled by the skins' hips-height ratio.
## 2. Hands (optional): two-bone arm IK to world targets (an arcade panel's stick and buttons),
##    offset by the clip's own hand motion around its running average, so the fingers and wrists
##    keep the clip's life while the hands stay on the controls.
## 3. Look (optional): neck and head turn toward a world point (the arcade screen), ≤ 60°.
class_name NpcRig
extends SkeletonModifier3D

var hands := {}:                # "Left"/"Right" -> world target
	set(v):
		hands = v
		_avg = {}               # a fresh grip: the running mean starts over
var look := Vector3.INF
var look_weight := 1.0          # TALK (scripts/npc_look.gd): blends the look in and out of the clip's own head
var ratio := 1.0
var _fix := []                  # [bone, A, B]
var _hips := -1
var _avg := {}                  # side -> running mean of the clip's hand position (skeleton space)
var _bones := {}
var dbg := {}                   # QA: last solved hand positions (world) per side

func setup(sk: Skeleton3D, hips_ratio: float) -> void:
	ratio = hips_ratio
	var rest: Dictionary = NpcBody.meta().get("rest", {})
	for i in range(sk.get_bone_count()):
		var n := sk.get_bone_name(i)
		_bones[n] = i
		if n.ends_with("_Hips"): _hips = i
		if not rest.has(n): continue
		var p := sk.get_bone_parent(i)
		var gs_b := _q(rest[n])
		var gt_b := sk.get_bone_global_rest(i).basis.get_rotation_quaternion()
		var gs_p := Quaternion(); var gt_p := Quaternion()
		if p >= 0 and rest.has(sk.get_bone_name(p)):
			gs_p = _q(rest[sk.get_bone_name(p)])
			gt_p = sk.get_bone_global_rest(p).basis.get_rotation_quaternion()
		var A := (gt_p.inverse() * gs_p).normalized()
		var B := (gs_b.inverse() * gt_b).normalized()
		if A.angle_to(Quaternion()) > 0.002 or B.angle_to(Quaternion()) > 0.002:
			_fix.append([i, A, B])

static func _q(a: Array) -> Quaternion:
	return Quaternion(float(a[0]), float(a[1]), float(a[2]), float(a[3])).normalized()

func _process_modification() -> void:
	var sk := get_skeleton()
	if sk == null: return
	for f in _fix:
		var i: int = f[0]
		sk.set_bone_pose_rotation(i, (f[1] * sk.get_bone_pose_rotation(i) * f[2]).normalized())
	if _hips >= 0 and absf(ratio - 1.0) > 0.001:
		sk.set_bone_pose_position(_hips, sk.get_bone_pose_position(_hips) * ratio)
	if not hands.is_empty():
		_lean(sk)
		var dt := get_process_delta_time()
		for side in hands:
			_arm(sk, side, hands[side], dt)
	if look != Vector3.INF:
		_look(sk)

func _bone(n: String) -> int:
	return int(_bones.get(n, -1))

## Mixamo arms are short (~0.49 m shoulder to wrist): when the controls are out of reach, bend the
## spine forward over the panel (up to ~23° over three spine bones), as a player leans in.
func _lean(sk: Skeleton3D) -> void:
	var inv := sk.global_transform.affine_inverse()
	var short := 0.0
	for side in hands:
		var up := _bone("mixamorig_" + side + "Arm"); var fo := _bone("mixamorig_" + side + "ForeArm"); var ha := _bone("mixamorig_" + side + "Hand")
		if up < 0 or fo < 0 or ha < 0: continue
		var S := _gp(sk, up).origin; var E := _gp(sk, fo).origin; var Wr := _gp(sk, ha).origin
		short = maxf(short, S.distance_to(inv * (hands[side] as Vector3)) - (S.distance_to(E) + E.distance_to(Wr)) + 0.04)
	if short <= 0.0: return
	var upv := (inv.basis * Vector3.UP).normalized()
	var axis := upv.cross(_fwd(sk)).normalized()
	var th := clampf(short * 3.6, 0.0, 0.45)
	for n in ["mixamorig_Spine", "mixamorig_Spine1", "mixamorig_Spine2"]:
		var i := _bone(n)
		if i >= 0: _rot(sk, i, Quaternion(axis, th / 3.0))

## The body's facing (+Z of the NPC) in skeleton space.
func _fwd(sk: Skeleton3D) -> Vector3:
	var inv := sk.global_transform.affine_inverse()
	var body := sk.get_parent_node_3d()
	while body and not (body is NpcBody): body = body.get_parent_node_3d()
	return (inv.basis * (body.global_transform.basis.z if body else Vector3.BACK)).normalized()

## Two-bone IK: the elbow from the law of cosines, bent toward a pole below and behind.
func _arm(sk: Skeleton3D, side: String, target_w: Vector3, dt: float) -> void:
	var up := _bone("mixamorig_" + side + "Arm")
	var fo := _bone("mixamorig_" + side + "ForeArm")
	var ha := _bone("mixamorig_" + side + "Hand")
	if up < 0 or fo < 0 or ha < 0: return
	var inv := sk.global_transform.affine_inverse()
	var hp: Vector3 = _gp(sk, ha).origin
	# the clip's own hand motion around its running mean (texting thumbs become stick work)
	if not _avg.has(side): _avg[side] = hp
	_avg[side] = (_avg[side] as Vector3).lerp(hp, 1.0 - exp(-dt / 2.5))
	var wiggle: Vector3 = ((hp - _avg[side]) * 0.5).limit_length(0.03)
	var t: Vector3 = inv * target_w + wiggle
	var S: Vector3 = _gp(sk, up).origin
	var E: Vector3 = _gp(sk, fo).origin
	var Wr: Vector3 = hp
	var a := S.distance_to(E); var b := E.distance_to(Wr)
	var to_t := t - S
	var d := clampf(to_t.length(), 0.05, a + b - 0.01)
	var dir := to_t.normalized()
	var cos_s := clampf((a * a + d * d - b * b) / (2.0 * a * d), -1.0, 1.0)
	var hq: Quaternion = _gp(sk, 0).basis.get_rotation_quaternion()
	var pole: Vector3 = hq * Vector3(0.6 if side == "Right" else -0.6, -1.0, -0.4)
	var side_v := (pole - pole.project(dir)).normalized()
	if side_v.length_squared() < 1e-4: side_v = Vector3.DOWN
	var E1: Vector3 = S + (dir * cos_s + side_v * sin(acos(cos_s))) * a
	_turn(sk, up, E - S, E1 - S)
	E = _gp(sk, fo).origin
	Wr = _gp(sk, ha).origin
	_turn(sk, fo, Wr - E, (S + dir * d) - E)
	dbg[side] = [sk.global_transform * _gp(sk, ha).origin, target_w, sk.global_transform * hp]

## Neck 40 %, head the rest, toward `look`; nothing past 60°.
func _look(sk: Skeleton3D) -> void:
	var hd := _bone("mixamorig_Head"); var nk := _bone("mixamorig_Neck")
	if hd < 0 or nk < 0: return
	var inv := sk.global_transform.affine_inverse()
	var body_fwd := _fwd(sk)
	for k in [[nk, 0.4], [hd, 1.0]]:
		var b: int = k[0]
		var g := _gp(sk, b)
		var rest_q := sk.get_bone_global_rest(b).basis.get_rotation_quaternion()
		var now_q := g.basis.get_rotation_quaternion()
		var fwd: Vector3 = (now_q * rest_q.inverse()) * body_fwd
		var want: Vector3 = (inv * look - g.origin).normalized()
		if fwd.angle_to(want) > deg_to_rad(60.0): return
		var q := Quaternion(fwd.normalized(), want)
		_rot(sk, b, Quaternion().slerp(q, float(k[1]) * look_weight))   # TALK: * look_weight

## Rotate bone `i` so the skeleton-space direction `from` becomes `to` (shortest arc).
func _turn(sk: Skeleton3D, i: int, from: Vector3, to: Vector3) -> void:
	if from.length_squared() < 1e-8 or to.length_squared() < 1e-8: return
	_rot(sk, i, Quaternion(from.normalized(), to.normalized()))

## Apply a skeleton-space rotation to bone `i`, in its local terms.
func _rot(sk: Skeleton3D, i: int, delta: Quaternion) -> void:
	var parent := sk.get_bone_parent(i)
	var pg := _gp(sk, parent).basis.get_rotation_quaternion() if parent >= 0 else Quaternion()
	var local_delta := pg.inverse() * delta * pg
	sk.set_bone_pose_rotation(i, (local_delta * sk.get_bone_pose_rotation(i)).normalized())

## A bone's skeleton-space pose from the local poses as they stand now (the modifier changes them
## during this pass, and the skeleton's cached global poses are not refreshed until afterwards).
func _gp(sk: Skeleton3D, i: int) -> Transform3D:
	if i < 0: return Transform3D()
	var t := sk.get_bone_pose(i)
	var p := sk.get_bone_parent(i)
	return _gp(sk, p) * t if p >= 0 else t
