## Drops Blender .glb models into tools/qa/preview.gd's scene (realtime, probe-lit, unbaked), either on a
## bare stage ("glb") or inside a store with the hall in front ("store:<NAME>"), so a model is seen with
## the game's own lights and materials. Run through tools/blender/godot_check.sh.
## opts JSON: {"glb": [{"path": "res://models/<id>/<id>.glb", "at": [x,y,z], "yaw": deg, "scale": 1}],
##             "stand": [w, h, d]  (optional grey block under the first model, e.g. a counter top),
##             each glb entry may add "colors": {"<material name>": "#hex"} (see recolor())
##             "probe": false (true adds a box reflection probe like the halls' ones; it streaks under xvfb)}
## Models load through the editor import (res://models/... .glb.import), like the game; a model that
## has not been imported yet is loaded straight from the file with GLTFDocument and a warning is printed.
extends "res://tools/qa/preview.gd"

func _initialize():
	super._initialize()
	var args = OS.get_cmdline_user_args()
	var opts = JSON.parse_string(args[2]) if args.size() > 2 and args[2] != "" else {}
	if opts == null:
		opts = {}
	if opts.has("stand"):
		var s = opts.stand
		var mi = MeshInstance3D.new()
		var bm = BoxMesh.new()
		bm.size = Vector3(s[0], s[1], s[2])
		var m = StandardMaterial3D.new()
		m.albedo_color = Color("#8c8a86")
		m.roughness = 0.6
		bm.material = m
		mi.mesh = bm
		var at0 = opts.get("stand_at", opts.glb[0].get("at", [0, 0, 0]))
		mi.position = Vector3(at0[0], s[1] * 0.5, at0[2])
		mall.add_child(mi)
	if opts.get("probe", false):
		# like the hall and court probes in build_mall.gd (box-projected, interior, intensity 0.9)
		var rp = ReflectionProbe.new()
		rp.position = Vector3(0, 1.8, 0)
		rp.size = Vector3(12, 3.6, 12)
		rp.box_projection = true
		rp.interior = true
		rp.update_mode = ReflectionProbe.UPDATE_ONCE
		rp.intensity = 0.9
		mall.add_child(rp)
	for g in opts.get("glb", []):
		var n = load_glb(g.path)
		if n == null:
			push_error("could not load " + g.path)
			continue
		var at = g.get("at", [0, 0, 0])
		n.position = Vector3(at[0], at[1], at[2])
		n.rotation_degrees.y = float(g.get("yaw", 0.0))
		n.scale = Vector3.ONE * float(g.get("scale", 1.0))
		if g.has("colors"):
			recolor(n, g.colors)
		mall.add_child(n)
		print("GLB ", g.path, " at ", n.position)

## Surface overrides by material name, as the game would do them: {"bl_x_baked": "#hex"} tints a baked
## atlas (albedo colour multiplies the texture: the plush fur), {"bl_gb_lavalamp_wax": "#hex"} recolours a
## flat glowing material (albedo and emission).
func recolor(node, colors):
	for mi in node.find_children("*", "MeshInstance3D", true, false):
		for i in mi.mesh.get_surface_count():
			var m = mi.mesh.surface_get_material(i)
			if m == null or not colors.has(m.resource_name):
				continue
			var c = Color(colors[m.resource_name])
			var nm = m.duplicate()
			nm.albedo_color = Color(c.r, c.g, c.b, m.albedo_color.a)
			if nm.emission_enabled:
				nm.emission = c
			mi.set_surface_override_material(i, nm)

func load_glb(path):
	if ResourceLoader.exists(path):
		var ps = load(path)
		if ps is PackedScene:
			return ps.instantiate()
	print("WARNING: ", path, " is not imported; loading it raw with GLTFDocument (run godot --headless --import)")
	var doc = GLTFDocument.new()
	var st = GLTFState.new()
	if doc.append_from_file(ProjectSettings.globalize_path(path), st) != OK:
		return null
	return doc.generate_scene(st)

func build_prop(module, opts):
	if module != "glb":
		super.build_prop(module, opts)
		return
	cur_color = Color("#2a2a30")
	quad("room", "vcolor_matte", [Vector3(-6, 0, -6), Vector3(6, 0, -6), Vector3(6, 0, 6), Vector3(-6, 0, 6)], Vector3.UP)
	cur_color = Color("#3a3a44")
	quad("room", "vcolor_matte", [Vector3(-6, 0, -6), Vector3(6, 0, -6), Vector3(6, 3.6, -6), Vector3(-6, 3.6, -6)], Vector3.BACK)
	cur_color = Color.WHITE
