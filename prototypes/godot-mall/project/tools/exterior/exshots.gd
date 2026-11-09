## Unbaked views of the outside (wing 3) for geometry checks (Workstream F, design/godot-exterior.md):
## a plain sun and sky instead of the lightmap, any eye height, and an orthographic top view.
##   xvfb-run -a godot --path . --rendering-driver opengl3 --script res://tools/exterior/exshots.gd -- \
##     --scene=res://wing3.tscn --out=DIR --cams="x,y,z,yaw,pitch[,fov]:name;top:x0,z0,size:name;..."
## Workstream LOT: --sun=x,y,z (the sun's direction, e.g. 0.05,-1,0.1 for noon; default the bake's
## afternoon), --baked (keep the LightmapGI and the scene's day environment: what a baked build shows,
## when the wing's lightmap is in the project).
## yaw as player.gd (0 looks -z, 90 looks -x); "top" cameras look straight down over a square
## `size` metres wide centred on (x0, z0). Writes <out>/<name>.png (1280x720, top views 1024x1024).
extends SceneTree
var frames := 0
var out := "/tmp"
var vp: SubViewport
var cam: Camera3D
var cams := []
var i := 0

func _initialize() -> void:
	var scene_path := "res://wing3.tscn"
	var mode := "day"
	var sun_dir := Vector3(-0.42, -0.64, 0.64)
	var baked := false
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--scene="): scene_path = a.substr(8)
		elif a.begins_with("--out="): out = a.substr(6)
		elif a.begins_with("--mode="): mode = a.substr(7)
		elif a.begins_with("--sun="):
			var v = a.substr(6).split(","); sun_dir = Vector3(float(v[0]), float(v[1]), float(v[2])).normalized()
		elif a == "--baked": baked = true
		elif a.begins_with("--cams="):
			for c in a.substr(7).split(";"):
				var kv = c.split(":")
				if kv.size() == 2:
					cams.append([kv[0], kv[1]])
				elif kv.size() == 3 and kv[0] == "top":
					cams.append(["top", kv[1], kv[2]])
	var scn = load(scene_path).instantiate()
	var pl = scn.get_node_or_null("Player")
	if pl:
		scn.remove_child(pl); pl.free()
	root.add_child(scn)
	current_scene = scn
	if baked:
		var we0 = scn.find_child("Env", true, false)
		if we0: we0.environment = load("res://gen/env_day.tres")
		for l in scn.find_children("*", "Light3D", true, false):
			l.visible = l is DirectionalLight3D
		vp = SubViewport.new(); vp.size = Vector2i(1280, 720); vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		vp.msaa_3d = Viewport.MSAA_2X
		cam = Camera3D.new(); cam.fov = 70.0; cam.far = 900.0
		vp.add_child(cam); root.add_child(vp); cam.current = true
		_place()
		return
	var lm = scn.find_child("LightmapGI", true, false)
	if lm: lm.get_parent().remove_child(lm); lm.free()
	var env := Environment.new()
	var sky := Sky.new(); var sm := ProceduralSkyMaterial.new()
	sky.sky_material = sm
	env.background_mode = Environment.BG_SKY; env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#dfe8f2") if mode == "day" else Color("#2a3040")
	env.ambient_light_energy = 0.35 if mode == "day" else 0.3
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 0.8
	var we = scn.find_child("Env", true, false)
	if we: we.environment = env
	for l in scn.find_children("*", "Light3D", true, false):
		l.visible = mode == "night" and not (l is DirectionalLight3D)
		if l.visible: l.light_bake_mode = Light3D.BAKE_DYNAMIC
	var sun := DirectionalLight3D.new(); sun.light_energy = 0.85 if mode == "day" else 0.0
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 250.0
	# EXT-B: the game's N / NE afternoon sun, as wing 3's bake (build_mall.gd)
	sun.transform = Transform3D(Basis.looking_at(sun_dir, Vector3.UP if abs(sun_dir.y) < 0.99 else Vector3.FORWARD), Vector3.ZERO)
	scn.add_child(sun)
	vp = SubViewport.new(); vp.size = Vector2i(1280, 720); vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.msaa_3d = Viewport.MSAA_2X   # the game's own MSAA (project.godot), for alpha-to-coverage foliage
	cam = Camera3D.new(); cam.fov = 70.0; cam.far = 900.0
	vp.add_child(cam); root.add_child(vp); cam.current = true
	_place()

func _place() -> void:
	var c = cams[i]
	if c[0] == "top":
		var v = c[1].split(",")
		vp.size = Vector2i(1024, 1024)
		cam.projection = Camera3D.PROJECTION_ORTHOGONAL
		cam.size = float(v[2])
		cam.rotation = Vector3(-PI * 0.5, 0, 0)
		cam.position = Vector3(float(v[0]), 200.0, float(v[1]))
	else:
		var v = c[0].split(",")
		vp.size = Vector2i(1280, 720)
		cam.projection = Camera3D.PROJECTION_PERSPECTIVE
		cam.fov = float(v[5]) if v.size() > 5 else 70.0
		cam.rotation = Vector3(deg_to_rad(float(v[4])), deg_to_rad(float(v[3])), 0)
		cam.position = Vector3(float(v[0]), float(v[1]), float(v[2]))
	frames = 0

func _process(_d) -> bool:
	frames += 1
	if frames < 12: return false
	var name: String = cams[i][cams[i].size() - 1]
	vp.get_texture().get_image().save_png(out + "/" + name + ".png")
	print("wrote ", name)
	i += 1
	if i >= cams.size():
		return true
	_place()
	return false
