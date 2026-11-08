## Eye bones and blink morphs on any body that has them (CHAR-BUILD, design/godot-cast.md "TALK"):
## the cast's .glb files (eye.L / eye.R, morphs blink_L / blink_R) and converted Rocketbox bodies
## (mixamorig_LeftEye / RightEye, ARKit EyeBlinkLeft / EyeBlinkRight). scripts/npc_look.gd uses this
## when a body has them and keeps its iris-texture slide for the bodies that don't.
##
## Eye turns are given as TALK gives them: degrees relative to the head (x = yaw toward the body's +x,
## y = pitch up), applied about the HEAD's current up / right axes in skeleton space, so they are right
## whatever rest orientation the eye bones carry (Ch01's rests are not axis-aligned).
class_name CastFace
extends RefCounted

const EYE_NAMES := ["eye.L", "eye.R"]
const BLINK := {"L": ["blink_L", "EyeBlinkLeft"], "R": ["blink_R", "EyeBlinkRight"]}
## Rocketbox's ARKit blink leaves a slit at 1.0; a little squint closes it (CHAR-SOURCES "faults").
const SQUINT := {"L": ["EyeSquintLeft"], "R": ["EyeSquintRight"]}
const SQUINT_K := 0.3

## Eye bone indices ([] when the rig has none).
static func eye_bones(sk: Skeleton3D) -> Array:
	var out := []
	if sk == null: return out
	for i in range(sk.get_bone_count()):
		var n := sk.get_bone_name(i)
		if n in EYE_NAMES or n.ends_with("LeftEye") or n.ends_with("RightEye"):
			out.append(i)
	return out

## Set the eye bones to yaw / pitch (degrees, head-relative) from their REST (the clips don't animate
## eye bones, so building on the current pose would add up frame after frame). Call after the
## skeleton's pose is final for the frame (Skeleton3D.skeleton_updated), or any time for a still shot.
static func turn_eyes(sk: Skeleton3D, bones: Array, yaw_deg: float, pitch_deg: float) -> void:
	if sk == null or bones.is_empty(): return
	for i in bones:
		var p := sk.get_bone_parent(i)
		if p < 0: continue
		var pg := sk.get_bone_global_pose(p).basis.get_rotation_quaternion()
		var pr := sk.get_bone_global_rest(p).basis.get_rotation_quaternion()
		var rel := pg * pr.inverse()                       # the head's turn from its rest, skeleton space
		var up := rel * Vector3.UP
		var right := rel * Vector3.RIGHT
		var r := Quaternion(up, deg_to_rad(yaw_deg)) * Quaternion(right, deg_to_rad(-pitch_deg))
		var g := pg * sk.get_bone_rest(i).basis.get_rotation_quaternion()
		sk.set_bone_pose_rotation(i, (pg.inverse() * r * g).normalized())

## [[MeshInstance3D, blend shape index, side "L"/"R", weight], ...] for the body's blink morphs.
static func blink_shapes(root: Node) -> Array:
	var out := []
	if root == null: return out
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		if mi.mesh == null: continue
		for side in ["L", "R"]:
			for n in BLINK[side]:
				var i: int = mi.find_blend_shape_by_name(n)
				if i >= 0: out.append([mi, i, side, 1.0])
			for n in SQUINT[side]:
				var i: int = mi.find_blend_shape_by_name(n)
				if i >= 0 and _has(mi, BLINK[side]): out.append([mi, i, side, SQUINT_K])
	return out

static func _has(mi: MeshInstance3D, names: Array) -> bool:
	for n in names:
		if mi.find_blend_shape_by_name(n) >= 0: return true
	return false

## Close both eyes by v (0 open .. 1 shut).
static func set_blink(shapes: Array, v: float) -> void:
	for s in shapes:
		var mi: MeshInstance3D = s[0]
		if is_instance_valid(mi): mi.set_blend_shape_value(int(s[1]), clampf(v * float(s[3]), 0.0, 1.0))
