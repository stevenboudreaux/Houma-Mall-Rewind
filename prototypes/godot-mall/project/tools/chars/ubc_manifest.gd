## CHARS-UBC (design/godot-ubc-characters.md): writes models/ubc/ubc.json, the UBC bodies' manifest in
## the same shape as B1's models/characters/characters.json, so CharBody / CharPreset / the editor run
## on either (CharBody.manifest_path()).
##   godot --headless --path . --script res://tools/chars/ubc_manifest.gd
## Read from the imported files themselves (Godot space, so CharBody needs no conversion):
##   bodies.<sex>: glb, height, hips height, blend shapes, bones (parent, local rest pos / rot; the kit's
##     rest IS its bind: a T-pose), joints: per blend shape, each bone's local rest-translation offset,
##     measured as the mean displacement of the skin around the joint (so a taller body's knees, hips,
##     shoulders and head move with the flesh);
##   sliders from the blend shape names; presets; the colour lists, layers and regions from B1's
##   manifest; pieces from models/ubc/pieces.json (written by tools/blender/ubc/build_pieces.py).
extends SceneTree

const OUT := "res://models/ubc/ubc.json"
const MH := "res://models/characters/characters.json"
const MOVES_JOINTS := ["height", "shoulders", "neck_length"]
const SIGMA := 0.045          # m: the skin around a joint that moves it
const GROUP := {"height": "body", "weight": "body", "muscle": "body", "shoulders": "torso", "chest": "torso",
	"bust": "torso", "waist": "torso", "belly": "torso", "hips": "legs", "butt": "legs", "thigh": "legs",
	"calf": "legs", "arms": "arms", "neck_length": "head", "head_size": "head", "jaw": "face", "chin": "face"}
const NOTES := {"weight": "build: + soft volume (belly, hips, thighs, arms), - lean",
	"muscle": "+ brings back the kit's superhero sculpt; the default is toned down",
	"height": "+1 = +12 % (legs and torso; the head keeps its size), -1 = -11 %",
	"jaw": "face pass: jaw width", "chin": "face pass: chin length"}

func _initialize() -> void:
	await process_frame
	var mh = JSON.parse_string(FileAccess.get_file_as_string(MH))
	var m := {"_": "CHARS-UBC manifest (design/godot-ubc-characters.md), written by tools/chars/ubc_manifest.gd from the Quaternius Universal Base Characters (CC0, models/ubc/LICENSE-UBC.txt).",
		"version": 1, "kit": "ubc", "wrinkle": false, "skeleton": "mixamo", "bodies": {}}
	var shape_names := {}
	for sex in ["female", "male"]:
		var b := _body(sex)
		m.bodies[sex] = b
		for s in b.shapes: shape_names[s] = true
	var sliders := []
	var seen := {}
	for s in shape_names:
		var base := str(s).substr(0, str(s).length() - 1)
		if seen.has(base): continue
		seen[base] = true
		var e := {"name": base, "group": GROUP.get(base, "body"), "range": [-1, 1], "kind": "shape",
			"shapes": [base + "+", base + "-"]}
		if NOTES.has(base): e.note = NOTES[base]
		if base == "bust": e.sex = "female"
		sliders.append(e)
	var order := GROUP.keys()
	sliders.sort_custom(func(a, b): return order.find(a.name) < order.find(b.name))
	m.sliders = sliders
	m.correctives = []
	m.presets = {
		"female": {"Slim": {"weight": -0.6, "muscle": -0.4, "hips": -0.2, "bust": -0.2},
			"Average": {},
			"Curvy": {"bust": 0.5, "waist": -0.4, "hips": 0.7, "butt": 0.6, "thigh": 0.35},
			"Plus": {"weight": 0.85, "muscle": -0.3, "bust": 0.5, "waist": 0.4, "belly": 0.4, "hips": 0.5, "thigh": 0.5, "arms": 0.4}},
		"male": {"Slim": {"weight": -0.6, "muscle": -0.4, "shoulders": -0.3, "chest": -0.3, "arms": -0.3},
			"Average": {},
			"Athletic": {"muscle": 0.6, "shoulders": 0.4, "chest": 0.4, "waist": -0.3, "arms": 0.3},
			"Big & Tall": {"height": 0.55, "weight": 0.85, "muscle": -0.1, "belly": 0.6, "waist": 0.5, "chest": 0.3, "shoulders": 0.3}},
		"extremes": {"heavy-set 52": {"weight": 1.0, "muscle": -0.7, "belly": 0.8, "waist": 0.7, "neck_length": -0.4},
			"skinny 74": {"weight": -1.0, "muscle": -0.8, "height": -0.2}}}
	for k in ["skin_tones", "iris_colors", "hair_colors", "layers", "regions", "patterns"]:
		if mh.has(k): m[k] = mh[k]
	m.pieces = []
	if FileAccess.file_exists("res://models/ubc/pieces.json"):
		var pj = JSON.parse_string(FileAccess.get_file_as_string("res://models/ubc/pieces.json"))
		if pj is Dictionary:
			m.pieces = pj.get("pieces", [])
			m.aliases = pj.get("aliases", {})
	var f := FileAccess.open(OUT, FileAccess.WRITE)
	f.store_string(JSON.stringify(m, "\t", false) + "\n")
	f.close()
	print("UBC MANIFEST OK: %d sliders, %d pieces -> %s" % [sliders.size(), m.pieces.size(), OUT])
	quit(0)

func _body(sex: String) -> Dictionary:
	var path := "res://models/ubc/body_%s.gltf" % sex
	var s: Node3D = load(path).instantiate()
	root.add_child(s)
	var sk: Skeleton3D = s.find_child("Skeleton3D", true, false)
	var body: MeshInstance3D = sk.find_child("body", true, false)
	var am: ArrayMesh = body.mesh
	var arr := am.surface_get_arrays(0)
	var V: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var bsa := am.surface_get_blend_shape_arrays(0)
	var normalized := am.blend_shape_mode == Mesh.BLEND_SHAPE_MODE_NORMALIZED
	var bones := {}
	var top := 0.0
	for v in V: top = maxf(top, v.y)
	for i in range(sk.get_bone_count()):
		var r := sk.get_bone_rest(i)
		var q := r.basis.get_rotation_quaternion()
		var p := sk.get_bone_parent(i)
		bones[sk.get_bone_name(i)] = {"parent": sk.get_bone_name(p) if p >= 0 else "",
			"pos": [snappedf(r.origin.x, 0.00001), snappedf(r.origin.y, 0.00001), snappedf(r.origin.z, 0.00001)],
			"rest_rot": [q.x, q.y, q.z, q.w], "bind_rot": [q.x, q.y, q.z, q.w]}
	# the skin around each joint, once: [indices, weights]
	var near := {}
	for i in range(sk.get_bone_count()):
		var J := sk.get_bone_global_rest(i).origin
		var idx := PackedInt32Array(); var ws := PackedFloat32Array()
		for k in range(V.size()):
			var d2 := V[k].distance_squared_to(J)
			if d2 > 9.0 * SIGMA * SIGMA: continue
			idx.append(k); ws.append(exp(-0.5 * d2 / (SIGMA * SIGMA)))
		near[i] = [idx, ws]
	var shapes := []
	var joints := {}
	for si in range(am.get_blend_shape_count()):
		var nm := str(am.get_blend_shape_name(si))
		shapes.append(nm)
		var T: PackedVector3Array = bsa[si][Mesh.ARRAY_VERTEX]
		var D := PackedVector3Array(); D.resize(V.size())
		for k in range(V.size()): D[k] = (T[k] - V[k]) if normalized else T[k]
		var gd := {}      # bone -> global displacement of its joint
		for i in range(sk.get_bone_count()):
			var acc := Vector3.ZERO
			var wsum := 0.0
			var idx: PackedInt32Array = near[i][0]
			var ws: PackedFloat32Array = near[i][1]
			for q in range(idx.size()):
				acc += D[idx[q]] * ws[q]
				wsum += ws[q]
			var p := sk.get_bone_parent(i)
			gd[i] = acc / wsum if wsum > 0.05 else (gd.get(p, Vector3.ZERO) if p >= 0 else Vector3.ZERO)
		var jd := {}
		for i in range(sk.get_bone_count()):
			var p := sk.get_bone_parent(i)
			var dg: Vector3 = gd[i] - (gd[p] if p >= 0 else Vector3.ZERO)
			var pb := sk.get_bone_global_rest(p).basis.orthonormalized() if p >= 0 else Basis()
			var dl := pb.inverse() * dg
			if dl.length() > 0.0004:
				jd[sk.get_bone_name(i)] = [snappedf(dl.x, 0.00001), snappedf(dl.y, 0.00001), snappedf(dl.z, 0.00001)]
		# only the shapes that move the skeleton: an inflation (weight, hips, arms ...) leaves the joints
		# where they are (its neighbourhood average is not a joint move)
		if nm.trim_suffix("+").trim_suffix("-") in MOVES_JOINTS:
			joints[nm] = jd
	var hips := sk.get_bone_global_rest(sk.find_bone("mixamorig_Hips")).origin.y
	s.queue_free()
	return {"glb": path, "glb_hi": path, "height_m": snappedf(top, 0.001), "hips_height": snappedf(hips, 0.0001),
		"shapes": shapes, "bones": bones, "joints": joints,
		"materials": {"skin_body": "skin", "eye_iris": "iris tint", "hair_brows": "hair tint (eyebrows)"}}
