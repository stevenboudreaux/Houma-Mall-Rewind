## CHAR-BUILD: every cast file through the one loader (scripts/cast.gd), headless.
##   godot --headless --path . --script res://tools/qa/cast_test.gd [-- --id=<id>]
## For each res://cast/<id>.json: CastGlb.body(id) loads; the skeleton has every bone npc_rig.gd retargets
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
	var ids := CastGlb.ids()
	_check(ids.size() > 0, "cast ids found: %s" % ", ".join(ids))
	var rest: Dictionary = NpcBody.meta().get("rest", {})
	for id in ids:
		if only != "" and id != only: continue
		await _one(id, rest)
	var nb := CastGlb.body("no_such_person")
	_check(nb == null, "unknown id -> null (no fallback body)")
	print(("CAST TEST OK (%d checks)" % oks) if errors.is_empty() else ("CAST TEST FAILED: %d of %d\n  " % [errors.size(), errors.size() + oks]) + "\n  ".join(errors))
	quit(0 if errors.is_empty() else 1)

func _one(id: String, rest: Dictionary) -> void:
	var m := CastGlb.meta(id)
	var nb := CastGlb.body(id)
	_check(nb != null, "%s: CastGlb.body loads" % id)
	if nb == null: return
	root.add_child(nb)
	_check(CastGlb.id_of(nb) == id, "%s: body carries its cast id" % id)
	var sk := CastGlb.skeleton(nb)
	_check(sk != null, "%s: one Skeleton3D" % id)
	_check(nb.find_children("*", "Skeleton3D", true, false).size() == 1, "%s: exactly one skeleton under the body" % id)
	var missing := []
	for bn in rest:
		# leaf bones (*_End, finger *4) carry no skin and no clip motion; Rocketbox has none
		if bn.ends_with("_End") or bn.ends_with("4"): continue
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
	var l0 := CastGlb.lod_mesh(nb, 0); var l1 := CastGlb.lod_mesh(nb, 1)
	_check(l0 != null and l1 != null, "%s: LOD0 and LOD1 meshes" % id)
	if l0 == null or l1 == null: return
	var t0 := 0; var t1 := 0; var s0 := 0; var s1 := 0
	for mi in CastGlb.lod_meshes(nb, 0): t0 += _tris(mi); s0 += mi.mesh.get_surface_count()
	for mi in CastGlb.lod_meshes(nb, 1): t1 += _tris(mi); s1 += mi.mesh.get_surface_count()
	_check(t0 <= 15000, "%s: LOD0 %d tris <= 15000" % [id, t0])
	_check(t1 <= 6000, "%s: LOD1 %d tris <= 6000" % [id, t1])
	_check(s0 <= 3 and s1 <= 3, "%s: surfaces %d / %d (<= 3 draw calls per LOD)" % [id, s0, s1])
	var lods_ok := true
	for mi in CastGlb.lod_meshes(nb, 0): lods_ok = lods_ok and mi.visibility_range_end > 0 and mi.visibility_range_end == l1.visibility_range_begin
	_check(lods_ok, "%s: LOD switch at %.1f m on every mesh" % [id, l1.visibility_range_begin])
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
		if mv < 0.001 and mn != "viseme_Sil": still.append("%s %.4f" % [mn, mv])   # Sil = the neutral viseme
		for x in [0.0, 1.0, 0.0]:
			CastGlb.set_morph(nb, mn, x)
			if absf(CastGlb.get_morph(nb, mn) - x) > 1e-4: bad.append(mn + "@" + str(x))
	_check(bad.is_empty(), "%s: %d morphs exist and drive 0 -> 1 -> 0%s" % [id, morphs.size(), "" if bad.is_empty() else " " + str(bad)])
	_check(still.is_empty(), "%s: every morph moves the mesh > 1 mm%s" % [id, "" if still.is_empty() else " " + str(still)])
	var nm1 := 0
	for mi in CastGlb.lod_meshes(nb, 1): nm1 += mi.mesh.get_blend_shape_count()
	_check(nm1 == 0, "%s: LOD1 carries no morphs" % id)
	# eyes and jaw
	nb.play("idle", 0.0, false)
	nb.face(Vector3(-1, 0, -0.3))          # turned, so a wrong frame would show
	await process_frame
	var eL := sk.find_bone("eye.L")
	var g0 := sk.get_bone_global_pose(eL).basis.get_rotation_quaternion()
	var target := nb.global_position + Vector3(1.5, 1.6, 2.0)
	CastGlb.aim_eyes(nb, target)
	await process_frame
	var g1 := sk.get_bone_global_pose(eL).basis.get_rotation_quaternion()
	_check(g0.angle_to(g1) > deg_to_rad(5), "%s: eye.L turns toward a point (%.1f deg)" % [id, rad_to_deg(g0.angle_to(g1))])
	var eye_w: Vector3 = sk.global_transform * sk.get_bone_global_pose(eL).origin
	var near := nb.global_position + nb.global_basis.z * 2.0 + Vector3(0.25, 1.7, 0)
	CastGlb.aim_eyes(nb, near)
	await process_frame
	eye_w = sk.global_transform * sk.get_bone_global_pose(eL).origin
	var miss := rad_to_deg(CastGlb.eye_dir(nb).angle_to(near - eye_w))
	_check(miss < 3.0, "%s: eye.L looks at a point in front within 3 deg (%.1f)" % [id, miss])
	CastGlb.aim_eyes(nb, Vector3.INF)
	# CastFace (what npc_look.gd uses): head-relative yaw lands where asked, twice gives the same pose
	var eb := CastFace.eye_bones(sk)
	_check(eb.size() == 2, "%s: CastFace finds 2 eye bones" % id)
	var d0 := CastGlb.eye_dir(nb)
	CastFace.turn_eyes(sk, eb, 12.0, 0.0)
	var q1 := sk.get_bone_pose_rotation(eb[0])
	CastFace.turn_eyes(sk, eb, 12.0, 0.0)
	var d1 := CastGlb.eye_dir(nb)
	var side := d1.dot(nb.global_basis.x) - d0.dot(nb.global_basis.x)
	_check(absf(rad_to_deg(d0.angle_to(d1)) - 12.0) < 1.0 and side > 0 and sk.get_bone_pose_rotation(eb[0]).is_equal_approx(q1),
		"%s: CastFace.turn_eyes 12 deg toward the body's +x, no build-up (%.1f deg)" % [id, rad_to_deg(d0.angle_to(d1))])
	CastFace.turn_eyes(sk, eb, 0.0, 0.0)
	var bl := CastFace.blink_shapes(nb.skin)
	_check(bl.size() >= 2, "%s: CastFace finds the blink morphs (%d)" % [id, bl.size()])
	CastFace.set_blink(bl, 1.0)
	_check(absf(CastGlb.get_morph(nb, "blink_L") - 1.0) < 1e-4, "%s: CastFace.set_blink closes blink_L" % id)
	CastFace.set_blink(bl, 0.0)
	var jw := sk.find_bone("jaw")
	CastGlb.set_mouth(nb, 1.0)
	await process_frame
	var jq := sk.get_bone_pose_rotation(jw)
	var jdeg := float(m.get("jaw_open_deg", 0.0))
	var turned := rad_to_deg(jq.angle_to(sk.get_bone_rest(jw).basis.get_rotation_quaternion()))
	_check(absf(turned - jdeg) < 0.5 and absf(CastGlb.get_morph(nb, "jaw_open") - 1.0) < 1e-4, "%s: set_mouth(1): jaw_open + the jaw bone %.1f deg (build record %.1f)" % [id, turned, jdeg])
	CastGlb.set_mouth(nb, 0.0)
	nb.queue_free()
	await process_frame
