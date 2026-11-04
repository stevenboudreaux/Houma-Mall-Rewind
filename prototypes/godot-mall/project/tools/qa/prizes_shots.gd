## Native, unbaked shots of a wing from fixed cameras (workstream PRIZES; design/godot-prize-counter.md):
## the prize counters before and after. The lightmap is removed (unbaked), night lighting.
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1600x900 \
##     --script res://tools/qa/prizes_shots.gd -- --scene=res://wing2.tscn --out=/tmp/pz/pc \
##     --cams="overview:-107.4,1.7,65.6,-102.4,1.0,65.6;case:-105.2,1.4,64.2,-103.8,0.45,65.1"
## Each camera: name:px,py,pz,tx,ty,tz (position, target). --wait=seconds before the first shot (default 4).
## --list prints the GIPrize* markers and the Prizes node's views (to aim cameras). Prints SHOTS OK.
extends SceneTree

var out := "/tmp/pz/shot"
var scene := "res://wing2.tscn"
var cams := []
var wait := 4.0
var list := false
var scn: Node
var cam: Camera3D
var clock := 0.0
var k := -1

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.substr(6)
		elif a.begins_with("--scene="): scene = a.substr(8)
		elif a.begins_with("--wait="): wait = float(a.substr(7))
		elif a == "--list": list = true
		elif a.begins_with("--cams="):
			for c in a.substr(7).split(";", false):
				var nm := c.get_slice(":", 0)
				var v := c.get_slice(":", 1).split(",")
				cams.append([nm, Vector3(float(v[0]), float(v[1]), float(v[2])), Vector3(float(v[3]), float(v[4]), float(v[5]))])
	DirAccess.make_dir_recursive_absolute(out.get_base_dir())
	Engine.set_meta("mall_state_1995", "")
	Engine.set_meta("mall_state_2026", "")
	var L: Dictionary = load("res://scripts/avatar_look.gd").default_look()
	L.done = true
	L.view = "first"
	Engine.set_meta("mall_avatar", JSON.stringify(L))
	scn = load(scene).instantiate()
	root.add_child(scn)
	current_scene = scn
	var lm = scn.find_child("LightmapGI", true, false)
	if lm: lm.get_parent().remove_child(lm); lm.free()
	load("res://scripts/time_of_day.gd").apply(scn, "night")
	cam = Camera3D.new()
	cam.fov = 55.0
	cam.near = 0.03
	scn.add_child(cam)

func _process(dt: float) -> bool:
	clock += dt
	if k < 0:
		if clock < wait:
			return false
		if list:
			for m in scn.find_children("GIPrize*", "Node3D", true, false):
				print("MARKER %s %s f=%s L=%s" % [m.name, m.global_position, m.global_transform.basis.z, m.get_meta("length", 0)])
			var pz = scn.get_node_or_null("Prizes")
			if pz and "views" in pz:
				for v in pz.views:
					print("VIEW %s pos=%s tgt=%s" % [v.name, v.pos, v.tgt])
				print("ITEMS %d" % pz.items.size())
		k = 0
		clock = 0.0
		if k < cams.size():
			_aim(k)
		return false
	if k >= cams.size():
		print("SHOTS OK %d" % cams.size())
		return true
	if clock > 0.5:
		root.get_texture().get_image().save_png("%s-%s.png" % [out, cams[k][0]])
		k += 1
		clock = 0.0
		if k < cams.size():
			_aim(k)
	return false

func _aim(i: int) -> void:
	cam.global_position = cams[i][1]
	cam.look_at(cams[i][2], Vector3.UP)
	cam.current = true
