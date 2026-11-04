## CHAR-EDITOR (design/godot-character-editor.md "Hair fit"): fitting hair to the body it is worn on.
##
## B1's hair is a shell on the Head bone whose blend shapes come from the 8 nearest head / neck skin
## vertices (tools/blender/characters/pieces.py). That follows the head, but not the shoulders, back and
## chest a long curtain hangs over: on a broad, heavy or busty body the shoulders and the shirt come up
## through the curtain. This fixes it at load, in the body's own mesh space (the A-pose bind every
## piece shares):
##   1. every obstacle surface (body skin and every worn piece except the hair itself, the eyes, teeth
##      and lashes) is evaluated at its current blend shape weights;
##   2. a hair vertex closer than CLEAR to the nearest obstacle vertex along its normal (or behind it)
##      is pushed out along that normal to CLEAR; the push is smoothed over the hair's neighbouring
##      vertices so the curtain moves as a whole, not as spikes;
##   3. the pushed positions go into the hair mesh's base vertices (its blend shapes are kept), so the
##      fit is exact at the body's current shape and a bake (CharPreset.bake) keeps it.
## The original hair mesh is kept on the MeshInstance (meta "fit_src"), so every slider change refits
## from the original, never from an already-pushed mesh.
## Then the curtain's skinning: below the Head joint the hair takes the weights of the skin it lies on
## (neck, shoulders, back, chest, and the little arm weight the shoulder blades carry; never skin that
## is mostly arm), blended in over BAND, so the clip's head turns and shoulder moves don't swing a long
## curtain or the braids through the shoulders and back: it moves like the shirt under it.
class_name CharFit
extends RefCounted

const CLEAR := 0.006          # m between a curtain / braid (below the Head joint) and what is under it
const CLEAR_SCALP := 0.0015   # m on the scalp (short styles are thin shells by design: a fade is 2-4 mm)
const INSIDE := 0.001         # QA: a hair vertex closer than this (or behind the surface) pokes through
const NEAR := 0.035           # m: obstacle vertices further than this don't push
const CELL := 0.02            # spatial hash cell, m
const SMOOTH := 2             # smoothing passes of the push over the hair's edges
const SKIP_MATS := ["eye", "teeth", "tongue", "lashes"]

## Off for the "before" pictures (tools/qa/char_hair_grid.gd --fit=0); on everywhere else.
static func enabled() -> bool:
	return bool(Engine.get_meta("char_hair_fit", true))

## The current, blended vertex positions and normals of one MeshInstance3D's mesh, all surfaces
## concatenated: [PackedVector3Array, PackedVector3Array].
static func blended(mi: MeshInstance3D) -> Array:
	var m := mi.mesh as ArrayMesh
	var V := PackedVector3Array()
	var N := PackedVector3Array()
	if m == null: return [V, N]
	var nb := m.get_blend_shape_count()
	var relative := m.blend_shape_mode == Mesh.BLEND_SHAPE_MODE_RELATIVE
	for s in range(m.get_surface_count()):
		var arr := m.surface_get_arrays(s)
		var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var n: PackedVector3Array = arr[Mesh.ARRAY_NORMAL] if arr[Mesh.ARRAY_NORMAL] != null else PackedVector3Array()
		if n.size() != v.size():
			n = PackedVector3Array(); n.resize(v.size())
		if nb > 0:
			var bsa := m.surface_get_blend_shape_arrays(s)
			var v0 := v.duplicate(); var n0 := n.duplicate()
			for i in range(mini(nb, bsa.size())):
				var w := mi.get_blend_shape_value(i)
				if absf(w) < 0.0001: continue
				var bv: PackedVector3Array = bsa[i][Mesh.ARRAY_VERTEX]
				var bn = bsa[i][Mesh.ARRAY_NORMAL]
				var has_bn: bool = bn is PackedVector3Array and (bn as PackedVector3Array).size() == v.size()
				for k in range(v.size()):
					v[k] += (bv[k] * w) if relative else ((bv[k] - v0[k]) * w)
				if has_bn:
					for k in range(n.size()):
						n[k] += ((bn as PackedVector3Array)[k] * w) if relative else (((bn as PackedVector3Array)[k] - n0[k]) * w)
		for k in range(n.size()): n[k] = n[k].normalized()
		V.append_array(v); N.append_array(n)
	return [V, N]

static func _skip(mi: MeshInstance3D) -> bool:
	if mi.mesh == null: return true
	for s in range(mi.mesh.get_surface_count()):
		var mat = mi.get_surface_override_material(s)
		if mat == null: mat = mi.mesh.surface_get_material(s)
		var nm := str(mat.resource_name) if mat else ""
		for k in SKIP_MATS:
			if nm.begins_with(k) or nm.contains("_" + k): return true
	return false

static func _hair_mis(cb: CharBody) -> Array:
	var out := []
	for mi in cb.sk.find_children("*", "MeshInstance3D", true, false):
		var pid := str(mi.get_meta("piece", ""))
		if pid != "" and cb.pieces.has(pid) and str(cb.pieces[pid].slot) == "hair": out.append(mi)
	return out

## The obstacles (body and worn pieces, not hair / eyes / teeth / lashes) in a spatial hash:
## {"V", "N", "grid": {Vector3i: PackedInt32Array}}.
static func obstacles(cb: CharBody) -> Dictionary:
	var V := PackedVector3Array(); var N := PackedVector3Array()
	for mi in cb.sk.find_children("*", "MeshInstance3D", true, false):
		var pid := str(mi.get_meta("piece", ""))
		if pid != "" and cb.pieces.has(pid) and str(cb.pieces[pid].slot) == "hair": continue
		if _skip(mi): continue
		var b := blended(mi)
		V.append_array(b[0]); N.append_array(b[1])
	var grid := {}
	for i in range(V.size()):
		var c := Vector3i((V[i] / CELL).floor())
		if not grid.has(c): grid[c] = PackedInt32Array()
		var arr: PackedInt32Array = grid[c]
		arr.append(i)
		grid[c] = arr      # packed arrays are values: write it back
	return {"V": V, "N": N, "grid": grid}

## The signed clearance of point p over the nearest obstacle vertex within NEAR (along that vertex's
## normal), and the normal: [found, clearance, normal].
static func _clearance(ob: Dictionary, p: Vector3) -> Array:
	var c := Vector3i((p / CELL).floor())
	var best := NEAR * NEAR
	var bi := -1
	var V: PackedVector3Array = ob.V
	var r := int(ceil(NEAR / CELL))
	for dx in range(-r, r + 1):
		for dy in range(-r, r + 1):
			for dz in range(-r, r + 1):
				var key := c + Vector3i(dx, dy, dz)
				if not ob.grid.has(key): continue
				var cell: PackedInt32Array = ob.grid[key]
				for i in cell:
					var d := V[i].distance_squared_to(p)
					if d < best:
						best = d
						bi = i
	if bi < 0: return [false, 0.0, Vector3.ZERO]
	var n: Vector3 = ob.N[bi]
	return [true, (p - V[bi]).dot(n), n]

## The push p needs to clear every surface under it by `want`: of the obstacle vertices within NEAR
## that p lies over (less than LAT from their normal line), the one p is deepest into / closest over
## decides (a shirt 3-7 mm over the skin wins over the skin: the nearest vertex alone could be the
## skin under it). Vector3.ZERO when p is clear.
const LAT := 0.015
static func _need(ob: Dictionary, p: Vector3, want: float) -> Vector3:
	var c := Vector3i((p / CELL).floor())
	var V: PackedVector3Array = ob.V
	var N: PackedVector3Array = ob.N
	var r := int(ceil(NEAR / CELL))
	var worst := 0.0
	var wn := Vector3.ZERO
	for dx in range(-r, r + 1):
		for dy in range(-r, r + 1):
			for dz in range(-r, r + 1):
				var key := c + Vector3i(dx, dy, dz)
				if not ob.grid.has(key): continue
				var cell: PackedInt32Array = ob.grid[key]
				for i in cell:
					var d := p - V[i]
					if d.length_squared() > NEAR * NEAR: continue
					var sd := d.dot(N[i])
					if (d - N[i] * sd).length() > LAT: continue
					var nd := want - sd
					if nd > worst:
						worst = nd
						wn = N[i]
	return wn * worst

## Hair vertices closer than INSIDE to what is under them (or behind it): Vector2i(inside, total).
## The QA number in tools/qa/char_hair_grid.gd.
static func inside_count(cb: CharBody) -> Vector2i:
	var ob := obstacles(cb)
	var bad := 0; var tot := 0
	for mi in _hair_mis(cb):
		var b := blended(mi)
		for p in (b[0] as PackedVector3Array):
			tot += 1
			if _need(ob, p, INSIDE) != Vector3.ZERO: bad += 1
	return Vector2i(bad, tot)

## Fit every worn hair to this body as it is now shaped (see the top of this file). Cheap enough to
## run on every slider change (one hair: ~1.5k vertices against ~20k obstacle vertices).
static func fit_hair(cb: CharBody) -> void:
	var hm := _hair_mis(cb)
	if hm.is_empty(): return
	var ob: Dictionary = {}
	for mi in hm:
		if not mi.has_meta("fit_src"):
			mi.set_meta("fit_src", mi.mesh)
		var src := mi.get_meta("fit_src") as ArrayMesh
		if mi.mesh != src:
			var keep := _shape_values(mi)
			var ov := []
			for i in range(mi.mesh.get_surface_count()): ov.append(mi.get_surface_override_material(i))
			mi.mesh = src
			_set_shape_values(mi, keep)
			for i in range(mini(ov.size(), src.get_surface_count())):
				if ov[i] != null: mi.set_surface_override_material(i, ov[i])
		if not enabled(): continue
		if ob.is_empty(): ob = obstacles(cb)
		_fit_one(mi, src, ob, cb)

static func _fit_one(mi: MeshInstance3D, src: ArrayMesh, ob: Dictionary, cb: CharBody) -> void:
	var b := blended(mi)
	var P: PackedVector3Array = b[0]
	var push := PackedVector3Array(); push.resize(P.size())
	var any := false
	var y_head := _joint_y(cb, "mixamorig_Head")
	var rad := _radial(cb, mi)
	for k in range(P.size()):
		var need := Vector3.ZERO
		if P[k].y < y_head - RAD_FROM:
			need = _radial_need(rad, P[k])
		else:
			var c := _clearance(ob, P[k])
			if c[0] and float(c[1]) < CLEAR_SCALP:
				need = (c[2] as Vector3) * (CLEAR_SCALP - float(c[1]))
		if need != Vector3.ZERO:
			push[k] = need
			any = true
	if not any:
		_reskin(mi, src, cb, PackedVector3Array())
		return
	# smooth the push over the mesh's edges (the max of a vertex's own push and its neighbours' mean),
	# so the curtain moves as a sheet
	var adj := _adjacency(src)
	for _pass in SMOOTH:
		var nxt := push.duplicate()
		for k in range(P.size()):
			var nb: Array = adj[k]
			if nb.is_empty(): continue
			var mean := Vector3.ZERO
			for j in nb: mean += push[j]
			mean /= nb.size()
			nxt[k] = push[k] if push[k].length() >= mean.length() else mean
		push = nxt
	_reskin(mi, src, cb, push)

## Below the jaw a curtain or a braid is fitted RADIALLY: around the body's vertical axis (the Neck joint
## down to Spine1), in bins of height x angle, the torso skin's outermost radius plus the clothes'
## allowance (CLOTH_GAP, more with an outer layer) plus CLEAR is the least radius a hair vertex may have.
## Radial, not along the nearest normal, so a curtain sunk several cm into a heavy back still comes out
## the right side, and arm vertices (which hang beside the body in the bind pose) are not obstacles.
const RAD_FROM := 0.02        # m below the Head joint where the radial fit starts
const RAD_DH := 0.012         # bin height, m
const RAD_DA := 6.0           # bin angle, degrees
const CLOTH_GAP := 0.002      # m over the outermost surface (the clothes are in the bins themselves)

static func _radial(cb: CharBody, hair: MeshInstance3D) -> Dictionary:
	# the skin and every worn piece's torso part (a piece's vertex weights are the body's, so the
	# sleeves drop out with the arms): the clothes as they really hang, loose backs included
	var t := _torso_skin(cb, hair, true)
	var gap := CLOTH_GAP
	var a := _joint_xz(cb, "mixamorig_Neck")
	var b := _joint_xz(cb, "mixamorig_Spine1")
	var bins := {}
	var V: PackedVector3Array = t.get("V", PackedVector3Array())
	for v in V:
		var ax := _axis_at(a, b, v.y)
		var d := Vector2(v.x - ax.x, v.z - ax.y)
		var key := Vector2i(int(floor(v.y / RAD_DH)), int(floor(rad_to_deg(atan2(d.x, d.y)) / RAD_DA)))
		bins[key] = maxf(float(bins.get(key, 0.0)), d.length())
	return {"bins": bins, "a": a, "b": b, "gap": gap}

## [x, z, y] of a joint's bind (rest) position: Vector3(x, z, y).
static func _joint_xz(cb: CharBody, bn: String) -> Vector3:
	var i := cb.sk.find_bone(bn)
	if i < 0: return Vector3.ZERO
	var o := cb.sk.get_bone_global_rest(i).origin
	return Vector3(o.x, o.z, o.y)

static func _axis_at(a: Vector3, b: Vector3, y: float) -> Vector2:
	var t := clampf((a.z - y) / maxf(a.z - b.z, 0.01), 0.0, 1.0)
	return Vector2(lerpf(a.x, b.x, t), lerpf(a.y, b.y, t))

static func _radial_need(rad: Dictionary, p: Vector3) -> Vector3:
	if rad.is_empty(): return Vector3.ZERO
	var ax := _axis_at(rad.a, rad.b, p.y)
	var d := Vector2(p.x - ax.x, p.z - ax.y)
	var r := d.length()
	if r < 0.001: return Vector3.ZERO
	var hy := int(floor(p.y / RAD_DH))
	var ha := int(floor(rad_to_deg(atan2(d.x, d.y)) / RAD_DA))
	var surf := 0.0
	for da in [-1, 0, 1]:
		var aa: int = ha + int(da)
		if aa < -30: aa += 60
		elif aa >= 30: aa -= 60
		surf = maxf(surf, float(rad.bins.get(Vector2i(hy, aa), 0.0)))
	if surf <= 0.0: return Vector3.ZERO
	var want: float = surf + float(rad.gap) + CLEAR
	if r >= want: return Vector3.ZERO
	var dir := d / r
	return Vector3(dir.x, 0.0, dir.y) * (want - r)

## Vertex neighbours over all surfaces (indices into the concatenated vertex list).
static func _adjacency(m: ArrayMesh) -> Array:
	var adj := []
	var base := 0
	for s in range(m.get_surface_count()):
		var arr := m.surface_get_arrays(s)
		var nv := (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
		for _i in nv: adj.append([])      # plain Arrays: they are references (packed arrays copy)
		var idx = arr[Mesh.ARRAY_INDEX]
		if idx != null:
			var I: PackedInt32Array = idx
			for t in range(0, I.size(), 3):
				for e in [[0, 1], [1, 2], [2, 0]]:
					var a := base + I[t + e[0]]; var c := base + I[t + e[1]]
					if not (adj[a] as Array).has(c): (adj[a] as Array).append(c)
					if not (adj[c] as Array).has(a): (adj[c] as Array).append(a)
		base += nv
	return adj

## A copy of the hair mesh with the push added to its base vertices (blend shapes kept) and the
## curtain's skinning moved down the neck (below the jaw). Materials are carried over.
static func _reskin(mi: MeshInstance3D, src: ArrayMesh, cb: CharBody, push: PackedVector3Array) -> void:
	# mesh bone indices are the Skin's bind indices, not skeleton bone indices
	var head := _bind_index(mi, cb, "mixamorig_Head")
	var b := blended(mi)
	var Pb: PackedVector3Array = b[0]
	var y_head := _joint_y(cb, "mixamorig_Head")
	var torso := {} if head < 0 else _torso_skin(cb, mi)
	var nm := ArrayMesh.new()
	nm.blend_shape_mode = src.blend_shape_mode
	for i in range(src.get_blend_shape_count()):
		nm.add_blend_shape(src.get_blend_shape_name(i))
	var overrides := []
	var base := 0
	for s in range(src.get_surface_count()):
		overrides.append(mi.get_surface_override_material(s))
		var arr := src.surface_get_arrays(s)
		var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		if not push.is_empty():
			for k in range(v.size()): v[k] += push[base + k]
		arr[Mesh.ARRAY_VERTEX] = v
		var fmt := src.surface_get_format(s)
		var eight := (fmt & Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS) != 0
		var per := 8 if eight else 4
		if arr[Mesh.ARRAY_BONES] != null and not torso.is_empty():
			var B: PackedInt32Array = arr[Mesh.ARRAY_BONES]
			var W: PackedFloat32Array = arr[Mesh.ARRAY_WEIGHTS]
			for k in range(v.size()):
				var p := Pb[base + k]
				if p.y >= y_head: continue
				# only the vertices B1 made rigid on the Head (every hair vertex today)
				if B[k * per] != head or W[k * per] < 0.99: continue
				# below the Head joint the hair rides what it lies on: the torso's own weights (neck,
				# shoulders, upper back, chest; never the arms), blended in over BAND metres
				var t := clampf((y_head - p.y) / BAND, 0.0, 1.0)
				t = t * t * (3.0 - 2.0 * t)
				var w := _torso_weights(torso, p)
				var acc := {head: 1.0 - t}
				for bi in w: acc[bi] = float(acc.get(bi, 0.0)) + float(w[bi]) * t
				var keys := acc.keys()
				keys.sort_custom(func(x, y): return float(acc[x]) > float(acc[y]))
				var tot := 0.0
				for q in mini(per, keys.size()): tot += float(acc[keys[q]])
				for q in per:
					B[k * per + q] = 0
					W[k * per + q] = 0.0
				for q in mini(per, keys.size()):
					B[k * per + q] = int(keys[q])
					W[k * per + q] = float(acc[keys[q]]) / maxf(tot, 0.0001)
			arr[Mesh.ARRAY_BONES] = B
			arr[Mesh.ARRAY_WEIGHTS] = W
		var bsa := src.surface_get_blend_shape_arrays(s)
		# B1's pieces are NORMALIZED blend shapes (absolute target positions: result = base x (1 - sum w)
		# + sum w x target), so the push goes into every target too, or a body with big weights would
		# scale it away
		if not push.is_empty() and src.blend_shape_mode == Mesh.BLEND_SHAPE_MODE_NORMALIZED:
			for j in range(bsa.size()):
				var tv: PackedVector3Array = bsa[j][Mesh.ARRAY_VERTEX]
				for k in range(tv.size()): tv[k] += push[base + k]
				bsa[j][Mesh.ARRAY_VERTEX] = tv
		nm.add_surface_from_arrays(src.surface_get_primitive_type(s), arr, bsa, {}, fmt & Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS)
		nm.surface_set_material(s, src.surface_get_material(s))
		nm.surface_set_name(s, src.surface_get_name(s))
		base += v.size()
	nm.resource_name = src.resource_name
	var keep := _shape_values(mi)
	mi.mesh = nm
	_set_shape_values(mi, keep)
	for s in range(overrides.size()):
		if overrides[s] != null: mi.set_surface_override_material(s, overrides[s])

const BAND := 0.07            # m below the Head joint over which hair goes from the Head to the torso
const TORSO_BONES := ["mixamorig_Hips", "mixamorig_Spine", "mixamorig_Spine1", "mixamorig_Spine2",
	"mixamorig_Neck", "mixamorig_Head", "mixamorig_LeftShoulder", "mixamorig_RightShoulder"]

## The body skin (body and head meshes) as positions + per-vertex torso weights, in the HAIR's bind
## indices, in a spatial hash: {"V", "W": [{bind: w}], "grid"}.
static func _torso_skin(cb: CharBody, hair: MeshInstance3D, with_clothes := false) -> Dictionary:
	var allow := {}
	for bn in TORSO_BONES:
		var hi := _bind_index(hair, cb, bn)
		var si := cb.sk.find_bone(bn)
		if hi >= 0 and si >= 0: allow[si] = hi
	var allmap := {}
	var V := PackedVector3Array()
	var Wl: Array = []
	for mi in cb.sk.find_children("*", "MeshInstance3D", true, false):
		var pid := str(mi.get_meta("piece", ""))
		if mi.mesh == null: continue
		if pid == "":
			if not (str(mi.name) in ["body", "head"]): continue
		elif not with_clothes or not cb.pieces.has(pid) or str(cb.pieces[pid].slot) == "hair" or _skip(mi):
			continue
		var bl: Array = blended(mi)
		var pos: PackedVector3Array = bl[0]
		var base := 0
		for s in range(mi.mesh.get_surface_count()):
			var arr: Array = mi.mesh.surface_get_arrays(s)
			var n := (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
			if arr[Mesh.ARRAY_BONES] == null:
				base += n; continue
			var B: PackedInt32Array = arr[Mesh.ARRAY_BONES]
			var W: PackedFloat32Array = arr[Mesh.ARRAY_WEIGHTS]
			var per := B.size() / maxi(n, 1)
			for k in range(n):
				var d := {}
				var tot := 0.0
				var all_w := 0.0
				for q in per:
					var w := W[k * per + q]
					if w <= 0.0: continue
					var sb: int = mi.skin.get_bind_bone(B[k * per + q]) if mi.skin else B[k * per + q]
					if sb < 0 and mi.skin: sb = cb.sk.find_bone(str(mi.skin.get_bind_name(B[k * per + q])))
					# every bone the skin under the hair moves with (the shoulder blades ride the arms a
					# little: a curtain over them must too, as the shirt does), in the hair's bind indices
					if not allmap.has(sb):
						allmap[sb] = _bind_index(hair, cb, cb.sk.get_bone_name(sb)) if sb >= 0 else -1
					if int(allmap[sb]) < 0: continue
					d[allmap[sb]] = float(d.get(allmap[sb], 0.0)) + w
					all_w += w
					if allow.has(sb): tot += w
				if all_w <= 0.0 or tot / all_w < 0.5: continue    # mostly an arm: not something hair rides
				for key in d: d[key] = float(d[key]) / all_w
				V.append(pos[base + k])
				Wl.append(d)
			base += n
	var grid := {}
	for i in range(V.size()):
		var c := Vector3i((V[i] / CELL).floor())
		if not grid.has(c): grid[c] = []
		(grid[c] as Array).append(i)
	return {"V": V, "W": Wl, "grid": grid}

## Torso weights at p: the 4 nearest torso skin vertices' weights, inverse-distance blended.
static func _torso_weights(t: Dictionary, p: Vector3) -> Dictionary:
	var c := Vector3i((p / CELL).floor())
	var best: Array = []      # [d2, i], kept sorted, at most 4
	for r in [1, 2, 4]:
		best = []
		for dx in range(-r, r + 1):
			for dy in range(-r, r + 1):
				for dz in range(-r, r + 1):
					var key := c + Vector3i(dx, dy, dz)
					if not t.grid.has(key): continue
					for i in t.grid[key]:
						var d2 := (t.V[i] as Vector3).distance_squared_to(p)
						best.append([d2, i])
		if best.size() >= 4: break
	if best.is_empty(): return {}
	best.sort_custom(func(a, b): return a[0] < b[0])
	var out := {}
	var tot := 0.0
	for j in mini(4, best.size()):
		var wi := 1.0 / maxf(sqrt(float(best[j][0])), 0.002)
		var d: Dictionary = t.W[best[j][1]]
		for key in d: out[key] = float(out.get(key, 0.0)) + float(d[key]) * wi
		tot += wi
	for key in out: out[key] = float(out[key]) / tot
	return out

## A joint's height in the mesh's bind space (the skeleton's global rest, which _bones() sets from the
## bind position plus the blend shapes' joint offsets).
static func _joint_y(cb: CharBody, bn: String) -> float:
	var i := cb.sk.find_bone(bn)
	if i < 0: return 0.0
	return cb.sk.get_bone_global_rest(i).origin.y

## The Skin bind index of a bone (what a mesh's ARRAY_BONES holds), -1 if the skin doesn't bind it.
static func _bind_index(mi: MeshInstance3D, cb: CharBody, bn: String) -> int:
	if mi.skin == null: return cb.sk.find_bone(bn)
	var bi := cb.sk.find_bone(bn)
	for k in range(mi.skin.get_bind_count()):
		if mi.skin.get_bind_bone(k) == bi and bi >= 0: return k
		if str(mi.skin.get_bind_name(k)) == bn: return k
	return -1

## Blend shape values by name (so a mesh swap keeps them).
static func _shape_values(mi: MeshInstance3D) -> Dictionary:
	var d := {}
	if mi.mesh == null: return d
	for i in range(mi.mesh.get_blend_shape_count()):
		d[str(mi.mesh.get_blend_shape_name(i))] = mi.get_blend_shape_value(i)
	return d

static func _set_shape_values(mi: MeshInstance3D, d: Dictionary) -> void:
	if mi.mesh == null: return
	for i in range(mi.mesh.get_blend_shape_count()):
		mi.set_blend_shape_value(i, float(d.get(str(mi.mesh.get_blend_shape_name(i)), 0.0)))
