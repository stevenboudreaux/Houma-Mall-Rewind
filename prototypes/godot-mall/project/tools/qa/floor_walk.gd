## FLOOR-FIX (Nov 11 2026, design/godot-floor-lighting-diagnosis.md): walks the player along a line
## and saves the screen at every step, once per floor_spec value, in one load. The game runs as it
## ships (Player, Runtime, NPCs, baked lightmap, clock at noon); only the floor's specular share changes.
## xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 960x540 --script res://tools/qa/floor_walk.gd -- \
##   --scene=wing1 "--cams=a:-7,16,0,-14;b:-4,-44,0,-10" --steps=7 --step=0.5 --specs=0.25,0 --flat=0 --out=.scratch/fw/w1
## Writes <out>-<cam name>[-flat]-s<spec>-<nn>.png. Cameras are name:x,z,yaw,pitch (or name:spawn); yaw 0 faces -z and the
## walk goes where the camera looks. --flat=1 paints the floor plain grey so only light and reflections
## show (a test-only edit of the shader string); --flat=2 shoots both, the real floor first.
extends SceneTree
const SETTLE := 5   # frames between a pose and its shot (the mirror lags the camera by one)
var frames := 0
var scn: Node
var pl: Node3D
var specs := PackedFloat32Array([0.25, 0.0])
var steps := 7
var step := 0.5
var flats := [false]
var out := ".scratch/fw/walk"
var cams := []          # [name, start, yaw, pitch]
var jobs := []          # [flat, cam index, spec, step index]
var ji := 0
var wait := 0
var code0 := ""

func _initialize() -> void:
	var scene := "wing1"
	var cams_s := "a:-7,16,0,-14"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--scene="): scene = a.substr(8)
		elif a.begins_with("--cams="): cams_s = a.substr(7)
		elif a.begins_with("--steps="): steps = int(a.substr(8))
		elif a.begins_with("--step="): step = float(a.substr(7))
		elif a.begins_with("--flat="): flats = {"0": [false], "1": [true], "2": [false, true]}[a.substr(7)]
		elif a.begins_with("--out="): out = a.substr(6)
		elif a.begins_with("--specs="):
			specs = PackedFloat32Array()
			for s in a.substr(8).split(","): specs.append(float(s))
	for c in cams_s.split(";"):
		var nv := c.split(":")
		if nv[1] == "spawn":   # the wing's own start pose (room wings 4-6), pitched down at the floor
			cams.append([nv[0], null, 0.0, deg_to_rad(-14.0)])
			continue
		var v := nv[1].split(",")
		cams.append([nv[0], Vector3(float(v[0]), 0, float(v[1])), deg_to_rad(float(v[2])), deg_to_rad(float(v[3])) if v.size() > 3 else 0.0])
	for f in flats:
		for ci in cams.size():
			for s in specs:
				for n in steps + 1:
					jobs.append([f, ci, s, n])
	scn = load("res://%s.tscn" % scene).instantiate()
	root.add_child(scn)
	current_scene = scn
	pl = scn.get_node("Player")

func _apply(j: Array) -> void:
	var rt = scn.get_node("Runtime")
	if rt.floor_mats.size() > 0:
		var sh: Shader = rt.floor_mats[0].shader
		var want: String = code0.replace("ALBEDO = a * (1.0 - k * 0.35);", "ALBEDO = vec3(0.5) * (1.0 - k * 0.35);") if j[0] else code0
		if sh.code != want:
			sh.code = want
	for m in rt.floor_mats: m.set_shader_parameter("floor_spec", j[2])
	var c: Array = cams[j[1]]
	if c[1] == null:
		c[1] = pl.position
		c[2] = pl.yaw
	pl.position = c[1] + Vector3(-sin(c[2]), 0, -cos(c[2])) * step * j[3]
	pl.yaw = c[2]
	pl.pitch = c[3]
	pl._apply_rot()

func _process(_d) -> bool:
	frames += 1
	if frames < 4:
		return false
	var rt = scn.get_node("Runtime")
	if frames == 4:
		rt.set_clock(12, 1)
		pl.set_process_input(false)
		pl.set_process_unhandled_input(false)
		for c in pl.find_children("*", "CanvasLayer", true, false): c.visible = false
		if rt.floor_mats.size() > 0:
			code0 = rt.floor_mats[0].shader.code
		var lm = scn.get_node_or_null("LightmapGI")
		print("floor_walk: floor mats=", rt.floor_mats.size(), " shipped floor_spec=", rt.floor_spec, " lightmap=", lm != null and lm.light_data != null)
		_apply(jobs[0])
		wait = 30   # shaders compile, probes capture
	wait -= 1
	if wait > 0:
		return false
	var j: Array = jobs[ji]
	var f := "%s-%s%s-s%s-%02d.png" % [out, cams[j[1]][0], "-flat" if j[0] else "", str(j[2]).replace(".", "p"), j[3]]
	root.get_texture().get_image().save_png(f)
	ji += 1
	if ji >= jobs.size():
		print("floor_walk: wrote ", jobs.size(), " shots")
		return true
	_apply(jobs[ji])
	wait = SETTLE
	return false
