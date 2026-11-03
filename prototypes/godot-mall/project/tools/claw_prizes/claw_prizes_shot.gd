## The claw's prizes as Godot draws them (workstream ECON; design/godot-economy.md "Claw prizes in the bag"):
## the eleven models/pc_claw_*.scn in a row on a grey floor, from the front and a little above, plus one held in the
## first-person hand in Wing 2 (unbaked). Checks each scene loads with a mesh and textures.
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script res://tools/claw_prizes/claw_prizes_shot.gd -- --out=/tmp/claw
## Prints CLAW PRIZES SHOT OK.
extends SceneTree

const KINDS := ["gator", "crawfish", "pelican", "nutria", "rougarou", "comet", "bruiser", "pogSkull", "pogGator", "pogEye", "slammer"]
var out := "/tmp/claw"
var step := 0
var clock := 0.0
var errors := []
var scn: Node
var player: Node3D

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.substr(6)
	DirAccess.make_dir_recursive_absolute(out.get_base_dir())
	var w := Node3D.new()
	root.add_child(w)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.22, 0.22, 0.25)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.55, 0.55, 0.6)
	w.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 30, 0)
	sun.light_energy = 1.4
	w.add_child(sun)
	var x := -0.75
	for k in KINDS:
		var ps = load("res://models/pc_claw_%s.scn" % k)
		if not (ps is PackedScene):
			errors.append(k); continue
		var n: Node3D = ps.instantiate()
		var mi: MeshInstance3D = n.get_node_or_null("Mesh")
		if mi == null or mi.mesh == null or mi.mesh.get_surface_count() == 0:
			errors.append(k + " mesh")
		n.position = Vector3(x, 0, 0)
		w.add_child(n)
		x += 0.15
	var cam := Camera3D.new()
	cam.fov = 40
	w.add_child(cam)
	cam.position = Vector3(0, 0.42, 1.05)
	cam.rotation_degrees = Vector3(-21.0, 0, 0)       # down at the row
	cam.current = true

func _process(dt: float) -> bool:
	clock += dt
	match step:
		0:
			if clock > 1.0:
				root.get_texture().get_image().save_png(out + "-lineup.png")
				for c in root.get_children():
					if c is Node3D: c.queue_free()
				Engine.set_meta("mall_state_1995", JSON.stringify({"v": 1, "year": 1995, "inventory": [], "hand": "pc_claw_gator", "moved": {}}))
				Engine.set_meta("mall_xfer", {"x": -104.8, "z": 70.0, "yaw": deg_to_rad(-90.0), "pitch": deg_to_rad(-10.0)})
				scn = load("res://wing2.tscn").instantiate()
				root.add_child(scn)
				current_scene = scn
				var lm = scn.find_child("LightmapGI", true, false)
				if lm: lm.get_parent().remove_child(lm); lm.free()
				load("res://scripts/time_of_day.gd").apply(scn, "night")
				player = scn.get_node("Player")
				step = 1; clock = 0.0
		1:
			if clock > 4.0:
				var it = player.get_node_or_null("Interact")
				if it == null or it.hand_item == null or player.mall.hand != "pc_claw_gator":
					errors.append("the gator is not in the hand")
				root.get_texture().get_image().save_png(out + "-hand.png")
				printerr("CLAW PRIZES SHOT OK" if errors.is_empty() else "CLAW PRIZES SHOT FAILED " + str(errors))
				return true
	return false
