## CHAR-BUILD: every cast file through the one loader (scripts/cast.gd), headless.
##   godot --headless --path . --script res://tools/qa/cast_test.gd [-- --id=<id>]
## For each res://cast/<id>.json: Cast.body(id) loads; the skeleton has every bone npc_rig.gd retargets
## (npc/anims.json "rest", Mixamo names) plus eye.L / eye.R / jaw under mixamorig_Head; walk_m, idle and
## talk play and move the bones; every morph listed in the build record exists on LOD0, moves vertices
## (> 1 mm) and drives 0 -> 1 -> 0; the eye bones and the jaw turn; LOD0 / LOD1 within budget (15k / 6k
## tris, <= 3 surfaces); an unknown id returns null (no fallback body).
## Prints CAST TEST OK (n checks) or the failures; exit code 1 on failure.
extends SceneTree

var errors := []
var oks := 0

func _check(ok: bool, what: String) -> void:
	print(("ok   " if ok else "FAIL ") + what)
	if ok: oks += 1
	else: errors.append(what)

func _tris(mi: MeshInstance3D) -> int:
	var n := 0
	for s in mi.mesh.get_surface_count():
		var a := mi.mesh.surface_get_arrays(s)
		n += (a[Mesh.ARRAY_INDEX] as PackedInt32Array).size() / 3 if a[Mesh.ARRAY_INDEX] else (a[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3
	return n

func _initialize() -> void:
	var only := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--id="): only = a.substr(5)
	await process_frame
	var ids := Cast.ids()
	_check(ids.size() > 0, "cast ids found: %s" % ", ".join(ids))
	var rest: Dictionary = NpcBody.meta().get("rest", {})
	for id in ids:
		if only != "" and id != only: continue
		await _one(id, rest)
	var nb := Cast.body("no_such_person")
	_check(nb == null, "unknown id -> null (no fallback body)")
	print(("CAST TEST OK (%d checks)" % oks) if errors.is_empty() else ("CAST TEST FAILED: %d of %d\n  " % [errors.size(), errors.size() + oks]) + "\n  ".join(errors))
	quit(0 if errors.is_empty() else 1)

func _one(id: String, rest: Dictionary) -> void:
	var m := Cast.meta(id)
	var nb := Cast.body(id)
	_check(nb != null, "%s: Cast.body loads" % id)
	if nb == null: return
	root.add_child(nb)
	_check(Cast.id_of(nb) == id, "%s: body carries its cast id" % id)
	var sk := Cast.skeleton(nb)
	_check(sk != null, "%s: one Skeleton3D" % id)
	_check(nb.find_children("*", "Skeleton3D", true, false).size() == 1, "%s: exactly one skeleton under the body" % id)
	var missing := []
	for bn in rest:
		if sk.find_bone(bn) < 0: missing.append(bn)
	_check(missing.is_empty(), "%s: every retargeted bone of npc_rig.gd present (%d)%s" % [id, rest.size(), "" if missing.is_empty() else " missing " + str(missing)])
	var head := sk.find_bone("mixamorig_Head")
	for bn in ["eye.L", "eye.R", "jaw"]:
		var b := sk.find_bone(bn)
		_check(b >= 0 and sk.get_bone_parent(b) == head, "%s: %s under mixamorig_Head" % [id, bn])
	_check(nb.rig != null and nb.rig._fix.is_empty(), "%s: rest matches the clips' skeleton (NpcRig has nothing to retarget: %d)" % [id, nb.rig._fix.size() if nb.rig else -1])
	# clips play and move bones
	var hips := sk.find_bone("mixamorig_Hips"); var arm := sk.find_bone("mixamorig_LeftForeArm")
	for clip in ["walk_m", "idle", "talk"]:
		nb.play(clip, 0.0, false)
		await process_frame; await process_frame
		var a := sk.get_bone_pose_rotation(arm)
		var p0 := sk.get_bone_global_pose(arm).origin
		for i in 20: await process_frame
		var p1 := sk.get_bone_global_pose(arm).origin
		_check(nb.clip == clip and nb.ap.is_playing() and nb.ap.current_animation == "npc/" + clip, "%s: plays %s" % [id, clip])
		_check(p0.distance_to(p1) > 0.0005 or not a.is_equal_approx(sk.get_bone_pose_rotation(arm)), "%s: %s moves the forearm (%.4f m)" % [id, clip, p0.distance_to(p1)])
	# LODs
	var l0 := Cast.lod_mesh(nb, 0); var l1 := Cast.lod_mesh(nb, 1)
	_check(l0 != null and l1 != null, "%s: LOD0 and LOD1 meshes" % id)
	if l0 == null or l1 == null: return
	var t0 := _tris(l0); var t1 := _tris(l1)
	_check(t0 <= 15000, "%s: LOD0 %d tris <= 15000" % [id, t0])
	_check(t1 <= 6000, "%s: LOD1 %d tris <= 6000" % [id, t1])
	_check(l0.mesh.get_surface_count() <= 3 and l1.mesh.get_surface_count() <= 3, "%s: surfaces %d / %d (<= 3 draw calls each)" % [id, l0.mesh.get_surface_count(), l1.mesh.get_surface_count()])
	_check(l0.visibility_range_end > 0 and l1.visibility_range_begin == l0.visibility_range_end, "%s: LOD switch at %.1f m" % [id, l0.visibility_range_end])
	# morphs
	var morphs: Array = m.get("morphs", [])
	for want in ["blink_L", "blink_R", "smile", "jaw_open", "brow_up"]:
		_check(want in morphs, "%s: morph %s in the build record" % [id, want])
	var bad := []
	var still := []
	var rel: bool = (l0.mesh as ArrayMesh).blend_shape_mode == Mesh.BLEND_SHAPE_MODE_RELATIVE
	for mn in morphs:
		var bi := l0.find_blend_shape_by_name(mn)
		if bi < 0: bad.append(mn); continue
		var mv := 0.0
		for s in l0.mesh.get_surface_count():
			var base: PackedVector3Array = l0.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX]
			var bs: Array = l0.mesh.surface_get_blend_shape_arrays(s)
			var v: PackedVector3Array = bs[bi][Mesh.ARRAY_VERTEX]
			for k in range(0, v.size(), 3):
				mv = maxf(mv, v[k].length() if rel else (v[k] - base[k]).length())
		if mv < 0.001: still.append("%s %.4f" % [mn, mv])
		for x in [0.0, 1.0, 0.0]:
			Cast.set_morph(nb, mn, x)
			if absf(Cast.get_morph(nb, mn) - x) > 1e-4: bad.append(mn + "@" + str(x))
	_check(bad.is_empty(), "%s: %d morphs exist and drive 0 -> 1 -> 0%s" % [id, morphs.size(), "" if bad.is_empty() else " " + str(bad)])
	_check(still.is_empty(), "%s: every morph moves the mesh > 1 mm%s" % [id, "" if still.is_empty() else " " + str(still)])
	_check(l1.mesh.get_blend_shape_count() == 0, "%s: LOD1 carries no morphs" % id)
	# eyes and jaw
	nb.play("idle", 0.0, false)
	nb.face(Vector3(-1, 0, -0.3))          # turned, so a wrong frame would show
	await process_frame
	var eL := sk.find_bone("eye.L")
	var g0 := sk.get_bone_global_pose(eL).basis.get_rotation_quaternion()
	var target := nb.global_position + Vector3(1.5, 1.6, 2.0)
	Cast.aim_eyes(nb, target)
	await process_frame
	var g1 := sk.get_bone_global_pose(eL).basis.get_rotation_quaternion()
	_check(g0.angle_to(g1) > deg_to_rad(5), "%s: eye.L turns toward a point (%.1f deg)" % [id, rad_to_deg(g0.angle_to(g1))])
	var eye_w: Vector3 = sk.global_transform * sk.get_bone_global_pose(eL).origin
	var near := nb.global_position + nb.global_basis.z * 2.0 + Vector3(0.25, 1.7, 0)
	Cast.aim_eyes(nb, near)
	await process_frame
	eye_w = sk.global_transform * sk.get_bone_global_pose(eL).origin
	var miss := rad_to_deg(Cast.eye_dir(nb).angle_to(near - eye_w))
	_check(miss < 3.0, "%s: eye.L looks at a point in front within 3 deg (%.1f)" % [id, miss])
	Cast.aim_eyes(nb, Vector3.INF)
	var jw := sk.find_bone("jaw")
	Cast.set_mouth(nb, 1.0)
	await process_frame
	var jq := sk.get_bone_pose_rotation(jw)
	_check(rad_to_deg(jq.get_angle()) > 3.0 and absf(Cast.get_morph(nb, "jaw_open") - 1.0) < 1e-4, "%s: set_mouth(1) opens the jaw %.1f deg + jaw_open" % [id, rad_to_deg(jq.get_angle())])
	Cast.set_mouth(nb, 0.0)
	nb.queue_free()
	await process_frame
