## FLOOR-FIX (Nov 11 2026, design/godot-floor-lighting-diagnosis.md): walks the player along a line
## and saves the screen at every step, once per floor_spec value, in one load. The game runs as it
## ships (Player, Runtime, baked lightmap, clock at noon); only the floor's specular share changes.
## xvfb-run -a godot --path . --rendering-driver opengl3 --script res://tools/qa/floor_walk.gd -- \
##   --scene=wing1 --cam=x,z,yaw,pitch --steps=8 --step=0.5 --specs=0.25,0 --flat=0 --out=.scratch/fw/a
## Writes <out>-s<spec>-<nn>.png. --flat=1 paints the floor plain grey so only light and reflections
## show (a test-only edit of the shader string). yaw 0 faces -z; the walk goes where the camera looks.
extends SceneTree
var frames := 0
var scn: Node
var pl: Node3D
var specs := PackedFloat32Array([0.25, 0.0])
var steps := 8
var step := 0.5
var flat := false
var out := ".scratch/fw/walk"
var start := Vector3.ZERO
var yaw := 0.0
var pitch := 0.0
var si := 0
var ni := 0
var wait := 0
const SETTLE := 12

func _initialize() -> void:
	var scene := "wing1"
	var cam_s := "-7,16,0,-14"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--scene="): scene = a.substr(8)
		elif a.begins_with("--cam="): cam_s = a.substr(6)
		elif a.begins_with("--steps="): steps = int(a.substr(8))
		elif a.begins_with("--step="): step = float(a.substr(7))
		elif a.begins_with("--flat="): flat = a.substr(7) == "1"
		elif a.begins_with("--out="): out = a.substr(6)
		elif a.begins_with("--specs="):
			specs = PackedFloat32Array()
			for s in a.substr(8).split(","): specs.append(float(s))
	var v := cam_s.split(",")
	start = Vector3(float(v[0]), 0, float(v[1]))
	yaw = deg_to_rad(float(v[2]))
	pitch = deg_to_rad(float(v[3])) if v.size() > 3 else 0.0
	root.size = Vector2i(960, 540)
	scn = load("res://%s.tscn" % scene).instantiate()
	root.add_child(scn)
	current_scene = scn
	pl = scn.get_node("Player")

func _pose() -> void:
	var fwd := Vector3(-sin(yaw), 0, -cos(yaw))
	pl.position = start + fwd * step * ni
	pl.set("velocity", Vector3.ZERO)
	pl.yaw = yaw
	pl.pitch = pitch

func _process(_d) -> bool:
	frames += 1
	if frames < 4:
		return false
	var rt = scn.get_node("Runtime")
	if frames == 4:
		rt.set_clock(12, 1)
		pl.set_physics_process(false)
		pl.set_process_input(false)
		pl.set_process_unhandled_input(false)
		for c in pl.find_children("*", "CanvasLayer", true, false): c.visible = false
		if flat and rt.floor_mats.size() > 0:
			var sh: Shader = rt.floor_mats[0].shader
			sh.code = sh.code.replace("ALBEDO = a * (1.0 - k * 0.35);", "ALBEDO = vec3(0.5) * (1.0 - k * 0.35);")
		print("floor_walk: floor mats=", rt.floor_mats.size(), " shipped floor_spec=", rt.floor_spec, " lightmap=", scn.get_node("LightmapGI").light_data != null)
		wait = 30   # shaders compile, probes capture
	if si >= specs.size():
		return true
	if wait == SETTLE or frames == 4:
		for m in rt.floor_mats: m.set_shader_parameter("floor_spec", specs[si])
		_pose()
	wait -= 1
	if wait > 0:
		return false
	var f := "%s-s%s-%02d.png" % [out, str(specs[si]).replace(".", "p"), ni]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://" + f.get_base_dir()) if not f.begins_with("/") else f.get_base_dir())
	root.get_texture().get_image().save_png(f)
	ni += 1
	if ni > steps:
		ni = 0; si += 1
	wait = SETTLE
	return false
