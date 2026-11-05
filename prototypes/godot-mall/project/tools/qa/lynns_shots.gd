## Lynn's Interiors (wing4_2026) unbaked placement shots — workstream LYNNS (design/lynns/layout.md "Pass 2").
## As unbaked_shots.gd (no lightmap: ambient + a sun), plus an eye height per camera and an overhead plan view
## with everything above 2.6 m hidden (ceiling, soffits, troffers):
##   godot --path . --rendering-driver opengl3 --script res://tools/qa/lynns_shots.gd -- \
##     --scene=res://wing4_2026.tscn --out=DIR --cams="x,z,yaw,pitch[,height]:name;...;top:cx,cz,size:name"
## yaw 0 looks north (-z), 90 west, -90 east, 180 south (toward the mall).
extends SceneTree
var frames := 0
var out := "/tmp"
var vp: SubViewport
var cam: Camera3D
var cams := []
var i := 0
var scn: Node
var hidden := []

func _initialize() -> void:
	var scene_path := "res://wing4_2026.tscn"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.substr(6)
		elif a.begins_with("--scene="): scene_path = a.substr(8)
		elif a.begins_with("--cams="):
			for c in a.substr(7).split(";"):
				var kv = c.split(":")
				if kv.size() == 2:
					cams.append([kv[0].split(","), kv[1]])
				elif kv.size() == 3 and kv[0] == "top":
					cams.append([["top"] + Array(kv[1].split(",")), kv[2]])
	scn = load(scene_path).instantiate()
	var pl = scn.get_node_or_null("Player")
	if pl:
		scn.remove_child(pl); pl.free()
	root.add_child(scn)
	current_scene = scn
	var lm = scn.find_child("LightmapGI", true, false)
	if lm: lm.get_parent().remove_child(lm); lm.free()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR; env.background_color = Color("#9fb8d0")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#fff4e6"); env.ambient_light_energy = 0.9
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we = scn.find_child("Env", true, false)
	if we: we.environment = env
	for rp in scn.find_children("*", "ReflectionProbe", true, false):
		rp.get_parent().remove_child(rp); rp.free()
	for l in scn.find_children("*", "Light3D", true, false):
		l.visible = false
	var sun := DirectionalLight3D.new(); sun.light_energy = 0.6
	sun.transform = Transform3D(Basis.looking_at(Vector3(0.3, -0.9, 0.2), Vector3.UP), Vector3.ZERO)
	scn.add_child(sun)
	vp = SubViewport.new(); vp.size = Vector2i(1280, 720); vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	cam = Camera3D.new(); cam.fov = 70.0; cam.far = 400.0
	vp.add_child(cam); root.add_child(vp); cam.current = true
	_place()

func _set_high_hidden(h: bool) -> void:
	if h and hidden.is_empty():
		for m in scn.find_children("*", "GeometryInstance3D", true, false):
			if m.visible and m is VisualInstance3D:
				var bb = m.global_transform * m.get_aabb()
				if bb.position.y > 2.6:
					m.visible = false
					hidden.append(m)
	elif not h:
		for m in hidden: m.visible = true
		hidden.clear()

func _place() -> void:
	var v = cams[i][0]
	if v[0] == "top":
		_set_high_hidden(true)
		vp.size = Vector2i(1400, 1000)
		cam.projection = Camera3D.PROJECTION_ORTHOGONAL
		cam.size = float(v[3])
		cam.rotation = Vector3(deg_to_rad(-90.0), 0, 0)
		cam.position = Vector3(float(v[1]), 60.0, float(v[2]))
	else:
		_set_high_hidden(false)
		vp.size = Vector2i(1280, 720)
		cam.projection = Camera3D.PROJECTION_PERSPECTIVE
		cam.rotation = Vector3(deg_to_rad(float(v[3])), deg_to_rad(float(v[2])), 0)
		cam.position = Vector3(float(v[0]), float(v[4]) if v.size() > 4 else 1.62, float(v[1]))
	frames = 0

func _process(_d) -> bool:
	frames += 1
	if frames < 20: return false
	vp.get_texture().get_image().save_png(out + "/" + cams[i][1] + ".png")
	print("wrote ", cams[i][1])
	i += 1
	if i >= cams.size():
		return true
	_place()
	return false
