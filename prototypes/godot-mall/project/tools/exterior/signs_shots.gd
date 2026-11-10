## EXT-SIGNS evidence shots (design/godot-exterior.md "EXT-SIGNS"): tools/exterior/exshots.gd, plus the
## materials' own day / night emission (e_day / e_night, as scripts/time_of_day.gd sets them in the game), so a
## lit sign face shows what the game shows by day and at night. Same arguments as exshots.gd:
##   xvfb-run -a godot --path . --rendering-driver opengl3 --script res://tools/exterior/signs_shots.gd -- \
##     --scene=res://wing3.tscn --out=DIR --mode=day|night --cams="x,y,z,yaw,pitch[,fov]:name;..."
extends "res://tools/exterior/exshots.gd"

func _initialize() -> void:
	super._initialize()
	var mode := "day"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--mode="): mode = a.substr(7)
	var done := {}
	for mi in current_scene.find_children("*", "MeshInstance3D", true, false):
		if mi.mesh == null:
			continue
		for k in mi.mesh.get_surface_count():
			var m = mi.mesh.surface_get_material(k)
			if m is StandardMaterial3D and not done.has(m) and m.has_meta("e_" + mode):
				done[m] = true
				m.emission_energy_multiplier = m.get_meta("e_" + mode)
