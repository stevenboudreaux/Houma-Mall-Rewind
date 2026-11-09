## CHAR-BUILD: a cast member in the mall's lighting, unbaked (the wing's LightmapGI removed), for the
## evidence shots. Stands CastGlb.body(<id>) at a spot, plays a clip (and optional morphs), hides the
## attendants near it, and shoots from each camera with its own Camera3D.
##   xvfb-run -a -s "-screen 0 1600x1000x24" godot --path . --rendering-driver opengl3 --resolution 1280x800 \
##     --script res://tools/qa/cast_shot.gd -- --id=radioshack_1995 --wing=1 --at=8.2,32.95,180 \
##     --cams="far:8.2,29.4,1.62,8.2,1.25,32.95,50;talk:8.2,31.6,1.62,8.2,1.62,32.95,40" --out=/tmp/cs/rs [--night]
##     [--clip=idle] [--morphs=smile:0.6,brow_up:0.3] [--freeze=0.6] [--year=2026]
## --at = x, z, facing yaw in degrees (0 = +Z, 180 = -Z); a camera = name: eye x,z,y, target x,y,z, fov.
## Prints CAST SHOT OK and writes <out>-<name>.png.
extends SceneTree

var args := {}

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--") and "=" in a:
			args[a.substr(2, a.find("=") - 2)] = a.substr(a.find("=") + 1)
		elif a.begins_with("--"):
			args[a.substr(2)] = "1"
	var out: String = args.get("out", "/tmp/cast_shot")
	DirAccess.make_dir_recursive_absolute(out.get_base_dir())
	Engine.set_meta("mall_state_1995", "")
	Engine.set_meta("mall_flags", "")
	var scn: Node
	if args.has("studio"):
		scn = _studio()
	else:
		var wing: String = args.get("wing", "1")
		var scene := "res://wing%s%s.tscn" % [wing, "_2026" if args.get("year", "") == "2026" else ""]
		scn = load(scene).instantiate()
		root.add_child(scn)
		current_scene = scn
		var lm = scn.find_child("LightmapGI", true, false)
		if lm: lm.get_parent().remove_child(lm); lm.free()
		load("res://scripts/time_of_day.gd").apply(scn, "night" if args.has("night") else "day")
	for i in 30: await process_frame
	var at: PackedStringArray = str(args.get("at", "0,0,0")).split(",")
	var spot := Vector3(float(at[0]), float(at[3]) if at.size() > 3 else 0.0, float(at[1]))
	# the attendants / NPCs standing near the spot go (this shot is about the cast member)
	for n in scn.find_children("*", "Node3D", true, false):
		if n is NpcBody and n.is_inside_tree() and (n as Node3D).global_position.distance_to(spot) < 2.5:
			(n as Node3D).visible = false
	var nb := CastGlb.body(str(args.get("id", "")))
	if nb == null:
		printerr("CAST SHOT FAILED: no body"); quit(1); return
	scn.add_child(nb)
	nb.position = spot
	nb.face(Vector3(sin(deg_to_rad(float(at[2]))), 0, cos(deg_to_rad(float(at[2])))))
	var clip: String = args.get("clip", "idle")
	nb.play(clip, 0.0, false)
	for i in 4: await process_frame
	if args.has("freeze"): nb.freeze(clip, float(args.freeze))
	for kv in str(args.get("morphs", "")).split(",", false):
		var p := kv.split(":")
		if p[0] == "jaw_open": CastGlb.set_mouth(nb, float(p[1]))
		else: CastGlb.set_morph(nb, p[0], float(p[1]))
	for cl in scn.find_children("*", "CanvasLayer", true, false):
		(cl as CanvasLayer).visible = false
	var cam := Camera3D.new()
	scn.add_child(cam)
	cam.current = true
	for c in str(args.get("cams", "")).split(";", false):
		var name := c.substr(0, c.find(":"))
		var v := c.substr(c.find(":") + 1).split(",")
		cam.position = Vector3(float(v[0]), float(v[2]), float(v[1]))
		cam.fov = float(v[6]) if v.size() > 6 else 50.0
		cam.look_at(Vector3(float(v[3]), float(v[4]), float(v[5])), Vector3.UP)
		if args.has("look_cam"):
			CastGlb.aim_eyes(nb, cam.global_position)
		for i in 8: await process_frame
		var im := root.get_texture().get_image()
		im.save_png("%s-%s.png" % [out, name])
		printerr("shot ", name)
	printerr("CAST SHOT OK")
	quit(0)

## --studio: a quick look without a wing (warm overhead key like the mall's fluorescents, cool fill,
## ambient), for iterating on a face in the game's renderer. Evidence shots use a wing.
func _studio() -> Node3D:
	var s := Node3D.new()
	root.add_child(s)
	current_scene = s
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.28, 0.25, 0.22)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.85, 0.82, 0.78)
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	we.environment = env
	s.add_child(we)
	for l in [[Vector3(-60, 15, 0), 1.1, Color(1, 0.95, 0.86)], [Vector3(-20, -70, 0), 0.35, Color(0.85, 0.9, 1)], [Vector3(-25, 165, 0), 0.5, Color(1, 0.85, 0.7)]]:
		var d := DirectionalLight3D.new()
		d.rotation_degrees = l[0]; d.light_energy = l[1]; d.light_color = l[2]
		s.add_child(d)
	return s
