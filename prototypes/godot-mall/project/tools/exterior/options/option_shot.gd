## Workstream LOT tree options sheet (design/godot-exterior.md "Tree options"): the palm drive with
## option A (flora.gd, as built), B (a CC0 pack's palm) or C (the Blender-built sabal) standing at the
## drive's 24 palm spots, unbaked, the same sun as exshots.gd.
##   xvfb-run -a godot --path . --rendering-driver opengl3 --script res://tools/exterior/options/option_shot.gd -- \
##     --option=B --model=res://_lotopt/PalmTree_1.fbx --scale=1.0 --out=DIR --cams="x,y,z,yaw,pitch:name;..."
## For B the pack's leaf / trunk textures are put on by material name (the FBX carries no paths).
extends SceneTree
var frames := 0
var out := "/tmp"
var vp: SubViewport
var cam: Camera3D
var cams := []
var i := 0

func _initialize() -> void:
	var option := "A"
	var model := ""
	var scl := 1.0
	var rotx := 0.0
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.substr(6)
		elif a.begins_with("--option="): option = a.substr(9)
		elif a.begins_with("--model="): model = a.substr(8)
		elif a.begins_with("--scale="): scl = float(a.substr(8))
		elif a.begins_with("--rotx="): rotx = deg_to_rad(float(a.substr(7)))
		elif a.begins_with("--cams="):
			for c in a.substr(7).split(";"):
				var kv = c.split(":")
				cams.append([kv[0], kv[1]])
	var scn = load("res://wing3.tscn").instantiate()
	var pl = scn.get_node_or_null("Player")
	if pl:
		scn.remove_child(pl); pl.free()
	root.add_child(scn)
	current_scene = scn
	var lm = scn.find_child("LightmapGI", true, false)
	if lm: lm.get_parent().remove_child(lm); lm.free()
	if option != "A":
		# hide the built palms of the drive: the flora mesh, the trunks stay in ex_props, so hide those too
		for n in ["dyn_ex_flora", "ex_props"]:
			var nd = scn.find_child(n, true, false)
			if nd: nd.visible = false
		var ps = load(model)
		var x0 = 50.0; var x1 = 112.0 - 6.5
		for sd in [-1.0, 1.0]:
			for k in 12:
				var inst = ps.instantiate()
				var h = 6.0 + (k % 3) * 0.8
				inst.position = Vector3(x0 + 6.0 + k * ((x1 - x0 - 10.0) / 11.0), 0.08, sd * 4.3)
				inst.rotation = Vector3(rotx, k * 1.7, 0)
				var s = scl * (h / 6.5)
				inst.scale = Vector3(s, s, s)
				scn.add_child(inst)
				if option == "B":
					_skin(inst)
				else:
					for mi in inst.find_children("*", "MeshInstance3D", true, false):
						var m := StandardMaterial3D.new()
						m.vertex_color_use_as_albedo = true; m.roughness = 0.85; m.albedo_color = Color(2.4, 2.4, 2.4)   # the sketch's vertex colours are linear
						m.cull_mode = BaseMaterial3D.CULL_DISABLED
						mi.material_override = m
	var env := Environment.new()
	var sky := Sky.new(); var sm := ProceduralSkyMaterial.new()
	sky.sky_material = sm
	env.background_mode = Environment.BG_SKY; env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#dfe8f2"); env.ambient_light_energy = 0.35
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC; env.tonemap_exposure = 0.8
	var we = scn.find_child("Env", true, false)
	if we: we.environment = env
	for l in scn.find_children("*", "Light3D", true, false):
		l.visible = false
	var sun := DirectionalLight3D.new(); sun.light_energy = 0.85
	sun.shadow_enabled = true; sun.directional_shadow_max_distance = 250.0
	sun.transform = Transform3D(Basis.looking_at(Vector3(-0.42, -0.64, 0.64), Vector3.UP), Vector3.ZERO)
	scn.add_child(sun)
	vp = SubViewport.new(); vp.size = Vector2i(1280, 720); vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.msaa_3d = Viewport.MSAA_2X
	cam = Camera3D.new(); cam.fov = 70.0; cam.far = 900.0
	vp.add_child(cam); root.add_child(vp); cam.current = true
	_place()

func _skin(n: Node) -> void:
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		for s in mi.mesh.get_surface_count():
			var src = mi.mesh.surface_get_material(s)
			var nm = src.resource_name if src else ""
			var m := StandardMaterial3D.new()
			if nm.to_lower().contains("leaves"):
				m.albedo_texture = load("res://_lotopt/PalmTree_Leaves.png")
				m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR; m.alpha_scissor_threshold = 0.5
				m.cull_mode = BaseMaterial3D.CULL_DISABLED
			else:
				m.albedo_texture = load("res://_lotopt/PalmTree_Trunk.png")
			m.roughness = 0.9
			mi.set_surface_override_material(s, m)

func _place() -> void:
	var v = cams[i][0].split(",")
	cam.rotation = Vector3(deg_to_rad(float(v[4])), deg_to_rad(float(v[3])), 0)
	cam.position = Vector3(float(v[0]), float(v[1]), float(v[2]))
	frames = 0

func _process(_d) -> bool:
	if vp == null:
		return true
	frames += 1
	if frames < 12: return false
	vp.get_texture().get_image().save_png(out + "/" + cams[i][1] + ".png")
	print("wrote ", cams[i][1])
	i += 1
	if i >= cams.size():
		return true
	_place()
	return false
